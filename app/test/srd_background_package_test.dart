import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_background_package.dart';

void main() {
  var serial = 0;
  String id() => 'item-${serial++}';

  setUp(() => serial = 0);

  test('all four SRD starting kits give exact count, skills and coins', () {
    final kits = <SrdBackground, (int, int, List<String>)>{
      SrdBackground.acolyte: (5, 8, ['Motiv erkennen', 'Religion']),
      SrdBackground.criminal: (5, 16, ['Fingerfertigkeit', 'Heimlichkeit']),
      SrdBackground.sage: (5, 8, ['Arkane Kunde', 'Geschichte']),
      SrdBackground.soldier: (7, 14, ['Athletik', 'Einschüchtern']),
    };
    final game = SrdBackgroundPackageChoice.gamingSets.first.id;
    for (final entry in kits.entries) {
      final choice = SrdBackgroundPackageChoice(
        background: entry.key,
        takeGold: false,
        gamingSetCatalogId: entry.key == SrdBackground.soldier ? game : '',
      );
      final hero = HeroCharacter(
        id: 'hero',
        name: 'Entwurf',
        background: entry.key.label,
        gold: 4,
      );
      final result = choice.applyTo(hero, nextId: id);
      expect(result.inventory, hasLength(entry.value.$1));
      expect(result.gold, entry.value.$2 + 4);
      expect(result.skills, entry.value.$3);
      expect(result.startingBackgroundPackage!.toJson(), choice.toJson());
      expect(
        result.features,
        contains('Werkzeugübung: ${choice.toolProficiency}'),
      );
      expect(
        result.features.any(
          (feature) =>
              feature.contains(choice.originFeat) &&
              feature.contains('noch nicht automatisiert'),
        ),
        true,
      );
      expect(
        result.inventory.map((item) => item.id).toSet().length,
        result.inventory.length,
      );
      expect(HeroCharacter.fromJson(result.toJson()).toJson(), result.toJson());
      expect(() => choice.applyTo(result, nextId: id), throwsFormatException);
    }
  });

  test('four 50 GP alternatives grant no items but preserve all training', () {
    for (final background in SrdBackground.values) {
      final choice = SrdBackgroundPackageChoice(
        background: background,
        takeGold: true,
        gamingSetCatalogId: background == SrdBackground.soldier
            ? SrdBackgroundPackageChoice.gamingSets.last.id
            : '',
      );
      final initial = HeroCharacter(
        id: 'hero',
        name: 'Köchin',
        background: background.label,
        inventory: [const InventoryItem(id: 'kept', name: 'Alter Schlüssel')],
      );
      final result = choice.applyTo(initial, nextId: id);
      expect(result.gold, 50);
      expect(result.inventory.single.id, 'kept');
      expect(result.skills, hasLength(2));
      expect(
        result.features.any((name) => name.startsWith('Werkzeugübung: ')),
        true,
      );
      expect(choice.kitItems, isEmpty);
    }
  });

  test('soldier requires a real game even when taking 50 GP', () {
    expect(
      () => SrdBackgroundPackageChoice(
        background: SrdBackground.soldier,
        takeGold: true,
      ),
      throwsFormatException,
    );
    expect(
      () => SrdBackgroundPackageChoice(
        background: SrdBackground.soldier,
        takeGold: false,
        gamingSetCatalogId: 'item-holy-symbol',
      ),
      throwsFormatException,
    );
    expect(
      () => SrdBackgroundPackageChoice(
        background: SrdBackground.acolyte,
        takeGold: true,
        gamingSetCatalogId: SrdBackgroundPackageChoice.gamingSets.first.id,
      ),
      throwsFormatException,
    );
  });

  test('soldier game selection is the same equipment and trained tool', () {
    final set = SrdBackgroundPackageChoice.gamingSets.last;
    final choice = SrdBackgroundPackageChoice(
      background: SrdBackground.soldier,
      takeGold: false,
      gamingSetCatalogId: set.id,
    );
    final result = choice.applyTo(
      HeroCharacter(id: 'soldier', name: 'A', background: 'Soldat'),
      nextId: id,
    );
    expect(choice.toolProficiency, set.name);
    expect(
      result.inventory.singleWhere((i) => i.catalogId == set.id).name,
      set.name,
    );
    final arrows = result.inventory.singleWhere(
      (item) => item.catalogId == 'item-arrows-20',
    );
    expect(arrows.quantity, 1); // One twenty-arrow catalog bundle.
  });

  test('duplicate skills and mismatched background fail without mutation', () {
    final choice = SrdBackgroundPackageChoice(
      background: SrdBackground.criminal,
      takeGold: false,
    );
    final repeated = HeroCharacter(
      id: 'hero',
      name: 'A',
      background: 'Krimineller',
      skills: ['Heimlichkeit'],
      gold: 3,
    );
    final before = repeated.toJson();
    expect(() => choice.applyTo(repeated, nextId: id), throwsFormatException);
    expect(repeated.toJson(), before);
    expect(
      () => choice.applyTo(
        repeated.copyWith(skills: [], background: 'Weiser'),
        nextId: id,
      ),
      throwsFormatException,
    );
    expect(
      () => choice.applyTo(repeated.copyWith(skills: [], level: 2), nextId: id),
      throwsFormatException,
    );
  });

  test('missing metadata does not change legacy JSON, forged options fail', () {
    final legacy = HeroCharacter(id: 'legacy', name: 'Alt').toJson();
    expect(legacy.containsKey('startingBackgroundPackage'), false);
    expect(HeroCharacter.fromJson(legacy).toJson(), legacy);
    final record = SrdBackgroundPackageChoice(
      background: SrdBackground.acolyte,
      takeGold: false,
    );
    expect(
      SrdBackgroundPackageChoice.fromJson(record.toJson()).toJson(),
      record.toJson(),
    );
    final rejected = <Map<String, dynamic>>[
      {...record.toJson(), 'version': 22},
      {...record.toJson(), 'background': 'unknown'},
      {...record.toJson(), 'takeGold': 'yes'},
      {...record.toJson(), 'gamingSetCatalogId': 'item-dice-set'},
      {'version': 1, 'background': 'soldier', 'takeGold': true},
    ];
    for (final bad in rejected) {
      expect(
        () => SrdBackgroundPackageChoice.fromJson(bad),
        throwsFormatException,
      );
    }
  });
}
