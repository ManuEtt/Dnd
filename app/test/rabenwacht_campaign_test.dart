import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rabenwacht_campaign.dart';

void main() {
  test('Die vorgefertigte Geschichte nutzt einen eigenen Helden', () {
    final engine = GameEngine();
    final hero = engine.createDemo().hero.copyWith(name: 'Valen');
    final a = engine.createRabenwacht(hero);
    final b = engine.createRabenwacht(hero);
    expect(a.hero.name, 'Valen');
    expect(a.hero.id, hero.id);
    expect(a.name, RabenwachtCampaign.title);
    expect(a.storyBible['mode'], RabenwachtCampaign.mode);
    expect(a.storyBible['stage'], 'road');
    expect(a.id, isNot(b.id));
    expect(a.npcs.length, greaterThanOrEqualTo(8));
    expect(a.scene, contains('Valen'));
    expect(Campaign.fromJson(a.toJson()).toJson(), a.toJson());
  });

  test('Probe hat bestätigten Bonus und führt nach Erfolg weiter', () {
    final engine = GameEngine();
    var campaign = engine.createRabenwacht(engine.createDemo().hero);
    campaign = engine.act(campaign, 'Ich untersuche die Schritte im Nebel.').campaign;
    final pending = campaign.pendingRoll;
    expect(pending, isNotNull);
    expect(pending!.type, 'preparedCheck');
    expect(pending.targetName, 'wisdom|Wahrnehmung');
    expect(pending.difficulty, 12);
    campaign = Campaign.fromJson(campaign.toJson());
    campaign = engine.resolveRoll(campaign, natural: 20).campaign;
    expect(campaign.pendingRoll, isNull);
    expect(campaign.storyBible['stage'], 'square');
    expect(campaign.facts['blackHandClue'], 'true');
    expect(campaign.events.last.type, 'roll.resolved');
  });

  test('Fehlschläge halten den Abenteuerpfad offen', () {
    final engine = GameEngine();
    var campaign = engine.createRabenwacht(engine.createDemo().hero);
    campaign = engine.act(campaign, 'Ich höre die Schritte.').campaign;
    campaign = engine.resolveRoll(campaign, natural: 1).campaign;
    expect(campaign.storyBible['stage'], 'square');
    expect(campaign.facts['blackHandClue'], isNot('true'));
    campaign = engine.act(campaign, 'Ich gehe zum Wirt Tarek.').campaign;
    expect(campaign.storyBible['stage'], 'inn');
  });

  test('Manipulierte Probenboni werden beim Einlesen abgelehnt', () {
    final engine = GameEngine();
    var campaign = engine.createRabenwacht(engine.createDemo().hero);
    campaign = engine.act(campaign, 'Ich untersuche die Schritte.').campaign;
    final json = campaign.toJson();
    final pending = Map<String, dynamic>.from(json['pendingRoll'] as Map);
    pending['modifier'] = 29;
    json['pendingRoll'] = pending;
    expect(() => Campaign.fromJson(json), throwsFormatException);
  });

  test('Skelettwächter entsteht nur bei gewähltem Kampf', () {
    final engine = GameEngine();
    var campaign = engine.createRabenwacht(engine.createDemo().hero);
    campaign = campaign.copyWith(storyBible: {
      ...campaign.storyBible,
      'stage': 'bonehall',
    });
    final examined = engine.act(campaign, 'Ich beobachte die Statue.').campaign;
    expect(examined.encounter, isNull);
    final started = engine.act(examined, 'Ich greife den Wächter an.').campaign;
    expect(started.encounter, isNotNull);
    expect(started.encounter!.enemyName, 'Skelettwächter');
    expect(started.encounter!.enemyArmorClass, 13);
    expect(started.storyBible['stage'], 'sentryFight');
    expect(Campaign.fromJson(started.toJson()).encounter, isNotNull);
  });

  test('Drei unterschiedliche Abschlüsse bleiben persistent', () {
    final engine = GameEngine();
    for (final choice in ['erneuere das Siegel', 'zerstöre das Siegel', 'erlöse Seren']) {
      final start = engine.createRabenwacht(engine.createDemo().hero);
      final before = start.copyWith(storyBible: {
        ...start.storyBible,
        'stage': 'choice',
      });
      final update = engine.act(before, choice);
      final c = Campaign.fromJson(update.campaign.toJson());
      expect(c.storyBible['stage'], startsWith('end-'));
      expect(c.quests.every((q) => q.status == 'completed'), isTrue);
      expect(c.facts['ending'], c.storyBible['stage']);
    }
  });
}
