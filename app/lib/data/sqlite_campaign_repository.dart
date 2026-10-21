import 'dart:convert';

import 'package:path/path.dart' as paths;
import 'package:sqflite/sqflite.dart';

import '../domain/models.dart';
import 'campaign_repository.dart';

/// SQLite holds both the current snapshot and an immutable revision journal.
/// Narration providers never receive this object or a database handle.
class SqliteCampaignRepository implements CampaignRepository {
  SqliteCampaignRepository._(this._database);
  final Database _database;

  static Future<SqliteCampaignRepository> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final selectedFactory = factory ?? databaseFactory;
    final databasePath =
        path ??
        paths.join(
          await selectedFactory.getDatabasesPath(),
          'living_gm.sqlite',
        );
    final database = await selectedFactory.openDatabase(
      databasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onConfigure: (database) async {
          await database.execute('PRAGMA foreign_keys = ON');
        },
        onDowngrade: (database, oldVersion, newVersion) async {
          throw UnsupportedDatabaseVersion(oldVersion);
        },
        onCreate: (database, version) async {
          await database.execute('''
CREATE TABLE campaigns (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  revision INTEGER NOT NULL CHECK (revision >= 0),
  snapshot TEXT NOT NULL,
  initial_snapshot TEXT NOT NULL,
  updated_at TEXT NOT NULL
)''');
          await database.execute('''
CREATE TABLE campaign_revisions (
  campaign_id TEXT NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  revision INTEGER NOT NULL,
  snapshot TEXT NOT NULL,
  confirmed_at TEXT NOT NULL,
  PRIMARY KEY (campaign_id, revision)
)''');
          await database.execute('''
CREATE TABLE game_events (
  id TEXT PRIMARY KEY,
  campaign_id TEXT NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  revision INTEGER NOT NULL,
  ordinal INTEGER NOT NULL,
  event_json TEXT NOT NULL
)''');
          await database.execute('''
CREATE INDEX game_events_campaign
ON game_events(campaign_id, ordinal)''');
          await database.execute('''
CREATE TABLE characters (
  id TEXT PRIMARY KEY,
  snapshot TEXT NOT NULL,
  updated_at TEXT NOT NULL
)''');
          await database.execute('''
CREATE TABLE settings (
  id INTEGER PRIMARY KEY CHECK (id = 1),
  snapshot TEXT NOT NULL
)''');
        },
      ),
    );
    return SqliteCampaignRepository._(database);
  }

  @override
  Future<List<Campaign>> loadCampaigns() async {
    final rows = await _database.query('campaigns', orderBy: 'updated_at DESC');
    return rows
        .map((row) => _decodeCampaign(row['snapshot'] as String))
        .toList();
  }

  @override
  Future<Campaign?> getCampaign(String id) async {
    final rows = await _database.query(
      'campaigns',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty
        ? null
        : _decodeCampaign(rows.first['snapshot'] as String);
  }

  @override
  Future<void> saveCampaign(
    Campaign campaign, {
    List<GameEvent> events = const [],
    int? expectedRevision,
  }) => _saveCampaign(
    campaign,
    events: events,
    expectedRevision: expectedRevision,
  );

  Future<void> _saveCampaign(
    Campaign campaign, {
    List<GameEvent> events = const [],
    int? expectedRevision,
    bool imported = false,
  }) async {
    final campaignData = _validateCampaignData(campaign.toJson());
    final allEvents = List<Map<String, dynamic>>.from(
      (campaignData['events'] as List).map(
        (event) => Map<String, dynamic>.from(event as Map),
      ),
    );
    final eventById = <String, Map<String, dynamic>>{};
    for (final event in [
      ...allEvents,
      ...events.map((event) => event.toJson()),
    ]) {
      _validateEvent(event, campaign.id);
      final eventId = event['id'] as String;
      final previous = eventById[eventId];
      if (previous != null && _canonical(previous) != _canonical(event)) {
        throw const InvalidSaveException(
          'Eine Ereignis-ID hat widersprüchliche Daten.',
        );
      }
      eventById[eventId] = event;
    }
    campaignData['events'] = eventById.values.toList();
    final snapshot = _canonical(campaignData);
    final confirmedAt = DateTime.now().toUtc().toIso8601String();

    await _database.transaction((transaction) async {
      final rows = await transaction.query(
        'campaigns',
        where: 'id = ?',
        whereArgs: [campaign.id],
        limit: 1,
      );
      if (rows.isEmpty) {
        if ((!imported && campaign.revision != 0) ||
            (expectedRevision != null && expectedRevision != -1)) {
          throw const CampaignConflictException(
            'Der neue Spielstand benötigt Revision 0.',
          );
        }
        await transaction.insert('campaigns', {
          'id': campaign.id,
          'name': campaign.name,
          'revision': campaign.revision,
          'snapshot': snapshot,
          'initial_snapshot': snapshot,
          'updated_at': confirmedAt,
        });
      } else {
        final existing = rows.single;
        if (imported) {
          throw const CampaignConflictException(
            'Diese Kampagne existiert bereits. Der Import überschreibt keine Spielstände.',
          );
        }
        final storedRevision = existing['revision'] as int;
        if (storedRevision == campaign.revision &&
            existing['snapshot'] == snapshot) {
          return; // A retry after a lost response must never grant rewards twice.
        }
        if ((expectedRevision ?? campaign.revision - 1) != storedRevision ||
            campaign.revision != storedRevision + 1) {
          throw CampaignConflictException(
            'Der Spielstand wurde inzwischen geändert (Revision $storedRevision). Bitte neu laden.',
          );
        }
        final storedEvents = await transaction.query(
          'game_events',
          where: 'campaign_id = ?',
          whereArgs: [campaign.id],
        );
        for (final event in storedEvents) {
          final current = eventById[event['id'] as String];
          if (current == null || _canonical(current) != event['event_json']) {
            throw const InvalidSaveException(
              'Bestätigte Ereignisse dürfen nicht verändert oder entfernt werden.',
            );
          }
        }
        await transaction.update(
          'campaigns',
          {
            'name': campaign.name,
            'revision': campaign.revision,
            'snapshot': snapshot,
            'updated_at': confirmedAt,
          },
          where: 'id = ?',
          whereArgs: [campaign.id],
        );
      }

      await transaction.insert('campaign_revisions', {
        'campaign_id': campaign.id,
        'revision': campaign.revision,
        'snapshot': snapshot,
        'confirmed_at': confirmedAt,
      });
      var ordinal = 0;
      for (final event in eventById.values) {
        final eventJson = _canonical(event);
        final existing = await transaction.query(
          'game_events',
          where: 'id = ?',
          whereArgs: [event['id']],
          limit: 1,
        );
        if (existing.isNotEmpty) {
          if (existing.single['campaign_id'] != campaign.id ||
              existing.single['event_json'] != eventJson) {
            throw const InvalidSaveException(
              'Ereignis-ID ist bereits für andere Daten vergeben.',
            );
          }
        } else {
          await transaction.insert('game_events', {
            'id': event['id'],
            'campaign_id': campaign.id,
            'revision': campaign.revision,
            'ordinal': ordinal,
            'event_json': eventJson,
          });
        }
        ordinal++;
      }

      // The campaign and hero archive represent the same hero ID. Persist
      // progression/loot/XP in the *same* transaction as events and revision.
      // Imported campaigns may add an absent hero, but never replace a hero
      // already in the archive just because an older backup was imported.
      final hero = HeroCharacter.fromJson(
        Map<String, dynamic>.from(campaignData['hero'] as Map),
      );
      final archived = await transaction.query(
        'characters',
        columns: ['snapshot'],
        where: 'id = ?',
        whereArgs: [hero.id],
        limit: 1,
      );
      final previous = archived.isEmpty
          ? null
          : HeroCharacter.fromJson(
              Map<String, dynamic>.from(
                jsonDecode(archived.single['snapshot'] as String) as Map,
              ),
            );
      if ((previous == null || !imported) &&
          (previous == null || !_losesEarnedExperience(previous, hero))) {
        await transaction.insert('characters', {
          'id': hero.id,
          'snapshot': _canonical(hero.toJson()),
          'updated_at': confirmedAt,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  @override
  Future<void> deleteCampaign(String id) async {
    await _database.delete('campaigns', where: 'id = ?', whereArgs: [id]);
  }

  /// Repairs archives created before campaign progress was synchronized.
  /// Only a newer campaign for the same stable hero ID may take precedence;
  /// a later manual hero edit or higher known XP is never rolled back.
  Future<void> _reconcileArchivedCharacters() async {
    await _database.transaction((transaction) async {
      final archived = await transaction.query('characters');
      if (archived.isEmpty) return;
      final archivedById = {
        for (final row in archived) row['id'] as String: row,
      };
      final campaigns = await transaction.query(
        'campaigns',
        columns: ['snapshot', 'updated_at'],
        orderBy: 'updated_at DESC',
      );
      final checked = <String>{};
      for (final row in campaigns) {
        final data = Map<String, dynamic>.from(
          jsonDecode(row['snapshot'] as String) as Map,
        );
        final heroData = Map<String, dynamic>.from(data['hero'] as Map);
        final id = heroData['id'] as String;
        final oldRow = archivedById[id];
        if (oldRow == null || !checked.add(id)) continue;
        final savedAt = row['updated_at'] as String;
        if (savedAt.compareTo(oldRow['updated_at'] as String) <= 0) continue;
        final next = HeroCharacter.fromJson(heroData);
        final previous = HeroCharacter.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(oldRow['snapshot'] as String) as Map,
          ),
        );
        if (_losesEarnedExperience(previous, next)) continue;
        await transaction.update(
          'characters',
          {'snapshot': _canonical(next.toJson()), 'updated_at': savedAt},
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });
  }

  @override
  Future<List<HeroCharacter>> loadCharacters() async {
    await _reconcileArchivedCharacters();
    final rows = await _database.query(
      'characters',
      orderBy: 'updated_at DESC',
    );
    return rows
        .map(
          (row) => HeroCharacter.fromJson(
            Map<String, dynamic>.from(
              jsonDecode(row['snapshot'] as String) as Map,
            ),
          ),
        )
        .toList();
  }

  @override
  Future<void> saveCharacter(HeroCharacter character) async {
    _validateId(character.id);
    HeroCharacter.fromJson(character.toJson());
    await _database.insert('characters', {
      'id': character.id,
      'snapshot': _canonical(character.toJson()),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> deleteCharacter(String id) async {
    await _database.delete('characters', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<Map<String, dynamic>> loadSettings() async {
    final rows = await _database.query('settings', where: 'id = 1', limit: 1);
    return rows.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(
            jsonDecode(rows.single['snapshot'] as String) as Map,
          );
  }

  @override
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    await _database.insert('settings', {
      'id': 1,
      'snapshot': _canonical(settings),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<String> exportCampaign(String id) async {
    final campaign = await getCampaign(id);
    if (campaign == null) {
      throw const InvalidSaveException('Diese Kampagne wurde nicht gefunden.');
    }
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'living-gm-campaign',
      'schemaVersion': 1,
      'campaign': campaign.toJson(),
    });
  }

  @override
  Future<Campaign> importCampaign(String source) async {
    if (source.length > 10 * 1024 * 1024) {
      throw const InvalidSaveException('Der Import ist größer als 10 MB.');
    }
    late final Campaign campaign;
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) {
        throw const FormatException(
          'Ein Spielstand muss ein JSON-Objekt sein.',
        );
      }
      final envelope = Map<String, dynamic>.from(decoded);
      Map<String, dynamic> data;
      if (envelope.containsKey('format')) {
        if (envelope['format'] != 'living-gm-campaign' ||
            envelope['schemaVersion'] != 1 ||
            envelope['campaign'] is! Map) {
          throw const FormatException('Unbekanntes Spielstandformat.');
        }
        data = Map<String, dynamic>.from(envelope['campaign'] as Map);
      } else {
        data = envelope; // Seed snapshots can also be imported directly.
      }
      campaign = Campaign.fromJson(_validateCampaignData(data));
    } catch (error) {
      throw InvalidSaveException('Spielstand ist ungültig: $error');
    }
    await _saveCampaign(campaign, imported: true);
    return campaign;
  }

  @override
  Future<Campaign?> reconstructCampaign(String id, {int? revision}) async {
    final rows = await _database.query(
      'campaign_revisions',
      where: revision == null
          ? 'campaign_id = ?'
          : 'campaign_id = ? AND revision = ?',
      whereArgs: revision == null ? [id] : [id, revision],
      orderBy: 'revision DESC',
      limit: 1,
    );
    return rows.isEmpty
        ? null
        : _decodeCampaign(rows.single['snapshot'] as String);
  }

  @override
  Future<void> close() => _database.close();
}

/// An older campaign must not erase confirmed XP from a newer hero record.
bool _losesEarnedExperience(HeroCharacter previous, HeroCharacter next) {
  final earned = previous.experience;
  return earned != null &&
      (next.experience == null || next.experience! < earned);
}

Campaign _decodeCampaign(String snapshot) =>
    Campaign.fromJson(Map<String, dynamic>.from(jsonDecode(snapshot) as Map));

Map<String, dynamic> _validateCampaignData(Map<String, dynamic> source) {
  final data = Map<String, dynamic>.from(source);
  _validateId(data['id']);
  _validateId(data['sessionId']);
  for (final key in ['name', 'world', 'scene']) {
    if (data[key] is! String || (data[key] as String).trim().isEmpty) {
      throw InvalidSaveException('Das Feld $key fehlt oder ist leer.');
    }
  }
  if (data['revision'] is! int || (data['revision'] as int) < 0) {
    throw const InvalidSaveException('Die Spielstandrevision ist ungültig.');
  }
  if (data['hero'] is! Map ||
      data['events'] is! List ||
      (data['events'] as List).length > 10000) {
    throw const InvalidSaveException(
      'Charakter oder Ereignisprotokoll ist ungültig.',
    );
  }
  _validateId((data['hero'] as Map)['id']);
  final seen = <String>{};
  for (final rawEvent in data['events'] as List) {
    if (rawEvent is! Map) {
      throw const InvalidSaveException('Das Ereignisprotokoll ist ungültig.');
    }
    final event = Map<String, dynamic>.from(rawEvent);
    _validateEvent(event, data['id'] as String);
    if (!seen.add(event['id'] as String)) {
      throw const InvalidSaveException(
        'Eine Ereignis-ID ist im Import doppelt vorhanden.',
      );
    }
  }
  // Constructors permit incomplete historical values, but imported or manually
  // edited values must still satisfy the complete typed serialization contract.
  Campaign.fromJson(data);
  return data;
}

void _validateEvent(Map<String, dynamic> event, String campaignId) {
  _validateId(event['id']);
  if (event['campaignId'] != campaignId) {
    throw const InvalidSaveException(
      'Ein Ereignis gehört zu einer anderen Kampagne.',
    );
  }
  _validateId(event['sessionId']);
  GameEvent.fromJson(event);
}

void _validateId(dynamic id) {
  if (id is! String ||
      id.trim().isEmpty ||
      id.length > 128 ||
      id.codeUnits.any((unit) => unit < 32)) {
    throw const InvalidSaveException('Eine Objekt-ID ist ungültig.');
  }
}

String _canonical(dynamic value) {
  dynamic sorted(dynamic item) {
    if (item is Map) {
      final keys = item.keys.cast<String>().toList()..sort();
      return {for (final key in keys) key: sorted(item[key])};
    }
    if (item is List) return item.map(sorted).toList();
    return item;
  }

  return jsonEncode(sorted(value));
}
