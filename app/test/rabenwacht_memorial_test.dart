import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rabenwacht_campaign.dart';

void main() {
  final engine = GameEngine();

  Campaign graveyard({Map<String, String> clues = const {}}) {
    final campaign = engine.createRabenwacht(
      engine.createDemo().hero.copyWith(experience: 900),
    );
    return campaign.copyWith(
      storyBible: {...campaign.storyBible, 'stage': 'graveyard'},
      facts: {...campaign.facts, ...clues},
    );
  }

  test('Gedenkstein eröffnet Nebenquest ohne Geheimnis-Spoiler', () {
    var campaign = graveyard();
    expect(
      RabenwachtCampaign.discoveredClues(campaign),
      isNot(contains('Gedenkstein')),
    );
    campaign = engine.act(campaign, 'Ich untersuche den Gedenkstein.').campaign;
    expect(campaign.storyBible['stage'], 'graveyard');
    expect(campaign.facts['memorialSeen'], 'true');
    expect(campaign.facts['graveOath'], isNull);
    expect(
      campaign.quests.where((q) => q.id == 'rabenwacht-memorial').length,
      1,
    );
    expect(
      campaign.quests.singleWhere((q) => q.id == 'rabenwacht-memorial').status,
      'active',
    );
    expect(
      RabenwachtCampaign.discoveredClues(campaign),
      contains('Gedenkstein'),
    );
    campaign = engine.act(campaign, 'Ich höre die Geisterstimme.').campaign;
    expect(
      campaign.quests.where((q) => q.id == 'rabenwacht-memorial').length,
      1,
    );
    expect(Campaign.fromJson(campaign.toJson()).toJson(), campaign.toJson());
  });

  test('Namen bewahren braucht Belege und erlaubt spätere Rückkehr', () {
    var campaign = graveyard();
    campaign = engine.act(campaign, 'Ich sehe den Gedenkstein.').campaign;
    final withoutEvidence = engine
        .act(campaign, 'Ich bewahre die Namen.')
        .campaign;
    expect(withoutEvidence.facts['graveOath'], isNull);
    expect(withoutEvidence.storyBible['stage'], 'graveyard');
    expect(withoutEvidence.messages.last.text, contains('Gebetbuch'));
    expect(withoutEvidence.facts['graveOath'], isNull);

    campaign = withoutEvidence.copyWith(
      facts: {...withoutEvidence.facts, 'oswinTruth': 'true'},
    );
    campaign = engine.act(campaign, 'Ich bewahre die Namen.').campaign;
    expect(campaign.facts['graveOath'], 'remembered');
    expect(
      campaign.quests.singleWhere((q) => q.id == 'rabenwacht-memorial').status,
      'completed',
    );
    final xp = campaign.hero.experience;
    campaign = engine.act(campaign, 'Ich gehe zum Waldpfad.').campaign;
    expect(campaign.storyBible['stage'], 'forest');
    campaign = engine.act(campaign, 'Ich kehre zum Friedhof zurück.').campaign;
    expect(campaign.storyBible['stage'], 'graveyard');
    campaign = engine.act(campaign, 'Ich untersuche den Gedenkstein.').campaign;
    expect(campaign.hero.experience, xp);
    expect(
      campaign.quests.where((q) => q.id == 'rabenwacht-memorial').length,
      1,
    );
    expect(Campaign.fromJson(campaign.toJson()).toJson(), campaign.toJson());
  });

  test(
    'Verschweigen ist eigener Abschluss und bleibt nach Finale gescheitert',
    () {
      var campaign = graveyard();
      campaign = engine
          .act(campaign, 'Ich betrachte den Gedenkstein.')
          .campaign;
      campaign = engine.act(campaign, 'Ich verschweige die Namen.').campaign;
      expect(campaign.facts['graveOath'], 'hidden');
      expect(
        campaign.quests
            .singleWhere((q) => q.id == 'rabenwacht-memorial')
            .status,
        'failed',
      );
      campaign = campaign.copyWith(
        storyBible: {...campaign.storyBible, 'stage': 'choice'},
      );
      campaign = engine.act(campaign, 'Ich erneuere das Siegel.').campaign;
      expect(campaign.storyBible['stage'], 'end-seal');
      expect(campaign.scene, contains('Geheimnis'));
      expect(
        campaign.quests
            .singleWhere((q) => q.id == 'rabenwacht-memorial')
            .status,
        'failed',
      );
    },
  );

  test('Bewahrte Namen verändern den Epilog bei allen drei Enden', () {
    for (final choice in [
      'Ich erneuere das Siegel.',
      'Ich zerstöre das Siegel.',
      'Ich erlöse Seren.',
    ]) {
      var campaign = graveyard(clues: {'prayerFound': 'true'});
      campaign = engine.act(campaign, 'Ich schaue zum Gedenkstein.').campaign;
      campaign = engine.act(campaign, 'Ich gedenke der Opfer.').campaign;
      campaign = campaign.copyWith(
        storyBible: {...campaign.storyBible, 'stage': 'choice'},
      );
      campaign = engine.act(campaign, choice).campaign;
      expect(campaign.scene, contains('bewahrten Namen'), reason: choice);
      expect(campaign.facts['graveOath'], 'remembered');
      expect(Campaign.fromJson(campaign.toJson()).toJson(), campaign.toJson());
    }
  });

  test('Ungelöste freiwillige Quest blockiert Finale nicht', () {
    var campaign = graveyard();
    campaign = engine.act(campaign, 'Ich sehe den Gedenkstein.').campaign;
    campaign = campaign.copyWith(
      storyBible: {...campaign.storyBible, 'stage': 'choice'},
    );
    campaign = engine.act(campaign, 'Ich erlöse Seren.').campaign;
    expect(campaign.storyBible['stage'], 'end-mercy');
    expect(
      campaign.quests.singleWhere((q) => q.id == 'rabenwacht-memorial').status,
      'failed',
    );
    expect(campaign.facts['graveOath'], isNull);
  });

  test('Unklare und negierte Aussagen treffen keine unwiderrufliche Wahl', () {
    var campaign = graveyard(clues: {'prayerFound': 'true'});
    campaign = engine.act(campaign, 'Ich lese den Gedenkstein.').campaign;
    campaign = engine
        .act(campaign, 'Ich will die Namen nicht vergessen.')
        .campaign;
    expect(campaign.facts['graveOath'], isNull);
    expect(campaign.storyBible['stage'], 'graveyard');
    campaign = engine.act(campaign, 'Ich bin noch unsicher.').campaign;
    expect(campaign.facts['graveOath'], isNull);
  });
}
