import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/character_rule_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_character_sheet.dart';

HeroCharacter character({
  String characterClass = 'Kämpfer',
  int level = 1,
  int? wisdom = 12,
  List<String> skills = const ['Wahrnehmung'],
  int exhaustion = 0,
  List<String> conditions = const [],
  int? hitPoints = 15,
  String secondClass = '',
  int secondaryLevel = 0,
}) => HeroCharacter(
  id: 'passive-perception-test',
  name: 'Arescan',
  className: characterClass,
  level: level,
  secondaryClassName: secondClass,
  secondaryClassLevel: secondaryLevel,
  hitPoints: hitPoints,
  maxHitPoints: 20,
  speed: 9,
  armorClass: 13,
  abilities: {
    'strength': 12,
    'dexterity': 14,
    'constitution': 14,
    'intelligence': 12,
    'wisdom': wisdom,
    'charisma': 12,
  },
  skills: skills,
  exhaustionLevel: exhaustion,
  conditions: conditions,
);

void main() {
  group('Passive Wahrnehmung aus dem deutschen Einsteigerset, S. 6', () {
    test('10 + WE + bestätigte Wahrnehmungsübung, ohne Würfelwurf', () {
      final trained = character();
      expect(CharacterRuleEngine.perception(trained).modifier, 3);
      expect(CharacterRuleEngine.passivePerception(trained), 13);
      final untrained = character(skills: const []);
      expect(CharacterRuleEngine.passivePerception(untrained), 11);
      expect(CharacterRuleEngine.passivePerception(character(wisdom: 16)), 15);
    });

    test('Vorteil und Nachteil geben einmal ±5 und heben sich auf', () {
      final figure = character();
      expect(
        CharacterRuleEngine.passivePerception(
          figure,
          situationalAdvantage: true,
        ),
        18,
      );
      expect(
        CharacterRuleEngine.passivePerception(
          figure,
          situationalDisadvantage: true,
        ),
        8,
      );
      expect(
        CharacterRuleEngine.passivePerception(
          figure,
          situationalAdvantage: true,
          situationalDisadvantage: true,
        ),
        13,
      );
      final poisoned = character(conditions: const ['vergiftet']);
      expect(CharacterRuleEngine.passivePerception(poisoned), 8);
      expect(
        CharacterRuleEngine.passivePerception(
          poisoned,
          situationalAdvantage: true,
        ),
        13,
      );
      expect(
        CharacterRuleEngine.passivePerception(
          poisoned,
          situationalDisadvantage: true,
        ),
        8,
      );
    });

    test('Barden-Alleskönner und Erschöpfung wirken auch passiv', () {
      final bard = character(
        characterClass: 'Barde',
        level: 2,
        skills: const [],
      );
      // WE 12 = +1 and Jack of All Trades = +1.
      expect(CharacterRuleEngine.passivePerception(bard), 12);
      final mixed = character(
        characterClass: 'Kämpfer',
        secondClass: 'Barde',
        secondaryLevel: 2,
        level: 9,
        skills: const [],
      );
      // Proficiency +4 from TOTAL level => half +2, WE +1.
      expect(CharacterRuleEngine.passivePerception(mixed), 13);
      expect(
        CharacterRuleEngine.passivePerception(
          mixed.copyWith(exhaustionLevel: 2),
        ),
        9,
      );
      expect(
        CharacterRuleEngine.passivePerception(
          mixed.copyWith(skills: ['Wahrnehmung']),
        ),
        15,
      );
    });

    test('Niemals einen unbestätigten Wahrnehmungswert erfinden', () {
      expect(
        CharacterRuleEngine.passivePerception(character(wisdom: null)),
        isNull,
      );
      expect(
        CharacterRuleEngine.passivePerception(
          character(conditions: const ['bewusstlos']),
        ),
        isNull,
      );
      expect(
        CharacterRuleEngine.passivePerception(character(hitPoints: 0)),
        isNull,
      );
      expect(
        CharacterRuleEngine.passivePerception(
          character(conditions: const ['tot']),
        ),
        isNull,
      );
    });
  });

  group('Offline-Spielleitung meldet nur bestätigte Werte', () {
    test(
      'Passive Wahrnehmung würfelt nicht und enthüllt keine Storygeheimnisse',
      () {
        final gameMaster = GameEngine();
        final initial = gameMaster.createRabenwacht(
          gameMaster.createDemo().hero,
        );
        final beforeStage = initial.storyBible['stage'];
        final update = gameMaster.act(
          initial,
          'Wie hoch ist meine passive Wahrnehmung?',
        );
        final result = update.campaign;
        expect(result.pendingRoll, isNull);
        expect(result.storyBible['stage'], beforeStage);
        expect(result.facts, initial.facts);
        expect(update.events.single.type, 'rules.passivePerception');
        expect(update.events.single.payload['value'], 13);
        expect(update.events.single.payload['withoutDice'], true);
        expect(update.events.single.payload['grantsDiscovery'], false);
        expect(result.messages.last.text, contains('keine geheimen Hinweise'));
        expect(Campaign.fromJson(result.toJson()).toJson(), result.toJson());
      },
    );

    test(
      'Offene Würfelproben können nicht durch passiven Wert ersetzt werden',
      () {
        final engine = GameEngine();
        final initial = engine.createRabenwacht(engine.createDemo().hero);
        final opened = engine
            .act(initial, 'Ich untersuche die Schritte.')
            .campaign;
        expect(opened.pendingRoll?.type, 'preparedCheck');
        final update = engine.act(opened, 'passive Wahrnehmung');
        expect(update.campaign.pendingRoll?.id, opened.pendingRoll?.id);
        expect(update.events.single.type, isNot('rules.passivePerception'));
        expect(update.campaign.storyBible['stage'], 'road');
      },
    );

    test('Unbekannte Weisheit wird nicht durch erfundene Zahlen ersetzt', () {
      final engine = GameEngine();
      final base = engine.createDemo();
      final incomplete = base.copyWith(
        hero: base.hero.copyWith(
          abilities: {...base.hero.abilities, 'wisdom': null},
        ),
      );
      final update = engine.act(incomplete, 'passive wahrnehmung');
      expect(update.events.single.type, 'rules.blocked');
      expect(update.campaign.pendingRoll, isNull);
    });
  });

  for (final width in [320.0, 360.0, 400.0]) {
    testWidgets('Passive Wahrnehmung auf dem Charakterbogen bei $width dp', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(home: CharacterSheetPage(hero: character())),
      );
      await tester.pumpAndSettle();
      final strip = find.byKey(const ValueKey('sheet-passive-perception'));
      await tester.scrollUntilVisible(
        strip,
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final score = tester.widget<Text>(
        find.byKey(const ValueKey('sheet-passive-perception-score')),
      );
      expect(score.data, '13');
      expect(find.text('PASSIVE WAHRNEHMUNG'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
