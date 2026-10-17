import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/character_rule_engine.dart';

HeroCharacter hero(String klass, int level, {String subclass = ''}) =>
    HeroCharacter(
      id: 'passive',
      name: 'Figur',
      className: klass,
      level: level,
      subclass: subclass,
      speed: 9,
      hitPoints: 15,
      abilities: const {
        'strength': 16,
        'dexterity': 14,
        'constitution': 14,
        'intelligence': 10,
        'wisdom': 12,
        'charisma': 10,
      },
    );

void main() {
  test('Barbarian Fast Movement is only applied from Barbarian 5', () {
    expect(CharacterRuleEngine.speedMeters(hero('Barbar', 4)), 9);
    expect(CharacterRuleEngine.speedMeters(hero('Barbar', 5)), 12);
    expect(CharacterRuleEngine.initiative(hero('Barbar', 6)).advantage, false);
    expect(CharacterRuleEngine.initiative(hero('Barbar', 7)).advantage, true);
    expect(
      CharacterRuleEngine.savingThrow(hero('Barbar', 2), 'dexterity').advantage,
      true,
    );
  });
  test('Monk unarmored movement scales in metres', () {
    expect(CharacterRuleEngine.speedMeters(hero('Mönch', 1)), 9);
    expect(CharacterRuleEngine.speedMeters(hero('Mönch', 2)), 12);
    expect(CharacterRuleEngine.speedMeters(hero('Mönch', 6)), 13.5);
    expect(CharacterRuleEngine.speedMeters(hero('Mönch', 18)), 18);
  });
  test('Champion gets remarkable athlete initiative advantage', () {
    expect(
      CharacterRuleEngine.initiative(
        hero('Kämpfer', 2, subclass: 'Champion'),
      ).advantage,
      false,
    );
    expect(
      CharacterRuleEngine.initiative(
        hero('Kämpfer', 3, subclass: 'Champion'),
      ).advantage,
      true,
    );
  });
}
