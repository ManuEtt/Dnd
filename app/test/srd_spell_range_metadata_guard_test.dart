import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_preflight_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_target_rules.dart';

SrdSpellDefinition _withRange(SrdSpellDefinition source, String range) =>
    SrdSpellDefinition(
      id: source.id,
      name: source.name,
      level: source.level,
      school: source.school,
      classes: source.classes,
      castingTime: source.castingTime,
      range: range,
      components: source.components,
      duration: source.duration,
      verbal: source.verbal,
      somatic: source.somatic,
      material: source.material,
      concentration: source.concentration,
      ritual: source.ritual,
    );

const _self = SrdSpellTargetFacts(
  mode: SrdSpellOriginMode.caster,
  originDistanceFeet: 0,
);
const _touch = SrdSpellTargetFacts(
  mode: SrdSpellOriginMode.touched,
  clearPathConfirmed: true,
  withinTouchReachConfirmed: true,
);
const _sight = SrdSpellTargetFacts(
  mode: SrdSpellOriginMode.distant,
  originDistanceFeet: 50,
  clearPathConfirmed: true,
  visibleOriginConfirmed: true,
);
const _distance = SrdSpellTargetFacts(
  mode: SrdSpellOriginMode.distant,
  originDistanceFeet: 120,
  clearPathConfirmed: true,
);

HeroCharacter _wizard() => HeroCharacter(
  id: 'spell-range-metadata-caster',
  name: 'Reichweitentest',
  className: 'Magier',
  level: 5,
  spells: const ['Magic Missile'],
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 16,
    'wisdom': 12,
    'charisma': 10,
  },
  hitPoints: 28,
  maxHitPoints: 28,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('all catalogue ranges remain supported or explicitly unsupported', () {
    var unsupported = 0;
    for (final spell in catalog.spells) {
      final facts = switch (spell.range) {
        'Self' => _self,
        'Touch' => _touch,
        'Sight' => _sight,
        _ => const SrdSpellTargetFacts(
          mode: SrdSpellOriginMode.distant,
          originDistanceFeet: 0,
          clearPathConfirmed: true,
        ),
      };
      if (const {'Unlimited', 'Special'}.contains(spell.range)) {
        unsupported++;
        expect(
          () => SrdSpellTargetRules.validateOrigin(spell, facts),
          throwsUnsupportedError,
          reason: spell.name,
        );
      } else {
        expect(
          SrdSpellTargetRules.validateOrigin(spell, facts).range,
          spell.range,
          reason: spell.name,
        );
      }
    }
    expect(unsupported, 2);
  });

  test('Self, Touch and Sight reject added boundary whitespace', () {
    final cases = [
      (catalog.find('Burning Hands')!, _self),
      (catalog.find('Cure Wounds')!, _touch),
      (catalog.find('Mirage Arcane')!, _sight),
    ];
    for (final (spell, facts) in cases) {
      expect(
        SrdSpellTargetRules.validateOrigin(spell, facts).range,
        spell.range,
      );
      for (final invalid in [
        ' ${spell.range}',
        '${spell.range} ',
        '\n${spell.range}',
        '${spell.range}\t',
      ]) {
        expect(
          () => SrdSpellTargetRules.validateOrigin(
            _withRange(spell, invalid),
            facts,
          ),
          throwsFormatException,
          reason: invalid,
        );
      }
    }
  });

  test('numeric ranges reject whitespace and mixed-case metadata', () {
    final missile = catalog.find('Magic Missile')!;
    expect(
      SrdSpellTargetRules.validateOrigin(
        missile,
        _distance,
      ).maxOriginDistanceFeet,
      120,
    );

    for (final invalid in [
      ' 120 feet',
      '120 feet ',
      '\n120 feet',
      '120 feet\t',
      '120 feet\u00a0',
    ]) {
      expect(SrdSpellTargetRules.maxRangeFeet(invalid), isNull);
      expect(
        () => SrdSpellTargetRules.validateOrigin(
          _withRange(missile, invalid),
          _distance,
        ),
        throwsFormatException,
        reason: invalid,
      );
    }
    for (final invalid in ['120 FEET', '120 Feet', '120 feEt']) {
      expect(SrdSpellTargetRules.maxRangeFeet(invalid), isNull);
      expect(
        () => SrdSpellTargetRules.validateOrigin(
          _withRange(missile, invalid),
          _distance,
        ),
        throwsUnsupportedError,
        reason: invalid,
      );
    }
  });

  test('canonical singular and plural ranges keep exact boundaries', () {
    expect(SrdSpellTargetRules.maxRangeFeet('1 foot'), 1);
    expect(SrdSpellTargetRules.maxRangeFeet('5 feet'), 5);
    expect(SrdSpellTargetRules.maxRangeFeet('1 mile'), 5280);
    expect(SrdSpellTargetRules.maxRangeFeet('2 miles'), 10560);
    expect(SrdSpellTargetRules.maxRangeFeet('01 mile'), isNull);
    expect(SrdSpellTargetRules.maxRangeFeet('2 mile'), isNull);
    expect(SrdSpellTargetRules.maxRangeFeet('0 feet'), isNull);
  });

  test('invalid range blocks preflight without a slot spend', () {
    final hero = _wizard();
    final before = jsonEncode(hero.toJson());
    final original = catalog.find('Magic Missile')!;

    SrdSpellCastPlan preflight(SrdSpellDefinition spell) =>
        SrdSpellPreflightRules.preflight(
          hero,
          spell: spell,
          castingClass: 'Magier',
          slotLevel: 1,
          actionAvailableConfirmed: true,
          targetRulesConfirmed: true,
          targetFacts: _distance,
          verbalComponentConfirmed: true,
          somaticComponentConfirmed: true,
          slotTurnLimitConfirmed: true,
        );

    expect(preflight(original).targetAssessment!.originDistanceFeet, 120);
    expect(
      () => preflight(_withRange(original, '120 feet\n')),
      throwsFormatException,
    );
    expect(jsonEncode(hero.toJson()), before);
    expect(hero.spentSpellSlots, isEmpty);
  });
}
