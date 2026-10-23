import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/localization/l10n.dart';
import '../../core/theme/app_colors.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/bloc/session_cubit.dart';
import '../../features/profile/presentation/widgets/character_avatar.dart';
import 'nav_glyph.dart';

/// The four-tab bar from design_references/home-page.png: a compact strip
/// sitting just above the gesture inset, painted [NavGlyph]s, and the
/// user's character as the Profile tab (labelled only while selected).
class AppBottomBar extends StatelessWidget {
  const AppBottomBar({required this.currentIndex, required this.onSelect, super.key});

  final int currentIndex;
  final ValueChanged<int> onSelect;

  /// Height above the system gesture inset; labels end at the inset, as
  /// in the reference, so nothing reaches the gesture handle.
  static const height = 61.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.select<SessionCubit, AppUser?>((cubit) => cubit.state.user);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.navBackground,
        border: Border(top: BorderSide(color: AppColors.navBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              _GlyphTab(
                kind: NavGlyphKind.home,
                label: l10n.navHome,
                selected: currentIndex == 0,
                onTap: () => onSelect(0),
              ),
              _GlyphTab(
                kind: NavGlyphKind.categories,
                label: l10n.navCategories,
                selected: currentIndex == 1,
                onTap: () => onSelect(1),
              ),
              _GlyphTab(
                kind: NavGlyphKind.wallet,
                label: l10n.navWallet,
                selected: currentIndex == 2,
                onTap: () => onSelect(2),
              ),
              _ProfileTab(
                key: const ValueKey('nav-profile'),
                label: l10n.navProfile,
                selected: currentIndex == 3,
                user: user,
                onTap: () => onSelect(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared tap target and semantics of a tab.
class _TabFrame extends StatelessWidget {
  const _TabFrame({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: child),
    ),
  );
}

class _TabLabel extends StatelessWidget {
  const _TabLabel(this.text, {required this.selected});

  final String text;
  final bool selected;

  @override
  // Labels scale up to 1.15× so the bar keeps its measured height; page
  // content still follows the full system text scale.
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    maxScaleFactor: 1.15,
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: selected ? AppColors.violet : AppColors.navInactive,
        // Arabic glyphs render smaller at the same size.
        fontSize: context.isArabic ? 12.5 : 11.5,
        height: 1.15,
        letterSpacing: -.2,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    ),
  );
}

class _GlyphTab extends StatelessWidget {
  const _GlyphTab({
    required this.kind,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final NavGlyphKind kind;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _TabFrame(
    label: label,
    selected: selected,
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        children: [
          NavGlyph(
            kind: kind,
            selected: selected,
            color: selected ? AppColors.violet : AppColors.navInactive,
          ),
          _TabLabel(label, selected: selected),
        ],
      ),
    ),
  );
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.label,
    required this.selected,
    required this.user,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final AppUser? user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatar = Container(
      width: selected ? 34 : 40,
      height: selected ? 34 : 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.avatarRing,
        border: selected ? Border.all(color: AppColors.violet, width: 2) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: CharacterImage(
        avatarId: user?.avatarId,
        imageUrl: user?.avatarImageUrl,
        alignment: Alignment.topCenter,
      ),
    );
    return _TabFrame(
      label: label,
      selected: selected,
      onTap: onTap,
      child: selected
          ? Padding(
              padding: const EdgeInsets.only(top: 7),
              child: Column(
                children: [avatar, const SizedBox(height: 3), _TabLabel(label, selected: true)],
              ),
            )
          // As in the reference, the idle avatar stands alone, centered on
          // the icon-and-label block of the other tabs.
          : Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Center(child: avatar),
            ),
    );
  }
}
