import '../domain/models.dart';
import 'rabenwacht_campaign.dart' show RabenwachtTurn;

/// Spielbarer Epilog nach einem echten Akt-VIII-Ende.
/// Ausschließlich erzählerische Folgen, keine SRD- oder Charakterbuchungen.
class FourteenthVoiceEpilogue {
  const FourteenthVoiceEpilogue._();

  static const _endStages = {
    'voice-end-oath',
    'voice-end-archive',
    'voice-end-accord',
  };
  static const _epilogueStages = {
    'voice-epilogue-square',
    'voice-epilogue-elda',
    'voice-epilogue-tarek',
    'voice-epilogue-liora',
    'voice-epilogue-future',
    'voice-epilogue-complete',
  };

  static bool handles(String stage) =>
      _endStages.contains(stage) || _epilogueStages.contains(stage);

  static bool _said(String text, String alternatives) =>
      alternatives.split('|').any(text.contains);

  static bool _negated(String text) => RegExp(
    r'\b(?:nicht|niemals|ohne|kein(?:e|en|em|er|es)?)\b',
  ).hasMatch(text);

  static bool _hasRealEnding(Campaign c) =>
      const {
        'end-oath',
        'end-archive',
        'end-accord',
      }.contains(c.facts['voice:ending']) &&
      c.facts['voice:witnessChain'] == 'true' &&
      c.quests.any((q) => q.id == 'voice-main' && q.status == 'completed');

  static int witnessCount(Campaign c) => const [
    'voice:epilogue:elda',
    'voice:epilogue:tarek',
    'voice:epilogue:liora',
  ].where((key) => c.facts[key] == 'true').length;

  static String _endingConsequence(Campaign c) =>
      switch (c.facts['voice:ending']) {
        'end-oath' =>
          'Die Glocke trägt die Stimmen wieder über den Dorfplatz. '
              'Der erneuerte Eid schützt Erinnerungen durch '
              'freiwillige gegenseitige Zeugenschaft.',
        'end-archive' =>
          'Vom unmöglichen Archiv ist nur ein leerer Grundriss übrig. '
              'Drei gesicherte Originalbelege liegen getrennt '
              'bei den Menschen, die sie bewahren wollen.',
        'end-accord' =>
          'Im Ratsbuch stehen mehrere Sichtweisen nebeneinander. '
              'Der neue Eid verlangt keine einzige '
              'unumstößliche Wahrheit von allen.',
        _ => 'Rabenwacht erzählt seine Geschichte neu.',
      };

  static String _oldConsequence(Campaign c) =>
      switch (c.facts['voice:originEnding']) {
        'end-seal' =>
          'Die alte Siegelgrenze bleibt sichtbar; '
              'Seren ist nicht körperlich zurückgekehrt.',
        'end-break' =>
          'Das gebrochene Siegel lässt die Bewohner '
              'auf dem Dorfplatz wachsam zusammenstehen.',
        'end-mercy' =>
          'Serens Erlösung bleibt bestehen. '
              'Ihr Mut wird erinnert, ohne sie zurückzurufen.',
        'end-chorus' =>
          'Der Namenchor klingt im Morgenwind; '
              'niemand zwingt Seren zu einer Rückkehr.',
        _ => 'Die Narben der ersten Glockennacht bleiben sichtbar.',
      };

  static String _lioraConsequence(Campaign c) =>
      switch (c.facts['voice:lioraChoice']) {
        'protect' =>
          'Liora erinnert sich daran, dass du sie '
              'vor der Menschenmenge geschützt hast.',
        'accuse' =>
          'Liora erinnert dich an deine öffentliche '
              'Anschuldigung. Vertrauen wächst langsam.',
        'evidence' =>
          'Liora respektiert, dass du zuerst '
              'nach unabhängigen Belegen gesucht hast.',
        _ =>
          'Liora entscheidet selbst, welche Erinnerungen '
              'sie mit dir teilen möchte.',
      };

  static String _debtConsequence(Campaign c) =>
      switch (c.facts['voice:chronistChoice']) {
        'accepted' =>
          'Der früher versprochene Preis bleibt ausdrücklich '
              'bestritten. Niemand wurde ausgelöscht.',
        'feigned' =>
          'Der Chronist hatte deine Täuschung bemerkt; '
              'seine Behauptungen sind dennoch kein Zeugnis.',
        'refused' =>
          'Deine Weigerung gegen den Handel ist '
              'in den Zeugenaussagen erhalten.',
        _ => 'Kein Opfer wurde dem Chronisten versprochen.',
      };

  static RabenwachtTurn _move(
    Campaign c,
    String stage,
    String prose, {
    Map<String, String> gained = const {},
  }) {
    final isComplete = stage == 'voice-epilogue-complete';
    final facts = {
      ...c.facts,
      ...gained,
      'voice:visited:${stage.replaceFirst('voice-', '')}': 'true',
      'location': switch (stage) {
        'voice-epilogue-elda' => 'Eldas Haus',
        'voice-epilogue-tarek' => 'Gasthaus Zum Letzten Licht',
        'voice-epilogue-liora' => 'Brunnen von Rabenwacht',
        _ => 'Dorfplatz von Rabenwacht',
      },
    };
    final next = c.copyWith(
      scene: '${c.hero.name}, $prose',
      storyBible: {...c.storyBible, 'stage': stage},
      facts: facts,
      quests: [
        for (final q in c.quests)
          if (q.id == 'voice-epilogue' && isComplete)
            q.copyWith(status: 'completed')
          else
            q,
        if (stage == 'voice-epilogue-square' &&
            !c.quests.any((q) => q.id == 'voice-epilogue'))
          const Quest(
            id: 'voice-epilogue',
            title: 'Was Rabenwacht bewahrt',
            description:
                'Höre mindestens zwei Dorfbewohner an und '
                'entscheide, was dem Dorf erhalten bleibt.',
          ),
      ],
      storyThreads: [
        for (final thread in c.storyThreads)
          if (thread.id == 'voice-liora-origin' &&
              facts['voice:epilogue:liora'] == 'true')
            thread.copyWith(status: 'resolved')
          else
            thread,
        if (isComplete &&
            !c.storyThreads.any((t) => t.id == 'voice-village-legacy'))
          const StoryThread(
            id: 'voice-village-legacy',
            title: 'Rabenwachts gemeinsames Gedächtnis',
            description: 'Die Gemeinde trägt ihre Entscheidung selbst.',
            status: 'resolved',
          ),
      ],
    );
    return RabenwachtTurn(next, next.scene);
  }

  static RabenwachtTurn advance(Campaign c, String input) {
    final stage = c.storyBible['stage'] ?? '';
    if (c.storyBible['mode'] != 'rabenwacht-voice-v1' || !handles(stage)) {
      throw const FormatException('Unbekannte Epilogszene.');
    }
    if (!_hasRealEnding(c)) {
      return RabenwachtTurn(
        c,
        'Der Epilog setzt ein tatsächlich abgeschlossenes '
        'Rabenwacht-Finale und die bestätigte Beweiskette voraus.',
      );
    }

    final text = input.trim().toLowerCase();
    if (_endStages.contains(stage)) {
      final correctEnd =
          c.facts['voice:ending'] == stage.replaceFirst('voice-', '');
      if (!correctEnd) {
        return RabenwachtTurn(
          c,
          'Das gewählte Finale stimmt nicht mit '
          'dem gespeicherten Ausgang überein.',
        );
      }
      if (_said(text, 'epilog beginnen|epilog erleben|eine woche später') &&
          !_negated(text)) {
        return _move(
          c,
          'voice-epilogue-square',
          'Sieben Tage nach der vierzehnten Stimme '
              'füllen sich die Straßen mit Menschen. '
              '${_endingConsequence(c)} '
              '${_oldConsequence(c)} '
              'Elda sitzt vor ihrem Haus, Tarek öffnet '
              'das Gasthaus und Liora steht am Brunnen. '
              'Du kannst jede Person besuchen; '
              'mindestens zwei Stimmen sollten gehört werden.',
          gained: {'voice:epilogueStarted': 'true'},
        );
      }
      return RabenwachtTurn(
        c,
        'Die vierzehnte Stimme ist abgeschlossen. '
        'Deine Entscheidung bleibt gespeichert. '
        'Mit „Epilog beginnen“ kannst du erfahren, '
        'wie es Rabenwacht eine Woche später geht.',
      );
    }

    if (c.facts['voice:epilogueStarted'] != 'true') {
      return RabenwachtTurn(
        c,
        'Der Epilog wurde noch nicht ausdrücklich begonnen.',
      );
    }
    if (stage == 'voice-epilogue-complete') {
      return RabenwachtTurn(
        c,
        'Rabenwachts Epilog ist abgeschlossen. '
        'Du kannst den Dorfentscheid im Tagebuch nachlesen. '
        'Frühere Entscheidungen bleiben unverändert.',
      );
    }

    if (stage == 'voice-epilogue-square') {
      if (_negated(text)) {
        return RabenwachtTurn(
          c,
          'Niemand wird ohne deinen Entschluss besucht.',
        );
      }
      if (_said(text, 'elda|teller|zeichnung')) {
        return _move(
          c,
          'voice-epilogue-elda',
          c.facts['voice:memorySketch'] == 'true'
              ? 'Elda stellt diesmal nur die Teller auf, '
                    'deren Gäste sie benennen kann. '
                    'Die alte Kinderzeichnung bewahrt sie '
                    'als widersprüchliche Spur, nicht als Beweis '
                    'für eine erfundene Tochter. '
                    'Du darfst zum Dorfplatz zurückkehren.'
              : 'Elda deckt einen vierten Teller, obwohl '
                    'sie sich dessen Besitzer nicht sicher ist. '
                    'Sie möchte Erinnerungen aufschreiben, '
                    'ohne fremde Geschichten für wahr zu erklären. '
                    'Du darfst zum Dorfplatz zurückkehren.',
          gained: {'voice:epilogue:elda': 'true'},
        );
      }
      if (_said(text, 'tarek|gasthaus|brief')) {
        return _move(
          c,
          'voice-epilogue-tarek',
          c.facts['voice:splitInkLetter'] == 'true'
              ? 'Tarek zeigt dir das Schriftstück mit '
                    'seinen zwei Tintenschichten. '
                    'Jetzt bietet er jedem Zeugen ein eigenes '
                    'Blatt an, damit niemand allein die Chronik '
                    'des Dorfes schreiben darf. '
                    'Du darfst zum Dorfplatz zurückkehren.'
              : 'Tarek schlägt im Gasthaus ein neues Gästebuch '
                    'auf. Er will Zeugnisse voneinander trennen, '
                    'solange ihre Herkunft ungeklärt bleibt. '
                    'Du darfst zum Dorfplatz zurückkehren.',
          gained: {'voice:epilogue:tarek': 'true'},
        );
      }
      if (_said(text, 'liora|brunnen|fremde')) {
        return _move(
          c,
          'voice-epilogue-liora',
          '${_lioraConsequence(c)} '
              'Sie wird weder zum Symbol eines Eids '
              'noch zum Preis für einen anderen Menschen. '
              '${c.facts['voice:nameCustody'] == 'liora' ? 'Sie hat die Abschrift freiwillig gezeigt.' : 'Sie vertraut dir die Bewahrung der Abschrift zu.'} '
              'Sie möchte Rabenwacht als freie Person '
              'kennenlernen und bittet um Geduld. '
              'Du darfst zum Dorfplatz zurückkehren.',
          gained: {'voice:epilogue:liora': 'true'},
        );
      }
      if (_said(
        text,
        'dorfversammlung|dorfzukunft|zukunft entscheiden|epilog abschließen|epilog abschliessen',
      )) {
        if (witnessCount(c) < 2) {
          return RabenwachtTurn(
            c,
            'Bevor du die Zukunft des Dorfes mitgestaltest, '
            'höre mindestens zwei verschiedene Menschen an.',
          );
        }
        return _move(
          c,
          'voice-epilogue-future',
          'Zwei oder mehr Menschen haben dir ihre Sicht '
              'erzählt. Der Dorfplatz erwartet keinen '
              'weiteren erzwungenen Eid. Du kannst '
              'ein Gedenkbuch anlegen, Zeugnisse veröffentlichen '
              'oder ein Erinnerungsfest veranstalten. '
              'Du darfst auch erst weitere Menschen besuchen.',
        );
      }
      return RabenwachtTurn(
        c,
        'Besuche Elda, Tarek oder Liora. '
        'Gehörte Stimmen: ${witnessCount(c)} von 3. '
        'Nach zwei Gesprächen kannst du mit '
        '„Dorfzukunft entscheiden“ weitermachen.',
      );
    }

    if (const {
      'voice-epilogue-elda',
      'voice-epilogue-tarek',
      'voice-epilogue-liora',
    }.contains(stage)) {
      if (_said(text, 'zurück|zurueck|dorfplatz|platz') && !_negated(text)) {
        return _move(
          c,
          'voice-epilogue-square',
          'Auf dem Dorfplatz hörst du wieder die '
              'gewöhnlichen Stimmen Rabenwachts. '
              'Du kannst weitere Menschen besuchen '
              'oder die Dorfzukunft entscheiden.',
        );
      }
      return RabenwachtTurn(
        c,
        'Du kannst zuhörend verweilen oder '
        'zum Dorfplatz zurückkehren.',
      );
    }

    if (stage == 'voice-epilogue-future') {
      if (_said(text, 'zurück|weitere menschen|mehr gespräche') &&
          !_negated(text)) {
        return _move(
          c,
          'voice-epilogue-square',
          'Du kehrst zu den Menschen zurück. '
              'Ihre Stimmen warten ohne Zeitdruck.',
        );
      }
      if (_negated(text)) {
        return RabenwachtTurn(
          c,
          'Du hast noch keine Dorfentscheidung bestätigt.',
        );
      }
      if (_said(text, 'gedenkbuch anlegen')) {
        return _finish(
          c,
          'memorial',
          'Du legst ein Gedenkbuch an, das auch '
              'unvollständige Erinnerungen kenntlich macht. '
              'Jede Familie entscheidet selbst, '
              'was sie darin festhalten will.',
        );
      }
      if (_said(text, 'zeugnisse veröffentlichen|zeugnisse veroeffentlichen')) {
        return _finish(
          c,
          'testimonies',
          'Die Bewohner veröffentlichen ihre '
              'persönlichen, getrennt gekennzeichneten '
              'Zeugnisse. Das Archiv des Chronisten '
              'wird dadurch nicht wiederhergestellt.',
        );
      }
      if (_said(text, 'erinnerungsfest veranstalten')) {
        return _finish(
          c,
          'festival',
          'Auf dem Platz feiern die Menschen, '
              'die noch hier sind, gemeinsam mit '
              'denen, die eine Geschichte erzählen wollen. '
              'Widersprüche dürfen bestehen bleiben.',
        );
      }
      return RabenwachtTurn(
        c,
        'Wähle bewusst: Gedenkbuch anlegen, '
        'Zeugnisse veröffentlichen oder '
        'Erinnerungsfest veranstalten.',
      );
    }

    throw const FormatException('Ungültige Epilogszene.');
  }

  static RabenwachtTurn _finish(Campaign c, String legacy, String description) {
    if (witnessCount(c) < 2 || c.facts['voice:legacy'] != null) {
      return RabenwachtTurn(c, 'Die Epilogentscheidung ist nicht verfügbar.');
    }
    final risk = c.facts['voice:publicTestimony'] == 'true'
        ? 'Deine öffentliche Ersatzzeugenaussage bleibt '
              'als bestrittenes Zeugnis erkennbar. '
        : 'Drei unabhängige Belege bleiben gesichert. ';
    return _move(
      c,
      'voice-epilogue-complete',
      '$description $risk${_debtConsequence(c)} '
          '${_endingConsequence(c)} '
          'Rabenwacht bewahrt diese Wahl, ohne '
          'vergangene Entscheidungen umzuschreiben.',
      gained: {'voice:legacy': legacy},
    );
  }
}
