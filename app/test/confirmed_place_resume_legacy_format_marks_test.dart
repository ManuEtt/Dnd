import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/confirmed_place_resume_selection.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Campaign _campaign({List<Place> places = const []}) => Campaign(
  id: 'legacy-place-recap',
  name: 'Der vergessene Turm',
  world: 'Valdorn',
  sessionId: 'session-two',
  hero: HeroCharacter(id: 'aria', name: 'Aria', hitPoints: 13),
  scene: 'Die KI behauptet, der Held besitze 999 Gold.',
  places: places,
  revision: 0,
);

void main() {
  sqfliteFfiInit();

  test('legacy soft hyphen and deprecated bidi marks never enter place recaps', () {
    for (final point in [
      0x00ad,
      0x206a,
      0x206b,
      0x206c,
      0x206d,
      0x206e,
      0x206f,
    ]) {
      final mark = String.fromCharCode(point);
      final original = _campaign(
        places: [
          Place(
            id: 'tower',
            name: 'Alte' + mark + 'Ruine',
            description: 'Der Schlüssel' + mark + 'liegt hier.',
          ),
        ],
      );
      final before = jsonEncode(original.toJson());
      final selection = ConfirmedPlaceResumeSelector.read(
        original,
        expectedRevision: 0,
      );

      expect(selection.entries, hasLength(1));
      expect(selection.entries.single.placeId, 'tower');
      expect(selection.entries.single.name, 'AlteRuine');
      expect(selection.entries.single.description, 'Der Schlüssel liegt hier.');
      expect(selection.playerOverview, contains('kein Besuchsnachweis'));
      expect(selection.playerOverview, isNot(contains('999 Gold')));
      expect(selection.playerOverview, isNot(contains(mark)));
      expect(selection.playerOverview.split('\n'), hasLength(2));
      selection.requireCurrent(original);
      expect(jsonEncode(original.toJson()), before);
      expect(before, contains(mark));
    }
  });

  test('distinct place IDs remain visible after identical-name sanitation', () {
    final invisible = String.fromCharCode(0x206e);
    final original = _campaign(
      places: [
        const Place(id: 'north', name: 'AlteRuine', description: 'Nordtor.'),
        Place(
          id: 'south',
          name: 'Alte' + invisible + 'Ruine',
          description: 'Südtor.',
        ),
      ],
    );
    final before = jsonEncode(original.toJson());
    final selection = ConfirmedPlaceResumeSelector.read(
      original,
      expectedRevision: 0,
    );

    expect(selection.entries.map((e) => e.placeId).toList(), [
      'north',
      'south',
    ]);
    expect(selection.entries.map((e) => e.name).toList(), [
      'AlteRuine',
      'AlteRuine',
    ]);
    expect(selection.playerOverview, contains('ID: north'));
    expect(selection.playerOverview, contains('ID: south'));
    expect(selection.playerOverview, isNot(contains(invisible)));
    expect(() => selection.entries.clear(), throwsUnsupportedError);

    final changed = original.copyWith(
      places: [
        original.places.first,
        Place(
          id: 'south',
          name: 'Alte' + invisible + 'Ruine',
          description: 'Ein neuer, noch nicht gezeigter Ort.',
        ),
      ],
    );
    expect(() => selection.requireCurrent(changed), throwsFormatException);
    selection.requireCurrent(original);
    expect(jsonEncode(original.toJson()), before);
  });

  test('legacy raw place data survives JSON and SQLite restart', () async {
    final softHyphen = String.fromCharCode(0x00ad);
    final bidi = String.fromCharCode(0x206a);
    final original = _campaign(
      places: [
        Place(
          id: 'legacy',
          name: 'Tor' + softHyphen + 'Ruine',
          description: 'Geheimnis' + bidi + 'bekannt.',
        ),
      ],
    );
    final json = jsonEncode(original.toJson());
    final imported = Campaign.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );
    final folder = await Directory.systemTemp.createTemp('place-legacy-');
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
      final selection = ConfirmedPlaceResumeSelector.read(
        restored,
        expectedRevision: restored.revision,
      );

      expect(selection.entries.single.name, 'TorRuine');
      expect(selection.entries.single.description, 'Geheimnis bekannt.');
      expect(selection.playerOverview, isNot(contains(softHyphen)));
      expect(selection.playerOverview, isNot(contains(bidi)));
      expect(selection.playerOverview, isNot(contains('999 Gold')));
      expect(restored.places.single.name, contains(softHyphen));
      expect(restored.places.single.description, contains(bidi));
      expect(restored.hero.hitPoints, 13);
      expect(restored.revision, 0);
      selection.requireCurrent(restored);
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
