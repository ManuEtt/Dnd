/// A versioned, explicitly assigned spell-preparation record.
///
/// This is a *record of a player's confirmation*, not proof of spell effects,
/// daily preparation counts or any unverified class feature. In particular,
/// old flat spell lists do not acquire an implicit preparing class.
class SrdPreparedSpellRecord {
  SrdPreparedSpellRecord._({
    required this.className,
    required this.level,
    required this.secondaryClassName,
    required this.secondaryClassLevel,
    required List<String> sourceSpells,
    required Map<String, List<String>> spellsByClass,
  }) : sourceSpells = List.unmodifiable(sourceSpells),
       spellsByClass = Map.unmodifiable({
         for (final entry in spellsByClass.entries)
           entry.key: List<String>.unmodifiable(entry.value),
       });

  static const version = 1;

  final String className;
  final int level;
  final String secondaryClassName;
  final int secondaryClassLevel;
  final List<String> sourceSpells;

  /// Canonical SRD class name -> explicitly chosen legacy spell-list entries.
  /// Empty lists are allowed; missing keys are never guessed.
  final Map<String, List<String>> spellsByClass;

  static const castingClasses = <String>{
    'Barde',
    'Kleriker',
    'Druide',
    'Paladin',
    'Waldläufer',
    'Zauberer',
    'Hexenmeister',
    'Magier',
  };

  static SrdPreparedSpellRecord fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != version ||
        json.keys.toSet().difference({
          'schemaVersion',
          'className',
          'level',
          'secondaryClassName',
          'secondaryClassLevel',
          'sourceSpells',
          'spellsByClass',
        }).isNotEmpty) {
      throw const FormatException('Unbekannter Zaubervorbereitungsnachweis.');
    }
    final first = json['className'];
    final second = json['secondaryClassName'];
    final level = json['level'];
    final secondLevel = json['secondaryClassLevel'];
    if (first is! String ||
        first.trim().isEmpty ||
        second is! String ||
        level is! int ||
        level < 1 ||
        level > 20 ||
        secondLevel is! int ||
        secondLevel < 0 ||
        secondLevel >= level ||
        (second.isEmpty != (secondLevel == 0))) {
      throw const FormatException('Ungültiger Klassenstand im Zaubernachweis.');
    }
    final source = json['sourceSpells'];
    final selections = json['spellsByClass'];
    if (source is! List ||
        source.any((s) => s is! String || s.trim().isEmpty) ||
        selections is! Map<String, dynamic> ||
        selections.isEmpty ||
        selections.length > 2) {
      throw const FormatException('Ungültige vorbereitete Zauberliste.');
    }
    final spells = <String, List<String>>{};
    for (final entry in selections.entries) {
      final chosen = entry.value;
      if (!castingClasses.contains(entry.key) ||
          chosen is! List ||
          chosen.length > 400 ||
          chosen.any(
            (value) =>
                value is! String ||
                value.isEmpty ||
                value.trim() != value ||
                value.length > 200,
          )) {
        throw const FormatException(
          'Ungültiger Klasseneintrag im Zaubernachweis.',
        );
      }
      final names = chosen.cast<String>();
      if (names.toSet().length != names.length ||
          names.any((name) => !source.contains(name))) {
        throw const FormatException(
          'Zauberzuordnung widerspricht der bestätigten Zauberliste.',
        );
      }
      spells[entry.key] = names;
    }
    return SrdPreparedSpellRecord._(
      className: first,
      level: level,
      secondaryClassName: second,
      secondaryClassLevel: secondLevel,
      sourceSpells: source.cast<String>(),
      spellsByClass: spells,
    );
  }

  bool matchesSource({
    required String className,
    required int level,
    required String secondaryClassName,
    required int secondaryClassLevel,
    required List<String> spells,
  }) {
    if (this.className != className ||
        this.level != level ||
        this.secondaryClassName != secondaryClassName ||
        this.secondaryClassLevel != secondaryClassLevel ||
        sourceSpells.length != spells.length) {
      return false;
    }
    for (var i = 0; i < spells.length; i++) {
      if (sourceSpells[i] != spells[i]) return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': version,
    'className': className,
    'level': level,
    'secondaryClassName': secondaryClassName,
    'secondaryClassLevel': secondaryClassLevel,
    'sourceSpells': sourceSpells,
    'spellsByClass': spellsByClass,
  };
}
