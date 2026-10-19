import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_campaign_dashboard.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

void main() {
  for (final width in [320.0, 360.0, 960.0]) {
    testWidgets('Heldenübersicht bleibt bei $width dp bedienbar', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var continuations = 0;
      var heroOpens = 0;
      final hero = HeroCharacter(
        id: 'hero-overview',
        name: 'Elowen die Sternensucherin',
        species: 'Elf',
        className: 'Waldläufer',
        level: 3,
        hitPoints: 18,
        maxHitPoints: 24,
        armorClass: 16,
        speed: 9,
        experience: 950,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: buildFantasyTheme(),
          home: Scaffold(
            body: ListView(
              children: [
                FantasyActiveHeroCard(
                  hero: hero,
                  campaignName: 'Die Nebel der Rabenwacht',
                  onContinue: () => continuations++,
                  onHeroes: () => heroOpens++,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('fantasy-active-hero-card')),
        findsOneWidget,
      );
      expect(find.text('18 / 24'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);
      expect(find.text('9 m'), findsOneWidget);
      expect(find.textContaining('950'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final resume = find.byKey(const ValueKey('fantasy-hero-continue'));
      await tester.ensureVisible(resume);
      await tester.pumpAndSettle();
      await tester.tap(resume);
      expect(continuations, 1);
      final archive = find.byKey(const ValueKey('fantasy-hero-archive'));
      await tester.ensureVisible(archive);
      await tester.pumpAndSettle();
      await tester.tap(archive);
      expect(heroOpens, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Fehlende Charakterwerte bleiben unbekannt', (tester) async {
    final hero = HeroCharacter(
      id: 'missing',
      name: 'Unbestätigte Heldin',
      level: 1,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFantasyTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: FantasyActiveHeroCard(
              hero: hero,
              campaignName: 'Die Reise beginnt',
              onContinue: null,
              onHeroes: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('? / ?'), findsOneWidget);
    expect(find.text('Rüstungsklasse'), findsOneWidget);
    expect(find.text('Trefferpunkte noch nicht bestätigt'), findsOneWidget);
    expect(find.text('Erfahrungspunkte: nicht bestätigt'), findsOneWidget);
    final continueButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('fantasy-hero-continue')),
    );
    expect(continueButton.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bestätigte Erfahrung kann Stufenaufstieg anzeigen', (
    tester,
  ) async {
    final hero = HeroCharacter(
      id: 'advancing',
      name: 'Arescan',
      level: 1,
      experience: 300,
      hitPoints: 8,
      maxHitPoints: 8,
      armorClass: 14,
      speed: 9,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFantasyTheme(),
        home: Scaffold(
          body: ListView(
            children: [
              FantasyActiveHeroCard(
                hero: hero,
                campaignName: 'Waldlicht',
                onContinue: () {},
                onHeroes: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Stufenaufstieg möglich'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
