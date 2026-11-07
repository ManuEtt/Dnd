import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_preflight_rules.dart';

HeroCharacter _caster({
  String first = 'Magier',
  String second = '',
  int level = 5,
  int secondLevel = 0,
}) => HeroCharacter(
  id: 'spell-class-profile',
  name: 'Klassenprofil',
  className: first,
  secondaryClassName: second,
  secondaryClassLevel: secondLevel,
  level: level,
  spells: const ['Fire Bolt', 'Magic Missile'],
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
);

SrdSpellCastPlan _preflight(
  HeroCharacter hero,
  SrdSpellDefinition spell,
) => SrdSpellPreflightRules.preflight(
  hero,
  spell: spell,
  castingClass: 'Wizard',
  slotLevel: spell.level,
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

  test('known single and multiclass profiles retain authorized casting', () {
    final cantrip = catalog.find('Fire Bolt')!;
    final first = _caster();
    final english = _caster(first: 'Wizard');
    final multiclass = _caster(
      first: 'Wizard',
      second: 'Fighter',
      secondLevel: 2,
    );
    final secondaryCaster = _caster(
      first: 'Kämpfer',
      second: 'Magier',
      level: 6,
      secondLevel: 4,
    );

    for (final hero in [first, english, multiclass, secondaryCaster]) {
      final original = jsonEncode(hero.toJson());
      final plan = _preflight(hero, cantrip);
      expect(plan.castingClass, 'Magier');
      expect(plan.slotLevel, 0);
      expect(jsonEncode(hero.toJson()), original);
      expect(hero.spentSpellSlots, isEmpty);
    }
    final missile = catalog.find('Magic Missile')!;
    final slotPlan = _preflight(multiclass, missile);
    expect(slotPlan.castingClass, 'Magier');
    expect(slotPlan.slotLevel, 1);
    expect(multiclass.spentSpellSlots, isEmpty);
  });

  test('unknown, duplicate and inconsistent classes fail before casting', () {
    final cantrip = catalog.find('Fire Bolt')!;
    final missile = catalog.find('Magic Missile')!;
    final invalid = [
      _caster(first: 'Unbekannte Klasse'),
      _caster(second: 'Unbekannte Klasse', secondLevel: 1),
      _caster(second: 'Wizard', secondLevel: 1),
      _caster(second: 'Magier', secondLevel: 1),
      _caster(second: 'Fighter', secondLevel: 0),
      _caster(second: '', secondLevel: 1),
      _caster(second: ' ', secondLevel: 0),
      _caster(second: 'Fighter', secondLevel: -1),
      _caster(second: 'Fighter', secondLevel: 5),
      _caster(level: 0),
      _caster(level: 21),
    ];

    for (final hero in invalid) {
      final original = jsonEncode(hero.toJson());
      for (final spell in [cantrip, missile]) {
        expect(
          () => _preflight(hero, spell),
          throwsFormatException,
          reason: hero.classSummary,
        );
      }
      expect(jsonEncode(hero.toJson()), original);
      expect(hero.spentSpellSlots, isEmpty);
      expect(hero.spentPactSlots, 0);
    }
  });
}
