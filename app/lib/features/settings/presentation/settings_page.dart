import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/widgets/inline_error_card.dart';
import 'settings_view_model.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _displayNameCtrl = TextEditingController();
  final _currencyCtrl = TextEditingController();
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsViewModelProvider).load();
    });
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _currencyCtrl.dispose();
    super.dispose();
  }

  void _seed(SettingsViewModel vm) {
    if (_seeded) return;
    final p = vm.profile;
    if (p == null) return;
    _seeded = true;
    _displayNameCtrl.text = p.displayName ?? '';
    _currencyCtrl.text = p.currencyCode;
  }

  Future<void> _save(SettingsViewModel vm) async {
    try {
      await vm.save(
        displayName: _displayNameCtrl.text,
        currencyCode: _currencyCtrl.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu cài đặt')),
      );
    } on SettingsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _confirmLogout(SettingsViewModel vm) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn sẽ cần đăng nhập lại để tiếp tục.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (ok == true) await vm.logout();
  }

  Future<void> _confirmDeleteData(SettingsViewModel vm) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá dữ liệu trên cloud?'),
        content: const Text(
          'Thao tác này sẽ xoá giao dịch, hoá đơn (ảnh) và các dữ liệu liên quan '
          'trên Supabase, rồi đăng xuất.\n\n'
          'Tài khoản đăng nhập (Auth) có thể vẫn tồn tại cho đến khi được xử lý '
          'theo yêu cầu qua email hỗ trợ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá dữ liệu'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await vm.deleteAllUserDataAndSignOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xoá dữ liệu và đăng xuất')),
      );
    } on SettingsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(settingsViewModelProvider);
    _seed(vm);

    ref.listen(settingsViewModelProvider, (prev, next) {
      final err = next.error;
      if (err == null) return;
      if (prev?.error == err) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được profile: $err')),
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: RefreshIndicator(
        onRefresh: vm.load,
        child: vm.loading && vm.profile == null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  if (vm.error != null) ...[
                    InlineErrorCard(
                      message: vm.error!,
                      onRetry: vm.load,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Tài khoản',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(label: 'Email', value: vm.email),
                        ],
                      ),
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
                            'Hồ sơ',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _displayNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Tên hiển thị',
                              hintText: 'Ví dụ: An',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _currencyCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Currency code',
                              hintText: 'VND',
                              helperText: 'Ví dụ: VND, USD (không để trống).',
                            ),
                            textCapitalization: TextCapitalization.characters,
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: vm.loading ? null : () => _save(vm),
                            child: const Text('Lưu'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: vm.loading ? null : () => _confirmLogout(vm),
                    icon: const Icon(Icons.logout),
                    label: const Text('Đăng xuất'),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer.withValues(
                          alpha: 0.35,
                        ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Quyền riêng tư',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Để yêu cầu xoá hoàn toàn tài khoản (Auth), gửi email tới '
                            '${SettingsViewModel.supportEmail}.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: vm.loading
                                ? null
                                : () async {
                                    await Clipboard.setData(
                                      const ClipboardData(
                                        text: SettingsViewModel.supportEmail,
                                      ),
                                    );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Đã sao chép email hỗ trợ'),
                                      ),
                                    );
                                  },
                            child: const Text('Sao chép email hỗ trợ'),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.error,
                              foregroundColor:
                                  Theme.of(context).colorScheme.onError,
                            ),
                            onPressed:
                                vm.loading ? null : () => _confirmDeleteData(vm),
                            icon: const Icon(Icons.delete_forever_outlined),
                            label: const Text('Xoá dữ liệu trên cloud'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

