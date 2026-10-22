import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'fantasy_ui.dart';

/// Individually drawn high-density artwork: no external font, image request,
/// network dependency, or placeholder character data is required.
enum FantasyRune { dice, compass, hero, tome, quill, moon }

class FantasyRuneEmblem extends StatelessWidget {
  const FantasyRuneEmblem({
    super.key,
    required this.rune,
    this.size = 44,
    this.color = FantasyPalette.gold,
  });

  final FantasyRune rune;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FantasyRunePainter(rune: rune, color: color),
      ),
    ),
  );
}

/// Selected navigation art, rendered as native vectors and scaled to the
/// available slot. The containing NavigationBar/Rail still handles semantics,
/// keyboard focus, touch navigation, and the selected destination.
class FantasySelectedNavigationRune extends StatelessWidget {
  const FantasySelectedNavigationRune({
    super.key,
    required this.rune,
    this.size = 32,
  });

  final FantasyRune rune;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xff5d4329), Color(0xff1a3146)],
          ),
          border: Border.all(color: FantasyPalette.gold, width: 1.3),
          boxShadow: [
            BoxShadow(
              color: FantasyPalette.gold.withValues(alpha: .33),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: CustomPaint(
          foregroundPainter: const _NavigationEmblemPainter(),
          child: Center(
            child: FantasyRuneEmblem(
              rune: rune,
              size: size * .72,
              color: FantasyPalette.ivory,
            ),
          ),
        ),
      ),
    ),
  );
}

class _NavigationEmblemPainter extends CustomPainter {
  const _NavigationEmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 16 || size.height < 16) return;
    final paint = Paint()
      ..color = FantasyPalette.gold.withValues(alpha: .82)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final c = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 3;
    canvas.drawCircle(c, radius, paint);
    for (final direction in const [
      Offset(0, -1),
      Offset(1, 0),
      Offset(0, 1),
      Offset(-1, 0),
    ]) {
      final center = c + direction * (radius - 1);
      final glyph = Path()
        ..moveTo(center.dx, center.dy - 2)
        ..lineTo(center.dx + 2, center.dy)
        ..lineTo(center.dx, center.dy + 2)
        ..lineTo(center.dx - 2, center.dy)
        ..close();
      canvas.drawPath(glyph, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NavigationEmblemPainter oldDelegate) => false;
}

class _FantasyRunePainter extends CustomPainter {
  const _FantasyRunePainter({required this.rune, required this.color});

  final FantasyRune rune;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    final side = math.min(size.width, size.height);
    canvas.scale(side / 100);
    final edge = Paint()
      ..color = color
      ..strokeWidth = 2.25
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final fine = Paint()
      ..color = color.withValues(alpha: .52)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: .20), Colors.transparent],
      ).createShader(const Rect.fromLTWH(-48, -48, 96, 96));
    canvas.drawCircle(Offset.zero, 47, glow);
    canvas.drawCircle(Offset.zero, 42, fine);
    canvas.drawCircle(Offset.zero, 35, edge);

    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final p = Offset(math.cos(angle) * 45, math.sin(angle) * 45);
      final q = Offset(math.cos(angle) * 49, math.sin(angle) * 49);
      canvas.drawLine(p, q, edge);
    }

    void segment(double x, double y, double xx, double yy) =>
        canvas.drawLine(Offset(x, y), Offset(xx, yy), edge);
    void polygon(List<Offset> vertices, {Paint? paint}) {
      final path = Path()..moveTo(vertices.first.dx, vertices.first.dy);
      for (final point in vertices.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      path.close();
      canvas.drawPath(path, paint ?? edge);
    }

    switch (rune) {
      case FantasyRune.dice:
        polygon([
          const Offset(0, -28),
          const Offset(26, -12),
          const Offset(22, 20),
          const Offset(0, 31),
          const Offset(-22, 20),
          const Offset(-26, -12),
        ]);
        polygon([
          const Offset(0, -28),
          const Offset(26, -12),
          const Offset(0, 7),
          const Offset(-26, -12),
        ]);
        segment(-22, 20, 0, 7);
        segment(22, 20, 0, 7);
        segment(0, 7, 0, 31);
        segment(-26, -12, -8, -17);
        segment(26, -12, 8, -17);
      case FantasyRune.compass:
        polygon([
          const Offset(0, -29),
          const Offset(9, -9),
          const Offset(28, 0),
          const Offset(9, 9),
          const Offset(0, 29),
          const Offset(-9, 9),
          const Offset(-28, 0),
          const Offset(-9, -9),
        ]);
        polygon([
          const Offset(0, -22),
          const Offset(6, -6),
          const Offset(0, 0),
          const Offset(-6, -6),
        ]);
        canvas.drawCircle(Offset.zero, 4, edge);
      case FantasyRune.hero:
        final helm = Path()
          ..moveTo(-22, 27)
          ..lineTo(-18, -12)
          ..quadraticBezierTo(0, -34, 18, -12)
          ..lineTo(22, 27)
          ..lineTo(0, 32)
          ..close();
        canvas.drawPath(helm, edge);
        segment(-15, 0, 15, 0);
        segment(0, -22, 0, 21);
        segment(-14, 17, 14, 17);
        segment(-18, -12, -29, -20);
        segment(18, -12, 29, -20);
      case FantasyRune.tome:
        final left = Path()
          ..moveTo(0, -18)
          ..quadraticBezierTo(-13, -28, -29, -21)
          ..lineTo(-29, 23)
          ..quadraticBezierTo(-11, 15, 0, 26)
          ..close();
        canvas.drawPath(left, edge);
        final right = Path()
          ..moveTo(0, -18)
          ..quadraticBezierTo(13, -28, 29, -21)
          ..lineTo(29, 23)
          ..quadraticBezierTo(11, 15, 0, 26)
          ..close();
        canvas.drawPath(right, edge);
        segment(0, -17, 0, 26);
        segment(-23, -10, -8, -12);
        segment(8, -12, 23, -10);
      case FantasyRune.quill:
        final feather = Path()
          ..moveTo(-18, 25)
          ..quadraticBezierTo(-25, -9, 24, -29)
          ..quadraticBezierTo(28, 8, -18, 25)
          ..close();
        canvas.drawPath(feather, edge);
        segment(-26, 30, 19, -20);
        segment(-12, -1, 14, -3);
        segment(-15, 9, 6, 8);
      case FantasyRune.moon:
        final crescent = Path()
          ..moveTo(7, -30)
          ..arcToPoint(const Offset(7, 30), radius: const Radius.circular(31))
          ..arcToPoint(
            const Offset(7, -30),
            radius: const Radius.circular(25),
            clockwise: false,
          );
        canvas.drawPath(crescent, edge);
        polygon([
          const Offset(21, -24),
          const Offset(25, -14),
          const Offset(35, -10),
          const Offset(25, -6),
          const Offset(21, 4),
          const Offset(17, -6),
          const Offset(7, -10),
          const Offset(17, -14),
        ], paint: fine);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FantasyRunePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.rune != rune;
}

/// A new illustrated emblem plaque shared by the title screen and headings.
class FantasyBrandPlaque extends StatelessWidget {
  const FantasyBrandPlaque({
    super.key,
    this.subtitle = 'DEINE ABENTEUER · DEINE HELDEN · DEINE GESCHICHTEN',
    this.compact = false,
  });

  final String subtitle;
  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Würfelraunen',
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: FantasyPalette.gold.withValues(alpha: .32)),
        ),
        gradient: const LinearGradient(
          colors: [Color(0xee101d29), Color(0xa8122637), Color(0xee101d29)],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 15,
          vertical: compact ? 6 : 14,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FantasyRuneEmblem(rune: FantasyRune.dice, size: compact ? 32 : 62),
            SizedBox(width: compact ? 8 : 13),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Würfelraunen',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontWeight: FontWeight.bold,
                      color: FantasyPalette.gold,
                      fontSize: compact ? 20 : 30,
                      shadows: const [
                        Shadow(color: Color(0xbb000000), blurRadius: 6),
                      ],
                    ),
                  ),
                  if (!compact)
                    Text(
                      subtitle,
                      maxLines: 2,
                      style: const TextStyle(
                        fontSize: 10,
                        color: FantasyPalette.ivory,
                        letterSpacing: 1.0,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Responsive illustrated action choice. Every tile retains an actual onTap.
class FantasyJourneyCard extends StatelessWidget {
  const FantasyJourneyCard({
    super.key,
    required this.title,
    required this.description,
    required this.image,
    required this.rune,
    required this.onTap,
    this.accent = FantasyPalette.gold,
  });

  final String title;
  final String description;
  final String image;
  final FantasyRune rune;
  final VoidCallback? onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) => Material(
    color: FantasyPalette.ink,
    borderRadius: BorderRadius.circular(14),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Semantics(
        button: true,
        enabled: onTap != null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 118),
          decoration: BoxDecoration(
            border: Border.all(color: accent.withValues(alpha: .57)),
            borderRadius: BorderRadius.circular(14),
            image: DecorationImage(
              image: AssetImage(image),
              fit: BoxFit.cover,
              opacity: .5,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xf70b1724),
                  Color(0xe90b1724),
                  Color(0x99132131),
                ],
              ),
            ),
            child: Row(
              children: [
                FantasyRuneEmblem(rune: rune, size: 56, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: accent),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// Readable chapter heading with entirely new vector ornament work.
class FantasyChapterHeading extends StatelessWidget {
  const FantasyChapterHeading({
    super.key,
    required this.label,
    required this.rune,
    this.description,
  });

  final String label;
  final String? description;
  final FantasyRune rune;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FantasyRuneEmblem(rune: rune, size: 36),
            const SizedBox(width: 11),
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.titleLarge),
            ),
            const Icon(
              Icons.auto_awesome,
              color: FantasyPalette.gold,
              size: 14,
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: FantasyPalette.gold.withValues(alpha: .56),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.diamond_outlined,
                size: 14,
                color: FantasyPalette.gold,
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: FantasyPalette.gold.withValues(alpha: .56),
              ),
            ),
          ],
        ),
        if (description != null) ...[
          const SizedBox(height: 8),
          Text(description!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    ),
  );
}
