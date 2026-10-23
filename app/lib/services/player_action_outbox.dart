import 'dart:convert';
import 'dart:math';

import '../data/campaign_repository.dart';

/// A player's intent, written to local storage before a command is executed.
/// Retrying must reuse both the ID and the exact text of this intent.
class PendingPlayerAction {
  const PendingPlayerAction({
    required this.campaignId,
    required this.requestId,
    required this.text,
  });

  final String campaignId;
  final String requestId;
  final String text;

  Map<String, dynamic> toJson() => {
    'campaignId': campaignId,
    'requestId': requestId,
    'text': text,
  };

  factory PendingPlayerAction.fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Ungültige ausstehende Handlung.');
    }
    final campaignId = value['campaignId'];
    final requestId = value['requestId'];
    final text = value['text'];
    if (campaignId is! String ||
        campaignId.isEmpty ||
        campaignId.length > 128 ||
        requestId is! String ||
        requestId.isEmpty ||
        requestId.length > 128 ||
        RegExp(r'[^A-Za-z0-9_-]').hasMatch(requestId) ||
        text is! String ||
        text.isEmpty ||
        text.length > 4000) {
      throw const FormatException('Ungültige ausstehende Handlung.');
    }
    return PendingPlayerAction(
      campaignId: campaignId,
      requestId: requestId,
      text: text,
    );
  }
}

/// One durable pending action per campaign; other settings remain untouched.
///
/// No automatic replay on launch: retrying an unconfirmed action may contact a
/// paid narrator again. The player chooses whether to retry or discard it.
class PlayerActionOutbox {
  PlayerActionOutbox(this.repository, {String Function()? newRequestId})
    : _newRequestId = newRequestId ?? _secureRequestId;

  static const _settingsKey = 'pendingPlayerActionsV1';
  final CampaignRepository repository;
  final String Function() _newRequestId;

  static String _secureRequestId() {
    final random = Random.secure();
    final bytes = List<int>.generate(18, (_) => random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  Map<String, dynamic> _pendingMap(Map<String, dynamic> settings) {
    final raw = settings[_settingsKey];
    if (raw == null) return <String, dynamic>{};
    if (raw is! Map) {
      throw const FormatException(
        'Der ausstehende Handlungsstatus ist beschädigt.',
      );
    }
    return Map<String, dynamic>.from(raw);
  }

  Future<PendingPlayerAction?> pendingFor(String campaignId) async {
    if (repository case PendingActionStore store) {
      final raw = await store.pendingActionFor(campaignId);
      if (raw == null) return null;
      final action = PendingPlayerAction.fromJson(raw);
      if (action.campaignId != campaignId) {
        throw const FormatException(
          'Die ausstehende Handlung gehört zu einem anderen Spielstand.',
        );
      }
      return action;
    }
    final entries = _pendingMap(await repository.loadSettings());
    final raw = entries[campaignId];
    if (raw == null) return null;
    final action = PendingPlayerAction.fromJson(raw);
    if (action.campaignId != campaignId) {
      throw const FormatException(
        'Die ausstehende Handlung gehört zu einem anderen Spielstand.',
      );
    }
    return action;
  }

  /// Returns only after durable storage confirms the pending command.
  Future<PendingPlayerAction> stage(String campaignId, String text) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty || cleaned.length > 4000) {
      throw const FormatException(
        'Die Handlung muss 1 bis 4000 Zeichen enthalten.',
      );
    }
    final requestId = _newRequestId();
    final action = PendingPlayerAction.fromJson({
      'campaignId': campaignId,
      'requestId': requestId,
      'text': cleaned,
    });
    if (repository case PendingActionStore store) {
      await store.stagePendingAction(
        campaignId: action.campaignId,
        requestId: action.requestId,
        text: action.text,
      );
      return action;
    }
    // Legacy repositories without a transactional store retain the old
    // settings path. Production SQLite always uses the dedicated table.
    final settings = await repository.loadSettings();
    final entries = _pendingMap(settings);
    if (entries.containsKey(campaignId)) {
      throw StateError('Zuerst die ausstehende Handlung klären.');
    }
    // Reject collisions across campaigns as well; retries are unambiguous.
    for (final raw in entries.values) {
      if (PendingPlayerAction.fromJson(raw).requestId == action.requestId) {
        throw StateError('Handlungskennung bereits vergeben.');
      }
    }
    entries[campaignId] = action.toJson();
    settings[_settingsKey] = entries;
    await repository.saveSettings(settings);
    return action;
  }

  /// A stale completion must never clear a newer queued action.
  Future<void> remove(PendingPlayerAction action) async {
    if (repository case PendingActionStore store) {
      await store.removePendingAction(
        campaignId: action.campaignId,
        requestId: action.requestId,
        text: action.text,
      );
      return;
    }
    final settings = await repository.loadSettings();
    final entries = _pendingMap(settings);
    final raw = entries[action.campaignId];
    if (raw == null) return;
    final stored = PendingPlayerAction.fromJson(raw);
    if (stored.requestId != action.requestId || stored.text != action.text) {
      throw StateError('Die ausstehende Handlung hat sich geändert.');
    }
    entries.remove(action.campaignId);
    if (entries.isEmpty) {
      settings.remove(_settingsKey);
    } else {
      settings[_settingsKey] = entries;
    }
    await repository.saveSettings(settings);
  }
}
