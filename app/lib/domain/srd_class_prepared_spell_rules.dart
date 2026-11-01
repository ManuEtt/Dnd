import 'healing_spell_rules.dart';
import 'models.dart';
import 'srd_character_classes.dart';
import 'srd_prepared_spell_record.dart';
import 'srd_spell_catalog.dart';

/// Conservative class-owned preparation ledger. It does not cast spells.
///
/// An explicit list from the player is required. Old flat hero.spells lists
/// are never retroactively split between classes. Count limits, feats and
/// subclass preparation still require separate source-verified workflows.
class SrdClassPreparedSpellRules {
  const SrdClassPreparedSpellRules._();

  static const _english = <String, String>{
    'Barde': 'Bard',
    'Kleriker': 'Cleric',
    'Druide': 'Druid',
    'Paladin': 'Paladin',
    'Waldläufer': 'Ranger',
    'Zauberer': 'Sorcerer',
    'Hexenmeister': 'Warlock',
    'Magier': 'Wizard',
  };

  static const _knownAliases = <String, String>{
    'Magisches Geschoss': 'Magic Missile',
    'Wunden heilen': 'Cure Wounds',
    'Heilendes Wort': 'Healing Word',
    'Licht': 'Light',
    'Unsichtbarkeit': 'Invisibility',
  };

  static Map<String, int> _ownCastingClasses(HeroCharacter hero) {
    final first = findSrdClass(hero.className)?.name;
    final second = hero.hasSecondClass
        ? findSrdClass(hero.secondaryClassName)?.name
        : null;
    if (first == null ||
        hero.level < 1 ||
        hero.level > 20 ||
        hero.primaryClassLevel < 1 ||
        (!hero.hasSecondClass && hero.secondaryClassLevel != 0) ||
        (hero.hasSecondClass &&
            (second == null ||
                second == first ||
                hero.secondaryClassLevel < 1))) {
      throw const FormatException(
        'Klassen und Klassenstufen für die Zaubervorbereitung ungültig.',
      );
    }
    return {
      if (_english.containsKey(first)) first: hero.primaryClassLevel,
      if (second != null && _english.containsKey(second))
        second: hero.secondaryClassLevel,
    };
  }

  static Map<String, List<String>> _verify(
    HeroCharacter hero,
    SrdSpellCatalog catalog,
    Map<String, List<String>> selections,
  ) {
    final classes = _ownCastingClasses(hero);
    if (classes.isEmpty || selections.length != classes.length) {
      throw const FormatException(
        'Alle eigenen Zauberklassen müssen einzeln gewählt werden.',
      );
    }
    final canonical = <String, List<String>>{};
    for (final entry in selections.entries) {
      final ownClass = findSrdClass(entry.key)?.name;
      if (ownClass == null ||
          !classes.containsKey(ownClass) ||
          canonical.containsKey(ownClass)) {
        throw const FormatException(
          'Zaubervorbereitung gehört nicht zu einer eigenen Zauberklasse.',
        );
      }
      final seen = <String>{};
      final validated = <String>[];
      for (final raw in entry.value) {
        if (raw.isEmpty ||
            raw != raw.trim() ||
            !hero.spells.contains(raw)) {
          throw const FormatException(
            'Nur ausdrücklich bekannte Zauber dürfen zugeordnet werden.',
          );
        }
        final englishName = _knownAliases[raw] ?? raw;
        final spell = catalog.find(englishName);
        if (spell == null ||
            !spell.classes.contains(_english[ownClass]) ||
            spell.level >
                HealingSpellRules.maximumPreparedSpellLevel(hero, ownClass) ||
            !seen.add(spell.name)) {
          throw const FormatException(
            'Zauber ist für diese eigene Klasse oder deren Stufe ungültig.',
          );
        }
        validated.add(raw);
      }
      canonical[ownClass] = List.unmodifiable(validated);
    }
    if (canonical.length != classes.length ||
        classes.keys.any((name) => !canonical.containsKey(name))) {
      throw const FormatException(
        'Die Vorbereitung aller eigenen Zauberklassen muss bestätigt sein.',
      );
    }
    return Map.unmodifiable(canonical);
  }

  /// Records exactly the confirmed choices without changing legacy spells,
  /// hit points, resources, or the spellcasting class in the raw character.
  static HeroCharacter confirm(
    HeroCharacter hero, {
    required SrdSpellCatalog catalog,
    required Map<String, List<String>> selectedByClass,
    required bool preparationChoicesConfirmed,
  }) {
    if (!preparationChoicesConfirmed) {
      throw const FormatException(
        'Zaubervorbereitung muss ausdrücklich bestätigt werden.',
      );
    }
    final canonical = _verify(hero, catalog, selectedByClass);
    final record = SrdPreparedSpellRecord.fromJson({
      'schemaVersion': SrdPreparedSpellRecord.version,
      'className': hero.className,
      'level': hero.level,
      'secondaryClassName': hero.secondaryClassName,
      'secondaryClassLevel': hero.secondaryClassLevel,
      'sourceSpells': hero.spells,
      'spellsByClass': canonical,
    });
    return hero.copyWith(preparedSpellRecord: record);
  }

  /// Read-only revalidation on trusted, loaded SRD catalogue metadata.
  /// A persisted record is never treated as a cryptographic player signature.
  static bool isPreparedForClass(
    HeroCharacter hero, {
    required SrdSpellCatalog catalog,
    required String castingClass,
    required String spellName,
  }) {
    final record = hero.preparedSpellRecord;
    if (record == null ||
        !record.matchesSource(
          className: hero.className,
          level: hero.level,
          secondaryClassName: hero.secondaryClassName,
          secondaryClassLevel: hero.secondaryClassLevel,
          spells: hero.spells,
        )) {
      return false;
    }
    final canonical = _verify(hero, catalog, record.spellsByClass);
    final own = findSrdClass(castingClass)?.name;
    return canonical[own]?.contains(spellName) ?? false;
  }
}
