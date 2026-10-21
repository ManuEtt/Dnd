import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rabenwacht_campaign.dart';

void main() {
  final engine = GameEngine();

  Campaign start() => engine.createRabenwacht(
    engine.createDemo().hero.copyWith(experience: 900),
  );

  Campaign at(String stage, {Map<String, String> facts = const {}}) {
    final campaign = start();
    return campaign.copyWith(
      storyBible: {...campaign.storyBible, 'stage': stage},
      facts: {...campaign.facts, 'visited:$stage': 'true', ...facts},
    );
  }

  test('Tareks Geheimweg wird erst nach ausdrücklicher Bitte bekannt', () {
    var campaign = at('inn');
    expect(
      RabenwachtCampaign.discoveredClues(campaign),
      isNot(contains('Wegzeichen')),
    );
    campaign = engine
        .act(campaign, 'Ich bitte Tarek um einen Geheimweg.')
        .campaign;
    expect(campaign.storyBible['stage'], 'inn');
    expect(campaign.facts['tarekSafeRoute'], 'true');
    expect(campaign.facts['crowsBypassed'], isNull);
    expect(
      campaign.npcs.singleWhere((npc) => npc.id == 'tarek').relationship,
      'freundlich',
    );
    expect(
      RabenwachtCampaign.discoveredClues(campaign),
      contains('geheime Wegzeichen'),
    );
    expect(Campaign.fromJson(campaign.toJson()).toJson(), campaign.toJson());
  });

  test(
    'Unbekannter Geheimweg darf keine Turmreise oder neue Fakten erzeugen',
    () {
      var campaign = at('forest');
      campaign = engine.act(campaign, 'Ich folge Tareks Geheimweg.').campaign;
      expect(campaign.storyBible['stage'], 'forest');
      expect(campaign.facts['crowsBypassed'], isNull);
      expect(campaign.facts['visited:ruins'], isNull);
    },
  );

  test(
    'Bekannter Geheimweg umgeht Krähen ohne Würfelprobe und doppelte EP',
    () {
      var campaign = at('forest', facts: {'tarekSafeRoute': 'true'});
      campaign = engine.act(campaign, 'Ich folge Tareks Geheimweg.').campaign;
      expect(campaign.storyBible['stage'], 'ruins');
      expect(campaign.pendingRoll, isNull);
      expect(campaign.facts['crowsBypassed'], 'true');
      expect(campaign.facts['crowsAlerted'], isNull);
      final xp = campaign.hero.experience;
      expect(xp, 1160);
      campaign = engine
          .act(campaign, 'Ich gehe zurück zur Rabenschlucht.')
          .campaign;
      expect(campaign.storyBible['stage'], 'forest');
      campaign = engine.act(campaign, 'Ich folge Tareks Geheimweg.').campaign;
      expect(campaign.hero.experience, xp);
      expect(Campaign.fromJson(campaign.toJson()).toJson(), campaign.toJson());
    },
  );

  test('Ein früherer Krähenalarm bleibt trotz Geheimweg erhalten', () {
    var campaign = at(
      'forest',
      facts: {'tarekSafeRoute': 'true', 'crowsAlerted': 'true'},
    );
    campaign = engine.act(campaign, 'Ich folge dem Geheimweg.').campaign;
    expect(campaign.facts['crowsAlerted'], 'true');
    expect(campaign.facts['crowsBypassed'], 'true');
    expect(campaign.messages.last.text, contains('bereits alarmiert'));
  });

  test('Alrik bekennt sich erst zu den nachweislich bewahrten Namen', () {
    var campaign = at('archive');
    campaign = engine.act(campaign, 'Ich konfrontiere Alrik.').campaign;
    expect(campaign.facts['alrikConfession'], isNull);
    expect(
      RabenwachtCampaign.discoveredClues(campaign),
      isNot(contains('Alrik gestand')),
    );
    campaign = campaign.copyWith(
      facts: {...campaign.facts, 'graveOath': 'remembered'},
    );
    campaign = engine
        .act(campaign, 'Ich konfrontiere Alrik mit den Namen.')
        .campaign;
    expect(campaign.storyBible['stage'], 'archive');
    expect(campaign.facts['alrikConfession'], 'true');
    expect(
      campaign.npcs.singleWhere((npc) => npc.id == 'alrik').relationship,
      'reumütig',
    );
    expect(
      RabenwachtCampaign.discoveredClues(campaign),
      contains('Alrik gestand'),
    );
    expect(Campaign.fromJson(campaign.toJson()).toJson(), campaign.toJson());
  });

  test('Mara verlangt Alriks Geständnis zur Versöhnung', () {
    var campaign = at('watchhouse', facts: {'maraDefied': 'true'});
    campaign = engine
        .act(campaign, 'Ich zeige Mara Alriks Geständnis.')
        .campaign;
    expect(campaign.facts['maraReconciled'], isNull);
    campaign = campaign.copyWith(
      facts: {...campaign.facts, 'alrikConfession': 'true'},
    );
    campaign = engine
        .act(campaign, 'Ich zeige Mara Alriks Geständnis.')
        .campaign;
    expect(campaign.storyBible['stage'], 'watchhouse');
    expect(campaign.facts['maraReconciled'], 'true');
    expect(
      campaign.npcs.singleWhere((npc) => npc.id == 'mara').relationship,
      'versöhnt',
    );
    expect(Campaign.fromJson(campaign.toJson()).toJson(), campaign.toJson());
    campaign = campaign.copyWith(
      storyBible: {...campaign.storyBible, 'stage': 'choice'},
    );
    campaign = engine.act(campaign, 'Ich erneuere das Siegel.').campaign;
    expect(campaign.scene, contains('Ratsbuch'));
    expect(campaign.scene, isNot(contains('Streit über das Schweigen')));
  });

  test('Geschichte kann Vertrauen über zwei Figuren tatsächlich verbinden', () {
    var campaign = engine.act(start(), 'Ich gehe zum Dorfplatz.').campaign;
    campaign = engine.act(campaign, 'Ich spreche mit Mara Voss.').campaign;
    campaign = engine.act(campaign, 'Ich fordere die Wahrheit.').campaign;
    expect(campaign.storyBible['stage'], 'inn');
    campaign = engine
        .act(campaign, 'Ich frage Tarek nach dem Geheimweg.')
        .campaign;
    expect(campaign.facts['tarekSafeRoute'], 'true');
    campaign = engine.act(campaign, 'Ich spreche mit Tarek.').campaign;
    campaign = engine.act(campaign, 'Ich spreche mit Joren.').campaign;
    campaign = engine.act(campaign, 'Ich suche das Gebetbuch.').campaign;
    expect(campaign.storyBible['stage'], 'archive');
    campaign = engine.act(campaign, 'Ich untersuche die Chronik.').campaign;
    campaign = engine.resolveRoll(campaign, natural: 20).campaign;
    expect(campaign.storyBible['stage'], 'graveyard');
    campaign = engine.act(campaign, 'Ich untersuche den Gedenkstein.').campaign;
    campaign = engine.act(campaign, 'Ich bewahre die Namen.').campaign;
    campaign = engine.act(campaign, 'Ich gehe zum Chronistenhaus.').campaign;
    expect(campaign.storyBible['stage'], 'archive');
    campaign = engine.act(campaign, 'Ich konfrontiere Alrik.').campaign;
    campaign = engine.act(campaign, 'Ich gehe zur Ratsstube.').campaign;
    expect(campaign.storyBible['stage'], 'watchhouse');
    campaign = engine
        .act(campaign, 'Ich zeige Mara Alriks Geständnis.')
        .campaign;
    expect(campaign.facts['maraReconciled'], 'true');
    expect(campaign.facts['graveOath'], 'remembered');
    expect(campaign.facts['tarekSafeRoute'], 'true');
    expect(Campaign.fromJson(campaign.toJson()).toJson(), campaign.toJson());
  });
}
