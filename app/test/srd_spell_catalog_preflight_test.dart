import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_preflight_rules.dart';

HeroCharacter prepared({
  String className = 'Magier',
  int level = 5,
  List<String> spells = const [
    'Magisches Geschoss',
    'Unsichtbarkeit',
    'Licht',
    'Fireball',
    'Counterspell',
    'Find Familiar',
    'Divine Smite',
  ],
}) => HeroCharacter(
  id: 'srd-spell-caster',
  name: 'Zauberprüfung',
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
  maxHitPoints: 24,
  hitPoints: 24,
);

SrdSpellCastPlan plan(
  HeroCharacter hero,
  SrdSpellDefinition spell, {
  String castingClass = 'Magier',
  int slotLevel = 1,
  bool pactMagic = false,
  bool verbal = true,
  bool somatic = true,
  bool material = true,
  bool action = true,
  bool target = true,
  bool turnSlot = true,
}) => SrdSpellPreflightRules.preflight(
  hero,
  spell: spell,
  castingClass: castingClass,
  slotLevel: slotLevel,
  pactMagic: pactMagic,
  actionAvailableConfirmed: action,
  targetRulesConfirmed: target,
  verbalComponentConfirmed: verbal,
  somaticComponentConfirmed: somatic,
  materialComponentConfirmed: material,
  slotTurnLimitConfirmed: turnSlot,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('339 SRD spell entries, unique stable names and complete metadata', () {
    expect(catalog.spells, hasLength(339));
    expect(catalog.byName.length, catalog.spells.length);
    expect(catalog.spells.map((s) => s.id).toSet().length, 339);
    expect(catalog.spells.every((s) => s.level >= 0 && s.level <= 9), isTrue);
    expect(catalog.spells.where((s) => s.level == 0), hasLength(27));
    expect(catalog.find('Magic Missile')?.level, 1);
    expect(catalog.find('Magic Missile')?.classes, ['Sorcerer', 'Wizard']);
    expect(catalog.find('Magic Missile')?.range, '120 feet');
    expect(catalog.find('Magic Missile')?.components, 'V, S');
    expect(catalog.find('Shield')?.castingTime, startsWith('Reaction'));
    expect(catalog.find('Detect Magic')?.concentration, isTrue);
    expect(catalog.find('Detect Magic')?.ritual, isTrue);
    expect(catalog.find('Find Familiar')?.material, isTrue);
    expect(catalog.find('Not An SRD Spell'), isNull);
  });

  test('tampered or duplicate catalogue records are rejected', () async {
    final source = await rootBundle.loadString('assets/srd_5_2_1_spells.json');
    final root = jsonDecode(source) as Map<String, dynamic>;
    final entries = root['spells'] as List<dynamic>;
    entries.add(Map<String, dynamic>.from(entries.first as Map));
    expect(
      () => SrdSpellCatalog.fromJsonString(jsonEncode(root)),
      throwsFormatException,
    );
    entries.removeLast();
    final first = entries.first as Map<String, dynamic>;
    first['level'] = 10;
    expect(
      () => SrdSpellCatalog.fromJsonString(jsonEncode(root)),
      throwsFormatException,
    );
    first['level'] = 2;
    first['verbal'] = false;
    expect(
      () => SrdSpellCatalog.fromJsonString(jsonEncode(root)),
      throwsFormatException,
    );
  });

  test(
    'preflight is read-only and resource commit requires resolved effect',
    () {
      final hero = prepared();
      final spell = catalog.find('Magic Missile')!;
      final approval = plan(hero, spell);
      expect(approval.preparedName, 'Magisches Geschoss');
      expect(approval.slotLevel, 1);
      expect(hero.spentSpellSlots, isEmpty);
      expect(
        () => SrdSpellPreflightRules.recordConfirmedResourceUse(
          hero,
          approval,
          effectResolvedSeparatelyConfirmed: false,
        ),
        throwsStateError,
      );
      final spent = SrdSpellPreflightRules.recordConfirmedResourceUse(
        hero,
        approval,
        effectResolvedSeparatelyConfirmed: true,
      );
      expect(spent.hero.spentSpellSlots, {'1': 1});
      expect(hero.spentSpellSlots, isEmpty);
      expect(
        () => SrdSpellPreflightRules.recordConfirmedResourceUse(
          spent.hero,
          approval,
          effectResolvedSeparatelyConfirmed: true,
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'cannot cast without prepared name, own class, or class spell level',
    () {
      final spell = catalog.find('Magic Missile')!;
      expect(
        () => plan(prepared(spells: const ['Licht']), spell),
        throwsFormatException,
      );
      expect(
        () => plan(
          prepared(className: 'Kleriker'),
          spell,
          castingClass: 'Kleriker',
        ),
        throwsFormatException,
      );
      final multiclass = prepared(
        level: 6,
      ).copyWith(secondaryClassName: 'Zauberer', secondaryClassLevel: 5);
      expect(
        () => plan(
          multiclass,
          catalog.find('Fireball')!,
          castingClass: 'Magier',
          slotLevel: 3,
        ),
        throwsFormatException,
      );
    },
  );

  test('component and target confirmations cannot be bypassed', () {
    final hero = prepared();
    final spell = catalog.find('Fireball')!;
    expect(spell.material, isTrue);
    expect(
      () => plan(hero, spell, slotLevel: 3, material: false),
      throwsFormatException,
    );
    expect(
      () => plan(hero, spell, slotLevel: 3, somatic: false),
      throwsFormatException,
    );
    expect(
      () => plan(hero, spell, slotLevel: 3, target: false),
      throwsFormatException,
    );
    expect(
      () => plan(hero, spell, slotLevel: 3, action: false),
      throwsFormatException,
    );
    expect(
      () => plan(hero, spell, slotLevel: 3, turnSlot: false),
      throwsFormatException,
    );
    expect(plan(hero, spell, slotLevel: 3).spell.level, 3);
  });

  test('concentration is taken from SRD metadata, not caller guesses', () {
    final hero = prepared().copyWith(concentratingOn: 'Alter Zauber');
    final invisibility = catalog.find('Invisibility')!;
    final assessment = plan(hero, invisibility, slotLevel: 2);
    final changed = SrdSpellPreflightRules.recordConfirmedResourceUse(
      hero,
      assessment,
      effectResolvedSeparatelyConfirmed: true,
    );
    expect(changed.hero.concentratingOn, 'Unsichtbarkeit');
    expect(changed.hero.spentSpellSlots, {'2': 1});
    expect(hero.concentratingOn, 'Alter Zauber');
  });

  test('cantrips use no slots and pact slots retain their correct level', () {
    final mage = prepared();
    final light = plan(mage, catalog.find('Light')!, slotLevel: 0);
    final noSlot = SrdSpellPreflightRules.recordConfirmedResourceUse(
      mage,
      light,
      effectResolvedSeparatelyConfirmed: true,
    );
    expect(noSlot.hero.spentSpellSlots, isEmpty);
    expect(
      () => plan(mage, catalog.find('Light')!, slotLevel: 1),
      throwsFormatException,
    );

    final warlock = prepared(className: 'Hexenmeister', spells: const ['Hex']);
    final hex = catalog.find('Hex')!;
    final pact = plan(
      warlock,
      hex,
      castingClass: 'Hexenmeister',
      slotLevel: 3,
      pactMagic: true,
    );
    final used = SrdSpellPreflightRules.recordConfirmedResourceUse(
      warlock,
      pact,
      effectResolvedSeparatelyConfirmed: true,
    );
    expect(used.hero.spentPactSlots, 1);
    expect(used.hero.concentratingOn, 'Hex');
  });

  test('reaction, triggered bonus and multi-turn spells stay unsupported', () {
    final hero = prepared();
    for (final name in ['Counterspell', 'Find Familiar']) {
      expect(
        () => plan(hero, catalog.find(name)!, slotLevel: 3),
        throwsUnsupportedError,
      );
    }
    final paladin = prepared(
      className: 'Paladin',
      spells: const ['Divine Smite'],
    );
    expect(
      () =>
          plan(paladin, catalog.find('Divine Smite')!, castingClass: 'Paladin'),
      throwsUnsupportedError,
    );
  });

  test('insufficient resources or an impossible spell grade are rejected', () {
    final hero = prepared();
    final missile = catalog.find('Magic Missile')!;
    expect(() => plan(hero, missile, slotLevel: 9), throwsStateError);
    expect(() => plan(hero, missile, slotLevel: 0), throwsFormatException);
  });
}
