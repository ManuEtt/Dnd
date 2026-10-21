import 'character_rule_engine.dart';
import 'campaign_experience.dart';
import 'models.dart';

/// Handgeschriebene Offline-Solo-Kampagne. Keine KI-Entscheidung, kein
/// vorgefertigter Charakter und keine automatischen Belohnungswürfe.
class RabenwachtTurn {
  const RabenwachtTurn(this.campaign, this.narration, {this.battle = false});
  final Campaign campaign;
  final String narration;
  final bool battle;
}

class RabenwachtCampaign {
  const RabenwachtCampaign._();

  static const title = 'Das Flüstern der vergessenen Glocke';
  static const mode = 'rabenwacht-v1';

  static Campaign create({
    required HeroCharacter hero,
    required String campaignId,
    required String sessionId,
    required String messageId,
    required DateTime now,
  }) {
    final validated = HeroCharacter.fromJson(hero.toJson());
    final opening =
        '${validated.name}, kalter Herbstregen schlägt dir ins Gesicht, als du '
        'das Dorf Rabenwacht erreichst. Der geborstene Glockenturm ragt wie '
        'ein schwarzer Zahn über die Dächer. Eine Frau im grauen Mantel '
        'bleibt vor dir stehen. „Nein … nicht schon wieder“, haucht sie und '
        'starrt hinter dich. Im Nebel nähern sich Schritte, doch du siehst '
        'niemanden. Untersuche die Schritte, sprich mit der Frau oder gehe '
        'zum Dorfplatz. Was tust du?';
    final result = Campaign(
      id: campaignId,
      name: title,
      world: 'Valdorn',
      sessionId: sessionId,
      hero: validated,
      scene: opening,
      messages: [
        NarrativeMessage(
          id: messageId,
          role: 'gm',
          text: opening,
          timestamp: now,
        ),
      ],
      storyBible: const {
        'mode': mode,
        'stage': 'road',
        'version': '1',
        'targetDuration': '120-180 Minuten',
      },
      facts: const {
        'origin': 'rabenwacht',
        'visited:road': 'true',
        'location': 'Straße nach Rabenwacht',
        'bells': 'Seit sieben Nächten läutet der zerstörte Glockenturm.',
      },
      quests: const [
        Quest(
          id: 'rabenwacht-main',
          title: 'Das Geheimnis der vierzehnten Glocke',
          description:
              'Finde die Vermissten und entscheide über das Schicksal des Glockensiegels.',
        ),
        Quest(
          id: 'rabenwacht-missing',
          title: 'Die Verschwundenen',
          description:
              'Ermittle, wo sich die drei verschwundenen Dorfbewohner befinden.',
        ),
        Quest(
          id: 'rabenwacht-key',
          title: 'Die dreizehnte Tür',
          description:
              'Entschlüssele die Warnung des sterbenden Boten und finde das Siegel.',
        ),
      ],
      storyThreads: const [
        StoryThread(
          id: 'bells',
          title: 'Die vierzehn Schläge',
          description: 'Der Turm steht seit 41 Jahren nicht mehr.',
        ),
        StoryThread(
          id: 'missing',
          title: 'Vermisste Bewohner',
          description: 'Holzfäller, Müllerstochter und Dorfwächter.',
        ),
        StoryThread(
          id: 'stranger',
          title: 'Der silberne Schlüssel',
          description: 'Ein Bote warnte vor der dreizehnten Tür.',
        ),
      ],
      npcs: const [
        WorldNpc(
          id: 'elda',
          name: 'Elda Weißdorn',
          description: 'Ängstliche Dorfhebamme in grauem Mantel.',
          relationship: 'vorsichtig',
        ),
        WorldNpc(
          id: 'tarek',
          name: 'Tarek Dorn',
          description: 'Wirt zum Letzten Licht und ehemaliger Kundschafter.',
          relationship: 'neutral',
        ),
        WorldNpc(
          id: 'mara',
          name: 'Mara Voss',
          description: 'Dorfvorsteherin, verbirgt ein familiäres Versprechen.',
          relationship: 'misstrauisch',
        ),
        WorldNpc(
          id: 'oswin',
          name: 'Bruder Oswin',
          description: 'Gealterter Hüter der Kapelle, kennt die Brandnacht.',
          relationship: 'neutral',
        ),
        WorldNpc(
          id: 'fina',
          name: 'Fina Kessel',
          description: 'Müllerstochter, unter der Erde gefangen.',
          relationship: 'vermisst',
        ),
        WorldNpc(
          id: 'joren',
          name: 'Joren Kessel',
          description: 'Müller, sucht verzweifelt seine Tochter.',
          relationship: 'besorgt',
        ),
        WorldNpc(
          id: 'bram',
          name: 'Bram Eisfeld',
          description: 'Verschwundener Dorfwächter, lebt möglicherweise.',
          relationship: 'vermisst',
        ),
        WorldNpc(
          id: 'alrik',
          name: 'Alrik Nebel',
          description: 'Chronist mit ungewöhnlich guten Kenntnissen der Ruine.',
          relationship: 'verschlossen',
        ),
        WorldNpc(
          id: 'seren',
          name: 'Seren vom Glockenorden',
          description:
              'Im alten Ritual gebundener Geist; weder eindeutig gut noch böse.',
          relationship: 'unbekannt',
        ),
      ],
      places: const [
        Place(
          id: 'road',
          name: 'Nebelstraße',
          description: 'Nasse Handelsstraße im Westen Rabenwachts.',
        ),
        Place(
          id: 'square',
          name: 'Dorfplatz',
          description:
              'Brunnen, ausgebrannte Steine und eine verschlossene Wachstube.',
        ),
        Place(
          id: 'inn',
          name: 'Zum Letzten Licht',
          description: 'Warme Schankstube, in der jeder ein Geheimnis hütet.',
        ),
        Place(
          id: 'mill',
          name: 'Alte Mühle',
          description: 'Stillgelegtes Mühlrad neben einem schwarzen Bach.',
        ),
        Place(
          id: 'chapel',
          name: 'Kapelle des Morgensterns',
          description: 'Verlassene Altäre, verblasste Gebetsbücher.',
        ),
        Place(
          id: 'archive',
          name: 'Chronistenhaus',
          description: 'Archiv der Gemeinde mit Berichten über die Brandnacht.',
        ),
        Place(
          id: 'grave',
          name: 'Friedhof der Namenlosen',
          description: 'Moosige Steine und ein Pfad durch alte Eiben.',
        ),
        Place(
          id: 'forest',
          name: 'Rabenschlucht',
          description: 'Ein schmaler Waldpfad führt zu den Turmruinen.',
        ),
        Place(
          id: 'ruins',
          name: 'Geborstener Turm',
          description: 'Ausgebrannte Ruine über einer verborgenen Krypta.',
        ),
        Place(
          id: 'crypt',
          name: 'Unterstadt',
          description: 'Steintreppen, Erinnerungsreliefs und alte Wächter.',
        ),
      ],
    );
    return Campaign.fromJson(result.toJson());
  }

  /// Show only information the hero has actually discovered. No secret,
  /// future scene or hidden NPC motivation is exposed by the journal.
  static String discoveredClues(Campaign campaign) {
    final known = <String>[
      'Seit sieben Nächten läutet der vor 41 Jahren zerstörte Glockenturm.',
      if (campaign.facts['blackHandClue'] == 'true')
        'Die unsichtbaren Schritte endeten an einem schwarzen Handabdruck.',
      if (campaign.facts['wellClue'] == 'true')
        'Im Dorfbrunnen spiegelt sich eine vierzehnte Tür, die oberirdisch fehlt.',
      if (campaign.facts['maraMet'] == 'true')
        'Mara Voss bestätigte: Drei Dorfbewohner verschwanden am schwarzen Bach.',
      if (campaign.facts['maraTrust'] == 'true')
        'Mara vertraute dir den Glockeneid und Alriks versiegelte Akten an.',
      if (campaign.facts['maraDefied'] == 'true')
        'Nach eurem Streit hält Mara die Ratsakten zurück.',
      if (campaign.facts['tarekTrust'] == 'true')
        'Tarek markierte Mühle, Kapelle und Chronistenhaus auf einer Karte.',
      if (campaign.facts['finaNote'] == 'true')
        'Finas Nachricht am Mühlrad verweist auf das Gebetbuch der Kapelle.',
      if (campaign.facts['jorenMet'] == 'true')
        'Joren sucht seine Tochter Fina; sie notierte Namen in einem Gebetbuch.',
      if (campaign.facts['prayerFound'] == 'true')
        'Das Gebetbuch verbindet dreizehn Türen mit der vierzehnten Glocke.',
      if (campaign.facts['oswinTruth'] == 'true')
        'Bruder Oswin sagt: Der Glockenturm wurde absichtlich zerstört.',
      if (campaign.facts['serenMotive'] == 'true')
        'Die Archivakten deuten darauf hin, dass Seren Menschen beschützen wollte.',
      if (campaign.facts['graveClue'] == 'true')
        'Am Friedhof steht: Der Schlüssel trennt ein Versprechen.',
      if (campaign.facts['memorialSeen'] == 'true')
        'Am Gedenkstein bitten Stimmen, die verschwiegenen Namen nicht zu vergessen.',
      if (campaign.facts['graveOath'] == 'remembered')
        'Du hast die Namen der Opfer am Gedenkstein bewahrt.',
      if (campaign.facts['graveOath'] == 'hidden')
        'Du hast die Namen am Gedenkstein bewusst verschwiegen.',
      if (campaign.facts['runeClue'] == 'true')
        'Die Turmrunen binden das Ritual an den Willen und an Erinnerungen.',
      if (campaign.facts['silverKeyFound'] == 'true')
        'Der silberne Schlüssel liegt bei dir; er gehört zur dreizehnten Tür.',
      if (campaign.facts['finaHeard'] == 'true')
        'Fina sagte, dass Seren die Gefangenen vor der Glocke schützt.',
      if (campaign.facts['ritualSolution'] == 'true')
        'Die Runen zeigen einen Weg, das Siegel ohne neue Opfer zu erneuern.',
      if (campaign.facts['ritualKnown'] == 'true')
        'Die Gefangenen werden unfreiwillig vom Erinnerungsritual aufgezehrt.',
      if (campaign.facts['allMissingFound'] == 'true')
        'Alle drei vermissten Menschen wurden befreit.',
    ];
    final objectives = campaign.quests
        .where((quest) => quest.status == 'active')
        .map((quest) => '• ${quest.title}')
        .join('\n');
    return '${campaign.hero.name}, dies hast du bisher selbst herausgefunden:\n'
        '${known.map((clue) => '• $clue').join('\n')}\n\n'
        'Offene Aufträge:\n'
        '${objectives.isEmpty ? 'Keine – die Geschichte ist abgeschlossen.' : objectives}\n'
        'Dein aktueller Ort: ${campaign.facts['location'] ?? 'unbekannt'}.';
  }

  static bool _has(String input, String words) {
    final text = input.toLowerCase();
    return words.split('|').any((part) => text.contains(part));
  }

  /// Negated commands such as "nicht angreifen" must not start combat.
  static bool _wantsFight(String input) {
    final text = input.toLowerCase();
    final verbs = RegExp(
      r'\b(?:angreif\w*|attackier\w*|greif\w*|kämpf\w*|kaempf\w*|'
      r'schlag\w*|töt\w*|schieß\w*|schiess\w*)',
    );
    for (final match in verbs.allMatches(text)) {
      final before = text.substring(0, match.start);
      final after = text.substring(match.end);
      // "greifen nach" is grasping, not an attack. Only "greifen ... an"
      // counts here; explicit "angreifen" remains independently supported.
      if (match.group(0)!.startsWith('greif') &&
          !RegExp(r'^\s+(?:\S+\s+){0,5}an\b').hasMatch(after)) {
        continue;
      }
      final refusalBefore = RegExp(
        r'\b(?:nicht|kein|keine|keinen|ohne|niemals)\b'
        r'(?:\s+\S+){0,4}\s*$',
      ).hasMatch(before);
      final refusalAfter = RegExp(
        r'^\s+(?:\S+\s+){0,4}nicht\b',
      ).hasMatch(after);
      if (!refusalBefore && !refusalAfter) return true;
    }
    return false;
  }

  /// Travel to discovered locations; visit markers survive saving/loading.
  static RabenwachtTurn? _revisit(Campaign c, String input, String stage) {
    if (!_has(input, 'geh|reise|kehr|zurück|zurueck|lauf|besuch')) {
      return null;
    }
    const names = <String, String>{
      'square': 'dorfplatz|platz',
      'watchhouse': 'ratsstube|vorsteherin',
      'inn': 'gasthaus|schankstube|taverne|wirtshaus',
      'mill': 'mühle|muehle',
      'chapel': 'kapelle',
      'archive': 'chronistenhaus|archiv',
      'graveyard': 'friedhof',
      'forest': 'rabenschlucht|waldpfad',
      'ruins': 'turmruine|turm',
    };
    const locations = <String, String>{
      'square': 'Dorfplatz',
      'watchhouse': 'Ratsstube',
      'inn': 'Gasthaus',
      'mill': 'Alte Mühle',
      'chapel': 'Kapelle',
      'archive': 'Chronistenhaus',
      'graveyard': 'Friedhof',
      'forest': 'Rabenschlucht',
      'ruins': 'Turmruine',
    };
    final spoken = input.toLowerCase();
    String? target;
    var lastMention = -1;
    for (final entry in names.entries) {
      for (final word in entry.value.split('|')) {
        final at = spoken.lastIndexOf(word);
        if (at > lastMention) {
          target = entry.key;
          lastMention = at;
        }
      }
    }
    if (target == null || target == stage) return null;
    final alreadyKnown = c.facts['visited:$target'] == 'true';
    final maraRoute =
        c.facts['maraLetter'] == 'true' &&
        (target == 'mill' || target == 'chapel');
    if (!alreadyKnown && !maraRoute) return null;
    final label = locations[target]!;
    return _move(
      c,
      target,
      'Du kehrst an den bekannten Ort $label zurück. '
      'Deine bisherigen Erkenntnisse bleiben erhalten. '
      'Du kannst dort weiteren Spuren nachgehen.',
      clues: {'location': label},
    );
  }

  static RabenwachtTurn _move(
    Campaign c,
    String stage,
    String scene, {
    Map<String, String> clues = const {},
    bool battle = false,
  }) {
    final narration = '${c.hero.name}, $scene';
    final facts = {...c.facts, ...clues, 'visited:$stage': 'true'};
    final located =
        stage == 'chamber' ||
        stage == 'choice' ||
        stage.startsWith('end-') ||
        facts['missingLocated'] == 'true';
    final keyUsed = located && facts['silverKeyFound'] == 'true';
    final rescued = facts['allMissingFound'] == 'true';
    final next = c.copyWith(
      scene: narration,
      storyBible: {...c.storyBible, 'stage': stage},
      facts: {...facts, if (located) 'missingLocated': 'true'},
      quests: [
        for (final quest in c.quests)
          if (quest.id == 'rabenwacht-missing' && located)
            quest.copyWith(status: 'completed')
          else if (quest.id == 'rabenwacht-key' && keyUsed)
            quest.copyWith(status: 'completed')
          else if (quest.id == 'rabenwacht-well' &&
              facts['wellClue'] == 'true' &&
              stage == 'square')
            quest.copyWith(status: 'completed')
          else
            quest,
      ],
      storyThreads: [
        for (final thread in c.storyThreads)
          if (thread.id == 'missing' && rescued)
            thread.copyWith(status: 'resolved')
          else if (thread.id == 'stranger' && keyUsed)
            thread.copyWith(status: 'resolved')
          else if (thread.id == 'bells' && stage.startsWith('end-'))
            thread.copyWith(status: 'resolved')
          else
            thread,
      ],
      npcs: [
        for (final npc in c.npcs)
          if (npc.id == 'elda' && facts['eldaHelped'] == 'true')
            npc.copyWith(relationship: 'freundlich')
          else if (npc.id == 'mara' && facts['maraTrust'] == 'true')
            npc.copyWith(relationship: 'verbündet')
          else if (npc.id == 'mara' && facts['maraDefied'] == 'true')
            npc.copyWith(relationship: 'feindselig')
          else if (npc.id == 'tarek' && facts['tarekTrust'] == 'true')
            npc.copyWith(relationship: 'freundlich')
          else if (npc.id == 'joren' && facts['jorenMet'] == 'true')
            npc.copyWith(relationship: 'dankbar')
          else if (npc.id == 'oswin' && facts['oswinTruth'] == 'true')
            npc.copyWith(relationship: 'vertrauensvoll')
          else if ((npc.id == 'fina' || npc.id == 'bram') && rescued)
            npc.copyWith(relationship: 'gerettet')
          else
            npc,
      ],
    );
    // Etappen werden nur beim ersten Erreichen belohnt. Die Höhe ist
    // Spielleiter-Design; der erforderliche EP-Stand für Stufen ist SRD 5.2.1.
    final milestone = switch (stage) {
      'square' when facts['wellClue'] == 'true' => 'well-discovery',
      'mill' => 'reach-mill',
      'chapel' => 'reach-chapel',
      'archive' => 'reach-archive',
      'graveyard' => 'reach-graveyard',
      'ruins' => 'reach-ruins',
      'chamber' => 'reach-chamber',
      'end-seal' || 'end-break' || 'end-mercy' => 'resolve-rabenwacht',
      _ => null,
    };
    final reward = milestone == null
        ? ExperienceAward(next, 0, '')
        : CampaignExperience.awardOnce(next, milestone);
    final description = reward.narration.isEmpty
        ? narration
        : '$narration\n\n${reward.narration}';
    return RabenwachtTurn(reward.campaign, description, battle: battle);
  }

  static RabenwachtTurn _ask(
    Campaign c,
    String input,
    String stage,
    String ability,
    String skill,
    int difficulty,
    String description,
    String rollId,
  ) {
    if (!c.hero.isComplete) {
      return RabenwachtTurn(
        c,
        'Vor dieser Probe benötigt dein Held einen vollständigen Charakterbogen '
        'mit bestätigten Attributen, Fertigkeiten und Trefferpunkten.',
      );
    }
    final check = CharacterRuleEngine.abilityCheck(
      c.hero,
      ability,
      proficient: c.hero.skills.contains(skill),
      stealth: skill == 'Heimlichkeit',
      skill: skill,
    );
    return RabenwachtTurn(
      c.copyWith(
        pendingRoll: PendingRoll(
          id: rollId,
          type: 'preparedCheck',
          targetId: 'rabenwacht:$stage',
          targetName: '$ability|$skill',
          difficulty: difficulty,
          modifier: check.modifier,
          minimumNatural: check.minimumNatural,
          advantage: check.advantage,
          disadvantage: check.disadvantage,
        ),
      ),
      '$description W20-Probe auf $skill (SG $difficulty, '
      'Bonus ${check.modifier >= 0 ? '+' : ''}${check.modifier}). '
      'Würfle jetzt automatisch oder gib deinen natürlichen W20 ein.'
      '${check.minimumNatural == 10 ? ' Verlässliches Talent: Würfelwerte unter 10 gelten als 10.' : ''}',
    );
  }

  static RabenwachtTurn advance(
    Campaign c,
    String input, {
    required String rollId,
  }) {
    final stage = c.storyBible['stage'] ?? 'road';
    if (stage.startsWith('end-')) {
      return RabenwachtTurn(
        c,
        'Die Chronik von Rabenwacht ist abgeschlossen. Dein gewähltes Ende '
        'bleibt gespeichert. Für ein anderes Ende starte eine neue Kampagne.',
      );
    }
    if (_has(input, 'hinweise|hinweisprotokoll|ermittlungsstand|spurenliste')) {
      return RabenwachtTurn(c, discoveredClues(c));
    }
    final revisit = _revisit(c, input, stage);
    if (revisit != null) return revisit;
    switch (stage) {
      case 'road':
        if (_has(input, 'schritt|nebel|spur|wahrnehm|untersuch|lauschen')) {
          return _ask(
            c,
            input,
            'road',
            'wisdom',
            'Wahrnehmung',
            12,
            'Du horchst auf die Schritte im Nebel.',
            rollId,
          );
        }
        if (_has(input, 'frau|elda|sprech|frag|helfe')) {
          return _move(
            c,
            'square',
            'Elda Weißdorn hält deinen Ärmel fest. „Er folgt jedem, '
                'der die Glocke gehört hat. Frag Tarek im Letzten Licht.“ '
                'Sie führt dich zum Dorfplatz. Dort stehen die Schankstube '
                'und das Haus der Vorsteherin offen. Wen suchst du zuerst?',
            clues: {'eldaHelped': 'true', 'location': 'Dorfplatz'},
          );
        }
        if (_has(input, 'platz|dorf|weiter|geh')) {
          return _move(
            c,
            'square',
            'Auf dem Dorfplatz liegt eine einzelne schwarze Feder im Brunnen. '
                'Ein beleuchtetes Wirtshausschild knarrt, während vor der '
                'Ratsstube zwei Wachen flüstern. Gehst du zur Schankstube '
                'oder befragst du die Vorsteherin?',
            clues: {'location': 'Dorfplatz'},
          );
        }
        return RabenwachtTurn(
          c,
          'Der Nebel schluckt jedes Geräusch. '
          'Du kannst mit Elda sprechen, die Schritte untersuchen oder '
          'zum Dorfplatz gehen. Was tust du?',
        );
      case 'square':
        if (_has(input, 'brunnen|feder|wasser|schacht')) {
          final visit = _move(
            c,
            'well',
            'Das schwarze Wasser im Dorfbrunnen zittert im Takt eines '
                'Glockenschlags. Zwischen den Fugen scheint eine weitere '
                'Tür gespiegelt, doch die Wasseroberfläche ist unruhig. '
                'Untersuchst du das Spiegelbild genauer oder kehrst du '
                'zum Dorfplatz zurück?',
            clues: {'location': 'Dorfbrunnen'},
          );
          return RabenwachtTurn(
            visit.campaign.copyWith(
              quests: [
                ...visit.campaign.quests,
                if (!visit.campaign.quests.any(
                  (quest) => quest.id == 'rabenwacht-well',
                ))
                  const Quest(
                    id: 'rabenwacht-well',
                    title: 'Das Spiegelbild im Brunnen',
                    description: 'Untersuche die rätselhafte Spiegelung.',
                  ),
              ],
            ),
            visit.narration,
          );
        }
        if (_has(input, 'tarek|wirt|schank|taverne|gasthaus|licht')) {
          return _move(
            c,
            'inn',
            'Im „Letzten Licht“ riecht es nach Zimt, Rauch und nassem Leder. '
                'Wirt Tarek legt dir schweigend eine Karte hin: Auf ihr '
                'sind Mühle, Kapelle und Chronistenhaus eingekreist. '
                '„Eine davon wird lügen“, murmelt er. '
                'Du kannst ihn befragen oder einen Ort aufsuchen.',
            clues: {'location': 'Gasthaus'},
          );
        }
        if (_has(input, 'mara|voss|vorsteher|wache|rat|befrag')) {
          return _move(
            c,
            'watchhouse',
            'Mara Voss führt dich in die Ratsstube. Hinter verschlossenen '
                'Fensterläden zeigt sie dir eine Liste der Vermissten. '
                'Ihre behandschuhte Hand zittert. „Der Glockenorden nahm '
                'uns damals ein Versprechen ab. Was ich dir erzähle, '
                'darf nicht auf den Dorfplatz.“ '
                'Versprichst du Verschwiegenheit, verlangst du die '
                'Wahrheit oder fragst du nach Fina Kessel?',
            clues: {'maraMet': 'true', 'location': 'Ratsstube'},
          );
        }
        return RabenwachtTurn(
          c,
          'Zwischen Ratsstube und Schankstube '
          'liegt die Entscheidung bei dir. Sprich mit Mara Voss oder '
          'besuche Tarek im Letzten Licht.',
        );
      case 'watchhouse':
        if (_has(input, 'versprech|schweig|diskret|geheim|vertrau')) {
          return _move(
            c,
            'archive',
            'Du sicherst Mara zu, die Namen nicht leichtfertig preiszugeben. '
                'Sie übergibt dir einen versiegelten Brief an Alrik Nebel '
                'und eine Abschrift des Glockeneids. '
                'Diese Spur führt direkt ins Chronistenhaus. '
                'Alrik erkennt das Siegel und öffnet die alten Akten. '
                'Du kannst die Chronik untersuchen oder später '
                'die Mühle und Kapelle aufsuchen.',
            clues: {
              'maraTrust': 'true',
              'maraLetter': 'true',
              'location': 'Chronistenhaus',
            },
          );
        }
        if (_has(input, 'forder|droh|enthüll|öffentlich|verrat|lüge|anklag')) {
          return _move(
            c,
            'inn',
            'Du weigerst dich, Maras Schweigen hinzunehmen. '
                'Sie verwehrt dir den Zugang zu den Ratsakten. '
                'Doch im Flur flüstert eine Wache: '
                '„Tarek kennt den Weg am schwarzen Bach.“ '
                'Du erreichst das Gasthaus und suchst andere Spuren.',
            clues: {'maraDefied': 'true', 'location': 'Gasthaus'},
          );
        }
        if (_has(
          input,
          'fina|müller|muehle|mühl|tochter|hinweis|frag|beweis',
        )) {
          return _move(
            c,
            'mill',
            'Mara nennt dir Fina Kessels Vater Joren. '
                'Du erreichst die Mühle am schwarzen Bach. '
                'Das Mühlrad dreht sich trotz Windstille. '
                'Untersuchst du die Spuren oder sprichst du mit Joren?',
            clues: {'location': 'Alte Mühle'},
          );
        }
        return RabenwachtTurn(
          c,
          'Mara wartet auf deine Antwort: Verschwiegenheit versprechen, '
          'die Offenlegung fordern oder nach Fina fragen. '
          'Du kannst auch zum Dorfplatz zurückkehren.',
        );
      case 'well':
        if (_has(input, 'untersuch|spiegel|blick|schau|prüf|suche|feder')) {
          return _ask(
            c,
            input,
            'well',
            'wisdom',
            'Wahrnehmung',
            12,
            'Du versuchst das unmögliche Spiegelbild zu erkennen.',
            rollId,
          );
        }
        if (_has(input, 'platz|zurück|verlass|weiter')) {
          return _move(
            c,
            'square',
            'Du verlässt den Brunnen und kehrst zwischen die Häuser '
                'zurück. Die Dorfvorsteherin erwartet dich in der '
                'Ratsstube, während im Gasthaus Licht brennt.',
            clues: {'location': 'Dorfplatz'},
          );
        }
        return RabenwachtTurn(
          c,
          'Das Wasser bleibt schwarz. Du kannst sein Spiegelbild '
          'untersuchen oder zum Dorfplatz zurückgehen.',
        );
      case 'inn':
        if (_has(input, 'tarek|sprech|frag|karte|unterhalt|wirt')) {
          return _move(
            c,
            'mill',
            'Tarek schiebt dir ein schmales Messer mit eingeritztem '
                'Glockensymbol zu, bittet aber, es liegenzulassen. '
                '„Die Müllerstochter Fina war zuletzt bei der Mühle. '
                'Dort liegt der erste Teil der Wahrheit.“ '
                'Du trittst hinaus zum schwarzen Bach. '
                'Untersuchst du die Mühle oder suchst du zuerst ihre Familie?',
            clues: {'tarekTrust': 'true', 'location': 'Alte Mühle'},
          );
        }
        if (_has(input, 'mühl|bach|fina|kessel|weiter|geh')) {
          return _move(
            c,
            'mill',
            'Das Mühlrad dreht sich trotz Windstille. Auf dem Ufer '
                'liegen kleine Abdrücke, die plötzlich enden. '
                'Joren Kessel ruft aus dem Haus nach seiner Tochter. '
                'Durchsuchst du den Bach oder sprichst du mit Joren?',
            clues: {'location': 'Alte Mühle'},
          );
        }
        return RabenwachtTurn(
          c,
          'Tarek mustert dich über seinem Becher. '
          'Du kannst ihn befragen oder dich zur alten Mühle aufmachen.',
        );
      case 'mill':
        if (_has(input, 'suche|untersuch|bach|spur|rad|mühl')) {
          return _ask(
            c,
            input,
            'mill',
            'intelligence',
            'Nachforschungen',
            13,
            'Du untersuchst die nassen Spuren und die Mechanik des Mühlrads.',
            rollId,
          );
        }
        if (_has(input, 'joren|vater|kessel|sprech|frag')) {
          return _move(
            c,
            'chapel',
            'Joren erzählt dir, dass Fina die Namen der Verschollenen '
                'in ein Gebetbuch schrieb. Als du nach dem Glockenturm '
                'fragst, zeigt er auf die verlassene Kapelle. '
                'Unter ihrem Altar, sagt er, liegt etwas Verborgenes. '
                'Untersuchst du die Altarnische oder befragst du Bruder Oswin?',
            clues: {'jorenMet': 'true', 'location': 'Kapelle'},
          );
        }
        return RabenwachtTurn(
          c,
          'Das Mühlrad klappert ohne Wasser. '
          'Du kannst Joren Kessel befragen oder die Spuren am Bach untersuchen.',
        );
      case 'chapel':
        if (_has(input, 'altar|nische|buch|untersuch|gebet|such')) {
          return _move(
            c,
            'archive',
            'Hinter dem Altar liegt ein in Ölzeug gewickeltes Gebetbuch. '
                'Zwischen den Seiten steht: „Dreizehn Türen halten die '
                'Erinnerung; die vierzehnte Glocke ruft den Wächter.“ '
                'Bruder Oswin nennt dir den Namen Alrik Nebel, der im '
                'Chronistenhaus die Aufzeichnungen über die Brandnacht aufbewahrt.',
            clues: {'prayerFound': 'true', 'location': 'Chronistenhaus'},
          );
        }
        if (_has(input, 'oswin|priester|sprech|frag|geistlich')) {
          return _move(
            c,
            'archive',
            'Oswin gesteht, dass der Turm absichtlich zum Einsturz '
                'gebracht wurde, um ein Ritual zu stoppen. '
                '„Seren wollte die Vermissten schützen. Andere wollten '
                'ihre Erinnerungen als Brennstoff für ein Siegel nutzen.“ '
                'Er schickt dich zum Chronisten Alrik.',
            clues: {'oswinTruth': 'true', 'location': 'Chronistenhaus'},
          );
        }
        return RabenwachtTurn(
          c,
          'Ein einsamer Lichtstrahl fällt auf den '
          'Altar. Untersuche die Nische oder sprich mit Bruder Oswin.',
        );
      case 'archive':
        if (_has(
          input,
          'archiv|buch|bericht|alrik|schrift|untersuch|frag|sprech',
        )) {
          return _ask(
            c,
            input,
            'archive',
            'intelligence',
            'Nachforschungen',
            12,
            c.facts['maraLetter'] == 'true'
                ? 'Alrik bricht Maras Siegel und legt die geheimen '
                      'Brandberichte des Glockenordens offen. '
                      'Du vergleichst den Eid mit der Chronik.'
                : 'Du vergleichst die Brandberichte '
                      'mit der Chronik des Glockenordens.',
            rollId,
          );
        }
        return RabenwachtTurn(
          c,
          c.facts['maraDefied'] == 'true'
              ? 'Alrik kennt deinen Streit mit Mara und bleibt '
                    'auf Distanz. Du kannst die vorhandenen '
                    'Aufzeichnungen trotzdem untersuchen.'
              : 'Alrik lässt dich allein mit der Chronik. '
                    'Untersuche die alten Aufzeichnungen, '
                    'bevor du weiterziehst.',
        );
      case 'graveyard':
        // The optional memorial is a local story branch, not a mandatory
        // gate. It does not use new rule modifiers or unconfirmed rewards.
        if (_has(
          input,
          'gedenkstein|namenlosen|flüsterstein|fluesterstein|'
          'geisterstimme|schwarzen stein',
        )) {
          if (c.facts['graveOath'] == 'remembered') {
            return RabenwachtTurn(
              c,
              'Der Gedenkstein trägt nun die bewahrten Namen. '
              'Die Stimmen schweigen dankbar. Du kannst zum '
              'Waldpfad weitergehen.',
            );
          }
          if (c.facts['graveOath'] == 'hidden') {
            return RabenwachtTurn(
              c,
              'Die Namen bleiben unter dem Stein verborgen. '
              'Der Wind klingt wie ein erstickter Glockenschlag. '
              'Du kannst zum Waldpfad weitergehen.',
            );
          }
          final visited = _move(
            c,
            'graveyard',
            'Im Schatten einer abgestorbenen Eibe liegt ein Gedenkstein '
                'mit drei ausgemeißelten Namen. Darunter hörst du '
                'Stimmen: „Wer erinnert sich noch an uns?“ '
                'Alte Zeichen erinnern an den Glockenorden. '
                'Du kannst nach Hinweisen suchen, die Namen '
                'bewahren, sie verbergen oder weiterziehen.',
            clues: {'memorialSeen': 'true', 'location': 'Friedhof'},
          );
          return RabenwachtTurn(
            visited.campaign.copyWith(
              quests: [
                ...visited.campaign.quests,
                if (!visited.campaign.quests.any(
                  (quest) => quest.id == 'rabenwacht-memorial',
                ))
                  const Quest(
                    id: 'rabenwacht-memorial',
                    title: 'Die ausgelöschten Namen',
                    description: 'Entscheide, ob die Namen der '
                        'Opfer des Glockenordens bewahrt werden.',
                  ),
              ],
            ),
            visited.narration,
          );
        }
        if (c.facts['memorialSeen'] == 'true' &&
            c.facts['graveOath'] == null) {
          final hide = _has(
            input,
            'verberg|verschweig|verbrenn|vergess|vernicht|zerstör|leugne',
          );
          final remember = _has(
            input,
            'bewahr|gedenk|ich nenne|ich ehre|schwör|schwoer|erinner',
          );
          // Ambiguous/negated utterances are never silently resolved.
          final negated = _has(input, 'nicht|kein|niemals|ohne');
          if ((hide || remember) && (negated || hide == remember)) {
            return RabenwachtTurn(
              c,
              'Du bist noch unentschlossen. Soll ich die Namen bewahren '
              'oder das alte Schweigen fortsetzen? '
              'Formuliere deine Entscheidung ausdrücklich.',
            );
          }
          if (!negated && hide != remember) {
            final evidence = c.facts['prayerFound'] == 'true' ||
                c.facts['oswinTruth'] == 'true' ||
                c.facts['maraLetter'] == 'true' ||
                c.facts['serenMotive'] == 'true';
            if (remember && !evidence) {
              return RabenwachtTurn(
                c,
                'Du willst die Namen bewahren, doch die Inschrift '
                'ist unleserlich. Das Gebetbuch, Oswins Zeugnis '
                'oder die alten Aufzeichnungen könnten helfen. '
                'Du kannst später zurückkehren oder jetzt '
                'bewusst das Schweigen wählen.',
              );
            }
            final updated = c.copyWith(
              facts: {
                ...c.facts,
                'graveOath': remember ? 'remembered' : 'hidden',
              },
              quests: [
                for (final quest in c.quests)
                  if (quest.id == 'rabenwacht-memorial')
                    quest.copyWith(
                      status: remember ? 'completed' : 'failed',
                    )
                  else
                    quest,
              ],
            );
            return _move(
              updated,
              'graveyard',
              remember
                  ? 'Du sprichst die Namen laut aus den geretteten '
                      'Aufzeichnungen. Ein warmer Wind streicht '
                      'über die Gräber. Die Stimmen bitten dich, '
                      'die Wahrheit nach Rabenwacht zurückzutragen. '
                      'Im Nebel führt ein Pfad in die Rabenschlucht.'
                  : 'Du verdeckst die ausgelöschten Namen erneut. '
                      'Die Stimmen verstummen, aber das Versprechen '
                      'des Ordens bleibt ungebrochen. '
                      'Du entdeckst den Pfad zur Rabenschlucht.',
              clues: {'location': 'Friedhof'},
            );
          }
        }
        if (_has(input, 'grab|stein|zeichen|namen|untersuch|les')) {
          return _move(
            c,
            'forest',
            'Drei Grabsteine tragen dieselbe eingeritzte schwarze Hand. '
                'Unter einem davon findest du den Satz: „Der Schlüssel öffnet '
                'nicht die Tür, er trennt ihr Versprechen.“ '
                'Ein schmaler Pfad verschwindet in der Rabenschlucht. '
                'Du kannst vorsichtig vorrücken oder den Weg erkunden.',
            clues: {'graveClue': 'true', 'location': 'Rabenschlucht'},
          );
        }
        if (_has(input, 'pfad|wald|schlucht|geh|weiter')) {
          return _move(
            c,
            'forest',
            'Zwischen den Eiben siehst du am Horizont die geborstenen '
                'Zinnen des Turms. Der Weg fällt steil ab.',
            clues: {'location': 'Rabenschlucht'},
          );
        }
        return RabenwachtTurn(
          c,
          'Kalte Regentropfen fallen von den '
          'Eiben. Untersuche die Grabsteine oder betrete den Waldpfad.',
        );
      case 'forest':
        if (_has(input, 'schleich|leise|vorsichtig|heimlich')) {
          return _ask(
            c,
            input,
            'forest',
            'dexterity',
            'Heimlichkeit',
            12,
            'Du versuchst ungesehen an den Krähenwächtern vorbei zu gelangen.',
            rollId,
          );
        }
        if (_has(input, 'turm|ruine|geh|weiter|pfad|erkund')) {
          return _move(
            c,
            'ruins',
            'In der Ruine hängt keine Glocke. Dennoch zittert der '
                'Stein nach jedem Schlag. Ein Riss im Mauerwerk führt '
                'zu einer schmalen Treppe. Eine alte Inschrift sagt: '
                '„Nur wer die Schuld kennt, darf hinab.“ '
                'Untersuchst du die Inschrift oder steigst du hinunter?',
            clues: {'location': 'Turmruine'},
          );
        }
        return RabenwachtTurn(
          c,
          'Krähen starren dich aus kahlen Ästen '
          'an. Schleiche zum Turm oder gehe offen über den Pfad.',
        );
      case 'ruins':
        if (_has(input, 'inschrift|zeichen|rune|untersuch|les|magie')) {
          return _ask(
            c,
            input,
            'ruins',
            'intelligence',
            'Arkane Kunde',
            13,
            'Du deutest die verbrannten Zeichen am Torbogen.',
            rollId,
          );
        }
        if (_has(input, 'trepp|hinab|abstieg|geh|weiter')) {
          return _move(
            c,
            'stairs',
            'Du steigst ins Herz der Ruine hinab. Die Stufen sind '
                'feucht, teilweise weggebrochen. Weiter unten glänzt '
                'etwas Silbernes zwischen eingestürzten Balken. '
                'Kletterst du vorsichtig oder suchst du einen sicheren Umweg?',
            clues: {'location': 'Kryptatreppe'},
          );
        }
        return RabenwachtTurn(
          c,
          'Die Treppe führt in die Dunkelheit. '
          'Untersuche die Inschrift oder steige hinab.',
        );
      case 'stairs':
        if (_has(input, 'kletter|spring|überwind|stärk|athlet')) {
          return _ask(
            c,
            input,
            'stairs',
            'strength',
            'Athletik',
            12,
            'Du versuchst die eingestürzte Stufe zu überwinden.',
            rollId,
          );
        }
        if (_has(input, 'umweg|suche|vorsichtig|ander|weiter')) {
          return _move(
            c,
            'bonehall',
            'Du entdeckst einen schmalen Seitengang hinter den Balken. '
                'Er führt in eine Halle voller steinerner Wächterstatuen. '
                'Zwischen ihren Füßen liegt der silberne Schlüssel des '
                'sterbenden Boten. Als du näherkommst, regt sich eine '
                'Rüstung voller Knochen. Du kannst kämpfen oder versuchen, '
                'an ihr vorbeizuschleichen.',
            clues: {'location': 'Halle der Wächter'},
          );
        }
        return RabenwachtTurn(
          c,
          'Vor dir klafft eine Lücke in der '
          'Steintreppe. Klettere darüber oder suche einen Umweg.',
        );
      case 'bonehall':
        if (_has(input, 'schleich|umgeh|versteck|leise')) {
          return _ask(
            c,
            input,
            'bonehall',
            'dexterity',
            'Heimlichkeit',
            13,
            c.facts['crowsAlerted'] == 'true'
                ? 'Die Krähen haben den Wächter bereits gewarnt. '
                      'Du suchst trotzdem lautlos einen Weg vorbei.'
                : 'Du versuchst den Knochenwächter lautlos zu umgehen.',
            rollId,
          );
        }
        if (_wantsFight(input)) {
          return RabenwachtTurn(
            c.copyWith(storyBible: {...c.storyBible, 'stage': 'sentryFight'}),
            'Die Knochen der alten Rüstung klappern. Ein Skelettwächter '
            'stellt sich dir in den Weg. Würfle Initiative!',
            battle: true,
          );
        }
        return RabenwachtTurn(
          c,
          'Der Knochenwächter bewacht den '
          'silbernen Schlüssel. Du kannst kämpfen oder schleichen.',
        );
      case 'sentryFight':
        return RabenwachtTurn(
          c,
          'Der Wächter steht noch vor dir. '
          'Verwende deine Kampfaktionen. Nach dem Sieg geht die Reise weiter.',
        );
      case 'seal':
        if (_has(input, 'schlüssel|silber|nehm|tür|siegel|geh|weiter')) {
          return _move(
            c,
            'door13',
            'Hinter der Wache erstreckt sich eine Galerie mit dreizehn '
                'steinernen Türen. Zwölf sind versiegelt. Hinter der '
                'dreizehnten hörst du Fina um Hilfe rufen. '
                'Die Tür trägt zwei Vertiefungen: Hand und Schlüssel. '
                'Untersuchst du das Siegel, sprichst du mit Fina oder '
                'versuchst du die Tür zu öffnen?',
            clues: {
              'silverKeyFound': 'true',
              'location': 'Galerie der dreizehn Türen',
            },
          );
        }
        return RabenwachtTurn(
          c,
          'Der Gang ist frei, der silberne '
          'Schlüssel liegt vor dir. Nimm ihn und geh zur Galerie.',
        );
      case 'door13':
        if (_has(input, 'rune|siegel|untersuch|magie|zeichen|inschrift')) {
          return _ask(
            c,
            input,
            'door13',
            'intelligence',
            'Arkane Kunde',
            14,
            'Du prüfst die Magie des silbernen Schlüssels und der Tür.',
            rollId,
          );
        }
        if (_has(input, 'fina|spreche|ruf|antwort|rede|frag')) {
          return _move(
            c,
            'chamber',
            '„Ich bin nicht allein“, flüstert Fina durch den Stein. '
                '„Die anderen schlafen im Kreis. Seren hält uns fest, '
                'damit die Glocke uns nicht verzehrt.“ '
                'Du öffnest die Tür mit dem silbernen Schlüssel. '
                'Im Inneren wartet ein leuchtender Kreis mit drei '
                'Gefangenen und dem Geist Seren. '
                'Du kannst Seren befragen, den Kreis untersuchen oder '
                'das Siegel gewaltsam brechen.',
            clues: {'finaHeard': 'true', 'location': 'Siegelkammer'},
          );
        }
        if (_has(input, 'öffn|oeffn|schlüssel|betret|hindurch|geh|weiter')) {
          return _move(
            c,
            'chamber',
            'Der silberne Schlüssel wird kalt in deiner Hand. '
                'Du öffnest die dreizehnte Tür. Fina, Bram und der '
                'Holzfäller liegen im Schutzkreis. Darüber schwebt '
                'Seren, ein ausgezehrter Geist in einer zerbrochenen '
                'Ordensrobe. „Ich wollte sie retten“, sagt Seren. '
                'Was tust du: sprechen, das Ritual untersuchen oder das Siegel brechen?',
            clues: {'location': 'Siegelkammer'},
          );
        }
        return RabenwachtTurn(
          c,
          'Aus der dreizehnten Tür dringt ein '
          'leises Klopfen. Sprich mit Fina, untersuche das Siegel '
          'oder öffne die Tür.',
        );
      case 'chamber':
        if (_has(input, 'seren|sprech|verhandel|überred|frag|vertrau|rede')) {
          return _ask(
            c,
            input,
            'chamber',
            'charisma',
            'Überreden',
            14,
            'Du versuchst Seren davon zu überzeugen, die Gefangenen freizugeben.',
            rollId,
          );
        }
        if (_has(input, 'ritual|kreis|zeichen|untersuch|prüf|magie')) {
          return _move(
            c,
            'choice',
            'Du erkennst die grausame Wahrheit: Die Menschen dienen '
                'dem Siegel nicht aus freiem Willen. Die vierzehnte Glocke '
                'zieht Kraft aus ihren Erinnerungen. '
                'Mit dem silbernen Schlüssel kannst du das Siegel erneuern '
                'und die Gefangenen befreien. Du könntest es auch zerstören '
                'oder Serens Hilfe beim Übergang erbitten. '
                'Wie entscheidest du dich?',
            clues: {'ritualKnown': 'true'},
          );
        }
        if (_has(input, 'zerstör|zerschlag|brech|gewalt')) {
          return _ending(
            c,
            'end-break',
            'Du zerschlägst das alte Siegel. Alle drei Vermissten '
                'erwachen und stolpern zu dir. Die Glocke verstummt, '
                'doch unter der Ruine öffnet sich ein dunkler Riss. '
                'Du hast Leben gerettet, aber ein altes Unheil befreit. '
                'Rabenwacht wird deine Entscheidung nie vergessen.',
          );
        }
        return RabenwachtTurn(
          c,
          'Seren blickt dich mit Augen aus '
          'blassem Licht an. Du kannst verhandeln, den Kreis untersuchen '
          'oder das Siegel brechen.',
        );
      case 'choice':
        if (_has(input, 'erneuer|reparier|versiegel|schlüssel|schluessel')) {
          return _ending(
            c,
            'end-seal',
            'Du drehst den silbernen Schlüssel im Herzen der Glocke. '
                'Die gefangenen Erinnerungen kehren zu ihren Besitzern zurück. '
                'Fina, Bram und der Holzfäller erwachen. Die Tür schließt '
                'sich, die Glocke verstummt und Seren findet endlich Ruhe. '
                'Das Dorf feiert deine stille, schwere Entscheidung.',
          );
        }
        if (_has(input, 'zerstör|zerschlag|brech')) {
          return _ending(
            c,
            'end-break',
            'Du zerbrichst den Runenkreis. Die drei Gefangenen entkommen, '
                'aber die Ruine erbebt: Etwas Altes dringt nach Valdorn. '
                'Du kehrst mit den Geretteten zurück. Der Schatten '
                'dieser Entscheidung bleibt über der Grenze liegen.',
          );
        }
        if (_has(input, 'seren|erlös|erloes|vergeb|fried|übergang')) {
          return _ending(
            c,
            'end-mercy',
            'Du legst den Schlüssel in Serens Hand und sprichst die '
                'vergessenen Namen der Gefangenen. Seren lächelt zum '
                'ersten Mal seit einundvierzig Jahren. Der Geist opfert '
                'seinen letzten Funken, um die Menschen zu befreien und '
                'das Siegel ohne Opfer zu schließen. Als draußen '
                'die Sonne aufgeht, ist Rabenwacht endlich still.',
          );
        }
        return RabenwachtTurn(
          c,
          'Es gibt drei ernsthafte Möglichkeiten: '
          'das Siegel erneuern, es zerstören oder Seren erlösen. '
          'Du darfst frei entscheiden und weitere Fragen stellen.',
        );
      default:
        return RabenwachtTurn(
          c,
          'Dein letzter Schritt wurde bewahrt. '
          'Beschreibe bitte, welchen Ort oder wen du nun aufsuchst.',
        );
    }
  }

  static RabenwachtTurn resolveCheck(
    Campaign c,
    PendingRoll pending,
    bool passed,
  ) {
    final step = pending.targetId.replaceFirst('rabenwacht:', '');
    switch (step) {
      case 'road':
        return _move(
          c,
          'square',
          passed
              ? 'Im Nebel erkennst du die Schritte eines barfüßigen '
                    'Menschen. Sie enden an einem schwarzen Handabdruck '
                    'auf einem Wegstein. Elda nennt dir das Gasthaus '
                    '„Zum Letzten Licht“. Du erreichst den Dorfplatz.'
              : 'Du hörst nur den Regen, doch Elda zieht dich '
                    'zum Dorfplatz. „Im Letzten Licht wissen sie mehr“, '
                    'flüstert sie.',
          clues: {if (passed) 'blackHandClue': 'true', 'location': 'Dorfplatz'},
        );
      case 'well':
        return _move(
          c,
          'square',
          passed
              ? 'Du erkennst im Wasser das Spiegelbild einer '
                    'vierzehnten Tür ohne sichtbares Gegenstück. '
                    'Ein einzelnes Wort steht auf dem Rahmen: '
                    '„Erinnerung“. Mit dieser Entdeckung kehrst du '
                    'auf den Dorfplatz zurück.'
              : 'Für einen Moment siehst du einen Schatten zwischen '
                    'den Spiegelungen, doch der Regen zerstreut ihn. '
                    'Du kehrst zum Dorfplatz zurück.',
          clues: {
            'wellVisited': 'true',
            if (passed) 'wellClue': 'true',
            'location': 'Dorfplatz',
          },
        );
      case 'mill':
        return _move(
          c,
          'chapel',
          passed
              ? 'Zwischen den Zähnen des Mühlrads findest du eine '
                    'feuchte, aber lesbare Nachricht von Fina: „Suche '
                    'das Gebetbuch unter dem Altar.“ Du eilst zur Kapelle.'
              : 'Die Strömung hat die Spuren verwischt. Joren weist '
                    'dich auf das Gebetbuch in der Kapelle hin.',
          clues: {if (passed) 'finaNote': 'true', 'location': 'Kapelle'},
        );
      case 'archive':
        return _move(
          c,
          'graveyard',
          passed
              ? 'Ein übersehener Bericht enthüllt: Seren band die '
                    'Seelen nicht aus Bosheit, sondern um das Ritual '
                    'der Glockenmacher zu unterbrechen. Eine Karte '
                    'markiert den Friedhof, wo ihr letzter Weg beginnt.'
              : 'Alrik weicht deinen Fragen aus. Immerhin gibt er '
                    'dir den Weg zum Friedhof: Dort soll der Schlüssel '
                    'in der Brandnacht zuletzt gesehen worden sein.',
          clues: {if (passed) 'serenMotive': 'true', 'location': 'Friedhof'},
        );
      case 'forest':
        return _move(
          c,
          'ruins',
          passed
              ? 'Du erreichst den Turm, ohne dass die Krähen dich '
                    'bemerken. Unter einem Stein entdeckst du '
                    'die Spuren einer verborgenen Treppe.'
              : 'Eine Krähe schreit auf, alle anderen folgen ihr. '
                    'Du erreichst den Turm, doch die Wächter der '
                    'Krypta sind gewarnt. Die Treppe liegt offen.',
          clues: {if (!passed) 'crowsAlerted': 'true', 'location': 'Turmruine'},
        );
      case 'ruins':
        return _move(
          c,
          'stairs',
          passed
              ? 'Du entzifferst: „Das Opfer ist ein Wille, kein '
                    'Körper.“ Dir wird klar, dass der Kreis unter dem '
                    'Turm an Erinnerungen gebunden ist. Du steigst '
                    'über die verborgene Treppe hinab.'
              : 'Die Zeichen sind zu verwittert, um sie vollständig '
                    'zu lesen. Die Treppe führt dennoch nach unten.',
          clues: {if (passed) 'runeClue': 'true', 'location': 'Kryptatreppe'},
        );
      case 'stairs':
        return _move(
          c,
          'bonehall',
          passed
              ? 'Du ziehst dich mit beiden Händen über den '
                    'Abgrund. Dahinter erstreckt sich eine Halle '
                    'voller Statuen; ein Skelettwächter regt sich '
                    'neben dem silbernen Schlüssel.'
              : 'Ein Stein löst sich unter deinem Fuß. Du '
                    'klammerst dich an den Rand, findest aber '
                    'eine sichere Kante und erreichst die Halle. '
                    'Dort wartet ein Skelettwächter am Schlüssel.',
          clues: {'location': 'Halle der Wächter'},
        );
      case 'bonehall':
        return _move(
          c,
          'seal',
          passed
              ? 'Du schlüpfst ungesehen zwischen zwei Pfeilern '
                    'hindurch. Den silbernen Schlüssel ziehst du '
                    'aus einer Spalte im Boden. Ein Tor führt '
                    'zur Galerie der dreizehn Türen.'
              : 'Die Rüstung rasselt, als du eine Kette streifst. '
                    'Der Wächter ist gewarnt, doch du erreichst '
                    'eine schmale Seitennische mit dem Schlüssel. '
                    'Jetzt kannst du zur Galerie weitergehen.',
          clues: {'silverKeyFound': 'true'},
        );
      case 'door13':
        return _move(
          c,
          'chamber',
          passed
              ? 'Du erkennst, dass der Schlüssel das Siegel '
                    'erneuern kann, ohne ein Leben zu fordern. '
                    'Du öffnest die dreizehnte Tür. Fina, Bram '
                    'und der Holzfäller liegen in einem leuchtenden '
                    'Kreis; der Geist Seren bewacht sie.'
              : 'Die Runen bleiben rätselhaft. Mit dem '
                    'silbernen Schlüssel öffnest du die dreizehnte '
                    'Tür. Drei Gefangene ruhen in einem Lichtkreis, '
                    'über dem Seren schwebt.',
          clues: {
            if (passed) 'ritualSolution': 'true',
            'location': 'Siegelkammer',
          },
        );
      case 'chamber':
        if (passed) {
          return _move(
            c,
            'choice',
            'Deine Worte erreichen Seren. Der Geist vertraut dir '
                'genug, die Wahrheit über das Opfer zu offenbaren. '
                'Seren ist bereit, sich erlösen zu lassen. '
                'Du entscheidest jetzt selbst, ob du ihr diesen '
                'Frieden anbietest, das Siegel erneuerst '
                'oder den Runenkreis zerstörst.',
            clues: {'serenTrust': 'true'},
          );
        }
        return _move(
          c,
          'choice',
          'Seren weicht deinem Blick aus. „Ich wollte niemanden '
              'verletzen.“ Du hast jetzt die Entscheidung: '
              'Erneuere das Siegel, zerstöre es oder biete Seren '
              'den Übergang an. Der Ausgang liegt bei dir.',
        );
      default:
        throw const FormatException('Unbekannte Rabenwacht-Probe.');
    }
  }

  static RabenwachtTurn _ending(Campaign c, String stage, String prose) {
    final aftermath = <String>[
      if (c.facts['maraTrust'] == 'true')
        'Mara Voss hält ihr Versprechen und unterstützt dich '
            'als Verbündete beim Wiederaufbau des Dorfes.',
      if (c.facts['maraDefied'] == 'true')
        'Mara Voss dankt dir für die Rettung, doch euer Streit '
            'über das Schweigen des Rates bleibt ungelöst.',
      if (c.facts['crowsAlerted'] == 'true')
        'Die aufgescheuchten Krähen haben die Wachen alarmiert; '
            'die Dorfbewohner erwarten deine Rückkehr mit Sorge.',
      if (c.facts['serenTrust'] == 'true')
        'Serens Vertrauen verändert, wie das Dorf '
            'über den gebundenen Geist spricht.',
      if (c.facts['graveOath'] == 'remembered')
        'Vor dem Dorf liest du die bewahrten Namen vor. '
            'Die Familien wissen endlich, was damals geschah.',
      if (c.facts['graveOath'] == 'hidden')
        'Die ausgelöschten Namen bleiben ein Geheimnis. '
            'Einige Familien erfahren nie die ganze Wahrheit.',
    ].join(' ');
    final next = c.copyWith(
      quests: [
        for (final quest in c.quests)
          if (quest.id == 'rabenwacht-memorial' &&
              quest.status == 'active')
            quest.copyWith(status: 'failed')
          else if (quest.status == 'active')
            quest.copyWith(status: 'completed')
          else
            quest,
      ],
      facts: {...c.facts, 'allMissingFound': 'true', 'ending': stage},
    );

    return _move(
      next,
      stage,
      '$prose${aftermath.isEmpty ? '' : ' $aftermath'}',
    );
  }
}
