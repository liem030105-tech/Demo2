import 'package:supabase_flutter/supabase_flutter.dart';

/// Inserts default accounts/categories for a new user (idempotent).
class BootstrapService {
  BootstrapService({required SupabaseClient supabase}) : _supabase = supabase;

  final SupabaseClient _supabase;

  Future<void> ensureBootstrapData() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await _ensureAccounts(userId);
    await _ensureCategories(userId);
  }

  Future<void> _ensureAccounts(String userId) async {
    const name = 'Tiền mặt';
    final existing = await _supabase
        .from('accounts')
        .select('id')
        .eq('user_id', userId)
        .eq('name', name)
        .maybeSingle();

    if (existing != null) return;

    await _supabase.from('accounts').insert({
      'user_id': userId,
      'name': name,
    });
  }

  Future<void> _ensureCategories(String userId) async {
    final defaults = <Map<String, Object?>>[
      {'name': 'Ăn uống', 'type': 'expense', 'color': '#FF7043', 'icon': 'food'},
      {'name': 'Di chuyển', 'type': 'expense', 'color': '#42A5F5', 'icon': 'transport'},
      {'name': 'Hóa đơn', 'type': 'expense', 'color': '#AB47BC', 'icon': 'bills'},
      {'name': 'Giải trí', 'type': 'expense', 'color': '#66BB6A', 'icon': 'fun'},
      {'name': 'Lương', 'type': 'income', 'color': '#26A69A', 'icon': 'salary'},
      {'name': 'Thu nhập khác', 'type': 'income', 'color': '#78909C', 'icon': 'other_income'},
    ];

    for (final row in defaults) {
      final name = row['name']! as String;
      final type = row['type']! as String;

      final existing = await _supabase
          .from('categories')
          .select('id')
          .eq('user_id', userId)
          .eq('name', name)
          .eq('type', type)
          .maybeSingle();

      if (existing != null) continue;

      await _supabase.from('categories').insert({
        'user_id': userId,
        'name': name,
        'type': type,
        'color': row['color'],
        'icon': row['icon'],
      });
    }
  }
}
