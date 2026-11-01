import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_preflight_rules.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

HeroCharacter _hero({
  String first = 'Magier',
  String second = 'Zauberer',
  int totalLevel = 6,
  int secondLevel = 3,
  List<String> spells = const ['Magisches Geschoss', 'Licht'],
}) => HeroCharacter(
  id: 'class-preparation',
  name: 'Tira',
  className: first,
  secondaryClassName: second,
  secondaryClassLevel: secondLevel,
  level: totalLevel,
  spells: spells,
  hitPoints: 21,
  maxHitPoints: 21,
);

SrdSpellDefinition _spell({
  String name = 'Magic Missile',
  int level = 1,
  List<String> classes = const ['Sorcerer', 'Wizard'],
}) => SrdSpellDefinition(
  id: 'test-prepared-class',
  name: name,
  level: level,
  school: 'Evocation',
  classes: classes,
  castingTime: 'Action',
  range: '120 feet',
  components: 'V, S',
  duration: 'Instantaneous',
  verbal: true,
  somatic: true,
  material: false,
  concentration: false,
  ritual: false,
);

SrdSpellCastPlan _prepare(
  HeroCharacter hero, {
  required SrdSpellDefinition spell,
  String castingClass = 'Magier',
  int? slotLevel,
  bool classConfirmed = false,
}) => SrdSpellPreflightRules.preflight(
  hero,
  spell: spell,
  castingClass: castingClass,
  slotLevel: slotLevel ?? spell.level,
  preparedForCastingClassConfirmed: classConfirmed,
  actionAvailableConfirmed: true,
  targetRulesConfirmed: true,
  verbalComponentConfirmed: true,
  somaticComponentConfirmed: true,
  slotTurnLimitConfirmed: true,
);

void main() {
  setUpAll(sqfliteFfiInit);

  test(
    'shared spell on both eligible classes requires explicit class choice',
    () {
      final hero = _hero();
      final before = hero.toJson();
      final spell = _spell();
      for (final castingClass in ['Magier', 'Wizard', 'Zauberer', 'Sorcerer']) {
        expect(
          () => _prepare(hero, spell: spell, castingClass: castingClass),
          throwsFormatException,
          reason: castingClass,
        );
      }
      expect(hero.toJson(), before);
      expect(hero.spentSpellSlots, isEmpty);
    },
  );

  test('confirmed source binds chosen class to original hero and spell', () {
    final hero = _hero();
    final spell = _spell();
    final plan = _prepare(
      hero,
      spell: spell,
      castingClass: 'wizard',
      classConfirmed: true,
    );
    expect(plan.castingClass, 'Magier');
    expect(plan.preparedName, 'Magisches Geschoss');
    expect(hero.spentSpellSlots, isEmpty);
    final after = SrdSpellPreflightRules.recordConfirmedResourceUse(
      hero,
      plan,
      effectResolvedSeparatelyConfirmed: true,
    );
    expect(after.hero.spentSpellSlots, {'1': 1});
    expect(hero.spentSpellSlots, isEmpty);
    expect(
      () => SrdSpellPreflightRules.recordConfirmedResourceUse(
        after.hero,
        plan,
        effectResolvedSeparatelyConfirmed: true,
      ),
      throwsFormatException,
    );
    expect(
      () => SrdSpellPreflightRules.recordConfirmedResourceUse(
        hero.copyWith(spells: const ['Licht']),
        plan,
        effectResolvedSeparatelyConfirmed: true,
      ),
      throwsFormatException,
    );
  });

  test(
    'only one class at sufficient level needs no ambiguous confirmation',
    () {
      final hero = _hero(
        totalLevel: 6,
        secondLevel: 5,
        spells: const ['Fireball'],
      );
      final spell = _spell(name: 'Fireball', level: 3);
      expect(
        () => _prepare(
          hero,
          spell: spell,
          castingClass: 'Magier',
          slotLevel: 3,
          classConfirmed: true,
        ),
        throwsFormatException,
      );
      final legal = _prepare(
        hero,
        spell: spell,
        castingClass: 'Zauberer',
        slotLevel: 3,
      );
      expect(legal.castingClass, 'Zauberer');
      expect(legal.slotLevel, 3);
      expect(hero.spentSpellSlots, isEmpty);
    },
  );

  test('unique class-list membership is unambiguous for multiclass heroes', () {
    final hero = _hero(second: 'Kleriker', spells: const ['Wunden heilen']);
    final spell = _spell(
      name: 'Cure Wounds',
      classes: const ['Bard', 'Cleric', 'Druid', 'Paladin', 'Ranger'],
    );
    final plan = _prepare(hero, spell: spell, castingClass: 'Kleriker');
    expect(plan.preparedName, 'Wunden heilen');
    expect(plan.castingClass, 'Kleriker');
    expect(
      () => _prepare(
        hero,
        spell: spell,
        castingClass: 'Magier',
        classConfirmed: true,
      ),
      throwsFormatException,
    );
  });

  test('unconfirmed shared cantrip is blocked without using a spell slot', () {
    final hero = _hero();
    final spell = _spell(
      name: 'Light',
      level: 0,
      classes: const ['Cleric', 'Bard', 'Sorcerer', 'Wizard'],
    );
    expect(() => _prepare(hero, spell: spell), throwsFormatException);
    final plan = _prepare(
      hero,
      spell: spell,
      castingClass: 'Sorcerer',
      classConfirmed: true,
    );
    final result = SrdSpellPreflightRules.recordConfirmedResourceUse(
      hero,
      plan,
      effectResolvedSeparatelyConfirmed: true,
    );
    expect(result.hero.spentSpellSlots, isEmpty);
    expect(hero.toJson(), result.hero.toJson());
  });

  test(
    'single-class characters preserve existing legacy spell preparation',
    () {
      final hero = _hero(second: '', secondLevel: 0, totalLevel: 3);
      final plan = _prepare(hero, spell: _spell());
      expect(plan.castingClass, 'Magier');
      expect(plan.preparedName, 'Magisches Geschoss');
    },
  );

  test('JSON restart keeps raw class labels and requires the choice again', () {
    final source = _hero();
    final raw = source.toJson();
    final restored = HeroCharacter.fromJson(raw);
    expect(restored.toJson(), raw);
    expect(restored.className, 'Magier');
    expect(restored.secondaryClassName, 'Zauberer');
    expect(() => _prepare(restored, spell: _spell()), throwsFormatException);
    final plan = _prepare(restored, spell: _spell(), classConfirmed: true);
    expect(plan.castingClass, 'Magier');
    expect(restored.toJson(), raw);
  });

  test('SQLite restart does not grant implicit class ownership', () async {
    final directory = await Directory.systemTemp.createTemp('spell-owner-');
    final path = '${directory.path}/campaign.sqlite';
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      final campaign = Campaign(
        id: 'prepared-source',
        name: 'Bestätigte Zauberquelle',
        world: 'Test',
        sessionId: 'session',
        scene: 'Beginn',
        hero: _hero(),
      );
      await repository.saveCampaign(campaign);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final reloaded = (await repository.getCampaign(campaign.id))!;
      final raw = reloaded.toJson();
      expect(
        () => _prepare(reloaded.hero, spell: _spell()),
        throwsFormatException,
      );
      expect(reloaded.hero.spentSpellSlots, isEmpty);
      expect((await repository.getCampaign(campaign.id))!.toJson(), raw);

      final plan = _prepare(
        reloaded.hero,
        spell: _spell(),
        classConfirmed: true,
      );
      expect(plan.castingClass, 'Magier');
      expect((await repository.getCampaign(campaign.id))!.toJson(), raw);
    } finally {
      await repository.close();
      await directory.delete(recursive: true);
    }
  });
}
