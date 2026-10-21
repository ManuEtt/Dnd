import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rabenwacht_campaign.dart';

void main() {
  final engine = GameEngine();

  Campaign chapter({Map<String, String> facts = const {}}) {
    final c = engine.createRabenwacht(
      engine.createDemo().hero.copyWith(experience: 900),
    );
    return c.copyWith(
      storyBible: {...c.storyBible, 'stage': 'chapel'},
      facts: {
        ...c.facts,
        'visited:chapel': 'true',
        'location': 'Kapelle',
        ...facts,
      },
    );
  }

  Campaign explore(Campaign c) =>
      engine.act(c, 'Ich untersuche das Glockenlied.').campaign;

  test('Das geheime Glockenlied wird erst in der Kapelle entdeckt', () {
    var c = chapter();
    expect(RabenwachtCampaign.discoveredClues(c), isNot(contains('Strophe')));
    c = explore(c);
    expect(c.storyBible['stage'], 'hymn');
    expect(c.facts['hymnSeen'], 'true');
    expect(c.facts['hymnChoice'], isNull);
    expect(c.quests.where((q) => q.id == 'rabenwacht-hymn').length, 1);
    expect(
      c.quests.singleWhere((q) => q.id == 'rabenwacht-hymn').status,
      'active',
    );
    expect(RabenwachtCampaign.discoveredClues(c), contains('Strophe'));
    expect(Campaign.fromJson(c.toJson()).toJson(), c.toJson());
  });

  test('Unbekannte Strophe kann ohne Beleg nicht erfunden werden', () {
    var c = explore(chapter());
    c = engine.act(c, 'Ich bewahre die Strophe.').campaign;
    expect(c.storyBible['stage'], 'hymn');
    expect(c.facts['hymnChoice'], isNull);
    expect(c.messages.last.text, contains('Gebetbuch'));
    expect(
      c.npcs.singleWhere((npc) => npc.id == 'oswin').relationship,
      'neutral',
    );
  });

  test(
    'Das Lied kann unterbrochen und ohne doppelte Quest erneut entdeckt werden',
    () {
      var c = explore(chapter());
      c = engine.act(c, 'Ich kehre zur Kapelle zurück.').campaign;
      expect(c.storyBible['stage'], 'chapel');
      c = explore(c);
      expect(c.storyBible['stage'], 'hymn');
      expect(c.quests.where((q) => q.id == 'rabenwacht-hymn').length, 1);
      expect(c.facts['hymnChoice'], isNull);
    },
  );

  test('Oswin vervollständigt das Lied mit bestätigten Aufzeichnungen', () {
    var c = explore(chapter(facts: {'prayerFound': 'true'}));
    c = engine.act(c, 'Ich bewahre die Strophe.').campaign;
    expect(c.storyBible['stage'], 'chapel');
    expect(c.facts['hymnChoice'], 'kept');
    expect(
      c.quests.singleWhere((q) => q.id == 'rabenwacht-hymn').status,
      'completed',
    );
    expect(
      c.npcs.singleWhere((npc) => npc.id == 'oswin').relationship,
      'verbündet',
    );
    expect(c.scene, contains('Vierzehn Schläge'));
    expect(Campaign.fromJson(c.toJson()).toJson(), c.toJson());
    final experience = c.hero.experience;
    c = explore(c);
    expect(c.storyBible['stage'], 'chapel');
    expect(c.hero.experience, experience);
    expect(c.quests.where((q) => q.id == 'rabenwacht-hymn').length, 1);
  });

  test('Das Lied kann unwiderruflich verbrannt werden', () {
    var c = explore(chapter());
    c = engine.act(c, 'Ich verbrenne das Notenblatt.').campaign;
    expect(c.storyBible['stage'], 'chapel');
    expect(c.facts['hymnChoice'], 'burned');
    expect(
      c.quests.singleWhere((q) => q.id == 'rabenwacht-hymn').status,
      'failed',
    );
    expect(
      c.npcs.singleWhere((npc) => npc.id == 'oswin').relationship,
      'abweisend',
    );
    c = explore(c);
    expect(c.facts['hymnChoice'], 'burned');
    expect(c.quests.where((q) => q.id == 'rabenwacht-hymn').length, 1);
    expect(Campaign.fromJson(c.toJson()).toJson(), c.toJson());
  });

  test(
    'Negierte oder widersprüchliche Handlungen entscheiden nicht automatisch',
    () {
      var c = explore(chapter(facts: {'oswinTruth': 'true'}));
      c = engine.act(c, 'Ich will das Lied nicht verbrennen.').campaign;
      expect(c.facts['hymnChoice'], isNull);
      expect(c.storyBible['stage'], 'hymn');
      c = engine.act(c, 'Ich bewahre das Lied und verbrenne es.').campaign;
      expect(c.facts['hymnChoice'], isNull);
      expect(c.storyBible['stage'], 'hymn');
    },
  );

  test('Der verborgene Namenchor bleibt ohne Beweise gesperrt', () {
    var c = chapter();
    c = c.copyWith(storyBible: {...c.storyBible, 'stage': 'choice'});
    c = engine.act(c, 'Ich stimme den Namenchor an.').campaign;
    expect(c.storyBible['stage'], 'choice');
    expect(c.facts['ending'], isNull);
    expect(c.hero.experience, 900);
    c = engine.act(c, 'Ich erneuere das Siegel.').campaign;
    expect(c.storyBible['stage'], 'end-seal');
  });

  test(
    'Der Namenchor wird nur durch vier bestätigte Voraussetzungen möglich',
    () {
      var c = explore(chapter(facts: {'oswinTruth': 'true'}));
      c = engine.act(c, 'Ich bewahre das Lied.').campaign;
      c = c.copyWith(
        storyBible: {...c.storyBible, 'stage': 'choice'},
        facts: {
          ...c.facts,
          'graveOath': 'remembered',
          'alrikConfession': 'true',
        },
      );
      c = engine.act(c, 'Ich singe den Namenchor.').campaign;
      expect(c.storyBible['stage'], 'choice');
      expect(c.facts['ending'], isNull);
      expect(c.messages.last.text, contains('Serens Vertrauen'));
      c = c.copyWith(facts: {...c.facts, 'serenTrust': 'true'});
      c = engine.act(c, 'Ich singe den Namenchor.').campaign;
      expect(c.storyBible['stage'], 'end-chorus');
      expect(c.facts['ending'], 'end-chorus');
      expect(c.facts['allMissingFound'], 'true');
      expect(c.scene, contains('Hüterin der Erinnerungen'));
      expect(
        c.quests.singleWhere((q) => q.id == 'rabenwacht-hymn').status,
        'completed',
      );
      expect(Campaign.fromJson(c.toJson()).toJson(), c.toJson());
      final experience = c.hero.experience;
      c = engine.act(c, 'Ich singe erneut.').campaign;
      expect(c.hero.experience, experience);
    },
  );

  test('Vernichtetes Glockenlied sperrt den Namenchor dauerhaft', () {
    var c = explore(chapter(facts: {'prayerFound': 'true'}));
    c = engine.act(c, 'Ich vernichte die Strophe.').campaign;
    expect(c.facts['hymnChoice'], 'burned');
    c = c.copyWith(
      storyBible: {...c.storyBible, 'stage': 'choice'},
      facts: {
        ...c.facts,
        'graveOath': 'remembered',
        'alrikConfession': 'true',
        'serenTrust': 'true',
      },
    );
    c = engine.act(c, 'Ich stimme den Namenchor an.').campaign;
    expect(c.storyBible['stage'], 'choice');
    expect(c.facts['ending'], isNull);
    c = engine.act(c, 'Ich erlöse Seren.').campaign;
    expect(c.storyBible['stage'], 'end-mercy');
    expect(c.scene, contains('Asche'));
  });

  test('Offene freiwillige Hymnenquest blockiert kein ursprüngliches Ende', () {
    var c = explore(chapter());
    c = c.copyWith(storyBible: {...c.storyBible, 'stage': 'choice'});
    c = engine.act(c, 'Ich zerstöre das Siegel.').campaign;
    expect(c.storyBible['stage'], 'end-break');
    expect(
      c.quests.singleWhere((q) => q.id == 'rabenwacht-hymn').status,
      'failed',
    );
  });
}
