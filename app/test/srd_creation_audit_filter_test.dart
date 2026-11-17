import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_creation_audit.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';
import 'package:lebendiger_spielleiter/ui/srd_creation_audit_dialog.dart';

const _confirmed = CreationStep(
  'class.done',
  'Bestätigte Klasse',
  CreationStepStatus.confirmed,
  'Klassenwahl gespeichert.',
);
const _missing = CreationStep(
  'origin.missing',
  'Fehlende Spezies',
  CreationStepStatus.missing,
  'Bitte Spezies wählen.',
);
const _invalid = CreationStep(
  'ability.invalid',
  'Ungültige Attribute',
  CreationStepStatus.invalid,
  'Bitte Attributsverteilung prüfen.',
);

Finder _key(String name) => find.byKey(ValueKey(name));

Widget _app(List<CreationStep> steps, {double scale = 1}) => MaterialApp(
  theme: buildFantasyTheme(),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: Scaffold(
    body: Builder(
      builder: (context) => Center(
        child: TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (_) => SrdCreationAuditDialog(steps: steps),
          ),
          child: const Text('Prüfung öffnen'),
        ),
      ),
    ),
  ),
);

Future<void> _open(WidgetTester tester, List<CreationStep> steps, {double scale = 1}) async {
  await tester.pumpWidget(_app(steps, scale: scale));
  await tester.tap(find.text('Prüfung öffnen'));
  await tester.pumpAndSettle();
}

List<String> _displayedStepIds(WidgetTester tester) {
  final list = tester.widget<ListView>(_key('srd-creation-audit-list'));
  final children = (list.childrenDelegate as SliverChildListDelegate).children;
  return [
    for (final child in children)
      if (child is Semantics && child.key is ValueKey<String>)
        (child.key! as ValueKey<String>).value,
  ];
}

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets('Audit-Filter bei $width dp, 200 % und IME bleibt bedienbar', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1100);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final semantics = tester.ensureSemantics();
      addTearDown(semantics.dispose);

      const steps = [_confirmed, _missing, _invalid];
      await _open(tester, steps, scale: 2);

      expect(find.text('Noch nicht bestätigt: 2 von 3'), findsOneWidget);
      expect(_displayedStepIds(tester), [
        'creation-audit-class.done',
        'creation-audit-origin.missing',
        'creation-audit-ability.invalid',
      ]);
      expect(
        tester.widget<ChoiceChip>(
          _key('creation-audit-filter-all'),
        ).selected,
        isTrue,
      );

      final unconfirmed = _key('creation-audit-filter-unconfirmed');
      await tester.ensureVisible(unconfirmed);
      await tester.tap(unconfirmed);
      await tester.pumpAndSettle();

      expect(
        tester.widget<ChoiceChip>(unconfirmed).selected,
        isTrue,
      );
      expect(_displayedStepIds(tester), [
        'creation-audit-origin.missing',
        'creation-audit-ability.invalid',
      ]);
      expect(find.text('Noch nicht bestätigt: 2 von 3'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'Fehlende Spezies. Fehlt. Bitte Spezies wählen.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      final all = _key('creation-audit-filter-all');
      await tester.ensureVisible(all);
      await tester.tap(all);
      await tester.pumpAndSettle();
      expect(_displayedStepIds(tester), [
        'creation-audit-class.done',
        'creation-audit-origin.missing',
        'creation-audit-ability.invalid',
      ]);
      final close = _key('close-srd-creation-audit');
      await tester.ensureVisible(close);
      await tester.tap(close);
      await tester.pumpAndSettle();
      expect(find.byType(SrdCreationAuditDialog), findsNothing);
      expect(steps, [_confirmed, _missing, _invalid]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Unbestätigt umfasst alle nicht bestätigten SRD-Statusarten', (
    tester,
  ) async {
    const steps = [
      _confirmed,
      _missing,
      _invalid,
      CreationStep('dependent', 'Abhängigkeit', CreationStepStatus.dependent, 'Auswahl nötig.'),
      CreationStep('automation', 'Katalogprüfung', CreationStepStatus.notAutomated, 'Nicht automatisiert.'),
      CreationStep('house-rule', 'Hausregel', CreationStepStatus.houseRule, 'Freie Wahl.'),
      CreationStep('non-srd', 'Fremdoption', CreationStepStatus.notInSrd, 'Ungeprüft.'),
    ];
    await _open(tester, steps);
    await tester.tap(_key('creation-audit-filter-unconfirmed'));
    await tester.pumpAndSettle();

    expect(find.text('Noch nicht bestätigt: 6 von 7'), findsOneWidget);
    expect(_displayedStepIds(tester), [
      'creation-audit-origin.missing',
      'creation-audit-ability.invalid',
      'creation-audit-dependent',
      'creation-audit-automation',
      'creation-audit-house-rule',
      'creation-audit-non-srd',
    ]);
    expect(_key('creation-audit-no-unconfirmed'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Leerer Filter erfindet keine vollständige SRD-Abnahme', (
    tester,
  ) async {
    await _open(tester, const [_confirmed]);
    await tester.tap(_key('creation-audit-filter-unconfirmed'));
    await tester.pumpAndSettle();

    expect(find.text('Noch nicht bestätigt: 0 von 1'), findsOneWidget);
    expect(_displayedStepIds(tester), isEmpty);
    expect(
      find.text(
        'Alle angezeigten Prüfschritte sind bestätigt. '
        'Dies ist keine vollständige SRD-Zertifizierung.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Neue Audit-Snapshots aktualisieren offenen Zähler und Liste', (
    tester,
  ) async {
    List<CreationStep> steps = const [_confirmed, _missing];
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildFantasyTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SrdCreationAuditDialog(steps: steps);
            },
          ),
        ),
      ),
    );
    await tester.tap(_key('creation-audit-filter-unconfirmed'));
    await tester.pumpAndSettle();
    expect(_displayedStepIds(tester), ['creation-audit-origin.missing']);

    rebuild(() {
      steps = const [_confirmed, _invalid];
    });
    await tester.pumpAndSettle();
    expect(find.text('Noch nicht bestätigt: 1 von 2'), findsOneWidget);
    expect(_displayedStepIds(tester), ['creation-audit-ability.invalid']);
    expect(
      tester.widget<ChoiceChip>(
        _key('creation-audit-filter-unconfirmed'),
      ).selected,
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });
}
