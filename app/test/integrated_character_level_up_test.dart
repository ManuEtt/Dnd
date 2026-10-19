import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_class_level_up.dart';

HeroCharacter example({
  String className = 'Kämpfer',
  int level = 3,
  int constitution = 13,
  int? xp = 2700,
  String subclass = 'Champion',
}) => HeroCharacter(
  id: 'integrated-asi',
  name: 'Aelia',
  species: 'Mensch',
  className: className,
  subclass: subclass,
  level: level,
  experience: xp,
  maxHitPoints: 30,
  hitPoints: 25,
  speed: 9,
  armorClass: 14,
  abilities: {
    'strength': 14,
    'dexterity': 14,
    'constitution': constitution,
    'intelligence': 12,
    'wisdom': 14,
    'charisma': 12,
  },
  inventory: const [InventoryItem(id: 'backpack', name: 'Rucksack')],
);

void main() {
  test('Main level-up includes PR10 unique ASI +2 without duplicate wizard', () {
    final original = example();
    final proposal = SrdClassLevelUpRules.propose(
      hero: original,
      className: 'Kämpfer',
      method: LevelUpMethod.experience,
      abilityIncreases: const {'strength': 2},
    );
    final result = proposal.applyTo(original);
    expect(proposal.abilityIncreases['strength'], 2);
    expect(result.level, 4);
    expect(result.abilities['strength'], 16);
    expect(result.maxHitPoints, 37); // d10 fixed 6 + CON +1
    expect(result.hitPoints, 32);
    expect(result.unverifiedNotes.any((n) =>
        n.contains('Talent oder Attributsverbesserung wählen')), isFalse);
    expect(result.inventory.single.id, 'backpack');
    expect(HeroCharacter.fromJson(result.toJson()).toJson(), result.toJson());
  });

  test('ASI +1/+1 with CON change applies retroactive HP across all levels', () {
    final original = example();
    final proposal = SrdClassLevelUpRules.propose(
      hero: original,
      className: 'Kämpfer',
      method: LevelUpMethod.experience,
      abilityIncreases: const {'constitution': 1, 'dexterity': 1},
    );
    expect(proposal.hpGain, 11); // 7 fixed + 4 retroactive CON
    final result = proposal.applyTo(original);
    expect(result.level, 4);
    expect(result.abilities['constitution'], 14);
    expect(result.abilities['dexterity'], 15);
    expect(result.maxHitPoints, 41);
    expect(result.hitPoints, 36);
    expect(result.maxHitPoints! - result.hitPoints!, 5);
  });

  test('ASI not chosen remains an explicit pending feat', () {
    final original = example();
    final result = SrdClassLevelUpRules.propose(
      hero: original,
      className: 'Kämpfer',
      method: LevelUpMethod.experience,
    ).applyTo(original);
    expect(result.abilities, original.abilities);
    expect(result.unverifiedNotes.any((n) =>
        n.contains('Talent oder Attributsverbesserung wählen')), isTrue);
  });

  test('Fighter extra feat at 6 and Rogue at 10', () {
    final fighter = example(level: 5, xp: 14000);
    final rogue = example(className: 'Schurke', level: 9, xp: 64000);
    for (final data in [(fighter, 'Kämpfer'), (rogue, 'Schurke')]) {
      final proposal = SrdClassLevelUpRules.propose(
        hero: data.$1,
        className: data.$2,
        method: LevelUpMethod.experience,
        abilityIncreases: const {'wisdom': 2},
      );
      expect(proposal.applyTo(data.$1).abilities['wisdom'], 16);
    }
  });

  test('Off-level, invalid shape, unknown or capped attributes are rejected', () {
    final start = example();
    for (final bad in [
      const {'strength': 3},
      const {'strength': 1},
      const {'strength': 1, 'dexterity': 2},
      const {'strength': 1, 'dexterity': 1, 'wisdom': 1},
      const {'invalid': 2},
    ]) {
      expect(
        () => SrdClassLevelUpRules.propose(
          hero: start, className: 'Kämpfer',
          method: LevelUpMethod.experience, abilityIncreases: bad,
        ),
        throwsFormatException,
      );
    }
    final capped = start.copyWith(
      abilities: {...start.abilities, 'strength': 20},
    );
    expect(
      () => SrdClassLevelUpRules.propose(
        hero: capped, className: 'Kämpfer',
        method: LevelUpMethod.experience,
        abilityIncreases: const {'strength': 2},
      ),
      throwsFormatException,
    );
    expect(
      () => SrdClassLevelUpRules.propose(
        hero: example(level: 2, xp: 900, subclass: ''),
        className: 'Kämpfer', method: LevelUpMethod.experience,
        abilityIncreases: const {'strength': 2},
      ),
      throwsFormatException,
    );
  });

  test('Changes to saved hero invalidate ASI proposals', () {
    final hero = example();
    final proposal = SrdClassLevelUpRules.propose(
      hero: hero, className: 'Kämpfer', method: LevelUpMethod.experience,
      abilityIncreases: const {'strength': 2},
    );
    expect(
      () => proposal.applyTo(hero.copyWith(experience: 3000)),
      throwsFormatException,
    );
    final after = proposal.applyTo(hero);
    expect(() => proposal.applyTo(after), throwsFormatException);
  });
}
