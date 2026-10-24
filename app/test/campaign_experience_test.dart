import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/campaign_experience.dart';
import 'package:lebendiger_spielleiter/domain/character_creation_progression.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_class_level_up.dart';

void main() {
  test('Schwellenwerte stammen aus SRD und Fortschritt endet auf Stufe 20', () {
    expect(CharacterCreationProgression.startingExperience(2), 300);
    expect(CharacterCreationProgression.startingExperience(3), 900);
    expect(CharacterCreationProgression.startingExperience(4), 2700);
    expect(CharacterCreationProgression.startingExperience(20), 355000);

    final engine = GameEngine();
    final hero = engine.createDemo().hero;
    expect(CampaignExperience.pointsUntilLevel(hero), 300);
    expect(CampaignExperience.levelProgress(hero), 0);
    expect(CampaignExperience.canLevelUp(hero), isFalse);
    expect(
      CampaignExperience.canLevelUp(hero.copyWith(experience: 300)),
      isTrue,
    );
    expect(CampaignExperience.levelProgress(hero.copyWith(experience: 300)), 1);
    expect(
      CampaignExperience.nextThreshold(
        hero.copyWith(level: 20, experience: 355000),
      ),
      isNull,
    );
  });

  test('Mehrere erreichte Stufen werden in der Erzählung gezählt', () {
    final engine = GameEngine();
    final hero = engine.createDemo().hero.copyWith(experience: 6400);
    final campaign = engine.createRabenwacht(hero);
    expect(CampaignExperience.pendingLevels(campaign.hero), 3);

    final award = CampaignExperience.awardOnce(campaign, 'reach-mill');
    expect(award.points, 200);
    expect(award.campaign.hero.experience, 6600);
    expect(CampaignExperience.pendingLevels(award.campaign.hero), 4);
    expect(award.narration, contains('4 Stufenaufstiege'));
    expect(award.campaign.hero.level, 1);
  });

  test('EP werden genau einmal bei einer erreichten Szene gutgeschrieben', () {
    final engine = GameEngine();
    var c = engine.createRabenwacht(engine.createDemo().hero);
    c = engine.act(c, 'Ich gehe zum Dorfplatz.').campaign;
    c = engine.act(c, 'Ich gehe zum Wirt Tarek.').campaign;
    c = engine.act(c, 'Ich gehe zur Mühle.').campaign;
    expect(c.storyBible['stage'], 'mill');
    expect(c.hero.experience, 200);
    expect(c.facts['xpReward:reach-mill'], 'true');
    expect(c.messages.last.text, contains('+200 EP'));
    c = Campaign.fromJson(c.toJson());
    final duplicate = CampaignExperience.awardOnce(c, 'reach-mill');
    expect(duplicate.points, 0);
    expect(duplicate.campaign.hero.experience, 200);
    expect(duplicate.campaign.toJson(), c.toJson());

    c = engine.act(c, 'Ich befrage Joren.').campaign;
    expect(c.storyBible['stage'], 'chapel');
    expect(c.hero.experience, 420);
    expect(c.messages.last.text, contains('neue Charakterstufe'));
    expect(CampaignExperience.canLevelUp(c.hero), isTrue);
    final proposal = SrdClassLevelUpRules.propose(
      hero: c.hero,
      className: c.hero.className,
      method: LevelUpMethod.experience,
    );
    final advanced = proposal.applyTo(c.hero);
    expect(advanced.level, 2);
    expect(advanced.experience, 420);
    expect(advanced.maxHitPoints, greaterThan(c.hero.maxHitPoints!));
    expect(CampaignExperience.canLevelUp(advanced), isFalse);
  });

  test(
    'EP sind nicht durch wiederholten Sieg oder falsche Kampagne farmbar',
    () {
      final engine = GameEngine();
      final c = engine.createRabenwacht(engine.createDemo().hero);
      expect(
        () => CampaignExperience.awardOnce(c, 'not-listed'),
        throwsFormatException,
      );
      expect(
        () => CampaignExperience.awardOnce(engine.createDemo(), 'reach-mill'),
        throwsFormatException,
      );
      final rewarded = CampaignExperience.awardOnce(c, 'reach-mill').campaign;
      final after = CampaignExperience.awardOnce(
        rewarded,
        'reach-mill',
      ).campaign;
      expect(after.hero.experience, 200);
      expect(Campaign.fromJson(after.toJson()).toJson(), after.toJson());
    },
  );

  test(
    'Beschädigter Belohnungsmarker wird auch nach JSON-Roundtrip abgewiesen',
    () {
      final engine = GameEngine();
      final original = engine.createRabenwacht(engine.createDemo().hero);
      for (final invalid in ['false', '0', 'unbekannt']) {
        final legacy = Campaign.fromJson(
          original.copyWith(
            facts: {
              ...original.facts,
              'xpReward:reach-mill': invalid,
            },
          ).toJson(),
        );
        expect(
          () => CampaignExperience.awardOnce(legacy, 'reach-mill'),
          throwsFormatException,
        );
        expect(legacy.hero.experience, original.hero.experience);
        expect(legacy.facts['xpReward:reach-mill'], invalid);
      }
      // An old save with no marker is not corrupted and remains awardable.
      final awarded = CampaignExperience.awardOnce(original, 'reach-mill');
      expect(awarded.points, 200);
      expect(awarded.campaign.facts['xpReward:reach-mill'], 'true');
    },
  );

  test(
    'Unbestätigte historische XP werden niemals stillschweigend erfunden',
    () {
      final engine = GameEngine();
      final unknown = engine.createDemo().hero.copyWith(experience: null);
      final campaign = engine.createRabenwacht(unknown);
      final outcome = CampaignExperience.awardOnce(campaign, 'reach-mill');
      expect(outcome.points, 0);
      expect(outcome.campaign.hero.experience, isNull);
      expect(outcome.campaign.facts['xpReward:reach-mill'], isNull);
      expect(outcome.narration, contains('nicht bestätigt'));
    },
  );

  test(
    'Drittes Charakterlevel steigt nach Kampagnenabschluss regelkonform',
    () {
      final engine = GameEngine();
      final hero = engine.createDemo().hero.copyWith(
        level: 3,
        hitPoints: 28,
        maxHitPoints: 28,
        experience: 900,
      );
      var campaign = engine.createRabenwacht(hero);
      final milestones = [
        'reach-mill',
        'reach-chapel',
        'reach-archive',
        'reach-graveyard',
        'reach-ruins',
        'reach-chamber',
        'resolve-rabenwacht',
      ];
      for (final item in milestones) {
        campaign = CampaignExperience.awardOnce(campaign, item).campaign;
      }
      expect(campaign.hero.experience, 3320);
      expect(CampaignExperience.canLevelUp(campaign.hero), isTrue);
      final proposal = SrdClassLevelUpRules.propose(
        hero: campaign.hero,
        className: 'Kämpfer',
        method: LevelUpMethod.experience,
        abilityIncreases: {'strength': 2},
      );
      final after = proposal.applyTo(campaign.hero);
      expect(after.level, 4);
      expect(after.experience, 3320);
      expect(after.abilities['strength'], 18);
      expect(
        CampaignExperience.nextThreshold(after),
        CharacterCreationProgression.startingExperience(5),
      );
    },
  );
}
