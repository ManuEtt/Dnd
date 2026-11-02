import 'models.dart';
import 'srd_character_classes.dart';
import 'srd_class_feature_catalog.dart';

/// SRD 5.2.1 Sorcerer, Metamagic: a validated *standalone* choice record.
///
/// This document is not yet a field of HeroCharacter, not a casting permit,
/// and not a cryptographic signature. Legacy sheets must never be assigned
/// Metamagic options by guessing from descriptive feature text.
class SrdMetamagicChoiceRecord {
  const SrdMetamagicChoiceRecord._({
    required this.primaryClassLabel,
    required this.secondaryClassLabel,
    required this.sorcererClassLevel,
    required this.options,
  });

  static const int schemaVersion = 1;

  /// Original labels are retained so a future class edit invalidates a proof.
  final String primaryClassLabel;
  final String secondaryClassLabel;
  final int sorcererClassLevel;
  final List<String> options;

  bool containsOption(String option) => options.contains(option);

  /// An unrelated change of HP, resources, or another class's level must NOT
  /// grant additional options or invalidate a valid Sorcerer selection.
  bool matchesHero(HeroCharacter hero) {
    if (hero.className != primaryClassLabel ||
        hero.secondaryClassName != secondaryClassLabel) {
      return false;
    }
    try {
      return SrdMetamagicChoiceRules._confirmedSorcererLevel(hero) ==
          sorcererClassLevel;
    } on FormatException {
      return false;
    }
  }

  Map<String, dynamic> toJson() => {
    'schemaVersion': schemaVersion,
    'primaryClassLabel': primaryClassLabel,
    'secondaryClassLabel': secondaryClassLabel,
    'sorcererClassLevel': sorcererClassLevel,
    'options': List<String>.of(options),
  };

  factory SrdMetamagicChoiceRecord.fromJson(Map<String, dynamic> json) {
    const keys = <String>{
      'schemaVersion',
      'primaryClassLabel',
      'secondaryClassLabel',
      'sorcererClassLevel',
      'options',
    };
    if (json.length != keys.length || !json.keys.toSet().containsAll(keys)) {
      throw const FormatException('Metamagie-Auswahl enthält unbekannte Felder.');
    }
    if (json['schemaVersion'] != schemaVersion ||
        json['primaryClassLabel'] is! String ||
        json['secondaryClassLabel'] is! String ||
        json['sorcererClassLevel'] is! int ||
        json['options'] is! List) {
      throw const FormatException('Ungültiges Metamagie-Auswahlformat.');
    }
    final primary = json['primaryClassLabel'] as String;
    final secondary = json['secondaryClassLabel'] as String;
    final level = json['sorcererClassLevel'] as int;
    final rawOptions = json['options'] as List;
    if (rawOptions.any((item) => item is! String)) {
      throw const FormatException('Metamagie-Optionen müssen Namen enthalten.');
    }
    SrdMetamagicChoiceRules._validateSourceLabels(
      primary,
      secondary,
      level,
    );
    final names = List<String>.from(rawOptions);
    SrdMetamagicChoiceRules._validateOptions(level, names);
    return SrdMetamagicChoiceRecord._(
      primaryClassLabel: primary,
      secondaryClassLabel: secondary,
      sorcererClassLevel: level,
      options: List.unmodifiable(names),
    );
  }
}

/// Confirmed list size and level-up replacements, independent of UI/database.
class SrdMetamagicChoiceRules {
  const SrdMetamagicChoiceRules._();

  static const Set<String> officialOptions = {
    'Careful Spell',
    'Distant Spell',
    'Empowered Spell',
    'Extended Spell',
    'Heightened Spell',
    'Quickened Spell',
    'Seeking Spell',
    'Subtle Spell',
    'Transmuted Spell',
    'Twinned Spell',
  };

  static int maximumChoices(int sorcererLevel) {
    if (sorcererLevel < 2 || sorcererLevel > 20) return 0;
    if (sorcererLevel >= 17) return 6;
    if (sorcererLevel >= 10) return 4;
    return 2;
  }

  static void _validateSourceLabels(
    String primary,
    String secondary,
    int sorcererLevel,
  ) {
    final first = findSrdClass(primary)?.name;
    final second = secondary.isEmpty ? null : findSrdClass(secondary)?.name;
    if (first == null ||
        (secondary.isNotEmpty && second == null) ||
        (second != null && second == first) ||
        (first != 'Zauberer' && second != 'Zauberer') ||
        sorcererLevel < 2 ||
        sorcererLevel > 20) {
      throw const FormatException(
        'Metamagie-Auswahl benötigt eine bestätigte eigene Zaubererklasse.',
      );
    }
  }

  static int _confirmedSorcererLevel(HeroCharacter hero) {
    final first = findSrdClass(hero.className)?.name;
    final second = hero.hasSecondClass
        ? findSrdClass(hero.secondaryClassName)?.name
        : null;
    if (hero.level < 1 ||
        hero.level > 20 ||
        first == null ||
        hero.primaryClassLevel < 1 ||
        (hero.hasSecondClass &&
            (second == null ||
                second == first ||
                hero.secondaryClassLevel < 1))) {
      throw const FormatException('Unbestätigte eigene Klassenstufen.');
    }
    final level = first == 'Zauberer'
        ? hero.primaryClassLevel
        : second == 'Zauberer'
        ? hero.secondaryClassLevel
        : 0;
    _validateSourceLabels(hero.className, hero.secondaryClassName, level);
    if (!SrdClassFeatureCatalog.unlocked(hero).any(
      (feature) =>
          feature.name == 'Metamagic' &&
          feature.className == 'Zauberer' &&
          feature.classLevel == 2,
    )) {
      throw const FormatException(
        'Metamagie ist für diese Klassenstufe nicht freigeschaltet.',
      );
    }
    return level;
  }

  static void _validateOptions(int level, List<String> options) {
    final count = maximumChoices(level);
    if (count == 0 ||
        options.length != count ||
        options.toSet().length != count ||
        options.any((name) => !officialOptions.contains(name))) {
      throw const FormatException(
        'Metamagieoptionen entsprechen nicht der gewählten Klassenstufe.',
      );
    }
  }

  /// Explicit attestation, e.g. when the player opens an old save that lacks
  /// any verified selection. No options are invented from the class catalog.
  static SrdMetamagicChoiceRecord confirm({
    required HeroCharacter hero,
    required List<String> selectedOptions,
    required bool playerChoiceConfirmed,
  }) {
    if (!playerChoiceConfirmed) {
      throw const FormatException(
        'Die Metamagiewahl muss ausdrücklich bestätigt werden.',
      );
    }
    final level = _confirmedSorcererLevel(hero);
    _validateOptions(level, selectedOptions);
    return SrdMetamagicChoiceRecord._(
      primaryClassLabel: hero.className,
      secondaryClassLabel: hero.secondaryClassName,
      sorcererClassLevel: level,
      options: List.unmodifiable(selectedOptions),
    );
  }

  /// During a verified *Sorcerer-class* level gain, the Sorcerer may exchange
  /// no more than ONE known option, and at 10/17 selects two extra options.
  /// Other-class level gains grant no replacements or new slots.
  static SrdMetamagicChoiceRecord advanceSorcererLevel({
    required HeroCharacter before,
    required HeroCharacter after,
    required SrdMetamagicChoiceRecord previous,
    required List<String> selectedOptions,
    required bool levelGainConfirmed,
    required bool playerChoiceConfirmed,
  }) {
    if (!levelGainConfirmed || !playerChoiceConfirmed) {
      throw const FormatException(
        'Aufstieg und neue Metamagiewahl müssen bestätigt werden.',
      );
    }
    if (!previous.matchesHero(before) ||
        before.className != after.className ||
        before.secondaryClassName != after.secondaryClassName ||
        after.level != before.level + 1 ||
        (before.hasSecondClass &&
            after.secondaryClassLevel != before.secondaryClassLevel &&
            findSrdClass(before.secondaryClassName)?.name != 'Zauberer')) {
      throw const FormatException(
        'Metamagie-Auswahl gehört nicht zum geprüften Klassenaufstieg.',
      );
    }
    final oldLevel = _confirmedSorcererLevel(before);
    final newLevel = _confirmedSorcererLevel(after);
    if (newLevel != oldLevel + 1) {
      throw const FormatException(
        'Neue Metamagieoptionen erfordern genau eine Zaubererstufe.',
      );
    }
    _validateOptions(newLevel, selectedOptions);
    final oldNames = previous.options.toSet();
    final newNames = selectedOptions.toSet();
    final removed = oldNames.difference(newNames).length;
    final added = newNames.difference(oldNames).length;
    final additionalSlots = maximumChoices(newLevel) - maximumChoices(oldLevel);
    if (removed > 1 || added != removed + additionalSlots) {
      throw const FormatException(
        'Bei einem Zaubereraufstieg darf nur eine Metamagieoption wechseln.',
      );
    }
    return SrdMetamagicChoiceRecord._(
      primaryClassLabel: after.className,
      secondaryClassLabel: after.secondaryClassName,
      sorcererClassLevel: newLevel,
      options: List.unmodifiable(selectedOptions),
    );
  }
}
