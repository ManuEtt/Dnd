import 'dart:convert';

const abilityNames = ['Stärke', 'Geschicklichkeit', 'Konstitution', 'Intelligenz', 'Weisheit', 'Charisma'];

/// Null means unknown; never silently invent ability scores.
class CharacterSheet {
  const CharacterSheet({
    required this.id,
    required this.name,
    required this.species,
    required this.characterClass,
    this.level = 1,
    this.background = '',
    this.backstory = '',
    this.abilities = const {},
    this.maxHp,
    this.hp,
    this.armorClass,
    this.gold,
    this.experience = 0,
    this.inventory = const [],
  });

  final String id;
  final String name;
  final String species;
  final String characterClass;
  final int level;
  final String background;
  final String backstory;
  final Map<String, int?> abilities;
  final int? maxHp;
  final int? hp;
  final int? armorClass;
  final int? gold;
  final int experience;
  final List<String> inventory;

  int? get dexterity => abilities['Geschicklichkeit'];
  bool get isComplete => abilityNames.every((name) => abilities[name] != null) &&
      maxHp != null && hp != null && armorClass != null;

  CharacterSheet copyWith({
    String? name, String? species, String? characterClass,
    int? level, String? background, String? backstory,
    Map<String, int?>? abilities, int? maxHp, int? hp,
    int? armorClass, int? gold, int? experience, List<String>? inventory,
  }) => CharacterSheet(
    id: id,
    name: name ?? this.name,
    species: species ?? this.species,
    characterClass: characterClass ?? this.characterClass,
    level: level ?? this.level,
    background: background ?? this.background,
    backstory: backstory ?? this.backstory,
    abilities: abilities ?? this.abilities,
    maxHp: maxHp ?? this.maxHp,
    hp: hp ?? this.hp,
    armorClass: armorClass ?? this.armorClass,
    gold: gold ?? this.gold,
    experience: experience ?? this.experience,
    inventory: inventory ?? this.inventory,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'species': species, 'characterClass': characterClass,
    'level': level, 'background': background, 'backstory': backstory,
    'abilities': abilities, 'maxHp': maxHp, 'hp': hp,
    'armorClass': armorClass, 'gold': gold, 'experience': experience,
    'inventory': inventory,
  };

  factory CharacterSheet.fromJson(Map<String, dynamic> value) => CharacterSheet(
    id: value['id'] as String,
    name: value['name'] as String,
    species: value['species'] as String,
    characterClass: value['characterClass'] as String,
    level: (value['level'] as num?)?.toInt() ?? 1,
    background: value['background'] as String? ?? '',
    backstory: value['backstory'] as String? ?? '',
    abilities: (value['abilities'] as Map<String, dynamic>? ?? {}).map(
      (key, val) => MapEntry(key, (val as num?)?.toInt()),
    ),
    maxHp: (value['maxHp'] as num?)?.toInt(),
    hp: (value['hp'] as num?)?.toInt(),
    armorClass: (value['armorClass'] as num?)?.toInt(),
    gold: (value['gold'] as num?)?.toInt(),
    experience: (value['experience'] as num?)?.toInt() ?? 0,
    inventory: List<String>.from(value['inventory'] as List? ?? []),
  );
}

class Campaign {
  const Campaign({
    required this.id, required this.title, required this.heroId,
    required this.scene, required this.location, this.turn = 0,
  });
  final String id;
  final String title;
  final String heroId;
  final String scene;
  final String location;
  final int turn;

  Campaign copyWith({String? scene, String? location, int? turn}) => Campaign(
    id: id, title: title, heroId: heroId, scene: scene ?? this.scene,
    location: location ?? this.location, turn: turn ?? this.turn,
  );
  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'heroId': heroId, 'scene': scene,
    'location': location, 'turn': turn,
  };
  factory Campaign.fromJson(Map<String, dynamic> value) => Campaign(
    id: value['id'] as String, title: value['title'] as String,
    heroId: value['heroId'] as String, scene: value['scene'] as String,
    location: value['location'] as String,
    turn: (value['turn'] as num?)?.toInt() ?? 0,
  );
}

class GameEvent {
  const GameEvent({
    required this.id, required this.campaignId, required this.sessionId,
    required this.type, required this.text, required this.createdAt,
    this.data = const {},
  });
  final String id;
  final String campaignId;
  final String sessionId;
  final String type;
  final String text;
  final DateTime createdAt;
  final Map<String, dynamic> data;
  Map<String, Object?> toRow() => {
    'id': id, 'campaign_id': campaignId, 'session_id': sessionId,
    'type': type, 'text': text, 'created_at': createdAt.toUtc().toIso8601String(),
    'payload': jsonEncode(data),
  };
  factory GameEvent.fromRow(Map<String, Object?> row) => GameEvent(
    id: row['id'] as String, campaignId: row['campaign_id'] as String,
    sessionId: row['session_id'] as String, type: row['type'] as String,
    text: row['text'] as String,
    createdAt: DateTime.parse(row['created_at'] as String),
    data: jsonDecode(row['payload'] as String) as Map<String, dynamic>,
  );
}
