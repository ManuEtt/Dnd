import 'srd_equipment_catalog.dart';
import 'spellcasting_rules.dart';

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
  });
  /// Optional catalog reference; legacy and user-defined items leave it empty.
  final String catalogId;
  final String id, name, description;
  final int quantity;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'quantity': quantity,
    'description': description,
    if (catalogId.isNotEmpty) 'catalogId': catalogId,
  };
  factory InventoryItem.fromJson(Map<String, dynamic> j) => InventoryItem(
    id: _string(j['id'], 'Gegenstand-ID'),
    name: _string(j['name'], 'Gegenstand'),
    quantity: _int(j['quantity'], 'Anzahl', fallback: 1, min: 1),
    description: _string(j['description'], 'Beschreibung', fallback: ''),
    catalogId: _string(j['catalogId'], 'Katalog-ID', fallback: ''),
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
    this.level = 1,
    this.subclass = '',
    this.background = '',
    this.backstory = '',
    Map<String, int?>? abilities,
    this.hitPoints,
    this.maxHitPoints,
    this.armorClass,
    this.speed,
    List<String> skills = const [],
    List<String> savingThrowProficiencies = const [],
    List<String> features = const [],
    List<String> spells = const [],
    List<InventoryItem> inventory = const [],
    this.gold,
    this.experience,
    List<String> conditions = const [],
    this.exhaustionLevel = 0,
    Map<String, int> spentHitDice = const {},
    Map<String, int> spentSpellSlots = const {},
    this.spentPactSlots = 0,
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
       conditions = List.unmodifiable(conditions),
       spentHitDice = Map.unmodifiable(spentHitDice),
       spentSpellSlots = Map.unmodifiable(spentSpellSlots),
       unverifiedNotes = List.unmodifiable(unverifiedNotes);
  final String id, name, species, className, secondaryClassName, subclass, background, backstory;
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
  final List<String> skills,
      savingThrowProficiencies,
      features,
      spells,
      conditions,
      unverifiedNotes;
  final List<InventoryItem> inventory;
  /// Already spent class Hit Dice, keyed by die type (d6/d8/d10/d12).
  /// Optional in schemaVersion 1 for backwards-compatible older saves.
  final Map<String, int> spentHitDice;
  /// Spent Spellcasting slots per spell level; Pact Magic is separate.
  final Map<String, int> spentSpellSlots;
  final int spentPactSlots;
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
    int? level,
    String? subclass,
    String? background,
    String? backstory,
    Map<String, int?>? abilities,
    Object? hitPoints = _unchanged,
    Object? maxHitPoints = _unchanged,
    Object? armorClass = _unchanged,
    Object? speed = _unchanged,
    List<String>? skills,
    List<String>? savingThrowProficiencies,
    List<String>? features,
    List<String>? spells,
    List<InventoryItem>? inventory,
    Object? gold = _unchanged,
    Object? experience = _unchanged,
    List<String>? conditions,
    int? exhaustionLevel,
    Map<String, int>? spentHitDice,
    Map<String, int>? spentSpellSlots,
    int? spentPactSlots,
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
    level: level ?? this.level,
    subclass: subclass ?? this.subclass,
    background: background ?? this.background,
    backstory: backstory ?? this.backstory,
    abilities: abilities ?? this.abilities,
    hitPoints: identical(hitPoints, _unchanged)
        ? this.hitPoints
        : hitPoints as int?,
    maxHitPoints: identical(maxHitPoints, _unchanged)
        ? this.maxHitPoints
        : maxHitPoints as int?,
    armorClass: identical(armorClass, _unchanged)
        ? this.armorClass
        : armorClass as int?,
    speed: identical(speed, _unchanged) ? this.speed : speed as int?,
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
    conditions: conditions ?? this.conditions,
    exhaustionLevel: exhaustionLevel ?? this.exhaustionLevel,
    spentHitDice: spentHitDice ?? this.spentHitDice,
    spentSpellSlots: spentSpellSlots ?? this.spentSpellSlots,
    spentPactSlots: spentPactSlots ?? this.spentPactSlots,
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
    'level': level,
    'subclass': subclass,
    'background': background,
    'backstory': backstory,
    'abilities': abilities,
    'hitPoints': hitPoints,
    'maxHitPoints': maxHitPoints,
    'armorClass': armorClass,
    'speed': speed,
    'skills': skills,
    'savingThrowProficiencies': savingThrowProficiencies,
    'features': features,
    'spells': spells,
    'inventory': inventory.map((e) => e.toJson()).toList(),
    'gold': gold,
    'experience': experience,
    'conditions': conditions,
    if (exhaustionLevel > 0) 'exhaustionLevel': exhaustionLevel,
    if (spentHitDice.isNotEmpty) 'spentHitDice': spentHitDice,
    if (spentSpellSlots.isNotEmpty) 'spentSpellSlots': spentSpellSlots,
    if (spentPactSlots > 0) 'spentPactSlots': spentPactSlots,
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
    final secondary = _string(j['secondaryClassName'], 'Zweitklasse', fallback: '');
    final secondaryLevel = _int(j['secondaryClassLevel'], 'Zweitklassenstufe',
        fallback: 0, min: 0, max: 19);
    final totalLevel = _int(j['level'], 'Stufe', min: 1, max: 20);
    final diceRecord = j['spentHitDice'];
    if (diceRecord != null && diceRecord is! Map<String, dynamic>) {
      throw const FormatException('Verbrauchte Trefferwürfel sind ungültig.');
    }
    final spent = <String, int>{};
    if (diceRecord != null) {
      for (final entry in diceRecord.entries) {
        if (!const ['d6', 'd8', 'd10', 'd12'].contains(entry.key) ||
            entry.value is! int || entry.value < 0 || entry.value > totalLevel) {
          throw const FormatException('Ungültiger Trefferwürfelbestand.');
        }
        if (entry.value > 0) spent[entry.key] = entry.value as int;
      }
      if (spent.values.fold<int>(0, (sum, count) => sum + count) > totalLevel) {
        throw const FormatException('Mehr Trefferwürfel verbraucht als Stufen vorhanden.');
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
        if (slot == null || slot < 1 || slot > 9 ||
            entry.key != '$slot' || entry.value is! int ||
            entry.value < 0 || entry.value > maxima[slot - 1]) {
          throw const FormatException('Ungültiger verbrauchter Zauberplatz.');
        }
        if (entry.value > 0) spentSlots[entry.key] = entry.value as int;
      }
    }
    final spentPact = _int(j['spentPactSlots'], 'Verbrauchte Paktplätze',
        fallback: 0, min: 0, max: 4);
    final concentration = _string(j['concentratingOn'], 'Konzentrationszauber',
        fallback: '');
    if (concentration.length > 200 || concentration != concentration.trim()) {
      throw const FormatException('Ungültiger Konzentrationszauber.');
    }

    if ((secondary.isEmpty && secondaryLevel != 0) ||
        (secondary.isNotEmpty && (secondaryLevel < 1 || secondaryLevel >= totalLevel)) ||
        (secondary.isNotEmpty && secondary.toLowerCase() ==
            _string(j['className'], 'Klasse').toLowerCase())) {
      throw const FormatException('Ungültige Zweitklassenstufe oder Klassenkombination.');
    }
    final items = _list(j['inventory'], 'Inventar')
        .map((item) => InventoryItem.fromJson(_map(item, 'Gegenstand')))
        .toList();
    final armorId = _string(j['equippedArmorId'], 'Rüstungs-Referenz', fallback: '');
    final shieldId = _string(j['equippedShieldId'], 'Schild-Referenz', fallback: '');
    final weaponId = _string(j['equippedWeaponId'], 'Waffen-Referenz', fallback: '');
    final equipped = [armorId, shieldId, weaponId].where((id) => id.isNotEmpty);
    if (equipped.length != equipped.toSet().length ||
        equipped.any((id) => items.where((item) => item.id == id &&
            item.catalogId.isNotEmpty).length != 1)) {
      throw const FormatException('Ausrüstung verweist auf fehlende oder doppelte Inventareinträge.');
    }
    for (final (id, type) in [(armorId, 'armor'),
      (shieldId, 'shield'), (weaponId, 'weapon')]) {
      if (id.isEmpty) continue;
      final match = items.singleWhere((item) => item.id == id);
      final entry = SrdEquipmentCatalog.byId(match.catalogId);
      if (entry == null ||
          (type == 'armor' && !entry.isArmor) ||
          (type == 'shield' && !entry.isShield) ||
          (type == 'weapon' && !entry.isWeapon)) {
        throw const FormatException('Nicht unterstützter ausgerüsteter Gegenstand.');
      }
    }
    if (shieldId.isNotEmpty && weaponId.isNotEmpty) {
      final weapon = SrdEquipmentCatalog.byId(
        items.singleWhere((item) => item.id == weaponId).catalogId);
      if (weapon!.hasProperty('two-handed')) {
        throw const FormatException('Schild und Zweihandwaffe dürfen nicht gleichzeitig ausgerüstet sein.');
      }
    }
    if ((armorId.isEmpty && _bool(j['equippedArmorTrained'], 'Rüstungsübung')) ||
        (shieldId.isEmpty && _bool(j['equippedShieldTrained'], 'Schildübung'))) {
      throw const FormatException('Ausrüstungsübung ohne angelegten Gegenstand.');
    }
    final parsed = HeroCharacter(
      id: _string(j['id'], 'Charakter-ID'),
      name: _string(j['name'], 'Name'),
      species: _string(j['species'], 'Spezies'),
      className: _string(j['className'], 'Klasse'),
      secondaryClassName: secondary,
      secondaryClassLevel: secondaryLevel,
      level: totalLevel,
      subclass: _string(j['subclass'], 'Unterklasse', fallback: ''),
      background: _string(j['background'], 'Hintergrund', fallback: ''),
      backstory: _string(j['backstory'], 'Geschichte', fallback: ''),
      abilities: {
        for (final key in abilityNames)
          key: _nullableInt(a[key], key, min: 1, max: 30),
      },
      hitPoints: hp,
      maxHitPoints: maxHp,
      armorClass: _nullableInt(
        j['armorClass'],
        'Rüstungsklasse',
        min: 1,
        max: 100,
      ),
      speed: _nullableInt(j['speed'], 'Bewegung', max: 1000),
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
      exhaustionLevel: _int(j['exhaustionLevel'], 'Erschöpfung',
          fallback: 0, min: 0, max: 6),
      spentHitDice: spent,
      spentSpellSlots: spentSlots,
      spentPactSlots: spentPact,
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
    if (parsed.concentratingOn.isNotEmpty &&
        (parsed.isDead || parsed.hitPoints == 0)) {
      throw const FormatException('Bewusstlose oder tote Helden können nicht konzentrieren.');
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
  const AdventureOffer({required this.id, required this.title,
    required this.description, required this.archetype,
    required this.questTitle, required this.questDescription});
  final String id, title, description, archetype, questTitle, questDescription;
  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'description': description,
    'archetype': archetype, 'questTitle': questTitle,
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
    if (!const ['bandit', 'wolf', 'skeleton', 'goblin', 'orc', 'investigation']
        .contains(archetype)) {
      throw const FormatException('Unbekanntes Gegnerprofil.');
    }
    return AdventureOffer(id: id, title: bounded('title', 120),
      description: bounded('description', 500), archetype: archetype,
      questTitle: bounded('questTitle', 120),
      questDescription: bounded('questDescription', 500));
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
    if (title.trim().isEmpty || title.length > 100 ||
        summary.trim().isEmpty || summary.length > 2400) {
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
      j['description'], 'Handlungsnotiz', fallback: '',
    );
    final status = _string(j['status'], 'Handlungsstatus', fallback: 'open');
    if (title.trim().isEmpty || title.length > 120 ||
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
    if (relationship.trim().isEmpty || relationship.length > 80 ||
        note.trim().isEmpty || note.length > 500) {
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
    this.expression = '1d20',
    this.advantage = false,
    this.disadvantage = false,
  });
  final String id, type, targetId, targetName, expression;
  final int modifier, difficulty;
  final bool advantage, disadvantage;
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'modifier': modifier,
    'difficulty': difficulty,
    'targetId': targetId,
    'targetName': targetName,
    'expression': expression,
    if (advantage) 'advantage': true,
    if (disadvantage) 'disadvantage': true,
  };
  factory PendingRoll.fromJson(Map<String, dynamic> j) {
    final type = _string(j['type'], 'Probeart');
    final expression = _string(j['expression'], 'Würfel', fallback: '1d20');
    if (!['attack', 'death', 'escape', 'perception'].contains(type) ||
        expression != '1d20') {
      throw const FormatException('Unbekannte Probe oder Würfelanweisung.');
    }
    return PendingRoll(
      id: _string(j['id'], 'Probe-ID'),
      type: type,
      modifier: _int(j['modifier'], 'Modifikator', min: -20, max: 30),
      difficulty: _int(j['difficulty'], 'Schwierigkeit', min: 1, max: 100),
      targetId: _string(j['targetId'], 'Ziel-ID', fallback: ''),
      targetName: _string(j['targetName'], 'Ziel', fallback: ''),
      expression: expression,
      advantage: _bool(j['advantage'], 'Vorteil'),
      disadvantage: _bool(j['disadvantage'], 'Nachteil'),
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
    this.enemyAttackBonus = 2,
    this.enemyDamage = '1d4',
    this.round = 1,
    this.activeParticipant = 'hero',
    this.heroInitiative = 0,
    this.enemyInitiative = 0,
    this.movementRemaining = 9,
    this.actionUsed = false,
    this.attacksRemaining = 0,
    this.bonusActionUsed = false,
    this.reactionUsed = false,
  });
  final String id, enemyName, enemyDamage, activeParticipant;
  final int enemyHitPoints,
      enemyMaxHitPoints,
      enemyArmorClass,
      enemyAttackBonus,
      round,
      heroInitiative,
      enemyInitiative,
      movementRemaining;
  final bool actionUsed, bonusActionUsed, reactionUsed;
  /// Remaining attacks after the first attack of a single Attack action.
  /// Old campaign saves omit the field and resume with zero.
  final int attacksRemaining;
  bool get isFinished => enemyHitPoints == 0;
  Encounter copyWith({
    int? enemyHitPoints,
    int? round,
    String? activeParticipant,
    int? heroInitiative,
    int? enemyInitiative,
    int? movementRemaining,
    bool? actionUsed,
    int? attacksRemaining,
    bool? bonusActionUsed,
    bool? reactionUsed,
  }) => Encounter(
    id: id,
    enemyName: enemyName,
    enemyHitPoints: enemyHitPoints ?? this.enemyHitPoints,
    enemyMaxHitPoints: enemyMaxHitPoints,
    enemyArmorClass: enemyArmorClass,
    enemyAttackBonus: enemyAttackBonus,
    enemyDamage: enemyDamage,
    round: round ?? this.round,
    activeParticipant: activeParticipant ?? this.activeParticipant,
    heroInitiative: heroInitiative ?? this.heroInitiative,
    enemyInitiative: enemyInitiative ?? this.enemyInitiative,
    movementRemaining: movementRemaining ?? this.movementRemaining,
    actionUsed: actionUsed ?? this.actionUsed,
    attacksRemaining: attacksRemaining ?? this.attacksRemaining,
    bonusActionUsed: bonusActionUsed ?? this.bonusActionUsed,
    reactionUsed: reactionUsed ?? this.reactionUsed,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'enemyName': enemyName,
    'enemyHitPoints': enemyHitPoints,
    'enemyMaxHitPoints': enemyMaxHitPoints,
    'enemyArmorClass': enemyArmorClass,
    'enemyAttackBonus': enemyAttackBonus,
    'enemyDamage': enemyDamage,
    'round': round,
    'activeParticipant': activeParticipant,
    'heroInitiative': heroInitiative,
    'enemyInitiative': enemyInitiative,
    'movementRemaining': movementRemaining,
    'actionUsed': actionUsed,
    if (attacksRemaining > 0) 'attacksRemaining': attacksRemaining,
    'bonusActionUsed': bonusActionUsed,
    'reactionUsed': reactionUsed,
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
    final active = _string(
      j['activeParticipant'],
      'Aktiver Teilnehmer',
      fallback: 'hero',
    );
    if (!['hero', 'enemy'].contains(active)) {
      throw const FormatException('Unbekannter aktiver Teilnehmer.');
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
      enemyAttackBonus: _int(
        j['enemyAttackBonus'],
        'Gegnerbonus',
        fallback: 2,
        min: -20,
        max: 30,
      ),
      enemyDamage: damage,
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
      actionUsed: _bool(j['actionUsed'], 'Aktion'),
      attacksRemaining: _int(j['attacksRemaining'],
          'Verbleibende Angriffe', fallback: 0, min: 0, max: 3),
      bonusActionUsed: _bool(j['bonusActionUsed'], 'Bonusaktion'),
      reactionUsed: _bool(j['reactionUsed'], 'Reaktion'),
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
    this.pendingRoll,
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
       events = List.unmodifiable(events);
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
  final PendingRoll? pendingRoll;
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
    Object? pendingRoll = _unchanged,
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
    pendingRoll: identical(pendingRoll, _unchanged)
        ? this.pendingRoll
        : pendingRoll as PendingRoll?,
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
    'npcRelationshipNotes':
        npcRelationshipNotes.map((e) => e.toJson()).toList(),
    'npcs': npcs.map((e) => e.toJson()).toList(),
    'places': places.map((e) => e.toJson()).toList(),
    'events': events.map((e) => e.toJson()).toList(),
    'pendingRoll': pendingRoll?.toJson(),
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
    final encounter = j['encounter'] == null
        ? null
        : Encounter.fromJson(_map(j['encounter'], 'Kampf'));
    final adventureOffer = j['adventureOffer'] == null
        ? null
        : AdventureOffer.fromJson(_map(j['adventureOffer'], 'Begegnungsvorschlag'));
    // Existing 0.3.5 saves omit these optional collections; no migration.
    final recaps = _list(j['sessionRecaps'], 'Sitzungsrückblicke')
        .map((e) => SessionRecap.fromJson(_map(e, 'Sitzungsrückblick')))
        .toList();
    final threads = _list(j['storyThreads'], 'Handlungsstränge')
        .map((e) => StoryThread.fromJson(_map(e, 'Handlungsstrang')))
        .toList();
    final rawBible = j['storyBible'] == null ? <String, dynamic>{} : _map(j['storyBible'], 'KI-Geschichtenbuch');
    if (rawBible.length > 12 || rawBible.keys.any((key) => key.length > 60) ||
        rawBible.values.any((value) => value is! String || value.length > 1500)) {
      throw const FormatException('Ungültiges KI-Geschichtenbuch.');
    }
    final relationshipNotes = _list(j['npcRelationshipNotes'], 'NPC-Notizen')
        .map((e) => NpcRelationshipNote.fromJson(_map(e, 'NPC-Notiz')))
        .toList();
    final npcs = _list(j['npcs'], 'NPCs')
        .map((e) => WorldNpc.fromJson(_map(e, 'NPC')))
        .toList();
    if (recaps.length > 60 || threads.length > 100 ||
        relationshipNotes.length > 300 ||
        recaps.map((e) => e.id).toSet().length != recaps.length ||
        threads.map((e) => e.id).toSet().length != threads.length ||
        relationshipNotes.map((e) => e.id).toSet().length !=
            relationshipNotes.length ||
        relationshipNotes.any((e) =>
            !npcs.any((npc) => npc.id == e.npcId))) {
      throw const FormatException('Ungültiges Kampagnengedächtnis.');
    }
    if (pending != null) {
      if (!hero.isComplete) {
        throw const FormatException(
          'Eine offene Probe benötigt bestätigte Charakterwerte.',
        );
      }
      final prof = 2 + (hero.level - 1) ~/ 4;
      int modifier(String key) => ((hero.abilities[key]! - 10) / 2).floor();
      final expected = switch (pending.type) {
        'attack' =>
          modifier(hero.weaponAbility) + (hero.weaponProficient ? prof : 0),
        'perception' =>
          modifier('wisdom') + (hero.skills.contains('Wahrnehmung') ? prof : 0),
        'escape' => modifier('dexterity'),
        _ => 0,
      };
      if (pending.modifier != expected) {
        throw const FormatException(
          'Die gespeicherte Probe enthält einen falschen Bonus.',
        );
      }
      if (pending.type == 'attack' &&
          (encounter == null ||
              encounter.isFinished ||
              encounter.id != pending.targetId ||
              encounter.enemyArmorClass != pending.difficulty)) {
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
              hero.conditions.contains('stabil'))) {
        throw const FormatException('Ungültiger Todesrettungswurf.');
      }
      if (pending.type != 'attack' && pending.difficulty != 10) {
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
      storyBible: {for (final entry in rawBible.entries) entry.key: entry.value as String},
      npcRelationshipNotes: relationshipNotes,
      npcs: npcs,
      places: _list(
        j['places'],
        'Orte',
      ).map((e) => Place.fromJson(_map(e, 'Ort'))).toList(),
      events: events,
      pendingRoll: pending,
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
