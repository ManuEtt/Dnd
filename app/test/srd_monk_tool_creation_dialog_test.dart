import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_classes.dart';
import 'package:lebendiger_spielleiter/domain/starting_class_choice.dart';
import 'package:lebendiger_spielleiter/domain/starting_equipment_import.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';
import 'package:lebendiger_spielleiter/ui/srd_class_selection_dialog.dart';

const _toolId = 'item-smith-s-tools';
const _instrumentId = 'item-lute';
const _monkSkills = ['Akrobatik', 'Athletik'];

Finder _key(String value) => find.byKey(ValueKey(value));
Finder get _toolChoice => _key('srd-monk-tool-proficiency');

Future<void> _open(
  WidgetTester tester, {
  required void Function(SrdClassSetupResult?) onResult,
  String className = 'Mönch',
  bool isNewCharacter = true,
  bool allowEquipment = true,
  bool largeTextWithKeyboard = false,
  StartingClassChoice? currentChoice,
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
                  isNewCharacter: isNewCharacter,
                  existingSkills: findSrdClass(className)!.skillChoices
                      .take(findSrdClass(className)!.skillCount)
                      .toList(),
                  existingSavingThrows: const [],
                  characterLevel: 1,
                  constitutionScore: 14,
                  hasExistingHitPoints: !isNewCharacter,
                  allowEquipment: allowEquipment,
                  currentStartingClassChoice: currentChoice,
                ),
              ),
            ),
            child: const Text('Mönch-Klassenwahl öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Mönch-Klassenwahl öffnen'));
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
  final button = tester.widget<DropdownButton>(
    find.descendant(
      of: dropdown,
      matching: find.byWidgetPredicate((widget) => widget is DropdownButton),
    ),
  );
  final targetIndex = button.items!.indexWhere(
    (entry) => entry.child is Text && (entry.child as Text).data == option,
  );
  final currentIndex = button.items!.indexWhere(
    (entry) => entry.value == button.value,
  );
  await _tap(tester, dropdown);
  if (find.text(option).evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      find.text(option),
      targetIndex < currentIndex ? -120 : 120,
      scrollable: find.byType(Scrollable).last,
    );
  }
  await _tap(tester, find.text(option).last);
}

StartingClassChoice _proof({required bool gold}) =>
    StartingClassChoice.confirmed(
      className: 'Mönch',
      skills: _monkSkills,
      kitIndex: gold ? 1 : 0,
      equipmentChoices: gold
          ? const {}
          : const {StartingEquipmentImport.monkToolLabel: _toolId},
      toolProficiencyCatalogId: _toolId,
    );

void main() {
  for (final kit in [0, 1]) {
    testWidgets(
      'Mönch-Paket $kit benötigt eine Werkzeugübung ohne Vorauswahl',
      (tester) async {
        SrdClassSetupResult? result;
        await _open(tester, onResult: (value) => result = value);
        expect(tester.state<FormFieldState<String>>(_toolChoice).value, isNull);
        final selector = tester.widget<DropdownButton<String>>(
          find.descendant(
            of: _toolChoice,
            matching: find.byWidgetPredicate(
              (widget) => widget is DropdownButton<String>,
            ),
          ),
        );
        expect(
          selector.items!.map((item) => item.value),
          containsAll([_toolId, _instrumentId]),
        );
        expect(
          selector.items!.map((item) => item.value),
          isNot(contains('item-thieves-tools')),
        );
        await _choose(
          tester,
          _key('srd-equipment--1'),
          kit == 0 ? 'A – Ausrüstung' : 'B – Startgold',
        );
        await _tap(tester, _key('srd-confirm-class'));
        expect(result, isNull);
        expect(find.byType(SrdClassSelectionDialog), findsOneWidget);
        expect(
          find.text(
            'Eine Handwerkszeug- oder Instrumentübung für den Mönch wählen.',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final tool in const {
    _toolId: 'Schmiedewerkzeug',
    _instrumentId: 'Laute',
  }.entries) {
    testWidgets(
      'Mönch-Paket A enthält genau die gewählte Übung: ${tool.value}',
      (tester) async {
        SrdClassSetupResult? result;
        await _open(tester, onResult: (value) => result = value);
        await _choose(tester, _toolChoice, tool.value);
        await _choose(tester, _key('srd-equipment--1'), 'A – Ausrüstung');
        expect(
          _key('srd-starter-choice-${StartingEquipmentImport.monkToolLabel}'),
          findsNothing,
        );
        expect(
          tester.state<FormFieldState<String>>(_toolChoice).value,
          tool.key,
        );
        await _tap(tester, _key('srd-confirm-class'));
        expect(find.byType(SrdClassSelectionDialog), findsNothing);
        expect(result!.selection.kitIndex, 0);
        expect(result!.selection.startingKit!.gold, 11);
        expect(result!.equipmentChoices, {
          StartingEquipmentImport.monkToolLabel: tool.key,
        });
        final proof = result!.startingClassChoice!;
        expect(proof.version, 3);
        expect(proof.toolProficiencyCatalogId, tool.key);
        expect(proof.equipmentChoices, result!.equipmentChoices);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Mönch-Startgold erhält die Übung ohne Werkzeug-Gegenstand', (
    tester,
  ) async {
    SrdClassSetupResult? result;
    await _open(tester, onResult: (value) => result = value);
    await _choose(tester, _key('srd-equipment--1'), 'B – Startgold');
    await _choose(tester, _toolChoice, 'Laute');
    await _tap(tester, _key('srd-confirm-class'));
    expect(result!.selection.startingKit!.gold, 50);
    expect(result!.selection.startingKit!.items, isEmpty);
    expect(result!.equipmentChoices, isEmpty);
    expect(
      result!.startingClassChoice!.toolProficiencyCatalogId,
      _instrumentId,
    );
    expect(result!.startingClassChoice!.version, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Abbruch verwirft die nur vorgeschlagene Mönch-Werkzeugwahl', (
    tester,
  ) async {
    var completed = false;
    SrdClassSetupResult? result;
    await _open(
      tester,
      onResult: (value) {
        completed = true;
        result = value;
      },
    );
    await _choose(tester, _toolChoice, 'Schmiedewerkzeug');
    await _choose(tester, _key('srd-equipment--1'), 'A – Ausrüstung');
    expect(completed, isFalse);
    await _tap(tester, find.text('Abbrechen'));
    expect(completed, isTrue);
    expect(result, isNull);
    expect(find.byType(SrdClassSelectionDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Paket A–B–A bewahrt die unabhängig gewählte Werkzeugübung', (
    tester,
  ) async {
    SrdClassSetupResult? result;
    await _open(tester, onResult: (value) => result = value);
    await _choose(tester, _toolChoice, 'Laute');
    await _choose(tester, _key('srd-equipment--1'), 'A – Ausrüstung');
    await _choose(tester, _key('srd-equipment-0'), 'B – Startgold');
    expect(
      tester.state<FormFieldState<String>>(_toolChoice).value,
      _instrumentId,
    );
    await _choose(tester, _key('srd-equipment-1'), 'A – Ausrüstung');
    expect(
      tester.state<FormFieldState<String>>(_toolChoice).value,
      _instrumentId,
    );
    await _tap(tester, _key('srd-confirm-class'));
    expect(result!.equipmentChoices, {
      StartingEquipmentImport.monkToolLabel: _instrumentId,
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('Klassenwechsel verwirft die unbestätigte Mönch-Werkzeugwahl', (
    tester,
  ) async {
    await _open(tester, onResult: (_) {});
    await _choose(tester, _toolChoice, 'Laute');
    await _choose(tester, _key('srd-class-Mönch'), 'Barbar');
    expect(_toolChoice, findsNothing);
    await _choose(tester, _key('srd-class-Barbar'), 'Mönch');
    expect(tester.state<FormFieldState<String>>(_toolChoice).value, isNull);
    expect(find.byKey(const ValueKey('srd-equipment--1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dieselbe Klasse bewahrt ausdrückliche Werkzeug- und Paketwahl', (
    tester,
  ) async {
    SrdClassSetupResult? result;
    await _open(tester, onResult: (value) => result = value);
    await _choose(tester, _toolChoice, 'Laute');
    await _choose(tester, _key('srd-equipment--1'), 'A – Ausrüstung');
    await _choose(tester, _key('srd-class-Mönch'), 'Mönch');
    expect(
      tester.state<FormFieldState<String>>(_toolChoice).value,
      _instrumentId,
    );
    expect(_key('srd-equipment-0'), findsOneWidget);
    await _tap(tester, _key('srd-confirm-class'));
    expect(
      result!.startingClassChoice!.toolProficiencyCatalogId,
      _instrumentId,
    );
    expect(result!.equipmentChoices, {
      StartingEquipmentImport.monkToolLabel: _instrumentId,
    });
    expect(tester.takeException(), isNull);
  });

  testWidgets('Übernommenes Paket A setzt und sperrt die tatsächliche Übung', (
    tester,
  ) async {
    final original = _proof(gold: false);
    final before = jsonEncode(original.toJson());
    SrdClassSetupResult? result;
    await _open(
      tester,
      allowEquipment: false,
      currentChoice: original,
      onResult: (value) => result = value,
    );
    expect(tester.state<FormFieldState<String>>(_toolChoice).value, _toolId);
    final selector = tester.widget<DropdownButton<String>>(
      find.descendant(
        of: _toolChoice,
        matching: find.byWidgetPredicate(
          (widget) => widget is DropdownButton<String>,
        ),
      ),
    );
    expect(selector.onChanged, isNull);
    expect(
      find.text('Mit dem bereits übernommenen Paket verbunden.'),
      findsOneWidget,
    );
    expect(_key('srd-equipment--1'), findsNothing);
    await _tap(tester, _key('srd-confirm-class'));
    expect(result!.startingClassChoice!.toolProficiencyCatalogId, _toolId);
    expect(result!.selection.startingKit, isNull);
    expect(result!.equipmentChoices, isEmpty);
    expect(jsonEncode(original.toJson()), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Übernommenes Startgold erlaubt eine ausdrückliche Übungsänderung',
    (tester) async {
      final original = _proof(gold: true);
      final before = jsonEncode(original.toJson());
      SrdClassSetupResult? result;
      await _open(
        tester,
        allowEquipment: false,
        currentChoice: original,
        onResult: (value) => result = value,
      );
      expect(tester.state<FormFieldState<String>>(_toolChoice).value, _toolId);
      await _choose(tester, _toolChoice, 'Laute');
      await _tap(tester, _key('srd-confirm-class'));
      expect(
        result!.startingClassChoice!.toolProficiencyCatalogId,
        _instrumentId,
      );
      expect(result!.selection.startingKit, isNull);
      expect(result!.equipmentChoices, isEmpty);
      expect(jsonEncode(original.toJson()), before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Gesperrte Paket-A-Übung bleibt nach Klassen-Rückwechsel bedienbar',
    (tester) async {
      final original = _proof(gold: false);
      final before = jsonEncode(original.toJson());
      SrdClassSetupResult? result;
      await _open(
        tester,
        allowEquipment: false,
        currentChoice: original,
        onResult: (value) => result = value,
      );
      await _choose(tester, _key('srd-class-Mönch'), 'Barbar');
      await _choose(tester, _key('srd-class-Barbar'), 'Mönch');
      expect(tester.state<FormFieldState<String>>(_toolChoice).value, _toolId);
      for (final skill in _monkSkills) {
        await _tap(tester, _key('srd-skill-$skill'));
      }
      await _tap(tester, _key('srd-confirm-class'));
      expect(find.byType(SrdClassSelectionDialog), findsNothing);
      expect(result!.startingClassChoice!.toolProficiencyCatalogId, _toolId);
      expect(result!.selection.startingKit, isNull);
      expect(jsonEncode(original.toJson()), before);
      expect(tester.takeException(), isNull);
    },
  );

  for (final version in [1, 2]) {
    testWidgets('Bestehender v$version-Mönch erhält keine neue Werkzeugwahl', (
      tester,
    ) async {
      final original = StartingClassChoice.fromJson({
        'version': version,
        'className': 'Mönch',
        'skills': _monkSkills,
        'kitIndex': 0,
        'equipmentChoices': {StartingEquipmentImport.monkToolLabel: _toolId},
      });
      final before = jsonEncode(original.toJson());
      SrdClassSetupResult? result;
      await _open(
        tester,
        isNewCharacter: false,
        allowEquipment: false,
        currentChoice: original,
        onResult: (value) => result = value,
      );
      expect(_toolChoice, findsNothing);
      await _tap(tester, _key('srd-confirm-class'));
      expect(result!.startingClassChoice, isNull);
      expect(result!.selection.startingKit, isNull);
      expect(result!.equipmentChoices, isEmpty);
      expect(jsonEncode(original.toJson()), before);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Andere Startklasse erhält keine Mönch-Werkzeugübung', (
    tester,
  ) async {
    SrdClassSetupResult? result;
    await _open(
      tester,
      className: 'Barbar',
      onResult: (value) => result = value,
    );
    expect(_toolChoice, findsNothing);
    await _choose(tester, _key('srd-equipment--1'), 'B – Startgold');
    await _tap(tester, _key('srd-confirm-class'));
    expect(result!.selection.characterClass.name, 'Barbar');
    expect(result!.startingClassChoice!.toolProficiencyCatalogId, isNull);
    expect(result!.equipmentChoices, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 360.0]) {
    testWidgets(
      'Mönch-Wahl $width dp bei 200 % Schrift und Tastatur erreichbar',
      (tester) async {
        tester.view.physicalSize = Size(width, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        SrdClassSetupResult? result;
        await _open(
          tester,
          largeTextWithKeyboard: true,
          onResult: (value) => result = value,
        );
        await _choose(tester, _toolChoice, 'Flöte');
        await _choose(tester, _key('srd-equipment--1'), 'A – Ausrüstung');
        final confirm = _key('srd-confirm-class');
        expect(confirm.hitTestable(), findsOneWidget);
        expect(tester.getSize(confirm).height, greaterThanOrEqualTo(48));
        expect(
          tester.getSemantics(confirm).label,
          contains('Klasse und Fertigkeiten'),
        );
        expect(tester.takeException(), isNull);
        await _tap(tester, confirm);
        expect(
          result!.startingClassChoice!.toolProficiencyCatalogId,
          'item-flute',
        );
        expect(result!.equipmentChoices, {
          StartingEquipmentImport.monkToolLabel: 'item-flute',
        });
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }
}
