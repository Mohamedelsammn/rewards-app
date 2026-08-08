import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Consistent placeholder/error handling for every remote image in the app
/// (implementation-plan.md §29): shimmer-ish placeholder, graceful broken-
/// image fallback, disk+memory caching via cached_network_image.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({super.key, required this.url, this.fit = BoxFit.cover, this.borderRadius});

  final String? url;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;
    if (url == null || url!.isEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Container(
          color: AppColors.surfaceContainerHigh,
          child: const Center(
            child: Icon(Icons.card_giftcard_rounded, color: AppColors.outline, size: 32),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: url!,
        fit: fit,
        placeholder: (context, _) => Container(color: AppColors.surfaceContainerHigh),
        errorWidget: (context, _, _) => Container(
          color: AppColors.surfaceContainerHigh,
          child: const Center(
            child: Icon(Icons.broken_image_outlined, color: AppColors.outline, size: 32),
          ),
        ),
      ),
    );
  }
}
