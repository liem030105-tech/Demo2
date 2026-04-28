import 'package:app/core/supabase_providers.dart';
import 'package:app/features/manage/data/account_model.dart';
import 'package:app/features/manage/data/category_model.dart';
import 'package:app/features/transactions/data/transaction_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final transactionFormViewModelProvider = ChangeNotifierProvider.autoDispose
    .family<TransactionFormViewModel, String?>((ref, existingId) {
  final supabase = ref.watch(supabaseClientProvider);
  return TransactionFormViewModel(supabase: supabase, existingId: existingId);
});

class TransactionFormException implements Exception {
  TransactionFormException(this.message);
  final String message;

  @override
  String toString() => message;
}

class TransactionFormViewModel extends ChangeNotifier {
  TransactionFormViewModel({
    required SupabaseClient supabase,
    required String? existingId,
  })  : _supabase = supabase,
        _existingId = existingId;

  final SupabaseClient _supabase;
  final String? _existingId;

  List<AccountModel> _accounts = [];
  List<CategoryModel> _categories = [];
  TransactionModel? _existing;
  bool _loading = true;
  String? _loadError;

  List<AccountModel> get accounts => List.unmodifiable(_accounts);
  List<CategoryModel> get categories => List.unmodifiable(_categories);
  TransactionModel? get existing => _existing;
  bool get loading => _loading;
  String? get loadError => _loadError;
  bool get isEdit => _existingId != null;

  Future<void> init() async {
    _loading = true;
    _loadError = null;
    notifyListeners();
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) throw TransactionFormException('Chưa đăng nhập');

      final acc = await _supabase.from('accounts').select().order('name');
      _accounts = (acc as List<dynamic>)
          .map((e) => AccountModel.fromRow(Map<String, dynamic>.from(e as Map)))
          .toList();

      final cat = await _supabase.from('categories').select().order('name');
      _categories = (cat as List<dynamic>)
          .map((e) => CategoryModel.fromRow(Map<String, dynamic>.from(e as Map)))
          .toList();

      final existingId = _existingId;
      if (existingId != null) {
        final row = await _supabase
            .from('transactions')
            .select(
              'id, type, amount_minor, occurred_at, note, payment_method, '
              'category_id, account_id, categories ( name ), accounts ( name )',
            )
            .eq('id', existingId)
            .maybeSingle();
        if (row == null) {
          throw TransactionFormException('Không tìm thấy giao dịch');
        }
        _existing = TransactionModel.fromRow(Map<String, dynamic>.from(row));
      } else {
        _existing = null;
      }
    } catch (e) {
      _loadError = e is TransactionFormException ? e.message : e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  List<CategoryModel> categoriesForType(String type) {
    return _categories.where((c) => c.type == type).toList();
  }

  Future<void> save({
    required String type,
    required int amountMinor,
    required DateTime occurredAt,
    required String accountId,
    required String categoryId,
    required String note,
    required String? paymentMethod,
  }) async {
    if (type != 'expense' && type != 'income') {
      throw TransactionFormException('Loại không hợp lệ');
    }
    if (amountMinor <= 0) {
      throw TransactionFormException('Số tiền phải lớn hơn 0');
    }
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw TransactionFormException('Chưa đăng nhập');

    CategoryModel? cat;
    for (final c in _categories) {
      if (c.id == categoryId) {
        cat = c;
        break;
      }
    }
    if (cat == null) throw TransactionFormException('Danh mục không hợp lệ');
    if (cat.type != type) {
      throw TransactionFormException('Danh mục không khớp loại thu/chi');
    }
    if (!_accounts.any((a) => a.id == accountId)) {
      throw TransactionFormException('Tài khoản không hợp lệ');
    }

    final payload = <String, Object?>{
      'type': type,
      'amount_minor': amountMinor,
      'occurred_at': _toPgDate(occurredAt),
      'account_id': accountId,
      'category_id': categoryId,
      'note': note.trim().isEmpty ? null : note.trim(),
      'payment_method': paymentMethod,
    };

    final targetId = _existingId;
    if (targetId == null) {
      await _supabase.from('transactions').insert({
        ...payload,
        'user_id': uid,
      });
    } else {
      await _supabase.from('transactions').update(payload).eq('id', targetId);
    }
  }

  String _toPgDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
