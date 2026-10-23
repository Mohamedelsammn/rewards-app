import 'package:flutter/material.dart';

import '../../../../core/widgets/skeleton.dart';
import 'giveaway_visuals.dart';

/// Placeholder grid of portrait [GiveawayCard]s (same delegate and aspect
/// as [GiveawayGrid]). Must sit inside a [Skeleton].
class GiveawayGridSkeleton extends StatelessWidget {
  const GiveawayGridSkeleton({this.count = 4, super.key});

  final int count;

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: EdgeInsets.zero,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: count,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: giveawayCardAspect,
    ),
    itemBuilder: (_, _) => const SkeletonBox(radius: GiveawayCard.radius),
  );
}
