import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/saving_throw_class_actions.dart';
import 'package:lebendiger_spielleiter/ui/death_save_decision_panel.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';

void main() {
  const pending = PendingDeathSave(originalNatural: 1, modifier: 5);
  final monk = HeroCharacter(
    id: 'death-save-large-font',
    name: 'Ayla',
    className: 'Mönch',
    level: 14,
    hitPoints: 0,
    maxHitPoints: 40,
  );

  Future<void> mountPanel(
    WidgetTester tester, {
    required double width,
    required double textScale,
    required HeroCharacter hero,
    required bool busy,
    required VoidCallback onAccept,
    required ValueChanged<SavingThrowRerollFeature> onReroll,
    bool keyboardOpen = true,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    if (keyboardOpen) {
      tester.view.viewInsets = const FakeViewPadding(bottom: 270);
    }
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeathSaveDecisionPanel(
              hero: hero,
              pending: pending,
              busy: busy,
              onAccept: onAccept,
              onReroll: onReroll,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in [320.0, 360.0]) {
    testWidgets('Todesrettungsaktionen bei $width dp und 200 % untereinander', (
      tester,
    ) async {
      var accepts = 0;
      final rerolls = <SavingThrowRerollFeature>[];
      final originalHero = monk.toJson();
      await mountPanel(
        tester,
        width: width,
        textScale: 2,
        hero: monk,
        busy: false,
        onAccept: () => accepts++,
        onReroll: rerolls.add,
      );

      final accept = find.byKey(const ValueKey('death-save-accept'));
      final reroll = find.byKey(const ValueKey('death-save-reroll-focus'));
      expect(reroll, findsOneWidget);
      expect(
        tester.getTopLeft(reroll).dy,
        greaterThan(tester.getBottomLeft(accept).dy),
      );
      expect(
        tester.getSize(accept).width,
        closeTo(tester.getSize(reroll).width, 1),
      );

      await tester.ensureVisible(accept);
      await tester.pumpAndSettle();
      expect(accept.hitTestable(), findsOneWidget);
      await tester.tap(accept);
      await tester.ensureVisible(reroll);
      await tester.pumpAndSettle();
      expect(reroll.hitTestable(), findsOneWidget);
      await tester.tap(reroll);

      expect(accepts, 1);
      expect(rerolls, [SavingThrowRerollFeature.disciplinedSurvivor]);
      expect(monk.toJson(), originalHero);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Gesperrte Todesrettung bleibt bei großer Schrift gesperrt', (
    tester,
  ) async {
    var accepts = 0;
    final rerolls = <SavingThrowRerollFeature>[];
    await mountPanel(
      tester,
      width: 320,
      textScale: 2,
      hero: monk,
      busy: true,
      onAccept: () => accepts++,
      onReroll: rerolls.add,
    );
    final accept = find.byKey(const ValueKey('death-save-accept'));
    final reroll = find.byKey(const ValueKey('death-save-reroll-focus'));
    expect(tester.widget<FantasyTextButton>(accept).onPressed, isNull);
    expect(tester.widget<FantasyTextButton>(reroll).onPressed, isNull);
    await tester.ensureVisible(accept);
    await tester.pumpAndSettle();
    await tester.tap(accept);
    await tester.ensureVisible(reroll);
    await tester.pumpAndSettle();
    await tester.tap(reroll);
    expect(accepts, 0);
    expect(rerolls, isEmpty);
    expect(find.text('Entscheidung wird verarbeitet …'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ohne verfügbare Klassenwiederholung nur Wurf annehmen', (
    tester,
  ) async {
    final hero = HeroCharacter(
      id: 'no-reroll',
      name: 'Taris',
      className: 'Kämpfer',
      level: 1,
      hitPoints: 0,
      maxHitPoints: 12,
    );
    var accepts = 0;
    await mountPanel(
      tester,
      width: 320,
      textScale: 2,
      hero: hero,
      busy: false,
      onAccept: () => accepts++,
      onReroll: (_) => fail('Keine Wiederholung verfügbar'),
    );
    expect(find.byKey(const ValueKey('death-save-reroll-focus')), findsNothing);
    expect(
      find.byKey(const ValueKey('death-save-reroll-indomitable')),
      findsNothing,
    );
    final accept = find.byKey(const ValueKey('death-save-accept'));
    await tester.ensureVisible(accept);
    await tester.pumpAndSettle();
    await tester.tap(accept);
    expect(accepts, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bei normaler Schrift bleiben Aktionen in einer Zeile', (
    tester,
  ) async {
    await mountPanel(
      tester,
      width: 960,
      textScale: 1,
      hero: monk,
      busy: false,
      keyboardOpen: false,
      onAccept: () {},
      onReroll: (_) {},
    );
    final accept = find.byKey(const ValueKey('death-save-accept'));
    final reroll = find.byKey(const ValueKey('death-save-reroll-focus'));
    expect(
      tester.getTopLeft(accept).dy,
      closeTo(tester.getTopLeft(reroll).dy, 1),
    );
    expect(tester.takeException(), isNull);
  });
}
