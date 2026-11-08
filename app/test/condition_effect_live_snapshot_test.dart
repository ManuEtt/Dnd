import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/condition_effects.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/condition_effect_dialog.dart';

Finder _field(String name) => find.byKey(ValueKey('condition-effect-$name'));

ConditionEffect _effect(String id, String source) =>
    ConditionEffect(id: id, condition: 'vergiftet', source: source);

Future<List<ConditionEffectChoice?>> _open(
  WidgetTester tester, {
  required double width,
  required ValueNotifier<HeroCharacter> heroes,
  required ValueNotifier<Encounter?> encounters,
}) async {
  tester.view.physicalSize = Size(width, 840);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = const FakeViewPadding(bottom: 220);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  addTearDown(heroes.dispose);
  addTearDown(encounters.dispose);

  final results = <ConditionEffectChoice?>[];
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
          builder: (context) => TextButton(
            onPressed: () async {
              results.add(
                await showDialog<ConditionEffectChoice>(
                  context: context,
                  builder: (_) => ValueListenableBuilder<HeroCharacter>(
                    valueListenable: heroes,
                    builder: (context, hero, _) =>
                        ValueListenableBuilder<Encounter?>(
                          valueListenable: encounters,
                          builder: (context, encounter, _) =>
                              ConditionEffectDialog(
                                hero: hero,
                                encounter: encounter,
                              ),
                        ),
                  ),
                ),
              );
            },
            child: const Text('Zustandsquelle öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Zustandsquelle öffnen'));
  await tester.pumpAndSettle();
  return results;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _chooseSource(WidgetTester tester, String label) async {
  await _tap(tester, _field('existing-source'));
  final item = find.text(label).last;
  await tester.ensureVisible(item);
  await tester.pumpAndSettle();
  await tester.tap(item);
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets('$width dp: entfernte Quelle erfordert neue Auswahl', (
      tester,
    ) async {
      final initial = HeroCharacter(
        id: 'hero',
        name: 'Liora',
        conditionEffects: [_effect('a', 'Nebel'), _effect('b', 'Pfeil')],
      );
      final updated = initial.copyWith(
        conditionEffects: [_effect('a', 'Nebel')],
      );
      final originalJson = initial.toJson();
      final updatedJson = updated.toJson();
      final heroes = ValueNotifier(initial);
      final encounters = ValueNotifier<Encounter?>(null);
      final results = await _open(
        tester,
        width: width,
        heroes: heroes,
        encounters: encounters,
      );

      await _tap(tester, _field('remove-mode'));
      await _chooseSource(tester, 'vergiftet: Pfeil');
      expect(
        tester.state<FormFieldState<String>>(_field('existing-source')).value,
        'b',
      );

      heroes.value = updated;
      await tester.pumpAndSettle();
      expect(
        tester.state<FormFieldState<String>>(_field('existing-source')).value,
        isNull,
      );
      await _tap(tester, _field('confirm'));
      expect(_field('error'), findsOneWidget);
      expect(results, isEmpty);

      await _chooseSource(tester, 'vergiftet: Nebel');
      await _tap(tester, _field('confirm'));
      expect(results, hasLength(1));
      expect(results.single?.isRemoval, isTrue);
      expect(results.single?.effectId, 'a');
      expect(initial.toJson(), originalJson);
      expect(updated.toJson(), updatedJson);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Letzte Quelle verschwindet: Entfernen wird verlassen', (
    tester,
  ) async {
    final initial = HeroCharacter(
      id: 'hero',
      name: 'Liora',
      conditionEffects: [_effect('a', 'Nebel')],
    );
    final heroes = ValueNotifier(initial);
    final results = await _open(
      tester,
      width: 320,
      heroes: heroes,
      encounters: ValueNotifier<Encounter?>(null),
    );
    await _tap(tester, _field('remove-mode'));
    heroes.value = initial.copyWith(conditionEffects: []);
    await tester.pumpAndSettle();
    expect(_field('remove-mode'), findsNothing);
    expect(_field('existing-source'), findsNothing);
    expect(_field('source'), findsOneWidget);
    await _tap(tester, _field('confirm'));
    expect(_field('error'), findsOneWidget);
    expect(results, isEmpty);
    await _tap(tester, _field('cancel'));
    expect(results, [null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Anderer Held mit gleicher Quellen-ID bleibt ungeprüft', (
    tester,
  ) async {
    final heroes = ValueNotifier(
      HeroCharacter(
        id: 'hero-one',
        name: 'Liora',
        conditionEffects: [_effect('shared-id', 'Nebel')],
      ),
    );
    final results = await _open(
      tester,
      width: 360,
      heroes: heroes,
      encounters: ValueNotifier<Encounter?>(null),
    );
    await _tap(tester, _field('remove-mode'));
    heroes.value = HeroCharacter(
      id: 'hero-two',
      name: 'Tarek',
      conditionEffects: [_effect('shared-id', 'Pfeil')],
    );
    await tester.pumpAndSettle();
    expect(_field('existing-source'), findsNothing);
    expect(tester.widget<SwitchListTile>(_field('remove-mode')).value, isFalse);
    await _tap(tester, _field('confirm'));
    expect(_field('error'), findsOneWidget);
    expect(results, isEmpty);
    await _tap(tester, _field('cancel'));
    expect(results, [null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Abgelaufener Kampfzug setzt Wirkungsende sicher zurück', (
    tester,
  ) async {
    final hero = HeroCharacter(id: 'hero', name: 'Liora');
    const encounter = Encounter(
      id: 'fight',
      enemyName: 'Wächter',
      enemyHitPoints: 10,
      enemyMaxHitPoints: 10,
    );
    final heroes = ValueNotifier(hero);
    final encounters = ValueNotifier<Encounter?>(encounter);
    final results = await _open(
      tester,
      width: 320,
      heroes: heroes,
      encounters: encounters,
    );
    await _tap(tester, _field('duration'));
    final timed = find.text('Ende des nächsten eigenen Zugs').last;
    await tester.ensureVisible(timed);
    await tester.pumpAndSettle();
    await tester.tap(timed);
    await tester.pumpAndSettle();
    expect(
      tester
          .state<FormFieldState<ConditionEffectDuration>>(_field('duration'))
          .value,
      ConditionEffectDuration.nextTurnEnd,
    );

    encounters.value = encounter.copyWith(activeParticipant: 'enemy');
    await tester.pumpAndSettle();
    expect(
      tester
          .state<FormFieldState<ConditionEffectDuration>>(_field('duration'))
          .value,
      ConditionEffectDuration.untilRemoved,
    );
    await tester.enterText(_field('source'), '  Giftfalle  ');
    await tester.pumpAndSettle();
    await _tap(tester, _field('confirm'));
    expect(results, hasLength(1));
    expect(results.single?.isRemoval, isFalse);
    expect(results.single?.source, 'Giftfalle');
    expect(results.single?.duration, ConditionEffectDuration.untilRemoved);
    expect(hero.conditionEffects, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
