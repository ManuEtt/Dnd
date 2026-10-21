import '../domain/models.dart';
import 'rabenwacht_campaign.dart' show RabenwachtTurn;

/// Akt VII: rein erzählerische Entscheidungen, keine Regel- oder Würfelhoheit.
/// Akt VIII bleibt gesperrt, bis die Zeugen- und Eidmechanik implementiert ist.
class FourteenthVoiceAct7 {
  const FourteenthVoiceAct7._();

  static bool handles(String stage) => const {
    'voice-gallery',
    'voice-library',
    'voice-price',
    'voice-ledger',
  }.contains(stage);

  static bool _has(String text, String alternatives) =>
      alternatives.split('|').any(text.contains);

  static bool _negated(String text) => RegExp(
    r'\b(?:nicht|niemals|ohne|kein(?:e|en|em|er|es)?)\b',
  ).hasMatch(text);

  static RabenwachtTurn _move(
    Campaign campaign,
    String stage,
    String narration, {
    Map<String, String> gained = const {},
  }) {
    final facts = {
      ...campaign.facts,
      ...gained,
      'voice:visited:${stage.replaceFirst('voice-', '')}': 'true',
    };
    final next = campaign.copyWith(
      scene: '${campaign.hero.name}, $narration',
      storyBible: {...campaign.storyBible, 'stage': stage},
      facts: facts,
      quests: [
        for (final quest in campaign.quests)
          if (quest.id == 'voice-chronist' &&
              facts['voice:chronistChoice'] != null)
            quest.copyWith(status: 'completed')
          else
            quest,
        if (stage == 'voice-library' &&
            !campaign.quests.any((q) => q.id == 'voice-chronist'))
          const Quest(
            id: 'voice-chronist',
            title: 'Ein unmögliches Angebot',
            description:
                'Prüfe die Bedingungen des Fremden und entscheide selbst.',
          ),
      ],
      storyThreads: [
        for (final thread in campaign.storyThreads)
          if (thread.id == 'voice-fourteenth-name' &&
              facts['voice:oathPageFound'] == 'true')
            thread.copyWith(
              description:
                  'Das vierzehnte Blatt belegt eine beschädigte Zeugenfolge.',
            )
          else
            thread,
      ],
    );
    return RabenwachtTurn(next, next.scene);
  }

  static RabenwachtTurn _decision(
    Campaign campaign,
    String decision,
    String narration, {
    Map<String, String> gained = const {},
  }) {
    final old = campaign.facts['voice:chronistChoice'];
    if (old != null) {
      return RabenwachtTurn(
        campaign,
        'Deine Antwort an den Chronisten ist bereits festgehalten. '
        'Ein neuer Satz kann diese Entscheidung nicht ungeschehen machen. '
        'Du kannst das vierzehnte Blatt suchen.',
      );
    }
    return _move(
      campaign,
      'voice-library',
      narration,
      gained: {'voice:chronistChoice': decision, ...gained},
    );
  }

  static RabenwachtTurn advance(Campaign campaign, String input) {
    final stage = campaign.storyBible['stage'] ?? '';
    if (campaign.storyBible['mode'] != 'rabenwacht-voice-v1' ||
        !handles(stage)) {
      throw const FormatException('Ungültiger Schauplatz in Akt VII.');
    }
    final text = input.trim().toLowerCase();
    if (_has(text, 'hinweise|ermittlungsstand|tagebuch')) {
      // Der aufrufende Akt-VI-Dispatcher verwaltet das Hinweisprotokoll.
      return RabenwachtTurn(campaign, '');
    }

    if (stage == 'voice-gallery') {
      if (_has(text, 'vergleich|porträt|portrait|bilder|rahmen|untersuch') &&
          !_negated(text)) {
        if (campaign.facts['voice:portraitCompared'] == 'true') {
          return RabenwachtTurn(
            campaign,
            'Du hast die Porträts bereits verglichen. '
            'Ihre Altersangaben widersprechen den gesicherten Spuren. '
            'Hinter der Galerie wartet die Bibliothek.',
          );
        }
        return _move(
          campaign,
          'voice-gallery',
          'In den dreizehn Rahmen altern die Eidträger, '
              'aber niemals gleichzeitig. Eldas Zeichnung, Tareks Brief '
              'und das namenlose Grab ergeben je eine andere Zeitfolge. '
              'Das vierzehnte Bild zeigt nur eine mögliche Zukunft, '
              'keinen feststehenden Tod. Hinter einem Rahmen '
              'hörst du das Umblättern eines Buches.',
          gained: {'voice:portraitCompared': 'true'},
        );
      }
      if (_has(text, 'bibliothek|hinterzimmer|buch|tür|tuer') &&
          !_negated(text)) {
        return _move(
          campaign,
          'voice-library',
          'Du trittst in die Bibliothek der ungelebten Tage. '
              'Ein Mann ohne Schatten stellt sich als Chronist vor. '
              '„Ich kann einen Verlust aus deiner Erinnerung nehmen“, '
              'sagt er. „Dafür muss eine andere Person aus den '
              'gemeinsamen Erinnerungen verschwinden.“ '
              'Du kannst ablehnen, Bedingungen verhandeln, '
              'Zustimmung vortäuschen oder ausdrücklich nach dem Preis fragen. '
              'Das vierzehnte Blatt liegt hinter ihm.',
          gained: {'voice:chronistMet': 'true'},
        );
      }
      if (_has(text, 'zurück|verlass|haus') && !_negated(text)) {
        return _move(
          campaign,
          'voice-house',
          'Du verlässt die Galerie und stehst wieder '
              'im Eingang des Hauses ohne Türen.',
        );
      }
      return RabenwachtTurn(
        campaign,
        'Dreizehn Porträts und dein vierzehntes Bild hängen '
        'vor dir. Du kannst sie vergleichen oder die '
        'Bibliothek hinter den Rahmen betreten.',
      );
    }

    if (stage == 'voice-library') {
      if (_has(text, 'blatt|archiv|eid|handschrift|suchen') &&
          !_negated(text)) {
        return _move(
          campaign,
          'voice-ledger',
          'Du folgst einer Spur loser Seiten in den '
              'Lesesaal. Auf einem Pult liegt ein Buch '
              'mit herausgetrennter vierzehnter Seite. '
              'Untersuche das Blatt, bevor du jemandem '
              'einen Namen anvertraust.',
        );
      }
      if (_has(text, 'preis|kost|opfer|handel annehmen|angebot annehmen') &&
          !_negated(text)) {
        if (campaign.facts['voice:chronistChoice'] != null) {
          return RabenwachtTurn(
            campaign,
            'Deine frühere Entscheidung bleibt bestehen. '
            'Der Chronist öffnet keinen zweiten Handel.',
          );
        }
        return _move(
          campaign,
          'voice-price',
          'Der Chronist zeigt zwei leere Seiten. '
              'Er würde deinen Verlust aus den Erinnerungen streichen. '
              'Im Gegenzug soll ein anderer Mensch von allen '
              'vergessen werden. Du kennst weder eine sichere '
              'Person noch eine folgenlose Rücknahme. '
              'Der Handel wird noch nicht ausgeführt. '
              'Um das Risiko bewusst anzunehmen, bestätige exakt: '
              '„Ich bestätige den Preis: Eine andere Person wird vergessen.“ '
              'Oder lehne den Handel ab.',
          gained: {'voice:priceExplained': 'true'},
        );
      }
      if (_has(text, 'verhandl|verhandel|bedingungen prüf|bedingungen pruef') &&
          !_negated(text)) {
        return _move(
          campaign,
          stage,
          'Du verlangst Beweise statt Versprechen. '
          'Der Chronist legt offen, dass er nur geteilte '
          'Erinnerungen verändert, nicht die Vergangenheit selbst. '
          'Du hast noch keinem Preis zugestimmt. '
          'Du kannst das vierzehnte Blatt suchen '
          'oder eine endgültige Antwort geben.',
          gained: {'voice:termsQuestioned': 'true'},
        );
      }
      if (_has(text, 'lehn|ablehn|verweig|kein angebot') && !_negated(text)) {
        return _decision(
          campaign,
          'refused',
          'Du schlägst den Handel aus. '
              'Liora atmet hörbar aus. Der Chronist legt '
              'eine leere Seite zwischen euch, doch er '
              'kann deine Weigerung nicht zurücknehmen. '
              'Das vierzehnte Blatt wartet im Lesesaal.',
        );
      }
      if (_has(text, 'täusch|taeusch|spiele zustimmung|zum schein annehm') &&
          !_negated(text)) {
        return _decision(
          campaign,
          'feigned',
          'Du spielst Einverständnis. Der Chronist '
              'lächelt, doch sein Federkiel stockt. '
              'Er glaubt dir nicht vollständig. '
              'Dieser Verdacht könnte später Folgen haben. '
              'Du kannst nun das vierzehnte Blatt suchen.',
          gained: {'voice:chronistSuspicious': 'true'},
        );
      }
      return RabenwachtTurn(
        campaign,
        'Der Chronist erwartet deine Antwort. '
        'Du darfst den Handel ablehnen, verhandeln, '
        'den Preis erfragen oder im Lesesaal '
        'nach dem vierzehnten Blatt suchen.',
      );
    }

    if (stage == 'voice-price') {
      if (text ==
              'ich bestätige den preis: eine andere person wird vergessen.' ||
          text ==
              'ich bestätige den preis: eine andere person wird vergessen') {
        return _decision(
          campaign,
          'accepted',
          'Du bestätigst den gefährlichen Preis. '
              'Der Chronist vermerkt deine Zustimmung, '
              'doch noch ist kein Mensch aus der Welt '
              'oder aus einem Spielstand gelöscht. '
              'Die Folgen dieses Versprechens stehen '
              'im Rat der Zeugen noch aus. '
              'Suche nun das vierzehnte Blatt.',
          gained: {'voice:chronistDebt': 'pending'},
        );
      }
      if (_has(
            text,
            'lehn|ablehn|abbruch|abbrechen|zurück|zurueck|verzichte',
          ) &&
          !_negated(text)) {
        return _move(
          campaign,
          'voice-library',
          'Du ziehst deine unbestätigte Zustimmung '
              'zurück. Niemand wurde geopfert. '
              'Der Chronist wartet schweigend.',
        );
      }
      return RabenwachtTurn(
        campaign,
        'Der Preis ist die kollektive Erinnerung '
        'an einen anderen Menschen. '
        'Ohne die ausdrücklich verlangte vollständige '
        'Bestätigung bleibt der Handel ungeschlossen. '
        'Du kannst jederzeit ablehnen.',
      );
    }

    if (stage == 'voice-ledger') {
      if (_has(text, 'untersuch|blatt|entziffer|lese|zeichen|schrift') &&
          !_negated(text)) {
        if (campaign.facts['voice:oathPageFound'] == 'true') {
          return RabenwachtTurn(
            campaign,
            'Du hast den beschädigten Eid bereits '
            'entziffert. Nun musst du entscheiden, '
            'wem du den unlesbaren Namen anvertraust.',
          );
        }
        return _move(
          campaign,
          stage,
          'Auf dem Blatt stehen dreizehn Namen, '
          'jeder von einem anderen Zeugen bestätigt. '
          'Die vierzehnte Stelle wurde ausradiert. '
          'Der Eid brach nicht, weil Zeit zurückgedreht '
          'wurde, sondern weil niemand mehr die '
          'Erinnerungen des anderen bezeugen konnte. '
          'Den fehlenden Namen kannst du noch nicht lesen.',
          gained: {'voice:oathPageFound': 'true'},
        );
      }
      if (_has(text, 'liora anvertrau|vertraue liora|liora den namen') &&
          !_negated(text)) {
        if (campaign.facts['voice:oathPageFound'] != 'true') {
          return RabenwachtTurn(
            campaign,
            'Bevor du Liora einen Namen anvertrauen kannst, '
            'musst du das vierzehnte Blatt untersuchen.',
          );
        }
        return _move(
          campaign,
          'voice-threshold',
          campaign.facts['voice:lioraChoice'] == 'accuse'
              ? 'Liora erinnert sich an deine Anschuldigung '
                    'und nimmt den Beleg nur zögernd an. '
                    'Dennoch verspricht sie, ihn vor dem Rat '
                    'der Zeugen auszusprechen. '
                    'Der Weg zu Akt VIII ist vorbereitet.'
              : 'Du vertraust Liora die Abschrift der '
                    'unlesbaren Stelle an. Sie entscheidet '
                    'selbst, vor dem Rat als Zeugin '
                    'aufzutreten. Der Weg zu Akt VIII '
                    'ist vorbereitet.',
          gained: {'voice:nameCustody': 'liora', 'voice:act7Reached': 'true'},
        );
      }
      if (_has(text, 'selbst bewahr|selbst verwahr|ich behalte den namen') &&
          !_negated(text)) {
        if (campaign.facts['voice:oathPageFound'] != 'true') {
          return RabenwachtTurn(
            campaign,
            'Ohne die untersuchte Seite gibt es '
            'keinen bestätigten Namen, den du bewahren könntest.',
          );
        }
        return _move(
          campaign,
          'voice-threshold',
          'Du verwahrst die beschädigte Abschrift '
              'selbst und versprichst, sie vor dem Rat '
              'der Zeugen offen zu prüfen. '
              'Der Weg zu Akt VIII ist vorbereitet.',
          gained: {'voice:nameCustody': 'hero', 'voice:act7Reached': 'true'},
        );
      }
      if (_has(text, 'zurück|chronist|bibliothek') && !_negated(text)) {
        return _move(
          campaign,
          'voice-library',
          'Du kehrst mit deinem gesicherten Wissen '
              'zum Chronisten zurück.',
        );
      }
      return RabenwachtTurn(
        campaign,
        'Untersuche das vierzehnte Blatt. '
        'Danach kannst du die Abschrift Liora '
        'anvertrauen oder selbst bewahren.',
      );
    }

    return RabenwachtTurn(
      campaign,
      'Das vierzehnte Blatt ist gesichert. '
      'Die Zusammenkunft der Zeugen und die Entscheidung '
      'über den Eid folgen in Akt VIII. '
      'Deine bisherigen Entscheidungen bleiben gespeichert.',
    );
  }
}
