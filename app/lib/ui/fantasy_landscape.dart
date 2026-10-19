import 'package:flutter/material.dart';

/// A new, offline nightscape illustrated entirely by vectors.
///
/// The scene is intentionally decorative: neither hidden buttons nor
/// invented places, quest objectives or character data are embedded in it.
class FantasyMoonlitScenery extends StatelessWidget {
  const FantasyMoonlitScenery({super.key, this.height = 220});

  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: IgnorePointer(
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: const CustomPaint(painter: _MoonlitSceneryPainter()),
      ),
    ),
  );
}

class _MoonlitSceneryPainter extends CustomPainter {
  const _MoonlitSceneryPainter();

  static const _horizon = Color(0xff142b42);
  static const _mountain = Color(0xff102238);
  static const _ridge = Color(0xff09172a);
  static const _pine = Color(0xff061322);
  static const _castle = Color(0xff071323);
  static const _lantern = Color(0xffe8b66d);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    canvas.save();
    canvas.scale(size.width / 1000, size.height / 350);

    final glow = Paint()
      ..shader =
          const RadialGradient(
            colors: [Color(0x77bcd8e8), Color(0x2283a6ce), Color(0x00223856)],
          ).createShader(
            const Rect.fromLTWH(615, -69, 310, 310),
          );
    canvas.drawCircle(const Offset(770, 86), 155, glow);
    canvas.drawCircle(
      const Offset(770, 86),
      38,
      Paint()..color = const Color(0xffc9dce6),
    );
    canvas.drawCircle(
      const Offset(760, 78),
      7,
      Paint()..color = const Color(0x337489a5),
    );
    canvas.drawCircle(
      const Offset(790, 94),
      4,
      Paint()..color = const Color(0x447489a5),
    );

    final star = Paint()
      ..color = const Color(0xbbe2e5df)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 42; i++) {
      final x = ((i * 179 + 31) % 980).toDouble() + 10;
      final y = ((i * 47 + 17) % 168).toDouble() + 6;
      if ((x - 770).abs() < 75 && (y - 86).abs() < 75) continue;
      final radius = i % 9 == 0 ? 2.1 : .75;
      canvas.drawCircle(Offset(x, y), radius, star);
    }

    _mountains(canvas, _horizon, const [
      Offset(-50, 245),
      Offset(66, 153),
      Offset(166, 222),
      Offset(312, 125),
      Offset(442, 231),
      Offset(554, 147),
      Offset(644, 206),
      Offset(830, 134),
      Offset(1050, 246),
    ]);
    _mountains(canvas, _mountain, const [
      Offset(-50, 294),
      Offset(97, 209),
      Offset(188, 253),
      Offset(349, 173),
      Offset(488, 278),
      Offset(601, 213),
      Offset(734, 253),
      Offset(855, 207),
      Offset(1050, 290),
    ]);
    _mountains(canvas, _ridge, const [
      Offset(-50, 327),
      Offset(112, 271),
      Offset(240, 308),
      Offset(393, 246),
      Offset(528, 297),
      Offset(674, 240),
      Offset(792, 300),
      Offset(975, 254),
      Offset(1050, 296),
    ]);

    // A fictional silhouette, not a claim about a game location.
    final silhouette = Paint()..color = _castle;
    final keep = Path()
      ..moveTo(516, 290)
      ..lineTo(516, 207)
      ..lineTo(548, 191)
      ..lineTo(573, 207)
      ..lineTo(573, 293)
      ..close();
    canvas.drawPath(keep, silhouette);
    _tower(canvas, 498, 216, 30, 70, silhouette);
    _tower(canvas, 575, 213, 31, 79, silhouette);
    _tower(canvas, 530, 166, 32, 122, silhouette);
    canvas.drawRect(const Rect.fromLTWH(492, 277, 116, 24), silhouette);
    final windowPaint = Paint()..color = _lantern.withValues(alpha: .83);
    for (final window in [
      const Rect.fromLTWH(513, 246, 4, 9),
      const Rect.fromLTWH(541, 230, 4, 13),
      const Rect.fromLTWH(582, 241, 4, 9),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(window, const Radius.circular(2)),
        windowPaint,
      );
    }

    // Foreground pines create depth without obscuring interactive content.
    final trees = Paint()..color = _pine;
    for (var i = 0; i < 32; i++) {
      final x = i * 37.0 - 18;
      final height = 40.0 + ((i * 23) % 60);
      final top = 346.0 - height;
      final path = Path()
        ..moveTo(x, 350)
        ..lineTo(x, top)
        ..lineTo(x - height * .23, top + height * .60)
        ..lineTo(x - height * .12, top + height * .56)
        ..lineTo(x - height * .30, top + height * .81)
        ..lineTo(x - height * .13, top + height * .76)
        ..lineTo(x - height * .35, 347)
        ..lineTo(x + height * .35, 347)
        ..lineTo(x + height * .13, top + height * .76)
        ..lineTo(x + height * .30, top + height * .81)
        ..lineTo(x + height * .12, top + height * .56)
        ..lineTo(x + height * .23, top + height * .60)
        ..close();
      canvas.drawPath(path, trees);
    }
    canvas.restore();
  }

  void _mountains(Canvas canvas, Color color, List<Offset> ridge) {
    final shape = Path()..moveTo(ridge.first.dx, ridge.first.dy);
    for (final point in ridge.skip(1)) {
      shape.lineTo(point.dx, point.dy);
    }
    shape
      ..lineTo(1050, 350)
      ..lineTo(-50, 350)
      ..close();
    canvas.drawPath(shape, Paint()..color = color);
  }

  void _tower(
    Canvas canvas,
    double x,
    double y,
    double width,
    double height,
    Paint paint,
  ) {
    final roof = Path()
      ..moveTo(x - 5, y)
      ..lineTo(x + width / 2, y - height * .39)
      ..lineTo(x + width + 5, y)
      ..close();
    canvas.drawPath(roof, paint);
    canvas.drawRect(Rect.fromLTWH(x, y, width, height), paint);
  }

  @override
  bool shouldRepaint(covariant _MoonlitSceneryPainter oldDelegate) => false;
}
