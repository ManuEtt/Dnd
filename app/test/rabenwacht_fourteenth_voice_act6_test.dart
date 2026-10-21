import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rabenwacht_campaign.dart';

void main() {
  final engine = GameEngine();

  Campaign firstAdventure() => engine.createRabenwacht(
    engine.createDemo().hero.copyWith(name: 'Valen', experience: 900),
  );

  Campaign completed({String ending = 'end-seal'}) {
    final campaign = firstAdventure();
    return campaign.copyWith(
      storyBible: {...campaign.storyBible, 'stage': ending},
      facts: {...campaign.facts, 'ending': ending},
    );
  }

  Campaign continued({String ending = 'end-seal'}) =>
      engine.act(completed(ending: ending), 'Fortsetzung beginnen').campaign;

  Campaign collect(Campaign campaign, String witness) {
    switch (witness) {
      case 'elda':
        campaign = engine.act(campaign, 'Ich besuche Elda.').campaign;
        expect(campaign.storyBible['stage'], 'voice-elda');
        campaign = engine
            .act(campaign, 'Ich untersuche die Zeichnungen.')
            .campaign;
        expect(campaign.pendingRoll?.targetId, 'voice:elda');
        expect(campaign.pendingRoll?.difficulty, 12);
        break;
      case 'tarek':
        campaign = engine.act(campaign, 'Ich suche Tarek.').campaign;
        expect(campaign.storyBible['stage'], 'voice-tarek');
        campaign = engine
            .act(campaign, 'Ich untersuche die Tinte im Brief.')
            .campaign;
        expect(campaign.pendingRoll?.targetId, 'voice:tarek');
        expect(campaign.pendingRoll?.difficulty, 13);
        break;
      case 'grave':
        campaign = engine
            .act(campaign, 'Ich folge Liora zum Friedhof.')
            .campaign;
        expect(campaign.storyBible['stage'], 'voice-grave');
        campaign = engine.act(campaign, 'Ich untersuche das Grab.').campaign;
        expect(campaign.pendingRoll?.targetId, 'voice:grave');
        expect(campaign.pendingRoll?.difficulty, 12);
        break;
      default:
        throw StateError('Unbekannter Zeuge: $witness');
    }
    campaign = engine.resolveRoll(campaign, natural: 20).campaign;
    expect(campaign.storyBible['stage'], 'voice-square');
    expect(campaign.pendingRoll, isNull);
    return campaign;
  }

  test('Unvollendete Geschichte bleibt unverändert und gesperrt', () {
    final first = firstAdventure();
    final after = engine.act(first, 'Fortsetzung beginnen').campaign;
    expect(after.storyBible['mode'], RabenwachtCampaign.mode);
    expect(after.storyBible['stage'], first.storyBible['stage']);
    expect(after.quests.where((q) => q.id == 'voice-main'), isEmpty);
    expect(after.facts['voice:started'], isNull);
    expect(RabenwachtCampaign.canStartSequel(first), false);
  });

  test(
    'Akt VI beginnt nur auf ausdrücklichen Wunsch, ohne alte Fakten zu löschen',
    () {
      for (final ending in [
        'end-seal',
        'end-break',
        'end-mercy',
        'end-chorus',
      ]) {
        final before = completed(ending: ending);
        final after = engine.act(before, 'Fortsetzung beginnen').campaign;
        expect(after.storyBible['mode'], 'rabenwacht-voice-v1');
        expect(after.storyBible['stage'], 'voice-square');
        expect(after.storyBible['voicePreviousEnding'], ending);
        expect(after.facts['voice:originEnding'], ending);
        expect(after.facts['ending'], ending);
        expect(after.hero.toJson(), before.hero.toJson());
        expect(after.messages.length, greaterThan(before.messages.length));
        expect(after.quests.where((q) => q.id == 'voice-main').length, 1);
        expect(after.quests.where((q) => q.id == 'voice-witnesses').length, 1);
        expect(after.npcs.where((npc) => npc.id == 'liora').length, 1);
        expect(after.encounter, isNull);
        expect(Campaign.fromJson(after.toJson()).toJson(), after.toJson());
      }
    },
  );

  test('Der Fortsetzungsstart ist nicht wiederholbar', () {
    var campaign = continued();
    final beforeCount = campaign.quests.length;
    campaign = engine.act(campaign, 'Fortsetzung beginnen').campaign;
    expect(campaign.quests.length, beforeCount);
    expect(campaign.facts['voice:started'], 'true');
  });

  test(
    'Liora kann geschützt, beschuldigt oder vorläufig offen beurteilt werden',
    () {
      const choices = <String, String>{
        'Ich schütze Liora.': 'protect',
        'Ich beschuldige Liora.': 'accuse',
        'Ich will erst Belege suchen.': 'evidence',
      };
      for (final entry in choices.entries) {
        final campaign = engine.act(continued(), entry.key).campaign;
        expect(campaign.facts['voice:lioraChoice'], entry.value);
        expect(
          campaign.quests.singleWhere((q) => q.id == 'voice-liora').status,
          'completed',
        );
        if (entry.value == 'protect') {
          expect(
            campaign.npcs.singleWhere((npc) => npc.id == 'liora').relationship,
            'vertrauensvoll',
          );
        } else if (entry.value == 'accuse') {
          expect(
            campaign.npcs.singleWhere((npc) => npc.id == 'liora').relationship,
            'misstrauisch',
          );
        }
        expect(
          Campaign.fromJson(campaign.toJson()).toJson(),
          campaign.toJson(),
        );
      }
    },
  );

  test('Hinweise erscheinen nicht vor ihrer tatsächlichen Entdeckung', () {
    var campaign = continued();
    campaign = engine.act(campaign, 'Zeige Hinweise.').campaign;
    expect(
      campaign.messages.last.text,
      isNot(contains('ausradiertes Gesicht')),
    );
    expect(campaign.messages.last.text, isNot(contains('Tintenschichten')));
    campaign = collect(campaign, 'elda');
    campaign = engine.act(campaign, 'Ermittlungsstand').campaign;
    expect(campaign.messages.last.text, contains('ausradiertes Gesicht'));
    expect(campaign.messages.last.text, isNot(contains('Tintenschichten')));
  });

  test('Jede Ermittlungsroute nutzt eine gespeicherte echte Probe', () {
    for (final witness in ['elda', 'tarek', 'grave']) {
      var campaign = continued();
      campaign = collect(campaign, witness);
      final marker = {
        'elda': 'voice:memorySketch',
        'tarek': 'voice:splitInkLetter',
        'grave': 'voice:namelessGrave',
      }[witness]!;
      expect(campaign.facts[marker], 'true');
      expect(Campaign.fromJson(campaign.toJson()).toJson(), campaign.toJson());
    }
  });

  test('Misslungene Untersuchung erfindet kein Zeugnis', () {
    var campaign = continued();
    campaign = engine.act(campaign, 'Ich besuche Elda.').campaign;
    campaign = engine.act(campaign, 'Ich untersuche die Zeichnungen.').campaign;
    expect(campaign.pendingRoll?.targetId, 'voice:elda');
    campaign = engine.resolveRoll(campaign, natural: 1).campaign;
    expect(campaign.storyBible['stage'], 'voice-square');
    expect(campaign.facts['voice:memorySketch'], isNull);
    expect(campaign.facts['voice:houseFound'], isNull);
    expect(
      campaign.quests.singleWhere((q) => q.id == 'voice-witnesses').status,
      'active',
    );
  });

  test('Ein Hinweis reicht nicht, zwei beliebige Spuren öffnen das Haus', () {
    for (final pair in [
      ['elda', 'tarek'],
      ['elda', 'grave'],
      ['grave', 'tarek'],
    ]) {
      var campaign = continued();
      campaign = collect(campaign, pair.first);
      campaign = engine.act(campaign, 'Ich gehe zum Haus ohne Türen.').campaign;
      expect(campaign.storyBible['stage'], 'voice-square', reason: '$pair');
      expect(campaign.facts['voice:houseFound'], isNull);

      campaign = collect(campaign, pair.last);
      expect(
        campaign.quests.singleWhere((q) => q.id == 'voice-witnesses').status,
        'completed',
      );
      final experienceBefore = campaign.hero.experience;
      campaign = engine.act(campaign, 'Ich gehe zum Haus ohne Türen.').campaign;
      expect(campaign.storyBible['stage'], 'voice-house');
      expect(campaign.facts['voice:houseFound'], 'true');
      expect(campaign.hero.experience, experienceBefore);
      campaign = engine.act(campaign, 'Ich betrachte die Porträts.').campaign;
      expect(campaign.storyBible['stage'], 'voice-gallery');
      expect(campaign.facts['voice:portraitSeen'], 'true');
      expect(campaign.hero.experience, experienceBefore);
      expect(Campaign.fromJson(campaign.toJson()).toJson(), campaign.toJson());
    }
  });

  test('Alte Tarek-Beziehung verändert den Dialog, aber nicht die SG', () {
    final before = completed().copyWith(
      facts: {...completed().facts, 'tarekTrust': 'true'},
    );
    var campaign = engine.act(before, 'Fortsetzung beginnen').campaign;
    campaign = engine.act(campaign, 'Ich gehe zu Tarek.').campaign;
    expect(campaign.messages.last.text, contains('vertraut'));
    campaign = engine.act(campaign, 'Ich untersuche den Brief.').campaign;
    expect(campaign.pendingRoll?.difficulty, 13);
  });

  test('Gesprochener Zauberwunsch ändert weder Helden noch Hinweise', () {
    final campaign = continued();
    final after = engine
        .act(campaign, 'Ich wirke Magie entdecken auf den Brief.')
        .campaign;
    expect(after.storyBible['stage'], 'voice-square');
    expect(after.pendingRoll, isNull);
    expect(after.hero.toJson(), campaign.hero.toJson());
    expect(after.facts, campaign.facts);
    expect(after.messages.last.text, contains('keine Zauberwirkungen'));
  });

  test(
    'Kapitelwechsel verändert nicht die Questabschlüsse der ersten Kampagne',
    () {
      final old = completed().copyWith(
        quests: [
          for (final q in completed().quests)
            if (q.id == 'rabenwacht-well') q.copyWith(status: 'failed') else q,
        ],
      );
      var campaign = engine.act(old, 'Fortsetzung beginnen').campaign;
      campaign = collect(campaign, 'grave');
      campaign = collect(campaign, 'tarek');
      campaign = engine.act(campaign, 'Ich gehe zum Haus ohne Türen.').campaign;
      expect(
        campaign.quests.singleWhere((q) => q.id == 'rabenwacht-well').status,
        'failed',
      );
      expect(
        campaign.quests.singleWhere((q) => q.id == 'voice-main').status,
        'active',
      );
    },
  );
}
