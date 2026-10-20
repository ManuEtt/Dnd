import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/magic_missile_dialog.dart';

void main() {
  testWidgets('Unbestätigtes Ziel verhindert Zauberauswahl', (tester) async {
    MagicMissileChoice? selected;
    final hero = HeroCharacter(
      id: 'hero',
      name: 'Alia',
      className: 'Magier',
      level: 1,
      spells: const ['Magisches Geschoss'],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                selected = await showDialog<MagicMissileChoice>(
                  context: context,
                  builder: (_) => MagicMissileDialog(
                    hero: hero,
                    encounter: const Encounter(
                      id: 'e',
                      enemyName: 'Wache',
                      enemyHitPoints: 20,
                      enemyMaxHitPoints: 20,
                    ),
                  ),
                );
              },
              child: const Text('Dialog öffnen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Dialog öffnen'));
    await tester.pumpAndSettle();
    expect(find.textContaining('3 Geschosse'), findsOneWidget);
    final button = find.byKey(const ValueKey('missile-confirm'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(selected, isNull);
    expect(find.textContaining('Bitte alle tatsächlichen'), findsOneWidget);

    for (final name in [
      'missile-visible',
      'missile-range',
      'missile-verbal',
      'missile-somatic',
      'missile-protection',
    ]) {
      final field = find.byKey(ValueKey(name));
      await tester.ensureVisible(field);
      await tester.tap(field);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(selected, isNotNull);
    expect(selected!.castingClass, 'Magier');
    expect(selected!.slotLevel, 1);
    expect(selected!.targetVisibleConfirmed, isTrue);
    expect(selected!.noProtectionConfirmed, isTrue);
  });
}
