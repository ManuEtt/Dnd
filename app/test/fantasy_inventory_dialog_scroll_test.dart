import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_art.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets(
      'Lange Inventarnotiz bei $width dp und 2x Schrift bleibt schließbar',
      (tester) async {
        tester.view.physicalSize = Size(width, 520);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final description = List.filled(
          90,
          'Der Fund ist nur ein bestätigter Tagebucheintrag.',
        ).join(' ');
        final item = InventoryItem(
          id: 'long-note',
          name: 'Expeditionsbericht',
          quantity: 3,
          description: description,
        );
        final original = item.toJson();

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
                child: FantasyInventoryCards(items: [item]),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Expeditionsbericht'));
        await tester.pumpAndSettle();

        final dialog = tester.widget<AlertDialog>(
          find.byType(AlertDialog),
        );
        expect(dialog.scrollable, isTrue);
        expect(find.textContaining('Der Fund ist nur ein'), findsOneWidget);
        expect(find.text('Schließen').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Schließen'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        expect(item.toJson(), original);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Leere Inventarbeschreibung hat Fallback ohne Datenänderung', (
    tester,
  ) async {
    const item = InventoryItem(
      id: 'empty-note',
      name: 'Leerer Beutel',
      quantity: 1,
    );
    final original = item.toJson();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FantasyInventoryCards(items: [item]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Leerer Beutel'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Keine weitere Beschreibung gespeichert.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Schließen'));
    await tester.pumpAndSettle();

    expect(item.toJson(), original);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
