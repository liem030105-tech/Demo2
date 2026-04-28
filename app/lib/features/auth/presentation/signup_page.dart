import 'package:app/features/auth/presentation/auth_scaffold.dart';
import 'package:app/features/auth/presentation/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final vm = ref.read(authViewModelProvider);
    try {
      await vm.signUp(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đăng ký thành công. Bạn có thể cần xác thực email.')),
      );
      context.go('/login');
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = ref.watch(authViewModelProvider);

    return AuthScaffold(
      title: 'Đăng ký',
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.newUsername],
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
              onSubmitted: (_) => vm.loading ? null : _submit(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: vm.loading ? null : _submit,
              child: vm.loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Tạo tài khoản'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: vm.loading ? null : () => context.go('/login'),
              child: const Text('Đã có tài khoản? Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}

