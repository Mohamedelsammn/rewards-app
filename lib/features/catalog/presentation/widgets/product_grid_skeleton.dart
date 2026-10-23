import 'package:flutter/material.dart';

import '../../../../core/widgets/skeleton.dart';

/// Placeholder for the Category Details product grid: image, name, price
/// and the Redeem pill, with the grid's real delegate.
class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({this.count = 4, super.key});

  final int count;

  @override
  Widget build(BuildContext context) => Skeleton(
    child: GridView.builder(
      key: const ValueKey('product-grid-skeleton'),
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: .68,
      ),
      itemBuilder: (_, _) => const Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: SkeletonBox(radius: 18)),
            SizedBox(height: 12),
            SkeletonLine(width: 86, height: 15),
            SizedBox(height: 8),
            SkeletonLine(width: 64, height: 13),
            SizedBox(height: 12),
            SkeletonBox(height: 40, radius: 20),
          ],
        ),
      ),
    ),
  );
}
