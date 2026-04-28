import 'package:app/features/manage/data/account_model.dart';
import 'package:app/features/manage/data/category_model.dart';
import 'package:app/features/manage/presentation/manage_view_model.dart';
import 'package:app/core/widgets/inline_error_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ManagePage extends ConsumerStatefulWidget {
  const ManagePage({super.key});

  @override
  ConsumerState<ManagePage> createState() => _ManagePageState();
}

class _ManagePageState extends ConsumerState<ManagePage> {
  static const List<String> _categoryPaletteHex = [
    // reds / pinks
    '#EF5350',
    '#EC407A',
    '#AB47BC',
    '#7E57C2',
    // blues
    '#5C6BC0',
    '#42A5F5',
    '#29B6F6',
    '#26C6DA',
    // greens
    '#26A69A',
    '#66BB6A',
    '#9CCC65',
    '#D4E157',
    // yellows / oranges
    '#FFEE58',
    '#FFCA28',
    '#FFA726',
    '#FF7043',
    // browns / greys
    '#8D6E63',
    '#BDBDBD',
    '#78909C',
    '#607D8B',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(manageViewModelProvider).load();
    });
  }

  Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var s = hex.trim();
    if (s.startsWith('#')) s = s.substring(1);
    if (s.length == 6) s = 'FF$s';
    if (s.length != 8) return null;
    return Color(int.parse(s, radix: 16));
  }

  String _defaultCategoryColorHex(String type) =>
      type == 'income' ? '#26A69A' : '#78909C';

  Future<String?> _showCategoryColorPickerDialog(
    BuildContext dialogContext, {
    required String currentHex,
  }) {
    return showDialog<String>(
      context: dialogContext,
      builder: (pickerCtx) => AlertDialog(
        title: const Text('Chọn màu'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(pickerCtx, ''),
                icon: const Icon(Icons.format_color_reset_outlined),
                label: const Text('Màu mặc định'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _categoryPaletteHex.map((hex) {
                  return _colorSwatch(
                    hex: hex,
                    selected: currentHex == hex,
                    onTap: () => Navigator.pop(pickerCtx, hex),
                    tooltip: hex,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(pickerCtx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _colorSwatch({
    required String hex,
    required bool selected,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final c = _parseHexColor(hex) ?? Colors.transparent;
    return Tooltip(
      message: tooltip ?? hex,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.black.withValues(alpha: 0.75) : Colors.black12,
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: selected
              ? const Icon(Icons.check, size: 18, color: Colors.white)
              : null,
        ),
      ),
    );
  }

  Future<void> _snack(Object e) async {
    if (!mounted) return;
    final msg = e is ManageException ? e.message : e.toString();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _confirmDelete({
    required String title,
    required String body,
    required Future<void> Function() onConfirm,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
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
    if (ok == true) await onConfirm();
  }

  Future<void> _showAccountDialog({AccountModel? existing}) async {
    final vm = ref.read(manageViewModelProvider);
    final controller = TextEditingController(text: existing?.name ?? '');
    try {
      final formKey = GlobalKey<FormState>();
      final saved = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(existing == null ? 'Thêm tài khoản' : 'Đổi tên tài khoản'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Tên'),
              autofocus: true,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Không được để trống';
                return null;
              },
              onFieldSubmitted: (_) {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx, true);
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      );
      if (saved != true || !mounted) return;
      try {
        if (existing == null) {
          await vm.addAccount(controller.text);
        } else {
          await vm.renameAccount(existing.id, controller.text);
        }
      } catch (e) {
        await _snack(e);
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _showCategoryDialog({
    CategoryModel? existing,
    String? initialType,
  }) async {
    final vm = ref.read(manageViewModelProvider);
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final colorCtrl = TextEditingController(text: existing?.color ?? '');
    final iconCtrl = TextEditingController(text: existing?.icon ?? '');
    var type = existing?.type ?? initialType ?? vm.categoryTypeFilter;
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Thêm danh mục' : 'Sửa danh mục'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'expense', label: Text('Chi')),
                      ButtonSegment(value: 'income', label: Text('Thu')),
                    ],
                    selected: {type},
                    onSelectionChanged: (Set<String> s) {
                      setLocal(() => type = s.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Tên'),
                    autofocus: existing == null,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Không được để trống';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Màu',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.palette_outlined),
                        label: const Text('Chọn màu'),
                        onPressed: () async {
                          final picked = await _showCategoryColorPickerDialog(
                            context,
                            currentHex: colorCtrl.text.trim(),
                          );
                          if (picked == null) return;
                          setLocal(() {
                            colorCtrl.text = picked;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: _parseHexColor(colorCtrl.text.trim()) ??
                                    _parseHexColor(_defaultCategoryColorHex(type)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.black12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              colorCtrl.text.trim().isEmpty
                                  ? 'Màu mặc định (${_defaultCategoryColorHex(type)})'
                                  : 'Đã chọn: ${colorCtrl.text.trim()}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: iconCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Icon key (tuỳ chọn)',
                      hintText: 'food',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    if (saved == true && mounted) {
      try {
        if (existing == null) {
          await vm.addCategory(
            rawName: nameCtrl.text,
            type: type,
            color: colorCtrl.text,
            icon: iconCtrl.text,
          );
        } else {
          await vm.updateCategory(
            id: existing.id,
            rawName: nameCtrl.text,
            type: type,
            color: colorCtrl.text,
            icon: iconCtrl.text,
          );
        }
      } catch (e) {
        await _snack(e);
      }
    }
    nameCtrl.dispose();
    colorCtrl.dispose();
    iconCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(manageViewModelProvider);

    ref.listen(manageViewModelProvider, (prev, next) {
      final err = next.loadError;
      if (err == null) return;
      if (prev?.loadError == err) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được dữ liệu: $err')),
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý')),
      body: RefreshIndicator(
        onRefresh: vm.load,
        child: vm.loading && vm.accounts.isEmpty && vm.categories.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (vm.loadError != null) ...[
                    InlineErrorCard(
                      message: vm.loadError!,
                      onRetry: vm.load,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    'Tài khoản',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  if (vm.accounts.isEmpty)
                    Text(
                      'Chưa có tài khoản.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    )
                  else
                    ...vm.accounts.map(
                      (a) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(a.name),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Đổi tên',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showAccountDialog(existing: a),
                              ),
                              IconButton(
                                tooltip: 'Xoá',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _confirmDelete(
                                  title: 'Xoá tài khoản?',
                                  body:
                                      'Giao dịch dùng tài khoản này có thể bị gỡ liên kết tài khoản.',
                                  onConfirm: () async {
                                    try {
                                      await vm.deleteAccount(a.id);
                                    } catch (e) {
                                      await _snack(e);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonalIcon(
                      onPressed: vm.loading ? null : () => _showAccountDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm tài khoản'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Danh mục',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'expense', label: Text('Chi')),
                      ButtonSegment(value: 'income', label: Text('Thu')),
                    ],
                    selected: {vm.categoryTypeFilter},
                    onSelectionChanged: (s) {
                      vm.setCategoryTypeFilter(s.first);
                    },
                  ),
                  const SizedBox(height: 12),
                  if (vm.filteredCategories.isEmpty)
                    Text(
                      'Chưa có danh mục cho loại này.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    )
                  else
                    ...vm.filteredCategories.map(
                      (c) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _parseHexColor(c.color) ??
                                Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: Icon(
                              c.type == 'income'
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              color: _parseHexColor(c.color) != null
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                          title: Text(c.name),
                          subtitle: Text(
                            '${c.type == 'income' ? 'Thu' : 'Chi'}'
                            '${(c.icon ?? '').isNotEmpty ? ' · ${c.icon}' : ''}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Sửa',
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showCategoryDialog(existing: c),
                              ),
                              IconButton(
                                tooltip: 'Xoá',
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _confirmDelete(
                                  title: 'Xoá danh mục?',
                                  body:
                                      'Danh mục sẽ bị xoá; giao dịch liên quan có thể mất liên kết danh mục.',
                                  onConfirm: () async {
                                    try {
                                      await vm.deleteCategory(c.id);
                                    } catch (e) {
                                      await _snack(e);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonalIcon(
                      onPressed: vm.loading
                          ? null
                          : () => _showCategoryDialog(
                                initialType: vm.categoryTypeFilter,
                              ),
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm danh mục'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
