import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/class_resource_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/monk_focus_actions.dart';
import 'package:lebendiger_spielleiter/domain/rest_rules.dart';
import 'package:lebendiger_spielleiter/domain/rules_engine.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_character_sheet.dart';

class MinimumRoll implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

HeroCharacter monk({
  int level = 10,
  int temporary = 0,
  int focusSpent = 0,
  String className = 'Mönch',
  String secondary = '',
  int secondaryLevel = 0,
}) => HeroCharacter(
  id: 'monk',
  name: 'Arescan',
  className: className,
  secondaryClassName: secondary,
  secondaryClassLevel: secondaryLevel,
  level: level,
  temporaryHitPoints: temporary,
  hitPoints: 35,
  maxHitPoints: 40,
  armorClass: 16,
  speed: 9,
  weaponDamage: '1d8',
  weaponProficient: true,
  abilities: const {
    'strength': 13,
    'dexterity': 18,
    'constitution': 14,
    'intelligence': 10,
    'wisdom': 16,
    'charisma': 10,
  },
  spentClassResources: {if (focusSpent > 0) 'focusPoints': focusSpent},
);

Encounter fight() => const Encounter(
  id: 'fight',
  enemyName: 'Wache',
  enemyHitPoints: 20,
  enemyMaxHitPoints: 20,
  movementRemaining: 12,
);

void main() {
  group('SRD 5.2.1 temporäre Trefferpunkte', () {
    test('alte Spielstände ohne Feld laden mit null temporären TP', () {
      final before = monk().toJson();
      expect(before.containsKey('temporaryHitPoints'), isFalse);
      expect(HeroCharacter.fromJson(before).temporaryHitPoints, 0);
      final updated = monk(temporary: 12);
      expect(HeroCharacter.fromJson(updated.toJson()).temporaryHitPoints, 12);
    });

    test('ungültige negative/fremde temporäre Trefferpunkte ablehnen', () {
      final json = monk().toJson();
      expect(
        () => HeroCharacter.fromJson({...json, 'temporaryHitPoints': -1}),
        throwsFormatException,
      );
      expect(
        () => HeroCharacter.fromJson({...json, 'temporaryHitPoints': '8'}),
        throwsFormatException,
      );
      expect(
        () => HeroCharacter.fromJson({...json, 'temporaryHitPoints': 100001}),
        throwsFormatException,
      );
    });

    test('nicht stapelbar, ersetzbar nach Spielerentscheidung', () {
      final old = monk(temporary: 9);
      expect(RulesEngine.grantTemporaryHitPoints(old, 4).temporaryHitPoints, 9);
      expect(
        RulesEngine.grantTemporaryHitPoints(old, 12).temporaryHitPoints,
        12,
      );
      expect(
        RulesEngine.grantTemporaryHitPoints(
          old,
          4,
          replaceExisting: true,
        ).temporaryHitPoints,
        4,
      );
      expect(old.temporaryHitPoints, 9);
    });

    test('Schaden wird vollständig durch temporäre TP aufgefangen', () {
      final before = monk(temporary: 8);
      final after = RulesEngine.damage(before, 6);
      expect(after.hitPoints, 35);
      expect(after.temporaryHitPoints, 2);
      expect(before.hitPoints, 35);
      expect(after.conditions, isEmpty);
    });

    test(
      'überschüssiger Schaden trifft echte TP und kann bewusstlos machen',
      () {
        final after = RulesEngine.damage(monk(temporary: 5), 12);
        expect(after.temporaryHitPoints, 0);
        expect(after.hitPoints, 28);
        final fallen = RulesEngine.damage(
          monk(temporary: 5).copyWith(hitPoints: 4),
          9,
        );
        expect(fallen.hitPoints, 0);
        expect(fallen.temporaryHitPoints, 0);
        expect(fallen.conditions, contains(RulesEngine.unconscious));
      },
    );

    test('nur überschießender Schaden zählt bei massivem Schaden', () {
      final almostDead = monk(
        temporary: 30,
      ).copyWith(hitPoints: 3, maxHitPoints: 10);
      final survived = RulesEngine.damage(almostDead, 35);
      expect(survived.isDead, isFalse);
      expect(survived.hitPoints, 0);
      final dead = RulesEngine.damage(almostDead, 43);
      expect(dead.isDead, isTrue);
    });

    test('Heilung erhält temporäre TP; lange Rast löscht sie', () {
      final injured = monk(temporary: 9).copyWith(hitPoints: 20);
      expect(RulesEngine.heal(injured, 5).temporaryHitPoints, 9);
      expect(RestRules.longRest(injured).temporaryHitPoints, 0);
      expect(RestRules.longRest(injured).hitPoints, 40);
      final shortRest = RestRules.shortRest(
        injured,
        dice: DiceEngine(random: MinimumRoll()),
        dieSides: 8,
      );
      expect(shortRest.hero.temporaryHitPoints, 9);
    });

    test('temporäre TP bei null echten TP machen nicht bewusst', () {
      final unconscious = monk().copyWith(
        hitPoints: 0,
        conditions: ['bewusstlos'],
      );
      final shielded = RulesEngine.grantTemporaryHitPoints(unconscious, 10);
      expect(shielded.hitPoints, 0);
      expect(shielded.conditions, contains('bewusstlos'));
      final damaged = RulesEngine.damage(shielded, 5);
      expect(damaged.temporaryHitPoints, 5);
      expect(damaged.deathFailures, 1);
    });
  });

  group('Mönchsstufe 10 – erhöhter Fokus', () {
    test('verstärkte Verteidigung würfelt 2 Kampfkunstwürfel', () {
      final result = MonkFocusActions.use(
        monk(),
        fight(),
        action: MonkBonusAction.patientDefense,
        enhanced: true,
        dice: DiceEngine(random: MinimumRoll()),
      );
      expect(result.focusSpent, 1);
      expect(result.temporaryHitPointsRolled, 2);
      expect(result.hero.temporaryHitPoints, 2);
      expect(result.encounter.dodgeActive, isTrue);
      expect(ClassResourceRules.remaining(result.hero, 'focusPoints'), 9);
    });

    test(
      'Stufe 9 erhält keine temporären TP; normaler Rückzug bleibt kostenlos',
      () {
        final level9 = MonkFocusActions.use(
          monk(level: 9),
          fight(),
          action: MonkBonusAction.patientDefense,
          enhanced: true,
        );
        expect(level9.temporaryHitPointsRolled, 0);
        expect(level9.hero.temporaryHitPoints, 0);
        final basic10 = MonkFocusActions.use(
          monk(),
          fight(),
          action: MonkBonusAction.patientDefense,
        );
        expect(basic10.hero.temporaryHitPoints, 0);
        expect(basic10.focusSpent, 0);
      },
    );

    test('Mehrklassenstufe und vorhandene höhere temporäre TP', () {
      final multiclass = monk(
        level: 14,
        className: 'Kämpfer',
        secondary: 'Mönch',
        secondaryLevel: 10,
        temporary: 20,
      );
      final result = MonkFocusActions.use(
        multiclass,
        fight(),
        action: MonkBonusAction.patientDefense,
        enhanced: true,
        dice: DiceEngine(random: MinimumRoll()),
      );
      expect(result.temporaryHitPointsRolled, 2);
      expect(result.hero.temporaryHitPoints, 20);
      expect(ClassResourceRules.remaining(result.hero, 'focusPoints'), 9);
    });

    test('fehlender Würfeldienst belastet keine Ressourcen', () {
      final hero = monk();
      expect(
        () => MonkFocusActions.use(
          hero,
          fight(),
          action: MonkBonusAction.patientDefense,
          enhanced: true,
        ),
        throwsStateError,
      );
      expect(hero.spentClassResources, isEmpty);
      expect(
        () => MonkFocusActions.use(
          monk(focusSpent: 10),
          fight(),
          action: MonkBonusAction.patientDefense,
          enhanced: true,
          dice: DiceEngine(random: MinimumRoll()),
        ),
        throwsStateError,
      );
    });

    test('Spielleiteraktion protokolliert und speichert temporäre TP', () {
      final gm = GameEngine(
        dice: DiceEngine(random: MinimumRoll()),
        clock: () => DateTime.utc(2026, 10, 16),
      );
      final demo = gm.createDemo();
      final starting = demo.copyWith(hero: monk().copyWith(id: demo.hero.id));
      final campaign = gm.act(starting, 'Ich gehe zum Waldschrein.').campaign;
      final result = gm.act(campaign, 'Geduldige Verteidigung mit Fokuspunkt');
      expect(result.events.single.type, 'class.patientDefense');
      final payload = result.events.single.payload;
      expect(payload['temporaryHitPointsRolled'], 2);
      expect(payload['temporaryHitPoints'], 2);
      expect(
        Campaign.fromJson(result.campaign.toJson()).hero.temporaryHitPoints,
        2,
      );
    });
  });

  testWidgets('Charakterbogen zeigt temporäre TP getrennt von normalen TP', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: CharacterSheetPage(hero: monk(temporary: 7))),
    );
    expect(
      find.byKey(const ValueKey('sheet-temporary-hit-points')),
      findsOneWidget,
    );
    expect(find.text('+7 temporäre TP'), findsOneWidget);
  });
}
