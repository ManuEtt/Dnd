import 'package:flutter/material.dart';

import '../domain/condition_effects.dart';
import '../domain/condition_rules.dart';
import '../domain/models.dart';
import 'fantasy_ui.dart';

/// Read-only fantasy cards for confirmed effects. Only the parent may open
/// the existing, revision-checked condition confirmation dialog.
class FantasyEffectWard extends StatelessWidget {
  const FantasyEffectWard({
    super.key,
    required this.hero,
    this.encounter,
    this.onManage,
    this.expandDetailsInitially = false,
  });

  final HeroCharacter hero;
  final Encounter? encounter;
  final VoidCallback? onManage;
  final bool expandDetailsInitially;

  @override
  Widget build(BuildContext context) => FantasyPanel(
    title: 'Arkaner Zustandskreis',
    icon: Icons.auto_awesome_outlined,
    accent: FantasyPalette.blue,
    material: FantasyPanelMaterial.iron,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WardCard(
          key: const ValueKey('ward-concentration'),
          icon: Icons.auto_awesome,
          color: FantasyPalette.blue,
          title: 'Konzentration',
          summary: hero.concentratingOn.isEmpty
              ? 'Keine aktive Konzentration'
              : hero.concentratingOn,
          expanded: expandDetailsInitially,
          details: [
            if (hero.concentratingOn.isNotEmpty)
              Text('Bestätigter Zauber: ' + hero.concentratingOn),
            const Text(
              'Die Wirkungsdauer ist nicht bestätigt. Aus dem '
              'Zaubernamen wird keine Restzeit abgeleitet.',
            ),
            const Text(
              'Konzentration endet bei einem neuen Konzentrationseffekt, '
              'misslungenem Konstitutionsrettungswurf nach Schaden '
              'oder Handlungsunfähigkeit/Tod.',
            ),
          ],
        ),
        if (hero.exhaustionLevel > 0) ...[
          const SizedBox(height: 9),
          _WardCard(
            key: const ValueKey('ward-exhaustion'),
            icon: Icons.hourglass_bottom,
            color: FantasyPalette.danger,
            title: 'Erschöpfung',
            summary: 'Stufe ' + hero.exhaustionLevel.toString() + '/6',
            expanded: expandDetailsInitially,
            details: [
              Text(
                'W20-Tests: −' +
                    (hero.exhaustionLevel * 2).toString() +
                    ' durch Erschöpfung.',
              ),
              Text('Bewegungsrate: ' + _speedLabel(hero)),
              const Text(
                'Die gespeicherte Grundbewegung bleibt unverändert. '
                'Lange Rast und Stufenänderungen benötigen bestätigte Regeln.',
              ),
            ],
          ),
        ],
        for (final condition in hero.conditions) ...[
          const SizedBox(height: 9),
          _WardCard(
            key: ValueKey('ward-condition-' + condition),
            icon: _conditionIcon(condition),
            color: _conditionColor(condition),
            title: _title(condition),
            summary: _summary(condition),
            expanded: expandDetailsInitially,
            details: [
              Text(
                ConditionRules.descriptions[condition] ??
                    'Historischer Eintrag ohne geprüfte Regelwirkung.',
              ),
              if (hero.manualConditions.contains(condition))
                const Text('Manuell / historisch'),
              for (final effect in hero.conditionEffects.where(
                (item) => item.condition == condition,
              ))
                Text(
                  'Quelle: ' + effect.source + ' · ' + _duration(effect),
                  key: ValueKey('source-effect-' + effect.id),
                ),
            ],
          ),
        ],
        if (hero.conditions.isEmpty && hero.exhaustionLevel == 0)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Keine bestätigten Zustände oder Erschöpfungsstufen.',
              style: TextStyle(color: FantasyPalette.muted, fontSize: 12),
            ),
          ),
        if (encounter != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'Bestätigte Kampfrunde: ' + encounter!.round.toString() +
                  '. Ein Effekt endet ausschließlich am bestätigten '
                      'eigenen Zugende seiner Begegnung.',
              style: const TextStyle(
                color: FantasyPalette.muted,
                fontSize: 12,
              ),
            ),
          ),
        if (onManage != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('ward-manage-effects'),
              onPressed: onManage,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Zustandsquellen verwalten'),
            ),
          ),
      ],
    ),
  );

  String _summary(String condition) {
    final count = hero.conditionEffects
        .where((effect) => effect.condition == condition)
        .length;
    if (count == 0) return 'Manuell / historisch';
    final sourceLabel =
        count == 1 ? '1 bestätigte Quelle' : '$count bestätigte Quellen';
    return hero.manualConditions.contains(condition)
        ? sourceLabel + ' · auch manuell'
        : sourceLabel;
  }

  String _duration(ConditionEffect effect) {
    final id = effect.expiresInEncounterId;
    final round = effect.expiresAtOwnTurnEndRound;
    if (id == null || round == null) {
      return 'Bis zur ausdrücklichen Entfernung';
    }
    final other = encounter != null && encounter!.id != id;
    return 'Ende deines Zugs: Runde $round ($id)' +
        (other ? ' · andere Begegnung' : '');
  }

  static String _speedLabel(HeroCharacter hero) {
    final speed = ExhaustionRules.effectiveSpeedMeters(hero);
    if (speed == null) return 'nicht bestätigt';
    return speed == speed.roundToDouble()
        ? speed.toInt().toString() + ' m'
        : speed.toString() + ' m';
  }

  static String _title(String condition) => condition.isEmpty
      ? 'Unbekannt'
      : condition[0].toUpperCase() + condition.substring(1);

  static Color _conditionColor(String value) => switch (value) {
    'vergiftet' => FantasyPalette.success,
    'gelähmt' || 'betäubt' || 'bewusstlos' => FantasyPalette.danger,
    'liegend' => FantasyPalette.gold,
    _ => FantasyPalette.blue,
  };

  static IconData _conditionIcon(String value) => switch (value) {
    'vergiftet' => Icons.science_outlined,
    'gelähmt' => Icons.lock_outline,
    'liegend' => Icons.south_outlined,
    'betäubt' || 'bewusstlos' => Icons.nights_stay_outlined,
    _ => Icons.shield_moon_outlined,
  };
}

class _WardCard extends StatelessWidget {
  const _WardCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.summary,
    required this.details,
    required this.expanded,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String summary;
  final List<Widget> details;
  final bool expanded;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: FantasyPalette.night.withValues(alpha: .75),
      border: Border.all(color: color.withValues(alpha: .55)),
      borderRadius: BorderRadius.circular(11),
    ),
    child: ExpansionTile(
      initiallyExpanded: expanded,
      leading: _RuneSeal(icon: icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontFamily: 'serif',
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        summary,
        style: const TextStyle(
          color: FantasyPalette.ivory,
          fontSize: 12,
        ),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      expandedAlignment: Alignment.centerLeft,
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final detail in details)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: DefaultTextStyle.merge(
              style: const TextStyle(
                color: FantasyPalette.muted,
                fontSize: 12,
              ),
              child: detail,
            ),
          ),
      ],
    ),
  );
}

class _RuneSeal extends StatelessWidget {
  const _RuneSeal({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 40,
    height: 40,
    child: Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: const Size(40, 40),
          painter: _RuneRing(color),
        ),
        Icon(icon, color: color, size: 19),
      ],
    ),
  );
}

/// Tiny vector sigil, available offline without changing bundled assets.
class _RuneRing extends CustomPainter {
  const _RuneRing(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = Paint()
      ..color = color.withValues(alpha: .8)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, size.width * .42, stroke);
    canvas.drawCircle(center, size.width * .34, stroke);
    final diamond = Path()
      ..moveTo(center.dx, 0)
      ..lineTo(size.width, center.dy)
      ..lineTo(center.dx, size.height)
      ..lineTo(0, center.dy)
      ..close();
    canvas.drawPath(diamond, stroke);
  }

  @override
  bool shouldRepaint(covariant _RuneRing oldDelegate) =>
      oldDelegate.color != color;
}
