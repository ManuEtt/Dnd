import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'fantasy_experience.dart';
import 'fantasy_ui.dart';

/// Read-only combat portrait: every value comes from the current encounter.
/// Unknown or unconfirmed stats are deliberately never replaced by defaults.
class FantasyCombatantCard extends StatelessWidget {
  const FantasyCombatantCard({
    super.key,
    required this.name,
    required this.isHero,
    required this.isActive,
    this.initiative,
    this.hitPoints,
    this.maxHitPoints,
    this.armorClass,
    this.temporaryHitPoints = 0,
  });

  final String name;
  final bool isHero;
  final bool isActive;
  final int? initiative;
  final int? hitPoints;
  final int? maxHitPoints;
  final int? armorClass;
  final int temporaryHitPoints;

  double? get healthProgress {
    if (hitPoints == null || maxHitPoints == null || maxHitPoints! <= 0) {
      return null;
    }
    return (hitPoints! / maxHitPoints!).clamp(0.0, 1.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final accent = isHero ? FantasyPalette.gold : FantasyPalette.danger;
    final hp = hitPoints == null || maxHitPoints == null
        ? '? / ?'
        : '$hitPoints / $maxHitPoints';
    final progress = healthProgress;
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.8;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: accent.withValues(alpha: isActive ? .92 : .48),
          width: isActive ? 1.7 : 1,
        ),
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isHero
              ? const [Color(0xff243a43), Color(0xff0c1827)]
              : const [Color(0xff3a2528), Color(0xff111a26)],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isActive ? .20 : .07),
            blurRadius: isActive ? 14 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: CustomPaint(
                  painter: _CombatEngravingPainter(color: accent),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flex(
                  direction: largeText ? Axis.vertical : Axis.horizontal,
                  crossAxisAlignment: largeText
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    FantasyRuneEmblem(
                      rune: isHero ? FantasyRune.hero : FantasyRune.dice,
                      color: accent,
                      size: 42,
                    ),
                    SizedBox(width: largeText ? 0 : 10, height: largeText ? 8 : 0),
                    Flexible(
                      fit: FlexFit.loose,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHero ? 'HELD' : 'GEGNER',
                            style: TextStyle(
                              color: accent,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.3,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            name,
                            maxLines: largeText ? null : 2,
                            overflow: largeText
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    if (isActive)
                      Container(
                        key: const ValueKey('combatant-active-turn'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: .16),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: accent.withValues(alpha: .65),
                          ),
                        ),
                        child: Text(
                          'AM ZUG',
                          style: TextStyle(
                            color: accent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _CombatStatTag(
                      label: 'INI',
                      value: initiative?.toString() ?? '?',
                      color: accent,
                    ),
                    _CombatStatTag(
                      label: 'RK',
                      value: armorClass?.toString() ?? '?',
                      color: accent,
                    ),
                    _CombatStatTag(label: 'TP', value: hp, color: accent),
                    if (isHero && temporaryHitPoints > 0)
                      _CombatStatTag(
                        label: 'TEMP',
                        value: '$temporaryHitPoints',
                        color: FantasyPalette.blue,
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (progress == null)
                  const Text(
                    'Trefferpunkte nicht vollständig bestätigt',
                    style: TextStyle(color: FantasyPalette.muted, fontSize: 11),
                  )
                else
                  Semantics(
                    label: 'Trefferpunkte: $hitPoints von $maxHitPoints',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        key: const ValueKey('combatant-health-meter'),
                        value: progress,
                        minHeight: 7,
                        backgroundColor: FantasyPalette.night,
                        color: progress > .5
                            ? FantasyPalette.success
                            : progress > .2
                            ? FantasyPalette.gold
                            : FantasyPalette.danger,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CombatStatTag extends StatelessWidget {
  const _CombatStatTag({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: FantasyPalette.night.withValues(alpha: .86),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: color.withValues(alpha: .30)),
    ),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(color: FantasyPalette.ivory, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}

/// Fine vector filigree that scales with narrow phones and tablets.
class _CombatEngravingPainter extends CustomPainter {
  const _CombatEngravingPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 60 || size.height < 50) return;
    final ink = Paint()
      ..color = color.withValues(alpha: .23)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final cx = size.width - 32.0;
    final cy = math.min(size.height / 2, 64.0);
    canvas.drawCircle(Offset(cx, cy), 25, ink);
    canvas.drawCircle(Offset(cx, cy), 18, ink);
    for (final angle in [
      -math.pi / 4,
      math.pi / 4,
      3 * math.pi / 4,
      5 * math.pi / 4,
    ]) {
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        Offset(cx, cy) + direction * 27,
        Offset(cx, cy) + direction * 33,
        ink,
      );
    }
    final corner = Path()
      ..moveTo(8, 35)
      ..lineTo(8, 15)
      ..quadraticBezierTo(8, 8, 15, 8)
      ..lineTo(35, 8);
    canvas.drawPath(corner, ink);
  }

  @override
  bool shouldRepaint(covariant _CombatEngravingPainter old) =>
      old.color != color;
}
