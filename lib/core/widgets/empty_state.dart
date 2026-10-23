import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Illustrated empty state: a gradient icon tile on a soft lavender halo
/// with sparkles, a title and a short message. Sits directly on the page
/// background (no card) and centers itself in the available width.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.accent = Icons.auto_awesome,
    this.action,
    this.padding = const EdgeInsets.fromLTRB(32, 36, 32, 24),
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  /// Small decorative glyph orbiting the tile (sparkle by default).
  final IconData accent;
  final Widget? action;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: _Illustration(icon: icon, accent: accent),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 15, height: 1.5),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    ),
  );
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.icon, required this.accent});

  final IconData icon;
  final IconData accent;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 168,
    height: 150,
    child: Stack(
      alignment: Alignment.center,
      children: [
        // Halo
        Container(
          width: 150,
          height: 150,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [AppColors.emptyHalo, AppColors.emptyHaloEdge]),
          ),
        ),
        // Tilted back card for depth
        Transform.rotate(
          angle: -.2,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .75),
              borderRadius: BorderRadius.circular(26),
            ),
          ),
        ),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppGradients.emptyIcon,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(color: Color(0x406b4dff), blurRadius: 24, offset: Offset(0, 12)),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 38),
        ),
        PositionedDirectional(
          top: 18,
          end: 22,
          child: Icon(accent, color: AppColors.violet, size: 20),
        ),
        const PositionedDirectional(
          bottom: 24,
          start: 20,
          child: Icon(Icons.auto_awesome, color: AppColors.star, size: 18),
        ),
        const PositionedDirectional(
          top: 40,
          start: 24,
          child: _Dot(size: 8, color: Color(0xffc7b8ff)),
        ),
        const PositionedDirectional(
          bottom: 30,
          end: 28,
          child: _Dot(size: 6, color: Color(0xfff3a6dc)),
        ),
      ],
    ),
  );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
