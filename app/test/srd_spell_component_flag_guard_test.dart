import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_component_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_preflight_rules.dart';

SrdSpellDefinition _changed(
  SrdSpellDefinition source, {
  String? components,
  bool? verbal,
  bool? somatic,
  bool? material,
}) => SrdSpellDefinition(
  id: source.id,
  name: source.name,
  level: source.level,
  school: source.school,
  classes: source.classes,
  castingTime: source.castingTime,
  range: source.range,
  components: components ?? source.components,
  duration: source.duration,
  verbal: verbal ?? source.verbal,
  somatic: somatic ?? source.somatic,
  material: material ?? source.material,
  concentration: source.concentration,
  ritual: source.ritual,
);

HeroCharacter _wizard() => HeroCharacter(
  id: 'spell-component-guard',
  name: 'Komponentenprüfung',
  className: 'Magier',
  level: 5,
  spells: const ['Chromatic Orb', 'Magic Missile'],
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 16,
    'wisdom': 12,
    'charisma': 10,
  },
  maxHitPoints: 27,
  hitPoints: 27,
);

SrdSpellCastPlan _plan(
  HeroCharacter hero,
  SrdSpellDefinition spell, {
  bool verbal = true,
  bool somatic = true,
  bool material = false,
  bool costly = false,
}) => SrdSpellPreflightRules.preflight(
  hero,
  spell: spell,
  castingClass: 'Magier',
  slotLevel: 1,
  actionAvailableConfirmed: true,
  targetRulesConfirmed: true,
  verbalComponentConfirmed: verbal,
  somaticComponentConfirmed: somatic,
  materialComponentConfirmed: material,
  costlyComponentAvailableConfirmed: costly,
  slotTurnLimitConfirmed: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('all catalogue entries retain valid component metadata', () {
    for (final spell in catalog.spells) {
      SrdSpellDefinition.validateComponentMetadata(
        components: spell.components,
        verbal: spell.verbal,
        somatic: spell.somatic,
        material: spell.material,
      );
      expect(
        SrdSpellComponentRules.requirements(spell).hasMaterial,
        spell.material,
        reason: spell.name,
      );
    }
  });

  test('a forged M=false flag cannot waive a costly material', () {
    final spell = _changed(catalog.find('Chromatic Orb')!, material: false);
    final hero = _wizard();
    final before = jsonEncode(hero.toJson());

    expect(
      () => SrdSpellComponentRules.requirements(spell),
      throwsFormatException,
    );
    expect(
      () => SrdSpellComponentRules.validateMaterial(
        spell,
        materialComponentConfirmed: false,
      ),
      throwsFormatException,
    );
    expect(() => _plan(hero, spell), throwsFormatException);
    expect(jsonEncode(hero.toJson()), before);
    expect(hero.spentSpellSlots, isEmpty);
  });

  test('forged verbal and somatic flags cannot waive confirmations', () {
    final original = catalog.find('Magic Missile')!;
    final hero = _wizard();
    final before = jsonEncode(hero.toJson());

    expect(
      () => _plan(hero, _changed(original, verbal: false), verbal: false),
      throwsFormatException,
    );
    expect(
      () => _plan(hero, _changed(original, somatic: false), somatic: false),
      throwsFormatException,
    );
    expect(
      () => _plan(
        hero,
        _changed(original, verbal: false, somatic: false),
        verbal: false,
        somatic: false,
      ),
      throwsFormatException,
    );
    expect(jsonEncode(hero.toJson()), before);
  });

  test('invented materials and malformed direct metadata fail closed', () {
    final original = catalog.find('Magic Missile')!;
    for (final spell in [
      _changed(original, material: true),
      _changed(original, components: 'V, S, M'),
      _changed(original, components: 'V, S, M ()', material: true),
      _changed(original, components: 'V, V, S'),
      _changed(original, components: 'S, V'),
    ]) {
      expect(
        () => SrdSpellComponentRules.requirements(spell),
        throwsFormatException,
        reason: spell.components,
      );
    }
  });

  test('valid costly material still requires approval and spends no slot', () {
    final hero = _wizard();
    final spell = catalog.find('Chromatic Orb')!;
    final before = jsonEncode(hero.toJson());

    expect(() => _plan(hero, spell), throwsFormatException);
    final plan = _plan(hero, spell, material: true, costly: true);
    expect(plan.spell.name, spell.name);
    expect(plan.hasConsumedMaterial, isFalse);
    expect(jsonEncode(hero.toJson()), before);
    expect(hero.spentSpellSlots, isEmpty);
  });
}
