import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// `CustomPainter`-based erase canvas: dragging clears an opaque foil layer
/// via `BlendMode.clear`, revealing whatever `child` is painted beneath it
/// (implementation-plan.md §20, tasks.md T10-01/T10-02). Progress is sampled
/// on a coarse grid rather than per-pixel, and reports scratched% via
/// [onProgressChanged] on every update -- completion/threshold logic lives
/// in ScratchCardCubit, not here.
class ScratchCardWidget extends StatefulWidget {
  const ScratchCardWidget({
    super.key,
    required this.child,
    required this.onProgressChanged,
    this.isRevealed = false,
    this.gridSize = 24,
  });

  final Widget child;
  final ValueChanged<double> onProgressChanged;
  final bool isRevealed;
  final int gridSize;

  @override
  State<ScratchCardWidget> createState() => _ScratchCardWidgetState();
}

class _ScratchCardWidgetState extends State<ScratchCardWidget> with SingleTickerProviderStateMixin {
  final Path _erasePath = Path();
  late List<List<bool>> _grid;
  Size _lastSize = Size.zero;

  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _grid = List.generate(widget.gridSize, (_) => List.filled(widget.gridSize, false));
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
      value: widget.isRevealed ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant ScratchCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRevealed && !oldWidget.isRevealed) {
      _fadeController.forward();
    }
  }

  void _handleTouch(Offset localPosition, Size size) {
    if (widget.isRevealed) return;
    _lastSize = size;

    _erasePath.addOval(Rect.fromCircle(center: localPosition, radius: 28));

    final col = (localPosition.dx / size.width * widget.gridSize).floor().clamp(
      0,
      widget.gridSize - 1,
    );
    final row = (localPosition.dy / size.height * widget.gridSize).floor().clamp(
      0,
      widget.gridSize - 1,
    );
    _grid[row][col] = true;

    // Mark a small neighborhood too so a single tap/drag clears a visible patch.
    for (final dr in [-1, 0, 1]) {
      for (final dc in [-1, 0, 1]) {
        final r = row + dr, c = col + dc;
        if (r >= 0 && r < widget.gridSize && c >= 0 && c < widget.gridSize) {
          _grid[r][c] = true;
        }
      }
    }

    final scratchedCount = _grid.expand((row) => row).where((cell) => cell).length;
    final total = widget.gridSize * widget.gridSize;
    widget.onProgressChanged(scratchedCount / total);

    setState(() {});
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Positioned.fill(child: widget.child),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _fadeController,
              builder: (context, _) {
                if (_fadeController.value >= 1) return const SizedBox.shrink();
                return Opacity(
                  opacity: 1 - _fadeController.value,
                  child: GestureDetector(
                    onPanStart: (details) =>
                        _handleTouch(details.localPosition, context.size ?? _lastSize),
                    onPanUpdate: (details) =>
                        _handleTouch(details.localPosition, context.size ?? _lastSize),
                    child: CustomPaint(
                      painter: _FoilPainter(erasePath: _erasePath),
                      size: Size.infinite,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FoilPainter extends CustomPainter {
  _FoilPainter({required this.erasePath});

  final Path erasePath;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());

    final foilPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.outlineVariant, AppColors.surfaceContainerHigh],
      ).createShader(Offset.zero & size);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24)),
      foilPaint,
    );

    _drawHint(canvas, size);

    canvas.drawPath(erasePath, Paint()..blendMode = ui.BlendMode.clear);

    canvas.restore();
  }

  void _drawHint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Scratch here',
        style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _FoilPainter oldDelegate) => true;
}
