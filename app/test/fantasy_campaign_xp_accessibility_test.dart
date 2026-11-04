import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_campaign_dashboard.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

Future<void> _showHero(
  WidgetTester tester, {
  required double width,
  required HeroCharacter hero,
  required VoidCallback? onContinue,
  required VoidCallback onHeroes,
}) async {
  tester.view.physicalSize = Size(width, 760);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = const FakeViewPadding(bottom: 220);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);

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
              onContinue: onContinue,
              onHeroes: onHeroes,
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
      'Dashboard-XP bei $width dp / 200 % / IME hat eindeutige Semantik',
      (tester) async {
        final semantics = tester.ensureSemantics();
        var continued = 0;
        var managed = 0;
        final hero = HeroCharacter(
          id: 'dashboard-a11y-hero',
          name: 'Arescan der Sternensucher',
          level: 1,
          experience: 150,
          hitPoints: 9,
          maxHitPoints: 24,
          armorClass: 14,
          speed: 9,
        );
        final original = hero.toJson();
        await _showHero(
          tester,
          width: width,
          hero: hero,
          onContinue: () => continued++,
          onHeroes: () => managed++,
        );

        expect(find.text('Erfahrung: 150 / 300 EP'), findsOneWidget);
        expect(
          find.bySemanticsLabel('Erfahrungsfortschritt: 50 Prozent'),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(RegExp(r'Erfahrungsfortschritt:')),
          findsOneWidget,
        );
        expect(find.text('9 / 24'), findsOneWidget);
        expect(find.bySemanticsLabel('Trefferpunkte: 9 von 24'), findsOneWidget);
        expect(continued, 0);
        expect(managed, 0);

        final continueAction = find.byKey(
          const ValueKey('fantasy-hero-continue'),
        );
        await tester.ensureVisible(continueAction);
        await tester.pumpAndSettle();
        expect(continueAction.hitTestable(), findsOneWidget);
        await tester.tap(continueAction);
        expect(continued, 1);
        expect(managed, 0);
        expect(hero.toJson(), original);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }

  testWidgets('Unbestätigte Erfahrung erzeugt keinen Prozentwert', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var continued = 0;
    var managed = 0;
    final hero = HeroCharacter(
      id: 'dashboard-a11y-unknown',
      name: 'Unbekannte Heldin',
      level: 1,
    );
    final original = hero.toJson();
    await _showHero(
      tester,
      width: 320,
      hero: hero,
      onContinue: null,
      onHeroes: () => managed++,
    );
    expect(find.text('Erfahrungspunkte: nicht bestätigt'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'Erfahrungsfortschritt:')),
      findsNothing,
    );
    expect(find.text('? / ?'), findsOneWidget);
    final manageAction = find.byKey(const ValueKey('fantasy-hero-archive'));
    await tester.ensureVisible(manageAction);
    await tester.pumpAndSettle();
    expect(manageAction.hitTestable(), findsOneWidget);
    await tester.tap(manageAction);
    expect(managed, 1);
    expect(continued, 0);
    expect(hero.toJson(), original);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
