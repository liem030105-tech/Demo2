import 'package:app/core/supabase_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authViewModelProvider =
    ChangeNotifierProvider.autoDispose<AuthViewModel>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AuthViewModel(supabase: supabase);
});

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  bool _loading = false;
  bool get loading => _loading;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
      );
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (_loading == value) return;
    _loading = value;
    notifyListeners();
  }
}

