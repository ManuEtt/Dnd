import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/sneak_attack_ally_dialog.dart';

Finder _key(String suffix) =>
    find.byKey(ValueKey('sneak-attack-ally-$suffix'));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _approve(WidgetTester tester, String name) async {
  await tester.enterText(_key('name'), name);
  await tester.pumpAndSettle();
  await _tap(tester, _key('near-target'));
  await _tap(tester, _key('not-incapacitated'));
}

bool _checked(WidgetTester tester, String key) =>
    tester.widget<CheckboxListTile>(_key(key)).value ?? false;

String _name(WidgetTester tester) =>
    tester.widget<TextField>(_key('name')).controller!.text;

Future<void> _show(
  WidgetTester tester, {
  required String Function() target,
  required ValueChanged<StateSetter> onRebuild,
  required ValueChanged<SneakAttackAllyChoice?> onResult,
}) async {
  tester.view.physicalSize = const Size(360, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final choice = await showDialog<SneakAttackAllyChoice>(
                context: context,
                builder: (_) => StatefulBuilder(
                  builder: (context, repaint) {
                    onRebuild(repaint);
                    return SneakAttackAllyDialog(targetName: target());
                  },
                ),
              );
              onResult(choice);
            },
            child: const Text('Öffnen'),
          ),
        ),
      ),
    ),
  );
  await _tap(tester, find.text('Öffnen'));
}

void main() {
  testWidgets('Unchanged attack target keeps intentional ally approval', (
    tester,
  ) async {
    const target = 'Wächter';
    StateSetter? rebuild;
    final results = <SneakAttackAllyChoice?>[];
    await _show(
      tester,
      target: () => target,
      onRebuild: (value) => rebuild = value,
      onResult: results.add,
    );
    await _approve(tester, 'Mira');
    rebuild!(() {});
    await tester.pumpAndSettle();

    expect(_name(tester), 'Mira');
    expect(_checked(tester, 'near-target'), isTrue);
    expect(_checked(tester, 'not-incapacitated'), isTrue);
    expect(
      tester.widget<FantasyTextButton>(_key('confirm')).onPressed,
      isNotNull,
    );
    await _tap(tester, _key('confirm'));
    expect(results, hasLength(1));
    expect(results.single?.allyName, 'Mira');
    expect(results.single?.withinFiveFeetOfTargetConfirmed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('New attack target revokes former ally name and consent', (
    tester,
  ) async {
    var target = 'Wächter';
    StateSetter? rebuild;
    final results = <SneakAttackAllyChoice?>[];
    await _show(
      tester,
      target: () => target,
      onRebuild: (value) => rebuild = value,
      onResult: results.add,
    );
    await _approve(tester, 'Mira');
    rebuild!(() => target = 'Ork');
    await tester.pumpAndSettle();

    expect(find.text('Angriffsziel: Ork'), findsOneWidget);
    expect(_name(tester), isEmpty);
    expect(_checked(tester, 'near-target'), isFalse);
    expect(_checked(tester, 'not-incapacitated'), isFalse);
    expect(
      tester.widget<FantasyTextButton>(_key('confirm')).onPressed,
      isNull,
    );
    expect(results, isEmpty);
    await _approve(tester, 'Liora');
    await _tap(tester, _key('confirm'));
    expect(results, hasLength(1));
    expect(results.single?.allyName, 'Liora');
    expect(results.single?.notIncapacitatedConfirmed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Successive target switches never restore prior approval', (
    tester,
  ) async {
    var target = 'Wächter';
    StateSetter? rebuild;
    final results = <SneakAttackAllyChoice?>[];
    await _show(
      tester,
      target: () => target,
      onRebuild: (value) => rebuild = value,
      onResult: results.add,
    );
    await _approve(tester, 'Mira');
    rebuild!(() => target = 'Ork');
    await tester.pumpAndSettle();
    await _approve(tester, 'Liora');
    rebuild!(() => target = 'Wächter');
    await tester.pumpAndSettle();

    expect(find.text('Angriffsziel: Wächter'), findsOneWidget);
    expect(_name(tester), isEmpty);
    expect(_checked(tester, 'near-target'), isFalse);
    expect(_checked(tester, 'not-incapacitated'), isFalse);
    expect(
      tester.widget<FantasyTextButton>(_key('confirm')).onPressed,
      isNull,
    );
    await _tap(tester, _key('cancel'));
    expect(results, [null]);
    expect(tester.takeException(), isNull);
  });
}
