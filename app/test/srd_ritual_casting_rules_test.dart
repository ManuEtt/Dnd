import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_ritual_casting_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_component_rules.dart';

HeroCharacter _hero({
  String className = 'Magier',
  String secondaryClassName = '',
  int secondaryClassLevel = 0,
  int level = 20,
  List<String> spells = const ['Detect Magic', 'Find Familiar', 'Identify'],
}) => HeroCharacter(
  id: 'ritual-hero',
  name: 'Ritualprobe',
  className: className,
  secondaryClassName: secondaryClassName,
  secondaryClassLevel: secondaryClassLevel,
  level: level,
  spells: spells,
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 18,
    'wisdom': 16,
    'charisma': 14,
  },
  hitPoints: 32,
  maxHitPoints: 32,
);

SrdRitualCastPlan _plan(
  HeroCharacter hero,
  SrdSpellDefinition spell, {
  String? castingClass,
  bool preparedForClass = true,
  bool timeAvailable = true,
  bool concentration = true,
  bool target = true,
  bool verbal = true,
  bool somatic = true,
  bool material = true,
  SrdSpellMaterialSource source = SrdSpellMaterialSource.specificComponents,
  bool focusAuthorized = true,
  bool costly = true,
  bool consumedReserved = true,
}) => SrdRitualCastingRules.preflight(
  hero,
  spell: spell,
  castingClass: castingClass ?? hero.className,
  preparedForSelectedClassConfirmed: preparedForClass,
  uninterruptedTimeAvailableConfirmed: timeAvailable,
  castingConcentrationAvailableConfirmed: concentration,
  targetRulesConfirmed: target,
  verbalComponentConfirmed: verbal,
  somaticComponentConfirmed: somatic,
  materialComponentConfirmed: material,
  materialSource: source,
  focusUseAuthorizedConfirmed: focusAuthorized,
  costlyComponentAvailableConfirmed: costly,
  consumedComponentReservedConfirmed: consumedReserved,
);

SrdSpellDefinition _alter(
  SrdSpellDefinition spell, {
  String? castingTime,
  bool? ritual,
  int? level,
}) => SrdSpellDefinition(
  id: spell.id,
  name: spell.name,
  level: level ?? spell.level,
  school: spell.school,
  classes: spell.classes,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test(
    'all 29 tagged ritual entries pass class and prepared spell preflight',
    () {
      const byEnglish = {
        'Bard': 'Barde',
        'Cleric': 'Kleriker',
        'Druid': 'Druide',
        'Paladin': 'Paladin',
        'Ranger': 'Waldläufer',
        'Sorcerer': 'Zauberer',
        'Warlock': 'Hexenmeister',
        'Wizard': 'Magier',
      };
      final spells = catalog.spells.where((spell) => spell.ritual).toList();
      expect(spells, hasLength(29));
      for (final spell in spells) {
        final name = byEnglish[spell.classes.first]!;
        final hero = _hero(className: name, spells: [spell.name]);
        final before = jsonEncode(hero.toJson());
        final plan = _plan(hero, spell);
        expect(plan.spellName, spell.name);
        expect(plan.castingClass, name);
        expect(plan.spellSlotCost, 0);
        expect(plan.additionalMinutes, 10);
        expect(jsonEncode(hero.toJson()), before);
        plan.validateUnchanged(hero);
      }
    },
  );

  test('Action + 10 minutes is not silently rounded to an invented minute', () {
    final plan = _plan(_hero(), catalog.find('Detect Magic')!);
    expect(plan.normalCastingTime, 'Action or Ritual');
    expect(plan.additionalMinutes, 10);
    expect(plan.totalCastingMinutes, isNull);
    expect(plan.spellSlotCost, 0);
  });

  test('1 minute, 10 minutes, and 1 hour gain exactly ten minutes', () {
    for (final data in [
      ('Identify', 11),
      ('Forbiddance', 20),
      ('Find Familiar', 70),
    ]) {
      final spell = catalog.find(data.$1)!;
      final className = spell.classes.first == 'Cleric' ? 'Kleriker' : 'Magier';
      final plan = _plan(
        _hero(className: className, spells: [spell.name]),
        spell,
      );
      expect(plan.totalCastingMinutes, data.$2);
    }
  });

  test('ritual needs its tag, valid positive level and known time grammar', () {
    final hero = _hero();
    final valid = catalog.find('Detect Magic')!;
    final invalid = catalog.find('Magic Missile')!;
    expect(() => _plan(hero, invalid), throwsFormatException);
    expect(
      () => _plan(hero, _alter(valid, ritual: false)),
      throwsFormatException,
    );
    expect(() => _plan(hero, _alter(valid, level: 0)), throwsFormatException);
    expect(
      () => _plan(hero, _alter(valid, castingTime: 'Special or Ritual')),
      throwsUnsupportedError,
    );
  });

  test('unprepared ritual and wrong class cannot claim free casting', () {
    final detect = catalog.find('Detect Magic')!;
    expect(() => _plan(_hero(spells: const []), detect), throwsFormatException);
    expect(
      () => _plan(_hero(), detect, preparedForClass: false),
      throwsFormatException,
    );
    expect(
      () => _plan(_hero(), detect, castingClass: 'Kleriker'),
      throwsFormatException,
    );
    expect(
      () => _plan(_hero(className: 'Kämpfer'), detect),
      throwsFormatException,
    );
    expect(() => _plan(_hero(className: 'Magierin'), detect), returnsNormally);
  });

  test('class-specific spell limit applies even with a high total level', () {
    final findFamiliar = catalog.find('Find Familiar')!;
    final hero = _hero(
      className: 'Kleriker',
      secondaryClassName: 'Magier',
      secondaryClassLevel: 1,
      level: 20,
      spells: [findFamiliar.name],
    );
    final plan = _plan(hero, findFamiliar, castingClass: 'Magier');
    expect(plan.castingClass, 'Magier');
    expect(plan.spellSlotCost, 0);

    final tooHigh = catalog.find('Forbiddance')!;
    final cleric = _hero(
      className: 'Kleriker',
      secondaryClassName: 'Magier',
      secondaryClassLevel: 15,
      level: 20,
      spells: [tooHigh.name],
    );
    expect(
      () => _plan(cleric, tooHigh, castingClass: 'Kleriker'),
      throwsFormatException,
    );
  });

  test('invalid multiclass levels and duplicated class are rejected', () {
    final spell = catalog.find('Detect Magic')!;
    for (final hero in [
      _hero(level: 0),
      _hero(level: 21),
      _hero(level: 1, secondaryClassLevel: 1),
      _hero(secondaryClassName: 'Zauberer', secondaryClassLevel: 0),
      _hero(secondaryClassName: 'Magier', secondaryClassLevel: 2),
      _hero(secondaryClassName: 'Unbekannt', secondaryClassLevel: 3),
      _hero(level: 3, secondaryClassName: 'Zauberer', secondaryClassLevel: 3),
    ]) {
      expect(() => _plan(hero, spell), throwsFormatException);
    }
  });

  test('time, concentration and target confirmations all fail closed', () {
    final spell = catalog.find('Detect Magic')!;
    final hero = _hero();
    expect(
      () => _plan(hero, spell, timeAvailable: false),
      throwsFormatException,
    );
    expect(
      () => _plan(hero, spell, concentration: false),
      throwsFormatException,
    );
    expect(() => _plan(hero, spell, target: false), throwsFormatException);
  });

  test('verbal, somatic and material requirements cannot be bypassed', () {
    final ritual = catalog.find('Identify')!;
    final hero = _hero();
    expect(() => _plan(hero, ritual, verbal: false), throwsFormatException);
    expect(() => _plan(hero, ritual, somatic: false), throwsFormatException);
    expect(() => _plan(hero, ritual, material: false), throwsFormatException);
    expect(() => _plan(hero, ritual, costly: false), throwsFormatException);
    expect(
      () =>
          _plan(hero, ritual, source: SrdSpellMaterialSource.spellcastingFocus),
      throwsFormatException,
    );
  });

  test('consumed material requires reserved components in ritual too', () {
    final spell = catalog.find('Illusory Script')!;
    final hero = _hero(spells: [spell.name]);
    expect(
      () => _plan(hero, spell, consumedReserved: false),
      throwsFormatException,
    );
    final plan = _plan(hero, spell, consumedReserved: true);
    expect(plan.hasConsumedMaterial, isTrue);
  });

  test('incapacity, zero HP and untrained equipment forbid ritual', () {
    final spell = catalog.find('Detect Magic')!;
    final hero = _hero();
    for (final blocked in [
      hero.copyWith(hitPoints: 0),
      hero.copyWith(conditions: ['bewusstlos']),
      hero.copyWith(equippedArmorId: 'armor', equippedArmorTrained: false),
      hero.copyWith(equippedShieldId: 'shield', equippedShieldTrained: false),
    ]) {
      expect(() => _plan(blocked, spell), throwsStateError);
    }
  });

  test(
    'ritual eligibility neither spends exhausted slots nor mutates hero',
    () {
      final hero = _hero().copyWith(
        spentSpellSlots: {'1': 4, '2': 3, '3': 3},
        spentPactSlots: 1,
        concentratingOn: 'Existing concentration',
      );
      final before = jsonEncode(hero.toJson());
      final plan = _plan(hero, catalog.find('Detect Magic')!);
      expect(plan.spellSlotCost, 0);
      expect(jsonEncode(hero.toJson()), before);
      expect(hero.concentratingOn, 'Existing concentration');
      expect(hero.spentSpellSlots['1'], 4);
    },
  );

  test('character changes make a formerly valid ritual plan stale', () {
    final hero = _hero();
    final plan = _plan(hero, catalog.find('Detect Magic')!);
    plan.validateUnchanged(hero);
    expect(
      () => plan.validateUnchanged(hero.copyWith(gold: 20)),
      throwsFormatException,
    );
    expect(
      () => plan.validateUnchanged(hero.copyWith(spells: const [])),
      throwsFormatException,
    );
  });
}
