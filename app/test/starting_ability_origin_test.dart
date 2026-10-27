import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/starting_ability_origin.dart';

const original = <String, int>{
  'strength': 15,
  'dexterity': 14,
  'constitution': 13,
  'intelligence': 12,
  'wisdom': 10,
  'charisma': 8,
};

StartingAbilityOrigin soldier() => StartingAbilityOrigin.confirmed(
  method: 'standardArray',
  baseScores: original,
  background: 'Soldat',
  increases: {'strength': 2, 'constitution': 1},
);

void main() {
  test('confirmed origin round-trips and does not reapply any bonus', () {
    final record = soldier();
    expect(record.startingScores['strength'], 17);
    expect(record.startingScores['constitution'], 14);
    final hero = HeroCharacter(
      id: 'new',
      name: 'Held',
      abilities: record.startingScores,
      background: 'Soldat',
      startingAbilityOrigin: record,
    );
    final encoded = hero.toJson();
    expect(encoded['schemaVersion'], 1);
    expect(encoded['startingAbilityOrigin']['version'], 1);
    final restored = HeroCharacter.fromJson(encoded);
    expect(restored.toJson(), encoded);
    expect(restored.startingAbilityOrigin!.baseScores, original);
    expect(restored.abilities['strength'], 17);
    expect(
      restored
          .copyWith(
            level: 2,
            abilities: {...restored.abilities, 'strength': 18},
          )
          .startingAbilityOrigin!
          .startingScores['strength'],
      17,
    );
    expect(() => record.baseScores['strength'] = 8, throwsUnsupportedError);
    expect(() => record.increases['strength'] = 4, throwsUnsupportedError);
  });

  test('old saves without provenance remain byte-identical', () {
    final oldHero = HeroCharacter(id: 'legacy', name: 'Alt');
    final oldJson = oldHero.toJson();
    expect(oldJson.containsKey('startingAbilityOrigin'), false);
    expect(HeroCharacter.fromJson(oldJson).toJson(), oldJson);
    expect(
      oldHero
          .copyWith(startingAbilityOrigin: soldier())
          .copyWith(startingAbilityOrigin: null)
          .toJson(),
      oldJson,
    );
  });

  test('all three SRD methods accept faithful evidence', () {
    final point = StartingAbilityOrigin.confirmed(
      method: 'pointBuy',
      baseScores: {
        'strength': 15,
        'dexterity': 15,
        'constitution': 15,
        'intelligence': 8,
        'wisdom': 8,
        'charisma': 8,
      },
      background: 'Krimineller',
      increases: {'dexterity': 1, 'constitution': 1, 'intelligence': 1},
    );
    expect(point.startingScores['dexterity'], 16);
    expect(point.rolledScores, isEmpty);
    // The standard-array numbers also form a valid 27-point purchase.
    // Their method cannot be inferred from the resulting values alone.
    expect(
      StartingAbilityOrigin.confirmed(
        method: 'pointBuy',
        baseScores: original,
        background: 'Soldat',
        increases: {'strength': 2, 'constitution': 1},
      ).startingScores,
      soldier().startingScores,
    );
    expect(
      StartingAbilityOrigin.fromJson(point.toJson()).toJson(),
      point.toJson(),
    );
    final random = StartingAbilityOrigin.confirmed(
      method: 'randomRoll',
      baseScores: {
        'strength': 18,
        'dexterity': 15,
        'constitution': 12,
        'intelligence': 9,
        'wisdom': 6,
        'charisma': 3,
      },
      background: 'Soldat',
      increases: {'strength': 1, 'dexterity': 1, 'constitution': 1},
      diceRolls: [
        [6, 6, 6, 1],
        [5, 5, 5, 1],
        [4, 4, 4, 1],
        [3, 3, 3, 1],
        [2, 2, 2, 1],
        [1, 1, 1, 1],
      ],
    );
    expect(random.startingScores['strength'], 19);
    expect(random.rolledScores, [18, 15, 12, 9, 6, 3]);
    expect(() => random.rolledScores[0] = 1, throwsUnsupportedError);
    expect(
      StartingAbilityOrigin.fromJson(random.toJson()).toJson(),
      random.toJson(),
    );
    expect(() => random.diceRolls.first[0] = 1, throwsUnsupportedError);
  });

  test('forged dice, missing attributes, bonuses and methods fail closed', () {
    final good = soldier().toJson();
    final malformed = <Map<String, dynamic>>[
      {...good, 'version': 2},
      {...good, 'version': 1.0},
      {...good, 'version': '1'},
      {...good, 'method': 'dice-cheat'},
      {
        ...good,
        'baseScores': {...original, 'luck': 9},
      },
      {
        ...good,
        'baseScores': {...original}..remove('wisdom'),
      },
      {
        ...good,
        'increases': {'strength': 2, 'dexterity': 2},
      },
      {...good, 'background': 'Freier Hintergrund'},
      {
        ...good,
        'diceRolls': [
          [6, 6, 6, 6],
        ],
      },
      {...good, 'method': 'randomRoll', 'diceRolls': []},
      {
        ...good,
        'method': 'pointBuy',
        'baseScores': {for (final key in original.keys) key: 15},
      },
    ];
    for (final entry in malformed) {
      expect(
        () => StartingAbilityOrigin.fromJson(entry),
        throwsFormatException,
      );
    }
    final validRoll = StartingAbilityOrigin.confirmed(
      method: 'randomRoll',
      baseScores: {
        'strength': 18,
        'dexterity': 15,
        'constitution': 12,
        'intelligence': 9,
        'wisdom': 6,
        'charisma': 3,
      },
      background: 'Soldat',
      increases: {'strength': 1, 'dexterity': 1, 'constitution': 1},
      diceRolls: [
        [6, 6, 6, 1],
        [5, 5, 5, 1],
        [4, 4, 4, 1],
        [3, 3, 3, 1],
        [2, 2, 2, 1],
        [1, 1, 1, 1],
      ],
    ).toJson();
    for (final alteration in [
      {
        ...validRoll,
        'diceRolls': [
          [6, 6, 6, 8],
        ],
      },
      {
        ...validRoll,
        'diceRolls': [
          [6, 6, 6, 1],
        ],
      },
      {
        ...validRoll,
        'diceRolls': [
          [6, 6, 6, 1],
          [5, 5, 5, 1],
          [4, 4, 4, 1],
          [3, 3, 3, 1],
          [2, 2, 2, 1],
          [1, 1, 1, 6],
        ],
      },
    ]) {
      expect(
        () => StartingAbilityOrigin.fromJson(alteration),
        throwsFormatException,
      );
    }
  });

  test('invalid payload cannot enter HeroCharacter by JSON', () {
    final json = HeroCharacter(
      id: 'test',
      name: 'Tester',
    ).copyWith(startingAbilityOrigin: soldier()).toJson();
    (json['startingAbilityOrigin'] as Map<String, dynamic>)['method'] =
        'invalid';
    expect(() => HeroCharacter.fromJson(json), throwsFormatException);
  });
}
