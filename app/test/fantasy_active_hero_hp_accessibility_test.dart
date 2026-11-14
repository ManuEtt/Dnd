import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_campaign_dashboard.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

Future<void> _showCard(WidgetTester tester, HeroCharacter hero) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFantasyTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: Scaffold(
        body: ListView(
          children: [
            FantasyActiveHeroCard(
              hero: hero,
              campaignName: 'Die Nebel der Rabenwacht',
              onContinue: () {},
              onHeroes: () {},
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets(
      'Trefferpunkte bei $width dp, 200 % und IME nur einmal vorlesen',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = const FakeViewPadding(bottom: 220);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        final semantics = tester.ensureSemantics();

        final hero = HeroCharacter(
          id: 'hp-accessibility-confirmed',
          name: 'Elowen',
          level: 3,
          hitPoints: 12,
          maxHitPoints: 24,
        );
        final original = hero.toJson();

        await _showCard(tester, hero);

        expect(find.text('12 / 24'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Trefferpunkte: 12 von 24'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(RegExp(r'^Trefferpunkte:')),
          findsOneWidget,
        );
        final bar = find.byType(LinearProgressIndicator);
        expect(bar, findsOneWidget);
        expect(
          find.ancestor(of: bar, matching: find.byType(ExcludeSemantics)),
          findsOneWidget,
        );
        expect(hero.toJson(), original);
        expect(tester.takeException(), isNull);
    semantics.dispose();
      },
    );
  }

  testWidgets('Unbestätigte TP erzeugen keinen scheinbar gültigen Balken', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final hero = HeroCharacter(
      id: 'hp-accessibility-unknown',
      name: 'Unbekannte Heldin',
      level: 1,
      hitPoints: 12,
    );
    final original = hero.toJson();

    await _showCard(tester, hero);

    expect(find.text('? / ?'), findsOneWidget);
    expect(find.text('Trefferpunkte noch nicht bestätigt'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Trefferpunkte: nicht bestätigt'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp(r'^Trefferpunkte:')), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(hero.toJson(), original);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('Neuer Heldensnapshot aktualisiert die einzige TP-Ansage', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final heroBefore = HeroCharacter(
      id: 'hp-accessibility-rebuild',
      name: 'Arescan',
      level: 1,
      hitPoints: 20,
      maxHitPoints: 20,
    );
    final heroAfter = HeroCharacter(
      id: 'hp-accessibility-rebuild',
      name: 'Arescan',
      level: 1,
      hitPoints: 0,
      maxHitPoints: 20,
    );
    final beforeJson = heroBefore.toJson();
    final afterJson = heroAfter.toJson();

    await _showCard(tester, heroBefore);
    expect(find.bySemanticsLabel('Trefferpunkte: 20 von 20'), findsOneWidget);

    await _showCard(tester, heroAfter);

    expect(find.text('0 / 20'), findsOneWidget);
    expect(find.bySemanticsLabel('Trefferpunkte: 0 von 20'), findsOneWidget);
    expect(find.bySemanticsLabel('Trefferpunkte: 20 von 20'), findsNothing);
    expect(find.bySemanticsLabel(RegExp(r'^Trefferpunkte:')), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(heroBefore.toJson(), beforeJson);
    expect(heroAfter.toJson(), afterJson);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
