import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

void main() {
  final engine = GameEngine();

  Campaign continued({String originalEnding = 'end-seal'}) {
    final first = engine.createRabenwacht(
      engine.createDemo().hero.copyWith(name: 'Valen', experience: 900),
    );
    final old = first.copyWith(
      storyBible: {...first.storyBible, 'stage': originalEnding},
      facts: {...first.facts, 'ending': originalEnding},
    );
    return engine.act(old, 'Fortsetzung beginnen').campaign;
  }

  Campaign collect(Campaign c, String witness) {
    final route = switch (witness) {
      'elda' => 'Ich besuche Elda.',
      'tarek' => 'Ich suche Tarek.',
      _ => 'Ich folge Liora zum Friedhof.',
    };
    final inspect = switch (witness) {
      'elda' => 'Ich untersuche die Zeichnungen.',
      'tarek' => 'Ich untersuche die Tinte im Brief.',
      _ => 'Ich untersuche das Grab.',
    };
    c = engine.act(c, route).campaign;
    c = engine.act(c, inspect).campaign;
    expect(c.pendingRoll, isNotNull);
    c = engine.resolveRoll(c, natural: 20).campaign;
    expect(c.pendingRoll, isNull);
    return c;
  }

  Campaign finale({
    String ending = 'oath',
    String originalEnding = 'end-seal',
    List<String> clues = const ['elda', 'tarek', 'grave'],
    String chronistChoice = 'refused',
    bool lioraCustody = true,
    String lioraChoice = 'protect',
  }) {
    var c = continued(originalEnding: originalEnding);
    if (lioraChoice == 'protect') {
      c = engine.act(c, 'Ich schütze Liora.').campaign;
    } else if (lioraChoice == 'accuse') {
      c = engine.act(c, 'Ich beschuldige Liora.').campaign;
    }
    for (final witness in clues) {
      c = collect(c, witness);
    }
    c = engine.act(c, 'Ich gehe zum Haus ohne Türen.').campaign;
    expect(c.storyBible['stage'], 'voice-house');
    c = engine.act(c, 'Ich betrachte die Porträts.').campaign;
    c = engine.act(c, 'Ich betrete die Bibliothek.').campaign;
    if (chronistChoice == 'refused') {
      c = engine.act(c, 'Ich lehne das Angebot ab.').campaign;
    } else if (chronistChoice == 'feigned') {
      c = engine.act(c, 'Ich täusche Zustimmung vor.').campaign;
    } else if (chronistChoice == 'accepted') {
      c = engine.act(c, 'Ich frage nach dem Preis.').campaign;
      c = engine
          .act(c, 'Ich bestätige den Preis: Eine andere Person wird vergessen.')
          .campaign;
    }
    c = engine.act(c, 'Ich suche das vierzehnte Blatt.').campaign;
    c = engine.act(c, 'Ich untersuche das Blatt.').campaign;
    c = engine
        .act(
          c,
          lioraCustody
              ? 'Ich vertraue Liora den Namen an.'
              : 'Ich will den Namen selbst bewahren.',
        )
        .campaign;
    c = engine.act(c, 'Ich berufe den Rat der Zeugen ein.').campaign;
    if (clues.length == 2) {
      c = engine.act(c, 'Ich biete eine öffentliche Aussage an.').campaign;
      c = engine.act(c, 'Ich bezeuge öffentlich die Lücke im Eid.').campaign;
    }
    c = engine.act(c, 'Ich will die Beweise verbinden.').campaign;
    expect(c.storyBible['stage'], 'voice-ritual');
    final decision = switch (ending) {
      'oath' => 'Ich will den Eid erneuern.',
      'archive' => 'Ich will das Archiv zerstören.',
      _ => 'Ich will einen neuen Eid verhandeln.',
    };
    c = engine.act(c, decision).campaign;
    expect(c.storyBible['stage'], 'voice-end-$ending');
    return c;
  }

  Campaign begin(Campaign c) =>
      engine.act(c, 'Ich möchte den Epilog beginnen.').campaign;

  Campaign speak(Campaign c, String name) {
    c = engine.act(c, 'Ich besuche $name.').campaign;
    expect(c.storyBible['stage'], 'voice-epilogue-${name.toLowerCase()}');
    return engine.act(c, 'Zurück zum Dorfplatz.').campaign;
  }

  test('Epilog startet nur ausdrücklich nach echtem Finale', () {
    final old = finale();
    expect(old.facts['voice:epilogueStarted'], isNull);
    final ignored = engine.act(old, 'Epilog nicht beginnen.').campaign;
    expect(ignored.storyBible['stage'], 'voice-end-oath');
    expect(ignored.facts['voice:epilogueStarted'], isNull);
    final c = begin(old);
    expect(c.storyBible['stage'], 'voice-epilogue-square');
    expect(c.facts['voice:ending'], 'end-oath');
    expect(c.hero.toJson(), old.hero.toJson());
    expect(c.facts['voice:epilogueStarted'], 'true');
    expect(c.quests.where((q) => q.id == 'voice-epilogue').length, 1);
    expect(Campaign.fromJson(c.toJson()).toJson(), c.toJson());
  });

  test('Kein Epilog vor bewiesener, beendeter Haupthandlung', () {
    final base = continued();
    final forged = base.copyWith(
      storyBible: {...base.storyBible, 'stage': 'voice-end-oath'},
      facts: {...base.facts, 'voice:ending': 'end-oath'},
    );
    final after = begin(forged);
    expect(after.storyBible['stage'], 'voice-end-oath');
    expect(after.facts['voice:epilogueStarted'], isNull);
    expect(after.quests.where((q) => q.id == 'voice-epilogue'), isEmpty);
  });

  test('Vor Zukunftsentscheidung braucht es zwei verschiedene Stimmen', () {
    var c = begin(finale());
    c = speak(c, 'Elda');
    c = speak(c, 'Elda');
    expect(c.facts['voice:epilogue:elda'], 'true');
    c = engine.act(c, 'Dorfzukunft entscheiden.').campaign;
    expect(c.storyBible['stage'], 'voice-epilogue-square');
    expect(c.facts['voice:legacy'], isNull);
    c = speak(c, 'Tarek');
    expect(c.facts['voice:epilogue:tarek'], 'true');
    c = engine.act(c, 'Dorfzukunft entscheiden.').campaign;
    expect(c.storyBible['stage'], 'voice-epilogue-future');
    expect(c.quests.where((q) => q.id == 'voice-epilogue').length, 1);
  });

  test('Negierte Wahl und Rückweg erlauben weitere Gespräche', () {
    var c = begin(finale());
    c = engine.act(c, 'Ich besuche Liora nicht.').campaign;
    expect(c.storyBible['stage'], 'voice-epilogue-square');
    expect(c.facts['voice:epilogue:liora'], isNull);
    c = speak(c, 'Liora');
    c = speak(c, 'Elda');
    c = engine.act(c, 'Dorfzukunft entscheiden.').campaign;
    c = engine.act(c, 'Ich werde kein Gedenkbuch anlegen.').campaign;
    expect(c.storyBible['stage'], 'voice-epilogue-future');
    c = engine.act(c, 'Ich möchte weitere Menschen besuchen.').campaign;
    expect(c.storyBible['stage'], 'voice-epilogue-square');
    expect(c.facts['voice:legacy'], isNull);
    c = speak(c, 'Tarek');
    expect(Campaign.fromJson(c.toJson()).toJson(), c.toJson());
  });

  test('Alle drei alten Finalausgänge erhalten eigene Folgen', () {
    for (final entry in {
      'oath': 'erneuerte Eid',
      'archive': 'unmöglichen Archiv',
      'accord': 'mehrere Sichtweisen',
    }.entries) {
      final c = begin(finale(ending: entry.key));
      expect(c.storyBible['stage'], 'voice-epilogue-square');
      expect(c.messages.last.text, contains(entry.value));
      expect(c.facts['voice:ending'], 'end-${entry.key}');
      expect(Campaign.fromJson(c.toJson()).toJson(), c.toJson());
    }
  });

  test('Die vier ursprünglichen Enden werden nicht überschrieben', () {
    for (final entry in {
      'end-seal': 'Siegelgrenze',
      'end-break': 'gebrochene Siegel',
      'end-mercy': 'Serens Erlösung',
      'end-chorus': 'Namenchor',
    }.entries) {
      final original = finale(originalEnding: entry.key);
      final c = begin(original);
      expect(c.messages.last.text, contains(entry.value));
      expect(c.facts['voice:originEnding'], entry.key);
      expect(c.facts['ending'], entry.key);
    }
  });

  test('Liora bleibt eigenständig auch nach Anschuldigung', () {
    final before = finale(
      lioraChoice: 'accuse',
      lioraCustody: false,
      chronistChoice: 'accepted',
    );
    var c = begin(before);
    c = engine.act(c, 'Ich besuche Liora.').campaign;
    expect(c.messages.last.text, contains('Anschuldigung'));
    expect(c.messages.last.text, contains('freie Person'));
    expect(c.facts['voice:epilogue:liora'], 'true');
    expect(c.facts['voice:chronistDebt'], 'contested');
    expect(
      c.npcs.map((n) => n.toJson()).toList(),
      before.npcs.map((n) => n.toJson()).toList(),
    );
    expect(
      c.storyThreads.singleWhere((t) => t.id == 'voice-liora-origin').status,
      'resolved',
    );
  });

  test('Drei Dorfvermächtnisse sind getrennt und dauerhaft', () {
    for (final entry in {
      'Gedenkbuch anlegen.': 'memorial',
      'Zeugnisse veröffentlichen.': 'testimonies',
      'Dorffest veranstalten.': 'festival',
    }.entries) {
      final before = finale(
        ending: 'accord',
        chronistChoice: 'feigned',
        lioraCustody: false,
      );
      var c = begin(before);
      c = speak(c, 'Elda');
      c = speak(c, 'Liora');
      c = engine.act(c, 'Dorfzukunft entscheiden.').campaign;
      c = engine.act(c, entry.key).campaign;
      expect(c.storyBible['stage'], 'voice-epilogue-complete');
      expect(c.facts['voice:legacy'], entry.value);
      expect(c.facts['voice:chronistChoice'], 'feigned');
      expect(c.hero.toJson(), before.hero.toJson());
      expect(
        c.quests.singleWhere((q) => q.id == 'voice-main').status,
        'completed',
      );
      expect(
        c.quests.singleWhere((q) => q.id == 'voice-epilogue').status,
        'completed',
      );
      expect(Campaign.fromJson(c.toJson()).toJson(), c.toJson());
      final repeated = engine.act(c, 'Gedenkbuch anlegen.').campaign;
      expect(repeated.facts['voice:legacy'], entry.value);
      expect(repeated.quests.where((q) => q.id == 'voice-epilogue').length, 1);
      expect(repeated.hero.experience, before.hero.experience);
    }
  });

  test('Umstrittenes öffentliches Zeugnis bleibt umstritten', () {
    var c = begin(finale(ending: 'oath', clues: const ['elda', 'grave']));
    c = speak(c, 'Elda');
    c = speak(c, 'Tarek');
    c = engine.act(c, 'Dorfzukunft entscheiden.').campaign;
    c = engine.act(c, 'Gedenkbuch anlegen.').campaign;
    expect(c.facts['voice:publicTestimony'], 'true');
    expect(c.messages.last.text, contains('bestrittenes Zeugnis'));
    expect(c.facts['voice:splitInkLetter'], isNull);
  });

  test('Offene Nebenquests und alte Fehlschläge bleiben unangetastet', () {
    final original = finale();
    final withQuests = original.copyWith(
      quests: [
        ...original.quests,
        const Quest(id: 'voice-side', title: 'Offene Nebengeschichte'),
        const Quest(
          id: 'rabenwacht-old-failure',
          title: 'Verlorener Auftrag',
          status: 'failed',
        ),
      ],
    );
    var c = begin(withQuests);
    c = speak(c, 'Elda');
    c = speak(c, 'Tarek');
    c = engine.act(c, 'Dorfzukunft entscheiden.').campaign;
    c = engine.act(c, 'Gedenkbuch anlegen.').campaign;
    expect(c.quests.singleWhere((q) => q.id == 'voice-side').status, 'active');
    expect(
      c.quests.singleWhere((q) => q.id == 'rabenwacht-old-failure').status,
      'failed',
    );
    expect(c.hero.toJson(), original.hero.toJson());
    final notes = engine.act(c, 'Hinweise').campaign.messages.last.text;
    expect(notes, contains('Gedenkbuch'));
  });
}
