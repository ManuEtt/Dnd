import 'dart:convert';

import '../domain/models.dart';

/// A saved historical session recap, not proof of the current rule state.
///
/// The caller must revalidate this selection after every intervening turn.
class ConfirmedSessionRecapSelection {
  ConfirmedSessionRecapSelection._({
    required this.campaignId,
    required this.sessionId,
    required this.revision,
    required this.recapId,
    required this.title,
    required this.summary,
    required this.createdAt,
    required String sourceStamp,
  }) : _sourceStamp = sourceStamp;

  final String campaignId;
  final String sessionId;
  final int revision;
  final String recapId;
  final String title;
  final String summary;
  final DateTime createdAt;
  final String _sourceStamp;

  /// At most 1,200 UTF-16 code units, with explicit historical trust labels.
  String get playerOverview {
    final result = [
      'Historischer Sitzungsrückblick (ID: $recapId; '
          'Revision $revision): $title',
      'Gespeichert am: ${createdAt.toUtc().toIso8601String()}',
      'Damals gespeicherter Rückblick: $summary',
      'Historische Erinnerung, kein Beleg für aktuelle Regeln, '
          'Questabschlüsse oder Belohnungen.',
    ].join('\n');
    if (result.length > 1200) {
      throw const FormatException('Sitzungsrückblick überschreitet das Limit.');
    }
    return result;
  }

  /// Detect same-revision edits anywhere in the complete saved recap list.
  ///
  /// This never authorizes a narrative or rule-state modification.
  void requireCurrent(Campaign campaign) {
    if (campaign.id != campaignId ||
        campaign.sessionId != sessionId ||
        campaign.revision != revision ||
        _sourceStamp != ConfirmedSessionRecapSelector._sourceStamp(campaign)) {
      throw const FormatException('Historischer Sitzungsrückblick ist veraltet.');
    }
  }
}

/// Read one explicitly requested, previously saved session recap by exact ID.
///
/// Older saved recaps remain selectable beyond the normal latest-recap view.
/// No scene, AI message, quest, hero value or reward becomes confirmed by
/// reading the historical text. Storage and gameplay state remain unchanged.
class ConfirmedSessionRecapSelector {
  const ConfirmedSessionRecapSelector._();

  static final RegExp _safeId = RegExp(r'^[a-zA-Z0-9_-]{1,64}$');
  static final RegExp _formatMarks = RegExp(
    r'[\u00ad\u034f\u061c\u180e\u200b-\u200f\u202a-\u202e\u2060-\u206f\ufeff]',
  );
  static final RegExp _controls = RegExp(r'[\x00-\x1f\x7f-\x9f\u2028\u2029]');

  static ConfirmedSessionRecapSelection readSelected(
    Campaign campaign, {
    required int expectedRevision,
    required String recapId,
  }) {
    if (campaign.id.trim().isEmpty ||
        campaign.sessionId.trim().isEmpty ||
        expectedRevision < 0 ||
        expectedRevision > 2147483647 ||
        campaign.revision != expectedRevision ||
        _safeId.stringMatch(recapId) != recapId) {
      throw const FormatException('Ungültige Sitzungsrückblick-Auswahl.');
    }

    SessionRecap? chosen;
    for (final recap in campaign.sessionRecaps) {
      if (recap.id != recapId) continue;
      if (chosen != null) {
        throw const FormatException('Sitzungsrückblick-ID ist nicht eindeutig.');
      }
      chosen = recap;
    }
    if (chosen == null) {
      throw const FormatException('Sitzungsrückblick ist nicht gespeichert.');
    }

    final title = _oneLine(chosen.title, 100, name: true);
    final summary = _oneLine(chosen.summary, 800);
    if (title.isEmpty || summary.isEmpty) {
      throw const FormatException('Gespeicherter Rückblick ist nicht lesbar.');
    }
    final selection = ConfirmedSessionRecapSelection._(
      campaignId: campaign.id,
      sessionId: campaign.sessionId,
      revision: campaign.revision,
      recapId: chosen.id,
      title: title,
      summary: summary,
      createdAt: chosen.createdAt,
      sourceStamp: _sourceStamp(campaign),
    );
    if (selection.playerOverview.length > 1200) {
      throw const FormatException('Sitzungsrückblick überschreitet das Limit.');
    }
    return selection;
  }

  static String _sourceStamp(Campaign campaign) => jsonEncode({
    'sessionRecaps': [
      for (final recap in campaign.sessionRecaps) recap.toJson(),
    ],
  });

  // Only the visible projection is cleaned. Stored text stays byte-for-byte
  // equivalent. Truncate on rune boundaries to preserve UTF-16 emoji pairs.
  static String _oneLine(String raw, int maxUnits, {bool name = false}) {
    final clean = raw
        .replaceAll(_formatMarks, name ? '' : ' ')
        .replaceAll(_controls, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (clean.length <= maxUnits) return clean;

    final buffer = StringBuffer();
    var units = 0;
    for (final rune in clean.runes) {
      final size = rune > 0xffff ? 2 : 1;
      if (units + size > maxUnits - 1) break;
      buffer.writeCharCode(rune);
      units += size;
    }
    return '${buffer.toString().trimRight()}…';
  }
}
