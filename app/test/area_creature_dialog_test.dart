import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/area_creature_registration_dialog.dart';
import 'package:lebendiger_spielleiter/ui/acid_splash_dialog.dart';

HeroCharacter _mage() => HeroCharacter(
  id: 'mage',
  name: 'Aria',
  className: 'Magier',
  level: 5,
  spells: const ['Säurespritzer'],
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 16,
    'wisdom': 12,
    'charisma': 14,
  },
  hitPoints: 20,
  maxHitPoints: 20,
);

const _fight = Encounter(
  id: 'primary',
  enemyName: 'Hauptgegner',
  enemyHitPoints: 30,
  enemyMaxHitPoints: 30,
);

void main() {
  testWidgets('Registration must require confirmed identity and HP', (
    tester,
  ) async {
    TrackedAreaCreature? added;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                added = await showDialog<TrackedAreaCreature>(
                  context: context,
                  builder: (_) => const AreaCreatureRegistrationDialog(),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('area-creature-register')));
    await tester.pumpAndSettle();
    expect(added, isNull);
    expect(find.textContaining('Bitte alle Werte'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('area-creature-id')),
      'goblin-2',
    );
    await tester.enterText(
      find.byKey(const ValueKey('area-creature-name')),
      'Goblin',
    );
    await tester.enterText(find.byKey(const ValueKey('area-creature-hp')), '7');
    await tester.enterText(
      find.byKey(const ValueKey('area-creature-maxhp')),
      '7',
    );
    await tester.tap(find.byKey(const ValueKey('area-creature-confirmed')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('area-creature-register')));
    await tester.pumpAndSettle();
    expect(added?.id, 'goblin-2');
    expect(added?.hitPoints, 7);
  });

  testWidgets('Acid Splash additional targets start unchecked and unverified', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AcidSplashDialog(
            hero: _mage(),
            encounter: _fight,
            trackedAreaCreatures: const [
              TrackedAreaCreature(
                id: 'extra-1',
                name: 'Goblin',
                hitPoints: 7,
                maxHitPoints: 7,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final selected = tester.widget<CheckboxListTile>(
      find.byKey(const ValueKey('acid-extra-select-extra-1')),
    );
    expect(selected.value, false);
    expect(find.byKey(const ValueKey('acid-extra-save-extra-1')), findsNothing);
    await tester.ensureVisible(
      find.byKey(const ValueKey('acid-extra-select-extra-1')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('acid-extra-select-extra-1')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('acid-extra-save-extra-1')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('acid-splash-all-included')),
          )
          .value,
      false,
    );
  });
}
