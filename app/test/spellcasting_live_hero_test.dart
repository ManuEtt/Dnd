import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/spellcasting_dialog.dart';

HeroCharacter _hero({
  String id = 'wizard',
  int level = 3,
  List<String> spells = const ['Licht', 'Magisches Geschoss'],
  Map<String, int> spentSpellSlots = const {},
}) => HeroCharacter(
  id: id,
  name: 'Mira',
  className: 'Magier',
  level: level,
  spells: spells,
  spentSpellSlots: spentSpellSlots,
  hitPoints: 18,
  maxHitPoints: 18,
);

Finder _field(String name) => find.byKey(ValueKey('spell-dialog-$name'));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _chooseSpell(WidgetTester tester, String name) async {
  await _tap(tester, _field('name'));
  await _tap(tester, find.text(name).last);
}

Future<void> _chooseLevel(WidgetTester tester, int level) async {
  await _tap(tester, _field('level'));
  await _tap(tester, find.text('Grad $level').last);
}

bool _concentrating(WidgetTester tester) =>
    tester.widget<SwitchListTile>(_field('concentration')).value;

bool _canCast(WidgetTester tester) =>
    tester.widget<FantasyTextButton>(_field('cast')).onPressed != null;

Future<void> _open(
  WidgetTester tester, {
  required HeroCharacter Function() hero,
  required ValueChanged<StateSetter> onRebuild,
  required ValueChanged<SpellcastingChoice?> onResult,
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
              final choice = await showDialog<SpellcastingChoice>(
                context: context,
                builder: (_) => StatefulBuilder(
                  builder: (context, rebuild) {
                    onRebuild(rebuild);
                    return SpellcastingDialog(hero: hero());
                  },
                ),
              );
              onResult(choice);
            },
            child: const Text('Zauber öffnen'),
          ),
        ),
      ),
    ),
  );
  await _tap(tester, find.text('Zauber öffnen'));
}

void main() {
  testWidgets('Unchanged hero retains deliberate spell and slot choices', (
    tester,
  ) async {
    final hero = _hero();
    final before = hero.toJson();
    StateSetter? rebuild;
    final results = <SpellcastingChoice?>[];
    await _open(
      tester,
      hero: () => hero,
      onRebuild: (setter) => rebuild = setter,
      onResult: results.add,
    );
    await _chooseSpell(tester, 'Magisches Geschoss');
    await _chooseLevel(tester, 1);
    await _tap(tester, _field('concentration'));
    expect(_concentrating(tester), isTrue);

    rebuild!(() {});
    await tester.pumpAndSettle();

    expect(_field('snapshot-notice'), findsNothing);
    expect(_concentrating(tester), isTrue);
    expect(_canCast(tester), isTrue);
    await _tap(tester, _field('cast'));

    expect(results, hasLength(1));
    expect(results.single?.name, 'Magisches Geschoss');
    expect(results.single?.level, 1);
    expect(results.single?.concentration, isTrue);
    expect(hero.toJson(), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('New hero resets stale spell, grade and concentration', (
    tester,
  ) async {
    var hero = _hero();
    StateSetter? rebuild;
    final results = <SpellcastingChoice?>[];
    await _open(
      tester,
      hero: () => hero,
      onRebuild: (setter) => rebuild = setter,
      onResult: results.add,
    );
    await _chooseSpell(tester, 'Magisches Geschoss');
    await _chooseLevel(tester, 1);
    await _tap(tester, _field('concentration'));

    rebuild!(() => hero = _hero(id: 'new-wizard', spells: const ['Licht']));
    await tester.pumpAndSettle();

    expect(_field('snapshot-notice'), findsOneWidget);
    expect(find.text('Magisches Geschoss'), findsNothing);
    expect(
      tester.widget<DropdownButtonFormField<String>>(_field('name'))
          .initialValue,
      'Licht',
    );
    expect(
      tester.widget<DropdownButtonFormField<int>>(_field('level'))
          .initialValue,
      0,
    );
    expect(_concentrating(tester), isFalse);
    expect(_canCast(tester), isTrue);
    await _tap(tester, _field('cast'));
    expect(results.single?.name, 'Licht');
    expect(results.single?.level, 0);
    expect(results.single?.concentration, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hero losing known spells disables stale casting choice', (
    tester,
  ) async {
    var hero = _hero();
    StateSetter? rebuild;
    final results = <SpellcastingChoice?>[];
    await _open(
      tester,
      hero: () => hero,
      onRebuild: (setter) => rebuild = setter,
      onResult: results.add,
    );
    await _chooseLevel(tester, 1);
    await _tap(tester, _field('concentration'));

    rebuild!(() => hero = _hero(id: 'unprepared', spells: const []));
    await tester.pumpAndSettle();

    expect(_field('snapshot-notice'), findsOneWidget);
    expect(find.textContaining('bekannte Zauber eintragen'), findsOneWidget);
    expect(_field('name'), findsNothing);
    expect(
      tester.widget<DropdownButtonFormField<int>>(_field('level'))
          .initialValue,
      0,
    );
    expect(_concentrating(tester), isFalse);
    expect(_canCast(tester), isFalse);
    await _tap(tester, find.text('Abbrechen'));
    expect(results, [null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Invalid new slot pool is displayed and prevents casting', (
    tester,
  ) async {
    var hero = _hero();
    StateSetter? rebuild;
    final results = <SpellcastingChoice?>[];
    await _open(
      tester,
      hero: () => hero,
      onRebuild: (setter) => rebuild = setter,
      onResult: results.add,
    );
    await _chooseLevel(tester, 1);

    rebuild!(
      () => hero = _hero(
        id: 'bad-slots',
        level: 1,
        spentSpellSlots: const {'1': 3},
      ),
    );
    await tester.pumpAndSettle();

    expect(_field('snapshot-notice'), findsOneWidget);
    expect(_field('resource-error'), findsOneWidget);
    expect(_canCast(tester), isFalse);
    expect(
      tester.widget<DropdownButtonFormField<int>>(_field('level'))
          .initialValue,
      0,
    );
    await _tap(tester, find.text('Abbrechen'));
    expect(results, [null]);
    expect(tester.takeException(), isNull);
  });
}
