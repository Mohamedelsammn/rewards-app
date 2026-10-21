import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/catalog_entities.dart';
import 'category_visuals.dart';

/// Product tile of the category grid (art, name, price, Redeem).
class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    required this.onRedeem,
    this.category,
    this.busy = false,
    super.key,
  });

  final Product product;
  final RewardCategory? category;
  final VoidCallback onRedeem;
  final bool busy;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: AppShadows.productCard,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.tintStrong,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ProductArt(product: product, category: category),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          product.name.of(context),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.ink, fontSize: 17, fontWeight: FontWeight.w800),
        ),
        Text(
          context.l10n.pointsAmount(Formatters.points(product.pointsPrice)),
          style: const TextStyle(
            color: AppColors.violet,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: busy || !product.inStock ? null : onRedeem,
            child: Text(
              product.inStock ? context.l10n.productRedeem : context.l10n.productOutOfStock,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    ),
  );
}
