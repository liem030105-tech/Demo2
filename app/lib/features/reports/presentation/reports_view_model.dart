import 'package:app/core/supabase_providers.dart';
import 'package:app/core/utils/month_range.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final reportsViewModelProvider =
    ChangeNotifierProvider.autoDispose<ReportsViewModel>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ReportsViewModel(supabase: supabase);
});

class ExpenseCategoryBreakdown {
  const ExpenseCategoryBreakdown({
    required this.label,
    required this.totalMinor,
  });

  final String label;
  final int totalMinor;
}

class ReportsViewModel extends ChangeNotifier {
  ReportsViewModel({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  DateTime _month = firstDayOfMonth(DateTime.now());
  int _incomeMinor = 0;
  int _expenseMinor = 0;
  List<ExpenseCategoryBreakdown> _breakdown = [];
  bool _loading = false;
  String? _loadError;

  DateTime get month => _month;
  int get incomeMinor => _incomeMinor;
  int get expenseMinor => _expenseMinor;
  int get netMinor => _incomeMinor - _expenseMinor;
  List<ExpenseCategoryBreakdown> get breakdown =>
      List.unmodifiable(_breakdown);
  bool get loading => _loading;
  String? get loadError => _loadError;

  void setMonth(DateTime anyDayInMonth) {
    final next = firstDayOfMonth(anyDayInMonth);
    if (next.year == _month.year && next.month == _month.month) return;
    _month = next;
    notifyListeners();
    load();
  }

  Future<void> load() async {
    if (_supabase.auth.currentUser == null) return;
    _loading = true;
    _loadError = null;
    notifyListeners();
    try {
      final start = toPgDate(_month);
      final end = toPgDate(lastDayOfMonth(_month));
      final res = await _supabase
          .from('transactions')
          .select(
            'type, amount_minor, category_id, categories ( name )',
          )
          .gte('occurred_at', start)
          .lte('occurred_at', end);

      var income = 0;
      var expense = 0;
      final agg = <String, _Agg>{};

      for (final raw in res as List<dynamic>) {
        final row = Map<String, dynamic>.from(raw as Map);
        final type = row['type'] as String?;
        final amt = (row['amount_minor'] as num?)?.toInt() ?? 0;
        if (type == 'income') {
          income += amt;
        } else if (type == 'expense') {
          expense += amt;
          final cid = row['category_id'] as String?;
          final key = cid ?? '__null__';
          final nested = row['categories'];
          String? name;
          if (nested is Map<String, dynamic>) {
            name = nested['name'] as String?;
          }
          final a = agg.putIfAbsent(key, _Agg.new);
          a.total += amt;
          a.categoryId ??= cid;
          if (name != null && name.isNotEmpty) a.name = name;
        }
      }

      _incomeMinor = income;
      _expenseMinor = expense;

      final rows = <ExpenseCategoryBreakdown>[];
      for (final e in agg.entries) {
        final a = e.value;
        final label = _labelFor(a);
        rows.add(ExpenseCategoryBreakdown(label: label, totalMinor: a.total));
      }
      rows.sort((a, b) => b.totalMinor.compareTo(a.totalMinor));
      _breakdown = rows;
    } catch (e) {
      _loadError = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String _labelFor(_Agg a) {
    if (a.name != null && a.name!.isNotEmpty) return a.name!;
    if (a.categoryId == null) return '(Đã xoá)';
    return '(Đã xoá)';
  }
}

class _Agg {
  int total = 0;
  String? name;
  String? categoryId;
}
