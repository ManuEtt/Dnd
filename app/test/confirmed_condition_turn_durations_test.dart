import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/condition_effects.dart';
import 'package:lebendiger_spielleiter/domain/cover_rules.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

void main() {
  final engine = GameEngine();

  Campaign fighting({int round = 3, String id = 'fight-3'}) {
    final base = engine.createDemo();
    return base.copyWith(
      encounter: Encounter(
        id: id,
        enemyName: 'Wächter',
        enemyHitPoints: 50,
        enemyMaxHitPoints: 50,
        heroCover: CoverLevel.total,
        round: round,
      ),
    );
  }

  const durations = {
    ConditionEffectDuration.currentTurnEnd: 1,
    ConditionEffectDuration.nextTurnEnd: 2,
    ConditionEffectDuration.threeOwnTurnEnds: 3,
    ConditionEffectDuration.fiveOwnTurnEnds: 5,
    ConditionEffectDuration.tenOwnTurnEnds: 10,
  };

  for (final entry in durations.entries) {
    test('${entry.value} eigene Zugenden: Endrunde und bestätigter Ablauf', () {
      final original = fighting();
      final update = engine.applyConditionEffect(
        original,
        source: 'Ausdrücklich bestätigte Zauberwirkung',
        condition: 'vergiftet',
        duration: entry.key,
      );
      final effect = update.campaign.hero.conditionEffects.single;
      expect(effect.expiresAtOwnTurnEndRound, 3 + entry.value - 1);
      expect(effect.expiresInEncounterId, 'fight-3');
      expect(
        update.events.single.payload['effect'],
        effect.toJson(),
      );
      expect(original.hero.conditionEffects, isEmpty);
      expect(
        ConditionEffectRules.remainingOwnTurnEnds(
          effect,
          update.campaign.encounter,
        ),
        entry.value,
      );
      var current = update.campaign;
      for (var n = 1; n <= entry.value; n++) {
        final finished = engine.endHeroTurn(current);
        current = finished.campaign;
        expect(current.encounter!.round, 3 + n);
        expect(
          current.hero.conditionEffects.isEmpty,
          n == entry.value,
        );
        if (n < entry.value) {
          expect(
            ConditionEffectRules.remainingOwnTurnEnds(
              effect,
              current.encounter,
            ),
            entry.value - n,
          );
        }
      }
      expect(current.hero.conditions, isNot(contains('vergiftet')));
      expect(current.events.length, greaterThan(original.events.length));
    });
  }

  test('Grenzwert wird vor Ereignis, ID-Vergabe oder Spielstandänderung geprüft', () {
    final campaign = fighting(round: 999997);
    expect(
      () => engine.applyConditionEffect(
        campaign,
        source: 'Quellennachweis',
        condition: 'blind',
        duration: ConditionEffectDuration.tenOwnTurnEnds,
      ),
      throwsFormatException,
    );
    expect(campaign.hero.conditionEffects, isEmpty);
    expect(campaign.revision, 0);
  });

  test('Zeitgebundener Eintrag benötigt lebende eigene aktive Begegnung', () {
    final enemyTurn = fighting().copyWith(
      encounter: fighting().encounter!.copyWith(activeParticipant: 'enemy'),
    );
    for (final duration in durations.keys) {
      expect(
        () => engine.applyConditionEffect(
          enemyTurn,
          source: 'Falle',
          condition: 'blind',
          duration: duration,
        ),
        throwsFormatException,
      );
    }
    expect(enemyTurn.hero.conditionEffects, isEmpty);
  });

  test('altes Schema-1 JSON und unabhängige Ursachen bleiben kompatibel', () {
    final origin = fighting();
    final confirmed = engine.applyConditionEffect(
      origin,
      source: 'Giftfalle',
      condition: 'vergiftet',
      duration: ConditionEffectDuration.fiveOwnTurnEnds,
    );
    final effective = confirmed.campaign.hero;
    final persisted = HeroCharacter.fromJson(
      jsonDecode(jsonEncode(effective.toJson())) as Map<String, dynamic>,
    );
    expect(persisted.conditionEffects.single.toJson(),
        effective.conditionEffects.single.toJson());
    expect(
      ConditionEffectRules.remainingOwnTurnEnds(
        persisted.conditionEffects.single,
        origin.encounter,
      ),
      5,
    );
    final oldJson = origin.hero.toJson()..remove('conditionEffects');
    final legacy = HeroCharacter.fromJson(oldJson);
    expect(legacy.conditionEffects, isEmpty);
    expect(legacy.manualConditions, origin.hero.manualConditions);
    final permanent = ConditionEffectRules.add(
      persisted,
      ConditionEffect(
        id: 'another-source',
        condition: 'vergiftet',
        source: 'Bestätigte zweite Quelle',
      ),
    );
    final after = ConditionEffectRules.expireAtOwnTurnEnd(
      permanent,
      encounterId: 'fight-3',
      round: 7,
    );
    expect(after.conditions, contains('vergiftet'));
    expect(after.conditionEffects.single.id, 'another-source');
  });

  test('Restlaufzeit wird außerhalb eigener bestätigter Kampfrunde verborgen', () {
    final effect = ConditionEffect(
      id: 'timed',
      condition: 'blind',
      source: 'Zauber',
      expiresInEncounterId: 'fight-3',
      expiresAtOwnTurnEndRound: 8,
    );
    expect(
      ConditionEffectRules.remainingOwnTurnEnds(
        effect,
        fighting(round: 7).encounter,
      ),
      2,
    );
    expect(
      ConditionEffectRules.remainingOwnTurnEnds(
        effect,
        fighting(round: 7, id: 'other').encounter,
      ),
      isNull,
    );
    expect(
      ConditionEffectRules.remainingOwnTurnEnds(
        effect,
        fighting(round: 9).encounter,
      ),
      isNull,
    );
    expect(
      ConditionEffectRules.remainingOwnTurnEnds(
        effect,
        fighting(round: 7).encounter!.copyWith(activeParticipant: 'enemy'),
      ),
      isNull,
    );
    expect(ConditionEffectRules.remainingOwnTurnEnds(effect, null), isNull);
  });
}
