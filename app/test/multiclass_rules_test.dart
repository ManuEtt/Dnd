import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/multiclass_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_classes.dart';

HeroCharacter hero({
  String first = 'Kämpfer', int level = 3, int strength = 14,
  int dexterity = 14, int constitution = 14, int wisdom = 14,
  int charisma = 14, int intelligence = 14,
  String second = '', int secondLevel = 0,
}) => HeroCharacter(
  id: 'hero', name: 'Tira', className: first, level: level,
  secondaryClassName: second, secondaryClassLevel: secondLevel,
  hitPoints: 16, maxHitPoints: 22,
  abilities: {
    'strength': strength, 'dexterity': dexterity,
    'constitution': constitution, 'wisdom': wisdom,
    'charisma': charisma, 'intelligence': intelligence,
  },
  savingThrowProficiencies: const ['strength','constitution'],
  skills: const ['Athletik'],
  inventory: const [InventoryItem(id: 'rope', name: 'Seil')],
);

void main() {
  test('all 12 SRD classes have multiclass prerequisites', () {
    for (final definition in srdCharacterClasses) {
      expect(MulticlassRules.prerequisites.containsKey(definition.name), isTrue);
    }
  });

  test('multiclass fighter / bard: total level, fixed HP, saves preserved', () {
    final original = hero();
    final p = MulticlassRules.propose(
      hero: original, newClass: 'Barde', selectedSkill: 'Auftreten');
    expect(p.totalLevel, 4);
    expect(p.hpGain, 7); // d8 fixed 5 + CON +2
    final updated = p.applyTo(original);
    expect(updated.primaryClassLevel, 3);
    expect(updated.secondaryClassLevel, 1);
    expect(updated.level, 4);
    expect(updated.hitPoints, 23);
    expect(updated.maxHitPoints, 29);
    expect(updated.skills, containsAll(['Athletik','Auftreten']));
    expect(updated.savingThrowProficiencies, ['strength','constitution']);
    expect(updated.inventory.single.name, 'Seil');
    expect(updated.gold, isNull);
    final restored = HeroCharacter.fromJson(updated.toJson());
    expect(restored.secondaryClassName, 'Barde');
    expect(restored.secondaryClassLevel, 1);
    expect(restored.primaryClassLevel, 3);
  });

  test('existing schemaVersion 1 hero remains single-class', () {
    final json = hero().toJson();
    expect(json.containsKey('secondaryClassName'), isFalse);
    final restored = HeroCharacter.fromJson(json);
    expect(restored.hasSecondClass, isFalse);
    expect(restored.primaryClassLevel, restored.level);
  });

  test('fighter can qualify with strength OR dexterity, ranger needs BOTH', () {
    final qualified = hero(first: 'Kämpfer', strength: 8, dexterity: 13,
        wisdom: 13);
    expect(MulticlassRules.prerequisiteError(qualified, 'Waldläufer'), isNull);
    final unqualified = hero(first: 'Kämpfer', strength: 8, dexterity: 12,
        wisdom: 20);
    expect(MulticlassRules.prerequisiteError(unqualified, 'Waldläufer'),
        isNotNull);
    expect(() => MulticlassRules.propose(hero: unqualified,
        newClass: 'Waldläufer', selectedSkill: 'Überlebenskunst'),
        throwsFormatException);
  });

  test('bypassing prerequisites and missing constitution are rejected', () {
    final character = hero(first: 'Paladin', strength: 14, charisma: 12);
    expect(() => MulticlassRules.propose(hero: character,
        newClass: 'Magier'), throwsFormatException);
    final unknown = hero().copyWith(abilities: {
      for (final key in hero().abilities.keys)
        key: key == 'constitution' ? null : 14,
    });
    expect(() => MulticlassRules.propose(hero: unknown, newClass: 'Magier'),
        throwsFormatException);
  });

  test('bard, ranger, rogue get one class skill, never old-class savings', () {
    for (final name in ['Barde', 'Waldläufer', 'Schurke']) {
      final character = hero();
      expect(MulticlassRules.availableSkills(character, name), isNotEmpty);
      expect(() => MulticlassRules.propose(hero: character,
          newClass: name), throwsFormatException);
      final choice = MulticlassRules.availableSkills(character, name).first;
      final result = MulticlassRules.propose(hero: character,
          newClass: name, selectedSkill: choice).applyTo(character);
      expect(result.skills, contains(choice));
      expect(result.savingThrowProficiencies,
          character.savingThrowProficiencies);
    }
  });

  test('later second-class levels do not award a new skill again', () {
    final character = hero(first: 'Kämpfer',level:4,
        second:'Barde', secondLevel:1);
    final p = MulticlassRules.propose(hero: character, newClass: 'Barde');
    final result = p.applyTo(character);
    expect(result.secondaryClassLevel, 2);
    expect(result.primaryClassLevel, 3);
    expect(result.skills, character.skills);
  });

  test('single-class and invalid multi-class state validation', () {
    final input = hero().toJson();
    input['secondaryClassName'] = 'Barde';
    input['secondaryClassLevel'] = 3;
    expect(() => HeroCharacter.fromJson(input), throwsFormatException);
    input['secondaryClassLevel'] = 1;
    expect(HeroCharacter.fromJson(input).hasSecondClass, isTrue);
    input['secondaryClassName'] = '';
    expect(() => HeroCharacter.fromJson(input), throwsFormatException);
  });

  test('maximum 20 levels, no third class and stale proposal protection', () {
    expect(() => MulticlassRules.propose(hero: hero(level:20),
        newClass:'Barde', selectedSkill:'Auftreten'), throwsFormatException);
    final character = hero(second:'Magier', secondLevel:1);
    expect(() => MulticlassRules.propose(hero: character,newClass:'Barde'),
        throwsFormatException);
    final p = MulticlassRules.propose(hero: hero(),newClass:'Magier');
    expect(() => p.applyTo(hero(level:5)), throwsFormatException);
  });

  test('spell slot math uses class levels and half rounded up for paladin', () {
    final character = hero(first:'Paladin', level:8,
        second:'Magier', secondLevel:3);
    expect(character.primaryClassLevel,5);
    expect(MulticlassRules.combinedSpellcasterLevel(character),6);
    expect(MulticlassRules.spellSlots(character).take(3),[4,3,3]);
    expect(MulticlassRules.combinedSpellcasterLevel(
        hero(first:'Hexenmeister',level:3,second:'Magier',secondLevel:1)),1);
  });
}
