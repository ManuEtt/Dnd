import 'package:flutter/material.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
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

  testWidgets('class attack preview requires actual confirmation', (
    tester,
  ) async {
    final hero = _hero();
    final before = hero.toJson();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FireBoltDialog(hero: hero, encounter: _fight),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('fire-bolt-class-stats')), findsNothing);
    final tile = find.byKey(const ValueKey('fire-bolt-attack-modifiers'));
    expect(tester.widget<CheckboxListTile>(tile).value, isFalse);
    final checkbox = find.descendant(of: tile, matching: find.byType(Checkbox));
    await tester.ensureVisible(checkbox);
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    final preview = tester
        .widget<Text>(
          find.byKey(const ValueKey('fire-bolt-class-stats')),
        )
        .data!;
    expect(preview, contains('Basisangriff +6'));
    expect(preview, contains('Intelligenz 16'));
    expect(hero.toJson(), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invalid class profile cannot confirm attack preview', (
    tester,
  ) async {
    final hero = _hero().copyWith(
      className: 'Wizard',
      secondaryClassName: 'Magier',
      secondaryClassLevel: 1,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FireBoltDialog(hero: hero, encounter: _fight),
        ),
      ),
    );
    final confirm = tester.widget<FantasyTextButton>(
      find.byKey(const ValueKey('fire-bolt-cast')),
    );
    expect(confirm.onPressed, isNull);
    expect(find.byKey(const ValueKey('fire-bolt-class-stats')), findsNothing);
    expect(tester.takeException(), isNull);
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
    final confirm = tester.widget<FantasyTextButton>(
      find.byKey(const ValueKey('fire-bolt-cast')),
    );
    expect(confirm.onPressed, isNull);
  });
}
