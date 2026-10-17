import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/class_progression_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_classes.dart';

HeroCharacter hero(
  String name,
  int level, {
  String secondClass = '',
  int secondLevel = 0,
}) => HeroCharacter(
  id: 'progression',
  name: 'Test',
  className: name,
  level: level,
  secondaryClassName: secondClass,
  secondaryClassLevel: secondLevel,
);

void main() {
  group('SRD 5.2.1 – Klassenstufen und zusätzliche Angriffe', () {
    test('jeder der zwölf Klassen ist bekannt und hat Wahlmeilensteine', () {
      expect(srdCharacterClasses, hasLength(12));
      for (final candidate in srdCharacterClasses) {
        final milestones = ClassProgressionRules.milestonesForClass(
          candidate.name,
        );
        expect(
          milestones.any(
            (m) =>
                m.classLevel == 3 &&
                m.type == ClassMilestoneType.subclassChoice,
          ),
          isTrue,
          reason: candidate.name,
        );
        for (final level in [4, 8, 12, 16, 19]) {
          expect(
            milestones.any((m) => m.classLevel == level),
            isTrue,
            reason: '${candidate.name} – Stufe $level',
          );
        }
        expect(
          milestones.every(
            (m) =>
                m.className == candidate.name &&
                m.classLevel >= 1 &&
                m.classLevel <= 20,
          ),
          isTrue,
        );
      }
    });

    test('nur fünf Basis-Klassen haben Extra Attack auf Klassenstufe 5', () {
      const martial = ['Barbar', 'Kämpfer', 'Mönch', 'Paladin', 'Waldläufer'];
      for (final c in srdCharacterClasses) {
        expect(
          ClassProgressionRules.attacksPerAttackAction(hero(c.name, 4)),
          1,
        );
        expect(
          ClassProgressionRules.attacksPerAttackAction(hero(c.name, 5)),
          martial.contains(c.name) ? 2 : 1,
          reason: c.name,
        );
      }
    });

    test('Kämpfer hat ab Klassenstufe 11 drei und ab 20 vier Angriffe', () {
      expect(
        ClassProgressionRules.attacksPerAttackAction(hero('Kämpfer', 10)),
        2,
      );
      expect(
        ClassProgressionRules.attacksPerAttackAction(hero('Kämpfer', 11)),
        3,
      );
      expect(
        ClassProgressionRules.attacksPerAttackAction(hero('Kämpfer', 19)),
        3,
      );
      expect(
        ClassProgressionRules.attacksPerAttackAction(hero('Kämpfer', 20)),
        4,
      );
      expect(
        ClassProgressionRules.attacksPerAttackAction(hero('fighter', 11)),
        3,
      );
    });

    test('Mehrklassen-Extra-Attack wird nicht addiert', () {
      expect(
        ClassProgressionRules.attacksPerAttackAction(
          hero('Barbar', 10, secondClass: 'Kämpfer', secondLevel: 5),
        ),
        2,
      );
      expect(
        ClassProgressionRules.attacksPerAttackAction(
          hero('Kämpfer', 16, secondClass: 'Paladin', secondLevel: 5),
        ),
        3,
      );
      expect(
        ClassProgressionRules.attacksPerAttackAction(
          hero('Magier', 16, secondClass: 'Kämpfer', secondLevel: 11),
        ),
        3,
      );
      expect(
        ClassProgressionRules.attacksPerAttackAction(
          hero('Magier', 10, secondClass: 'Schurke', secondLevel: 5),
        ),
        1,
      );
    });

    test('Wahlmeilensteine Kämpfer 6/14 und Schurke 10', () {
      final fighter = ClassProgressionRules.milestonesForClass('Kämpfer');
      expect(
        fighter.any(
          (m) => m.classLevel == 6 && m.type == ClassMilestoneType.featChoice,
        ),
        isTrue,
      );
      expect(
        fighter.any(
          (m) => m.classLevel == 14 && m.type == ClassMilestoneType.featChoice,
        ),
        isTrue,
      );
      final rogue = ClassProgressionRules.milestonesForClass('Schurke');
      expect(
        rogue.any(
          (m) => m.classLevel == 10 && m.type == ClassMilestoneType.featChoice,
        ),
        isTrue,
      );
      expect(ClassProgressionRules.milestonesForClass('Unbekannt'), isEmpty);
    });

    test(
      'nächste Meilensteine bleiben ohne automatische Charakteränderung',
      () {
        final character = hero('Kämpfer', 4);
        final next = ClassProgressionRules.nextMilestones(character, limit: 3);
        expect(next.first.classLevel, 5);
        expect(next.first.type, ClassMilestoneType.extraAttack);
        expect(character.features, isEmpty);
        expect(
          ClassProgressionRules.nextMilestones(hero('Kämpfer', 20)),
          isEmpty,
        );
        expect(
          () => ClassProgressionRules.nextMilestones(character, limit: 0),
          throwsRangeError,
        );
      },
    );
  });
}
