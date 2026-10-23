import 'package:flutter/material.dart';

import '../../../../core/widgets/skeleton.dart';
import 'giveaway_detail_sections.dart';

/// Placeholder for Giveaway Details: hero, badge, title, metadata and the
/// About and Rules cards, laid out like the loaded screen.
class GiveawayDetailsSkeleton extends StatelessWidget {
  const GiveawayDetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final heroHeight = giveawayHeroHeight(MediaQuery.sizeOf(context).width);
    return Skeleton(
      child: SingleChildScrollView(
        key: const ValueKey('giveaway-details-skeleton'),
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SkeletonBox(height: heroHeight - giveawayPanelOverlap, radius: 0),
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 24, 28, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 104, height: 28, radius: 14),
                  SizedBox(height: 14),
                  SkeletonLine(width: 260, height: 26),
                  SizedBox(height: 10),
                  SkeletonLine(width: 180, height: 26),
                  SizedBox(height: 16),
                  SkeletonLine(width: 240, height: 14),
                  SizedBox(height: 8),
                  SkeletonLine(width: 120, height: 12),
                  SizedBox(height: 20),
                  SkeletonBox(height: 128, radius: 22),
                  SizedBox(height: 14),
                  SkeletonBox(height: 168, radius: 22),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
