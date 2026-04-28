import 'package:app/core/supabase_providers.dart';
import 'package:app/core/utils/month_range.dart';
import 'package:app/features/manage/data/category_model.dart';
import 'package:app/features/transactions/data/transaction_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final transactionsViewModelProvider =
    ChangeNotifierProvider.autoDispose<TransactionsViewModel>((ref) {
  ref.keepAlive();
  final supabase = ref.watch(supabaseClientProvider);
  return TransactionsViewModel(supabase: supabase);
});

class TransactionsException implements Exception {
  TransactionsException(this.message);
  final String message;

  @override
  String toString() => message;
}

class TransactionsViewModel extends ChangeNotifier {
  TransactionsViewModel({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  DateTime _month = firstDayOfMonth(DateTime.now());
  List<TransactionModel> _items = [];
  List<CategoryModel> _categories = [];
  bool _metaLoaded = false;
  bool _loading = false;
  String? _loadError;

  // Filters (in-session)
  // - if [_from]/[_to] set => use date range
  // - otherwise use [_month] for month filter
  DateTime? _from;
  DateTime? _to;
  String? _type; // null | expense | income
  String? _categoryId;
  String _keyword = '';

  DateTime get month => _month;
  List<TransactionModel> get items => List.unmodifiable(_items);
  List<CategoryModel> get categories => List.unmodifiable(_categories);
  bool get loading => _loading;
  String? get loadError => _loadError;

  DateTime? get from => _from;
  DateTime? get to => _to;
  String? get typeFilter => _type;
  String? get categoryIdFilter => _categoryId;
  String get keyword => _keyword;
  bool get usingDateRange => _from != null || _to != null;

  void setMonth(DateTime anyDayInMonth) {
    final next = firstDayOfMonth(anyDayInMonth);
    if (next.year == _month.year && next.month == _month.month) return;
    _month = next;
    // When user explicitly changes month, switch back to month mode.
    _from = null;
    _to = null;
    notifyListeners();
    load();
  }

  Future<void> ensureMetaLoaded() async {
    if (_metaLoaded) return;
    final res =
        await _supabase.from('categories').select().order('type').order('name');
    _categories = (res as List<dynamic>)
        .map((e) => CategoryModel.fromRow(Map<String, dynamic>.from(e as Map)))
        .toList();
    _metaLoaded = true;
    notifyListeners();
  }

  void setTypeFilter(String? type) {
    if (type != null && type != 'expense' && type != 'income') return;
    if (_type == type) return;
    _type = type;
    // If selected category no longer matches type, clear it.
    if (_type != null && _categoryId != null) {
      final selected = _categories.where((c) => c.id == _categoryId).toList();
      if (selected.isEmpty || selected.first.type != _type) {
        _categoryId = null;
      }
    }
    notifyListeners();
  }

  void setCategoryIdFilter(String? categoryId) {
    if (_categoryId == categoryId) return;
    _categoryId = categoryId;
    notifyListeners();
  }

  void setKeyword(String value) {
    final next = value.trim();
    if (_keyword == next) return;
    _keyword = next;
    notifyListeners();
  }

  void setDateRange({DateTime? from, DateTime? to}) {
    _from = from == null ? null : DateTime(from.year, from.month, from.day);
    _to = to == null ? null : DateTime(to.year, to.month, to.day);
    notifyListeners();
    load();
  }

  void resetFilters() {
    _from = null;
    _to = null;
    _type = null;
    _categoryId = null;
    _keyword = '';
    notifyListeners();
    load();
  }

  Future<void> load() async {
    if (_supabase.auth.currentUser == null) return;
    _loading = true;
    _loadError = null;
    notifyListeners();
    try {
      await ensureMetaLoaded();

      DateTime rangeStart;
      DateTime rangeEnd;
      if (usingDateRange) {
        final base = _from ?? _to ?? _month;
        rangeStart = _from ?? base;
        rangeEnd = _to ?? base;
      } else {
        rangeStart = _month;
        rangeEnd = lastDayOfMonth(_month);
      }

      final start = toPgDate(rangeStart);
      final end = toPgDate(rangeEnd);

      dynamic q = _supabase
          .from('transactions')
          .select(
            'id, type, amount_minor, occurred_at, note, payment_method, '
            'category_id, account_id, categories ( name ), accounts ( name )',
          )
          .gte('occurred_at', start)
          .lte('occurred_at', end)
          .order('occurred_at', ascending: false);

      if (_type != null) q = q.eq('type', _type!);
      if (_categoryId != null) q = q.eq('category_id', _categoryId!);
      if (_keyword.isNotEmpty) q = q.ilike('note', '%$_keyword%');

      final res = await q;
      _items = (res as List<dynamic>)
          .map((e) => TransactionModel.fromRow(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      _loadError = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> delete(String id) async {
    await _supabase.from('transactions').delete().eq('id', id);
    await load();
  }
}
