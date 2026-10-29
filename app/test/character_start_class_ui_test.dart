import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_creation_audit.dart';
import 'package:lebendiger_spielleiter/ui/character_editor.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/srd_class_selection_dialog.dart';
import 'package:lebendiger_spielleiter/ui/srd_creation_audit_dialog.dart';

Finder _key(String value) => find.byKey(ValueKey(value));
const _rangerSkills = ['Wahrnehmung', 'Heimlichkeit', 'Überlebenskunst'];

Future<void> _tap(
  WidgetTester tester,
  Finder target, {
  double delta = 300,
}) async {
  await tester.scrollUntilVisible(
    target,
    delta,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _open(
  WidgetTester tester,
  HeroCharacter? original,
  void Function(HeroCharacter?) onResult,
) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFantasyTheme(),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => onResult(
              await Navigator.of(context).push<HeroCharacter>(
                MaterialPageRoute(
                  builder: (_) => CharacterEditor(hero: original),
                ),
              ),
            ),
            child: const Text('Editor öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Editor öffnen'));
  await tester.pumpAndSettle();
  if (original == null) {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Charaktername'),
      'Liora',
    );
    // The combined class-start gate requires an explicitly confirmed KO score.
    // These focused editor tests deliberately use the labelled house-rule path;
    // full SRD generation has independent ability-assignment regressions.
    final constitution = find.widgetWithText(TextFormField, 'Konstitution');
    await tester.scrollUntilVisible(
      constitution,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(constitution, '14');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await _tap(tester, _key('allow-manual-abilities'));
    await tester.scrollUntilVisible(
      _key('open-srd-class-selection'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
  }
}

Future<void> _chooseDropdown(
  WidgetTester tester,
  Finder dropdown,
  String option,
) async {
  final button = tester.widget<DropdownButton>(
    find.descendant(
      of: dropdown,
      matching: find.byWidgetPredicate((widget) => widget is DropdownButton),
    ),
  );
  final targetIndex = button.items!.indexWhere(
    (entry) => entry.child is Text && (entry.child as Text).data == option,
  );
  final currentIndex = button.items!.indexWhere(
    (entry) => entry.value == button.value,
  );
  await tester.ensureVisible(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  if (find.text(option).evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      find.text(option),
      targetIndex < currentIndex ? -120 : 120,
      scrollable: find.byType(Scrollable).last,
    );
  }
  final choice = find.text(option).last;
  await tester.ensureVisible(choice);
  await tester.tap(choice);
  await tester.pumpAndSettle();
}

Future<void> _ranger(
  WidgetTester tester, {
  bool chooseSkills = true,
  bool gold = false,
  bool equipment = false,
}) async {
  await _tap(tester, _key('open-srd-class-selection'));
  if (chooseSkills) {
    for (final skill in _rangerSkills) {
      final target = _key('srd-skill-$skill');
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }
  }
  final dialog = tester.widget<SrdClassSelectionDialog>(
    find.byType(SrdClassSelectionDialog),
  );
  if (gold || equipment || (dialog.isNewCharacter && dialog.allowEquipment)) {
    await _chooseDropdown(
      tester,
      _key('srd-equipment--1'),
      equipment ? 'A – Ausrüstung' : 'B – Startgold',
    );
  }
  await tester.ensureVisible(_key('srd-confirm-class'));
  await tester.pumpAndSettle();
  await tester.tap(_key('srd-confirm-class'));
  await tester.pumpAndSettle();
  expect(find.byType(SrdClassSelectionDialog), findsNothing);
  expect(tester.takeException(), isNull);
}

Future<void> _save(WidgetTester tester) async {
  await _tap(tester, find.text('Charakter speichern'));
}

void main() {
  testWidgets(
    'Bestätigte neue Klassenwahl erhält strukturierten Teilnachweis',
    (tester) async {
      HeroCharacter? saved;
      await _open(tester, null, (hero) => saved = hero);
      await _ranger(tester);
      expect(saved, isNull);
      await _tap(tester, _key('open-srd-creation-audit'));
      final audit = tester.widget<SrdCreationAuditDialog>(
        find.byType(SrdCreationAuditDialog),
      );
      expect(
        audit.steps.singleWhere((step) => step.id == 'class.selection').status,
        CreationStepStatus.confirmed,
      );
      expect(saved, isNull);
      await tester.tap(_key('close-srd-creation-audit'));
      await tester.pumpAndSettle();
      await _save(tester);
      expect(saved!.startingClassChoice!.className, 'Waldläufer');
      expect(saved!.startingClassChoice!.skills, _rangerSkills);
      expect(saved!.startingClassChoice!.kitIndex, 1);
      expect(saved!.startingClassChoice!.equipmentChoices, isEmpty);
      expect(saved!.savingThrowProficiencies, ['strength', 'dexterity']);
      expect(saved!.inventory, isEmpty);
      expect(saved!.gold, 150);
      expect(saved!.hitPoints, 12);
      expect(saved!.maxHitPoints, 12);
    },
  );

  testWidgets('Erneute Bestätigung erhält Goldpaket ohne doppelte Vergabe', (
    tester,
  ) async {
    HeroCharacter? saved;
    await _open(tester, null, (hero) => saved = hero);
    await _ranger(tester, gold: true);
    await _ranger(tester, chooseSkills: false);
    await _save(tester);
    expect(saved!.gold, 150);
    expect(saved!.inventory, isEmpty);
    expect(saved!.startingClassChoice!.kitIndex, 1);
    expect(saved!.startingClassChoice!.className, 'Waldläufer');
  });

  testWidgets('Ausrüstungspaket bleibt bei erneuter Klassenwahl einmalig', (
    tester,
  ) async {
    HeroCharacter? saved;
    await _open(tester, null, (hero) => saved = hero);
    await _ranger(tester, equipment: true);
    await _ranger(tester, chooseSkills: false);
    await _save(tester);
    expect(saved!.gold, 7);
    expect(saved!.startingClassChoice!.kitIndex, 0);
    expect(saved!.inventory, hasLength(8));
    expect(saved!.inventory.map((item) => item.id).toSet(), hasLength(8));
    expect(
      saved!.inventory
          .singleWhere((item) => item.catalogId == 'item-arrows-20')
          .quantity,
      1,
    );
  });

  testWidgets('Neue Fertigkeitswahl ersetzt die bisherige Klassenquelle', (
    tester,
  ) async {
    HeroCharacter? saved;
    await _open(tester, null, (hero) => saved = hero);
    await _ranger(tester);
    await _tap(tester, _key('open-srd-class-selection'));
    for (final skill in ['Heimlichkeit', 'Nachforschungen']) {
      final target = _key('srd-skill-$skill');
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(_key('srd-confirm-class'));
    await tester.tap(_key('srd-confirm-class'));
    await tester.pumpAndSettle();
    await _save(tester);
    const expected = ['Wahrnehmung', 'Überlebenskunst', 'Nachforschungen'];
    expect(saved!.skills, unorderedEquals(expected));
    expect(saved!.startingClassChoice!.skills, unorderedEquals(expected));
    expect(saved!.savingThrowProficiencies, ['strength', 'dexterity']);
  });

  testWidgets('Klassenwechsel im unbestätigten Dialog sammelt keine Übungen', (
    tester,
  ) async {
    HeroCharacter? saved;
    await _open(tester, null, (hero) => saved = hero);
    await _tap(tester, _key('open-srd-class-selection'));
    for (final skill in _rangerSkills) {
      await tester.ensureVisible(_key('srd-skill-$skill'));
      await tester.tap(_key('srd-skill-$skill'));
      await tester.pumpAndSettle();
    }
    // No source is committed while kit choice is missing.
    expect(
      tester.widget<FantasyButton>(_key('srd-confirm-class')).onPressed,
      isNull,
    );
    await _chooseDropdown(tester, _key('srd-class-Waldläufer'), 'Barbar');
    for (final skill in ['Athletik', 'Überlebenskunst']) {
      final target = _key('srd-skill-$skill');
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }
    await _chooseDropdown(tester, _key('srd-equipment--1'), 'B – Startgold');
    await tester.ensureVisible(_key('srd-confirm-class'));
    await tester.tap(_key('srd-confirm-class'));
    await tester.pumpAndSettle();
    await _save(tester);
    expect(saved!.className, 'Barbar');
    expect(saved!.skills, ['Athletik', 'Überlebenskunst']);
    expect(saved!.savingThrowProficiencies, ['strength', 'constitution']);
    expect(saved!.startingClassChoice!.className, 'Barbar');
    expect(saved!.startingClassChoice!.kitIndex, 1);
    expect(saved!.gold, 75);
    expect(saved!.hitPoints, 14);
    expect(saved!.maxHitPoints, 14);
    expect(saved!.inventory, isEmpty);
  });

  testWidgets('Anderer Klasse wird bestätigtes Startpaket nicht zugeordnet', (
    tester,
  ) async {
    HeroCharacter? saved;
    await _open(tester, null, (hero) => saved = hero);
    await _ranger(tester, gold: true);
    await _tap(tester, _key('open-srd-class-selection'));
    await _chooseDropdown(tester, _key('srd-class-Waldläufer'), 'Barbar');
    for (final skill in ['Athletik', 'Überlebenskunst']) {
      final target = _key('srd-skill-$skill');
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      await tester.tap(target);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(_key('srd-confirm-class'));
    await tester.tap(_key('srd-confirm-class'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('bereits ein Startpaket übernommen'),
      findsOneWidget,
    );
    expect(saved, isNull);
    await _save(tester);
    expect(saved!.className, 'Waldläufer');
    expect(saved!.gold, 150);
    expect(saved!.startingClassChoice!.className, 'Waldläufer');
    expect(saved!.startingClassChoice!.kitIndex, 1);
  });

  testWidgets('Manuelle Klassenänderung widerspricht neuem Teilnachweis', (
    tester,
  ) async {
    HeroCharacter? saved;
    await _open(tester, null, (hero) => saved = hero);
    await _ranger(tester);
    final field = find.widgetWithText(TextFormField, 'Klasse');
    await tester.scrollUntilVisible(
      field,
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(field, 'Magier');
    await _save(tester);
    expect(saved, isNull);
    expect(
      find.textContaining('bestätigte Startklassenwahl passt nicht'),
      findsOneWidget,
    );
  });

  testWidgets('Abbruch erzeugt keinen Nachweis und vergibt kein Gold', (
    tester,
  ) async {
    HeroCharacter? saved;
    await _open(tester, null, (hero) => saved = hero);
    await _tap(tester, _key('open-srd-class-selection'));
    await _chooseDropdown(tester, _key('srd-equipment--1'), 'B – Startgold');
    await tester.tap(find.text('Abbrechen').last);
    await tester.pumpAndSettle();
    await _save(tester);
    expect(saved!.startingClassChoice, isNull);
    expect(saved!.gold, isNull);
    expect(saved!.inventory, isEmpty);
  });

  testWidgets('Legacy-Klassenbestätigung erfindet keinen Startnachweis', (
    tester,
  ) async {
    final original = HeroCharacter(
      id: 'legacy-class',
      name: 'Liora',
      className: 'Waldläufer',
      skills: _rangerSkills,
      savingThrowProficiencies: const ['strength', 'dexterity'],
      gold: 9,
    );
    HeroCharacter? saved;
    await _open(tester, original, (hero) => saved = hero);
    await _ranger(tester, chooseSkills: false);
    await _save(tester);
    expect(saved!.startingClassChoice, isNull);
    expect(saved!.toJson(), original.toJson());
  });

  for (final width in [320.0, 360.0]) {
    testWidgets('Klassenbestätigung $width dp, 200 % und Tastatur erreichbar', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semantics = tester.ensureSemantics();
      SrdClassSetupResult? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildFantasyTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              viewInsets: const EdgeInsets.only(bottom: 200),
            ),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async =>
                    result = await showDialog<SrdClassSetupResult>(
                      context: context,
                      builder: (_) => const SrdClassSelectionDialog(
                        currentClass: 'Waldläufer',
                        isNewCharacter: true,
                        existingSkills: _rangerSkills,
                        existingSavingThrows: [],
                        characterLevel: 1,
                        constitutionScore: 14,
                        hasExistingHitPoints: false,
                        allowEquipment: false,
                      ),
                    ),
                child: const Text('Klassenwahl'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Klassenwahl'));
      await tester.pumpAndSettle();
      final confirm = _key('srd-confirm-class');
      expect(confirm.hitTestable(), findsOneWidget);
      expect(tester.getSize(confirm).height, greaterThanOrEqualTo(48));
      expect(
        tester.getSemantics(confirm).label,
        contains('Klasse und Fertigkeiten'),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(result!.startingClassChoice!.className, 'Waldläufer');
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });
  }
  for (final className in ['Kleriker', 'Paladin']) {
    testWidgets(
      '$className: Symbolwahl wird erst mit gespeichertem Editor übernommen',
      (tester) async {
        HeroCharacter? saved;
        await _open(tester, null, (hero) => saved = hero);
        await _tap(tester, _key('open-srd-class-selection'));
        await _chooseDropdown(tester, _key('srd-class-Waldläufer'), className);
        for (final skill in ['Heilkunde', 'Religion']) {
          await _tap(tester, _key('srd-skill-$skill'));
        }
        await _chooseDropdown(
          tester,
          _key('srd-equipment--1'),
          'A – Ausrüstung',
        );
        await _chooseDropdown(
          tester,
          _key('srd-starter-choice-Heiliges Symbol'),
          'Heiliges Symbol: Reliquiar',
        );
        await _tap(tester, _key('srd-confirm-class'));
        expect(saved, isNull);
        await _tap(tester, _key('open-srd-creation-audit'));
        final audit = tester.widget<SrdCreationAuditDialog>(
          find.byType(SrdCreationAuditDialog),
        );
        expect(
          audit.steps
              .singleWhere((step) => step.id == 'class.equipment')
              .status,
          CreationStepStatus.confirmed,
        );
        await tester.tap(_key('close-srd-creation-audit'));
        await tester.pumpAndSettle();
        // A second class confirmation must retain the kit and the chosen symbol.
        await _tap(tester, _key('open-srd-class-selection'), delta: -300);
        expect(
          tester
              .widget<SrdClassSelectionDialog>(
                find.byType(SrdClassSelectionDialog),
              )
              .allowEquipment,
          isFalse,
        );
        await _tap(tester, _key('srd-confirm-class'));
        await _save(tester);
        expect(saved!.className, className);
        expect(saved!.gold, className == 'Kleriker' ? 7 : 9);
        expect(saved!.hitPoints, className == 'Kleriker' ? 10 : 12);
        expect(saved!.startingClassChoice!.version, 3);
        expect(saved!.startingClassChoice!.kitIndex, 0);
        expect(saved!.startingClassChoice!.equipmentChoices, {
          'Heiliges Symbol': 'item-holy-symbol-reliquary',
        });
        expect(
          saved!.inventory.where(
            (item) => item.catalogId == 'item-holy-symbol-reliquary',
          ),
          hasLength(1),
        );
        expect(saved!.inventory.every((item) => item.stats != null), isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final gold in [false, true]) {
    testWidgets(
      'Mönch: Werkzeugquelle und ${gold ? 'Gold' : 'Paket'} erst nach Editor-Speicherung',
      (tester) async {
        HeroCharacter? saved;
        await _open(tester, null, (hero) => saved = hero);
        await _tap(tester, _key('open-srd-class-selection'));
        await _chooseDropdown(tester, _key('srd-class-Waldläufer'), 'Mönch');
        await _chooseDropdown(
          tester,
          _key('srd-monk-tool-proficiency'),
          'Laute',
        );
        for (final skill in ['Akrobatik', 'Athletik']) {
          await _tap(tester, _key('srd-skill-$skill'));
        }
        await _chooseDropdown(
          tester,
          _key('srd-equipment--1'),
          gold ? 'B – Startgold' : 'A – Ausrüstung',
        );
        await _tap(tester, _key('srd-confirm-class'));
        expect(saved, isNull);
        // A second explicit confirmation retains the source, not a second kit.
        await _tap(tester, _key('open-srd-class-selection'));
        expect(
          tester
              .widget<SrdClassSelectionDialog>(
                find.byType(SrdClassSelectionDialog),
              )
              .allowEquipment,
          isFalse,
        );
        expect(
          tester
              .state<FormFieldState<String>>(_key('srd-monk-tool-proficiency'))
              .value,
          'item-lute',
        );
        await _tap(tester, _key('srd-confirm-class'));
        await _tap(tester, _key('open-srd-creation-audit'));
        final audit = tester.widget<SrdCreationAuditDialog>(
          find.byType(SrdCreationAuditDialog),
        );
        expect(
          audit.steps.singleWhere((step) => step.id == 'class.tools').status,
          CreationStepStatus.confirmed,
        );
        expect(
          audit.steps
              .singleWhere((step) => step.id == 'class.equipment')
              .status,
          CreationStepStatus.confirmed,
        );
        await tester.tap(_key('close-srd-creation-audit'));
        await tester.pumpAndSettle();
        await _save(tester);
        expect(saved!.className, 'Mönch');
        expect(saved!.hitPoints, 10);
        expect(saved!.gold, gold ? 50 : 11);
        expect(saved!.startingClassChoice!.version, 3);
        expect(
          saved!.startingClassChoice!.toolProficiencyCatalogId,
          'item-lute',
        );
        expect(saved!.startingClassChoice!.kitIndex, gold ? 1 : 0);
        expect(
          saved!.inventory.where((item) => item.catalogId == 'item-lute'),
          hasLength(gold ? 0 : 1),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
