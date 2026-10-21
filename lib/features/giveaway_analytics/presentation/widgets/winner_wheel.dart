import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

/// A premium wheel-of-fortune style spinner.
///
/// IMPORTANT: this widget is a pure presentation layer -- [winningIndex]
/// (which wedge to land on) is decided by the caller BEFORE this widget is
/// even built, from the server's already-confirmed winner (see
/// `WinnerWheelOverlay`). It spins for a few seconds, decelerates naturally,
/// and stops exactly on that pre-determined wedge; it never makes the
/// selection decision itself, whether the caller's pick was random or a
/// manually targeted participant -- both cases drive this widget identically,
/// so the spin never visually reveals which mode was used.
class WinnerWheel extends StatefulWidget {
  const WinnerWheel({
    super.key,
    required this.segments,
    required this.winningIndex,
    required this.onSpinComplete,
  });

  /// Labels shown on each wedge (participation codes) -- always at least 1.
  final List<String> segments;

  /// Index into [segments] the wheel must land on.
  final int winningIndex;

  final VoidCallback onSpinComplete;

  @override
  State<WinnerWheel> createState() => _WinnerWheelState();
}

class _WinnerWheelState extends State<WinnerWheel> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  static const _spinDuration = Duration(milliseconds: 4200);
  // Full rotations before landing, purely for visual effect -- the actual
  // landing wedge is fixed regardless of how many extra turns this is.
  static const _extraTurns = 6;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _spinDuration);

    final segmentAngle = (2 * math.pi) / widget.segments.length;
    // The pointer is fixed at the top (12 o'clock). To land segment
    // [winningIndex]'s center under the pointer, rotate the wheel so that
    // segment's own center angle ends up there, after a few extra full
    // spins for visual effect.
    final targetSegmentCenter = widget.winningIndex * segmentAngle + segmentAngle / 2;
    final targetAngle = (_extraTurns * 2 * math.pi) - targetSegmentCenter;

    _rotation = Tween<double>(
      begin: 0,
      end: targetAngle,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutQuart));

    _controller.forward().whenComplete(() {
      if (mounted) widget.onSpinComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Subtle ambient glow behind the wheel.
              Container(
                width: size * 0.98,
                height: size * 0.98,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.goldAccent.withValues(alpha: 0.35),
                      blurRadius: 48,
                      spreadRadius: 6,
                    ),
                  ],
                ),
              ),
              AnimatedBuilder(
                animation: _rotation,
                builder: (context, child) => Transform.rotate(angle: _rotation.value, child: child),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 8)),
                    ],
                  ),
                  child: CustomPaint(
                    size: Size(size, size),
                    painter: _WheelPainter(segments: widget.segments),
                  ),
                ),
              ),
              // Center hub.
              Container(
                width: size * 0.16,
                height: size * 0.16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.gradientGold,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(color: AppColors.goldAccent.withValues(alpha: 0.6), blurRadius: 12),
                  ],
                ),
              ),
              // Fixed pointer at the top -- never rotates with the wheel.
              PositionedDirectional(
                top: -size * 0.03,
                child: Icon(
                  Icons.arrow_drop_down_rounded,
                  size: size * 0.16,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.segments});

  final List<String> segments;

  static const _wedgeColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.primaryContainer,
    AppColors.secondaryContainer,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = (2 * math.pi) / segments.length;

    for (var i = 0; i < segments.length; i++) {
      final startAngle = i * segmentAngle;
      final wedgePaint = Paint()..color = _wedgeColors[i % _wedgeColors.length];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        wedgePaint,
      );

      if (segments.length > 1) {
        final separatorPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..strokeWidth = 1.5;
        canvas.drawLine(
          center,
          center + Offset(math.cos(startAngle), math.sin(startAngle)) * radius,
          separatorPaint,
        );
      }

      final labelAngle = startAngle + segmentAngle / 2;
      final labelPos =
          center + Offset(math.cos(labelAngle), math.sin(labelAngle)) * (radius * 0.68);
      final textPainter = TextPainter(
        text: TextSpan(
          text: segments[i],
          style: AppTypography.labelSm.copyWith(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(labelPos.dx, labelPos.dy);
      canvas.rotate(labelAngle + math.pi / 2);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();
    }

    final rimPaint = Paint()
      ..color = AppColors.goldAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius - 2, rimPaint);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) => oldDelegate.segments != segments;
}
