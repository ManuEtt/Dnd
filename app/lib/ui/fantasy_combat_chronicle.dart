import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'fantasy_ui.dart';

/// A read-only view over persisted game events. Never renders the raw event
/// payload: it contains stateAfter checkpoints, which include private save data.
class FantasyCombatChronicle extends StatelessWidget {
  const FantasyCombatChronicle({
    super.key,
    required this.events,
    this.maxEntries = 8,
  });

  final List<GameEvent> events;
  final int maxEntries;

  static bool isRelevant(GameEvent event) {
    final type = event.type;
    return type.startsWith('combat.') ||
        type.startsWith('spell.') ||
        type.startsWith('effect.') ||
        type.startsWith('condition.effect.') ||
        type.startsWith('deathSave.') ||
        type.startsWith('class.') ||
        type == 'attack' ||
        type == 'offhandAttack' ||
        type == 'dice.freeRoll' ||
        type == 'roll.resolved' ||
        type == 'saving.roll' ||
        type == 'saving.rerolled';
  }

  @override
  Widget build(BuildContext context) {
    final relevant = events.where(isRelevant).toList(growable: false);
    final visible = relevant.reversed.take(maxEntries < 0 ? 0 : maxEntries);
    return FantasyPanel(
      key: const ValueKey('combat-chronicle'),
      title: 'Kampf- & Würfelchronik',
      icon: Icons.history_edu_outlined,
      material: FantasyPanelMaterial.parchment,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bestätigte Regelereignisse aus dem Kampagnenverlauf. '
            'Neueste Einträge zuerst; keine erzählerischen Vermutungen.',
            style: TextStyle(fontSize: 12, color: FantasyPalette.muted),
          ),
          const SizedBox(height: 10),
          if (relevant.isEmpty || maxEntries <= 0)
            const Text('Noch keine bestätigten Kampf- oder Würfelereignisse.')
          else
            for (final event in visible)
              Padding(
                key: ValueKey('chronicle-event-${event.id}'),
                padding: const EdgeInsets.only(bottom: 9),
                child: _ChronicleEntry(event: event),
              ),
          if (relevant.length > maxEntries && maxEntries > 0)
            Text(
              'Zeige die letzten $maxEntries von ${relevant.length} '
              'bestätigten Ereignissen.',
              style: const TextStyle(
                color: FantasyPalette.muted,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }
}

class _ChronicleEntry extends StatelessWidget {
  const _ChronicleEntry({required this.event});

  final GameEvent event;

  @override
  Widget build(BuildContext context) {
    final label = _EventSummary.title(event.type);
    final details = _EventSummary.details(event);
    final diceDetails = _EventSummary.diceDetails(event);
    final date = event.timestamp.toLocal();
    final when =
        '${_two(date.day)}.${_two(date.month)}.${date.year} '
        '${_two(date.hour)}:${_two(date.minute)}';
    final attack = event.type == 'attack' ||
        event.type == 'offhandAttack' ||
        event.type.startsWith('combat.enemyAttack') ||
        event.type == 'combat.turnCompleted';
    final accent = attack ? FantasyPalette.danger : FantasyPalette.gold;

    return Semantics(
      label: '$label, $when${details.isEmpty ? '' : ', ${details.join(', ')}'}${diceDetails.isEmpty ? '' : ', ${diceDetails.join(', ')}'}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: FantasyPalette.night.withValues(alpha: .64),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: accent.withValues(alpha: .5),
              width: 1.3,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                attack ? Icons.sports_martial_arts : Icons.auto_stories_outlined,
                color: accent,
                size: 20,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      when,
                      style: const TextStyle(
                        fontSize: 11,
                        color: FantasyPalette.muted,
                      ),
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(details.join(' · '), softWrap: true),
                    ],
                    if (diceDetails.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      for (final item in diceDetails)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: _DiceDetail(
                            label: item,
                            critical: item.startsWith('KRITISCH'),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

/// Compact engraved row, rather than a new interactive roll: all values are
/// copied verbatim from confirmed, pre-existing dice result objects.
class _DiceDetail extends StatelessWidget {
  const _DiceDetail({required this.label, required this.critical});

  final String label;
  final bool critical;

  @override
  Widget build(BuildContext context) {
    final accent = critical ? FantasyPalette.danger : FantasyPalette.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: FantasyPalette.night.withValues(alpha: .8),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: accent.withValues(alpha: .55)),
      ),
      child: Row(
        children: [
          Icon(Icons.casino_outlined, color: accent, size: 17),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              softWrap: true,
              style: TextStyle(
                color: critical ? accent : FantasyPalette.ivory,
                fontSize: 12,
                fontWeight: critical ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// An explicit allowlist prevents stateAfter, internal identifiers or arbitrary
/// third-party payload fields from being exposed as player-facing prose.
class _EventSummary {
  static String title(String type) => switch (type) {
    'combat.started' => 'Kampf begonnen',
    'combat.turnCompleted' => 'Kampfrunde abgeschlossen',
    'combat.enemyAttackContinued' => 'Gegnerangriff fortgesetzt',
    'combat.enemyAttackCountConfirmed' => 'Gegnerangriffe bestätigt',
    'combat.shieldHitResolved' => 'Schildreaktion abgeschlossen',
    'combat.coverConfirmed' => 'Deckung bestätigt',
    'combat.coverStatus' => 'Deckung geprüft',
    'combat.moved' => 'Bewegung bestätigt',
    'combat.stoodUp' => 'Aufstehen bestätigt',
    'combat.crawled' => 'Kriechen bestätigt',
    'combat.manualTurnQueueEstablished' => 'Zugfolge bestätigt',
    'combat.manualTurnQueueAdvanced' => 'Zugfolge fortgesetzt',
    'combat.manualExtraCreatureAttack' => 'Kreaturenangriff bestätigt',
    'combat.areaCreatureTracked' => 'Kreatur registriert',
    'combat.areaCreatureInitiativeConfirmed' => 'Kreatureninitiative bestätigt',
    'attack' => 'Angriffswurf',
    'offhandAttack' => 'Nebenhandangriff',
    'dice.freeRoll' => 'Würfelwurf',
    'roll.resolved' => 'Probe ausgewertet',
    'effect.damage' => 'Schaden bestätigt',
    'effect.healing' => 'Heilung bestätigt',
    'effect.temporaryHitPoints' => 'Temporäre Trefferpunkte',
    'spell.magicMissile' => 'Magisches Geschoss',
    'spell.fireBolt' => 'Feuerpfeil',
    'spell.acidSplash' => 'Säurespritzer',
    'spell.sacredFlame' => 'Heilige Flamme',
    'spell.healing' => 'Heilzauber gewirkt',
    'deathSave.resolved' => 'Todesrettung ausgewertet',
    'deathSave.choicePending' => 'Todesrettung noch offen',
    'saving.roll' => 'Rettungswurf',
    'saving.rerolled' => 'Rettungswurf wiederholt',
    _ when type.startsWith('class.') => 'Klassenfähigkeit bestätigt',
    _ when type.startsWith('condition.effect.') =>
      'Zustandsänderung bestätigt',
    _ when type.startsWith('spell.') => 'Zauberwirkung bestätigt',
    _ => 'Kampfereignis bestätigt',
  };

  /// Show real die faces separately from the already stored final result.
  /// Never print arbitrary expressions, checkpoint data or custom payload text.
  static List<String> diceDetails(GameEvent event) {
    final p = event.payload;
    final result = <String>[];
    final attack = p['attackRoll'] is Map
        ? p['attackRoll']
        : event.type == 'attack' ||
              event.type == 'offhandAttack' ||
              event.type == 'roll.resolved'
        ? p['roll']
        : null;
    final normal = attack ?? (event.type == 'dice.freeRoll' ? p['roll'] : null);
    final attackLabel = event.type == 'dice.freeRoll' ? 'Freier Wurf' : 'Angriffswurf';
    final roll = _diceLine(attackLabel, normal);
    if (roll != null) result.add(roll);

    if (p['critical'] == true && p['hit'] == true) {
      result.add('KRITISCHER TREFFER bestätigt');
    }
    final damage = _diceLine('Schadenswürfel', p['damageRoll']);
    if (damage != null) result.add(damage);
    // On a critical hit, extra weapon dice do not add the ability modifier
    // again. Present the raw faces only, not an invented damage sum.
    final criticalDice = _diceLine(
      'Kritische Zusatzwürfel',
      p['criticalExtra'] ?? p['criticalExtraRoll'],
      includeModifier: false,
    );
    if (criticalDice != null) result.add(criticalDice);
    final sneak = _diceLine('Hinterhältige Angriffswürfel', p['sneakAttackRoll']);
    if (sneak != null) result.add(sneak);
    return result;
  }

  static String? _diceLine(
    String label,
    Object? dice, {
    bool includeModifier = true,
  }) {
    if (dice is! Map) return null;
    final raw = dice['rolls'];
    if (raw is! List || raw.isEmpty || raw.length > 100) return null;
    if (raw.any((die) => die is! int || die < 1 || die > 100)) return null;
    final faces = raw.cast<int>();
    final display = faces.take(8).join(', ');
    final omitted = faces.length > 8 ? ' (+${faces.length - 8} weitere)' : '';
    final expression = dice['expression'];
    final match = expression is String
        ? RegExp(r'^\\d{1,3}d(\\d{1,3})(?:[+-]\\d{1,4})?
    final payload = event.payload;
    final result = <String>[];
    final roll = payload['attackRoll'] is Map
        ? payload['attackRoll'] as Map
        : payload['roll'] is Map
        ? payload['roll'] as Map
        : null;

    if (roll != null && roll['total'] is num) {
      result.add('Wurf: ${roll['total']}');
    }
    if (payload['pendingEnemyShieldHit'] == true) {
      result.add('Schildentscheidung offen');
    } else if (payload['hit'] is bool) {
      result.add(payload['hit'] == true ? 'Treffer' : 'Verfehlt');
    }
    if (payload['damage'] is num) {
      result.add('Schaden: ${payload['damage']}');
    }
    if (payload['hitPointsRestored'] is num) {
      result.add('Geheilte TP: ${payload['hitPointsRestored']}');
    }
    if (payload['recovered'] is num) {
      result.add('Geheilte TP: ${payload['recovered']}');
    }
    if (payload['meters'] is num) {
      result.add('Bewegung: ${payload['meters']} m');
    }
    if (event.type == 'combat.enemyAttackCountConfirmed' &&
        payload['count'] is int) {
      result.add('Gegnerangriffe: ${payload['count']}');
    }
    if (payload['enemyAttacksRemaining'] is int &&
        (payload['enemyAttacksRemaining'] as int) > 0) {
      result.add('Weitere Gegnerangriffe: ${payload['enemyAttacksRemaining']}');
    }
    if (event.type == 'combat.shieldHitResolved') {
      if (payload['choice'] == 'cast') {
        result.add('Schild gewirkt');
      } else if (payload['choice'] == 'decline') {
        result.add('Auf Schild verzichtet');
      }
    }
    if (event.type == 'combat.coverConfirmed') {
      const levels = {
        'none': 'keine',
        'half': 'halbe',
        'threeQuarters': 'Dreiviertel',
        'total': 'vollständige',
      };
      final target = switch (payload['target']) {
        'held' => 'Held',
        'gegner' => 'Gegner',
        _ => null,
      };
      final level = levels[payload['grade']];
      if (target != null && level != null) {
        result.add('$target: $level Deckung');
      }
    }
    return result;
  }
}
).firstMatch(expression)
        : null;
    final sides = match?.group(1);
    final dieType = sides == null ? '' : ' W$sides';
    var description = '$label$dieType: $display$omitted';
    final natural = dice['natural'];
    if (natural is int && natural >= 1 && natural <= 20 && faces.length > 1) {
      description += ' · gewählt: $natural';
    }
    final bonus = dice['modifier'];
    if (includeModifier && bonus is int && bonus != 0 && bonus.abs() <= 1000) {
      description += ' · Bonus: ${bonus > 0 ? '+' : ''}$bonus';
    }
    return description;
  }

  static List<String> details(GameEvent event) {
    final payload = event.payload;
    final result = <String>[];
    final roll = payload['attackRoll'] is Map
        ? payload['attackRoll'] as Map
        : payload['roll'] is Map
        ? payload['roll'] as Map
        : null;

    if (roll != null && roll['total'] is num) {
      result.add('Wurf: ${roll['total']}');
    }
    if (payload['pendingEnemyShieldHit'] == true) {
      result.add('Schildentscheidung offen');
    } else if (payload['hit'] is bool) {
      result.add(payload['hit'] == true ? 'Treffer' : 'Verfehlt');
    }
    if (payload['damage'] is num) {
      result.add('Schaden: ${payload['damage']}');
    }
    if (payload['hitPointsRestored'] is num) {
      result.add('Geheilte TP: ${payload['hitPointsRestored']}');
    }
    if (payload['recovered'] is num) {
      result.add('Geheilte TP: ${payload['recovered']}');
    }
    if (payload['meters'] is num) {
      result.add('Bewegung: ${payload['meters']} m');
    }
    if (event.type == 'combat.enemyAttackCountConfirmed' &&
        payload['count'] is int) {
      result.add('Gegnerangriffe: ${payload['count']}');
    }
    if (payload['enemyAttacksRemaining'] is int &&
        (payload['enemyAttacksRemaining'] as int) > 0) {
      result.add('Weitere Gegnerangriffe: ${payload['enemyAttacksRemaining']}');
    }
    if (event.type == 'combat.shieldHitResolved') {
      if (payload['choice'] == 'cast') {
        result.add('Schild gewirkt');
      } else if (payload['choice'] == 'decline') {
        result.add('Auf Schild verzichtet');
      }
    }
    if (event.type == 'combat.coverConfirmed') {
      const levels = {
        'none': 'keine',
        'half': 'halbe',
        'threeQuarters': 'Dreiviertel',
        'total': 'vollständige',
      };
      final target = switch (payload['target']) {
        'held' => 'Held',
        'gegner' => 'Gegner',
        _ => null,
      };
      final level = levels[payload['grade']];
      if (target != null && level != null) {
        result.add('$target: $level Deckung');
      }
    }
    return result;
  }
}
