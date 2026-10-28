import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_bard_font_of_inspiration.dart';
import 'package:lebendiger_spielleiter/ui/srd_bard_font_of_inspiration_dialog.dart';

HeroCharacter _bard() => HeroCharacter(
  id: 'font-dialog-bard',
  name: 'Lyra',
  className: 'Barde',
  level: 5,
  hitPoints: 30,
  maxHitPoints: 30,
  abilities: const {
    'strength': 10,
    'dexterity': 14,
    'constitution': 12,
    'intelligence': 10,
    'wisdom': 12,
    'charisma': 16,
  },
  spentClassResources: const {'bardicInspiration': 1},
);

void main() {
  for (final width in [320.0, 360.0]) {
    for (final confirm in [false, true]) {
      testWidgets('${width.toInt()} dp, 200 Prozent Schrift und Tastatur: '
          '${confirm ? 'Bestätigung' : 'Abbruch'} ohne Überlauf', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        try {
          final hero = _bard();
          final original = hero.toJson();
          SrdBardFontProposal? result;
          var returned = false;
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(2),
                  viewInsets: const EdgeInsets.only(bottom: 280),
                ),
                child: child!,
              ),
              home: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () async {
                      result = await showBardFontOfInspirationDialog(
                        context,
                        hero,
                      );
                      returned = true;
                    },
                    child: const Text('Öffnen'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Öffnen'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(hero.toJson(), original);
          expect(returned, isFalse);
          final action = confirm
              ? find.byKey(const ValueKey('bard-font-confirm'))
              : find.widgetWithText(TextButton, 'Abbrechen');
          await tester.ensureVisible(action);
          await tester.pumpAndSettle();
          expect(action.hitTestable(), findsOneWidget);
          expect(
            tester.getSemantics(action).getSemanticsData().label,
            contains(confirm ? 'Umwandlung bestätigen' : 'Abbrechen'),
          );
          await tester.tap(action);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(returned, isTrue);
          expect(hero.toJson(), original);
          if (confirm) {
            expect(result, isNotNull);
            final updated = result!.applyTo(hero);
            expect(updated.spentSpellSlots['1'], 1);
            expect(updated.spentClassResources['bardicInspiration'] ?? 0, 0);
          } else {
            expect(result, isNull);
          }
        } finally {
          semantics.dispose();
        }
      });
    }
  }
}
