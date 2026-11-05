import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/character_rule_engine.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_classes.dart';

class _Random implements Random {
  int draws = 0;
  @override
  int nextInt(int max) {
    draws++;
    return 0;
  }

  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

HeroCharacter _hero({
  String primary = 'Fighter',
  String secondary = '',
  int level = 15,
  int secondaryLevel = 0,
  List<String> proficiencies = const ['wisdom'],
}) => HeroCharacter(
  id: 'manual-save-profile',
  name: 'Bestätigter Charakter',
  className: primary,
  secondaryClassName: secondary,
  level: level,
  secondaryClassLevel: secondaryLevel,
  hitPoints: 30,
  maxHitPoints: 40,
  savingThrowProficiencies: proficiencies,
  abilities: {for (final ability in abilityNames) ability: 14},
);

void main() {
  late _Random random;
  late GameEngine engine;
  setUp(() {
    random = _Random();
    engine = GameEngine(
      dice: DiceEngine(random: random),
      clock: () => DateTime.utc(2026, 11, 2),
    );
  });

  final invalid = <String, HeroCharacter>{
    'unknown primary cannot authorize Monk 14': _hero(
      primary: 'Historisch',
      secondary: 'Monk',
      secondaryLevel: 14,
    ),
    'unknown primary cannot authorize Rogue 15': _hero(
      primary: 'Historisch',
      secondary: 'Rogue',
      level: 16,
      secondaryLevel: 15,
    ),
    'unknown primary cannot authorize Danger Sense': _hero(
      primary: 'Historisch',
      secondary: 'Barbarian',
      level: 3,
      secondaryLevel: 2,
    ),
    'unknown secondary': _hero(secondary: 'Unbestätigt', secondaryLevel: 1),
    'duplicate canonical class': _hero(secondary: 'Kämpfer', secondaryLevel: 6),
    'named secondary level zero': _hero(secondary: 'Wizard'),
    'unnamed secondary has levels': _hero(secondaryLevel: 1),
    'negative secondary': _hero(secondaryLevel: -1),
    'no primary level': _hero(secondary: 'Monk', secondaryLevel: 15),
    'above total limit': _hero(level: 21),
    'zero total': _hero(level: 0),
    'unknown recorded training': _hero(proficiencies: const ['flying']),
    'duplicate training': _hero(proficiencies: const ['wisdom', 'wisdom']),
  };
  for (final entry in invalid.entries) {
    for (final ability in ['Weisheit', 'Geschicklichkeit']) {
      test('${entry.key}: $ability rejected before any d20', () {
        final hero = entry.value;
        final before = jsonEncode(hero.toJson());
        final campaign = engine.createDemo().copyWith(hero: hero);
        final result = engine.act(campaign, 'Rettungswurf: $ability SG 20');
        expect(result.events.single.type, 'rules.blocked');
        expect(result.events.single.payload.containsKey('roll'), isFalse);
        expect(random.draws, 0);
        expect(jsonEncode(result.campaign.hero.toJson()), before);
        expect(jsonEncode(hero.toJson()), before);
      });
    }
  }

  for (final cls in srdCharacterClasses) {
    test('${cls.name}: valid profile delegates the existing save formula', () {
      final hero = _hero(primary: cls.name).copyWith(exhaustionLevel: 1);
      final before = jsonEncode(hero.toJson());
      final expected = CharacterRuleEngine.savingThrow(hero, 'wisdom');
      final result = engine.act(
        engine.createDemo().copyWith(hero: hero),
        'Rettungswurf: Weisheit SG 20',
      );
      expect(result.events.single.type, 'saving.roll');
      final roll = result.events.single.payload['roll'] as Map;
      expect(roll['modifier'], expected.modifier);
      expect(roll['total'], 1 + expected.modifier);
      expect(random.draws, 1);
      expect(jsonEncode(result.campaign.hero.toJson()), before);
    });
  }

  for (final condition in ['gelähmt', 'versteinert', 'betäubt', 'bewusstlos']) {
    for (final ability in ['Stärke', 'Geschicklichkeit']) {
      test('$condition/$ability: automatic failure needs no class bonus', () {
        final hero = _hero(
          primary: 'Historische Klasse',
        ).copyWith(conditions: [condition]);
        final result = engine.act(
          engine.createDemo().copyWith(hero: hero),
          'Rettungswurf: $ability SG 20',
        );
        expect(result.events.single.type, 'saving.automaticFailure');
        expect(result.events.single.payload.containsKey('roll'), isFalse);
        expect(result.events.single.payload.containsKey('total'), isFalse);
        expect(random.draws, 0);
      });
    }
  }

  test('unconfirmed attribute still rejects even an automatic failure', () {
    final hero = _hero().copyWith(
      abilities: const {},
      conditions: const ['gelähmt'],
    );
    final result = engine.act(
      engine.createDemo().copyWith(hero: hero),
      'Rettungswurf: Stärke SG 20',
    );
    expect(result.events.single.type, 'rules.blocked');
    expect(random.draws, 0);
  });

  test(
    'valid English multiclass alias keeps Monk proficiency exactly once',
    () {
      final hero = _hero(
        primary: 'Wizard',
        secondary: ' MONK ',
        secondaryLevel: 14,
      ).copyWith(exhaustionLevel: 1);
      final result = engine.act(
        engine.createDemo().copyWith(hero: hero),
        'Rettungswurf: Weisheit SG 20',
      );
      expect(result.events.single.type, 'saving.roll');
      final roll = result.events.single.payload['roll'] as Map;
      expect(roll['modifier'], 5); // +2 Wisdom +5 proficiency -2 Exhaustion.
      expect(roll['total'], 6);
      expect(random.draws, 1);
      expect(result.campaign.hero.className, 'Wizard');
      expect(result.campaign.hero.secondaryClassName, ' MONK ');
    },
  );
}
