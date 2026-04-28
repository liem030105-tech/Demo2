import 'package:app/core/supabase_providers.dart';
import 'package:app/core/profile_providers.dart';
import 'package:app/core/utils/month_range.dart';
import 'package:app/core/utils/money_format.dart';
import 'package:app/core/widgets/inline_error_card.dart';
import 'package:app/features/dashboard/presentation/dashboard_view_model.dart';
import 'package:app/features/manage/data/category_model.dart';
import 'package:app/features/settings/data/profile_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  Future<void> _pickMonth(DashboardViewModel vm) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.month,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) vm.setMonth(picked);
  }

  Future<void> _editBudget(DashboardViewModel vm, CategoryModel c) async {
    final existing = vm.budgetLimitFor(c.id);
    final ctrl = TextEditingController(text: existing?.toString() ?? '');
    try {
      final saved = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Ngân sách: ${c.name}'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Giới hạn (đồng)',
              hintText: 'Ví dụ: 1000000',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ'),
            ),
            if (existing != null)
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Xoá'),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lưu'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      if (saved == true) {
        final digits = ctrl.text.replaceAll(RegExp(r'\D'), '');
        final limit = int.tryParse(digits);
        if (limit == null || limit <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nhập giới hạn hợp lệ (> 0).')),
          );
          return;
        }
        await vm.upsertBudget(categoryId: c.id, limitMinor: limit);
      } else if (saved == null) {
        await vm.deleteBudget(categoryId: c.id);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      ctrl.dispose();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardViewModelProvider).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final supabase = ref.watch(supabaseClientProvider);
    final email = supabase.auth.currentUser?.email ?? '';
    final profile = ref.watch(profileProvider).valueOrNull;
    final vm = ref.watch(dashboardViewModelProvider);

    ref.listen(dashboardViewModelProvider, (prev, next) {
      final err = next.bootstrapError;
      if (err == null) return;
      if (prev?.bootstrapError == err) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể seed dữ liệu mặc định: $err')),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Chọn tháng',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => _pickMonth(vm),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: () async => supabase.auth.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            if (vm.loadError != null) ...[
              InlineErrorCard(message: vm.loadError!, onRetry: vm.load),
              const SizedBox(height: 12),
            ],
            if (vm.bootstrapping) ...[
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
            ],
            Text(
              'Xin chào, ${_greetingName(profile, email)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              monthLabelVi(vm.month),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Tổng quan tháng',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _SummaryRow(
                      label: 'Thu',
                      value: formatMoneyVnd(vm.incomeMinor),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    _SummaryRow(
                      label: 'Chi',
                      value: formatMoneyVnd(vm.expenseMinor),
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const Divider(height: 24),
                    _SummaryRow(
                      label: 'Chênh lệch',
                      value: formatMoneyVnd(vm.netMinor),
                      color: Theme.of(context).colorScheme.onSurface,
                      emphasize: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Top chi theo danh mục',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (vm.topExpenses.isEmpty)
              Text(
                'Chưa có khoản chi trong tháng này.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              )
            else
              ...vm.topExpenses.map(
                (e) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(e.label),
                    trailing: Text(
                      formatMoneyVnd(e.totalMinor),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Text(
              'Cảnh báo ngân sách',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (vm.budgetAlerts.isEmpty)
              Text(
                'Chưa có cảnh báo (hoặc bạn chưa đặt ngân sách).',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              )
            else
              ...vm.budgetAlerts.map(
                (a) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(a.categoryName),
                    subtitle: Text(
                      '${formatMoneyVnd(a.spentMinor)} / ${formatMoneyVnd(a.limitMinor)}'
                      '${a.isOver ? ' · VƯỢT' : ''}',
                    ),
                    trailing: SizedBox(
                      width: 84,
                      child: LinearProgressIndicator(
                        value: a.usedRatio.clamp(0.0, 1.0),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(999),
                        color: a.isOver
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Text(
              'Đặt ngân sách (theo danh mục chi)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (vm.expenseCategories.isEmpty)
              Text(
                'Chưa có danh mục chi.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              )
            else
              ...vm.expenseCategories.map(
                (c) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(c.name),
                    subtitle: Text(
                      vm.budgetLimitFor(c.id) == null
                          ? 'Chưa đặt ngân sách'
                          : 'Giới hạn: ${formatMoneyVnd(vm.budgetLimitFor(c.id)!)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _editBudget(vm, c),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = emphasize
        ? Theme.of(context).textTheme.titleMedium?.copyWith(color: color)
        : Theme.of(context).textTheme.bodyLarge?.copyWith(color: color);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        Text(value, style: style),
      ],
    );
  }
}

String _greetingName(ProfileModel? p, String email) {
  final name = p?.displayName?.trim();
  if (name == null || name.isEmpty) return email;
  return name;
}

