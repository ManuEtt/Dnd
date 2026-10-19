import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_classes.dart';
import 'package:lebendiger_spielleiter/domain/starting_equipment_import.dart';
import 'package:lebendiger_spielleiter/ui/srd_class_selection_dialog.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Barde: konkrete Laute wird vor bestätigtem Startset verlangt', (
    tester,
  ) async {
    SrdClassSetupResult? result;
    final klass = findSrdClass('Barde')!;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showDialog<SrdClassSetupResult>(
                  context: context,
                  builder: (_) => SrdClassSelectionDialog(
                    currentClass: klass.name,
                    isNewCharacter: true,
                    existingSkills:
                        klass.skillChoices.take(klass.skillCount).toList(),
                    existingSavingThrows: const [],
                    characterLevel: 1,
                    constitutionScore: 14,
                    hasExistingHitPoints: false,
                    allowEquipment: true,
                  ),
                );
              },
              child: const Text('Assistent öffnen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Assistent öffnen'));
    await tester.pumpAndSettle();
    await tapVisible(
      tester,
      find.byKey(const ValueKey('srd-equipment--1')),
    );
    await tapVisible(tester, find.text('A – Ausrüstung').last);
    await tapVisible(
      tester,
      find.byKey(
        const ValueKey('srd-starter-choice-Musikinstrument (nach Wahl)'),
      ),
    );
    final lute = StartingEquipmentImport.optionsFor(
      const SrdStartingItem('Musikinstrument (nach Wahl)'),
    ).singleWhere((item) => item.name == 'Laute');
    await tapVisible(tester, find.text(lute.name).last);
    await tapVisible(
      tester,
      find.byKey(const ValueKey('srd-confirm-class')),
    );
    expect(result?.selection.characterClass.name, 'Barde');
    expect(
      result?.equipmentChoices['Musikinstrument (nach Wahl)'],
      lute.id,
    );
    expect(tester.takeException(), isNull);
  });
}
