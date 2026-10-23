import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'skeleton.dart';

/// A backend image. While it loads it shows a shimmer skeleton; when the URL
/// is missing or fails it shows a neutral placeholder. It never substitutes
/// an unrelated product picture for API content.
///
/// [designAsset] is only for art the app itself owns (e.g. the bundled
/// characters an avatar id refers to); API-driven rewards, categories and
/// giveaways must not pass one.
class AppImage extends StatelessWidget {
  const AppImage({
    required this.url,
    this.designAsset,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.radius = 0,
    this.placeholderIcon = Icons.image_outlined,
    this.cacheWidth,
    super.key,
  });

  final String? url;
  final String? designAsset;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;

  /// Corner radius of the loading skeleton (match the clip around the image).
  final double radius;
  final IconData placeholderIcon;

  /// Decode width in physical pixels for images much larger than shown
  /// (less memory and decode time; the file on disk stays the original).
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    final source = url;
    if (source != null && source.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: source,
        fit: fit,
        alignment: alignment,
        width: width,
        height: height,
        memCacheWidth: cacheWidth,
        fadeInDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        // A cached image appears at once; no placeholder flashes on refresh.
        fadeOutDuration: Duration.zero,
        placeholder: (_, _) => Skeleton(
          child: SkeletonBox(width: width, height: height, radius: radius),
        ),
        errorWidget: (_, _, _) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    final asset = designAsset;
    if (asset != null) {
      return Image.asset(
        asset,
        fit: fit,
        alignment: alignment,
        width: width,
        height: height,
        errorBuilder: (_, _, _) =>
            ImagePlaceholder(width: width, height: height, icon: placeholderIcon),
      );
    }
    return ImagePlaceholder(width: width, height: height, icon: placeholderIcon);
  }
}

/// Neutral stand-in for a missing or broken image.
class ImagePlaceholder extends StatelessWidget {
  const ImagePlaceholder({this.width, this.height, this.icon = Icons.image_outlined, super.key});

  final double? width;
  final double? height;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('image-placeholder'),
    width: width,
    height: height,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.tintStrong, AppColors.tint],
      ),
    ),
    alignment: Alignment.center,
    child: Icon(icon, color: AppColors.violet.withValues(alpha: .45), size: 32),
  );
}
