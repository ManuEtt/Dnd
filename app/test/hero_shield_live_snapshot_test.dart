import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/hero_shield_reaction_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/hero_shield_reaction_dialog.dart';

HeroCharacter _hero({
  String id = 'shield-hero',
  String className = 'Magier',
  int level = 5,
  List<String> spells = const ['Schild'],
}) => HeroCharacter(
  id: id,
  name: 'Mira',
  className: className,
  level: level,
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
  armorClass: 14,
  speed: 9,
  weaponDamage: '1d4',
);

Finder _field(String name) => find.byKey(ValueKey('hero-shield-$name'));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _selectSlot(WidgetTester tester, String label) async {
  await _tap(tester, _field('slot'));
  await _tap(tester, find.text(label).last);
}

Future<void> _approve(WidgetTester tester) async {
  await _tap(tester, _field('verbal'));
  await _tap(tester, _field('somatic'));
}

bool _checked(WidgetTester tester, String name) =>
    tester.widget<CheckboxListTile>(_field(name)).value ?? false;

Future<void> _show(
  WidgetTester tester, {
  required HeroCharacter Function() hero,
  required ValueChanged<StateSetter> onRebuild,
  required ValueChanged<HeroShieldReactionPlan?> onResult,
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
              final choice = await showDialog<HeroShieldReactionPlan>(
                context: context,
                builder: (_) => StatefulBuilder(
                  builder: (context, rebuild) {
                    onRebuild(rebuild);
                    return HeroShieldReactionDialog(hero: hero());
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
  testWidgets('Same hero preserves chosen slot and consent on rebuild', (
    tester,
  ) async {
    final hero = _hero();
    final before = hero.toJson();
    StateSetter? rebuild;
    final plans = <HeroShieldReactionPlan?>[];
    await _show(
      tester,
      hero: () => hero,
      onRebuild: (value) => rebuild = value,
      onResult: plans.add,
    );
    await _selectSlot(tester, 'Grad 3 – 2 frei');
    await _approve(tester);
    rebuild!(() {});
    await tester.pumpAndSettle();

    expect(_checked(tester, 'verbal'), isTrue);
    expect(_checked(tester, 'somatic'), isTrue);
    expect(find.text('Grad 3 – 2 frei'), findsOneWidget);
    await _tap(tester, _field('confirm'));

    expect(plans, hasLength(1));
    expect(plans.single?.slotLevel, 3);
    expect(plans.single?.castingClass, 'Magier');
    expect(plans.single?.verbalConfirmed, isTrue);
    expect(hero.toJson(), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('New hero replaces old class, slot and confirmations', (
    tester,
  ) async {
    var hero = _hero();
    final before = hero.toJson();
    StateSetter? rebuild;
    final plans = <HeroShieldReactionPlan?>[];
    await _show(
      tester,
      hero: () => hero,
      onRebuild: (value) => rebuild = value,
      onResult: plans.add,
    );
    await _selectSlot(tester, 'Grad 3 – 2 frei');
    await _approve(tester);
    rebuild!(() => hero = _hero(
      id: 'new-sorcerer',
      className: 'Zauberer',
      level: 1,
    ));
    await tester.pumpAndSettle();

    expect(find.text('Grad 3 – 2 frei'), findsNothing);
    expect(find.text('Magier'), findsNothing);
    expect(find.text('Zauberer'), findsOneWidget);
    expect(find.text('Grad 1 – 2 frei'), findsOneWidget);
    expect(_checked(tester, 'verbal'), isFalse);
    expect(_checked(tester, 'somatic'), isFalse);
    await _tap(tester, _field('confirm'));
    expect(_field('error'), findsOneWidget);
    expect(plans, isEmpty);

    await _approve(tester);
    await _tap(tester, _field('confirm'));
    expect(plans, hasLength(1));
    expect(plans.single?.slotLevel, 1);
    expect(plans.single?.castingClass, 'Zauberer');
    expect(plans.single?.somaticConfirmed, isTrue);
    expect(before['spentSpellSlots'], isNot({'1': 1}));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Spent slots and lost preparation disable stale consent', (
    tester,
  ) async {
    var hero = _hero(level: 1);
    StateSetter? rebuild;
    final plans = <HeroShieldReactionPlan?>[];
    await _show(
      tester,
      hero: () => hero,
      onRebuild: (value) => rebuild = value,
      onResult: plans.add,
    );
    await _approve(tester);
    rebuild!(() {
      hero = _hero(id: 'spent-hero', level: 1).copyWith(
        spentSpellSlots: {'1': 2},
      );
    });
    await tester.pumpAndSettle();

    expect(_checked(tester, 'verbal'), isFalse);
    expect(_checked(tester, 'somatic'), isFalse);
    expect(
      tester.widget<FantasyTextButton>(_field('confirm')).onPressed,
      isNull,
    );
    expect(find.text('Grad 1 – 2 frei'), findsNothing);
    rebuild!(() => hero = _hero(id: 'unprepared', spells: const []));
    await tester.pumpAndSettle();

    expect(
      find.text('Der Zauber Schild ist nicht vorbereitet.'),
      findsOneWidget,
    );
    expect(
      tester.widget<FantasyTextButton>(_field('confirm')).onPressed,
      isNull,
    );
    await _tap(tester, find.text('Abbrechen'));
    expect(plans, [null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Invalid live class clears options without throwing', (
    tester,
  ) async {
    var hero = _hero();
    StateSetter? rebuild;
    final plans = <HeroShieldReactionPlan?>[];
    await _show(
      tester,
      hero: () => hero,
      onRebuild: (value) => rebuild = value,
      onResult: plans.add,
    );
    await _approve(tester);
    rebuild!(() => hero = _hero(id: 'invalid', className: 'Unbekannt'));
    await tester.pumpAndSettle();

    expect(_checked(tester, 'verbal'), isFalse);
    expect(_checked(tester, 'somatic'), isFalse);
    expect(_field('error'), findsOneWidget);
    expect(
      tester.widget<FantasyTextButton>(_field('confirm')).onPressed,
      isNull,
    );
    await _tap(tester, find.text('Abbrechen'));
    expect(plans, [null]);
    expect(tester.takeException(), isNull);
  });
}
