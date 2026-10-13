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
      'Datenbankversion $version ist neuer als die unterstützte Version 1.';
}
