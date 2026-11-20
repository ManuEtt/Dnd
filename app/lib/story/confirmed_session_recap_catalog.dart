import 'dart:convert';

import '../domain/models.dart';

/// A saved recap identity for selecting a historical session by ID.
///
/// Titles and dates come only from persisted session recaps. Neither this
/// entry nor its list claims that any narrated fact is currently true.
class ConfirmedSessionRecapCatalogEntry {
  const ConfirmedSessionRecapCatalogEntry({
    required this.recapId,
    required this.title,
    required this.createdAt,
  });

  final String recapId;
  final String title;
  final DateTime createdAt;
}

/// One bounded, read-only page of historical session recap identities.
///
/// Consumers must call [requireCurrent] before displaying or acting on a
/// selection after any intervening campaign change.
class ConfirmedSessionRecapCatalogPage {
  ConfirmedSessionRecapCatalogPage._({
    required this.campaignId,
    required this.sessionId,
    required this.revision,
    required this.pageIndex,
    required this.pageSize,
    required this.hasMore,
    required List<ConfirmedSessionRecapCatalogEntry> entries,
    required String sourceStamp,
  }) : entries = List.unmodifiable(entries),
       _sourceStamp = sourceStamp;

  final String campaignId;
  final String sessionId;
  final int revision;

  /// Zero-based page number and requested number of entries per page.
  final int pageIndex;
  final int pageSize;
  final bool hasMore;
  final List<ConfirmedSessionRecapCatalogEntry> entries;
  final String _sourceStamp;

  /// IDs are selectors, not claims about quests, items or current rules.
  String get playerOverview {
    final lines = <String>[
      'Gespeicherte Sitzungsrückblicke '
          '(Seite ${pageIndex + 1}; Revision $revision; historisch):',
      for (final entry in entries)
        'Rückblick (ID: ${entry.recapId}; '
            '${entry.createdAt.toUtc().toIso8601String()}): ${entry.title}',
      if (entries.isEmpty) 'Keine Rückblicke auf dieser Seite.',
      if (hasMore) 'Weitere gespeicherte Rückblicke vorhanden.',
      'Nur historische Einträge, kein aktueller Quest- oder Belohnungsnachweis.',
    ];
    final text = lines.join('\n');
    if (text.length > 1500) {
      throw const FormatException('Rückblickverzeichnis überschreitet das Limit.');
    }
    return text;
  }

  /// Detect same-revision edits even to recaps outside this visible page.
  ///
  /// Rule-only changes do not turn a saved historical recap into a rule fact.
  void requireCurrent(Campaign campaign) {
    if (campaign.id != campaignId ||
        campaign.sessionId != sessionId ||
        campaign.revision != revision ||
        _sourceStamp != ConfirmedSessionRecapCatalog._sourceStamp(campaign)) {
      throw const FormatException('Rückblickverzeichnis ist veraltet.');
    }
  }
}

/// Lists saved recap IDs without reading their free-text summaries.
///
/// Older recaps can be found through pages sorted by their saved UTC time
/// (newest first). Equal timestamps retain a deterministic reverse saved
/// order. Duplicate and unsafe IDs never become selectable identities.
/// This projection performs no writes and never contacts an AI provider.
class ConfirmedSessionRecapCatalog {
  const ConfirmedSessionRecapCatalog._();

  static final RegExp _safeId = RegExp(r'^[a-zA-Z0-9_-]{1,64}$');
  static final RegExp _formatMarks = RegExp(
    r'[\u00ad\u034f\u061c\u180e\u200b-\u200f\u202a-\u202e\u2060-\u206f\ufeff]',
  );
  static final RegExp _controls = RegExp(r'[\x00-\x1f\x7f-\x9f\u2028\u2029]');

  static ConfirmedSessionRecapCatalogPage read(
    Campaign campaign, {
    required int expectedRevision,
    int pageIndex = 0,
    int pageSize = 4,
  }) {
    if (campaign.id.trim().isEmpty ||
        campaign.sessionId.trim().isEmpty ||
        expectedRevision < 0 ||
        expectedRevision > 2147483647 ||
        campaign.revision != expectedRevision ||
        pageIndex < 0 ||
        pageIndex > 1000000 ||
        pageSize < 1 ||
        pageSize > 4) {
      throw const FormatException('Ungültige Rückblickverzeichnis-Anfrage.');
    }

    // Count across the complete original source, before any paging or
    // filtering, so conflicting legacy IDs can never become unique by page.
    final idCounts = <String, int>{};
    for (final recap in campaign.sessionRecaps) {
      idCounts[recap.id] = (idCounts[recap.id] ?? 0) + 1;
    }
    final eligible = <({SessionRecap recap, int position, String title})>[];
    for (var i = 0; i < campaign.sessionRecaps.length; i++) {
      final recap = campaign.sessionRecaps[i];
      if (_safeId.stringMatch(recap.id) != recap.id ||
          idCounts[recap.id] != 1) {
        continue;
      }
      final title = _oneLine(recap.title, 70);
      if (title.isEmpty) continue;
      eligible.add((recap: recap, position: i, title: title));
    }

    eligible.sort((a, b) {
      final byDate = b.recap.createdAt.compareTo(a.recap.createdAt);
      return byDate != 0 ? byDate : b.position.compareTo(a.position);
    });

    final from = pageIndex * pageSize;
    final items = from >= eligible.length
        ? <({SessionRecap recap, int position, String title})>[]
        : eligible.skip(from).take(pageSize).toList();
    final page = ConfirmedSessionRecapCatalogPage._(
      campaignId: campaign.id,
      sessionId: campaign.sessionId,
      revision: campaign.revision,
      pageIndex: pageIndex,
      pageSize: pageSize,
      hasMore: from + items.length < eligible.length,
      entries: [
        for (final item in items)
          ConfirmedSessionRecapCatalogEntry(
            recapId: item.recap.id,
            title: item.title,
            createdAt: item.recap.createdAt,
          ),
      ],
      sourceStamp: _sourceStamp(campaign),
    );
    if (page.playerOverview.length > 1500) {
      throw const FormatException('Rückblickverzeichnis überschreitet das Limit.');
    }
    return page;
  }

  static String _sourceStamp(Campaign campaign) => jsonEncode({
    'sessionRecaps': [
      for (final recap in campaign.sessionRecaps) recap.toJson(),
    ],
  });

  /// Clean only the presentation; never mutate the saved historical title.
  /// Truncate on Unicode rune boundaries to preserve emoji surrogate pairs.
  static String _oneLine(String raw, int limit) {
    final text = raw
        .replaceAll(_formatMarks, '')
        .replaceAll(_controls, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (text.length <= limit) return text;
    final out = StringBuffer();
    var length = 0;
    for (final rune in text.runes) {
      final width = rune > 0xffff ? 2 : 1;
      if (length + width > limit - 1) break;
      out.writeCharCode(rune);
      length += width;
    }
    return '${out.toString().trimRight()}…';
  }
}
