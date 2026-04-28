import 'package:app/core/supabase_providers.dart';
import 'package:app/features/settings/data/profile_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final settingsViewModelProvider =
    ChangeNotifierProvider.autoDispose<SettingsViewModel>((ref) {
  ref.keepAlive();
  final supabase = ref.watch(supabaseClientProvider);
  return SettingsViewModel(supabase: supabase);
});

class SettingsException implements Exception {
  SettingsException(this.message);
  final String message;

  @override
  String toString() => message;
}

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  static const supportEmail = 'liem030105@gmail.com';

  bool _loading = false;
  String? _error;
  ProfileModel? _profile;

  bool get loading => _loading;
  String? get error => _error;
  ProfileModel? get profile => _profile;

  String get email => _supabase.auth.currentUser?.email ?? '';

  Future<void> load() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final row = await _supabase
          .from('profiles')
          .select('id, display_name, currency_code')
          .eq('id', uid)
          .maybeSingle();
      if (row == null) {
        // Edge case: profile missing. Create it.
        await _supabase.from('profiles').insert({'id': uid});
        final created = await _supabase
            .from('profiles')
            .select('id, display_name, currency_code')
            .eq('id', uid)
            .single();
        _profile = ProfileModel.fromRow(Map<String, dynamic>.from(created));
      } else {
        _profile = ProfileModel.fromRow(Map<String, dynamic>.from(row));
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> save({
    required String displayName,
    required String currencyCode,
  }) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw SettingsException('Chưa đăng nhập');

    final code = currencyCode.trim();
    if (code.isEmpty) {
      throw SettingsException('currency_code không được để trống');
    }

    await _supabase.from('profiles').upsert({
      'id': uid,
      'display_name': displayName.trim().isEmpty ? null : displayName.trim(),
      'currency_code': code,
    });
    // Ensure other listeners (e.g. profileProvider) can refetch fresh data.
    await load();
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  /// Deletes app data stored in Supabase for the current user (DB rows + receipt
  /// objects in Storage), then signs out.
  ///
  /// Note: this does **not** delete the Supabase Auth user record itself (requires
  /// a privileged server operation). Users can request full account deletion via
  /// [supportEmail] (see Privacy Policy).
  Future<void> deleteAllUserDataAndSignOut() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) throw SettingsException('Chưa đăng nhập');

    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final receiptRows = await _supabase
          .from('transaction_receipts')
          .select('path')
          .eq('user_id', uid);
      final paths = (receiptRows as List<dynamic>)
          .map((e) => (e as Map)['path'] as String?)
          .whereType<String>()
          .toList();

      if (paths.isNotEmpty) {
        const chunk = 95;
        for (var i = 0; i < paths.length; i += chunk) {
          final slice = paths.sublist(
            i,
            i + chunk > paths.length ? paths.length : i + chunk,
          );
          await _supabase.storage.from('receipts').remove(slice);
        }
      }

      await _supabase.from('transaction_receipts').delete().eq('user_id', uid);
      await _supabase.from('transactions').delete().eq('user_id', uid);
      await _supabase.from('budgets').delete().eq('user_id', uid);
      await _supabase.from('accounts').delete().eq('user_id', uid);
      await _supabase.from('categories').delete().eq('user_id', uid);
      await _supabase.from('profiles').delete().eq('id', uid);

      await _supabase.auth.signOut();
    } catch (e) {
      throw SettingsException(e.toString());
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

