import '../domain/models.dart';
import 'rabenwacht_campaign.dart' show RabenwachtTurn;

/// Akt VIII. Geschützte, narrative Auflösung ohne Kampf-, EP- oder SRD-Effekte.
class FourteenthVoiceAct8 {
  const FourteenthVoiceAct8._();

  static const _stages = {
    'voice-threshold',
    'voice-council',
    'voice-testimony',
    'voice-ritual',
    'voice-end-oath',
    'voice-end-archive',
    'voice-end-accord',
  };

  static bool handles(String stage) => _stages.contains(stage);

  static bool _said(String text, String words) =>
      words.split('|').any(text.contains);

  static bool _negated(String text) => RegExp(
    r'\b(?:nicht|niemals|ohne|kein(?:e|en|em|er|es)?)\b',
  ).hasMatch(text);

  static int evidenceCount(Campaign c) => const [
    'voice:memorySketch',
    'voice:splitInkLetter',
    'voice:namelessGrave',
  ].where((key) => c.facts[key] == 'true').length;

  static bool _hasCustody(Campaign c) =>
      c.facts['voice:oathPageFound'] == 'true' &&
      const ['hero', 'liora'].contains(c.facts['voice:nameCustody']);

  static String _oldEnding(Campaign c) =>
      switch (c.facts['voice:originEnding']) {
        'end-seal' =>
          'Die erneuerte Siegelgrenze lässt nur Worte durch; '
              'Seren kann nicht persönlich an der Versammlung teilnehmen.',
        'end-break' =>
          'Seit dem Bruch des Siegels erreicht der Chronist '
              'den Platz ohne Schutz. Die Bewohner halten zusammen.',
        'end-mercy' =>
          'Seren wurde erlöst und ist keine gefangene Zeugin. '
              'Ihr früherer Mut lebt in den Aussagen der Familien.',
        'end-chorus' =>
          'Der Namenchor hat Serens Zeugnis bewahrt. '
              'Seren darf sich frei entscheiden, ob sie antwortet.',
        _ => 'Der Rat erinnert sich an die Glockennacht.',
      };

  static RabenwachtTurn _move(
    Campaign c,
    String stage,
    String prose, {
    Map<String, String> gained = const {},
  }) {
    final end = stage.startsWith('voice-end-');
    final facts = {
      ...c.facts,
      ...gained,
      'voice:visited:${stage.replaceFirst('voice-', '')}': 'true',
      if (end) 'voice:ending': stage.replaceFirst('voice-', ''),
      if (end && c.facts['voice:chronistDebt'] == 'pending')
        'voice:chronistDebt': 'contested',
    };
    final next = c.copyWith(
      scene: '${c.hero.name}, $prose',
      storyBible: {...c.storyBible, 'stage': stage},
      facts: facts,
      quests: [
        for (final q in c.quests)
          if (end && q.id == 'voice-main')
            q.copyWith(status: 'completed')
          else
            q,
      ],
      storyThreads: [
        for (final thread in c.storyThreads)
          if (end && thread.id == 'voice-fourteenth-name')
            thread.copyWith(status: 'resolved')
          else
            thread,
      ],
    );
    return RabenwachtTurn(next, next.scene);
  }

  static RabenwachtTurn _finish(Campaign c, String stage, String prose) {
    final chronist = switch (c.facts['voice:chronistChoice']) {
      'refused' => 'Du hast dem Chronisten nie dein Einverständnis gegeben. ',
      'feigned' =>
        'Der Chronist erkennt deinen früheren Täuschungsversuch, '
            'aber die öffentlichen Zeugnisse entziehen ihm die Macht. ',
      'accepted' =>
        'Du widerrufst öffentlich den unvollstreckten Handel. '
            'Die Schuld wird bestritten, niemand wird ausgelöscht. ',
      _ => 'Du hast dem Chronisten kein Opfer versprochen. ',
    };
    final liora = c.facts['voice:nameCustody'] == 'liora'
        ? 'Liora zeigt den Zeugen die ihr anvertraute Abschrift. '
        : 'Du legst die selbst verwahrte Abschrift vor den Rat. ';
    final memory = c.facts['voice:publicTestimony'] == 'true'
        ? 'Die öffentliche Ersatzzeugenaussage bleibt umstritten, '
              'wird aber im Ratsbuch als solche kenntlich gemacht. '
        : 'Drei voneinander unabhängige Erinnerungsbelege '
              'bestätigen die Zeugenfolge. ';
    return _move(
      c,
      stage,
      '$liora$memory$chronist$prose ${_oldEnding(c)} '
      'Liora behält ihr eigenes Leben und ihre Entscheidungen. '
      'Keine Erinnerung eines Unbeteiligten wird als Preis gelöscht.',
    );
  }

  static RabenwachtTurn advance(Campaign c, String input) {
    final stage = c.storyBible['stage'] ?? '';
    if (c.storyBible['mode'] != 'rabenwacht-voice-v1' || !handles(stage)) {
      throw const FormatException('Ungültiger Handlungsstand in Akt VIII.');
    }
    final text = input.trim().toLowerCase();
    if (stage.startsWith('voice-end-')) {
      return RabenwachtTurn(
        c,
        'Die vierzehnte Stimme ist abgeschlossen. '
        'Deine Entscheidung bleibt im Spielstand erhalten.',
      );
    }
    if (stage == 'voice-threshold') {
      if (!_hasCustody(c) || evidenceCount(c) < 2) {
        return RabenwachtTurn(
          c,
          'Für den Rat benötigst du das vierzehnte Blatt '
          'und mindestens zwei unabhängige Spuren.',
        );
      }
      if (_said(text, 'rat|versammlung|zeugen versammeln|dorfplatz') &&
          !_negated(text)) {
        return _move(
          c,
          'voice-council',
          'Die Glocken schweigen, als sich der Rat der Zeugen '
              'auf dem Dorfplatz versammelt. Elda, Tarek und '
              'die anderen Bewohner prüfen deine Belege. '
              '${_oldEnding(c)} '
              'Du kannst die Beweise verbinden, eine fehlende '
              'Aussage öffentlich ersetzen oder die dritte Spur '
              'im Dorf nachholen.',
          gained: {'location': 'Rat der Zeugen'},
        );
      }
      return RabenwachtTurn(
        c,
        'Das Eidblatt ist gesichert. Berufe den Rat der Zeugen ein.',
      );
    }

    if (stage == 'voice-council') {
      if (_said(text, 'dorfplatz|zurück|nachholen|weitere spur') &&
          !_negated(text)) {
        return _move(
          c,
          'voice-square',
          'Du vertagst den Rat. Elda, Tarek und der Friedhof '
              'stehen weiterhin für Nachforschungen offen.',
          gained: {'location': 'Dorfplatz von Rabenwacht'},
        );
      }
      if (_said(text, 'aussage|selbst bezeugen|öffentlich zeugen') &&
          !_negated(text)) {
        if (evidenceCount(c) >= 3) {
          return RabenwachtTurn(
            c,
            'Drei unabhängige Spuren sind bereits gesichert. '
            'Verbinde die Beweise ohne Ersatzzeugnis.',
          );
        }
        return _move(
          c,
          'voice-testimony',
          'Zwei Belege sind gesichert, ein dritter fehlt. '
              'Du kannst die Lücke öffentlich bezeugen. '
              'Dein Wort wird als riskante Ersatzzeugenaussage '
              'gekennzeichnet, nicht als gefundenes Dokument. '
              'Bestätige dazu ausdrücklich: '
              '„Ich bezeuge öffentlich die Lücke im Eid.“ '
              'Oder kehre zum Rat zurück.',
        );
      }
      if (_said(text, 'beweise verbinden|eid rekonstruieren|namen verbinden') &&
          !_negated(text)) {
        if (!_hasCustody(c)) {
          return RabenwachtTurn(c, 'Das vierzehnte Blatt fehlt.');
        }
        if (evidenceCount(c) < 3 &&
            c.facts['voice:publicTestimony'] != 'true') {
          return RabenwachtTurn(
            c,
            'Du benötigst drei voneinander unabhängige '
            'Belege oder eine ausdrücklich bestätigte '
            'öffentliche Ersatzzeugenaussage.',
          );
        }
        return _move(
          c,
          'voice-ritual',
          'Der Rat verbindet die Erinnerungen. '
              'Der ausgelöschte vierzehnte Name gehört '
              'dem Chronisten. Nicht die Zeit wurde gebrochen, '
              'sondern die Beweiskette zwischen den Menschen. '
              'Der Rat kann den Eid erneuern, nach Sicherung '
              'aller drei Belege das Archiv auflösen '
              'oder einen neuen gemeinsamen Eid verhandeln.',
          gained: {'voice:witnessChain': 'true'},
        );
      }
      return RabenwachtTurn(
        c,
        'Der Rat hat ${evidenceCount(c)} von 3 unabhängigen '
        'Erinnerungsbelegen. Verbinde die Beweise, '
        'biete ein öffentliches Zeugnis an oder '
        'hole die fehlende Spur nach.',
      );
    }

    if (stage == 'voice-testimony') {
      if (text == 'ich bezeuge öffentlich die lücke im eid.' ||
          text == 'ich bezeuge öffentlich die lücke im eid') {
        return _move(
          c,
          'voice-council',
          'Du bezeugst die Lücke vor allen Anwesenden. '
              'Einige Bewohner zweifeln dir, andere danken dir. '
              'Die Aussage wird getrennt von den Belegen '
              'aufgezeichnet. Verbinde nun die Beweise.',
          gained: {
            'voice:publicTestimony': 'true',
            'voice:testimonyRisk': 'true',
          },
        );
      }
      if (_said(text, 'zurück|abbruch|verzicht|lehn') && !_negated(text)) {
        return _move(
          c,
          'voice-council',
          'Du verzichtest vorerst auf die Ersatzzeugenaussage. '
              'Der Rat wartet auf neue Belege.',
        );
      }
      return RabenwachtTurn(
        c,
        'Ein öffentliches Zeugnis hat Folgen. '
        'Nur die eindeutige Bestätigung gilt als Aussage.',
      );
    }

    if (stage == 'voice-ritual') {
      if (_said(text, 'zurück zum rat|weitere belege sammeln') &&
          !_negated(text)) {
        return _move(
          c,
          'voice-council',
          'Du unterbrichst die Schlussentscheidung. '
              'Der Rat bewahrt seine bisherigen Aussagen. '
              'Weitere Spuren können weiterhin gesucht werden.',
        );
      }
      if (c.facts['voice:witnessChain'] != 'true') {
        return RabenwachtTurn(c, 'Die Beweiskette fehlt.');
      }
      if (_negated(text)) {
        return RabenwachtTurn(
          c,
          'Du hast noch keine endgültige Entscheidung getroffen.',
        );
      }
      if (_said(text, 'eid erneuern|alten eid erneuern|eid wiederherstellen')) {
        return _finish(
          c,
          'voice-end-oath',
          'Ihr erneuert die gegenseitige Zeugenschaft. '
              'Der Chronist kann die Erinnerung des Dorfes '
              'nicht länger allein umschreiben. Der neue '
              'Schwur bindet die Zeugen freiwillig an den Ort.',
        );
      }
      if (_said(text, 'archiv zerstören|archiv zerstoeren|archiv auflösen')) {
        if (evidenceCount(c) < 3) {
          return RabenwachtTurn(
            c,
            'Das Archiv darf erst nach Sicherung aller '
            'drei unabhängigen Belege aufgelöst werden. '
            'Wähle einen anderen Eid oder sammle die dritte Spur.',
          );
        }
        return _finish(
          c,
          'voice-end-archive',
          'Die drei gesicherten Zeugnisse werden '
              'vervielfältigt und öffentlich hinterlegt. '
              'Erst danach löst der Rat das Archiv '
              'der ungelebten Tage auf. Seine falschen '
              'Erinnerungen verlieren ihre Macht.',
        );
      }
      if (_said(text, 'neuen eid verhandeln|gemeinsamen eid verhandeln')) {
        return _finish(
          c,
          'voice-end-accord',
          'Die Bewohner sprechen nacheinander aus, '
              'welche Erinnerung sie bezeugen wollen. '
              'Niemand muss sich einer einzigen '
              'amtlichen Version unterwerfen. '
              'Der Chronist verliert sein Monopol.',
        );
      }
      return RabenwachtTurn(
        c,
        'Drei Wege bleiben: Eid erneuern, Archiv zerstören '
        'oder neuen Eid verhandeln. Deine Wahl ist endgültig.',
      );
    }
    throw const FormatException('Unbekannter Abschnitt in Akt VIII.');
  }
}
