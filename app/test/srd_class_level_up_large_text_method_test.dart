import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_class_level_up.dart';
import 'package:lebendiger_spielleiter/ui/srd_class_level_up_dialog.dart';

HeroCharacter _hero({required int xp}) => HeroCharacter(
  id: 'levelup-large-text',
  name: 'Tira',
  className: 'Kämpfer',
  level: 1,
  experience: xp,
  hitPoints: 8,
  maxHitPoints: 14,
  abilities: const {
    'strength': 14,
    'dexterity': 14,
    'constitution': 14,
    'intelligence': 10,
    'wisdom': 10,
    'charisma': 10,
  },
);

Future<List<SrdClassLevelUpProposal?>> _open(
  WidgetTester tester, {
  required HeroCharacter hero,
  required double width,
  double textScale = 2,
}) async {
  tester.view.physicalSize = Size(width, 840);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final results = <SrdClassLevelUpProposal?>[];
  await tester.pumpWidget(
    MaterialApp(
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
              results.add(
                await showDialog<SrdClassLevelUpProposal>(
                  context: context,
                  builder: (_) => SrdClassLevelUpDialog(hero: hero),
                ),
              );
            },
            child: const Text('Stufe erhöhen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Stufe erhöhen'));
  await tester.pumpAndSettle();
  return results;
}

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets(
      '$width dp bei 200 %: Meilenstein bleibt erreichbar und ausdrücklich',
      (tester) async {
        final hero = _hero(xp: 0);
        final original = hero.toJson();
        final results = await _open(tester, hero: hero, width: width);

        final horizontal = find.byKey(const ValueKey('levelup-method-scroll'));
        expect(horizontal, findsOneWidget);
        expect(
          tester.widget<SingleChildScrollView>(horizontal).scrollDirection,
          Axis.horizontal,
        );
        expect(find.byKey(const ValueKey('levelup-error')), findsOneWidget);
        expect(results, isEmpty);

        final milestone = find.text('Meilenstein');
        await tester.ensureVisible(milestone);
        await tester.pumpAndSettle();
        expect(milestone.hitTestable(), findsOneWidget);
        await tester.tap(milestone);
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<SegmentedButton<LevelUpMethod>>(
                find.byType(SegmentedButton<LevelUpMethod>),
              )
              .selected,
          {LevelUpMethod.milestone},
        );
        expect(find.byKey(const ValueKey('levelup-error')), findsNothing);
        expect(results, isEmpty);
        final confirm = find.byKey(const ValueKey('levelup-confirm'));
        await tester.ensureVisible(confirm);
        await tester.pumpAndSettle();
        expect(confirm.hitTestable(), findsOneWidget);
        await tester.tap(confirm);
        await tester.pumpAndSettle();

        expect(results, hasLength(1));
        expect(results.single?.totalLevel, 2);
        expect(hero.level, 1);
        expect(hero.experience, 0);
        expect(hero.toJson(), original);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Ohne ausreichende EP und ohne Meilenstein kein Stufenanstieg', (
    tester,
  ) async {
    final hero = _hero(xp: 0);
    final results = await _open(tester, hero: hero, width: 320);
    expect(find.byKey(const ValueKey('levelup-error')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('levelup-confirm')));
    await tester.pumpAndSettle();
    expect(results, isEmpty);
    expect(find.byType(SrdClassLevelUpDialog), findsOneWidget);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(results, [null]);
    expect(hero.level, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Normale Schrift behält die ursprüngliche EP-Auswahl', (
    tester,
  ) async {
    final hero = _hero(xp: 300);
    final results = await _open(tester, hero: hero, width: 360, textScale: 1);
    expect(
      tester
          .widget<SegmentedButton<LevelUpMethod>>(
            find.byType(SegmentedButton<LevelUpMethod>),
          )
          .selected,
      {LevelUpMethod.experience},
    );
    await tester.tap(find.byKey(const ValueKey('levelup-confirm')));
    await tester.pumpAndSettle();
    expect(results.single?.totalLevel, 2);
    expect(hero.level, 1);
    expect(tester.takeException(), isNull);
  });
}
