import 'dart:convert';

import '../domain/models.dart';

/// A read-only projection for resuming a campaign after a break.
///
/// A narrated scene is not evidence of a rule result. Only the separately
/// stored recap, facts and user-confirmed thread statuses are labelled as
/// confirmed. Neither this snapshot nor its text is an AI command.
class CampaignResumeSnapshot {
  CampaignResumeSnapshot({
    required this.revision,
    required this.sessionId,
    this.latestScene,
    this.latestSavedRecap,
    required List<String> confirmedFacts,
    required List<String> openLeads,
  }) : confirmedFacts = List.unmodifiable(confirmedFacts),
       openLeads = List.unmodifiable(openLeads),
       _campaignId = null,
       _sourceStamp = null;

  // Only a reader-produced snapshot can prove which saved source it describes.
  // Keep the public constructor compatible, but unbound snapshots fail closed.
  CampaignResumeSnapshot._saved({
    required Campaign campaign,
    this.latestScene,
    this.latestSavedRecap,
    required List<String> confirmedFacts,
    required List<String> openLeads,
  }) : revision = campaign.revision,
       sessionId = campaign.sessionId,
       confirmedFacts = List.unmodifiable(confirmedFacts),
       openLeads = List.unmodifiable(openLeads),
       _campaignId = campaign.id,
       _sourceStamp = CampaignResumeReader._sourceStamp(campaign);

  final String? _campaignId;
  final String? _sourceStamp;

  final int revision;
  final String sessionId;

  /// Last narrated scene: context for continuing, not a confirmed game fact.
  final String? latestScene;

  /// Last explicitly saved recap: historical, not automatically up to date.
  final String? latestSavedRecap;

  /// Live confirmed facts, separately from the last saved recap.
  final List<String> confirmedFacts;

  /// Only story threads currently saved as open, most recent list entry first.
  final List<String> openLeads;

  /// Recheck against the latest campaign before showing or forwarding a recap.
  ///
  /// Even edits hidden behind a truncated line, or outside the selected top
  /// facts/leads, invalidate the snapshot at the same revision. Rule-only
  /// changes at that revision do not turn narration into confirmed facts.
  /// This is a read-only check; it never changes the underlying campaign.
  void requireCurrent(Campaign campaign) {
    if (_campaignId == null ||
        campaign.id != _campaignId ||
        campaign.sessionId != sessionId ||
        campaign.revision != revision ||
        _sourceStamp != CampaignResumeReader._sourceStamp(campaign)) {
      throw const FormatException('Gespeicherter Rückblick ist veraltet.');
    }
  }

  /// Line-safe player-facing projection, with source/trust labels intact.
  String get playerOverview {
    final sections = <String>[];
    void addSection(String title, String? content) {
      if (content != null && content.isNotEmpty) {
        sections.add('$title\n$content');
      }
    }

    addSection(
      'Zuletzt erzählte Szene (kein bestätigter Regelzustand):',
      latestScene,
    );
    addSection(
      'Letzter gespeicherter Rückblick (Stand bei Speicherung):',
      latestSavedRecap,
    );
    addSection(
      'Aktuell bestätigte Fakten:',
      confirmedFacts.map((fact) => '• $fact').join('\n'),
    );
    addSection(
      'Aktuell offene Handlungsstränge:',
      openLeads.map((lead) => '• $lead').join('\n'),
    );
    return sections.isEmpty
        ? 'Noch kein Wiederaufnahmekontext gespeichert.'
        : sections.join('\n\n');
  }
}

/// Does not write events, checkpoints, campaign fields or provider messages.
class CampaignResumeReader {
  const CampaignResumeReader._();

  // Saved thread IDs, not their display titles, bind a lead to one identity.
  static final RegExp _safeThreadId = RegExp(r'^[a-zA-Z0-9_-]{1,64}$');

  // Compare the full raw story sources, not only the visible bounded excerpt.
  // None of these fields is a rule result, and no JSON/SQLite writes occur.
  static String _sourceStamp(Campaign campaign) => jsonEncode({
    'scene': campaign.scene,
    'sessionRecaps': [
      for (final recap in campaign.sessionRecaps) recap.toJson(),
    ],
    'facts': campaign.facts,
    'storyThreads': [
      for (final thread in campaign.storyThreads) thread.toJson(),
    ],
  });

  static CampaignResumeSnapshot read(
    Campaign campaign, {
    int maxLeads = 3,
    int maxFacts = 4,
  }) {
    if (maxLeads < 1 || maxLeads > 5 || maxFacts < 1 || maxFacts > 10) {
      throw const FormatException(
        'Wiederaufnahme benötigt gültige Fakten- und Handlungsgrenzen.',
      );
    }

    // All source strings can originate from imported older saves. Never let
    // embedded newlines, Bidi overrides or invisible control characters
    // impersonate a trusted section heading in the rendered overview.
    final scene = _excerpt(campaign.scene, 320);
    final recap = campaign.sessionRecaps.isEmpty
        ? ''
        : _excerpt(campaign.sessionRecaps.last.summary, 800);

    final facts = <String>[];
    for (final fact in campaign.facts.entries.toList().reversed) {
      final key = _excerpt(fact.key, 80);
      final value = _excerpt(fact.value, 180);
      if (key.isEmpty || value.isEmpty) continue;
      facts.add('$key: $value');
      if (facts.length == maxFacts) break;
    }

    // Old imported saves may contain the same thread ID more than once,
    // including contradictory open/resolved statuses. No such record can
    // prove an active lead. Exclude every ambiguous or unsafe identity
    // rather than resurrecting an older open entry or trusting its position.
    final threadIdCounts = <String, int>{};
    for (final thread in campaign.storyThreads) {
      threadIdCounts[thread.id] = (threadIdCounts[thread.id] ?? 0) + 1;
    }

    final leads = <String>[];
    for (final thread in campaign.storyThreads.reversed) {
      if (thread.status != 'open' ||
          _safeThreadId.stringMatch(thread.id) != thread.id ||
          threadIdCounts[thread.id] != 1) {
        continue;
      }
      final title = _excerpt(thread.title, 100);
      final note = _excerpt(thread.description, 180);
      if (title.isEmpty || note.isEmpty) continue;
      leads.add('$title: $note');
      if (leads.length == maxLeads) break;
    }

    return CampaignResumeSnapshot._saved(
      campaign: campaign,
      latestScene: scene.isEmpty ? null : scene,
      latestSavedRecap: recap.isEmpty ? null : recap,
      confirmedFacts: facts,
      openLeads: leads,
    );
  }
}

String _excerpt(String original, int maxUnits) {
  final cleaned = original
      .replaceAll(
        RegExp(
          r'[\x00-\x1f\x7f-\x9f\u061c\u200b-\u200f'
          r'\u2028-\u202e\u2060-\u2069\ufeff]',
        ),
        ' ',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleaned.length <= maxUnits) return cleaned;

  final output = StringBuffer();
  var length = 0;
  for (final rune in cleaned.runes) {
    final units = rune > 0xffff ? 2 : 1;
    if (length + units > maxUnits - 1) break;
    output.writeCharCode(rune);
    length += units;
  }
  return '${output.toString().trimRight()}…';
}
