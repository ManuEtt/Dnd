import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_ritual_casting_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';

SrdSpellDefinition _alter(
  SrdSpellDefinition spell, {
  String? id,
  String? name,
  int? level,
  String? castingTime,
  List<String>? classes,
  bool? ritual,
}) => SrdSpellDefinition(
  id: id ?? spell.id,
  name: name ?? spell.name,
  level: level ?? spell.level,
  school: spell.school,
  classes: classes ?? spell.classes,
  castingTime: castingTime ?? spell.castingTime,
  range: spell.range,
  components: spell.components,
  duration: spell.duration,
  verbal: spell.verbal,
  somatic: spell.somatic,
  material: spell.material,
  concentration: spell.concentration,
  ritual: ritual ?? spell.ritual,
);

HeroCharacter _hero(String className, String preparedName) => HeroCharacter(
  id: 'ritual-index-caster',
  name: 'Ritualkatalog-Test',
  className: className,
  level: 20,
  hitPoints: 55,
  maxHitPoints: 55,
  spells: [preparedName],
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 18,
    'wisdom': 16,
    'charisma': 14,
  },
);

SrdRitualCastPlan _preflight(
  HeroCharacter hero,
  SrdSpellDefinition spell, {
  String? castingClass,
}) => SrdRitualCastingRules.preflight(
  hero,
  spell: spell,
  castingClass: castingClass ?? hero.className,
  preparedForSelectedClassConfirmed: true,
  uninterruptedTimeAvailableConfirmed: true,
  castingConcentrationAvailableConfirmed: true,
  targetRulesConfirmed: true,
  verbalComponentConfirmed: true,
  somaticComponentConfirmed: true,
  materialComponentConfirmed: true,
  costlyComponentAvailableConfirmed: true,
  consumedComponentReservedConfirmed: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('all 29 indexed ritual identities and class lists are authorized', () {
    const classNames = {
      'Bard': 'Barde',
      'Cleric': 'Kleriker',
      'Druid': 'Druide',
      'Paladin': 'Paladin',
      'Ranger': 'Waldläufer',
      'Sorcerer': 'Zauberer',
      'Warlock': 'Hexenmeister',
      'Wizard': 'Magier',
    };
    final rituals = catalog.spells.where((spell) => spell.ritual).toList();
    expect(rituals, hasLength(29));
    for (final spell in rituals) {
      final hero = _hero(classNames[spell.classes.first]!, spell.name);
      final before = jsonEncode(hero.toJson());
      final plan = _preflight(hero, spell);
      expect(plan.spellName, spell.name, reason: spell.name);
      expect(plan.normalCastingTime, spell.castingTime, reason: spell.name);
      expect(plan.spellSlotCost, 0, reason: spell.name);
      expect(plan.additionalMinutes, 10, reason: spell.name);
      plan.validateUnchanged(hero);
      expect(jsonEncode(hero.toJson()), before, reason: spell.name);
    }
  });

  test('prepared non-ritual Magic Missile cannot gain a free ritual tag', () {
    final spell = catalog.find('Magic Missile')!;
    final hero = _hero('Magier', spell.name);
    final before = jsonEncode(hero.toJson());
    expect(
      () => _preflight(
        hero,
        _alter(spell, castingTime: 'Action or Ritual', ritual: true),
      ),
      throwsFormatException,
    );
    expect(() => _preflight(hero, spell), throwsFormatException);
    expect(jsonEncode(hero.toJson()), before);
    expect(hero.spentSpellSlots, isEmpty);
    expect(hero.spentPactSlots, 0);
  });

  test('indexed ritual cannot change identity, level, time or classes', () {
    final spell = catalog.find('Find Familiar')!;
    final hero = _hero('Magier', spell.name);
    final before = jsonEncode(hero.toJson());
    final plan = _preflight(hero, spell);
    expect(plan.totalCastingMinutes, 70);
    for (final fake in [
      _alter(spell, id: 'spell-not-find-familiar'),
      _alter(spell, name: 'Familiar Forgery'),
      _alter(spell, level: 2),
      _alter(spell, castingTime: '1 minute or Ritual'),
      _alter(spell, classes: ['Wizard', 'Warlock']),
      _alter(spell, classes: ['Warlock']),
      _alter(spell, ritual: false),
    ]) {
      expect(
        () => _preflight(hero, fake),
        throwsFormatException,
        reason: fake.name,
      );
    }
    expect(jsonEncode(hero.toJson()), before);
    expect(hero.spentSpellSlots, isEmpty);
  });

  test(
    'unknown ritual-time grammar stays unsupported before identity gate',
    () {
      final spell = catalog.find('Detect Magic')!;
      final hero = _hero('Magier', spell.name);
      expect(
        () => _preflight(hero, _alter(spell, castingTime: 'Special or Ritual')),
        throwsUnsupportedError,
      );
    },
  );

  test('ritual approval is read-only and expires after hero modification', () {
    final spell = catalog.find('Detect Magic')!;
    final hero = _hero('Magier', spell.name);
    final before = jsonEncode(hero.toJson());
    final plan = _preflight(hero, spell);
    plan.validateUnchanged(hero);
    expect(
      () => plan.validateUnchanged(hero.copyWith(gold: 2)),
      throwsFormatException,
    );
    expect(jsonEncode(hero.toJson()), before);
  });
}
