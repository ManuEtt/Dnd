import 'srd_equipment_catalog.dart';
import 'inventory_item_stats.dart';
export 'inventory_item_stats.dart';
import 'condition_rules.dart';
import 'condition_effects.dart';
import 'death_saving_throw_rules.dart';
import 'saving_throw_class_actions.dart';
import 'spellcasting_rules.dart';
import 'class_feature_resources.dart';
import 'class_resource_rules.dart';
import 'skill_check_passives.dart';
import 'cover_rules.dart';
import 'enemy_force_defense.dart';

/// Versioned, provider-independent game data. Unknown historical values stay null.
const abilityNames = <String>[
  'strength',
  'dexterity',
  'constitution',
  'intelligence',
  'wisdom',
  'charisma',
];
const _unchanged = Object();

Map<String, dynamic> _map(dynamic value, String name) {
  if (value is! Map<String, dynamic>) {
    throw FormatException('$name muss ein Objekt sein.');
  }
  return value;
}

String _string(dynamic value, String name, {String? fallback}) {
  if (value == null && fallback != null) return fallback;
  if (value is! String || value.length > 50000) {
    throw FormatException('$name ist ungültig.');
  }
  return value;
}

int _int(
  dynamic value,
  String name, {
  int? fallback,
  int min = 0,
  int max = 1000000,
}) {
  if (value == null && fallback != null) return fallback;
  if (value is! int || value < min || value > max) {
    throw FormatException('$name ist ungültig.');
  }
  return value;
}

int? _nullableInt(
  dynamic value,
  String name, {
  int min = 0,
  int max = 1000000,
}) => value == null ? null : _int(value, name, min: min, max: max);
List<dynamic> _list(dynamic value, String name) {
  if (value == null) return [];
  if (value is! List || value.length > 10000) {
    throw FormatException('$name ist ungültig.');
  }
  return value;
}

List<String> _strings(dynamic value, String name) =>
    _list(value, name).map((e) => _string(e, name)).toList();
bool _bool(dynamic value, String name, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is! bool) throw FormatException('$name ist ungültig.');
  return value;
}

void _version(Map<String, dynamic> json) {
  if (json['schemaVersion'] != 1) {
    throw const FormatException('Nicht unterstützte Schema-Version.');
  }
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.description = '',
    this.catalogId = '',
    this.stats,
  });

  /// Optional catalog reference; legacy and user-defined items leave it empty.
  final String catalogId;

  /// Eigene Werte werden separat gespeichert und nie aus Beschreibungstext gelesen.
  final InventoryItemStats? stats;
  final String id, name, description;
  final int quantity;

  /// Preserve the catalog reference when updating an inventory stack.
  InventoryItem copyWith({
    String? name,
    int? quantity,
    String? description,
    String? catalogId,
    InventoryItemStats? stats,
  }) => InventoryItem(
    id: id,
    name: name ?? this.name,
    quantity: quantity ?? this.quantity,
    description: description ?? this.description,
    catalogId: catalogId ?? this.catalogId,
    stats: stats ?? this.stats,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'description': description,
    if (catalogId.isNotEmpty) 'catalogId': catalogId,
    if (stats != null) 'stats': stats!.toJson(),
  };
  static InventoryItemStats? _catalogStats(String id) {
    final entry = SrdEquipmentCatalog.byId(id);
    return entry == null ? null : InventoryItemStats.fromCatalog(entry);
  }

  factory InventoryItem.fromJson(Map<String, dynamic> j) => InventoryItem(
    id: _string(j['id'], 'Gegenstand-ID'),
    name: _string(j['name'], 'Gegenstand'),
    quantity: _int(j['quantity'], 'Anzahl', fallback: 1, min: 1),
    description: _string(j['description'], 'Beschreibung', fallback: ''),
    catalogId: _string(j['catalogId'], 'Katalog-ID', fallback: ''),
    // Explicit SRD catalog IDs are sufficient to restore missing typed
    // attributes in older imports. Never infer a catalog ID from a free name,
    // and never overwrite user-confirmed custom stats.
    stats: j['stats'] == null
        ? _catalogStats(_string(j['catalogId'], 'Katalog-ID', fallback: ''))
        : InventoryItemStats.fromJson(_map(j['stats'], 'Gegenstandswerte')),
  );
}

class HeroCharacter {
  HeroCharacter({
    required this.id,
    required this.name,
    this.species = 'Mensch',
    this.className = 'Kämpfer',
    this.secondaryClassName = '',
    this.secondaryClassLevel = 0,
    this.secondarySubclass = '',
    this.level = 1,
    this.subclass = '',
    this.background = '',
    this.backstory = '',
    this.portraitPreset = -1,
    this.portraitPhotoBase64 = '',
    Map<String, int?>? abilities,
    this.hitPoints,
    this.maxHitPoints,
    this.temporaryHitPoints = 0,
    this.armorClass,
    this.speed,
    this.speedRemainderDecimeters = 0,
    List<String> skills = const [],
    List<String> savingThrowProficiencies = const [],
    List<String> features = const [],
    List<String> spells = const [],
    List<InventoryItem> inventory = const [],
    this.gold,
    this.experience,
    List<String> conditions = const [],
    List<ConditionEffect> conditionEffects = const [],
    this.exhaustionLevel = 0,
    Map<String, int> spentHitDice = const {},
    Map<String, int> spentSpellSlots = const {},
    this.spentPactSlots = 0,
    this.spentSecondWind = 0,
    this.spentActionSurge = 0,
    Map<String, int> spentClassResources = const {},
    this.concentratingOn = '',
    this.weaponDamage = '',
    this.weaponAbility = 'strength',
    this.weaponProficient = false,
    this.equippedArmorId = '',
    this.equippedShieldId = '',
    this.equippedWeaponId = '',
    this.equippedArmorTrained = false,
    this.equippedShieldTrained = false,
    this.deathSuccesses = 0,
    this.deathFailures = 0,
    List<String> unverifiedNotes = const [],
  }) : abilities = Map.unmodifiable(
         abilities ?? {for (final key in abilityNames) key: null},
       ),
       skills = List.unmodifiable(skills),
       savingThrowProficiencies = List.unmodifiable(savingThrowProficiencies),
       features = List.unmodifiable(features),
       spells = List.unmodifiable(spells),
       inventory = List.unmodifiable(inventory),
       manualConditions = List.unmodifiable(conditions),
       conditionEffects = ConditionEffectRules.validated(conditionEffects),
       spentHitDice = Map.unmodifiable(spentHitDice),
       spentSpellSlots = Map.unmodifiable(spentSpellSlots),
       spentClassResources = Map.unmodifiable(spentClassResources),
       unverifiedNotes = List.unmodifiable(unverifiedNotes);
  final String id,
      name,
      species,
      className,
      secondaryClassName,
      subclass,
      secondarySubclass,
      background,
      backstory,
      portraitPhotoBase64;

  /// -1 = no preset, 0..8 = approved portrait grid.
  final int portraitPreset;
  final int secondaryClassLevel;
  int get primaryClassLevel => level - secondaryClassLevel;
  bool get hasSecondClass => secondaryClassName.isNotEmpty;
  String get classSummary => hasSecondClass
      ? '$className $primaryClassLevel / $secondaryClassName $secondaryClassLevel'
      : className;
  final int level, exhaustionLevel, deathSuccesses, deathFailures;
  final int? gold, experience;
  final Map<String, int?> abilities;
  final int? hitPoints, maxHitPoints, armorClass, speed;

  static int _readSpeedRemainder(dynamic raw) {
    final remainder = _int(raw, 'Bewegungsrest', fallback: 0, min: 0, max: 5);
    if (remainder != 0 && remainder != 5) {
      throw const FormatException(
        'Bewegungsrest darf nur 0 oder 5 Dezimeter betragen.',
      );
    }
    return remainder;
  }

  /// Optional fractional base speed (0 or 5 decimeters) for SRD 35-ft species.
  /// Absent in old saves; do not confuse with an exhaustion penalty.
  final int speedRemainderDecimeters;
  double? get baseSpeedMeters =>
      speed == null ? null : speed! + speedRemainderDecimeters / 10.0;

  /// SRD temporary HP: separate from normal/max HP, not additive.
  final int temporaryHitPoints;
  final List<String> skills,
      savingThrowProficiencies,
      features,
      spells,
      unverifiedNotes;

  /// Explicit legacy/manual entries, never synthesized from a source effect.
  final List<String> manualConditions;
  final List<ConditionEffect> conditionEffects;

  /// Read-only effective condition view: distinct names, multiple causes.
  List<String> get conditions => List.unmodifiable({
    ...manualConditions,
    for (final effect in conditionEffects) effect.condition,
  });
  final List<InventoryItem> inventory;

  /// Already spent class Hit Dice, keyed by die type (d6/d8/d10/d12).
  /// Optional in schemaVersion 1 for backwards-compatible older saves.
  final Map<String, int> spentHitDice;

  /// Spent Spellcasting slots per spell level; Pact Magic is separate.
  final Map<String, int> spentSpellSlots;
  final int spentPactSlots;
  final int spentSecondWind, spentActionSurge;

  /// Optional cross-class SRD resource counters, keyed by source class.
  final Map<String, int> spentClassResources;

  /// Explicitly declared current concentration, not a claimed spell effect.
  final String concentratingOn;
  final String weaponDamage, weaponAbility;
  final bool weaponProficient;

  /// Optional inventory-instance references. Old saves default to no equipment.
  final String equippedArmorId, equippedShieldId, equippedWeaponId;

  /// Explicitly confirmed training for the currently equipped armor and shield.
  final bool equippedArmorTrained, equippedShieldTrained;
  List<String> get incompleteFields => [
    for (final key in abilityNames)
      if (abilities[key] == null) key,
    if (hitPoints == null) 'Trefferpunkte',
    if (maxHitPoints == null) 'Maximale Trefferpunkte',
    if (armorClass == null) 'Rüstungsklasse',
    if (speed == null) 'Bewegung',
    if (weaponDamage.isEmpty) 'Waffenschaden',
  ];
  bool get isComplete => incompleteFields.isEmpty;
  bool get isDead => conditions.contains('tot') || exhaustionLevel >= 6;
  HeroCharacter copyWith({
    String? id,
    String? name,
    String? species,
    String? className,
    String? secondaryClassName,
    int? secondaryClassLevel,
    String? secondarySubclass,
    int? level,
    String? subclass,
    String? background,
    String? backstory,
    int? portraitPreset,
    String? portraitPhotoBase64,
    Map<String, int?>? abilities,
    Object? hitPoints = _unchanged,
    Object? maxHitPoints = _unchanged,
    int? temporaryHitPoints,
    Object? armorClass = _unchanged,
    Object? speed = _unchanged,
    int? speedRemainderDecimeters,
    List<String>? skills,
    List<String>? savingThrowProficiencies,
    List<String>? features,
    List<String>? spells,
    List<InventoryItem>? inventory,
    Object? gold = _unchanged,
    Object? experience = _unchanged,
    List<String>? conditions,
    List<ConditionEffect>? conditionEffects,
    int? exhaustionLevel,
    Map<String, int>? spentHitDice,
    Map<String, int>? spentSpellSlots,
    int? spentPactSlots,
    int? spentSecondWind,
    int? spentActionSurge,
    Map<String, int>? spentClassResources,
    String? concentratingOn,
    String? weaponDamage,
    String? weaponAbility,
    bool? weaponProficient,
    String? equippedArmorId,
    String? equippedShieldId,
    String? equippedWeaponId,
    bool? equippedArmorTrained,
    bool? equippedShieldTrained,
    int? deathSuccesses,
    int? deathFailures,
    List<String>? unverifiedNotes,
  }) => HeroCharacter(
    id: id ?? this.id,
    name: name ?? this.name,
    species: species ?? this.species,
    className: className ?? this.className,
    secondaryClassName: secondaryClassName ?? this.secondaryClassName,
    secondaryClassLevel: secondaryClassLevel ?? this.secondaryClassLevel,
    secondarySubclass: secondarySubclass ?? this.secondarySubclass,
    level: level ?? this.level,
    subclass: subclass ?? this.subclass,
    background: background ?? this.background,
    backstory: backstory ?? this.backstory,
    portraitPreset: portraitPreset ?? this.portraitPreset,
    portraitPhotoBase64: portraitPhotoBase64 ?? this.portraitPhotoBase64,
    abilities: abilities ?? this.abilities,
    hitPoints: identical(hitPoints, _unchanged)
        ? this.hitPoints
        : hitPoints as int?,
    maxHitPoints: identical(maxHitPoints, _unchanged)
        ? this.maxHitPoints
        : maxHitPoints as int?,
    temporaryHitPoints: temporaryHitPoints ?? this.temporaryHitPoints,
    armorClass: identical(armorClass, _unchanged)
        ? this.armorClass
        : armorClass as int?,
    speed: identical(speed, _unchanged) ? this.speed : speed as int?,
    speedRemainderDecimeters:
        speedRemainderDecimeters ?? this.speedRemainderDecimeters,
    skills: skills ?? this.skills,
    savingThrowProficiencies:
        savingThrowProficiencies ?? this.savingThrowProficiencies,
    features: features ?? this.features,
    spells: spells ?? this.spells,
    inventory: inventory ?? this.inventory,
    gold: identical(gold, _unchanged) ? this.gold : gold as int?,
    experience: identical(experience, _unchanged)
        ? this.experience
        : experience as int?,
    conditions: conditions ?? manualConditions,
    conditionEffects: conditionEffects ?? this.conditionEffects,
    exhaustionLevel: exhaustionLevel ?? this.exhaustionLevel,
    spentHitDice: spentHitDice ?? this.spentHitDice,
    spentSpellSlots: spentSpellSlots ?? this.spentSpellSlots,
    spentPactSlots: spentPactSlots ?? this.spentPactSlots,
    spentSecondWind: spentSecondWind ?? this.spentSecondWind,
    spentActionSurge: spentActionSurge ?? this.spentActionSurge,
    spentClassResources: spentClassResources ?? this.spentClassResources,
    concentratingOn: concentratingOn ?? this.concentratingOn,
    weaponDamage: weaponDamage ?? this.weaponDamage,
    weaponAbility: weaponAbility ?? this.weaponAbility,
    weaponProficient: weaponProficient ?? this.weaponProficient,
    equippedArmorId: equippedArmorId ?? this.equippedArmorId,
    equippedShieldId: equippedShieldId ?? this.equippedShieldId,
    equippedWeaponId: equippedWeaponId ?? this.equippedWeaponId,
    equippedArmorTrained: equippedArmorTrained ?? this.equippedArmorTrained,
    equippedShieldTrained: equippedShieldTrained ?? this.equippedShieldTrained,
    deathSuccesses: deathSuccesses ?? this.deathSuccesses,
    deathFailures: deathFailures ?? this.deathFailures,
    unverifiedNotes: unverifiedNotes ?? this.unverifiedNotes,
  );
  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'id': id,
    'name': name,
    'species': species,
    'className': className,
    if (secondaryClassName.isNotEmpty) 'secondaryClassName': secondaryClassName,
    if (secondaryClassLevel > 0) 'secondaryClassLevel': secondaryClassLevel,
    if (secondarySubclass.isNotEmpty) 'secondarySubclass': secondarySubclass,
    'level': level,
    'subclass': subclass,
    'background': background,
    'backstory': backstory,
    if (portraitPreset >= 0) 'portraitPreset': portraitPreset,
    if (portraitPhotoBase64.isNotEmpty)
      'portraitPhotoBase64': portraitPhotoBase64,
    'abilities': abilities,
    'hitPoints': hitPoints,
    'maxHitPoints': maxHitPoints,
    if (temporaryHitPoints > 0) 'temporaryHitPoints': temporaryHitPoints,
    'armorClass': armorClass,
    'speed': speed,
    if (speedRemainderDecimeters != 0)
      'speedRemainderDecimeters': speedRemainderDecimeters,
    'skills': skills,
    'savingThrowProficiencies': savingThrowProficiencies,
    'features': features,
    'spells': spells,
    'inventory': inventory.map((e) => e.toJson()).toList(),
    'gold': gold,
    'experience': experience,
    'conditions': manualConditions,
    if (conditionEffects.isNotEmpty)
      'conditionEffects': conditionEffects.map((e) => e.toJson()).toList(),
    if (exhaustionLevel > 0) 'exhaustionLevel': exhaustionLevel,
    if (spentHitDice.isNotEmpty) 'spentHitDice': spentHitDice,
    if (spentSpellSlots.isNotEmpty) 'spentSpellSlots': spentSpellSlots,
    if (spentPactSlots > 0) 'spentPactSlots': spentPactSlots,
    if (spentSecondWind > 0) 'spentSecondWind': spentSecondWind,
    if (spentActionSurge > 0) 'spentActionSurge': spentActionSurge,
    if (spentClassResources.values.any((spent) => spent > 0))
      'spentClassResources': {
        for (final e in spentClassResources.entries)
          if (e.value > 0) e.key: e.value,
      },
    if (concentratingOn.isNotEmpty) 'concentratingOn': concentratingOn,
    'weaponDamage': weaponDamage,
    'weaponAbility': weaponAbility,
    'weaponProficient': weaponProficient,
    if (equippedArmorId.isNotEmpty) 'equippedArmorId': equippedArmorId,
    if (equippedShieldId.isNotEmpty) 'equippedShieldId': equippedShieldId,
    if (equippedWeaponId.isNotEmpty) 'equippedWeaponId': equippedWeaponId,
    if (equippedArmorTrained) 'equippedArmorTrained': true,
    if (equippedShieldTrained) 'equippedShieldTrained': true,
    'deathSuccesses': deathSuccesses,
    'deathFailures': deathFailures,
    'unverifiedNotes': unverifiedNotes,
  };
  factory HeroCharacter.fromJson(Map<String, dynamic> j) {
    _version(j);
    final a = _map(j['abilities'], 'Attribute');
    if (a.keys.any((key) => !abilityNames.contains(key))) {
      throw const FormatException('Unbekanntes Attribut.');
    }
    final hp = _nullableInt(j['hitPoints'], 'Trefferpunkte');
    final maxHp = _nullableInt(
      j['maxHitPoints'],
      'Maximale Trefferpunkte',
      min: 1,
    );
    if (hp != null && maxHp != null && hp > maxHp) {
      throw const FormatException('Trefferpunkte über Maximum.');
    }
    if (_readSpeedRemainder(j['speedRemainderDecimeters']) != 0 &&
        _nullableInt(j['speed'], 'Bewegung', max: 1000) == null) {
      throw const FormatException(
        'Ein halber Meter Rest setzt einen bestätigten Bewegungswert voraus.',
      );
    }
    final weaponAbility = _string(
      j['weaponAbility'],
      'Waffenattribut',
      fallback: 'strength',
    );
    if (!abilityNames.contains(weaponAbility)) {
      throw const FormatException('Unbekanntes Waffenattribut.');
    }
    final weaponDamage = _string(
      j['weaponDamage'],
      'Waffenschaden',
      fallback: '',
    );
    if (weaponDamage.isNotEmpty &&
        !RegExp(
          r'^([1-9][0-9]?)[dDwW](4|6|8|10|12|20|100)(\s*[+-]\s*[0-9]{1,3})?$',
        ).hasMatch(weaponDamage)) {
      throw const FormatException('Ungültiger Waffenschaden.');
    }
    final secondary = _string(
      j['secondaryClassName'],
      'Zweitklasse',
      fallback: '',
    );
    final secondaryLevel = _int(
      j['secondaryClassLevel'],
      'Zweitklassenstufe',
      fallback: 0,
      min: 0,
      max: 19,
    );
    final totalLevel = _int(j['level'], 'Stufe', min: 1, max: 20);
    final diceRecord = j['spentHitDice'];
    if (diceRecord != null && diceRecord is! Map<String, dynamic>) {
      throw const FormatException('Verbrauchte Trefferwürfel sind ungültig.');
    }
    final spent = <String, int>{};
    if (diceRecord != null) {
      for (final entry in diceRecord.entries) {
        if (!const ['d6', 'd8', 'd10', 'd12'].contains(entry.key) ||
            entry.value is! int ||
            entry.value < 0 ||
            entry.value > totalLevel) {
          throw const FormatException('Ungültiger Trefferwürfelbestand.');
        }
        if (entry.value > 0) spent[entry.key] = entry.value as int;
      }
      if (spent.values.fold<int>(0, (sum, count) => sum + count) > totalLevel) {
        throw const FormatException(
          'Mehr Trefferwürfel verbraucht als Stufen vorhanden.',
        );
      }
    }

    final spellsRecord = j['spentSpellSlots'];
    if (spellsRecord != null && spellsRecord is! Map<String, dynamic>) {
      throw const FormatException('Zauberplatzverbrauch ist ungültig.');
    }
    const maxima = [4, 3, 3, 3, 3, 2, 2, 1, 1];
    final spentSlots = <String, int>{};
    if (spellsRecord != null) {
      for (final entry in spellsRecord.entries) {
        final slot = int.tryParse(entry.key);
        if (slot == null ||
            slot < 1 ||
            slot > 9 ||
            entry.key != '$slot' ||
            entry.value is! int ||
            entry.value < 0 ||
            entry.value > maxima[slot - 1]) {
          throw const FormatException('Ungültiger verbrauchter Zauberplatz.');
        }
        if (entry.value > 0) spentSlots[entry.key] = entry.value as int;
      }
    }
    final classResourceRaw = j['spentClassResources'];
    if (classResourceRaw != null && classResourceRaw is! Map<String, dynamic>) {
      throw const FormatException('Klassenressourcen sind ungültig.');
    }
    final spentClassResources = <String, int>{};
    if (classResourceRaw != null) {
      for (final e in classResourceRaw.entries) {
        if (!ClassResourceRules.supported.contains(e.key) ||
            e.value is! int ||
            e.value < 0 ||
            e.value > 100) {
          throw const FormatException('Ungültige Klassenressource.');
        }
        if (e.value > 0) spentClassResources[e.key] = e.value as int;
      }
    }
    final spentPact = _int(
      j['spentPactSlots'],
      'Verbrauchte Paktplätze',
      fallback: 0,
      min: 0,
      max: 4,
    );
    final concentration = _string(
      j['concentratingOn'],
      'Konzentrationszauber',
      fallback: '',
    );
    if (concentration.length > 200 || concentration != concentration.trim()) {
      throw const FormatException('Ungültiger Konzentrationszauber.');
    }

    if ((secondary.isEmpty && secondaryLevel != 0) ||
        (secondary.isNotEmpty &&
            (secondaryLevel < 1 || secondaryLevel >= totalLevel)) ||
        (secondary.isNotEmpty &&
            secondary.toLowerCase() ==
                _string(j['className'], 'Klasse').toLowerCase())) {
      throw const FormatException(
        'Ungültige Zweitklassenstufe oder Klassenkombination.',
      );
    }
    final secondarySubclass = _string(
      j['secondarySubclass'],
      'Unterklasse der Zweitklasse',
      fallback: '',
    );
    if (secondarySubclass.length > 120 ||
        (secondarySubclass.isNotEmpty &&
            (secondary.isEmpty || secondaryLevel < 3))) {
      throw const FormatException(
        'Die zweite Unterklasse setzt drei Stufen in der Zweitklasse voraus.',
      );
    }
    final portraitPreset = _int(
      j['portraitPreset'],
      'Porträtvorlage',
      fallback: -1,
      min: -1,
      max: 8,
    );
    final photo = j['portraitPhotoBase64'] ?? '';
    if (photo is! String ||
        photo.length > 64000 ||
        (photo.isNotEmpty &&
            (photo.length % 4 != 0 ||
                !RegExp(r'^[A-Za-z0-9+/]+={0,2}$').hasMatch(photo)))) {
      throw const FormatException(
        'Ungültige oder zu große Charakterbilddaten.',
      );
    }
    if (portraitPreset >= 0 && photo.isNotEmpty) {
      throw const FormatException('Nur eine Charakterbildquelle ist zulässig.');
    }
    final items = _list(
      j['inventory'],
      'Inventar',
    ).map((item) => InventoryItem.fromJson(_map(item, 'Gegenstand'))).toList();
    final armorId = _string(
      j['equippedArmorId'],
      'Rüstungs-Referenz',
      fallback: '',
    );
    final shieldId = _string(
      j['equippedShieldId'],
      'Schild-Referenz',
      fallback: '',
    );
    final weaponId = _string(
      j['equippedWeaponId'],
      'Waffen-Referenz',
      fallback: '',
    );
    final equipped = [armorId, shieldId, weaponId].where((id) => id.isNotEmpty);
    if (equipped.length != equipped.toSet().length ||
        equipped.any(
          (id) =>
              items
                  .where((item) => item.id == id && item.catalogId.isNotEmpty)
                  .length !=
              1,
        )) {
      throw const FormatException(
        'Ausrüstung verweist auf fehlende oder doppelte Inventareinträge.',
      );
    }
    for (final (id, type) in [
      (armorId, 'armor'),
      (shieldId, 'shield'),
      (weaponId, 'weapon'),
    ]) {
      if (id.isEmpty) continue;
      final match = items.singleWhere((item) => item.id == id);
      final entry = SrdEquipmentCatalog.byId(match.catalogId);
      if (entry == null ||
          (type == 'armor' && !entry.isArmor) ||
          (type == 'shield' && !entry.isShield) ||
          (type == 'weapon' && !entry.isWeapon)) {
        throw const FormatException(
          'Nicht unterstützter ausgerüsteter Gegenstand.',
        );
      }
    }
    if (shieldId.isNotEmpty && weaponId.isNotEmpty) {
      final weapon = SrdEquipmentCatalog.byId(
        items.singleWhere((item) => item.id == weaponId).catalogId,
      );
      if (weapon!.hasProperty('two-handed')) {
        throw const FormatException(
          'Schild und Zweihandwaffe dürfen nicht gleichzeitig ausgerüstet sein.',
        );
      }
    }
    if ((armorId.isEmpty &&
            _bool(j['equippedArmorTrained'], 'Rüstungsübung')) ||
        (shieldId.isEmpty &&
            _bool(j['equippedShieldTrained'], 'Schildübung'))) {
      throw const FormatException(
        'Ausrüstungsübung ohne angelegten Gegenstand.',
      );
    }
    final parsed = HeroCharacter(
      id: _string(j['id'], 'Charakter-ID'),
      name: _string(j['name'], 'Name'),
      species: _string(j['species'], 'Spezies'),
      className: _string(j['className'], 'Klasse'),
      secondaryClassName: secondary,
      secondaryClassLevel: secondaryLevel,
      secondarySubclass: secondarySubclass,
      level: totalLevel,
      subclass: _string(j['subclass'], 'Unterklasse', fallback: ''),
      background: _string(j['background'], 'Hintergrund', fallback: ''),
      backstory: _string(j['backstory'], 'Geschichte', fallback: ''),
      portraitPreset: portraitPreset,
      portraitPhotoBase64: photo,
      abilities: {
        for (final key in abilityNames)
          key: _nullableInt(a[key], key, min: 1, max: 30),
      },
      hitPoints: hp,
      maxHitPoints: maxHp,
      temporaryHitPoints: _int(
        j['temporaryHitPoints'],
        'Temporäre Trefferpunkte',
        fallback: 0,
        max: 100000,
      ),
      armorClass: _nullableInt(
        j['armorClass'],
        'Rüstungsklasse',
        min: 1,
        max: 100,
      ),
      speed: _nullableInt(j['speed'], 'Bewegung', max: 1000),
      speedRemainderDecimeters: _readSpeedRemainder(
        j['speedRemainderDecimeters'],
      ),
      skills: _strings(j['skills'], 'Fertigkeiten'),
      savingThrowProficiencies: _strings(
        j['savingThrowProficiencies'],
        'Rettungswürfe',
      ),
      features: _strings(j['features'], 'Fähigkeiten'),
      spells: _strings(j['spells'], 'Zauber'),
      inventory: items,
      gold: _nullableInt(j['gold'], 'Gold'),
      experience: _nullableInt(j['experience'], 'Erfahrung'),
      conditions: _strings(j['conditions'], 'Zustände'),
      conditionEffects: _list(
        j['conditionEffects'],
        'Zustandseffekte',
      ).map(ConditionEffect.fromJson).toList(),
      exhaustionLevel: _int(
        j['exhaustionLevel'],
        'Erschöpfung',
        fallback: 0,
        min: 0,
        max: 6,
      ),
      spentHitDice: spent,
      spentSpellSlots: spentSlots,
      spentPactSlots: spentPact,
      spentSecondWind: _int(
        j['spentSecondWind'],
        'Second Wind',
        fallback: 0,
        min: 0,
        max: 4,
      ),
      spentActionSurge: _int(
        j['spentActionSurge'],
        'Action Surge',
        fallback: 0,
        min: 0,
        max: 2,
      ),
      spentClassResources: spentClassResources,
      concentratingOn: concentration,
      weaponDamage: weaponDamage,
      weaponAbility: weaponAbility,
      weaponProficient: _bool(j['weaponProficient'], 'Waffenübung'),
      equippedArmorId: armorId,
      equippedShieldId: shieldId,
      equippedWeaponId: weaponId,
      equippedArmorTrained: _bool(j['equippedArmorTrained'], 'Rüstungsübung'),
      equippedShieldTrained: _bool(j['equippedShieldTrained'], 'Schildübung'),
      deathSuccesses: _int(
        j['deathSuccesses'],
        'Todeserfolge',
        fallback: 0,
        max: 3,
      ),
      deathFailures: _int(
        j['deathFailures'],
        'Todesfehlschläge',
        fallback: 0,
        max: 3,
      ),
      unverifiedNotes: _strings(j['unverifiedNotes'], 'Ungeprüfte Angaben'),
    );
    // Reject forged/unavailable slots during import, before persisting any
    // partial campaign state. Existing saves without these fields stay valid.
    SpellcastingRules.availableSlots(parsed);
    SpellcastingRules.availablePactSlots(parsed);
    ClassFeatureResources.validate(parsed);
    ClassResourceRules.validate(parsed);
    if (parsed.concentratingOn.isNotEmpty &&
        (parsed.isDead || parsed.hitPoints == 0)) {
      throw const FormatException(
        'Bewusstlose oder tote Helden können nicht konzentrieren.',
      );
    }
    return parsed;
  }
}

class NarrativeMessage {
  const NarrativeMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
  });
  final String id, role, text;
  final DateTime timestamp;
  Map<String, dynamic> toJson() => {
    'id': id,
    'role': role,
    'text': text,
    'timestamp': timestamp.toUtc().toIso8601String(),
  };
  factory NarrativeMessage.fromJson(Map<String, dynamic> j) {
    final role = _string(j['role'], 'Sprecher');
    if (!['player', 'gm', 'system'].contains(role)) {
      throw const FormatException('Ungültiger Sprecher.');
    }
    return NarrativeMessage(
      id: _string(j['id'], 'Nachricht-ID'),
      role: role,
      text: _string(j['text'], 'Nachricht'),
      timestamp: DateTime.parse(_string(j['timestamp'], 'Zeitstempel')),
    );
  }
}

class Quest {
  const Quest({
    required this.id,
    required this.title,
    this.description = '',
    this.status = 'active',
  });
  final String id, title, description, status;
  Quest copyWith({String? status, String? description}) => Quest(
    id: id,
    title: title,
    description: description ?? this.description,
    status: status ?? this.status,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'status': status,
  };
  factory Quest.fromJson(Map<String, dynamic> j) {
    final status = _string(j['status'], 'Queststatus', fallback: 'active');
    if (!['active', 'completed', 'failed'].contains(status)) {
      throw const FormatException('Ungültiger Queststatus.');
    }
    return Quest(
      id: _string(j['id'], 'Quest-ID'),
      title: _string(j['title'], 'Quest'),
      description: _string(j['description'], 'Beschreibung', fallback: ''),
      status: status,
    );
  }
}

/// AI proposal, never an active encounter, reward or completed quest.
/// Its enemy archetype is resolved exclusively against the local catalogue.
class AdventureOffer {
  const AdventureOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.archetype,
    required this.questTitle,
    required this.questDescription,
  });
  final String id, title, description, archetype, questTitle, questDescription;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'archetype': archetype,
    'questTitle': questTitle,
    'questDescription': questDescription,
  };
  factory AdventureOffer.fromJson(Map<String, dynamic> j) {
    String bounded(String key, int max) {
      final value = _string(j[key], key).trim();
      if (value.isEmpty || value.length > max) {
        throw const FormatException('Ungültiger Begegnungsvorschlag.');
      }
      return value;
    }

    final id = bounded('id', 64);
    if (!RegExp(r'^[a-z][a-z0-9_-]{0,63}$').hasMatch(id)) {
      throw const FormatException('Ungültige Begegnungs-ID.');
    }
    final archetype = bounded('archetype', 32);
    if (!const [
      'bandit',
      'wolf',
      'skeleton',
      'goblin',
      'orc',
      'investigation',
    ].contains(archetype)) {
      throw const FormatException('Unbekanntes Gegnerprofil.');
    }
    return AdventureOffer(
      id: id,
      title: bounded('title', 120),
      description: bounded('description', 500),
      archetype: archetype,
      questTitle: bounded('questTitle', 120),
      questDescription: bounded('questDescription', 500),
    );
  }
}

class WorldNpc {
  const WorldNpc({
    required this.id,
    required this.name,
    this.description = '',
    this.alive = true,
    this.relationship = 'neutral',
  });
  final String id, name, description, relationship;
  final bool alive;
  WorldNpc copyWith({bool? alive, String? relationship}) => WorldNpc(
    id: id,
    name: name,
    description: description,
    alive: alive ?? this.alive,
    relationship: relationship ?? this.relationship,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'alive': alive,
    'relationship': relationship,
  };
  factory WorldNpc.fromJson(Map<String, dynamic> j) => WorldNpc(
    id: _string(j['id'], 'NPC-ID'),
    name: _string(j['name'], 'NPC'),
    description: _string(j['description'], 'Beschreibung', fallback: ''),
    alive: _bool(j['alive'], 'Lebendig', fallback: true),
    relationship: _string(j['relationship'], 'Beziehung', fallback: 'neutral'),
  );
}

/// Confirmed, deterministic snapshot of known campaign information.
/// Separate from free-form narrator dialogue or unverified player claims.
class SessionRecap {
  const SessionRecap({
    required this.id,
    required this.title,
    required this.summary,
    required this.createdAt,
  });
  final String id, title, summary;
  final DateTime createdAt;
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'summary': summary,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };
  factory SessionRecap.fromJson(Map<String, dynamic> j) {
    final title = _string(j['title'], 'Rückblickstitel');
    final summary = _string(j['summary'], 'Sitzungsrückblick');
    if (title.trim().isEmpty ||
        title.length > 100 ||
        summary.trim().isEmpty ||
        summary.length > 2400) {
      throw const FormatException('Ungültiger Sitzungsrückblick.');
    }
    return SessionRecap(
      id: _string(j['id'], 'Rückblick-ID'),
      title: title,
      summary: summary,
      createdAt: DateTime.parse(_string(j['createdAt'], 'Rückblickdatum')),
    );
  }
}

/// A user-managed story hook. Status changes never imply a quest reward.
class StoryThread {
  const StoryThread({
    required this.id,
    required this.title,
    this.description = '',
    this.status = 'open',
  });
  final String id, title, description, status;
  StoryThread copyWith({String? title, String? description, String? status}) =>
      StoryThread(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        status: status ?? this.status,
      );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'status': status,
  };
  factory StoryThread.fromJson(Map<String, dynamic> j) {
    final title = _string(j['title'], 'Handlungsstrang');
    final description = _string(
      j['description'],
      'Handlungsnotiz',
      fallback: '',
    );
    final status = _string(j['status'], 'Handlungsstatus', fallback: 'open');
    if (title.trim().isEmpty ||
        title.length > 120 ||
        description.length > 1000 ||
        !const ['open', 'resolved', 'abandoned'].contains(status)) {
      throw const FormatException('Ungültiger Handlungsstrang.');
    }
    return StoryThread(
      id: _string(j['id'], 'Handlungs-ID'),
      title: title,
      description: description,
      status: status,
    );
  }
}

/// Explicitly recorded NPC relationship, retained as an auditable timeline.
class NpcRelationshipNote {
  const NpcRelationshipNote({
    required this.id,
    required this.npcId,
    required this.relationship,
    required this.note,
    required this.recordedAt,
  });
  final String id, npcId, relationship, note;
  final DateTime recordedAt;
  Map<String, dynamic> toJson() => {
    'id': id,
    'npcId': npcId,
    'relationship': relationship,
    'note': note,
    'recordedAt': recordedAt.toUtc().toIso8601String(),
  };
  factory NpcRelationshipNote.fromJson(Map<String, dynamic> j) {
    final relationship = _string(j['relationship'], 'NPC-Beziehung');
    final note = _string(j['note'], 'Beziehungsnotiz');
    if (relationship.trim().isEmpty ||
        relationship.length > 80 ||
        note.trim().isEmpty ||
        note.length > 500) {
      throw const FormatException('Ungültige Beziehungsnotiz.');
    }
    return NpcRelationshipNote(
      id: _string(j['id'], 'Notiz-ID'),
      npcId: _string(j['npcId'], 'NPC-ID'),
      relationship: relationship,
      note: note,
      recordedAt: DateTime.parse(_string(j['recordedAt'], 'Notizdatum')),
    );
  }
}

class Place {
  const Place({required this.id, required this.name, this.description = ''});
  final String id, name, description;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
  };
  factory Place.fromJson(Map<String, dynamic> j) => Place(
    id: _string(j['id'], 'Ort-ID'),
    name: _string(j['name'], 'Ort'),
    description: _string(j['description'], 'Beschreibung', fallback: ''),
  );
}

class GameEvent {
  GameEvent({
    required this.id,
    required this.campaignId,
    required this.sessionId,
    required this.timestamp,
    required this.type,
    List<String> entities = const [],
    Map<String, dynamic> payload = const {},
  }) : entities = List.unmodifiable(entities),
       payload = Map.unmodifiable(payload);
  final String id, campaignId, sessionId, type;
  final DateTime timestamp;
  final List<String> entities;
  final Map<String, dynamic> payload;
  Map<String, dynamic> toJson() => {
    'id': id,
    'campaignId': campaignId,
    'sessionId': sessionId,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'type': type,
    'entities': entities,
    'payload': payload,
  };
  factory GameEvent.fromJson(Map<String, dynamic> j) => GameEvent(
    id: _string(j['id'], 'Ereignis-ID'),
    campaignId: _string(j['campaignId'], 'Kampagnen-ID'),
    sessionId: _string(j['sessionId'], 'Sitzungs-ID'),
    timestamp: DateTime.parse(_string(j['timestamp'], 'Zeitstempel')),
    type: _string(j['type'], 'Ereignistyp'),
    entities: _strings(j['entities'], 'Objekte'),
    payload: _map(j['payload'], 'Ereignisdaten'),
  );
}

class PendingRoll {
  const PendingRoll({
    required this.id,
    required this.type,
    required this.modifier,
    required this.difficulty,
    this.targetId = '',
    this.targetName = '',
    this.weaponId = '',
    this.expression = '1d20',
    this.deathSaveRulesVersion = 0,
    this.minimumNatural = 0,
    this.advantage = false,
    this.disadvantage = false,
  });
  final String id, type, targetId, targetName, weaponId, expression;
  final int modifier, difficulty;
  final int deathSaveRulesVersion;

  /// The verified skill check's lower natural d20 limit, 0 or 10.
  final int minimumNatural;
  final bool advantage, disadvantage;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'modifier': modifier,
    'difficulty': difficulty,
    'targetId': targetId,
    'targetName': targetName,
    if (weaponId.isNotEmpty) 'weaponId': weaponId,
    'expression': expression,
    if (deathSaveRulesVersion > 0)
      'deathSaveRulesVersion': deathSaveRulesVersion,
    if (minimumNatural > 0) 'minimumNatural': minimumNatural,
    if (advantage) 'advantage': true,
    if (disadvantage) 'disadvantage': true,
  };
  factory PendingRoll.fromJson(Map<String, dynamic> j) {
    final type = _string(j['type'], 'Probeart');
    final expression = _string(j['expression'], 'Würfel', fallback: '1d20');
    if (![
          'attack',
          'offhandAttack',
          'death',
          'escape',
          'perception',
          'preparedCheck',
        ].contains(type) ||
        expression != '1d20') {
      throw const FormatException('Unbekannte Probe oder Würfelanweisung.');
    }
    final minimumNatural = _int(
      j['minimumNatural'],
      'Fertigkeits-Mindestwurf',
      fallback: 0,
      min: 0,
      max: 10,
    );
    if ((minimumNatural != 0 && minimumNatural != 10) ||
        (minimumNatural > 0 &&
            type != 'preparedCheck' &&
            type != 'perception')) {
      throw const FormatException('Unzulässiger natürlicher Mindestwurf.');
    }
    final weaponId = _string(j['weaponId'], 'Nebenhandwaffe', fallback: '');
    if ((type == 'offhandAttack') != weaponId.isNotEmpty) {
      throw const FormatException('Ungültige Nebenhand-Angriffsanweisung.');
    }
    final deathVersion = _int(
      j['deathSaveRulesVersion'],
      'Todesrettungsregelversion',
      fallback: 0,
      max: 1,
    );
    if ((type != 'death' && deathVersion != 0) ||
        (type == 'death' &&
            (_bool(j['advantage'], 'Vorteil') ||
                _bool(j['disadvantage'], 'Nachteil')))) {
      throw const FormatException('Unzulässige Todesrettungsanweisung.');
    }
    return PendingRoll(
      deathSaveRulesVersion: deathVersion,
      minimumNatural: minimumNatural,
      id: _string(j['id'], 'Probe-ID'),
      type: type,
      modifier: _int(j['modifier'], 'Modifikator', min: -20, max: 30),
      difficulty: _int(j['difficulty'], 'Schwierigkeit', min: 1, max: 100),
      targetId: _string(j['targetId'], 'Ziel-ID', fallback: ''),
      targetName: _string(j['targetName'], 'Ziel', fallback: ''),
      weaponId: weaponId,
      expression: expression,
      advantage: _bool(j['advantage'], 'Vorteil'),
      disadvantage: _bool(j['disadvantage'], 'Nachteil'),
    );
  }
}

/// A failed, not-yet-applied roll awaiting an explicit class-feature choice.
/// The campaign hero is still the state BEFORE this roll. No arbitrary saved
/// character snapshot or provider-supplied result may replace it.
class PendingDeathSave {
  const PendingDeathSave({
    required this.originalNatural,
    required this.modifier,
  });
  final int originalNatural, modifier;
  Map<String, dynamic> toJson() => {
    'originalNatural': originalNatural,
    'modifier': modifier,
  };
  factory PendingDeathSave.fromJson(Map<String, dynamic> j) => PendingDeathSave(
    originalNatural: _int(
      j['originalNatural'],
      'Vorläufiger Todesrettungswurf',
      min: 1,
      max: 19,
    ),
    modifier: _int(j['modifier'], 'Todesrettungsbonus', min: -20, max: 30),
  );
}

/// A rolled, genuinely hitting enemy attack awaiting the player's
/// post-hit Shield reaction decision. No damage has been rolled or applied.
class PendingEnemyShieldHit {
  const PendingEnemyShieldHit({
    required this.encounterId,
    required this.natural,
    required this.modifier,
    required this.total,
    required this.rolls,
    required this.advanceRound,
  });

  final String encounterId;
  final int natural, modifier, total;
  final List<int> rolls;
  final bool advanceRound;

  Map<String, dynamic> toJson() => {
    'encounterId': encounterId,
    'natural': natural,
    'modifier': modifier,
    'total': total,
    'rolls': rolls,
    'advanceRound': advanceRound,
  };

  factory PendingEnemyShieldHit.fromJson(Map<String, dynamic> j) {
    final natural = _int(j['natural'], 'Gegnernaturwurf', min: 1, max: 20);
    final modifier = _int(
      j['modifier'],
      'Gegnerangriffsbonus',
      min: -20,
      max: 30,
    );
    final total = _int(j['total'], 'Gegnerangriffsergebnis', min: -20, max: 50);
    final rolls = _list(j['rolls'], 'Gegnerangriffswürfel')
        .map((v) => _int(v, 'Gegnerwürfel', min: 1, max: 20))
        .toList(growable: false);
    if (total != natural + modifier ||
        rolls.isEmpty ||
        rolls.length > 2 ||
        !rolls.contains(natural)) {
      throw const FormatException('Manipulierter Gegnerangriffswurf.');
    }
    return PendingEnemyShieldHit(
      encounterId: _string(j['encounterId'], 'Angriffsziel-ID'),
      natural: natural,
      modifier: modifier,
      total: total,
      rolls: List.unmodifiable(rolls),
      advanceRound: _bool(j['advanceRound'], 'Rundenfortschritt'),
    );
  }
}

class Encounter {
  const Encounter({
    required this.id,
    required this.enemyName,
    required this.enemyHitPoints,
    required this.enemyMaxHitPoints,
    this.enemyArmorClass = 12,
    this.heroCover = CoverLevel.none,
    this.enemyCover = CoverLevel.none,
    this.enemyForceDefense = EnemyForceDefense.unknown,
    this.enemyShieldSlotsRemaining,
    this.enemyShieldReactionUsed = false,
    this.enemyShieldActive = false,
    this.enemyAttacksPerTurn = 1,
    this.enemyAttacksRemaining = 0,
    this.enemyTurnAdvanceRound = false,
    this.heroShieldActive = false,
    this.enemyAttackBonus = 2,
    this.enemyDamage = '1d4',
    this.enemyDamageType = '',
    this.round = 1,
    this.activeParticipant = 'hero',
    this.heroInitiative = 0,
    this.enemyInitiative = 0,
    this.movementRemaining = 9,
    this.movementRemainderDecimeters = 0,
    this.actionUsed = false,
    this.attacksRemaining = 0,
    this.bonusActionUsed = false,
    this.lightAttackAvailable = false,
    this.spellSlotExpendedThisTurn = false,
    this.deathSaveResolvedThisTurn = false,
    this.dodgeActive = false,
    this.disengagedThisTurn = false,
    this.jumpDoubledThisTurn = false,
    this.reactionUsed = false,
    this.surgeReserved = false,
    this.surgeUsedThisTurn = false,
    this.sneakAttackUsedThisTurn = false,
    this.rageUntilRound = 0,
    this.rageStartedRound = 0,
    this.selfRestorationChoice = '',
  });
  final String id, enemyName, enemyDamage, enemyDamageType, activeParticipant;

  /// Explicitly confirmed from the CURRENT opponent's attack direction.
  /// Older campaigns default to no cover, not an inferred obstacle.
  final CoverLevel heroCover, enemyCover;

  /// Validated from an explicit encounter confirmation, never from narration.
  final EnemyForceDefense enemyForceDefense;

  /// Null means unknown; never invent monster spell slots.
  final int? enemyShieldSlotsRemaining;
  final bool enemyShieldReactionUsed, enemyShieldActive;

  /// Explicitly confirmed from a monster profile, not inferred from narration.
  final int enemyAttacksPerTurn, enemyAttacksRemaining;
  final bool enemyTurnAdvanceRound, heroShieldActive;
  int get effectiveEnemyArmorClass =>
      enemyArmorClass + (enemyShieldActive ? 5 : 0);

  /// Pending player choice for the Monk's end-of-turn Self-Restoration.
  final String selfRestorationChoice;
  final int enemyHitPoints,
      enemyMaxHitPoints,
      enemyArmorClass,
      enemyAttackBonus,
      round,
      heroInitiative,
      enemyInitiative,
      movementRemaining,
      movementRemainderDecimeters;

  /// Precise fraction of remaining movement in tenths of a meter (0..9).
  /// Older schema-1 campaigns omit it, retaining their full-meter balance.
  int get remainingMovementDecimeters =>
      movementRemaining * 10 + movementRemainderDecimeters;

  String get movementRemainingLabel => movementRemainderDecimeters == 0
      ? '$movementRemaining m'
      : '$movementRemaining.$movementRemainderDecimeters m';

  final bool actionUsed, bonusActionUsed, reactionUsed, lightAttackAvailable;

  /// SRD 2024: expend a spell slot to cast a spell only once on a turn.
  /// Absent in older schema-1 saves; defaults to false.
  final bool spellSlotExpendedThisTurn;
  final bool deathSaveResolvedThisTurn;

  /// Bonus-Action defensive effects persist until the enemy turn concludes.
  final bool dodgeActive, disengagedThisTurn, jumpDoubledThisTurn;

  /// One reserved extra Attack action; a second Action Surge is not allowed.
  final bool surgeReserved, surgeUsedThisTurn;

  /// A Sneak Attack may be used once per turn, including extra Attack actions.
  final bool sneakAttackUsedThisTurn;

  /// Rage ends at the end of this hero turn unless extended by a qualifying act.
  /// Zero means no active Rage. The start round imposes the 100-round limit.
  final int rageUntilRound, rageStartedRound;

  /// Remaining attacks after the first attack of a single Attack action.
  /// Old campaign saves omit the field and resume with zero.
  final int attacksRemaining;
  bool get isFinished => enemyHitPoints == 0;
  Encounter copyWith({
    int? enemyHitPoints,
    CoverLevel? heroCover,
    CoverLevel? enemyCover,
    EnemyForceDefense? enemyForceDefense,
    int? enemyShieldSlotsRemaining,
    bool? enemyShieldReactionUsed,
    bool? enemyShieldActive,
    int? enemyAttacksPerTurn,
    int? enemyAttacksRemaining,
    bool? enemyTurnAdvanceRound,
    bool? heroShieldActive,
    int? round,
    String? activeParticipant,
    int? heroInitiative,
    int? enemyInitiative,
    int? movementRemaining,
    int? movementRemainderDecimeters,
    bool? actionUsed,
    int? attacksRemaining,
    bool? bonusActionUsed,
    bool? lightAttackAvailable,
    bool? spellSlotExpendedThisTurn,
    bool? deathSaveResolvedThisTurn,
    bool? dodgeActive,
    bool? disengagedThisTurn,
    bool? jumpDoubledThisTurn,
    bool? reactionUsed,
    bool? surgeReserved,
    bool? surgeUsedThisTurn,
    bool? sneakAttackUsedThisTurn,
    int? rageUntilRound,
    int? rageStartedRound,
    String? selfRestorationChoice,
  }) => Encounter(
    id: id,
    enemyName: enemyName,
    enemyHitPoints: enemyHitPoints ?? this.enemyHitPoints,
    enemyMaxHitPoints: enemyMaxHitPoints,
    enemyArmorClass: enemyArmorClass,
    heroCover: heroCover ?? this.heroCover,
    enemyCover: enemyCover ?? this.enemyCover,
    enemyForceDefense: enemyForceDefense ?? this.enemyForceDefense,
    enemyShieldSlotsRemaining:
        enemyShieldSlotsRemaining ?? this.enemyShieldSlotsRemaining,
    enemyShieldReactionUsed:
        enemyShieldReactionUsed ?? this.enemyShieldReactionUsed,
    enemyShieldActive: enemyShieldActive ?? this.enemyShieldActive,
    enemyAttacksPerTurn: enemyAttacksPerTurn ?? this.enemyAttacksPerTurn,
    enemyAttacksRemaining: enemyAttacksRemaining ?? this.enemyAttacksRemaining,
    enemyTurnAdvanceRound: enemyTurnAdvanceRound ?? this.enemyTurnAdvanceRound,
    heroShieldActive: heroShieldActive ?? this.heroShieldActive,
    enemyAttackBonus: enemyAttackBonus,
    enemyDamage: enemyDamage,
    enemyDamageType: enemyDamageType,
    round: round ?? this.round,
    activeParticipant: activeParticipant ?? this.activeParticipant,
    heroInitiative: heroInitiative ?? this.heroInitiative,
    enemyInitiative: enemyInitiative ?? this.enemyInitiative,
    movementRemaining: movementRemaining ?? this.movementRemaining,
    movementRemainderDecimeters:
        movementRemainderDecimeters ?? this.movementRemainderDecimeters,
    actionUsed: actionUsed ?? this.actionUsed,
    attacksRemaining: attacksRemaining ?? this.attacksRemaining,
    bonusActionUsed: bonusActionUsed ?? this.bonusActionUsed,
    lightAttackAvailable: lightAttackAvailable ?? this.lightAttackAvailable,
    spellSlotExpendedThisTurn:
        spellSlotExpendedThisTurn ?? this.spellSlotExpendedThisTurn,
    deathSaveResolvedThisTurn:
        deathSaveResolvedThisTurn ?? this.deathSaveResolvedThisTurn,
    dodgeActive: dodgeActive ?? this.dodgeActive,
    disengagedThisTurn: disengagedThisTurn ?? this.disengagedThisTurn,
    jumpDoubledThisTurn: jumpDoubledThisTurn ?? this.jumpDoubledThisTurn,
    reactionUsed: reactionUsed ?? this.reactionUsed,
    surgeReserved: surgeReserved ?? this.surgeReserved,
    surgeUsedThisTurn: surgeUsedThisTurn ?? this.surgeUsedThisTurn,
    sneakAttackUsedThisTurn:
        sneakAttackUsedThisTurn ?? this.sneakAttackUsedThisTurn,
    rageUntilRound: rageUntilRound ?? this.rageUntilRound,
    rageStartedRound: rageStartedRound ?? this.rageStartedRound,
    selfRestorationChoice: selfRestorationChoice ?? this.selfRestorationChoice,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'enemyName': enemyName,
    'enemyHitPoints': enemyHitPoints,
    'enemyMaxHitPoints': enemyMaxHitPoints,
    'enemyArmorClass': enemyArmorClass,
    if (heroCover != CoverLevel.none) 'heroCover': heroCover.name,
    if (enemyCover != CoverLevel.none) 'enemyCover': enemyCover.name,
    if (enemyForceDefense != EnemyForceDefense.unknown)
      'enemyForceDefense': enemyForceDefense.name,
    if (enemyShieldSlotsRemaining != null)
      'enemyShieldSlotsRemaining': enemyShieldSlotsRemaining,
    if (enemyShieldReactionUsed) 'enemyShieldReactionUsed': true,
    if (enemyShieldActive) 'enemyShieldActive': true,
    if (enemyAttacksPerTurn != 1) 'enemyAttacksPerTurn': enemyAttacksPerTurn,
    if (enemyAttacksRemaining > 0)
      'enemyAttacksRemaining': enemyAttacksRemaining,
    if (enemyTurnAdvanceRound) 'enemyTurnAdvanceRound': true,
    if (heroShieldActive) 'heroShieldActive': true,
    'enemyAttackBonus': enemyAttackBonus,
    'enemyDamage': enemyDamage,
    if (enemyDamageType.isNotEmpty) 'enemyDamageType': enemyDamageType,
    'round': round,
    'activeParticipant': activeParticipant,
    'heroInitiative': heroInitiative,
    'enemyInitiative': enemyInitiative,
    'movementRemaining': movementRemaining,
    if (movementRemainderDecimeters > 0)
      'movementRemainderDecimeters': movementRemainderDecimeters,
    'actionUsed': actionUsed,
    if (attacksRemaining > 0) 'attacksRemaining': attacksRemaining,
    'bonusActionUsed': bonusActionUsed,
    if (lightAttackAvailable) 'lightAttackAvailable': true,
    if (spellSlotExpendedThisTurn) 'spellSlotExpendedThisTurn': true,
    if (deathSaveResolvedThisTurn) 'deathSaveResolvedThisTurn': true,
    if (dodgeActive) 'dodgeActive': true,
    if (disengagedThisTurn) 'disengagedThisTurn': true,
    if (jumpDoubledThisTurn) 'jumpDoubledThisTurn': true,
    'reactionUsed': reactionUsed,
    if (surgeReserved) 'surgeReserved': true,
    if (surgeUsedThisTurn) 'surgeUsedThisTurn': true,
    if (sneakAttackUsedThisTurn) 'sneakAttackUsedThisTurn': true,
    if (rageUntilRound > 0) 'rageUntilRound': rageUntilRound,
    if (rageStartedRound > 0) 'rageStartedRound': rageStartedRound,
    if (selfRestorationChoice.isNotEmpty)
      'selfRestorationChoice': selfRestorationChoice,
  };
  factory Encounter.fromJson(Map<String, dynamic> j) {
    final maxHp = _int(j['enemyMaxHitPoints'], 'Gegnermaximum', min: 1);
    final hp = _int(j['enemyHitPoints'], 'Gegner-TP', max: maxHp);
    final damage = _string(j['enemyDamage'], 'Gegnerschaden', fallback: '1d4');
    if (!RegExp(
      r'^([1-9][0-9]?)[dDwW](4|6|8|10|12|20|100)(\s*[+-]\s*[0-9]{1,3})?$',
    ).hasMatch(damage)) {
      throw const FormatException('Ungültiger Gegnerschaden.');
    }
    final damageType = _string(
      j['enemyDamageType'],
      'Gegnerschadensart',
      fallback: '',
    );
    const supportedDamageTypes = {
      'acid',
      'bludgeoning',
      'cold',
      'fire',
      'force',
      'lightning',
      'necrotic',
      'piercing',
      'poison',
      'psychic',
      'radiant',
      'slashing',
      'thunder',
    };
    if (damageType.isNotEmpty && !supportedDamageTypes.contains(damageType)) {
      throw const FormatException('Unbekannte Gegnerschadensart.');
    }
    final active = _string(
      j['activeParticipant'],
      'Aktiver Teilnehmer',
      fallback: 'hero',
    );
    if (!['hero', 'enemy'].contains(active)) {
      throw const FormatException('Unbekannter aktiver Teilnehmer.');
    }
    if (_bool(j['surgeReserved'], 'Action Surge reserviert') &&
        !_bool(j['surgeUsedThisTurn'], 'Action Surge bereits genutzt')) {
      throw const FormatException(
        'Reservierte Zusatzaktion ohne Action Surge.',
      );
    }
    final rageStart = _int(
      j['rageStartedRound'],
      'Rage-Beginn',
      fallback: 0,
      min: 0,
      max: 1000000,
    );
    final rageEnd = _int(
      j['rageUntilRound'],
      'Rage-Ende',
      fallback: 0,
      min: 0,
      max: 1000000,
    );
    final currentRound = _int(j['round'], 'Runde', fallback: 1, min: 1);
    if ((rageStart == 0) != (rageEnd == 0) ||
        (rageEnd > 0 &&
            (rageStart > currentRound ||
                rageEnd < currentRound ||
                rageEnd < rageStart ||
                rageEnd > rageStart + 99))) {
      throw const FormatException('Ungültige Kampfrausch-Dauer.');
    }
    final restoration = _string(
      j['selfRestorationChoice'],
      'Selbstwiederherstellung',
      fallback: '',
    );
    if (restoration.isNotEmpty &&
        !const {
          'bezaubert',
          'verängstigt',
          'vergiftet',
        }.contains(restoration)) {
      throw const FormatException(
        'Ungültige Selbstwiederherstellungs-Auswahl.',
      );
    }
    final shieldSlots = j['enemyShieldSlotsRemaining'] == null
        ? null
        : _int(
            j['enemyShieldSlotsRemaining'],
            'Gegner-Schildzauberplätze',
            min: 0,
            max: 99,
          );
    final shieldActive = _bool(j['enemyShieldActive'], 'Schild aktiv');
    final shieldReactionUsed = _bool(
      j['enemyShieldReactionUsed'],
      'Gegnerreaktion verbraucht',
    );
    if (shieldActive && (!shieldReactionUsed || shieldSlots == null)) {
      throw const FormatException('Ungültiger aktiver Schildzauber.');
    }
    final enemyAttacks = _int(
      j['enemyAttacksPerTurn'],
      'Bestätigte gegnerische Angriffe',
      fallback: 1,
      min: 1,
      max: 4,
    );
    final enemyRemaining = _int(
      j['enemyAttacksRemaining'],
      'Verbleibende gegnerische Angriffe',
      fallback: 0,
      min: 0,
      max: 3,
    );
    final turnAdvance = _bool(
      j['enemyTurnAdvanceRound'],
      'Laufender Gegnerzug',
    );
    final heroShield = _bool(j['heroShieldActive'], 'Schild des Helden aktiv');
    if (enemyRemaining >= enemyAttacks ||
        (enemyRemaining > 0 && active != 'enemy') ||
        (turnAdvance && active != 'enemy') ||
        (heroShield && active != 'enemy')) {
      throw const FormatException('Ungültiger laufender Gegnerzug.');
    }
    return Encounter(
      id: _string(j['id'], 'Begegnung-ID'),
      enemyName: _string(j['enemyName'], 'Gegner'),
      enemyHitPoints: hp,
      enemyMaxHitPoints: maxHp,
      enemyArmorClass: _int(
        j['enemyArmorClass'],
        'Gegner-RK',
        fallback: 12,
        min: 1,
        max: 100,
      ),
      heroCover: CoverRules.fromStorage(
        _string(j['heroCover'], 'Deckung des Helden', fallback: 'none'),
      ),
      enemyCover: CoverRules.fromStorage(
        _string(j['enemyCover'], 'Deckung des Gegners', fallback: 'none'),
      ),
      enemyForceDefense: EnemyForceDefenseRules.fromStorage(
        _string(
          j['enemyForceDefense'],
          'Energieschaden-Abwehr des Gegners',
          fallback: 'unknown',
        ),
      ),
      enemyShieldSlotsRemaining: shieldSlots,
      enemyShieldReactionUsed: shieldReactionUsed,
      enemyShieldActive: shieldActive,
      enemyAttacksPerTurn: enemyAttacks,
      enemyAttacksRemaining: enemyRemaining,
      enemyTurnAdvanceRound: turnAdvance,
      heroShieldActive: heroShield,
      enemyAttackBonus: _int(
        j['enemyAttackBonus'],
        'Gegnerbonus',
        fallback: 2,
        min: -20,
        max: 30,
      ),
      enemyDamage: damage,
      enemyDamageType: damageType,
      round: _int(j['round'], 'Runde', fallback: 1, min: 1),
      activeParticipant: active,
      heroInitiative: _int(
        j['heroInitiative'],
        'Initiative',
        fallback: 0,
        min: -20,
      ),
      enemyInitiative: _int(
        j['enemyInitiative'],
        'Initiative',
        fallback: 0,
        min: -20,
      ),
      movementRemaining: _int(j['movementRemaining'], 'Bewegung', fallback: 9),
      movementRemainderDecimeters: _int(
        j['movementRemainderDecimeters'],
        'Bewegungsrest in Dezimetern',
        fallback: 0,
        min: 0,
        max: 9,
      ),
      actionUsed: _bool(j['actionUsed'], 'Aktion'),
      attacksRemaining: _int(
        j['attacksRemaining'],
        'Verbleibende Angriffe',
        fallback: 0,
        min: 0,
        max: 3,
      ),
      bonusActionUsed: _bool(j['bonusActionUsed'], 'Bonusaktion'),
      lightAttackAvailable: _bool(
        j['lightAttackAvailable'],
        'Leichter Zusatzangriff',
      ),
      deathSaveResolvedThisTurn: _bool(
        j['deathSaveResolvedThisTurn'],
        'Todesrettung in diesem Zug',
      ),
      spellSlotExpendedThisTurn: _bool(
        j['spellSlotExpendedThisTurn'],
        'Zauberplatz in diesem Zug',
      ),
      dodgeActive: _bool(j['dodgeActive'], 'Ausweichen aktiv'),
      disengagedThisTurn: _bool(j['disengagedThisTurn'], 'Rückzug aktiv'),
      jumpDoubledThisTurn: _bool(j['jumpDoubledThisTurn'], 'Sprungbonus aktiv'),
      reactionUsed: _bool(j['reactionUsed'], 'Reaktion'),
      surgeReserved: _bool(j['surgeReserved'], 'Action Surge reserviert'),
      surgeUsedThisTurn: _bool(
        j['surgeUsedThisTurn'],
        'Action Surge bereits genutzt',
      ),
      sneakAttackUsedThisTurn: _bool(
        j['sneakAttackUsedThisTurn'],
        'Hinterhältiger Angriff bereits genutzt',
      ),
      rageUntilRound: rageEnd,
      rageStartedRound: rageStart,
      selfRestorationChoice: restoration,
    );
  }
}

/// Explicitly recorded additional creature HP for area effects.
///
/// These are NOT fully simulated encounter actors: their initiative may be
/// explicitly recorded but does not authorize attacks, turns or movement.
class TrackedAreaCreature {
  const TrackedAreaCreature({
    required this.id,
    required this.name,
    required this.hitPoints,
    required this.maxHitPoints,
    this.initiativeTotal,
    this.initiativeController,
  });

  final String id, name;
  final int hitPoints, maxHitPoints;

  /// Null means initiative has NOT been confirmed; zero is a valid result.
  final int? initiativeTotal;

  /// Explicit SRD tie adjudicator: 'gm' for GM-managed creatures or
  /// 'player' for player-managed characters. Never inferred from a name.
  final String? initiativeController;

  TrackedAreaCreature copyWith({
    int? hitPoints,
    int? initiativeTotal,
    String? initiativeController,
  }) => TrackedAreaCreature(
    id: id,
    name: name,
    hitPoints: hitPoints ?? this.hitPoints,
    maxHitPoints: maxHitPoints,
    initiativeTotal: initiativeTotal ?? this.initiativeTotal,
    initiativeController: initiativeController ?? this.initiativeController,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'hitPoints': hitPoints,
    'maxHitPoints': maxHitPoints,
    if (initiativeTotal != null) 'initiativeTotal': initiativeTotal,
    if (initiativeController != null)
      'initiativeController': initiativeController,
  };

  factory TrackedAreaCreature.fromJson(Map<String, dynamic> j) {
    final id = _string(j['id'], 'Zusätzliche Kreatur-ID');
    final name = _string(j['name'], 'Zusätzliche Kreatur');
    final maxHp = _int(j['maxHitPoints'], 'Kreatur-Maximum', min: 1);
    final hp = _int(j['hitPoints'], 'Kreatur-TP', max: maxHp);
    final total = _nullableInt(
      j['initiativeTotal'],
      'Initiative der Kreatur',
      min: -30,
      max: 100,
    );
    final controller = j['initiativeController'] == null
        ? null
        : _string(j['initiativeController'], 'Initiativkontrolle');
    if ((total == null) != (controller == null) ||
        (controller != null && controller != 'gm' && controller != 'player')) {
      throw const FormatException(
        'Initiative und bestätigte Spieler-/SL-Kontrolle gehören zusammen.',
      );
    }
    if (id.isEmpty ||
        id.length > 128 ||
        name.trim().isEmpty ||
        name.length > 128) {
      throw const FormatException(
        'Zusätzliche Kreatur braucht eine eindeutige ID und einen Namen.',
      );
    }
    return TrackedAreaCreature(
      id: id,
      name: name,
      hitPoints: hp,
      maxHitPoints: maxHp,
      initiativeTotal: total,
      initiativeController: controller,
    );
  }
}

/// Separate, manually advanced initiative marker. This is NOT an automatic
/// actor scheduler: the legacy Encounter alone owns attack/action economy.
class ManualCombatTurnQueue {
  ManualCombatTurnQueue({
    required this.encounterId,
    required List<String> actorIds,
    required this.activeIndex,
    required this.round,
  }) : actorIds = List.unmodifiable(actorIds) {
    if (encounterId.isEmpty ||
        encounterId.length > 128 ||
        actorIds.length < 2 ||
        actorIds.length > 21 ||
        actorIds.any((id) => id.isEmpty || id.length > 128) ||
        actorIds.toSet().length != actorIds.length ||
        activeIndex < 0 ||
        activeIndex >= actorIds.length ||
        round < 1 ||
        round > 1000000) {
      throw const FormatException('Ungültige manuelle Kampf-Zugfolge.');
    }
  }

  final String encounterId;
  final List<String> actorIds;
  final int activeIndex, round;

  String get activeActorId => actorIds[activeIndex];

  ManualCombatTurnQueue copyWith({int? activeIndex, int? round}) =>
      ManualCombatTurnQueue(
        encounterId: encounterId,
        actorIds: actorIds,
        activeIndex: activeIndex ?? this.activeIndex,
        round: round ?? this.round,
      );

  Map<String, dynamic> toJson() => {
    'encounterId': encounterId,
    'actorIds': actorIds.toList(),
    'activeIndex': activeIndex,
    'round': round,
  };

  factory ManualCombatTurnQueue.fromJson(Map<String, dynamic> j) {
    final ids = _list(j['actorIds'], 'Zugfolge-Akteure')
        .map((value) => _string(value, 'Zugfolge-Akteur'))
        .toList();
    return ManualCombatTurnQueue(
      encounterId: _string(j['encounterId'], 'Zugfolge-Kampf'),
      actorIds: ids,
      activeIndex: _int(j['activeIndex'], 'Aktive Zugfolge-Position'),
      round: _int(j['round'], 'Zugfolge-Runde', min: 1),
    );
  }
}

class Campaign {
  Campaign({
    required this.id,
    required this.name,
    required this.world,
    required this.sessionId,
    required this.hero,
    required this.scene,
    List<NarrativeMessage> messages = const [],
    Map<String, String> facts = const {},
    List<Quest> quests = const [],
    List<SessionRecap> sessionRecaps = const [],
    List<StoryThread> storyThreads = const [],
    Map<String, String> storyBible = const {},
    List<NpcRelationshipNote> npcRelationshipNotes = const [],
    List<WorldNpc> npcs = const [],
    List<Place> places = const [],
    List<GameEvent> events = const [],
    List<TrackedAreaCreature> trackedAreaCreatures = const [],
    this.manualTurnQueue,
    this.pendingRoll,
    this.pendingDeathSave,
    this.pendingEnemyShieldHit,
    this.encounter,
    this.adventureOffer,
    this.revision = 0,
  }) : messages = List.unmodifiable(messages),
       facts = Map.unmodifiable(facts),
       quests = List.unmodifiable(quests),
       sessionRecaps = List.unmodifiable(sessionRecaps),
       storyThreads = List.unmodifiable(storyThreads),
       storyBible = Map.unmodifiable(storyBible),
       npcRelationshipNotes = List.unmodifiable(npcRelationshipNotes),
       npcs = List.unmodifiable(npcs),
       places = List.unmodifiable(places),
       events = List.unmodifiable(events),
       trackedAreaCreatures = List.unmodifiable(trackedAreaCreatures);
  final String id, name, world, sessionId, scene;
  final HeroCharacter hero;
  final List<NarrativeMessage> messages;
  final Map<String, String> facts;
  final List<Quest> quests;
  final List<SessionRecap> sessionRecaps;
  final List<StoryThread> storyThreads;
  final Map<String, String> storyBible;
  final List<NpcRelationshipNote> npcRelationshipNotes;
  final List<WorldNpc> npcs;
  final List<Place> places;
  final List<GameEvent> events;

  /// HP-only additional creatures, persistent even if the main fight ends.
  final List<TrackedAreaCreature> trackedAreaCreatures;
  /// Optional advisory turn cursor; never authorizes real combat actions.
  final ManualCombatTurnQueue? manualTurnQueue;
  final PendingRoll? pendingRoll;
  final PendingDeathSave? pendingDeathSave;
  final PendingEnemyShieldHit? pendingEnemyShieldHit;
  final Encounter? encounter;
  final AdventureOffer? adventureOffer;
  final int revision;
  Campaign copyWith({
    String? name,
    String? scene,
    HeroCharacter? hero,
    List<NarrativeMessage>? messages,
    Map<String, String>? facts,
    List<Quest>? quests,
    List<SessionRecap>? sessionRecaps,
    List<StoryThread>? storyThreads,
    Map<String, String>? storyBible,
    List<NpcRelationshipNote>? npcRelationshipNotes,
    List<WorldNpc>? npcs,
    List<Place>? places,
    List<GameEvent>? events,
    List<TrackedAreaCreature>? trackedAreaCreatures,
    Object? manualTurnQueue = _unchanged,
    Object? pendingRoll = _unchanged,
    Object? pendingDeathSave = _unchanged,
    Object? pendingEnemyShieldHit = _unchanged,
    Object? encounter = _unchanged,
    Object? adventureOffer = _unchanged,
    int? revision,
  }) => Campaign(
    id: id,
    name: name ?? this.name,
    world: world,
    sessionId: sessionId,
    hero: hero ?? this.hero,
    scene: scene ?? this.scene,
    messages: messages ?? this.messages,
    facts: facts ?? this.facts,
    quests: quests ?? this.quests,
    sessionRecaps: sessionRecaps ?? this.sessionRecaps,
    storyThreads: storyThreads ?? this.storyThreads,
    storyBible: storyBible ?? this.storyBible,
    npcRelationshipNotes: npcRelationshipNotes ?? this.npcRelationshipNotes,
    npcs: npcs ?? this.npcs,
    places: places ?? this.places,
    events: events ?? this.events,
    trackedAreaCreatures: trackedAreaCreatures ?? this.trackedAreaCreatures,
    manualTurnQueue: identical(manualTurnQueue, _unchanged)
        ? this.manualTurnQueue
        : manualTurnQueue as ManualCombatTurnQueue?,
    pendingRoll: identical(pendingRoll, _unchanged)
        ? this.pendingRoll
        : pendingRoll as PendingRoll?,
    pendingDeathSave: identical(pendingDeathSave, _unchanged)
        ? this.pendingDeathSave
        : pendingDeathSave as PendingDeathSave?,
    pendingEnemyShieldHit: identical(pendingEnemyShieldHit, _unchanged)
        ? this.pendingEnemyShieldHit
        : pendingEnemyShieldHit as PendingEnemyShieldHit?,
    encounter: identical(encounter, _unchanged)
        ? this.encounter
        : encounter as Encounter?,
    adventureOffer: identical(adventureOffer, _unchanged)
        ? this.adventureOffer
        : adventureOffer as AdventureOffer?,
    revision: revision ?? this.revision,
  );
  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'id': id,
    'name': name,
    'world': world,
    'sessionId': sessionId,
    'hero': hero.toJson(),
    'scene': scene,
    'messages': messages.map((e) => e.toJson()).toList(),
    'facts': facts,
    'quests': quests.map((e) => e.toJson()).toList(),
    'sessionRecaps': sessionRecaps.map((e) => e.toJson()).toList(),
    'storyThreads': storyThreads.map((e) => e.toJson()).toList(),
    'storyBible': storyBible,
    'npcRelationshipNotes': npcRelationshipNotes
        .map((e) => e.toJson())
        .toList(),
    'npcs': npcs.map((e) => e.toJson()).toList(),
    'places': places.map((e) => e.toJson()).toList(),
    'events': events.map((e) => e.toJson()).toList(),
    if (trackedAreaCreatures.isNotEmpty)
      'trackedAreaCreatures': trackedAreaCreatures
          .map((e) => e.toJson())
          .toList(),
    if (manualTurnQueue != null) 'manualTurnQueue': manualTurnQueue!.toJson(),
    'pendingRoll': pendingRoll?.toJson(),
    if (pendingDeathSave != null)
      'pendingDeathSave': pendingDeathSave!.toJson(),
    if (pendingEnemyShieldHit != null)
      'pendingEnemyShieldHit': pendingEnemyShieldHit!.toJson(),
    'encounter': encounter?.toJson(),
    'adventureOffer': adventureOffer?.toJson(),
    'revision': revision,
  };
  factory Campaign.fromJson(Map<String, dynamic> j) {
    _version(j);
    final id = _string(j['id'], 'Kampagnen-ID');
    final session = _string(j['sessionId'], 'Sitzungs-ID');
    final events = _list(
      j['events'],
      'Ereignisse',
    ).map((e) => GameEvent.fromJson(_map(e, 'Ereignis'))).toList();
    if (events.any((e) => e.campaignId != id) ||
        events.map((e) => e.id).toSet().length != events.length) {
      throw const FormatException('Ungültiges Ereignisprotokoll.');
    }
    final facts = _map(j['facts'], 'Erinnerungen');
    final hero = HeroCharacter.fromJson(_map(j['hero'], 'Charakter'));
    final pending = j['pendingRoll'] == null
        ? null
        : PendingRoll.fromJson(_map(j['pendingRoll'], 'Probe'));
    final deathChoice = j['pendingDeathSave'] == null
        ? null
        : PendingDeathSave.fromJson(
            _map(j['pendingDeathSave'], 'Todesrettungsentscheidung'),
          );
    final encounter = j['encounter'] == null
        ? null
        : Encounter.fromJson(_map(j['encounter'], 'Kampf'));
    final trackedAreaCreatures = _list(
      j['trackedAreaCreatures'],
      'Zusätzliche Kreaturen',
    ).map((e) => TrackedAreaCreature.fromJson(_map(e, 'Kreatur'))).toList();
    if (trackedAreaCreatures.length > 19 ||
        trackedAreaCreatures.map((e) => e.id).toSet().length !=
            trackedAreaCreatures.length ||
        trackedAreaCreatures.any(
          (e) => e.id == hero.id || (encounter != null && e.id == encounter.id),
        )) {
      throw const FormatException(
        'Ungültige Anzahl oder doppelte IDs zusätzlicher Kreaturen.',
      );
    }
    final manualQueue = j['manualTurnQueue'] == null
        ? null
        : ManualCombatTurnQueue.fromJson(
            _map(j['manualTurnQueue'], 'Manuelle Zugfolge'),
          );
    if (manualQueue != null &&
        (encounter == null ||
            encounter.isFinished ||
            manualQueue.encounterId != encounter.id ||
            !manualQueue.actorIds.contains(hero.id) ||
            !manualQueue.actorIds.contains(encounter.id) ||
            manualQueue.actorIds.any(
              (id) => id != hero.id &&
                  id != encounter.id &&
                  !trackedAreaCreatures.any((creature) => creature.id == id),
            ))) {
      throw const FormatException(
        'Manuelle Zugfolge gehört nicht zum aktuellen Kampf.',
      );
    }
    final pendingEnemyShieldHit = j['pendingEnemyShieldHit'] == null
        ? null
        : PendingEnemyShieldHit.fromJson(
            _map(j['pendingEnemyShieldHit'], 'Offene Schildreaktion'),
          );
    if (pendingEnemyShieldHit != null &&
        (encounter == null ||
            encounter.isFinished ||
            encounter.id != pendingEnemyShieldHit.encounterId ||
            encounter.activeParticipant != 'enemy' ||
            pending != null ||
            deathChoice != null ||
            hero.isDead ||
            hero.hitPoints == null ||
            hero.hitPoints! <= 0 ||
            hero.armorClass == null ||
            (pendingEnemyShieldHit.natural != 20 &&
                pendingEnemyShieldHit.total <
                    CoverRules.armorClass(
                      hero.armorClass!,
                      encounter.heroCover,
                    )))) {
      throw const FormatException('Ungültiger offener Gegnerangriff.');
    }
    final adventureOffer = j['adventureOffer'] == null
        ? null
        : AdventureOffer.fromJson(
            _map(j['adventureOffer'], 'Begegnungsvorschlag'),
          );
    // Existing 0.3.5 saves omit these optional collections; no migration.
    final recaps = _list(
      j['sessionRecaps'],
      'Sitzungsrückblicke',
    ).map((e) => SessionRecap.fromJson(_map(e, 'Sitzungsrückblick'))).toList();
    final threads = _list(
      j['storyThreads'],
      'Handlungsstränge',
    ).map((e) => StoryThread.fromJson(_map(e, 'Handlungsstrang'))).toList();
    final rawBible = j['storyBible'] == null
        ? <String, dynamic>{}
        : _map(j['storyBible'], 'KI-Geschichtenbuch');
    if (rawBible.length > 12 ||
        rawBible.keys.any((key) => key.length > 60) ||
        rawBible.values.any(
          (value) => value is! String || value.length > 1500,
        )) {
      throw const FormatException('Ungültiges KI-Geschichtenbuch.');
    }
    final relationshipNotes = _list(
      j['npcRelationshipNotes'],
      'NPC-Notizen',
    ).map((e) => NpcRelationshipNote.fromJson(_map(e, 'NPC-Notiz'))).toList();
    final npcs = _list(
      j['npcs'],
      'NPCs',
    ).map((e) => WorldNpc.fromJson(_map(e, 'NPC'))).toList();
    if (recaps.length > 60 ||
        threads.length > 100 ||
        relationshipNotes.length > 300 ||
        recaps.map((e) => e.id).toSet().length != recaps.length ||
        threads.map((e) => e.id).toSet().length != threads.length ||
        relationshipNotes.map((e) => e.id).toSet().length !=
            relationshipNotes.length ||
        relationshipNotes.any((e) => !npcs.any((npc) => npc.id == e.npcId))) {
      throw const FormatException('Ungültiges Kampagnengedächtnis.');
    }
    if (deathChoice != null) {
      if (pending != null ||
          !hero.isComplete ||
          (encounter != null &&
              !encounter.isFinished &&
              (encounter.activeParticipant != 'hero' ||
                  encounter.deathSaveResolvedThisTurn))) {
        throw const FormatException(
          'Ungültige offene Todesrettungsentscheidung.',
        );
      }
      try {
        final original = DeathSavingThrowRules.resolve(
          hero: hero,
          natural: deathChoice.originalNatural,
        );
        if (deathChoice.modifier != original.roll.modifier ||
            original.passed ||
            !SavingThrowRerollFeature.values.any(
              (f) => DeathSavingThrowRules.canReroll(original, f),
            )) {
          throw const FormatException(
            'Vorläufiger Todesrettungswurf passt nicht zum Charakter.',
          );
        }
      } on StateError {
        throw const FormatException('Unzulässige Todesrettungsentscheidung.');
      }
    }
    if (pending != null) {
      if (!hero.isComplete) {
        throw const FormatException(
          'Eine offene Probe benötigt bestätigte Charakterwerte.',
        );
      }
      final prof = 2 + (hero.level - 1) ~/ 4;
      int modifier(String key) => ((hero.abilities[key]! - 10) / 2).floor();
      int skillBonus(String skill) {
        final proficient = hero.skills.contains(skill);
        return proficient
            ? prof
            : SkillCheckPassives.jackOfAllTrades(
                bardClassLevel: ClassResourceRules.level(hero, 'Barde'),
                proficiencyBonus: prof,
                usesSkill: true,
                proficient: false,
              );
      }

      // A saved request must match the same confirmed Exhaustion penalty that
      // the shared character rules applied when creating it. Legacy death-save
      // requests use modifier0; version1 includes the authoritative bonus.
      // The final death result always recomputes it from the confirmed hero.
      final exhaustion = ExhaustionRules.d20Modifier(hero);
      final expected = switch (pending.type) {
        'offhandAttack' => () {
          final candidates = hero.inventory.where(
            (item) => item.id == pending.weaponId && item.quantity > 0,
          );
          if (candidates.length != 1) {
            throw const FormatException('Nebenhandwaffe nicht eindeutig.');
          }
          final weapon = SrdEquipmentCatalog.byId(candidates.single.catalogId);
          if (weapon == null ||
              !weapon.hasProperty('light') ||
              (weapon.category != EquipmentCategory.simpleMelee &&
                  weapon.category != EquipmentCategory.martialMelee)) {
            throw const FormatException(
              'Keine bestätigte leichte Nebenhandwaffe.',
            );
          }
          final ability =
              weapon.hasProperty('finesse') && hero.weaponAbility == 'dexterity'
              ? 'dexterity'
              : 'strength';
          return modifier(ability) + prof + exhaustion;
        }(),
        'attack' =>
          modifier(hero.weaponAbility) +
              (hero.weaponProficient ? prof : 0) +
              exhaustion,
        'perception' =>
          modifier('wisdom') + skillBonus('Wahrnehmung') + exhaustion,
        'preparedCheck' => () {
          const skills = <String, String>{
            'Wahrnehmung': 'wisdom',
            'Nachforschungen': 'intelligence',
            'Arkane Kunde': 'intelligence',
            'Athletik': 'strength',
            'Heimlichkeit': 'dexterity',
            'Überreden': 'charisma',
          };
          final values = pending.targetName.split('|');
          const difficultyByStage = <String, int>{
            'road': 12,
            'well': 12,
            'mill': 13,
            'archive': 12,
            'forest': 12,
            'ruins': 13,
            'stairs': 12,
            'bonehall': 13,
            'door13': 14,
            'chamber': 14,
          };
          final stage = pending.targetId.replaceFirst('rabenwacht:', '');
          if (rawBible['mode'] != 'rabenwacht-v1' ||
              !pending.targetId.startsWith('rabenwacht:') ||
              rawBible['stage'] != stage ||
              pending.difficulty != difficultyByStage[stage] ||
              values.length != 2 ||
              skills[values[1]] != values[0]) {
            throw const FormatException('Ungültige Kampagnenprobe.');
          }
          return modifier(values[0]) + skillBonus(values[1]) + exhaustion;
        }(),
        'escape' => modifier('dexterity') + exhaustion,
        'death' when pending.deathSaveRulesVersion == 1 =>
          DeathSavingThrowRules.modifier(hero),
        _ => 0,
      };
      if (pending.minimumNatural > 0) {
        final skill = pending.type == 'perception'
            ? 'Wahrnehmung'
            : pending.type == 'preparedCheck'
            ? pending.targetName.split('|').last
            : '';
        final expectedMinimum = SkillCheckPassives.minimumNatural(
          rogueClassLevel: ClassResourceRules.level(hero, 'Schurke'),
          usesSkill: skill.isNotEmpty,
          proficient: hero.skills.contains(skill),
        );
        if (pending.minimumNatural != expectedMinimum) {
          throw const FormatException(
            'Dieser Charakter besitzt keinen gültigen Fertigkeits-Mindestwurf.',
          );
        }
      }
      if (pending.modifier != expected) {
        throw const FormatException(
          'Die gespeicherte Probe enthält einen falschen Bonus.',
        );
      }
      if (pending.type == 'offhandAttack') {
        final primary = hero.inventory.where(
          (item) => item.id == hero.equippedWeaponId && item.quantity > 0,
        );
        final mainWeapon = primary.length == 1
            ? SrdEquipmentCatalog.byId(primary.single.catalogId)
            : null;
        if (!hero.features.contains('Kampfstil: Kampf mit zwei Waffen') ||
            ClassResourceRules.level(hero, 'Kämpfer') < 1 ||
            hero.equippedShieldId.isNotEmpty ||
            pending.weaponId == hero.equippedWeaponId ||
            (mainWeapon == null ||
                !mainWeapon.hasProperty('light') ||
                (mainWeapon.category != EquipmentCategory.simpleMelee &&
                    mainWeapon.category != EquipmentCategory.martialMelee)) ||
            encounter == null ||
            encounter.isFinished ||
            encounter.activeParticipant != 'hero' ||
            !encounter.actionUsed ||
            encounter.attacksRemaining != 0 ||
            !encounter.bonusActionUsed ||
            !encounter.lightAttackAvailable) {
          throw const FormatException('Unzulässiger offener Nebenhandangriff.');
        }
      }
      if ((pending.type == 'attack' || pending.type == 'offhandAttack') &&
          (encounter == null ||
              encounter.isFinished ||
              encounter.id != pending.targetId ||
              encounter.enemyCover == CoverLevel.total ||
              CoverRules.armorClass(
                    encounter.effectiveEnemyArmorClass,
                    encounter.enemyCover,
                  ) !=
                  pending.difficulty)) {
        throw const FormatException(
          'Das Angriffsziel stimmt nicht mit der Probe überein.',
        );
      }
      if (pending.type == 'escape' && encounter == null) {
        throw const FormatException('Fluchtprobe ohne Kampf.');
      }
      if (pending.type == 'death' &&
          (hero.hitPoints != 0 ||
              hero.isDead ||
              hero.conditions.contains('stabil') ||
              (encounter != null &&
                  !encounter.isFinished &&
                  (encounter.activeParticipant != 'hero' ||
                      encounter.deathSaveResolvedThisTurn)))) {
        throw const FormatException('Ungültiger Todesrettungswurf.');
      }
      if (pending.type != 'attack' &&
          pending.type != 'offhandAttack' &&
          pending.type != 'preparedCheck' &&
          pending.difficulty != 10) {
        throw const FormatException('Ungültige Schwierigkeit.');
      }
    }
    return Campaign(
      id: id,
      name: _string(j['name'], 'Kampagnenname'),
      world: _string(j['world'], 'Welt'),
      sessionId: session,
      hero: hero,
      scene: _string(j['scene'], 'Szene'),
      messages: _list(
        j['messages'],
        'Nachrichten',
      ).map((e) => NarrativeMessage.fromJson(_map(e, 'Nachricht'))).toList(),
      facts: {
        for (final e in facts.entries) e.key: _string(e.value, 'Erinnerung'),
      },
      quests: _list(
        j['quests'],
        'Quests',
      ).map((e) => Quest.fromJson(_map(e, 'Quest'))).toList(),
      sessionRecaps: recaps,
      storyThreads: threads,
      storyBible: {
        for (final entry in rawBible.entries) entry.key: entry.value as String,
      },
      npcRelationshipNotes: relationshipNotes,
      npcs: npcs,
      places: _list(
        j['places'],
        'Orte',
      ).map((e) => Place.fromJson(_map(e, 'Ort'))).toList(),
      events: events,
      trackedAreaCreatures: trackedAreaCreatures,
      manualTurnQueue: manualQueue,
      pendingRoll: pending,
      pendingDeathSave: deathChoice,
      pendingEnemyShieldHit: pendingEnemyShieldHit,
      encounter: encounter,
      adventureOffer: adventureOffer,
      revision: _int(j['revision'], 'Revision', fallback: 0),
    );
  }
}

class GameUpdate {
  GameUpdate({required this.campaign, required List<GameEvent> events})
    : events = List.unmodifiable(events);
  final Campaign campaign;
  final List<GameEvent> events;
  String get narration =>
      campaign.messages.isEmpty ? '' : campaign.messages.last.text;
}
