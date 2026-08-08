import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../admin_giveaways/presentation/admin_giveaways_page.dart';
import '../../admin_settings/presentation/admin_profile_page.dart';
import 'admin_dashboard_page.dart';

/// Admin bottom nav shell: Dashboard / Giveaways / Profile
/// (tasks.md T13-08). "Giveaways" doubles as management + the entry point
/// into each giveaway's Analytics, since Analytics is inherently per-
/// giveaway rather than a standalone global tab.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _pages = [AdminDashboardPage(), AdminGiveawaysPage(), AdminProfilePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.surfaceContainerLowest,
        indicatorColor: AppColors.primaryContainer.withValues(alpha: 0.15),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign_rounded),
            label: 'Giveaways',
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
