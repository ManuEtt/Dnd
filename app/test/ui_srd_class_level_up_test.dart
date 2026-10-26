import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/character_editor.dart';

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    250,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> openEditor(
  WidgetTester tester,
  HeroCharacter character,
  void Function(HeroCharacter?) save,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => FilledButton(
            onPressed: () async => save(
              await Navigator.push<HeroCharacter>(
                context,
                MaterialPageRoute(
                  builder: (_) => CharacterEditor(hero: character),
                ),
              ),
            ),
            child: const Text('Bearbeiten'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Bearbeiten'));
  await tester.pumpAndSettle();
}

HeroCharacter current({int xp = 300}) => HeroCharacter(
  id: 'levelup-ui',
  name: 'Tira',
  className: 'Kämpfer',
  level: 1,
  experience: xp,
  hitPoints: 8,
  maxHitPoints: 14,
  armorClass: 14,
  speed: 9,
  abilities: const {
    'strength': 14,
    'dexterity': 14,
    'constitution': 14,
    'intelligence': 10,
    'wisdom': 10,
    'charisma': 10,
  },
);

void main() {
  testWidgets(
    'Bestehende Klasse wird erst nach Vorschau und Speicherung erhöht',
    (tester) async {
      HeroCharacter? result;
      await openEditor(tester, current(), (value) => result = value);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('open-class-level-up')),
      );
      expect(find.text('Klasse um eine Stufe steigern'), findsOneWidget);
      expect(find.textContaining('Gesamtstufe 1 → 2'), findsOneWidget);
      expect(find.textContaining('feste +8 TP'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('levelup-confirm')));
      await tester.pumpAndSettle();
      // No user save yet; the editor still owns the changes.
      expect(result, isNull);
      await tapVisible(tester, find.text('Charakter speichern'));
      expect(result?.level, 2);
      expect(result?.maxHitPoints, 22);
      expect(result?.hitPoints, 16);
      expect(result?.experience, 300);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Zu wenige Erfahrungspunkte erfordern ausdrücklichen Meilenstein',
    (tester) async {
      HeroCharacter? result;
      await openEditor(tester, current(xp: 0), (value) => result = value);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('open-class-level-up')),
      );
      expect(find.byKey(const ValueKey('levelup-error')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('levelup-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Klasse um eine Stufe steigern'), findsOneWidget);
      await tester.tap(find.text('Meilenstein'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('levelup-confirm')));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Charakter speichern'));
      expect(result?.level, 2);
      expect(result?.experience, 0);
    },
  );

  testWidgets(
    'Mehrere EP-Aufstiege können vor dem Speichern bestätigt werden',
    (tester) async {
      HeroCharacter? result;
      await openEditor(tester, current(xp: 900), (value) => result = value);

      await tapVisible(
        tester,
        find.byKey(const ValueKey('open-class-level-up')),
      );
      expect(find.textContaining('Gesamtstufe 1 → 2'), findsOneWidget);
      expect(
        find.textContaining('2 Aufstiege mit EP verfügbar'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('levelup-hp-preview')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('levelup-proficiency-preview')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('levelup-confirm')));
      await tester.pumpAndSettle();

      // The second step stays bound to the first wizard-confirmed draft.
      await tapVisible(
        tester,
        find.byKey(const ValueKey('open-class-level-up')),
      );
      expect(find.textContaining('Gesamtstufe 2 → 3'), findsOneWidget);
      expect(
        find.textContaining('Ein Aufstieg mit bestätigten EP verfügbar'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('levelup-confirm')));
      await tester.pumpAndSettle();
      expect(result, isNull);

      await tapVisible(tester, find.text('Charakter speichern'));
      expect(result?.level, 3);
      expect(result?.primaryClassLevel, 3);
      expect(result?.experience, 900);
      expect(result?.hitPoints, 24);
      expect(result?.maxHitPoints, 30);
      expect(
        result?.unverifiedNotes.any(
          (note) => note.contains('Unterklasse wählen'),
        ),
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Abbrechen ändert keine bestätigten Trefferpunkte', (
    tester,
  ) async {
    HeroCharacter? result;
    await openEditor(tester, current(), (value) => result = value);
    await tapVisible(tester, find.byKey(const ValueKey('open-class-level-up')));
    await tester.tap(find.text('Abbrechen').last);
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Charakter speichern'));
    expect(result?.level, 1);
    expect(result?.maxHitPoints, 14);
    expect(result?.hitPoints, 8);
  });
  testWidgets('Stufe 20 zeigt automatische Barbar-Attribute vor Speicherung', (
    tester,
  ) async {
    HeroCharacter? result;
    final barbarian = current(
      xp: 355000,
    ).copyWith(className: 'Barbar', level: 19);
    await openEditor(tester, barbarian, (value) => result = value);
    await tapVisible(
      tester,
      find.byKey(const ValueKey('open-class-level-up')),
    );
    expect(
      find.textContaining('Automatisches Klassenmerkmal:'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('levelup-automatic-abilities')),
      findsOneWidget,
    );
    expect(result, isNull);
    await tester.tap(find.byKey(const ValueKey('levelup-confirm')));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Charakter speichern'));
    expect(result?.level, 20);
    expect(result?.abilities['strength'], 18);
    expect(result?.abilities['constitution'], 18);
    expect(result?.maxHitPoints, 14 + 49);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Höchststufe 20 verursacht keinen UI-Fehler', (tester) async {
    await openEditor(
      tester,
      current().copyWith(level: 20, experience: 355000),
      (_) {},
    );
    await tapVisible(tester, find.byKey(const ValueKey('open-class-level-up')));
    expect(find.textContaining('Höchststufe 20'), findsWidgets);
    expect(find.byKey(const ValueKey('levelup-error')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
