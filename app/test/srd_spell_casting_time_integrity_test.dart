import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_casting_time_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_preflight_rules.dart';

SrdSpellDefinition _alter(
  SrdSpellDefinition spell, {
  String? time,
  bool? ritual,
}) => SrdSpellDefinition(
  id: spell.id,
  name: spell.name,
  level: spell.level,
  school: spell.school,
  classes: spell.classes,
  castingTime: time ?? spell.castingTime,
  range: spell.range,
  components: spell.components,
  duration: spell.duration,
  verbal: spell.verbal,
  somatic: spell.somatic,
  material: spell.material,
  concentration: spell.concentration,
  ritual: ritual ?? spell.ritual,
);

HeroCharacter _wizard() => HeroCharacter(
  id: 'spell-time-caster',
  name: 'Zauberwirkzeitprüfung',
  className: 'Magier',
  level: 5,
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 18,
    'wisdom': 12,
    'charisma': 10,
  },
  spells: const ['Detect Magic', 'Magic Missile', 'Counterspell'],
  hitPoints: 26,
  maxHitPoints: 26,
);

SrdSpellCastPlan _plan(HeroCharacter hero, SrdSpellDefinition spell) =>
    SrdSpellPreflightRules.preflight(
      hero,
      spell: spell,
      castingClass: 'Magier',
      slotLevel: 1,
      actionAvailableConfirmed: true,
      targetRulesConfirmed: true,
      verbalComponentConfirmed: true,
      somaticComponentConfirmed: true,
      materialComponentConfirmed: true,
      slotTurnLimitConfirmed: true,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('classifies all 339 working SRD casting times without guessing', () {
    const expected = {
      SrdSpellCastingTimeKind.action: 256,
      SrdSpellCastingTimeKind.bonusAction: 19,
      SrdSpellCastingTimeKind.triggeredBonusAction: 4,
      SrdSpellCastingTimeKind.triggeredReaction: 4,
      SrdSpellCastingTimeKind.extended: 55,
      SrdSpellCastingTimeKind.special: 1,
    };
    final counted = <SrdSpellCastingTimeKind, int>{};
    var rituals = 0;
    for (final spell in catalog.spells) {
      final result = SrdSpellCastingTimeRules.inspect(spell);
      counted.update(result.kind, (count) => count + 1, ifAbsent: () => 1);
      expect(result.ritualOption, spell.ritual, reason: spell.name);
      if (result.ritualOption) rituals++;
      expect(
        result.permitsExistingSingleTurnPreflight,
        const {
          SrdSpellCastingTimeKind.action,
          SrdSpellCastingTimeKind.bonusAction,
        }.contains(result.kind),
        reason: spell.name,
      );
      expect(
        result.ordinaryMinutes == null,
        result.kind != SrdSpellCastingTimeKind.extended,
        reason: spell.name,
      );
    }
    expect(counted, expected);
    expect(rituals, 29);
  });

  test('the ritual option does not make normal Action casting a ritual', () {
    final ritual = catalog.find('Detect Magic')!;
    final assessed = SrdSpellCastingTimeRules.requireSingleTurn(ritual);
    expect(assessed.kind, SrdSpellCastingTimeKind.action);
    expect(assessed.ritualOption, isTrue);
    expect(assessed.ordinaryMinutes, isNull);

    final ordinary = SrdSpellCastingTimeRules.requireSingleTurn(
      catalog.find('Magic Missile')!,
    );
    expect(ordinary.ritualOption, isFalse);
    expect(ordinary.kind, SrdSpellCastingTimeKind.action);
  });

  test('known long spell timings are exact without invented round clock', () {
    final cases = [
      ('Find Familiar', 60, true),
      ('Identify', 1, true),
      ('Forbiddance', 10, true),
      ('Glyph of Warding', 60, false),
      ('Plant Growth', null, false),
    ];
    for (final (name, minutes, ritual) in cases) {
      final spell = catalog.find(name)!;
      final result = SrdSpellCastingTimeRules.inspect(spell);
      expect(result.ordinaryMinutes, minutes, reason: name);
      expect(result.ritualOption, ritual, reason: name);
      expect(
        result.kind,
        minutes == null
            ? SrdSpellCastingTimeKind.special
            : SrdSpellCastingTimeKind.extended,
        reason: name,
      );
      expect(
        () => SrdSpellCastingTimeRules.requireSingleTurn(spell),
        throwsUnsupportedError,
        reason: name,
      );
    }
  });

  test('triggered reaction and bonus action never mint ordinary action', () {
    for (final spell in catalog.spells.where(
      (spell) =>
          spell.castingTime.startsWith('Reaction,') ||
          spell.castingTime.startsWith('Bonus Action,'),
    )) {
      final value = SrdSpellCastingTimeRules.inspect(spell);
      expect(value.permitsExistingSingleTurnPreflight, isFalse);
      expect(
        () => SrdSpellCastingTimeRules.requireSingleTurn(spell),
        throwsUnsupportedError,
        reason: spell.name,
      );
    }
    expect(
      SrdSpellCastingTimeRules.requireSingleTurn(
        catalog.spells.firstWhere(
          (spell) => spell.castingTime == 'Bonus Action',
        ),
      ).kind,
      SrdSpellCastingTimeKind.bonusAction,
    );
  });

  test('constructor bypass cannot forge inconsistent ritual metadata', () {
    final hero = _wizard();
    final before = jsonEncode(hero.toJson());
    final detect = catalog.find('Detect Magic')!;
    final missile = catalog.find('Magic Missile')!;
    expect(_plan(hero, detect).spell.name, 'Detect Magic');
    for (final forged in [
      _alter(detect, time: 'Action'),
      _alter(detect, ritual: false),
      _alter(missile, time: 'Action or Ritual'),
      _alter(missile, ritual: true),
    ]) {
      expect(
        () => SrdSpellCastingTimeRules.inspect(forged),
        throwsFormatException,
      );
      expect(() => _plan(hero, forged), throwsFormatException);
    }
    expect(hero.spentSpellSlots, isEmpty);
    expect(jsonEncode(hero.toJson()), before);
  });

  test('noncanonical spacing, case and invisible controls fail closed', () {
    final missile = catalog.find('Magic Missile')!;
    for (final invalid in [
      '',
      ' Action',
      'Action ',
      'Action\n',
      'action',
      'ACTION',
      'Action\u200b',
      'Action\u202e',
      'Action\u2066',
      'Action or Ritual ',
      'Action  or Ritual',
      'Action,',
      'Bonus Action, which you take ',
      'Reaction, which you take',
      'Reaction, which you take \u200fwhen attacked',
      '1 Minutes',
      '0 minutes',
      '100 hours',
      '1 minute or Ritual ',
    ]) {
      final forged = _alter(missile, time: invalid);
      expect(
        () => SrdSpellCastingTimeRules.inspect(forged),
        throwsA(anyOf(isA<FormatException>(), isA<UnsupportedError>())),
        reason: invalid,
      );
    }
  });

  test('triggered time text cannot escape explicit trigger path', () {
    final missile = catalog.find('Magic Missile')!;
    for (final text in [
      'Reaction, which you take when hit',
      'Bonus Action, which you take after attacking',
    ]) {
      final forged = _alter(missile, time: text);
      final assessment = SrdSpellCastingTimeRules.inspect(forged);
      expect(assessment.permitsExistingSingleTurnPreflight, isFalse);
      expect(() => _plan(_wizard(), forged), throwsUnsupportedError);
    }
  });

  test('the existing preflight still denies unverified reactions and time', () {
    final hero = _wizard();
    expect(
      () => _plan(hero, catalog.find('Counterspell')!),
      throwsUnsupportedError,
    );
    final prepared = _plan(hero, catalog.find('Magic Missile')!);
    expect(prepared.slotLevel, 1);
    expect(hero.spentSpellSlots, isEmpty);
    expect(
      () => SrdSpellPreflightRules.recordConfirmedResourceUse(
        hero,
        prepared,
        effectResolvedSeparatelyConfirmed: false,
      ),
      throwsStateError,
    );
  });
}
