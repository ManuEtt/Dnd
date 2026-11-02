import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/tracked_creature_initiative_dialog.dart';

Campaign _campaign() => GameEngine().createDemo().copyWith(
  hero: HeroCharacter(
    id: 'aria',
    name: 'Aria',
    className: 'Magier',
    level: 5,
    hitPoints: 20,
    maxHitPoints: 20,
  ),
  encounter: const Encounter(
    id: 'foe',
    enemyName: 'Wächter',
    enemyHitPoints: 30,
    enemyMaxHitPoints: 30,
    heroInitiative: 15,
    enemyInitiative: 15,
  ),
  trackedAreaCreatures: const [
    TrackedAreaCreature(
      id: 'goblin',
      name: 'Goblin',
      hitPoints: 5,
      maxHitPoints: 5,
    ),
  ],
);

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _open(
  WidgetTester tester,
  Campaign campaign,
  ValueChanged<ConfirmedInitiativeChoice?> receive, {
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 680);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = const FakeViewPadding(bottom: 220);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              receive(
                await showDialog<ConfirmedInitiativeChoice>(
                  context: context,
                  builder: (_) =>
                      TrackedCreatureInitiativeDialog(campaign: campaign),
                ),
              );
            },
            child: const Text('Öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Öffnen'));
  await tester.pumpAndSettle();
  expect(find.byType(TrackedCreatureInitiativeDialog), findsOneWidget);
  expect(tester.takeException(), isNull);
}

Future<void> _selectCreatureAndController(WidgetTester tester) async {
  await _tapVisible(tester, find.byKey(const ValueKey('initiative-target')));
  await tester.tap(find.text('Goblin').last);
  await tester.pumpAndSettle();
  await _tapVisible(
    tester,
    find.byKey(const ValueKey('initiative-controller')),
  );
  await tester.tap(find.text('Spielleitung (Monster/NSC)').last);
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets(
      'Initiative at $width dp, 200 % and IME: cancel remains reachable',
      (tester) async {
        final result = <ConfirmedInitiativeChoice?>[];
        final campaign = _campaign();
        final before = campaign.toJson();
        await _open(tester, campaign, result.add, width: width);
        await tester.ensureVisible(
          find.byKey(const ValueKey('initiative-total')),
        );
        expect(
          find.byKey(const ValueKey('initiative-total')).hitTestable(),
          findsOneWidget,
        );
        await tester.enterText(
          find.byKey(const ValueKey('initiative-total')),
          '19',
        );
        await _tapVisible(
          tester,
          find.byKey(const ValueKey('initiative-close')),
        );
        expect(result, [null]);
        expect(campaign.toJson(), before);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Unconfirmed initiative is rejected and announced with IME', (
    tester,
  ) async {
    final result = <ConfirmedInitiativeChoice?>[];
    final campaign = _campaign();
    final before = campaign.toJson();
    await _open(tester, campaign, result.add, width: 320);
    await _tapVisible(tester, find.byKey(const ValueKey('initiative-save')));
    expect(
      find.byKey(const ValueKey('initiative-validation-error')),
      findsOneWidget,
    );
    expect(result, isEmpty);
    expect(campaign.toJson(), before);
    await _tapVisible(tester, find.byKey(const ValueKey('initiative-close')));
    expect(result, [null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Confirmed choice stays a preview on a narrow IME screen', (
    tester,
  ) async {
    final result = <ConfirmedInitiativeChoice?>[];
    final campaign = _campaign();
    final before = campaign.toJson();
    await _open(tester, campaign, result.add, width: 320);
    await _selectCreatureAndController(tester);
    await tester.enterText(
      find.byKey(const ValueKey('initiative-total')),
      '14',
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('initiative-entry-confirmed')),
    );
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('initiative-base-confirmed')),
          )
          .value,
      isFalse,
    );
    await _tapVisible(tester, find.byKey(const ValueKey('initiative-save')));
    expect(result, hasLength(1));
    expect(result.single?.creatureId, 'goblin');
    expect(result.single?.total, 14);
    expect(result.single?.controller, 'gm');
    expect(campaign.toJson(), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Out-of-range initiative cannot be saved at 360 dp with IME', (
    tester,
  ) async {
    final result = <ConfirmedInitiativeChoice?>[];
    final campaign = _campaign();
    final before = campaign.toJson();
    await _open(tester, campaign, result.add, width: 360);
    await _selectCreatureAndController(tester);
    await tester.enterText(
      find.byKey(const ValueKey('initiative-total')),
      '101',
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('initiative-entry-confirmed')),
    );
    await _tapVisible(tester, find.byKey(const ValueKey('initiative-save')));
    expect(
      find.byKey(const ValueKey('initiative-validation-error')),
      findsOneWidget,
    );
    expect(result, isEmpty);
    expect(campaign.toJson(), before);
    await _tapVisible(tester, find.byKey(const ValueKey('initiative-close')));
    expect(result, [null]);
    expect(tester.takeException(), isNull);
  });
}
