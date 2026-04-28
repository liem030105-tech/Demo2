import 'package:app/core/routing/go_router_refresh_stream.dart';
import 'package:app/core/supabase_providers.dart';
import 'package:app/features/app_shell/presentation/app_shell.dart';
import 'package:app/features/auth/presentation/login_page.dart';
import 'package:app/features/auth/presentation/signup_page.dart';
import 'package:app/features/dashboard/presentation/dashboard_page.dart';
import 'package:app/features/manage/presentation/manage_page.dart';
import 'package:app/features/reports/presentation/reports_page.dart';
import 'package:app/features/settings/presentation/settings_page.dart';
import 'package:app/features/transactions/presentation/transaction_form_page.dart';
import 'package:app/features/transactions/presentation/transactions_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final supabase = ref.watch(supabaseClientProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),
    redirect: (context, state) {
      final loggedIn = supabase.auth.currentSession != null;
      final isAuthRoute =
          state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      if (!loggedIn && !isAuthRoute) return '/login';
      if (loggedIn && isAuthRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionsPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) =>
                    const TransactionFormPage(existingId: null),
              ),
              GoRoute(
                path: 'edit/:id',
                builder: (context, state) => TransactionFormPage(
                  existingId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsPage(),
          ),
          GoRoute(
            path: '/manage',
            builder: (context, state) => const ManagePage(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
});

