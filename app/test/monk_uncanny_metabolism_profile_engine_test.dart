import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/ai_story.dart';
import 'package:lebendiger_spielleiter/domain/class_resource_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

class _InitiativeRandom implements Random {
  final List<int> sides = [];

  @override
  int nextInt(int max) {
    sides.add(max);
    // The hero wins Initiative, so there are no incidental enemy attacks.
    // The Martial Arts die, when explicitly selected, then rolls a natural 1.
    return sides.length == 1 ? max - 1 : 0;
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

enum _CombatPath { aiAdventure, rabenwacht, waldschrein }

HeroCharacter _hero({String primary = 'Fighter', String secondary = 'Monk'}) =>
    HeroCharacter(
      id: 'metabolism-profile-engine',
      name: 'Liora',
      className: primary,
      secondaryClassName: secondary,
      secondaryClassLevel: 2,
      level: 4,
      hitPoints: 10,
      maxHitPoints: 30,
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
      spentClassResources: const {'focusPoints': 2},
    );

Campaign _campaign(GameEngine engine, _CombatPath path, HeroCharacter hero) {
  final Campaign campaign;
  switch (path) {
    case _CombatPath.waldschrein:
      final demo = engine.createDemo();
      campaign = demo.copyWith(hero: hero);
    case _CombatPath.rabenwacht:
      final source = engine.createRabenwacht(hero);
      campaign = source.copyWith(
        storyBible: {...source.storyBible, 'stage': 'bonehall'},
      );
    case _CombatPath.aiAdventure:
      final plan = AiStoryPlan.fromJson({
        'title': 'Nebelland',
        'world': 'Veyr',
        'opening': 'Ein dunkler Pfad wartet.',
        'premise': 'Die Straße ist versperrt.',
        'secret': 'Eine alte Schuld.',
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
      campaign = engine
          .createAiCampaign(hero, plan, provider: 'mock')
          .copyWith(
            adventureOffer: AdventureOffer.fromJson({
              'id': 'metabolism-offer',
              'title': 'Die Brücke',
              'description': 'Ein Wegelagerer wartet.',
              'archetype': 'bandit',
              'questTitle': 'Der Pfad',
              'questDescription': 'Überwinde die Brücke.',
            }),
          );
  }
  // Legacy profiles remain importable; using a class feature still needs
  // validation at the actual combat-start boundary.
  return Campaign.fromJson(campaign.toJson());
}

GameUpdate _start(
  GameEngine engine,
  Campaign campaign,
  _CombatPath path, {
  bool useUncannyMetabolism = false,
}) => switch (path) {
  _CombatPath.aiAdventure => engine.acceptAdventure(
    campaign,
    useUncannyMetabolism: useUncannyMetabolism,
  ),
  _CombatPath.rabenwacht => engine.act(
    campaign,
    'Ich greife den Wächter an.',
    useUncannyMetabolism: useUncannyMetabolism,
  ),
  _CombatPath.waldschrein => engine.act(
    campaign,
    'Ich gehe zum Waldschrein.',
    useUncannyMetabolism: useUncannyMetabolism,
  ),
};

void main() {
  for (final path in _CombatPath.values) {
    test(
      '${path.name}: ungültige importierbare Hauptklasse sperrt gewählten Stoffwechsel vor allen Würfeln',
      () {
        final random = _InitiativeRandom();
        final engine = GameEngine(
          dice: DiceEngine(random: random),
          clock: () => DateTime.utc(2026, 11, 6),
        );
        final campaign = _campaign(
          engine,
          path,
          _hero(primary: 'Historische Klasse'),
        );
        final before = campaign.toJson();
        expect(campaign.hero.level, 4);
        expect(campaign.hero.primaryClassLevel, 2);
        expect(ClassResourceRules.level(campaign.hero, 'Mönch'), 2);
        expect(campaign.hero.isComplete, isTrue);
        expect(random.sides, isEmpty);

        expect(
          () => _start(engine, campaign, path, useUncannyMetabolism: true),
          throwsFormatException,
        );

        expect(random.sides, isEmpty);
        expect(campaign.toJson(), before);
        expect(campaign.encounter, isNull);
        expect(campaign.hero.spentClassResources, {'focusPoints': 2});
        expect(campaign.hero.hitPoints, 10);
      },
    );

    for (final profile in [
      (primary: 'Monk', secondary: 'Fighter'),
      (primary: 'Fighter', secondary: 'Mönchin'),
    ]) {
      test(
        '${path.name}: ${profile.primary}/${profile.secondary} erholt Fokus und TP genau beim bestätigten Kampfbeginn',
        () {
          final random = _InitiativeRandom();
          final engine = GameEngine(
            dice: DiceEngine(random: random),
            clock: () => DateTime.utc(2026, 11, 6),
          );
          final campaign = _campaign(
            engine,
            path,
            _hero(primary: profile.primary, secondary: profile.secondary),
          );
          final before = campaign.toJson();

          final update = _start(
            engine,
            campaign,
            path,
            useUncannyMetabolism: true,
          );

          expect(random.sides, [20, 20, 6]);
          expect(update.campaign.encounter, isNotNull);
          expect(update.campaign.encounter!.isFinished, isFalse);
          expect(update.campaign.revision, campaign.revision + 1);
          expect(update.events, hasLength(1));
          final event = update.events.single;
          expect(
            event.type,
            path == _CombatPath.aiAdventure
                ? 'adventure.accepted'
                : 'combat.started',
          );
          expect(event.payload['uncannyMetabolismUsed'], isTrue);
          expect(event.payload['uncannyMetabolismHealing'], 3);
          expect(event.payload['uncannyMetabolismDieRoll'], 1);
          expect(event.payload['focusRecoveredAtInitiative'], 2);
          expect(update.campaign.hero.hitPoints, 13);
          expect(update.campaign.hero.spentClassResources, {
            'uncannyMetabolism': 1,
          });
          expect(
            ClassResourceRules.remaining(update.campaign.hero, 'focusPoints'),
            2,
          );
          expect(campaign.toJson(), before);
        },
      );
    }

    test(
      '${path.name}: ohne ausdrückliche Wahl bleiben Stoffwechsel, Fokus und TP unverändert',
      () {
        final random = _InitiativeRandom();
        final engine = GameEngine(
          dice: DiceEngine(random: random),
          clock: () => DateTime.utc(2026, 11, 6),
        );
        final campaign = _campaign(engine, path, _hero());
        final before = campaign.toJson();

        final update = _start(engine, campaign, path);

        expect(random.sides, [20, 20]);
        expect(update.campaign.encounter, isNotNull);
        expect(update.events, hasLength(1));
        expect(update.events.single.payload['uncannyMetabolismUsed'], isNull);
        expect(
          update.events.single.payload['uncannyMetabolismHealing'],
          isNull,
        );
        expect(
          update.events.single.payload['uncannyMetabolismDieRoll'],
          isNull,
        );
        expect(update.events.single.payload['focusRecoveredAtInitiative'], 0);
        expect(update.campaign.hero.toJson(), campaign.hero.toJson());
        expect(campaign.toJson(), before);
      },
    );
  }
}
