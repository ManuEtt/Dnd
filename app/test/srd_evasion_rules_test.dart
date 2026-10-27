import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_class_feature_catalog.dart';
import 'package:lebendiger_spielleiter/rules/rules_api.dart';

HeroCharacter _hero({
  String className = 'Mönch',
  int level = 7,
  String secondaryClassName = '',
  int secondaryClassLevel = 0,
  int? hitPoints = 30,
  List<String> conditions = const [],
}) => HeroCharacter(
  id: 'evasion-tested',
  name: 'Nebeltritt',
  className: className,
  secondaryClassName: secondaryClassName,
  secondaryClassLevel: secondaryClassLevel,
  level: level,
  hitPoints: hitPoints,
  maxHitPoints: 30,
  armorClass: 15,
  speed: 9,
  conditions: conditions,
  abilities: const {
    'strength': 10,
    'dexterity': 16,
    'constitution': 14,
    'intelligence': 12,
    'wisdom': 16,
    'charisma': 10,
  },
);

SrdEvasionResult _preview(
  HeroCharacter hero, {
  int? damage = 23,
  bool confirmedDamage = true,
  bool halfOnDexSave = true,
  bool? succeeded = true,
}) => SrdEvasionRules.previewConfirmedDexteritySave(
  hero,
  incomingDamage: damage,
  incomingDamageConfirmed: confirmedDamage,
  dexteritySaveForHalfConfirmed: halfOnDexSave,
  saveSucceeded: succeeded,
);

void main() {
  test('Monk and Rogue unlock separately at actual class level seven', () {
    for (final name in ['Mönch', 'Schurke']) {
      expect(SrdEvasionRules.unlocked(_hero(className: name, level: 6)), false);
      expect(SrdEvasionRules.unlocked(_hero(className: name, level: 7)), true);
      expect(SrdEvasionRules.unlocked(_hero(className: name, level: 20)), true);
    }
    expect(
      SrdEvasionRules.unlocked(_hero(className: 'Kämpfer', level: 20)),
      false,
    );
  });

  test('Second-class levels never masquerade as total levels', () {
    final second = _hero(
      className: 'Kämpfer',
      level: 16,
      secondaryClassName: 'Schurke',
      secondaryClassLevel: 7,
    );
    expect(SrdEvasionRules.unlocked(second), true);
    expect(_preview(second).damageAfterEvasion, 0);
    final below = second.copyWith(level: 16, secondaryClassLevel: 6);
    expect(SrdEvasionRules.unlocked(below), false);
    expect(() => _preview(below), throwsFormatException);
    final primary = _hero(
      className: 'Mönch',
      level: 9,
      secondaryClassName: 'Kämpfer',
      secondaryClassLevel: 2,
    );
    expect(SrdEvasionRules.unlocked(primary), true);
    expect(_preview(primary, succeeded: false).damageAfterEvasion, 11);
  });

  test('Success avoids all and failure halves pre-save damage rounding down', () {
    final hero = _hero();
    for (final damage in [0, 1, 2, 3, 23, 100000]) {
      final success = _preview(hero, damage: damage);
      expect(success.saveSucceeded, true);
      expect(success.incomingDamage, damage);
      expect(success.damageAfterEvasion, 0);
      expect(success.preventedDamage, damage);

      final failed = _preview(hero, damage: damage, succeeded: false);
      expect(failed.saveSucceeded, false);
      expect(failed.incomingDamage, damage);
      expect(failed.damageAfterEvasion, damage ~/ 2);
      expect(failed.preventedDamage, damage - damage ~/ 2);
    }
  });

  test('Unknown save outcome, source or damage fails closed', () {
    final hero = _hero();
    expect(() => _preview(hero, damage: null), throwsFormatException);
    expect(() => _preview(hero, damage: -1), throwsFormatException);
    expect(() => _preview(hero, damage: 100001), throwsFormatException);
    expect(
      () => _preview(hero, confirmedDamage: false),
      throwsFormatException,
    );
    expect(
      () => _preview(hero, halfOnDexSave: false),
      throwsFormatException,
    );
    expect(() => _preview(hero, succeeded: null), throwsFormatException);
  });

  test('No benefit during incapacitation, even with a confirmed save', () {
    for (final condition in [
      'handlungsunfähig',
      'bewusstlos',
      'betäubt',
      'gelähmt',
      'versteinert',
    ]) {
      final hero = _hero(conditions: [condition]);
      expect(SrdEvasionRules.unlocked(hero), true);
      expect(SrdEvasionRules.eligible(hero), false);
      expect(() => _preview(hero), throwsFormatException);
    }
    for (final hp in <int?>[null, 0]) {
      final hero = _hero(hitPoints: hp);
      expect(SrdEvasionRules.eligible(hero), false);
      expect(() => _preview(hero), throwsFormatException);
    }
  });

  test('Read-only preview does not modify hit points or JSON schema', () {
    final hero = _hero();
    final before = hero.toJson();
    final result = _preview(hero, damage: 31, succeeded: false);
    expect(result.damageAfterEvasion, 15);
    expect(hero.hitPoints, 30);
    expect(hero.toJson(), before);
    final restored = HeroCharacter.fromJson(before);
    expect(restored.toJson(), before);
    expect(_preview(restored, succeeded: false).damageAfterEvasion, 11);
  });

  test('Catalogue correctly identifies a partial rule, not an auto-commit', () {
    for (final name in ['Mönch', 'Schurke']) {
      final entry = SrdClassFeatureCatalog.atClassLevel(name, 7)
          .singleWhere((feature) => feature.name == 'Evasion');
      expect(entry.automation, FeatureAutomation.partial);
      expect(entry.needsRuleResolution, true);
      expect(
        SrdClassFeatureCatalog.unlocked(_hero(className: name, level: 6))
            .where((feature) => feature.name == 'Evasion'),
        isEmpty,
      );
      expect(
        SrdClassFeatureCatalog.unlocked(_hero(className: name, level: 7))
            .where((feature) => feature.name == 'Evasion'),
        hasLength(1),
      );
    }
  });
}
