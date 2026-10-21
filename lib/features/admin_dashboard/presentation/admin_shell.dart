import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../../core/theme/app_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/app_bottom_nav.dart';
import '../../admin_analysis/presentation/admin_analysis_page.dart';
import '../../admin_settings/presentation/admin_profile_page.dart';
import 'admin_dashboard_page.dart';

/// Admin bottom nav shell: Home / Analysis / Profile.
///
/// There used to be a standalone "Giveaways" destination listing every
/// campaign; it's been removed (final correction pass) -- per-campaign
/// management happens from the Home tab's "Active Campaigns" cards, each
/// with its own "View Analysis" entry into the PER-GIVEAWAY
/// `GiveawayAnalyticsPage`. The Analysis TAB here is a different, distinct
/// page: an OVERALL summary aggregated across every giveaway this admin
/// owns (see `AdminAnalysisPage` / `AdminAnalysisCubit`), not a giveaway
/// listing.
///
/// Uses the exact same [AppBottomNav] component as [UserHomeShell] -- same
/// Liquid Glass surface, same circular selected indicator, same everything.
/// Admin and User must never have visually different navigation bars.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _pages = [AdminDashboardPage(), AdminAnalysisPage(), AdminProfilePage()];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GlassScaffold(
      backgroundColor: AppColors.surface,
      // GlassScaffold renders on a CupertinoPageScaffold, which -- unlike
      // Material's Scaffold -- provides no Material ancestor. Every page
      // this shell hosts (present and future) needs one for ListTile,
      // TextField, InkWell, etc., so it's supplied once here rather than
      // patched into each individual page as those widgets turn up.
      // `transparency` keeps it invisible -- only each widget's own
      // styling should paint.
      body: Material(
        type: MaterialType.transparency,
        child: IndexedStack(index: _index, children: _pages),
      ),
      bottomBar: AppBottomNav(
        selectedIndex: _index,
        onTabSelected: (i) => setState(() => _index = i),
        items: [
          AppBottomNavItem(
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view_rounded,
            semanticLabel: l10n.navDashboard,
          ),
          AppBottomNavItem(
            icon: Icons.query_stats_outlined,
            activeIcon: Icons.query_stats_rounded,
            semanticLabel: l10n.adminAnalysisTitle,
          ),
          AppBottomNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            semanticLabel: l10n.adminProfileTitle,
          ),
        ],
      ),
    );
  }
}
