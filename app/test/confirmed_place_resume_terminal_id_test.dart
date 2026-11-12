import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/confirmed_place_resume_selection.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Campaign _campaign({List<Place> places = const [], int revision = 0}) =>
    Campaign(
      id: 'strict-place-resume',
      name: 'Die alten Wege',
      world: 'Valdorn',
      sessionId: 'session-safe',
      hero: HeroCharacter(id: 'aria', name: 'Aria', hitPoints: 13),
      scene: 'Unbestätigt: Der Spieler hat einen Drachen bezwungen.',
      revision: revision,
      places: places,
    );

void main() {
  sqfliteFfiInit();

  test('only complete canonical place IDs appear in the overview', () {
    final longId = List.filled(64, 'a').join();
    final campaign = _campaign(
      places: [
        const Place(id: 'gate\n', name: 'Eingeschleuster Absatz'),
        const Place(id: 'well\r', name: 'Zeilenende CR'),
        const Place(id: 'tower\r\n', name: 'Zeilenende CRLF'),
        const Place(id: 'watch\u2028', name: 'Zeilentrenner'),
        const Place(id: 'hall\u2029', name: 'Absatztrenner'),
        const Place(id: 'bad\u200b', name: 'Unsichtbare ID'),
        const Place(
          id: 'valid-1',
          name: 'Brunnen',
          description: 'Klares Wasser.',
        ),
        Place(id: longId, name: 'Alter Turm'),
      ],
    );
    final before = jsonEncode(campaign.toJson());

    final selection = ConfirmedPlaceResumeSelector.read(
      campaign,
      expectedRevision: 0,
    );

    expect(selection.entries.map((e) => e.placeId).toList(), [
      'valid-1',
      longId,
    ]);
    expect(selection.playerOverview.split('\n'), hasLength(3));
    expect(selection.playerOverview, contains('ID: valid-1'));
    expect(selection.playerOverview, contains('ID: $longId'));
    expect(selection.playerOverview, isNot(contains('Eingeschleuster')));
    expect(selection.playerOverview, isNot(contains('Zeilenende')));
    expect(selection.playerOverview, isNot(contains('Zeilentrenner')));
    expect(selection.playerOverview, isNot(contains('Absatztrenner')));
    expect(selection.playerOverview, isNot(contains('Unsichtbare ID')));
    selection.requireCurrent(campaign);
    expect(() => selection.entries.clear(), throwsUnsupportedError);
    expect(jsonEncode(campaign.toJson()), before);
    expect(campaign.hero.hitPoints, 13);
  });

  test('an unsafe first place cannot consume a limited resume slot', () {
    final campaign = _campaign(
      places: const [
        Place(id: 'shrine\n', name: 'Nicht bestätigt'),
        Place(id: 'shrine', name: 'Alter Schrein'),
        Place(id: 'other', name: 'Eine weitere Ruine'),
      ],
    );
    final selection = ConfirmedPlaceResumeSelector.read(
      campaign,
      expectedRevision: 0,
      maxPlaces: 1,
    );

    expect(selection.entries.map((e) => e.placeId).toList(), ['shrine']);
    expect(selection.playerOverview, contains('Alter Schrein'));
    expect(selection.playerOverview, isNot(contains('Nicht bestätigt')));
    expect(selection.playerOverview, isNot(contains('weitere Ruine')));

    final changed = campaign.copyWith(
      places: const [
        Place(id: 'shrine\n', name: 'Nicht bestätigt'),
        Place(id: 'shrine', name: 'Neuer Name'),
        Place(id: 'other', name: 'Eine weitere Ruine'),
      ],
    );
    expect(() => selection.requireCurrent(changed), throwsFormatException);
    expect(
      () => selection.requireCurrent(campaign.copyWith(revision: 1)),
      throwsFormatException,
    );
  });

  test('an explicit saved ID can resume a place beyond the overview limit', () {
    final places = [
      for (var i = 0; i < 6; i++)
        Place(
          id: 'place-$i',
          name: 'Alte Ruine',
          description: 'Gespeicherte Beschreibung $i.',
        ),
    ];
    final campaign = _campaign(places: places);
    final before = jsonEncode(campaign.toJson());

    final overview = ConfirmedPlaceResumeSelector.read(
      campaign,
      expectedRevision: 0,
    );
    expect(overview.entries, hasLength(4));
    expect(overview.playerOverview, isNot(contains('ID: place-5')));

    final chosen = ConfirmedPlaceResumeSelector.readSelected(
      campaign,
      expectedRevision: 0,
      placeId: 'place-5',
    );
    expect(chosen.entries, hasLength(1));
    expect(chosen.entries.single.placeId, 'place-5');
    expect(chosen.entries.single.name, 'Alte Ruine');
    expect(chosen.entries.single.description, 'Gespeicherte Beschreibung 5.');
    expect(chosen.playerOverview, contains('kein Besuchsnachweis'));
    expect(chosen.playerOverview, isNot(contains('Drachen bezwungen')));
    expect(() => chosen.entries.clear(), throwsUnsupportedError);
    chosen.requireCurrent(campaign);
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('explicit place choice rejects ambiguous, missing and unsafe IDs', () {
    final sameNames = _campaign(
      places: const [
        Place(id: 'west', name: 'Ruine'),
        Place(id: 'east', name: 'Ruine'),
        Place(id: 'double', name: 'Tor'),
        Place(id: 'double', name: 'Anderes Tor'),
        Place(id: 'blank', name: '\u200b'),
      ],
    );
    final before = jsonEncode(sameNames.toJson());
    final chosen = ConfirmedPlaceResumeSelector.readSelected(
      sameNames,
      expectedRevision: 0,
      placeId: 'east',
    );
    expect(chosen.entries.single.placeId, 'east');
    expect(chosen.entries.single.name, 'Ruine');

    for (final unsafe in [
      '',
      'missing',
      'double',
      'blank',
      'west\n',
      'bad id',
      'ä',
      List.filled(65, 'a').join(),
    ]) {
      expect(
        () => ConfirmedPlaceResumeSelector.readSelected(
          sameNames,
          expectedRevision: 0,
          placeId: unsafe,
        ),
        throwsFormatException,
      );
    }
    expect(
      () => ConfirmedPlaceResumeSelector.readSelected(
        sameNames,
        expectedRevision: 1,
        placeId: 'east',
      ),
      throwsFormatException,
    );
    expect(
      () => chosen.requireCurrent(
        sameNames.copyWith(
          places: const [
            Place(id: 'west', name: 'Ruine'),
            Place(id: 'east', name: 'Umbenannte Ruine'),
            Place(id: 'double', name: 'Tor'),
            Place(id: 'double', name: 'Anderes Tor'),
            Place(id: 'blank', name: '\u200b'),
          ],
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => chosen.requireCurrent(
        sameNames.copyWith(hero: sameNames.hero.copyWith(hitPoints: 1)),
      ),
      returnsNormally,
    );
    expect(jsonEncode(sameNames.toJson()), before);
  });

  test('valid IDs survive JSON and SQLite restart', () async {
    final original = _campaign(
      places: const [
        Place(id: 'gate-west', name: 'Westtor'),
        Place(id: 'tower_1', name: 'Turm', description: 'Ein Licht brennt.'),
      ],
    );
    final restoredJson = Campaign.fromJson(
      jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
    );
    final folder = await Directory.systemTemp.createTemp('strict-place-id-');
    final path = paths.join(folder.path, 'campaign.sqlite');
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      await repository.saveCampaign(restoredJson);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final restored = (await repository.getCampaign(original.id))!;
      final before = jsonEncode(restored.toJson());
      final selection = ConfirmedPlaceResumeSelector.read(
        restored,
        expectedRevision: restored.revision,
      );

      expect(selection.entries.map((e) => e.placeId).toList(), [
        'gate-west',
        'tower_1',
      ]);
      expect(selection.playerOverview, contains('kein Besuchsnachweis'));
      expect(selection.playerOverview, isNot(contains('Drachen bezwungen')));
      expect(restored.hero.hitPoints, 13);
      selection.requireCurrent(restored);
      expect(jsonEncode(restored.toJson()), before);
      expect(
        (await repository.reconstructCampaign(original.id))!.toJson(),
        restored.toJson(),
      );
    } finally {
      await repository.close();
      await folder.delete(recursive: true);
    }
  });
}
