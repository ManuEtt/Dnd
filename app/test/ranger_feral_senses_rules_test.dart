import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_class_feature_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_ranger_feral_senses_rules.dart';

HeroCharacter rangerSight({
  String className = 'Waldläufer',
  int level = 18,
  String secondaryClass = '',
  int secondaryLevel = 0,
  List<String> conditions = const [],
}) => HeroCharacter(
  id: 'feral-senses',
  name: 'Waldwacht',
  className: className,
  level: level,
  secondaryClassName: secondaryClass,
  secondaryClassLevel: secondaryLevel,
  hitPoints: 12,
  maxHitPoints: 12,
  armorClass: 14,
  speed: 9,
  conditions: conditions,
  abilities: const {
    'strength': 12,
    'dexterity': 16,
    'constitution': 14,
    'intelligence': 10,
    'wisdom': 16,
    'charisma': 10,
  },
);

void main() {
  test('Only Ranger class level 18 grants 30ft Blindsight', () {
    for (final level in [1, 6, 17]) {
      expect(
        SrdRangerFeralSensesRules.blindsightRangeFeet(
          rangerSight(level: level),
        ),
        isNull,
      );
    }
    for (final level in [18, 19, 20]) {
      expect(
        SrdRangerFeralSensesRules.blindsightRangeFeet(
          rangerSight(level: level),
        ),
        30,
      );
    }
    expect(SrdRangerFeralSensesRules.grantedRangeDecimeters, 90);
    expect(
      SrdRangerFeralSensesRules.blindsightRangeFeet(
        rangerSight(className: 'Magier'),
      ),
      isNull,
    );
  });

  test('Multiclass gating is based on Ranger levels, not character level', () {
    final rangerSecondary = rangerSight(
      className: 'Kämpfer',
      secondaryClass: 'Waldläufer',
      level: 19,
      secondaryLevel: 18,
    );
    expect(
      SrdRangerFeralSensesRules.blindsightRangeFeet(rangerSecondary),
      30,
    );
    final below = rangerSecondary.copyWith(
      level: 18,
      secondaryClassLevel: 17,
    );
    expect(SrdRangerFeralSensesRules.blindsightRangeFeet(below), isNull);
    final otherClass = rangerSight(
      className: 'Waldläufer',
      secondaryClass: 'Magier',
      level: 19,
      secondaryLevel: 2,
    );
    expect(SrdRangerFeralSensesRules.blindsightRangeFeet(otherClass), isNull);
  });

  test('Only confirmed positive target distances can be compared', () {
    final hero = rangerSight();
    for (final distance in [1, 5, 29, 30]) {
      expect(
        SrdRangerFeralSensesRules.withinConfirmedRange(
          hero,
          distanceFeet: distance,
          distanceConfirmed: true,
        ),
        true,
      );
    }
    for (final distance in [31, 45, 300]) {
      expect(
        SrdRangerFeralSensesRules.withinConfirmedRange(
          hero,
          distanceFeet: distance,
          distanceConfirmed: true,
        ),
        false,
      );
    }
    for (final distance in <int?>[null, -1, 0, 1000001]) {
      expect(
        SrdRangerFeralSensesRules.withinConfirmedRange(
          hero,
          distanceFeet: distance,
          distanceConfirmed: true,
        ),
        isNull,
      );
    }
    expect(
      SrdRangerFeralSensesRules.withinConfirmedRange(
        hero,
        distanceFeet: 3,
        distanceConfirmed: false,
      ),
      isNull,
    );
    expect(
      SrdRangerFeralSensesRules.withinConfirmedRange(
        rangerSight(level: 17),
        distanceFeet: 3,
        distanceConfirmed: true,
      ),
      isNull,
    );
  });

  test('Range is static; no status automatically resolves hidden targets', () {
    final hero = rangerSight(conditions: const ['blind']);
    expect(SrdRangerFeralSensesRules.blindsightRangeFeet(hero), 30);
    expect(hero.conditions, contains('blind'));
    expect(hero.abilities['wisdom'], 16);
    final before = hero.toJson();
    SrdRangerFeralSensesRules.withinConfirmedRange(
      hero,
      distanceFeet: 10,
      distanceConfirmed: true,
    );
    expect(hero.toJson(), before);
  });

  test('Catalog honestly marks range as partial, not complete detection', () {
    final feature = SrdClassFeatureCatalog.atClassLevel('Waldläufer', 18)
        .singleWhere((entry) => entry.name == 'Feral Senses');
    expect(feature.automation, FeatureAutomation.partial);
    expect(feature.needsRuleResolution, true);
    expect(
      SrdClassFeatureCatalog.unlocked(
        rangerSight(level: 17),
      ).where((entry) => entry.name == 'Feral Senses'),
      isEmpty,
    );
    expect(
      SrdClassFeatureCatalog.unlocked(
        rangerSight(),
      ).where((entry) => entry.name == 'Feral Senses'),
      hasLength(1),
    );
  });

  test('Legacy character JSON needs no new stored feature flag', () {
    final original = rangerSight();
    final restored = HeroCharacter.fromJson(original.toJson());
    final normalized = restored.toJson();
    expect(HeroCharacter.fromJson(normalized).toJson(), normalized);
    expect(
      SrdRangerFeralSensesRules.blindsightRangeFeet(restored),
      30,
    );
    expect(restored.features, isEmpty);
  });
}
