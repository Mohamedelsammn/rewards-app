import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/localization/localized_text.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/giveaway_entities.dart';

/// Prize art: backend image, else the matching bundled 3D render.
class GiveawayArt extends StatelessWidget {
  const GiveawayArt({
    required this.imageUrl,
    required this.title,
    this.prize = const LocalizedText(),
    this.fit = BoxFit.contain,
    super.key,
  });

  final String? imageUrl;
  final LocalizedText title;
  final LocalizedText prize;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => AppImage(
    url: imageUrl,
    fallbackAsset: GiveawayArtwork.match('${prize.matchText} ${title.matchText}'),
    fit: fit,
    placeholderColors: const [Colors.transparent, Colors.transparent],
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

/// Pastel giveaway card of the Home and Giveaways grids.
class GiveawayCard extends StatelessWidget {
  const GiveawayCard({required this.giveaway, required this.index, required this.onTap, super.key});

  final Giveaway giveaway;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(24),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.giveawayCards[index % AppColors.giveawayCards.length],
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: GiveawayArt(
                  imageUrl: giveaway.imageUrl,
                  title: giveaway.title,
                  prize: giveaway.prize,
                ),
              ),
            ),
          ),
          Text(
            giveaway.title.of(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.ink, fontSize: 15, fontWeight: FontWeight.w800),
          ),
          Text(
            giveawaySubtitle(context, giveaway),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

/// Two-column giveaway grid used inside scroll views.
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
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
    ),
    itemBuilder: (_, index) => GiveawayCard(
      giveaway: giveaways[index],
      index: index,
      onTap: () => onTap(giveaways[index]),
    ),
  );
}
