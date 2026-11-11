import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/fire_bolt_dialog.dart';

HeroCharacter _hero({
  String id = 'wizard',
  String className = 'Magier',
  String secondaryClassName = '',
  int secondaryClassLevel = 0,
  List<String> spells = const ['Feuerpfeil'],
}) => HeroCharacter(
  id: id,
  name: 'Arina',
  className: className,
  secondaryClassName: secondaryClassName,
  secondaryClassLevel: secondaryClassLevel,
  level: 5,
  spells: spells,
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 16,
    'wisdom': 12,
    'charisma': 14,
  },
  hitPoints: 20,
  maxHitPoints: 20,
);

const _guard = Encounter(
  id: 'fire-target-1',
  enemyName: 'Wächter',
  enemyHitPoints: 20,
  enemyMaxHitPoints: 20,
  enemyArmorClass: 14,
);

const _wolf = Encounter(
  id: 'fire-target-2',
  enemyName: 'Wolf',
  enemyHitPoints: 11,
  enemyMaxHitPoints: 11,
  enemyArmorClass: 12,
);

Finder _key(String id) => find.byKey(ValueKey('fire-bolt-$id'));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _selectClass(WidgetTester tester, String name) async {
  await _tap(tester, _key('class'));
  await _tap(tester, find.text(name).last);
}

Future<void> _approve(WidgetTester tester) async {
  for (final id in [
    'visible',
    'range',
    'verbal',
    'somatic',
    'defenses',
    'shield',
    'circumstances',
    'attack-modifiers',
  ]) {
    await _tap(tester, _key(id));
  }
}

Future<void> _launch(
  WidgetTester tester, {
  required HeroCharacter Function() hero,
  required Encounter Function() encounter,
  required ValueChanged<StateSetter> onRebuild,
  required ValueChanged<FireBoltChoice?> onResult,
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
              final result = await showDialog<FireBoltChoice>(
                context: context,
                builder: (_) => StatefulBuilder(
                  builder: (context, rebuild) {
                    onRebuild(rebuild);
                    return FireBoltDialog(
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

void main() {
  testWidgets('Same snapshot keeps selected class and checks', (tester) async {
    final hero = _hero(
      secondaryClassName: 'Zauberer',
      secondaryClassLevel: 1,
    );
    StateSetter? rebuild;
    final choices = <FireBoltChoice?>[];
    await _launch(
      tester,
      hero: () => hero,
      encounter: () => _guard,
      onRebuild: (value) => rebuild = value,
      onResult: choices.add,
    );
    await _selectClass(tester, 'Zauberer');
    await _tap(tester, _key('attack-modifiers'));
    rebuild!(() {});
    await tester.pumpAndSettle();

    expect(
      tester.widget<DropdownButtonFormField<String>>(_key('class'))
          .initialValue,
      'Magier',
    );
    expect(find.textContaining('Klasse: Zauberer'), findsOneWidget);
    expect(
      tester.widget<CheckboxListTile>(_key('attack-modifiers')).value,
      isTrue,
    );
    expect(choices, isEmpty);
    await _tap(tester, find.text('Abbrechen'));
    expect(choices, [null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('New hero rebuilds class field and requires new consent', (
    tester,
  ) async {
    var hero = _hero(
      secondaryClassName: 'Zauberer',
      secondaryClassLevel: 1,
    );
    StateSetter? rebuild;
    final choices = <FireBoltChoice?>[];
    await _launch(
      tester,
      hero: () => hero,
      encounter: () => _guard,
      onRebuild: (value) => rebuild = value,
      onResult: choices.add,
    );
    await _approve(tester);
    expect(_key('class-stats'), findsOneWidget);

    rebuild!(() => hero = _hero(id: 'sorcerer', className: 'Zauberer'));
    await tester.pumpAndSettle();

    expect(find.text('Magier'), findsNothing);
    expect(
      tester.widget<DropdownButtonFormField<String>>(_key('class'))
          .initialValue,
      'Zauberer',
    );
    for (final id in [
      'visible',
      'range',
      'verbal',
      'somatic',
      'defenses',
      'shield',
      'circumstances',
      'attack-modifiers',
    ]) {
      expect(tester.widget<CheckboxListTile>(_key(id)).value, isFalse);
    }
    expect(_key('class-stats'), findsNothing);
    expect(choices, isEmpty);
    await _approve(tester);
    await _tap(tester, _key('cast'));
    expect(choices, hasLength(1));
    expect(choices.single?.castingClass, 'Zauberer');
    expect(choices.single?.targetVisibleConfirmed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('New encounter revokes target-specific confirmations', (
    tester,
  ) async {
    final hero = _hero();
    var encounter = _guard;
    StateSetter? rebuild;
    final choices = <FireBoltChoice?>[];
    await _launch(
      tester,
      hero: () => hero,
      encounter: () => encounter,
      onRebuild: (value) => rebuild = value,
      onResult: choices.add,
    );
    await _approve(tester);
    await _tap(tester, _key('advantage'));
    await _tap(tester, _key('prone'));
    rebuild!(() => encounter = _wolf);
    await tester.pumpAndSettle();

    expect(find.textContaining('Ziel: Wolf'), findsOneWidget);
    for (final id in [
      'visible',
      'range',
      'verbal',
      'somatic',
      'defenses',
      'shield',
      'circumstances',
      'attack-modifiers',
      'advantage',
      'prone',
    ]) {
      expect(tester.widget<CheckboxListTile>(_key(id)).value, isFalse);
    }
    await _tap(tester, _key('cast'));
    expect(find.textContaining('Bitte alle tatsächlichen'), findsOneWidget);
    expect(choices, isEmpty);
    await _tap(tester, find.text('Abbrechen'));
    expect(choices, [null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hero without prepared spell disables obsolete class', (
    tester,
  ) async {
    var hero = _hero();
    StateSetter? rebuild;
    final choices = <FireBoltChoice?>[];
    await _launch(
      tester,
      hero: () => hero,
      encounter: () => _guard,
      onRebuild: (value) => rebuild = value,
      onResult: choices.add,
    );
    await _tap(tester, _key('visible'));
    rebuild!(() => hero = _hero(id: 'new-hero', spells: const []));
    await tester.pumpAndSettle();

    expect(
      tester.widget<CheckboxListTile>(_key('visible')).value,
      isFalse,
    );
    expect(find.text('Kein bestätigter Feuerpfeil verfügbar.'), findsOneWidget);
    expect(
      tester.widget<FantasyTextButton>(_key('cast')).onPressed,
      isNull,
    );
    expect(choices, isEmpty);
    await _tap(tester, find.text('Abbrechen'));
    expect(choices, [null]);
    expect(tester.takeException(), isNull);
  });
}
