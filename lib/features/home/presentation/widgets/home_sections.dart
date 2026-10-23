import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../catalog/domain/entities/catalog_entities.dart';
import '../../../catalog/presentation/widgets/category_visuals.dart';
import '../../../giveaways/domain/entities/giveaway_entities.dart';
import '../../../giveaways/presentation/giveaway_navigation.dart';
import '../../../giveaways/presentation/widgets/giveaway_visuals.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.onSeeAll, super.key});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
    child: Row(
      children: [
        Expanded(child: Text(title, style: AppTypography.sectionTitle)),
        if (onSeeAll != null)
          TextButton(onPressed: onSeeAll, child: Text(context.l10n.commonSeeAll)),
      ],
    ),
  );
}

/// Horizontal "Available Rewards" rail.
class CategoryRail extends StatelessWidget {
  const CategoryRail({required this.categories, super.key});

  final List<RewardCategory> categories;

  @override
  // 93 px tile + gap, plus two text lines (~37 px at 1.0) that grow with
  // the system text scale.
  Widget build(BuildContext context) => SizedBox(
    height: 103 + 37 * (MediaQuery.textScalerOf(context).scale(14) / 14),
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: categories.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, index) => CategoryTile(
        category: categories[index],
        onTap: () => context.push(Routes.category(categories[index].id), extra: categories[index]),
      ),
    ),
  );
}

/// Featured / matching products as compact cards; tapping opens the
/// product's category where it can be redeemed.
class FeaturedProductsRow extends StatelessWidget {
  const FeaturedProductsRow({required this.products, required this.categories, super.key});

  final List<Product> products;
  final List<RewardCategory> categories;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 176,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, index) {
        final product = products[index];
        final category = categories.where((item) => item.id == product.categoryId).firstOrNull;
        return InkWell(
          onTap: () => context.push(Routes.category(product.categoryId), extra: category),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 132,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppShadows.productCard,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ProductArt(product: product, category: category),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.name.of(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800),
                ),
                Text(
                  context.l10n.pointsAmount(Formatters.points(product.pointsPrice)),
                  style: const TextStyle(
                    color: AppColors.violet,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class HomeGiveaways extends StatelessWidget {
  const HomeGiveaways({required this.giveaways, super.key});

  final List<Giveaway> giveaways;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: GiveawayGrid(
      giveaways: giveaways,
      onTap: (giveaway) => openGiveawayFromTap(context, giveaway.id),
    ),
  );
}
