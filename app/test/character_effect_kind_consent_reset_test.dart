import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/damage_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/character_effect_dialog.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_ui.dart';

Finder _control(String id) => find.byKey(ValueKey('character-effect-$id'));

Future<List<CharacterEffectChoice?>> _open(
  WidgetTester tester,
  HeroCharacter hero, {
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 840);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = const FakeViewPadding(bottom: 220);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);

  final results = <CharacterEffectChoice?>[];
  await tester.pumpWidget(
    MaterialApp(
      theme: buildFantasyTheme(),
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
                await showDialog<CharacterEffectChoice>(
                  context: context,
                  builder: (_) => CharacterEffectDialog(hero: hero),
                ),
              );
            },
            child: const Text('Effekt öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Effekt öffnen'));
  await tester.pumpAndSettle();
  return results;
}

Future<void> _tap(WidgetTester tester, String key) async {
  final target = _control(key);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _kind(WidgetTester tester, String name) async {
  await _tap(tester, 'kind');
  final option = find.text(name).last;
  await tester.ensureVisible(option);
  await tester.pumpAndSettle();
  await tester.tap(option);
  await tester.pumpAndSettle();
}

Future<void> _enter(
  WidgetTester tester,
  String key,
  String text,
) async {
  final field = _control(key);
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pumpAndSettle();
}

HeroCharacter _hero() => HeroCharacter(
  id: 'damage-consent-reset',
  name: 'Elya',
  hitPoints: 8,
  maxHitPoints: 15,
  temporaryHitPoints: 5,
);

void main() {
  testWidgets('320 dp: Schadensmerkmale nach Artenwechsel erneut wählen', (
    tester,
  ) async {
    final hero = _hero();
    final before = jsonEncode(hero.toJson());
    final results = await _open(tester, hero, width: 320);

    await _tap(tester, 'damage-type');
    await tester.tap(find.text('Feuer').last);
    await tester.pumpAndSettle();
    for (final key in ['resistant', 'vulnerable', 'immune', 'critical']) {
      await _tap(tester, key);
      expect(tester.widget<CheckboxListTile>(_control(key)).value, isTrue);
    }

    await _kind(tester, 'Heilung');
    expect(_control('immune'), findsNothing);
    await _kind(tester, 'Schaden');
    for (final key in ['resistant', 'vulnerable', 'immune', 'critical']) {
      expect(tester.widget<CheckboxListTile>(_control(key)).value, isFalse);
    }
    expect(
      tester.state<FormFieldState<DamageType>>(
        _control('damage-type'),
      ).value,
      DamageType.force,
    );

    await _enter(tester, 'source', 'Bestätigter Treffer');
    await _enter(tester, 'amount', '7');
    await _tap(tester, 'confirm');
    expect(results, hasLength(1));
    expect(results.single?.kind, CharacterEffectKind.damage);
    expect(results.single?.resistant, isFalse);
    expect(results.single?.vulnerable, isFalse);
    expect(results.single?.immune, isFalse);
    expect(results.single?.critical, isFalse);
    expect(results.single?.damageType, DamageType.force);
    expect(jsonEncode(hero.toJson()), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('360 dp: Ersetzfreigabe nach Artenwechsel nicht übernehmen', (
    tester,
  ) async {
    final hero = _hero();
    final before = jsonEncode(hero.toJson());
    final results = await _open(tester, hero, width: 360);
    await _kind(tester, 'Temporäre TP');
    await _tap(tester, 'replace-temporary');
    expect(
      tester.widget<CheckboxListTile>(
        _control('replace-temporary'),
      ).value,
      isTrue,
    );

    await _kind(tester, 'Heilung');
    expect(_control('replace-temporary'), findsNothing);
    await _kind(tester, 'Temporäre TP');
    expect(
      tester.widget<CheckboxListTile>(
        _control('replace-temporary'),
      ).value,
      isFalse,
    );
    await _enter(tester, 'source', 'Bestätigte Schutzwirkung');
    await _enter(tester, 'amount', '3');
    await _tap(tester, 'confirm');
    expect(results.single?.kind, CharacterEffectKind.temporaryHitPoints);
    expect(results.single?.replaceTemporary, isFalse);
    expect(hero.temporaryHitPoints, 5);
    expect(jsonEncode(hero.toJson()), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('320 dp: ausdrückliche Neuwahl und Abbruch ohne Mutation', (
    tester,
  ) async {
    final hero = _hero();
    final before = jsonEncode(hero.toJson());
    final results = await _open(tester, hero, width: 320);
    await _tap(tester, 'immune');
    await _kind(tester, 'Heilung');
    await _kind(tester, 'Schaden');
    await _tap(tester, 'immune');
    expect(
      tester.widget<CheckboxListTile>(_control('immune')).value,
      isTrue,
    );
    await _tap(tester, 'cancel');
    expect(results, [null]);
    expect(jsonEncode(hero.toJson()), before);
    expect(tester.takeException(), isNull);
  });
}
