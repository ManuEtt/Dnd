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
}
