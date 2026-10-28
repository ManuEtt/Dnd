import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/ai_story.dart';
import 'package:lebendiger_spielleiter/domain/class_resource_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_bard_superior_inspiration_rules.dart';

class _MinimumRandom implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

HeroCharacter _bard({
  int bardLevel = 18,
  int spent = 3,
  int? charisma = 16,
  bool multiclass = false,
}) => HeroCharacter(
  id: 'bard-inspiration',
  name: 'Lyra',
  className: multiclass ? 'Kämpfer' : 'Barde',
  secondaryClassName: multiclass ? 'Barde' : '',
  secondaryClassLevel: multiclass ? bardLevel : 0,
  level: bardLevel + (multiclass ? 2 : 0),
  hitPoints: 40,
  maxHitPoints: 40,
  armorClass: 14,
  speed: 9,
  weaponDamage: '1d8',
  weaponProficient: true,
  abilities: {
    'strength': 12,
    'dexterity': 14,
    'constitution': 12,
    'intelligence': 10,
    'wisdom': 12,
    'charisma': charisma,
  },
  spentClassResources: {'bardicInspiration': spent},
);

GameEngine _engine() => GameEngine(
  dice: DiceEngine(random: _MinimumRandom()),
  clock: () => DateTime.utc(2026, 10, 28),
);

void main() {
  group('SRD 5.2.1: Barde 18 Überlegene Inspiration', () {
    test('Bei Initiative werden höchstens zwei verbrauchte Nutzungen erneuert', () {
      final hero = _bard();
      final result = SrdBardSuperiorInspirationRules.onInitiative(hero);
      expect(result.recovered, 2);
      expect(
        ClassResourceRules.remaining(result.hero, 'bardicInspiration'),
        2,
      );
      expect(result.hero.spentClassResources['bardicInspiration'], 1);
      expect(hero.spentClassResources['bardicInspiration'], 3);
    });

    test('Mit einer vorhandenen Nutzung genau eine weitere zurückholen', () {
      final result = SrdBardSuperiorInspirationRules.onInitiative(
        _bard(spent: 2),
      );
      expect(result.recovered, 1);
      expect(
        ClassResourceRules.remaining(result.hero, 'bardicInspiration'),
        2,
      );
    });

    test('Ab zwei Nutzungen keinerlei Wiederherstellung', () {
      for (final spent in [0, 1]) {
        final hero = _bard(spent: spent);
        final result = SrdBardSuperiorInspirationRules.onInitiative(hero);
        expect(result.recovered, 0);
        expect(result.hero.toJson(), hero.toJson());
      }
    });

    test('Klassenstufe 17 löst noch keine Wiederherstellung aus', () {
      final hero = _bard(bardLevel: 17, spent: 3);
      final result = SrdBardSuperiorInspirationRules.onInitiative(hero);
      expect(result.recovered, 0);
      expect(result.hero.toJson(), hero.toJson());
    });

    test('Mehrklassenprüfung verwendet Bardenlevel statt Gesamtstufe', () {
      final hero = _bard(multiclass: true);
      expect(hero.level, 20);
      final result = SrdBardSuperiorInspirationRules.onInitiative(hero);
      expect(result.recovered, 2);
      final restored = HeroCharacter.fromJson(result.hero.toJson());
      expect(
        ClassResourceRules.remaining(restored, 'bardicInspiration'),
        2,
      );
      final early = _bard(multiclass: true, bardLevel: 17);
      expect(
        SrdBardSuperiorInspirationRules.onInitiative(early).recovered,
        0,
      );
    });

    test('Kleine bestätigte Ressource kann nicht über Maximum steigen', () {
      final hero = _bard(spent: 1, charisma: 8);
      expect(ClassResourceRules.maximum(hero, 'bardicInspiration'), 1);
      final result = SrdBardSuperiorInspirationRules.onInitiative(hero);
      expect(result.recovered, 1);
      expect(
        ClassResourceRules.remaining(result.hero, 'bardicInspiration'),
        1,
      );
      expect(
        result.hero.spentClassResources.containsKey('bardicInspiration'),
        isFalse,
      );
    });

    test('Unbekanntes Charisma und manipulierte Nutzung werden abgelehnt', () {
      expect(
        () => SrdBardSuperiorInspirationRules.onInitiative(
          _bard(charisma: null, spent: 0),
        ),
        throwsStateError,
      );
      expect(
        () => SrdBardSuperiorInspirationRules.onInitiative(_bard(spent: 4)),
        throwsFormatException,
      );
    });

    test('Kampf am Waldschrein regeneriert bei Initiative einmalig', () {
      final engine = _engine();
      final source = engine.createDemo();
      final campaign = source.copyWith(
        hero: _bard().copyWith(id: source.hero.id),
      );
      final started = engine.act(campaign, 'Ich gehe zum Waldschrein.');
      expect(started.events.single.type, 'combat.started');
      expect(
        started.events.single.payload['bardicInspirationRecoveredAtInitiative'],
        2,
      );
      expect(
        ClassResourceRules.remaining(
          started.campaign.hero,
          'bardicInspiration',
        ),
        2,
      );
      final turn = engine.act(started.campaign, 'Ich beende meinen Zug.');
      expect(
        ClassResourceRules.remaining(turn.campaign.hero, 'bardicInspiration'),
        2,
      );
    });

    test('Rabenwacht-Kampf nutzt dieselbe Klassenregel', () {
      final engine = _engine();
      final source = engine.createRabenwacht(_bard());
      final campaign = source.copyWith(
        storyBible: {...source.storyBible, 'stage': 'bonehall'},
      );
      final started = engine.act(campaign, 'Ich greife den Wächter an.');
      expect(started.events.single.type, 'combat.started');
      expect(
        started.events.single.payload['bardicInspirationRecoveredAtInitiative'],
        2,
      );
      expect(
        ClassResourceRules.remaining(
          started.campaign.hero,
          'bardicInspiration',
        ),
        2,
      );
      expect(
        Campaign.fromJson(started.campaign.toJson()).hero.toJson(),
        started.campaign.hero.toJson(),
      );
    });

    test('Bestätigtes KI-Kampfangebot triggert ebenfalls Initiative', () {
      final engine = _engine();
      final plan = AiStoryPlan.fromJson({
        'title': 'Nebelland',
        'world': 'Veyr',
        'opening': 'Ein dunkler Wald wartet.',
        'premise': 'Die Straße ist versperrt.',
        'secret': 'Ein alter Verrat.',
        'goal': 'Finde den Pfad.',
        'threads': [
          {'id': 'weg', 'title': 'Der Weg', 'description': 'Suche den Pfad.'},
          {'id': 'bund', 'title': 'Der Bund', 'description': 'Finde Freunde.'},
        ],
        'npcs': [
          {
            'id': 'mara',
            'name': 'Mara',
            'description': 'Pfadfinderin',
            'relationship': 'neutral',
          },
        ],
        'places': [
          {'id': 'wald', 'name': 'Wald', 'description': 'Nebliger Pfad'},
        ],
      });
      final campaign = engine.createAiCampaign(
        _bard(),
        plan,
        provider: 'mock',
      );
      final offer = AdventureOffer.fromJson({
        'id': 'offer',
        'title': 'Die Brücke',
        'description': 'Ein Schatten wartet.',
        'archetype': 'bandit',
        'questTitle': 'Der Weg',
        'questDescription': 'Überwinde die Brücke.',
      });
      final accepted = engine.acceptAdventure(
        campaign.copyWith(adventureOffer: offer),
      );
      expect(accepted.events.single.type, 'adventure.accepted');
      expect(
        accepted.events.single.payload['bardicInspirationRecoveredAtInitiative'],
        2,
      );
      expect(
        ClassResourceRules.remaining(
          accepted.campaign.hero,
          'bardicInspiration',
        ),
        2,
      );
    });
  });
}
