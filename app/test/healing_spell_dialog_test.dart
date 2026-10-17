import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';
import 'package:lebendiger_spielleiter/ui/healing_spell_dialog.dart';

HeroCharacter healer({String className = 'Kleriker', int level = 5}) =>
    HeroCharacter(
      id: 'healer',
      name: 'Mira',
      className: className,
      level: level,
      hitPoints: 7,
      maxHitPoints: 32,
      abilities: const {'wisdom': 16, 'charisma': 18},
      spells: const ['Wunden heilen', 'Heilendes Wort'],
    );

Finder control(String name) => find.byKey(ValueKey('healing-spell-$name'));

Future<void> open(
  WidgetTester tester,
  HeroCharacter hero, {
  ValueChanged<HealingSpellChoice?>? onResult,
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
              final result = await showDialog<HealingSpellChoice>(
                context: context,
                builder: (_) => HealingSpellDialog(hero: hero),
              );
              onResult?.call(result);
            },
            child: const Text('Heilzauber öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Heilzauber öffnen'));
  await tester.pumpAndSettle();
}

Future<void> tap(WidgetTester tester, String name) async {
  await tester.ensureVisible(control(name));
  await tester.pumpAndSettle();
  await tester.tap(control(name));
  await tester.pumpAndSettle();
}

Future<void> choose(WidgetTester tester, String name, String label) async {
  await tap(tester, name);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Auswahl bestätigt Selbstheilung ohne Wurf oder Ressourcenbuchung',
    (tester) async {
      final hero = healer().copyWith(spells: ['Cure Wounds', 'Healing Word']);
      final before = hero.toJson();
      HealingSpellChoice? result;
      await open(tester, hero, onResult: (choice) => result = choice);
      expect(find.text('Kosten im Kampf: Aktion (Magie).'), findsOneWidget);
      expect(find.text('Heilung: 2W8 + Weisheit (+3).'), findsOneWidget);
      expect(find.textContaining('durch Berührung'), findsOneWidget);
      expect(tester.widget<CheckboxListTile>(control('verbal')).value, isFalse);
      expect(
        tester.widget<CheckboxListTile>(control('somatic')).value,
        isFalse,
      );

      await tap(tester, 'verbal');
      await tap(tester, 'somatic');
      await tap(tester, 'confirm');

      expect(result?.spellName, 'Wunden heilen');
      expect(result?.castingClass, 'Kleriker');
      expect(result?.slotLevel, 1);
      expect(result?.pactMagic, isFalse);
      expect(result?.verbalComponentConfirmed, isTrue);
      expect(result?.somaticComponentConfirmed, isTrue);
      expect(hero.toJson(), before);
      expect(find.byType(HealingSpellDialog), findsNothing);
    },
  );

  testWidgets('Fehlende verbale und gestische Bestätigung hält Dialog offen', (
    tester,
  ) async {
    var returned = false;
    await open(tester, healer(), onResult: (_) => returned = true);
    await tap(tester, 'confirm');
    expect(
      find.text(
        'Bitte bestätigen, dass die verbalen Komponenten möglich sind.',
      ),
      findsOneWidget,
    );
    expect(returned, isFalse);
    await tap(tester, 'verbal');
    await tap(tester, 'confirm');
    expect(
      find.text(
        'Bitte bestätigen, dass die gestischen Komponenten möglich sind.',
      ),
      findsOneWidget,
    );
    expect(returned, isFalse);
  });

  testWidgets(
    'Heilendes Wort zeigt Bonusaktion, Sicht und ausschließlich verbal',
    (tester) async {
      HealingSpellChoice? result;
      await open(tester, healer(), onResult: (choice) => result = choice);
      await tap(tester, 'verbal');
      await tap(tester, 'somatic');
      await choose(tester, 'name', 'Heilendes Wort');
      expect(find.text('Kosten im Kampf: Bonusaktion.'), findsOneWidget);
      expect(find.text('Heilung: 2W4 + Weisheit (+3).'), findsOneWidget);
      expect(
        find.textContaining('Du musst dich selbst sehen können'),
        findsOneWidget,
      );
      expect(control('somatic'), findsNothing);
      expect(tester.widget<CheckboxListTile>(control('verbal')).value, isFalse);
      await tap(tester, 'verbal');
      await tap(tester, 'confirm');
      expect(result?.spellName, 'Heilendes Wort');
      expect(result?.verbalComponentConfirmed, isTrue);
      expect(result?.somaticComponentConfirmed, isFalse);
    },
  );

  testWidgets(
    'Höherer freier Platz ändert Vorschau und wird ausdrücklich gewählt',
    (tester) async {
      final hero = healer().copyWith(spentSpellSlots: {'1': 4, '3': 1});
      HealingSpellChoice? result;
      await open(tester, hero, onResult: (choice) => result = choice);
      final field = tester.widget<DropdownButtonFormField<String>>(
        control('slot'),
      );
      expect(field.initialValue, 'slot-2');
      await choose(tester, 'slot', 'Grad 3 · 1 frei');
      expect(find.text('Heilung: 6W8 + Weisheit (+3).'), findsOneWidget);
      expect(find.text('Verbrauch: 1 Zauberplatz Grad 3.'), findsOneWidget);
      await tap(tester, 'verbal');
      await tap(tester, 'somatic');
      await tap(tester, 'confirm');
      expect(result?.slotLevel, 3);
      expect(result?.pactMagic, isFalse);
      expect(hero.spentSpellSlots, {'1': 4, '3': 1});
    },
  );

  testWidgets(
    'Mehrklassenwahl zeigt das Attribut der ausgewählten Zauberklasse',
    (tester) async {
      final hero = healer(
        className: 'Barde',
        level: 3,
      ).copyWith(secondaryClassName: 'Kleriker', secondaryClassLevel: 1);
      HealingSpellChoice? result;
      await open(tester, hero, onResult: (choice) => result = choice);
      expect(find.text('Heilung: 2W8 + Charisma (+4).'), findsOneWidget);
      await choose(tester, 'class', 'Kleriker');
      expect(find.text('Heilung: 2W8 + Weisheit (+3).'), findsOneWidget);
      await tap(tester, 'verbal');
      await tap(tester, 'somatic');
      await tap(tester, 'confirm');
      expect(result?.castingClass, 'Kleriker');
    },
  );

  testWidgets('Zauberwechsel entfernt unzulässige Mehrklassenwahl', (
    tester,
  ) async {
    final hero = healer(
      className: 'Paladin',
      level: 3,
    ).copyWith(secondaryClassName: 'Barde', secondaryClassLevel: 1);
    HealingSpellChoice? result;
    await open(tester, hero, onResult: (choice) => result = choice);
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(control('class'))
          .initialValue,
      'Paladin',
    );
    await choose(tester, 'name', 'Heilendes Wort');
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(control('class'))
          .initialValue,
      'Barde',
    );
    await tap(tester, 'verbal');
    await tap(tester, 'confirm');
    expect(result?.castingClass, 'Barde');
    expect(result?.spellName, 'Heilendes Wort');
  });

  testWidgets(
    'Paktplatz wird mit fester Stufe angezeigt und getrennt ausgewählt',
    (tester) async {
      final hero = healer(
        className: 'Cleric',
        level: 6,
      ).copyWith(secondaryClassName: 'Warlock', secondaryClassLevel: 5);
      final before = hero.toJson();
      HealingSpellChoice? result;
      await open(tester, hero, onResult: (choice) => result = choice);
      await choose(tester, 'slot', 'Pakt Grad 3 · 2 frei');
      expect(find.text('Heilung: 6W8 + Weisheit (+3).'), findsOneWidget);
      expect(find.text('Verbrauch: 1 Paktmagieplatz Grad 3.'), findsOneWidget);
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(control('class'))
            .initialValue,
        'Kleriker',
      );
      await tap(tester, 'verbal');
      await tap(tester, 'somatic');
      await tap(tester, 'confirm');
      expect(result?.pactMagic, isTrue);
      expect(result?.slotLevel, isNull);
      expect(result?.castingClass, 'Kleriker');
      expect(hero.toJson(), before);
    },
  );

  testWidgets(
    'Lebensdomänenvorschau zeigt Bonus und Höchstwerte ohne Anwendung',
    (tester) async {
      final hero = healer(level: 17).copyWith(subclass: 'Life Domain');
      final before = hero.toJson();
      await open(tester, hero);
      expect(find.text('Jünger des Lebens: zusätzlich 3 TP.'), findsOneWidget);
      expect(
        find.text('Höchste Heilung: 22 TP durch Höchstwerte statt Würfelwurf.'),
        findsOneWidget,
      );
      expect(hero.toJson(), before);
    },
  );

  testWidgets(
    'Fehlende Vorbereitung oder falsche Klassenliste bietet keine Zauber',
    (tester) async {
      for (final hero in [
        healer().copyWith(spells: ['Segen']),
        healer(className: 'Magier'),
      ]) {
        await open(tester, hero);
        expect(
          find.textContaining('Kein unterstützter vorbereiteter Heilzauber'),
          findsOneWidget,
        );
        expect(control('name'), findsNothing);
        expect(
          tester.widget<FilledButton>(control('confirm')).onPressed,
          isNull,
        );
        await tap(tester, 'cancel');
      }
    },
  );

  testWidgets(
    'Verbrauchte Plätze werden nicht angeboten; ohne Platz kein Wirken',
    (tester) async {
      final hero = healer(level: 1).copyWith(spentSpellSlots: {'1': 2});
      await open(tester, hero);
      expect(control('slot'), findsNothing);
      expect(
        find.textContaining('Kein ausreichender freier Zauberplatz'),
        findsOneWidget,
      );
      expect(tester.widget<FilledButton>(control('confirm')).onPressed, isNull);
      expect(hero.spentSpellSlots, {'1': 2});
    },
  );

  testWidgets(
    'Unsichtbarkeit verhindert sichtpflichtiges Heilendes Wort im Dialog',
    (tester) async {
      var returned = false;
      await open(
        tester,
        healer().copyWith(conditions: ['unsichtbar']),
        onResult: (_) => returned = true,
      );
      await choose(tester, 'name', 'Heilendes Wort');
      await tap(tester, 'verbal');
      await tap(tester, 'confirm');
      expect(
        find.textContaining('Heilendes Wort benötigt Sicht auf dich selbst'),
        findsOneWidget,
      );
      expect(returned, isFalse);
    },
  );

  testWidgets('Abbruch verwirft Auswahl und Komponenten ohne Heldenänderung', (
    tester,
  ) async {
    final hero = healer();
    final before = hero.toJson();
    var returned = false;
    HealingSpellChoice? result;
    await open(
      tester,
      hero,
      onResult: (choice) {
        returned = true;
        result = choice;
      },
    );
    await choose(tester, 'slot', 'Grad 2 · 3 frei');
    await tap(tester, 'verbal');
    await tap(tester, 'cancel');
    expect(returned, isTrue);
    expect(result, isNull);
    expect(hero.toJson(), before);
  });

  testWidgets(
    '320 dp und Schrift 180 Prozent erlauben Auswahl und Bestätigung',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      HealingSpellChoice? result;
      await open(
        tester,
        healer(),
        textScale: 1.8,
        onResult: (choice) => result = choice,
      );
      await choose(tester, 'name', 'Heilendes Wort');
      await choose(tester, 'slot', 'Grad 2 · 3 frei');
      await tap(tester, 'verbal');
      await tap(tester, 'confirm');
      expect(result?.spellName, 'Heilendes Wort');
      expect(result?.slotLevel, 2);
      expect(tester.takeException(), isNull);
    },
  );
}
