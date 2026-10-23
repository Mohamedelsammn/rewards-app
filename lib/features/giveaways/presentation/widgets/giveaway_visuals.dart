import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/localized_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/giveaway_entities.dart';

/// The giveaway's backend image; a neutral placeholder when it is missing
/// or fails (never a bundled prize render).
class GiveawayArt extends StatelessWidget {
  const GiveawayArt({
    required this.imageUrl,
    required this.title,
    this.prize = const LocalizedText(),
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.radius = 0,
    super.key,
  });

  final String? imageUrl;

  /// Kept for callers (semantics/context); the art never depends on them.
  final LocalizedText title;
  final LocalizedText prize;
  final BoxFit fit;
  final Alignment alignment;
  final double radius;

  @override
  Widget build(BuildContext context) => AppImage(
    url: imageUrl,
    fit: fit,
    alignment: alignment,
    radius: radius,
    placeholderIcon: Icons.card_giftcard_rounded,
  );
}

/// "Ends Oct 22", "Starts Nov 1", "Ended", … for a giveaway.
String giveawaySubtitle(BuildContext context, Giveaway giveaway) {
  final l10n = context.l10n;
  return switch (giveaway.status) {
    GiveawayStatus.upcoming =>
      giveaway.startsAt == null
          ? l10n.giveawayUpcoming
          : l10n.giveawayStartsOn(Formatters.date(context, giveaway.startsAt!)),
    GiveawayStatus.active =>
      giveaway.endsAt == null
          ? l10n.giveawayAvailable
          : l10n.giveawayEndsOn(Formatters.date(context, giveaway.endsAt!)),
    GiveawayStatus.winnersSelected || GiveawayStatus.completed => l10n.giveawayWinnersSelected,
    GiveawayStatus.cancelled => l10n.giveawayCancelled,
    GiveawayStatus.ended => l10n.giveawayEnded,
  };
}

/// Portrait giveaway card of the Home and Giveaways grids: the backend image
/// fills the card (`BoxFit.cover`) with the title and end date on a soft
/// bottom gradient.
class GiveawayCard extends StatelessWidget {
  const GiveawayCard({required this.giveaway, required this.index, required this.onTap, super.key});

  final Giveaway giveaway;

  /// Position in the grid (kept for callers).
  final int index;
  final VoidCallback onTap;

  static const radius = 24.0;

  @override
  Widget build(BuildContext context) {
    final title = giveaway.title.of(context);
    final subtitle = giveawaySubtitle(context, giveaway);
    return Semantics(
      button: true,
      label: '$title, $subtitle',
      excludeSemantics: true,
      child: Material(
        color: AppColors.tint,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              GiveawayArt(
                imageUrl: giveaway.imageUrl,
                title: giveaway.title,
                prize: giveaway.prize,
                radius: radius,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(gradient: AppGradients.giveawayCardScrim),
              ),
              PositionedDirectional(
                top: 10,
                start: 10,
                child: GiveawayStatusBadge(giveaway: giveaway),
              ),
              PositionedDirectional(
                start: 12,
                end: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What a giveaway card's badge says.
enum GiveawayBadgeState { active, comingSoon, ended, full }

/// The server's `status` decides; capacity marks an active giveaway full.
/// The end date only matters while the server still reports `ACTIVE` after
/// `endsAt` (entries are refused then with `GIVEAWAY_ENDED`).
GiveawayBadgeState giveawayBadgeState(Giveaway giveaway, {DateTime? now}) =>
    switch (giveaway.status) {
      GiveawayStatus.upcoming => GiveawayBadgeState.comingSoon,
      GiveawayStatus.active
          when giveaway.endsAt != null && !(now ?? DateTime.now()).isBefore(giveaway.endsAt!) =>
        GiveawayBadgeState.ended,
      GiveawayStatus.active when giveaway.isFull => GiveawayBadgeState.full,
      GiveawayStatus.active => GiveawayBadgeState.active,
      GiveawayStatus.ended ||
      GiveawayStatus.winnersSelected ||
      GiveawayStatus.completed ||
      GiveawayStatus.cancelled => GiveawayBadgeState.ended,
    };

/// Status pill at the top of a giveaway card: a colored dot and label on
/// the card's white pill.
class GiveawayStatusBadge extends StatelessWidget {
  const GiveawayStatusBadge({required this.giveaway, this.now, super.key});

  final Giveaway giveaway;

  /// For tests; defaults to the current time.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = giveawayBadgeState(giveaway, now: now);
    final (label, color) = switch (state) {
      GiveawayBadgeState.active => (l10n.giveawayBadgeActive, AppColors.giveawayBadgeActive),
      GiveawayBadgeState.comingSoon => (l10n.giveawayBadgeComingSoon, AppColors.giveawayBadgeSoon),
      GiveawayBadgeState.ended => (l10n.giveawayBadgeEnded, AppColors.giveawayBadgeEnded),
      GiveawayBadgeState.full => (l10n.giveawayBadgeFull, AppColors.giveawayBadgeFull),
    };
    return Container(
      key: ValueKey('giveaway-badge-${state.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Same 12 px slot the gift icon used, so the pill keeps its size.
          SizedBox.square(
            dimension: 12,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const SizedBox.square(dimension: 7),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Width / height of a [GiveawayCard] in the two-column grid.
const giveawayCardAspect = .74;

/// Two-column portrait layout of giveaway cards; keep in sync with the
/// Home/Giveaways skeletons.
const giveawayGridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
  crossAxisCount: 2,
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
  childAspectRatio: giveawayCardAspect,
);

/// Two-column giveaway grid used inside scroll views, for short lists (the
/// Home feed). Long, paginated lists use [GiveawaySliverGrid].
class GiveawayGrid extends StatelessWidget {
  const GiveawayGrid({required this.giveaways, required this.onTap, super.key});

  final List<Giveaway> giveaways;
  final ValueChanged<Giveaway> onTap;

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: EdgeInsets.zero,
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    itemCount: giveaways.length,
    gridDelegate: giveawayGridDelegate,
    itemBuilder: (_, index) => GiveawayCard(
      giveaway: giveaways[index],
      index: index,
      onTap: () => onTap(giveaways[index]),
    ),
  );
}

/// The same grid as a lazy sliver: only cards near the viewport are built
/// (and their images loaded), however many pages are loaded.
class GiveawaySliverGrid extends StatelessWidget {
  const GiveawaySliverGrid({required this.giveaways, required this.onTap, super.key});

  final List<Giveaway> giveaways;
  final ValueChanged<Giveaway> onTap;

  @override
  Widget build(BuildContext context) => SliverGrid.builder(
    itemCount: giveaways.length,
    gridDelegate: giveawayGridDelegate,
    itemBuilder: (_, index) => GiveawayCard(
      giveaway: giveaways[index],
      index: index,
      onTap: () => onTap(giveaways[index]),
    ),
  );
}
