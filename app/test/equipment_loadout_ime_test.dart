import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/equipment_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/equipment_loadout_dialog.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';

void main() {
  HeroCharacter makeHero({bool equipped = false}) => HeroCharacter(
    id: 'h',
    name: 'Held',
    abilities: const {
      'strength': 16,
      'dexterity': 14,
      'constitution': 10,
      'intelligence': 10,
      'wisdom': 10,
      'charisma': 10,
    },
    equippedArmorId: equipped ? 'armor' : '',
    inventory: const [
      InventoryItem(
        id: 'armor',
        name: 'Lederrüstung',
        catalogId: 'armor-leather-armor',
      ),
    ],
  );

  Future<void> openDialog(
    WidgetTester tester,
    HeroCharacter character, {
    required double width,
    required ValueChanged<EquipmentRulePreview?> onResult,
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
              key: const ValueKey('open-loadout-ime'),
              onPressed: () async {
                final result = await showDialog<EquipmentRulePreview>(
                  context: context,
                  builder: (_) => EquipmentLoadoutDialog(hero: character),
                );
                onResult(result);
              },
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-loadout-ime')));
    await tester.pumpAndSettle();
  }

  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    final scrollable = find
        .descendant(
          of: find.byType(EquipmentLoadoutDialog),
          matching: find.byType(Scrollable),
        )
        .first;
    for (var attempt = 0; attempt < 12; attempt++) {
      if (target.hitTestable().evaluate().isNotEmpty) break;
      await tester.drag(scrollable, const Offset(0, -170));
      await tester.pumpAndSettle();
    }
    expect(target.hitTestable(), findsOneWidget);
  }

  for (final width in [320.0, 360.0]) {
    testWidgets('Ausrüstung bei $width dp/200 %/IME sicher abbrechen', (
      tester,
    ) async {
      final character = makeHero();
      final original = character.toJson();
      final results = <EquipmentRulePreview?>[];
      await openDialog(
        tester,
        character,
        width: width,
        onResult: results.add,
      );
      final confirm = find.byKey(const ValueKey('loadout-confirm'));
      expect(tester.widget<FantasyTextButton>(confirm).onPressed, isNull);
      final cancel = find.text('Abbrechen');
      expect(cancel.hitTestable(), findsOneWidget);
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(results, [null]);
      expect(character.toJson(), original);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Rüstungsübung bei 320 dp/200 %/IME per Touch erreichbar', (
    tester,
  ) async {
    final character = makeHero(equipped: true);
    final original = character.toJson();
    final results = <EquipmentRulePreview?>[];
    await openDialog(
      tester,
      character,
      width: 320,
      onResult: results.add,
    );
    final trained = find.byKey(const ValueKey('loadout-armor-trained'));
    expect(find.text('Rüstungsübung bestätigt'), findsOneWidget);
    await scrollTo(tester, trained);
    await tester.tap(trained);
    await tester.pumpAndSettle();
    final confirm = find.byKey(const ValueKey('loadout-confirm'));
    expect(tester.widget<FantasyTextButton>(confirm).onPressed, isNotNull);
    expect(confirm.hitTestable(), findsOneWidget);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(results.single?.armorClass, 13);
    expect(character.toJson(), original);
    expect(tester.takeException(), isNull);
  });
}
