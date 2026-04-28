import 'package:app/core/supabase_providers.dart';
import 'package:app/features/settings/data/profile_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileProvider = FutureProvider.autoDispose<ProfileModel?>((ref) async {
  ref.keepAlive();
  final supabase = ref.watch(supabaseClientProvider);
  final uid = supabase.auth.currentUser?.id;
  if (uid == null) return null;
  final row = await supabase
      .from('profiles')
      .select('id, display_name, currency_code')
      .eq('id', uid)
      .maybeSingle();
  if (row == null) return null;
  return ProfileModel.fromRow(Map<String, dynamic>.from(row));
});

