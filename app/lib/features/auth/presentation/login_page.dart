import 'package:app/features/auth/presentation/auth_scaffold.dart';
import 'package:app/features/auth/presentation/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
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
      await vm.signIn(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
      );
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
      title: 'Đăng nhập',
      child: AutofillGroup(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
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
                  : const Text('Đăng nhập'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: vm.loading ? null : () => context.go('/signup'),
              child: const Text('Chưa có tài khoản? Đăng ký'),
            ),
          ],
        ),
      ),
    );
  }
}

