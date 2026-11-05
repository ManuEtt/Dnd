import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/story_memory_engine.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Campaign _campaign({
  List<Place> places = const [],
  int revision = 0,
}) => Campaign(
  id: 'place-recall-identity',
  name: 'Die zwei Ruinen',
  world: 'Valdorn',
  sessionId: 'session-two',
  revision: revision,
  hero: HeroCharacter(id: 'aria', name: 'Aria', hitPoints: 12),
  scene: 'Unbestätigt: Alle Ruinen sind ein und derselbe Ort.',
  places: places,
);

void main() {
  sqfliteFfiInit();

  test('same-name places retain two separate confirmed IDs', () {
    final campaign = _campaign(
      places: const [
        Place(
          id: 'west',
          name: 'Alte Ruine',
          description: 'Im Westen befindet sich ein Brunnen.',
        ),
        Place(
          id: 'east',
          name: 'ALTE RUINE',
          description: 'Im Osten befindet sich ein Brunnen.',
        ),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final memories = MemoryEngine.retrieve(
      campaign,
      'Was weißt du über die Ruine?',
      matchingOnly: true,
    );

    expect(memories, [
      'Ort: Alte Ruine (Ort-ID: west). '
          'Im Westen befindet sich ein Brunnen.',
      'Ort: ALTE RUINE (Ort-ID: east). '
          'Im Osten befindet sich ein Brunnen.',
    ]);
    expect(memories.join(' '), isNot(contains('Unbestätigt')));
    expect(jsonEncode(campaign.toJson()), before);
    expect(campaign.hero.hitPoints, 12);
    expect(() => memories.clear(), throwsUnsupportedError);
  });

  test('invisible legacy marks cannot disguise identical place names', () {
    final campaign = _campaign(
      places: const [
        Place(
          id: 'north',
          name: 'Alte\u200bRuine',
          description: 'Nord\u202e\nTor: offen.',
        ),
        Place(
          id: 'south',
          name: 'AlteRuine',
          description: 'Süd\u206f Tor: geschlossen.',
        ),
      ],
    );
    final recalled = MemoryEngine.retrieve(
      campaign,
      'Erinnere dich an die AlteRuine.',
      matchingOnly: true,
    );

    expect(recalled, hasLength(2));
    expect(recalled.first, startsWith('Ort: AlteRuine (Ort-ID: north)'));
    expect(recalled.last, startsWith('Ort: AlteRuine (Ort-ID: south)'));
    expect(recalled.first, contains('Nord Tor: offen.'));
    expect(recalled.last, contains('Süd Tor: geschlossen.'));
    expect(recalled.every((line) => !line.contains('\n')), isTrue);
    expect(recalled.join(' '), isNot(contains('\u200b')));
    expect(recalled.join(' '), isNot(contains('\u202e')));
    expect(recalled.join(' '), isNot(contains('\u206f')));
  });

  test('duplicate, malformed and missing IDs never prove a location', () {
    final campaign = _campaign(
      places: [
        const Place(id: 'same', name: 'Dorf', description: 'Weg nach Norden.'),
        const Place(id: 'same', name: 'Anderes Dorf'),
        const Place(id: 'bad id', name: 'Unsicher'),
        const Place(id: 'newline\n', name: 'Zeilenende'),
        const Place(id: '', name: 'Ohne ID'),
        Place(id: List.filled(65, 'x').join(), name: 'Zu lang'),
        const Place(id: 'safe', name: 'Burg', description: 'Ein Burgtor.'),
      ],
    );

    final recalled = MemoryEngine.retrieve(campaign, '', limit: 20);

    expect(recalled, ['Ort: Burg. Ein Burgtor.']);
    expect(recalled.join(' '), isNot(contains('Anderes Dorf')));
    expect(recalled.join(' '), isNot(contains('Unsicher')));
    expect(recalled.join(' '), isNot(contains('Zeilenende')));
    expect(recalled.join(' '), isNot(contains('Ohne ID')));
  });

  test('short memories must not lose disambiguating place IDs', () {
    final longWest = List.filled(64, 'w').join();
    final longEast = List.filled(64, 'e').join();
    final campaign = _campaign(
      places: [
        Place(id: longWest, name: 'Wald', description: 'Westliches Licht.'),
        Place(id: longEast, name: 'Wald', description: 'Östliches Licht.'),
        const Place(id: 'unique', name: 'Mühle'),
      ],
    );

    final short = MemoryEngine.retrieve(campaign, '', maxCharacters: 40);
    final long = MemoryEngine.retrieve(campaign, '', maxCharacters: 400);

    expect(short, ['Ort: Mühle']);
    expect(long, hasLength(3));
    expect(long.first, contains('Ort-ID: $longWest'));
    expect(long[1], contains('Ort-ID: $longEast'));
    expect(long.last, 'Ort: Mühle');
  });

  test('unique legacy names remain unchanged and game recall uses IDs', () {
    final campaign = _campaign(
      places: const [
        Place(id: 'street', name: 'Straße der Königin'),
        Place(id: 'west', name: 'Alte Ruine', description: 'Westhang.'),
        Place(id: 'east', name: 'Alte Ruine', description: 'Osthang.'),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final unique = MemoryEngine.retrieve(
      campaign,
      'STRASSE KOENIGIN',
      matchingOnly: true,
    );
    final result = GameEngine(
      clock: () => DateTime.utc(2026, 11, 5),
    ).act(campaign, 'Was weißt du über die Alte Ruine?');

    expect(unique, ['Ort: Straße der Königin']);
    expect(result.events.single.type, 'memory.recalled');
    expect(result.narration, contains('Ort-ID: west'));
    expect(result.narration, contains('Ort-ID: east'));
    expect(result.campaign.hero.toJson(), campaign.hero.toJson());
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('SQLite restart preserves two identically named places', () async {
    final original = _campaign(
      places: const [
        Place(id: 'west', name: 'Ruine', description: 'Westhang.'),
        Place(id: 'east', name: 'Ruine', description: 'Osthang.'),
      ],
    );
    final raw = jsonEncode(original.toJson());
    final decoded = Campaign.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    expect(jsonEncode(decoded.toJson()), raw);

    final folder = await Directory.systemTemp.createTemp('place-recall-id-');
    final path = paths.join(folder.path, 'campaign.sqlite');
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      await repository.saveCampaign(decoded);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final restored = (await repository.getCampaign(decoded.id))!;
      final before = jsonEncode(restored.toJson());
      final memories = MemoryEngine.retrieve(
        restored,
        'Ruine',
        matchingOnly: true,
      );

      expect(memories, [
        'Ort: Ruine (Ort-ID: west). Westhang.',
        'Ort: Ruine (Ort-ID: east). Osthang.',
      ]);
      expect(restored.hero.hitPoints, 12);
      expect(jsonEncode(restored.toJson()), before);
      expect(
        (await repository.reconstructCampaign(decoded.id))!.toJson(),
        restored.toJson(),
      );
    } finally {
      await repository.close();
      await folder.delete(recursive: true);
    }
  });
}
