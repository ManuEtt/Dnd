import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/saving_throw_class_actions.dart';
import 'package:lebendiger_spielleiter/ui/death_save_decision_panel.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets('Todesrettung bei $width dp: Wartezustand sperrt Aktionen', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      final hero = HeroCharacter(
        id: 'hero',
        name: 'Ayla',
        className: 'Mönch',
        level: 14,
        hitPoints: 0,
        maxHitPoints: 40,
      );
      final saved = hero.toJson();
      var accepts = 0;
      final rerolls = <SavingThrowRerollFeature>[];

      Widget page({required bool busy}) => MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: SingleChildScrollView(
            child: DeathSaveDecisionPanel(
              hero: hero,
              pending: const PendingDeathSave(originalNatural: 1, modifier: 5),
              busy: busy,
              onAccept: () => accepts++,
              onReroll: rerolls.add,
            ),
          ),
        ),
      );

      await tester.pumpWidget(page(busy: true));
      await tester.pumpAndSettle();
      final accept = find.byKey(const ValueKey('death-save-accept'));
      final focus = find.byKey(const ValueKey('death-save-reroll-focus'));
      expect(accept, findsOneWidget);
      expect(focus, findsOneWidget);
      expect(find.text('Entscheidung wird verarbeitet …'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Todesrettungswurf: Entscheidung wird verarbeitet. '
          'Weitere Eingaben sind gesperrt.',
        ),
        findsOneWidget,
      );
      expect(tester.widget<FantasyTextButton>(accept).onPressed, isNull);
      expect(tester.widget<FantasyTextButton>(focus).onPressed, isNull);
      await tester.tap(accept);
      await tester.tap(focus);
      await tester.pumpAndSettle();
      expect(accepts, 0);
      expect(rerolls, isEmpty);
      expect(hero.toJson(), saved);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(page(busy: false));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('death-save-busy-status')),
        findsNothing,
      );
      expect(
        find.bySemanticsLabel(
          'Todesrettungswurf: Entscheidung wird verarbeitet. '
          'Weitere Eingaben sind gesperrt.',
        ),
        findsNothing,
      );
      expect(tester.widget<FantasyTextButton>(accept).onPressed, isNotNull);
      expect(tester.widget<FantasyTextButton>(focus).onPressed, isNotNull);
      await tester.tap(focus);
      await tester.pumpAndSettle();
      expect(rerolls, [SavingThrowRerollFeature.disciplinedSurvivor]);
      expect(accepts, 0);
      expect(hero.toJson(), saved);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
}
