import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/class_resource_rules.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/monk_focus_actions.dart';

class LowRandom implements Random {
  @override int nextInt(int max) => 0;
  @override bool nextBool() => false;
  @override double nextDouble() => 0;
}

HeroCharacter monk({int level = 2, int? spent = 0,
    String primary = 'Mönch', String secondary = '', int secondaryLevel = 0}) =>
    HeroCharacter(
      id: 'monk', name: 'Liora', className: primary, level: level,
      secondaryClassName: secondary, secondaryClassLevel: secondaryLevel,
      hitPoints: 20, maxHitPoints: 20, armorClass: 16, speed: 9,
      abilities: const {
        'strength': 12, 'dexterity': 16, 'constitution': 12,
        'wisdom': 14, 'intelligence': 10, 'charisma': 10,
      },
      weaponDamage: '1d6', weaponProficient: true,
      spentClassResources: spent == null ? const {} : {'focusPoints': spent},
    );

Encounter encounter() => const Encounter(id: 'fight', enemyName: 'Wache',
    enemyHitPoints: 20, enemyMaxHitPoints: 20, movementRemaining: 12);

GameEngine gm() => GameEngine(
    dice: DiceEngine(random: LowRandom()),
    clock: () => DateTime.utc(2026, 10, 16));

Campaign fighting(GameEngine engine, HeroCharacter hero) {
  final original = engine.createDemo();
  return engine.act(original.copyWith(hero: hero.copyWith(id: original.hero.id)),
      'Ich gehe zum Waldschrein.').campaign;
}

void main() {
  test('Patient Defense basic uses bonus action without focus', () {
    final result = MonkFocusActions.use(monk(), encounter(),
        action: MonkBonusAction.patientDefense);
    expect(result.focusSpent, 0);
    expect(result.hero.spentClassResources, {'focusPoints': 0});
    expect(result.encounter.bonusActionUsed, isTrue);
    expect(result.encounter.disengagedThisTurn, isTrue);
    expect(result.encounter.dodgeActive, isFalse);
    expect(result.encounter.movementRemaining, 12);
  });

  test('Patient Defense enhanced spends 1 and applies Dodge and Disengage', () {
    final result = MonkFocusActions.use(monk(), encounter(),
      action: MonkBonusAction.patientDefense, enhanced: true);
    expect(result.focusSpent, 1);
    expect(ClassResourceRules.remaining(result.hero, 'focusPoints'), 1);
    expect(result.encounter.dodgeActive, isTrue);
    expect(result.encounter.disengagedThisTurn, isTrue);
    expect(() => MonkFocusActions.use(result.hero, result.encounter,
        action: MonkBonusAction.stepOfTheWind), throwsStateError);
    final saved = Encounter.fromJson(result.encounter.toJson());
    expect(saved.dodgeActive, isTrue);
    expect(saved.disengagedThisTurn, isTrue);
  });

  test('Step of the Wind basic Dash is free; enhanced adds Disengage and jump', () {
    final basic = MonkFocusActions.use(monk(), encounter(),
      action: MonkBonusAction.stepOfTheWind);
    expect(basic.focusSpent, 0);
    expect(basic.movementAdded, 12); // Level 2 unarmored Monk adds 3m to base 9m.
    expect(basic.encounter.movementRemaining, 24);
    expect(basic.encounter.jumpDoubledThisTurn, isFalse);
    expect(basic.encounter.disengagedThisTurn, isFalse);
    final enhanced = MonkFocusActions.use(monk(), encounter(),
      action: MonkBonusAction.stepOfTheWind, enhanced: true);
    expect(enhanced.focusSpent, 1);
    expect(enhanced.encounter.movementRemaining, 24);
    expect(enhanced.encounter.jumpDoubledThisTurn, isTrue);
    expect(enhanced.encounter.disengagedThisTurn, isTrue);
    expect(enhanced.encounter.dodgeActive, isFalse);
  });

  test('Class level, used pools and turn ownership fail closed', () {
    expect(() => MonkFocusActions.use(monk(level: 1), encounter(),
      action: MonkBonusAction.patientDefense), throwsStateError);
    expect(() => MonkFocusActions.use(monk(spent: 2), encounter(),
      action: MonkBonusAction.patientDefense, enhanced: true), throwsStateError);
    expect(() => MonkFocusActions.use(monk(),
      encounter().copyWith(activeParticipant: 'enemy'),
      action: MonkBonusAction.patientDefense), throwsStateError);
    expect(() => MonkFocusActions.use(
      monk().copyWith(conditions: ['handlungsunfähig']), encounter(),
      action: MonkBonusAction.patientDefense), throwsStateError);
    final multi = monk(level: 8, primary: 'Kämpfer',
      secondary: 'Mönch', secondaryLevel: 3);
    final use = MonkFocusActions.use(multi, encounter(),
      action: MonkBonusAction.patientDefense, enhanced: true);
    expect(ClassResourceRules.remaining(use.hero, 'focusPoints'), 2);
  });

  test('Game engine records enhanced Patient Defense; opponent rolls with disadvantage', () {
    final engine = gm();
    var campaign = fighting(engine, monk());
    final action = engine.act(campaign, 'Geduldige Verteidigung mit Fokuspunkt');
    expect(action.events.single.type, 'class.patientDefense');
    campaign = action.campaign;
    expect(campaign.encounter!.dodgeActive, isTrue);
    expect(campaign.hero.spentClassResources['focusPoints'], 1);
    expect(engine.act(campaign, 'Schritt des Windes').events.single.type,
      'rules.blocked');
    final end = engine.act(campaign, 'Ich beende meinen Zug.');
    expect(end.events.single.type, 'combat.turnCompleted');
    final rolled = end.events.single.payload['attackRoll'] as Map;
    expect((rolled['rolls'] as List).length, 2);
    expect(end.campaign.encounter!.dodgeActive, isFalse);
    expect(end.campaign.encounter!.disengagedThisTurn, isFalse);
    expect(end.campaign.encounter!.bonusActionUsed, isFalse);
  });

  test('Game engine records enhanced Step and saves flags until end of turn', () {
    final engine = gm();
    var campaign = fighting(engine, monk(level: 10));
    final baseSpeed = campaign.encounter!.movementRemaining;
    final action = engine.act(campaign, 'Schritt des Windes verstärkt');
    expect(action.events.single.type, 'class.stepOfTheWind');
    campaign = action.campaign;
    expect(campaign.encounter!.movementRemaining, greaterThan(baseSpeed));
    expect(campaign.encounter!.jumpDoubledThisTurn, true);
    expect(Campaign.fromJson(campaign.toJson())
        .encounter!.jumpDoubledThisTurn, true);
    expect(engine.act(campaign, 'Zweite Luft').events.single.type,
      'rules.blocked');
  });

  test('Rogue Cunning Action Disengage spends bonus without extra movement', () {
    final engine = gm();
    var campaign = fighting(engine, monk(level: 3).copyWith(
      className: 'Schurke', level: 3));
    final originalMovement = campaign.encounter!.movementRemaining;
    final action = engine.act(campaign, 'Flinke Aktion: Rückzug');
    expect(action.events.single.type, 'class.cunningDisengage');
    campaign = action.campaign;
    expect(campaign.encounter!.disengagedThisTurn, isTrue);
    expect(campaign.encounter!.movementRemaining, originalMovement);
    expect(engine.act(campaign, 'Flinke Aktion: Sprinten').events.single.type,
      'rules.blocked');
    expect(Campaign.fromJson(campaign.toJson())
        .encounter!.disengagedThisTurn, isTrue);
  });

  test('Legacy encounter JSON omitting new flags remains compatible', () {
    final json = encounter().toJson();
    expect(json.containsKey('dodgeActive'), isFalse);
    expect(json.containsKey('disengagedThisTurn'), isFalse);
    expect(json.containsKey('jumpDoubledThisTurn'), isFalse);
    final old = Encounter.fromJson(json);
    expect(old.dodgeActive, isFalse);
    expect(old.disengagedThisTurn, isFalse);
    expect(old.jumpDoubledThisTurn, isFalse);
  });
}
