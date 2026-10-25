import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/two_weapon_fighting_rules.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:lebendiger_spielleiter/services/voice_controller.dart';
import 'package:lebendiger_spielleiter/ui/app.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';
import 'package:lebendiger_spielleiter/ui/offhand_attack_dialog.dart';

HeroCharacter _hero() => HeroCharacter(
  id: 'light-rogue',
  name: 'Nara',
  className: 'Schurke',
  level: 3,
  abilities: const {
    'strength': 12,
    'dexterity': 16,
    'constitution': 14,
    'intelligence': 10,
    'wisdom': 10,
    'charisma': 10,
  },
  hitPoints: 24,
  maxHitPoints: 24,
  armorClass: 14,
  speed: 9,
  weaponDamage: '1d6',
  weaponAbility: 'dexterity',
  weaponProficient: true,
  equippedWeaponId: 'main',
  inventory: const [
    InventoryItem(
      id: 'main',
      name: 'Hauptkurzschwert',
      catalogId: 'weapon-shortsword',
    ),
    InventoryItem(id: 'dagger', name: 'Nebendolch', catalogId: 'weapon-dagger'),
    InventoryItem(id: 'axe', name: 'Nebenhandaxt', catalogId: 'weapon-handaxe'),
  ],
);

class _Voice extends VoiceController {
  @override
  Future<void> stopListening() async {}
  @override
  Future<void> stopSpeaking() async {}
  @override
  Future<void> speak(String text) async {}
}

Finder _key(String key) => find.byKey(ValueKey(key));
Finder get _confirm => _key('offhand-attack-confirm');
Finder get _input => find.byWidgetPredicate(
  (widget) =>
      widget is TextField &&
      widget.decoration?.labelText == 'Was möchtest du tun?',
);

void _view(
  WidgetTester tester, {
  double width = 360,
  double scale = 1,
  double keyboard = 0,
}) {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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
      220,
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

Future<void> _select(WidgetTester tester, String key, String text) async {
  await _tap(tester, _key(key));
  await _tap(tester, find.text(text).last);
}

Future<void> _chooseDagger(WidgetTester tester, {bool trained = true}) async {
  await _select(tester, 'offhand-weapon', 'Nebendolch');
  await _select(tester, 'offhand-ability-dagger', 'Geschicklichkeit (Finesse)');
  await _select(
    tester,
    'offhand-proficiency-dagger',
    trained ? 'Mit dieser Waffe geübt' : 'Mit dieser Waffe nicht geübt',
  );
  await _tap(tester, _key('offhand-weapons-held'));
}

Future<void> _show(
  WidgetTester tester, {
  HeroCharacter? hero,
  required void Function(OffhandAttackChoice?) onClosed,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFantasyTheme(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => onClosed(
              await showDialog<OffhandAttackChoice>(
                context: context,
                builder: (_) => OffhandAttackDialog(
                  hero: hero ?? _hero(),
                  targetName: 'Bestätigter Gegner',
                ),
              ),
            ),
            child: const Text('Öffnen'),
          ),
        ),
      ),
    ),
  );
  await _tap(tester, find.text('Öffnen'));
}

void main() {
  setUpAll(sqfliteFfiInit);
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets('No weapon or proficiency is silently confirmed', (tester) async {
    _view(tester);
    OffhandAttackChoice? result;
    await _show(tester, onClosed: (value) => result = value);
    expect(tester.widget<FantasyTextButton>(_confirm).onPressed, isNull);
    expect(_key('offhand-attack-preview'), findsNothing);
    await _select(tester, 'offhand-weapon', 'Nebendolch');
    await _select(
      tester,
      'offhand-ability-dagger',
      'Geschicklichkeit (Finesse)',
    );
    await _tap(tester, _key('offhand-weapons-held'));
    expect(_key('offhand-attack-preview'), findsNothing);
    expect(
      tester
          .widget<CheckboxListTile>(_key('offhand-attack-approved'))
          .onChanged,
      isNull,
    );
    await _select(
      tester,
      'offhand-proficiency-dagger',
      'Mit dieser Waffe nicht geübt',
    );
    expect(find.textContaining('Angriff: W20 +3'), findsOneWidget);
    expect(tester.widget<FantasyTextButton>(_confirm).onPressed, isNull);
    await _tap(tester, _key('offhand-attack-approved'));
    await _tap(tester, _confirm);
    expect(result?.weaponId, 'dagger');
    expect(result?.attackAbility, 'dexterity');
    expect(result?.weaponProficient, isFalse);
    expect(result?.weaponsHeldConfirmed, isTrue);
    expect(result?.playerConfirmed, isTrue);
  });

  testWidgets('Preview uses confirmed attack bonus and omits positive damage', (
    tester,
  ) async {
    _view(tester);
    final hero = _hero();
    final before = hero.toJson();
    OffhandAttackChoice? result;
    await _show(tester, hero: hero, onClosed: (value) => result = value);
    await _chooseDagger(tester);
    expect(find.textContaining('Angriff: W20 +5'), findsOneWidget);
    expect(find.textContaining('Waffenschaden: 1d4 +0'), findsOneWidget);
    expect(hero.toJson(), before);
    expect(result, isNull);
    await _tap(tester, _key('offhand-attack-approved'));
    await _tap(tester, _confirm);
    expect(result?.weaponProficient, isTrue);
    expect(hero.toJson(), before);
  });

  testWidgets('Changing attribute or weapon revokes previous consent', (
    tester,
  ) async {
    _view(tester);
    await _show(tester, onClosed: (_) {});
    await _chooseDagger(tester);
    await _tap(tester, _key('offhand-attack-approved'));
    expect(tester.widget<FantasyTextButton>(_confirm).onPressed, isNotNull);
    await _select(tester, 'offhand-ability-dagger', 'Stärke');
    expect(tester.widget<FantasyTextButton>(_confirm).onPressed, isNull);
    expect(
      tester.widget<CheckboxListTile>(_key('offhand-attack-approved')).value,
      isFalse,
    );
    expect(find.textContaining('Angriff: W20 +3'), findsOneWidget);
    await _tap(tester, _key('offhand-attack-approved'));
    await _select(tester, 'offhand-weapon', 'Nebenhandaxt');
    expect(_key('offhand-attack-preview'), findsNothing);
    expect(
      tester.widget<CheckboxListTile>(_key('offhand-weapons-held')).value,
      isFalse,
    );
    expect(tester.widget<FantasyTextButton>(_confirm).onPressed, isNull);
  });

  testWidgets('Cancel never produces an attack request', (tester) async {
    _view(tester);
    var closed = false;
    OffhandAttackChoice? result;
    await _show(
      tester,
      onClosed: (value) {
        closed = true;
        result = value;
      },
    );
    await _chooseDagger(tester);
    await _tap(tester, _key('offhand-attack-cancel'));
    expect(closed, isTrue);
    expect(result, isNull);
    expect(find.byType(OffhandAttackDialog), findsNothing);
  });

  for (final width in [320.0, 360.0]) {
    testWidgets('Dialog remains usable at $width dp, large text and keyboard', (
      tester,
    ) async {
      _view(tester, width: width, scale: 1.8, keyboard: 260);
      OffhandAttackChoice? result;
      await _show(tester, onClosed: (value) => result = value);
      await _chooseDagger(tester);
      await _tap(tester, _key('offhand-attack-approved'));
      await _tap(tester, _confirm);
      expect(result?.attackAbility, 'dexterity');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Adventure preparation stores facts once and keeps free draft', (
    tester,
  ) async {
    _view(tester);
    final repository = (await tester.runAsync(
      () => SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      ),
    ))!;
    final engine = GameEngine();
    final controller = GameController(repository: repository, engine: engine);
    final voice = _Voice();
    final base = engine.createDemo(hero: _hero());
    final fight = engine.act(base, 'Ich gehe zum Waldschrein.').campaign;
    final primary = engine.act(fight, 'Ich greife an.').campaign;
    final waiting = engine
        .resolveRoll(primary, natural: 1)
        .campaign
        .copyWith(revision: 0, events: const []);
    await tester.runAsync(
      () => repository.importCampaign(jsonEncode(waiting.toJson())),
    );
    await tester.runAsync(() => controller.openCampaign(waiting.id));
    expect(controller.error, isNull);
    expect(
      TwoWeaponFightingRules.canPrepare(controller.currentCampaign!),
      isTrue,
      reason: jsonEncode(controller.currentCampaign!.toJson()),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      voice.dispose();
      await tester.runAsync(repository.close);
    });
    await tester.pumpWidget(
      LivingGameApp(controller: controller, voice: voice),
    );
    await tester.pumpAndSettle();
    await _tap(
      tester,
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Abenteuer'),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(_input, 'Mein freier Eingabeentwurf');
    await _tap(tester, _key('adventure-combat-mode-toggle'));
    final before = controller.currentCampaign!.toJson();
    await _tap(tester, _key('combat-prepare-offhand-attack'));
    await _chooseDagger(tester);
    await _tap(tester, _key('offhand-attack-cancel'));
    expect(controller.currentCampaign!.toJson(), before);
    expect(
      tester.widget<TextField>(_input).controller!.text,
      'Mein freier Eingabeentwurf',
    );
    await _tap(tester, _key('combat-prepare-offhand-attack'));
    await _chooseDagger(tester);
    await _tap(tester, _key('offhand-attack-approved'));
    await _tap(tester, _confirm, settle: false);
    await tester.runAsync(() async {
      for (var attempt = 0; attempt < 200 && controller.busy; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();
    expect(controller.busy, isFalse);
    expect(controller.error, isNull);
    final saved = (await tester.runAsync(
      () => repository.getCampaign(waiting.id),
    ))!;
    expect(saved.revision, 1);
    expect(saved.pendingRoll!.type, 'offhandAttack');
    expect(saved.pendingRoll!.weaponId, 'dagger');
    expect(saved.pendingRoll!.modifier, 5);
    expect(saved.pendingRoll!.offhandAttackAbility, 'dexterity');
    expect(saved.pendingRoll!.offhandWeaponProficient, isTrue);
    expect(saved.pendingRoll!.offhandWeaponsHeldConfirmed, isTrue);
    expect(saved.encounter!.bonusActionUsed, isTrue);
    expect(saved.events, hasLength(1));
    expect(saved.hero.hitPoints, waiting.hero.hitPoints);
    expect(
      tester.widget<TextField>(_input).controller!.text,
      'Mein freier Eingabeentwurf',
    );
    expect(_key('combat-prepare-offhand-attack'), findsNothing);
  });
}
