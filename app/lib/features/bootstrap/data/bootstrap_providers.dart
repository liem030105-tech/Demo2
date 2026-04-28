import 'package:app/core/supabase_providers.dart';
import 'package:app/features/bootstrap/data/bootstrap_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bootstrapServiceProvider = Provider<BootstrapService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return BootstrapService(supabase: supabase);
});
