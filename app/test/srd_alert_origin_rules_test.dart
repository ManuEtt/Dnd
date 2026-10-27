import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/domain/character_rule_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rules_engine.dart';
import 'package:lebendiger_spielleiter/domain/srd_alert_origin_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_background_package.dart';

HeroCharacter heroAt(
  int level, {
  bool confirmedAlert = true,
  String background = 'Krimineller',
  int exhaustion = 0,
}) => HeroCharacter(
  id: 'initiative-hero',
  name: 'Tala',
  className: 'Schurke',
  level: level,
  background: background,
  hitPoints: 12,
  maxHitPoints: 12,
  exhaustionLevel: exhaustion,
  abilities: const {
    'strength': 10,
    'dexterity': 14,
    'constitution': 12,
    'intelligence': 10,
    'wisdom': 12,
    'charisma': 10,
  },
  startingBackgroundPackage: confirmedAlert
      ? SrdBackgroundPackageChoice(
          background: SrdBackground.criminal,
          takeGold: true,
        )
      : null,
);

void main() {
  test('confirmed Alert adds total-level proficiency at every tier', () {
    const levels = <int, int>{
      1: 2,
      4: 2,
      5: 3,
      8: 3,
      9: 4,
      12: 4,
      13: 5,
      16: 5,
      17: 6,
      20: 6,
    };
    for (final entry in levels.entries) {
      final hero = heroAt(entry.key);
      expect(SrdAlertOriginRules.hasInitiativeProficiency(hero), true);
      expect(RulesEngine.initiativeBonus(hero), 2 + entry.value);
      expect(CharacterRuleEngine.initiative(hero).modifier, 2 + entry.value);
      expect(RulesEngine.proficiencyBonus(entry.key), entry.value);
    }
  });

  test('plain background or forged feature text gives no bonus', () {
    final plain = heroAt(5, confirmedAlert: false);
    final forged = plain.copyWith(
      features: ['Herkunftstalent: Wachsam', 'Wachsam'],
    );
    expect(SrdAlertOriginRules.hasInitiativeProficiency(plain), false);
    expect(SrdAlertOriginRules.hasInitiativeProficiency(forged), false);
    expect(RulesEngine.initiativeBonus(plain), 2);
    expect(RulesEngine.initiativeBonus(forged), 2);
  });

  test('mismatched later background never grants a lingering feat', () {
    final hero = heroAt(9, background: 'Weiser');
    expect(SrdAlertOriginRules.hasInitiativeProficiency(hero), false);
    expect(RulesEngine.initiativeBonus(hero), 2);
    final withSage = heroAt(9, confirmedAlert: false).copyWith(
      startingBackgroundPackage: SrdBackgroundPackageChoice(
        background: SrdBackground.sage,
        takeGold: true,
      ),
    );
    expect(RulesEngine.initiativeBonus(withSage), 2);
  });

  test('exhaustion remains a separate d20 penalty, not double counted', () {
    final normal = heroAt(5);
    final exhausted = heroAt(5, exhaustion: 2);
    expect(RulesEngine.initiativeBonus(normal), 5);
    expect(RulesEngine.initiativeBonus(exhausted), 1);
    expect(CharacterRuleEngine.initiative(exhausted).modifier, 1);
  });

  test('confirmed choice persists via Hero JSON, legacy stays unchanged', () {
    final confirmed = heroAt(13);
    final encoded = confirmed.toJson();
    final restored = HeroCharacter.fromJson(encoded);
    expect(restored.toJson(), encoded);
    expect(RulesEngine.initiativeBonus(restored), 7);

    final legacy = heroAt(13, confirmedAlert: false).toJson();
    expect(legacy.containsKey('startingBackgroundPackage'), false);
    expect(HeroCharacter.fromJson(legacy).toJson(), legacy);
    expect(RulesEngine.initiativeBonus(HeroCharacter.fromJson(legacy)), 2);
  });

  test('initiative-only feat does not change attack or skill checks', () {
    final normal = heroAt(5, confirmedAlert: false);
    final alert = heroAt(5);
    expect(
      CharacterRuleEngine.attack(alert).modifier,
      CharacterRuleEngine.attack(normal).modifier,
    );
    expect(
      CharacterRuleEngine.abilityCheck(alert, 'dexterity').modifier,
      CharacterRuleEngine.abilityCheck(normal, 'dexterity').modifier,
    );
  });
}
