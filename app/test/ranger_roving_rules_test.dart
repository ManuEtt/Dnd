import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/character_rule_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

HeroCharacter ranger({
  int level = 6,
  String className = 'Waldläufer',
  String secondClass = '',
  int secondLevel = 0,
  int? speed = 9,
  int speedRemainder = 0,
  int exhaustion = 0,
  List<String> conditions = const [],
  String armorId = '',
  String shieldId = '',
  int strength = 16,
}) => HeroCharacter(
  id: 'roving-hero',
  name: 'Waldläufer-Test',
  className: className,
  level: level,
  secondaryClassName: secondClass,
  secondaryClassLevel: secondLevel,
  hitPoints: 20,
  maxHitPoints: 20,
  armorClass: 16,
  speed: speed,
  speedRemainderDecimeters: speedRemainder,
  exhaustionLevel: exhaustion,
  conditions: conditions,
  equippedArmorId: armorId,
  equippedShieldId: shieldId,
  equippedArmorTrained: true,
  equippedShieldTrained: true,
  abilities: {
    'strength': strength,
    'dexterity': 16,
    'constitution': 14,
    'intelligence': 12,
    'wisdom': 14,
    'charisma': 10,
  },
  inventory: const [
    InventoryItem(
      id: 'heavy',
      name: 'Plattenrüstung',
      catalogId: 'armor-plate-armor',
    ),
    InventoryItem(
      id: 'medium',
      name: 'Schuppenpanzer',
      catalogId: 'armor-scale-mail',
    ),
    InventoryItem(id: 'shield', name: 'Schild', catalogId: 'armor-shield'),
    InventoryItem(
      id: 'unknown',
      name: 'Nicht identifizierte Rüstung',
      catalogId: 'not-in-srd-catalog',
    ),
  ],
);

void main() {
  test('Roving appears at Ranger class level 6, not earlier', () {
    for (final level in [1, 5]) {
      final before = ranger(level: level);
      expect(CharacterRuleEngine.speedMeters(before), 9);
      expect(CharacterRuleEngine.rovingClimbSpeedMeters(before), isNull);
      expect(CharacterRuleEngine.rovingSwimSpeedMeters(before), isNull);
    }
    final after = ranger();
    expect(CharacterRuleEngine.speedMeters(after), 12);
    expect(CharacterRuleEngine.movementWholeMeters(after), 12);
    expect(CharacterRuleEngine.rovingClimbSpeedMeters(after), 12);
    expect(CharacterRuleEngine.rovingSwimSpeedMeters(after), 12);
    expect(after.speed, 9); // The saved base speed is not overwritten.
  });

  test('Heavy armor blocks bonus, but not climb and swim speeds', () {
    final heavy = ranger(armorId: 'heavy');
    expect(CharacterRuleEngine.speedMeters(heavy), 9);
    expect(CharacterRuleEngine.rovingClimbSpeedMeters(heavy), 9);
    expect(CharacterRuleEngine.rovingSwimSpeedMeters(heavy), 9);
    final weak = ranger(armorId: 'heavy', strength: 10);
    expect(CharacterRuleEngine.speedMeters(weak), 6);
    expect(CharacterRuleEngine.rovingClimbSpeedMeters(weak), 6);
    expect(CharacterRuleEngine.rovingSwimSpeedMeters(weak), 6);
  });

  test('Medium armor and shield do not suppress Roving', () {
    final equipped = ranger(armorId: 'medium', shieldId: 'shield');
    expect(CharacterRuleEngine.speedMeters(equipped), 12);
    expect(CharacterRuleEngine.rovingClimbSpeedMeters(equipped), 12);
    expect(CharacterRuleEngine.rovingSwimSpeedMeters(equipped), 12);
  });

  test('Unverified equipped armor must not unlock bonus automatically', () {
    final unresolved = ranger(armorId: 'unknown');
    expect(CharacterRuleEngine.speedMeters(unresolved), 9);
    // Class-granted speed types still exist at the confirmed normal speed.
    expect(CharacterRuleEngine.rovingClimbSpeedMeters(unresolved), 9);
    expect(CharacterRuleEngine.rovingSwimSpeedMeters(unresolved), 9);
  });

  test('Multiclass thresholds use only confirmed Ranger class levels', () {
    final secondary = ranger(
      className: 'Kämpfer',
      secondClass: 'Waldläufer',
      level: 11,
      secondLevel: 6,
    );
    expect(CharacterRuleEngine.speedMeters(secondary), 12);
    expect(CharacterRuleEngine.rovingSwimSpeedMeters(secondary), 12);
    final underLevel = secondary.copyWith(level: 10, secondaryClassLevel: 5);
    expect(CharacterRuleEngine.speedMeters(underLevel), 9);
    expect(CharacterRuleEngine.rovingClimbSpeedMeters(underLevel), isNull);
    final primary = ranger(secondClass: 'Magier', secondLevel: 5, level: 11);
    expect(CharacterRuleEngine.speedMeters(primary), 12);
    final otherClass = ranger(className: 'Kämpfer');
    expect(CharacterRuleEngine.speedMeters(otherClass), 9);
    expect(CharacterRuleEngine.rovingSwimSpeedMeters(otherClass), isNull);
  });

  test('Different class features only stack with independent sources', () {
    final mixed = ranger(
      className: 'Barbar',
      secondClass: 'Waldläufer',
      level: 11,
      secondLevel: 6,
    );
    // Barbar Fast Movement + Ranger Roving, each 10 feet.
    expect(CharacterRuleEngine.speedMeters(mixed), 15);
    expect(CharacterRuleEngine.rovingClimbSpeedMeters(mixed), 15);
    expect(CharacterRuleEngine.rovingSwimSpeedMeters(mixed), 15);
    expect(
      CharacterRuleEngine.speedMeters(mixed.copyWith(equippedArmorId: 'heavy')),
      9,
    );
  });

  test('Exhaustion and immobilization apply without changing base speed', () {
    final tired = ranger(exhaustion: 2, speedRemainder: 5);
    expect(CharacterRuleEngine.speedMeters(tired), 9.5);
    expect(CharacterRuleEngine.rovingClimbSpeedMeters(tired), 9.5);
    expect(CharacterRuleEngine.rovingSwimSpeedMeters(tired), 9.5);
    expect(CharacterRuleEngine.movementWholeMeters(tired), 9);
    final stopped = tired.copyWith(conditions: ['gepackt']);
    expect(CharacterRuleEngine.speedMeters(stopped), 0);
    expect(CharacterRuleEngine.rovingClimbSpeedMeters(stopped), 0);
    expect(CharacterRuleEngine.rovingSwimSpeedMeters(stopped), 0);
    final unknown = ranger(speed: null);
    expect(CharacterRuleEngine.speedMeters(unknown), isNull);
    expect(CharacterRuleEngine.rovingClimbSpeedMeters(unknown), isNull);
    expect(CharacterRuleEngine.rovingSwimSpeedMeters(unknown), isNull);
  });

  test(
    'Old character JSON roundtrip derives Roving without schema changes',
    () {
      final original = ranger(armorId: 'medium', shieldId: 'shield');
      final saved = original.toJson();
      final restored = HeroCharacter.fromJson(saved);
      // Validated inventory imports enrich supported catalog items with
      // canonical stats. Require a stable canonical second roundtrip, not
      // byte-for-byte equality with a deliberately minimal legacy inventory.
      final canonical = restored.toJson();
      expect(HeroCharacter.fromJson(canonical).toJson(), canonical);
      expect(CharacterRuleEngine.speedMeters(restored), 12);
      expect(CharacterRuleEngine.rovingClimbSpeedMeters(restored), 12);
      expect(CharacterRuleEngine.rovingSwimSpeedMeters(restored), 12);
      expect(restored.speed, 9);
    },
  );
}
