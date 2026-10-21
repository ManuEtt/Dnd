import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rabenwacht_campaign.dart';

void main() {
  final engine = GameEngine();

  Campaign atVillage() {
    final start = engine.createRabenwacht(
      engine.createDemo().hero.copyWith(experience: 900),
    );
    return engine.act(start, 'Ich gehe zum Dorfplatz.').campaign;
  }

  test('Mara bietet einen eigenständigen Vertrauensweg zum Archiv', () {
    var campaign = atVillage();
    campaign = engine.act(campaign, 'Ich spreche mit Mara Voss.').campaign;
    expect(campaign.storyBible['stage'], 'watchhouse');
    expect(campaign.facts['visited:watchhouse'], 'true');
    expect(campaign.npcs.singleWhere((npc) => npc.id == 'mara').relationship,
        'misstrauisch');

    campaign = engine.act(campaign, 'Ich verspreche Verschwiegenheit.').campaign;
    expect(campaign.storyBible['stage'], 'archive');
    expect(campaign.facts['maraTrust'], 'true');
    expect(campaign.facts['visited:archive'], 'true');
    expect(campaign.npcs.singleWhere((npc) => npc.id == 'mara').relationship,
        'verbündet');
    expect(RabenwachtCampaign.discoveredClues(campaign), contains('Glockeneid'));
    expect(Campaign.fromJson(campaign.toJson()).toJson(), campaign.toJson());
  });

  test('Mara kann widersprochen werden: Vertrauen und Ausgang unterscheiden sich', () {
    var campaign = atVillage();
    campaign = engine.act(campaign, 'Ich befrage die Vorsteherin.').campaign;
    campaign = engine.act(campaign, 'Ich fordere die Wahrheit.').campaign;
    expect(campaign.storyBible['stage'], 'inn');
    expect(campaign.facts['maraDefied'], 'true');
    expect(campaign.npcs.singleWhere((npc) => npc.id == 'mara').relationship,
        'feindselig');

    campaign = campaign.copyWith(
      storyBible: {...campaign.storyBible, 'stage': 'choice'},
    );
    campaign = engine.act(campaign, 'Ich erneuere das Siegel.').campaign;
    expect(campaign.storyBible['stage'], 'end-seal');
    expect(campaign.scene, contains('Streit'));
    expect(campaign.facts['ending'], 'end-seal');
  });

  test('Erkundete Orte sind erneut erreichbar, nicht erkundete bleiben gesperrt', () {
    var campaign = atVillage();
    campaign = engine.act(campaign, 'Ich gehe zur Turmruine.').campaign;
    expect(campaign.storyBible['stage'], 'square');
    campaign = engine.act(campaign, 'Ich gehe zum Gasthaus.').campaign;
    expect(campaign.storyBible['stage'], 'inn');
    campaign = engine.act(campaign, 'Ich gehe zurück zum Dorfplatz.').campaign;
    expect(campaign.storyBible['stage'], 'square');
    campaign = engine.act(campaign, 'Ich gehe zum Gasthaus.').campaign;
    expect(campaign.storyBible['stage'], 'inn');
    expect(Campaign.fromJson(campaign.toJson()).toJson(), campaign.toJson());
  });

  test('Maras Brief öffnet auch nach dem Archiv den Weg zur Mühle', () {
    var campaign = atVillage();
    campaign = engine.act(campaign, 'Ich frage Mara.').campaign;
    campaign = engine.act(campaign, 'Ich verspreche zu schweigen.').campaign;
    expect(campaign.storyBible['stage'], 'archive');
    campaign = engine.act(campaign, 'Ich gehe zur Mühle.').campaign;
    expect(campaign.storyBible['stage'], 'mill');
    final xp = campaign.hero.experience;
    campaign = engine.act(campaign, 'Ich gehe zurück ins Chronistenhaus.').campaign;
    expect(campaign.storyBible['stage'], 'archive');
    campaign = engine.act(campaign, 'Ich gehe zur Mühle.').campaign;
    expect(campaign.hero.experience, xp);
    expect(campaign.facts['visited:mill'], 'true');
  });

  test('Verweigerung und Schlüsselinteresse beginnen keinen Kampf', () {
    final campaign = engine.createRabenwacht(engine.createDemo().hero);
    final hall = campaign.copyWith(
      storyBible: {...campaign.storyBible, 'stage': 'bonehall'},
    );
    for (final words in [
      'Ich will den Wächter nicht angreifen.',
      'Ich greife den Wächter nicht an.',
      'Ich nehme den silbernen Schlüssel.',
      'Ich möchte keinen Kampf.',
    ]) {
      final after = engine.act(hall, words).campaign;
      expect(after.encounter, isNull, reason: words);
      expect(after.storyBible['stage'], 'bonehall', reason: words);
    }
    final attacking = engine.act(hall, 'Ich greife den Wächter an.').campaign;
    expect(attacking.encounter, isNotNull);
    expect(attacking.storyBible['stage'], 'sentryFight');
  });

  test('Erfolgreiches Überreden eröffnet die finale Wahl statt sie zu treffen', () {
    var campaign = engine.createRabenwacht(engine.createDemo().hero);
    campaign = campaign.copyWith(
      storyBible: {...campaign.storyBible, 'stage': 'chamber'},
    );
    campaign = engine.act(campaign, 'Ich spreche mit Seren.').campaign;
    expect(campaign.pendingRoll?.difficulty, 14);
    campaign = engine.resolveRoll(campaign, natural: 20).campaign;
    expect(campaign.storyBible['stage'], 'choice');
    expect(campaign.facts['serenTrust'], 'true');
    expect(campaign.facts['ending'], isNull);
    expect(Campaign.fromJson(campaign.toJson()).toJson(), campaign.toJson());
    campaign = engine.act(campaign, 'Ich erlöse Seren.').campaign;
    expect(campaign.storyBible['stage'], 'end-mercy');
    expect(campaign.scene, contains('Vertrauen'));
  });

  test('Misslungene Heimlichkeit warnt die Wachen und prägt das Ende', () {
    var campaign = engine.createRabenwacht(engine.createDemo().hero);
    campaign = campaign.copyWith(
      storyBible: {...campaign.storyBible, 'stage': 'forest'},
    );
    campaign = engine.act(campaign, 'Ich schleiche vorsichtig.').campaign;
    campaign = engine.resolveRoll(campaign, natural: 1).campaign;
    expect(campaign.storyBible['stage'], 'ruins');
    expect(campaign.facts['crowsAlerted'], 'true');

    campaign = campaign.copyWith(
      storyBible: {...campaign.storyBible, 'stage': 'choice'},
    );
    campaign = engine.act(campaign, 'Ich zerstöre das Siegel.').campaign;
    expect(campaign.scene, contains('Krähen'));
    expect(campaign.facts['ending'], 'end-break');
  });
}
