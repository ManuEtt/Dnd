import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/condition_effects.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_effect_ward.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

HeroCharacter _hero() => HeroCharacter(
  id: 'caster',
  name: 'Liora',
  hitPoints: 14,
  maxHitPoints: 20,
  speed: 9,
  concentratingOn: 'Schutzzauber',
  exhaustionLevel: 1,
  conditions: const ['vergiftet', 'liegend'],
  conditionEffects: [
    ConditionEffect(
      id: 'trap',
      condition: 'vergiftet',
      source: 'Giftfalle',
      expiresInEncounterId: 'battle',
      expiresAtOwnTurnEndRound: 4,
    ),
    ConditionEffect(
      id: 'curse',
      condition: 'vergiftet',
      source: 'Fluch',
    ),
  ],
);

Encounter _encounter({String id = 'battle'}) => Encounter(
  id: id,
  enemyName: 'Wolf',
  enemyHitPoints: 8,
  enemyMaxHitPoints: 8,
  round: 3,
);

Widget _page(
  HeroCharacter hero, {
  Encounter? encounter,
  VoidCallback? onManage,
  bool expanded = false,
}) => MaterialApp(
  theme: buildFantasyTheme(),
  home: Scaffold(
    body: ListView(
      children: [
        FantasyEffectWard(
          hero: hero,
          encounter: encounter,
          onManage: onManage,
          expandDetailsInitially: expanded,
        ),
      ],
    ),
  ),
);

void main() {
  for (final width in [320.0, 360.0, 960.0]) {
    testWidgets('Runenkarten bei $width dp ohne Überlauf', (tester) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        _page(_hero(), encounter: _encounter(), expanded: true),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ward-concentration')), findsOneWidget);
      expect(find.byKey(const ValueKey('ward-exhaustion')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('ward-condition-vergiftet')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('ward-condition-liegend')), findsOneWidget);
      expect(find.byKey(const ValueKey('source-effect-trap')), findsOneWidget);
      expect(find.byKey(const ValueKey('source-effect-curse')), findsOneWidget);
      expect(find.textContaining('Runde 4 (battle)'), findsOneWidget);
      expect(find.textContaining('noch 2 eigene Zugenden'), findsOneWidget);
      expect(find.textContaining('Wirkungsdauer ist nicht bestätigt'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Details öffnen sich erst nach Tipp; reine Anzeige', (
    tester,
  ) async {
    final hero = _hero();
    final before = hero.toJson();
    await tester.pumpWidget(_page(hero, encounter: _encounter()));
    expect(find.text('Konzentration'), findsOneWidget);
    expect(find.textContaining('Wirkungsdauer ist nicht bestätigt'), findsNothing);
    await tester.tap(find.text('Konzentration'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Wirkungsdauer ist nicht bestätigt'), findsOneWidget);
    expect(hero.toJson(), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Zustandsaktion ruft nur vorhandene Bestätigung auf', (
    tester,
  ) async {
    var opened = 0;
    await tester.pumpWidget(
      _page(_hero(), onManage: () => opened++),
    );
    await tester.tap(find.byKey(const ValueKey('ward-manage-effects')));
    expect(opened, 1);
    expect(find.text('Giftfalle'), findsNothing);
  });

  testWidgets('Fremde Kampfbegegnung erhält eigenen Zeitstempel', (
    tester,
  ) async {
    await tester.pumpWidget(
      _page(
        _hero(),
        encounter: _encounter(id: 'another-battle'),
        expanded: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('andere Begegnung'), findsOneWidget);
    expect(find.textContaining('noch 2 eigene Zugenden'), findsNothing);
    expect(find.textContaining('Bestätigte Kampfrunde: 3'), findsOneWidget);
  });

  testWidgets('Keine erfundenen Werte für alte leere Bögen', (
    tester,
  ) async {
    await tester.pumpWidget(
      _page(HeroCharacter(id: 'old', name: 'Alt')),
    );
    expect(find.text('Keine aktive Konzentration'), findsOneWidget);
    expect(
      find.text('Keine Zustände eingetragen.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('ward-exhaustion')), findsNothing);
    expect(find.byKey(const ValueKey('ward-manage-effects')), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Nach einem bestätigten Rundenwechsel sinkt Restzeit', (
    tester,
  ) async {
    final hero = _hero();
    await tester.pumpWidget(
      _page(hero, encounter: _encounter().copyWith(round: 4), expanded: true),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('noch 1 eigenes Zugende'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

}
