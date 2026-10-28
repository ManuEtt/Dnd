import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/ai_story.dart';
import 'package:lebendiger_spielleiter/domain/class_resource_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/monk_initiative_features.dart';
import 'package:lebendiger_spielleiter/domain/rest_rules.dart';

class MinimumRandom implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

HeroCharacter monk({
  int monkLevel = 2,
  int spentFocus = 2,
  int hp = 10,
  int maxHp = 30,
  bool multiclass = false,
  bool used = false,
}) => HeroCharacter(
  id: 'monk',
  name: 'Liora',
  className: multiclass ? 'Kämpfer' : 'Mönch',
  secondaryClassName: multiclass ? 'Mönch' : '',
  secondaryClassLevel: multiclass ? monkLevel : 0,
  level: monkLevel + (multiclass ? 3 : 0),
  hitPoints: hp,
  maxHitPoints: maxHp,
  armorClass: 16,
  speed: 9,
  weaponDamage: '1d8',
  weaponProficient: true,
  abilities: const {
    'strength': 12,
    'dexterity': 16,
    'constitution': 14,
    'intelligence': 10,
    'wisdom': 16,
    'charisma': 10,
  },
  spentClassResources: {
    'focusPoints': spentFocus,
    if (used) 'uncannyMetabolism': 1,
  },
);

DiceEngine minimumDice() => DiceEngine(random: MinimumRandom());

void main() {
  group('SRD 5.2.1 Unheimlicher Stoffwechsel bei Initiative', () {
    test('Ohne Zustimmung wird weder gewürfelt noch eine Nutzung ausgegeben', () {
      final hero = monk();
      final before = hero.toJson();
      final result = MonkInitiativeFeatures.onInitiative(hero);
      expect(result.uncannyMetabolismUsed, false);
      expect(result.focusRecovered, 0);
      expect(result.hitPointsRecovered, 0);
      expect(result.hero.toJson(), before);
      expect(result.martialArtsDieRoll, isNull);
    });

    test('Ab Stufe 2 alle verbrauchten Fokuspunkte und W6 + Klassenstufe HP', () {
      final hero = monk();
      final result = MonkInitiativeFeatures.onInitiative(
        hero,
        useUncannyMetabolism: true,
        dice: minimumDice(),
      );
      expect(result.uncannyMetabolismUsed, true);
      expect(result.martialArtsDieRoll, 1);
      expect(result.focusRecovered, 2);
      expect(result.hitPointsRecovered, 3);
      expect(result.hero.hitPoints, 13);
      expect(result.hero.spentClassResources, {'uncannyMetabolism': 1});
      expect(ClassResourceRules.remaining(result.hero, 'focusPoints'), 2);
      expect(hero.hitPoints, 10);
      expect(hero.spentClassResources['focusPoints'], 2);
    });

    test('Mehrklasse benutzt Mönchsstufe und den richtigen Kampfkünste-Würfel', () {
      final hero = monk(
        monkLevel: 5,
        spentFocus: 4,
        hp: 4,
        maxHp: 30,
        multiclass: true,
      );
      final result = MonkInitiativeFeatures.onInitiative(
        hero,
        useUncannyMetabolism: true,
        dice: minimumDice(),
      );
      expect(ClassResourceRules.level(hero, 'Mönch'), 5);
      expect(ClassResourceRules.martialArtsDie(5), 8);
      expect(result.hitPointsRecovered, 6);
      expect(result.hero.hitPoints, 10);
      expect(result.focusRecovered, 4);
      expect(ClassResourceRules.remaining(result.hero, 'focusPoints'), 5);
    });

    test('Heilung stoppt bei maximalen TP; Nutzung trotzdem verbraucht', () {
      final result = MonkInitiativeFeatures.onInitiative(
        monk(monkLevel: 10, spentFocus: 0, hp: 29, maxHp: 30),
        useUncannyMetabolism: true,
        dice: minimumDice(),
      );
      expect(result.hitPointsRecovered, 1);
      expect(result.focusRecovered, 0);
      expect(result.hero.hitPoints, 30);
      expect(result.hero.spentClassResources['uncannyMetabolism'], 1);
    });

    test('Verbrauch bleibt nach kurzer Rast und Import; lange Rast erneuert', () {
      final used = MonkInitiativeFeatures.onInitiative(
        monk(),
        useUncannyMetabolism: true,
        dice: minimumDice(),
      ).hero;
      final loaded = HeroCharacter.fromJson(used.toJson());
      expect(ClassResourceRules.remaining(loaded, 'uncannyMetabolism'), 0);
      final short = ClassResourceRules.afterShortRest(loaded);
      expect(ClassResourceRules.remaining(short, 'uncannyMetabolism'), 0);
      expect(
        () => MonkInitiativeFeatures.onInitiative(
          short,
          useUncannyMetabolism: true,
          dice: minimumDice(),
        ),
        throwsStateError,
      );
      final long = RestRules.longRest(short);
      expect(ClassResourceRules.remaining(long, 'uncannyMetabolism'), 1);
      expect(long.spentClassResources.containsKey('uncannyMetabolism'), false);
    });

    test('Mönch 15 wählt zwischen perfektem Fokus und Stoffwechsel', () {
      final hero = monk(monkLevel: 15, spentFocus: 14);
      final automatic = MonkInitiativeFeatures.onInitiative(hero);
      expect(automatic.focusRecovered, 3);
      expect(ClassResourceRules.remaining(automatic.hero, 'focusPoints'), 4);
      expect(automatic.hero.spentClassResources.containsKey('uncannyMetabolism'), false);

      final chosen = MonkInitiativeFeatures.onInitiative(
        hero,
        useUncannyMetabolism: true,
        dice: minimumDice(),
      );
      expect(chosen.focusRecovered, 14);
      expect(ClassResourceRules.remaining(chosen.hero, 'focusPoints'), 15);
      expect(chosen.hero.spentClassResources['uncannyMetabolism'], 1);
    });

    test('Nicht verfügbare Klasse, fehlende Daten, Würfeldienst sind gesperrt', () {
      expect(
        () => MonkInitiativeFeatures.onInitiative(
          monk(monkLevel: 1, spentFocus: 0),
          useUncannyMetabolism: true,
          dice: minimumDice(),
        ),
        throwsStateError,
      );
      expect(
        () => MonkInitiativeFeatures.onInitiative(
          monk(hp: 0),
          useUncannyMetabolism: true,
          dice: minimumDice(),
        ),
        throwsStateError,
      );
      expect(
        () => MonkInitiativeFeatures.onInitiative(
          monk(),
          useUncannyMetabolism: true,
        ),
        throwsStateError,
      );
    });

    test('Gefälschte Speicherstände mit unmöglicher Ladung werden abgelehnt', () {
      final old = monk().toJson();
      expect(
        () => HeroCharacter.fromJson({
          ...old,
          'spentClassResources': {'uncannyMetabolism': 2},
        }),
        throwsFormatException,
      );
      expect(
        () => HeroCharacter.fromJson({
          ...monk(monkLevel: 1, spentFocus: 0).toJson(),
          'spentClassResources': {'uncannyMetabolism': 1},
        }),
        throwsFormatException,
      );
    });

    test('Spielengine setzt freiwillige Nutzung genau beim Kampfbeginn um', () {
      final game = GameEngine(
        dice: minimumDice(),
        clock: () => DateTime.utc(2026, 10, 28),
      );
      final demo = game.createDemo();
      final initial = demo.copyWith(
        hero: monk().copyWith(id: demo.hero.id),
      );
      final started = game.act(
        initial,
        'Ich gehe zum Waldschrein.',
        useUncannyMetabolism: true,
      );
      expect(started.events.single.type, 'combat.started');
      expect(started.events.single.payload['uncannyMetabolismUsed'], true);
      expect(started.events.single.payload['uncannyMetabolismHealing'], 3);
      expect(started.events.single.payload['uncannyMetabolismDieRoll'], 1);
      expect(started.events.single.payload['focusRecoveredAtInitiative'], 2);
      expect(started.campaign.hero.spentClassResources, {
        'uncannyMetabolism': 1,
      });
    });
    test('KI-Angebot führt Initiative samt ausdrücklich gewählter Nutzung aus', () {
      final game = GameEngine(
        dice: minimumDice(),
        clock: () => DateTime.utc(2026, 10, 28),
      );
      final ai = game.createAiCampaign(
        monk(),
        AiStoryPlan.fromJson({
          'title': 'Nebel',
          'world': 'Veyr',
          'opening': 'Ein dunkler Pfad.',
          'premise': 'Die Straße ist versperrt.',
          'secret': 'Eine alte Schuld.',
          'goal': 'Finde den Pfad.',
          'threads': [
            {'id': 'weg', 'title': 'Weg', 'description': 'Finde den Weg.'},
            {'id': 'bund', 'title': 'Bund', 'description': 'Finde Verbündete.'},
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
            {'id': 'wald', 'name': 'Wald', 'description': 'Neblig.'},
          ],
        }),
        provider: 'mock',
      );
      final offered = ai.copyWith(
        adventureOffer: AdventureOffer.fromJson({
          'id': 'weg1',
          'title': 'Die Brücke',
          'description': 'Ein Wegelagerer wartet.',
          'archetype': 'bandit',
          'questTitle': 'Der Pfad',
          'questDescription': 'Überwinde die Brücke.',
        }),
      );
      final without = game.acceptAdventure(offered);
      expect(without.events.single.payload['uncannyMetabolismUsed'], isNull);
      expect(without.campaign.hero.spentClassResources['focusPoints'], 2);
      final chosen = game.acceptAdventure(
        offered,
        useUncannyMetabolism: true,
      );
      expect(chosen.events.single.payload['uncannyMetabolismUsed'], true);
      expect(chosen.events.single.payload['uncannyMetabolismHealing'], 3);
      expect(chosen.campaign.hero.spentClassResources, {'uncannyMetabolism': 1});
    });

  });
}
