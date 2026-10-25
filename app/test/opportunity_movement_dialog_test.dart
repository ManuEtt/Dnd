import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_opportunity_attack_rules.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';
import 'package:lebendiger_spielleiter/ui/opportunity_movement_dialog.dart';

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
Finder get _confirm => _key('opportunity-movement-confirm');

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

Future<void> _tap(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  tester.testTextInput.hide();
  await tester.pumpAndSettle();
  final target = tester.widget(finder) is CheckboxListTile
      ? find.descendant(of: finder, matching: find.byType(Checkbox))
      : finder;
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _select(WidgetTester tester, String key, String label) async {
  await _tap(tester, _key(key));
  await _tap(tester, find.text(label).last);
}

Future<void> _show(
  WidgetTester tester, {
  Campaign? campaign,
  required void Function(ConfirmedOpportunityTrigger?) onClosed,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFantasyTheme(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => onClosed(
              await showDialog<ConfirmedOpportunityTrigger>(
                context: context,
                builder: (_) => OpportunityMovementDialog(
                  campaign: campaign ?? _campaign(),
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

Future<void> _facts(
  WidgetTester tester, {
  String movement = 'Eigene gewöhnliche Bewegung',
  String strike = 'Dolch',
}) async {
  await _select(tester, 'opportunity-movement-kind', movement);
  await _select(tester, 'opportunity-strike', strike);
  for (final field in {'before': '5', 'after': '10', 'reach': '5'}.entries) {
    final finder = _key('opportunity-${field.key}');
    await tester.ensureVisible(finder);
    await tester.enterText(finder, field.value);
    await tester.pumpAndSettle();
  }
  await _tap(tester, _key('opportunity-visible'));
}

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets('Bewegung, Angriff, Werte und Zustimmung sind zunächst offen', (
    tester,
  ) async {
    _view(tester);
    await _show(tester, onClosed: (_) {});
    expect(tester.widget<FantasyTextButton>(_confirm).onPressed, isNull);
    for (final key in ['opportunity-visible', 'opportunity-authorized']) {
      expect(tester.widget<CheckboxListTile>(_key(key)).value, isFalse);
    }
    for (final name in ['before', 'after', 'reach']) {
      expect(
        tester.widget<TextField>(_key('opportunity-$name')).controller!.text,
        isEmpty,
      );
    }
    expect(
      tester
          .widget<DropdownButtonFormField<OpportunityMovement>>(
            _key('opportunity-movement-kind'),
          )
          .initialValue,
      isNull,
    );
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(_key('opportunity-strike'))
          .initialValue,
      isNull,
    );
  });

  testWidgets(
    'Nur ausdrückliche geprüfte Bewegung liefert Trigger ohne Mutation',
    (tester) async {
      _view(tester);
      final campaign = _campaign();
      final original = campaign.toJson();
      ConfirmedOpportunityTrigger? result;
      await _show(
        tester,
        campaign: campaign,
        onClosed: (value) => result = value,
      );
      await _facts(tester);
      expect(tester.widget<FantasyTextButton>(_confirm).onPressed, isNull);
      await _tap(tester, _key('opportunity-authorized'));
      expect(_key('opportunity-movement-preview'), findsOneWidget);
      expect(result, isNull);
      await _tap(tester, _confirm);
      expect(result?.encounterId, 'confirmed-enemy');
      expect(result?.weaponId, 'dagger');
      expect(result?.beforeDistanceFeet, 5);
      expect(result?.afterDistanceFeet, 10);
      expect(result?.reachFeet, 5);
      expect(result?.targetVisibleConfirmed, isTrue);
      expect(result?.playerAuthorizedReaction, isTrue);
      expect(result?.movement, OpportunityMovement.ordinary);
      expect(campaign.toJson(), original);
    },
  );

  for (final movement in [
    'Rückzug (Disengage)',
    'Teleportation',
    'Erzwungene Fremdbewegung',
  ]) {
    testWidgets('$movement kann kein Angebot bestätigen', (tester) async {
      _view(tester);
      await _show(tester, onClosed: (_) {});
      await _facts(tester, movement: movement);
      await _tap(tester, _key('opportunity-authorized'));
      expect(tester.widget<FantasyTextButton>(_confirm).onPressed, isNull);
      expect(
        find.textContaining('lösen keinen Gelegenheitsangriff aus'),
        findsOneWidget,
      );
    });
  }

  testWidgets(
    'Geänderte Entfernung widerruft Zustimmung und wird erneut geprüft',
    (tester) async {
      _view(tester);
      await _show(tester, onClosed: (_) {});
      await _facts(tester);
      await _tap(tester, _key('opportunity-authorized'));
      final after = _key('opportunity-after');
      await tester.ensureVisible(after);
      await tester.enterText(after, '5');
      await tester.pumpAndSettle();
      expect(
        tester.widget<CheckboxListTile>(_key('opportunity-authorized')).value,
        isFalse,
      );
      await _tap(tester, _key('opportunity-authorized'));
      expect(tester.widget<FantasyTextButton>(_confirm).onPressed, isNull);
      await tester.ensureVisible(after);
      await tester.enterText(after, '-1');
      await tester.pumpAndSettle();
      await _tap(tester, _key('opportunity-authorized'));
      expect(tester.widget<FantasyTextButton>(_confirm).onPressed, isNull);
    },
  );

  testWidgets(
    'Doppelte Waffenreferenzen bleiben gesperrt; waffenlos ist explizit',
    (tester) async {
      _view(tester);
      final base = _campaign();
      final campaign = base.copyWith(
        hero: base.hero.copyWith(
          inventory: [...base.hero.inventory, ...base.hero.inventory],
        ),
      );
      ConfirmedOpportunityTrigger? result;
      await _show(
        tester,
        campaign: campaign,
        onClosed: (value) => result = value,
      );
      await _tap(tester, _key('opportunity-strike'));
      expect(find.text('Dolch'), findsNothing);
      await _tap(tester, find.text('Waffenloser Schlag').last);
      await _facts(tester, strike: 'Waffenloser Schlag');
      await _tap(tester, _key('opportunity-authorized'));
      await _tap(tester, _confirm);
      expect(result?.strike, OpportunityStrike.unarmedStrike);
      expect(result?.weaponId, isEmpty);
    },
  );

  testWidgets('Abbrechen bewahrt selbst vollständig eingegebene Bewegung', (
    tester,
  ) async {
    _view(tester);
    final campaign = _campaign();
    final original = campaign.toJson();
    var closed = false;
    ConfirmedOpportunityTrigger? result;
    await _show(
      tester,
      campaign: campaign,
      onClosed: (value) {
        closed = true;
        result = value;
      },
    );
    await _facts(tester);
    await _tap(tester, _key('opportunity-authorized'));
    await _tap(tester, _key('opportunity-movement-cancel'));
    expect(closed, isTrue);
    expect(result, isNull);
    expect(campaign.toJson(), original);
  });

  testWidgets(
    '360 dp, große Schrift und Tastatur behalten die Bestätigung erreichbar',
    (tester) async {
      _view(tester, scale: 1.8, keyboard: 220);
      ConfirmedOpportunityTrigger? result;
      await _show(tester, onClosed: (value) => result = value);
      await _facts(tester);
      await _tap(tester, _key('opportunity-authorized'));
      await _tap(tester, _confirm);
      expect(result, isNotNull);
      expect(tester.takeException(), isNull);
    },
  );
}
