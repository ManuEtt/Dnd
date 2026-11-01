import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/character_effect_rules.dart';
import 'package:lebendiger_spielleiter/domain/damage_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/spellcasting_rules.dart';

class _CountingRandom implements Random {
  _CountingRandom([this.natural = 3]);
  final int natural;
  int calls = 0;

  @override
  int nextInt(int max) {
    calls++;
    return (natural - 1) % max;
  }

  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

HeroCharacter _hero() => HeroCharacter(
  id: 'concentration-class-preflight',
  name: 'Bestätigte Konzentration',
  species: 'Mensch',
  className: 'Magier',
  secondaryClassName: 'Mönch',
  secondaryClassLevel: 14,
  level: 15,
  abilities: {for (final ability in abilityNames) ability: 14},
  hitPoints: 30,
  maxHitPoints: 40,
  concentratingOn: 'Segen',
);

List<(String, HeroCharacter)> _invalidProfiles() => [
  ('unknown primary', _hero().copyWith(className: 'Unbestätigt')),
  (
    'unknown secondary',
    _hero().copyWith(
      className: 'Mönch',
      secondaryClassName: 'Unbestätigt',
      secondaryClassLevel: 1,
    ),
  ),
  ('same class aliases', _hero().copyWith(className: 'Monk')),
  ('named zero-level secondary', _hero().copyWith(secondaryClassLevel: 0)),
  (
    'unnamed secondary levels',
    _hero().copyWith(secondaryClassName: '', secondaryClassLevel: 1),
  ),
  ('negative secondary level', _hero().copyWith(secondaryClassLevel: -1)),
  ('no primary levels', _hero().copyWith(secondaryClassLevel: 15)),
  (
    'level zero',
    _hero().copyWith(level: 0, secondaryClassName: '', secondaryClassLevel: 0),
  ),
  ('level above SRD cap', _hero().copyWith(level: 21)),
  (
    'duplicate saving throw proficiency',
    _hero().copyWith(
      savingThrowProficiencies: const ['constitution', 'constitution'],
    ),
  ),
  (
    'unknown saving throw proficiency',
    _hero().copyWith(savingThrowProficiencies: const ['unknown']),
  ),
];

void main() {
  for (final (label, hero) in _invalidProfiles()) {
    for (final typed in [false, true]) {
      test('$label rejects ${typed ? 'typed' : 'untyped'} save before RNG', () {
        final random = _CountingRandom();
        final dice = DiceEngine(random: random);
        final before = jsonEncode(hero.toJson());
        expect(
          () => typed
              ? CharacterEffectRules.damage(
                  hero,
                  components: const [DamageComponent(DamageType.fire, 1)],
                  defenses: DamageDefenses(),
                  dice: dice,
                )
              : CharacterEffectRules.untypedDamage(hero, amount: 1, dice: dice),
          throwsFormatException,
        );
        expect(random.calls, 0);
        expect(jsonEncode(hero.toJson()), before);
      });
    }

    test('$label also rejects a separately supplied concentration die', () {
      final before = jsonEncode(hero.toJson());
      expect(
        () => SpellcastingRules.saveAfterDamage(hero, damage: 1, d20: 3),
        throwsFormatException,
      );
      expect(jsonEncode(hero.toJson()), before);
    });
  }

  test(
    'valid multiclass aliases keep Monk proficiency and exhaustion once',
    () {
      final hero = _hero().copyWith(
        className: 'Wizard',
        secondaryClassName: 'Monk',
        exhaustionLevel: 2,
        savingThrowProficiencies: const ['constitution'],
        temporaryHitPoints: 2,
      );
      final random = _CountingRandom(7);
      final effect = CharacterEffectRules.damage(
        hero,
        components: const [DamageComponent(DamageType.fire, 1)],
        defenses: DamageDefenses(),
        dice: DiceEngine(random: random),
      );
      // CON +2, PB +5 once despite recorded AND automatic proficiency,
      // exhaustion -4 once, natural 7 => exactly DC 10.
      expect(effect.concentrationSave!.modifier, 3);
      expect(effect.concentrationSave!.total, 10);
      expect(effect.concentrationDc, 10);
      expect(effect.concentrationLost, isFalse);
      expect(effect.hero.hitPoints, 30);
      expect(effect.hero.temporaryHitPoints, 1);
      expect(effect.hero.concentratingOn, 'Segen');
      expect(effect.hero.spentClassResources, hero.spentClassResources);
      expect(random.calls, 1);
      final direct = SpellcastingRules.saveAfterDamage(hero, damage: 1, d20: 7);
      expect(direct.total, effect.concentrationSave!.total);
      expect(direct.maintained, isTrue);
      expect(hero.temporaryHitPoints, 2);
    },
  );

  for (final className in [
    'Barbar',
    'Barde',
    'Kleriker',
    'Druide',
    'Kämpfer',
    'Mönch',
    'Paladin',
    'Waldläufer',
    'Schurke',
    'Zauberer',
    'Hexenmeister',
    'Magier',
    'Barbarian',
    'Bard',
    'Cleric',
    'Druid',
    'Fighter',
    'Monk',
    'Ranger',
    'Rogue',
    'Sorcerer',
    'Warlock',
    'Wizard',
  ]) {
    test('confirmed $className can resolve concentration from any source', () {
      final hero = _hero().copyWith(
        className: className,
        level: 14,
        secondaryClassName: '',
        secondaryClassLevel: 0,
      );
      final random = _CountingRandom(8);
      final effect = CharacterEffectRules.untypedDamage(
        hero,
        amount: 1,
        dice: DiceEngine(random: random),
      );
      final monk = className == 'Mönch' || className == 'Monk';
      expect(effect.concentrationSave!.modifier, monk ? 7 : 2);
      expect(effect.concentrationSave!.total, monk ? 15 : 10);
      expect(effect.concentrationLost, isFalse);
      expect(effect.hero.hitPoints, 29);
      expect(random.calls, 1);
    });
  }

  test('legacy unknown classes still accept damage that requires no save', () {
    final legacy = _hero().copyWith(className: 'Unbestätigt');
    final before = jsonEncode(legacy.toJson());
    final random = _CountingRandom();
    final dice = DiceEngine(random: random);
    final none = CharacterEffectRules.untypedDamage(
      legacy,
      amount: 0,
      dice: dice,
    );
    expect(none.hero.toJson(), legacy.toJson());
    final immune = CharacterEffectRules.damage(
      legacy,
      components: const [DamageComponent(DamageType.fire, 99)],
      defenses: DamageDefenses(immunities: const [DamageType.fire]),
      dice: dice,
    );
    expect(immune.hero.toJson(), legacy.toJson());
    final notConcentrating = CharacterEffectRules.untypedDamage(
      legacy.copyWith(concentratingOn: ''),
      amount: 1,
      dice: dice,
    );
    expect(notConcentrating.hero.hitPoints, 29);
    final knockedOut = CharacterEffectRules.untypedDamage(
      legacy,
      amount: 30,
      dice: dice,
    );
    expect(knockedOut.hero.hitPoints, 0);
    expect(knockedOut.hero.concentratingOn, '');
    final incapacitated = CharacterEffectRules.untypedDamage(
      legacy.copyWith(conditions: const ['betäubt']),
      amount: 1,
      dice: dice,
    );
    expect(incapacitated.hero.concentratingOn, '');
    final direct = SpellcastingRules.saveAfterDamage(
      legacy.copyWith(hitPoints: 0),
      damage: 1,
      d20: 3,
    );
    expect(direct.maintained, isFalse);
    expect(direct.hero.concentratingOn, '');
    expect(random.calls, 0);
    expect(jsonEncode(legacy.toJson()), before);
  });
}
