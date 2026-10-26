import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/sacred_flame_dialog.dart';

HeroCharacter _hero({
  String primary = 'Magier',
  String secondary = 'Kleriker',
}) => HeroCharacter.fromJson(
  HeroCharacter(
    id: 'sacred-class-dialog',
    name: 'Arina',
    className: primary,
    secondaryClassName: secondary,
    secondaryClassLevel: 1,
    level: 6,
    spells: const ['Heilige Flamme'],
    abilities: const {
      'strength': 10,
      'dexterity': 12,
      'constitution': 14,
      'intelligence': 20,
      'wisdom': 12,
      'charisma': 14,
    },
    hitPoints: 20,
    maxHitPoints: 20,
    armorClass: 14,
    speed: 9,
  ).toJson(),
);
const _fight = Encounter(
  id: 'foe',
  enemyName: 'Wächter',
  enemyHitPoints: 30,
  enemyMaxHitPoints: 30,
);

Future<void> _tick(WidgetTester tester, String suffix) async {
  final tile = find.byKey(ValueKey('sacred-flame-$suffix'));
  final found = find.descendant(of: tile, matching: find.byType(Checkbox));
  await tester.ensureVisible(found);
  await tester.pumpAndSettle();
  await tester.tap(found);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'class-specific Wisdom DC preview requires actual modifier confirmation',
    (tester) async {
      final hero = _hero();
      final original = hero.toJson();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SacredFlameDialog(hero: hero, encounter: _fight),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('sacred-flame-class-stats')),
        findsNothing,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('sacred-flame-dc')),
            )
            .value,
        isFalse,
      );
      await _tick(tester, 'dc');
      final text = tester
          .widget<Text>(find.byKey(const ValueKey('sacred-flame-class-stats')))
          .data!;
      expect(text, contains('Weisheit 12'));
      expect(text, contains('Übungsbonus +3'));
      expect(text, contains('Zauber-SG 12'));
      await _tick(tester, 'dc');
      expect(
        find.byKey(const ValueKey('sacred-flame-class-stats')),
        findsNothing,
      );
      expect(hero.toJson(), original);
    },
  );

  for (final primary in ['Cleric', 'Unbekannt']) {
    testWidgets('invalid imported $primary/Cleric cannot be confirmed', (
      tester,
    ) async {
      final hero = _hero(primary: primary);
      final before = hero.toJson();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SacredFlameDialog(hero: hero, encounter: _fight),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const ValueKey('sacred-flame-enemy-save-modifier')),
        '0',
      );
      for (final key in [
        'visible',
        'range',
        'verbal',
        'somatic',
        'radiant-defense',
        'dc',
        'circumstances',
      ]) {
        await _tick(tester, key);
      }
      expect(
        find.byKey(const ValueKey('sacred-flame-class-stats-invalid')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('sacred-flame-class-stats')),
        findsNothing,
      );
      expect(
        tester
            .widget<FantasyTextButton>(
              find.byKey(const ValueKey('sacred-flame-cast')),
            )
            .onPressed,
        isNull,
      );
      expect(hero.toJson(), before);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'valid confirmed multiclass returns existing choice without mutating character',
    (tester) async {
      final hero = _hero();
      final before = hero.toJson();
      SacredFlameChoice? choice;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  choice = await showDialog<SacredFlameChoice>(
                    context: context,
                    builder: (_) =>
                        SacredFlameDialog(hero: hero, encounter: _fight),
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
      await tester.enterText(
        find.byKey(const ValueKey('sacred-flame-enemy-save-modifier')),
        '0',
      );
      for (final key in [
        'visible',
        'range',
        'verbal',
        'somatic',
        'radiant-defense',
        'dc',
        'circumstances',
      ]) {
        await _tick(tester, key);
      }
      await tester.tap(find.byKey(const ValueKey('sacred-flame-cast')));
      await tester.pumpAndSettle();
      expect(choice, isNotNull);
      expect(choice!.noUnmodelledDcModifiersConfirmed, isTrue);
      expect(choice!.confirmedTargetDexteritySaveModifier, 0);
      expect(hero.toJson(), before);
    },
  );

  testWidgets(
    'DC preview remains readable at 360dp with large text and keyboard',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.8),
              viewInsets: const EdgeInsets.only(bottom: 200),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) =>
                      SacredFlameDialog(hero: _hero(), encounter: _fight),
                ),
                child: const Text('Öffnen'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Öffnen'));
      await tester.pumpAndSettle();
      await _tick(tester, 'dc');
      expect(
        tester
            .widget<CheckboxListTile>(
              find.byKey(const ValueKey('sacred-flame-dc')),
            )
            .value,
        isTrue,
      );
      expect(
        find.byKey(const ValueKey('sacred-flame-class-stats-invalid')),
        findsNothing,
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('sacred-flame-class-stats')),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('sacred-flame-class-stats')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
