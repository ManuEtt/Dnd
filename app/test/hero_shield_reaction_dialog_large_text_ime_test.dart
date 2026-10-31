import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/hero_shield_reaction_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/hero_shield_reaction_dialog.dart';

HeroCharacter _hero({bool prepared = true}) => HeroCharacter(
  id: 'shield-ui-hero',
  name: 'Mira',
  className: 'Magier',
  level: 5,
  spells: prepared ? const ['Schild'] : const [],
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
  armorClass: 14,
  speed: 9,
  weaponDamage: '1d4',
);

Future<void> _open(
  WidgetTester tester,
  HeroCharacter hero, {
  required double width,
  required ValueChanged<HeroShieldReactionPlan?> onResult,
}) async {
  tester.view.physicalSize = Size(width, 680);
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = const FakeViewPadding(bottom: 220);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
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
            key: const ValueKey('open-hero-shield'),
            onPressed: () async {
              onResult(
                await showDialog<HeroShieldReactionPlan>(
                  context: context,
                  builder: (_) => HeroShieldReactionDialog(hero: hero),
                ),
              );
            },
            child: const Text('Schild öffnen'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('open-hero-shield')));
  await tester.pumpAndSettle();
}

Future<void> _tapScrolled(WidgetTester tester, String key) async {
  final target = find.byKey(ValueKey(key));
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  expect(target.hitTestable(), findsOneWidget);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  for (final width in [320.0, 360.0]) {
    testWidgets('Schilddialog bei $width dp/200 %/IME scrollt und bricht ab', (
      tester,
    ) async {
      final hero = _hero();
      final before = hero.toJson();
      final results = <HeroShieldReactionPlan?>[];
      await _open(tester, hero, width: width, onResult: results.add);

      expect(
        tester.widget<AlertDialog>(find.byType(AlertDialog)).scrollable,
        isTrue,
      );
      final checkbox = find.byKey(const ValueKey('hero-shield-somatic'));
      final dialogScroll = find.ancestor(
        of: checkbox,
        matching: find.byType(Scrollable),
      );
      expect(dialogScroll, findsOneWidget);
      final cancel = find.text('Abbrechen');
      expect(cancel.hitTestable(), findsOneWidget);
      await tester.tap(cancel);
      await tester.pumpAndSettle();

      expect(results, [null]);
      expect(hero.toJson(), before);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('320 dp/IME: Schild nur nach beiden Bestätigungen', (
    tester,
  ) async {
    final hero = _hero();
    final before = hero.toJson();
    final results = <HeroShieldReactionPlan?>[];
    await _open(tester, hero, width: 320, onResult: results.add);

    final confirm = find.byKey(const ValueKey('hero-shield-confirm'));
    expect(tester.widget<FantasyTextButton>(confirm).onPressed, isNotNull);
    expect(confirm.hitTestable(), findsOneWidget);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('hero-shield-error')), findsOneWidget);
    expect(results, isEmpty);
    await _tapScrolled(tester, 'hero-shield-verbal');
    await _tapScrolled(tester, 'hero-shield-somatic');
    expect(confirm.hitTestable(), findsOneWidget);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(results, hasLength(1));
    expect(results.single!.castingClass, 'Magier');
    expect(results.single!.slotLevel, 1);
    expect(results.single!.pactMagic, isFalse);
    expect(results.single!.verbalConfirmed, isTrue);
    expect(results.single!.somaticConfirmed, isTrue);
    expect(hero.toJson(), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ohne vorbereiteten Schild bleibt Bestätigung gesperrt', (
    tester,
  ) async {
    final hero = _hero(prepared: false);
    final before = hero.toJson();
    final results = <HeroShieldReactionPlan?>[];
    await _open(tester, hero, width: 320, onResult: results.add);

    expect(find.text('Der Zauber Schild ist nicht vorbereitet.'), findsOneWidget);
    final confirm = find.byKey(const ValueKey('hero-shield-confirm'));
    expect(tester.widget<FantasyTextButton>(confirm).onPressed, isNull);
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();

    expect(results, [null]);
    expect(hero.toJson(), before);
    expect(tester.takeException(), isNull);
  });
}
