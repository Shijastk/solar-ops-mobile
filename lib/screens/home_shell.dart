import 'package:flutter/material.dart';

import '../app_controller.dart';
import 'bills_screen.dart';
import 'dashboard_screen.dart';
import 'dispatch_screen.dart';
import 'profile_screen.dart';
import 'stock_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.controller,
    required this.isDark,
    required this.onToggleTheme,
  });

  final AppController controller;
  final bool isDark;
  final VoidCallback onToggleTheme;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  void _select(int index) {
    if (_index != index) setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        controller: widget.controller,
        onOpenBills: () => _select(1),
      ),
      BillsScreen(controller: widget.controller),
      DispatchScreen(controller: widget.controller),
      StockScreen(controller: widget.controller),
      ProfileScreen(
        controller: widget.controller,
        isDark: widget.isDark,
        onToggleTheme: widget.onToggleTheme,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: _index, children: screens),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Bills',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping_rounded),
            label: 'Dispatch',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
