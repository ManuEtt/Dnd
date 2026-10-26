import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_combatant_card.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

void main() {
  for (final width in [320.0, 360.0, 960.0]) {
    testWidgets('Kampfkarten bleiben bei $width dp lesbar', (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildFantasyTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: const [
                  FantasyCombatantCard(
                    key: ValueKey('hero'),
                    name: 'Elowen',
                    isHero: true,
                    isActive: true,
                    initiative: 14,
                    hitPoints: 18,
                    maxHitPoints: 24,
                    armorClass: 16,
                    temporaryHitPoints: 3,
                  ),
                  SizedBox(height: 12),
                  FantasyCombatantCard(
                    key: ValueKey('enemy'),
                    name: 'Schattenläufer',
                    isHero: false,
                    isActive: false,
                    initiative: 11,
                    hitPoints: 9,
                    maxHitPoints: 18,
                    armorClass: 13,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('hero')), findsOneWidget);
      expect(find.byKey(const ValueKey('enemy')), findsOneWidget);
      expect(find.text('Elowen'), findsOneWidget);
      expect(find.text('Schattenläufer'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('combatant-active-turn')),
        findsOneWidget,
      );
      final hero = tester.widget<FantasyCombatantCard>(
        find.byKey(const ValueKey('hero')),
      );
      final enemy = tester.widget<FantasyCombatantCard>(
        find.byKey(const ValueKey('enemy')),
      );
      expect(hero.healthProgress, .75);
      expect(enemy.healthProgress, .5);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Unbestätigte Trefferpunkte bleiben ausdrücklich unbekannt', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFantasyTheme(),
        home: const Scaffold(
          body: FantasyCombatantCard(
            name: 'Unbekannter Gegner',
            isHero: false,
            isActive: true,
          ),
        ),
      ),
    );
    expect(
      find.text('Trefferpunkte nicht vollständig bestätigt'),
      findsOneWidget,
    );
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byKey(const ValueKey('combatant-active-turn')), findsOneWidget);
    expect(
      tester
          .widget<FantasyCombatantCard>(find.byType(FantasyCombatantCard))
          .healthProgress,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  test('Lebenspunkte-Balken begrenzt bestätigte Extremwerte', () {
    const defeated = FantasyCombatantCard(
      name: 'Gefallener',
      isHero: false,
      isActive: false,
      hitPoints: -4,
      maxHitPoints: 20,
    );
    const overHealed = FantasyCombatantCard(
      name: 'Held',
      isHero: true,
      isActive: false,
      hitPoints: 25,
      maxHitPoints: 20,
    );
    const missingMax = FantasyCombatantCard(
      name: 'Offen',
      isHero: true,
      isActive: false,
      hitPoints: 8,
      maxHitPoints: 0,
    );
    expect(defeated.healthProgress, 0);
    expect(overHealed.healthProgress, 1);
    expect(missingMax.healthProgress, isNull);
  });

  for (final width in [320.0, 360.0]) {
    testWidgets('Kampfteilnehmernamen bei $width dp und 200 % vollständig', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const heroName =
          'Elowen die unermüdliche Beschützerin des alten Nebelpasses';
      const enemyName =
          'Schattenwächter der verborgenen Festung hinter dem Gebirge';

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
            body: SingleChildScrollView(
              child: Column(
                children: const [
                  FantasyCombatantCard(
                    key: ValueKey('large-combat-hero'),
                    name: heroName,
                    isHero: true,
                    isActive: true,
                    initiative: 18,
                    hitPoints: 12,
                    maxHitPoints: 24,
                    armorClass: 16,
                    temporaryHitPoints: 3,
                  ),
                  FantasyCombatantCard(
                    key: ValueKey('large-combat-enemy'),
                    name: enemyName,
                    isHero: false,
                    isActive: false,
                    initiative: 9,
                    hitPoints: 8,
                    maxHitPoints: 20,
                    armorClass: 13,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final hero = find.byKey(const ValueKey('large-combat-hero'));
      final enemy = find.byKey(const ValueKey('large-combat-enemy'));
      final heroText = find.text(heroName);
      final enemyText = find.text(enemyName);
      expect(tester.widget<Text>(heroText).maxLines, isNull);
      expect(tester.widget<Text>(enemyText).maxLines, isNull);
      expect(tester.widget<Text>(heroText).overflow, TextOverflow.visible);
      expect(tester.widget<Text>(enemyText).overflow, TextOverflow.visible);
      final header = find.descendant(of: hero, matching: find.byType(Flex));
      expect(tester.widget<Flex>(header.first).direction, Axis.vertical);
      expect(
        tester
            .getTopLeft(find.byKey(const ValueKey('combatant-active-turn')))
            .dy,
        greaterThan(tester.getBottomLeft(heroText).dy),
      );
      expect(
        find.descendant(
          of: enemy,
          matching: find.byKey(const ValueKey('combatant-active-turn')),
        ),
        findsNothing,
      );
      expect(find.text('INI 18'), findsOneWidget);
      expect(find.text('RK 16'), findsOneWidget);
      expect(find.text('TP 12 / 24'), findsOneWidget);
      expect(find.text('TEMP 3'), findsOneWidget);
      expect(find.text('INI 9'), findsOneWidget);
      expect(find.text('TP 8 / 20'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('combatant-health-meter')),
        findsNWidgets(2),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('200 %: unbestätigte Werte werden nicht ersetzt', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFantasyTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: FantasyCombatantCard(
              name: 'Unbekannter Gegner des verlassenen Nordturms',
              isHero: false,
              isActive: false,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Trefferpunkte nicht vollständig bestätigt'),
      findsOneWidget,
    );
    expect(find.text('INI ?'), findsOneWidget);
    expect(find.text('RK ?'), findsOneWidget);
    expect(find.text('TP ? / ?'), findsOneWidget);
    expect(find.byKey(const ValueKey('combatant-health-meter')), findsNothing);
    expect(find.byKey(const ValueKey('combatant-active-turn')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Normale Schrift behält die kompakte Kopfzeile', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFantasyTheme(),
        home: const Scaffold(
          body: FantasyCombatantCard(
            name: 'Elowen von der Nebelwacht',
            isHero: true,
            isActive: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final text = tester.widget<Text>(find.text('Elowen von der Nebelwacht'));
    expect(text.maxLines, 2);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(
      tester.widget<Flex>(find.byType(Flex).first).direction,
      Axis.horizontal,
    );
    expect(tester.takeException(), isNull);
  });
  for (final width in [320.0, 360.0]) {
    testWidgets('Kampfteilnehmer bei $width dp und 200 % vollständig lesbar', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const heroName =
          'Elowen die Wanderin aus den vergessenen Nebelbergen';
      const enemyName =
          'Schattenwächter der verlassenen Sternwarte';
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFantasyTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: const [
                  FantasyCombatantCard(
                    key: ValueKey('large-hero'),
                    name: heroName,
                    isHero: true,
                    isActive: true,
                    initiative: 18,
                    hitPoints: 12,
                    maxHitPoints: 24,
                    armorClass: 16,
                  ),
                  FantasyCombatantCard(
                    key: ValueKey('large-enemy'),
                    name: enemyName,
                    isHero: false,
                    isActive: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.text(heroName)).maxLines, isNull);
      expect(tester.widget<Text>(find.text(enemyName)).maxLines, isNull);
      expect(find.byKey(const ValueKey('combatant-active-turn')), findsOneWidget);
      expect(find.textContaining('INI 18', findRichText: true), findsWidgets);
      expect(find.textContaining('RK 16', findRichText: true), findsWidgets);
      expect(find.textContaining('TP 12 / 24', findRichText: true), findsWidgets);
      expect(find.text('Trefferpunkte nicht vollständig bestätigt'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

}
