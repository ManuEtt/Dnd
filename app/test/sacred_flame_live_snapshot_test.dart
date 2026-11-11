import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/sacred_flame_dialog.dart';

HeroCharacter _hero({
  String id = 'cleric',
  List<String> spells = const ['Heilige Flamme'],
}) {
  return HeroCharacter(
    id: id,
    name: 'Ari',
    className: 'Kleriker',
    level: 5,
    spells: spells,
    abilities: const {
      'strength': 10,
      'dexterity': 12,
      'constitution': 14,
      'intelligence': 10,
      'wisdom': 16,
      'charisma': 10,
    },
    hitPoints: 20,
    maxHitPoints: 20,
  );
}

const _guard = Encounter(
  id: 'enemy-1',
  enemyName: 'Wächter',
  enemyHitPoints: 20,
  enemyMaxHitPoints: 20,
);

const _wolf = Encounter(
  id: 'enemy-2',
  enemyName: 'Wolf',
  enemyHitPoints: 11,
  enemyMaxHitPoints: 11,
);

Finder _key(String name) => find.byKey(ValueKey('sacred-flame-$name'));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _launch(
  WidgetTester tester, {
  required HeroCharacter Function() hero,
  required Encounter Function() encounter,
  required ValueChanged<StateSetter> onRebuild,
  required ValueChanged<SacredFlameChoice?> onResult,
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
              final result = await showDialog<SacredFlameChoice>(
                context: context,
                builder: (_) => StatefulBuilder(
                  builder: (context, rebuild) {
                    onRebuild(rebuild);
                    return SacredFlameDialog(
                      hero: hero(),
                      encounter: encounter(),
                    );
                  },
                ),
              );
              onResult(result);
            },
            child: const Text('Öffnen'),
          ),
        ),
      ),
    ),
  );
  await _tap(tester, find.text('Öffnen'));
}

Future<void> _enterSave(WidgetTester tester, String value) async {
  final field = _key('enemy-save-modifier');
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}

String _save(WidgetTester tester) {
  final field = tester.widget<TextField>(_key('enemy-save-modifier'));
  return field.controller!.text;
}

void main() {
  testWidgets('Same snapshot keeps unsubmitted draft', (tester) async {
    final hero = _hero();
    StateSetter? rebuild;
    final results = <SacredFlameChoice?>[];
    await _launch(
      tester,
      hero: () => hero,
      encounter: () => _guard,
      onRebuild: (value) => rebuild = value,
      onResult: results.add,
    );
    await _enterSave(tester, '+3');
    await _tap(tester, _key('visible'));
    rebuild!(() {});
    await tester.pumpAndSettle();

    expect(_save(tester), '+3');
    expect(tester.widget<CheckboxListTile>(_key('visible')).value, isTrue);
    expect(results, isEmpty);
    await _tap(tester, find.text('Abbrechen'));
    expect(results, [null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('New enemy revokes saved checks', (tester) async {
    final hero = _hero();
    var encounter = _guard;
    StateSetter? rebuild;
    final results = <SacredFlameChoice?>[];
    await _launch(
      tester,
      hero: () => hero,
      encounter: () => encounter,
      onRebuild: (value) => rebuild = value,
      onResult: results.add,
    );
    await _enterSave(tester, '-2');
    await _tap(tester, _key('visible'));
    await _tap(tester, _key('range'));
    await _tap(tester, _key('dc'));
    await _tap(tester, _key('advantage'));
    rebuild!(() => encounter = _wolf);
    await tester.pumpAndSettle();

    expect(find.textContaining('Ziel: Wolf'), findsOneWidget);
    expect(_save(tester), isEmpty);
    for (final key in ['visible', 'range', 'dc', 'advantage']) {
      expect(tester.widget<CheckboxListTile>(_key(key)).value, isFalse);
    }
    expect(results, isEmpty);
    await _tap(tester, find.text('Abbrechen'));
    expect(results, [null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('New hero revokes spell confirmation', (tester) async {
    var hero = _hero();
    StateSetter? rebuild;
    final results = <SacredFlameChoice?>[];
    await _launch(
      tester,
      hero: () => hero,
      encounter: () => _guard,
      onRebuild: (value) => rebuild = value,
      onResult: results.add,
    );
    await _enterSave(tester, '+4');
    await _tap(tester, _key('visible'));
    rebuild!(() => hero = _hero(id: 'other', spells: const []));
    await tester.pumpAndSettle();

    expect(_save(tester), isEmpty);
    expect(tester.widget<CheckboxListTile>(_key('visible')).value, isFalse);
    expect(
      find.text('Kein bestätigter Kleriker-Zaubertrick verfügbar.'),
      findsOneWidget,
    );
    final cast = tester.widget<FantasyTextButton>(_key('cast'));
    expect(cast.onPressed, isNull);
    expect(results, isEmpty);
    await _tap(tester, find.text('Abbrechen'));
    expect(results, [null]);
    expect(tester.takeException(), isNull);
  });
}
