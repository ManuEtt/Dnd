import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_campaign_dashboard.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
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
      expect(
        tester.widget<FantasyTextButton>(resume).style,
        FantasyButtonStyle.woodGold,
      );
      await tester.tap(resume);
      expect(continuations, 1);
      final archive = find.byKey(const ValueKey('fantasy-hero-archive'));
      await tester.ensureVisible(archive);
      await tester.pumpAndSettle();
      expect(
        tester.widget<FantasyTextButton>(archive).style,
        FantasyButtonStyle.iron,
      );
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
    final continueButton = tester.widget<FantasyTextButton>(
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

  for (final width in [320.0, 360.0]) {
    testWidgets('Aktive Heldenkarte bei $width dp und 200 % gut lesbar', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      var continued = 0;
      final hero = HeroCharacter(
        id: 'accessible-overview',
        name: 'Arescan',
        level: 3,
        hitPoints: 18,
        maxHitPoints: 24,
        armorClass: 16,
        speed: 9,
      );
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
                  campaignName: 'Nebelwacht',
                  onContinue: () => continued++,
                  onHeroes: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final keys = [
        const ValueKey('active-hero-metric-hp'),
        const ValueKey('active-hero-metric-ac'),
        const ValueKey('active-hero-metric-speed'),
      ];
      final positions = [
        for (final key in keys) tester.getTopLeft(find.byKey(key)),
      ];
      expect(positions[1].dx, closeTo(positions[0].dx, 1));
      expect(positions[2].dx, closeTo(positions[0].dx, 1));
      expect(positions[1].dy, greaterThan(positions[0].dy));
      expect(positions[2].dy, greaterThan(positions[1].dy));
      expect(find.text('18 / 24'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);
      expect(find.text('9 m'), findsOneWidget);
      expect(
        find.ancestor(
          of: find.text('18 / 24'),
          matching: find.byType(FittedBox),
        ),
        findsNothing,
      );
      expect(find.bySemanticsLabel('Trefferpunkte: 18 von 24'), findsOneWidget);
      expect(find.bySemanticsLabel('Rüstungsklasse: 16'), findsOneWidget);
      expect(find.bySemanticsLabel('Bewegung: 9 m'), findsOneWidget);

      final resume = find.byKey(const ValueKey('fantasy-hero-continue'));
      await tester.ensureVisible(resume);
      await tester.tap(resume);
      expect(continued, 1);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }

  testWidgets('Unbestätigte Kartenwerte sind bei 200 % kenntlich', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    final hero = HeroCharacter(
      id: 'unknown-overview',
      name: 'Unbekannter Held',
      level: 1,
    );
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
                campaignName: 'Unbestätigt',
                onContinue: null,
                onHeroes: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('? / ?'), findsOneWidget);
    expect(find.text('?'), findsNWidgets(2));
    for (final label in ['Trefferpunkte', 'Rüstungsklasse', 'Bewegung']) {
      expect(find.bySemanticsLabel('$label: nicht bestätigt'), findsOneWidget);
    }
    expect(
      tester
          .widget<FantasyTextButton>(
            find.byKey(const ValueKey('fantasy-hero-continue')),
          )
          .onPressed,
      isNull,
    );
    expect(find.text('Erfahrungspunkte: nicht bestätigt'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
