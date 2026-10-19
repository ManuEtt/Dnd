import 'dart:convert';

import 'dice_engine.dart';
import 'death_saving_throw_rules.dart';
import 'condition_rules.dart';
import 'condition_effects.dart';
import 'prone_movement_rules.dart';
import 'character_rule_engine.dart';
import 'character_effect_rules.dart';
import 'healing_spell_rules.dart';
import 'damage_rules.dart';
import 'class_progression_rules.dart';
import 'class_feature_resources.dart';
import 'class_resource_rules.dart';
import 'class_combat_features.dart';
import 'combat_class_actions.dart';
import 'two_weapon_fighting_rules.dart';
import 'monk_focus_actions.dart';
import 'monk_flurry_rules.dart';
import 'monk_self_restoration.dart';
import 'monk_perfect_focus.dart';
import 'paladin_lay_on_hands.dart';
import 'saving_throw_class_actions.dart';
import 'ai_story.dart';
import 'adventure_catalog.dart';
import 'rabenwacht_campaign.dart';
import 'models.dart';
import 'rules_engine.dart';
import 'rest_rules.dart';
import 'spellcasting_rules.dart';

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

  /// Creates a new independent campaign from a validated generative story plan.
  /// Nothing about the hero's rules or inventory comes from the provider.
  Campaign createAiCampaign(
    HeroCharacter hero,
    AiStoryPlan plan, {
    required String provider,
  }) {
    if (!const ['mock', 'openai'].contains(provider)) {
      throw const FormatException('Unbekannter Geschichtendienst.');
    }
    final validatedHero = HeroCharacter.fromJson(hero.toJson());
    final campaign = Campaign(
      id: _id('story'),
      name: plan.title,
      world: plan.world,
      sessionId: _id('session'),
      hero: validatedHero,
      scene: plan.opening,
      messages: [
        NarrativeMessage(
          id: _id('message'),
          role: 'gm',
          text: plan.opening,
          timestamp: _clock(),
        ),
      ],
      storyThreads: plan.threads,
      npcs: plan.npcs,
      places: plan.places,
      storyBible: {
        'mode': 'ai',
        'provider': provider,
        'premise': plan.premise,
        'secret': plan.secret,
        'goal': plan.goal,
        'turnCount': '0',
      },
      facts: const {'storySource': 'generated'},
    );
    Campaign.fromJson(campaign.toJson());
    return campaign;
  }

  /// Applies narrative world development to an as-yet uncommitted local
  /// free-turn. Exactly one event, one revision and one atomic save result.
  /// Rule fields, quests and combat are preserved exactly as the local engine
  /// decided them. Unknown entity IDs and oversize payloads are rejected.
  GameUpdate applyAiStoryStep(
    GameUpdate update,
    AiStoryStep step, {
    required String provider,
    required String decision,
  }) {
    final current = update.campaign;
    if (current.storyBible['mode'] != 'ai' ||
        !const ['mock', 'openai'].contains(provider) ||
        update.events.length != 1 ||
        update.events.single.type != 'narrative.turn' ||
        current.messages.isEmpty ||
        current.messages.last.role != 'gm') {
      throw const FormatException(
        'Dieser Spielzug ist nicht KI-fortschreibbar.',
      );
    }
    // Do not trust callers to have parsed and bounded external response fields.
    final replay = AiStoryStep.fromJson({
      'narration': step.narration,
      'threadUpdates': [
        for (final t in step.threadUpdates)
          {'id': t.id, 'status': t.status, 'description': t.description},
      ],
      'newThreads': [for (final t in step.newThreads) t.toJson()],
      'npcUpdates': [
        for (final n in step.npcUpdates)
          {'id': n.id, 'relationship': n.relationship, 'note': n.note},
      ],
      'adventure': step.adventure?.toJson(),
    }, current);
    final now = _clock();
    final changes = {for (final t in replay.threadUpdates) t.id: t};
    final relationships = {for (final n in replay.npcUpdates) n.id: n};
    final oldLast = current.messages.last;
    final pastTurns = int.tryParse(current.storyBible['turnCount'] ?? '0') ?? 0;
    final next = current.copyWith(
      scene: replay.narration,
      messages: [
        ...current.messages.take(current.messages.length - 1),
        NarrativeMessage(
          id: oldLast.id,
          role: 'gm',
          text: replay.narration,
          timestamp: oldLast.timestamp,
        ),
      ],
      storyThreads: [
        for (final t in current.storyThreads)
          if (changes.containsKey(t.id))
            t.copyWith(
              status: changes[t.id]!.status,
              description: changes[t.id]!.description,
            )
          else
            t,
        ...replay.newThreads,
      ],
      npcs: [
        for (final n in current.npcs)
          relationships.containsKey(n.id)
              ? n.copyWith(relationship: relationships[n.id]!.relationship)
              : n,
      ],
      npcRelationshipNotes: [
        ...current.npcRelationshipNotes,
        for (final n in replay.npcUpdates)
          NpcRelationshipNote(
            id: _id('npc-note'),
            npcId: n.id,
            relationship: n.relationship,
            note: n.note,
            recordedAt: now,
          ),
      ],
      storyBible: {...current.storyBible, 'turnCount': '${pastTurns + 1}'},
      adventureOffer: replay.adventure ?? current.adventureOffer,
    );
    final oldEvent = update.events.single;
    final payload =
        jsonDecode(jsonEncode(oldEvent.payload)) as Map<String, dynamic>;
    payload['storyProvider'] = provider;
    payload['playerDecision'] = decision.length > 2000
        ? decision.substring(0, 2000)
        : decision;
    payload['threadUpdates'] = [for (final e in replay.threadUpdates) e.id];
    payload['newThreads'] = [for (final e in replay.newThreads) e.id];
    payload['npcUpdates'] = [for (final e in replay.npcUpdates) e.id];
    payload['adventureOffer'] = replay.adventure?.id;
    payload['stateAfter'] = jsonDecode(
      jsonEncode(next.copyWith(events: const []).toJson()),
    );
    final event = GameEvent(
      id: oldEvent.id,
      campaignId: oldEvent.campaignId,
      sessionId: oldEvent.sessionId,
      timestamp: oldEvent.timestamp,
      type: oldEvent.type,
      entities: oldEvent.entities,
      payload: payload,
    );
    final result = next.copyWith(
      events: [...current.events.take(current.events.length - 1), event],
    );
    Campaign.fromJson(result.toJson());
    return GameUpdate(campaign: result, events: [event]);
  }

  /// Player opt-in converts the untrusted AI proposal into exactly one local
  /// quest + one vetted enemy encounter. Initiatives are rolled locally.
  GameUpdate acceptAdventure(Campaign campaign) {
    final offer = campaign.adventureOffer;
    if (offer == null ||
        campaign.storyBible['mode'] != 'ai' ||
        campaign.pendingRoll != null ||
        (campaign.encounter != null && !campaign.encounter!.isFinished)) {
      throw const FormatException('Keine annehmbare Begegnung vorhanden.');
    }
    if (!campaign.hero.isComplete ||
        campaign.hero.isDead ||
        campaign.hero.hitPoints == 0) {
      throw const FormatException(
        'Vor der Begegnung muss der Held kampffähig und sein Charakterbogen vollständig sein.',
      );
    }
    final valid = AdventureOffer.fromJson(offer.toJson());
    final questId = 'ai-${valid.id}';
    if (campaign.quests.length >= 100 ||
        campaign.quests.any((q) => q.id == questId) ||
        campaign.hero.inventory.any((item) => item.id == 'loot-${valid.id}')) {
      throw const FormatException(
        'Diese Begegnung wurde bereits gespielt oder das Questlimit ist erreicht.',
      );
    }
    if (valid.archetype == 'investigation') {
      final perception = CharacterRuleEngine.perception(campaign.hero);
      final bonus = perception.modifier;
      final next = campaign.copyWith(
        adventureOffer: null,
        scene: valid.description,
        quests: [
          ...campaign.quests,
          Quest(
            id: questId,
            title: valid.questTitle,
            description: valid.questDescription,
          ),
        ],
        pendingRoll: PendingRoll(
          id: _id('roll'),
          type: 'perception',
          modifier: bonus,
          difficulty: 10,
          advantage: perception.advantage,
          disadvantage: perception.disadvantage,
        ),
        facts: {
          ...campaign.facts,
          'aiEncounterQuestId': questId,
          'aiEncounterOfferId': valid.id,
          'aiEncounterLoot': 'Spurenkarte',
        },
      );
      return _commit(
        campaign,
        next,
        '${valid.title}: ${valid.description} Würfle einen W20 für Wahrnehmung '
        'mit ${_signed(bonus)}; die Schwierigkeit beträgt 10.',
        type: 'adventure.investigationStarted',
        payload: {
          'questId': questId,
          'template': 'investigation',
          'difficulty': 10,
        },
      );
    }
    final foe = AdventureCatalog.forHero(valid.archetype, campaign.hero);
    final initiative = CharacterRuleEngine.initiative(campaign.hero);
    final heroInitiative = dice.check(
      modifier: initiative.modifier,
      advantage: initiative.advantage,
      disadvantage: initiative.disadvantage,
    );
    final enemyInitiative = dice.check(modifier: 0);
    final focus = MonkPerfectFocus.onInitiative(campaign.hero);
    var next = campaign.copyWith(
      hero: focus.hero,
      adventureOffer: null,
      quests: [
        ...campaign.quests,
        Quest(
          id: questId,
          title: valid.questTitle,
          description: valid.questDescription,
        ),
      ],
      encounter: Encounter(
        id: _id('encounter'),
        enemyName: foe.name,
        enemyHitPoints: foe.hitPoints,
        enemyMaxHitPoints: foe.hitPoints,
        enemyArmorClass: foe.armorClass,
        enemyAttackBonus: foe.attackBonus,
        enemyDamage: foe.damage,
        heroInitiative: heroInitiative.total,
        enemyInitiative: enemyInitiative.total,
        movementRemaining: CharacterRuleEngine.movementWholeMeters(
          campaign.hero,
        )!,
      ),
      scene: valid.description,
      facts: {
        ...campaign.facts,
        'aiEncounterQuestId': questId,
        'aiEncounterOfferId': valid.id,
        'aiEncounterLoot': foe.loot,
      },
    );
    var narration =
        '${valid.title}: ${valid.description} '
        'Die Initiative beträgt ${heroInitiative.total} für ${campaign.hero.name} '
        'und ${enemyInitiative.total} für ${foe.name}. ';
    final details = <String, dynamic>{
      'questId': questId,
      'template': valid.archetype,
      'heroInitiative': heroInitiative.toJson(),
      'enemyInitiative': enemyInitiative.toJson(),
      'focusRecoveredAtInitiative': focus.recovered,
    };
    if (enemyInitiative.total > heroInitiative.total) {
      final turn = _enemyTurn(next, advanceRound: false);
      next = turn.campaign;
      narration += '${turn.narration} ';
      details['enemyTurn'] = turn.details;
    }
    narration += 'Angreifen, ausweichen oder fliehen?';
    return _commit(
      campaign,
      next,
      narration,
      type: 'adventure.accepted',
      payload: details,
    );
  }

  /// A rejected offer has no mechanical side effects.
  GameUpdate rejectAdventure(Campaign campaign) {
    final offer = campaign.adventureOffer;
    if (offer == null) {
      throw const FormatException('Es gibt keinen offenen Vorschlag.');
    }
    return _commit(
      campaign,
      campaign.copyWith(adventureOffer: null),
      'Du entscheidest dich gegen ${offer.title}. Die Welt bleibt offen für andere Wege.',
      type: 'adventure.rejected',
      payload: {'offerId': offer.id},
    );
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
    if (normalized.isEmpty ||
        normalized.length > 80 ||
        description.isEmpty ||
        description.length > 500) {
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
    if (cleanTitle.isEmpty ||
        cleanTitle.length > 120 ||
        cleanDescription.length > 1000 ||
        !const ['open', 'resolved', 'abandoned'].contains(status)) {
      throw const FormatException(
        'Titel, Notiz oder Handlungsstatus ungültig.',
      );
    }
    if (threadId == null && campaign.storyThreads.length >= 100) {
      throw const FormatException('Maximal 100 Handlungsstränge möglich.');
    }
    if (threadId != null &&
        campaign.storyThreads.where((thread) => thread.id == threadId).length !=
            1) {
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

  /// Starts a prewritten, offline solo story using the selected character.
  Campaign createRabenwacht(HeroCharacter hero) =>
      RabenwachtCampaign.create(
        hero: hero,
        campaignId: _id('rabenwacht'),
        sessionId: _id('session'),
        messageId: _id('message'),
        now: _clock(),
      );

  /// Incapacitation ends these effects immediately, including when a confirmed
  /// external source or character correction occurs between combat turns.
  /// Healing or removing the condition later cannot revive the old Rage.
  Encounter? _encounterAfterHeroChange(Campaign campaign, HeroCharacter hero) {
    final fight = campaign.encounter;
    if (fight == null ||
        (hero.hitPoints != 0 && ConditionRules.canTakeActions(hero))) {
      return fight;
    }
    return fight.copyWith(
      rageStartedRound: 0,
      rageUntilRound: 0,
      dodgeActive: false,
    );
  }

  GameUpdate updateHero(Campaign campaign, HeroCharacter hero) {
    // Round-trip validation also checks imported edits made outside the engine.
    final parsed = HeroCharacter.fromJson(hero.toJson());
    var validated = ConditionRules.retainProneFromUnconscious(
      campaign.hero,
      parsed,
    );
    if (validated.id != campaign.hero.id) {
      throw ArgumentError(
        'Ein anderer Charakter kann nicht stillschweigend übernommen werden.',
      );
    }
    if (campaign.encounter != null &&
        !campaign.encounter!.isFinished &&
        campaign.hero.manualConditions.contains('liegend') &&
        !validated.manualConditions.contains('liegend')) {
      throw const FormatException(
        'Im laufenden Kampf bitte über Aufstehen mit Bewegungskosten aufstehen.',
      );
    }
    if (!ConditionRules.canTakeActions(validated)) {
      validated = SpellcastingRules.endConcentration(validated);
    }
    final fight = _encounterAfterHeroChange(campaign, validated);
    return _commit(
      campaign,
      campaign.copyWith(
        hero: validated,
        encounter: fight,
        pendingRoll: null,
        pendingDeathSave: null,
      ),
      validated.isComplete
          ? '${hero.name}, dein Charakterbogen ist bestätigt. Deine historischen Erlebnisse bleiben erhalten.'
          : 'Der Charakterbogen wurde gespeichert. Noch offen: ${validated.incompleteFields.join(', ')}.',
      type: 'character.updated',
      payload: {
        'characterId': hero.id,
        if ((campaign.encounter?.rageUntilRound ?? 0) > 0 &&
            fight?.rageUntilRound == 0)
          'rageEndedByIncapacitation': true,
      },
    );
  }

  void _requireExternalEffect(Campaign campaign, String source) {
    if (source.trim().isEmpty || source.trim().length > 200) {
      throw const FormatException(
        'Eine Effektquelle mit 1 bis 200 Zeichen angeben.',
      );
    }
    if (campaign.pendingRoll != null || campaign.pendingDeathSave != null) {
      throw const FormatException(
        'Zuerst den bereits offenen Würfelwurf abschließen.',
      );
    }
    if (campaign.hero.hitPoints == null || campaign.hero.maxHitPoints == null) {
      throw const FormatException(
        'Zuerst die Trefferpunkte im Charakterbogen bestätigen.',
      );
    }
    if (campaign.hero.isDead) {
      throw const FormatException(
        'Diese Effekte können einen toten Charakter nicht verändern.',
      );
    }
  }

  /// End the manually retained Prone condition by spending the proper
  /// half-Speed movement on the active hero turn. A still-active sourced
  /// Prone effect cannot be silently cancelled by standing up.
  GameUpdate standUp(Campaign campaign) {
    final hero = campaign.hero;
    if (!hero.conditions.contains('liegend')) {
      throw const FormatException('Dein Charakter liegt nicht am Boden.');
    }
    if (!hero.manualConditions.contains('liegend') ||
        hero.conditionEffects.any((entry) => entry.condition == 'liegend')) {
      throw const FormatException(
        'Eine bestätigte Zustandsquelle hält dich noch liegend. '
        'Beende zuerst diese Quelle.',
      );
    }
    if (campaign.pendingRoll != null ||
        campaign.pendingDeathSave != null ||
        hero.isDead) {
      throw const FormatException(
        'Zuerst den offenen Wurf abschließen oder den Tod beachten.',
      );
    }
    final fight = campaign.encounter;
    final active = fight != null && !fight.isFinished;
    if (active && fight.activeParticipant != 'hero') {
      throw const FormatException('Aufstehen ist nur im eigenen Zug erlaubt.');
    }
    // Also validates positive Speed and movement-blocking conditions outside
    // combat, without inventing a turn/movement pool there.
    final cost = ProneMovementRules.standingCostDecimeters(hero);
    final updatedFight = active
        ? ProneMovementRules.spendStandingMovement(fight, hero)
        : fight;
    final after = hero.copyWith(
      conditions: [
        for (final condition in hero.manualConditions)
          if (condition != 'liegend') condition,
      ],
    );
    return _commit(
      campaign,
      campaign.copyWith(hero: after, encounter: updatedFight),
      active
          ? 'Du stehst auf und verbrauchst ${ProneMovementRules.formatDecimeters(cost)} '
                'Bewegung. Übrig: ${updatedFight!.movementRemainingLabel}.'
          : 'Du stehst auf. Außerhalb des Kampfes wird kein Zugbudget verbraucht.',
      type: 'combat.stoodUp',
      payload: {
        'targetId': hero.id,
        'movementSpentDecimeters': active ? cost : 0,
        if (active)
          'movementRemainingDecimeters':
              updatedFight!.remainingMovementDecimeters,
      },
    );
  }

  /// Apply one confirmed external condition, never inferred from narration.
  /// A timed effect is tied to the currently active encounter and its own
  /// hero-turn boundary. Other durations require a future world-time model.
  GameUpdate applyConditionEffect(
    Campaign campaign, {
    required String source,
    required String condition,
    required ConditionEffectDuration duration,
  }) {
    _requireExternalEffect(campaign, source);
    final fight = campaign.encounter;
    final int? endRound;
    final String? encounterId;
    if (duration == ConditionEffectDuration.untilRemoved) {
      endRound = null;
      encounterId = null;
    } else {
      if (fight == null ||
          fight.isFinished ||
          fight.activeParticipant != 'hero') {
        throw const FormatException(
          'Ein Zugendpunkt erfordert einen aktiven eigenen Kampfzug.',
        );
      }
      encounterId = fight.id;
      endRound =
          fight.round +
          (duration == ConditionEffectDuration.nextTurnEnd ? 1 : 0);
    }
    final effect = ConditionEffect(
      id: _id('condition'),
      condition: condition,
      source: source,
      expiresInEncounterId: encounterId,
      expiresAtOwnTurnEndRound: endRound,
    );
    var hero = ConditionEffectRules.add(campaign.hero, effect);
    if (!ConditionRules.canTakeActions(hero)) {
      hero = SpellcastingRules.endConcentration(hero);
    }
    final nextFight = _encounterAfterHeroChange(campaign, hero);
    final rageEnded =
        (fight?.rageUntilRound ?? 0) > 0 && nextFight?.rageUntilRound == 0;
    return _commit(
      campaign,
      campaign.copyWith(hero: hero, encounter: nextFight),
      'Bestätigter Zustand: $condition durch ${effect.source}.'
      '${endRound == null ? ' Bis zur ausdrücklichen Entfernung.' : ' Bis zu deinem Zugende in Runde $endRound.'}'
      '${rageEnded ? ' Dein Kampfrausch endet.' : ''}',
      type: 'condition.effect.added',
      payload: {
        'effect': effect.toJson(),
        'targetId': hero.id,
        if (rageEnded) 'rageEndedByIncapacitation': true,
        if (campaign.hero.concentratingOn.isNotEmpty &&
            hero.concentratingOn.isEmpty)
          'concentrationEnded': true,
      },
    );
  }

  /// End exactly one validated cause; overlapping sources and manual entries
  /// remain in place. Never restart a lost concentration or Rage.
  GameUpdate removeConditionEffect(
    Campaign campaign, {
    required String effectId,
  }) {
    if (campaign.pendingRoll != null || campaign.pendingDeathSave != null) {
      throw const FormatException(
        'Zuerst den bereits offenen Würfelwurf abschließen.',
      );
    }
    final matches = campaign.hero.conditionEffects.where(
      (entry) => entry.id == effectId,
    );
    if (matches.length != 1) {
      throw const FormatException(
        'Diese Zustandsquelle ist nicht mehr vorhanden.',
      );
    }
    final effect = matches.single;
    final hero = ConditionEffectRules.removeById(campaign.hero, effectId);
    return _commit(
      campaign,
      campaign.copyWith(hero: hero),
      'Zustandsquelle ${effect.source} für ${effect.condition} beendet.',
      type: 'condition.effect.removed',
      payload: {
        'effectId': effect.id,
        'condition': effect.condition,
        'source': effect.source,
        'targetId': hero.id,
      },
    );
  }

  /// An explicit user-confirmed external source, never parsed out of prose.
  GameUpdate applyDamage(
    Campaign campaign, {
    required String source,
    required List<DamageComponent> components,
    required DamageDefenses defenses,
    bool critical = false,
  }) {
    _requireExternalEffect(campaign, source);
    final effect = CharacterEffectRules.damage(
      campaign.hero,
      components: components,
      defenses: CharacterEffectRules.defensesFor(
        campaign.hero,
        encounter: campaign.encounter,
        declared: defenses,
      ),
      dice: dice,
      critical: critical,
    );
    final concentration = effect.concentrationSave;
    final fight = _encounterAfterHeroChange(campaign, effect.hero);
    final rageEnded =
        (campaign.encounter?.rageUntilRound ?? 0) > 0 &&
        fight?.rageUntilRound == 0;
    final concentrationText = concentration != null
        ? ' Konzentrationsrettungswurf ${concentration.total} gegen SG '
              '${effect.concentrationDc}: ${effect.concentrationLost ? 'misslungen' : 'gelungen'}.'
        : effect.concentrationLost
        ? ' Deine Konzentration endet.'
        : '';
    return _commit(
      campaign,
      campaign.copyWith(hero: effect.hero, encounter: fight),
      '${source.trim()}: ${effect.damage} Schaden bestätigt. '
      '${effect.temporaryHitPointsAbsorbed} temporäre TP absorbiert; '
      'TP ${effect.hero.hitPoints}/${effect.hero.maxHitPoints}.'
      '$concentrationText${rageEnded ? ' Dein Kampfrausch endet wegen Handlungsunfähigkeit.' : ''}',
      type: 'effect.damage',
      payload: {
        'source': source.trim(),
        'targetId': campaign.hero.id,
        'critical': critical,
        if (rageEnded) 'rageEndedByIncapacitation': true,
        ...effect.toJson(),
      },
    );
  }

  GameUpdate applyHealing(
    Campaign campaign, {
    required String source,
    required int amount,
  }) {
    _requireExternalEffect(campaign, source);
    final hero = RulesEngine.heal(campaign.hero, amount);
    final restored = hero.hitPoints! - campaign.hero.hitPoints!;
    return _commit(
      campaign,
      campaign.copyWith(hero: hero),
      '${source.trim()}: $restored Trefferpunkte wiederhergestellt. '
      'TP ${hero.hitPoints}/${hero.maxHitPoints}.',
      type: 'effect.healing',
      payload: {
        'source': source.trim(),
        'targetId': hero.id,
        'amount': amount,
        'hitPointsRestored': restored,
      },
    );
  }

  GameUpdate grantTemporaryHitPoints(
    Campaign campaign, {
    required String source,
    required int amount,
    bool replaceExisting = false,
  }) {
    _requireExternalEffect(campaign, source);
    final hero = RulesEngine.grantTemporaryHitPoints(
      campaign.hero,
      amount,
      replaceExisting: replaceExisting,
    );
    return _commit(
      campaign,
      campaign.copyWith(hero: hero),
      '${source.trim()}: ${hero.temporaryHitPoints} temporäre Trefferpunkte. '
      'Temporäre TP werden nicht addiert und stellen keine echten TP wieder her.',
      type: 'effect.temporaryHitPoints',
      payload: {
        'source': source.trim(),
        'targetId': hero.id,
        'amount': amount,
        'replaceExisting': replaceExisting,
        'previousTemporaryHitPoints': campaign.hero.temporaryHitPoints,
        'temporaryHitPoints': hero.temporaryHitPoints,
      },
    );
  }

  GameUpdate castHealingSpell(
    Campaign campaign, {
    required String spellName,
    required String castingClass,
    int? slotLevel,
    bool pactMagic = false,
    required bool verbalComponentConfirmed,
    bool somaticComponentConfirmed = false,
  }) {
    _requireExternalEffect(campaign, spellName);
    final definition = HealingSpellRules.find(spellName);
    if (definition == null) {
      throw const FormatException(
        'Dieser Zauber besitzt keine bestätigte Heilwirkung.',
      );
    }
    final fight = campaign.encounter;
    final inCombat = fight != null && !fight.isFinished;
    final bonusAction = definition.actionType == 'bonusAction';
    if (inCombat) {
      if (!campaign.hero.isComplete || fight.activeParticipant != 'hero') {
        throw const FormatException(
          'Zauberwirken benötigt deinen eigenen Zug und bestätigte Kampfwerte.',
        );
      }
      if (CombatClassActions.rageActive(fight)) {
        throw const FormatException(
          'Während des Kampfrauschs kannst du keine Zauber wirken.',
        );
      }
      if (fight.spellSlotExpendedThisTurn) {
        throw const FormatException(
          'Du hast in diesem Zug bereits einen Zauberplatz zum Zauberwirken verbraucht.',
        );
      }
      if (bonusAction ? fight.bonusActionUsed : fight.actionUsed) {
        throw FormatException(
          bonusAction
              ? 'Deine Bonusaktion ist bereits verbraucht.'
              : 'Deine Aktion ist bereits verbraucht.',
        );
      }
      // The existing Action Surge implementation reserves an Attack action.
      // It may never authorize the Magic action in the 2024 rules.
      if (!bonusAction && (fight.surgeReserved || fight.surgeUsedThisTurn)) {
        throw const FormatException(
          'Die zusätzliche Action-Surge-Aktion erlaubt keine Magieaktion.',
        );
      }
    }
    final cast = HealingSpellRules.castSelf(
      campaign.hero,
      dice: dice,
      spellName: spellName,
      castingClass: castingClass,
      slotLevel: slotLevel,
      pactMagic: pactMagic,
      verbalComponentConfirmed: verbalComponentConfirmed,
      somaticComponentConfirmed: somaticComponentConfirmed,
    );
    final nextFight = inCombat
        ? fight.copyWith(
            actionUsed: bonusAction ? fight.actionUsed : true,
            bonusActionUsed: bonusAction ? true : fight.bonusActionUsed,
            spellSlotExpendedThisTurn: true,
          )
        : fight;
    return _commit(
      campaign,
      campaign.copyWith(hero: cast.hero, encounter: nextFight),
      '${cast.spellName}: ${cast.roll.expression} ergibt ${cast.roll.total}; '
      '${cast.recovered} TP wiederhergestellt '
      '(${cast.hero.hitPoints}/${cast.hero.maxHitPoints}). '
      '${cast.pactMagic ? 'Paktplatz' : 'Zauberplatz'} Grad ${cast.slotLevel} verbraucht.'
      '${inCombat ? ' ${bonusAction ? 'Bonusaktion' : 'Magieaktion'} verbraucht. Du kannst deinen Zug ausdrücklich beenden.' : ''}',
      type: 'spell.healing',
      payload: {
        'spellName': cast.spellName,
        'castingClass': cast.castingClass,
        'spellcastingAbility': cast.spellcastingAbility,
        'spellLevel': definition.level,
        'slotLevel': cast.slotLevel,
        'pactMagic': cast.pactMagic,
        'targetId': cast.hero.id,
        'actionType': cast.actionType,
        'inCombat': inCombat,
        'verbalComponentConfirmed': verbalComponentConfirmed,
        'somaticComponentConfirmed': somaticComponentConfirmed,
        'healingRoll': cast.roll.toJson(),
        'hitPointsRestored': cast.recovered,
        'discipleOfLifeBonus': cast.discipleOfLifeBonus,
        'maximizedHealing': cast.maximizedHealing,
      },
    );
  }

  static bool _isEndTurn(String words) => RegExp(
    r'^(?:zug beenden|(?:ich )?beende (?:meinen|den) zug)[.!?]?$',
  ).hasMatch(words.trim());

  /// Ending a turn is not an action. Incapacitation cannot prevent it.
  GameUpdate endHeroTurn(Campaign campaign) {
    final fight = campaign.encounter;
    if (fight == null ||
        fight.isFinished ||
        fight.activeParticipant != 'hero' ||
        campaign.pendingRoll != null ||
        campaign.pendingDeathSave != null ||
        campaign.hero.isDead ||
        !campaign.hero.isComplete) {
      throw const FormatException(
        'Der eigene Kampfzug kann jetzt nicht beendet werden.',
      );
    }
    if (campaign.hero.hitPoints == 0 &&
        !campaign.hero.conditions.contains(RulesEngine.stable) &&
        !fight.deathSaveResolvedThisTurn) {
      throw const FormatException(
        'Zuerst den Todesrettungswurf für diesen Zug abschließen.',
      );
    }
    final turn = _enemyTurn(campaign);
    return _commit(
      campaign,
      turn.campaign,
      'Du beendest deinen Zug. ${turn.narration} ${_nextInstruction(turn.campaign)}',
      type: 'combat.turnCompleted',
      payload: turn.details,
    );
  }

  GameUpdate _completeDeathSave(
    Campaign before,
    Campaign next,
    DeathSavingThrowResult result, {
    Map<String, dynamic> payload = const {},
    String type = 'roll.resolved',
  }) {
    final fight = next.encounter;
    next = next.copyWith(
      hero: result.hero,
      pendingRoll: null,
      pendingDeathSave: null,
      encounter: fight != null && !fight.isFinished
          ? fight.copyWith(deathSaveResolvedThisTurn: true)
          : fight,
    );
    final outcome = result.hero.isDead
        ? 'Dein Held stirbt; das Ereignis bleibt im Tagebuch.'
        : result.hero.hitPoints! > 0
        ? 'Du kommst mit einem Trefferpunkt wieder zu Bewusstsein und kannst deinen Zug fortsetzen.'
        : result.hero.conditions.contains(RulesEngine.stable)
        ? 'Du bist stabilisiert und bleibst bewusstlos.'
        : 'Todesrettung: ${result.hero.deathSuccesses} Erfolge, ${result.hero.deathFailures} Fehlschläge.';
    return _commit(
      before,
      next,
      'Todesrettungswurf: Naturwurf ${result.roll.natural} ${_signed(result.roll.modifier)} = ${result.roll.total}. '
      '$outcome${fight != null && !fight.isFinished && !result.hero.isDead && result.hero.hitPoints == 0 ? ' Beende jetzt deinen Zug; erst im nächsten eigenen Zug ist wieder eine Todesrettung fällig.' : ''}',
      type: type,
      payload: {
        ...payload,
        'roll': result.roll.toJson(),
        'deathSave': true,
        'passed': result.passed,
        'rerolled': result.rerolled,
        if (result.rerolled) ...{
          'originalRoll': result.originalRoll.toJson(),
          'resource': result.resource,
          'fighterLevelBonus': result.fighterLevelBonus,
        },
      },
    );
  }

  GameUpdate resolveDeathSaveDecision(
    Campaign campaign, {
    SavingThrowRerollFeature? feature,
  }) {
    final choice = campaign.pendingDeathSave;
    if (choice == null) {
      throw const FormatException('Keine offene Todesrettungsentscheidung.');
    }
    Campaign.fromJson(campaign.toJson());
    final original = DeathSavingThrowRules.resolve(
      hero: campaign.hero,
      natural: choice.originalNatural,
    );
    if (feature == null) {
      return _completeDeathSave(
        campaign,
        campaign,
        original,
        type: 'deathSave.resolved',
        payload: {'decision': 'accepted'},
      );
    }
    if (!DeathSavingThrowRules.canReroll(original, feature)) {
      throw const FormatException(
        'Diese Todesrettungswiederholung ist nicht verfügbar.',
      );
    }
    final rolled = dice.check(
      modifier:
          DeathSavingThrowRules.modifier(campaign.hero) +
          (feature == SavingThrowRerollFeature.indomitable
              ? ClassResourceRules.level(campaign.hero, 'Kämpfer')
              : 0),
    );
    final result = DeathSavingThrowRules.rerollFailed(
      original: original,
      natural: rolled.natural!,
      feature: feature,
    );
    return _completeDeathSave(
      campaign,
      campaign,
      result,
      type: 'deathSave.resolved',
      payload: {'decision': feature.name},
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
    final deathCommand = RegExp(
      r'^todesrettung (annehmen|wiederholen\s*:\s*(fokus|unbeugsam))[.!?]?$',
    ).firstMatch(words);
    if (campaign.pendingDeathSave != null || deathCommand != null) {
      try {
        if (deathCommand == null) {
          throw const FormatException(
            'Zuerst die offene Todesrettung annehmen oder wiederholen.',
          );
        }
        return resolveDeathSaveDecision(
          campaign,
          feature: deathCommand.group(2) == null
              ? null
              : deathCommand.group(2) == 'fokus'
              ? SavingThrowRerollFeature.disciplinedSurvivor
              : SavingThrowRerollFeature.indomitable,
        );
      } on FormatException catch (error) {
        return _commit(
          campaign,
          campaign,
          error.message,
          type: 'rules.blocked',
        );
      } on StateError catch (error) {
        return _commit(
          campaign,
          campaign,
          error.message.toString(),
          type: 'rules.blocked',
        );
      }
    }

    // A new class action or save request must never be mistaken for the
    // natural die value of an already pending attack/check.
    if (campaign.pendingRoll != null &&
        RegExp(r'^(?:rettungswurf|handauflegen)\s*[: ]').hasMatch(words)) {
      return _commit(
        campaign,
        campaign,
        'Zuerst den bereits offenen Würfelwurf abschließen.',
        type: 'rules.blocked',
      );
    }
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
      return _commit(campaign, current, narration, type: 'memory.recalled');
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
    // Manual saving throws with explicitly declared DC. This is deliberately
    // NOT a spell save inferred from AI narration: the player supplies the DC.
    const saveNames = <String, String>{
      'stärke': 'strength',
      'staerke': 'strength',
      'geschicklichkeit': 'dexterity',
      'konstitution': 'constitution',
      'intelligenz': 'intelligence',
      'weisheit': 'wisdom',
      'charisma': 'charisma',
    };
    final requestedSave = RegExp(
      r'^rettungswurf\s*:\s*(stärke|staerke|geschicklichkeit|konstitution|intelligenz|weisheit|charisma)\s+sg\s+(\d{1,2})\s*[.!?]?$',
    ).firstMatch(words);
    if (requestedSave != null) {
      final ability = saveNames[requestedSave.group(1)!]!;
      final dc = int.parse(requestedSave.group(2)!);
      if (dc < 1 || dc > 30 || current.hero.isDead) {
        return _commit(
          campaign,
          current,
          'Der manuelle Rettungswurf benötigt SG 1 bis 30 und einen lebenden Charakter.',
          type: 'rules.blocked',
        );
      }
      try {
        final rule = CharacterRuleEngine.savingThrow(current.hero, ability);
        if (rule.automaticallyFails) {
          return _commit(
            campaign,
            current,
            'Der Rettungswurf (${requestedSave.group(1)}, SG $dc) '
            'misslingt durch deinen Zustand automatisch. '
            'Es wird kein W20 gewürfelt und kein Wiederholungsmerkmal verbraucht.',
            type: 'saving.automaticFailure',
            payload: {
              'ability': ability,
              'difficulty': dc,
              'failed': true,
              'automaticFailure': true,
              'manualDifficulty': true,
            },
          );
        }
        final rolled = dice.check(
          modifier: rule.modifier,
          advantage: rule.advantage,
          disadvantage: rule.disadvantage,
        );
        final passed = rolled.total >= dc;
        final options = <String>[
          if (!passed &&
              SavingThrowClassActions.available(
                current.hero,
                SavingThrowRerollFeature.disciplinedSurvivor,
              ))
            'Fokus',
          if (!passed &&
              SavingThrowClassActions.available(
                current.hero,
                SavingThrowRerollFeature.indomitable,
              ))
            'Unbeugsam',
        ];
        final suggestions = options.isEmpty
            ? ''
            : 'Du kannst sofort wiederholen mit: '
                  '${options.map((option) => 'Rettungswurf wiederholen: $option').join(' oder ')}. ';
        return _commit(
          campaign,
          current,
          'Manueller Rettungswurf (${requestedSave.group(1)}, SG $dc): '
          '${rolled.total} – ${passed ? 'gelungen' : 'misslungen'}. '
          '$suggestions'
          'Das Ergebnis wird dokumentiert; Wirkungen fremder Zauber werden nicht automatisch angenommen.',
          type: 'saving.roll',
          payload: {
            'ability': ability,
            'difficulty': dc,
            'total': rolled.total,
            'failed': !passed,
            'roll': rolled.toJson(),
            'manualDifficulty': true,
          },
        );
      } on StateError catch (e) {
        return _commit(
          campaign,
          current,
          e.message.toString(),
          type: 'rules.blocked',
        );
      }
    }
    final retrySave = RegExp(
      r'^rettungswurf wiederholen\s*:\s*(fokus|unbeugsam)\s*[.!?]?$',
    ).firstMatch(words);
    if (retrySave != null) {
      final previous = campaign.events.isNotEmpty ? campaign.events.last : null;
      final payload = previous?.payload ?? const <String, dynamic>{};
      if (previous?.type != 'saving.roll' ||
          payload['failed'] != true ||
          payload['ability'] is! String ||
          payload['difficulty'] is! int ||
          payload['total'] is! int) {
        return _commit(
          campaign,
          current,
          'Es liegt kein unmittelbar vorheriger fehlgeschlagener Rettungswurf vor.',
          type: 'rules.blocked',
        );
      }
      final feature = retrySave.group(1) == 'fokus'
          ? SavingThrowRerollFeature.disciplinedSurvivor
          : SavingThrowRerollFeature.indomitable;
      try {
        final rerolled = SavingThrowClassActions.rerollFailed(
          hero: current.hero,
          dice: dice,
          ability: payload['ability'] as String,
          difficulty: payload['difficulty'] as int,
          originalTotal: payload['total'] as int,
          feature: feature,
        );
        return _commit(
          campaign,
          current.copyWith(hero: rerolled.hero),
          'Wiederholter Rettungswurf: ${rerolled.roll.total} – '
          '${rerolled.passed ? 'gelungen' : 'misslungen'}. '
          'Das neue Ergebnis gilt auch dann, wenn es schlechter ist.',
          type: 'saving.rerolled',
          payload: {
            'ability': payload['ability'],
            'difficulty': payload['difficulty'],
            'previousTotal': payload['total'],
            'roll': rerolled.roll.toJson(),
            'passed': rerolled.passed,
            'resource': rerolled.resource,
            'fighterLevelBonus': rerolled.fighterLevelBonus,
          },
        );
      } on StateError catch (e) {
        return _commit(
          campaign,
          current,
          e.message.toString(),
          type: 'rules.blocked',
        );
      } on FormatException catch (e) {
        return _commit(campaign, current, e.message, type: 'rules.blocked');
      }
    }
    // An explicit Lay on Hands command is the only authority to spend the
    // paladin's shared healing pool. Natural-language story text cannot do so.
    final handsCommand = RegExp(
      r'^handauflegen\s*:\s*(\d{1,3}|vergiftung)(?:\s*[.!?])?$',
    ).firstMatch(words);
    if (handsCommand != null) {
      final encounter = current.encounter;
      if (encounter != null &&
          !encounter.isFinished &&
          (encounter.bonusActionUsed ||
              encounter.activeParticipant != 'hero')) {
        return _commit(
          campaign,
          current,
          'Handauflegen benötigt deine freie Bonusaktion im eigenen Zug.',
          type: 'rules.blocked',
        );
      }
      try {
        final choice = handsCommand.group(1)!;
        final use = PaladinLayOnHands.useOnSelf(
          current.hero,
          healing: int.tryParse(choice) ?? 0,
          removePoisoned: choice == 'vergiftung',
        );
        final nextEncounter = encounter != null && !encounter.isFinished
            ? encounter.copyWith(bonusActionUsed: true)
            : encounter;
        final remaining = PaladinLayOnHands.remaining(use.hero);
        return _commit(
          campaign,
          current.copyWith(hero: use.hero, encounter: nextEncounter),
          use.poisonedRemoved
              ? 'Handauflegen: Vergiftet entfernt, 5 Heilpunkte verbraucht. '
                    '$remaining Punkte verbleiben.'
              : 'Handauflegen: ${use.hitPointsRestored} Trefferpunkte '
                    'wiederhergestellt; ${use.pointsSpent} Heilpunkte verbraucht. '
                    '$remaining Punkte verbleiben.',
          type: 'class.layOnHands',
          payload: {
            'pointsSpent': use.pointsSpent,
            'hitPointsRestored': use.hitPointsRestored,
            'poisonedRemoved': use.poisonedRemoved,
            'remaining': remaining,
          },
        );
      } on StateError catch (e) {
        return _commit(
          campaign,
          current,
          e.message.toString(),
          type: 'rules.blocked',
        );
      } on FormatException catch (e) {
        return _commit(campaign, current, e.message, type: 'rules.blocked');
      } on RangeError catch (e) {
        return _commit(
          campaign,
          current,
          'Ungültige Heilpunktzahl: $e',
          type: 'rules.blocked',
        );
      }
    }
    if (RegExp(r'second wind|zweite luft').hasMatch(words)) {
      final encounter = current.encounter;
      if (encounter != null &&
          !encounter.isFinished &&
          encounter.bonusActionUsed) {
        return _commit(
          campaign,
          current,
          'Die Bonusaktion dieses Zugs ist bereits verbraucht.',
          type: 'rules.blocked',
        );
      }
      if (encounter != null &&
          !encounter.isFinished &&
          !ConditionRules.canTakeActions(current.hero)) {
        return _commit(
          campaign,
          current,
          'Dein Zustand verhindert diese Bonusaktion.',
          type: 'rules.blocked',
        );
      }
      try {
        final used = ClassFeatureResources.useSecondWind(current.hero, dice);
        final updatedEncounter = encounter != null && !encounter.isFinished
            ? encounter.copyWith(bonusActionUsed: true)
            : encounter;
        return _commit(
          campaign,
          current.copyWith(hero: used.hero, encounter: updatedEncounter),
          'Second Wind: ${used.roll.rolls.single} + '
          '${ClassFeatureResources.fighterLevel(current.hero)} = '
          '${used.totalHealing} Heilung (tatsächlich '
          '${used.hitPointsRestored} TP). Verbleibende Nutzungen: '
          '${ClassFeatureResources.remainingSecondWind(used.hero)}.',
          type: 'class.secondWind',
          payload: {
            'roll': used.roll.toJson(),
            'restoredHitPoints': used.hitPointsRestored,
            'spentSecondWind': used.hero.spentSecondWind,
          },
        );
      } on StateError catch (error) {
        return _commit(
          campaign,
          current,
          error.message.toString(),
          type: 'rules.blocked',
        );
      } on FormatException catch (error) {
        return _commit(campaign, current, error.message, type: 'rules.blocked');
      }
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
    if (_isEndTurn(words)) {
      try {
        return endHeroTurn(current);
      } on FormatException catch (error) {
        return _commit(campaign, current, error.message, type: 'rules.blocked');
      }
    }
    if (words.startsWith('selbstwiederherstellung') &&
        current.encounter != null &&
        !current.encounter!.isFinished) {
      return _combatAction(campaign, current, words);
    }
    if (current.hero.hitPoints == 0 && current.hero.isComplete) {
      final fight = current.encounter;
      if (fight != null &&
          !fight.isFinished &&
          fight.activeParticipant != 'hero') {
        return _commit(
          campaign,
          current,
          'Die Todesrettung ist erst zu Beginn deines eigenen Zugs fällig.',
          type: 'rules.blocked',
        );
      }
      if (fight != null &&
          !fight.isFinished &&
          fight.deathSaveResolvedThisTurn) {
        return _commit(
          campaign,
          current,
          'Die Todesrettung dieses Zugs ist abgeschlossen. Beende deinen Zug.',
          type: 'rules.blocked',
        );
      }

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
            modifier: DeathSavingThrowRules.modifier(current.hero),
            deathSaveRulesVersion: 1,
            difficulty: 10,
          ),
        ),
        'Du bist bewusstlos. Bitte würfle einen natürlichen W20 für deinen Todesrettungswurf.',
        type: 'roll.requested',
      );
    }
    // Both deterministic demo and AI campaigns use the SAME local rest rules.
    // No external storyteller can restore Hit Dice or Hit Points directly.
    if (RegExp(r'rast|ausruh|\bruhe\b').hasMatch(words)) {
      if (!current.hero.isComplete) {
        return _commit(
          campaign,
          current,
          'Eine Rast benötigt einen vollständigen Charakterbogen.',
          type: 'rules.blocked',
        );
      }
      if (current.encounter != null && !current.encounter!.isFinished) {
        return _commit(
          campaign,
          current,
          'Während eines laufenden Kampfes ist keine Rast möglich.',
          type: 'rules.blocked',
        );
      }
      final short = RegExp(r'kurz\w*\s+rast').hasMatch(words);
      final long = RegExp(r'lang\w*\s+rast').hasMatch(words);
      if (!short && !long) {
        return _commit(
          campaign,
          current,
          'Bitte bestätige ausdrücklich „kurze Rast“ (mindestens 1 Stunde) '
          'oder „lange Rast“ (mindestens 8 Stunden).',
          type: 'rules.blocked',
        );
      }
      try {
        if (short) {
          final requested = RegExp(
            r'(\d{1,2})\s*[wd](6|8|10|12)',
          ).firstMatch(words);
          final count = requested == null ? 1 : int.parse(requested.group(1)!);
          final sides = requested == null
              ? null
              : int.parse(requested.group(2)!);
          if (current.hero.hitPoints == current.hero.maxHitPoints) {
            if (requested == null &&
                (current.hero.spentPactSlots > 0 ||
                    current.hero.spentSecondWind > 0 ||
                    current.hero.spentActionSurge > 0 ||
                    current.hero.spentClassResources.values.any(
                      (n) => n > 0,
                    ))) {
              final refreshed = ClassResourceRules.afterShortRest(
                ClassFeatureResources.afterShortRest(
                  SpellcastingRules.afterShortRest(current.hero),
                ),
              );
              return _commit(
                campaign,
                current.copyWith(hero: refreshed),
                'Nach der kurzen Rast wurden deine verfügbaren Klassen- und '
                'Paktressourcen regeneriert. Es wurden keine Trefferwürfel verbraucht.',
                type: 'character.shortRest',
                payload: {
                  'hitDice': null,
                  'count': 0,
                  'rolls': <dynamic>[],
                  'pactSlotsRecovered': current.hero.spentPactSlots,
                },
              );
            }
            return _commit(
              campaign,
              current,
              'Deine Trefferpunkte sind bereits vollständig. '
              'Es werden keine Trefferwürfel automatisch verbraucht.',
              type: 'rules.blocked',
            );
          }
          if (requested == null &&
              (current.hero.spentPactSlots > 0 ||
                  current.hero.spentSecondWind > 0 ||
                  current.hero.spentActionSurge > 0 ||
                  current.hero.spentClassResources.values.any((n) => n > 0)) &&
              !RestRules.availableHitDice(
                current.hero,
              ).values.any((n) => n > 0)) {
            final refreshed = ClassResourceRules.afterShortRest(
              ClassFeatureResources.afterShortRest(
                SpellcastingRules.afterShortRest(current.hero),
              ),
            );
            return _commit(
              campaign,
              current.copyWith(hero: refreshed),
              'Nach der kurzen Rast wurden Klassen- und Paktressourcen regeneriert. '
              'Die Trefferwürfel sind bereits verbraucht.',
              type: 'character.shortRest',
              payload: {
                'hitDice': null,
                'count': 0,
                'rolls': <dynamic>[],
                'pactSlotsRecovered': current.hero.spentPactSlots,
              },
            );
          }
          final rest = RestRules.shortRest(
            current.hero,
            dice: dice,
            dieSides: sides,
            count: count,
          );
          return _commit(
            campaign,
            current.copyWith(hero: rest.hero),
            'Nach einer kurzen Rast (mindestens 1 Stunde) verbrauchst du '
            '$count Trefferwürfel ${rest.dieType.toUpperCase()}. '
            'Du erhältst ${rest.recovered} Trefferpunkte zurück '
            '(jetzt ${rest.hero.hitPoints}/${rest.hero.maxHitPoints}).',
            type: 'character.shortRest',
            payload: {
              'hitDice': rest.dieType,
              'count': count,
              'rolls': [for (final roll in rest.dice) roll.toJson()],
              'constitutionBonus': rest.constitutionBonus,
              'healed': rest.recovered,
              'pactSlotsRecovered': current.hero.spentPactSlots,
            },
          );
        }
        final hero = RestRules.longRest(current.hero);
        return _commit(
          campaign,
          current.copyWith(hero: hero),
          'Nach einer langen Rast (mindestens 8 Stunden) sind deine '
          'Trefferpunkte und verbrauchten Trefferwürfel wiederhergestellt. '
          'Erschöpfung: ${current.hero.exhaustionLevel} → ${hero.exhaustionLevel}. '
          'Klassenressourcen wurden ebenfalls wiederhergestellt.',
          type: 'character.longRest',
          payload: {
            'hitPoints': hero.hitPoints,
            'spentHitDice': hero.spentHitDice,
            'spellSlotsRestored': current.hero.spentSpellSlots,
            'pactSlotsRestored': current.hero.spentPactSlots,
            'exhaustionBefore': current.hero.exhaustionLevel,
            'exhaustionAfter': hero.exhaustionLevel,
          },
        );
      } on StateError catch (error) {
        return _commit(
          campaign,
          current,
          error.message.toString(),
          type: 'rules.blocked',
        );
      } on FormatException catch (error) {
        return _commit(campaign, current, error.message, type: 'rules.blocked');
      } on RangeError {
        return _commit(
          campaign,
          current,
          'Ungültige Anzahl Trefferwürfel.',
          type: 'rules.blocked',
        );
      }
    }
    if (current.storyBible['mode'] == RabenwachtCampaign.mode) {
      if (current.encounter != null && !current.encounter!.isFinished) {
        return _combatAction(campaign, current, words);
      }
      if (RegExp(r'heiltrank|trank.*trink|trink.*trank').hasMatch(words)) {
        return _drinkPotion(campaign, current);
      }
      final scripted = RabenwachtCampaign.advance(
        current,
        text,
        rollId: _id('roll'),
      );
      if (!scripted.battle) {
        return _commit(
          campaign,
          scripted.campaign,
          scripted.narration,
          type: scripted.campaign.pendingRoll != null
              ? 'roll.requested'
              : 'narrative.turn',
        );
      }
      if (!current.hero.isComplete) {
        return _commit(
          campaign,
          current,
          'Für diesen Kampf benötigt dein Held einen vollständigen Charakterbogen.',
          type: 'rules.blocked',
        );
      }
      final enemy = AdventureCatalog.forHero('skeleton', current.hero);
      final initiative = CharacterRuleEngine.initiative(current.hero);
      final heroRoll = dice.check(
        modifier: initiative.modifier,
        advantage: initiative.advantage,
        disadvantage: initiative.disadvantage,
      );
      final foeRoll = dice.check(modifier: 2);
      final focus = MonkPerfectFocus.onInitiative(current.hero);
      var started = scripted.campaign.copyWith(
        hero: focus.hero,
        encounter: Encounter(
          id: _id('encounter'),
          enemyName: enemy.name,
          enemyHitPoints: enemy.hitPoints,
          enemyMaxHitPoints: enemy.hitPoints,
          enemyArmorClass: enemy.armorClass,
          enemyAttackBonus: enemy.attackBonus,
          enemyDamage: enemy.damage,
          heroInitiative: heroRoll.total,
          enemyInitiative: foeRoll.total,
          movementRemaining:
              CharacterRuleEngine.movementWholeMeters(current.hero)!,
        ),
      );
      var description = '${scripted.narration} Deine Initiative: '
          '${heroRoll.total}, Gegnerinitiative: ${foeRoll.total}. ';
      if (foeRoll.total > heroRoll.total) {
        final first = _enemyTurn(started, advanceRound: false);
        started = first.campaign;
        description += '${first.narration} ';
      }
      description += 'Du kannst angreifen, ausweichen, '
          'fliehen oder eine Klassenfähigkeit einsetzen.';
      return _commit(
        campaign,
        started,
        description,
        type: 'combat.started',
        payload: {
          'heroInitiative': heroRoll.toJson(),
          'enemyInitiative': foeRoll.toJson(),
          'adventure': 'rabenwacht',
        },
      );
    }
    // AI campaigns must NEVER fall through into the fixed Mooswacht demo.
    // The external narrator handles free world actions; mechanical outcomes
    // remain local and require an explicitly confirmed encounter/rule source.
    if (current.storyBible['mode'] == 'ai') {
      if (current.encounter != null && !current.encounter!.isFinished) {
        return _combatAction(campaign, current, words);
      }
      if (RegExp(r'heiltrank|trank.*trink|trink.*trank').hasMatch(words)) {
        return _drinkPotion(campaign, current);
      }
      if (RegExp(
        r'angreif|attackier|schieß|schies|kämpf|kaempf',
      ).hasMatch(words)) {
        return _commit(
          campaign,
          current,
          'Ein Angriff benötigt zuerst einen bestätigten Gegner mit regelkonformen Werten. '
          'Die KI darf Trefferwürfe oder Schaden nicht selbst bestimmen.',
          type: 'rules.blocked',
        );
      }
      return _commit(
        campaign,
        current,
        'Deine Entscheidung wurde im Tagebuch festgehalten. Was möchtest du als Nächstes tun?',
      );
    }
    // Imported campaigns (including older user-created saves) are not a
    // hardcoded demo. Preserve their story and data; avoid accidentally
    // awarding Mooswacht items or applying its scripted quest mechanics.
    if (current.facts['origin'] != 'demo') {
      if (current.encounter != null && !current.encounter!.isFinished) {
        return _combatAction(campaign, current, words);
      }
      if (RegExp(
        r'angreif|attackier|schieß|schies|kämpf|kaempf|töte|heiltrank|trank.*trink|trink.*trank',
      ).hasMatch(words)) {
        return _commit(
          campaign,
          current,
          'Für diese Regelaktion fehlen bestätigte Gegner- oder Gegenstandswerte. '
          'Die importierte Geschichte bleibt unverändert; du kannst deine '
          'Charakter- und Kampfdaten ergänzen.',
          type: 'rules.blocked',
        );
      }
      return _commit(
        campaign,
        current,
        '${current.hero.name}, deine Entscheidung wurde im Tagebuch '
        'festgehalten. Die importierte Geschichte und ihre vorhandenen '
        'Erinnerungen bleiben erhalten. Was möchtest du als Nächstes tun?',
      );
    }
    if (current.encounter != null && !current.encounter!.isFinished) {
      return _combatAction(campaign, current, words);
    }
    if (RegExp(r'heiltrank|trank.*trink|trink.*trank').hasMatch(words)) {
      return _drinkPotion(campaign, current);
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
                '${current.facts['keyFound'] == 'true' ? 'Mit dem gefundenen Messingschlüssel kannst du den Schrein öffnen.' : 'Der Messingschlüssel am Dorfbrunnen fehlt dir noch.'} '
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
      final initiative = CharacterRuleEngine.initiative(current.hero);
      final heroInit = dice.check(
        modifier: initiative.modifier,
        advantage: initiative.advantage,
        disadvantage: initiative.disadvantage,
      );
      final foeInit = dice.check(modifier: 0);
      final focus = MonkPerfectFocus.onInitiative(current.hero);
      var next = current.copyWith(
        hero: focus.hero,
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
          movementRemaining: CharacterRuleEngine.movementWholeMeters(
            current.hero,
          )!,
        ),
      );
      var narration =
          '${current.hero.name}, ein Dornenwächter erhebt sich vor dem Schrein. Deine Initiative ist ${heroInit.total}, seine ${foeInit.total}. ';
      final details = <String, dynamic>{
        'heroInitiative': heroInit.toJson(),
        'enemyInitiative': foeInit.toJson(),
        'focusRecoveredAtInitiative': focus.recovered,
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
      final perception = CharacterRuleEngine.perception(current.hero);
      final bonus = perception.modifier;
      return _commit(
        campaign,
        current.copyWith(
          pendingRoll: PendingRoll(
            id: _id('roll'),
            type: 'perception',
            modifier: bonus,
            difficulty: 10,
            advantage: perception.advantage,
            disadvantage: perception.disadvantage,
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

  /// The bonus-action feature can defeat an enemy before or after the Attack
  /// action. Complete only confirmed AI quests; never fabricate rewards.
  Campaign _afterFlurryVictory(Campaign current, Map<String, dynamic> payload) {
    // Demo-only quest logic never applies to a manually imported campaign.
    if (current.storyBible['mode'] == RabenwachtCampaign.mode) {
      return current.copyWith(
        encounter: null,
        scene: 'Der Skelettwächter ist überwunden. Die Galerie liegt vor dir.',
        storyBible: {...current.storyBible, 'stage': 'seal'},
        facts: {...current.facts, 'sentryDefeated': 'true'},
      );
    }
    if (current.storyBible['mode'] != 'ai' &&
        current.facts['origin'] != 'demo') {
      return current.copyWith(encounter: null);
    }
    if (current.storyBible['mode'] != 'ai') {
      return current.copyWith(
        facts: {
          ...current.facts,
          'guardianDefeated': 'true',
          'dornenwächter':
              'Der Dornenwächter wurde im bestätigten Kampf überwunden.',
        },
      );
    }
    final questId = current.facts['aiEncounterQuestId'];
    final offerId = current.facts['aiEncounterOfferId'];
    final lootName = current.facts['aiEncounterLoot'];
    final valid =
        questId != null &&
        offerId != null &&
        lootName != null &&
        current.quests.any((q) => q.id == questId && q.status == 'active');
    if (!valid) {
      return current.copyWith(encounter: null);
    }
    final lootId = 'loot-$offerId';
    final inventory = current.hero.inventory.any((e) => e.id == lootId)
        ? current.hero.inventory
        : [
            ...current.hero.inventory,
            InventoryItem(
              id: lootId,
              name: lootName,
              description: 'Beute der bestätigten Begegnung.',
            ),
          ];
    payload['completedQuestId'] = questId;
    payload['rewardItemId'] = lootId;
    return current.copyWith(
      hero: current.hero.copyWith(inventory: inventory),
      quests: [
        for (final q in current.quests)
          q.id == questId ? q.copyWith(status: 'completed') : q,
      ],
      encounter: null,
      facts: {
        ...current.facts,
        'aiEncounterQuestId': '',
        'aiEncounterOfferId': '',
        'aiEncounterLoot': '',
        'aiQuestCompleted:$questId': 'true',
      },
    );
  }

  GameUpdate _combatAction(Campaign before, Campaign current, String words) {
    final encounter = current.encounter!;
    if (words.startsWith('selbstwiederherstellung')) {
      if (encounter.activeParticipant != 'hero') {
        return _commit(
          before,
          current,
          'Die Auswahl für Selbstwiederherstellung benötigt deinen eigenen Zug.',
          type: 'rules.blocked',
        );
      }
      final match = RegExp(
        r'^selbstwiederherstellung\s*:\s*(bezaubert|verängstigt|vergiftet)\s*[.!?]?$',
      ).firstMatch(words);
      if (match == null) {
        return _commit(
          before,
          current,
          'Bitte wähle genau einen Zustand: Bezaubert, Verängstigt oder Vergiftet.',
          type: 'rules.blocked',
        );
      }
      final choice = match.group(1)!;
      try {
        MonkSelfRestoration.validateChoice(current.hero, choice);
        return _commit(
          before,
          current.copyWith(
            encounter: encounter.copyWith(selfRestorationChoice: choice),
          ),
          'Selbstwiederherstellung vorbereitet: $choice. Der Zustand endet '
          'am Ende deines Zugs, nicht sofort.',
          type: 'class.selfRestorationSelected',
          payload: {'condition': choice},
        );
      } on StateError catch (error) {
        return _commit(
          before,
          current,
          error.message.toString(),
          type: 'rules.blocked',
        );
      }
    }
    if (!ConditionRules.canTakeActions(current.hero) &&
        !RegExp(r'beweg|lauf|geh').hasMatch(words)) {
      return _commit(
        before,
        current,
        'Dein aktueller Zustand verhindert diese Kampfhandlung.',
        type: 'rules.blocked',
      );
    }
    if (RegExp(
      r'kampfrausch.*verlänger|kampfrausch.*verlaenger',
    ).hasMatch(words)) {
      if (!CombatClassActions.rageActive(encounter) ||
          encounter.bonusActionUsed) {
        return _commit(
          before,
          current,
          'Kampfrausch verlängern erfordert aktiven Kampfrausch und eine freie Bonusaktion.',
          type: 'rules.blocked',
        );
      }
      final until = encounter.round + 1;
      final hardEnd = encounter.rageStartedRound + 99;
      final nextUntil = until < hardEnd ? until : hardEnd;
      return _commit(
        before,
        current.copyWith(
          encounter: encounter.copyWith(
            bonusActionUsed: true,
            rageUntilRound: nextUntil,
          ),
        ),
        'Du verlängerst deinen Kampfrausch bis zum Ende des nächsten Zugs.',
        type: 'class.rageExtended',
        payload: {'rageUntilRound': nextUntil},
      );
    }
    if (RegExp(r'kampfrausch|\brage\b').hasMatch(words)) {
      if (encounter.bonusActionUsed ||
          CombatClassActions.rageActive(encounter)) {
        return _commit(
          before,
          current,
          'Bonusaktion bereits verbraucht oder Kampfrausch aktiv.',
          type: 'rules.blocked',
        );
      }
      try {
        if (CombatClassActions.hasHeavyArmor(current.hero)) {
          throw StateError(
            'Mit schwerer Rüstung ist Kampfrausch nicht möglich.',
          );
        }
        final hero = ClassResourceRules.spend(
          current.hero,
          'rage',
        ).copyWith(concentratingOn: '');
        return _commit(
          before,
          current.copyWith(
            hero: hero,
            encounter: encounter.copyWith(
              bonusActionUsed: true,
              rageStartedRound: encounter.round,
              rageUntilRound: encounter.round + 1,
            ),
          ),
          'Kampfrausch aktiviert. Ein Angriff verlängert ihn bis zum Ende '
          'deines nächsten Zugs; deine Konzentration endet.',
          type: 'class.rage',
          payload: {
            'spentRage': hero.spentClassResources['rage'],
            'rageUntilRound': encounter.round + 1,
          },
        );
      } on StateError catch (e) {
        return _commit(
          before,
          current,
          e.message.toString(),
          type: 'rules.blocked',
        );
      }
    }
    if (RegExp(r'schlaghagel|flurry of blows').hasMatch(words)) {
      try {
        final flurry = MonkFlurryRules.use(current.hero, encounter, dice);
        var next = current.copyWith(
          hero: flurry.hero,
          encounter: flurry.encounter,
        );
        final payload = <String, dynamic>{
          'focusSpent': 1,
          'remainingFocus': ClassResourceRules.remaining(
            flurry.hero,
            'focusPoints',
          ),
          'strikes': [for (final strike in flurry.strikes) strike.toJson()],
          'damage': flurry.damageTotal,
        };
        var narration =
            'Schlaghagel: ${flurry.strikes.length} '
            'unbewaffnete Angriffe, ${flurry.damageTotal} Schaden. ';
        if (flurry.encounter.isFinished) {
          next = _afterFlurryVictory(next, payload);
          narration += 'Der ${encounter.enemyName} ist besiegt. ';
        } else if (flurry.encounter.actionUsed &&
            flurry.encounter.attacksRemaining == 0 &&
            !flurry.encounter.surgeReserved) {
          final turn = _enemyTurn(next);
          next = turn.campaign;
          payload['enemyTurn'] = turn.details;
          narration += '${turn.narration} ${_nextInstruction(next)}';
        } else {
          narration +=
              'Du kannst deine regulären Angriffe fortsetzen '
              'oder deinen Zug beenden.';
        }
        return _commit(
          before,
          next,
          narration,
          type: 'class.flurryOfBlows',
          payload: payload,
        );
      } on StateError catch (error) {
        return _commit(
          before,
          current,
          error.message.toString(),
          type: 'rules.blocked',
        );
      } on FormatException catch (error) {
        return _commit(before, current, error.message, type: 'rules.blocked');
      }
    }
    // Free / empowered Monk Focus actions. Enhanced choices cost one point.
    if (RegExp(r'geduldige verteidigung|schritt des windes').hasMatch(words)) {
      final patient = words.contains('geduldige verteidigung');
      final enhanced = RegExp(
        r'verstärkt|verstaerkt|mit fokus|fokuspunkt',
      ).hasMatch(words);
      try {
        final used = MonkFocusActions.use(
          current.hero,
          encounter,
          action: patient
              ? MonkBonusAction.patientDefense
              : MonkBonusAction.stepOfTheWind,
          enhanced: enhanced,
          dice: dice,
        );
        final remaining = ClassResourceRules.remaining(
          used.hero,
          'focusPoints',
        );
        return _commit(
          before,
          current.copyWith(hero: used.hero, encounter: used.encounter),
          patient
              ? (enhanced
                    ? 'Geduldige Verteidigung: Rückzug und Ausweichen als Bonusaktion. '
                          'Der nächste Gegnerangriff in diesem Kampfzug hat Nachteil, sofern kein Vorteil entgegenwirkt.'
                          '${used.temporaryHitPointsRolled > 0 ? ' Du erhältst ${used.temporaryHitPointsRolled} gewürfelte temporäre Trefferpunkte (aktuell ${used.hero.temporaryHitPoints}).' : ''}'
                    : 'Geduldige Verteidigung: Rückzug als Bonusaktion (ohne Fokuskosten).')
              : (enhanced
                    ? 'Schritt des Windes: Sprinten und Rückzug; deine Sprungweite ist '
                          'in diesem Zug verdoppelt.'
                    : 'Schritt des Windes: Sprinten als Bonusaktion (ohne Fokuskosten).'),
          type: patient ? 'class.patientDefense' : 'class.stepOfTheWind',
          payload: {
            'focusSpent': used.focusSpent,
            'remainingFocus': remaining,
            'addedMovement': used.movementAdded,
            'temporaryHitPointsRolled': used.temporaryHitPointsRolled,
            'temporaryHitPoints': used.hero.temporaryHitPoints,
            'dodgeActive': used.encounter.dodgeActive,
            'disengagedThisTurn': used.encounter.disengagedThisTurn,
            'jumpDoubledThisTurn': used.encounter.jumpDoubledThisTurn,
          },
        );
      } on StateError catch (e) {
        return _commit(
          before,
          current,
          e.message.toString(),
          type: 'rules.blocked',
        );
      } on FormatException catch (e) {
        return _commit(before, current, e.message, type: 'rules.blocked');
      }
    }
    if (RegExp(
      r'flinke aktion.*(?:rückzug|rueckzug|disengage)|'
      r'(?:rückzug|rueckzug|disengage).*flinke aktion',
    ).hasMatch(words)) {
      if (ClassResourceRules.level(current.hero, 'Schurke') < 2 ||
          encounter.bonusActionUsed) {
        return _commit(
          before,
          current,
          'Flinke Aktion: Rückzug erfordert Schurkenstufe 2 und eine freie Bonusaktion.',
          type: 'rules.blocked',
        );
      }
      return _commit(
        before,
        current.copyWith(
          encounter: encounter.copyWith(
            bonusActionUsed: true,
            disengagedThisTurn: true,
          ),
        ),
        'Flinke Aktion: Du ziehst dich als Bonusaktion zurück. '
        'Gelegenheitsangriffe werden in diesem vereinfachten Kampf noch nicht berechnet.',
        type: 'class.cunningDisengage',
        payload: {'disengagedThisTurn': true},
      );
    }
    if (RegExp(
      r'flinke aktion.*(?:sprint|dash)|(?:sprint|dash).*flinke aktion',
    ).hasMatch(words)) {
      if (ClassResourceRules.level(current.hero, 'Schurke') < 2 ||
          encounter.bonusActionUsed ||
          !ConditionRules.canMove(current.hero)) {
        return _commit(
          before,
          current,
          'Flinke Aktion: Sprinten erfordert Schurkenstufe 2 und eine freie Bonusaktion.',
          type: 'rules.blocked',
        );
      }
      final additional =
          CharacterRuleEngine.movementWholeMeters(current.hero) ?? 0;
      final remaining = encounter.movementRemaining + additional;
      return _commit(
        before,
        current.copyWith(
          encounter: encounter.copyWith(
            movementRemaining: remaining,
            bonusActionUsed: true,
          ),
        ),
        'Flinke Aktion: Du sprintest als Bonusaktion. '
        'Dir stehen in diesem Zug insgesamt noch $remaining Meter zur Verfügung.',
        type: 'class.cunningDash',
        payload: {'addedMovement': additional},
      );
    }
    if (RegExp(r'action surge|aktionsschub').hasMatch(words)) {
      if (encounter.surgeUsedThisTurn) {
        return _commit(
          before,
          current,
          'Action Surge ist pro Zug nur einmal möglich.',
          type: 'rules.blocked',
        );
      }
      try {
        final hero = ClassFeatureResources.spendActionSurge(current.hero);
        return _commit(
          before,
          current.copyWith(
            hero: hero,
            encounter: encounter.copyWith(
              surgeReserved: true,
              surgeUsedThisTurn: true,
            ),
          ),
          'Action Surge aktiviert: In diesem Zug kannst du nach deiner '
          'regulären Angriffsaktion noch eine weitere Angriffsaktion ausführen. '
          'Eine Magieaktion ist hier ausgeschlossen.',
          type: 'class.actionSurge',
          payload: {'spentActionSurge': hero.spentActionSurge},
        );
      } on StateError catch (error) {
        return _commit(
          before,
          current,
          error.message.toString(),
          type: 'rules.blocked',
        );
      } on FormatException catch (error) {
        return _commit(before, current, error.message, type: 'rules.blocked');
      }
    }
    final offhandCommand = RegExp(
      r'^nebenhandangriff(?:\s+mit\s+(.+?)|\s*:\s*(.+?))\s*[.!?]?$',
    ).firstMatch(words);
    if (words.startsWith('nebenhandangriff')) {
      if (offhandCommand == null ||
          !encounter.actionUsed ||
          encounter.attacksRemaining != 0 ||
          encounter.bonusActionUsed ||
          !encounter.lightAttackAvailable ||
          encounter.surgeReserved) {
        return _commit(
          before,
          current,
          'Nebenhandangriff benötigt eine vorherige Angriffsaktion mit einer '
          'leichten Waffe, eine freie Bonusaktion und eine bestätigte Zweitwaffe. '
          'Nutze: Nebenhandangriff mit Dolch.',
          type: 'rules.blocked',
        );
      }
      final selected = (offhandCommand.group(1) ?? offhandCommand.group(2)!)
          .trim();
      final choices = TwoWeaponFightingRules.offhandChoices(current.hero)
          .where(
            (item) =>
                item.id.toLowerCase() == selected ||
                item.name.toLowerCase() == selected,
          )
          .toList();
      if (choices.length != 1) {
        return _commit(
          before,
          current,
          'Nebenhandwaffe nicht eindeutig bestätigt. '
          'Nutze den eindeutigen Inventar-Namen oder die Gegenstand-ID.',
          type: 'rules.blocked',
        );
      }
      final offhand = TwoWeaponFightingRules.confirmedOffhand(
        current.hero,
        choices.single.id,
      )!;
      final attackRule = CharacterRuleEngine.attack(current.hero);
      final bonus = TwoWeaponFightingRules.attackBonus(current.hero, offhand);
      return _commit(
        before,
        current.copyWith(
          encounter: encounter.copyWith(bonusActionUsed: true),
          pendingRoll: PendingRoll(
            id: _id('roll'),
            type: 'offhandAttack',
            modifier: bonus,
            advantage: attackRule.advantage,
            disadvantage: attackRule.disadvantage,
            difficulty: encounter.enemyArmorClass,
            targetId: encounter.id,
            targetName: encounter.enemyName,
            weaponId: choices.single.id,
          ),
        ),
        'Nebenhandangriff mit ${choices.single.name}: Würfle W20 '
        '${_signed(bonus)} gegen RK ${encounter.enemyArmorClass}. '
        'Die Bonusaktion ist reserviert.',
        type: 'roll.requested',
        payload: {'offhandWeaponId': choices.single.id},
      );
    }
    if (encounter.actionUsed &&
        RegExp(
          r'ausweich|weich\w*\s+aus|verteidig|flieh|flucht|wegrenn|heiltrank|trank.*trink|trink.*trank',
        ).hasMatch(words)) {
      return _commit(
        before,
        current,
        'Deine Angriffsaktion wurde bereits begonnen. Du kannst weitere '
        'Angriffe ausführen, eine freie Bonusaktion wählen, dich bewegen '
        'oder den Zug beenden; keine zweite volle Aktion beginnen.',
        type: 'rules.blocked',
      );
    }
    if (RegExp(
      r'angreif|attackier|greif\w*.*\ban(?:[.!?]|$)|schieß|schies|schlag|hieb|bogen|schwert',
    ).hasMatch(words)) {
      if (encounter.actionUsed && encounter.attacksRemaining == 0) {
        return _commit(
          before,
          current,
          'Deine Angriffsaktion ist bereits verbraucht.',
          type: 'rules.blocked',
        );
      }
      final attack = CharacterRuleEngine.attack(current.hero);
      final bonus = attack.modifier;
      return _commit(
        before,
        current.copyWith(
          pendingRoll: PendingRoll(
            id: _id('roll'),
            type: 'attack',
            modifier: bonus,
            advantage: attack.advantage,
            disadvantage: attack.disadvantage,
            difficulty: encounter.enemyArmorClass,
            targetId: encounter.id,
            targetName: encounter.enemyName,
          ),
        ),
        '${current.hero.name}, würfle einen W20 für deinen Angriff auf den ${encounter.enemyName}. Dein Angriffsbonus ist ${_signed(bonus)} (${attack.rollHint}); seine Rüstungsklasse beträgt ${encounter.enemyArmorClass}.',
        type: 'roll.requested',
      );
    }
    if (RegExp(r'flieh|flucht|wegrenn').hasMatch(words)) {
      final escape = CharacterRuleEngine.abilityCheck(
        current.hero,
        'dexterity',
      );
      return _commit(
        before,
        current.copyWith(
          pendingRoll: PendingRoll(
            id: _id('roll'),
            type: 'escape',
            modifier: escape.modifier,
            advantage: escape.advantage,
            disadvantage: escape.disadvantage,
            difficulty: 10,
          ),
        ),
        'Bitte würfle einen W20 für die Flucht. Die Schwierigkeit beträgt 10.',
      );
    }
    if (RegExp(r'heiltrank|trank.*trink|trink.*trank').hasMatch(words)) {
      return _drinkPotion(before, current);
    }
    if (RegExp(
      r'ausweich|weich\w*\s+aus|verteidig|warten|zug beenden|beende(?:\s+\w+){0,2}\s+zug',
    ).hasMatch(words)) {
      final dodge = RegExp(
        r'ausweich|weich\w*\s+aus|verteidig',
      ).hasMatch(words);
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
      if (current.hero.conditions.contains('liegend')) {
        return _commit(
          before,
          current,
          'Du liegst am Boden und kannst nicht normal laufen. '
          'Stehe zuerst regelkonform auf. Kriechen wird noch nicht '
          'automatisch berechnet.',
          type: 'rules.blocked',
        );
      }
      if ((CharacterRuleEngine.movementWholeMeters(current.hero) ?? 0) <= 0) {
        return _commit(
          before,
          current,
          'Dein Zustand oder deine Bewegungsrate erlaubt keine Bewegung.',
          type: 'rules.blocked',
        );
      }
      final amount =
          int.tryParse(
            RegExp(r'(\d+)\s*(?:m|meter)').firstMatch(words)?.group(1) ?? '',
          ) ??
          3;
      if (amount <= 0 || amount > encounter.movementRemaining) {
        return _commit(
          before,
          current,
          'Für diese Bewegung reichen die verbleibenden ${encounter.movementRemainingLabel} nicht aus. Deine Aktion ist weiterhin verfügbar.',
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
        'Du bewegst dich $amount Meter. In diesem Zug bleiben ${encounter.copyWith(movementRemaining: encounter.movementRemaining - amount).movementRemainingLabel}; deine Aktion ist verfügbar.',
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
    if (pending.type == 'death') Campaign.fromJson(campaign.toJson());
    final result = dice.check(
      modifier: pending.modifier,
      natural: natural,
      total: total,
      advantage: pending.advantage,
      disadvantage: pending.disadvantage,
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
      final resolved = DeathSavingThrowRules.resolve(
        hero: next.hero,
        natural: result.natural!,
      );
      if (!resolved.passed &&
          SavingThrowRerollFeature.values.any(
            (feature) => DeathSavingThrowRules.canReroll(resolved, feature),
          )) {
        return _commit(
          campaign,
          next.copyWith(
            pendingDeathSave: PendingDeathSave(
              originalNatural: result.natural!,
              modifier: resolved.roll.modifier,
            ),
          ),
          'Vorläufiger Todesrettungswurf: ${resolved.roll.total} – misslungen. '
          'Die Folgen sind noch nicht gebucht. Nimm den Wurf an oder wähle eine verfügbare Klassenwiederholung.',
          type: 'deathSave.choicePending',
          payload: {
            ...payload,
            'roll': resolved.roll.toJson(),
            'provisional': true,
          },
        );
      }
      return _completeDeathSave(campaign, next, resolved, payload: payload);
    } else if (pending.type == 'attack' || pending.type == 'offhandAttack') {
      final isOffhand = pending.type == 'offhandAttack';
      final offhand = isOffhand
          ? TwoWeaponFightingRules.confirmedOffhand(next.hero, pending.weaponId)
          : null;
      if (isOffhand && offhand == null) {
        throw StateError('Nebenhandwaffe nicht mehr bestätigt.');
      }
      final foe = next.encounter;
      if (foe == null || foe.id != pending.targetId || foe.isFinished) {
        throw StateError('Das Angriffsziel ist nicht mehr gültig.');
      }
      final outcome = RulesEngine.attack(
        roll: result,
        armorClass: foe.enemyArmorClass,
        criticalThreshold: ClassCombatFeatures.weaponCriticalThreshold(
          next.hero,
        ),
      );
      // A regular Attack action may contain multiple separate attack rolls.
      // Resolve each roll/damage independently and give the enemy exactly one
      // turn when the sequence finishes (or the player ends their turn).
      final attacksRemaining = isOffhand
          ? foe.attacksRemaining
          : foe.actionUsed
          ? foe.attacksRemaining - 1
          : ClassProgressionRules.attacksPerAttackAction(next.hero) - 1;
      if (attacksRemaining < 0) {
        throw StateError('Die Angriffsaktion ist bereits abgeschlossen.');
      }
      payload['attacksRemaining'] = attacksRemaining;
      if (isOffhand) {
        payload['offhandWeaponId'] = pending.weaponId;
        payload['bonusActionUsed'] = true;
      }
      final rolledFight = CombatClassActions.onAttackRoll(foe);
      if (rolledFight.rageUntilRound != foe.rageUntilRound) {
        payload['rageExtendedUntilRound'] = rolledFight.rageUntilRound;
      }
      if (outcome.hit) {
        final expression = isOffhand
            ? offhand!.damage!
            : next.hero.weaponDamage;
        final base = dice.roll(expression);
        final extra = outcome.critical ? dice.roll(expression) : null;
        final weaponDamage = isOffhand
            ? TwoWeaponFightingRules.damage(
                next.hero,
                offhand!,
                base.total + (extra?.total ?? 0),
              )
            : RulesEngine.weaponDamage(
                next.hero,
                baseRoll: base,
                criticalExtra: extra,
              );
        final rageBonus = CombatClassActions.rageDamageBonus(
          next.hero,
          rolledFight,
        );
        final sneakDice = ClassCombatFeatures.eligibleSneakAttackDice(
          next.hero,
          hasAdvantage: pending.advantage,
          hasDisadvantage: pending.disadvantage,
          adjacentConsciousAlly: false, // No confirmed ally positioning yet.
          alreadyUsedThisTurn: foe.sneakAttackUsedThisTurn,
        );
        final sneakRoll = sneakDice > 0
            ? ClassCombatFeatures.rollSneakAttack(
                dice,
                sneakDice,
                critical: outcome.critical,
              )
            : null;
        final damage = weaponDamage + rageBonus + (sneakRoll?.total ?? 0);
        if (rageBonus > 0) payload['rageDamageBonus'] = rageBonus;
        if (sneakRoll != null) payload['sneakAttackRoll'] = sneakRoll.toJson();
        final hp = RulesEngine.remainingHitPoints(
          hitPoints: foe.enemyHitPoints,
          damage: damage,
        );
        payload['damageRoll'] = base.toJson();
        payload['criticalExtra'] = extra?.toJson();
        payload['damage'] = damage;
        next = next.copyWith(
          encounter: rolledFight.copyWith(
            enemyHitPoints: hp,
            actionUsed: true,
            bonusActionUsed: isOffhand ? true : foe.bonusActionUsed,
            lightAttackAvailable: isOffhand
                ? false
                : (foe.lightAttackAvailable ||
                      TwoWeaponFightingRules.offhandChoices(
                        next.hero,
                      ).isNotEmpty),
            sneakAttackUsedThisTurn:
                foe.sneakAttackUsedThisTurn || sneakRoll != null,
            attacksRemaining: attacksRemaining,
          ),
          facts: next.storyBible['mode'] == 'ai'
              ? next.facts
              : {...next.facts, 'guardianHitPoints': '$hp'},
        );
        narration +=
            '${outcome.critical ? 'Ein kritischer Treffer! ' : ''}Du verursachst $damage Schaden; der ${foe.enemyName} hat noch $hp Trefferpunkte. ';
      } else {
        next = next.copyWith(
          encounter: rolledFight.copyWith(
            actionUsed: true,
            bonusActionUsed: isOffhand ? true : foe.bonusActionUsed,
            lightAttackAvailable: isOffhand
                ? false
                : (foe.lightAttackAvailable ||
                      TwoWeaponFightingRules.offhandChoices(
                        next.hero,
                      ).isNotEmpty),
            attacksRemaining: attacksRemaining,
          ),
        );
        narration += 'Dein Angriff verfehlt den ${foe.enemyName}. ';
      }
      if (next.encounter!.isFinished) {
        if (next.storyBible['mode'] == 'ai') {
          final questId = next.facts['aiEncounterQuestId'];
          final offerId = next.facts['aiEncounterOfferId'];
          final lootName = next.facts['aiEncounterLoot'];
          final valid =
              questId != null &&
              offerId != null &&
              lootName != null &&
              next.quests.any((q) => q.id == questId && q.status == 'active');
          if (valid) {
            final lootId = 'loot-$offerId';
            final inventory = next.hero.inventory.any((e) => e.id == lootId)
                ? next.hero.inventory
                : [
                    ...next.hero.inventory,
                    InventoryItem(
                      id: lootId,
                      name: lootName,
                      description: 'Beute der bestätigten Begegnung.',
                    ),
                  ];
            next = next.copyWith(
              hero: next.hero.copyWith(inventory: inventory),
              quests: [
                for (final q in next.quests)
                  q.id == questId ? q.copyWith(status: 'completed') : q,
              ],
              encounter: null,
              facts: {
                ...next.facts,
                'aiEncounterQuestId': '',
                'aiEncounterOfferId': '',
                'aiEncounterLoot': '',
                'aiQuestCompleted:$questId': 'true',
              },
            );
            payload['completedQuestId'] = questId;
            payload['rewardItemId'] = lootId;
            narration +=
                'Die Begegnung ist gewonnen. Dein Auftrag ist '
                'abgeschlossen; als bestätigte Beute erhältst du $lootName. ';
          } else {
            next = next.copyWith(encounter: null);
            narration += 'Du hast den Gegner überwunden. ';
          }
        } else {
          next = next.copyWith(
            facts: {
              ...next.facts,
              'guardianDefeated': 'true',
              'dornenwächter':
                  'Der Dornenwächter wurde im bestätigten Kampf überwunden.',
            },
          );
          narration +=
              'Der Dornenwächter zerfällt in Blätter. '
              'Der Weg zum Schrein ist frei. Was möchtest du tun?';
        }
      } else if (next.encounter!.attacksRemaining == 0 &&
          next.encounter!.surgeReserved) {
        next = next.copyWith(
          encounter: next.encounter!.copyWith(
            actionUsed: false,
            surgeReserved: false,
          ),
        );
        narration +=
            'Action Surge: Du kannst noch eine zusätzliche '
            'Angriffsaktion beginnen oder deinen Zug beenden. ';
      } else if (next.encounter!.attacksRemaining == 0 &&
          next.encounter!.lightAttackAvailable &&
          !next.encounter!.bonusActionUsed &&
          !next.encounter!.surgeReserved) {
        narration +=
            'Du kannst jetzt einen Nebenhandangriff als Bonusaktion '
            'ausführen (Nebenhandangriff mit Waffenname) oder deinen Zug beenden.';
      } else if (next.encounter!.attacksRemaining == 0 &&
          MonkFlurryRules.canUse(next.hero, next.encounter!) &&
          !next.encounter!.surgeReserved) {
        narration +=
            'Du kannst jetzt Schlaghagel als Bonusaktion einsetzen '
            'oder deinen Zug beenden.';
      } else if (next.encounter!.attacksRemaining > 0) {
        narration +=
            'Du kannst in derselben Angriffsaktion noch '
            '${next.encounter!.attacksRemaining} '
            '${next.encounter!.attacksRemaining == 1 ? 'Angriff' : 'Angriffe'} '
            'ausführen oder deinen Zug beenden.';
      } else {
        final turn = _enemyTurn(next);
        next = turn.campaign;
        payload['enemyTurn'] = turn.details;
        narration += '${turn.narration} ${_nextInstruction(next)}';
      }
    } else if (pending.type == 'escape') {
      if (result.total >= pending.difficulty) {
        if (next.storyBible['mode'] == 'ai') {
          final questId = next.facts['aiEncounterQuestId'];
          next = next.copyWith(
            encounter: null,
            quests: [
              for (final q in next.quests)
                q.id == questId ? q.copyWith(status: 'failed') : q,
            ],
            facts: {
              ...next.facts,
              'aiEncounterQuestId': '',
              'aiEncounterOfferId': '',
              'aiEncounterLoot': '',
            },
          );
          narration +=
              'Du entkommst dem Kampf. Der Auftrag gilt als gescheitert; '
              'du erhältst keine Kampfbelohnung. Was möchtest du tun?';
        } else {
          next = next.copyWith(
            encounter: null,
            scene: 'Du bist zum sicheren Dorf Mooswacht zurückgekehrt.',
            facts: {...next.facts, 'location': 'Mooswacht'},
          );
          narration +=
              'Du entkommst den Dornen und erreichst das Dorf. '
              'Der Wächter bewacht weiterhin den Schrein. Was möchtest du tun?';
        }
      } else {
        final turn = _enemyTurn(next);
        next = turn.campaign;
        payload['enemyTurn'] = turn.details;
        narration +=
            'Die Dornen halten dich auf. ${turn.narration} ${_nextInstruction(next)}';
      }
    } else if (pending.type == 'perception') {
      if (next.storyBible['mode'] == 'ai' &&
          (next.facts['aiEncounterQuestId'] ?? '').isNotEmpty &&
          next.encounter == null) {
        final questId = next.facts['aiEncounterQuestId']!;
        final offerId = next.facts['aiEncounterOfferId']!;
        final success = result.total >= pending.difficulty;
        final lootId = 'loot-$offerId';
        next = next.copyWith(
          quests: [
            for (final q in next.quests)
              q.id == questId
                  ? q.copyWith(status: success ? 'completed' : 'failed')
                  : q,
          ],
          hero: success && !next.hero.inventory.any((item) => item.id == lootId)
              ? next.hero.copyWith(
                  inventory: [
                    ...next.hero.inventory,
                    InventoryItem(
                      id: lootId,
                      name: 'Spurenkarte',
                      description: 'Fund einer bestätigten Wahrnehmungsprobe.',
                    ),
                  ],
                )
              : next.hero,
          facts: {
            ...next.facts,
            'aiEncounterQuestId': '',
            'aiEncounterOfferId': '',
            'aiEncounterLoot': '',
            if (success) 'aiQuestCompleted:$questId': 'true',
          },
        );
        payload['completedQuestId'] = success ? questId : null;
        narration += success
            ? 'Du findest die entscheidende Spur! Der Auftrag ist abgeschlossen. '
                  'Du erhältst eine Spurenkarte als erzählerische Belohnung.'
            : 'Die Spur bleibt verborgen. Der Auftrag ist gescheitert; '
                  'es gibt keine Belohnung. Du kannst einen anderen Weg wählen.';
      } else if (result.total >= pending.difficulty) {
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
              ? [e.copyWith(quantity: e.quantity - 1)]
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
    final originalFight = campaign.encounter!;
    var foe = advanceRound
        ? CombatClassActions.afterHeroTurn(originalFight)
        : originalFight;
    var hero = campaign.hero;
    if (advanceRound) {
      hero = ConditionEffectRules.expireAtOwnTurnEnd(
        hero,
        encounterId: originalFight.id,
        round: originalFight.round,
      );
    }
    final rageExpired =
        originalFight.rageUntilRound > 0 && foe.rageUntilRound == 0;
    final incapacitated =
        !ConditionRules.canTakeActions(hero) || hero.hitPoints == 0;
    final rageEndedByIncapacitation = incapacitated && foe.rageUntilRound > 0;
    if (incapacitated) {
      hero = SpellcastingRules.endConcentration(hero);
      foe = foe.copyWith(
        rageStartedRound: 0,
        rageUntilRound: 0,
        dodgeActive: false,
      );
    }
    var restored = '';
    var restorationChoiceRequired = false;
    if (advanceRound) {
      final resolution = MonkSelfRestoration.atEndOfTurn(
        hero,
        choice: foe.selfRestorationChoice,
      );
      hero = resolution.hero;
      restored = resolution.removed;
      restorationChoiceRequired = resolution.choiceRequired;
    }
    final result = dice.check(
      modifier: foe.enemyAttackBonus,
      advantage: ConditionRules.hasUnconditionalAttackerAdvantage(hero),
      disadvantage:
          (disadvantage || foe.dodgeActive) &&
          ConditionRules.canTakeActions(hero) &&
          (CharacterRuleEngine.speedMeters(hero) ?? 0) > 0 &&
          !ConditionRules.has(hero, 'blind'),
    );
    final outcome = RulesEngine.attack(
      roll: result,
      armorClass: hero.armorClass!,
    );
    var narration =
        'Der ${foe.enemyName} greift an: ${result.total} gegen deine Rüstungsklasse ${hero.armorClass}. ';
    final details = <String, dynamic>{
      'attackRoll': result.toJson(),
      'hit': outcome.hit,
      if (rageExpired) 'rageExpiredAtTurnEnd': true,
      if (rageEndedByIncapacitation) 'rageEndedByIncapacitation': true,
    };
    if (restored.isNotEmpty) {
      details['selfRestorationRemoved'] = restored;
      narration = 'Selbstwiederherstellung beendet $restored. $narration';
    } else if (restorationChoiceRequired) {
      details['selfRestorationChoiceRequired'] = true;
      narration =
          'Selbstwiederherstellung wurde nicht eingesetzt: '
          'Mehrere Zustände waren vorhanden, aber keiner ausgewählt. $narration';
    }
    if (outcome.hit) {
      final damageRoll = dice.roll(foe.enemyDamage);
      final extra = outcome.critical ? dice.roll(foe.enemyDamage) : null;
      final rawDamage =
          damageRoll.total + (extra == null ? 0 : extra.total - extra.modifier);
      final effect = foe.enemyDamageType.isEmpty
          ? CharacterEffectRules.untypedDamage(
              hero,
              amount: rawDamage,
              dice: dice,
              critical: outcome.critical,
            )
          : CharacterEffectRules.damage(
              hero,
              components: [
                DamageComponent(
                  DamageType.values.byName(foe.enemyDamageType),
                  rawDamage,
                ),
              ],
              defenses: CharacterEffectRules.defensesFor(hero, encounter: foe),
              dice: dice,
              critical: outcome.critical,
            );
      final damage = effect.damage;
      if (damage != rawDamage) {
        details['rawDamage'] = rawDamage;
        details['damageDefenseReduction'] = rawDamage - damage;
        if (CombatClassActions.rageActive(foe)) {
          details['rageResistanceReduction'] = rawDamage - damage;
        }
      }
      hero = effect.hero;
      details.addAll(effect.toJson());
      if (effect.concentrationSave != null) {
        narration += effect.concentrationLost
            ? ' Konzentration verloren (${effect.concentrationSave!.total} gegen SG ${effect.concentrationDc}).'
            : ' Konzentrationsrettungswurf geschafft (${effect.concentrationSave!.total} gegen SG ${effect.concentrationDc}).';
      } else if (effect.concentrationLost) {
        narration += ' Deine Konzentration endet.';
      }
      details['damageRoll'] = damageRoll.toJson();
      details['criticalExtra'] = extra?.toJson();
      details['damage'] = damage;
      narration +=
          'Du erleidest $damage Schaden und hast noch ${hero.hitPoints} Trefferpunkte'
          '${hero.temporaryHitPoints > 0 ? ' und ${hero.temporaryHitPoints} temporäre Trefferpunkte' : ''}.';
    } else {
      narration += 'Der Angriff verfehlt dich.';
    }
    final afterTurn =
        !ConditionRules.canTakeActions(hero) || hero.hitPoints == 0
        ? foe.copyWith(rageStartedRound: 0, rageUntilRound: 0)
        : foe;
    return _EnemyTurn(
      campaign.copyWith(
        hero: hero,
        encounter: afterTurn.copyWith(
          round: foe.round + (advanceRound ? 1 : 0),
          activeParticipant: 'hero',
          movementRemaining: CharacterRuleEngine.movementWholeMeters(hero)!,
          movementRemainderDecimeters: 0,
          actionUsed: false,
          attacksRemaining: 0,
          bonusActionUsed: false,
          lightAttackAvailable: false,
          spellSlotExpendedThisTurn: false,
          deathSaveResolvedThisTurn: false,
          dodgeActive: false,
          disengagedThisTurn: false,
          jumpDoubledThisTurn: false,
          reactionUsed: false,
          surgeReserved: false,
          surgeUsedThisTurn: false,
          sneakAttackUsedThisTurn: false,
          selfRestorationChoice: '',
        ),
      ),
      narration,
      details,
    );
  }

  String _nextInstruction(Campaign campaign) => campaign.hero.isDead
      ? 'Dein Held ist gestorben.'
      : campaign.hero.hitPoints == 0 &&
            campaign.encounter?.deathSaveResolvedThisTurn == true
      ? 'Die Todesrettung dieses Zugs ist abgeschlossen. Beende deinen Zug.'
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
        RegExp(
          r'\b(?:meine|unsere|bisherige)\s+geschichte\b',
        ).hasMatch(normalized) ||
        RegExp(r'\bwas\s+weisst\s+du\b').hasMatch(normalized) ||
        RegExp(
          r'\berzaehl\w*\s+(?:mir\s+)?(?:etwas\s+)?(?:ueber|von)\b',
        ).hasMatch(normalized);
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
      add(
        'Handlungsstrang $status: ${thread.title}',
        thread.description,
        priority: thread.status == 'open' ? 210 : 70,
      );
    }
    for (final note in campaign.npcRelationshipNotes.reversed) {
      final npc = campaign.npcs.where((entry) => entry.id == note.npcId);
      if (npc.isEmpty) continue;
      add(
        'Beziehung zu ${npc.first.name}: ${note.relationship}',
        note.note,
        priority: 220,
      );
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
        'Quests: ${campaign.quests.map((q) => '${q.title} (${questStatus(q.status)})').join('; ')}.',
      if (campaign.npcs.isNotEmpty)
        'Bekannte NPCs: ${campaign.npcs.map((n) => '${n.name} (${n.alive ? 'lebendig' : 'tot'}, ${n.relationship})').join('; ')}.',
      if (campaign.storyThreads.isNotEmpty)
        'Handlungsstränge: ${campaign.storyThreads.map((t) => '${t.title} (${threadStatus(t.status)})').join('; ')}.',
      if (campaign.facts.isNotEmpty)
        'Bestätigte Fakten: ${campaign.facts.entries.map((f) => '${f.key}: ${f.value}').join('; ')}.',
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
      'npcRelationshipNotes': campaign.npcRelationshipNotes
          .map((e) => e.toJson())
          .toList(),
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
