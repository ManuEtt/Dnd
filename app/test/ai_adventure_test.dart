import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/adventure_catalog.dart';
import 'package:lebendiger_spielleiter/domain/ai_story.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

Map<String, dynamic> plan() => {
  'title': 'Das Nebelland',
  'world': 'Veyr',
  'opening': 'Ein dunkler Wald wartet. Was tust du?',
  'premise': 'Die Straße ist versperrt.',
  'secret': 'Ein alter Verrat.',
  'goal': 'Finde den verlorenen Pfad.',
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
};
Map<String, dynamic> draft({
  String archetype = 'bandit',
  String id = 'road1',
}) => {
  'id': id,
  'title': 'Die Brücke',
  'description': 'Ein unbekannter Schatten wartet.',
  'archetype': archetype,
  'questTitle': 'Der sichere Pfad',
  'questDescription': 'Überwinde die Herausforderung auf dem Weg.',
};

void main() {
  GameEngine engine() => GameEngine(dice: DiceEngine(random: Random(11)));
  Campaign start(GameEngine e, {HeroCharacter? hero}) => e.createAiCampaign(
    hero ?? e.createDemo().hero,
    AiStoryPlan.fromJson(plan()),
    provider: 'mock',
  );

  test('AI cannot inject rules, arbitrary enemy statistics or unknown IDs', () {
    expect(
      () => AdventureOffer.fromJson({...draft(), 'archetype': 'dragon'}),
      throwsFormatException,
    );
    expect(
      () => AdventureOffer.fromJson({...draft(), 'id': '../../passwd'}),
      throwsFormatException,
    );
    expect(
      () => AdventureOffer.fromJson({
        ...draft(),
        'description': List.filled(501, 'x').join(),
      }),
      throwsFormatException,
    );
    expect(AdventureCatalog.enemies['bandit']!.hitPoints, 11);
    expect(
      AdventureOffer.fromJson({
        ...draft(),
        'hitPoints': 999,
        'damage': '999d999',
        'gold': 99999,
      }).archetype,
      'bandit',
    );
    final before = start(engine());
    final parsed = AiStoryStep.fromJson({
      'narration': 'Es erscheint ein Gegner.',
      'threadUpdates': [],
      'newThreads': [],
      'npcUpdates': [],
      'adventure': {...draft(), 'hitPoints': 9999, 'gold': 9999},
    }, before);
    expect(parsed.adventure!.archetype, 'bandit');
    expect(parsed.adventure!.toJson().containsKey('hitPoints'), false);
    expect(parsed.adventure!.toJson().containsKey('gold'), false);
  });

  test('AI story only offers quests: no mechanical changes before opt-in', () {
    final e = engine();
    final original = start(e);
    final free = e.act(original, 'Ich nähere mich der verwitterten Brücke.');
    final step = AiStoryStep.fromJson({
      'narration': 'Ein Wegelagerer steht im Nebel. Was tust du?',
      'threadUpdates': [],
      'newThreads': [],
      'npcUpdates': [],
      'adventure': draft(),
    }, free.campaign);
    final updated = e.applyAiStoryStep(
      free,
      step,
      provider: 'mock',
      decision: 'Ich nähere mich der Brücke.',
    );
    expect(updated.events, hasLength(1));
    expect(updated.campaign.revision, original.revision + 1);
    expect(updated.campaign.adventureOffer?.id, 'road1');
    expect(updated.campaign.quests, isEmpty);
    expect(updated.campaign.encounter, isNull);
    expect(updated.campaign.hero.toJson(), original.hero.toJson());
    expect(
      Campaign.fromJson(updated.campaign.toJson()).toJson(),
      updated.campaign.toJson(),
    );
    final declined = e.rejectAdventure(updated.campaign).campaign;
    expect(declined.adventureOffer, isNull);
    expect(declined.quests, isEmpty);
    expect(declined.hero.inventory, original.hero.inventory);
    expect(() => e.rejectAdventure(declined), throwsFormatException);
  });

  test(
    'accepted combat uses ONLY local HP/AC/attack and completes quest once',
    () {
      final e = engine();
      final before = start(e);
      final offer = AdventureOffer.fromJson(draft());
      final accepted = e.acceptAdventure(
        before.copyWith(adventureOffer: offer),
      );
      final fighting = accepted.campaign;
      expect(accepted.events.single.type, 'adventure.accepted');
      expect(fighting.adventureOffer, isNull);
      expect(fighting.quests.single.status, 'active');
      expect(fighting.encounter!.enemyHitPoints, 11);
      expect(fighting.encounter!.enemyArmorClass, 12);
      expect(fighting.encounter!.enemyAttackBonus, 3);
      expect(Campaign.fromJson(fighting.toJson()).toJson(), fighting.toJson());
      expect(() => e.acceptAdventure(fighting), throwsFormatException);
      // A low HP enemy is a test setup, not a provider-controlled rule change.
      final almost = fighting.copyWith(
        encounter: fighting.encounter!.copyWith(enemyHitPoints: 1),
      );
      final attack = e.act(almost, 'Ich greife den Wegelagerer an.').campaign;
      expect(attack.pendingRoll?.type, 'attack');
      final victory = e.resolveRoll(attack, natural: 20).campaign;
      expect(victory.encounter, isNull);
      expect(victory.quests.single.status, 'completed');
      expect(
        victory.hero.inventory.where((i) => i.id == 'loot-road1'),
        hasLength(1),
      );
      expect(victory.hero.gold, before.hero.gold);
      expect(victory.facts['guardianDefeated'], isNull);
      expect(victory.facts['aiQuestCompleted:ai-road1'], 'true');
      expect(Campaign.fromJson(victory.toJson()).toJson(), victory.toJson());
      expect(
        () => e.acceptAdventure(victory.copyWith(adventureOffer: offer)),
        throwsFormatException,
      );
    },
  );

  test(
    'non-combat investigation uses local check and awards only on success',
    () {
      final e = engine();
      final before = start(e);
      final offer = AdventureOffer.fromJson(draft(archetype: 'investigation'));
      final accepted = e.acceptAdventure(
        before.copyWith(adventureOffer: offer),
      );
      expect(accepted.events.single.type, 'adventure.investigationStarted');
      expect(accepted.campaign.pendingRoll?.type, 'perception');
      expect(accepted.campaign.pendingRoll?.difficulty, 10);
      expect(accepted.campaign.encounter, isNull);
      expect(
        Campaign.fromJson(accepted.campaign.toJson()).toJson(),
        accepted.campaign.toJson(),
      );
      final won = e.resolveRoll(accepted.campaign, natural: 20).campaign;
      expect(won.quests.single.status, 'completed');
      expect(won.hero.inventory.any((item) => item.id == 'loot-road1'), true);
      expect(won.hero.gold, before.hero.gold);
      final another = e.acceptAdventure(before.copyWith(adventureOffer: offer));
      final failed = e.resolveRoll(another.campaign, natural: 1).campaign;
      expect(failed.quests.single.status, 'failed');
      expect(
        failed.hero.inventory.any((item) => item.id == 'loot-road1'),
        false,
      );
    },
  );

  test('incomplete hero cannot accept quest; old saves remain compatible', () {
    final e = engine();
    final old = start(
      e,
      hero: HeroCharacter(id: 'old', name: 'Alter Held'),
    );
    final offered = old.copyWith(
      adventureOffer: AdventureOffer.fromJson(draft()),
    );
    expect(() => e.acceptAdventure(offered), throwsFormatException);
    final json = old.toJson()..remove('adventureOffer');
    expect(Campaign.fromJson(json).adventureOffer, isNull);
  });
}
