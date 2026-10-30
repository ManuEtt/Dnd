import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_concentration_damage_rules.dart';

HeroCharacter _hero({
  int? hitPoints = 30,
  List<String> conditions = const [],
}) => HeroCharacter(
  id: 'concentration-caster',
  name: 'Konzentrationsprüfung',
  className: 'Magier',
  level: 5,
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 16,
    'intelligence': 18,
    'wisdom': 12,
    'charisma': 10,
  },
  hitPoints: hitPoints,
  maxHitPoints: 30,
  concentratingOn: 'Invisibility',
  conditions: conditions,
);

SrdConcentrationDamageSource _damage(
  String id,
  int damage, {
  int? die = 12,
  int? modifier = 3,
  bool amountConfirmed = true,
  bool modifierConfirmed = true,
  bool rollConfirmed = true,
}) => SrdConcentrationDamageSource(
  sourceId: id,
  damageTaken: damage,
  damageConfirmed: amountConfirmed,
  confirmedNaturalD20: die,
  confirmedConstitutionSaveModifier: modifier,
  savingThrowModifiersConfirmed: modifierConfirmed,
  rollCircumstancesConfirmed: rollConfirmed,
);

SrdConcentrationDamageResult _resolve(
  HeroCharacter hero,
  List<SrdConcentrationDamageSource> sources, {
  bool snapshotConfirmed = true,
}) => SrdConcentrationDamageRules.resolve(
  hero,
  sources: sources,
  postDamageHeroSnapshotConfirmed: snapshotConfirmed,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SRD 5.2.1 damage DC rounds down and caps at 30', () {
    for (final (damage, dc) in [
      (1, 10),
      (19, 10),
      (20, 10),
      (21, 10),
      (39, 19),
      (40, 20),
      (59, 29),
      (60, 30),
      (61, 30),
      (1000000000, 30),
    ]) {
      expect(
        SrdConcentrationDamageRules.difficultyClass(damage),
        dc,
        reason: 'damage: $damage',
      );
    }
    for (final damage in [0, -1, -100]) {
      expect(
        () => SrdConcentrationDamageRules.difficultyClass(damage),
        throwsRangeError,
      );
    }
  });

  test('equal total succeeds and a lower total ends concentration', () {
    final hero = _hero();
    final before = jsonEncode(hero.toJson());
    final success = _resolve(hero, [_damage('arrow', 40, die: 17)]);
    expect(success.checks.single.difficultyClass, 20);
    expect(success.checks.single.total, 20);
    expect(success.checks.single.succeeded, isTrue);
    expect(success.hero.concentratingOn, 'Invisibility');
    expect(success.maintained, isTrue);
    expect(success.endedWithoutSave, isFalse);

    final failed = _resolve(hero, [_damage('arrow', 40, die: 16)]);
    expect(failed.checks.single.succeeded, isFalse);
    expect(failed.maintained, isFalse);
    expect(failed.endedWithoutSave, isFalse);
    expect(failed.hero.concentratingOn, isEmpty);
    expect(failed.hero.hitPoints, 30);
    expect(jsonEncode(hero.toJson()), before);
    expect(
      HeroCharacter.fromJson(failed.hero.toJson()).concentratingOn,
      isEmpty,
    );
  });

  test('saving throws do not treat natural 1 or 20 as automatic', () {
    final caster = _hero();
    final naturalTwenty = _resolve(
      caster,
      [_damage('crushing-wave', 60, die: 20, modifier: -15)],
    );
    expect(naturalTwenty.checks.single.total, 5);
    expect(naturalTwenty.checks.single.difficultyClass, 30);
    expect(naturalTwenty.maintained, isFalse);

    final naturalOne = _resolve(
      caster,
      [_damage('scratch', 1, die: 1, modifier: 20)],
    );
    expect(naturalOne.checks.single.total, 21);
    expect(naturalOne.maintained, isTrue);
  });

  test('different damage sources each require a separate save', () {
    final hero = _hero();
    final result = _resolve(
      hero,
      [
        _damage('arrow', 19, die: 7),
        _damage('breath', 60, die: 20, modifier: 10),
      ],
    );
    expect(result.checks.map((check) => check.difficultyClass).toList(), [
      10,
      30,
    ]);
    expect(result.checks.every((check) => check.succeeded), isTrue);
    expect(result.maintained, isTrue);

    final failedSecond = _resolve(
      hero,
      [
        _damage('arrow', 19, die: 7),
        _damage('breath', 60, die: 19, modifier: 10),
        _damage('later', 1, die: 20),
      ],
    );
    expect(failedSecond.checks.map((check) => check.sourceId).toList(), [
      'arrow',
      'breath',
    ]);
    expect(failedSecond.maintained, isFalse);
    expect(failedSecond.hero.concentratingOn, isEmpty);
    expect(hero.concentratingOn, 'Invisibility');
  });

  test('invalid later confirmation cannot hide behind an earlier failure', () {
    final hero = _hero();
    final original = jsonEncode(hero.toJson());
    for (final invalid in [
      _damage('later', 5, die: null),
      _damage('later', 5, modifier: null),
      _damage('later', 5, modifierConfirmed: false),
      _damage('later', 5, rollConfirmed: false),
      _damage('later', 5, die: 21),
      _damage('later', 5, die: 0),
      _damage('later', 5, modifier: 31),
      _damage('later', 5, modifier: -31),
    ]) {
      expect(
        () => _resolve(
          hero,
          [_damage('first', 40, die: 1), invalid],
        ),
        throwsFormatException,
      );
    }
    expect(jsonEncode(hero.toJson()), original);
  });

  test('unconfirmed or ambiguous damage sources fail before transition', () {
    final hero = _hero();
    final sources = [
      [_damage('arrow', 5, amountConfirmed: false)],
      [_damage('arrow', 5), _damage('arrow', 5)],
      [_damage('', 5)],
      [_damage(' arrow', 5)],
      [_damage('arrow ', 5)],
      [_damage('arrow\nextra', 5)],
      [_damage('arrow\u202eextra', 5)],
      [_damage('arrow\u200bextra', 5)],
      [_damage(List.filled(129, 'x').join(), 5)],
      [_damage('arrow', 0)],
      [_damage('arrow', -2)],
    ];
    for (final batch in sources) {
      expect(
        () => _resolve(hero, batch),
        throwsA(anyOf(isA<FormatException>(), isA<RangeError>())),
      );
    }
    expect(() => _resolve(hero, const []), throwsFormatException);
    expect(
      () => _resolve(hero, [_damage('arrow', 10)], snapshotConfirmed: false),
      throwsFormatException,
    );
  });

  test('incapacity and zero hit points end concentration without a roll', () {
    for (final hero in [
      _hero(hitPoints: 0),
      _hero(conditions: ['bewusstlos']),
      _hero(conditions: ['betäubt']),
      _hero(conditions: ['gelähmt']),
      _hero(conditions: ['handlungsunfähig']),
      _hero(conditions: ['tot']),
    ]) {
      final before = jsonEncode(hero.toJson());
      final result = _resolve(
        hero,
        [_damage('collapse', 20, die: null, modifier: null)],
      );
      expect(result.endedWithoutSave, isTrue);
      expect(result.checks, isEmpty);
      expect(result.maintained, isFalse);
      expect(result.hero.concentratingOn, isEmpty);
      expect(jsonEncode(hero.toJson()), before);
    }
  });

  test('unknown hit points and absent concentration fail closed', () {
    expect(
      () => _resolve(
        _hero(hitPoints: null),
        [_damage('arrow', 10)],
      ),
      throwsFormatException,
    );
    expect(
      () => _resolve(
        _hero().copyWith(concentratingOn: ''),
        [_damage('arrow', 10)],
      ),
      throwsFormatException,
    );
    expect(
      () => _resolve(
        _hero().copyWith(concentratingOn: ' Invisibility '),
        [_damage('arrow', 10)],
      ),
      throwsFormatException,
    );
  });
}
