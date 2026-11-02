import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/manual_turn_queue_dialog.dart';

HeroCharacter _hero() => HeroCharacter(
  id: 'hero',
  name: 'Aria',
  className: 'Magier',
  level: 5,
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 16,
    'wisdom': 12,
    'charisma': 14,
  },
  hitPoints: 20,
  maxHitPoints: 20,
  armorClass: 14,
);

Campaign _campaign() => GameEngine().createDemo().copyWith(
  hero: _hero(),
  encounter: const Encounter(
    id: 'foe',
    enemyName: 'Wächter',
    enemyHitPoints: 10,
    enemyMaxHitPoints: 10,
    heroInitiative: 15,
    enemyInitiative: 15,
  ),
  trackedAreaCreatures: const [
    TrackedAreaCreature(
      id: 'goblin',
      name: 'Goblin',
      hitPoints: 5,
      maxHitPoints: 5,
      initiativeTotal: 13,
      initiativeController: 'gm',
    ),
  ],
);

Finder _key(String name) => find.byKey(ValueKey('queue-$name'));

Future<void> _open(
  WidgetTester tester, {
  required double width,
  required Campaign campaign,
  required ValueChanged<ManualTurnQueueChoice?> onResult,
}) async {
  tester.view.physicalSize = Size(width, 840);
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
              onResult(
                await showDialog<ManualTurnQueueChoice>(
                  context: context,
                  builder: (_) => ManualTurnQueueDialog(campaign: campaign),
                ),
              );
            },
            child: const Text('Zugfolge öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Zugfolge öffnen'));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets('Manuelle Zugfolge $width dp/200 %/IME: Fehler und Abbruch', (
      tester,
    ) async {
      final campaign = _campaign();
      final snapshot = campaign.toJson();
      final results = <ManualTurnQueueChoice?>[];
      await _open(
        tester,
        width: width,
        campaign: campaign,
        onResult: results.add,
      );

      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(dialog.scrollable, isTrue);
      expect(
        find.ancestor(
          of: _key('ties-confirmed'),
          matching: find.byType(Scrollable),
        ),
        findsOneWidget,
      );
      expect(_key('entry-goblin'), findsOneWidget);
      await _tap(tester, _key('establish'));
      expect(_key('validation-error'), findsOneWidget);
      expect(find.textContaining('Vor dem Speichern'), findsOneWidget);
      expect(
        find.byWidgetPredicate((widget) {
          if (widget is! Semantics) return false;
          return widget.properties.liveRegion ?? false;
        }),
        findsWidgets,
      );
      expect(results, isEmpty);
      await _tap(tester, find.text('Schließen'));
      expect(results, [null]);
      expect(campaign.toJson(), snapshot);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('320 dp/200 %/IME: bewusste Bestätigungen liefern nur Auswahl', (
    tester,
  ) async {
    final campaign = _campaign();
    final snapshot = campaign.toJson();
    final results = <ManualTurnQueueChoice?>[];
    await _open(
      tester,
      width: 320,
      campaign: campaign,
      onResult: results.add,
    );
    await _tap(tester, _key('base-confirmed'));
    await _tap(tester, _key('ties-confirmed'));
    expect(
      tester.widget<CheckboxListTile>(_key('base-confirmed')).value,
      isTrue,
    );
    expect(
      tester.widget<CheckboxListTile>(_key('ties-confirmed')).value,
      isTrue,
    );
    await _tap(tester, _key('establish'));
    expect(results, hasLength(1));
    expect(results.single!.advance, isFalse);
    expect(results.single!.baseConfirmed, isTrue);
    expect(results.single!.tieConfirmed, isTrue);
    expect(results.single!.actorIds, ['hero', 'foe', 'goblin']);
    expect(campaign.toJson(), snapshot);
    expect(tester.takeException(), isNull);
  });

  testWidgets('360 dp/200 %/IME: Gleichstand-Umsortierung widerruft Häkchen', (
    tester,
  ) async {
    final campaign = _campaign();
    final snapshot = campaign.toJson();
    final results = <ManualTurnQueueChoice?>[];
    await _open(
      tester,
      width: 360,
      campaign: campaign,
      onResult: results.add,
    );
    await _tap(tester, _key('base-confirmed'));
    await _tap(tester, _key('ties-confirmed'));
    await _tap(tester, _key('down-hero'));
    expect(
      tester.widget<CheckboxListTile>(_key('ties-confirmed')).value,
      isFalse,
    );
    await _tap(tester, _key('establish'));
    expect(results, isEmpty);
    expect(_key('validation-error'), findsOneWidget);
    await _tap(tester, _key('ties-confirmed'));
    await _tap(tester, _key('establish'));
    expect(results, hasLength(1));
    expect(results.single!.actorIds, ['foe', 'hero', 'goblin']);
    expect(results.single!.tieConfirmed, isTrue);
    expect(campaign.toJson(), snapshot);
    expect(tester.takeException(), isNull);
  });

  testWidgets('320 dp/200 %/IME: gespeicherten Marker nur als Aktion melden', (
    tester,
  ) async {
    final campaign = GameEngine()
        .establishManualTurnQueue(
          _campaign(),
          orderedActorIds: const ['hero', 'foe', 'goblin'],
          baseInitiativeConfirmed: true,
          tiedOrderConfirmed: true,
        )
        .campaign;
    final snapshot = campaign.toJson();
    final results = <ManualTurnQueueChoice?>[];
    await _open(
      tester,
      width: 320,
      campaign: campaign,
      onResult: results.add,
    );
    expect(find.textContaining('Manuelle Runde:'), findsOneWidget);
    expect(_key('advance'), findsOneWidget);
    await _tap(tester, _key('advance'));
    expect(results, hasLength(1));
    expect(results.single!.advance, isTrue);
    expect(campaign.toJson(), snapshot);
    expect(tester.takeException(), isNull);
  });
}
