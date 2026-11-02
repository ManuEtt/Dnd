import 'dart:convert';

import '../domain/models.dart';

/// One saved place record for a read-only campaign resumption.
class ConfirmedPlaceResumeEntry {
  ConfirmedPlaceResumeEntry._({
    required this.placeId,
    required this.name,
    required this.description,
  });

  final String placeId;
  final String name;
  final String description;
}

/// Bounded view of saved places, never a claim that the hero visited them.
///
/// A caller must recheck [requireCurrent] against the latest saved campaign
/// before displaying or forwarding this snapshot. It cannot change rules,
/// quests, location, discoveries or persistence state.
class ConfirmedPlaceResumeSelection {
  ConfirmedPlaceResumeSelection._({
    required this.campaignId,
    required this.sessionId,
    required this.revision,
    required List<ConfirmedPlaceResumeEntry> entries,
    required String sourceStamp,
  }) : entries = List.unmodifiable(entries),
       _sourceStamp = sourceStamp;

  final String campaignId;
  final String sessionId;
  final int revision;
  final List<ConfirmedPlaceResumeEntry> entries;
  final String _sourceStamp;

  /// Only saved identities and descriptions; never AI prose or visit claims.
  String get playerOverview {
    final lines = <String>[
      'Gespeicherte Orte (Revision $revision; kein Besuchsnachweis):',
      for (final entry in entries)
        'Ort (ID: ${entry.placeId}): ${entry.name}. '
            'Beschreibung: ${entry.description}',
    ];
    final result = lines.join('\n');
    if (result.length > 1800) {
      throw const FormatException('Ortsrückblick überschreitet sein Limit.');
    }
    return result;
  }

  /// Reject even same-revision changes beyond the visible truncated excerpt.
  void requireCurrent(Campaign campaign) {
    if (campaign.id != campaignId ||
        campaign.sessionId != sessionId ||
        campaign.revision != revision ||
        _sourceStamp != ConfirmedPlaceResumeSelector._sourceStamp(campaign)) {
      throw const FormatException('Gespeicherter Ortsrückblick ist veraltet.');
    }
  }
}

/// Read-only deterministic projection of the campaign's saved place records.
///
/// Place names alone are not identities, so every line retains its exact safe
/// stored ID. Duplicated and unsafe IDs are excluded instead of guessed.
class ConfirmedPlaceResumeSelector {
  const ConfirmedPlaceResumeSelector._();

  static final RegExp _safeId = RegExp(r'^[a-zA-Z0-9_-]{1,64}$');
  static final RegExp _formatMarks = RegExp(
    r'[\u034f\u061c\u180e\u200b-\u200f\u202a-\u202e\u2060-\u2069\ufeff]',
  );
  static final RegExp _controls = RegExp(r'[\x00-\x1f\x7f-\x9f\u2028\u2029]');

  static ConfirmedPlaceResumeSelection read(
    Campaign campaign, {
    required int expectedRevision,
    int maxPlaces = 4,
  }) {
    if (campaign.id.trim().isEmpty ||
        campaign.sessionId.trim().isEmpty ||
        expectedRevision < 0 ||
        expectedRevision > 2147483647 ||
        campaign.revision != expectedRevision ||
        maxPlaces < 1 ||
        maxPlaces > 4) {
      throw const FormatException('Ungültige Orts-Wiederaufnahmegrenzen.');
    }

    final idCounts = <String, int>{};
    for (final place in campaign.places) {
      idCounts[place.id] = (idCounts[place.id] ?? 0) + 1;
    }

    final entries = <ConfirmedPlaceResumeEntry>[];
    for (final place in campaign.places) {
      if (!_safeId.hasMatch(place.id) || idCounts[place.id] != 1) continue;
      final name = _oneLine(place.name, 72, name: true);
      if (name.isEmpty) continue;
      final description = _oneLine(place.description, 220);
      entries.add(
        ConfirmedPlaceResumeEntry._(
          placeId: place.id,
          name: name,
          description: description.isEmpty
              ? 'keine gespeicherte Beschreibung'
              : description,
        ),
      );
      if (entries.length == maxPlaces) break;
    }
    final selection = ConfirmedPlaceResumeSelection._(
      campaignId: campaign.id,
      sessionId: campaign.sessionId,
      revision: campaign.revision,
      entries: entries,
      sourceStamp: _sourceStamp(campaign),
    );
    if (selection.playerOverview.length > 1800) {
      throw const FormatException('Ortsrückblick überschreitet sein Limit.');
    }
    return selection;
  }

  static String _sourceStamp(Campaign campaign) => jsonEncode({
    'places': [for (final place in campaign.places) place.toJson()],
  });

  // Only the rendered excerpt is sanitized. Saved input is never modified.
  // Rune-wise truncation does not split UTF-16 surrogate pairs (e.g. emoji).
  static String _oneLine(String text, int limit, {bool name = false}) {
    final cleaned = text
        .replaceAll(_formatMarks, name ? '' : ' ')
        .replaceAll(_controls, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.length <= limit) return cleaned;
    final buffer = StringBuffer();
    var length = 0;
    for (final rune in cleaned.runes) {
      final units = rune > 0xffff ? 2 : 1;
      if (length + units > limit - 1) break;
      buffer.writeCharCode(rune);
      length += units;
    }
    return '${buffer.toString().trimRight()}…';
  }
}
