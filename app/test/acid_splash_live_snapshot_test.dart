import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/acid_splash_dialog.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';

HeroCharacter _mage({
  String id = 'acid-mage',
  String className = 'Magier',
  List<String> spells = const ['Säurespritzer'],
}) => HeroCharacter(
  id: id,
  name: 'Aria',
  className: className,
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
  hitPoints: 25,
  maxHitPoints: 25,
);

const _guard = Encounter(
  id: 'acid-guard',
  enemyName: 'Wächter',
  enemyHitPoints: 25,
  enemyMaxHitPoints: 25,
);

const _wolf = Encounter(
  id: 'acid-wolf',
  enemyName: 'Wolf',
  enemyHitPoints: 12,
  enemyMaxHitPoints: 12,
);

const _goblin = TrackedAreaCreature(
  id: 'goblin',
  name: 'Goblin',
  hitPoints: 7,
  maxHitPoints: 7,
);

const _orc = TrackedAreaCreature(
  id: 'orc',
  name: 'Ork',
  hitPoints: 14,
  maxHitPoints: 14,
);

Finder _field(String name) => find.byKey(ValueKey('acid-splash-$name'));
Finder _extra(String name) => find.byKey(ValueKey('acid-extra-$name'));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enter(
  WidgetTester tester,
  Finder finder,
  String value,
) async {
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
  await tester.pumpAndSettle();
}

String _text(WidgetTester tester, Finder finder) =>
    tester.widget<TextField>(finder).controller!.text;

bool _checked(WidgetTester tester, Finder finder) =>
    tester.widget<CheckboxListTile>(finder).value ?? false;

Future<void> _confirmSingleTarget(WidgetTester tester) async {
  await _enter(tester, _field('save-modifier'), '+3');
  for (final id in [
    'origin',
    'only',
    'verbal',
    'somatic',
    'dc',
    'save',
    'cover',
    'path',
    'acid-defense',
  ]) {
    await _tap(tester, _field(id));
  }
}

Future<void> _launch(
  WidgetTester tester, {
  required HeroCharacter Function() hero,
  required Encounter Function() encounter,
  required List<TrackedAreaCreature> Function() tracked,
  required ValueChanged<StateSetter> onRebuild,
  required ValueChanged<AcidSplashChoice?> onResult,
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
              final choice = await showDialog<AcidSplashChoice>(
                context: context,
                builder: (_) => StatefulBuilder(
                  builder: (context, rebuild) {
                    onRebuild(rebuild);
                    return AcidSplashDialog(
                      hero: hero(),
                      encounter: encounter(),
                      trackedAreaCreatures: tracked(),
                    );
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
  testWidgets('Same snapshot keeps deliberate checks and allows casting', (
    tester,
  ) async {
    final hero = _mage();
    StateSetter? rebuild;
    final results = <AcidSplashChoice?>[];
    await _launch(
      tester,
      hero: () => hero,
      encounter: () => _guard,
      tracked: () => const [],
      onRebuild: (setter) => rebuild = setter,
      onResult: results.add,
    );

    await _confirmSingleTarget(tester);
    rebuild!(() {});
    await tester.pumpAndSettle();
    expect(_text(tester, _field('save-modifier')), '+3');
    expect(_checked(tester, _field('only')), isTrue);
    expect(_checked(tester, _field('acid-defense')), isTrue);
    await _tap(tester, _field('cast'));
    expect(results, hasLength(1));
    expect(results.single!.castingClass, 'Magier');
    expect(results.single!.targetDexteritySaveModifier, 3);
    expect(results.single!.onlyCreatureInSphereConfirmed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('New hero clears bonus, consent and obsolete casting class', (
    tester,
  ) async {
    var hero = _mage();
    StateSetter? rebuild;
    final results = <AcidSplashChoice?>[];
    await _launch(
      tester,
      hero: () => hero,
      encounter: () => _guard,
      tracked: () => const [],
      onRebuild: (setter) => rebuild = setter,
      onResult: results.add,
    );
    await _confirmSingleTarget(tester);
    rebuild!(() => hero = _mage(
      id: 'new-sorcerer',
      className: 'Zauberer',
      spells: const [],
    ));
    await tester.pumpAndSettle();

    expect(_text(tester, _field('save-modifier')), isEmpty);
    expect(_checked(tester, _field('origin')), isFalse);
    expect(_checked(tester, _field('only')), isFalse);
    expect(_checked(tester, _field('acid-defense')), isFalse);
    expect(
      tester.widget<DropdownButtonFormField<String>>(_field('class'))
          .initialValue,
      'Zauberer',
    );
    expect(find.text('Magier'), findsNothing);
    expect(find.text('Säurespritzer ist nicht vorbereitet.'), findsOneWidget);
    expect(
      tester.widget<FantasyTextButton>(_field('cast')).onPressed,
      isNull,
    );
    expect(results, isEmpty);
    await _tap(tester, find.text('Abbrechen'));
    expect(results, [null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('New primary enemy revokes all prior target confirmations', (
    tester,
  ) async {
    final hero = _mage();
    var enemy = _guard;
    StateSetter? rebuild;
    final results = <AcidSplashChoice?>[];
    await _launch(
      tester,
      hero: () => hero,
      encounter: () => enemy,
      tracked: () => const [],
      onRebuild: (setter) => rebuild = setter,
      onResult: results.add,
    );
    await _confirmSingleTarget(tester);
    rebuild!(() => enemy = _wolf);
    await tester.pumpAndSettle();

    expect(find.textContaining('Gespeicherter Gegner: Wolf'), findsOneWidget);
    expect(_text(tester, _field('save-modifier')), isEmpty);
    for (final id in [
      'origin',
      'only',
      'verbal',
      'somatic',
      'dc',
      'save',
      'cover',
      'path',
      'acid-defense',
    ]) {
      expect(_checked(tester, _field(id)), isFalse);
    }
    await _tap(tester, _field('cast'));
    expect(find.textContaining('GES-Rettungswurfbonus'), findsWidgets);
    expect(results, isEmpty);
    await _tap(tester, find.text('Abbrechen'));
    expect(results, [null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Replacing area creatures clears verified extras and adds new', (
    tester,
  ) async {
    final hero = _mage();
    var tracked = <TrackedAreaCreature>[_goblin, _orc];
    StateSetter? rebuild;
    final results = <AcidSplashChoice?>[];
    await _launch(
      tester,
      hero: () => hero,
      encounter: () => _guard,
      tracked: () => tracked,
      onRebuild: (setter) => rebuild = setter,
      onResult: results.add,
    );

    await _enter(tester, _field('save-modifier'), '+2');
    await _tap(tester, _extra('select-goblin'));
    await _enter(tester, _extra('save-goblin'), '+4');
    await _tap(tester, _field('extra-confirm-goblin'));
    await _tap(tester, _field('all-included'));
    expect(_checked(tester, _extra('select-goblin')), isTrue);
    expect(_checked(tester, _field('all-included')), isTrue);

    rebuild!(() {
      tracked = <TrackedAreaCreature>[
        _goblin.copyWith(hitPoints: 5),
        const TrackedAreaCreature(
          id: 'wolf-2',
          name: 'Wolf 2',
          hitPoints: 11,
          maxHitPoints: 11,
        ),
      ];
    });
    await tester.pumpAndSettle();

    expect(_text(tester, _field('save-modifier')), isEmpty);
    expect(_checked(tester, _extra('select-goblin')), isFalse);
    expect(_checked(tester, _field('all-included')), isFalse);
    expect(_extra('select-orc'), findsNothing);
    expect(_extra('select-wolf-2'), findsOneWidget);
    expect(_extra('save-goblin'), findsNothing);
    await _tap(tester, _extra('select-goblin'));
    expect(_text(tester, _extra('save-goblin')), isEmpty);
    expect(_checked(tester, _field('extra-confirm-goblin')), isFalse);
    expect(results, isEmpty);
    await _tap(tester, find.text('Abbrechen'));
    expect(results, [null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('In-place mutation of area list invalidates stale approval', (
    tester,
  ) async {
    final hero = _mage();
    final tracked = <TrackedAreaCreature>[_goblin];
    StateSetter? rebuild;
    final results = <AcidSplashChoice?>[];
    await _launch(
      tester,
      hero: () => hero,
      encounter: () => _guard,
      tracked: () => tracked,
      onRebuild: (setter) => rebuild = setter,
      onResult: results.add,
    );
    await _enter(tester, _field('save-modifier'), '+1');
    await _tap(tester, _extra('select-goblin'));
    await _enter(tester, _extra('save-goblin'), '-3');
    rebuild!(() => tracked[0] = _goblin.copyWith(hitPoints: 3));
    await tester.pumpAndSettle();

    expect(_checked(tester, _extra('select-goblin')), isFalse);
    expect(_extra('save-goblin'), findsNothing);
    expect(_text(tester, _field('save-modifier')), isEmpty);
    expect(find.textContaining('Goblin (3/7 TP)'), findsOneWidget);
    await _tap(tester, _extra('select-goblin'));
    expect(_text(tester, _extra('save-goblin')), isEmpty);
    await _tap(tester, find.text('Abbrechen'));
    expect(results, [null]);
    expect(tester.takeException(), isNull);
  });
}
