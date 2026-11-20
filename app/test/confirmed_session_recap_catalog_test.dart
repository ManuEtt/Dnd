import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/confirmed_session_recap_catalog.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _at = DateTime.utc(2026, 11, 14, 12);

SessionRecap _recap(
  String id,
  String title, {
  String summary = 'Damals bestätigte Zusammenfassung.',
  DateTime? at,
}) => SessionRecap(
  id: id,
  title: title,
  summary: summary,
  createdAt: at ?? _at,
);

Campaign _campaign({
  String id = 'recap-catalog',
  String sessionId = 'continued-session',
  int revision = 3,
  List<SessionRecap> recaps = const [],
}) => Campaign(
  id: id,
  name: 'Die alte Chronik',
  world: 'Valdorn',
  sessionId: sessionId,
  revision: revision,
  hero: HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 17),
  scene: 'Die KI behauptet: 999 Gold und eine Questbelohnung.',
  sessionRecaps: recaps,
);

bool _isValidUtf16(String text) {
  for (var i = 0; i < text.length; i++) {
    final code = text.codeUnitAt(i);
    if (code >= 0xd800 && code <= 0xdbff) {
      i++;
      if (i >= text.length) return false;
      if (text.codeUnitAt(i) < 0xdc00 || text.codeUnitAt(i) > 0xdfff) {
        return false;
      }
    } else if (code >= 0xdc00 && code <= 0xdfff) {
      return false;
    }
  }
  return true;
}

void main() {
  sqfliteFfiInit();

  test('page through old saved IDs without confirming narrative rewards', () {
    final campaign = _campaign(
      recaps: [
        for (var i = 0; i < 7; i++)
          _recap(
            'recap-$i',
            'Abend $i',
            at: DateTime.utc(2026, 11, i + 1),
            summary: 'Historischer Text mit $i gefundenen Münzen.',
          ),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final first = ConfirmedSessionRecapCatalog.read(
      campaign,
      expectedRevision: 3,
      pageSize: 3,
    );
    final last = ConfirmedSessionRecapCatalog.read(
      campaign,
      expectedRevision: 3,
      pageIndex: 2,
      pageSize: 3,
    );

    expect(first.entries.map((e) => e.recapId).toList(), [
      'recap-6',
      'recap-5',
      'recap-4',
    ]);
    expect(last.entries.map((e) => e.recapId).toList(), ['recap-0']);
    expect(first.hasMore, isTrue);
    expect(last.hasMore, isFalse);
    expect(last.pageIndex, 2);
    expect(last.playerOverview, contains('ID: recap-0'));
    expect(first.playerOverview, contains('Weitere gespeicherte Rückblicke'));
    expect(first.playerOverview, contains('kein aktueller Quest-'));
    expect(first.playerOverview, isNot(contains('999 Gold')));
    expect(first.playerOverview, isNot(contains('gefundenen Münzen')));
    first.requireCurrent(campaign);
    last.requireCurrent(campaign);
    expect(() => first.entries.clear(), throwsUnsupportedError);
    expect(jsonEncode(campaign.toJson()), before);
    expect(campaign.hero.hitPoints, 17);
  });

  test('equal timestamps use later saved order, not guessed identity', () {
    final campaign = _campaign(
      recaps: [
        _recap('first', 'Erster Eintrag'),
        _recap('second', 'Zweiter Eintrag'),
        _recap('third', 'Dritter Eintrag'),
      ],
    );
    final page = ConfirmedSessionRecapCatalog.read(
      campaign,
      expectedRevision: 3,
      pageSize: 2,
    );

    expect(page.entries.map((e) => e.recapId).toList(), ['third', 'second']);
    expect(page.entries.first.createdAt, _at);
    expect(page.hasMore, isTrue);
    expect(page.playerOverview.split('\n'), hasLength(5));
    page.requireCurrent(campaign);
  });

  test('unsafe and duplicate IDs cannot appear on any catalog page', () {
    final campaign = _campaign(
      recaps: [
        _recap('duplicate', 'Falsche erste Version'),
        _recap('duplicate', 'Falsche zweite Version'),
        _recap('bad id', 'Leerzeichen'),
        _recap('line\n', 'Zeilenumbruch'),
        _recap('hidden\u200b', 'Unsichtbare Kennung'),
        _recap('blank', '\u202e\n\t'),
        _recap('safe', 'Eindeutige Chronik'),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final page = ConfirmedSessionRecapCatalog.read(
      campaign,
      expectedRevision: 3,
      pageSize: 4,
    );

    expect(page.entries.map((e) => e.recapId).toList(), ['safe']);
    expect(page.playerOverview, contains('Eindeutige Chronik'));
    expect(page.playerOverview, isNot(contains('Falsche erste Version')));
    expect(page.playerOverview, isNot(contains('Unsichtbare Kennung')));
    expect(page.playerOverview, isNot(contains('Leerzeichen')));
    expect(page.hasMore, isFalse);
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('unicode formatting is removed without splitting emoji pairs', () {
    final dragons = List.filled(180, '🐉').join();
    final campaign = _campaign(
      recaps: [
        _recap(
          'old',
          'Mi\u200bra\nStatus: gelöst\u202e $dragons',
        ),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final page = ConfirmedSessionRecapCatalog.read(
      campaign,
      expectedRevision: 3,
    );
    final overview = page.playerOverview;

    expect(page.entries.single.title, startsWith('Mira Status: gelöst'));
    expect(page.entries.single.title, contains('…'));
    expect(overview, isNot(contains('\u200b')));
    expect(overview, isNot(contains('\u202e')));
    expect(overview.split('\n'), hasLength(3));
    expect(overview.length, lessThanOrEqualTo(1500));
    expect(_isValidUtf16(overview), isTrue);
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('invalid page and revision boundaries fail closed', () {
    final campaign = _campaign(recaps: [_recap('valid', 'Der Turm')]);
    for (final index in [-1, 1000001]) {
      expect(
        () => ConfirmedSessionRecapCatalog.read(
          campaign,
          expectedRevision: 3,
          pageIndex: index,
        ),
        throwsFormatException,
      );
    }
    for (final size in [-1, 0, 5]) {
      expect(
        () => ConfirmedSessionRecapCatalog.read(
          campaign,
          expectedRevision: 3,
          pageSize: size,
        ),
        throwsFormatException,
      );
    }
    for (final revision in [-1, 2, 2147483648]) {
      expect(
        () => ConfirmedSessionRecapCatalog.read(
          campaign,
          expectedRevision: revision,
        ),
        throwsFormatException,
      );
    }
    for (final invalid in [
      _campaign(id: ''),
      _campaign(sessionId: ' '),
    ]) {
      expect(
        () => ConfirmedSessionRecapCatalog.read(
          invalid,
          expectedRevision: 3,
        ),
        throwsFormatException,
      );
    }
    final outOfRange = ConfirmedSessionRecapCatalog.read(
      campaign,
      expectedRevision: 3,
      pageIndex: 100,
    );
    expect(outOfRange.entries, isEmpty);
    expect(outOfRange.hasMore, isFalse);
    expect(outOfRange.playerOverview, contains('Keine Rückblicke'));
  });

  test('stale same-revision edits outside page are detected', () {
    final campaign = _campaign(
      recaps: [
        _recap('old', 'Erste Spur', summary: List.filled(900, 'a').join()),
        _recap('new', 'Jüngste Spur', at: _at.add(const Duration(days: 1))),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final page = ConfirmedSessionRecapCatalog.read(
      campaign,
      expectedRevision: 3,
      pageSize: 1,
    );

    page.requireCurrent(campaign);
    final editedOld = campaign.copyWith(
      sessionRecaps: [
        _recap('old', 'Erste Spur', summary: List.filled(899, 'a').join() + 'b'),
        _recap('new', 'Jüngste Spur', at: _at.add(const Duration(days: 1))),
      ],
    );
    final editedNew = campaign.copyWith(
      sessionRecaps: [
        campaign.sessionRecaps.first,
        _recap('new', 'Andere Spur', at: _at.add(const Duration(days: 1))),
      ],
    );
    for (final stale in [
      editedOld,
      editedNew,
      campaign.copyWith(revision: 4),
      _campaign(id: 'other', recaps: campaign.sessionRecaps),
      _campaign(sessionId: 'other', recaps: campaign.sessionRecaps),
    ]) {
      expect(() => page.requireCurrent(stale), throwsFormatException);
    }
    page.requireCurrent(
      campaign.copyWith(hero: campaign.hero.copyWith(hitPoints: 1)),
    );
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('legacy JSON without recaps keeps empty safe pages', () {
    final data = _campaign().toJson()..remove('sessionRecaps');
    final restored = Campaign.fromJson(
      jsonDecode(jsonEncode(data)) as Map<String, dynamic>,
    );
    final before = jsonEncode(restored.toJson());
    final page = ConfirmedSessionRecapCatalog.read(
      restored,
      expectedRevision: 3,
    );

    expect(page.entries, isEmpty);
    expect(page.hasMore, isFalse);
    expect(page.playerOverview, contains('Keine Rückblicke'));
    page.requireCurrent(restored);
    expect(jsonEncode(restored.toJson()), before);
  });

  test('catalog survives JSON and SQLite reopen without writes', () async {
    final original = _campaign(
      revision: 0,
      recaps: [
        _recap('first', 'Der erste Abend', at: _at),
        _recap(
          'second',
          'Der zweite Abend',
          at: _at.add(const Duration(days: 1)),
        ),
      ],
    );
    final encoded = jsonEncode(original.toJson());
    final imported = Campaign.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );
    final folder = await Directory.systemTemp.createTemp('recap-catalog-');
    final path = paths.join(folder.path, 'campaign.sqlite');
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );

    try {
      await repository.saveCampaign(imported);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final restored = (await repository.getCampaign(original.id))!;
      final before = jsonEncode(restored.toJson());
      final page = ConfirmedSessionRecapCatalog.read(
        restored,
        expectedRevision: 0,
        pageSize: 1,
      );

      expect(page.entries.single.recapId, 'second');
      expect(page.hasMore, isTrue);
      expect(page.playerOverview, isNot(contains('999 Gold')));
      page.requireCurrent(restored);
      expect(restored.hero.toJson(), original.hero.toJson());
      expect(jsonEncode(restored.toJson()), before);
      expect(
        (await repository.reconstructCampaign(restored.id))!.toJson(),
        restored.toJson(),
      );
    } finally {
      await repository.close();
      await folder.delete(recursive: true);
    }
  });
}
