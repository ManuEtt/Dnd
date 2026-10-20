import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fire_bolt_dialog.dart';

HeroCharacter _hero({List<String> spells = const ['Feuerpfeil']}) =>
    HeroCharacter(
      id: 'fire-dialog',
      name: 'Arina',
      className: 'Magier',
      level: 5,
      spells: spells,
      abilities: const {
        'strength': 10,
        'dexterity': 12,
        'constitution': 14,
        'intelligence': 16,
        'wisdom': 12,
        'charisma': 14,
      },
      maxHitPoints: 20,
      hitPoints: 20,
    );

const _fight = Encounter(
  id: 'fire-dialog-foe',
  enemyName: 'Wächter',
  enemyHitPoints: 20,
  enemyMaxHitPoints: 20,
  enemyArmorClass: 14,
);

void main() {
  testWidgets('fire confirmation starts unchecked and cannot fake approval', (
    tester,
  ) async {
    FireBoltChoice? choice;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                choice = await showDialog<FireBoltChoice>(
                  context: context,
                  builder: (_) =>
                      FireBoltDialog(hero: _hero(), encounter: _fight),
                );
              },
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
    expect(find.text('Feuerpfeil wirken'), findsOneWidget);
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('fire-bolt-visible')),
          )
          .value,
      false,
    );
    final cast = find.byKey(const ValueKey('fire-bolt-cast'));
    await tester.tap(cast);
    await tester.pumpAndSettle();
    expect(find.textContaining('Bitte alle tatsächlichen'), findsOneWidget);
    expect(choice, isNull);
    expect(find.text('Feuerpfeil wirken'), findsOneWidget);
  });

  testWidgets('missing prepared spell disables Fire Bolt confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FireBoltDialog(
            hero: _hero(spells: const []),
            encounter: _fight,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Kein bestätigter Feuerpfeil verfügbar.'), findsOneWidget);
    final confirm = tester.widget<FilledButton>(
      find.byKey(const ValueKey('fire-bolt-cast')),
    );
    expect(confirm.onPressed, isNull);
  });
}
