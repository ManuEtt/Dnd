import 'dart:convert';

import '../domain/models.dart';

/// Read-only view of a quest saved in a campaign.

/// A saved quest status is not evidence of XP, gold, inventory changes or
/// any other rule result. Only a separate validated game event can grant those.
class SavedQuestResumeSelection {
  SavedQuestResumeSelection._({
    required this.campaignId,
    required this.sessionId,
    required this.revision,
    required this.questId,
    required this.title,
    required this.description,
    required this.status,
    required this.statusLabel,
    required String sourceStamp,
  }) : _sourceStamp = sourceStamp;

  final String campaignId;
  final String sessionId;
  final int revision;
  final String questId;
  final String title;
  final String description;
  final String status;
  final String statusLabel;
  final String _sourceStamp;

  /// Bounded historical status; neither a reward nor an action to execute.
  String get playerOverview {
    final result = [
      'Gespeicherte Quest (ID: $questId; Revision $revision): $title',
      'Gespeicherter Queststatus: $statusLabel',
      'Gespeicherte Beschreibung: '
          '${description.isEmpty ? 'keine' : description}',
      'Kein Nachweis über EP, Gold, Gegenstände oder Questbelohnungen.',
    ].join('\n');
    if (result.length > 900) {
      throw const FormatException('Quest-Rückblick überschreitet sein Limit.');
    }
    return result;
  }

  /// Reject both revised and silently edited quest histories.
  ///
  /// Call this against the latest campaign before showing or forwarding a
  /// selection. Neither checking nor selecting can modify the campaign.
  void requireCurrent(Campaign campaign) {
    if (campaign.id != campaignId ||
        campaign.sessionId != sessionId ||
        campaign.revision != revision ||
        _sourceStamp != SavedQuestResumeSelector._sourceStamp(campaign)) {
      throw const FormatException('Gespeicherter Quest-Rückblick ist veraltet.');
    }
  }
}

/// Select a historical active, completed or failed quest by exact stored ID.
///
/// The selection does not read AI narration, confirm rewards, write events,
/// change quest status or assume that the quest is still actionable.
class SavedQuestResumeSelector {
  const SavedQuestResumeSelector._();

  static final RegExp _safeId = RegExp(r'^[a-zA-Z0-9_-]{1,64}$');
  static final RegExp _formatMarks = RegExp(
    r'[\u00ad\u034f\u061c\u180e\u200b-\u200f\u202a-\u202e\u2060-\u206f\ufeff]',
  );
  static final RegExp _controls = RegExp(r'[\x00-\x1f\x7f-\x9f\u2028\u2029]');

  static SavedQuestResumeSelection readSelected(
    Campaign campaign, {
    required int expectedRevision,
    required String questId,
  }) {
    if (campaign.id.trim().isEmpty ||
        campaign.sessionId.trim().isEmpty ||
        expectedRevision < 0 ||
        expectedRevision > 2147483647 ||
        campaign.revision != expectedRevision ||
        _safeId.stringMatch(questId) != questId) {
      throw const FormatException('Ungültige Quest-Wiederaufnahme.');
    }

    Quest? chosen;
    for (final quest in campaign.quests) {
      if (quest.id != questId) continue;
      if (chosen != null) {
        throw const FormatException('Quest-ID ist nicht eindeutig.');
      }
      chosen = quest;
    }
    if (chosen == null) {
      throw const FormatException('Quest wurde nicht gespeichert.');
    }

    final title = _oneLine(chosen.title, 100, title: true);
    if (title.isEmpty) {
      throw const FormatException('Gespeicherte Quest hat keinen Namen.');
    }
    final statusLabel = switch (chosen.status) {
      'active' => 'aktiv',
      'completed' => 'abgeschlossen',
      'failed' => 'gescheitert',
      _ => throw const FormatException('Unbekannter Queststatus.'),
    };
    final selection = SavedQuestResumeSelection._(
      campaignId: campaign.id,
      sessionId: campaign.sessionId,
      revision: campaign.revision,
      questId: chosen.id,
      title: title,
      description: _oneLine(chosen.description, 280),
      status: chosen.status,
      statusLabel: statusLabel,
      sourceStamp: _sourceStamp(campaign),
    );
    if (selection.playerOverview.length > 900) {
      throw const FormatException('Quest-Rückblick überschreitet sein Limit.');
    }
    return selection;
  }

  static String _sourceStamp(Campaign campaign) => jsonEncode({
    'quests': [for (final quest in campaign.quests) quest.toJson()],
  });

  // Only sanitize the visible projection; preserve saved data and Unicode
  // characters. Rune-wise truncation keeps surrogate pairs intact.
  static String _oneLine(String raw, int maxUnits, {bool title = false}) {
    final clean = raw
        .replaceAll(_formatMarks, title ? '' : ' ')
        .replaceAll(_controls, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (clean.length <= maxUnits) return clean;

    final buffer = StringBuffer();
    var used = 0;
    for (final rune in clean.runes) {
      final units = rune > 0xffff ? 2 : 1;
      if (used + units > maxUnits - 1) break;
      buffer.writeCharCode(rune);
      used += units;
    }
    return '${buffer.toString().trimRight()}…';
  }
}
