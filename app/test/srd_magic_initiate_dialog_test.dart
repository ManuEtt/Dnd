import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/domain/srd_magic_initiate_choice.dart';
import 'package:lebendiger_spielleiter/ui/srd_magic_initiate_dialog.dart';

Finder keyed(String text) => find.byKey(ValueKey(text));

Future<void> showChoice(
  WidgetTester tester,
  SrdBackground background,
  void Function(SrdMagicInitiateChoice?) done,
) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            final result = await showDialog<SrdMagicInitiateChoice>(
              context: context,
              builder: (_) => SrdMagicInitiateDialog(background: background),
            );
            done(result);
          },
          child: const Text('Öffnen'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('Öffnen'));
  await tester.pumpAndSettle();
}

Future<void> selectValue(
  WidgetTester tester,
  String key,
  String value,
) async {
  final dropdown = keyed(key);
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
  testWidgets('confirm requires two different cantrips, level-one and ability',
      (tester) async {
    SrdMagicInitiateChoice? result;
    await showChoice(tester, SrdBackground.acolyte, (value) => result = value);
    final button = keyed('confirm-magic-initiate-choice');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await selectValue(tester, 'magic-initiate-cantrip-one', 'Guidance');
    await selectValue(tester, 'magic-initiate-cantrip-two', 'Guidance');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    expect(find.textContaining('unterschiedliche Zaubertricks'),
        findsWidgets);
    await selectValue(tester, 'magic-initiate-cantrip-two', 'Light');
    await selectValue(tester, 'magic-initiate-level-one', 'Bless');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);
    await selectValue(tester, 'magic-initiate-ability', 'wisdom');
    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(result!.cantrips, ['Guidance', 'Light']);
    expect(result!.levelOneSpell, 'Bless');
    expect(result!.castingAbility, 'wisdom');
  });

  testWidgets('cancellation leaves the choice unset', (tester) async {
    SrdMagicInitiateChoice? result;
    await showChoice(tester, SrdBackground.sage, (value) => result = value);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('320dp with 200 percent text scale stays usable', (tester) async {
    tester.view.physicalSize = const Size(320, 840);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    SrdMagicInitiateChoice? result;
    await showChoice(tester, SrdBackground.sage, (value) => result = value);
    expect(tester.takeException(), isNull);
    expect(find.textContaining('noch nicht'), findsWidgets);
    await selectValue(tester, 'magic-initiate-cantrip-one', 'Fire Bolt');
    await selectValue(tester, 'magic-initiate-cantrip-two', 'Mage Hand');
    await selectValue(tester, 'magic-initiate-level-one', 'Magic Missile');
    await selectValue(tester, 'magic-initiate-ability', 'charisma');
    final button = keyed('confirm-magic-initiate-choice');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(result!.sourceList, 'Wizard');
    expect(result!.levelOneSpell, 'Magic Missile');
    expect(tester.takeException(), isNull);
  });
}
