import 'package:flutter/material.dart';

import '../../../../core/widgets/skeleton.dart';

/// Placeholder for the Categories list: wide banners with the same height,
/// radius, padding and spacing as the real [CategoryBanner] rows.
class CategoriesSkeleton extends StatelessWidget {
  const CategoriesSkeleton({this.count = 5, super.key});

  final int count;

  @override
  Widget build(BuildContext context) => Skeleton(
    child: ListView.separated(
      key: const ValueKey('categories-skeleton'),
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => const SkeletonBox(height: 102, radius: 22),
    ),
  );
}
