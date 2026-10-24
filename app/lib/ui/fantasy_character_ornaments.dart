import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Decorative portrait setting based on the character-sheet design reference.
/// The actual user-selected portrait and its semantics remain the only content:
/// the runes are drawn by Flutter, not a screenshot with fabricated values.
class FantasyPortraitMedallion extends StatelessWidget {
  const FantasyPortraitMedallion({
    super.key,
    required this.child,
    this.size = 112,
  });

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const ValueKey('sheet-portrait-medallion'),
    width: size,
    height: size,
    child: Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(
          key: ValueKey('sheet-portrait-halo'),
          painter: FantasyPortraitHaloPainter(),
        ),
        Padding(
          padding: EdgeInsets.all(size * .085),
          child: ClipOval(child: child),
        ),
        const IgnorePointer(
          child: CustomPaint(painter: FantasyPortraitRimPainter()),
        ),
      ],
    ),
  );
}

/// Engraved frame: unobtrusive corner curls and inset gold filigree.
/// No asset is required and the artwork cannot intercept taps on panel buttons.
class FantasyEngravedFrame extends StatelessWidget {
  const FantasyEngravedFrame({
    super.key,
    required this.child,
    this.parchment = false,
  });

  final Widget child;
  final bool parchment;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      child,
      Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            key: ValueKey(
              parchment ? 'sheet-parchment-filigree' : 'sheet-panel-filigree',
            ),
            painter: FantasyFiligreePainter(parchment: parchment),
          ),
        ),
      ),
    ],
  );
}

class FantasyPortraitHaloPainter extends CustomPainter {
  const FantasyPortraitHaloPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * .49;
    final gold = Paint()
      ..color = const Color(0xffd6aa56)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final soft = Paint()
      ..color = const Color(0x88efd596)
      ..strokeWidth = .8
      ..style = PaintingStyle.stroke;
    final glow = Paint()
      ..color = const Color(0x5538a4ed)
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5)
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius * .93, glow);
    canvas.drawCircle(center, radius * .97, gold);
    canvas.drawCircle(center, radius * .84, soft);
    final rect = Rect.fromCircle(center: center, radius: radius * .90);
    for (var i = 0; i < 4; i++) {
      canvas.drawArc(
        rect,
        i * math.pi / 2 + math.pi / 9,
        math.pi / 3,
        false,
        gold,
      );
    }
    for (var i = 0; i < 16; i++) {
      final angle = i * math.pi / 8 - math.pi / 2;
      final inner = radius * (i.isEven ? .88 : .92);
      final outer = radius * .96;
      canvas.drawLine(
        center + Offset(math.cos(angle) * inner, math.sin(angle) * inner),
        center + Offset(math.cos(angle) * outer, math.sin(angle) * outer),
        soft,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FantasyPortraitHaloPainter oldDelegate) => false;
}

class FantasyPortraitRimPainter extends CustomPainter {
  const FantasyPortraitRimPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * .49;
    final line = Paint()
      ..color = const Color(0xffe7c47b)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    final dark = Paint()
      ..color = const Color(0xff71552b)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius * .86, dark);
    canvas.drawCircle(center, radius * .84, line);
    // Four compass jewels, at the rim: thin enough to leave the portrait clear.
    for (var i = 0; i < 4; i++) {
      final angle = i * math.pi / 2 - math.pi / 2;
      final point =
          center +
          Offset(
            math.cos(angle) * radius * .94,
            math.sin(angle) * radius * .94,
          );
      final diamond = Path()
        ..moveTo(point.dx, point.dy - 5)
        ..lineTo(point.dx + 4, point.dy)
        ..lineTo(point.dx, point.dy + 5)
        ..lineTo(point.dx - 4, point.dy)
        ..close();
      canvas.drawPath(diamond, Paint()..color = const Color(0xff342b24));
      canvas.drawPath(diamond, line);
    }
  }

  @override
  bool shouldRepaint(covariant FantasyPortraitRimPainter oldDelegate) => false;
}

class FantasyFiligreePainter extends CustomPainter {
  const FantasyFiligreePainter({this.parchment = false});

  final bool parchment;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 68 || size.height < 66) return;
    final color = parchment ? const Color(0x885f432a) : const Color(0x99bf9753);
    final paint = Paint()
      ..color = color
      ..strokeWidth = .9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final inset = 5.0;
    final bounds = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, const Radius.circular(8)),
      paint,
    );
    // Each corner receives the same miniature engraving in mirrored form.
    for (final left in [true, false]) {
      for (final top in [true, false]) {
        canvas.save();
        canvas.translate(
          left ? inset + 6 : size.width - inset - 6,
          top ? inset + 6 : size.height - inset - 6,
        );
        canvas.scale(left ? 1 : -1, top ? 1 : -1);
        final flourish = Path()
          ..moveTo(0, 22)
          ..quadraticBezierTo(0, 4, 18, 4)
          ..quadraticBezierTo(10, 4, 10, 13)
          ..quadraticBezierTo(10, 18, 16, 18);
        canvas.drawPath(flourish, paint);
        canvas.drawCircle(const Offset(16, 18), 1.5, paint);
        canvas.restore();
      }
    }
    // A central diamond under the upper border and over the lower border.
    for (final y in [inset, size.height - inset]) {
      final x = size.width / 2;
      final diamond = Path()
        ..moveTo(x, y - 4)
        ..lineTo(x + 4, y)
        ..lineTo(x, y + 4)
        ..lineTo(x - 4, y)
        ..close();
      canvas.drawPath(diamond, paint);
    }
  }

  @override
  bool shouldRepaint(covariant FantasyFiligreePainter oldDelegate) =>
      parchment != oldDelegate.parchment;
}
