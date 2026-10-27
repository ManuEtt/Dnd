import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/starting_ability_origin.dart';
import 'package:lebendiger_spielleiter/ui/ability_assignment_dialog.dart';
import 'package:lebendiger_spielleiter/ui/character_editor.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';

Finder keyed(String key) => find.byKey(ValueKey(key));
Finder keyStarting(String prefix) => find.byWidgetPredicate((widget) {
  final key = widget.key;
  return key is ValueKey<String> && key.value.startsWith(prefix);
});

Future<void> showAssistant(
  WidgetTester tester, {
  bool hasExistingValues = false,
  int level = 1,
  void Function(AbilityAssignment?)? onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            onPressed: () async {
              final result = await showDialog<AbilityAssignment>(
                context: context,
                builder: (_) => AbilityAssignmentDialog(
                  hasExistingValues: hasExistingValues,
                  level: level,
                ),
              );
              onResult?.call(result);
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

Future<void> choose(WidgetTester tester, Finder dropdown, String option) async {
  await tester.ensureVisible(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  final item = find.text(option).last;
  await tester.ensureVisible(item);
  await tester.pumpAndSettle();
  await tester.tap(item);
  await tester.pumpAndSettle();
}

Future<void> chooseSoldierAllThree(WidgetTester tester) async {
  await choose(tester, keyed('ability-background'), 'Soldat');
  await choose(tester, keyed('ability-bonus-pattern'), '+1 auf alle drei');
}

FantasyTextButton applyButton(WidgetTester tester) =>
    tester.widget<FantasyTextButton>(keyed('apply-ability-assignment'));

Future<void> showEditor(
  WidgetTester tester,
  HeroCharacter hero,
  void Function(HeroCharacter?) onResult,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            onPressed: () async {
              onResult(
                await Navigator.push<HeroCharacter>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CharacterEditor(hero: hero),
                  ),
                ),
              );
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

Future<void> openAssistantFromEditor(
  WidgetTester tester, {
  double scrollStep = 400,
}) async {
  final button = keyed('open-ability-assignment');
  await tester.scrollUntilVisible(
    button,
    scrollStep,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> saveEditor(WidgetTester tester) async {
  final button = find.text('Charakter speichern');
  await tester.scrollUntilVisible(
    button,
    400,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> increase(WidgetTester tester, String ability, int steps) async {
  final button = keyed('increase-$ability');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  for (var i = 0; i < steps; i++) {
    await tester.tap(button);
    await tester.pump();
  }
}

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets('Requires explicitly selected background and increases', (
    tester,
  ) async {
    await showAssistant(tester);
    expect(applyButton(tester).onPressed, isNull);
    expect(
      tester
          .widget<DropdownButtonFormField<SrdBackground>>(
            keyed('ability-background'),
          )
          .initialValue,
      isNull,
    );
    expect(find.text('Bitte ausdrücklich wählen'), findsOneWidget);
    await choose(tester, keyed('ability-background'), 'Soldat');
    expect(applyButton(tester).onPressed, isNull);
    await choose(tester, keyStarting('bonus-two-'), 'Geschicklichkeit');
    expect(applyButton(tester).onPressed, isNull);
    await choose(tester, keyStarting('bonus-one-'), 'Konstitution');
    expect(applyButton(tester).onPressed, isNotNull);
  });

  testWidgets('Standard assignment swaps used values and applies +2/+1 once', (
    tester,
  ) async {
    AbilityAssignment? result;
    await showAssistant(tester, onResult: (value) => result = value);
    await choose(tester, keyStarting('base-strength-'), '8');
    expect(
      tester
          .widget<DropdownButtonFormField<int>>(keyStarting('base-charisma-'))
          .initialValue,
      15,
    );
    await choose(tester, keyed('ability-background'), 'Soldat');
    await choose(tester, keyStarting('bonus-two-'), 'Geschicklichkeit');
    await choose(tester, keyStarting('bonus-one-'), 'Konstitution');
    expect(
      tester.widget<Text>(keyed('preview-dexterity')).data,
      'Basis 14 + 2 = 16 · Modifikator +3',
    );
    await tester.tap(keyed('apply-ability-assignment'));
    await tester.pumpAndSettle();
    expect(result!.background, 'Soldat');
    expect(result!.scores, {
      'strength': 8,
      'dexterity': 16,
      'constitution': 14,
      'intelligence': 12,
      'wisdom': 10,
      'charisma': 15,
    });
  });

  testWidgets('Point buy stops at 27 and can free points again', (
    tester,
  ) async {
    await showAssistant(tester);
    await choose(
      tester,
      keyed('ability-generation-method'),
      'Punkte-Kauf (27 Punkte)',
    );
    await increase(tester, 'strength', 7);
    await increase(tester, 'dexterity', 7);
    await increase(tester, 'constitution', 7);
    expect(
      tester.widget<Text>(keyed('remaining-ability-points')).data,
      'Verfügbar: 0 von 27 Punkten',
    );
    expect(
      tester
          .widget<FantasyIconButton>(keyed('increase-intelligence'))
          .onPressed,
      isNull,
    );
    expect(
      tester.widget<FantasyIconButton>(keyed('increase-strength')).onPressed,
      isNull,
    );
    await tester.ensureVisible(keyed('decrease-strength'));
    await tester.pumpAndSettle();
    await tester.tap(keyed('decrease-strength'));
    await tester.pump();
    expect(
      tester.widget<Text>(keyed('remaining-ability-points')).data,
      'Verfügbar: 2 von 27 Punkten',
    );
    expect(
      tester
          .widget<FantasyIconButton>(keyed('increase-intelligence'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('Under-budget point buy shows unused points explicitly', (
    tester,
  ) async {
    AbilityAssignment? result;
    await showAssistant(tester, onResult: (value) => result = value);
    await choose(
      tester,
      keyed('ability-generation-method'),
      'Punkte-Kauf (27 Punkte)',
    );
    await chooseSoldierAllThree(tester);
    expect(find.textContaining('27 Punkte noch ungenutzt'), findsOneWidget);
    expect(applyButton(tester).onPressed, isNotNull);
    await tester.tap(keyed('apply-ability-assignment'));
    await tester.pumpAndSettle();
    expect(result!.scores['strength'], 9);
    expect(result!.scores['dexterity'], 9);
    expect(result!.scores['constitution'], 9);
    expect(result!.scores['charisma'], 8);
  });

  testWidgets(
    'Changing modes recomputes previews from bases without new bonus',
    (tester) async {
      await showAssistant(tester);
      await chooseSoldierAllThree(tester);
      expect(
        tester.widget<Text>(keyed('preview-strength')).data,
        'Basis 15 + 1 = 16 · Modifikator +3',
      );
      await choose(
        tester,
        keyed('ability-generation-method'),
        'Punkte-Kauf (27 Punkte)',
      );
      await increase(tester, 'strength', 2);
      expect(
        tester.widget<Text>(keyed('preview-strength')).data,
        'Basis 10 + 1 = 11 · Modifikator +0',
      );
      await choose(
        tester,
        keyed('ability-generation-method'),
        'Standardverteilung',
      );
      expect(
        tester.widget<Text>(keyed('preview-strength')).data,
        'Basis 15 + 1 = 16 · Modifikator +3',
      );
      await choose(
        tester,
        keyed('ability-generation-method'),
        'Punkte-Kauf (27 Punkte)',
      );
      expect(
        tester.widget<Text>(keyed('preview-strength')).data,
        'Basis 10 + 1 = 11 · Modifikator +0',
      );
    },
  );

  testWidgets('Background change clears old choices before allowing apply', (
    tester,
  ) async {
    await showAssistant(tester);
    await choose(tester, keyed('ability-background'), 'Soldat');
    await choose(tester, keyStarting('bonus-two-'), 'Stärke');
    await choose(tester, keyStarting('bonus-one-'), 'Geschicklichkeit');
    expect(applyButton(tester).onPressed, isNotNull);
    expect(
      tester.widget<Text>(keyed('preview-strength')).data,
      'Basis 15 + 2 = 17 · Modifikator +3',
    );
    await choose(tester, keyed('ability-background'), 'Akolyth');
    expect(applyButton(tester).onPressed, isNull);
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(keyStarting('bonus-two-'))
          .initialValue,
      isNull,
    );
    await choose(tester, keyStarting('bonus-two-'), 'Weisheit');
    await choose(tester, keyStarting('bonus-one-'), 'Charisma');
    expect(
      tester.widget<Text>(keyed('preview-strength')).data,
      'Basis 15 + 0 = 15 · Modifikator +2',
    );
    expect(
      tester.widget<Text>(keyed('preview-wisdom')).data,
      'Basis 10 + 2 = 12 · Modifikator +1',
    );
  });

  testWidgets('Changing +2 choice resets colliding +1 choice', (tester) async {
    await showAssistant(tester);
    await choose(tester, keyed('ability-background'), 'Soldat');
    await choose(tester, keyStarting('bonus-two-'), 'Stärke');
    await choose(tester, keyStarting('bonus-one-'), 'Geschicklichkeit');
    await choose(tester, keyStarting('bonus-two-'), 'Geschicklichkeit');
    expect(applyButton(tester).onPressed, isNull);
    final plusOne = tester.widget<DropdownButtonFormField<String>>(
      keyStarting('bonus-one-'),
    );
    expect(plusOne.initialValue, isNull);
    final dropdown = tester.widget<DropdownButton<String>>(
      find.descendant(
        of: keyStarting('bonus-one-'),
        matching: find.byType(DropdownButton<String>),
      ),
    );
    expect(
      dropdown.items!.map((item) => item.value),
      isNot(contains('dexterity')),
    );
  });

  testWidgets('Known values require explicit replacement confirmation', (
    tester,
  ) async {
    await showAssistant(tester, hasExistingValues: true);
    await chooseSoldierAllThree(tester);
    expect(applyButton(tester).onPressed, isNull);
    await tester.ensureVisible(keyed('confirm-ability-replacement'));
    await tester.pumpAndSettle();
    await tester.tap(keyed('confirm-ability-replacement'));
    await tester.pump();
    expect(applyButton(tester).onPressed, isNotNull);
  });

  testWidgets(
    'Higher level warns and requires confirmation even for unknowns',
    (tester) async {
      await showAssistant(tester, level: 7);
      await chooseSoldierAllThree(tester);
      expect(find.textContaining('Dieser Held ist Stufe 7'), findsOneWidget);
      expect(applyButton(tester).onPressed, isNull);
      await tester.ensureVisible(keyed('confirm-ability-replacement'));
      await tester.pumpAndSettle();
      await tester.tap(keyed('confirm-ability-replacement'));
      await tester.pump();
      expect(applyButton(tester).onPressed, isNotNull);
    },
  );

  testWidgets('Cancel preserves nullable historical Arescan and notes', (
    tester,
  ) async {
    final original = HeroCharacter(
      id: 'arescan',
      name: 'Arescan',
      className: 'Waldläufer',
      background: 'Unbestätigte Herkunft',
      unverifiedNotes: ['Historischer Modifikator +7 ist nicht bestätigt.'],
      inventory: [const InventoryItem(id: 'key', name: 'Magischer Schlüssel')],
    );
    HeroCharacter? saved;
    await showEditor(tester, original, (value) => saved = value);
    await openAssistantFromEditor(tester);
    await chooseSoldierAllThree(tester);
    await tester.tap(find.text('Abbrechen').last);
    await tester.pumpAndSettle();
    await saveEditor(tester);
    expect(saved!.toJson(), original.toJson());
    expect(saved!.abilities.values, everyElement(isNull));
  });

  testWidgets('Cancel preserves unsaved manual attributes and background', (
    tester,
  ) async {
    final original = HeroCharacter(id: 'hero', name: 'Elowen');
    HeroCharacter? saved;
    await showEditor(tester, original, (value) => saved = value);
    final background = find.widgetWithText(TextFormField, 'Hintergrund');
    await tester.scrollUntilVisible(
      background,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(background, 'Reisende');
    final strength = find.widgetWithText(TextFormField, 'Stärke');
    await tester.scrollUntilVisible(
      strength,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(strength, '17');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await openAssistantFromEditor(tester, scrollStep: -400);
    await chooseSoldierAllThree(tester);
    expect(applyButton(tester).onPressed, isNull);
    await tester.tap(find.text('Abbrechen').last);
    await tester.pumpAndSettle();
    await saveEditor(tester);
    expect(saved!.background, 'Reisende');
    expect(saved!.abilities['strength'], 17);
    expect(
      saved!.abilities.entries.where((entry) => entry.key != 'strength'),
      everyElement(
        predicate<MapEntry<String, int?>>((entry) => entry.value == null),
      ),
    );
  });

  testWidgets('Apply changes only six attributes and chosen background', (
    tester,
  ) async {
    final original = HeroCharacter(
      id: 'arescan',
      name: 'Arescan',
      className: 'Waldläufer',
      backstory: 'Das Herz der Ewigkeit ist verschwunden.',
      hitPoints: 4,
      maxHitPoints: 12,
      gold: 3,
      experience: 7,
      skills: ['Überleben'],
      features: ['Manuell bestätigte Fähigkeit'],
      spells: ['Manuell bestätigter Zauber'],
      conditions: ['vergiftet'],
      weaponDamage: '1d8',
      inventory: [const InventoryItem(id: 'key', name: 'Magischer Schlüssel')],
      unverifiedNotes: ['Historischer Modifikator +7 ist nicht bestätigt.'],
    );
    HeroCharacter? saved;
    await showEditor(tester, original, (value) => saved = value);
    await openAssistantFromEditor(tester);
    await chooseSoldierAllThree(tester);
    await tester.tap(keyed('apply-ability-assignment'));
    await tester.pumpAndSettle();
    await saveEditor(tester);
    final expected = original.toJson();
    expected['background'] = 'Soldat';
    expected['abilities'] = {
      'strength': 16,
      'dexterity': 15,
      'constitution': 14,
      'intelligence': 12,
      'wisdom': 10,
      'charisma': 8,
    };
    expected['startingAbilityOrigin'] = StartingAbilityOrigin.confirmed(
      method: 'standardArray',
      baseScores: {
        'strength': 15,
        'dexterity': 14,
        'constitution': 13,
        'intelligence': 12,
        'wisdom': 10,
        'charisma': 8,
      },
      background: 'Soldat',
      increases: {
        'strength': 1,
        'dexterity': 1,
        'constitution': 1,
      },
    ).toJson();
    expect(saved!.toJson(), expected);
    expect(saved!.startingAbilityOrigin!.baseScores['strength'], 15);
  });

  testWidgets('360 pixel dialog supports background, preview and apply', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    AbilityAssignment? result;
    await showAssistant(tester, onResult: (value) => result = value);
    await chooseSoldierAllThree(tester);
    await choose(
      tester,
      keyed('ability-generation-method'),
      'Punkte-Kauf (27 Punkte)',
    );
    await increase(tester, 'dexterity', 7);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(keyed('preview-charisma'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(keyed('apply-ability-assignment'));
    await tester.pumpAndSettle();
    expect(result!.scores['dexterity'], 16);
    expect(result!.background, 'Soldat');
    expect(tester.takeException(), isNull);
  });
}
