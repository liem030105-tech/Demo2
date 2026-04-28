import 'package:app/features/bootstrap/data/bootstrap_providers.dart';
import 'package:app/features/bootstrap/data/bootstrap_service.dart';
import 'package:app/core/supabase_providers.dart';
import 'package:app/core/utils/month_range.dart';
import 'package:app/features/manage/data/category_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final dashboardViewModelProvider =
    ChangeNotifierProvider.autoDispose<DashboardViewModel>((ref) {
  final bootstrap = ref.watch(bootstrapServiceProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return DashboardViewModel(bootstrap: bootstrap, supabase: supabase);
});

class BudgetAlert {
  const BudgetAlert({
    required this.categoryId,
    required this.categoryName,
    required this.spentMinor,
    required this.limitMinor,
  });

  final String categoryId;
  final String categoryName;
  final int spentMinor;
  final int limitMinor;

  int get remainingMinor => limitMinor - spentMinor;
  double get usedRatio =>
      limitMinor <= 0 ? 0 : (spentMinor / limitMinor).clamp(0.0, 10.0);
  bool get isOver => spentMinor > limitMinor;
}

class TopExpenseCategory {
  const TopExpenseCategory({required this.label, required this.totalMinor});

  final String label;
  final int totalMinor;
}

class DashboardViewModel extends ChangeNotifier {
  DashboardViewModel({required this.bootstrap, required SupabaseClient supabase})
      : _supabase = supabase;

  final BootstrapService bootstrap;
  final SupabaseClient _supabase;

  bool _bootstrapping = false;
  String? _bootstrapError;

  bool get bootstrapping => _bootstrapping;
  String? get bootstrapError => _bootstrapError;

  DateTime _month = firstDayOfMonth(DateTime.now());
  bool _loading = false;
  String? _loadError;

  int _incomeMinor = 0;
  int _expenseMinor = 0;
  List<TopExpenseCategory> _topExpenses = [];
  List<BudgetAlert> _budgetAlerts = [];
  List<CategoryModel> _expenseCategories = [];
  Map<String, int> _budgetLimitByCategoryId = {};

  DateTime get month => _month;
  bool get loading => _loading;
  String? get loadError => _loadError;
  int get incomeMinor => _incomeMinor;
  int get expenseMinor => _expenseMinor;
  int get netMinor => _incomeMinor - _expenseMinor;
  List<TopExpenseCategory> get topExpenses => List.unmodifiable(_topExpenses);
  List<BudgetAlert> get budgetAlerts => List.unmodifiable(_budgetAlerts);
  List<CategoryModel> get expenseCategories =>
      List.unmodifiable(_expenseCategories);

  int? budgetLimitFor(String categoryId) => _budgetLimitByCategoryId[categoryId];

  void setMonth(DateTime anyDayInMonth) {
    final next = firstDayOfMonth(anyDayInMonth);
    if (next.year == _month.year && next.month == _month.month) return;
    _month = next;
    notifyListeners();
    load();
  }

  Future<void> init() async {
    if (_bootstrapping) return;
    _bootstrapping = true;
    _bootstrapError = null;
    notifyListeners();

    try {
      await bootstrap.ensureBootstrapData();
      await load();
    } catch (e) {
      _bootstrapError = e.toString();
    } finally {
      _bootstrapping = false;
      notifyListeners();
    }
  }

  Future<void> load() async {
    if (_supabase.auth.currentUser == null) return;
    _loading = true;
    _loadError = null;
    notifyListeners();

    try {
      final start = toPgDate(_month);
      final end = toPgDate(lastDayOfMonth(_month));

      final catsRes = await _supabase
          .from('categories')
          .select()
          .eq('type', 'expense')
          .order('name');
      _expenseCategories = (catsRes as List<dynamic>)
          .map((e) => CategoryModel.fromRow(Map<String, dynamic>.from(e as Map)))
          .toList();

      final budgetsRes = await _supabase
          .from('budgets')
          .select('category_id, limit_minor')
          .eq('month', start);
      _budgetLimitByCategoryId = {};
      for (final raw in budgetsRes as List<dynamic>) {
        final m = Map<String, dynamic>.from(raw as Map);
        _budgetLimitByCategoryId[m['category_id'] as String] =
            (m['limit_minor'] as num).toInt();
      }

      final txRes = await _supabase
          .from('transactions')
          .select(
            'type, amount_minor, category_id, categories ( name )',
          )
          .gte('occurred_at', start)
          .lte('occurred_at', end);

      var income = 0;
      var expense = 0;
      final expenseAgg = <String, _Agg>{};
      for (final raw in txRes as List<dynamic>) {
        final row = Map<String, dynamic>.from(raw as Map);
        final type = row['type'] as String?;
        final amt = (row['amount_minor'] as num?)?.toInt() ?? 0;
        if (type == 'income') {
          income += amt;
          continue;
        }
        if (type != 'expense') continue;

        expense += amt;
        final cid = row['category_id'] as String?;
        final key = cid ?? '__null__';
        final a = expenseAgg.putIfAbsent(key, _Agg.new);
        a.total += amt;
        a.categoryId ??= cid;
        final nested = row['categories'];
        if (nested is Map<String, dynamic>) {
          final name = nested['name'] as String?;
          if (name != null && name.isNotEmpty) a.name = name;
        }
      }

      _incomeMinor = income;
      _expenseMinor = expense;

      final top = <TopExpenseCategory>[];
      final alerts = <BudgetAlert>[];

      for (final e in expenseAgg.entries) {
        final a = e.value;
        final label = a.name ?? '(Đã xoá)';
        top.add(TopExpenseCategory(label: label, totalMinor: a.total));

        final cid = a.categoryId;
        if (cid == null) continue;
        final limit = _budgetLimitByCategoryId[cid];
        if (limit == null) continue;
        alerts.add(
          BudgetAlert(
            categoryId: cid,
            categoryName: label,
            spentMinor: a.total,
            limitMinor: limit,
          ),
        );
      }

      top.sort((a, b) => b.totalMinor.compareTo(a.totalMinor));
      _topExpenses = top.take(5).toList();

      alerts.sort((a, b) => b.usedRatio.compareTo(a.usedRatio));
      _budgetAlerts =
          alerts.where((a) => a.usedRatio >= 0.8 || a.isOver).toList();
    } catch (e) {
      _loadError = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> upsertBudget({
    required String categoryId,
    required int limitMinor,
  }) async {
    if (limitMinor <= 0) return;
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    final monthStr = toPgDate(_month);

    await _supabase.from('budgets').upsert(
      {
        'user_id': uid,
        'category_id': categoryId,
        'month': monthStr,
        'limit_minor': limitMinor,
      },
      onConflict: 'user_id,category_id,month',
    );
    await load();
  }

  Future<void> deleteBudget({required String categoryId}) async {
    final monthStr = toPgDate(_month);
    await _supabase
        .from('budgets')
        .delete()
        .eq('category_id', categoryId)
        .eq('month', monthStr);
    await load();
  }
}

class _Agg {
  int total = 0;
  String? name;
  String? categoryId;
}
