import 'dart:convert';

import 'dice_engine.dart';
import 'models.dart';
import 'rules_engine.dart';

/// A free-text, deterministic narrator. It cannot execute SQL or provider tools.
/// Every accepted turn produces a validated state checkpoint and an audit event.
class GameEngine {
  GameEngine({DiceEngine? dice, DateTime Function()? clock})
    : dice = dice ?? DiceEngine(),
      _clock = clock ?? DateTime.now;
  final DiceEngine dice;
  final DateTime Function() _clock;
  int _sequence = 0;
  String _id(String prefix) =>
      '$prefix-${_clock().microsecondsSinceEpoch}-${_sequence++}';

  /// Replaces the narration of the latest unconfirmed free turn, never rules.
  /// Its existing checkpoint is rewritten with the same confirmed game state.
  GameUpdate replaceNarration(
    GameUpdate update, {
    required String text,
    required String provider,
  }) {
    final narration = text.trim();
    if (narration.isEmpty || narration.length > 4000) {
      throw const FormatException(
        'Die Erzählung muss 1 bis 4000 Zeichen enthalten.',
      );
    }
    if (!const ['mock', 'openai'].contains(provider)) {
      throw const FormatException('Unbekannter Erzählanbieter.');
    }
    final campaign = update.campaign;
    if (update.events.length != 1 || campaign.events.isEmpty) {
      throw const FormatException(
        'Nur ein einzelnes neues Erzählereignis darf ersetzt werden.',
      );
    }
    final original = update.events.single;
    if (original.type != 'narrative.turn' ||
        original.campaignId != campaign.id ||
        original.sessionId != campaign.sessionId ||
        campaign.events.last.id != original.id ||
        _canonicalJson(campaign.events.last.toJson()) !=
            _canonicalJson(original.toJson())) {
      throw const FormatException(
        'Nur die aktuelle freie Erzählung darf ersetzt werden.',
      );
    }
    if (campaign.messages.isEmpty || campaign.messages.last.role != 'gm') {
      throw const FormatException('Die aktuelle Spielleiterantwort fehlt.');
    }
    final checkpoint = original.payload['stateAfter'];
    if (checkpoint is! Map<String, dynamic> ||
        _canonicalJson(checkpoint) !=
            _canonicalJson(campaign.copyWith(events: const []).toJson())) {
      throw const FormatException(
        'Das Erzählereignis gehört nicht zum aktuellen Spielzustand.',
      );
    }
    // Validate the incoming state before retaining all of its rule fields.
    Campaign.fromJson(campaign.toJson());
    final last = campaign.messages.last;
    final narrated = campaign.copyWith(
      messages: [
        ...campaign.messages.take(campaign.messages.length - 1),
        NarrativeMessage(
          id: last.id,
          role: last.role,
          text: narration,
          timestamp: last.timestamp,
        ),
      ],
    );
    // Deep-copy JSON payloads so an external provider cannot retain or mutate
    // nested maps from the original audit event.
    final payload =
        jsonDecode(jsonEncode(original.payload)) as Map<String, dynamic>;
    payload['narrationProvider'] = provider;
    payload['stateAfter'] = jsonDecode(
      jsonEncode(narrated.copyWith(events: const []).toJson()),
    );
    final event = GameEvent(
      id: original.id,
      campaignId: original.campaignId,
      sessionId: original.sessionId,
      timestamp: original.timestamp,
      type: original.type,
      entities: original.entities,
      payload: payload,
    );
    final result = narrated.copyWith(
      events: [...campaign.events.take(campaign.events.length - 1), event],
    );
    Campaign.fromJson(result.toJson());
    return GameUpdate(campaign: result, events: [event]);
  }

  /// Saves a bounded summary of structured, already confirmed world state.
  /// Free player speech and generated prose are intentionally not sources.
  GameUpdate saveSessionRecap(Campaign campaign) {
    if (campaign.sessionRecaps.length >= 60) {
      throw const FormatException('Maximal 60 Sitzungsrückblicke möglich.');
    }
    final summary = MemoryEngine.buildSessionSummary(campaign);
    final recap = SessionRecap(
      id: _id('recap'),
      title: 'Rückblick ${campaign.sessionRecaps.length + 1}',
      summary: summary,
      createdAt: _clock(),
    );
    return _commit(
      campaign,
      campaign.copyWith(sessionRecaps: [...campaign.sessionRecaps, recap]),
      'Ein neuer Sitzungsrückblick wurde im Tagebuch bestätigt und gespeichert.',
      type: 'memory.sessionRecapSaved',
      payload: {'recapId': recap.id},
    );
  }

  /// Relationship changes are explicit editorial choices, never AI actions.
  GameUpdate recordNpcRelationship(
    Campaign campaign, {
    required String npcId,
    required String relationship,
    required String note,
  }) {
    final npc = campaign.npcs.where((entry) => entry.id == npcId).toList();
    if (npc.length != 1) {
      throw const FormatException('Der ausgewählte NPC existiert nicht.');
    }
    final normalized = relationship.trim();
    final description = note.trim();
    if (normalized.isEmpty || normalized.length > 80 ||
        description.isEmpty || description.length > 500) {
      throw const FormatException(
        'Beziehung (1–80 Zeichen) und Notiz (1–500 Zeichen) angeben.',
      );
    }
    if (campaign.npcRelationshipNotes.length >= 300) {
      throw const FormatException('Maximal 300 NPC-Notizen möglich.');
    }
    final entry = NpcRelationshipNote(
      id: _id('npc-note'),
      npcId: npcId,
      relationship: normalized,
      note: description,
      recordedAt: _clock(),
    );
    return _commit(
      campaign,
      campaign.copyWith(
        npcs: [
          for (final current in campaign.npcs)
            current.id == npcId
                ? current.copyWith(relationship: normalized)
                : current,
        ],
        npcRelationshipNotes: [...campaign.npcRelationshipNotes, entry],
      ),
      'Deine bestätigte Beziehungsnotiz zu ${npc.single.name} wurde gespeichert.',
      type: 'memory.npcRelationshipRecorded',
      payload: {'npcId': npcId, 'noteId': entry.id},
    );
  }

  /// Story threads are leads, not mechanically rewarded quests.
  GameUpdate saveStoryThread(
    Campaign campaign, {
    String? threadId,
    required String title,
    required String description,
    required String status,
  }) {
    final cleanTitle = title.trim();
    final cleanDescription = description.trim();
    if (cleanTitle.isEmpty || cleanTitle.length > 120 ||
        cleanDescription.length > 1000 ||
        !const ['open', 'resolved', 'abandoned'].contains(status)) {
      throw const FormatException('Titel, Notiz oder Handlungsstatus ungültig.');
    }
    if (threadId == null && campaign.storyThreads.length >= 100) {
      throw const FormatException('Maximal 100 Handlungsstränge möglich.');
    }
    if (threadId != null &&
        campaign.storyThreads.where((thread) => thread.id == threadId).length != 1) {
      throw const FormatException('Handlungsstrang nicht gefunden.');
    }
    final thread = StoryThread(
      id: threadId ?? _id('thread'),
      title: cleanTitle,
      description: cleanDescription,
      status: status,
    );
    final threads = threadId == null
        ? [...campaign.storyThreads, thread]
        : [
            for (final old in campaign.storyThreads)
              old.id == threadId ? thread : old,
          ];
    return _commit(
      campaign,
      campaign.copyWith(storyThreads: threads),
      'Der Handlungsstrang „${thread.title}“ wurde im Tagebuch gespeichert.',
      type: 'memory.storyThreadSaved',
      payload: {'threadId': thread.id, 'status': status},
    );
  }

  GameUpdate rollDice(Campaign campaign, String expression) {
    final result = dice.roll(expression);
    final natural = result.natural == null
        ? ''
        : ' Naturwurf: ${result.natural}.';
    return _commit(
      campaign,
      campaign,
      '${result.expression}: ${result.rolls.join(', ')}; Gesamtergebnis ${result.total}.$natural Der freie Wurf verändert keine Charakterwerte.',
      type: 'dice.freeRoll',
      payload: {'roll': result.toJson()},
    );
  }

  Campaign createDemo({HeroCharacter? hero, String? name}) {
    final chosen =
        hero ??
        HeroCharacter(
          id: _id('hero'),
          name: 'Liora',
          species: 'Mensch',
          className: 'Kämpfer',
          background: 'Wächterin',
          backstory: 'Eine wandernde Beschützerin der Waldwege.',
          abilities: const {
            'strength': 16,
            'dexterity': 14,
            'constitution': 14,
            'intelligence': 10,
            'wisdom': 12,
            'charisma': 8,
          },
          hitPoints: 12,
          maxHitPoints: 12,
          armorClass: 16,
          speed: 9,
          skills: const ['Athletik', 'Wahrnehmung'],
          savingThrowProficiencies: const ['strength', 'constitution'],
          features: const ['Demo-Testbogen: Schwertangriff'],
          weaponDamage: '1d8',
          weaponAbility: 'strength',
          weaponProficient: true,
          inventory: const [
            InventoryItem(id: 'sword', name: 'Langschwert'),
            InventoryItem(id: 'armor', name: 'Kettenhemd'),
            InventoryItem(
              id: 'potion',
              name: 'Heiltrank',
              description: 'Heilt 2W4+2 Trefferpunkte.',
            ),
          ],
          gold: 10,
          experience: 0,
        );
    final scene =
        '${chosen.name}, vor dir liegt Mooswacht am Rand des Sternenwaldes. '
        'Die Hüterin Mira bittet dich, das erloschene Waldlicht im alten Schrein zu entzünden. '
        'Am Dorfbrunnen glitzert etwas zwischen den Steinen. Was möchtest du tun?';
    final campaign = Campaign(
      id: _id('demo'),
      name: name ?? 'Das Licht von Mooswacht',
      world: 'Lunaris',
      sessionId: _id('session'),
      hero: chosen,
      scene: scene,
      messages: [
        NarrativeMessage(
          id: _id('message'),
          role: 'gm',
          text: scene,
          timestamp: _clock(),
        ),
      ],
      facts: const {
        'origin': 'demo',
        'location': 'Mooswacht',
        'waldlicht': 'Das Waldlicht ist erloschen. Mira bittet um Hilfe.',
      },
      quests: const [
        Quest(
          id: 'waldlicht',
          title: 'Das Waldlicht entzünden',
          description:
              'Finde den Messingschlüssel, überwinde den Dornenwächter und öffne den Schrein.',
        ),
      ],
      npcs: const [
        WorldNpc(
          id: 'mira',
          name: 'Mira',
          description: 'Freundliche Hüterin von Mooswacht.',
          relationship: 'freundlich',
        ),
      ],
      places: const [
        Place(
          id: 'mooswacht',
          name: 'Mooswacht',
          description: 'Walddorf mit einem alten Brunnen.',
        ),
      ],
    );
    return campaign;
  }

  Campaign createArescan() {
    final hero = HeroCharacter(
      id: _id('arescan'),
      name: 'Arescan',
      species: 'Mensch',
      className: 'Waldläufer',
      unverifiedNotes: const [
        'Attribute, Trefferpunkte, Rüstungsklasse, Bewegung, Ausrüstung und Waffenwerte sind nicht bestätigt.',
        'Gold und Erfahrungspunkte sind unbekannt. Leere Listen für Fertigkeiten, Zauber und Ausrüstung bedeuten nicht, dass Arescan diese nachweislich nicht besitzt.',
        'Historischer Angriff: Gesamtergebnis 19; erzählter Schaden 14. Kein natürlicher W20 bekannt.',
        'Der früher verwendete Geschicklichkeitsmodifikator +7 ist ungeprüft und wird NICHT angewendet.',
      ],
    );
    const scene =
        'Arescan steht auf dem Marktplatz von Silberhain neben der Elfenmagierin. '
        'Der verletzte Schattenritter liegt nach dem Sturz vom Dach auf dem Marktplatz. '
        'An seiner Brust leuchtet ein rotes Amulett: das Zeichen des Schattenkönigs. '
        'Du kannst ihn untersuchen, verhören oder die Elfin befragen. Regelaktionen benötigen zuerst einen bestätigten Charakterbogen.';
    final id = _id('aetheria');
    final sessionId = _id('session');
    final history = GameEvent(
      id: _id('history'),
      campaignId: id,
      sessionId: sessionId,
      timestamp: _clock(),
      type: 'history.imported',
      entities: [hero.id, 'shadow-knight'],
      payload: const {
        'attackTotal': 19,
        'narratedDamage': 14,
        'naturalRoll': null,
        'unverifiedDexterityModifier': 7,
        'mechanicallyVerified': false,
        'history': [
          'Der Sternentempel erwacht nach tausend Jahren.',
          'Ein goldener Drache verkündet, dass das Herz der Ewigkeit gestohlen wurde.',
          'In Silberhain erscheint ein Portal. Eine Elfenmagierin warnt vor Schattenrittern.',
          'Ein vermummter Bogenschütze greift vom Dach an. Arescan warnt die Elfin und zieht sie hinter einen Brunnen.',
          'Arescan greift mit seinem Bogen an: historisches Gesamtergebnis 19 und erzählter Schaden 14.',
          'Der Schattenritter stürzt vom Dach. Sein rotes Amulett zeigt das Zeichen des Schattenkönigs.',
        ],
      },
    );
    return Campaign(
      id: id,
      name: 'Das Herz der Ewigkeit',
      world: 'Aetheria',
      sessionId: sessionId,
      hero: hero,
      scene: scene,
      messages: [
        NarrativeMessage(
          id: _id('message'),
          role: 'gm',
          text: scene,
          timestamp: _clock(),
        ),
      ],
      facts: const {
        'origin': 'arescan',
        'location': 'Silberhain',
        'sternentempel': 'Der Sternentempel ist nach tausend Jahren erwacht.',
        'herz':
            'Das Herz der Ewigkeit wurde gestohlen; ein goldener Drache verkündete es.',
        'portal':
            'In Silberhain erschien ein Portal. Eine Elfenmagierin warnte vor Schattenrittern.',
        'rettung':
            'Arescan warnte die Elfin und zog sie hinter den Brunnen in Deckung.',
        'angriff':
            'Historischer Angriff Gesamt 19, erzählter Schaden 14; Regelwerte ungeprüft.',
        'amulett':
            'Das rote Amulett am verletzten Schattenritter ist das Zeichen des Schattenkönigs.',
        'schattenritter':
            'Verletzt nach dem Sturz vom Dach; genaue Trefferpunkte und Kampfwerte unbekannt.',
      },
      quests: const [
        Quest(
          id: 'heart',
          title: 'Das Herz der Ewigkeit',
          description:
              'Finde das gestohlene Herz und erforsche das Zeichen des Schattenkönigs.',
        ),
      ],
      npcs: const [
        WorldNpc(
          id: 'elf',
          name: 'Elfenmagierin',
          description:
              'Von Arescan gerettet; kennt das Zeichen des Schattenkönigs.',
          relationship: 'dankbar',
        ),
        WorldNpc(
          id: 'shadow-knight',
          name: 'Verletzter Schattenritter',
          description: 'Vom Dach gestürzt. Kampfwerte unbestätigt.',
        ),
      ],
      places: const [
        Place(
          id: 'silberhain',
          name: 'Silberhain',
          description: 'Marktplatz mit Brunnen und magischem Portal.',
        ),
      ],
      events: [history],
    );
  }

  GameUpdate updateHero(Campaign campaign, HeroCharacter hero) {
    // Round-trip validation also checks imported edits made outside the engine.
    final validated = HeroCharacter.fromJson(hero.toJson());
    if (validated.id != campaign.hero.id) {
      throw ArgumentError(
        'Ein anderer Charakter kann nicht stillschweigend übernommen werden.',
      );
    }
    return _commit(
      campaign,
      campaign.copyWith(hero: validated, pendingRoll: null),
      validated.isComplete
          ? '${hero.name}, dein Charakterbogen ist bestätigt. Deine historischen Erlebnisse bleiben erhalten.'
          : 'Der Charakterbogen wurde gespeichert. Noch offen: ${validated.incompleteFields.join(', ')}.',
      type: 'character.updated',
      payload: {'characterId': hero.id},
    );
  }

  GameUpdate act(Campaign campaign, String input) {
    final text = input.trim();
    if (text.isEmpty || text.length > 4000) {
      throw const FormatException(
        'Bitte eine Handlung mit 1 bis 4000 Zeichen eingeben.',
      );
    }
    final words = text.toLowerCase();
    final spokenRoll = _spokenNumber(words);
    if (campaign.pendingRoll != null && spokenRoll != null) {
      return resolveRoll(
        campaign,
        natural: words.contains('gesamt') ? null : spokenRoll,
        total: words.contains('gesamt') ? spokenRoll : null,
        input: text,
      );
    }
    final current = campaign.copyWith(
      messages: [
        ...campaign.messages,
        NarrativeMessage(
          id: _id('message'),
          role: 'player',
          text: text,
          timestamp: _clock(),
        ),
      ],
    );
    if (MemoryEngine.isRecallRequest(text)) {
      // Only explicitly confirmed structured sources can answer a recall.
      // Free narrative, player claims and model text are not evidence.
      final memories = MemoryEngine.retrieve(
        current,
        text,
        limit: 4,
        maxCharacters: 280,
        matchingOnly: true,
      );
      final narration = memories.isEmpty
          ? '${current.hero.name}, dazu finde ich in deinem bestätigten '
              'Abenteuer noch keine passende Erinnerung. '
              'Was möchtest du genauer untersuchen?'
          : '${current.hero.name}, das ist aus deinem Abenteuer bestätigt:\n'
              '${memories.map((entry) => '• $entry').join('\n')}\n'
              'Woran möchtest du anknüpfen?';
      return _commit(
        campaign,
        current,
        narration,
        type: 'memory.recalled',
      );
    }
    if (RegExp(r'inventar|ausrüstung|besitze').hasMatch(words)) {
      final items = current.hero.inventory
          .map((e) => '${e.quantity} ${e.name}')
          .join(', ');
      return _commit(
        campaign,
        current,
        items.isEmpty
            ? 'Deine Ausrüstung ist noch nicht bestätigt. Du kannst sie im Charakterbogen ergänzen.'
            : 'Du trägst $items. Was möchtest du damit tun?',
      );
    }
    if (campaign.pendingRoll != null) {
      return _commit(
        campaign,
        current,
        'Eine Probe wartet noch auf dich. Würfle automatisch oder gib den natürlichen W20 ein; ein Gesamtergebnis musst du ausdrücklich als Gesamt kennzeichnen.',
      );
    }
    if (RegExp(
          r'angreif|attackier|greif\w*.*\ban(?:[.!?]|$)|schieß|schies|kämpf|kaempf|würfel|wuerfel|probe|heile|heiltrank|rast|ruhe',
        ).hasMatch(words) &&
        !current.hero.isComplete) {
      return _commit(
        campaign,
        current,
        'Für eine regelkonforme Handlung fehlen: ${current.hero.incompleteFields.join(', ')}. Ergänze diese Werte im Charakterbogen. Die Geschichte bleibt zugänglich.',
        type: 'rules.blocked',
      );
    }
    if (current.hero.isDead) {
      return _commit(
        campaign,
        current,
        'Dein Held ist gestorben. Dieses Ereignis bleibt im Tagebuch. Du kannst einen neuen Helden und ein neues Abenteuer erstellen.',
        type: 'rules.blocked',
      );
    }
    if (current.hero.hitPoints == 0 && current.hero.isComplete) {
      if (current.hero.conditions.contains(RulesEngine.stable)) {
        return _commit(
          campaign,
          current,
          'Du bist stabil, aber bewusstlos. Eine andere Person muss dich heilen; du kannst selbst keine Handlung ausführen.',
          type: 'rules.blocked',
        );
      }
      return _commit(
        campaign,
        current.copyWith(
          pendingRoll: PendingRoll(
            id: _id('roll'),
            type: 'death',
            modifier: 0,
            difficulty: 10,
          ),
        ),
        'Du bist bewusstlos. Bitte würfle einen natürlichen W20 für deinen Todesrettungswurf.',
        type: 'roll.requested',
      );
    }
    if (current.facts['origin'] == 'arescan') {
      return _arescan(campaign, current, words);
    }
    if (current.encounter != null && !current.encounter!.isFinished) {
      return _combatAction(campaign, current, words);
    }
    if (RegExp(r'heiltrank|trank.*trink|trink.*trank').hasMatch(words)) {
      return _drinkPotion(campaign, current);
    }
    if (RegExp(r'rast|ausruhen|ruhe').hasMatch(words)) {
      if (!current.hero.isComplete) {
        return _commit(
          campaign,
          current,
          'Bitte vervollständige zunächst den Charakterbogen.',
          type: 'rules.blocked',
        );
      }
      final healed = RulesEngine.heal(current.hero, current.hero.maxHitPoints!);
      return _commit(
        campaign,
        current.copyWith(hero: healed),
        'Nach einer sicheren langen Rast bist du wieder bei Kräften. Deine Trefferpunkte sind vollständig hergestellt. Was möchtest du tun?',
        type: 'character.rested',
      );
    }
    if (RegExp(r'brunnen|schlüssel|schluessel').hasMatch(words) &&
        current.facts['keyFound'] == 'true') {
      return _commit(
        campaign,
        current,
        current.facts['questCompleted'] == 'true'
            ? 'Du hast den Messingschlüssel bereits gefunden und im Schrein verbraucht. Das Waldlicht leuchtet; am Brunnen liegt kein weiterer Schlüssel. Was möchtest du tun?'
            : 'Den Messingschlüssel vom Brunnen trägst du bereits im Inventar. Am Brunnen liegt kein weiterer Schlüssel. Der Waldpfad führt zum Schrein; was möchtest du tun?',
      );
    }
    if (RegExp(
          r'brunnen|schlüssel|schluessel|glitzer|steine.*untersuch',
        ).hasMatch(words) &&
        current.facts['keyFound'] != 'true') {
      final hero = current.hero.copyWith(
        inventory: [
          ...current.hero.inventory,
          const InventoryItem(
            id: 'brass-key',
            name: 'Messingschlüssel',
            description: 'Öffnet den alten Waldschrein.',
          ),
        ],
      );
      return _commit(
        campaign,
        current.copyWith(
          hero: hero,
          facts: {
            ...current.facts,
            'keyFound': 'true',
            'schlüssel': 'Am Dorfbrunnen wurde ein Messingschlüssel gefunden.',
          },
        ),
        '${hero.name}, zwischen den Steinen findest du einen Messingschlüssel mit einer Blattgravur. Mira erkennt das Zeichen des alten Schreins. Der Schlüssel liegt jetzt in deinem Inventar. Was möchtest du tun?',
        type: 'inventory.itemAdded',
        payload: {'itemId': 'brass-key'},
      );
    }
    if (RegExp(r'mira|hüterin|hueterin|befrag|spreche|reden').hasMatch(words)) {
      // Dialogue reflects only confirmed quest flags. Repeated conversations
      // must not reset progress or send the hero after consumed items.
      final answer = current.facts['questCompleted'] == 'true'
          ? 'Mira dankt dir für das erneuerte Waldlicht. Der Schrein ist '
              'bereits geöffnet, und du hast ihren Auftrag erfüllt. '
              'Was möchtest du als Nächstes unternehmen?'
          : current.facts['guardianDefeated'] == 'true'
          ? 'Mira weiß, dass der Dornenwächter besiegt ist. '
              '${current.facts['keyFound'] == 'true'
                  ? 'Mit dem gefundenen Messingschlüssel kannst du den Schrein öffnen.'
                  : 'Der Messingschlüssel am Dorfbrunnen fehlt dir noch.'} '
              'Wie möchtest du fortfahren?'
          : current.facts['keyFound'] == 'true'
          ? 'Mira erkennt den Messingschlüssel, den du bereits gefunden hast. '
              'Jetzt erwartet dich der Dornenwächter am Waldschrein. '
              'Wie möchtest du vorgehen?'
          : 'Mira lächelt dir zu. Der Schrein liegt jenseits des Waldpfades; '
              'ein Dornenwächter versperrt den Zugang. Suche den '
              'Messingschlüssel am Brunnen und bringe das Licht zurück. '
              'Was möchtest du tun?';
      return _commit(campaign, current, answer);
    }
    if (RegExp(
          r'schrein|tor|öffne|oeffne|entzünd|entzuend|licht',
        ).hasMatch(words) &&
        current.facts['guardianDefeated'] == 'true') {
      if (current.facts['questCompleted'] == 'true') {
        return _commit(
          campaign,
          current,
          'Das Waldlicht leuchtet bereits. Mira und die Bewohner erinnern sich an deine Hilfe. Der Schrein bleibt geöffnet; was möchtest du nun erkunden?',
        );
      }
      final key = current.hero.inventory.where((e) => e.id == 'brass-key');
      if (key.isEmpty) {
        return _commit(
          campaign,
          current,
          'Das Tor ist sicher, aber verschlossen. Dir fehlt der Messingschlüssel vom Dorfbrunnen. Was möchtest du tun?',
        );
      }
      final hero = current.hero.copyWith(
        inventory: current.hero.inventory
            .where((e) => e.id != 'brass-key')
            .toList(),
      );
      return _commit(
        campaign,
        current.copyWith(
          hero: hero,
          scene: 'Im offenen Waldschrein strahlt das erneuerte Waldlicht.',
          facts: {
            ...current.facts,
            'questCompleted': 'true',
            'waldlicht':
                'Das Waldlicht wurde erneuert. Der Messingschlüssel wurde im Schrein verbraucht.',
          },
          quests: current.quests
              .map(
                (e) =>
                    e.id == 'waldlicht' ? e.copyWith(status: 'completed') : e,
              )
              .toList(),
        ),
        '${hero.name}, der Messingschlüssel löst sich im Schloss in goldenen Staub auf. Das Waldlicht erwacht, und warme Strahlen durchziehen den Sternenwald. Du hast Miras Auftrag erfüllt. Wohin soll deine nächste Reise führen?',
        type: 'quest.completed',
        payload: {'questId': 'waldlicht', 'consumedItemId': 'brass-key'},
      );
    }
    if (RegExp(
          r'wald|ruine|schrein|wächter|waechter|angreif|attackier|greif\w*.*\ban(?:[.!?]|$)|kämpf|kaempf|schieß|schies',
        ).hasMatch(words) &&
        current.facts['guardianDefeated'] != 'true') {
      if (!current.hero.isComplete) {
        return _commit(
          campaign,
          current,
          'Am Waldrand hältst du inne. Für den Dornenwächter benötigen wir einen bestätigten Charakterbogen.',
          type: 'rules.blocked',
        );
      }
      final heroInit = dice.check(
        modifier: RulesEngine.initiativeBonus(current.hero),
      );
      final foeInit = dice.check(modifier: 0);
      var next = current.copyWith(
        scene: 'Am alten Waldschrein erhebt sich ein Dornenwächter.',
        facts: {...current.facts, 'location': 'Waldschrein'},
        places: current.places.any((e) => e.id == 'shrine')
            ? current.places
            : [
                ...current.places,
                const Place(
                  id: 'shrine',
                  name: 'Waldschrein',
                  description: 'Alte Steinbögen im Sternenwald.',
                ),
              ],
        encounter: Encounter(
          id: _id('encounter'),
          enemyName: 'Dornenwächter',
          enemyHitPoints:
              int.tryParse(current.facts['guardianHitPoints'] ?? '') ?? 10,
          enemyMaxHitPoints: 10,
          heroInitiative: heroInit.total,
          enemyInitiative: foeInit.total,
          movementRemaining: current.hero.speed!,
        ),
      );
      var narration =
          '${current.hero.name}, ein Dornenwächter erhebt sich vor dem Schrein. Deine Initiative ist ${heroInit.total}, seine ${foeInit.total}. ';
      final details = <String, dynamic>{
        'heroInitiative': heroInit.toJson(),
        'enemyInitiative': foeInit.toJson(),
      };
      if (foeInit.total > heroInit.total) {
        final turn = _enemyTurn(next, advanceRound: false);
        next = turn.campaign;
        narration += '${turn.narration} ';
        details['enemyTurn'] = turn.details;
      }
      narration += next.hero.hitPoints == 0
          ? 'Du bist bewusstlos; bitte fordere einen Todesrettungswurf an.'
          : 'Du kannst angreifen, ausweichen, einen Trank trinken oder fliehen. Was tust du?';
      return _commit(
        campaign,
        next,
        narration,
        type: 'combat.started',
        payload: details,
      );
    }
    if (RegExp(
      r'würfel|wuerfel|probe|untersuch|suche|wahrnehm',
    ).hasMatch(words)) {
      if (!current.hero.isComplete) {
        return _commit(
          campaign,
          current,
          'Bitte vervollständige vor einer Probe den Charakterbogen.',
          type: 'rules.blocked',
        );
      }
      final bonus =
          RulesEngine.abilityModifier(current.hero.abilities['wisdom']!) +
          (current.hero.skills.contains('Wahrnehmung')
              ? RulesEngine.proficiencyBonus(current.hero.level)
              : 0);
      return _commit(
        campaign,
        current.copyWith(
          pendingRoll: PendingRoll(
            id: _id('roll'),
            type: 'perception',
            modifier: bonus,
            difficulty: 10,
          ),
        ),
        'Bitte würfle einen W20 für deine Wahrnehmung. Dein bestätigter Modifikator ist ${_signed(bonus)}; die Schwierigkeit beträgt 10.',
        type: 'roll.requested',
      );
    }
    final completed = current.facts['questCompleted'] == 'true';
    return _commit(
      campaign,
      current,
      '${current.hero.name}, ${completed
          ? 'das erneuerte Waldlicht begleitet deinen nächsten Schritt'
          : current.facts['keyFound'] == 'true'
          ? 'der Messingschlüssel in deiner Tasche erinnert dich an Miras Bitte'
          : 'der Brunnen glitzert, während Mira zum Waldpfad blickt'}. '
      'Du beschreibst: $text Deine Entscheidung ist im Tagebuch festgehalten. Möchtest du etwas untersuchen, mit Mira sprechen oder zum Schrein gehen?',
    );
  }

  GameUpdate _arescan(Campaign before, Campaign current, String words) {
    if (RegExp(
      r'angreif|attackier|greif\w*.*\ban(?:[.!?]|$)|schieß|schies|kämpf|töte|heile',
    ).hasMatch(words)) {
      return _commit(
        before,
        current,
        'Die bisherigen Treffer und der Sturz bleiben historische Erzähldaten. Die Gegnerwerte des Schattenritters sind noch nicht bestätigt. Eine neue Regelaktion benötigt zusätzlich einen geprüften Gegnerbogen; du kannst ihn untersuchen oder befragen.',
        type: 'rules.blocked',
      );
    }
    if (words.contains('amulett') &&
        RegExp(r'nimm|nehme|abnehm|einsteck').hasMatch(words)) {
      if (current.facts['amuletTaken'] == 'true') {
        return _commit(
          before,
          current,
          'Das rote Amulett befindet sich bereits in deinem Inventar. Sein Leuchten pulsiert im Takt eines fernen Herzschlags. Was möchtest du tun?',
        );
      }
      return _commit(
        before,
        current.copyWith(
          hero: current.hero.copyWith(
            inventory: [
              ...current.hero.inventory,
              const InventoryItem(
                id: 'red-amulet',
                name: 'Rotes Amulett',
                description: 'Zeichen des Schattenkönigs; Wirkung unbekannt.',
              ),
            ],
          ),
          scene:
              'Arescan steht mit der geretteten Elfenmagierin beim Brunnen von Silberhain. Der verletzte Schattenritter liegt vor ihnen; Arescan trägt das rote Amulett.',
          facts: {
            ...current.facts,
            'amuletTaken': 'true',
            'amulett':
                'Arescan nahm das rote Amulett an sich. Seine Wirkung ist unbekannt.',
          },
        ),
        'Arescan, du nimmst das rote Amulett vorsichtig an dich. Die Elfin warnt dich vor seiner unbekannten Magie. Es ist jetzt in deinem Inventar; was möchtest du tun?',
        type: 'inventory.itemAdded',
        payload: {'itemId': 'red-amulet'},
      );
    }
    if (RegExp(r'elf|magierin|befrag').hasMatch(words)) {
      return _commit(
        before,
        current.copyWith(
          facts: {
            ...current.facts,
            'elfenwarnung':
                'Die Elfenmagierin warnt davor, das unbekannte rote Amulett zu aktivieren.',
          },
        ),
        'Arescan, die Elfenmagierin zeigt auf das rote Zeichen. Der Schattenkönig verbirgt seine Boten hinter solchen Amuletten, sagt sie. Sie bittet dich, es vorerst nicht zu aktivieren. Was möchtest du tun?',
      );
    }
    if (RegExp(
      r'verhör|verhoer|frage|schattenritter|untersuch',
    ).hasMatch(words)) {
      return _commit(
        before,
        current,
        'Arescan, der verletzte Schattenritter liegt weiterhin vor dir. ${current.facts['amuletTaken'] == 'true' ? 'Das rote Amulett leuchtet in deiner Tasche.' : 'Das rote Amulett überstrahlt seine Brust.'} Seine genauen Lebenspunkte sind unbekannt; die Elfin hält vorsichtig Abstand. Was möchtest du fragen oder untersuchen?',
      );
    }
    return _commit(
      before,
      current,
      'Arescan, das Portal schimmert über dem Marktplatz von Silberhain. Die gerettete Elfenmagierin bleibt bei dir, und der verletzte Schattenritter liegt beim Brunnen. Deine Entscheidung ist vermerkt. Was möchtest du tun?',
    );
  }

  GameUpdate _combatAction(Campaign before, Campaign current, String words) {
    final encounter = current.encounter!;
    if (RegExp(
      r'angreif|attackier|greif\w*.*\ban(?:[.!?]|$)|schieß|schies|schlag|hieb|bogen|schwert',
    ).hasMatch(words)) {
      final bonus = RulesEngine.attackBonus(current.hero);
      return _commit(
        before,
        current.copyWith(
          pendingRoll: PendingRoll(
            id: _id('roll'),
            type: 'attack',
            modifier: bonus,
            difficulty: encounter.enemyArmorClass,
            targetId: encounter.id,
            targetName: encounter.enemyName,
          ),
        ),
        '${current.hero.name}, würfle einen W20 für deinen Angriff auf den ${encounter.enemyName}. Dein Angriffsbonus ist ${_signed(bonus)}; seine Rüstungsklasse beträgt ${encounter.enemyArmorClass}.',
        type: 'roll.requested',
      );
    }
    if (RegExp(r'flieh|flucht|wegrenn').hasMatch(words)) {
      return _commit(
        before,
        current.copyWith(
          pendingRoll: PendingRoll(
            id: _id('roll'),
            type: 'escape',
            modifier: RulesEngine.initiativeBonus(current.hero),
            difficulty: 10,
          ),
        ),
        'Bitte würfle einen W20 für die Flucht durch die Dornen. Die Schwierigkeit beträgt 10.',
      );
    }
    if (RegExp(r'heiltrank|trank.*trink|trink.*trank').hasMatch(words)) {
      return _drinkPotion(before, current);
    }
    if (RegExp(r'ausweich|verteidig|warten|zug beenden').hasMatch(words)) {
      final dodge = RegExp(r'ausweich|verteidig').hasMatch(words);
      final turn = _enemyTurn(current, disadvantage: dodge);
      return _commit(
        before,
        turn.campaign,
        '${dodge ? 'Du weichst aus; der Gegner greift mit Nachteil an.' : 'Du beendest deinen Zug.'} ${turn.narration} ${_nextInstruction(turn.campaign)}',
        type: 'combat.turnCompleted',
        payload: turn.details,
      );
    }
    if (RegExp(r'beweg|lauf|geh').hasMatch(words)) {
      final amount =
          int.tryParse(
            RegExp(r'(\d+)\s*(?:m|meter)').firstMatch(words)?.group(1) ?? '',
          ) ??
          3;
      if (amount > encounter.movementRemaining) {
        return _commit(
          before,
          current,
          'Für diese Bewegung reichen die verbleibenden ${encounter.movementRemaining} Meter nicht aus. Deine Aktion ist weiterhin verfügbar.',
          type: 'rules.blocked',
        );
      }
      return _commit(
        before,
        current.copyWith(
          encounter: encounter.copyWith(
            movementRemaining: encounter.movementRemaining - amount,
          ),
        ),
        'Du bewegst dich $amount Meter. In diesem Zug bleiben ${encounter.movementRemaining - amount} Meter; deine Aktion ist verfügbar.',
        type: 'combat.moved',
        payload: {'meters': amount},
      );
    }
    return _commit(
      before,
      current,
      'Der ${encounter.enemyName} wartet auf deine nächste Handlung. Du kannst angreifen, ausweichen, einen Heiltrank trinken oder fliehen. Regelaktionen werden erst nach einer bestätigten Probe angewendet.',
    );
  }

  GameUpdate resolveRoll(
    Campaign campaign, {
    int? natural,
    int? total,
    String? input,
  }) {
    final pending = campaign.pendingRoll;
    if (pending == null) throw StateError('Es ist keine Probe offen.');
    final result = dice.check(
      modifier: pending.modifier,
      natural: natural,
      total: total,
    );
    var next = campaign.copyWith(pendingRoll: null);
    if (input != null) {
      next = next.copyWith(
        messages: [
          ...next.messages,
          NarrativeMessage(
            id: _id('message'),
            role: 'player',
            text: input,
            timestamp: _clock(),
          ),
        ],
      );
    }
    final payload = <String, dynamic>{
      'request': pending.toJson(),
      'roll': result.toJson(),
    };
    final label = result.natural == null
        ? 'Gesamtergebnis ${result.total} (Bonus bereits enthalten)'
        : 'Naturwurf ${result.natural} ${_signed(result.modifier)} = ${result.total}';
    var narration = '$label. ';
    if (pending.type == 'death') {
      if (result.natural == null) {
        throw ArgumentError(
          'Todesrettung benötigt den natürlichen W20, kein Gesamtergebnis.',
        );
      }
      next = next.copyWith(
        hero: RulesEngine.deathSave(next.hero, result.natural!),
      );
      narration += next.hero.isDead
          ? 'Dein Held stirbt; das Ereignis bleibt im Tagebuch.'
          : next.hero.hitPoints! > 0
          ? 'Du kommst mit einem Trefferpunkt wieder zu Bewusstsein. Was tust du?'
          : next.hero.conditions.contains(RulesEngine.stable)
          ? 'Du bist stabilisiert und bleibst bewusstlos. Du benötigst Hilfe.'
          : 'Todesrettung: ${next.hero.deathSuccesses} Erfolge, ${next.hero.deathFailures} Fehlschläge. Fordere deinen nächsten Rettungswurf an.';
    } else if (pending.type == 'attack') {
      final foe = next.encounter;
      if (foe == null || foe.id != pending.targetId || foe.isFinished) {
        throw StateError('Das Angriffsziel ist nicht mehr gültig.');
      }
      final outcome = RulesEngine.attack(
        roll: result,
        armorClass: foe.enemyArmorClass,
      );
      if (outcome.hit) {
        final base = dice.roll(next.hero.weaponDamage);
        final extra = outcome.critical
            ? dice.roll(next.hero.weaponDamage)
            : null;
        final damage = RulesEngine.weaponDamage(
          next.hero,
          baseRoll: base,
          criticalExtra: extra,
        );
        final hp = RulesEngine.remainingHitPoints(
          hitPoints: foe.enemyHitPoints,
          damage: damage,
        );
        payload['damageRoll'] = base.toJson();
        payload['criticalExtra'] = extra?.toJson();
        payload['damage'] = damage;
        next = next.copyWith(
          encounter: foe.copyWith(enemyHitPoints: hp, actionUsed: true),
          facts: {...next.facts, 'guardianHitPoints': '$hp'},
        );
        narration +=
            '${outcome.critical ? 'Ein kritischer Treffer! ' : ''}Du verursachst $damage Schaden; der ${foe.enemyName} hat noch $hp Trefferpunkte. ';
      } else {
        next = next.copyWith(encounter: foe.copyWith(actionUsed: true));
        narration += 'Dein Angriff verfehlt den ${foe.enemyName}. ';
      }
      if (next.encounter!.isFinished) {
        next = next.copyWith(
          facts: {
            ...next.facts,
            'guardianDefeated': 'true',
            'dornenwächter':
                'Der Dornenwächter wurde im bestätigten Kampf überwunden.',
          },
        );
        narration +=
            'Der Dornenwächter zerfällt in Blätter. Der Weg zum Schrein ist frei. Was möchtest du tun?';
      } else {
        final turn = _enemyTurn(next);
        next = turn.campaign;
        payload['enemyTurn'] = turn.details;
        narration += '${turn.narration} ${_nextInstruction(next)}';
      }
    } else if (pending.type == 'escape') {
      if (result.total >= pending.difficulty) {
        next = next.copyWith(
          encounter: null,
          scene: 'Du bist zum sicheren Dorf Mooswacht zurückgekehrt.',
          facts: {...next.facts, 'location': 'Mooswacht'},
        );
        narration +=
            'Du entkommst den Dornen und erreichst das Dorf. Der Wächter bewacht weiterhin den Schrein. Was möchtest du tun?';
      } else {
        final turn = _enemyTurn(next);
        next = turn.campaign;
        payload['enemyTurn'] = turn.details;
        narration +=
            'Die Dornen halten dich auf. ${turn.narration} ${_nextInstruction(next)}';
      }
    } else if (pending.type == 'perception') {
      if (result.total >= pending.difficulty) {
        next = next.copyWith(
          facts: {
            ...next.facts,
            'schreinspur':
                'Blattgravuren verbinden den Dorfbrunnen mit dem Waldschrein.',
          },
        );
        narration +=
            'Du erkennst Blattgravuren: Sie verbinden den Dorfbrunnen mit dem Waldschrein. Was möchtest du tun?';
      } else {
        narration +=
            'Im Rascheln der Blätter entgeht dir ein genauer Hinweis. Du kannst den Brunnen weiter untersuchen oder Mira fragen. Was möchtest du tun?';
      }
    } else {
      throw StateError('Unbekannte Probeart.');
    }
    return _commit(
      campaign,
      next,
      narration,
      type: 'roll.resolved',
      payload: payload,
    );
  }

  GameUpdate _drinkPotion(Campaign before, Campaign current) {
    final potion = current.hero.inventory.where((e) => e.id == 'potion');
    if (potion.isEmpty) {
      return _commit(
        before,
        current,
        'Du hast keinen Heiltrank mehr im Inventar. Du kannst außerhalb eines Kampfes sicher rasten.',
        type: 'rules.blocked',
      );
    }
    final roll = dice.roll('2d4+2');
    final items = current.hero.inventory
        .expand<InventoryItem>(
          (e) => e.id != 'potion'
              ? [e]
              : e.quantity > 1
              ? [
                  InventoryItem(
                    id: e.id,
                    name: e.name,
                    quantity: e.quantity - 1,
                    description: e.description,
                  ),
                ]
              : [],
        )
        .toList();
    var next = current.copyWith(
      hero: RulesEngine.heal(
        current.hero,
        roll.total,
      ).copyWith(inventory: items),
    );
    var narration =
        'Du trinkst einen Heiltrank. Die Heilung beträgt ${roll.total}; du hast jetzt ${next.hero.hitPoints} von ${next.hero.maxHitPoints} Trefferpunkten. ';
    final payload = <String, dynamic>{
      'healingRoll': roll.toJson(),
      'consumedItemId': 'potion',
    };
    if (next.encounter != null && !next.encounter!.isFinished) {
      final turn = _enemyTurn(next);
      next = turn.campaign;
      payload['enemyTurn'] = turn.details;
      narration += '${turn.narration} ${_nextInstruction(next)}';
    } else {
      narration += 'Was möchtest du tun?';
    }
    return _commit(
      before,
      next,
      narration,
      type: 'character.healed',
      payload: payload,
    );
  }

  _EnemyTurn _enemyTurn(
    Campaign campaign, {
    bool disadvantage = false,
    bool advanceRound = true,
  }) {
    final foe = campaign.encounter!;
    final result = dice.check(
      modifier: foe.enemyAttackBonus,
      disadvantage: disadvantage,
    );
    final outcome = RulesEngine.attack(
      roll: result,
      armorClass: campaign.hero.armorClass!,
    );
    var hero = campaign.hero;
    var narration =
        'Der ${foe.enemyName} greift an: ${result.total} gegen deine Rüstungsklasse ${hero.armorClass}. ';
    final details = <String, dynamic>{
      'attackRoll': result.toJson(),
      'hit': outcome.hit,
    };
    if (outcome.hit) {
      final damageRoll = dice.roll(foe.enemyDamage);
      final extra = outcome.critical ? dice.roll(foe.enemyDamage) : null;
      final damage =
          damageRoll.total + (extra == null ? 0 : extra.total - extra.modifier);
      hero = RulesEngine.damage(hero, damage, critical: outcome.critical);
      details['damageRoll'] = damageRoll.toJson();
      details['criticalExtra'] = extra?.toJson();
      details['damage'] = damage;
      narration +=
          'Du erleidest $damage Schaden und hast noch ${hero.hitPoints} Trefferpunkte.';
    } else {
      narration += 'Seine Dornen verfehlen dich.';
    }
    return _EnemyTurn(
      campaign.copyWith(
        hero: hero,
        encounter: foe.copyWith(
          round: foe.round + (advanceRound ? 1 : 0),
          activeParticipant: 'hero',
          movementRemaining: hero.speed!,
          actionUsed: false,
          bonusActionUsed: false,
          reactionUsed: false,
        ),
      ),
      narration,
      details,
    );
  }

  String _nextInstruction(Campaign campaign) => campaign.hero.isDead
      ? 'Dein Held ist gestorben.'
      : campaign.hero.hitPoints == 0
      ? 'Du bist bewusstlos. Fordere einen Todesrettungswurf an.'
      : 'Dein nächster Zug beginnt. Was möchtest du tun?';
  String _signed(int number) => number >= 0 ? '+$number' : '$number';
  int? _spokenNumber(String text) {
    final digits = RegExp(r'\b(-?\d{1,4})\b').firstMatch(text);
    if (digits != null) return int.tryParse(digits.group(1)!);
    const numbers = {
      'eins': 1,
      'eine eins': 1,
      'zwei': 2,
      'drei': 3,
      'vier': 4,
      'fünf': 5,
      'sechs': 6,
      'sieben': 7,
      'acht': 8,
      'neun': 9,
      'zehn': 10,
      'elf': 11,
      'zwölf': 12,
      'dreizehn': 13,
      'vierzehn': 14,
      'fünfzehn': 15,
      'sechzehn': 16,
      'siebzehn': 17,
      'achtzehn': 18,
      'neunzehn': 19,
      'zwanzig': 20,
    };
    for (final e in numbers.entries) {
      if (RegExp('(^|\\s)${e.key}(\\s|[.!?]|\$)').hasMatch(text)) {
        return e.value;
      }
    }
    return null;
  }

  GameUpdate _commit(
    Campaign before,
    Campaign next,
    String narration, {
    String type = 'narrative.turn',
    Map<String, dynamic> payload = const {},
  }) {
    final confirmed = next.copyWith(
      revision: before.revision + 1,
      messages: [
        ...next.messages,
        NarrativeMessage(
          id: _id('message'),
          role: 'gm',
          text: narration,
          timestamp: _clock(),
        ),
      ],
    );
    final state = confirmed.copyWith(events: const []).toJson();
    // The checkpoint contains no nested event journal, so replay remains linear.
    final event = GameEvent(
      id: _id('event'),
      campaignId: before.id,
      sessionId: before.sessionId,
      timestamp: _clock(),
      type: type,
      entities: [before.hero.id],
      payload: {
        ...payload,
        'revision': confirmed.revision,
        'stateAfter': state,
      },
    );
    final result = confirmed.copyWith(events: [...before.events, event]);
    Campaign.fromJson(result.toJson());
    return GameUpdate(campaign: result, events: [event]);
  }
}

class _EnemyTurn {
  const _EnemyTurn(this.campaign, this.narration, this.details);
  final Campaign campaign;
  final String narration;
  final Map<String, dynamic> details;
}

/// Explicitly separates scene context, session recap and persistent world facts.
class MemoryEngine {
  /// Recognizes explicit requests for established adventure memories.
  /// Free player actions mentioning historical nouns are not recall commands.
  static bool isRecallRequest(String text) {
    final normalized = _memoryNormalize(text);
    return RegExp(
      r'\b(?:erinner\w*|bisher\w*|tagebuch|'
      r'zusammenfass\w*|rueckblick)\b',
    ).hasMatch(normalized) ||
        RegExp(r'\b(?:meine|unsere|bisherige)\s+geschichte\b')
            .hasMatch(normalized) ||
        RegExp(r'\bwas\s+weisst\s+du\b').hasMatch(normalized) ||
        RegExp(r'\berzaehl\w*\s+(?:mir\s+)?(?:etwas\s+)?(?:ueber|von)\b')
            .hasMatch(normalized);
  }

  /// Selects confirmed memories by lexical relevance without model inference.
  /// Dialogue and generated narration are deliberately never memory sources.
  /// With matchingOnly, nonmatching memories are excluded from topical recall.
  static List<String> retrieve(
    Campaign campaign,
    String action, {
    int limit = 20,
    int maxCharacters = 400,
    bool matchingOnly = false,
  }) {
    if (limit < 1 || limit > 20 || maxCharacters < 40 || maxCharacters > 400) {
      throw const FormatException(
        'Gedächtnisabruf benötigt 1 bis 20 Einträge mit 40 bis 400 Zeichen.',
      );
    }
    final query = _memoryTokens(action);
    final candidates =
        <({String text, String identity, int score, int order})>[];
    void add(
      String label,
      String description, {
      required int priority,
      String? identity,
    }) {
      final titleTokens = _memoryTokens(label);
      final bodyTokens = _memoryTokens(description);
      int matches(Set<String> words) => query.where((token) {
        if (words.contains(token)) return true;
        // German compounds and inflections: Schlüssel / Messingschlüssel,
        // Amulett / Amuletts. Short words require an exact token match.
        return token.length >= 4 &&
            words.any((word) => word.startsWith(token) || word.endsWith(token));
      }).length;
      final titleHits = matches(titleTokens);
      final bodyHits = matches(bodyTokens);
      // Targeted recall must not fill missing matches with unrelated facts.
      // An empty topical query is a general recap and uses the normal ranking.
      if (matchingOnly && query.isNotEmpty && titleHits + bodyHits == 0) {
        return;
      }
      final score =
          priority +
          (titleHits + bodyHits > 0 ? 1000 : 0) +
          titleHits * 200 +
          bodyHits * 40;
      final text = description.trim().isEmpty
          ? label.trim()
          : '${label.trim()}${label.trim().endsWith(':') ? ' ' : '. '}${description.trim()}';
      if (text.isEmpty) return;
      candidates.add((
        text: text,
        identity: _memoryNormalize(identity ?? text),
        score: score,
        order: candidates.length,
      ));
    }

    for (final entry in campaign.facts.entries) {
      if (entry.value.trim().isNotEmpty) {
        final value = _memoryNormalize(entry.value);
        // Flags, numbers and short labels only have meaning with their key.
        // Longer, self-contained sentences can be deduplicated across keys.
        final selfContained =
            value.length >= 20 && value.split(' ').length >= 3;
        add(
          'Fakt ${entry.key}:',
          entry.value,
          priority: 0,
          identity: selfContained
              ? entry.value
              : '${entry.key}: ${entry.value}',
        );
      }
    }
    // Full snapshots can contain many unrelated topics; do not insert them
    // into a narrowly targeted recall merely because a name matches once.
    if (!matchingOnly || query.isEmpty) {
      for (final recap in campaign.sessionRecaps.reversed) {
        add('Sitzungsrückblick: ${recap.title}', recap.summary, priority: 90);
      }
    }
    for (final thread in campaign.storyThreads) {
      final status = switch (thread.status) {
        'open' => 'offen',
        'resolved' => 'gelöst',
        'abandoned' => 'aufgegeben',
        _ => thread.status,
      };
      add('Handlungsstrang $status: ${thread.title}',
          thread.description, priority: thread.status == 'open' ? 210 : 70);
    }
    for (final note in campaign.npcRelationshipNotes.reversed) {
      final npc = campaign.npcs.where((entry) => entry.id == note.npcId);
      if (npc.isEmpty) continue;
      add('Beziehung zu ${npc.first.name}: ${note.relationship}',
          note.note, priority: 220);
    }
    for (final item in campaign.hero.inventory) {
      add(
        'Inventar (Anzahl ${item.quantity}): ${item.name}',
        item.description,
        priority: 300,
      );
    }
    for (final quest in campaign.quests) {
      final status = switch (quest.status) {
        'completed' => 'abgeschlossen',
        'failed' => 'gescheitert',
        'active' => 'aktiv',
        _ => quest.status,
      };
      add(
        'Quest $status: ${quest.title}',
        quest.description,
        priority: quest.status == 'active' ? 200 : 400,
      );
    }
    for (final npc in campaign.npcs) {
      add(
        'NPC ${npc.alive ? 'lebendig' : 'tot'}: ${npc.name}',
        'Beziehung: ${npc.relationship}. ${npc.description}',
        priority: npc.alive ? 100 : 500,
      );
    }
    for (final place in campaign.places) {
      add('Ort: ${place.name}', place.description, priority: 50);
    }
    candidates.sort((a, b) {
      final score = b.score.compareTo(a.score);
      return score == 0 ? a.order.compareTo(b.order) : score;
    });
    final seen = <String>{};
    final displayed = <String>{};
    final results = <String>[];
    for (final candidate in candidates) {
      if (!seen.add(candidate.identity)) continue;
      final text = _memoryTruncate(candidate.text, maxCharacters);
      if (!displayed.add(_memoryNormalize(text))) continue;
      results.add(text);
      if (results.length == limit) break;
    }
    return List.unmodifiable(results);
  }

  /// Human-readable confirmed summary; no unverified chat or model prose.
  static String buildSessionSummary(Campaign campaign) {
    String questStatus(String status) => switch (status) {
      'active' => 'offen',
      'completed' => 'abgeschlossen',
      'failed' => 'gescheitert',
      _ => status,
    };
    String threadStatus(String status) => switch (status) {
      'open' => 'offen',
      'resolved' => 'gelöst',
      'abandoned' => 'aufgegeben',
      _ => status,
    };
    final lines = <String>[
      'Kampagne: ${campaign.name}.',
      'Held: ${campaign.hero.name}.',
      if (campaign.quests.isNotEmpty)
        'Quests: ${campaign.quests.map((q) =>
            '${q.title} (${questStatus(q.status)})').join('; ')}.',
      if (campaign.npcs.isNotEmpty)
        'Bekannte NPCs: ${campaign.npcs.map((n) =>
            '${n.name} (${n.alive ? 'lebendig' : 'tot'}, ${n.relationship})').join('; ')}.',
      if (campaign.storyThreads.isNotEmpty)
        'Handlungsstränge: ${campaign.storyThreads.map((t) =>
            '${t.title} (${threadStatus(t.status)})').join('; ')}.',
      if (campaign.facts.isNotEmpty)
        'Bestätigte Fakten: ${campaign.facts.entries.map((f) =>
            '${f.key}: ${f.value}').join('; ')}.',
    ];
    final whole = lines.join('\n');
    // Both import validation and JSON limits use UTF-16 code units. Avoid
    // splitting surrogate pairs when truncating an unusually long recap.
    final result = StringBuffer();
    var units = 0;
    for (final rune in whole.runes) {
      final size = rune > 0xffff ? 2 : 1;
      if (units + size > 2400) break;
      result.writeCharCode(rune);
      units += size;
    }
    return result.toString();
  }

  static Map<String, dynamic> context(Campaign campaign) => {
    'shortTerm': {
      'scene': campaign.scene,
      'recentMessages': campaign.messages
          .skip(campaign.messages.length > 6 ? campaign.messages.length - 6 : 0)
          .map((e) => e.toJson())
          .toList(),
    },
    'session': {
      'sessionId': campaign.sessionId,
      'confirmedTurns': campaign.revision,
      'summary': campaign.facts.values.join(' '),
    },
    'longTerm': {
      'facts': campaign.facts,
      'quests': campaign.quests.map((e) => e.toJson()).toList(),
      'sessionRecaps': campaign.sessionRecaps.map((e) => e.toJson()).toList(),
      'storyThreads': campaign.storyThreads.map((e) => e.toJson()).toList(),
      'npcRelationshipNotes':
          campaign.npcRelationshipNotes.map((e) => e.toJson()).toList(),
      'npcs': campaign.npcs.map((e) => e.toJson()).toList(),
      'inventory': campaign.hero.inventory.map((e) => e.toJson()).toList(),
    },
  };

  static Campaign replay(Campaign seed, List<GameEvent> journal) {
    var state = seed;
    final seen = {for (final event in seed.events) event.id: event};
    var events = [...seed.events];
    for (final event in journal) {
      if (event.campaignId != seed.id) {
        throw const FormatException('Fremdes Kampagnenereignis.');
      }
      final prior = seen[event.id];
      if (prior != null) {
        if (_canonicalJson(prior.toJson()) != _canonicalJson(event.toJson())) {
          throw const FormatException(
            'Ereignis-ID mit verändertem Inhalt wiederverwendet.',
          );
        }
        continue;
      }
      seen[event.id] = event;
      final raw = event.payload['stateAfter'];
      if (raw is Map<String, dynamic>) {
        final restored = Campaign.fromJson(raw);
        if (restored.id != seed.id || restored.revision != state.revision + 1) {
          throw const FormatException(
            'Lücke oder falsche Reihenfolge im Ereignisprotokoll.',
          );
        }
        state = restored;
      }
      events = [...events, event];
      state = state.copyWith(events: events);
    }
    return state;
  }
}

/// Object key order can change in storage; list order and number types cannot.
String _canonicalJson(Object? value) {
  Object? ordered(Object? item) {
    if (item is Map) {
      final keys = item.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: ordered(item[key])};
    }
    if (item is List) return item.map(ordered).toList();
    return item;
  }

  return jsonEncode(ordered(value));
}

String _memoryNormalize(String text) => text
    .toLowerCase()
    .replaceAll('ä', 'ae')
    .replaceAll('ö', 'oe')
    .replaceAll('ü', 'ue')
    .replaceAll('ß', 'ss')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

Set<String> _memoryTokens(String text) {
  const stopWords = {
    'ich',
    'du',
    'dich',
    'an',
    'erinnere',
    'erinnerst',
    'erinnern',
    'erinnerung',
    'erinnerungen',
    'erzaehl',
    'erzaehle',
    'erzaehlen',
    'erzaehlst',
    'weisst',
    'weiss',
    'wissen',
    'weissst',
    'bisher',
    'bisherige',
    'bisherigen',
    'bisheriges',
    'geschichte',
    'tagebuch',
    'zusammenfassung',
    'zusammenfassen',
    'zusammen',
    'fass',
    'fasse',
    'rueckblick',
    'unsere',
    'unser',
    'unserer',
    'passiert',
    'geschehen',
    'daran',
    'dazu',
    'darueber',
    'der',
    'die',
    'das',
    'ein',
    'eine',
    'einen',
    'einem',
    'einer',
    'und',
    'oder',
    'mit',
    'den',
    'dem',
    'des',
    'ist',
    'sind',
    'war',
    'waren',
    'wird',
    'werden',
    'zum',
    'zur',
    'von',
    'fuer',
    'auf',
    'aus',
    'bei',
    'ueber',
    'unter',
    'nach',
    'vor',
    'als',
    'was',
    'wie',
    'wer',
    'bitte',
    'moechte',
    'moechtest',
    'will',
    'kann',
    'koennte',
    'kannst',
    'habe',
    'hast',
    'hat',
    'mich',
    'mir',
    'mein',
    'meine',
    'meinen',
    'seine',
    'ihr',
    'ihre',
    'uns',
    'euch',
    'sich',
    'noch',
    'wieder',
    'jetzt',
    'dann',
    'dort',
    'hier',
    'nun',
    'auch',
    'man',
    'diese',
    'dieser',
    'dieses',
    'gehe',
    'tun',
    'frage',
    'fragen',
  };
  return RegExp(r'[a-z0-9]+')
      .allMatches(_memoryNormalize(text))
      .map((match) => match.group(0)!)
      .where((token) => token.length > 2 && !stopWords.contains(token))
      .toSet();
}

String _memoryTruncate(String text, int maximum) {
  if (text.length <= maximum) return text;
  var end = maximum - 1;
  final last = text.codeUnitAt(end - 1);
  if (last >= 0xD800 && last <= 0xDBFF) end--;
  return '${text.substring(0, end).trimRight()}…';
}
