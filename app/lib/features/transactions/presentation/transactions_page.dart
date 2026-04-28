import 'package:app/core/utils/month_range.dart';
import 'package:app/core/utils/money_format.dart';
import 'package:app/core/widgets/inline_error_card.dart';
import 'package:app/features/manage/data/category_model.dart';
import 'package:app/features/transactions/data/transaction_model.dart';
import 'package:app/features/transactions/presentation/transactions_csv_view_model.dart';
import 'package:app/features/transactions/presentation/transactions_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final _searchCtrl = TextEditingController();
  bool _csvHooked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionsViewModelProvider).load();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _categoryLabel(TransactionModel t) {
    if (t.categoryId == null) return '(Đã xoá)';
    if (t.categoryName != null && t.categoryName!.isNotEmpty) {
      return t.categoryName!;
    }
    return '(Đã xoá)';
  }

  String _accountLabel(TransactionModel t) {
    if (t.accountId == null) return '(Đã xoá)';
    if (t.accountName != null && t.accountName!.isNotEmpty) {
      return t.accountName!;
    }
    return '(Đã xoá)';
  }

  Future<void> _pickMonth(TransactionsViewModel vm) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.month,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) vm.setMonth(picked);
  }

  String _categoryNameById(TransactionsViewModel vm, String id) {
    for (final c in vm.categories) {
      if (c.id == id) return c.name;
    }
    return '(Đã xoá)';
  }

  Future<void> _openFilters(TransactionsViewModel vm) async {
    await vm.ensureMetaLoaded();
    if (!mounted) return;

    final startFrom = vm.from;
    final startTo = vm.to;
    final startType = vm.typeFilter;
    final startCat = vm.categoryIdFilter;
    _searchCtrl.text = vm.keyword;

    DateTime? from = startFrom;
    DateTime? to = startTo;
    String? type = startType;
    String? categoryId = startCat;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: StatefulBuilder(
          builder: (ctx, setState) {
            List<CategoryModel> cats = vm.categories;
            if (type != null) {
              cats = cats.where((c) => c.type == type).toList();
            }

            Future<void> pickFrom() async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: from ?? vm.month,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => from = picked);
            }

            Future<void> pickTo() async {
              final picked = await showDatePicker(
                context: ctx,
                initialDate: to ?? (from ?? vm.month),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => to = picked);
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Bộ lọc',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tìm trong ghi chú',
                    hintText: 'Ví dụ: coffee',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  // ignore: deprecated_member_use
                  value: type,
                  decoration: const InputDecoration(labelText: 'Loại'),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Tất cả')),
                    DropdownMenuItem(value: 'expense', child: Text('Chi')),
                    DropdownMenuItem(value: 'income', child: Text('Thu')),
                  ],
                  onChanged: (v) => setState(() {
                    type = v;
                    // Reset category if not compatible anymore.
                    if (categoryId != null) {
                      final found = vm.categories.any((c) =>
                          c.id == categoryId &&
                          (type == null || c.type == type));
                      if (!found) categoryId = null;
                    }
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  // ignore: deprecated_member_use
                  value: categoryId,
                  decoration: const InputDecoration(labelText: 'Danh mục'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tất cả')),
                    for (final c in cats)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) => setState(() => categoryId = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: pickFrom,
                        icon: const Icon(Icons.event_outlined),
                        label: Text(
                          from == null
                              ? 'Từ ngày'
                              : 'Từ: ${from!.day}/${from!.month}/${from!.year}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: pickTo,
                        icon: const Icon(Icons.event_available_outlined),
                        label: Text(
                          to == null
                              ? 'Đến ngày'
                              : 'Đến: ${to!.day}/${to!.month}/${to!.year}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        vm.resetFilters();
                      },
                      child: const Text('Reset'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        vm.setKeyword(_searchCtrl.text);
                        vm.setTypeFilter(type);
                        vm.setCategoryIdFilter(categoryId);
                        vm.setDateRange(from: from, to: to);
                        vm.load();
                      },
                      child: const Text('Áp dụng'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(TransactionsViewModel vm, String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá giao dịch?'),
        content: const Text('Thao tác này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      try {
        await vm.delete(id);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(transactionsViewModelProvider);
    final csvVm = ref.watch(transactionsCsvViewModelProvider);

    if (!_csvHooked) {
      _csvHooked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Warm up categories for filter + CSV mapping.
        await ref.read(transactionsViewModelProvider).ensureMetaLoaded();
      });
    }

    ref.listen(transactionsViewModelProvider, (prev, next) {
      final err = next.loadError;
      if (err == null) return;
      if (prev?.loadError == err) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được giao dịch: $err')),
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giao dịch'),
        actions: [
          IconButton(
            tooltip: 'Chọn tháng',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () => _pickMonth(vm),
          ),
          IconButton(
            tooltip: 'Lọc / tìm kiếm',
            icon: const Icon(Icons.filter_list_outlined),
            onPressed: () => _openFilters(vm),
          ),
          PopupMenuButton<String>(
            tooltip: 'Thêm',
            onSelected: (v) async {
              final messenger = ScaffoldMessenger.of(context);
              if (v == 'export') {
                final from = vm.from ?? vm.month;
                final to = vm.to ?? (vm.usingDateRange ? from : lastDayOfMonth(vm.month));
                try {
                  final file = await ref.read(transactionsCsvViewModelProvider).exportCsv(
                        from: from,
                        to: to,
                        type: vm.typeFilter,
                        categoryId: vm.categoryIdFilter,
                        keyword: vm.keyword,
                      );
                  await ref.read(transactionsCsvViewModelProvider).shareFile(file);
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
              if (v == 'import') {
                try {
                  final r = await ref.read(transactionsCsvViewModelProvider).importCsv();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Import xong: ${r.ok} dòng OK, ${r.failed} dòng lỗi'),
                    ),
                  );
                  ref.read(transactionsViewModelProvider).load();
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'export',
                enabled: !csvVm.busy,
                child: const Text('Export CSV'),
              ),
              PopupMenuItem(
                value: 'import',
                enabled: !csvVm.busy,
                child: const Text('Import CSV'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
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
                  child: Center(
                    child: Text(
                      monthLabelVi(vm.month),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
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
          ),
          if (vm.typeFilter != null ||
              vm.categoryIdFilter != null ||
              vm.keyword.isNotEmpty ||
              vm.usingDateRange)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (vm.typeFilter != null)
                    InputChip(
                      label: Text(vm.typeFilter == 'income' ? 'Thu' : 'Chi'),
                      onDeleted: () {
                        vm.setTypeFilter(null);
                        vm.load();
                      },
                    ),
                  if (vm.categoryIdFilter != null)
                    InputChip(
                      label: Text(_categoryNameById(vm, vm.categoryIdFilter!)),
                      onDeleted: () {
                        vm.setCategoryIdFilter(null);
                        vm.load();
                      },
                    ),
                  if (vm.keyword.isNotEmpty)
                    InputChip(
                      label: Text('“${vm.keyword}”'),
                      onDeleted: () {
                        vm.setKeyword('');
                        vm.load();
                      },
                    ),
                  if (vm.usingDateRange)
                    InputChip(
                      label: Text(
                        'Ngày: '
                        '${vm.from != null ? '${vm.from!.day}/${vm.from!.month}' : '…'}'
                        ' → '
                        '${vm.to != null ? '${vm.to!.day}/${vm.to!.month}' : '…'}',
                      ),
                      onDeleted: () {
                        vm.setDateRange(from: null, to: null);
                      },
                    ),
                  ActionChip(
                    label: const Text('Reset'),
                    onPressed: vm.resetFilters,
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: vm.load,
              child: vm.loading && vm.items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        Center(child: CircularProgressIndicator()),
                      ],
                    )
                  : vm.items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          children: [
                            if (vm.loadError != null) ...[
                              InlineErrorCard(
                                message: vm.loadError!,
                                onRetry: vm.load,
                              ),
                              const SizedBox(height: 16),
                            ],
                            Text(
                              vm.typeFilter != null ||
                                      vm.categoryIdFilter != null ||
                                      vm.keyword.isNotEmpty ||
                                      vm.usingDateRange
                                  ? 'Không có giao dịch phù hợp bộ lọc.'
                                  : 'Chưa có giao dịch trong ${monthLabelVi(vm.month)}.',
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      : ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 88),
                          itemCount: vm.items.length,
                          separatorBuilder: (context, _) =>
                              const SizedBox(height: 4),
                          itemBuilder: (context, i) {
                            final t = vm.items[i];
                            final isIncome = t.type == 'income';
                            final amt = formatMoneyVnd(t.amountMinor);
                            return Card(
                              child: ListTile(
                                title: Text(
                                  isIncome ? '+ $amt' : '- $amt',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isIncome
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.error,
                                  ),
                                ),
                                subtitle: Text(
                                  '${t.occurredAt.day}/${t.occurredAt.month} · '
                                  '${_categoryLabel(t)} · ${_accountLabel(t)}'
                                  '${(t.note ?? '').trim().isNotEmpty ? '\n${t.note}' : ''}',
                                ),
                                isThreeLine: (t.note ?? '').trim().isNotEmpty,
                                trailing: IconButton(
                                  tooltip: 'Xoá',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: vm.loading
                                      ? null
                                      : () => _confirmDelete(vm, t.id),
                                ),
                                onTap: () => context
                                    .push('/transactions/edit/${t.id}')
                                    .then((_) {
                                  if (!mounted) return;
                                  ref.read(transactionsViewModelProvider).load();
                                }),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/new').then((_) {
          if (!mounted) return;
          ref.read(transactionsViewModelProvider).load();
        }),
        child: const Icon(Icons.add),
      ),
    );
  }
}
