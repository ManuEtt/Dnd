import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/character_creation_progression.dart';
import 'package:lebendiger_spielleiter/domain/experience_progression.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_class_level_up.dart';

void main() {
  test('XP-Schwellen und Übungsbonus stimmen mit der SRD-Tabelle überein', () {
    expect(ExperienceProgression.thresholds, hasLength(20));
    expect(ExperienceProgression.levelForXp(0), 1);
    expect(ExperienceProgression.levelForXp(299), 1);
    expect(ExperienceProgression.levelForXp(300), 2);
    expect(ExperienceProgression.levelForXp(355000), 20);
    expect(ExperienceProgression.nextThreshold(20), isNull);
    for (var level = 1; level <= 20; level++) {
      final threshold = CharacterCreationProgression.startingExperience(level);
      expect(ExperienceProgression.levelForXp(threshold), level);
      expect(
        ExperienceProgression.proficiencyBonus(level),
        CharacterCreationProgression.proficiencyBonus(level),
      );
      if (level < 20) {
        expect(
          ExperienceProgression.nextThreshold(level),
          CharacterCreationProgression.startingExperience(level + 1),
        );
      }
    }
    expect(() => ExperienceProgression.levelForXp(-1), throwsFormatException);
    expect(() => ExperienceProgression.nextThreshold(0), throwsRangeError);
    expect(() => ExperienceProgression.nextThreshold(21), throwsRangeError);
  });

  test('Belohnung ist eindeutig und bleibt nach Speichern idempotent', () {
    final original = GameEngine().createDemo();
    final rewarded = ExperienceProgression.grant(
      original,
      rewardId: 'kapitel-1',
      amount: 300,
    );
    expect(rewarded.hero.experience, 300);
    expect(rewarded.hero.level, original.hero.level);
    expect(rewarded.facts['xp.reward.kapitel-1'], '300');
    expect(rewarded.facts['xp.levelUpAvailable'], 'true');
    expect(ExperienceProgression.pendingLevels(rewarded.hero), 1);

    final loaded = Campaign.fromJson(rewarded.toJson());
    expect(
      ExperienceProgression.grant(
        loaded,
        rewardId: 'kapitel-1',
        amount: 300,
      ).toJson(),
      loaded.toJson(),
    );
  });

  test('Unbestätigte historische XP werden nicht stillschweigend zu null', () {
    final original = GameEngine().createDemo();
    final unknown = original.copyWith(
      hero: original.hero.copyWith(experience: null),
    );
    expect(ExperienceProgression.pendingLevels(unknown.hero), 0);
    expect(
      () => ExperienceProgression.grant(
        unknown,
        rewardId: 'kapitel-1',
        amount: 50,
      ),
      throwsFormatException,
    );
    expect(unknown.facts.containsKey('xp.reward.kapitel-1'), isFalse);
  });


  test('EP erlauben mehrere getrennte, nicht automatische Aufstiege', () {
    final initial = GameEngine().createDemo().hero.copyWith(experience: 6500);
    expect(initial.level, 1);
    expect(ExperienceProgression.reachableLevel(initial), 5);
    expect(ExperienceProgression.pendingLevels(initial), 4);
    expect(ExperienceProgression.pointsUntilNextLevel(initial), 0);
    expect(ExperienceProgression.progressToNextLevel(initial), 1.0);

    var hero = initial;
    for (var target = 2; target <= 5; target++) {
      final proposal = SrdClassLevelUpRules.propose(
        hero: hero,
        className: hero.className,
        method: LevelUpMethod.experience,
      );
      hero = proposal.applyTo(hero);
      hero = HeroCharacter.fromJson(hero.toJson());
      expect(hero.level, target);
      expect(hero.experience, 6500);
      expect(ExperienceProgression.pendingLevels(hero), 5 - target);
      expect(ExperienceProgression.reachableLevel(hero), 5);
    }
    expect(ExperienceProgression.pointsUntilNextLevel(hero), 7500);
    expect(ExperienceProgression.progressToNextLevel(hero), 0.0);
  });

  test('Fortschrittsanzeige bleibt bei unbekannten EP unbestimmt', () {
    final original = GameEngine().createDemo().hero;
    final unknown = original.copyWith(experience: null);
    expect(ExperienceProgression.pointsUntilNextLevel(unknown), isNull);
    expect(ExperienceProgression.progressToNextLevel(unknown), isNull);
    expect(ExperienceProgression.pendingLevels(unknown), 0);
    expect(ExperienceProgression.reachableLevel(unknown), unknown.level);
    expect(ExperienceProgression.pointsUntilNextLevel(original), 300);
    expect(ExperienceProgression.progressToNextLevel(original), 0.0);
    final halfway = original.copyWith(experience: 150);
    expect(ExperienceProgression.progressToNextLevel(halfway), 0.5);
    expect(ExperienceProgression.pointsUntilNextLevel(halfway), 150);
  });

  test('Höchststufe 20 erzeugt trotz XP keine weiteren Aufstiege', () {
    final original = GameEngine().createDemo().hero.copyWith(
      level: 20,
      experience: 1000000,
    );
    expect(ExperienceProgression.reachableLevel(original), 20);
    expect(ExperienceProgression.pendingLevels(original), 0);
    expect(ExperienceProgression.pointsUntilNextLevel(original), 0);
    expect(ExperienceProgression.progressToNextLevel(original), 1.0);
  });

  test('Ungültige Belohnungen und Maximalgrenzen werden abgewiesen', () {
    final original = GameEngine().createDemo();
    for (final amount in [-1, 100001]) {
      expect(
        () => ExperienceProgression.grant(
          original,
          rewardId: 'kapitel-1',
          amount: amount,
        ),
        throwsFormatException,
      );
    }
    expect(
      () => ExperienceProgression.grant(original, rewardId: ' ', amount: 10),
      throwsFormatException,
    );
    final capped = original.copyWith(
      hero: original.hero.copyWith(experience: 999999),
    );
    expect(
      () =>
          ExperienceProgression.grant(capped, rewardId: 'kapitel-2', amount: 2),
      throwsFormatException,
    );
  });
}
