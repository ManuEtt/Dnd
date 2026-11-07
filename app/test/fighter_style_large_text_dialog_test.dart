import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/fighter_creation_rules.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/srd_class_selection_dialog.dart';

Finder _key(String name) => find.byKey(ValueKey(name));

Future<List<SrdClassSetupResult?>> _open(
  WidgetTester tester, {
  required double width,
  required double scale,
}) async {
  tester.view.physicalSize = Size(width, 840);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = const FakeViewPadding(bottom: 220);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);

  final results = <SrdClassSetupResult?>[];
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              results.add(
                await showDialog<SrdClassSetupResult>(
                  context: context,
                  builder: (_) => const SrdClassSelectionDialog(
                    currentClass: 'Kämpfer',
                    isNewCharacter: true,
                    existingSkills: [],
                    existingSavingThrows: [],
                    characterLevel: 1,
                    constitutionScore: 14,
                    hasExistingHitPoints: false,
                    allowEquipment: false,
                  ),
                ),
              );
            },
            child: const Text('Kämpfer erstellen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Kämpfer erstellen'));
  await tester.pumpAndSettle();
  return results;
}

Future<void> _tapVisible(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _selectLongStyle(WidgetTester tester) async {
  final field = _key('fighter-fighting-style');
  await _tapVisible(tester, field);
  final option = find.text('Kampf mit großen Waffen').last;
  await tester.ensureVisible(option);
  await tester.pumpAndSettle();
  await tester.tap(option);
  await tester.pumpAndSettle();
  final selectedStyle = tester.state<FormFieldState<String>>(field).value;
  expect(selectedStyle, 'great-weapon-fighting');
}

Future<void> _completeFighter(WidgetTester tester) async {
  await _selectLongStyle(tester);
  for (final skill in ['Athletik', 'Geschichte']) {
    await _tapVisible(tester, _key('srd-skill-$skill'));
  }
  for (final weapon in FighterCreationRules.masteryWeapons.take(3)) {
    await _tapVisible(tester, _key('fighter-mastery-${weapon.id}'));
  }
}

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets('$width dp / 200 % / IME: langer Kampfstil auswählbar', (
      tester,
    ) async {
      final results = await _open(tester, width: width, scale: 2);
      final style = _key('fighter-fighting-style');
      expect(
        tester.widget<DropdownButtonFormField<String>>(style).isExpanded,
        isTrue,
      );
      final confirm = _key('srd-confirm-class');
      expect(tester.widget<FantasyButton>(confirm).onPressed, isNull);
      await _completeFighter(tester);
      expect(tester.takeException(), isNull);
      expect(results, isEmpty);
      expect(tester.widget<FantasyButton>(confirm).onPressed, isNotNull);
      await _tapVisible(tester, confirm);
      expect(results, hasLength(1));
      expect(results.single?.selection.characterClass.name, 'Kämpfer');
      final fighter = results.single?.fighterChoices;
      expect(fighter?.styleId, 'great-weapon-fighting');
      expect(fighter?.masteryWeaponIds, hasLength(3));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('320 dp / 200 % / IME: keine Freigabe ohne Kampfstil', (
    tester,
  ) async {
    final results = await _open(tester, width: 320, scale: 2);
    final confirm = _key('srd-confirm-class');
    expect(tester.widget<FantasyButton>(confirm).onPressed, isNull);
    await _tapVisible(tester, find.text('Abbrechen').last);
    expect(results, [null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('360 dp / 100 %: langer Kampfstil bleibt auswählbar', (
    tester,
  ) async {
    final results = await _open(tester, width: 360, scale: 1);
    await _completeFighter(tester);
    await _tapVisible(tester, _key('srd-confirm-class'));
    expect(results.single?.fighterChoices?.styleId, 'great-weapon-fighting');
    expect(tester.takeException(), isNull);
  });
}
