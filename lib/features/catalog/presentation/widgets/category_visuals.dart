import 'package:flutter/material.dart';

import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/catalog_entities.dart';

ArtworkKey? artworkKeyFor(RewardCategory category) =>
    CategoryArtwork.match('${category.name.en} ${category.name.ar}');

/// Wide category banner (Categories list). Known categories use the
/// redesign's banner art: the English banners already contain the title,
/// Arabic uses the gradient + illustration with Flutter text. A backend
/// image always wins and gets a readable text overlay.
class CategoryBanner extends StatelessWidget {
  const CategoryBanner({required this.category, required this.height, super.key});

  final RewardCategory category;
  final double height;

  @override
  Widget build(BuildContext context) {
    final key = artworkKeyFor(category);
    final hasRemote = category.imageUrl?.isNotEmpty ?? false;
    final embeddedTitle = !hasRemote && key != null && !context.isArabic;
    final colors = CategoryArtwork.gradient(key);
    return Semantics(
      button: true,
      label: category.name.of(context),
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
            if (hasRemote)
              AppImage(url: category.imageUrl, placeholderColors: colors)
            else if (embeddedTitle)
              ExcludeSemantics(child: Image.asset(CategoryArtwork.banner(key), fit: BoxFit.cover))
            else if (key != null)
              PositionedDirectional(
                end: 0,
                top: 0,
                bottom: 0,
                width: height * 1.2,
                child: Image.asset(CategoryArtwork.art(key), fit: BoxFit.cover),
              ),
            if (hasRemote)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0x99070c39), Colors.transparent]),
                ),
              ),
            if (!embeddedTitle)
              PositionedDirectional(
                start: 22,
                top: 16,
                bottom: 16,
                end: height * 1.1,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
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

/// Square tile of the Home "Available Rewards" rail.
class CategoryTile extends StatelessWidget {
  const CategoryTile({required this.category, required this.onTap, super.key});

  final RewardCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final key = artworkKeyFor(category);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: SizedBox(
        width: 93,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: AppImage(
                url: category.imageUrl,
                fallbackAsset: key == null ? null : CategoryArtwork.tile(key),
                placeholderColors: CategoryArtwork.gradient(key),
                width: 93,
                height: 93,
              ),
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
}

/// Product art: backend image, PUBG UC package art, category illustration,
/// then a gradient placeholder.
class ProductArt extends StatelessWidget {
  const ProductArt({required this.product, this.category, this.fit = BoxFit.cover, super.key});

  final Product product;
  final RewardCategory? category;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final key = category == null ? null : artworkKeyFor(category!);
    final fallback = key == ArtworkKey.pubg
        ? CategoryArtwork.pubgPackage(product.name.en) ?? CategoryArtwork.art(key!)
        : key == null
        ? null
        : CategoryArtwork.art(key);
    return AppImage(
      url: product.imageUrl,
      fallbackAsset: fallback,
      fit: fit,
      placeholderColors: CategoryArtwork.gradient(key),
    );
  }
}
