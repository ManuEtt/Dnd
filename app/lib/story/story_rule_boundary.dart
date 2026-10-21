import 'dart:convert';

import '../domain/models.dart';

/// The story engine can change prose, memories and authored world entities,
/// but cannot mutate HP, spell slots, equipment, XP, quests, pending rolls,
/// combat, active actors, campaign identity, or any new unlisted rule field.
/// This whitelist fails closed when the shared schema gains new mechanics.
class StoryRuleBoundary {
  const StoryRuleBoundary._();

  static const storyOwnedFields = <String>{
    'scene',
    'messages',
    'events',
    'revision',
    'storyThreads',
    'storyBible',
    'npcs',
    'npcRelationshipNotes',
    'sessionRecaps',
    'adventureOffer',
  };

  static void ensureRuleStateUnchanged(Campaign before, Campaign after) {
    final original = Map<String, dynamic>.from(before.toJson());
    final candidate = Map<String, dynamic>.from(after.toJson());
    for (final key in storyOwnedFields) {
      original.remove(key);
      candidate.remove(key);
    }
    if (_canonical(original) != _canonical(candidate)) {
      throw const FormatException(
        'Die Story-Engine darf keinen regelrelevanten Zustand verändern.',
      );
    }
  }

  static String _canonical(Object? value) {
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
}
