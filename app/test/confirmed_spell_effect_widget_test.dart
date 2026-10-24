import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/confirmed_spell_effects.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/confirmed_spell_effect_dialog.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_effect_ward.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

HeroCharacter heroWithEffects() => HeroCharacter(
  id: 'hero',
  name: 'Liora',
  spells: const ['Segen', 'Magische Rüstung'],
  concentratingOn: 'Segen',
  confirmedSpellEffects: [
    ConfirmedSpellEffect(
      id: 'spell-one',
      spellName: 'Segen',
      source: 'Geprüfter Zauber',
      concentrationBound: true,
      expiresInEncounterId: 'battle',
      expiresAtOwnTurnEndRound: 6,
    ),
  ],
);

Encounter fight({String id = 'battle'}) => Encounter(
  id: id,
  enemyName: 'Wächter',
  enemyHitPoints: 15,
  enemyMaxHitPoints: 15,
  round: 3,
);

void main() {
  Future<void> openDialog(WidgetTester tester, {Encounter? encounter}) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<ConfirmedSpellEffectChoice>(
                context: context,
                builder: (_) => ConfirmedSpellEffectDialog(
                  hero: heroWithEffects(),
                  encounter: encounter,
                ),
              ),
              child: const Text('Öffnen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Öffnen'));
    await tester.pumpAndSettle();
  }

  testWidgets('Zuglaufzeiten erscheinen nur beim aktiven eigenen Zug', (
    tester,
  ) async {
    await openDialog(tester, encounter: fight());
    await tester.tap(find.byKey(const ValueKey('spell-effect-duration')));
    await tester.pumpAndSettle();
    expect(find.text('Nach 10 eigenen Zugenden'), findsWidgets);
    expect(find.text('Nach 3 eigenen Zugenden'), findsWidgets);
    await tester.tap(find.text('Nach 3 eigenen Zugenden').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('spell-effect-source')),
      'Geprüfter Wirkungsbeleg',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('ohne eigene Runde keine Zuglaufzeit, Abbruch ohne Änderung', (
    tester,
  ) async {
    await openDialog(tester);
    await tester.tap(find.byKey(const ValueKey('spell-effect-duration')));
    await tester.pumpAndSettle();
    expect(find.text('Nach 10 eigenen Zugenden'), findsNothing);
    await tester.tap(find.text('Nur ausdrückliche Beendigung').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('spell-effect-confirm')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('spell-effect-error')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('spell-effect-cancel')));
    await tester.pumpAndSettle();
    expect(find.byType(ConfirmedSpellEffectDialog), findsNothing);
  });

  testWidgets('vorhandene bestätigte Quelle ist einzeln entfernbar', (
    tester,
  ) async {
    await openDialog(tester, encounter: fight());
    await tester.tap(find.byKey(const ValueKey('spell-effect-remove-mode')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('spell-effect-existing')), findsOneWidget);
    expect(find.textContaining('Geprüfter Zauber'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('spell-effect-confirm')));
    await tester.pumpAndSettle();
    expect(find.byType(ConfirmedSpellEffectDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 360.0, 960.0]) {
    testWidgets(
      'Fantasy-Zauberkarte bei $width dp zeigt Quelle und echten Restzähler',
      (tester) async {
        tester.view.physicalSize = Size(width, 1300);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var managed = 0;
        final hero = heroWithEffects();
        final before = hero.toJson();
        await tester.pumpWidget(
          MaterialApp(
            theme: buildFantasyTheme(),
            home: Scaffold(
              body: ListView(
                children: [
                  FantasyEffectWard(
                    hero: hero,
                    encounter: fight(),
                    expandDetailsInitially: true,
                    onManageSpells: () => managed++,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('ward-spell-effect-spell-one')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('spell-effect-source-spell-one')),
          findsOneWidget,
        );
        expect(find.textContaining('noch 4 eigene Zugenden'), findsOneWidget);
        await tester.ensureVisible(
          find.byKey(const ValueKey('ward-manage-spell-effects')),
        );
        await tester.tap(
          find.byKey(const ValueKey('ward-manage-spell-effects')),
        );
        expect(managed, 1);
        expect(hero.toJson(), before);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Zauberfremde Begegnung zeigt keinen errechneten Countdown', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFantasyTheme(),
        home: Scaffold(
          body: ListView(
            children: [
              FantasyEffectWard(
                hero: heroWithEffects(),
                encounter: fight(id: 'other'),
                expandDetailsInitially: true,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('andere Begegnung'), findsOneWidget);
    expect(find.textContaining('noch 4 eigene Zugenden'), findsNothing);
  });
}
