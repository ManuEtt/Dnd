import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_creation_audit.dart';
import 'package:lebendiger_spielleiter/domain/starting_ability_origin.dart';
import 'package:lebendiger_spielleiter/ui/character_editor.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';
import 'package:lebendiger_spielleiter/ui/srd_creation_audit_dialog.dart';

const _labels = <CreationStepStatus, String>{
  CreationStepStatus.confirmed: 'Bestätigt',
  CreationStepStatus.missing: 'Fehlt',
  CreationStepStatus.invalid: 'Ungültig',
  CreationStepStatus.dependent: 'Weitere Auswahl nötig',
  CreationStepStatus.notAutomated: 'Nicht automatisiert',
  CreationStepStatus.houseRule: 'Hausregel',
  CreationStepStatus.notInSrd: 'Nicht im SRD',
};

Finder _key(String value) => find.byKey(ValueKey(value));

Future<void> _tapInEditor(
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

Future<void> _enter(
  WidgetTester tester,
  String label,
  String value, {
  double delta = 300,
}) async {
  final target = find.widgetWithText(TextFormField, label);
  await tester.scrollUntilVisible(
    target,
    delta,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.enterText(target, value);
  await tester.pumpAndSettle();
}

Future<void> _openEditor(
  WidgetTester tester,
  HeroCharacter? hero,
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
                MaterialPageRoute(builder: (_) => CharacterEditor(hero: hero)),
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
}

Future<void> _audit(WidgetTester tester, {double delta = 300}) async {
  await _tapInEditor(tester, _key('open-srd-creation-audit'), delta: delta);
  expect(find.byType(SrdCreationAuditDialog), findsOneWidget);
  expect(tester.takeException(), isNull);
}

CreationStep _step(WidgetTester tester, String id) => tester
    .widget<SrdCreationAuditDialog>(find.byType(SrdCreationAuditDialog))
    .steps
    .singleWhere((step) => step.id == id);

Future<void> _closeAudit(WidgetTester tester) async {
  await tester.tap(_key('close-srd-creation-audit'));
  await tester.pumpAndSettle();
  expect(find.byType(SrdCreationAuditDialog), findsNothing);
}

HeroCharacter _withOrigin({int level = 1}) {
  final origin = StartingAbilityOrigin.confirmed(
    method: 'standardArray',
    baseScores: const {
      'strength': 15,
      'dexterity': 14,
      'constitution': 13,
      'intelligence': 12,
      'wisdom': 10,
      'charisma': 8,
    },
    background: 'Soldat',
    increases: const {'strength': 2, 'constitution': 1},
  );
  return HeroCharacter(
    id: 'audit-source',
    name: 'Liora',
    species: 'Waldelf',
    className: 'Waldläufer',
    level: level,
    background: 'Soldat',
    abilities: {...origin.startingScores, if (level > 1) 'strength': 20},
    startingAbilityOrigin: origin,
    speed: 10,
    speedRemainderDecimeters: 5,
    armorClass: 12,
    hitPoints: 12,
    maxHitPoints: 12,
  );
}

Future<void> _choose(
  WidgetTester tester,
  Finder dropdown,
  String option,
) async {
  await tester.ensureVisible(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.text(option).last);
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets(
      'Sieben Prüfzustände mit Semantik: $width dp, 200 %, Tastatur',
      (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
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
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => SrdCreationAuditDialog(
                      steps: [
                        for (final status in CreationStepStatus.values)
                          CreationStep(
                            status.name,
                            'Auswahl ${status.name}',
                            status,
                            'Diese notwendige Entscheidung und ihre '
                                'Voraussetzungen bleiben vollständig lesbar.',
                          ),
                      ],
                    ),
                  ),
                  child: const Text('Prüfen'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Prüfen'));
        await tester.pumpAndSettle();
        for (final status in CreationStepStatus.values) {
          final card = _key('creation-audit-${status.name}');
          await tester.scrollUntilVisible(
            card,
            160,
            scrollable: find.descendant(
              of: _key('srd-creation-audit-list'),
              matching: find.byType(Scrollable),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text(_labels[status]!), findsOneWidget);
          final label = tester.getSemantics(card).label;
          expect(label, contains(_labels[status]!));
          expect(label, contains('Voraussetzungen'));
          expect(tester.takeException(), isNull);
        }
        final close = _key('close-srd-creation-audit');
        expect(close.hitTestable(), findsOneWidget);
        expect(tester.getSize(close).height, greaterThanOrEqualTo(48));
        await _closeAudit(tester);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }

  testWidgets('Neuer unbenannter Entwurf lässt sich ohne Speichern prüfen', (
    tester,
  ) async {
    HeroCharacter? saved;
    await _openEditor(tester, null, (result) => saved = result);
    final name = find.widgetWithText(TextFormField, 'Charaktername');
    expect(tester.widget<TextFormField>(name).controller!.text, isEmpty);
    await _audit(tester);
    expect(
      _step(tester, 'abilities.scores').status,
      CreationStepStatus.missing,
    );
    expect(saved, isNull);
    await _closeAudit(tester);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(saved, isNull);
  });

  testWidgets('Fehlende Stufe bleibt leer und verlangt ausdrückliche Eingabe', (
    tester,
  ) async {
    final original = _withOrigin();
    final before = jsonEncode(original.toJson());
    HeroCharacter? saved;
    await _openEditor(tester, original, (value) => saved = value);
    await _enter(tester, 'Stufe', '');
    final field = tester
        .widget<TextFormField>(find.widgetWithText(TextFormField, 'Stufe'))
        .controller!;
    await _tapInEditor(tester, _key('open-srd-creation-audit'));
    expect(find.byType(SrdCreationAuditDialog), findsNothing);
    expect(
      find.textContaining('Für die SRD-Prüfung zuerst die Stufe'),
      findsOneWidget,
    );
    expect(field.text, isEmpty);
    expect(saved, isNull);
    expect(jsonEncode(original.toJson()), before);

    await _enter(tester, 'Stufe', '1', delta: -300);
    await _audit(tester);
    expect(
      _step(tester, 'abilities.scores').status,
      CreationStepStatus.confirmed,
    );
    await _closeAudit(tester);
    expect(_key('editor-validation-error'), findsNothing);
    expect(saved, isNull);
    expect(jsonEncode(original.toJson()), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('10,5 m und historische Attribute bleiben im Audit erhalten', (
    tester,
  ) async {
    final original = _withOrigin(level: 5);
    final before = jsonEncode(original.toJson());
    HeroCharacter? saved;
    await _openEditor(tester, original, (result) => saved = result);
    await _audit(tester);
    expect(
      _step(tester, 'combat.armor-speed').status,
      isNot(CreationStepStatus.missing),
    );
    expect(
      _step(tester, 'abilities.scores').status,
      CreationStepStatus.notAutomated,
    );
    await _closeAudit(tester);
    final speed = _key('character-speed-meters');
    await tester.scrollUntilVisible(
      speed,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.widget<TextFormField>(speed).controller!.text, '10,5');
    expect(jsonEncode(original.toJson()), before);
    expect(saved, isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(saved, isNull);
    expect(jsonEncode(original.toJson()), before);
  });

  testWidgets('Nichtnumerische Eingabe wird nicht als leer bestätigt', (
    tester,
  ) async {
    final original = _withOrigin();
    final before = jsonEncode(original.toJson());
    await _openEditor(tester, original, (_) {});
    await _enter(tester, 'Gold', 'ungültig');
    await _tapInEditor(tester, _key('open-srd-creation-audit'));
    expect(find.byType(SrdCreationAuditDialog), findsNothing);
    expect(
      find.textContaining('Zahlenfelder müssen ganze Zahlen'),
      findsOneWidget,
    );
    expect(jsonEncode(original.toJson()), before);
    expect(tester.takeException(), isNull);
    await _enter(tester, 'Gold', '8', delta: -300);
    await _audit(tester);
    await _closeAudit(tester);
    expect(_key('editor-validation-error'), findsNothing);
    expect(jsonEncode(original.toJson()), before);
  });

  testWidgets('Audit prüft die geänderten Attribute statt des alten Bogens', (
    tester,
  ) async {
    final original = _withOrigin();
    final before = jsonEncode(original.toJson());
    await _openEditor(tester, original, (_) {});
    await _enter(tester, 'Stärke', '18');
    await _audit(tester, delta: -300);
    expect(
      _step(tester, 'abilities.scores').status,
      CreationStepStatus.invalid,
    );
    expect(jsonEncode(original.toJson()), before);
    await _closeAudit(tester);
  });

  testWidgets('Gerade bestätigter Attributentwurf ist vor Speichern prüfbar', (
    tester,
  ) async {
    HeroCharacter? saved;
    await _openEditor(tester, null, (result) => saved = result);
    await _tapInEditor(tester, _key('open-ability-assignment'));
    await _choose(tester, _key('ability-background'), 'Soldat');
    await _choose(tester, _key('ability-bonus-pattern'), '+1 auf alle drei');
    final apply = _key('apply-ability-assignment');
    await tester.ensureVisible(apply);
    await tester.pumpAndSettle();
    await tester.tap(apply);
    await tester.pumpAndSettle();
    await _audit(tester, delta: -300);
    expect(
      _step(tester, 'abilities.scores').status,
      CreationStepStatus.confirmed,
    );
    expect(saved, isNull);
    await _closeAudit(tester);
  });

  testWidgets('Nur ausdrücklich bestätigte manuelle Ausnahme heißt Hausregel', (
    tester,
  ) async {
    await _openEditor(tester, null, (_) {});
    for (final label in [
      'Stärke',
      'Geschicklichkeit',
      'Konstitution',
      'Intelligenz',
      'Weisheit',
      'Charisma',
    ]) {
      await _enter(tester, label, '8');
    }
    await _tapInEditor(tester, _key('allow-manual-abilities'));
    await _audit(tester, delta: -300);
    expect(
      _step(tester, 'abilities.scores').status,
      CreationStepStatus.houseRule,
    );
    await _closeAudit(tester);
  });
}
