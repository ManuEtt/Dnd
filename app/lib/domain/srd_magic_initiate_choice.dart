import 'ability_generation.dart';

/// Audited SRD 5.2.1 Magic Initiate choices for two fixed background lists.
/// Lists are a reviewed snapshot of app/assets/srd_5_2_1_spells.json, not
/// dynamically inferred from user text or unknown imported spell IDs.
/// This is a CHOICE record, not an authorization to cast or spend slots.
class SrdMagicInitiateChoice {
  SrdMagicInitiateChoice({
    required this.background,
    required List<String> cantrips,
    required this.levelOneSpell,
    required this.castingAbility,
  }) : cantrips = List<String>.unmodifiable(cantrips) {
    _validate();
  }

  static const clericCantrips = <String>[
    "Guidance",
    "Light",
    "Mending",
    "Resistance",
    "Sacred Flame",
    "Spare the Dying",
    "Thaumaturgy",
  ];
  static const clericLevelOne = <String>[
    "Bane",
    "Bless",
    "Command",
    "Create or Destroy Water",
    "Cure Wounds",
    "Detect Evil and Good",
    "Detect Magic",
    "Detect Poison and Disease",
    "Guiding Bolt",
    "Healing Word",
    "Inflict Wounds",
    "Protection from Evil and Good",
    "Purify Food and Drink",
    "Sanctuary",
    "Shield of Faith",
  ];
  static const wizardCantrips = <String>[
    "Acid Splash",
    "Chill Touch",
    "Dancing Lights",
    "Elementalism",
    "Fire Bolt",
    "Light",
    "Mage Hand",
    "Mending",
    "Message",
    "Minor Illusion",
    "Poison Spray",
    "Prestidigitation",
    "Ray of Frost",
    "Shocking Grasp",
    "True Strike",
  ];
  static const wizardLevelOne = <String>[
    "Alarm",
    "Burning Hands",
    "Charm Person",
    "Chromatic Orb",
    "Color Spray",
    "Comprehend Languages",
    "Detect Magic",
    "Disguise Self",
    "Expeditious Retreat",
    "False Life",
    "Feather Fall",
    "Find Familiar",
    "Floating Disk",
    "Fog Cloud",
    "Grease",
    "Hideous Laughter",
    "Ice Knife",
    "Identify",
    "Illusory Script",
    "Jump",
    "Longstrider",
    "Mage Armor",
    "Magic Missile",
    "Protection from Evil and Good",
    "Ray of Sickness",
    "Shield",
    "Silent Image",
    "Sleep",
    "Thunderwave",
    "Unseen Servant",
  ];

  static List<String> availableCantrips(SrdBackground background) =>
      switch (background) {
        SrdBackground.acolyte => clericCantrips,
        SrdBackground.sage => wizardCantrips,
        _ => const <String>[],
      };

  static List<String> availableLevelOne(SrdBackground background) =>
      switch (background) {
        SrdBackground.acolyte => clericLevelOne,
        SrdBackground.sage => wizardLevelOne,
        _ => const <String>[],
      };

  static const abilities = <String>['intelligence', 'wisdom', 'charisma'];

  final SrdBackground background;
  final List<String> cantrips;
  final String levelOneSpell;
  final String castingAbility;

  String get sourceList =>
      background == SrdBackground.acolyte ? 'Cleric' : 'Wizard';

  void _validate() {
    if (background != SrdBackground.acolyte &&
        background != SrdBackground.sage) {
      throw const FormatException(
        'Magieinitiierter ist für diesen SRD-Hintergrund nicht vorgesehen.',
      );
    }
    if (cantrips.length != 2 ||
        cantrips.toSet().length != 2 ||
        cantrips.any((name) => !availableCantrips(background).contains(name))) {
      throw const FormatException(
        'Genau zwei unterschiedliche Zaubertricks der Herkunftsliste wählen.',
      );
    }
    if (!availableLevelOne(background).contains(levelOneSpell)) {
      throw const FormatException(
        'Der Zauber des 1. Grades muss zur gleichen Herkunftsliste gehören.',
      );
    }
    if (!abilities.contains(castingAbility)) {
      throw const FormatException(
        'Als Zauberattribut nur Intelligenz, Weisheit oder Charisma wählen.',
      );
    }
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'background': background.name,
    'cantrips': cantrips,
    'levelOneSpell': levelOneSpell,
    'castingAbility': castingAbility,
  };

  factory SrdMagicInitiateChoice.fromJson(Map<String, dynamic> json) {
    final raw = json['cantrips'];
    final backgrounds = SrdBackground.values.where(
      (background) => background.name == json['background'],
    );
    if (json['version'] != 1 ||
        backgrounds.length != 1 ||
        raw is! List ||
        raw.any((value) => value is! String) ||
        json['levelOneSpell'] is! String ||
        json['castingAbility'] is! String) {
      throw const FormatException(
        'Unbekannte oder ungültige Magieinitiierter-Entscheidung.',
      );
    }
    return SrdMagicInitiateChoice(
      background: backgrounds.single,
      cantrips: List<String>.from(raw),
      levelOneSpell: json['levelOneSpell'] as String,
      castingAbility: json['castingAbility'] as String,
    );
  }
}
