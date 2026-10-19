import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rabenwacht_campaign.dart';

void main() {
  test('Ermittlungsstand zeigt nur bestätigte, bereits bekannte Hinweise', () {
    final engine = GameEngine();
    final start = engine.createRabenwacht(engine.createDemo().hero);
    final initial = RabenwachtCampaign.discoveredClues(start);
    expect(initial, contains('zerstörte Glockenturm'));
    expect(initial, isNot(contains('Seren')));
    expect(initial, isNot(contains('vierzehnte Tür')));
    expect(initial, isNot(contains('silberne Schlüssel')));

    final narrated = engine.act(start, 'Hinweise').campaign;
    expect(narrated.storyBible['stage'], 'road');
    expect(narrated.scene, start.scene);
    expect(narrated.hero.toJson(), start.hero.toJson());
    expect(narrated.messages.last.text, contains('Offene Aufträge'));
  });

  test('Brunnenszene hat eine optionale, speicherbare Wahrnehmungsprobe', () {
    final engine = GameEngine();
    var campaign = engine.createRabenwacht(engine.createDemo().hero);
    campaign = engine.act(campaign, 'Ich gehe zum Dorfplatz.').campaign;
    expect(campaign.storyBible['stage'], 'square');
    campaign = engine.act(campaign, 'Ich untersuche den Brunnen.').campaign;
    expect(campaign.storyBible['stage'], 'well');
    expect(
      campaign.quests.where((quest) => quest.id == 'rabenwacht-well').length,
      1,
    );
    expect(campaign.pendingRoll, isNull);

    campaign = engine.act(campaign, 'Ich prüfe das Spiegelbild.').campaign;
    expect(campaign.pendingRoll?.type, 'preparedCheck');
    expect(campaign.pendingRoll?.difficulty, 12);
    campaign = Campaign.fromJson(campaign.toJson());
    campaign = engine.resolveRoll(campaign, natural: 20).campaign;
    expect(campaign.storyBible['stage'], 'square');
    expect(campaign.facts['wellClue'], 'true');
    expect(campaign.quests.singleWhere(
      (quest) => quest.id == 'rabenwacht-well',
    ).status, 'completed');
    expect(
      RabenwachtCampaign.discoveredClues(campaign),
      contains('vierzehnte Tür'),
    );
    expect(Campaign.fromJson(campaign.toJson()).toJson(), campaign.toJson());
  });

  test('Brunnen ist auch ohne Probe verlassbar, Auftrag bleibt dann offen', () {
    final engine = GameEngine();
    var campaign = engine.createRabenwacht(engine.createDemo().hero);
    campaign = engine.act(campaign, 'Ich gehe zum Dorfplatz.').campaign;
    campaign = engine.act(campaign, 'Ich schaue zum Brunnen.').campaign;
    campaign = engine.act(campaign, 'Ich gehe zurück zum Platz.').campaign;
    expect(campaign.storyBible['stage'], 'square');
    expect(campaign.facts['wellClue'], isNull);
    expect(campaign.quests.singleWhere(
      (quest) => quest.id == 'rabenwacht-well',
    ).status, 'active');
  });

  test('Beziehungen reagieren auf tatsächliche Gespräche', () {
    final engine = GameEngine();
    var campaign = engine.createRabenwacht(engine.createDemo().hero);
    campaign = engine.act(campaign, 'Ich spreche mit Elda.').campaign;
    expect(
      campaign.npcs.singleWhere((npc) => npc.id == 'elda').relationship,
      'freundlich',
    );
    campaign = engine.act(campaign, 'Ich gehe zum Wirt Tarek.').campaign;
    campaign = engine.act(campaign, 'Ich befrage Tarek.').campaign;
    expect(
      campaign.npcs.singleWhere((npc) => npc.id == 'tarek').relationship,
      'freundlich',
    );
    expect(campaign.storyBible['stage'], 'mill');
  });

  test('Aufträge werden bei entdeckter Tür und Geretteten fortgeschrieben', () {
    final engine = GameEngine();
    var campaign = engine.createRabenwacht(engine.createDemo().hero);
    campaign = campaign.copyWith(
      storyBible: {...campaign.storyBible, 'stage': 'seal'},
    );
    campaign = engine.act(campaign, 'Ich nehme den Schlüssel und gehe zur Tür.').campaign;
    expect(campaign.storyBible['stage'], 'door13');
    expect(campaign.quests.singleWhere(
      (quest) => quest.id == 'rabenwacht-key',
    ).status, 'active');

    campaign = engine.act(campaign, 'Ich öffne die Tür.').campaign;
    expect(campaign.storyBible['stage'], 'chamber');
    expect(campaign.quests.singleWhere(
      (quest) => quest.id == 'rabenwacht-missing',
    ).status, 'completed');
    expect(campaign.quests.singleWhere(
      (quest) => quest.id == 'rabenwacht-key',
    ).status, 'completed');
    expect(campaign.storyThreads.singleWhere(
      (thread) => thread.id == 'stranger',
    ).status, 'resolved');
    expect(campaign.facts['allMissingFound'], isNull);

    campaign = engine.act(campaign, 'Ich zerstöre das Siegel.').campaign;
    expect(campaign.storyBible['stage'], 'end-break');
    expect(campaign.facts['allMissingFound'], 'true');
    expect(campaign.storyThreads.every(
      (thread) => thread.status == 'resolved',
    ), isTrue);
    expect(campaign.npcs.singleWhere(
      (npc) => npc.id == 'fina',
    ).relationship, 'gerettet');
    expect(Campaign.fromJson(campaign.toJson()).toJson(), campaign.toJson());
  });
}
