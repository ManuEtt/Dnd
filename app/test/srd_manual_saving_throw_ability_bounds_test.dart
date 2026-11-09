import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/character_rule_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_manual_saving_throw_rules.dart';

const _scores = <String, int?>{
  'strength': 14,
  'dexterity': 12,
  'constitution': 14,
  'intelligence': 10,
  'wisdom': 16,
  'charisma': 10,
};

HeroCharacter _hero({
  String className = 'Kämpfer',
  Map<String, int?>? abilities,
  List<String> conditions = const [],
}) => HeroCharacter(
  id: 'manual-auto-save-bounds',
  name: 'Rettungswurfprüfung',
  className: className,
  level: 5,
  abilities: abilities ?? _scores,
  hitPoints: 30,
  maxHitPoints: 40,
  savingThrowProficiencies: const ['strength', 'constitution'],
  conditions: conditions,
);

void main() {
  const autoConditions = [
    'gelähmt',
    'versteinert',
    'betäubt',
    'bewusstlos',
  ];
  const autoAbilities = ['strength', 'dexterity'];

  for (final condition in autoConditions) {
    for (final ability in autoAbilities) {
      test('$condition/$ability: valid score still fails without a die', () {
        final hero = _hero(conditions: [condition]);
        final before = jsonEncode(hero.toJson());
        expect(SrdManualSavingThrowRules.prepare(hero, ability), isNull);
        expect(jsonEncode(hero.toJson()), before);
      });

      test('$condition/$ability: invalid score cannot bypass preflight', () {
        for (final invalid in <int>[0, -1, 31]) {
          final hero = _hero(
            conditions: [condition],
            abilities: {..._scores, ability: invalid},
          );
          final before = jsonEncode(hero.toJson());
          expect(
            () => SrdManualSavingThrowRules.prepare(hero, ability),
            throwsFormatException,
            reason: '$condition/$ability/$invalid',
          );
          expect(jsonEncode(hero.toJson()), before);
        }
      });
    }
  }

  test('unconfirmed score still rejects automatic failure', () {
    final hero = _hero(
      conditions: const ['gelähmt'],
      abilities: {..._scores, 'strength': null},
    );
    expect(
      () => SrdManualSavingThrowRules.prepare(hero, 'strength'),
      throwsStateError,
    );
  });

  test('historical class can still fail automatically when score is valid', () {
    final hero = _hero(
      className: 'Historische Klasse',
      conditions: const ['betäubt'],
    );
    final before = jsonEncode(hero.toJson());
    expect(SrdManualSavingThrowRules.prepare(hero, 'dexterity'), isNull);
    expect(jsonEncode(hero.toJson()), before);
  });

  test('regular saving throw retains its existing class and bonus checks', () {
    final hero = _hero();
    for (final ability in autoAbilities) {
      final prepared = SrdManualSavingThrowRules.prepare(hero, ability);
      final reference = CharacterRuleEngine.savingThrow(hero, ability);
      expect(prepared, isNotNull);
      expect(prepared!.modifier, reference.modifier);
      expect(prepared.automaticallyFails, isFalse);
    }
    expect(
      () => SrdManualSavingThrowRules.prepare(
        _hero(className: 'Historische Klasse'),
        'strength',
      ),
      throwsFormatException,
    );
  });

  test('non-automatic saving throws also reject out-of-range scores', () {
    for (final bad in <int>[-1, 0, 31]) {
      final hero = _hero(abilities: {..._scores, 'wisdom': bad});
      expect(
        () => SrdManualSavingThrowRules.prepare(hero, 'wisdom'),
        throwsFormatException,
      );
    }
  });
}
