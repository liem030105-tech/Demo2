import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  static const _tabs = <_TabSpec>[
    _TabSpec(label: 'Home', icon: Icons.home_outlined, location: '/dashboard'),
    _TabSpec(
      label: 'Giao dịch',
      icon: Icons.receipt_long_outlined,
      location: '/transactions',
    ),
    _TabSpec(
      label: 'Báo cáo',
      icon: Icons.pie_chart_outline,
      location: '/reports',
    ),
    _TabSpec(label: 'Quản lý', icon: Icons.tune_outlined, location: '/manage'),
    _TabSpec(
      label: 'Cài đặt',
      icon: Icons.settings_outlined,
      location: '/settings',
    ),
  ];

  int _locationToIndex(String location) {
    final idx = _tabs.indexWhere((t) => location.startsWith(t.location));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (idx) => context.go(_tabs[idx].location),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({
    required this.label,
    required this.icon,
    required this.location,
  });

  final String label;
  final IconData icon;
  final String location;
}

