import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_opportunity_attack_rules.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:lebendiger_spielleiter/services/voice_controller.dart';
import 'package:lebendiger_spielleiter/ui/app.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';

class _Voice extends VoiceController {
  @override
  Future<void> stopListening() async {}
  @override
  Future<void> stopSpeaking() async {}
  @override
  Future<void> speak(String text) async {}
}

Campaign _campaign() {
  final demo = GameEngine().createDemo();
  return demo.copyWith(
    hero: demo.hero.copyWith(
      equippedWeaponId: 'dagger',
      inventory: const [
        InventoryItem(id: 'dagger', name: 'Dolch', catalogId: 'weapon-dagger'),
      ],
    ),
    encounter: const Encounter(
      id: 'confirmed-enemy',
      enemyName: 'Bestätigter Gegner',
      enemyHitPoints: 20,
      enemyMaxHitPoints: 20,
      activeParticipant: 'enemy',
      enemyAttacksPerTurn: 2,
      enemyAttacksRemaining: 1,
    ),
  );
}

Finder _key(String key) => find.byKey(ValueKey(key));
Finder _nav(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

void _view(WidgetTester tester) {
  tester.view.physicalSize = const Size(360, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _tap(
  WidgetTester tester,
  Finder finder, {
  bool settle = true,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 80,
    );
  }
  final target = tester.widget(finder) is CheckboxListTile
      ? find.descendant(of: finder, matching: find.byType(Checkbox))
      : finder;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

Future<void> _drain(WidgetTester tester, GameController controller) async {
  await tester.runAsync(() async {
    for (var i = 0; i < 200; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      if (!controller.busy) break;
    }
  });
  await tester.pumpAndSettle();
  expect(controller.busy, isFalse);
}

Future<void> _adventure(
  WidgetTester tester,
  GameController controller,
  _Voice voice,
) async {
  await tester.pumpWidget(LivingGameApp(controller: controller, voice: voice));
  await tester.pumpAndSettle();
  await _tap(tester, _nav('Abenteuer'));
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 20)),
  );
  await tester.pumpAndSettle();
}

Future<void> _fillMovement(WidgetTester tester) async {
  await _tap(tester, _key('opportunity-movement-kind'));
  await _tap(tester, find.text('Eigene gewöhnliche Bewegung').last);
  await _tap(tester, _key('opportunity-strike'));
  await _tap(tester, find.text('Dolch').last);
  for (final entry in {'before': '5', 'after': '10', 'reach': '5'}.entries) {
    final finder = _key('opportunity-${entry.key}');
    await tester.ensureVisible(finder);
    await tester.enterText(finder, entry.value);
    await tester.pumpAndSettle();
  }
  await _tap(tester, _key('opportunity-visible'));
  await _tap(tester, _key('opportunity-authorized'));
}

void main() {
  setUpAll(sqfliteFfiInit);
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets(
    'Abenteuer speichert Angebot, zeigt es nach Laden und verzichtet ausdrücklich',
    (tester) async {
      _view(tester);
      final repository = (await tester.runAsync(
        () => SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: inMemoryDatabasePath,
        ),
      ))!;
      var controller = GameController(repository: repository);
      final voice = _Voice();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
        voice.dispose();
        await tester.runAsync(repository.close);
      });
      final campaign = Campaign.fromJson(_campaign().toJson());
      await tester.runAsync(() => repository.saveCampaign(campaign));
      await tester.runAsync(() => controller.openCampaign(campaign.id));
      await tester.pumpWidget(
        LivingGameApp(controller: controller, voice: voice),
      );
      await tester.pumpAndSettle();
      expect(_key('adventure-confirm-opportunity-movement'), findsNothing);
      await _tap(tester, _nav('Helden'));
      expect(_key('adventure-confirm-opportunity-movement'), findsNothing);
      await _tap(tester, _nav('Abenteuer'));
      await _drain(tester, controller);
      await _tap(tester, _key('adventure-confirm-opportunity-movement'));
      await _fillMovement(tester);
      await _tap(tester, _key('opportunity-movement-confirm'), settle: false);
      await _drain(tester, controller);
      expect(controller.error, isNull);
      final offered = (await tester.runAsync(
        () => repository.getCampaign(campaign.id),
      ))!;
      expect(offered.pendingOpportunityAttack, isNotNull);
      expect(offered.hero.toJson(), campaign.hero.toJson());
      expect(offered.encounter!.toJson(), campaign.encounter!.toJson());
      expect(offered.events.last.type, 'combat.opportunityOffered');

      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      controller = GameController(repository: repository);
      await tester.runAsync(controller.initialize);
      await _adventure(tester, controller, voice);
      expect(_key('pending-opportunity-attack'), findsOneWidget);
      expect(
        find.textContaining('Ein Angriff wird hier noch nicht gewürfelt.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<FantasyTextButton>(
              _key('adventure-confirm-opportunity-movement'),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<FantasyTextButton>(
              _key('adventure-confirm-character-effect'),
            )
            .onPressed,
        isNull,
      );
      await _tap(tester, _key('adventure-combat-mode-toggle'));
      await tester.scrollUntilVisible(
        _key('enemy-attack-continue'),
        200,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 80,
      );
      expect(
        tester
            .widget<FantasyTextButton>(_key('enemy-attack-continue'))
            .onPressed,
        isNull,
      );
      expect(controller.currentCampaign!.toJson(), offered.toJson());
      await tester.scrollUntilVisible(
        _key('opportunity-attack-decline'),
        -200,
        scrollable: find.byType(Scrollable).first,
        maxScrolls: 80,
      );
      await _tap(tester, _key('opportunity-attack-decline'), settle: false);
      await _drain(tester, controller);
      expect(controller.error, isNull);
      final declined = (await tester.runAsync(
        () => repository.getCampaign(campaign.id),
      ))!;
      expect(declined.pendingOpportunityAttack, isNull);
      expect(declined.events.last.type, 'combat.opportunityDeclined');
      expect(declined.events.last.payload['playerConfirmed'], isTrue);
      expect(declined.hero.toJson(), campaign.hero.toJson());
      expect(declined.encounter!.toJson(), campaign.encounter!.toJson());
      expect(declined.revision, offered.revision + 1);
      expect(_key('pending-opportunity-attack'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Offener alter Bewegungsdialog kann geänderte Revision nicht bestätigen',
    (tester) async {
      _view(tester);
      final repository = (await tester.runAsync(
        () => SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: inMemoryDatabasePath,
        ),
      ))!;
      final controller = GameController(repository: repository);
      final voice = _Voice();
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
        voice.dispose();
        await tester.runAsync(repository.close);
      });
      final campaign = Campaign.fromJson(_campaign().toJson());
      await tester.runAsync(() => repository.saveCampaign(campaign));
      await tester.runAsync(() => controller.openCampaign(campaign.id));
      await _adventure(tester, controller, voice);
      await _tap(tester, _key('adventure-confirm-opportunity-movement'));
      await _fillMovement(tester);
      await tester.runAsync(
        () =>
            controller.saveHero(campaign.hero.copyWith(name: 'Neu bestätigt')),
      );
      final changed = controller.currentCampaign!.toJson();
      await _tap(tester, _key('opportunity-movement-confirm'), settle: false);
      await _drain(tester, controller);
      expect(controller.error, contains('geändert'));
      expect(controller.currentCampaign!.pendingOpportunityAttack, isNull);
      expect(controller.currentCampaign!.toJson(), changed);
      final stored = (await tester.runAsync(
        () => repository.getCampaign(campaign.id),
      ))!;
      expect(stored.toJson(), changed);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Alter Verzicht-Callback kann kein neueres Angebot ablehnen', (
    tester,
  ) async {
    _view(tester);
    final repository = (await tester.runAsync(
      () => SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      ),
    ))!;
    final controller = GameController(repository: repository);
    final voice = _Voice();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      voice.dispose();
      await tester.runAsync(repository.close);
    });
    final campaign = Campaign.fromJson(_campaign().toJson());
    const trigger = ConfirmedOpportunityTrigger(
      encounterId: 'confirmed-enemy',
      beforeDistanceFeet: 5,
      afterDistanceFeet: 10,
      reachFeet: 5,
      targetVisibleConfirmed: true,
      playerAuthorizedReaction: true,
      movement: OpportunityMovement.ordinary,
      strike: OpportunityStrike.equippedMeleeWeapon,
      weaponId: 'dagger',
    );
    await tester.runAsync(() => repository.saveCampaign(campaign));
    await tester.runAsync(() => controller.openCampaign(campaign.id));
    await tester.runAsync(
      () => controller.confirmOpportunityMovement(
        campaignId: campaign.id,
        expectedRevision: campaign.revision,
        trigger: trigger,
      ),
    );
    await _adventure(tester, controller, voice);
    final old = controller.currentCampaign!;
    final staleDecline = tester
        .widget<FantasyTextButton>(_key('opportunity-attack-decline'))
        .onPressed!;
    await tester.runAsync(
      () => controller.declineOpportunityAttack(
        campaignId: old.id,
        expectedRevision: old.revision,
        offerId: old.pendingOpportunityAttack!.id,
        playerConfirmed: true,
      ),
    );
    await tester.runAsync(
      () => controller.confirmOpportunityMovement(
        campaignId: campaign.id,
        expectedRevision: controller.currentCampaign!.revision,
        trigger: trigger,
      ),
    );
    final replacement = controller.currentCampaign!.toJson();
    expect(
      controller.currentCampaign!.pendingOpportunityAttack!.id,
      isNot(old.pendingOpportunityAttack!.id),
    );
    staleDecline();
    await _drain(tester, controller);
    expect(controller.error, contains('geändert'));
    expect(controller.currentCampaign!.toJson(), replacement);
    final stored = (await tester.runAsync(
      () => repository.getCampaign(campaign.id),
    ))!;
    expect(stored.toJson(), replacement);
    expect(tester.takeException(), isNull);
  });
}
