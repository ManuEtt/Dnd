import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/damage_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/character_effect_dialog.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

void main() {
  final hero = HeroCharacter(
    id: 'hero',
    name: 'Mira',
    hitPoints: 7,
    maxHitPoints: 12,
    temporaryHitPoints: 5,
  );

  Future<void> open(
    WidgetTester tester, {
    ValueChanged<CharacterEffectChoice?>? onResult,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFantasyTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await showDialog<CharacterEffectChoice>(
                  context: context,
                  builder: (_) => CharacterEffectDialog(hero: hero),
                );
                onResult?.call(result);
              },
              child: const Text('Effekt öffnen'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Effekt öffnen'));
    await tester.pumpAndSettle();
  }

  Finder control(String name) => find.byKey(ValueKey('character-effect-$name'));

  Future<void> tap(WidgetTester tester, String name) async {
    await tester.ensureVisible(control(name));
    await tester.pumpAndSettle();
    await tester.tap(control(name));
    await tester.pumpAndSettle();
  }

  Future<void> enter(WidgetTester tester, String name, String text) async {
    await tester.ensureVisible(control(name));
    await tester.enterText(control(name), text);
    await tester.pump();
  }

  Future<void> chooseKind(WidgetTester tester, String label) async {
    await tap(tester, 'kind');
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('Ungültige Quelle und Beträge verlassen die Bestätigung nicht', (
    tester,
  ) async {
    var returned = false;
    await open(tester, onResult: (_) => returned = true);
    await enter(tester, 'source', '   ');
    await tap(tester, 'confirm');
    expect(find.text('Bitte die bestätigte Quelle nennen.'), findsOneWidget);
    expect(
      find.text('Eine ganze Zahl von 1 bis 100000 eingeben.'),
      findsOneWidget,
    );
    expect(returned, isFalse);

    await enter(tester, 'source', 'x' * 201);
    await enter(tester, 'amount', '1');
    await tap(tester, 'confirm');
    expect(find.text('Höchstens 200 Zeichen verwenden.'), findsOneWidget);
    expect(returned, isFalse);

    await enter(tester, 'source', 'Bestätigte Falle');
    for (final invalid in ['0', '-1', '1.5', '100001']) {
      await enter(tester, 'amount', invalid);
      await tap(tester, 'confirm');
      expect(
        find.text('Eine ganze Zahl von 1 bis 100000 eingeben.'),
        findsOneWidget,
      );
      expect(returned, isFalse);
    }
  });

  testWidgets('Schaden gibt Quelle und unabhängige bestätigte Angaben zurück', (
    tester,
  ) async {
    CharacterEffectChoice? result;
    await open(tester, onResult: (value) => result = value);
    await enter(tester, 'source', '  Bestätigter Drachenangriff  ');
    await enter(tester, 'amount', '23');
    await tap(tester, 'damage-type');
    await tester.tap(find.text('Feuer').last);
    await tester.pumpAndSettle();
    for (final name in ['resistant', 'vulnerable', 'immune', 'critical']) {
      await tap(tester, name);
    }
    expect(find.textContaining('bereits alle gewürfelten'), findsOneWidget);
    await tap(tester, 'confirm');
    expect(result?.kind, CharacterEffectKind.damage);
    expect(result?.source, 'Bestätigter Drachenangriff');
    expect(result?.amount, 23);
    expect(result?.damageType, DamageType.fire);
    expect(result?.resistant, isTrue);
    expect(result?.vulnerable, isTrue);
    expect(result?.immune, isTrue);
    expect(result?.critical, isTrue);
    expect(result?.replaceTemporary, isFalse);
    expect(hero.hitPoints, 7);
    expect(hero.temporaryHitPoints, 5);
  });

  testWidgets('Heilung übernimmt keine zuvor gewählten Schadensoptionen', (
    tester,
  ) async {
    CharacterEffectChoice? result;
    await open(tester, onResult: (value) => result = value);
    await tap(tester, 'resistant');
    await tap(tester, 'critical');
    await chooseKind(tester, 'Heilung');
    expect(control('damage-type'), findsNothing);
    expect(control('critical'), findsNothing);
    expect(control('replace-temporary'), findsNothing);
    await enter(tester, 'source', 'Bestätigter Heiltrank');
    await enter(tester, 'amount', '100000');
    await tap(tester, 'confirm');
    expect(result?.kind, CharacterEffectKind.healing);
    expect(result?.amount, 100000);
    expect(result?.resistant, isFalse);
    expect(result?.critical, isFalse);
  });

  testWidgets(
    'Temporäre TP stapeln nicht und erfordern eine Ersetzentscheidung',
    (tester) async {
      CharacterEffectChoice? result;
      await open(tester, onResult: (value) => result = value);
      await chooseKind(tester, 'Temporäre TP');
      expect(control('damage-type'), findsNothing);
      expect(find.textContaining('niemals addiert'), findsOneWidget);
      expect(
        tester.widget<CheckboxListTile>(control('replace-temporary')).value,
        isFalse,
      );
      await enter(tester, 'source', 'Bestätigter Schutz');
      await enter(tester, 'amount', '3');
      await tap(tester, 'replace-temporary');
      await tap(tester, 'confirm');
      expect(result?.kind, CharacterEffectKind.temporaryHitPoints);
      expect(result?.amount, 3);
      expect(result?.replaceTemporary, isTrue);
      expect(hero.temporaryHitPoints, 5);
    },
  );

  testWidgets('Abbruch verwirft die Eingabe und erhält den Helden', (
    tester,
  ) async {
    CharacterEffectChoice? result;
    var returned = false;
    final before = hero.toJson();
    await open(
      tester,
      onResult: (value) {
        returned = true;
        result = value;
      },
    );
    await enter(tester, 'source', 'Nicht bestätigter Effekt');
    await enter(tester, 'amount', '9');
    await tap(tester, 'cancel');
    expect(returned, isTrue);
    expect(result, isNull);
    expect(hero.toJson(), before);
  });

  testWidgets('320 dp und große Schrift bleiben für jede Effektart bedienbar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(tester, textScale: 1.8);
    for (final label in ['Schaden', 'Heilung', 'Temporäre TP']) {
      await chooseKind(tester, label);
      await tap(tester, 'confirm');
      expect(tester.takeException(), isNull);
      expect(control('confirm').hitTestable(), findsOneWidget);
    }
    await tap(tester, 'cancel');
    expect(find.byType(CharacterEffectDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
