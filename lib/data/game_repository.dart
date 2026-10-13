import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../domain/models.dart';

class GameRepository {
  GameRepository._(this._database);
  final Database _database;

  static Future<GameRepository> open() async {
    final root = await getDatabasesPath();
    final db = await openDatabase(
      path.join(root, 'aetheria_v1.db'),
      version: 1,
      onCreate: (database, version) async {
        await database.execute('CREATE TABLE characters (id TEXT PRIMARY KEY, data TEXT NOT NULL)');
        await database.execute('CREATE TABLE campaigns (id TEXT PRIMARY KEY, hero_id TEXT NOT NULL, turn INTEGER NOT NULL, data TEXT NOT NULL)');
        await database.execute('CREATE TABLE events (id TEXT PRIMARY KEY, campaign_id TEXT NOT NULL, session_id TEXT NOT NULL, type TEXT NOT NULL, text TEXT NOT NULL, created_at TEXT NOT NULL, payload TEXT NOT NULL)');
        await database.execute('CREATE INDEX events_campaign ON events (campaign_id, created_at, id)');
      },
    );
    final repository = GameRepository._(db);
    await repository._seedIfEmpty();
    return repository;
  }

  Future<void> _seedIfEmpty() async {
    if ((await _database.rawQuery('SELECT COUNT(*) AS count FROM campaigns')).first['count'] != 0) return;
    final raw = await rootBundle.loadString('assets/arescan_save.json');
    final save = jsonDecode(raw) as Map<String, dynamic>;
    final hero = CharacterSheet.fromJson(save['character'] as Map<String, dynamic>);
    final campaign = Campaign.fromJson(save['campaign'] as Map<String, dynamic>);
    final history = List<String>.from(save['history'] as List);
    const demoHero = CharacterSheet(
      id: 'demo-mira', name: 'Mira', species: 'Mensch', characterClass: 'Waldläufer',
      abilities: {
        'Stärke': 12, 'Geschicklichkeit': 16, 'Konstitution': 14,
        'Intelligenz': 10, 'Weisheit': 14, 'Charisma': 8,
      },
      maxHp: 12, hp: 12, armorClass: 14, gold: 5,
      inventory: ['Kurzbogen', 'Reiseumhang', 'Heilkräuter'],
      background: 'Wanderin',
    );
    const demoCampaign = Campaign(
      id: 'mistwood', title: 'Die Glocken des Nebelwaldes', heroId: 'demo-mira',
      scene: 'Im Nebelwald erklingt eine Glocke, obwohl kein Turm zu sehen ist.',
      location: 'Aetheria – Nebelwald',
    );
    await _database.transaction((txn) async {
      for (final character in [hero, demoHero]) {
        await txn.insert('characters', {'id': character.id, 'data': jsonEncode(character.toJson())},
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      for (final item in [campaign, demoCampaign]) {
        await txn.insert('campaigns', {'id': item.id, 'hero_id': item.heroId, 'turn': item.turn,
            'data': jsonEncode(item.toJson())}, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      for (var i = 0; i < history.length; i++) {
        final event = GameEvent(
          id: 'historic-$i', campaignId: campaign.id, sessionId: 'imported-history',
          type: 'historic', text: history[i],
          createdAt: DateTime.utc(2026, 10, 13, 0, 0, i),
          data: {'historical': true, 'verifiedRules': false},
        );
        await txn.insert('events', event.toRow(), conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<List<CharacterSheet>> characters() async {
    final rows = await _database.query('characters', orderBy: 'id ASC');
    return rows.map((row) => CharacterSheet.fromJson(jsonDecode(row['data'] as String) as Map<String, dynamic>)).toList();
  }

  Future<CharacterSheet?> character(String id) async {
    final rows = await _database.query('characters', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : CharacterSheet.fromJson(jsonDecode(rows.first['data'] as String) as Map<String, dynamic>);
  }

  Future<void> saveCharacter(CharacterSheet character) async {
    await _database.insert('characters', {'id': character.id, 'data': jsonEncode(character.toJson())},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Campaign>> campaigns() async {
    final rows = await _database.query('campaigns', orderBy: 'id ASC');
    return rows.map((row) => Campaign.fromJson(jsonDecode(row['data'] as String) as Map<String, dynamic>)).toList();
  }

  Future<Campaign?> campaign(String id) async {
    final rows = await _database.query('campaigns', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Campaign.fromJson(jsonDecode(rows.first['data'] as String) as Map<String, dynamic>);
  }

  Future<void> createCampaign(Campaign campaign) async {
    await _database.insert('campaigns', {'id': campaign.id, 'hero_id': campaign.heroId,
      'turn': campaign.turn, 'data': jsonEncode(campaign.toJson())},
      conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<List<GameEvent>> events(String campaignId) async {
    final rows = await _database.query('events', where: 'campaign_id = ?', whereArgs: [campaignId],
        orderBy: 'created_at ASC, id ASC');
    return rows.map(GameEvent.fromRow).toList();
  }

  /// Atomic append and optimistic turn check: a duplicate submission cannot become a second turn.
  Future<void> appendTurn({required Campaign expected, required String playerText,
      required String narratorText}) async {
    final next = expected.copyWith(turn: expected.turn + 1);
    final now = DateTime.now().toUtc();
    await _database.transaction((txn) async {
      final updated = await txn.update('campaigns',
        {'turn': next.turn, 'data': jsonEncode(next.toJson())},
        where: 'id = ? AND turn = ?', whereArgs: [expected.id, expected.turn]);
      if (updated != 1) throw StateError('Spielstand ist veraltet – bitte neu laden.');
      for (final entry in <(String, String)>[
        ('player', playerText), ('narrator', narratorText),
      ]) {
        final event = GameEvent(
          id: '${expected.id}-${next.turn}-${entry.$1}',
          campaignId: expected.id, sessionId: 'local-solo', type: entry.$1,
          text: entry.$2, createdAt: now,
          data: {'turn': next.turn, 'rulesMutation': false},
        );
        await txn.insert('events', event.toRow(), conflictAlgorithm: ConflictAlgorithm.abort);
      }
    });
  }

  Future<void> appendRoll({required Campaign campaign, required String details,
      required Map<String, dynamic> data}) async {
    final event = GameEvent(
      id: '${campaign.id}-${DateTime.now().microsecondsSinceEpoch}-roll',
      campaignId: campaign.id, sessionId: 'local-solo', type: 'roll',
      text: details, createdAt: DateTime.now().toUtc(), data: data,
    );
    await _database.insert('events', event.toRow());
  }

  Future<void> close() => _database.close();
}
