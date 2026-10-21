import 'package:flutter/material.dart';

enum NavGlyphKind { home, categories, wallet }

/// Bottom-bar icons drawn to match design_references/home-page.png:
/// rounded outlines when idle and solid shapes (with cut-outs for the door
/// and the wallet clasp) when selected, from one shared 24-unit geometry so
/// both states line up exactly.
class NavGlyph extends StatelessWidget {
  const NavGlyph({
    required this.kind,
    required this.selected,
    required this.color,
    this.size = 29,
    super.key,
  });

  final NavGlyphKind kind;
  final bool selected;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _NavGlyphPainter(kind, selected, color)),
  );
}

class _NavGlyphPainter extends CustomPainter {
  const _NavGlyphPainter(this.kind, this.selected, this.color);

  final NavGlyphKind kind;
  final bool selected;
  final Color color;

  /// Stroke width in 24-unit space (≈ 2.1 logical px at size 29).
  static const _stroke = 1.75;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    switch (kind) {
      case NavGlyphKind.home:
        _home(canvas, stroke, fill);
      case NavGlyphKind.categories:
        _categories(canvas, stroke, fill);
      case NavGlyphKind.wallet:
        _wallet(canvas, stroke, fill);
    }
  }

  // House with a rounded roof and body and an arched door.
  Path _houseBody() => Path()
    ..moveTo(3.2, 10.4)
    ..quadraticBezierTo(3.2, 9.3, 4.1, 8.6)
    ..lineTo(10.6, 3.5)
    ..quadraticBezierTo(12, 2.4, 13.4, 3.5)
    ..lineTo(19.9, 8.6)
    ..quadraticBezierTo(20.8, 9.3, 20.8, 10.4)
    ..lineTo(20.8, 18.6)
    ..quadraticBezierTo(20.8, 21, 18.4, 21)
    ..lineTo(5.6, 21)
    ..quadraticBezierTo(3.2, 21, 3.2, 18.6)
    ..close();

  Path _door() => Path()
    ..moveTo(9.4, 21)
    ..lineTo(9.4, 15.4)
    ..arcToPoint(const Offset(14.6, 15.4), radius: const Radius.circular(2.6))
    ..lineTo(14.6, 21);

  /// Both states draw the same outline strokes; selected only adds the
  /// fill inside the house (the door stays open), so the silhouette never
  /// changes.
  void _home(Canvas canvas, Paint stroke, Paint fill) {
    if (selected) {
      final doorInterior = _door()..close();
      canvas
        ..saveLayer(Offset.zero & const Size(24, 24), Paint())
        ..drawPath(_houseBody(), fill)
        ..drawPath(doorInterior, Paint()..blendMode = BlendMode.clear);
    }
    canvas
      ..drawPath(_houseBody(), stroke)
      ..drawPath(_door(), stroke);
    if (selected) canvas.restore();
  }

  // Four generously rounded squares.
  void _categories(Canvas canvas, Paint stroke, Paint fill) {
    const cell = 7.6;
    for (final origin in const [
      Offset(3, 3),
      Offset(13.4, 3),
      Offset(3, 13.4),
      Offset(13.4, 13.4),
    ]) {
      final rect = RRect.fromRectAndRadius(
        origin & const Size(cell, cell),
        const Radius.circular(2.6),
      );
      canvas.drawRRect(selected ? rect.inflate(.4) : rect, selected ? fill : stroke);
    }
  }

  // Rounded wallet body, slanted top flap and a pill clasp on the trailing side.
  void _wallet(Canvas canvas, Paint stroke, Paint fill) {
    final body = RRect.fromLTRBR(3, 6.4, 20.6, 20.6, const Radius.circular(3.2));
    final flap = Path()
      ..moveTo(5.2, 6.4)
      ..lineTo(15.6, 3.3)
      ..quadraticBezierTo(17.2, 2.9, 17.6, 4.4)
      ..lineTo(18.1, 6.4);
    final clasp = RRect.fromLTRBR(14.6, 10.7, 21.4, 16.3, const Radius.circular(2.8));
    if (selected) {
      final shape = Path()
        ..addRRect(body)
        ..addPath(
          Path()
            ..moveTo(5.2, 6.4)
            ..lineTo(15.6, 3.3)
            ..quadraticBezierTo(17.2, 2.9, 17.6, 4.4)
            ..lineTo(18.1, 6.4)
            ..close(),
          Offset.zero,
        );
      canvas.saveLayer(Offset.zero & const Size(24, 24), Paint());
      canvas.drawPath(shape, fill);
      // The clasp reads as a cut-out ring with a dot, like the reference.
      canvas.drawRRect(clasp, Paint()..blendMode = BlendMode.clear);
      canvas.drawRRect(
        clasp.deflate(1.3),
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(clasp.center.translate(.2, 0), .9, Paint()..blendMode = BlendMode.clear);
      canvas.restore();
    } else {
      canvas
        ..drawRRect(body, stroke)
        ..drawPath(flap, stroke)
        ..drawRRect(clasp, stroke)
        ..drawCircle(clasp.center.translate(.2, 0), .9, fill);
    }
  }

  @override
  bool shouldRepaint(_NavGlyphPainter old) =>
      old.kind != kind || old.selected != selected || old.color != color;
}
