import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/confirmed_session_recap_selection.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _savedAt = DateTime.utc(2026, 11, 10, 14, 30);

SessionRecap _recap(
  String id,
  String title,
  String summary, {
  DateTime? at,
}) => SessionRecap(
  id: id,
  title: title,
  summary: summary,
  createdAt: at ?? _savedAt,
);

Campaign _campaign({
  String id = 'historical-recap',
  String sessionId = 'session-continued',
  int revision = 3,
  List<SessionRecap> recaps = const [],
}) => Campaign(
  id: id,
  name: 'Der vergessene Turm',
  world: 'Valdorn',
  sessionId: sessionId,
  revision: revision,
  hero: HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 17),
  scene: 'Die KI behauptet unbestätigt 999 Gold.',
  sessionRecaps: recaps,
);

bool _validUtf16(String value) {
  for (var i = 0; i < value.length; i++) {
    final unit = value.codeUnitAt(i);
    if (unit >= 0xd800 && unit <= 0xdbff) {
      i++;
      if (i >= value.length) return false;
      if (value.codeUnitAt(i) < 0xdc00 || value.codeUnitAt(i) > 0xdfff) {
        return false;
      }
    } else if (unit >= 0xdc00 && unit <= 0xdfff) {
      return false;
    }
  }
  return true;
}

void main() {
  sqfliteFfiInit();

  test('older recap can be selected beyond the latest saved recap', () {
    final campaign = _campaign(
      recaps: [
        _recap('old', 'Das alte Siegel', 'Die Karte lag beim Tor.'),
        _recap('latest', 'Der Hafen', 'Tarek wartet im Hafen.'),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final selected = ConfirmedSessionRecapSelector.readSelected(
      campaign,
      expectedRevision: 3,
      recapId: 'old',
    );
    final overview = selected.playerOverview;

    expect(selected.recapId, 'old');
    expect(selected.title, 'Das alte Siegel');
    expect(selected.createdAt, _savedAt);
    expect(overview, contains('Die Karte lag beim Tor.'));
    expect(overview, contains('ID: old'));
    expect(overview, contains('Gespeichert am: 2026-11-10T14:30:00.000Z'));
    expect(overview, contains('kein Beleg für aktuelle Regeln'));
    expect(overview, isNot(contains('Tarek wartet')));
    expect(overview, isNot(contains('999 Gold')));
    selected.requireCurrent(campaign);
    expect(campaign.hero.hitPoints, 17);
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('invalid, unknown and duplicate IDs fail closed without edits', () {
    final campaign = _campaign(
      recaps: [_recap('old', 'Eintrag', 'Die Karte bleibt im Archiv.')],
    );
    final before = jsonEncode(campaign.toJson());
    for (final badId in [
      '',
      'old\n',
      'old\r',
      'old\r\n',
      'old\u2028',
      'old\u200b',
      'bad id',
      List.filled(65, 'a').join(),
      'other',
    ]) {
      expect(
        () => ConfirmedSessionRecapSelector.readSelected(
          campaign,
          expectedRevision: 3,
          recapId: badId,
        ),
        throwsFormatException,
      );
    }
    final duplicate = _campaign(
      recaps: [
        _recap('old', 'Erste Aussage', 'Weg A.'),
        _recap('old', 'Andere Aussage', 'Weg B.'),
      ],
    );
    expect(
      () => ConfirmedSessionRecapSelector.readSelected(
        duplicate,
        expectedRevision: 3,
        recapId: 'old',
      ),
      throwsFormatException,
    );
    expect(jsonEncode(campaign.toJson()), before);
    expect(duplicate.sessionRecaps, hasLength(2));
  });

  test('revision, session and empty legacy texts fail closed', () {
    final saved = _campaign(
      recaps: [_recap('old', 'Eintrag', 'Ein gespeicherter Hinweis.')],
    );
    for (final revision in [-1, 2, 2147483648]) {
      expect(
        () => ConfirmedSessionRecapSelector.readSelected(
          saved,
          expectedRevision: revision,
          recapId: 'old',
        ),
        throwsFormatException,
      );
    }
    for (final content in [
      _recap('old', '\u200b\n', 'Eine Notiz.'),
      _recap('old', 'Titel', '\u202e\n\t'),
    ]) {
      expect(
        () => ConfirmedSessionRecapSelector.readSelected(
          _campaign(recaps: [content]),
          expectedRevision: 3,
          recapId: 'old',
        ),
        throwsFormatException,
      );
    }
    expect(
      () => ConfirmedSessionRecapSelector.readSelected(
        _campaign(
          sessionId: ' ',
          recaps: [_recap('old', 'Titel', 'Eine Notiz.')],
        ),
        expectedRevision: 3,
        recapId: 'old',
      ),
      throwsFormatException,
    );
    final legacy = _campaign().toJson()..remove('sessionRecaps');
    expect(
      () => ConfirmedSessionRecapSelector.readSelected(
        Campaign.fromJson(legacy),
        expectedRevision: 3,
        recapId: 'old',
      ),
      throwsFormatException,
    );
  });

  test('unicode and long historical notes stay bounded and line-safe', () {
    final dragons = List.filled(270, '🐉').join();
    final campaign = _campaign(
      recaps: [
        _recap(
          'old',
          'Mi\u200bra\nStatus: offen\u202e',
          'Chronik:\n$dragons\u206a\nAktuelle Regeln: falsch',
        ),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final selected = ConfirmedSessionRecapSelector.readSelected(
      campaign,
      expectedRevision: 3,
      recapId: 'old',
    );
    final overview = selected.playerOverview;

    expect(selected.title, 'Mira Status: offen');
    expect(overview.split('\n'), hasLength(4));
    expect(overview, isNot(contains('\u200b')));
    expect(overview, isNot(contains('\u202e')));
    expect(overview, isNot(contains('\u206a')));
    expect(overview, contains('Chronik:'));
    expect(overview, contains('…'));
    expect(overview.length, lessThanOrEqualTo(1200));
    expect(_validUtf16(overview), isTrue);
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('same-revision hidden edits and unrelated recaps invalidate', () {
    final summary = List.filled(900, 'a').join();
    final campaign = _campaign(
      recaps: [
        _recap('old', 'Gespeicherte Chronik', summary),
        _recap('other', 'Eine weitere Chronik', 'Ein alter Eintrag.'),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final selection = ConfirmedSessionRecapSelector.readSelected(
      campaign,
      expectedRevision: 3,
      recapId: 'old',
    );
    selection.requireCurrent(campaign);

    final changedOld = campaign.copyWith(
      sessionRecaps: [
        _recap('old', 'Gespeicherte Chronik', '${summary.substring(0, 899)}b'),
        _recap('other', 'Eine weitere Chronik', 'Ein alter Eintrag.'),
      ],
    );
    final changedOther = campaign.copyWith(
      sessionRecaps: [
        _recap('old', 'Gespeicherte Chronik', summary),
        _recap('other', 'Eine weitere Chronik', 'Ein neuer Eintrag.'),
      ],
    );
    for (final stale in [
      changedOld,
      changedOther,
      campaign.copyWith(revision: 4),
      _campaign(
        sessionId: 'another',
        recaps: campaign.sessionRecaps,
      ),
      _campaign(id: 'another', recaps: campaign.sessionRecaps),
    ]) {
      expect(() => selection.requireCurrent(stale), throwsFormatException);
    }
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('JSON and SQLite reopen preserve selected recap and replay', () async {
    final original = _campaign(
      revision: 0,
      recaps: [
        _recap('old', 'Der erste Abend', 'Das Tor war versiegelt.'),
        _recap('latest', 'Die zweite Nacht', 'Der Weg ist unklar.'),
      ],
    );
    final exported = jsonEncode(original.toJson());
    final imported = Campaign.fromJson(
      jsonDecode(exported) as Map<String, dynamic>,
    );
    final folder = await Directory.systemTemp.createTemp('recap-history-');
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
      final selected = ConfirmedSessionRecapSelector.readSelected(
        restored,
        expectedRevision: 0,
        recapId: 'old',
      );

      expect(selected.playerOverview, contains('Das Tor war versiegelt.'));
      expect(selected.playerOverview, isNot(contains('Der Weg ist unklar')));
      expect(selected.createdAt, _savedAt);
      selected.requireCurrent(restored);
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
