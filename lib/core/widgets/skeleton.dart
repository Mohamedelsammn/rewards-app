import 'package:flutter/material.dart';

import '../localization/l10n.dart';
import '../theme/app_colors.dart';

/// Shimmering placeholder group. One animation drives a single shader sweep
/// across every [SkeletonBox] below it, so a whole page of placeholders
/// costs one controller and one repaint boundary. Honors reduced motion.
class Skeleton extends StatefulWidget {
  const Skeleton({required this.child, super.key});

  final Widget child;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    // One announcement for the whole placeholder group.
    label: context.l10n.commonLoading,
    excludeSemantics: true,
    child: RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        child: widget.child,
        builder: (context, child) => ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            // A soft highlight band travels from start to end.
            final travel = bounds.width * 2.4;
            final dx = -bounds.width * 1.2 + travel * _controller.value;
            final rtl = Directionality.of(context) == TextDirection.rtl;
            return LinearGradient(
              begin: rtl ? Alignment.centerRight : Alignment.centerLeft,
              end: rtl ? Alignment.centerLeft : Alignment.centerRight,
              colors: const [
                AppColors.skeletonBase,
                AppColors.skeletonHighlight,
                AppColors.skeletonBase,
              ],
              stops: const [.35, .5, .65],
              transform: _SlideGradient(rtl ? -dx : dx),
            ).createShader(Offset.zero & bounds.size);
          },
          child: child,
        ),
      ),
    ),
  );
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient(this.dx);

  final double dx;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(dx, 0, 0);
}

/// A placeholder shape. Inside a [Skeleton] it shimmers; on its own it is a
/// static block in [AppColors.skeletonBase].
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({this.width, this.height, this.radius = 12, this.circle = false, super.key});

  final double? width;
  final double? height;
  final double radius;
  final bool circle;

  /// A missing [width] or [height] fills the available bounded space (so a
  /// box stretches in a start-aligned column or an [Expanded] slot).
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SizedBox(
      width: width ?? (constraints.hasBoundedWidth ? constraints.maxWidth : 0),
      height: height ?? (constraints.hasBoundedHeight ? constraints.maxHeight : 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.skeletonBase,
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(radius),
        ),
      ),
    ),
  );
}

/// A text-line placeholder (rounded, shorter than the line height).
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({required this.width, this.height = 12, super.key});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) =>
      SkeletonBox(width: width, height: height, radius: height / 2);
}

/// One list-row placeholder: a leading image/icon block, text lines and an
/// optional trailing block. Screens pass their real card's dimensions so
/// each list keeps its own shape.
class SkeletonRow extends StatelessWidget {
  const SkeletonRow({
    this.leadingSize = 52,
    this.leadingRadius = 16,
    this.lines = const [160, 100],
    this.lineHeight = 13,
    this.trailingWidth,
    this.trailingHeight = 16,
    this.padding = const EdgeInsets.all(14),
    super.key,
  });

  final double leadingSize;
  final double leadingRadius;

  /// Widths of the text lines, top to bottom (the first is drawn taller).
  final List<double> lines;
  final double lineHeight;
  final double? trailingWidth;
  final double trailingHeight;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Row(
      children: [
        if (leadingSize > 0) ...[
          SkeletonBox(width: leadingSize, height: leadingSize, radius: leadingRadius),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < lines.length; i++) ...[
                if (i > 0) const SizedBox(height: 9),
                // Lines never exceed the row; long ones shrink on small screens.
                LayoutBuilder(
                  builder: (context, constraints) => SkeletonLine(
                    width: lines[i].clamp(0, constraints.maxWidth).toDouble(),
                    height: i == 0 ? lineHeight + 3 : lineHeight,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailingWidth != null) ...[
          const SizedBox(width: 12),
          SkeletonLine(width: trailingWidth!, height: trailingHeight),
        ],
      ],
    ),
  );
}

/// [count] shimmering [row]s separated by [spacing], inside one [Skeleton].
class SkeletonList extends StatelessWidget {
  const SkeletonList({required this.row, this.count = 6, this.spacing = 12, super.key});

  final Widget row;
  final int count;
  final double spacing;

  @override
  Widget build(BuildContext context) => Skeleton(
    child: Column(
      key: const ValueKey('list-skeleton'),
      children: [
        for (var i = 0; i < count; i++) ...[if (i > 0) SizedBox(height: spacing), row],
      ],
    ),
  );
}
