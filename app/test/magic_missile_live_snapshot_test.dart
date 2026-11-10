import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/enemy_force_defense.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/magic_missile_dialog.dart';

typedef _Snapshot = ({HeroCharacter hero, Encounter encounter});

HeroCharacter _hero({
  int level = 5,
  List<String> spells = const ['Magisches Geschoss'],
}) => HeroCharacter(
  id: 'hero-1',
  name: 'Mira',
  className: 'Magier',
  level: level,
  spells: spells,
  hitPoints: 24,
  maxHitPoints: 24,
);

Encounter _encounter({
  String id = 'enemy-1',
  String name = 'Wächter',
  EnemyForceDefense defense = EnemyForceDefense.unknown,
}) => Encounter(
  id: id,
  enemyName: name,
  enemyHitPoints: 25,
  enemyMaxHitPoints: 25,
  enemyForceDefense: defense,
);

Finder _field(String name) => find.byKey(ValueKey('missile-$name'));

Future<void> _open(
  WidgetTester tester,
  ValueNotifier<_Snapshot> snapshots,
  ValueNotifier<MagicMissileChoice?> result, {
  ValueNotifier<int>? redraw,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result.value = await showDialog<MagicMissileChoice>(
                context: context,
                builder: (_) => ValueListenableBuilder<_Snapshot>(
                  valueListenable: snapshots,
                  builder: (_, value, __) => redraw == null
                      ? MagicMissileDialog(
                          hero: value.hero,
                          encounter: value.encounter,
                        )
                      : ValueListenableBuilder<int>(
                          valueListenable: redraw,
                          builder: (_, __, ___) => MagicMissileDialog(
                            hero: value.hero,
                            encounter: value.encounter,
                          ),
                        ),
                ),
              );
            },
            child: const Text('Öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Öffnen'));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String name) async {
  final field = _field(name);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.tap(field);
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String name, String label) async {
  await _tap(tester, name);
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

bool _canConfirm(WidgetTester tester) =>
    tester.widget<FantasyTextButton>(_field('confirm')).onPressed != null;

bool _checked(WidgetTester tester, String name) =>
    tester.widget<CheckboxListTile>(_field(name)).value ?? false;

void main() {
  testWidgets('Unveränderter Parent-Rebuild behält bestätigte Auswahl', (
    tester,
  ) async {
    final hero = _hero();
    final encounter = _encounter();
    final heroBefore = hero.toJson();
    final encounterBefore = encounter.toJson();
    final snapshots = ValueNotifier<_Snapshot>((
      hero: hero,
      encounter: encounter,
    ));
    final result = ValueNotifier<MagicMissileChoice?>(null);
    final redraw = ValueNotifier(0);
    addTearDown(snapshots.dispose);
    addTearDown(result.dispose);
    addTearDown(redraw.dispose);
    await _open(tester, snapshots, result, redraw: redraw);

    await _choose(tester, 'slot', 'Grad 3: 2 frei');
    await _choose(tester, 'force-defense', 'Resistenz gegen Energieschaden');
    for (final field in [
      'visible',
      'range',
      'verbal',
      'somatic',
      'protection',
    ]) {
      await _tap(tester, field);
    }

    redraw.value++;
    await tester.pumpAndSettle();
    expect(
      tester.widget<DropdownButtonFormField<String>>(_field('slot')).initialValue,
      'regular-3',
    );
    expect(find.text('Grad 3: 2 frei'), findsOneWidget);
    expect(_checked(tester, 'visible'), isTrue);
    expect(_checked(tester, 'protection'), isTrue);
    await _tap(tester, 'confirm');

    expect(result.value?.slotLevel, 3);
    expect(result.value?.castingClass, 'Magier');
    expect(result.value?.confirmedForceDefense, EnemyForceDefense.resistant);
    expect(result.value?.targetVisibleConfirmed, isTrue);
    expect(hero.toJson(), heroBefore);
    expect(encounter.toJson(), encounterBefore);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Neuer Helden-Snapshot erneuert Slots und alle Bestätigungen', (
    tester,
  ) async {
    final hero = _hero();
    final encounter = _encounter();
    final initialJson = hero.toJson();
    final snapshots = ValueNotifier<_Snapshot>((
      hero: hero,
      encounter: encounter,
    ));
    final result = ValueNotifier<MagicMissileChoice?>(null);
    addTearDown(snapshots.dispose);
    addTearDown(result.dispose);
    await _open(tester, snapshots, result);

    await _choose(tester, 'slot', 'Grad 3: 2 frei');
    await _choose(tester, 'force-defense', 'Resistenz gegen Energieschaden');
    await _tap(tester, 'visible');
    await _tap(tester, 'range');
    await _tap(tester, 'protection');

    final updated = hero.copyWith(spentSpellSlots: {'3': 2});
    final updatedJson = updated.toJson();
    snapshots.value = (hero: updated, encounter: encounter);
    await tester.pumpAndSettle();

    expect(find.text('Grad 3: 2 frei'), findsNothing);
    expect(find.text('Grad 1: 4 frei'), findsOneWidget);
    expect(
      tester.widget<DropdownButtonFormField<String>>(_field('slot')).initialValue,
      'regular-1',
    );
    expect(
      tester
          .widget<DropdownButtonFormField<EnemyForceDefense>>(
            _field('force-defense'),
          )
          .initialValue,
      isNull,
    );
    for (final field in ['visible', 'range', 'verbal', 'somatic', 'protection']) {
      expect(_checked(tester, field), isFalse);
    }
    await _tap(tester, 'confirm');
    expect(find.textContaining('Bitte alle tatsächlichen'), findsOneWidget);
    expect(result.value, isNull);
    await _tap(tester, 'cancel');
    expect(hero.toJson(), initialJson);
    expect(updated.toJson(), updatedJson);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Gegnerwechsel verwirft Ziel- und Abwehrbestätigungen', (
    tester,
  ) async {
    final hero = _hero(level: 1);
    final original = _encounter(defense: EnemyForceDefense.resistant);
    final updated = _encounter(id: 'enemy-2', name: 'Schatten');
    final snapshots = ValueNotifier<_Snapshot>((
      hero: hero,
      encounter: original,
    ));
    final result = ValueNotifier<MagicMissileChoice?>(null);
    addTearDown(snapshots.dispose);
    addTearDown(result.dispose);
    await _open(tester, snapshots, result);
    expect(
      tester
          .widget<DropdownButtonFormField<EnemyForceDefense>>(
            _field('force-defense'),
          )
          .initialValue,
      EnemyForceDefense.resistant,
    );
    await _tap(tester, 'visible');
    await _tap(tester, 'range');
    await _tap(tester, 'shield-reaction');
    expect(
      tester.widget<SwitchListTile>(_field('shield-reaction')).value,
      isTrue,
    );
    expect(_field('protection'), findsNothing);

    snapshots.value = (hero: hero, encounter: updated);
    await tester.pumpAndSettle();
    expect(find.textContaining('Ziel: Schatten.'), findsOneWidget);
    expect(_checked(tester, 'visible'), isFalse);
    expect(_checked(tester, 'range'), isFalse);
    expect(
      tester.widget<SwitchListTile>(_field('shield-reaction')).value,
      isFalse,
    );
    expect(_checked(tester, 'protection'), isFalse);
    expect(
      tester
          .widget<DropdownButtonFormField<EnemyForceDefense>>(
            _field('force-defense'),
          )
          .initialValue,
      isNull,
    );
    await _tap(tester, 'confirm');
    expect(find.textContaining('Bitte alle tatsächlichen'), findsOneWidget);
    expect(result.value, isNull);
    await _tap(tester, 'cancel');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Verlorene Vorbereitung und verbrauchte Slots sperren Wirken', (
    tester,
  ) async {
    final hero = _hero(level: 1);
    final encounter = _encounter();
    final snapshots = ValueNotifier<_Snapshot>((
      hero: hero,
      encounter: encounter,
    ));
    final result = ValueNotifier<MagicMissileChoice?>(null);
    addTearDown(snapshots.dispose);
    addTearDown(result.dispose);
    await _open(tester, snapshots, result);
    await _tap(tester, 'visible');

    snapshots.value = (
      hero: hero.copyWith(spells: const []),
      encounter: encounter,
    );
    await tester.pumpAndSettle();
    expect(_field('slot'), findsNothing);
    expect(_canConfirm(tester), isFalse);

    snapshots.value = (
      hero: hero.copyWith(spentSpellSlots: {'1': 2}),
      encounter: encounter,
    );
    await tester.pumpAndSettle();
    expect(_field('slot'), findsNothing);
    expect(_canConfirm(tester), isFalse);

    snapshots.value = (hero: _hero(level: 1), encounter: encounter);
    await tester.pumpAndSettle();
    expect(_field('slot'), findsOneWidget);
    expect(_canConfirm(tester), isTrue);
    expect(_checked(tester, 'visible'), isFalse);
    await _tap(tester, 'cancel');
    expect(result.value, isNull);
    expect(tester.takeException(), isNull);
  });
}
