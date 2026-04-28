import 'package:app/features/manage/data/account_model.dart';
import 'package:app/features/manage/data/category_model.dart';
import 'package:app/features/transactions/presentation/transaction_form_view_model.dart';
import 'package:app/features/transactions/presentation/transaction_receipts_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TransactionFormPage extends ConsumerStatefulWidget {
  const TransactionFormPage({super.key, this.existingId});

  /// `null` = tạo mới; ngược lại = id giao dịch cần sửa.
  final String? existingId;

  @override
  ConsumerState<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends ConsumerState<TransactionFormPage> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _type = 'expense';
  DateTime _occurred = DateTime.now();
  String? _accountId;
  String? _categoryId;
  String? _paymentMethod;
  bool _seeded = false;
  bool _initStarted = false;
  String? _receiptsForId;

  @override
  void didUpdateWidget(covariant TransactionFormPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.existingId != widget.existingId) {
      _initStarted = false;
      _seeded = false;
      _receiptsForId = null;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _seed(TransactionFormViewModel vm) {
    if (_seeded) return;
    _seeded = true;
    final e = vm.existing;
    if (e != null) {
      _type = e.type;
      _amountCtrl.text = e.amountMinor.toString();
      _noteCtrl.text = e.note ?? '';
      _occurred = DateTime(e.occurredAt.year, e.occurredAt.month, e.occurredAt.day);
      _accountId = e.accountId;
      _categoryId = e.categoryId;
      _paymentMethod = e.paymentMethod;
    } else {
      if (vm.accounts.isNotEmpty) _accountId = vm.accounts.first.id;
      final cats = vm.categoriesForType(_type);
      if (cats.isNotEmpty) _categoryId = cats.first.id;
    }
  }

  void _ensureCategoryValid(TransactionFormViewModel vm) {
    final cats = vm.categoriesForType(_type);
    if (_categoryId != null && cats.any((c) => c.id == _categoryId)) return;
    _categoryId = cats.isNotEmpty ? cats.first.id : null;
  }

  void _ensureAccountValid(TransactionFormViewModel vm) {
    if (_accountId != null && vm.accounts.any((a) => a.id == _accountId)) return;
    _accountId = vm.accounts.isNotEmpty ? vm.accounts.first.id : null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _occurred,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _occurred = picked);
  }

  Future<void> _save(TransactionFormViewModel vm) async {
    final digits = _amountCtrl.text.replaceAll(RegExp(r'\D'), '');
    final amount = int.tryParse(digits);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập số tiền hợp lệ (số nguyên > 0).')),
      );
      return;
    }
    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn tài khoản.')),
      );
      return;
    }
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chọn danh mục.')),
      );
      return;
    }
    try {
      await vm.save(
        type: _type,
        amountMinor: amount,
        occurredAt: _occurred,
        accountId: _accountId!,
        categoryId: _categoryId!,
        note: _noteCtrl.text,
        paymentMethod: _paymentMethod,
      );
      if (mounted) context.pop();
    } on TransactionFormException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(transactionFormViewModelProvider(widget.existingId));
    final receiptsVm = widget.existingId == null
        ? null
        : ref.watch(transactionReceiptsViewModelProvider(widget.existingId!));

    if (!_initStarted) {
      _initStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final m = ref.read(transactionFormViewModelProvider(widget.existingId));
        await m.init();
        if (!mounted) return;
        _seed(m);
        _ensureAccountValid(m);
        _ensureCategoryValid(m);
        setState(() {});
      });
    }

    final rid = widget.existingId;
    if (rid != null && _receiptsForId != rid) {
      _receiptsForId = rid;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(transactionReceiptsViewModelProvider(rid)).load();
      });
    }

    ref.listen(transactionFormViewModelProvider(widget.existingId), (prev, next) {
      if (prev?.loadError == next.loadError) return;
      final err = next.loadError;
      if (err == null) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(vm.isEdit ? 'Sửa giao dịch' : 'Thêm giao dịch'),
        actions: [
          if (!vm.loading && vm.loadError == null)
            TextButton(
              onPressed: () => _save(vm),
              child: const Text('Lưu'),
            ),
        ],
      ),
      body: vm.loading && !_seeded
          ? const Center(child: CircularProgressIndicator())
          : vm.loadError != null && vm.accounts.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(vm.loadError!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.pop(),
                          child: const Text('Quay lại'),
                        ),
                      ],
                    ),
                  ),
                )
              : vm.accounts.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Chưa có tài khoản. Hãy tạo tài khoản ở mục Quản lý.'),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'expense', label: Text('Chi')),
                            ButtonSegment(value: 'income', label: Text('Thu')),
                          ],
                          selected: {_type},
                          onSelectionChanged: (s) {
                            setState(() {
                              _type = s.first;
                              _ensureCategoryValid(vm);
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _amountCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Số tiền (đồng)',
                            hintText: 'Ví dụ: 50000',
                            helperText: 'Số nguyên — VND lưu theo đồng (minor units).',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Ngày'),
                          subtitle: Text(
                            '${_occurred.day}/${_occurred.month}/${_occurred.year}',
                          ),
                          trailing: const Icon(Icons.calendar_today_outlined),
                          onTap: _pickDate,
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          // Controlled selection; `initialValue` chỉ gắn một lần.
                          // ignore: deprecated_member_use
                          value: _accountId,
                          decoration: const InputDecoration(labelText: 'Tài khoản'),
                          items: [
                            for (final AccountModel a in vm.accounts)
                              DropdownMenuItem(value: a.id, child: Text(a.name)),
                          ],
                          onChanged: (v) => setState(() => _accountId = v),
                        ),
                        const SizedBox(height: 12),
                        Builder(
                          builder: (context) {
                            final cats = vm.categoriesForType(_type);
                            if (cats.isEmpty) {
                              return const Text(
                                'Chưa có danh mục cho loại này. Thêm ở Quản lý.',
                              );
                            }
                            return DropdownButtonFormField<String>(
                              // ignore: deprecated_member_use
                              value: _categoryId,
                              decoration: const InputDecoration(labelText: 'Danh mục'),
                              items: [
                                for (final CategoryModel c in cats)
                                  DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  ),
                              ],
                              onChanged: (v) => setState(() => _categoryId = v),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          // ignore: deprecated_member_use
                          value: _paymentMethod,
                          decoration: const InputDecoration(
                            labelText: 'Phương thức thanh toán',
                          ),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('—')),
                            DropdownMenuItem(value: 'cash', child: Text('Tiền mặt')),
                            DropdownMenuItem(value: 'card', child: Text('Thẻ')),
                            DropdownMenuItem(
                              value: 'bank_transfer',
                              child: Text('Chuyển khoản'),
                            ),
                            DropdownMenuItem(
                              value: 'ewallet',
                              child: Text('Ví điện tử'),
                            ),
                          ],
                          onChanged: (v) => setState(() => _paymentMethod = v),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _noteCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Ghi chú (tuỳ chọn)',
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                        if (widget.existingId != null) ...[
                          Text(
                            'Hoá đơn',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (receiptsVm != null &&
                              receiptsVm.loading &&
                              receiptsVm.items.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (receiptsVm != null && receiptsVm.items.isEmpty)
                            Text(
                              'Chưa có ảnh hoá đơn.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                            )
                          else if (receiptsVm != null)
                            SizedBox(
                              height: 96,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: receiptsVm.items.length,
                                separatorBuilder: (context, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, i) {
                                  final it = receiptsVm.items[i];
                                  return Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: AspectRatio(
                                          aspectRatio: 1,
                                          child: Image.network(
                                            it.signedUrl,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: IconButton(
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.black54,
                                            foregroundColor: Colors.white,
                                          ),
                                          tooltip: 'Xoá ảnh',
                                          icon: const Icon(Icons.close, size: 18),
                                          onPressed: () async {
                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            final ok = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title:
                                                    const Text('Xoá ảnh hoá đơn?'),
                                                content: const Text(
                                                  'Thao tác này không thể hoàn tác.',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(ctx, false),
                                                    child: const Text('Huỷ'),
                                                  ),
                                                  FilledButton(
                                                    onPressed: () =>
                                                        Navigator.pop(ctx, true),
                                                    child: const Text('Xoá'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (ok != true) return;
                                            try {
                                              await ref
                                                  .read(
                                                    transactionReceiptsViewModelProvider(
                                                      widget.existingId!,
                                                    ),
                                                  )
                                                  .deleteReceipt(it.model);
                                            } catch (e) {
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(e.toString()),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 8),
                          FilledButton.tonalIcon(
                            onPressed: receiptsVm?.loading == true
                                ? null
                                : () async {
                                    final messenger =
                                        ScaffoldMessenger.of(context);
                                    try {
                                      await ref
                                          .read(
                                            transactionReceiptsViewModelProvider(
                                              widget.existingId!,
                                            ),
                                          )
                                          .pickAndUpload();
                                    } catch (e) {
                                      messenger.showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.add_a_photo_outlined),
                            label: const Text('Thêm ảnh hoá đơn'),
                          ),
                          const SizedBox(height: 24),
                        ],
                        FilledButton(
                          onPressed: () => _save(vm),
                          child: const Text('Lưu'),
                        ),
                      ],
                    ),
    );
  }
}
