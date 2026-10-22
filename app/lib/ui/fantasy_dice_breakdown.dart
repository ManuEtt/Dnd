import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'fantasy_ui.dart';

/// Read-only die faces from a confirmed GameEvent. Arbitrary JSON fields,
/// checkpoint snapshots and unverified text are never rendered.
class FantasyDiceBreakdown extends StatelessWidget {
  const FantasyDiceBreakdown({super.key, required this.event});

  final GameEvent event;

  static List<String> describe(GameEvent event) {
    final data = event.payload;
    final lines = <String>[];

    void addRoll(
      String label,
      Object? source, {
      bool includeModifier = true,
    }) {
      if (source is! Map) return;
      final values = source['rolls'];
      if (values is! List ||
          values.isEmpty ||
          values.length > 100 ||
          values.any((v) => v is! int || v < 1 || v > 100)) {
        return;
      }
      final faces = values.cast<int>();
      var text = '$label: ' + faces.take(8).join(', ');
      if (faces.length > 8) {
        text += ' (+' + (faces.length - 8).toString() + ' weitere)';
      }
      final natural = source['natural'];
      if (faces.length > 1 &&
          natural is int &&
          natural >= 1 &&
          natural <= 20 &&
          faces.contains(natural)) {
        text += ' · W20 gewählt: $natural';
      }
      final bonus = source['modifier'];
      if (includeModifier &&
          bonus is int &&
          bonus != 0 &&
          bonus >= -1000 &&
          bonus <= 1000) {
        text += ' · Bonus: ' + (bonus > 0 ? '+' : '') + bonus.toString();
      }
      lines.add(text);
    }

    final attack = data['attackRoll'];
    if (attack is Map) {
      addRoll('Angriffswürfel', attack);
    } else if (data['roll'] is Map) {
      addRoll(
        event.type == 'dice.freeRoll' ? 'Freie Würfel' : 'Würfel',
        data['roll'],
      );
    }
    // A natural twenty alone is not proof of a critical hit: the actual
    // rule resolver sets this flag, accounting for class features and blocks.
    if (data['critical'] == true && data['hit'] == true) {
      lines.add('KRITISCHER TREFFER bestätigt');
    }
    addRoll('Schadenswürfel', data['damageRoll']);
    // Critical extra dice do not automatically repeat the weapon modifier.
    addRoll(
      'Kritische Zusatzwürfel',
      data['criticalExtra'] ?? data['criticalExtraRoll'],
      includeModifier: false,
    );
    addRoll('Hinterhältige Angriffswürfel', data['sneakAttackRoll']);
    return List.unmodifiable(lines);
  }

  @override
  Widget build(BuildContext context) {
    final entries = describe(event);
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      key: ValueKey('chronicle-dice-' + event.id),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: _DieFacePlaque(
              label: entry,
              critical: entry.startsWith('KRITISCH'),
            ),
          ),
      ],
    );
  }
}

class _DieFacePlaque extends StatelessWidget {
  const _DieFacePlaque({required this.label, required this.critical});

  final String label;
  final bool critical;

  @override
  Widget build(BuildContext context) {
    final accent = critical ? FantasyPalette.danger : FantasyPalette.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: FantasyPalette.night.withValues(alpha: .83),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: .55)),
      ),
      child: Row(
        children: [
          Icon(Icons.casino_outlined, size: 17, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              softWrap: true,
              style: TextStyle(
                fontSize: 12,
                color: critical ? accent : FantasyPalette.ivory,
                fontWeight: critical ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
