import '../domain/models.dart';

/// Every successful save is one atomic, confirmed campaign revision.
abstract interface class CampaignRepository {
  Future<List<Campaign>> loadCampaigns();
  Future<Campaign?> getCampaign(String id);
  Future<void> saveCampaign(
    Campaign campaign, {
    List<GameEvent> events = const [],
    int? expectedRevision,
  });
  Future<void> deleteCampaign(String id);
  Future<List<HeroCharacter>> loadCharacters();
  Future<void> saveCharacter(HeroCharacter character);
  Future<void> deleteCharacter(String id);
  Future<Map<String, dynamic>> loadSettings();
  Future<void> saveSettings(Map<String, dynamic> settings);
  Future<String> exportCampaign(String id);
  Future<Campaign> importCampaign(String source);
  Future<Campaign?> reconstructCampaign(String id, {int? revision});
  Future<void> close();
}

/// Delete every local user data table in a single durable transaction.
/// Implementations must leave every table unchanged if any deletion fails.
abstract interface class AtomicUserDataReset {
  Future<void> deleteAllUserData();
}

/// Atomic partial settings updates prevent stale independent writers from
/// replacing each other's unrelated preferences. A full saveSettings remains
/// available for deliberate complete replacements (for example, data reset).
abstract interface class AtomicSettingsStore {
  Future<void> updateSettingsEntries(
    Map<String, dynamic> changes, {
    Set<String> removeKeys = const <String>{},
  });
}

/// Uses an atomic database transaction on SQLite. Legacy mock repositories
/// retain their existing read/modify/write behavior for compatibility.
extension CampaignSettingsUpdates on CampaignRepository {
  Future<void> patchSettings(
    Map<String, dynamic> changes, {
    Set<String> removeKeys = const <String>{},
  }) async {
    if (removeKeys.any(changes.containsKey)) {
      throw ArgumentError(
        'Ein Einstellungsfeld darf nicht zugleich gesetzt und entfernt werden.',
      );
    }
    if (this case AtomicSettingsStore store) {
      await store.updateSettingsEntries(changes, removeKeys: removeKeys);
      return;
    }
    final settings = await loadSettings();
    for (final key in removeKeys) {
      settings.remove(key);
    }
    settings.addAll(changes);
    await saveSettings(settings);
  }
}

/// Dedicated durable command storage. Independent of the general settings JSON.
/// Implementations must serialize checks and mutations in one transaction.
abstract interface class PendingActionStore {
  Future<Map<String, dynamic>?> pendingActionFor(String campaignId);
  Future<void> stagePendingAction({
    required String campaignId,
    required String requestId,
    required String text,
  });
  Future<void> removePendingAction({
    required String campaignId,
    required String requestId,
    required String text,
  });

  /// Explicitly clear all pending commands during a user-requested data reset.
  Future<void> clearAllPendingActions();
}

class CampaignConflictException implements Exception {
  const CampaignConflictException(this.message);
  final String message;
  @override
  String toString() => message;
}

class InvalidSaveException implements Exception {
  const InvalidSaveException(this.message);
  final String message;
  @override
  String toString() => message;
}

class UnsupportedDatabaseVersion implements Exception {
  const UnsupportedDatabaseVersion(this.version);
  final int version;
  @override
  String toString() =>
      'Datenbankversion $version ist neuer als die unterstützte Version 2.';
}
