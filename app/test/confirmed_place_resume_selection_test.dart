import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/confirmed_place_resume_selection.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Campaign _campaign({
  String sessionId = 'session-2',
  int revision = 3,
  List<Place> places = const [
    Place(id: 'tower', name: 'Turmruine', description: 'Eine alte Treppe.'),
    Place(id: 'well', name: 'Brunnen', description: 'Das Wasser ist dunkel.'),
  ],
}) => Campaign(
  id: 'places-campaign',
  name: 'Gespeicherte Welt',
  world: 'Valdorn',
  sessionId: sessionId,
  hero: HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 17),
  scene: 'Unbestätigt: Die Heldin hat den Drachen erschlagen.',
  revision: revision,
  places: places,
);

void main() {
  sqfliteFfiInit();

  test('only saved places and their IDs appear, without fictional visits', () {
    final campaign = _campaign();
    final original = jsonEncode(campaign.toJson());
    final selected = ConfirmedPlaceResumeSelector.read(
      campaign,
      expectedRevision: 3,
    );

    expect(selected.entries.map((entry) => entry.placeId).toList(), [
      'tower',
      'well',
    ]);
    expect(selected.playerOverview, contains('ID: tower'));
    expect(selected.playerOverview, contains('ID: well'));
    expect(selected.playerOverview, contains('kein Besuchsnachweis'));
    expect(selected.playerOverview, isNot(contains('Drachen erschlagen')));
    expect(selected.entries, hasLength(2));
    selected.requireCurrent(campaign);
    expect(() => selected.entries.clear(), throwsUnsupportedError);
    expect(jsonEncode(campaign.toJson()), original);
  });

  test('same-name places and injected lines stay distinct', () {
    final selected = ConfirmedPlaceResumeSelector.read(
      _campaign(
        places: const [
          Place(id: 'north', name: 'Alte\u200bRuine', description: 'Nordtor'),
          Place(
            id: 'south',
            name: 'AlteRuine',
            description: 'Süden\u202e\nQuest: abgeschlossen\tGold: 999',
          ),
        ],
      ),
      expectedRevision: 3,
    );

    expect(selected.entries, hasLength(2));
    expect(selected.entries.first.name, 'AlteRuine');
    expect(selected.entries.last.name, 'AlteRuine');
    expect(selected.playerOverview, contains('ID: north'));
    expect(selected.playerOverview, contains('ID: south'));
    expect(selected.playerOverview, isNot(contains('\u200b')));
    expect(selected.playerOverview, isNot(contains('\u202e')));
    expect(selected.playerOverview.split('\n'), hasLength(3));
    expect(selected.playerOverview, contains('Süden Quest: abgeschlossen'));
  });

  test('invalid and duplicated place IDs are never treated as identities', () {
    final selected = ConfirmedPlaceResumeSelector.read(
      _campaign(
        places: const [
          Place(id: 'double', name: 'Turm'),
          Place(id: 'double', name: 'Anderer Turm'),
          Place(id: 'bad id', name: 'Unsicher'),
          Place(id: 'safe', name: 'Gültig'),
          Place(id: 'blank', name: '\u200b'),
        ],
      ),
      expectedRevision: 3,
    );

    expect(selected.entries.map((entry) => entry.placeId).toList(), ['safe']);
    expect(selected.playerOverview, isNot(contains('Anderer Turm')));
    expect(selected.playerOverview, isNot(contains('Unsicher')));
    for (final limit in [-1, 0, 5]) {
      expect(
        () => ConfirmedPlaceResumeSelector.read(
          _campaign(),
          expectedRevision: 3,
          maxPlaces: limit,
        ),
        throwsFormatException,
      );
    }
    expect(
      () => ConfirmedPlaceResumeSelector.read(_campaign(), expectedRevision: 4),
      throwsFormatException,
    );
    expect(
      () => ConfirmedPlaceResumeSelector.read(
        _campaign(sessionId: ''),
        expectedRevision: 3,
      ),
      throwsFormatException,
    );
  });

  test('emoji-safe limits and stale same-revision edits', () {
    final dragons = List.filled(180, '🐉').join();
    final original = _campaign(
      places: [
        Place(id: 'tower', name: 'Turm $dragons', description: 'A$dragons'),
        const Place(id: 'well', name: 'Brunnen'),
      ],
    );
    final selected = ConfirmedPlaceResumeSelector.read(
      original,
      expectedRevision: 3,
      maxPlaces: 1,
    );

    expect(selected.playerOverview.length, lessThanOrEqualTo(1800));
    expect(selected.playerOverview, contains('…'));
    expect(selected.playerOverview.runes, isNot(contains(0xfffd)));
    selected.requireCurrent(original);
    final amended = original.copyWith(
      places: [
        Place(id: 'tower', name: 'Turm $dragons', description: 'B$dragons'),
        const Place(id: 'well', name: 'Brunnen'),
      ],
    );
    expect(() => selected.requireCurrent(amended), throwsFormatException);
    expect(
      () => selected.requireCurrent(original.copyWith(revision: 4)),
      throwsFormatException,
    );
    expect(
      () => selected.requireCurrent(_campaign(sessionId: 'other')),
      throwsFormatException,
    );
    expect(
      () => selected.requireCurrent(
        original.copyWith(hero: original.hero.copyWith(hitPoints: 1)),
      ),
      returnsNormally,
    );
  });

  test('legacy JSON without places yields an empty read-only recap', () {
    final json = _campaign().toJson()..remove('places');
    final restored = Campaign.fromJson(
      jsonDecode(jsonEncode(json)) as Map<String, dynamic>,
    );
    final snapshot = ConfirmedPlaceResumeSelector.read(
      restored,
      expectedRevision: 3,
    );

    expect(snapshot.entries, isEmpty);
    expect(snapshot.playerOverview, contains('Gespeicherte Orte'));
    snapshot.requireCurrent(restored);
  });

  test('SQLite restart preserves saved place IDs and state', () async {
    final folder = await Directory.systemTemp.createTemp('place-resume-');
    final path = paths.join(folder.path, 'campaign.sqlite');
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      final campaign = _campaign(revision: 0);
      await repository.saveCampaign(campaign);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final restored = (await repository.getCampaign(campaign.id))!;
      final before = jsonEncode(restored.toJson());
      final selection = ConfirmedPlaceResumeSelector.read(
        restored,
        expectedRevision: restored.revision,
      );

      expect(selection.entries.map((entry) => entry.placeId).toList(), [
        'tower',
        'well',
      ]);
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
