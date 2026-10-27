import 'dart:convert';

import '../domain/models.dart';

/// Confirmed story/session memories, independent of live combat operations.
/// Explicitly separates scene context, session recap and persistent world facts.
class MemoryEngine {
  /// Recognizes explicit requests for established adventure memories.
  /// Free player actions mentioning historical nouns are not recall commands.
  static bool isRecallRequest(String text) {
    // A mention of a diary or of remembering is not necessarily a request.
    // Otherwise "Ich lese das Tagebuch" silently becomes a recall instead
    // of a player action. Only explicit questions and commands opt in.
    final request = _memoryNormalize(text)
        .replaceAll(RegExp(r'[.!?]+$'), '')
        .replaceFirst(RegExp(r'^bitte\s+'), '')
        .trim();
    if (request.isEmpty) return false;

    return <RegExp>[
      RegExp(r'^erinnere\s+dich\b'),
      RegExp(r'^erinnerst\s+du\s+dich\b'),
      RegExp(r'^(?:kannst|koenntest)\s+du\s+dich\b.*\berinnern\b'),
      RegExp(r'^(?:was\s+weisst\s+du|weisst\s+du\s+noch)\b'),
      RegExp(r'^was\s+(?:ist|war)\s+bisher\s+(?:passiert|geschehen)\b'),
      RegExp(r'^erzaehl\w*\s+(?:mir\s+)?(?:etwas\s+)?(?:ueber|von)\b'),
      RegExp(
        r'^fass(?:e|t)\b.*\b(?:geschichte|abenteuer|kampagne|sitzung|erlebnisse)\b.*\bzusammen\b',
      ),
      RegExp(r'^(?:rueckblick|tagebuch|zusammenfassung|erinnerungen)\b'),
      RegExp(r'^(?:zeig(?:e)?|oeffne)\s+(?:mir\s+)?(?:das\s+)?tagebuch\b'),
      RegExp(
        r'^(?:gib|zeige|erstelle)\s+(?:mir\s+)?(?:einen?\s+|die\s+)?(?:rueckblick|zusammenfassung)\b',
      ),
      RegExp(
        r'^ich\s+moechte\s+(?:einen?\s+|die\s+)?(?:rueckblick|zusammenfassung)\b',
      ),
    ].any((pattern) => pattern.hasMatch(request));
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
    // A visible name is not a saved identity: two distinct NPCs may both be
    // called Mira. Keep their confirmed histories individually attributable
    // in *all* recalls, including short summaries and topical retrieval.
    final npcNameCounts = <String, int>{};
    final npcIdCounts = <String, int>{};
    for (final npc in campaign.npcs) {
      final nameKey = _memoryNormalize(npc.name);
      if (nameKey.isNotEmpty) {
        npcNameCounts[nameKey] = (npcNameCounts[nameKey] ?? 0) + 1;
      }
      if (npc.id.trim().isNotEmpty) {
        npcIdCounts[npc.id] = (npcIdCounts[npc.id] ?? 0) + 1;
      }
    }
    String? npcLabel(WorldNpc npc) {
      // Malformed duplicate IDs cannot establish which NPC owns a note.
      if (npc.id.trim().isEmpty || npcIdCounts[npc.id] != 1) return null;
      final nameKey = _memoryNormalize(npc.name);
      if (nameKey.isEmpty) return null;
      return npcNameCounts[nameKey] == 1
          ? npc.name
          : '${npc.name} (NPC-ID: ${npc.id})';
    }

    for (final note in campaign.npcRelationshipNotes.reversed) {
      final matches = campaign.npcs.where((npc) => npc.id == note.npcId);
      if (matches.length != 1) continue;
      final label = npcLabel(matches.single);
      if (label == null) continue;
      final heading = 'Beziehung zu $label: ${note.relationship}';
      // Never truncate the distinguishing ID off a same-name entry.
      if (npcNameCounts[_memoryNormalize(matches.single.name)] != 1 &&
          heading.length + 1 > maxCharacters) {
        continue;
      }
      add(heading, note.note, priority: 220);
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
      final label = npcLabel(npc);
      if (label == null) continue;
      final heading = 'NPC ${npc.alive ? 'lebendig' : 'tot'}: $label';
      if (npcNameCounts[_memoryNormalize(npc.name)] != 1 &&
          heading.length + 1 > maxCharacters) {
        continue;
      }
      add(
        heading,
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
      // An exact duplicate from an older saved session remains idempotent,
      // but a NEW journal event must belong to the currently replayed session.
      if (event.sessionId != state.sessionId) {
        throw const FormatException('Fremdes Sitzungsereignis.');
      }
      final raw = event.payload['stateAfter'];
      if (raw is Map<String, dynamic>) {
        final restored = Campaign.fromJson(raw);
        if (restored.id != seed.id || restored.revision != state.revision + 1) {
          throw const FormatException(
            'Lücke oder falsche Reihenfolge im Ereignisprotokoll.',
          );
        }
        if (restored.sessionId != event.sessionId) {
          throw const FormatException(
            'Der Ereignis-Checkpoint gehört zu einer anderen Sitzung.',
          );
        }
        state = restored;
      }
      seen[event.id] = event;
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
