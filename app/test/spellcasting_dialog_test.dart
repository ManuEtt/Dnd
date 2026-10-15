import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/spellcasting_rules.dart';
import 'package:lebendiger_spielleiter/ui/spellcasting_dialog.dart';

void main() {
  testWidgets('Zauberplätze werden im Dialog nur ausdrücklich bestätigt',
      (tester) async {
    final original = HeroCharacter(id: 'mage', name: 'Mira',
      className: 'Magier', spells: ['Licht'], level: 1);
    SpellcastingChoice? chosen;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(
      builder: (context) => TextButton(onPressed: () async {
        chosen = await showDialog<SpellcastingChoice>(context: context,
            builder: (_) => SpellcastingDialog(hero: original));
      }, child: const Text('Zauber öffnen')),
    ))));
    await tester.tap(find.text('Zauber öffnen'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1: 2 frei'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('spell-dialog-cast')));
    await tester.tap(find.byKey(const ValueKey('spell-dialog-cast')));
    await tester.pumpAndSettle();
    expect(chosen?.name, 'Licht');
    expect(chosen?.level, 0);
    expect(original.spentSpellSlots, isEmpty);
    final result = SpellcastingRules.cast(original,
        spellName: chosen!.name, spellLevel: chosen!.level);
    expect(result.hero.spentSpellSlots, isEmpty);
  });
}
