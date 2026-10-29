import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_background_package.dart';
import 'package:lebendiger_spielleiter/domain/starting_class_choice.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';
import 'package:lebendiger_spielleiter/ui/tool_proficiency_panel.dart';

Finder _key(String value) => find.byKey(ValueKey(value));

HeroCharacter _monk({String tool = 'item-lute'}) => HeroCharacter(
  id: 'tool-hero',
  name: 'Liora',
  className: 'Mönch',
  level: 5,
  abilities: const {
    'strength': 14,
    'dexterity': 16,
    'constitution': 12,
    'intelligence': 10,
    'wisdom': 12,
    'charisma': 14,
  },
  skills: const ['Athletik', 'Heimlichkeit'],
  savingThrowProficiencies: const ['strength', 'dexterity'],
  gold: 50,
  startingClassChoice: StartingClassChoice.confirmed(
    className: 'Mönch',
    skills: const ['Athletik', 'Heimlichkeit'],
    kitIndex: 1,
    toolProficiencyCatalogId: tool,
  ),
);

Future<void> _open(
  WidgetTester tester,
  HeroCharacter hero, {
  bool largeTextWithKeyboard = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFantasyTheme(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(largeTextWithKeyboard ? 2 : 1),
          viewInsets: EdgeInsets.only(bottom: largeTextWithKeyboard ? 200 : 0),
        ),
        child: child!,
      ),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ToolProficiencyPanel(hero: hero),
          ),
        ),
      ),
    ),
  );
  if (_key('tool-proficiency-ability').evaluate().isEmpty &&
      _key('tool-proficiency-empty').evaluate().isEmpty) {
    await tester.tap(find.text('Werkzeugübungen'));
    await tester.pumpAndSettle();
  }
}

Future<void> _chooseAbility(WidgetTester tester, String label) async {
  final selector = _key('tool-proficiency-ability');
  await tester.ensureVisible(selector);
  await tester.pumpAndSettle();
  await tester.tap(selector);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(label).last);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

Future<void> _chooseSkill(WidgetTester tester, String label) async {
  final selector = _key('tool-proficiency-relevant-skill');
  await tester.ensureVisible(selector);
  await tester.pumpAndSettle();
  await tester.tap(selector);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(label).last);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

List<String?> _skillOptions(WidgetTester tester) => tester
    .widget<DropdownButton<String>>(
      find.descendant(
        of: _key('tool-proficiency-relevant-skill'),
        matching: find.byWidgetPredicate(
          (widget) => widget is DropdownButton<String>,
        ),
      ),
    )
    .items!
    .map((item) => item.value)
    .toList();

void main() {
  testWidgets(
    'Goldpaket zeigt erlernte Übung ohne Besitz oder Attribut-Vorauswahl',
    (tester) async {
      final hero = _monk();
      final before = jsonEncode(hero.toJson());
      await _open(tester, hero);
      expect(find.text('Laute'), findsOneWidget);
      expect(find.text('Übungsbonus +3'), findsOneWidget);
      final field = _key('tool-proficiency-ability');
      expect(tester.state<FormFieldState<String>>(field).value, isNull);
      final dropdown = tester.widget<DropdownButton<String>>(
        find.descendant(
          of: field,
          matching: find.byWidgetPredicate(
            (widget) => widget is DropdownButton<String>,
          ),
        ),
      );
      expect(dropdown.items!.map((entry) => entry.value), abilityNames);
      expect(_key('tool-proficiency-preview-item-lute'), findsNothing);
      await _chooseAbility(tester, 'Charisma');
      expect(find.text('Charisma: +5 · Normalwurf'), findsOneWidget);
      expect(find.textContaining('löst keinen Wurf aus'), findsOneWidget);
      expect(hero.inventory, isEmpty);
      expect(hero.gold, 50);
      expect(jsonEncode(hero.toJson()), before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Unbestätigtes Attribut erhält keinen geschätzten Bonus', (
    tester,
  ) async {
    final initial = _monk();
    final hero = initial.copyWith(
      abilities: {...initial.abilities, 'charisma': null},
    );
    final before = jsonEncode(hero.toJson());
    await _open(tester, hero);
    await _chooseAbility(tester, 'Charisma');
    expect(
      find.text('Für Charisma ist kein Attributswert bestätigt.'),
      findsOneWidget,
    );
    expect(find.text('Charisma: +3 · Normalwurf'), findsNothing);
    expect(jsonEncode(hero.toJson()), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Nur ausdrücklich gewählte geübte SRD-Fertigkeit gibt Vorteil', (
    tester,
  ) async {
    final initial = _monk();
    final hero = initial.copyWith(
      skills: [...initial.skills, 'Auftreten', 'Erfundene Kunst'],
    );
    final before = jsonEncode(hero.toJson());
    await _open(tester, hero);
    final field = _key('tool-proficiency-relevant-skill');
    expect(tester.state<FormFieldState<String>>(field).value, '');
    expect(_skillOptions(tester), [
      '',
      'Athletik',
      'Auftreten',
      'Heimlichkeit',
    ]);
    await _chooseAbility(tester, 'Charisma');
    expect(find.text('Charisma: +5 · Normalwurf'), findsOneWidget);
    await _chooseSkill(tester, 'Auftreten');
    expect(find.text('Charisma: +5 · Vorteil'), findsOneWidget);
    await _chooseSkill(tester, 'Keine Fertigkeit bestätigen');
    expect(find.text('Charisma: +5 · Normalwurf'), findsOneWidget);
    expect(jsonEncode(hero.toJson()), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Bestätigte Fertigkeit hebt Gift-Nachteil auf, nicht den Bonus an',
    (tester) async {
      final initial = _monk();
      final hero = initial.copyWith(
        skills: [...initial.skills, 'Auftreten'],
        conditions: const ['vergiftet'],
      );
      final before = jsonEncode(hero.toJson());
      await _open(tester, hero);
      await _chooseAbility(tester, 'Charisma');
      expect(find.text('Charisma: +5 · Nachteil'), findsOneWidget);
      await _chooseSkill(tester, 'Auftreten');
      expect(find.text('Charisma: +5 · Normalwurf'), findsOneWidget);
      await _chooseSkill(tester, 'Keine Fertigkeit bestätigen');
      expect(find.text('Charisma: +5 · Nachteil'), findsOneWidget);
      expect(jsonEncode(hero.toJson()), before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Entfernte Fertigkeit setzt Feld und Vorschauvorteil zurück', (
    tester,
  ) async {
    final initial = _monk();
    final hero = initial.copyWith(skills: [...initial.skills, 'Auftreten']);
    await _open(tester, hero);
    await _chooseAbility(tester, 'Charisma');
    await _chooseSkill(tester, 'Auftreten');
    final oldField = tester.state<FormFieldState<String>>(
      _key('tool-proficiency-relevant-skill'),
    );
    expect(find.text('Charisma: +5 · Vorteil'), findsOneWidget);
    await _open(tester, initial);
    final field = _key('tool-proficiency-relevant-skill');
    expect(tester.state<FormFieldState<String>>(field), isNot(same(oldField)));
    expect(tester.state<FormFieldState<String>>(field).value, '');
    expect(_skillOptions(tester), isNot(contains('Auftreten')));
    expect(find.text('Charisma: +5 · Normalwurf'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Historisches Medizin wird nur als geübtes Heilkunde angeboten', (
    tester,
  ) async {
    final initial = _monk();
    final hero = initial.copyWith(skills: [...initial.skills, 'Medizin']);
    final before = jsonEncode(hero.toJson());
    await _open(tester, hero);
    expect(_skillOptions(tester), [
      '',
      'Athletik',
      'Heilkunde',
      'Heimlichkeit',
    ]);
    await _chooseAbility(tester, 'Weisheit');
    await _chooseSkill(tester, 'Heilkunde');
    expect(find.text('Weisheit: +4 · Vorteil'), findsOneWidget);
    expect(hero.skills, contains('Medizin'));
    expect(hero.skills, isNot(contains('Heilkunde')));
    expect(jsonEncode(hero.toJson()), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Vorschau verwendet Übung, Erschöpfung und Zustände aus Regeln', (
    tester,
  ) async {
    final hero = _monk().copyWith(
      exhaustionLevel: 1,
      conditions: const ['vergiftet'],
    );
    final before = jsonEncode(hero.toJson());
    await _open(tester, hero);
    await _chooseAbility(tester, 'Charisma');
    expect(find.text('Charisma: +3 · Nachteil'), findsOneWidget);
    expect(jsonEncode(hero.toJson()), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mönch 1 / Schurke 7 zeigt natürlichen Werkzeug-Mindestwurf', (
    tester,
  ) async {
    final initial = _monk();
    final hero = initial.copyWith(
      level: 8,
      secondaryClassName: 'Schurke',
      secondaryClassLevel: 7,
      abilities: {...initial.abilities, 'wisdom': 14},
    );
    final before = jsonEncode(hero.toJson());
    await _open(tester, hero);
    await _chooseAbility(tester, 'Charisma');
    expect(
      find.text('Charisma: +5 · Normalwurf · Natürlicher W20 mindestens 10'),
      findsOneWidget,
    );
    expect(jsonEncode(hero.toJson()), before);
    expect(tester.takeException(), isNull);
  });

  for (final version in [1, 2]) {
    testWidgets(
      'Historische Version $version und Freitext erfinden keine Übung',
      (tester) async {
        final proof = StartingClassChoice.fromJson({
          'version': version,
          'className': 'Mönch',
          'skills': ['Athletik', 'Heimlichkeit'],
          'kitIndex': 1,
          'equipmentChoices': <String, String>{},
        });
        final hero = _monk().copyWith(
          startingClassChoice: proof,
          features: const ['Werkzeugübung: Laute'],
        );
        final before = jsonEncode(hero.toJson());
        await _open(tester, hero);
        expect(_key('tool-proficiency-empty'), findsOneWidget);
        expect(_key('tool-proficiency-ability'), findsNothing);
        expect(_key('tool-proficiency-item-item-lute'), findsNothing);
        expect(jsonEncode(hero.toJson()), before);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Gleiche Übung aus Klasse und Hintergrund erscheint nur einmal', (
    tester,
  ) async {
    final hero = _monk(tool: 'item-calligrapher-s-supplies').copyWith(
      background: 'Weiser',
      startingBackgroundPackage: SrdBackgroundPackageChoice(
        background: SrdBackground.sage,
        takeGold: true,
      ),
    );
    await _open(tester, hero);
    expect(
      _key('tool-proficiency-item-item-calligrapher-s-supplies'),
      findsOneWidget,
    );
    await _chooseAbility(tester, 'Intelligenz');
    expect(find.text('Intelligenz: +3 · Normalwurf'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Aktuelle Werte werden neu gelesen, anderer Held beginnt ohne Auswahl',
    (tester) async {
      final hero = _monk();
      await _open(tester, hero);
      await _chooseAbility(tester, 'Charisma');
      await _chooseSkill(tester, 'Athletik');
      await _open(
        tester,
        hero.copyWith(abilities: {...hero.abilities, 'charisma': 18}),
      );
      expect(find.text('Charisma: +7 · Vorteil'), findsOneWidget);
      await _open(tester, hero.copyWith(id: 'another-hero'));
      expect(
        tester
            .state<FormFieldState<String>>(_key('tool-proficiency-ability'))
            .value,
        isNull,
      );
      expect(
        tester
            .state<FormFieldState<String>>(
              _key('tool-proficiency-relevant-skill'),
            )
            .value,
        '',
      );
      expect(_key('tool-proficiency-preview-item-lute'), findsNothing);
    },
  );

  for (final width in [320.0, 360.0]) {
    testWidgets(
      'Werkzeugvorschau $width dp, 200 % Schrift und Tastatur erreichbar',
      (tester) async {
        tester.view.physicalSize = Size(width, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        try {
          final hero = _monk(tool: 'item-calligrapher-s-supplies');
          final before = jsonEncode(hero.toJson());
          await _open(tester, hero, largeTextWithKeyboard: true);
          final selector = _key('tool-proficiency-ability');
          await tester.ensureVisible(selector);
          await tester.pumpAndSettle();
          expect(selector.hitTestable(), findsOneWidget);
          expect(tester.getSize(selector).height, greaterThanOrEqualTo(48));
          await _chooseAbility(tester, 'Geschicklichkeit');
          final skill = _key('tool-proficiency-relevant-skill');
          await tester.ensureVisible(skill);
          await tester.pumpAndSettle();
          expect(skill.hitTestable(), findsOneWidget);
          expect(tester.getSize(skill).height, greaterThanOrEqualTo(48));
          await _chooseSkill(tester, 'Heimlichkeit');
          final preview = _key(
            'tool-proficiency-preview-item-calligrapher-s-supplies',
          );
          await tester.ensureVisible(preview);
          await tester.pumpAndSettle();
          expect(preview.hitTestable(), findsOneWidget);
          expect(find.text('Geschicklichkeit: +6 · Vorteil'), findsOneWidget);
          expect(
            tester.getSemantics(preview).label,
            contains('Geschicklichkeit'),
          );
          expect(jsonEncode(hero.toJson()), before);
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }
}
