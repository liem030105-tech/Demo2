import 'package:app/core/utils/month_range.dart';
import 'package:app/core/utils/money_format.dart';
import 'package:app/core/widgets/inline_error_card.dart';
import 'package:app/features/reports/presentation/reports_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportsViewModelProvider).load();
    });
  }

  Future<void> _pickMonth(ReportsViewModel vm) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.month,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) vm.setMonth(picked);
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(reportsViewModelProvider);

    ref.listen(reportsViewModelProvider, (prev, next) {
      final err = next.loadError;
      if (err == null) return;
      if (prev?.loadError == err) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được báo cáo: $err')),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo'),
        actions: [
          IconButton(
            tooltip: 'Chọn tháng',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => _pickMonth(vm),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: vm.load,
        child: vm.loading && vm.breakdown.isEmpty && vm.incomeMinor == 0 && vm.expenseMinor == 0
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (vm.loadError != null) ...[
                    InlineErrorCard(
                      message: vm.loadError!,
                      onRetry: vm.load,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Tháng trước',
                        onPressed: vm.loading
                            ? null
                            : () => vm.setMonth(
                                  DateTime(vm.month.year, vm.month.month - 1, 1),
                                ),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(
                        child: Text(
                          monthLabelVi(vm.month),
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Tháng sau',
                        onPressed: vm.loading
                            ? null
                            : () => vm.setMonth(
                                  DateTime(vm.month.year, vm.month.month + 1, 1),
                                ),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Tổng quan',
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
                            label: 'Chênh lệch (thu − chi)',
                            value: formatMoneyVnd(vm.netMinor),
                            color: Theme.of(context).colorScheme.onSurface,
                            emphasize: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Chi theo danh mục',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (vm.breakdown.isEmpty)
                    Text(
                      vm.expenseMinor == 0
                          ? 'Không có khoản chi trong tháng này.'
                          : 'Có chi nhưng chưa gom được theo danh mục.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    )
                  else
                    ...vm.breakdown.map(
                      (b) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(b.label),
                          trailing: Text(
                            formatMoneyVnd(b.totalMinor),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
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
