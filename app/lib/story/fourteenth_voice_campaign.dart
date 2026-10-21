import '../domain/models.dart';
import 'fourteenth_voice_act7.dart';
import 'rabenwacht_campaign.dart' show RabenwachtTurn;
import 'story_rule_port.dart';

/// Act VI of "Die vierzehnte Stimme". All narration and branching belong to
/// story/, while character modifiers and rolls belong to StoryRulePort.
class FourteenthVoiceStoryModule {
  const FourteenthVoiceStoryModule(this.rules);

  final StoryRulePort rules;

  static const mode = 'rabenwacht-voice-v1';
  static const title = 'Rabenwacht – Die vierzehnte Stimme';

  static bool canStart(Campaign campaign) =>
      campaign.storyBible['mode'] == 'rabenwacht-v1' &&
      (campaign.storyBible['stage'] ?? '').startsWith('end-') &&
      (campaign.facts['ending'] ?? '').startsWith('end-') &&
      campaign.encounter == null &&
      campaign.pendingRoll == null;

  /// Explicit opt-in from a finished adventure. Keeps hero, NPCs, full
  /// conversation and old facts. Does not silently migrate historical saves.
  RabenwachtTurn start(Campaign previous) {
    if (!canStart(previous)) {
      return RabenwachtTurn(
        previous,
        'Die Fortsetzung beginnt erst nach einem abgeschlossenen '
        'Rabenwacht-Abenteuer ohne offenen Kampf oder Würfelwurf.',
      );
    }
    final oldEnding = previous.facts['ending']!;
    final endingContext = switch (oldEnding) {
      'end-seal' =>
        'Du hast das Siegel erneuert. '
            'Seine Risse beginnen nun die Stimmen durchzulassen.',
      'end-break' =>
        'Du hast das Siegel gebrochen. '
            'Etwas Fremdes gelangt jetzt leichter nach Rabenwacht.',
      'end-mercy' =>
        'Du hast Seren erlöst. '
            'Die Erinnerung an ihre letzten Worte ist noch lebendig.',
      'end-chorus' =>
        'Du hast den Glockenchor bewahrt. '
            'Seine Stimmen klingen zwischen neuen Erinnerungen nach.',
      _ => 'Die Glocke ist verstummt, doch das Dorf findet keine Ruhe.',
    };
    final opening =
        '${previous.hero.name}, am Morgen nach der '
        'Glockennacht trägt Elda vier Teller an einen Tisch für drei. '
        'Eine junge Frau im grauen Mantel steht in der Tür. '
        '„Du hast mich gestern gerettet“, behauptet sie. '
        'Manche nennen sie Liora, andere haben sie nie gesehen. '
        '$endingContext '
        'Du kannst Liora schützen, sie beschuldigen oder erst Belege '
        'suchen. Elda, Tarek und der Friedhof bieten unterschiedliche Spuren.';
    final next = previous.copyWith(
      name: title,
      scene: opening,
      storyBible: {
        ...previous.storyBible,
        'mode': mode,
        'stage': 'voice-square',
        'version': '1',
        'voicePreviousMode': 'rabenwacht-v1',
        'voicePreviousEnding': oldEnding,
      },
      facts: {
        ...previous.facts,
        'voice:started': 'true',
        'voice:originEnding': oldEnding,
        'voice:visited:square': 'true',
        'location': 'Dorfplatz von Rabenwacht',
      },
      quests: [
        ...previous.quests,
        const Quest(
          id: 'voice-main',
          title: 'Die vierzehnte Stimme',
          description:
              'Finde heraus, weshalb Rabenwacht '
              'sich an Menschen erinnert, die es nie gab.',
        ),
        const Quest(
          id: 'voice-witnesses',
          title: 'Widersprüchliche Zeugnisse',
          description:
              'Sichere mindestens zwei voneinander '
              'unabhängige Hinweise auf die verlorenen Namen.',
        ),
        const Quest(
          id: 'voice-liora',
          title: 'Wer ist Liora?',
          description: 'Entscheide, wie du der Fremden begegnest.',
        ),
      ],
      storyThreads: [
        ...previous.storyThreads,
        const StoryThread(
          id: 'voice-liora-origin',
          title: 'Lioras Herkunft',
          description: 'Warum widersprechen sich die Erinnerungen?',
        ),
        const StoryThread(
          id: 'voice-fourteenth-name',
          title: 'Die vierzehnte Stimme',
          description: 'Wessen Name fehlt im Glockeneid?',
        ),
      ],
      npcs: [
        ...previous.npcs,
        if (!previous.npcs.any((npc) => npc.id == 'liora'))
          const WorldNpc(
            id: 'liora',
            name: 'Liora',
            description: 'Junge Frau mit widersprüchlicher Vergangenheit.',
            relationship: 'unbekannt',
          ),
      ],
      places: [
        ...previous.places,
        if (!previous.places.any((place) => place.id == 'voice-house'))
          const Place(
            id: 'voice-house',
            name: 'Haus ohne Türen',
            description: 'Ein Haus jenseits des alten Friedhofs.',
          ),
      ],
    );
    return RabenwachtTurn(next, opening);
  }

  static bool _has(String input, String fragments) {
    final spoken = input.toLowerCase();
    return fragments.split('|').any(spoken.contains);
  }

  static int evidenceCount(Campaign campaign) => [
    'voice:memorySketch',
    'voice:splitInkLetter',
    'voice:namelessGrave',
  ].where((key) => campaign.facts[key] == 'true').length;

  String discoveredClues(Campaign campaign) {
    final clues = <String>[
      'In Rabenwacht widersprechen sich die Erinnerungen an Liora.',
      if (campaign.facts['voice:lioraChoice'] == 'protect')
        'Du hast Liora vor den Anschuldigungen des Dorfes geschützt.',
      if (campaign.facts['voice:lioraChoice'] == 'accuse')
        'Du hast Liora öffentlich zur Rede gestellt.',
      if (campaign.facts['voice:lioraChoice'] == 'evidence')
        'Du hast zugesagt, zuerst nach Belegen zu suchen.',
      if (campaign.facts['voice:memorySketch'] == 'true')
        'Eldas alte Kinderzeichnungen zeigen ein ausradiertes Gesicht.',
      if (campaign.facts['voice:splitInkLetter'] == 'true')
        'Tareks Brief enthält zwei unterschiedlich alte Tintenschichten.',
      if (campaign.facts['voice:namelessGrave'] == 'true')
        'Am Friedhof enden Lioras Spuren an einem Grab ohne Namen.',
      if (campaign.facts['voice:houseFound'] == 'true')
        'Das Haus ohne Türen ist jenseits des Friedhofs erschienen.',
      if (campaign.facts['voice:portraitSeen'] == 'true')
        'Ein vierzehntes Porträt zeigt eine mögliche Zukunft deines Helden.',
      if (campaign.facts['voice:portraitCompared'] == 'true')
        'Die Porträts widersprechen der gemeinsamen Erinnerung an die Zeit.',
      if (campaign.facts['voice:chronistMet'] == 'true')
        'Der Chronist behauptet, Erinnerungen verändern zu können.',
      if (campaign.facts['voice:termsQuestioned'] == 'true')
        'Der Chronist kann Erinnerungen verändern, nicht Vergangenes ungeschehen machen.',
      if (campaign.facts['voice:chronistChoice'] == 'refused')
        'Du hast das Angebot des Chronisten abgelehnt.',
      if (campaign.facts['voice:chronistChoice'] == 'feigned')
        'Du hast dem Chronisten nur scheinbar zugestimmt.',
      if (campaign.facts['voice:chronistChoice'] == 'accepted')
        'Du hast einen gefährlichen Preis zugesagt; die Folgen sind noch offen.',
      if (campaign.facts['voice:oathPageFound'] == 'true')
        'Das vierzehnte Eidblatt zeigt eine unterbrochene Kette gegenseitiger Zeugen.',
      if (campaign.facts['voice:nameCustody'] == 'liora')
        'Liora verwahrt die Abschrift für den Rat der Zeugen.',
      if (campaign.facts['voice:nameCustody'] == 'hero')
        'Du bewahrst die Abschrift für den Rat der Zeugen.',
    ];
    final remaining = campaign.quests
        .where((q) => q.id.startsWith('voice-') && q.status == 'active')
        .map((q) => '• ${q.title}')
        .join('\n');
    return '${campaign.hero.name}, dein Ermittlungsstand:\n'
        '${clues.map((clue) => '• $clue').join('\n')}\n\n'
        'Gesicherte unabhängige Hinweise: ${evidenceCount(campaign)} von 3.\n'
        'Offene Aufträge:\n${remaining.isEmpty ? 'Keine' : remaining}.';
  }

  RabenwachtTurn _move(
    Campaign campaign,
    String stage,
    String description, {
    Map<String, String> gained = const {},
  }) {
    final facts = {
      ...campaign.facts,
      ...gained,
      'voice:visited:${stage.replaceFirst('voice-', '')}': 'true',
    };
    final found = [
      'voice:memorySketch',
      'voice:splitInkLetter',
      'voice:namelessGrave',
    ].where((key) => facts[key] == 'true').length;
    final next = campaign.copyWith(
      scene: '${campaign.hero.name}, $description',
      storyBible: {...campaign.storyBible, 'stage': stage},
      facts: facts,
      npcs: [
        for (final npc in campaign.npcs)
          if (npc.id == 'liora' && facts['voice:lioraChoice'] == 'protect')
            npc.copyWith(relationship: 'vertrauensvoll')
          else if (npc.id == 'liora' && facts['voice:lioraChoice'] == 'accuse')
            npc.copyWith(relationship: 'misstrauisch')
          else
            npc,
      ],
      quests: [
        for (final quest in campaign.quests)
          if (quest.id == 'voice-witnesses' && found >= 2)
            quest.copyWith(status: 'completed')
          else if (quest.id == 'voice-liora' &&
              facts['voice:lioraChoice'] != null)
            quest.copyWith(status: 'completed')
          else
            quest,
      ],
    );
    return RabenwachtTurn(next, next.scene);
  }

  RabenwachtTurn _ask(
    Campaign campaign,
    String stage,
    String ability,
    String skill,
    int difficulty,
    String description,
    String rollId,
  ) {
    if (!campaign.hero.isComplete) {
      return RabenwachtTurn(
        campaign,
        'Für diese Probe benötigt dein Held einen vollständigen '
        'bestätigten Charakterbogen.',
      );
    }
    final check = rules.abilityCheck(
      campaign.hero,
      ability,
      proficient: campaign.hero.skills.contains(skill),
      stealth: skill == 'Heimlichkeit',
      skill: skill,
    );
    return RabenwachtTurn(
      campaign.copyWith(
        pendingRoll: PendingRoll(
          id: rollId,
          type: 'preparedCheck',
          targetId: 'voice:$stage',
          targetName: '$ability|$skill',
          modifier: check.modifier,
          difficulty: difficulty,
          minimumNatural: check.minimumNatural,
          advantage: check.advantage,
          disadvantage: check.disadvantage,
        ),
      ),
      '$description W20-Probe auf $skill (SG $difficulty, '
      'Bonus ${check.modifier >= 0 ? '+' : ''}${check.modifier}). '
      'Würfle oder gib deinen natürlichen W20 ein.',
    );
  }

  RabenwachtTurn advance(
    Campaign campaign,
    String input, {
    required String rollId,
  }) {
    if (campaign.storyBible['mode'] != mode) {
      throw const FormatException('Unbekannter Fortsetzungsmodus.');
    }
    final stage = campaign.storyBible['stage'] ?? 'voice-square';
    final spoken = input.toLowerCase();
    if (_has(spoken, 'hinweise|ermittlungsstand|spurenliste|tagebuch')) {
      return RabenwachtTurn(campaign, discoveredClues(campaign));
    }
    if (RegExp(r'\b(?:wirke|zaubere|caste)\b').hasMatch(spoken)) {
      return RabenwachtTurn(
        campaign,
        'Ein Zauber kann nur durch eine geprüfte Regelaktion mit '
        'bestätigten Komponenten und Ressourcen gewirkt werden. '
        'Diese Geschichte erfindet keine Zauberwirkungen.',
      );
    }
    if (campaign.pendingRoll != null) {
      return RabenwachtTurn(
        campaign,
        'Zuerst den offenen Würfelwurf abschließen.',
      );
    }
    if (FourteenthVoiceAct7.handles(stage)) {
      return FourteenthVoiceAct7.advance(campaign, input);
    }
    if (stage == 'voice-house') {
      if (_has(spoken, 'porträt|portrait|bilder|galerie|betret|untersuch')) {
        return _move(
          campaign,
          'voice-gallery',
          'Du betrittst das Haus ohne Türen. Dreizehn '
              'Porträts hängen an einer Wand ohne Fenster. '
              'Im vierzehnten Rahmen erkennst du dich selbst, '
              'älter und mit einer silbernen Glocke in der Hand. '
              'Ist dies Zukunft, Lüge oder Erinnerung?',
          gained: {'voice:portraitSeen': 'true'},
        );
      }
      return RabenwachtTurn(
        campaign,
        'Das Haus steht vor dir. Du kannst die Galerie '
        'und die Porträts untersuchen.',
      );
    }

    // The three clues are non-linear. Players can return to any witness
    // without forfeiting already verified evidence.
    final goingBack =
        _has(spoken, 'zurück|zurueck|dorfplatz|zur mitte|platz zurück') &&
        (stage != 'voice-square');
    if (goingBack) {
      return _move(
        campaign,
        'voice-square',
        'Auf dem Dorfplatz suchen Elda, Tarek und Liora '
            'noch nach Antworten. Du kannst die anderen '
            'Spuren verfolgen oder deine Hinweise prüfen.',
        gained: {'location': 'Dorfplatz von Rabenwacht'},
      );
    }
    if (stage == 'voice-square') {
      if (_has(spoken, 'schütze|schuetze|verteidig|beschütz|beschuetz') &&
          _has(spoken, 'liora|frau|fremde')) {
        return _move(
          campaign,
          stage,
          'Du trittst vor Liora. Die Menge weicht zurück, '
          'aber Tarek bleibt misstrauisch. Liora flüstert: '
          '„Danke. Ich zeige dir das namenlose Grab.“ '
          'Du kannst nun den Friedhof aufsuchen.',
          gained: {'voice:lioraChoice': 'protect'},
        );
      }
      if (_has(spoken, 'beschuldig|anklag|verdächtig|verdaechtig') &&
          _has(spoken, 'liora|frau|fremde')) {
        return _move(
          campaign,
          stage,
          'Du forderst Liora öffentlich zur Wahrheit auf. '
          'Sie schaut verletzt zu Boden. Einige '
          'Dorfbewohner nicken dir zu. '
          'Die Spuren stehen dir trotzdem offen.',
          gained: {'voice:lioraChoice': 'accuse'},
        );
      }
      if (_has(spoken, 'erst belege|zuerst belege|beweise suchen|ermitteln')) {
        return _move(
          campaign,
          stage,
          'Du versprichst, niemanden ohne Beweise zu verurteilen. '
          'Elda bittet dich in ihr Haus; Tarek zeigt '
          'auf einen seltsamen Brief.',
          gained: {'voice:lioraChoice': 'evidence'},
        );
      }
      if (_has(
        spoken,
        'haus ohne türen|haus ohne tueren|zum haus|geheimhaus',
      )) {
        if (evidenceCount(campaign) < 2) {
          return RabenwachtTurn(
            campaign,
            'Der Nebel gibt kein Haus preis. '
            'Du brauchst mindestens zwei unabhängige '
            'Spuren von Elda, Tarek oder dem Friedhof.',
          );
        }
        return _move(
          campaign,
          'voice-house',
          'Zwei voneinander unabhängige Erinnerungen '
              'weisen denselben Ort aus. Hinter dem Friedhof '
              'steht ein Haus, das gestern noch nicht da war. '
              'Kein Türgriff, keine Fuge. Als du näherkommst, '
              'steht der Eingang plötzlich offen.',
          gained: {'voice:houseFound': 'true', 'location': 'Haus ohne Türen'},
        );
      }
      if (_has(spoken, 'elda|teller|zeichnung|kindheit')) {
        return _move(
          campaign,
          'voice-elda',
          'Elda sitzt vor vier Frühstückstellern. '
              'Auf ihrem Regal liegen vergilbte Kinderzeichnungen. '
              'Du kannst sie untersuchen oder Elda befragen.',
          gained: {'location': 'Eldas Haus'},
        );
      }
      if (_has(spoken, 'tarek|brief|tinte|gasthaus')) {
        return _move(
          campaign,
          'voice-tarek',
          campaign.facts['tarekTrust'] == 'true'
              ? 'Tarek erkennt dich und legt seinen Brief '
                    'offen auf den Tisch. „Du hast mir damals '
                    'vertraut. Jetzt brauche ich deine Hilfe.“ '
                    'Untersuche die Schrift und Tinte.'
              : 'Tarek hält einen Brief mit seiner Unterschrift '
                    'fest. „Ich schrieb das nicht.“ '
                    'Er lässt dich den Umschlag untersuchen, '
                    'wenn du ihn vorsichtig behandelst.',
          gained: {'location': 'Gasthaus Zum Letzten Licht'},
        );
      }
      if (_has(spoken, 'liora|friedhof|grab|fußspur|fussspur')) {
        return _move(
          campaign,
          'voice-grave',
          'Liora führt dich zum alten Friedhof. '
              'Ihre Fußspuren verschwinden an einem '
              'namenlosen Grab. Du kannst den Boden '
              'und die Grabeinfassung untersuchen.',
          gained: {'location': 'Friedhof von Rabenwacht'},
        );
      }
      return RabenwachtTurn(
        campaign,
        'Elda erinnert sich an einen vierten Teller. '
        'Tarek zeigt einen unmöglichen Brief. Liora '
        'will zum Friedhof. Welche Spur verfolgst du?',
      );
    }
    if (stage == 'voice-elda') {
      if (_has(spoken, 'untersuch|zeichnung|bild|radier|such|betracht')) {
        return _ask(
          campaign,
          'elda',
          'wisdom',
          'Wahrnehmung',
          12,
          'Du untersuchst die Zeichnungen auf ältere Linien '
              'und die Spuren eines ausradierten Gesichts.',
          rollId,
        );
      }
      return RabenwachtTurn(
        campaign,
        'Elda hält den vierten Teller fest. '
        'Untersuche die Kinderzeichnungen oder '
        'kehre auf den Dorfplatz zurück.',
      );
    }
    if (stage == 'voice-tarek') {
      if (_has(spoken, 'untersuch|brief|tinte|schrift|vergleich|les')) {
        return _ask(
          campaign,
          'tarek',
          'intelligence',
          'Nachforschungen',
          13,
          'Du vergleichst die beiden Tintenschichten '
              'und den Verlauf von Tareks Unterschrift.',
          rollId,
        );
      }
      return RabenwachtTurn(
        campaign,
        'Tarek lässt den Brief auf dem Tisch liegen. '
        'Du kannst Schrift und Tinte prüfen oder '
        'zum Dorfplatz zurückgehen.',
      );
    }
    if (stage == 'voice-grave') {
      if (_has(spoken, 'untersuch|spur|grab|stein|boden|such|betracht')) {
        return _ask(
          campaign,
          'grave',
          'wisdom',
          'Wahrnehmung',
          12,
          'Du folgst Lioras Fußabdrücken durch '
              'die feuchte Erde am namenlosen Grab.',
          rollId,
        );
      }
      return RabenwachtTurn(
        campaign,
        'Am namenlosen Grab verschwindet eine Spur im Nichts. '
        'Du kannst Boden und Grab untersuchen oder zurückgehen.',
      );
    }
    throw const FormatException('Unbekannte Szene der vierzehnten Stimme.');
  }

  RabenwachtTurn resolveCheck(
    Campaign campaign,
    PendingRoll pending,
    bool passed,
  ) {
    if (campaign.storyBible['mode'] != mode ||
        pending.type != 'preparedCheck' ||
        !pending.targetId.startsWith('voice:')) {
      throw const FormatException('Falsche Fortsetzungsprobe.');
    }
    final step = pending.targetId.substring('voice:'.length);
    switch (step) {
      case 'elda':
        if (passed) {
          return _move(
            campaign,
            'voice-square',
            'Unter dem Papier findest du ältere Linien: '
                'Das vierte Gesicht wurde sorgfältig '
                'ausradiert. Elda bestätigt, die Zeichnung '
                'selbst aufgehoben zu haben. '
                'Du kehrst mit einem Zeugnis zum Dorfplatz zurück.',
            gained: {
              'voice:memorySketch': 'true',
              'location': 'Dorfplatz von Rabenwacht',
            },
          );
        }
        return _move(
          campaign,
          'voice-square',
          'Die alten Linien sind zu schwach. '
              'Elda bittet dich, zunächst andere Zeugen '
              'zu befragen. Du kehrst zum Dorfplatz zurück.',
          gained: {'location': 'Dorfplatz von Rabenwacht'},
        );
      case 'tarek':
        if (passed) {
          return _move(
            campaign,
            'voice-square',
            'Du erkennst zwei Tintenschichten aus '
                'unterschiedlichen Jahren. Tarek kann '
                'nicht erklären, wie seine Unterschrift '
                'auf beide gelangte. Du nimmst die '
                'beglaubigte Abschrift zum Dorfplatz mit.',
            gained: {
              'voice:splitInkLetter': 'true',
              'location': 'Dorfplatz von Rabenwacht',
            },
          );
        }
        return _move(
          campaign,
          'voice-square',
          'Die Schrift lässt sich nicht sicher datieren. '
              'Tarek behält den Brief, aber verweist '
              'dich auf Elda und den Friedhof.',
          gained: {'location': 'Dorfplatz von Rabenwacht'},
        );
      case 'grave':
        if (passed) {
          return _move(
            campaign,
            'voice-square',
            'Die Abdrücke gehören tatsächlich zu '
                'Lioras Stiefeln, enden aber an einem '
                'Grab, dessen Namensplatte erst '
                'kürzlich abgeschliffen wurde. '
                'Du sicherst die Spur und kehrst zurück.',
            gained: {
              'voice:namelessGrave': 'true',
              'location': 'Dorfplatz von Rabenwacht',
            },
          );
        }
        return _move(
          campaign,
          'voice-square',
          'Der Regen verwischt die Fußspuren. '
              'Liora nennt dir Elda und Tarek als '
              'weitere Zeugen. Du kehrst zum Platz zurück.',
          gained: {'location': 'Dorfplatz von Rabenwacht'},
        );
      default:
        throw const FormatException('Unbekannte Probe in Akt VI.');
    }
  }
}
