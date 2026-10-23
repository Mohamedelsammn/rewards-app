import 'package:flutter/material.dart';

import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/catalog_entities.dart';

/// Brand gradient for a known category name (colors only, never artwork).
List<Color> categoryGradient(RewardCategory? category) => CategoryArtwork.gradient(
  category == null ? null : CategoryArtwork.match('${category.name.en} ${category.name.ar}'),
);

/// Wide category banner (Categories list): brand gradient, the category's
/// backend image on the trailing side and the localized title in Flutter
/// text. Backend images are square tiles, so they are shown at their own
/// shape instead of being stretched across the banner.
///
/// The backend art is a rounded tile on a light square margin (about 9 %
/// of each side). The image is scaled so the tile slightly overflows the
/// card's top, bottom and end edges (the card clips it, hiding the margin)
/// and its start edge fades into the gradient, so no light strip or seam
/// shows.
class CategoryBanner extends StatelessWidget {
  const CategoryBanner({required this.category, required this.height, super.key});

  final RewardCategory category;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = categoryGradient(category);
    final artWidth = height * 1.2;
    // Tile a little larger than the card, its end edge just past the card's.
    final tile = height + 8;
    final imageSize = tile / (1 - 2 * _artMargin);
    final overflow = (imageSize - tile) / 2;
    final direction = Directionality.of(context);
    return Semantics(
      button: true,
      label: category.name.of(context),
      excludeSemantics: true,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(colors: colors),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (category.homeImageUrl != null)
              PositionedDirectional(
                end: -overflow - 4,
                top: (height - imageSize) / 2,
                width: imageSize,
                height: imageSize,
                child: ShaderMask(
                  key: const ValueKey('category-banner-art'),
                  blendMode: BlendMode.dstIn,
                  // Transparent over the margin, then a soft fade into the tile.
                  shaderCallback: (bounds) => LinearGradient(
                    begin: AlignmentDirectional.centerStart.resolve(direction),
                    end: AlignmentDirectional.centerEnd.resolve(direction),
                    colors: const [Colors.transparent, Colors.transparent, Colors.white],
                    stops: [0, _artMargin + .02, _artMargin + .4],
                  ).createShader(bounds),
                  child: AppImage(url: category.homeImageUrl, width: imageSize, height: imageSize),
                ),
              ),
            PositionedDirectional(
              start: 22,
              top: 16,
              bottom: 16,
              end: artWidth - 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    category.name.of(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (!category.description.isEmpty)
                    Text(
                      category.description.of(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 13.5, height: 1.3),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Light margin around the tile in the backend category art (per side).
const _artMargin = .09;

/// Square tile of the Home "Available Rewards" rail.
class CategoryTile extends StatelessWidget {
  const CategoryTile({required this.category, required this.onTap, super.key});

  final RewardCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(17),
    child: SizedBox(
      width: 93,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: AppImage(url: category.homeImageUrl, width: 93, height: 93, radius: 17),
          ),
          const SizedBox(height: 5),
          Text(
            category.name.of(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          Text(
            category.description.of(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
          ),
        ],
      ),
    ),
  );
}

/// Product art: the product's backend image, else a neutral placeholder.
class ProductArt extends StatelessWidget {
  const ProductArt({required this.product, this.category, this.fit = BoxFit.cover, super.key});

  final Product product;

  /// Kept for callers; artwork never depends on the category any more.
  final RewardCategory? category;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) => AppImage(url: product.imageUrl, fit: fit);
}
