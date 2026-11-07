import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_preflight_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_target_rules.dart';

SrdSpellDefinition _alter(
  SrdSpellDefinition spell, {
  String? id,
  String? name,
  String? range,
}) => SrdSpellDefinition(
  id: id ?? spell.id,
  name: name ?? spell.name,
  level: spell.level,
  school: spell.school,
  classes: spell.classes,
  castingTime: spell.castingTime,
  range: range ?? spell.range,
  components: spell.components,
  duration: spell.duration,
  verbal: spell.verbal,
  somatic: spell.somatic,
  material: spell.material,
  concentration: spell.concentration,
  ritual: spell.ritual,
);

SrdSpellTargetFacts _facts(String range) => switch (range) {
  'Self' => const SrdSpellTargetFacts(
    mode: SrdSpellOriginMode.caster,
    originDistanceFeet: 0,
  ),
  'Touch' => const SrdSpellTargetFacts(
    mode: SrdSpellOriginMode.touched,
    withinTouchReachConfirmed: true,
    clearPathConfirmed: true,
  ),
  'Sight' => const SrdSpellTargetFacts(
    mode: SrdSpellOriginMode.distant,
    originDistanceFeet: 50,
    visibleOriginConfirmed: true,
    clearPathConfirmed: true,
  ),
  _ => const SrdSpellTargetFacts(
    mode: SrdSpellOriginMode.distant,
    originDistanceFeet: 0,
    clearPathConfirmed: true,
  ),
};

HeroCharacter _wizard() => HeroCharacter(
  id: 'range-catalog-wizard',
  name: 'Reichweitenwächter',
  className: 'Magier',
  level: 5,
  spells: const ['Magic Missile'],
  hitPoints: 25,
  maxHitPoints: 25,
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 16,
    'wisdom': 12,
    'charisma': 10,
  },
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('all 339 indexed spell range entries keep their current behavior', () {
    final vocabulary = catalog.spells.map((spell) => spell.range).toSet();
    expect(vocabulary, hasLength(18));
    var classified = 0;
    var unsupported = 0;
    for (final spell in catalog.spells) {
      if (const {'Special', 'Unlimited'}.contains(spell.range)) {
        expect(
          () => SrdSpellTargetRules.validateOrigin(
            spell,
            _facts(spell.range),
          ),
          throwsUnsupportedError,
          reason: spell.name,
        );
        unsupported++;
      } else {
        final assessed = SrdSpellTargetRules.validateOrigin(
          spell,
          _facts(spell.range),
        );
        expect(assessed.range, spell.range, reason: spell.name);
        classified++;
      }
    }
    expect(classified, 337);
    expect(unsupported, 2);
  });

  test('unindexed but syntactically correct ranges fail closed', () {
    final chromatic = catalog.find('Chromatic Orb')!;
    for (final forged in [
      '1 foot',
      '2 feet',
      '20 feet',
      '999 feet',
      '2 miles',
      '1000 miles',
      'Sight\u200b',
    ]) {
      expect(
        () => SrdSpellTargetRules.validateOrigin(
          _alter(chromatic, range: forged),
          _facts(chromatic.range),
        ),
        throwsUnsupportedError,
        reason: forged,
      );
    }

    // Keep public unit conversion distinct from spell metadata approval.
    expect(SrdSpellTargetRules.maxRangeFeet('1 foot'), 1);
    expect(SrdSpellTargetRules.maxRangeFeet('2 miles'), 10560);
    expect(
      SrdSpellTargetRules.validateOrigin(
        chromatic,
        _facts(chromatic.range),
      ).maxOriginDistanceFeet,
      90,
    );
  });

  test('pinned spell names accept only their own exact ID and range', () {
    const names = [
      'Aid',
      'Burning Hands',
      'Counterspell',
      'Cure Wounds',
      'Dimension Door',
      'Fireball',
      'Magic Missile',
      'Mirage Arcane',
      'Project Image',
      'Sending',
      'Shield',
      'Word of Recall',
    ];
    for (final name in names) {
      final spell = catalog.find(name)!;
      final facts = _facts(spell.range);
      if (spell.range == 'Unlimited') {
        expect(
          () => SrdSpellTargetRules.validateOrigin(spell, facts),
          throwsUnsupportedError,
          reason: name,
        );
      } else {
        final approved = SrdSpellTargetRules.validateOrigin(spell, facts);
        expect(approved.range, spell.range, reason: name);
      }
      final alternative = spell.range == 'Self'
          ? 'Touch'
          : spell.range == 'Touch'
          ? 'Self'
          : spell.range == '60 feet'
          ? '120 feet'
          : '60 feet';
      for (final modified in [
        _alter(spell, range: alternative),
        _alter(spell, id: 'forged-id'),
        _alter(spell, name: 'Forged $name'),
      ]) {
        expect(
          () => SrdSpellTargetRules.validateOrigin(modified, facts),
          throwsFormatException,
          reason: name,
        );
      }
      expect(spell.range, isNotEmpty);
    }
  });

  test('forged range cannot authorize or spend a prepared spell slot', () {
    final hero = _wizard();
    final before = jsonEncode(hero.toJson());
    final missile = catalog.find('Magic Missile')!;
    const target = SrdSpellTargetFacts(
      mode: SrdSpellOriginMode.distant,
      originDistanceFeet: 120,
      clearPathConfirmed: true,
    );
    SrdSpellCastPlan plan(SrdSpellDefinition spell) =>
        SrdSpellPreflightRules.preflight(
          hero,
          spell: spell,
          castingClass: 'Magier',
          slotLevel: 1,
          actionAvailableConfirmed: true,
          targetRulesConfirmed: true,
          targetFacts: target,
          verbalComponentConfirmed: true,
          somaticComponentConfirmed: true,
          slotTurnLimitConfirmed: true,
        );
    final valid = plan(missile);
    expect(valid.targetAssessment!.originDistanceFeet, 120);
    for (final changed in [
      _alter(missile, range: '150 feet'),
      _alter(missile, id: 'not-the-same-spell'),
    ]) {
      expect(() => plan(changed), throwsFormatException);
    }
    expect(jsonEncode(hero.toJson()), before);
    expect(hero.spentSpellSlots, isEmpty);
    expect(hero.spentPactSlots, 0);
  });
}
