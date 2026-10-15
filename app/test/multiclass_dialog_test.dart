import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/multiclass_rules.dart';
import 'package:lebendiger_spielleiter/ui/multiclass_selection_dialog.dart';

void main() {
  testWidgets('multiclass assistant explains required skills and confirms', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    MulticlassProposal? result;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (context) =>
      FilledButton(onPressed: () async {
        result = await showDialog<MulticlassProposal>(context: context,
          builder: (_) => MulticlassSelectionDialog(hero: HeroCharacter(
            id: 'id', name: 'Tira', className: 'Kämpfer', level: 3,
            abilities: const {'strength': 14, 'dexterity': 14,
              'constitution': 14,'intelligence': 14,'wisdom': 14,'charisma': 14},
          )));
      }, child: const Text('Öffnen'))))));
    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
    expect(find.text('Zweitklasse nach D&D'), findsOneWidget);
    expect(find.textContaining('Gesamtstufe: 3'), findsOneWidget);
    expect(find.byKey(const ValueKey('multiclass-class')), findsOneWidget);
    expect(find.byKey(const ValueKey('multiclass-accept')), findsOneWidget);
    // The initial (Barbar) proposal must preserve the original first class.
    await tester.tap(find.byKey(const ValueKey('multiclass-accept')));
    await tester.pumpAndSettle();
    expect(result?.secondClass, 'Barbar');
    expect(result?.totalLevel, 4);
    expect(tester.takeException(), isNull);
  });
}
