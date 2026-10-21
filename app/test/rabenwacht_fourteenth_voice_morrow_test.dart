import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

void main() {
  final engine = GameEngine();

  Campaign collect(Campaign c, String witness) {
    final travel = switch (witness) {
      'elda' => 'Ich besuche Elda.',
      'tarek' => 'Ich suche Tarek.',
      _ => 'Ich folge Liora zum Friedhof.',
    };
    final inspect = switch (witness) {
      'elda' => 'Ich untersuche die Zeichnungen.',
      'tarek' => 'Ich untersuche die Tinte im Brief.',
      _ => 'Ich untersuche das Grab.',
    };
    c = engine.act(c, travel).campaign;
    c = engine.act(c, inspect).campaign;
    expect(c.pendingRoll, isNotNull);
    return engine.resolveRoll(c, natural: 20).campaign;
  }

  Campaign completedEpilogue({
    String oldEnding = 'end-seal',
    String finale = 'oath',
    String legacy = 'memorial',
  }) {
    final original = engine.createRabenwacht(
      engine.createDemo().hero.copyWith(name: 'Valen', experience: 900),
    );
    var c = original.copyWith(
      storyBible: {...original.storyBible, 'stage': oldEnding},
      facts: {...original.facts, 'ending': oldEnding},
    );
    c = engine.act(c, 'Fortsetzung beginnen').campaign;
    for (final witness in const ['elda', 'tarek', 'grave']) {
      c = collect(c, witness);
    }
    c = engine.act(c, 'Ich gehe zum Haus ohne Türen.').campaign;
    c = engine.act(c, 'Ich betrachte die Porträts.').campaign;
    c = engine.act(c, 'Ich betrete die Bibliothek.').campaign;
    c = engine.act(c, 'Ich lehne das Angebot ab.').campaign;
    c = engine.act(c, 'Ich suche das vierzehnte Blatt.').campaign;
    c = engine.act(c, 'Ich untersuche das Blatt.').campaign;
    c = engine.act(c, 'Ich will den Namen selbst bewahren.').campaign;
    c = engine.act(c, 'Ich berufe den Rat der Zeugen ein.').campaign;
    c = engine.act(c, 'Ich will die Beweise verbinden.').campaign;
    c = engine
        .act(
          c,
          switch (finale) {
            'archive' => 'Ich will das Archiv zerstören.',
            'accord' => 'Ich will einen neuen Eid verhandeln.',
            _ => 'Ich will den Eid erneuern.',
          },
        )
        .campaign;
    expect(c.storyBible['stage'], 'voice-end-$finale');
    c = engine.act(c, 'Epilog beginnen.').campaign;
    c = engine.act(c, 'Ich besuche Elda.').campaign;
    c = engine.act(c, 'Zurück zum Dorfplatz.').campaign;
    c = engine.act(c, 'Ich besuche Tarek.').campaign;
    c = engine.act(c, 'Zurück zum Dorfplatz.').campaign;
    c = engine.act(c, 'Dorfzukunft entscheiden.').campaign;
    c = engine
        .act(
          c,
          switch (legacy) {
            'testimonies' => 'Zeugnisse veröffentlichen.',
            'festival' => 'Dorffest veranstalten.',
            _ => 'Gedenkbuch anlegen.',
          },
        )
        .campaign;
    expect(c.storyBible['stage'], 'voice-epilogue-complete');
    expect(c.facts['voice:legacy'], legacy);
    return c;
  }

  Campaign begin(Campaign c) =>
      engine.act(c, 'Brief von Morgen beginnen.').campaign;

  Campaign read(Campaign c) {
    c = begin(c);
    expect(c.storyBible['stage'], 'voice-morrow-square');
    return engine.act(c, 'Ich will den Brief öffnen.').campaign;
  }

  Campaign investigate(Campaign c, String person) {
    final travel = switch (person) {
      'elda' => 'Ich besuche Elda.',
      'tarek' => 'Ich besuche Tarek.',
      _ => 'Ich gehe zum Brunnen.',
    };
    final inspect = switch (person) {
      'elda' => 'Ich will das Register untersuchen.',
      'tarek' => 'Ich will die Tinte untersuchen.',
      _ => 'Ich will die Spuren prüfen.',
    };
    c = engine.act(c, travel).campaign;
    expect(c.storyBible['stage'], 'voice-morrow-${person == 'brunnen' ? 'well' : person}');
    c = engine.act(c, inspect).campaign;
    expect(c.facts['voice:morrow:${person == 'brunnen' ? 'well' : person}'], 'true');
    c = engine.act(c, 'Zurück zum Dorfplatz.').campaign;
    expect(c.storyBible['stage'], 'voice-morrow-square');
    return c;
  }

  test('Kein heimlicher Start ohne wirkliches Epilogfinale', () {
    final c = completedEpilogue();
    final other = engine.act(c, 'Brief von Morgen nicht beginnen.').campaign;
    expect(other.storyBible['stage'], 'voice-epilogue-complete');
    expect(other.facts['voice:morrow:started'], isNull);
    final begun = begin(c);
    expect(begun.facts['voice:morrow:started'], 'true');
    expect(begun.quests.where((q) => q.id == 'voice-morrow').length, 1);
    expect(begun.hero.toJson(), c.hero.toJson());
    expect(Campaign.fromJson(begun.toJson()).toJson(), begun.toJson());
  });

  test('Kapitelbeginn ohne bestätigten Epilog wird verweigert', () {
    final start = completedEpilogue();
    final forged = start.copyWith(
      facts: {...start.facts, 'voice:legacy': 'unknown'},
    );
    final c = begin(forged);
    expect(c.storyBible['stage'], 'voice-epilogue-complete');
    expect(c.facts['voice:morrow:started'], isNull);
  });

  test('Der Brief muss erst gelesen werden; keine Zukunft als Fakt', () {
    var c = begin(completedEpilogue());
    c = engine.act(c, 'Ich gehe zu Elda.').campaign;
    expect(c.storyBible['stage'], 'voice-morrow-square');
    c = engine.act(c, 'Brief nicht öffnen.').campaign;
    expect(c.facts['voice:morrow:letterRead'], isNull);
    c = engine.act(c, 'Brief öffnen.').campaign;
    expect(c.facts['voice:morrow:letterRead'], 'true');
    expect(c.messages.last.text, contains('keine Prophezeiung'));
    expect(c.facts['voice:morrow:outcome'], isNull);
  });

  test('Zwei tatsächlich untersuchte unabhängige Spuren öffnen den Rat', () {
    var c = read(completedEpilogue());
    c = engine.act(c, 'Rat einberufen.').campaign;
    expect(c.storyBible['stage'], 'voice-morrow-square');
    c = investigate(c, 'elda');
    c = investigate(c, 'elda');
    expect(c.facts['voice:morrow:tarek'], isNull);
    c = engine.act(c, 'Rat einberufen.').campaign;
    expect(c.storyBible['stage'], 'voice-morrow-square');
    c = investigate(c, 'tarek');
    c = engine.act(c, 'Rat einberufen.').campaign;
    expect(c.storyBible['stage'], 'voice-morrow-council');
    expect(c.facts['voice:morrow:outcome'], isNull);
    expect(Campaign.fromJson(c.toJson()).toJson(), c.toJson());
  });

  test('Der Brunnen liefert eine dritte unabhängige Route', () {
    var c = read(completedEpilogue(legacy: 'festival'));
    c = investigate(c, 'brunnen');
    c = investigate(c, 'elda');
    c = engine.act(c, 'Rat einberufen.').campaign;
    expect(c.storyBible['stage'], 'voice-morrow-council');
    expect(c.facts['voice:morrow:tarek'], isNull);
    expect(c.facts['voice:morrow:well'], 'true');
    expect(c.facts['voice:legacy'], 'festival');
  });

  test('Alle drei Briefentscheidungen bleiben unabhängig und endgültig', () {
    for (final entry in {
      'Brief versiegelt verwahren.': 'sealed',
      'Brief mit Quellen veröffentlichen.': 'published',
      'Liora selbst entscheiden lassen.': 'liora',
    }.entries) {
      final original = completedEpilogue(finale: 'accord');
      var c = read(original);
      c = investigate(c, 'elda');
      c = investigate(c, 'tarek');
      c = engine.act(c, 'Rat einberufen.').campaign;
      c = engine.act(c, 'Brief nicht versiegelt verwahren.').campaign;
      expect(c.storyBible['stage'], 'voice-morrow-council');
      expect(c.facts['voice:morrow:outcome'], isNull);
      c = engine.act(c, entry.key).campaign;
      expect(c.storyBible['stage'], 'voice-morrow-end-${entry.value}');
      expect(c.facts['voice:morrow:outcome'], entry.value);
      expect(c.facts['voice:ending'], original.facts['voice:ending']);
      expect(c.facts['voice:legacy'], original.facts['voice:legacy']);
      expect(c.hero.toJson(), original.hero.toJson());
      expect(Campaign.fromJson(c.toJson()).toJson(), c.toJson());
      final another = engine.act(c, 'Brief mit Quellen veröffentlichen.').campaign;
      expect(another.facts['voice:morrow:outcome'], entry.value);
      expect(another.hero.experience, original.hero.experience);
      expect(another.quests.where((q) => q.id == 'voice-morrow').length, 1);
      expect(
        another.quests.singleWhere((q) => q.id == 'voice-morrow').status,
        'completed',
      );
    }
  });

  test('Rückkehr zum Dorfplatz bewahrt Hinweise und Spielwerte', () {
    final original = completedEpilogue();
    var c = read(original);
    c = investigate(c, 'tarek');
    c = investigate(c, 'brunnen');
    c = engine.act(c, 'Rat einberufen.').campaign;
    c = engine.act(c, 'Ich will eine weitere Spur.').campaign;
    expect(c.storyBible['stage'], 'voice-morrow-square');
    expect(c.facts['voice:morrow:tarek'], 'true');
    expect(c.facts['voice:morrow:well'], 'true');
    expect(c.hero.toJson(), original.hero.toJson());
    expect(c.quests.singleWhere((q) => q.id == 'voice-main').status,
        'completed');
  });

  test('Jedes finale Dorfvermächtnis lässt eine Nachgeschichte zu', () {
    for (final legacy in ['memorial', 'testimonies', 'festival']) {
      final old = completedEpilogue(legacy: legacy);
      final c = begin(old);
      expect(c.storyBible['stage'], 'voice-morrow-square');
      expect(c.facts['voice:legacy'], legacy);
      expect(c.messages.last.text, isNotEmpty);
    }
  });

  test('Spoilerfreie Hinweisübersicht und unveränderte Altquests', () {
    final original = completedEpilogue(oldEnding: 'end-mercy');
    var c = read(original);
    final before = engine.act(c, 'Hinweise').campaign.messages.last.text;
    expect(before, isNot(contains('Tarek bestätigt zwei Handschriften')));
    c = investigate(c, 'tarek');
    final after = engine.act(c, 'Hinweise').campaign.messages.last.text;
    expect(after, contains('zwei Handschriften'));
    expect(c.facts['ending'], 'end-mercy');
    expect(c.hero.toJson(), original.hero.toJson());
    expect(c.quests.singleWhere((q) => q.id == 'voice-main').status,
        'completed');
  });
}
