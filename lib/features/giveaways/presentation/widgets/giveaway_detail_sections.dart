import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/giveaway_entities.dart';
import '../giveaway_rules.dart';
import 'giveaway_visuals.dart';

/// Sections of the Giveaway Details screen, after design_references'
/// "Giveaway Details": a full-bleed hero, the overlapping content panel,
/// the About and Rules cards.

/// Hero geometry: the artwork runs edge to edge from the very top of the
/// screen (behind the status bar) at its own aspect (≈ 1.09:1), and the
/// content panel rises over it at 80 % of its height.
const _imageAspect = 1312 / 1199;
const _panelAt = .8;
const giveawayPanelOverlap = 30.0;

double _imageHeight(double width) => width / _imageAspect;

/// Height of the hero box (the panel overlaps its last [giveawayPanelOverlap]).
double giveawayHeroHeight(double width) => _imageHeight(width) * _panelAt + giveawayPanelOverlap;

class GiveawayHero extends StatelessWidget {
  const GiveawayHero({required this.giveaway, required this.height, super.key});

  final Giveaway giveaway;
  final double height;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          const DecoratedBox(decoration: BoxDecoration(gradient: AppGradients.giveawayHero)),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _imageHeight(width),
            child: GiveawayArt(
              imageUrl: giveaway.imageUrl,
              title: giveaway.title,
              prize: giveaway.prize,
            ),
          ),
          // Decorative gift bubble from the reference, below the back button.
          // Anchored to the image's left like the art itself (images don't
          // mirror in RTL).
          Positioned(
            left: width * .12,
            top: _imageHeight(width) * .35,
            child: const ExcludeSemantics(child: _GiftBubble()),
          ),
        ],
      ),
    );
  }
}

class _GiftBubble extends StatelessWidget {
  const _GiftBubble();

  @override
  Widget build(BuildContext context) => Container(
    width: 58,
    height: 58,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: .55),
      border: Border.all(color: Colors.white.withValues(alpha: .85), width: 1.5),
    ),
    child: const Icon(LucideIcons.gift500, color: AppColors.violet, size: 26),
  );
}

/// The large rounded panel that rises over the hero.
class GiveawayPanel extends StatelessWidget {
  const GiveawayPanel({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: AppColors.giveawayPanelOuter,
      borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
        ),
      ),
    ),
  );
}

/// Badge, title, end date, participants and organizer.
class GiveawayHeadline extends StatelessWidget {
  const GiveawayHeadline({required this.giveaway, super.key});

  final Giveaway giveaway;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const meta = TextStyle(color: AppColors.muted, fontSize: 14.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.tintStrong,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.card_giftcard_rounded, size: 17, color: AppColors.violet),
              const SizedBox(width: 6),
              Text(
                l10n.giveawayBadge,
                style: const TextStyle(
                  color: AppColors.violet,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          giveaway.title.of(context),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 27,
            height: 1.18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _Meta(icon: LucideIcons.calendarDays, text: giveawaySubtitle(context, giveaway)),
            Container(width: 1, height: 18, color: AppColors.divider),
            _Meta(icon: LucideIcons.users, text: l10n.giveawayParticipants(giveaway.participants)),
          ],
        ),
        if (giveaway.organizer.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(l10n.giveawayOrganizer(giveaway.organizer), style: meta.copyWith(fontSize: 13.5)),
        ],
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: AppColors.muted),
      const SizedBox(width: 6),
      Flexible(
        child: Text(text, style: const TextStyle(color: AppColors.muted, fontSize: 13.5)),
      ),
    ],
  );
}

/// Rounded tinted card with a round icon and a heading.
class GiveawayInfoCard extends StatelessWidget {
  const GiveawayInfoCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.background,
    required this.title,
    required this.child,
    super.key,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Color background;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.fromSTEB(14, 16, 14, 18),
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(22)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(color: iconBackground, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              child,
            ],
          ),
        ),
      ],
    ),
  );
}

class GiveawayAboutCard extends StatelessWidget {
  const GiveawayAboutCard({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) => GiveawayInfoCard(
    key: const ValueKey('giveaway-about'),
    icon: LucideIcons.gift500,
    iconColor: AppColors.violet,
    iconBackground: AppColors.giveawayAboutIcon,
    background: AppColors.giveawayAboutCard,
    title: context.l10n.giveawayAboutTitle,
    child: Text(
      text,
      style: const TextStyle(color: AppColors.giveawayBody, fontSize: 13.5, height: 1.5),
    ),
  );
}

class GiveawayRulesCard extends StatelessWidget {
  const GiveawayRulesCard({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final rules = splitGiveawayRules(text);
    return GiveawayInfoCard(
      key: const ValueKey('giveaway-rules'),
      icon: LucideIcons.fileText,
      iconColor: AppColors.giveawayRulesAccent,
      iconBackground: AppColors.giveawayRulesIcon,
      background: AppColors.giveawayRulesCard,
      title: context.l10n.giveawayRules,
      child: Column(
        children: [
          for (var i = 0; i < rules.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 2 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.giveawayRulesNumber,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: AppColors.giveawayRulesAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rules[i],
                      style: const TextStyle(
                        color: AppColors.giveawayBody,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
