import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/routing/app_router.dart';
import 'core/supabase_providers.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_supabaseUrl.isEmpty || _supabaseAnonKey.isEmpty) {
    runApp(const MissingSupabaseConfigApp());
    return;
  }

  await Supabase.initialize(
    url: _supabaseUrl,
    anonKey: _supabaseAnonKey,
  );

  runApp(
    ProviderScope(
      overrides: [
        supabaseClientProvider.overrideWithValue(Supabase.instance.client),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = ProviderScope.containerOf(context).read(appRouterProvider);
    return MaterialApp.router(
      title: 'Expense Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3D5AFE)),
      ),
      routerConfig: router,
    );
  }
}

class MissingSupabaseConfigApp extends StatelessWidget {
  const MissingSupabaseConfigApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thiếu cấu hình Supabase',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  'Hãy chạy app với --dart-define=SUPABASE_URL=... và '
                  '--dart-define=SUPABASE_ANON_KEY=...',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
