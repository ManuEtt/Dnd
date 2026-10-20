import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/acid_splash_dialog.dart';

HeroCharacter _mage({List<String> spells = const ['Säurespritzer']}) =>
    HeroCharacter(
      id: 'acid-test-hero',
      name: 'Aria',
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
      hitPoints: 25,
      maxHitPoints: 25,
    );

const _encounter = Encounter(
  id: 'enc-acid',
  enemyName: 'Wächter',
  enemyHitPoints: 25,
  enemyMaxHitPoints: 25,
);

void main() {
  testWidgets('Acid Splash cannot proceed without sphere and save facts', (
    tester,
  ) async {
    AcidSplashChoice? choice;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                choice = await showDialog<AcidSplashChoice>(
                  context: context,
                  builder: (_) =>
                      AcidSplashDialog(hero: _mage(), encounter: _encounter),
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
    expect(find.text('Säurespritzer wirken'), findsOneWidget);
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('acid-splash-only')),
          )
          .value,
      false,
    );
    await tester.tap(find.byKey(const ValueKey('acid-splash-cast')));
    await tester.pumpAndSettle();
    expect(find.textContaining('GES-Rettungswurfbonus'), findsWidgets);
    expect(choice, isNull);
  });

  testWidgets('Without known spell the cast action is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AcidSplashDialog(
            hero: _mage(spells: const []),
            encounter: _encounter,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Säurespritzer ist nicht vorbereitet.'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('acid-splash-cast')))
          .onPressed,
      isNull,
    );
  });
}
