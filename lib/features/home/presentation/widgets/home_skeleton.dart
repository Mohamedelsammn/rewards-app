import 'package:flutter/material.dart';

import '../../../../core/widgets/skeleton.dart';
import '../../../giveaways/presentation/widgets/giveaway_grid_skeleton.dart';

/// Placeholder for the Home feed while `GET /home` loads. Mirrors the real
/// sections (section title, category rail of [CategoryTile]s, giveaway
/// grid) with the same paddings and sizes, so nothing jumps when the data
/// arrives. The header above it stays live.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Skeleton(
    child: Column(
      key: const ValueKey('home-skeleton'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(width: 190),
        // Category rail: 93x93 tiles with a title and a subtitle line.
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, _) => const SizedBox(
              width: 93,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 93, height: 93, radius: 17),
                  SizedBox(height: 9),
                  SkeletonLine(width: 72, height: 12),
                  SizedBox(height: 6),
                  SkeletonLine(width: 54, height: 9),
                ],
              ),
            ),
          ),
        ),
        const _SectionTitle(width: 120),
        // Giveaway grid: same delegate and portrait aspect as GiveawayGrid.
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: GiveawayGridSkeleton(count: 2),
        ),
      ],
    ),
  );
}

/// Same box as [SectionHeader]: 20/14/20/10 padding around a ~22pt title.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: SkeletonLine(width: width, height: 20),
    ),
  );
}
