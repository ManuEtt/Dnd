import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_saving_throw_rules.dart';

HeroCharacter _caster({
  String className = 'Magier',
  int level = 5,
  String secondaryClassName = '',
  int secondaryClassLevel = 0,
  Map<String, int?>? abilities,
}) => HeroCharacter(
  id: 'spell-class-stats',
  name: 'Klassenzauber',
  className: className,
  level: level,
  secondaryClassName: secondaryClassName,
  secondaryClassLevel: secondaryClassLevel,
  abilities:
      abilities ??
      const {
        'strength': 10,
        'dexterity': 12,
        'constitution': 14,
        'intelligence': 18,
        'wisdom': 16,
        'charisma': 14,
      },
  hitPoints: 25,
  maxHitPoints: 25,
);

SrdClassSpellStats _stats(HeroCharacter hero, String className) =>
    SrdSpellSavingThrowRules.statsForClass(
      hero,
      castingClass: className,
      noUnmodelledModifiersConfirmed: true,
    );

void main() {
  test('all eight SRD caster classes use their own class ability', () {
    const expected = <String, String>{
      'Barde': 'charisma',
      'Kleriker': 'wisdom',
      'Druide': 'wisdom',
      'Paladin': 'charisma',
      'Waldläufer': 'wisdom',
      'Zauberer': 'charisma',
      'Hexenmeister': 'charisma',
      'Magier': 'intelligence',
    };
    for (final pair in expected.entries) {
      final result = _stats(_caster(className: pair.key), pair.key);
      expect(result.castingClass, pair.key);
      expect(result.ability, pair.value);
      expect(result.proficiencyBonus, 3);
      expect(result.spellSaveDc, result.spellAttackModifier + 8);
      expect(result.abilityScore, isIn([14, 16, 18]));
    }
  });

  test('base DC and spell attack bonus use ability and total proficiency', () {
    final low = _stats(_caster(level: 1), 'Magier');
    expect(low.abilityModifier, 4);
    expect(low.proficiencyBonus, 2);
    expect(low.spellAttackModifier, 6);
    expect(low.spellSaveDc, 14);

    final high = _stats(_caster(level: 20), 'Magier');
    expect(high.proficiencyBonus, 6);
    expect(high.spellAttackModifier, 10);
    expect(high.spellSaveDc, 18);
  });

  test('multiclass spells use their own class ability, not the other', () {
    final hero = _caster(
      className: 'Zauberer',
      level: 8,
      secondaryClassName: 'Magier',
      secondaryClassLevel: 3,
    );
    final sorcerer = _stats(hero, 'Zauberer');
    final wizard = _stats(hero, 'wizard');
    expect(sorcerer.ability, 'charisma');
    expect(wizard.ability, 'intelligence');
    expect(sorcerer.proficiencyBonus, 3);
    expect(wizard.proficiencyBonus, 3);
    expect(sorcerer.spellAttackModifier, 5);
    expect(sorcerer.spellSaveDc, 13);
    expect(wizard.spellAttackModifier, 7);
    expect(wizard.spellSaveDc, 15);
  });

  test('localized and English class aliases preserve confirmed class', () {
    final hero = _caster(className: 'Magierin');
    expect(_stats(hero, 'wizard').castingClass, 'Magier');
    expect(_stats(hero, 'Magier').spellSaveDc, 15);
    expect(
      _stats(_caster(className: 'Waldläufer'), 'ranger').ability,
      'wisdom',
    );
  });

  test('foreign and noncasting classes cannot claim spell stats', () {
    final hero = _caster(className: 'Magier');
    for (final name in ['Zauberer', 'Kämpfer', 'Nicht vorhanden']) {
      expect(() => _stats(hero, name), throwsFormatException);
    }
    expect(
      () => _stats(_caster(className: 'Kämpfer'), 'Magier'),
      throwsFormatException,
    );
    expect(
      () => _stats(
        _caster(className: 'Unbekannte Klasse'),
        'Magier',
      ),
      throwsFormatException,
    );
  });

  test('unconfirmed overrides and unverified attributes fail closed', () {
    final hero = _caster();
    expect(
      () => SrdSpellSavingThrowRules.statsForClass(
        hero,
        castingClass: 'Magier',
        noUnmodelledModifiersConfirmed: false,
      ),
      throwsFormatException,
    );
    for (final score in <int?>[null, 0, -2, 31]) {
      final hero = _caster(
        abilities: {
          ..._caster().abilities,
          'intelligence': score,
        },
      );
      expect(() => _stats(hero, 'Magier'), throwsFormatException);
    }
  });

  test('inconsistent class levels and duplicate classes fail closed', () {
    for (final hero in [
      _caster(level: 0),
      _caster(level: 21),
      _caster(level: 3, secondaryClassLevel: 1),
      _caster(
        level: 5,
        secondaryClassName: 'Zauberer',
        secondaryClassLevel: 0,
      ),
      _caster(
        level: 5,
        secondaryClassName: 'Zauberer',
        secondaryClassLevel: 5,
      ),
      _caster(
        level: 5,
        secondaryClassName: 'Magier',
        secondaryClassLevel: 2,
      ),
      _caster(
        level: 5,
        secondaryClassName: 'Unbekannt',
        secondaryClassLevel: 2,
      ),
    ]) {
      expect(() => _stats(hero, 'Magier'), throwsFormatException);
    }
  });

  test('pure calculation does not change spells, resources or JSON state', () {
    final hero = _caster().copyWith(
      spells: const ['Magisches Geschoss'],
      spentSpellSlots: const {'1': 1},
      concentratingOn: 'Unsichtbarkeit',
    );
    final before = jsonEncode(hero.toJson());
    final stats = _stats(hero, 'Magier');
    expect(stats.spellAttackModifier, 7);
    expect(jsonEncode(hero.toJson()), before);
    expect(hero.spentSpellSlots, {'1': 1});
    expect(hero.concentratingOn, 'Unsichtbarkeit');
  });
}
