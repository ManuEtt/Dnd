import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rabenwacht_campaign.dart';

void main() {
  final engine = GameEngine();

  Campaign scene(String stage, {Map<String, String> facts = const {}}) {
    final campaign = engine.createRabenwacht(
      engine.createDemo().hero.copyWith(experience: 900),
    );
    return campaign.copyWith(
      storyBible: {...campaign.storyBible, 'stage': stage},
      facts: {...campaign.facts, ...facts},
    );
  }

  test('Mauerwerk erlaubt Nachforschungen statt Arkane Kunde', () {
    var campaign = scene('ruins');
    campaign = engine
        .act(campaign, 'Ich untersuche die Steinfügen im Mauerwerk.')
        .campaign;
    expect(campaign.pendingRoll?.targetId, 'rabenwacht:ruins');
    expect(campaign.pendingRoll?.targetName, 'intelligence|Nachforschungen');
    expect(campaign.pendingRoll?.difficulty, 13);
    campaign = engine.resolveRoll(campaign, natural: 20).campaign;
    expect(campaign.storyBible['stage'], 'stairs');
    expect(campaign.facts['towerSabotage'], 'true');
    expect(campaign.facts['runeClue'], isNull);
    expect(RabenwachtCampaign.discoveredClues(campaign), contains('Sprengung'));
    expect(Campaign.fromJson(campaign.toJson()).toJson(), campaign.toJson());
  });

  test('Magische Inschrift behält den bestehenden Arkane-Kunde-Weg', () {
    var campaign = scene('ruins');
    campaign = engine.act(campaign, 'Ich entziffere die Runen.').campaign;
    expect(campaign.pendingRoll?.targetName, 'intelligence|Arkane Kunde');
    expect(campaign.pendingRoll?.difficulty, 13);
    campaign = engine.resolveRoll(campaign, natural: 20).campaign;
    expect(campaign.facts['runeClue'], 'true');
    expect(campaign.facts['towerSabotage'], isNull);
  });

  test('Misslungenes Mauerwerk gibt kein erfundenes Geheimwissen', () {
    var campaign = scene('ruins');
    campaign = engine.act(campaign, 'Ich prüfe die Brandspuren.').campaign;
    campaign = engine.resolveRoll(campaign, natural: 1).campaign;
    expect(campaign.storyBible['stage'], 'stairs');
    expect(campaign.facts['towerSabotage'], isNull);
    expect(campaign.facts['runeClue'], isNull);
  });

  test('Ermittlungsweg an der Treppe prüft echte Attribute', () {
    var campaign = scene('stairs');
    campaign = engine.act(campaign, 'Ich prüfe das Tragwerk.').campaign;
    expect(campaign.pendingRoll?.targetName, 'intelligence|Nachforschungen');
    expect(campaign.pendingRoll?.difficulty, 12);
    final roll = campaign.pendingRoll!;
    expect(
      Campaign.fromJson(campaign.toJson()).pendingRoll!.toJson(),
      roll.toJson(),
    );
    campaign = engine.resolveRoll(campaign, natural: 20).campaign;
    expect(campaign.storyBible['stage'], 'bonehall');
    expect(campaign.facts['stairSafePassage'], 'true');
    expect(campaign.facts['stairLooseStone'], isNull);
    expect(campaign.encounter, isNull);
  });

  test('Misslungene Treppenuntersuchung erzeugt Hinweis statt Schaden', () {
    var campaign = scene('stairs');
    campaign = engine.act(campaign, 'Ich untersuche die Balken.').campaign;
    campaign = engine.resolveRoll(campaign, natural: 1).campaign;
    expect(campaign.storyBible['stage'], 'bonehall');
    expect(campaign.facts['stairLooseStone'], 'true');
    expect(campaign.facts['stairSafePassage'], isNull);
    expect(campaign.hero.hitPoints, scene('stairs').hero.hitPoints);
  });

  test('Athletik bleibt als Alternative an der Treppe erhalten', () {
    var campaign = scene('stairs');
    campaign = engine.act(campaign, 'Ich klettere über den Abgrund.').campaign;
    expect(campaign.pendingRoll?.targetName, 'strength|Athletik');
    campaign = engine.resolveRoll(campaign, natural: 20).campaign;
    expect(campaign.storyBible['stage'], 'bonehall');
    expect(campaign.facts['stairSafePassage'], isNull);
  });

  test('Tür durch Aufzeichnungen lösen erfordert bereits gefundene Belege', () {
    var campaign = scene('door13');
    campaign = engine.act(campaign, 'Ich vergleiche das Gebetbuch.').campaign;
    expect(campaign.storyBible['stage'], 'door13');
    expect(campaign.pendingRoll, isNull);
    expect(campaign.facts['ritualSolution'], isNull);

    campaign = campaign.copyWith(
      facts: {...campaign.facts, 'prayerFound': 'true'},
    );
    campaign = engine.act(campaign, 'Ich vergleiche das Gebetbuch.').campaign;
    expect(campaign.pendingRoll?.targetId, 'rabenwacht:door13');
    expect(campaign.pendingRoll?.targetName, 'intelligence|Nachforschungen');
    expect(campaign.pendingRoll?.difficulty, 14);
    campaign = engine.resolveRoll(campaign, natural: 20).campaign;
    expect(campaign.storyBible['stage'], 'chamber');
    expect(campaign.facts['ritualSolutionFromRecords'], 'true');
    expect(campaign.facts['ritualSolution'], 'true');
    expect(Campaign.fromJson(campaign.toJson()).toJson(), campaign.toJson());
  });

  test('Ein misslungener Belegvergleich gewährt keinen Lösungshinweis', () {
    var campaign = scene('door13', facts: {'maraLetter': 'true'});
    campaign = engine.act(campaign, 'Ich lese die Aufzeichnungen.').campaign;
    expect(campaign.pendingRoll?.targetName, 'intelligence|Nachforschungen');
    campaign = engine.resolveRoll(campaign, natural: 1).campaign;
    expect(campaign.storyBible['stage'], 'chamber');
    expect(campaign.facts['ritualSolutionFromRecords'], isNull);
    expect(campaign.facts['ritualSolution'], isNull);
  });

  test('Gesprochene Zauberwirkung verändert weder Helden noch Geschichte', () {
    final campaign = scene('ruins');
    final before = campaign.toJson();
    final result = engine
        .act(campaign, 'Ich wirke Magie entdecken auf die Runen.')
        .campaign;
    expect(result.storyBible['stage'], 'ruins');
    expect(result.pendingRoll, isNull);
    expect(result.hero.toJson(), campaign.hero.toJson());
    expect(result.facts, campaign.facts);
    expect(result.messages.last.text, contains('keinen Zauber'));
    expect(before['hero'], result.toJson()['hero']);
  });

  test('Die ursprüngliche arkane Türprobe bleibt verfügbar', () {
    var campaign = scene('door13');
    campaign = engine.act(campaign, 'Ich untersuche die Runen.').campaign;
    expect(campaign.pendingRoll?.targetName, 'intelligence|Arkane Kunde');
    expect(campaign.pendingRoll?.difficulty, 14);
    campaign = engine.resolveRoll(campaign, natural: 20).campaign;
    expect(campaign.facts['ritualSolution'], 'true');
    expect(campaign.facts['ritualSolutionFromRecords'], isNull);
  });
}
