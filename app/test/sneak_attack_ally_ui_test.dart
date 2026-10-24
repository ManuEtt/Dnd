import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:lebendiger_spielleiter/services/voice_controller.dart';
import 'package:lebendiger_spielleiter/ui/app.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';
import 'package:lebendiger_spielleiter/ui/sneak_attack_ally_dialog.dart';

class _Voice extends VoiceController {
  @override
  Future<void> stopListening() async {}
  @override
  Future<void> stopSpeaking() async {}
  @override
  Future<void> speak(String text) async {}
}

void _view(WidgetTester tester, {double scale = 1, double keyboard = 0}) {
  tester.view.physicalSize = const Size(360, 900);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

Finder _key(String key) => find.byKey(ValueKey(key));
Finder get _confirm => _key('sneak-attack-ally-confirm');
Finder get _openConfirmation => _key('adventure-confirm-sneak-attack-ally');
Finder get _input => find.byWidgetPredicate(
  (widget) =>
      widget is TextField &&
      widget.decoration?.labelText == 'Was möchtest du tun?',
);

Future<void> _tap(
  WidgetTester tester,
  Finder finder, {
  bool settle = true,
}) async {
  await tester.pumpAndSettle();
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

Future<void> _wait(WidgetTester tester, GameController controller) async {
  await tester.runAsync(() async {
    for (var attempt = 0; attempt < 200 && controller.busy; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
  await tester.pumpAndSettle();
  expect(controller.busy, false);
  expect(controller.error, isNull);
}

Future<void> _showPending(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    240,
    scrollable: find
        .descendant(
          of: find.byType(ListView).first,
          matching: find.byType(Scrollable),
        )
        .first,
    maxScrolls: 80,
  );
  await tester.pumpAndSettle();
}

Future<GameController> _start(
  WidgetTester tester, {
  String className = 'Schurke',
  String weapon = 'weapon-dagger',
}) async {
  final repository = (await tester.runAsync(
    () => SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    ),
  ))!;
  final controller = GameController(repository: repository);
  final voice = _Voice();
  final engine = GameEngine();
  final demo = engine.createDemo();
  final armed = demo.copyWith(
    hero: demo.hero.copyWith(
      className: className,
      level: 3,
      equippedWeaponId: 'main',
      weaponDamage: '1d4',
      weaponAbility: 'dexterity',
      weaponProficient: true,
      inventory: [
        InventoryItem(id: 'main', name: 'Bestätigte Waffe', catalogId: weapon),
      ],
    ),
  );
  final combat = engine.act(armed, 'Ich gehe zum Waldschrein.');
  final requested = engine.act(combat.campaign, 'Ich greife den Wächter an.');
  final pending = requested.campaign;
  expect(pending.pendingRoll?.type, 'attack');
  await tester.runAsync(() => repository.saveCampaign(armed));
  await tester.runAsync(
    () => repository.saveCampaign(
      combat.campaign,
      events: combat.events,
      expectedRevision: armed.revision,
    ),
  );
  await tester.runAsync(
    () => repository.saveCampaign(
      pending,
      events: requested.events,
      expectedRevision: combat.campaign.revision,
    ),
  );
  await tester.runAsync(() => controller.openCampaign(pending.id));
  expect(controller.error, isNull);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    voice.dispose();
    await tester.runAsync(repository.close);
  });
  await tester.pumpWidget(LivingGameApp(controller: controller, voice: voice));
  await tester.pumpAndSettle();
  await _tap(
    tester,
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Abenteuer'),
    ),
  );
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 10)),
  );
  await tester.pumpAndSettle();
  return controller;
}

void main() {
  setUpAll(sqfliteFfiInit);
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets(
    'Dialog verlangt Name und zwei unabhängige unvorbelegte Tatsachen',
    (tester) async {
      _view(tester);
      SneakAttackAllyChoice? choice;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFantasyTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  choice = await showDialog<SneakAttackAllyChoice>(
                    context: context,
                    builder: (_) =>
                        const SneakAttackAllyDialog(targetName: 'Wächter'),
                  );
                },
                child: const Text('Öffnen'),
              ),
            ),
          ),
        ),
      );
      await _tap(tester, find.text('Öffnen'));
      expect(
        tester
            .widget<CheckboxListTile>(_key('sneak-attack-ally-near-target'))
            .value,
        false,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              _key('sneak-attack-ally-not-incapacitated'),
            )
            .value,
        false,
      );
      expect(tester.widget<FantasyTextButton>(_confirm).onPressed, isNull);
      await tester.enterText(_key('sneak-attack-ally-name'), '  Mira  ');
      await _tap(tester, _key('sneak-attack-ally-near-target'));
      expect(tester.widget<FantasyTextButton>(_confirm).onPressed, isNull);
      await _tap(tester, _key('sneak-attack-ally-not-incapacitated'));
      expect(tester.widget<FantasyTextButton>(_confirm).onPressed, isNotNull);
      expect(choice, isNull);
      await _tap(tester, _confirm);
      expect(choice?.allyName, 'Mira');
      expect(choice?.withinFiveFeetOfTargetConfirmed, true);
      expect(choice?.notIncapacitatedConfirmed, true);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Dialog bleibt bei großer Schrift und Tastatur bedienbar', (
    tester,
  ) async {
    _view(tester, scale: 1.8, keyboard: 260);
    SneakAttackAllyChoice? choice;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFantasyTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                choice = await showDialog<SneakAttackAllyChoice>(
                  context: context,
                  builder: (_) => const SneakAttackAllyDialog(
                    targetName: 'Wächter am Brunnen',
                  ),
                );
              },
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    );
    await _tap(tester, find.text('Öffnen'));
    final name = _key('sneak-attack-ally-name');
    await tester.ensureVisible(name);
    await tester.enterText(name, 'Mira');
    await _tap(tester, _key('sneak-attack-ally-near-target'));
    await _tap(tester, _key('sneak-attack-ally-not-incapacitated'));
    await _tap(tester, _confirm);
    expect(choice?.allyName, 'Mira');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Abbruch im Abenteuer bewahrt Spielstand und freien Eingabeentwurf',
    (tester) async {
      _view(tester);
      final controller = await _start(tester);
      const draft = 'Nach dem Angriff prüfe ich die Tür.';
      await tester.enterText(_input, draft);
      final before = controller.currentCampaign!;
      await _showPending(tester, _openConfirmation);
      await _tap(tester, _openConfirmation);
      await tester.enterText(_key('sneak-attack-ally-name'), 'Mira');
      await _tap(tester, _key('sneak-attack-ally-near-target'));
      await _tap(tester, _key('sneak-attack-ally-not-incapacitated'));
      expect(controller.currentCampaign!.revision, before.revision);
      await _tap(tester, _key('sneak-attack-ally-cancel'));
      expect(controller.currentCampaign!.toJson(), before.toJson());
      expect(tester.widget<TextField>(_input).controller!.text, draft);
      final saved = await tester.runAsync(
        () => controller.repository.getCampaign(before.id),
      );
      expect(saved!.pendingRoll!.sneakAttackAlly, isNull);
      expect(saved.revision, before.revision);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Bestätigter Verbündeter wird für dieselbe Probe gespeichert und kann entfernt werden',
    (tester) async {
      _view(tester);
      final controller = await _start(tester);
      const draft = 'Mein nächster geplanter Schritt.';
      await tester.enterText(_input, draft);
      final before = controller.currentCampaign!;
      await _showPending(tester, _openConfirmation);
      await _tap(tester, _openConfirmation);
      await tester.enterText(_key('sneak-attack-ally-name'), 'Mira');
      await _tap(tester, _key('sneak-attack-ally-near-target'));
      await _tap(tester, _key('sneak-attack-ally-not-incapacitated'));
      await _tap(tester, _confirm, settle: false);
      await _wait(tester, controller);
      final confirmed = controller.currentCampaign!;
      expect(confirmed.revision, before.revision + 1);
      expect(confirmed.pendingRoll!.id, before.pendingRoll!.id);
      expect(confirmed.pendingRoll!.sneakAttackAlly?.allyName, 'Mira');
      expect(confirmed.hero.toJson(), before.hero.toJson());
      expect(confirmed.encounter!.toJson(), before.encounter!.toJson());
      expect(tester.widget<TextField>(_input).controller!.text, draft);
      expect(_key('adventure-sneak-attack-ally-source'), findsOneWidget);
      expect(find.text('Bestätigter Verbündeter: Mira'), findsOneWidget);
      final saved = await tester.runAsync(
        () => controller.repository.getCampaign(confirmed.id),
      );
      expect(saved!.pendingRoll!.sneakAttackAlly?.allyName, 'Mira');
      await _tap(
        tester,
        _key('adventure-clear-sneak-attack-ally'),
        settle: false,
      );
      await _wait(tester, controller);
      expect(controller.currentCampaign!.pendingRoll!.sneakAttackAlly, isNull);
      expect(
        controller.currentCampaign!.pendingRoll!.id,
        before.pendingRoll!.id,
      );
      expect(controller.currentCampaign!.revision, before.revision + 2);
      expect(tester.widget<TextField>(_input).controller!.text, draft);
      expect(_key('adventure-sneak-attack-ally-source'), findsNothing);
      expect(_openConfirmation, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final entry in [
    (className: 'Kämpfer', weapon: 'weapon-dagger'),
    (className: 'Schurke', weapon: 'weapon-longsword'),
  ]) {
    testWidgets(
      'Keine Verbündetenbestätigung für ${entry.className} mit ${entry.weapon}',
      (tester) async {
        _view(tester);
        final controller = await _start(
          tester,
          className: entry.className,
          weapon: entry.weapon,
        );
        await _showPending(
          tester,
          find.widgetWithText(FantasyTextButton, 'Wurf durchführen'),
        );
        expect(_openConfirmation, findsNothing);
        expect(_key('adventure-sneak-attack-ally-source'), findsNothing);
        expect(
          controller.currentCampaign!.pendingRoll!.sneakAttackAlly,
          isNull,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
