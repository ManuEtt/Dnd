import 'dart:convert';

import '../domain/models.dart';

/// A single saved story thread, explicitly selected by its stable ID.
///
/// Its status is a user-managed narrative marker, not a validated quest
/// completion, reward, game rule or narrator-generated inference.
class ConfirmedStoryThreadResumeSelection {
  ConfirmedStoryThreadResumeSelection._({
    required this.campaignId,
    required this.sessionId,
    required this.revision,
    required this.threadId,
    required this.title,
    required this.description,
    required this.status,
    required this.statusLabel,
    required String sourceStamp,
  }) : _sourceStamp = sourceStamp;

  final String campaignId;
  final String sessionId;
  final int revision;
  final String threadId;
  final String title;
  final String description;
  final String status;
  final String statusLabel;
  final String _sourceStamp;

  /// Line-safe, bounded display of the saved thread, never free AI dialogue.
  String get playerOverview {
    final result = [
      'Gespeicherter Handlungsstrang (ID: ${threadId}; Revision ${revision}): ${title}',
      'Handlungsstatus: ${statusLabel}',
      'Gespeicherte Beschreibung: ${description.isEmpty ? 'keine' : description}',
      'Kein bestätigter Questabschluss oder Belohnungsnachweis.',
    ].join('\n');
    if (result.length > 900) {
      throw const FormatException('Handlungsrückblick überschreitet sein Limit.');
    }
    return result;
  }

  /// Recheck the complete raw thread list after each intervening turn.
  ///
  /// A same-revision edit beyond the visible character limit also invalidates
  /// this selection. No campaign field, event or persisted data is modified.
  void requireCurrent(Campaign campaign) {
    if (campaign.id != campaignId ||
        campaign.sessionId != sessionId ||
        campaign.revision != revision ||
        _sourceStamp != ConfirmedStoryThreadResumeSelector._sourceStamp(campaign)) {
      throw const FormatException('Gespeicherter Handlungsrückblick ist veraltet.');
    }
  }
}

/// Read one old, open, resolved or abandoned saved narrative hook by exact ID.
///
/// Unlike a top-N list of currently open leads, the explicit selection can
/// recall an older thread without treating its status as quest authority.
class ConfirmedStoryThreadResumeSelector {
  const ConfirmedStoryThreadResumeSelector._();

  static final RegExp _safeId = RegExp(r'^[a-zA-Z0-9_-]{1,64}$');
  static final RegExp _formatMarks = RegExp(
    r'[\u00ad\u034f\u061c\u180e\u200b-\u200f\u202a-\u202e\u2060-\u206f\ufeff]',
  );
  static final RegExp _controls = RegExp(r'[\x00-\x1f\x7f-\x9f\u2028\u2029]');

  static ConfirmedStoryThreadResumeSelection readSelected(
    Campaign campaign, {
    required int expectedRevision,
    required String threadId,
  }) {
    if (campaign.id.trim().isEmpty ||
        campaign.sessionId.trim().isEmpty ||
        expectedRevision < 0 ||
        expectedRevision > 2147483647 ||
        campaign.revision != expectedRevision ||
        _safeId.stringMatch(threadId) != threadId) {
      throw const FormatException('Ungültige Handlungsstrang-Wiederaufnahme.');
    }

    StoryThread? selected;
    for (final thread in campaign.storyThreads) {
      if (thread.id != threadId) continue;
      if (selected != null) {
        throw const FormatException('Handlungsstrang-ID ist nicht eindeutig.');
      }
      selected = thread;
    }
    if (selected == null) {
      throw const FormatException('Handlungsstrang ist nicht gespeichert.');
    }

    final title = _oneLine(selected.title, 96, title: true);
    if (title.isEmpty) {
      throw const FormatException('Handlungsstrang hat keinen Anzeigenamen.');
    }
    final statusLabel = switch (selected.status) {
      'open' => 'offen',
      'resolved' => 'abgeschlossen',
      'abandoned' => 'aufgegeben',
      _ => throw const FormatException('Unbekannter Handlungsstatus.'),
    };
    final result = ConfirmedStoryThreadResumeSelection._(
      campaignId: campaign.id,
      sessionId: campaign.sessionId,
      revision: campaign.revision,
      threadId: selected.id,
      title: title,
      description: _oneLine(selected.description, 280),
      status: selected.status,
      statusLabel: statusLabel,
      sourceStamp: _sourceStamp(campaign),
    );
    // Fail closed should future fields enlarge the presentation contract.
    if (result.playerOverview.length > 900) {
      throw const FormatException('Handlungsrückblick überschreitet sein Limit.');
    }
    return result;
  }

  static String _sourceStamp(Campaign campaign) => jsonEncode({
    'storyThreads': [
      for (final thread in campaign.storyThreads) thread.toJson(),
    ],
  });

  // Sanitize only the displayed excerpt; preserve raw saved story history.
  // Truncate at rune boundaries to avoid splitting UTF-16 surrogate pairs.
  static String _oneLine(String raw, int limit, {bool title = false}) {
    final clean = raw
        .replaceAll(_formatMarks, title ? '' : ' ')
        .replaceAll(_controls, ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (clean.length <= limit) return clean;
    final buffer = StringBuffer();
    var units = 0;
    for (final rune in clean.runes) {
      final size = rune > 0xffff ? 2 : 1;
      if (units + size > limit - 1) break;
      buffer.writeCharCode(rune);
      units += size;
    }
    return '${buffer.toString().trimRight()}…';
  }
}
