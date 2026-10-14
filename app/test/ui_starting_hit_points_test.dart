import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/character_editor.dart';

Future<void> _open(
  WidgetTester tester,
  HeroCharacter hero,
  void Function(HeroCharacter?) onSaved,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            onPressed: () async {
              onSaved(await Navigator.of(context).push<HeroCharacter>(
                MaterialPageRoute(builder: (_) => CharacterEditor(hero: hero)),
              ));
            },
            child: const Text('Bearbeiten'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Bearbeiten'));
  await tester.pumpAndSettle();
}

Future<void> _findAndTap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    380,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('TP-Vorschlag überschreibt bestätigte TP erst nach Zustimmung',
      (tester) async {
    HeroCharacter? saved;
    final existing = HeroCharacter(
      id: 'player-1',
      name: 'Liora',
      className: 'Kämpfer',
      level: 1,
      abilities: const {'strength': 15, 'dexterity': 12,
        'constitution': 14, 'intelligence': 10, 'wisdom': 13, 'charisma': 8},
      hitPoints: 7,
      maxHitPoints: 9,
    );
    await _open(tester, existing, (hero) => saved = hero);
    const button = ValueKey('suggest-level1-hit-points');
    await _findAndTap(tester, find.byKey(button));
    expect(find.textContaining('W10'), findsWidgets);
    expect(find.textContaining('12 TP'), findsWidgets);
    await tester.tap(find.text('Abbrechen').last);
    await tester.pumpAndSettle();
    await _findAndTap(tester, find.text('Charakter speichern'));
    expect(saved?.hitPoints, 7);
    expect(saved?.maxHitPoints, 9);

    saved = null;
    await _open(tester, existing, (hero) => saved = hero);
    await _findAndTap(tester, find.byKey(button));
    await tester.tap(find.text('Trefferpunkte übernehmen'));
    await tester.pumpAndSettle();
    await _findAndTap(tester, find.text('Charakter speichern'));
    expect(saved?.hitPoints, 12);
    expect(saved?.maxHitPoints, 12);
  });
}
