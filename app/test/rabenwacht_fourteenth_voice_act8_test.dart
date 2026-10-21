import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

void main() {
  final engine = GameEngine();

  Campaign start({String ending = 'end-seal'}) {
    final original = engine.createRabenwacht(
      engine.createDemo().hero.copyWith(name: 'Valen', experience: 900),
    );
    final finished = original.copyWith(
      storyBible: {...original.storyBible, 'stage': ending},
      facts: {...original.facts, 'ending': ending},
    );
    return engine.act(finished, 'Fortsetzung beginnen').campaign;
  }

  Campaign collect(Campaign c, String witness) {
    final travel = switch (witness) {
      'elda' => 'Ich besuche Elda.',
      'tarek' => 'Ich suche Tarek.',
      _ => 'Ich folge Liora zum Friedhof.',
    };
    final investigate = switch (witness) {
      'elda' => 'Ich untersuche die Zeichnungen.',
      'tarek' => 'Ich untersuche die Tinte im Brief.',
      _ => 'Ich untersuche das Grab.',
    };
    c = engine.act(c, travel).campaign;
    c = engine.act(c, investigate).campaign;
    expect(c.pendingRoll, isNotNull);
    c = engine.resolveRoll(c, natural: 20).campaign;
    expect(c.storyBible['stage'], 'voice-square');
    return c;
  }

  Campaign council({
    List<String> clues = const ['elda', 'tarek'],
    String ending = 'end-seal',
    String choice = '',
    bool liora = true,
  }) {
    var c = start(ending: ending);
    for (final clue in clues) {
      c = collect(c, clue);
    }
    c = engine.act(c, 'Ich gehe zum Haus ohne Türen.').campaign;
    expect(c.storyBible['stage'], 'voice-house');
    c = engine.act(c, 'Ich betrachte die Porträts.').campaign;
    c = engine.act(c, 'Ich betrete die Bibliothek.').campaign;
    if (choice == 'refused') {
      c = engine.act(c, 'Ich lehne das Angebot ab.').campaign;
    } else if (choice == 'feigned') {
      c = engine.act(c, 'Ich täusche Zustimmung vor.').campaign;
    } else if (choice == 'accepted') {
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
          liora
              ? 'Ich vertraue Liora den Namen an.'
              : 'Ich will den Namen selbst bewahren.',
        )
        .campaign;
    expect(c.storyBible['stage'], 'voice-threshold');
    c = engine.act(c, 'Ich berufe den Rat der Zeugen ein.').campaign;
    expect(c.storyBible['stage'], 'voice-council');
    return c;
  }

  Campaign ritual(Campaign c) {
    c = engine.act(c, 'Ich will die Beweise verbinden.').campaign;
    expect(c.storyBible['stage'], 'voice-ritual');
    return c;
  }

  Campaign testimony(Campaign c) {
    c = engine.act(c, 'Ich biete eine öffentliche Aussage an.').campaign;
    expect(c.storyBible['stage'], 'voice-testimony');
    c = engine.act(c, 'Ich bezeuge öffentlich die Lücke im Eid.').campaign;
    expect(c.storyBible['stage'], 'voice-council');
    expect(c.facts['voice:publicTestimony'], 'true');
    return c;
  }

  test('Rat verlangt bestätigte Belege und behält den Helden', () {
    final c = council();
    expect(c.facts['voice:visited:council'], 'true');
    expect(c.facts['voice:witnessChain'], isNull);
    expect(c.quests.singleWhere((q) => q.id == 'voice-main').status, 'active');
    expect(c.facts['voice:originEnding'], 'end-seal');
    expect(Campaign.fromJson(c.toJson()).toJson(), c.toJson());
    final attempt = engine.act(c, 'Ich will die Beweise verbinden.').campaign;
    expect(attempt.storyBible['stage'], 'voice-council');
    expect(attempt.facts['voice:witnessChain'], isNull);
    expect(attempt.hero.toJson(), c.hero.toJson());
  });

  test('Zwei Belege plus öffentliches Zeugnis öffnen den Ritualweg', () {
    var c = council();
    c = engine.act(c, 'Ich biete eine öffentliche Aussage an.').campaign;
    final warning = engine
        .act(c, 'Ich bezeuge die Lücke im Eid nicht.')
        .campaign;
    expect(warning.storyBible['stage'], 'voice-testimony');
    expect(warning.facts['voice:publicTestimony'], isNull);
    c = engine
        .act(warning, 'Ich bezeuge öffentlich die Lücke im Eid.')
        .campaign;
    expect(c.facts['voice:testimonyRisk'], 'true');
    c = ritual(c);
    expect(c.facts['voice:witnessChain'], 'true');
    expect(Campaign.fromJson(c.toJson()).toJson(), c.toJson());
  });

  test('Ersatzzeugnis kann verweigert und dritte Spur nachgeholt werden', () {
    var c = council();
    c = engine.act(c, 'Ich biete eine öffentliche Aussage an.').campaign;
    c = engine.act(c, 'Ich verzichte.').campaign;
    expect(c.storyBible['stage'], 'voice-council');
    expect(c.facts['voice:publicTestimony'], isNull);
    c = engine.act(c, 'Ich gehe zurück zum Dorfplatz.').campaign;
    expect(c.storyBible['stage'], 'voice-square');
    c = collect(c, 'grave');
    c = engine.act(c, 'Ich gehe zum Haus ohne Türen.').campaign;
    c = engine.act(c, 'Ich betrachte die Porträts.').campaign;
    c = engine.act(c, 'Ich betrete die Bibliothek.').campaign;
    c = engine.act(c, 'Ich suche das vierzehnte Blatt.').campaign;
    c = engine.act(c, 'Ich will den Namen selbst bewahren.').campaign;
    expect(c.storyBible['stage'], 'voice-threshold');
    c = engine.act(c, 'Ich berufe den Rat ein.').campaign;
    c = ritual(c);
    expect(c.facts['voice:publicTestimony'], isNull);
    expect(c.facts['voice:witnessChain'], 'true');
  });

  test('Drei unterschiedliche Spuren sind gleichwertig', () {
    for (final order in [
      ['elda', 'tarek', 'grave'],
      ['grave', 'elda', 'tarek'],
      ['tarek', 'grave', 'elda'],
    ]) {
      var c = council(clues: order);
      c = ritual(c);
      expect(c.facts['voice:witnessChain'], 'true');
      expect(c.hero.experience, 900);
      expect(Campaign.fromJson(c.toJson()).toJson(), c.toJson());
    }
  });

  test('Archivauflösung verlangt alle drei unabhängigen Belege', () {
    var c = testimony(council());
    c = ritual(c);
    c = engine.act(c, 'Ich will das Archiv zerstören.').campaign;
    expect(c.storyBible['stage'], 'voice-ritual');
    expect(c.facts['voice:ending'], isNull);
    c = engine.act(c, 'Ich kehre zurück zum Rat.').campaign;
    expect(c.storyBible['stage'], 'voice-council');
  });

  test('Drei Enden sind ausschließlich bewusste Spielerentscheidungen', () {
    for (final entry in {
      'Ich will den Eid erneuern.': 'end-oath',
      'Ich will das Archiv zerstören.': 'end-archive',
      'Ich will einen neuen Eid verhandeln.': 'end-accord',
    }.entries) {
      final before = ritual(
        council(clues: const ['elda', 'grave', 'tarek'], liora: false),
      );
      final denial = engine
          .act(before, 'Ich will den Eid nicht erneuern.')
          .campaign;
      expect(denial.storyBible['stage'], 'voice-ritual');
      expect(denial.facts['voice:ending'], isNull);

      var c = engine.act(denial, entry.key).campaign;
      expect(c.storyBible['stage'], 'voice-${entry.value}');
      expect(c.facts['voice:ending'], entry.value);
      expect(c.hero.toJson(), before.hero.toJson());
      expect(
        c.quests.singleWhere((q) => q.id == 'voice-main').status,
        'completed',
      );
      expect(Campaign.fromJson(c.toJson()).toJson(), c.toJson());
      final again = engine.act(c, entry.key).campaign;
      expect(again.facts['voice:ending'], entry.value);
      expect(again.hero.experience, before.hero.experience);
    }
  });

  test('Alle vier alten Enden erhalten ihre eigene Ratskonsequenz', () {
    for (final ending in ['end-seal', 'end-break', 'end-mercy', 'end-chorus']) {
      final c = council(ending: ending);
      expect(c.facts['voice:originEnding'], ending);
      final text = c.messages.last.text;
      switch (ending) {
        case 'end-seal':
          expect(text, contains('Siegelgrenze'));
        case 'end-break':
          expect(text, contains('Bruch des Siegels'));
        case 'end-mercy':
          expect(text, contains('Seren wurde erlöst'));
        case 'end-chorus':
          expect(text, contains('Namenchor'));
      }
    }
  });

  test('Chronistenvertrag bleibt nach Abschluss nur bestritten', () {
    var c = council(choice: 'accepted');
    expect(c.facts['voice:chronistDebt'], 'pending');
    c = testimony(c);
    c = ritual(c);
    c = engine.act(c, 'Ich will den Eid erneuern.').campaign;
    expect(c.facts['voice:chronistChoice'], 'accepted');
    expect(c.facts['voice:chronistDebt'], 'contested');
    expect(c.messages.last.text, contains('niemand wird ausgelöscht'));
    expect(Campaign.fromJson(c.toJson()).toJson(), c.toJson());
  });

  test('Täuschung und Lioras Verwahrung werden im Finale erinnert', () {
    var c = council(clues: const ['grave', 'tarek', 'elda'], choice: 'feigned');
    c = ritual(c);
    c = engine.act(c, 'Ich will einen neuen Eid verhandeln.').campaign;
    expect(c.facts['voice:chronistSuspicious'], 'true');
    expect(c.facts['voice:nameCustody'], 'liora');
    expect(c.messages.last.text, contains('Täuschungsversuch'));
    expect(c.messages.last.text, contains('Liora zeigt'));
  });

  test('Offene Nebenaufträge und frühere Questfehler bleiben erhalten', () {
    var c = ritual(council(clues: const ['elda', 'tarek', 'grave']));
    c = c.copyWith(
      quests: [
        ...c.quests,
        const Quest(id: 'voice-optional', title: 'Offene Nebenspur'),
        const Quest(
          id: 'rabenwacht-historical',
          title: 'Frühere Entscheidung',
          status: 'failed',
        ),
      ],
    );
    c = engine.act(c, 'Ich will den Eid erneuern.').campaign;
    expect(
      c.quests.singleWhere((q) => q.id == 'voice-optional').status,
      'active',
    );
    expect(
      c.quests.singleWhere((q) => q.id == 'rabenwacht-historical').status,
      'failed',
    );
    final journal = engine.act(c, 'Hinweise').campaign.messages.last.text;
    expect(journal, contains('erneuert'));
  });

  test('Kein Schlussakt vor tatsächlich gesicherter Abschrift', () {
    final c = start().copyWith(
      storyBible: {...start().storyBible, 'stage': 'voice-threshold'},
    );
    final after = engine.act(c, 'Ich berufe den Rat ein.').campaign;
    expect(after.storyBible['stage'], 'voice-threshold');
    expect(after.facts['voice:witnessChain'], isNull);
  });
}
