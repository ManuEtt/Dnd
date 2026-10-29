import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_classes.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';
import 'package:lebendiger_spielleiter/ui/srd_class_selection_dialog.dart';

const _symbolNames = {
  'item-holy-symbol-amulet': 'Heiliges Symbol: Amulett',
  'item-holy-symbol-emblem': 'Heiliges Symbol: Emblem',
  'item-holy-symbol-reliquary': 'Heiliges Symbol: Reliquiar',
};

Finder _key(String value) => find.byKey(ValueKey(value));
Finder get _symbolChoice => _key('srd-starter-choice-Heiliges Symbol');

Future<void> _open(
  WidgetTester tester, {
  required String className,
  required void Function(SrdClassSetupResult?) onResult,
  bool largeTextWithKeyboard = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFantasyTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(largeTextWithKeyboard ? 2 : 1),
          viewInsets: EdgeInsets.only(bottom: largeTextWithKeyboard ? 200 : 0),
        ),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => onResult(
              await showDialog<SrdClassSetupResult>(
                context: context,
                builder: (_) => SrdClassSelectionDialog(
                  currentClass: className,
                  isNewCharacter: true,
                  existingSkills: findSrdClass(
                    className,
                  )!.skillChoices.take(2).toList(),
                  existingSavingThrows: const [],
                  characterLevel: 1,
                  constitutionScore: 14,
                  hasExistingHitPoints: false,
                  allowEquipment: true,
                ),
              ),
            ),
            child: const Text('Klassenwahl öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Klassenwahl öffnen'));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _choose(
  WidgetTester tester,
  Finder dropdown,
  String option,
) async {
  await _tap(tester, dropdown);
  await _tap(tester, find.text(option).last);
}

Future<void> _chooseKitA(WidgetTester tester) =>
    _choose(tester, _key('srd-equipment--1'), 'A – Ausrüstung');

void main() {
  for (final className in ['Kleriker', 'Paladin']) {
    testWidgets('$className verlangt ausdrücklich eine der drei Symbolformen', (
      tester,
    ) async {
      SrdClassSetupResult? result;
      await _open(
        tester,
        className: className,
        onResult: (value) => result = value,
      );
      await _chooseKitA(tester);
      final selector = tester.widget<DropdownButton<String>>(
        find.descendant(
          of: _symbolChoice,
          matching: find.byWidgetPredicate(
            (widget) => widget is DropdownButton<String>,
          ),
        ),
      );
      expect(
        selector.items!.map((entry) => entry.value),
        unorderedEquals(_symbolNames.keys),
      );
      expect(tester.state<FormFieldState<String>>(_symbolChoice).value, isNull);
      await _tap(tester, _key('srd-confirm-class'));
      expect(result, isNull);
      expect(find.byType(SrdClassSelectionDialog), findsOneWidget);
      expect(
        find.textContaining('konkreten SRD-Gegenstand wählen'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    for (final symbol in _symbolNames.entries) {
      testWidgets('$className bestätigt ${symbol.value} in einem V3-Beleg', (
        tester,
      ) async {
        SrdClassSetupResult? result;
        await _open(
          tester,
          className: className,
          onResult: (value) => result = value,
        );
        await _chooseKitA(tester);
        await _choose(tester, _symbolChoice, symbol.value);
        await _tap(tester, _key('srd-confirm-class'));
        expect(find.byType(SrdClassSelectionDialog), findsNothing);
        expect(result!.selection.characterClass.name, className);
        expect(result!.selection.kitIndex, 0);
        expect(result!.equipmentChoices, {'Heiliges Symbol': symbol.key});
        expect(result!.startingClassChoice!.toJson()['version'], 3);
        expect(
          result!.startingClassChoice!.equipmentChoices,
          result!.equipmentChoices,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('$className-Startgold verlangt kein zusätzliches Symbol', (
      tester,
    ) async {
      SrdClassSetupResult? result;
      await _open(
        tester,
        className: className,
        onResult: (value) => result = value,
      );
      await _choose(tester, _key('srd-equipment--1'), 'B – Startgold');
      expect(_symbolChoice, findsNothing);
      await _tap(tester, _key('srd-confirm-class'));
      expect(result!.selection.kitIndex, 1);
      expect(result!.selection.startingKit!.items, isEmpty);
      expect(
        result!.selection.startingKit!.gold,
        className == 'Kleriker' ? 110 : 150,
      );
      expect(result!.equipmentChoices, isEmpty);
      expect(result!.startingClassChoice!.equipmentChoices, isEmpty);
      expect(result!.startingClassChoice!.toJson()['version'], 3);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Abbrechen verwirft die vorgeschlagene Symbolwahl', (
    tester,
  ) async {
    var completed = false;
    SrdClassSetupResult? result;
    await _open(
      tester,
      className: 'Kleriker',
      onResult: (value) {
        completed = true;
        result = value;
      },
    );
    await _chooseKitA(tester);
    await _choose(tester, _symbolChoice, _symbolNames.values.first);
    expect(completed, isFalse);
    await _tap(tester, find.text('Abbrechen'));
    expect(completed, isTrue);
    expect(result, isNull);
    expect(find.byType(SrdClassSelectionDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Paketwechsel verwirft die frühere Symbolwahl', (tester) async {
    await _open(tester, className: 'Kleriker', onResult: (_) {});
    await _chooseKitA(tester);
    await _choose(tester, _symbolChoice, _symbolNames.values.first);
    await _choose(tester, _key('srd-equipment-0'), 'B – Startgold');
    expect(_symbolChoice, findsNothing);
    await _choose(tester, _key('srd-equipment-1'), 'A – Ausrüstung');
    expect(tester.state<FormFieldState<String>>(_symbolChoice).value, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dasselbe Paket erhält die ausdrücklich bestätigte Symbolwahl', (
    tester,
  ) async {
    SrdClassSetupResult? result;
    await _open(
      tester,
      className: 'Kleriker',
      onResult: (value) => result = value,
    );
    await _chooseKitA(tester);
    await _choose(tester, _symbolChoice, 'Heiliges Symbol: Reliquiar');
    await _choose(tester, _key('srd-equipment-0'), 'A – Ausrüstung');
    expect(
      tester.state<FormFieldState<String>>(_symbolChoice).value,
      'item-holy-symbol-reliquary',
    );
    await _tap(tester, _key('srd-confirm-class'));
    expect(find.byType(SrdClassSelectionDialog), findsNothing);
    expect(result!.startingClassChoice!.equipmentChoices, {
      'Heiliges Symbol': 'item-holy-symbol-reliquary',
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('Klassenwechsel übernimmt keine veraltete Symbolwahl', (
    tester,
  ) async {
    await _open(tester, className: 'Kleriker', onResult: (_) {});
    await _chooseKitA(tester);
    await _choose(tester, _symbolChoice, _symbolNames.values.last);
    await _choose(tester, _key('srd-class-Kleriker'), 'Paladin');
    expect(_symbolChoice, findsNothing);
    await _chooseKitA(tester);
    expect(tester.state<FormFieldState<String>>(_symbolChoice).value, isNull);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 360.0]) {
    testWidgets(
      'Symbolwahl bei $width dp, 200 % Schrift und Tastatur erreichbar',
      (tester) async {
        tester.view.physicalSize = Size(width, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        SrdClassSetupResult? result;
        await _open(
          tester,
          className: 'Kleriker',
          onResult: (value) => result = value,
          largeTextWithKeyboard: true,
        );
        await _chooseKitA(tester);
        await _choose(tester, _symbolChoice, 'Heiliges Symbol: Emblem');
        final confirm = _key('srd-confirm-class');
        expect(confirm.hitTestable(), findsOneWidget);
        expect(tester.getSize(confirm).height, greaterThanOrEqualTo(48));
        expect(
          tester.getSemantics(confirm).label,
          contains('Klasse und Fertigkeiten'),
        );
        expect(tester.takeException(), isNull);
        await _tap(tester, confirm);
        expect(result!.startingClassChoice!.equipmentChoices, {
          'Heiliges Symbol': 'item-holy-symbol-emblem',
        });
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }
}
