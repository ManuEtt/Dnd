import '../domain/models.dart';
import 'rabenwacht_campaign.dart' show RabenwachtTurn;

/// Optionale Nachgeschichte nach dem abgeschlossenen Rabenwacht-Epilog.
/// Untersucht Zeugnisse, nicht regelwidrig die Vergangenheit oder Zukunft.
class FourteenthVoiceMorrow {
  const FourteenthVoiceMorrow._();

  static const _scenes = {
    'voice-epilogue-complete',
    'voice-morrow-square',
    'voice-morrow-elda',
    'voice-morrow-tarek',
    'voice-morrow-well',
    'voice-morrow-council',
    'voice-morrow-end-sealed',
    'voice-morrow-end-published',
    'voice-morrow-end-liora',
  };

  static bool handles(String stage) => _scenes.contains(stage);

  static bool _said(String text, String alternatives) =>
      alternatives.split('|').any(text.contains);

  static bool _negated(String text) => RegExp(
    r'\b(?:nicht|niemals|ohne|kein(?:e|en|em|er|es)?)\b',
  ).hasMatch(text);

  static bool _mayStart(Campaign c) =>
      c.facts['voice:ending'] != null &&
      const {
        'memorial',
        'testimonies',
        'festival',
      }.contains(c.facts['voice:legacy']) &&
      c.facts['voice:witnessChain'] == 'true' &&
      c.quests.any((q) => q.id == 'voice-epilogue' && q.status == 'completed');

  static int clueCount(Campaign c) => const [
    'voice:morrow:elda',
    'voice:morrow:tarek',
    'voice:morrow:well',
  ].where((key) => c.facts[key] == 'true').length;

  static String _legacyContext(Campaign c) => switch (c.facts['voice:legacy']) {
    'memorial' =>
      'Das freiwillige Gedenkbuch enthält absichtlich '
          'auch weiße Seiten für offene Fragen.',
    'testimonies' =>
      'Die veröffentlichten Zeugnisse tragen eigene Namen '
          'und widersprechen sich manchmal.',
    'festival' =>
      'Das Dorffest ist vorbei, aber die Menschen '
          'sprechen noch immer über ihre Erinnerungen.',
    _ => 'Das Dorf trägt seine neue Erinnerung gemeinsam.',
  };

  static RabenwachtTurn _move(
    Campaign c,
    String stage,
    String narration, {
    Map<String, String> gained = const {},
  }) {
    final end = stage.startsWith('voice-morrow-end-');
    final facts = {
      ...c.facts,
      ...gained,
      'voice:visited:${stage.replaceFirst('voice-', '')}': 'true',
      'location': switch (stage) {
        'voice-morrow-elda' => 'Eldas Haus',
        'voice-morrow-tarek' => 'Gasthaus Zum Letzten Licht',
        'voice-morrow-well' => 'Brunnen von Rabenwacht',
        _ => 'Dorfplatz von Rabenwacht',
      },
    };
    final next = c.copyWith(
      scene: '${c.hero.name}, $narration',
      storyBible: {...c.storyBible, 'stage': stage},
      facts: facts,
      quests: [
        for (final quest in c.quests)
          if (end && quest.id == 'voice-morrow')
            quest.copyWith(status: 'completed')
          else
            quest,
        if (stage == 'voice-morrow-square' &&
            !c.quests.any((q) => q.id == 'voice-morrow'))
          const Quest(
            id: 'voice-morrow',
            title: 'Der Brief von Morgen',
            description:
                'Lies den Brief, sichere mindestens zwei '
                'unabhängige Spuren und wähle, wie er bewahrt wird.',
          ),
      ],
      storyThreads: [
        for (final thread in c.storyThreads)
          if (end && thread.id == 'voice-morrow-truth')
            thread.copyWith(status: 'resolved')
          else
            thread,
        if (stage == 'voice-morrow-square' &&
            !c.storyThreads.any((t) => t.id == 'voice-morrow-truth'))
          const StoryThread(
            id: 'voice-morrow-truth',
            title: 'Die zwei Fassungen des Morgens',
            description:
                'Ein Brief verspricht Zukunft, belegt '
                'aber zunächst nur einen Streit um Erinnerung.',
          ),
      ],
    );
    return RabenwachtTurn(next, next.scene);
  }

  static RabenwachtTurn _ending(Campaign c, String stage, String response) {
    if (c.facts['voice:morrow:outcome'] != null ||
        clueCount(c) < 2 ||
        c.facts['voice:morrow:letterRead'] != 'true') {
      return RabenwachtTurn(
        c,
        'Du brauchst den untersuchten Brief '
        'und mindestens zwei unabhängige Spuren.',
      );
    }
    final ending = stage.replaceFirst('voice-morrow-end-', '');
    final witness = c.facts['voice:morrow:well'] == 'true'
        ? 'Die Spuren am Brunnen zeigen, '
              'dass die Schriftstücke herumgereicht wurden. '
        : 'Die am Brunnen fehlende Spur bleibt offen. ';
    final liora = c.facts['voice:lioraChoice'] == 'accuse'
        ? 'Liora nimmt deine frühere Anschuldigung '
              'nicht zurück, aber sie hört dir zu. '
        : 'Liora entscheidet auch jetzt selbst, '
              'welche Rolle sie in der Dorfgeschichte übernimmt. ';
    return _move(
      c,
      stage,
      '$response $witness$liora'
      'Es gibt keinen Beweis, dass der Brief die Zukunft '
      'vorhersagt oder die Vergangenheit verändert. '
      'Das ursprüngliche Finale und das gewählte '
      'Dorfvermächtnis bleiben unberührt.',
      gained: {'voice:morrow:outcome': ending},
    );
  }

  static RabenwachtTurn advance(Campaign c, String input) {
    final stage = c.storyBible['stage'] ?? '';
    if (c.storyBible['mode'] != 'rabenwacht-voice-v1' || !handles(stage)) {
      throw const FormatException('Ungültige Nachgeschichtenszene.');
    }
    final text = input.trim().toLowerCase();

    if (stage == 'voice-epilogue-complete') {
      if (!_mayStart(c)) {
        return RabenwachtTurn(
          c,
          'Der Brief von Morgen wird erst nach einem '
          'wirklich abgeschlossenen Epilog freigeschaltet.',
        );
      }
      if (_said(text, 'brief von morgen beginnen') && !_negated(text)) {
        return _move(
          c,
          'voice-morrow-square',
          'Drei Wochen nach dem Ratsbeschluss liegt '
              'ein Umschlag ohne Absender auf der Bank '
              'vor dem Brunnen. Darauf steht: '
              '„Für alle, die glauben, morgen schon zu kennen.“ '
              '${_legacyContext(c)} '
              'Du kannst den Brief zunächst öffnen.',
          gained: {'voice:morrow:started': 'true'},
        );
      }
      return RabenwachtTurn(
        c,
        'Rabenwachts Epilog bleibt abgeschlossen. '
        'Mit „Brief von Morgen beginnen“ kannst du '
        'eine freiwillige Nachgeschichte starten.',
      );
    }

    if (stage.startsWith('voice-morrow-end-')) {
      return RabenwachtTurn(
        c,
        'Der Brief von Morgen ist abgeschlossen. '
        'Deine Entscheidung bleibt im Spielstand bestehen.',
      );
    }

    if (c.facts['voice:morrow:started'] != 'true' || !_mayStart(c)) {
      return RabenwachtTurn(
        c,
        'Diese Nachgeschichte muss aus dem '
        'vollständigen Epilog begonnen werden.',
      );
    }

    if (stage == 'voice-morrow-square') {
      if (_negated(text)) {
        return RabenwachtTurn(c, 'Du führst die verneinte Handlung nicht aus.');
      }
      if (_said(text, 'brief öffnen|brief oeffnen|brief lesen')) {
        if (c.facts['voice:morrow:letterRead'] == 'true') {
          return RabenwachtTurn(
            c,
            'Du hast beide Seiten schon gelesen. '
            'Prüfe ihre Herkunft bei Elda, Tarek '
            'oder am Brunnen.',
          );
        }
        return _move(
          c,
          stage,
          'Du öffnest den Umschlag. Zwei Seiten '
          'beschreiben denselben Morgen: '
          'eine nennt den Brunnen leer, die andere '
          'berichtet von drei Zeugen dort. '
          'Beide nennen sich „die einzige Wahrheit“. '
          'Ein Datum allein ist keine Prophezeiung. '
          'Elda, Tarek und der Brunnen können '
          'unabhängige Spuren liefern.',
          gained: {'voice:morrow:letterRead': 'true'},
        );
      }
      if (c.facts['voice:morrow:letterRead'] != 'true') {
        return RabenwachtTurn(
          c,
          'Lies den Brief zuerst, statt ihm '
          'ungeprüft eine Bedeutung zu geben.',
        );
      }
      if (_said(text, 'elda|zeichnungen|eldas haus')) {
        return _move(
          c,
          'voice-morrow-elda',
          'Elda bittet dich, beide Seiten '
              'mit den Aufzeichnungen ihres Hauses '
              'zu vergleichen. Untersuche ihr Register.',
        );
      }
      if (_said(text, 'tarek|gasthaus|druck')) {
        return _move(
          c,
          'voice-morrow-tarek',
          'Tarek zeigt dir sein Tischpult. '
              'Die zwei Papiere könnten dort '
              'beschrieben worden sein. '
              'Untersuche die Tinte.',
        );
      }
      if (_said(text, 'brunnen|wasser|spuren am platz')) {
        return _move(
          c,
          'voice-morrow-well',
          'Am Brunnen erinnern sich Menschen '
              'an verschiedene Besucher. '
              'Prüfe die Spuren vor Ort, '
              'ohne Liora sofort verantwortlich zu machen.',
        );
      }
      if (_said(text, 'rat einberufen|zeugen zusammenrufen|brief beraten')) {
        if (clueCount(c) < 2) {
          return RabenwachtTurn(
            c,
            'Sichere mindestens zwei unterschiedliche '
            'Spuren, ehe du den Brief öffentlich bewertest.',
          );
        }
        return _move(
          c,
          'voice-morrow-council',
          'Die Zeugen kommen auf dem Platz zusammen. '
              'Zwei oder mehr gesicherte Spuren zeigen, '
              'woher Teile des Briefs stammen könnten, '
              'aber beweisen keine Zukunft. '
              'Du kannst ihn versiegelt verwahren, '
              'die Seiten mit Quellenangaben veröffentlichen '
              'oder Liora selbst darüber entscheiden lassen.',
        );
      }
      return RabenwachtTurn(
        c,
        'Der Brief ist geöffnet. '
        'Gesicherte Spuren: ${clueCount(c)} von 3. '
        'Besuche Elda, Tarek oder den Brunnen; '
        'mit zwei Spuren kannst du den Rat einberufen.',
      );
    }

    if (const {
      'voice-morrow-elda',
      'voice-morrow-tarek',
      'voice-morrow-well',
    }.contains(stage)) {
      if (_said(text, 'zurück|zurueck|dorfplatz') && !_negated(text)) {
        return _move(
          c,
          'voice-morrow-square',
          'Du kehrst mit deinen gesicherten '
              'Beobachtungen zum Dorfplatz zurück.',
        );
      }
      if (_negated(text)) {
        return RabenwachtTurn(c, 'Die Untersuchung wird nicht durchgeführt.');
      }
      if (stage == 'voice-morrow-elda' &&
          _said(text, 'register untersuchen|register prüfen|buch prüfen')) {
        if (c.facts['voice:morrow:elda'] == 'true') {
          return RabenwachtTurn(
            c,
            'Eldas Register ist bereits geprüft. '
            'Andere Quellen bleiben unabhängig davon.',
          );
        }
        return _move(
          c,
          stage,
          'Eldas Register führt den Brief als '
          'heute eingegangene Abschrift, '
          'nicht als altes Original. '
          'Sie will die Unsicherheit sichtbar halten. '
          'Du kannst zurück zum Platz gehen.',
          gained: {'voice:morrow:elda': 'true'},
        );
      }
      if (stage == 'voice-morrow-tarek' &&
          _said(text, 'tinte untersuchen|tinte prüfen|papier prüfen')) {
        if (c.facts['voice:morrow:tarek'] == 'true') {
          return RabenwachtTurn(
            c,
            'Du hast die beiden Tintenspuren '
            'bereits verglichen.',
          );
        }
        return _move(
          c,
          stage,
          'Tarek findet zwei Handschriften auf '
          'Papier aus demselben Stapel. '
          'Es belegt einen gemeinsamen Ursprung '
          'des Materials, aber keinen Autor. '
          'Du kannst zurück zum Platz gehen.',
          gained: {'voice:morrow:tarek': 'true'},
        );
      }
      if (stage == 'voice-morrow-well' &&
          _said(text, 'spuren prüfen|spuren untersuchen|platz untersuchen')) {
        if (c.facts['voice:morrow:well'] == 'true') {
          return RabenwachtTurn(
            c,
            'Die Spuren am Brunnen '
            'sind bereits dokumentiert.',
          );
        }
        return _move(
          c,
          stage,
          'Am Brunnen siehst du trockene '
          'Wachsflecken am Rand des Umschlags. '
          'Mehrere Menschen könnten ihn '
          'dort abgelegt oder berührt haben. '
          'Niemand wird allein deshalb beschuldigt. '
          'Du kannst zurück zum Platz gehen.',
          gained: {'voice:morrow:well': 'true'},
        );
      }
      return RabenwachtTurn(
        c,
        'Untersuche hier die angebotene Spur '
        'oder kehre zum Dorfplatz zurück.',
      );
    }

    if (stage == 'voice-morrow-council') {
      if (_said(text, 'zurück|weitere spur|dritte spur') && !_negated(text)) {
        return _move(
          c,
          'voice-morrow-square',
          'Der Rat unterbricht seine Beratung. '
              'Die gesicherten Spuren bleiben erhalten.',
        );
      }
      if (clueCount(c) < 2 || c.facts['voice:morrow:letterRead'] != 'true') {
        return RabenwachtTurn(
          c,
          'Die gesicherte Beweiskette ist unvollständig.',
        );
      }
      if (_negated(text)) {
        return RabenwachtTurn(
          c,
          'Eine verneinte Entscheidung ist keine Zustimmung.',
        );
      }
      if (_said(text, 'brief versiegelt verwahren')) {
        return _ending(
          c,
          'voice-morrow-end-sealed',
          'Du übergibst den Brief in versiegelter '
              'Verwahrung an den Rat. Im öffentlichen '
              'Verzeichnis steht, dass er existiert, '
              'seine Behauptungen gelten nicht als bewiesen.',
        );
      }
      if (_said(
        text,
        'brief mit quellen veröffentlichen|brief mit quellen veroeffentlichen',
      )) {
        return _ending(
          c,
          'voice-morrow-end-published',
          'Du veröffentlichst beide Fassungen '
              'mit Herkunftshinweisen und markierten '
              'Widersprüchen. Niemand muss eine der '
              'Versionen zur absoluten Wahrheit erklären.',
        );
      }
      if (_said(text, 'liora selbst entscheiden lassen')) {
        return _ending(
          c,
          'voice-morrow-end-liora',
          'Du fragst Liora, ohne ihr eine Aufgabe '
              'zuzuweisen. Sie bittet darum, '
              'erst mit Elda und Tarek zu sprechen, '
              'bevor sie über eine Veröffentlichung '
              'entscheidet. Der Rat akzeptiert '
              'ihre freie Antwort.',
        );
      }
      return RabenwachtTurn(
        c,
        'Der Rat wartet auf eine bewusste Entscheidung: '
        'Brief versiegelt verwahren, '
        'Brief mit Quellen veröffentlichen '
        'oder Liora selbst entscheiden lassen.',
      );
    }

    throw const FormatException('Unbekannte Szene des Briefs von Morgen.');
  }
}
