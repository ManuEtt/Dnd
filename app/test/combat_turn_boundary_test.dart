import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/damage_rules.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:lebendiger_spielleiter/services/voice_controller.dart';
import 'package:lebendiger_spielleiter/ui/app.dart';

class _Random implements Random {
  _Random([this.faces = const []]);
  final List<int> faces;
  int calls = 0;

  @override
  int nextInt(int max) {
    final face = calls < faces.length ? faces[calls] : 1;
    calls++;
    return (face - 1) % max;
  }

  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

class _Voice extends VoiceController {
  @override
  Future<void> stopListening() async {}
  @override
  Future<void> stopSpeaking() async {}
  @override
  Future<void> speak(String text) async {}
}

const _fight = Encounter(
  id: 'turn-boundary',
  enemyName: 'Wache',
  enemyHitPoints: 40,
  enemyMaxHitPoints: 40,
  enemyAttackBonus: 0,
  enemyDamage: '1d4',
  enemyDamageType: 'slashing',
);

Campaign _campaign(
  GameEngine engine, {
  Encounter encounter = _fight,
  List<String> conditions = const [],
  String className = 'Kämpfer',
  int level = 1,
  int hp = 40,
  int speed = 9,
  String concentration = '',
}) {
  final demo = engine.createDemo();
  return demo.copyWith(
    encounter: encounter,
    hero: demo.hero.copyWith(
      className: className,
      level: level,
      hitPoints: hp,
      maxHitPoints: 40,
      armorClass: 15,
      speed: speed,
      conditions: conditions,
      concentratingOn: concentration,
      abilities: const {
        'strength': 14,
        'dexterity': 14,
        'constitution': 14,
        'intelligence': 14,
        'wisdom': 14,
        'charisma': 14,
      },
      weaponDamage: '1d6',
    ),
  );
}

void main() {
  setUpAll(sqfliteFfiInit);
  late _Random random;
  late GameEngine engine;
  setUp(() {
    random = _Random();
    engine = GameEngine(
      dice: DiceEngine(random: random),
      clock: () => DateTime.utc(2026, 10, 17),
    );
  });

  test('Externer KO beendet Kampfrausch dauerhaft vor einer Heilung', () {
    final before = _campaign(
      engine,
      className: 'Barbar',
      hp: 2,
      encounter: _fight.copyWith(
        rageStartedRound: 1,
        rageUntilRound: 10,
        dodgeActive: true,
      ),
    );
    final fallen = engine.applyDamage(
      before,
      source: 'Bestätigtes Feuer',
      components: [DamageComponent(DamageType.fire, 3)],
      defenses: DamageDefenses(),
    );
    expect(fallen.campaign.hero.hitPoints, 0);
    expect(fallen.campaign.encounter!.rageUntilRound, 0);
    expect(fallen.campaign.encounter!.rageStartedRound, 0);
    expect(fallen.campaign.encounter!.dodgeActive, isFalse);
    expect(fallen.campaign.encounter!.round, 1);
    expect(fallen.events.single.payload['rageEndedByIncapacitation'], isTrue);
    expect(before.encounter!.rageUntilRound, 10);
    final healed = engine.applyHealing(
      fallen.campaign,
      source: 'Bestätigte Hilfe',
      amount: 4,
    );
    final damaged = engine.applyDamage(
      healed.campaign,
      source: 'Bestätigter Hieb',
      components: [DamageComponent(DamageType.slashing, 3)],
      defenses: DamageDefenses(),
    );
    expect(damaged.campaign.hero.hitPoints, 1);
    expect(damaged.campaign.encounter!.rageUntilRound, 0);
    expect(random.calls, 0);
  });

  test(
    'Bestätigte Handlungsunfähigkeit beendet Kampfrausch beim Bearbeiten',
    () {
      final before = _campaign(
        engine,
        className: 'Barbar',
        encounter: _fight.copyWith(
          rageStartedRound: 1,
          rageUntilRound: 10,
          dodgeActive: true,
        ),
      );
      final stunned = engine.updateHero(
        before,
        before.hero.copyWith(conditions: ['betäubt']),
      );
      expect(stunned.campaign.encounter!.rageUntilRound, 0);
      expect(stunned.campaign.encounter!.dodgeActive, isFalse);
      expect(
        stunned.events.single.payload['rageEndedByIncapacitation'],
        isTrue,
      );
      final restored = engine.updateHero(
        stunned.campaign,
        stunned.campaign.hero.copyWith(conditions: []),
      );
      expect(restored.campaign.encounter!.rageUntilRound, 0);
      expect(random.calls, 0);
    },
  );

  test('Externer Schaden ohne KO lässt gültigen Kampfrausch aktiv', () {
    final before = _campaign(
      engine,
      className: 'Barbar',
      encounter: _fight.copyWith(
        rageStartedRound: 1,
        rageUntilRound: 10,
        dodgeActive: true,
      ),
    );
    final damaged = engine.applyDamage(
      before,
      source: 'Bestätigter Hieb',
      components: [DamageComponent(DamageType.slashing, 4)],
      defenses: DamageDefenses(),
    );
    expect(damaged.campaign.hero.hitPoints, 38);
    expect(damaged.campaign.encounter!.rageUntilRound, 10);
    expect(damaged.campaign.encounter!.dodgeActive, isTrue);
    expect(damaged.events.single.payload['rageEndedByIncapacitation'], isNull);
    expect(random.calls, 0);
  });

  test('Zug beenden beendet den Zug auch nach verbrauchter Aktion', () {
    final before = _campaign(
      engine,
      encounter: _fight.copyWith(
        actionUsed: true,
        bonusActionUsed: true,
        spellSlotExpendedThisTurn: true,
        movementRemaining: 0,
      ),
    );
    final result = engine.act(before, 'Zug beenden');
    expect(result.events.single.type, 'combat.turnCompleted');
    expect(result.campaign.encounter!.round, 2);
    expect(result.campaign.encounter!.actionUsed, isFalse);
    expect(result.campaign.encounter!.bonusActionUsed, isFalse);
    expect(result.campaign.encounter!.spellSlotExpendedThisTurn, isFalse);
    expect(result.campaign.encounter!.movementRemaining, 9);
    expect(result.campaign.hero.spentClassResources, isEmpty);
    expect(random.calls, 1);
  });

  test(
    'Handlungsunfähig verhindert Zugende nicht und erzeugt kein Ausweichen',
    () {
      final before = _campaign(engine, conditions: ['handlungsunfähig']);
      final result = engine.act(before, 'Ich beende meinen Zug.');
      expect(result.events.single.type, 'combat.turnCompleted');
      expect(result.campaign.encounter!.round, 2);
      expect(result.campaign.hero.conditions, ['handlungsunfähig']);
      expect(result.events.single.payload['attackRoll']['rolls'], [1]);
      expect(random.calls, 1);
    },
  );

  test(
    'Stabile bewusstlose Figur kann ihren Zug ohne Todesrettung beenden',
    () {
      final before = _campaign(
        engine,
        hp: 0,
        conditions: ['bewusstlos', 'stabil'],
      );
      final result = engine.act(before, 'Zug beenden');
      expect(result.events.single.type, 'combat.turnCompleted');
      expect(result.campaign.pendingRoll, isNull);
      expect(result.campaign.hero.hitPoints, 0);
      expect(result.campaign.hero.deathFailures, 0);
      expect(result.campaign.hero.conditions, contains('stabil'));
      expect(result.campaign.encounter!.round, 2);
      // Unconscious grants the attacker advantage; natural 1 still misses.
      expect(random.calls, 2);
    },
  );

  test(
    'Nichtstabile Figur mit 0 TP kann ihre Todesrettung nicht überspringen',
    () {
      final before = _campaign(engine, hp: 0, conditions: ['bewusstlos']);
      final result = engine.act(before, 'Zug beenden');
      expect(result.events.single.type, 'rules.blocked');
      expect(result.campaign.pendingRoll, isNull);
      expect(result.campaign.hero.toJson(), before.hero.toJson());
      expect(result.campaign.encounter!.toJson(), before.encounter!.toJson());
      expect(random.calls, 0);
    },
  );

  test(
    'Ausweichen mit angehängtem Zugende umgeht keine verbrauchte Aktion',
    () {
      final before = _campaign(
        engine,
        encounter: _fight.copyWith(actionUsed: true),
      );
      final result = engine.act(
        before,
        'Ich weiche aus und beende meinen Zug.',
      );
      expect(result.events.single.type, 'rules.blocked');
      expect(result.campaign.encounter!.round, 1);
      expect(result.campaign.encounter!.dodgeActive, isFalse);
      expect(result.campaign.hero.spentClassResources, isEmpty);
      expect(random.calls, 0);
      final end = engine.act(result.campaign, 'Zug beenden');
      expect(end.events.single.payload['attackRoll']['rolls'], [1]);
      expect(random.calls, 1);
    },
  );

  test(
    'Kein Zugende außerhalb Kampf, im fremden Zug, bei offener Probe oder Tod',
    () {
      final before = _campaign(engine);
      for (final invalid in [
        before.copyWith(encounter: null),
        before.copyWith(encounter: _fight.copyWith(enemyHitPoints: 0)),
        before.copyWith(encounter: _fight.copyWith(activeParticipant: 'enemy')),
        before.copyWith(
          pendingRoll: const PendingRoll(
            id: 'open',
            type: 'perception',
            modifier: 2,
            difficulty: 10,
          ),
        ),
        before.copyWith(hero: before.hero.copyWith(conditions: ['tot'])),
      ]) {
        expect(() => engine.endHeroTurn(invalid), throwsFormatException);
        expect(invalid.hero.spentClassResources, isEmpty);
      }
      expect(random.calls, 0);
    },
  );

  test('Mönch wählt Selbstwiederherstellung trotz Handlungsunfähigkeit', () {
    final before = _campaign(
      engine,
      className: 'Mönch',
      level: 10,
      conditions: ['handlungsunfähig', 'vergiftet', 'bezaubert'],
    );
    final selected = engine.act(before, 'Selbstwiederherstellung: vergiftet');
    expect(selected.events.single.type, 'class.selfRestorationSelected');
    expect(selected.campaign.hero.conditions, before.hero.conditions);
    expect(selected.campaign.encounter!.selfRestorationChoice, 'vergiftet');
    expect(selected.campaign.hero.spentClassResources, isEmpty);
    expect(random.calls, 0);
    final ended = engine.act(selected.campaign, 'Zug beenden');
    expect(ended.events.single.payload['selfRestorationRemoved'], 'vergiftet');
    expect(ended.campaign.hero.conditions, ['handlungsunfähig', 'bezaubert']);
    expect(ended.campaign.encounter!.selfRestorationChoice, isEmpty);
  });

  test('Gegner-Initiative ist noch kein eigenes Zugende für den Mönch', () {
    random = _Random([1, 1, 20, 1]);
    engine = GameEngine(dice: DiceEngine(random: random));
    final before = _campaign(
      engine,
      className: 'Mönch',
      level: 10,
      conditions: ['vergiftet'],
    ).copyWith(encounter: null);
    final result = engine.act(before, 'Ich gehe zum Waldschrein.');
    expect(result.events.single.payload['enemyTurn'], isNotNull);
    expect(result.campaign.encounter!.round, 1);
    expect(result.campaign.hero.conditions, ['vergiftet']);
    expect(
      result.events.single.payload['enemyTurn']['selfRestorationRemoved'],
      isNull,
    );
    expect(random.calls, 4);
  });

  test('Kampfrausch endet vor dem Schaden des folgenden Gegnerzugs', () {
    random = _Random([10, 4]);
    engine = GameEngine(dice: DiceEngine(random: random));
    final encounter = Encounter(
      id: 'expiring-rage',
      enemyName: 'Wache',
      enemyHitPoints: 40,
      enemyMaxHitPoints: 40,
      enemyAttackBonus: 20,
      enemyDamage: '1d4',
      enemyDamageType: 'slashing',
      rageStartedRound: 1,
      rageUntilRound: 1,
    );
    final before = _campaign(engine, className: 'Barbar', encounter: encounter);
    final result = engine.endHeroTurn(before);
    expect(result.events.single.payload['rageExpiredAtTurnEnd'], isTrue);
    expect(result.events.single.payload['damage'], 4);
    expect(result.events.single.payload['rageResistanceReduction'], isNull);
    expect(result.campaign.hero.hitPoints, 36);
    expect(result.campaign.encounter!.rageUntilRound, 0);
  });

  test(
    'Noch andauernder Kampfrausch halbiert bestätigten physischen Schaden',
    () {
      random = _Random([10, 4]);
      engine = GameEngine(dice: DiceEngine(random: random));
      final before = _campaign(
        engine,
        className: 'Barbar',
        encounter: const Encounter(
          id: 'active-rage',
          enemyName: 'Wache',
          enemyHitPoints: 40,
          enemyMaxHitPoints: 40,
          enemyAttackBonus: 20,
          enemyDamage: '1d4',
          enemyDamageType: 'slashing',
          rageStartedRound: 1,
          rageUntilRound: 2,
        ),
      );
      final result = engine.endHeroTurn(before);
      expect(result.events.single.payload['damage'], 2);
      expect(result.events.single.payload['rageResistanceReduction'], 2);
      expect(result.campaign.hero.hitPoints, 38);
      expect(result.campaign.encounter!.rageUntilRound, 2);
    },
  );

  test(
    'Handlungsunfähigkeit beendet Kampfrausch und Konzentration dauerhaft',
    () {
      final before = _campaign(
        engine,
        className: 'Barbar',
        conditions: ['handlungsunfähig'],
        concentration: 'Bestätigter Schutzzauber',
        encounter: _fight.copyWith(rageStartedRound: 1, rageUntilRound: 2),
      );
      final result = engine.endHeroTurn(before);
      expect(result.events.single.payload['rageEndedByIncapacitation'], isTrue);
      expect(result.campaign.hero.concentratingOn, isEmpty);
      expect(result.campaign.encounter!.rageUntilRound, 0);
      final recovered = result.campaign.copyWith(
        hero: result.campaign.hero.copyWith(conditions: []),
      );
      final again = engine.endHeroTurn(recovered);
      expect(again.campaign.encounter!.rageUntilRound, 0);
      expect(again.campaign.hero.concentratingOn, isEmpty);
      expect(again.campaign.hero.spentClassResources, isEmpty);
    },
  );

  test('Geduldige Verteidigung verliert Ausweichen bei Bewegungsrate 0', () {
    final result = engine.endHeroTurn(
      _campaign(
        engine,
        speed: 0,
        encounter: _fight.copyWith(dodgeActive: true),
      ),
    );
    expect(result.events.single.payload['attackRoll']['rolls'], [1]);
    expect(random.calls, 1);
    expect(result.campaign.encounter!.dodgeActive, isFalse);
  });

  test('Handlungsunfähigkeit hebt gespeicherten Ausweichvorteil auf', () {
    final result = engine.endHeroTurn(
      _campaign(
        engine,
        conditions: ['handlungsunfähig'],
        encounter: _fight.copyWith(dodgeActive: true),
      ),
    );
    expect(result.events.single.payload['attackRoll']['rolls'], [1]);
    expect(random.calls, 1);
  });

  test(
    'Blindheit lässt den Angreifervorteil durch Ausweichen nicht verschwinden',
    () {
      final result = engine.endHeroTurn(
        _campaign(
          engine,
          conditions: ['blind'],
          encounter: _fight.copyWith(dodgeActive: true),
        ),
      );
      expect(result.events.single.payload['attackRoll']['rolls'], [1, 1]);
      expect(random.calls, 2);
    },
  );

  test('Handlungsfähige bewegliche Figur behält ihren Ausweichvorteil', () {
    final result = engine.endHeroTurn(
      _campaign(engine, encounter: _fight.copyWith(dodgeActive: true)),
    );
    expect(result.events.single.payload['attackRoll']['rolls'], [1, 1]);
    expect(random.calls, 2);
  });

  test(
    'Positive Bewegungsrate unter einem Meter verliert Ausweichen nicht',
    () {
      final before = _campaign(
        engine,
        speed: 2,
        encounter: _fight.copyWith(dodgeActive: true),
      );
      final result = engine.endHeroTurn(
        before.copyWith(hero: before.hero.copyWith(exhaustionLevel: 1)),
      );
      // 2 m minus 1.5 m Exhaustion is still positive, even though this app's
      // whole-meter movement controls cannot spend the remaining half meter.
      expect(result.events.single.payload['attackRoll']['rolls'], [1, 1]);
      expect(random.calls, 2);
    },
  );

  testWidgets(
    'Echter Zugende-Button beendet handlungsunfähigen Zug und speichert SQLite',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = (await tester.runAsync(
        () => SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: inMemoryDatabasePath,
        ),
      ))!;
      final controller = GameController(repository: repository, engine: engine);
      final voice = _Voice();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
        voice.dispose();
        await tester.runAsync(repository.close);
      });
      final campaign = _campaign(engine, conditions: ['handlungsunfähig']);
      await tester.runAsync(() => repository.saveCampaign(campaign));
      await tester.runAsync(() => controller.openCampaign(campaign.id));
      await tester.pumpWidget(
        LivingGameApp(controller: controller, voice: voice),
      );
      await tester.tap(find.text('Abenteuer'));
      await tester.pumpAndSettle();
      final combatToggle = find.text('Kampf ansehen');
      await tester.ensureVisible(combatToggle);
      await tester.pumpAndSettle();
      expect(combatToggle.hitTestable(), findsOneWidget);
      await tester.tap(combatToggle);
      await tester.pumpAndSettle();
      final button = find.byKey(const ValueKey('combat-end-hero-turn'));
      await tester.scrollUntilVisible(
        button,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      expect(button.hitTestable(), findsOneWidget);
      await tester.tap(button);
      await tester.pump();
      await tester.runAsync(() async {
        for (var i = 0; i < 200 && controller.busy; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      });
      await tester.pumpAndSettle();
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.encounter!.round, 2);
      expect(
        controller.currentCampaign!.events.last.type,
        'combat.turnCompleted',
      );
      expect(controller.currentCampaign!.hero.conditions, ['handlungsunfähig']);
      final stored = await tester.runAsync(
        () => repository.getCampaign(campaign.id),
      );
      expect(stored!.toJson(), controller.currentCampaign!.toJson());
      expect(random.calls, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
