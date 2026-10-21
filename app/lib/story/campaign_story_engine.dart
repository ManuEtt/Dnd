import 'dart:convert';

import '../domain/ai_story.dart';
import '../domain/campaign_event_committer.dart';
import '../domain/models.dart';
import '../domain/rabenwacht_campaign.dart';

/// Story-only mutable-world orchestration.
///
/// No dice engine or attack/spell rule imports are permitted here. Narrative
/// proposals cannot directly change HP, spells, inventory or combat rules.
/// The legacy facade in game_engine.dart delegates to this service without
/// changing existing GameController methods or campaign saves.
class CampaignStoryEngine {
  CampaignStoryEngine({
    required this.newId,
    required this.clock,
    required this.events,
    required this.sessionSummary,
  });

  final String Function(String prefix) newId;
  final DateTime Function() clock;
  final CampaignEventCommitter events;
  final String Function(Campaign campaign) sessionSummary;

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
        canonicalJson(campaign.events.last.toJson()) !=
            canonicalJson(original.toJson())) {
      throw const FormatException(
        'Nur die aktuelle freie Erzählung darf ersetzt werden.',
      );
    }
    if (campaign.messages.isEmpty || campaign.messages.last.role != 'gm') {
      throw const FormatException('Die aktuelle Spielleiterantwort fehlt.');
    }
    final checkpoint = original.payload['stateAfter'];
    if (checkpoint is! Map<String, dynamic> ||
        canonicalJson(checkpoint) !=
            canonicalJson(campaign.copyWith(events: const []).toJson())) {
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
      id: newId('story'),
      name: plan.title,
      world: plan.world,
      sessionId: newId('session'),
      hero: validatedHero,
      scene: plan.opening,
      messages: [
        NarrativeMessage(
          id: newId('message'),
          role: 'gm',
          text: plan.opening,
          timestamp: clock(),
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
    final now = clock();
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
            id: newId('npc-note'),
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


  /// A rejected offer has no mechanical side effects.
  GameUpdate rejectAdventure(Campaign campaign) {
    final offer = campaign.adventureOffer;
    if (offer == null) {
      throw const FormatException('Es gibt keinen offenen Vorschlag.');
    }
    return events.commit(
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
    final summary = sessionSummary(campaign);
    final recap = SessionRecap(
      id: newId('recap'),
      title: 'Rückblick ${campaign.sessionRecaps.length + 1}',
      summary: summary,
      createdAt: clock(),
    );
    return events.commit(
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
      id: newId('npc-note'),
      npcId: npcId,
      relationship: normalized,
      note: description,
      recordedAt: clock(),
    );
    return events.commit(
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
      id: threadId ?? newId('thread'),
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
    return events.commit(
      campaign,
      campaign.copyWith(storyThreads: threads),
      'Der Handlungsstrang „${thread.title}“ wurde im Tagebuch gespeichert.',
      type: 'memory.storyThreadSaved',
      payload: {'threadId': thread.id, 'status': status},
    );
  }


  Campaign createDemo({HeroCharacter? hero, String? name}) {
    final chosen =
        hero ??
        HeroCharacter(
          id: newId('hero'),
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
      id: newId('demo'),
      name: name ?? 'Das Licht von Mooswacht',
      world: 'Lunaris',
      sessionId: newId('session'),
      hero: chosen,
      scene: scene,
      messages: [
        NarrativeMessage(
          id: newId('message'),
          role: 'gm',
          text: scene,
          timestamp: clock(),
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
  Campaign createRabenwacht(HeroCharacter hero) => RabenwachtCampaign.create(
    hero: hero,
    campaignId: newId('rabenwacht'),
    sessionId: newId('session'),
    messageId: newId('message'),
    now: clock(),
  );


}

/// The story layer compares canonical, deep state checkpoints so provider
/// text cannot sneak rule or inventory mutations into an accepted event.
String canonicalJson(Object? value) {
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
