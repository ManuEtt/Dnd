import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/character_editor.dart';

Future<void> openClassEditor(WidgetTester tester, HeroCharacter? original,
    void Function(HeroCharacter?) onSaved) async {
  await tester.pumpWidget(MaterialApp(
    home: Builder(builder: (context) => Scaffold(body: FilledButton(
      onPressed: () async => onSaved(await Navigator.push<HeroCharacter>(
        context,
        MaterialPageRoute(builder: (_) => CharacterEditor(hero: original)),
      )),
      child: const Text('Öffnen'),
    ))),
  ));
  await tester.tap(find.text('Öffnen'));
  await tester.pumpAndSettle();
}

Future<void> tapInEditor(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 320,
      scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('new level-1 hero: choose ranger skills and save the confirmed class', (tester) async {
    HeroCharacter? saved;
    await openClassEditor(tester, null, (hero) => saved = hero);
    await tester.enterText(find.widgetWithText(TextFormField, 'Charaktername'), 'Elowen');
    await tapInEditor(tester, find.byKey(const ValueKey('open-srd-class-selection')));
    expect(find.text('D&D-Klasse und Startwerte'), findsOneWidget);
    expect(find.textContaining('0 / 3'), findsOneWidget);
    for (final skill in ['Wahrnehmung', 'Heimlichkeit', 'Überlebenskunst']) {
      final target = find.byKey(ValueKey('srd-skill-$skill'));
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('3 / 3'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('srd-confirm-class')));
    await tester.tap(find.byKey(const ValueKey('srd-confirm-class')));
    await tester.pumpAndSettle();
    await tapInEditor(tester, find.text('Charakter speichern'));
    expect(saved?.className, 'Waldläufer');
    expect(saved?.skills, containsAll(['Wahrnehmung', 'Heimlichkeit', 'Überlebenskunst']));
    expect(saved?.savingThrowProficiencies, ['strength', 'dexterity']);
    expect(saved?.hitPoints, isNull);
    expect(saved?.inventory, isEmpty);
  });

  testWidgets('existing character: abort class selection leaves every field unchanged', (tester) async {
    HeroCharacter? saved;
    final original = HeroCharacter(id: 'arescan', name: 'Arescan',
        className: 'Waldläufer', skills: const ['Geschichte'],
        hitPoints: 9, maxHitPoints: 14);
    await openClassEditor(tester, original, (hero) => saved = hero);
    await tapInEditor(tester, find.byKey(const ValueKey('open-srd-class-selection')));
    await tester.tap(find.text('Abbrechen').last);
    await tester.pumpAndSettle();
    await tapInEditor(tester, find.text('Charakter speichern'));
    expect(saved?.toJson(), original.toJson());
  });

  testWidgets('new manually changed score requires explicit house-rule consent', (tester) async {
    HeroCharacter? saved;
    await openClassEditor(tester, null, (hero) => saved = hero);
    await tester.enterText(find.widgetWithText(TextFormField, 'Charaktername'), 'Elowen');
    final ability = find.widgetWithText(TextFormField, 'Stärke');
    await tester.scrollUntilVisible(ability, 300,
        scrollable: find.byType(Scrollable).first);
    await tester.enterText(ability, '20');
    await tapInEditor(tester, find.text('Charakter speichern'));
    expect(saved, isNull);
    expect(find.textContaining('Hausregel-Ausnahme'), findsOneWidget);
    await tapInEditor(tester, find.byKey(const ValueKey('allow-manual-abilities')));
    await tapInEditor(tester, find.text('Charakter speichern'));
    expect(saved?.abilities['strength'], 20);
  });
}
