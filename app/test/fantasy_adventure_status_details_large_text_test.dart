import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_adventure_hud.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

const _spell = 'Schutz des uralten Sternenlichts';
const _conditions = [
  'liegend',
  'verängstigt',
  'geblendet',
  'vergiftet',
  'festgesetzt',
  'erschöpft',
];

HeroCharacter _hero() => HeroCharacter(
  id: 'adventure-large-status',
  name: 'Elowen',
  hitPoints: 8,
  maxHitPoints: 16,
  armorClass: 14,
  speed: 9,
  temporaryHitPoints: 5,
  conditions: _conditions,
  concentratingOn: _spell,
);

Widget _screen(HeroCharacter hero, {double scale = 1}) => MaterialApp(
  theme: buildFantasyTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(
    body: ListView(children: [FantasyAdventureStatusHud(hero: hero)]),
  ),
);

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets('200 %: alle bestätigten Statusdetails bei $width dp', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final hero = _hero();
      final saved = hero.toJson();

      await tester.pumpWidget(_screen(hero, scale: 2));
      await tester.pumpAndSettle();

      final details = find.byKey(const ValueKey('adventure-status-details'));
      final label = tester.widget<Text>(details);
      expect(label.maxLines, isNull);
      expect(label.overflow, TextOverflow.visible);
      expect(label.data, contains('+5 temporäre TP'));
      expect(label.data, contains('Zustände:'));
      for (final condition in _conditions) {
        expect(label.data, contains(condition));
      }
      expect(label.data, contains('Konzentration: $_spell'));
      expect(tester.takeException(), isNull);
      expect(hero.toJson(), saved);
    });
  }

  testWidgets('Standardansicht bleibt mit maximal drei Zeilen kompakt', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_screen(_hero()));
    await tester.pumpAndSettle();

    final label = tester.widget<Text>(
      find.byKey(const ValueKey('adventure-status-details')),
    );
    expect(label.maxLines, 3);
    expect(label.overflow, TextOverflow.ellipsis);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ohne bestätigte Details keine künstliche Statuszeile', (
    tester,
  ) async {
    final hero = HeroCharacter(id: 'historical', name: 'Unbekannt');
    final saved = hero.toJson();
    await tester.pumpWidget(_screen(hero, scale: 2));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('adventure-status-details')),
      findsNothing,
    );
    expect(hero.toJson(), saved);
    expect(tester.takeException(), isNull);
  });
}
