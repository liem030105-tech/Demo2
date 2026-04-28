import 'dart:convert';
import 'dart:io';

import 'package:app/core/supabase_providers.dart';
import 'package:app/core/utils/month_range.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final transactionsCsvViewModelProvider =
    ChangeNotifierProvider.autoDispose<TransactionsCsvViewModel>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return TransactionsCsvViewModel(supabase: supabase);
});

class CsvResult {
  const CsvResult({
    required this.ok,
    required this.failed,
  });

  final int ok;
  final int failed;
}

class TransactionsCsvException implements Exception {
  TransactionsCsvException(this.message);
  final String message;

  @override
  String toString() => message;
}

class TransactionsCsvViewModel extends ChangeNotifier {
  TransactionsCsvViewModel({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  bool _busy = false;
  bool get busy => _busy;

  Future<File> exportCsv({
    required DateTime from,
    required DateTime to,
    String? type,
    String? categoryId,
    String? keyword,
  }) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw TransactionsCsvException('Chưa đăng nhập');

    _setBusy(true);
    try {
      final start = toPgDate(from);
      final end = toPgDate(to);

      dynamic q = _supabase
          .from('transactions')
          .select(
            'type, amount_minor, occurred_at, note, category_id, account_id, '
            'categories ( name ), accounts ( name )',
          )
          .gte('occurred_at', start)
          .lte('occurred_at', end)
          .order('occurred_at', ascending: true);

      if (type != null) q = q.eq('type', type);
      if (categoryId != null) q = q.eq('category_id', categoryId);
      final kw = (keyword ?? '').trim();
      if (kw.isNotEmpty) q = q.ilike('note', '%$kw%');

      final res = await q;

      final rows = <List<dynamic>>[
        [
          'date',
          'type',
          'amount_minor',
          'note',
          'category_name',
          'account_name',
        ],
      ];

      for (final raw in res as List<dynamic>) {
        final m = Map<String, dynamic>.from(raw as Map);
        final date = (m['occurred_at'] as String?) ?? '';
        final type = (m['type'] as String?) ?? '';
        final amt = (m['amount_minor'] as num?)?.toInt() ?? 0;
        final note = (m['note'] as String?) ?? '';
        final cat = m['categories'];
        final acc = m['accounts'];
        final catName =
            cat is Map<String, dynamic> ? (cat['name'] as String? ?? '') : '';
        final accName =
            acc is Map<String, dynamic> ? (acc['name'] as String? ?? '') : '';
        rows.add([date, type, amt, note, catName, accName]);
      }

      final csv = const ListToCsvConverter(
        fieldDelimiter: ',',
        eol: '\r\n',
        textDelimiter: '"',
      ).convert(rows);

      final dir = await getTemporaryDirectory();
      final fileName =
          'transactions_${from.year}${from.month.toString().padLeft(2, '0')}${from.day.toString().padLeft(2, '0')}'
          '_to_${to.year}${to.month.toString().padLeft(2, '0')}${to.day.toString().padLeft(2, '0')}.csv';
      final file = File('${dir.path}${Platform.pathSeparator}$fileName');
      await file.writeAsString('\uFEFF$csv', encoding: utf8);
      return file;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> shareFile(File file) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: 'Transactions CSV'),
    );
  }

  Future<CsvResult> importCsv() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw TransactionsCsvException('Chưa đăng nhập');

    _setBusy(true);
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        withData: true,
      );
      if (picked == null || picked.files.isEmpty) {
        throw TransactionsCsvException('Bạn chưa chọn file CSV');
      }

      final bytes = picked.files.first.bytes;
      if (bytes == null) {
        throw TransactionsCsvException('Không đọc được file (bytes null)');
      }

      final text = _decodeCsv(bytes);
      final table = const CsvToListConverter(
        fieldDelimiter: ',',
        eol: '\n',
        textDelimiter: '"',
        shouldParseNumbers: false,
      ).convert(text);
      if (table.isEmpty) {
        throw TransactionsCsvException('CSV rỗng');
      }

      // Header normalize
      final header = table.first.map((e) => (e?.toString() ?? '').trim()).toList();
      final idx = <String, int>{};
      for (var i = 0; i < header.length; i++) {
        idx[header[i].toLowerCase()] = i;
      }

      int col(String name) {
        final i = idx[name];
        if (i == null) {
          throw TransactionsCsvException('Thiếu cột `$name` trong CSV');
        }
        return i;
      }

      final iDate = col('date');
      final iType = col('type');
      final iAmt = col('amount_minor');
      final iNote = idx['note'] ?? -1;
      final iCatName = idx['category_name'] ?? -1;
      final iAccName = idx['account_name'] ?? -1;

      // Preload accounts + categories (by name)
      final accountsRes = await _supabase.from('accounts').select('id, name').order('name');
      final categoriesRes = await _supabase
          .from('categories')
          .select('id, name, type')
          .order('type')
          .order('name');

      final accountByName = <String, String>{};
      for (final raw in accountsRes as List<dynamic>) {
        final m = Map<String, dynamic>.from(raw as Map);
        accountByName[(m['name'] as String).trim().toLowerCase()] = m['id'] as String;
      }

      final categoryByTypeAndName = <String, String>{};
      for (final raw in categoriesRes as List<dynamic>) {
        final m = Map<String, dynamic>.from(raw as Map);
        final type = (m['type'] as String).trim();
        final name = (m['name'] as String).trim().toLowerCase();
        categoryByTypeAndName['$type::$name'] = m['id'] as String;
      }

      var ok = 0;
      var failed = 0;
      final batch = <Map<String, Object?>>[];

      Future<String> ensureAccount(String? name) async {
        final n = (name ?? '').trim();
        if (n.isEmpty) {
          // fallback to default
          return await _ensureDefaultAccount(uid, accountByName);
        }
        final key = n.toLowerCase();
        final existing = accountByName[key];
        if (existing != null) return existing;

        final inserted = await _supabase
            .from('accounts')
            .insert({'user_id': uid, 'name': n})
            .select('id')
            .single();
        final id = inserted['id'] as String;
        accountByName[key] = id;
        return id;
      }

      Future<String> ensureCategory(String type, String? name) async {
        final n = (name ?? '').trim();
        if (n.isEmpty) {
          // fallback category
          final fallback = type == 'income' ? 'Thu nhập khác' : 'Khác';
          return await ensureCategory(type, fallback);
        }
        final key = '$type::${n.toLowerCase()}';
        final existing = categoryByTypeAndName[key];
        if (existing != null) return existing;

        final inserted = await _supabase
            .from('categories')
            .insert({
              'user_id': uid,
              'name': n,
              'type': type,
              'color': type == 'income' ? '#26A69A' : '#78909C',
              'icon': 'import',
            })
            .select('id')
            .single();
        final id = inserted['id'] as String;
        categoryByTypeAndName[key] = id;
        return id;
      }

      Future<void> flush() async {
        if (batch.isEmpty) return;
        try {
          await _supabase.from('transactions').insert(batch);
          ok += batch.length;
        } catch (_) {
          failed += batch.length;
        } finally {
          batch.clear();
        }
      }

      for (var r = 1; r < table.length; r++) {
        final row = table[r];
        try {
          final dateRaw = row.elementAt(iDate)?.toString().trim() ?? '';
          final typeRaw = row.elementAt(iType)?.toString().trim().toLowerCase() ?? '';
          final amtRaw = row.elementAt(iAmt)?.toString().trim() ?? '';
          final note = iNote >= 0 ? (row.elementAt(iNote)?.toString() ?? '') : '';
          final catName = iCatName >= 0 ? (row.elementAt(iCatName)?.toString() ?? '') : '';
          final accName = iAccName >= 0 ? (row.elementAt(iAccName)?.toString() ?? '') : '';

          final type = (typeRaw == 'income' || typeRaw == 'expense') ? typeRaw : '';
          if (type.isEmpty) throw TransactionsCsvException('type không hợp lệ');

          final occurredAt = DateTime.tryParse(dateRaw);
          if (occurredAt == null) throw TransactionsCsvException('date không hợp lệ');

          final amt = int.tryParse(amtRaw.replaceAll(RegExp(r'\\D'), ''));
          if (amt == null || amt <= 0) throw TransactionsCsvException('amount_minor không hợp lệ');

          final accountId = await ensureAccount(accName);
          final categoryId = await ensureCategory(type, catName);

          batch.add({
            'user_id': uid,
            'type': type,
            'amount_minor': amt,
            'occurred_at': toPgDate(occurredAt),
            'note': note.trim().isEmpty ? null : note.trim(),
            'account_id': accountId,
            'category_id': categoryId,
          });

          if (batch.length >= 200) {
            await flush();
          }
        } catch (_) {
          failed += 1;
        }
      }

      await flush();
      return CsvResult(ok: ok, failed: failed);
    } finally {
      _setBusy(false);
    }
  }

  String _decodeCsv(Uint8List bytes) {
    // Handle BOM
    final s = utf8.decode(bytes, allowMalformed: true);
    if (s.startsWith('\uFEFF')) return s.substring(1);
    return s;
  }

  Future<String> _ensureDefaultAccount(
    String uid,
    Map<String, String> accountByName,
  ) async {
    const fallback = 'Tiền mặt';
    final key = fallback.toLowerCase();
    final existing = accountByName[key];
    if (existing != null) return existing;
    final inserted = await _supabase
        .from('accounts')
        .insert({'user_id': uid, 'name': fallback})
        .select('id')
        .single();
    final id = inserted['id'] as String;
    accountByName[key] = id;
    return id;
  }

  void _setBusy(bool v) {
    if (_busy == v) return;
    _busy = v;
    notifyListeners();
  }
}

