import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/dashboard/view/dashboard_screen.dart';
import '../features/dashboard/viewmodel/dashboard_view_model.dart';
import '../features/records/view/record_list_screen.dart';
import '../features/settings/view/settings_screen.dart';

/// Bottom navigation shell with the three tabs. An [IndexedStack] keeps each
/// tab's scroll position and form text when the user switches tabs.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The app may stay open past midnight, so "today" is re-read on resume.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<DashboardViewModel>().refreshDay();
    }
  }

  void _select(int index) {
    if (index == 0) context.read<DashboardViewModel>().refreshDay();
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Each tab has its own ScaffoldMessenger, so its SnackBars are laid out by the
      // tab's Scaffold and move its FAB up instead of covering it.
      body: IndexedStack(
        index: _index,
        children: const [
          ScaffoldMessenger(child: DashboardScreen()),
          ScaffoldMessenger(child: RecordListScreen()),
          ScaffoldMessenger(child: SettingsScreen()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(icon: Icon(Icons.format_list_bulleted), label: 'Records'),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
