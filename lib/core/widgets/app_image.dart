import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

/// Shows a backend image URL, falling back to bundled [fallbackAsset] and
/// finally to a gradient placeholder with [placeholderIcon]. `null` and failed
/// URLs never show a broken image.
class AppImage extends StatelessWidget {
  const AppImage({
    required this.url,
    this.fallbackAsset,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.placeholderColors = const [AppColors.tintStrong, AppColors.tint],
    this.placeholderIcon = AppIcons.gift,
    super.key,
  });

  final String? url;
  final String? fallbackAsset;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;
  final List<Color> placeholderColors;
  final IconData placeholderIcon;

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
        fadeInDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        placeholder: (_, _) => _fallback(),
        errorWidget: (_, _, _) => _fallback(),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    final asset = fallbackAsset;
    if (asset != null) {
      return Image.asset(
        asset,
        fit: fit,
        alignment: alignment,
        width: width,
        height: height,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(gradient: LinearGradient(colors: placeholderColors)),
    alignment: Alignment.center,
    child: Icon(placeholderIcon, color: AppColors.violet.withValues(alpha: .7), size: 34),
  );
}
