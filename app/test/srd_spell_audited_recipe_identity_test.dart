import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_component_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_material_value_rules.dart';

SrdSpellDefinition _alter(
  SrdSpellDefinition spell, {
  String? id,
  String? name,
  int? level,
  String? school,
  List<String>? classes,
  String? castingTime,
  String? range,
  String? duration,
  String? components,
  bool? verbal,
  bool? somatic,
  bool? material,
  bool? concentration,
  bool? ritual,
}) => SrdSpellDefinition(
  id: id ?? spell.id,
  name: name ?? spell.name,
  level: level ?? spell.level,
  school: school ?? spell.school,
  classes: classes ?? spell.classes,
  castingTime: castingTime ?? spell.castingTime,
  range: range ?? spell.range,
  components: components ?? spell.components,
  duration: duration ?? spell.duration,
  verbal: verbal ?? spell.verbal,
  somatic: somatic ?? spell.somatic,
  material: material ?? spell.material,
  concentration: concentration ?? spell.concentration,
  ritual: ritual ?? spell.ritual,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test(
    'four original multi-item material recipes retain two audited items',
    () {
      const names = [
        'Astral Projection',
        'Clone',
        'Legend Lore',
        'Secret Chest',
      ];
      for (final name in names) {
        final spell = catalog.find(name)!;
        final items = SrdSpellComponentRules.auditedItems(spell);
        expect(items, hasLength(2), reason: name);
        expect(items.map((item) => item.id).toSet(), hasLength(2));
        expect(items.every((item) => item.label.isNotEmpty), isTrue);
      }
      expect(
        SrdSpellComponentRules.auditedItems(catalog.find('Magic Missile')!),
        isEmpty,
      );
    },
  );

  test('audited recipes reject forgery of every indexed spell property', () {
    for (final name in [
      'Astral Projection',
      'Clone',
      'Legend Lore',
      'Secret Chest',
    ]) {
      final spell = catalog.find(name)!;
      final mutations = <SrdSpellDefinition>[
        _alter(spell, id: 'spell-forged-$name'),
        _alter(spell, name: 'Forged $name'),
        _alter(spell, level: 1),
        _alter(spell, school: 'Evocation'),
        _alter(spell, classes: ['Wizard', 'Ranger']),
        _alter(
          spell,
          classes: spell.classes.length > 1
              ? spell.classes.reversed.toList()
              : ['Warlock'],
        ),
        _alter(
          spell,
          castingTime: spell.castingTime == 'Action' ? '1 hour' : 'Action',
        ),
        _alter(spell, range: spell.range == 'Touch' ? '10 feet' : 'Touch'),
        _alter(
          spell,
          duration: spell.duration == 'Instantaneous'
              ? 'Until dispelled'
              : 'Instantaneous',
        ),
        _alter(spell, components: 'V, S, M (unverified material)'),
        _alter(spell, verbal: false),
        _alter(spell, somatic: false),
        _alter(spell, material: false),
        _alter(spell, concentration: true),
        _alter(spell, ritual: true),
      ];
      for (final fake in mutations) {
        expect(
          () => SrdSpellComponentRules.auditedItems(fake),
          throwsFormatException,
          reason: '$name: ${fake.name} / ${fake.id}',
        );
      }
    }
  });

  test('a pinned ID cannot bypass its audited recipe by renaming', () {
    final clone = catalog.find('Clone')!;
    final missile = catalog.find('Magic Missile')!;
    for (final fake in [
      _alter(clone, name: 'Magic Missile'),
      _alter(missile, id: clone.id),
      _alter(clone, name: 'Unknown Spell'),
    ]) {
      expect(
        () => SrdSpellComponentRules.auditedItems(fake),
        throwsFormatException,
      );
    }
    expect(
      SrdSpellComponentRules.auditedItems(catalog.find('Magic Missile')!),
      isEmpty,
    );
  });

  test('invalid audited identity does not touch hero inventory or slots', () {
    final spell = catalog.find('Secret Chest')!;
    final hero = HeroCharacter(
      id: 'audited-component-identity-hero',
      name: 'Materialprüfung',
      className: 'Magier',
      level: 9,
      spells: const ['Secret Chest'],
      abilities: const {
        'strength': 10,
        'dexterity': 12,
        'constitution': 14,
        'intelligence': 18,
        'wisdom': 12,
        'charisma': 10,
      },
      hitPoints: 38,
      maxHitPoints: 38,
      inventory: const [
        InventoryItem(id: 'chest', name: 'Chest'),
        InventoryItem(id: 'replica', name: 'Replica'),
      ],
    );
    final before = jsonEncode(hero.toJson());
    final fake = _alter(spell, level: 1);
    expect(
      () => SrdSpellMaterialValueRules.validatedConsumption(
        hero,
        fake,
        bindings: const [],
        values: const [],
      ),
      throwsFormatException,
    );
    expect(jsonEncode(hero.toJson()), before);
    expect(hero.spentSpellSlots, isEmpty);
    expect(hero.spentPactSlots, 0);
  });
}
