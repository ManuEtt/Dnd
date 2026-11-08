import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/healing_spell_dialog.dart';

HeroCharacter _hero({
  String id = 'hero-one',
  String name = 'Mira',
  String className = 'Kleriker',
  int level = 5,
  List<String> spells = const ['Wunden heilen', 'Heilendes Wort'],
}) => HeroCharacter(
  id: id,
  name: name,
  className: className,
  level: level,
  hitPoints: 7,
  maxHitPoints: 32,
  abilities: const {'wisdom': 16, 'charisma': 18},
  spells: spells,
);

Finder _control(String field) => find.byKey(ValueKey('healing-spell-$field'));

Future<void> _open(
  WidgetTester tester,
  ValueNotifier<HeroCharacter> heroes,
  ValueNotifier<HealingSpellChoice?> result, {
  ValueNotifier<int>? redraw,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final choice = await showDialog<HealingSpellChoice>(
                context: context,
                builder: (_) => ValueListenableBuilder<HeroCharacter>(
                  valueListenable: heroes,
                  builder: (_, hero, __) => redraw == null
                      ? HealingSpellDialog(hero: hero)
                      : ValueListenableBuilder<int>(
                          valueListenable: redraw,
                          builder: (_, __, ___) =>
                              HealingSpellDialog(hero: hero),
                        ),
                ),
              );
              result.value = choice;
            },
            child: const Text('Öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Öffnen'));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String field) async {
  final target = _control(field);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String field, String option) async {
  await _tap(tester, field);
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

bool _canConfirm(WidgetTester tester) =>
    tester.widget<FantasyTextButton>(_control('confirm')).onPressed != null;

void main() {
  testWidgets('unverändertes Angebot behält Auswahl bei Parent-Rebuild', (
    tester,
  ) async {
    final initial = _hero();
    final original = initial.toJson();
    final heroes = ValueNotifier(initial);
    final result = ValueNotifier<HealingSpellChoice?>(null);
    final redraw = ValueNotifier(0);
    addTearDown(heroes.dispose);
    addTearDown(result.dispose);
    addTearDown(redraw.dispose);
    await _open(tester, heroes, result, redraw: redraw);
    await _choose(tester, 'slot', 'Grad 2 · 3 frei');
    await _tap(tester, 'verbal');
    await _tap(tester, 'somatic');

    redraw.value++;
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<DropdownButtonFormField<String>>(_control('slot'))
          .initialValue,
      'slot-2',
    );
    expect(find.text('Grad 2 · 3 frei'), findsOneWidget);
    expect(tester.widget<CheckboxListTile>(_control('verbal')).value, isTrue);
    expect(tester.widget<CheckboxListTile>(_control('somatic')).value, isTrue);
    await _tap(tester, 'confirm');
    expect(result.value?.slotLevel, 2);
    expect(result.value?.spellName, 'Wunden heilen');
    expect(initial.toJson(), original);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 360.0]) {
    testWidgets(
      'Live-Platzwechsel bei $width dp/200 %/IME setzt Zusagen zurück',
      (tester) async {
        tester.view.physicalSize = Size(width, 840);
        tester.view.devicePixelRatio = 1;
        tester.view.viewInsets = const FakeViewPadding(bottom: 220);
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final initial = _hero();
        final initialJson = initial.toJson();
        final heroes = ValueNotifier(initial);
        final result = ValueNotifier<HealingSpellChoice?>(null);
        addTearDown(heroes.dispose);
        addTearDown(result.dispose);
        await _open(tester, heroes, result);
        await _choose(tester, 'slot', 'Grad 3 · 2 frei');
        await _tap(tester, 'verbal');
        await _tap(tester, 'somatic');

        final changed = initial.copyWith(spentSpellSlots: {'3': 2});
        final changedJson = changed.toJson();
        heroes.value = changed;
        await tester.pumpAndSettle();

        expect(find.text('Grad 3 · 2 frei'), findsNothing);
        expect(find.text('Grad 1 · 4 frei'), findsOneWidget);
        expect(
          tester.widget<CheckboxListTile>(_control('verbal')).value,
          isFalse,
        );
        expect(
          tester.widget<CheckboxListTile>(_control('somatic')).value,
          isFalse,
        );
        await _tap(tester, 'confirm');
        expect(
          find.text(
            'Bitte bestätigen, dass die verbalen Komponenten möglich sind.',
          ),
          findsOneWidget,
        );
        expect(result.value, isNull);
        await _tap(tester, 'verbal');
        await _tap(tester, 'somatic');
        await _tap(tester, 'confirm');
        expect(result.value?.slotLevel, 1);
        expect(result.value?.pactMagic, isFalse);
        expect(initial.toJson(), initialJson);
        expect(changed.toJson(), changedJson);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Heldwechsel bei gleichem Dialog vererbt keine Zustimmung', (
    tester,
  ) async {
    final initial = _hero();
    final heroes = ValueNotifier(initial);
    final result = ValueNotifier<HealingSpellChoice?>(null);
    addTearDown(heroes.dispose);
    addTearDown(result.dispose);
    await _open(tester, heroes, result);
    await _tap(tester, 'verbal');
    await _tap(tester, 'somatic');

    final other = _hero(
      id: 'hero-two',
      name: 'Nela',
      className: 'Barde',
      spells: const ['Healing Word'],
    );
    final before = other.toJson();
    heroes.value = other;
    await tester.pumpAndSettle();

    expect(find.textContaining('Nela: 7 / 32 TP'), findsOneWidget);
    expect(find.text('Heilendes Wort'), findsOneWidget);
    expect(find.text('Wunden heilen'), findsNothing);
    expect(_control('somatic'), findsNothing);
    expect(tester.widget<CheckboxListTile>(_control('verbal')).value, isFalse);
    await _tap(tester, 'confirm');
    expect(
      find.text(
        'Bitte bestätigen, dass die verbalen Komponenten möglich sind.',
      ),
      findsOneWidget,
    );
    await _tap(tester, 'verbal');
    await _tap(tester, 'confirm');
    expect(result.value?.spellName, 'Heilendes Wort');
    expect(result.value?.castingClass, 'Barde');
    expect(result.value?.somaticComponentConfirmed, isFalse);
    expect(other.toJson(), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('entfernte Vorbereitung und leere Plätze sperren Bestätigung', (
    tester,
  ) async {
    final heroes = ValueNotifier(_hero());
    final result = ValueNotifier<HealingSpellChoice?>(null);
    addTearDown(heroes.dispose);
    addTearDown(result.dispose);
    await _open(tester, heroes, result);
    await _tap(tester, 'verbal');
    await _tap(tester, 'somatic');

    heroes.value = _hero(spells: const ['Segen']);
    await tester.pumpAndSettle();
    expect(_control('name'), findsNothing);
    expect(_canConfirm(tester), isFalse);

    heroes.value = _hero(level: 1).copyWith(spentSpellSlots: {'1': 2});
    await tester.pumpAndSettle();
    expect(_control('name'), findsOneWidget);
    expect(_control('slot'), findsNothing);
    expect(_canConfirm(tester), isFalse);
    expect(
      find.textContaining('Kein ausreichender freier Zauberplatz'),
      findsOneWidget,
    );
    await _tap(tester, 'cancel');
    expect(result.value, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'ungültiger Ressourcenstand heilt nicht und kann ersetzt werden',
    (tester) async {
      final heroes = ValueNotifier(_hero());
      final result = ValueNotifier<HealingSpellChoice?>(null);
      addTearDown(heroes.dispose);
      addTearDown(result.dispose);
      await _open(tester, heroes, result);

      heroes.value = _hero().copyWith(spentSpellSlots: {'1': 99});
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Bitte zuerst die Charakterdaten prüfen'),
        findsOneWidget,
      );
      expect(_canConfirm(tester), isFalse);
      expect(_control('slot'), findsNothing);

      final recovered = _hero().copyWith(spentSpellSlots: {'1': 4});
      heroes.value = recovered;
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Bitte zuerst die Charakterdaten prüfen'),
        findsNothing,
      );
      expect(_control('slot'), findsOneWidget);
      expect(
        tester.widget<CheckboxListTile>(_control('verbal')).value,
        isFalse,
      );
      await _tap(tester, 'cancel');
      expect(result.value, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
