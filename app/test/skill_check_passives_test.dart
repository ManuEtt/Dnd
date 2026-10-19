import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/character_rule_engine.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/skill_check_passives.dart';
import 'package:lebendiger_spielleiter/domain/srd_class_feature_catalog.dart';

HeroCharacter hero({
  String klass = 'Barde',
  int level = 2,
  int secondLevel = 0,
  String second = '',
  List<String> skills = const [],
  int exhaustion = 0,
}) => HeroCharacter(
  id: 'class-skills',
  name: 'Elda',
  className: klass,
  level: level,
  secondaryClassName: second,
  secondaryClassLevel: secondLevel,
  abilities: const {
    'strength': 14,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 12,
    'wisdom': 12,
    'charisma': 16,
  },
  skills: skills,
  savingThrowProficiencies: const ['strength'],
  maxHitPoints: 35,
  hitPoints: 35,
  armorClass: 14,
  speed: 9,
  weaponDamage: '1d8',
  weaponAbility: 'strength',
  weaponProficient: true,
  exhaustionLevel: exhaustion,
  experience: 23000,
);

void main() {
  group('Alleskönner: Barde ab Klassenstufe 2', () {
    test('Nur untrainierte benannte Fertigkeitsproben erhalten halbe Übung', () {
      final before = hero(level: 1);
      final bard = hero();
      expect(
        CharacterRuleEngine.abilityCheck(
          before,
          'wisdom',
          skill: 'Wahrnehmung',
        ).modifier,
        1,
      );
      expect(
        CharacterRuleEngine.abilityCheck(
          bard,
          'wisdom',
          skill: 'Wahrnehmung',
        ).modifier,
        2,
      );
      final trained = bard.copyWith(skills: ['Wahrnehmung']);
      expect(
        CharacterRuleEngine.perception(trained).modifier,
        3,
      );
      expect(CharacterRuleEngine.perception(trained).minimumNatural, 0);
      // In SRD 5.2.1 initiative without a skill does not qualify.
      expect(CharacterRuleEngine.initiative(bard).modifier, 1);
      expect(
        CharacterRuleEngine.abilityCheck(bard, 'wisdom').modifier,
        1,
      );
      expect(CharacterRuleEngine.savingThrowBonus(bard, 'wisdom'), 1);
      expect(CharacterRuleEngine.attack(bard).modifier, 4);
    });

    test('Gesamt-Übungsbonus gilt auch bei Barde 2 / Kämpfer 7', () {
      final mixed = hero(
        klass: 'Kämpfer',
        level: 9,
        second: 'Barde',
        secondLevel: 2,
        exhaustion: 1,
      );
      // Wisdom +1, half of proficiency +2, exhaustion -2.
      expect(
        CharacterRuleEngine.abilityCheck(
          mixed,
          'wisdom',
          skill: 'Wahrnehmung',
        ).modifier,
        1,
      );
      expect(
        CharacterRuleEngine.perception(mixed).modifier,
        1,
      );
      expect(
        CharacterRuleEngine.abilityCheck(
          mixed.copyWith(skills: ['Wahrnehmung']),
          'wisdom',
          skill: 'Wahrnehmung',
          proficient: true,
        ).modifier,
        3,
      );
    });
  });

  group('Verlässliches Talent: Schurke ab Klassenstufe 7', () {
    test('Nur trainierte Skillchecks erhalten natürlichen Mindestwurf 10', () {
      final rogue = hero(
        klass: 'Schurke',
        level: 7,
        skills: ['Wahrnehmung'],
      );
      expect(CharacterRuleEngine.perception(rogue).minimumNatural, 10);
      expect(
        CharacterRuleEngine.abilityCheck(
          rogue,
          'wisdom',
          skill: 'Heimlichkeit',
        ).minimumNatural,
        0,
      );
      expect(
        CharacterRuleEngine.abilityCheck(rogue, 'wisdom').minimumNatural,
        0,
      );
      expect(CharacterRuleEngine.initiative(rogue).minimumNatural, 0);
      expect(CharacterRuleEngine.attack(rogue).minimumNatural, 0);
      expect(
        CharacterRuleEngine.perception(
          rogue.copyWith(level: 6),
        ).minimumNatural,
        0,
      );
      expect(
        CharacterRuleEngine.perception(
          rogue.copyWith(skills: []),
        ).minimumNatural,
        0,
      );
    });

    test('Erkennt auch Zweitklasse Schurke 7 bei Gesamtstufe 11', () {
      final mixed = hero(
        klass: 'Barde',
        level: 11,
        second: 'Schurke',
        secondLevel: 7,
        skills: ['Wahrnehmung'],
      );
      expect(CharacterRuleEngine.perception(mixed).minimumNatural, 10);
      expect(
        SkillCheckPassives.effectiveTotal(
          total: 5,
          natural: 1,
          minimumNatural: 10,
        ),
        14,
      );
      expect(
        SkillCheckPassives.effectiveTotal(
          total: 5,
          natural: null,
          minimumNatural: 10,
        ),
        5,
      );
    });

    test('Eine vorbereitete Rabenwacht-Probe wird regelkonform aufgewertet', () {
      final engine = GameEngine();
      final source = engine.createDemo().hero.copyWith(
        className: 'Schurke',
        level: 7,
      );
      var campaign = engine.createRabenwacht(source);
      campaign = engine.act(campaign, 'Ich untersuche die Schritte.').campaign;
      expect(campaign.pendingRoll?.type, 'preparedCheck');
      expect(campaign.pendingRoll?.minimumNatural, 10);
      expect(campaign.pendingRoll?.modifier, 4);
      campaign = Campaign.fromJson(campaign.toJson());
      final success = engine.resolveRoll(campaign, natural: 1);
      expect(success.campaign.storyBible['stage'], 'square');
      expect(success.campaign.facts['blackHandClue'], 'true');
      expect(success.events.single.payload['roll']['natural'], 1);
      expect(success.events.single.payload['roll']['total'], 5);
      expect(success.events.single.payload['effectiveTotal'], 14);
      expect(success.events.single.payload['skillFeature'], 'reliableTalent');
      expect(success.campaign.messages.last.text, contains('Verlässliches Talent'));
      expect(Campaign.fromJson(success.campaign.toJson()).toJson(),
          success.campaign.toJson());
    });

    test('Ein explizites Gesamtergebnis bekommt keinen heimlichen Bonus', () {
      final engine = GameEngine();
      final rogue = engine.createDemo().hero.copyWith(
        className: 'Schurke',
        level: 7,
      );
      var campaign = engine.createRabenwacht(rogue);
      campaign = engine.act(campaign, 'Ich untersuche die Schritte.').campaign;
      final result = engine.resolveRoll(campaign, total: 5);
      expect(result.campaign.facts['blackHandClue'], isNull);
      expect(result.events.single.payload.containsKey('effectiveTotal'), isFalse);
      expect(result.campaign.storyBible['stage'], 'square');
    });

    test('Manipulierte oder fehlgeleitete Mindestwürfe werden abgelehnt', () {
      final engine = GameEngine();
      final source = engine.createDemo().hero;
      final campaign = engine.createRabenwacht(source);
      final prepared = engine.act(campaign, 'Ich untersuche die Schritte.').campaign;
      final json = prepared.toJson();
      final pending = Map<String, dynamic>.from(json['pendingRoll'] as Map);
      pending['minimumNatural'] = 10;
      json['pendingRoll'] = pending;
      expect(() => Campaign.fromJson(json), throwsFormatException);
      expect(
        () => PendingRoll.fromJson({
          'id': 'invalid',
          'type': 'attack',
          'modifier': 4,
          'difficulty': 12,
          'minimumNatural': 10,
        }),
        throwsFormatException,
      );
      expect(
        () => PendingRoll.fromJson({
          'id': 'invalid',
          'type': 'preparedCheck',
          'modifier': 4,
          'difficulty': 12,
          'minimumNatural': 9,
        }),
        throwsFormatException,
      );
      // Legacy records without a minimum natural remain readable.
      final legacy = prepared.toJson();
      (legacy['pendingRoll'] as Map<String, dynamic>).remove('minimumNatural');
      expect(Campaign.fromJson(legacy).pendingRoll?.minimumNatural, 0);
    });
  });

  group('Schlüpfriger Geist: Schurke ab Klassenstufe 15', () {
    test('Weisheit und Charisma zählen als geübte Rettungswürfe', () {
      final early = hero(klass: 'Schurke', level: 14);
      final later = early.copyWith(level: 15);
      expect(CharacterRuleEngine.savingThrowBonus(early, 'wisdom'), 1);
      expect(CharacterRuleEngine.savingThrowBonus(later, 'wisdom'), 6);
      expect(CharacterRuleEngine.savingThrowBonus(later, 'charisma'), 8);
      expect(CharacterRuleEngine.savingThrowBonus(later, 'dexterity'), 1);
      // The normal STR saving throw already has proficiency: no stacking.
      expect(CharacterRuleEngine.savingThrowBonus(later, 'strength'), 7);
      expect(
        CharacterRuleEngine.savingThrowBonus(
          later.copyWith(savingThrowProficiencies: [
            'strength',
            'wisdom',
            'charisma',
          ]),
          'wisdom',
        ),
        6,
      );
      final mixed = hero(
        klass: 'Kämpfer',
        level: 18,
        second: 'Schurke',
        secondLevel: 15,
      );
      expect(CharacterRuleEngine.savingThrowBonus(mixed, 'charisma'), 9);
    });

    test('Freigeschaltete Merkmale werden als berechnet ausgewiesen', () {
      for (final entry in [
        ('Barde', 2, 'Jack of All Trades'),
        ('Schurke', 7, 'Reliable Talent'),
        ('Schurke', 15, 'Slippery Mind'),
      ]) {
        final feature = SrdClassFeatureCatalog.unlocked(
          hero(klass: entry.$1, level: entry.$2),
        ).singleWhere((item) => item.name == entry.$3);
        expect(feature.automation, FeatureAutomation.automatic);
      }
    });
  });
}
