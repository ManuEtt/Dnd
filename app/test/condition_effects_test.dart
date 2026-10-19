import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/condition_effects.dart';
import 'package:lebendiger_spielleiter/domain/condition_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/monk_self_restoration.dart';
import 'package:lebendiger_spielleiter/domain/paladin_lay_on_hands.dart';
import 'package:lebendiger_spielleiter/domain/rules_engine.dart';

HeroCharacter hero({
  String className = 'Kämpfer',
  int level = 1,
  List<String> conditions = const [],
  List<ConditionEffect> effects = const [],
}) => HeroCharacter(
  id: 'effect-hero',
  name: 'Liora',
  className: className,
  level: level,
  abilities: const {
    'strength': 12,
    'dexterity': 14,
    'constitution': 12,
    'intelligence': 10,
    'wisdom': 14,
    'charisma': 12,
  },
  hitPoints: 10,
  maxHitPoints: 20,
  armorClass: 15,
  speed: 9,
  weaponDamage: '1d8',
  conditions: conditions,
  conditionEffects: effects,
);

ConditionEffect effect(
  String id, {
  String condition = 'vergiftet',
  String? encounter,
  int? round,
}) => ConditionEffect(
  id: id,
  condition: condition,
  source: 'Bestätigte Falle',
  expiresInEncounterId: encounter,
  expiresAtOwnTurnEndRound: round,
);

void main() {
  test('zwei Quellen wirken einmal, aber enden unabhängig', () {
    final a = effect('a');
    final b = effect('b');
    final first = ConditionEffectRules.add(hero(), a);
    final second = ConditionEffectRules.add(first, b);
    expect(second.conditions, ['vergiftet']);
    expect(second.manualConditions, isEmpty);
    expect(ConditionRules.hasUnconditionalAttackDisadvantage(second), isTrue);

    final afterA = ConditionEffectRules.removeById(second, 'a');
    expect(afterA.conditions, ['vergiftet']);
    expect(afterA.conditionEffects.map((e) => e.id), ['b']);
    expect(ConditionEffectRules.removeById(afterA, 'b').conditions, isEmpty);
    expect(
      () => ConditionEffectRules.removeById(afterA, 'missing'),
      throwsStateError,
    );
    expect(() => ConditionEffectRules.add(afterA, b), throwsStateError);
  });

  test(
    'manuelle Einträge und Quellen bleiben in beide Richtungen getrennt',
    () {
      final stored = hero(
        conditions: ['vergiftet', 'liegend'],
        effects: [effect('source')],
      );
      expect(stored.conditions, ['vergiftet', 'liegend']);
      final sourceGone = ConditionEffectRules.removeById(stored, 'source');
      expect(sourceGone.conditions, ['vergiftet', 'liegend']);
      final manualGone = stored.copyWith(conditions: ['liegend']);
      expect(manualGone.conditions, ['liegend', 'vergiftet']);
      expect(manualGone.conditionEffects, hasLength(1));
      expect(
        ConditionEffectRules.endCondition(stored, 'vergiftet').conditions,
        ['liegend'],
      );
      expect(stored.manualConditions, ['vergiftet', 'liegend']);
      expect(() => stored.conditions.add('betäubt'), throwsUnsupportedError);
      expect(() => stored.conditionEffects.clear(), throwsUnsupportedError);
    },
  );

  test('Schema 1 JSON, Kopieren, Schaden und Heilung bewahren Quellbesitz', () {
    final original = hero(
      conditions: ['liegend'],
      effects: [effect('curse', condition: 'bewusstlos')],
    );
    final json = original.toJson();
    expect(json['conditions'], ['liegend']);
    expect((json['conditionEffects'] as List).length, 1);
    final restored = HeroCharacter.fromJson(
      jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
    );
    expect(restored.manualConditions, ['liegend']);
    expect(restored.conditions, ['liegend', 'bewusstlos']);
    final damaged = RulesEngine.damage(restored, 2);
    expect(damaged.manualConditions, ['liegend']);
    expect(damaged.conditionEffects.single.id, 'curse');
    final healed = RulesEngine.heal(damaged, 1);
    expect(healed.conditions, ['liegend', 'bewusstlos']);
    expect(healed.manualConditions, ['liegend']);
    expect(healed.copyWith(name: 'Neu').conditionEffects.single.id, 'curse');

    final legacy = hero(conditions: ['vergiftet']).toJson()
      ..remove('conditionEffects');
    final old = HeroCharacter.fromJson(legacy);
    expect(old.conditionEffects, isEmpty);
    expect(old.conditions, ['vergiftet']);
  });

  test('ablauf nur nach eigenem Zug in derselben Begegnung', () {
    final timed = hero(
      conditions: ['vergiftet'],
      effects: [
        effect('now', encounter: 'fight-1', round: 2),
        effect('later', condition: 'blind', encounter: 'fight-1', round: 3),
        effect('other', condition: 'gelähmt', encounter: 'fight-2', round: 2),
        effect('manual', condition: 'taub'),
      ],
    );
    expect(
      ConditionEffectRules.expireAtOwnTurnEnd(
        timed,
        encounterId: 'fight-2',
        round: 1,
      ).conditionEffects,
      hasLength(4),
    );
    final turn = ConditionEffectRules.expireAtOwnTurnEnd(
      timed,
      encounterId: 'fight-1',
      round: 2,
    );
    expect(turn.conditionEffects.map((e) => e.id), [
      'later',
      'other',
      'manual',
    ]);
    expect(turn.conditions, contains('vergiftet'));
    expect(turn.conditions, contains('gelähmt'));
    expect(
      ConditionEffectRules.expireAtOwnTurnEnd(
        turn,
        encounterId: 'fight-1',
        round: 2,
      ).conditionEffects,
      hasLength(3),
    );
    expect(
      ConditionEffectRules.expireAtOwnTurnEnd(
        turn,
        encounterId: 'fight-3',
        round: 100,
      ).conditionEffects,
      hasLength(3),
    );
  });

  test('ungültige Imports werden ohne stillen Datenverlust abgelehnt', () {
    expect(() => effect('x', condition: 'tot'), throwsFormatException);
    expect(
      () => ConditionEffect(id: 'x', condition: 'blind', source: '  '),
      throwsFormatException,
    );
    expect(() => effect('x', encounter: 'fight'), throwsFormatException);
    expect(() => effect('x', round: 2), throwsFormatException);
    expect(
      () => effect('x', encounter: 'fight', round: 0),
      throwsFormatException,
    );
    final duplicate = effect('dup');
    expect(() => hero(effects: [duplicate, duplicate]), throwsFormatException);
    final json = hero().toJson();
    expect(
      () => HeroCharacter.fromJson({
        ...json,
        'conditionEffects': [
          {
            'id': 'x',
            'condition': 'blind',
            'source': 'Trap',
            'expiresAtOwnTurnEndRound': '2',
          },
        ],
      }),
      throwsFormatException,
    );
    expect(
      () => HeroCharacter.fromJson({
        ...json,
        'conditionEffects': [true],
      }),
      throwsFormatException,
    );
  });

  test('Mönch-Selbstwiederherstellung entfernt alle Quellen des Zustands', () {
    final monk = hero(
      className: 'Mönch',
      level: 10,
      conditions: ['vergiftet'],
      effects: [effect('fume'), effect('curse')],
    );
    final end = MonkSelfRestoration.atEndOfTurn(monk);
    expect(end.removed, 'vergiftet');
    expect(end.hero.conditions, isEmpty);
    expect(end.hero.conditionEffects, isEmpty);
  });

  test('Paladin-Handauflegen entfernt alle Vergiftet-Quellen', () {
    final paladin = hero(
      className: 'Paladin',
      level: 5,
      effects: [effect('a'), effect('b')],
    );
    final result = PaladinLayOnHands.useOnSelf(paladin, removePoisoned: true);
    expect(result.poisonedRemoved, isTrue);
    expect(result.hero.conditions, isEmpty);
    expect(result.hero.conditionEffects, isEmpty);
  });
}
