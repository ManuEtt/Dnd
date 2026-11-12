import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_saving_throw_rules.dart';

const _abilities = <String, int?>{
  'strength': 18,
  'dexterity': 12,
  'constitution': 14,
  'intelligence': 18,
  'wisdom': 16,
  'charisma': 14,
};

HeroCharacter _caster({
  String className = 'Magier',
  int level = 5,
  String secondaryClassName = '',
  int secondaryClassLevel = 0,
  Map<String, int?>? abilities,
}) => HeroCharacter(
  id: 'class-bound-dc',
  name: 'Zauberprüfung',
  className: className,
  level: level,
  secondaryClassName: secondaryClassName,
  secondaryClassLevel: secondaryClassLevel,
  abilities: abilities ?? _abilities,
  hitPoints: 20,
  maxHitPoints: 20,
  spells: const ['Säurespritzer'],
);

int _dc(HeroCharacter hero, String ability, {bool confirmed = true}) =>
    SrdSpellSavingThrowRules.spellSaveDc(
      hero,
      spellcastingAbility: ability,
      noUnmodelledDcModifiersConfirmed: confirmed,
    );

void main() {
  test('eight canonical casters and class aliases retain their SRD DC', () {
    const examples = <(String, String, int)>[
      ('Barde', 'charisma', 13),
      ('Kleriker', 'wisdom', 14),
      ('Druide', 'wisdom', 14),
      ('Paladin', 'charisma', 13),
      ('Waldläufer', 'wisdom', 14),
      ('Zauberer', 'charisma', 13),
      ('Hexenmeister', 'charisma', 13),
      ('Magier', 'intelligence', 15),
      ('Magierin', 'intelligence', 15),
      ('Wizard', 'intelligence', 15),
    ];
    for (final example in examples) {
      expect(
        _dc(_caster(className: example.$1), example.$2),
        example.$3,
        reason: example.$1,
      );
    }
  });

  test('two valid class abilities use proficiency from total levels', () {
    final hero = _caster(
      className: 'Wizard',
      level: 6,
      secondaryClassName: 'Cleric',
      secondaryClassLevel: 1,
    );
    expect(_dc(hero, 'intelligence'), 15);
    expect(_dc(hero, 'wisdom'), 14);
    expect(
      SrdSpellSavingThrowRules.statsForClass(
        hero,
        castingClass: 'Cleric',
        noUnmodelledModifiersConfirmed: true,
      ).spellSaveDc,
      _dc(hero, 'wisdom'),
    );
  });

  test('unrelated abilities cannot fabricate a class spell save DC', () {
    final cleric = _caster(className: 'Kleriker');
    for (final ability in [
      'strength',
      'dexterity',
      'constitution',
      'intelligence',
      'charisma',
      'Wisdom',
      '',
      'spellcasting',
    ]) {
      expect(
        () => _dc(cleric, ability),
        throwsFormatException,
        reason: ability,
      );
    }
    expect(
      () => _dc(_caster(className: 'Kämpfer'), 'intelligence'),
      throwsFormatException,
    );
  });

  test('invalid classes and inconsistent multiclass profiles fail closed', () {
    final profiles = <HeroCharacter>[
      _caster(level: 0),
      _caster(level: 21),
      _caster(className: 'Unbekannt'),
      _caster(secondaryClassLevel: 1),
      _caster(secondaryClassName: 'Kleriker'),
      _caster(secondaryClassName: 'Kleriker', secondaryClassLevel: -1),
      _caster(secondaryClassName: 'Kleriker', secondaryClassLevel: 5),
      _caster(secondaryClassName: 'Unbekannt', secondaryClassLevel: 1),
      _caster(
        className: 'Wizard',
        secondaryClassName: 'Magier',
        secondaryClassLevel: 1,
      ),
      _caster(
        className: 'Unbekannt',
        secondaryClassName: 'Wizard',
        secondaryClassLevel: 1,
      ),
    ];
    for (final hero in profiles) {
      expect(
        () => _dc(hero, 'intelligence'),
        throwsFormatException,
        reason: '${hero.className}/${hero.secondaryClassName}: ${hero.level}',
      );
    }
  });

  test('invalid class ability scores and missing consent fail closed', () {
    for (final value in <int?>[null, 0, -1, 31]) {
      expect(
        () => _dc(
          _caster(abilities: {..._abilities, 'intelligence': value}),
          'intelligence',
        ),
        throwsFormatException,
      );
    }
    expect(
      () => _dc(_caster(), 'intelligence', confirmed: false),
      throwsFormatException,
    );
  });

  test('positive and rejected calculations do not modify save data', () {
    final hero = _caster().copyWith(
      spentSpellSlots: const {'1': 1},
      concentratingOn: 'Unsichtbarkeit',
    );
    final before = jsonEncode(hero.toJson());
    expect(_dc(hero, 'intelligence'), 15);
    expect(() => _dc(hero, 'strength'), throwsFormatException);
    expect(jsonEncode(hero.toJson()), before);
  });
}
