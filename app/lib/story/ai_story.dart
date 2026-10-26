import '../domain/models.dart';

// Data from the optional generative provider is untrusted until validated.
Map<String, dynamic> _obj(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('Ungültige KI-Geschichte.');
  }
  return value;
}

String _text(Object? value, int limit) {
  if (value is! String || value.trim().isEmpty || value.length > limit) {
    throw const FormatException('Ungültiges oder zu langes KI-Feld.');
  }
  return value.trim();
}

String _id(Object? value) {
  final id = _text(value, 64);
  if (!RegExp(r'^[a-z][a-z0-9_-]{0,63}$').hasMatch(id)) {
    throw const FormatException('Ungültige KI-Kennung.');
  }
  return id;
}

List<T> _items<T>(Object? value, int limit, T Function(Object?) parser) {
  if (value is! List || value.length > limit) {
    throw const FormatException('Zu viele KI-Einträge.');
  }
  return value.map(parser).toList();
}

void _unique(Iterable<String> ids) {
  if (ids.toSet().length != ids.length) {
    throw const FormatException('Doppelte KI-Kennung.');
  }
}

class AiStoryPlan {
  AiStoryPlan._(
    this.title,
    this.world,
    this.opening,
    this.premise,
    this.secret,
    this.goal,
    this.threads,
    this.npcs,
    this.places,
  );
  final String title, world, opening, premise, secret, goal;
  final List<StoryThread> threads;
  final List<WorldNpc> npcs;
  final List<Place> places;

  factory AiStoryPlan.fromJson(Map<String, dynamic> json) {
    final threads = _items(json['threads'], 4, (item) {
      final j = _obj(item);
      return StoryThread(
        id: _id(j['id']),
        title: _text(j['title'], 120),
        description: _text(j['description'], 1000),
      );
    });
    final npcs = _items(json['npcs'], 4, (item) {
      final j = _obj(item);
      return WorldNpc(
        id: _id(j['id']),
        name: _text(j['name'], 80),
        description: _text(j['description'], 500),
        relationship: _text(j['relationship'], 80),
      );
    });
    final places = _items(json['places'], 4, (item) {
      final j = _obj(item);
      return Place(
        id: _id(j['id']),
        name: _text(j['name'], 80),
        description: _text(j['description'], 500),
      );
    });
    if (threads.length < 2 || npcs.isEmpty || places.isEmpty) {
      throw const FormatException('KI-Geschichte ist unvollständig.');
    }
    _unique(threads.map((x) => x.id));
    _unique(npcs.map((x) => x.id));
    _unique(places.map((x) => x.id));
    return AiStoryPlan._(
      _text(json['title'], 120),
      _text(json['world'], 120),
      _text(json['opening'], 2500),
      _text(json['premise'], 1000),
      _text(json['secret'], 1000),
      _text(json['goal'], 500),
      List.unmodifiable(threads),
      List.unmodifiable(npcs),
      List.unmodifiable(places),
    );
  }
}

class AiThreadUpdate {
  const AiThreadUpdate(this.id, this.status, this.description);
  final String id, status, description;
}

class AiNpcUpdate {
  const AiNpcUpdate(this.id, this.relationship, this.note);
  final String id, relationship, note;
}

class AiStoryStep {
  AiStoryStep._(
    this.narration,
    this.threadUpdates,
    this.newThreads,
    this.npcUpdates,
    this.adventure,
  );
  final String narration;
  final List<AiThreadUpdate> threadUpdates;
  final List<StoryThread> newThreads;
  final List<AiNpcUpdate> npcUpdates;
  final AdventureOffer? adventure;

  factory AiStoryStep.fromJson(Map<String, dynamic> json, Campaign campaign) {
    // A validated provider update must never fan out to several NPCs with
    // the same ID or silently collapse contradictory saved story threads.
    // Check the actual local state even when no corresponding update is sent.
    _unique(campaign.storyThreads.map((thread) => thread.id));
    _unique(campaign.npcs.map((npc) => npc.id));
    final knownThreads = {
      for (final thread in campaign.storyThreads) thread.id: thread,
    };
    final knownNpcs = campaign.npcs.map((e) => e.id).toSet();
    final threadUpdates = _items(json['threadUpdates'], 6, (entry) {
      final j = _obj(entry);
      final id = _id(j['id']);
      final status = _text(j['status'], 16);
      if (!knownThreads.containsKey(id) ||
          !const ['open', 'resolved', 'abandoned'].contains(status)) {
        throw const FormatException('Unbekannter KI-Handlungsstrang.');
      }
      // Confirmed endings include their description. AI may neither reopen
      // nor rewrite them; manual saveStoryThread edits remain authoritative.
      final previous = knownThreads[id]!;
      final description = _text(j['description'], 1000);
      if (previous.status != 'open' &&
          (status != previous.status || description != previous.description)) {
        throw const FormatException(
          'Abgeschlossene Handlungsstränge können nur manuell geändert werden.',
        );
      }
      return AiThreadUpdate(id, status, description);
    });
    final newThreads = _items(json['newThreads'], 2, (entry) {
      final j = _obj(entry);
      return StoryThread(
        id: _id(j['id']),
        title: _text(j['title'], 120),
        description: _text(j['description'], 1000),
      );
    });
    final npcUpdates = _items(json['npcUpdates'], 4, (entry) {
      final j = _obj(entry);
      final id = _id(j['id']);
      if (!knownNpcs.contains(id)) {
        throw const FormatException('Unbekannter KI-NPC.');
      }
      return AiNpcUpdate(
        id,
        _text(j['relationship'], 80),
        _text(j['note'], 500),
      );
    });
    _unique(threadUpdates.map((x) => x.id));
    _unique(newThreads.map((x) => x.id));
    _unique(npcUpdates.map((x) => x.id));
    if (newThreads.any((x) => knownThreads.containsKey(x.id)) ||
        campaign.storyThreads.length + newThreads.length > 100 ||
        campaign.npcRelationshipNotes.length + npcUpdates.length > 300) {
      throw const FormatException('KI-Handlungsstränge überschneiden sich.');
    }
    final proposed = json['adventure'];
    final offer =
        proposed == null ||
            campaign.adventureOffer != null ||
            campaign.pendingRoll != null ||
            (campaign.encounter != null && !campaign.encounter!.isFinished)
        ? null
        : AdventureOffer.fromJson(_obj(proposed));
    if (offer != null && campaign.quests.any((q) => q.id == 'ai-${offer.id}')) {
      throw const FormatException('Bereits benutzte Quest-ID.');
    }
    return AiStoryStep._(
      _text(json['narration'], 4000),
      List.unmodifiable(threadUpdates),
      List.unmodifiable(newThreads),
      List.unmodifiable(npcUpdates),
      offer,
    );
  }
}
