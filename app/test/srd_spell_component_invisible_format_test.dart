import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_component_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_preflight_rules.dart';

const _hiddenCharacters = <int>[
  0x206a,
  0x206b,
  0x206c,
  0x206d,
  0x206e,
  0x206f,
  0xfff9,
  0xfffa,
  0xfffb,
];

SrdSpellDefinition _withComponents(
  SrdSpellDefinition spell,
  String components,
) => SrdSpellDefinition(
  id: spell.id,
  name: spell.name,
  level: spell.level,
  school: spell.school,
  classes: spell.classes,
  castingTime: spell.castingTime,
  range: spell.range,
  components: components,
  duration: spell.duration,
  verbal: spell.verbal,
  somatic: spell.somatic,
  material: spell.material,
  concentration: spell.concentration,
  ritual: spell.ritual,
);

Map<String, dynamic> _asCatalogueJson(
  SrdSpellDefinition spell,
  String components,
) => {
  'id': spell.id,
  'name': spell.name,
  'level': spell.level,
  'school': spell.school,
  'classes': spell.classes,
  'casting_time': spell.castingTime,
  'range': spell.range,
  'components': components,
  'duration': spell.duration,
  'verbal': spell.verbal,
  'somatic': spell.somatic,
  'material': spell.material,
  'concentration': spell.concentration,
  'ritual': spell.ritual,
};

HeroCharacter _cleric() => HeroCharacter(
  id: 'component-visibility-caster',
  name: 'Komponentenkontrolle',
  className: 'Kleriker',
  level: 5,
  spells: const ['Revivify'],
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 10,
    'wisdom': 18,
    'charisma': 12,
  },
  hitPoints: 32,
  maxHitPoints: 32,
);

SrdSpellCastPlan _preflight(
  HeroCharacter hero,
  SrdSpellDefinition spell, {
  bool reserved = false,
}) => SrdSpellPreflightRules.preflight(
  hero,
  spell: spell,
  castingClass: 'Kleriker',
  slotLevel: 3,
  actionAvailableConfirmed: true,
  targetRulesConfirmed: true,
  verbalComponentConfirmed: true,
  somaticComponentConfirmed: true,
  materialComponentConfirmed: true,
  costlyComponentAvailableConfirmed: true,
  consumedComponentReservedConfirmed: reserved,
  slotTurnLimitConfirmed: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('all existing catalogue component descriptions remain valid', () {
    for (final spell in catalog.spells) {
      SrdSpellDefinition.validateComponentMetadata(
        components: spell.components,
        verbal: spell.verbal,
        somatic: spell.somatic,
        material: spell.material,
      );
    }
    SrdSpellDefinition.validateComponentMetadata(
      components: 'V, S, M (crème, Blüte und Seide – Größe 2)',
      verbal: true,
      somatic: true,
      material: true,
    );
  });

  test('nine hidden marks cannot conceal a consumed material flag', () {
    final original = catalog.find('Revivify')!;
    expect(original.components, contains('consumes'));
    final hero = _cleric();
    final before = jsonEncode(hero.toJson());

    for (final codePoint in _hiddenCharacters) {
      final invisible = String.fromCharCode(codePoint);
      final tampered = original.components.replaceFirst(
        'consumes',
        'con${invisible}sumes',
      );
      final forged = _withComponents(original, tampered);
      expect(
        () => SrdSpellDefinition.validateComponentMetadata(
          components: forged.components,
          verbal: forged.verbal,
          somatic: forged.somatic,
          material: forged.material,
        ),
        throwsFormatException,
        reason: codePoint.toRadixString(16),
      );
      expect(
        () => SrdSpellComponentRules.requirements(forged),
        throwsFormatException,
        reason: codePoint.toRadixString(16),
      );
      expect(
        () => _preflight(hero, forged),
        throwsFormatException,
        reason: codePoint.toRadixString(16),
      );
      expect(
        () => SrdSpellDefinition.fromJson(_asCatalogueJson(original, tampered)),
        throwsFormatException,
        reason: codePoint.toRadixString(16),
      );
      expect(jsonEncode(hero.toJson()), before);
      expect(hero.spentSpellSlots, isEmpty);
    }
  });

  test('embedded controls cannot disguise an otherwise valid price', () {
    final original = catalog.find('Revivify')!;
    for (final codePoint in _hiddenCharacters) {
      final invisible = String.fromCharCode(codePoint);
      final tampered = original.components.replaceFirst(
        '300+ GP',
        '3${invisible}00+ GP',
      );
      expect(
        () => SrdSpellComponentRules.requirements(
          _withComponents(original, tampered),
        ),
        throwsFormatException,
        reason: codePoint.toRadixString(16),
      );
    }
  });

  test('legitimate Revivify retains consumption and reservation gates', () {
    final original = catalog.find('Revivify')!;
    final hero = _cleric();
    final before = jsonEncode(hero.toJson());

    final requirements = SrdSpellComponentRules.requirements(original);
    expect(requirements.hasMaterial, isTrue);
    expect(requirements.hasSpecifiedCost, isTrue);
    expect(requirements.isConsumed, isTrue);
    expect(() => _preflight(hero, original), throwsFormatException);
    final plan = _preflight(hero, original, reserved: true);
    expect(plan.hasConsumedMaterial, isTrue);
    expect(jsonEncode(hero.toJson()), before);
    expect(hero.spentSpellSlots, isEmpty);
  });
}
