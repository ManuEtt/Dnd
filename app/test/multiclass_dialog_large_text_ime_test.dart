import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/multiclass_rules.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/multiclass_selection_dialog.dart';

HeroCharacter _hero({int experience = 0}) => HeroCharacter(
  id: 'multiclass-ime',
  name: 'Tira',
  className: 'Kämpfer',
  level: 3,
  experience: experience,
  hitPoints: 20,
  maxHitPoints: 25,
  abilities: const {
    'strength': 14,
    'dexterity': 14,
    'constitution': 14,
    'intelligence': 14,
    'wisdom': 14,
    'charisma': 14,
  },
);

Future<void> _open(
  WidgetTester tester, {
  required double width,
  required HeroCharacter hero,
  required ValueChanged<MulticlassProposal?> onResult,
}) async {
  tester.view.physicalSize = Size(width, 680);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = const FakeViewPadding(bottom: 220);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(2)),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              onResult(
                await showDialog<MulticlassProposal>(
                  context: context,
                  builder: (_) => MulticlassSelectionDialog(hero: hero),
                ),
              );
            },
            child: const Text('Stufenaufstieg öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Stufenaufstieg öffnen'));
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, Finder dropdown, String value) async {
  await tester.ensureVisible(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  final option = find.text(value).last;
  await tester.ensureVisible(option);
  await tester.pumpAndSettle();
  await tester.tap(option);
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets('Mehrklassen $width dp/200 %/IME: Sperre und Abbruch', (
      tester,
    ) async {
      final hero = _hero();
      final before = hero.toJson();
      final results = <MulticlassProposal?>[];
      await _open(tester, width: width, hero: hero, onResult: results.add);
      final dialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(dialog.scrollable, isTrue);
      final methodScroll = find.byKey(
        const ValueKey('multiclass-method-scroll'),
      );
      expect(
        tester.widget<SingleChildScrollView>(methodScroll).scrollDirection,
        Axis.horizontal,
      );
      expect(find.byType(SegmentedButton), findsOneWidget);
      final confirm = find.byKey(const ValueKey('multiclass-accept'));
      expect(tester.widget<FantasyTextButton>(confirm).onPressed, isNull);
      expect(find.textContaining('mindestens 2700 EP'), findsOneWidget);
      final cancel = find.text('Abbrechen');
      expect(cancel.hitTestable(), findsOneWidget);
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(results, [null]);
      expect(hero.toJson(), before);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('320 dp/200 %/IME: Meilenstein trotz fehlender EP erreichbar', (
    tester,
  ) async {
    final hero = _hero();
    final before = hero.toJson();
    final results = <MulticlassProposal?>[];
    await _open(tester, width: 320, hero: hero, onResult: results.add);
    final confirm = find.byKey(const ValueKey('multiclass-accept'));
    expect(tester.widget<FantasyTextButton>(confirm).onPressed, isNull);

    final milestone = find.text('Meilenstein');
    await tester.ensureVisible(milestone);
    await tester.pumpAndSettle();
    expect(milestone.hitTestable(), findsOneWidget);
    await tester.tap(milestone);
    await tester.pumpAndSettle();
    expect(tester.widget<FantasyTextButton>(confirm).onPressed, isNotNull);
    expect(confirm.hitTestable(), findsOneWidget);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(results, hasLength(1));
    expect(results.single!.firstClass, 'Kämpfer');
    expect(results.single!.secondClass, 'Barbar');
    expect(results.single!.totalLevel, 4);
    expect(hero.toJson(), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('360 dp/200 %/IME: Barde erfordert Fertigkeitswahl', (
    tester,
  ) async {
    final hero = _hero(experience: 2700);
    final before = hero.toJson();
    final results = <MulticlassProposal?>[];
    await _open(tester, width: 360, hero: hero, onResult: results.add);
    final confirm = find.byKey(const ValueKey('multiclass-accept'));
    await _choose(
      tester,
      find.byKey(const ValueKey('multiclass-class')),
      'Barde',
    );
    expect(tester.widget<FantasyTextButton>(confirm).onPressed, isNull);
    final skill = MulticlassRules.availableSkills(hero, 'Barde').first;
    await _choose(
      tester,
      find.byKey(const ValueKey('multiclass-skill-Barde')),
      skill,
    );
    expect(tester.widget<FantasyTextButton>(confirm).onPressed, isNotNull);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(results.single?.secondClass, 'Barde');
    expect(results.single?.gainedSkill, skill);
    expect(hero.toJson(), before);
    expect(tester.takeException(), isNull);
  });
}
