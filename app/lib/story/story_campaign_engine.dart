import 'dart:convert';

import '../domain/ai_story.dart';
import '../domain/models.dart';

/// Isolated narrative-state mutations. No random dice and no combat rules.
/// All changed checkpoints are validated against the shared campaign schema.
class StoryCampaignEngine {
  StoryCampaignEngine({
    required String Function(String) nextId,
    required DateTime Function() clock,
  }) : _id = nextId, _clock = clock;

  final String Function(String) _id;
  final DateTime Function() _clock;

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

