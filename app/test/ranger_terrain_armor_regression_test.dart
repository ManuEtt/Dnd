import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/character_rule_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_terrain_movement_rules.dart';

HeroCharacter rangerWithArmor(String catalogId) => HeroCharacter(
  id: 'terrain-armor-ranger',
  name: 'Feldläufer',
  className: 'Waldläufer',
  level: 6,
  hitPoints: 16,
  maxHitPoints: 16,
  speed: 9,
  armorClass: 15,
  equippedArmorId: 'equipped',
  equippedArmorTrained: true,
  abilities: const {
    'strength': 16,
    'dexterity': 14,
    'constitution': 14,
    'intelligence': 10,
    'wisdom': 14,
    'charisma': 10,
  },
  inventory: [
    InventoryItem(id: 'equipped', name: 'Testausrüstung', catalogId: catalogId),
  ],
);

void main() {
  test('Heavy armor suppresses bonus, not Ranger climbing/swimming type', () {
    final hero = rangerWithArmor('armor-plate-armor');
    expect(CharacterRuleEngine.speedMeters(hero), 9);
    expect(CharacterRuleEngine.rovingClimbSpeedMeters(hero), 9);
    expect(CharacterRuleEngine.rovingSwimSpeedMeters(hero), 9);
    for (final kind in SrdTerrainMovement.values) {
      expect(SrdTerrainMovementRules.hasSpecialSpeed(hero, kind), isTrue);
      expect(
        SrdTerrainMovementRules.costDecimeters(
          hero,
          kind: kind,
          distanceFeet: 5,
          difficultTerrain: false,
        ),
        15,
      );
      expect(
        SrdTerrainMovementRules.costDecimeters(
          hero,
          kind: kind,
          distanceFeet: 5,
          difficultTerrain: true,
        ),
        30,
      );
    }
  });

  test('Unknown equipment never fabricates bonus or special speed levels', () {
    final hero = rangerWithArmor('unknown-item');
    expect(CharacterRuleEngine.speedMeters(hero), 9);
    expect(CharacterRuleEngine.rovingClimbSpeedMeters(hero), 9);
    expect(CharacterRuleEngine.rovingSwimSpeedMeters(hero), 9);
    expect(
      SrdTerrainMovementRules.costDecimeters(
        hero,
        kind: SrdTerrainMovement.swim,
        distanceFeet: 10,
        difficultTerrain: false,
      ),
      30,
    );
    final below = hero.copyWith(level: 5);
    expect(CharacterRuleEngine.rovingClimbSpeedMeters(below), isNull);
    expect(
      SrdTerrainMovementRules.costDecimeters(
        below,
        kind: SrdTerrainMovement.swim,
        distanceFeet: 10,
        difficultTerrain: false,
      ),
      60,
    );
  });
}
