import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/character_editor.dart';

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Fehlende Startwaffenwerte werden erst nach Zustimmung ergänzt', (
    tester,
  ) async {
    HeroCharacter? saved;
    final original = HeroCharacter(
      id: 'legacy-kit',
      name: 'Liora',
      inventory: [
        const InventoryItem(id: 'armor', name: 'Kettenpanzer'),
        const InventoryItem(id: 'weapon', name: 'Langschwert'),
        const InventoryItem(id: 'custom', name: 'Heiliges Symbol'),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                saved = await Navigator.push<HeroCharacter>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CharacterEditor(hero: original),
                  ),
                );
              },
              child: const Text('Editor öffnen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Editor öffnen'));
    await tester.pumpAndSettle();

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('character-enrich-equipment')),
    );
    expect(find.text('SRD-Gegenstandswerte nachtragen'), findsOneWidget);
    expect(find.textContaining('Kettenpanzer'), findsWidgets);
    expect(find.textContaining('Langschwert'), findsWidgets);
    await tester.tap(find.text('Abbrechen').last);
    await tester.pumpAndSettle();

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('character-enrich-equipment')),
    );
    await tester.tap(find.byKey(const ValueKey('character-enrich-confirm')));
    await tester.pumpAndSettle();

    await _tapVisible(tester, find.text('Charakter speichern'));
    expect(saved, isNotNull);
    expect(saved!.inventory[0].catalogId, 'armor-chain-mail');
    expect(saved!.inventory[0].stats!.armorBaseAc, 16);
    expect(saved!.inventory[1].catalogId, 'weapon-longsword');
    expect(saved!.inventory[1].stats!.damage, '1d8');
    expect(saved!.inventory[2].catalogId, isEmpty);
    expect(saved!.inventory[2].stats, isNull);
    expect(tester.takeException(), isNull);
  });
}
