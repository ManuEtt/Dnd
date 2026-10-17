import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/character_rule_engine.dart';
import 'package:lebendiger_spielleiter/domain/class_resource_rules.dart';
import 'package:lebendiger_spielleiter/domain/condition_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/saving_throw_class_actions.dart';

class _CountingRandom implements Random {
  int count = 0;

  @override
  int nextInt(int max) {
    count++;
    return max - 1;
  }

  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;
}

HeroCharacter _hero({
  List<String> conditions = const [],
  String className = 'Kämpfer',
  int level = 9,
  int exhaustion = 0,
}) => HeroCharacter(
  id: 'condition-save-hero',
  name: 'Liora',
  className: className,
  level: level,
  hitPoints: 25,
  maxHitPoints: 30,
  speed: 9,
  conditions: conditions,
  exhaustionLevel: exhaustion,
  abilities: const {
    'strength': 14,
    'dexterity': 16,
    'constitution': 12,
    'intelligence': 10,
    'wisdom': 12,
    'charisma': 10,
  },
  savingThrowProficiencies: const ['strength'],
);

void main() {
  group('SRD 5.2.1: Zustände und Rettungswürfe', () {
    for (final condition in [
      'gelähmt',
      'versteinert',
      'betäubt',
      'bewusstlos',
    ]) {
      test(
        '$condition lässt nur Stärke-/Geschicklichkeitsrettung misslingen',
        () {
          final hero = _hero(conditions: [condition], exhaustion: 1);
          for (final ability in hero.abilities.keys) {
            final rule = CharacterRuleEngine.savingThrow(hero, ability);
            final automatic = ability == 'strength' || ability == 'dexterity';
            expect(rule.automaticallyFails, automatic, reason: ability);
            expect(
              rule.modifier,
              CharacterRuleEngine.savingThrowBonus(hero, ability),
            );
            expect(
              rule.rollHint,
              automatic ? 'Automatisch misslungen' : 'Normalwurf',
            );
          }
          // STR 2 + proficiency 4 - exhaustion 2 remains visible on the sheet.
          expect(CharacterRuleEngine.savingThrow(hero, 'strength').modifier, 4);
          expect(
            CharacterRuleEngine.savingThrow(hero, 'dexterity').modifier,
            1,
          );
        },
      );

      for (final (className, level, feature, resource) in [
        ('Kämpfer', 9, SavingThrowRerollFeature.indomitable, 'indomitable'),
        (
          'Mönch',
          14,
          SavingThrowRerollFeature.disciplinedSurvivor,
          'focusPoints',
        ),
      ]) {
        test(
          '$condition: $className kann automatische Fehlschläge nicht wiederholen',
          () {
            final hero = _hero(
              conditions: [condition],
              className: className,
              level: level,
            );
            final random = _CountingRandom();
            final resourcesBefore = ClassResourceRules.remaining(
              hero,
              resource,
            );
            expect(resourcesBefore, greaterThan(0));
            for (final ability in ['strength', 'dexterity']) {
              expect(
                () => SavingThrowClassActions.rerollFailed(
                  hero: hero,
                  dice: DiceEngine(random: random),
                  ability: ability,
                  difficulty: 18,
                  originalTotal: 8,
                  feature: feature,
                ),
                throwsStateError,
              );
            }
            expect(random.count, 0);
            expect(hero.spentClassResources, isEmpty);
            expect(
              ClassResourceRules.remaining(hero, resource),
              resourcesBefore,
            );
          },
        );
      }
    }

    test(
      'Handlungsunfähig, gepackt und festgesetzt scheitern nicht automatisch',
      () {
        for (final condition in [
          'handlungsunfähig',
          'gepackt',
          'festgesetzt',
          'vergiftet',
          'blind',
        ]) {
          final hero = _hero(conditions: [condition]);
          for (final ability in hero.abilities.keys) {
            expect(
              CharacterRuleEngine.savingThrow(hero, ability).automaticallyFails,
              isFalse,
              reason: '$condition/$ability',
            );
          }
        }
        expect(
          CharacterRuleEngine.savingThrow(
            _hero(conditions: ['festgesetzt']),
            'dexterity',
          ).disadvantage,
          isTrue,
        );
      },
    );

    test(
      'Betäubt verhindert Aktionen, senkt die Bewegungsrate aber nicht auf 0',
      () {
        final stunned = _hero(conditions: ['betäubt']);
        expect(ConditionRules.canTakeActions(stunned), isFalse);
        expect(ConditionRules.canMove(stunned), isTrue);
        expect(CharacterRuleEngine.speedMeters(stunned), 9);
        expect(
          ConditionRules.hasUnconditionalAttackerAdvantage(stunned),
          isTrue,
        );
        expect(
          CharacterRuleEngine.speedMeters(
            stunned.copyWith(conditions: ['betäubt', 'gepackt']),
          ),
          0,
        );
        for (final condition in ['gelähmt', 'versteinert', 'bewusstlos']) {
          expect(
            CharacterRuleEngine.speedMeters(_hero(conditions: [condition])),
            0,
          );
        }
      },
    );

    test('Gefahrengespür verhindert keinen automatischen Fehlschlag', () {
      final normal = _hero(className: 'Barbar', level: 2);
      expect(
        CharacterRuleEngine.savingThrow(normal, 'dexterity').advantage,
        isTrue,
      );
      final stunned = normal.copyWith(conditions: ['betäubt']);
      final rule = CharacterRuleEngine.savingThrow(stunned, 'dexterity');
      expect(rule.advantage, isFalse);
      expect(rule.automaticallyFails, isTrue);
    });

    test('Konstitutionsrettung kann auch bei Betäubung wiederholt werden', () {
      final random = _CountingRandom();
      final result = SavingThrowClassActions.rerollFailed(
        hero: _hero(conditions: ['betäubt']),
        dice: DiceEngine(random: random),
        ability: 'constitution',
        difficulty: 18,
        originalTotal: 8,
        feature: SavingThrowRerollFeature.indomitable,
      );
      expect(random.count, 1);
      expect(result.roll.natural, 20);
      expect(result.passed, isTrue);
      expect(result.hero.spentClassResources['indomitable'], 1);
    });

    test(
      'Alte JSON-Zustände bleiben unverändert und berechnen die Regel neu',
      () {
        final oldJson = _hero(conditions: ['betäubt']).toJson();
        expect(oldJson.containsKey('automaticallyFails'), isFalse);
        final restored = HeroCharacter.fromJson(oldJson);
        expect(restored.conditions, ['betäubt']);
        expect(
          CharacterRuleEngine.savingThrow(
            restored,
            'dexterity',
          ).automaticallyFails,
          isTrue,
        );
        expect(CharacterRuleEngine.speedMeters(restored), 9);
        final unaffected = HeroCharacter.fromJson(_hero().toJson());
        expect(
          CharacterRuleEngine.savingThrow(
            unaffected,
            'dexterity',
          ).automaticallyFails,
          isFalse,
        );
        expect(const D20Rule(3).automaticallyFails, isFalse);
      },
    );
  });
}
