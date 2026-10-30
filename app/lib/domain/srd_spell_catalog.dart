import 'dart:convert';

/// SRD 5.2.1 spell metadata. The indexed transcript is a working source,
/// not proof that each spell's effects have been implemented or fully audited.
class SrdSpellDefinition {
  const SrdSpellDefinition({
    required this.id,
    required this.name,
    required this.level,
    required this.school,
    required this.classes,
    required this.castingTime,
    required this.range,
    required this.components,
    required this.duration,
    required this.verbal,
    required this.somatic,
    required this.material,
    required this.concentration,
    required this.ritual,
  });

  final String id;
  final String name;
  final int level;
  final String school;
  final List<String> classes;
  final String castingTime;
  final String range;
  final String components;
  final String duration;
  final bool verbal;
  final bool somatic;
  final bool material;
  final bool concentration;
  final bool ritual;

  /// Validate all three component flags against the exact spell notation.
  /// Publicly constructed spell definitions must be checked at rule boundaries
  /// as well as during JSON catalogue loading.
  static void validateComponentMetadata({
    required String components,
    required bool verbal,
    required bool somatic,
    required bool material,
  }) {
    // Fail closed on duplicate, unknown or out-of-order component symbols.
    // A material component requires one nonempty, unambiguous description.
    // The published V/S/M flags are still verified individually below.
    final componentMatch = RegExp(
      r'^(V(?:,\s*S)?(?:,\s*M)?|S(?:,\s*M)?|M)(?:\s*\(([^()]*)\))?
    String requiredText(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Ungültige SRD-Zauberangabe: $key');
      }
      return value;
    }

    bool requiredBool(String key) {
      final value = json[key];
      if (value is! bool) {
        throw FormatException('Ungültige SRD-Zauberangabe: $key');
      }
      return value;
    }

    final level = json['level'];
    if (level is! int || level < 0 || level > 9) {
      throw const FormatException('Ungültiger SRD-Zaubergrad.');
    }
    final rawClasses = json['classes'];
    if (rawClasses is! List ||
        rawClasses.isEmpty ||
        rawClasses.any((value) => value is! String || value.isEmpty)) {
      throw const FormatException('Ungültige SRD-Zauberklassen.');
    }
    final classes = List<String>.unmodifiable(rawClasses.cast<String>());
    if (classes.toSet().length != classes.length) {
      throw const FormatException('Doppelte SRD-Zauberklassen.');
    }
    final castingTime = requiredText('casting_time');
    final duration = requiredText('duration');
    final components = requiredText('components');
    final verbal = requiredBool('verbal');
    final somatic = requiredBool('somatic');
    final material = requiredBool('material');
    validateComponentMetadata(
      components: components,
      verbal: verbal,
      somatic: somatic,
      material: material,
    );
    final concentration = requiredBool('concentration');
    final ritual = requiredBool('ritual');
    if (concentration != duration.startsWith('Concentration') ||
        ritual != castingTime.contains('Ritual')) {
      throw const FormatException(
        'SRD-Zauberdauer oder Ritualangabe ungültig.',
      );
    }
    return SrdSpellDefinition(
      id: requiredText('id'),
      name: requiredText('name'),
      level: level,
      school: requiredText('school'),
      classes: classes,
      castingTime: castingTime,
      range: requiredText('range'),
      components: components,
      duration: duration,
      verbal: verbal,
      somatic: somatic,
      material: material,
      concentration: concentration,
      ritual: ritual,
    );
  }

  bool get supportsSingleTurnPreparation =>
      castingTime == 'Action' ||
      castingTime == 'Bonus Action' ||
      castingTime == 'Action or Ritual';
}

class SrdSpellCatalog {
  SrdSpellCatalog._(this.spells, this.byName);

  final List<SrdSpellDefinition> spells;
  final Map<String, SrdSpellDefinition> byName;

  static SrdSpellCatalog fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> ||
        decoded['schema_version'] != 1 ||
        decoded['srd_version'] != '5.2.1' ||
        decoded['official_full_reconciliation_complete'] is! bool ||
        decoded['effect_engine_complete'] is! bool) {
      throw const FormatException('Unbekannter SRD-Zauberkatalog.');
    }
    final raw = decoded['spells'];
    if (raw is! List || raw.isEmpty) {
      throw const FormatException('SRD-Zauberkatalog ist leer.');
    }
    final definitions = <SrdSpellDefinition>[];
    final ids = <String>{};
    final names = <String>{};
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) {
        throw const FormatException('SRD-Zaubereintrag ist kein Objekt.');
      }
      final spell = SrdSpellDefinition.fromJson(entry);
      if (!ids.add(spell.id) || !names.add(spell.name)) {
        throw const FormatException('SRD-Zauber-ID oder Name doppelt.');
      }
      definitions.add(spell);
    }
    return SrdSpellCatalog._(
      List.unmodifiable(definitions),
      Map.unmodifiable({for (final spell in definitions) spell.name: spell}),
    );
  }

  SrdSpellDefinition? find(String englishName) => byName[englishName.trim()];
}
,
    ).firstMatch(components);
    if (componentMatch == null ||
        componentMatch.group(0) != components ||
        (componentMatch.group(2) != null) != material ||
        (material && componentMatch.group(2)!.trim().isEmpty)) {
      throw const FormatException(
        'SRD-Zauberkomponenten haben ein ungültiges Format.',
      );
    }
    final componentTokens = componentMatch.group(1)!.split(',');
    final symbols = componentTokens.map((symbol) => symbol.trim()).toSet();
    for (final symbol in ['V', 'S', 'M']) {
      final expected = switch (symbol) {
        'V' => verbal,
        'S' => somatic,
        _ => material,
      };
      if (symbols.contains(symbol) != expected) {
        throw const FormatException(
          'SRD-Zauberkomponenten widersprechen sich.',
        );
      }
    }
  }

  factory SrdSpellDefinition.fromJson(Map<String, dynamic> json) {
    String requiredText(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('Ungültige SRD-Zauberangabe: $key');
      }
      return value;
    }

    bool requiredBool(String key) {
      final value = json[key];
      if (value is! bool) {
        throw FormatException('Ungültige SRD-Zauberangabe: $key');
      }
      return value;
    }

    final level = json['level'];
    if (level is! int || level < 0 || level > 9) {
      throw const FormatException('Ungültiger SRD-Zaubergrad.');
    }
    final rawClasses = json['classes'];
    if (rawClasses is! List ||
        rawClasses.isEmpty ||
        rawClasses.any((value) => value is! String || value.isEmpty)) {
      throw const FormatException('Ungültige SRD-Zauberklassen.');
    }
    final classes = List<String>.unmodifiable(rawClasses.cast<String>());
    if (classes.toSet().length != classes.length) {
      throw const FormatException('Doppelte SRD-Zauberklassen.');
    }
    final castingTime = requiredText('casting_time');
    final duration = requiredText('duration');
    final components = requiredText('components');
    final verbal = requiredBool('verbal');
    final somatic = requiredBool('somatic');
    final material = requiredBool('material');
    validateComponentMetadata(
      components: components,
      verbal: verbal,
      somatic: somatic,
      material: material,
    );
    final concentration = requiredBool('concentration');
    final ritual = requiredBool('ritual');
    if (concentration != duration.startsWith('Concentration') ||
        ritual != castingTime.contains('Ritual')) {
      throw const FormatException(
        'SRD-Zauberdauer oder Ritualangabe ungültig.',
      );
    }
    return SrdSpellDefinition(
      id: requiredText('id'),
      name: requiredText('name'),
      level: level,
      school: requiredText('school'),
      classes: classes,
      castingTime: castingTime,
      range: requiredText('range'),
      components: components,
      duration: duration,
      verbal: verbal,
      somatic: somatic,
      material: material,
      concentration: concentration,
      ritual: ritual,
    );
  }

  bool get supportsSingleTurnPreparation =>
      castingTime == 'Action' ||
      castingTime == 'Bonus Action' ||
      castingTime == 'Action or Ritual';
}

class SrdSpellCatalog {
  SrdSpellCatalog._(this.spells, this.byName);

  final List<SrdSpellDefinition> spells;
  final Map<String, SrdSpellDefinition> byName;

  static SrdSpellCatalog fromJsonString(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> ||
        decoded['schema_version'] != 1 ||
        decoded['srd_version'] != '5.2.1' ||
        decoded['official_full_reconciliation_complete'] is! bool ||
        decoded['effect_engine_complete'] is! bool) {
      throw const FormatException('Unbekannter SRD-Zauberkatalog.');
    }
    final raw = decoded['spells'];
    if (raw is! List || raw.isEmpty) {
      throw const FormatException('SRD-Zauberkatalog ist leer.');
    }
    final definitions = <SrdSpellDefinition>[];
    final ids = <String>{};
    final names = <String>{};
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) {
        throw const FormatException('SRD-Zaubereintrag ist kein Objekt.');
      }
      final spell = SrdSpellDefinition.fromJson(entry);
      if (!ids.add(spell.id) || !names.add(spell.name)) {
        throw const FormatException('SRD-Zauber-ID oder Name doppelt.');
      }
      definitions.add(spell);
    }
    return SrdSpellCatalog._(
      List.unmodifiable(definitions),
      Map.unmodifiable({for (final spell in definitions) spell.name: spell}),
    );
  }

  SrdSpellDefinition? find(String englishName) => byName[englishName.trim()];
}
