import 'dart:convert';

import 'healing_spell_rules.dart';
import 'models.dart';
import 'srd_character_classes.dart';
import 'srd_spell_catalog.dart';

/// SRD 5.2.1, Spells p. 104: when and how many level 1+ prepared spells a
/// class may EXCHANGE. New spells granted by a class level-up, cantrip changes,
/// always-prepared features, and full daily preparation limits are separate.
enum SrdSpellPreparationTrigger { completedLongRest, classLevelGain }

/// Read-only gate. It NEVER updates spells, consumes resources or marks a rest
/// or level-up complete; those events need their own verified transaction.
class SrdSpellPreparationExchangeRules {
  const SrdSpellPreparationExchangeRules._();

  static const _englishClasses = <String, String>{
    'Barde': 'Bard',
    'Kleriker': 'Cleric',
    'Druide': 'Druid',
    'Paladin': 'Paladin',
    'Waldläufer': 'Ranger',
    'Zauberer': 'Sorcerer',
    'Hexenmeister': 'Warlock',
    'Magier': 'Wizard',
  };

  static const _longRestClasses = <String>{
    'Kleriker',
    'Druide',
    'Paladin',
    'Waldläufer',
    'Magier',
  };

  static const _multipleAtRest = <String>{'Kleriker', 'Druide', 'Magier'};

  /// Return only confirmed, distinct SRD class levels. Invalid homebrew or
  /// duplicate aliases do not silently grant a valid class's spell rules.
  static Map<String, int> _classLevels(HeroCharacter hero) {
    final first = findSrdClass(hero.className)?.name;
    final second = hero.hasSecondClass
        ? findSrdClass(hero.secondaryClassName)?.name
        : null;
    if (hero.level < 1 ||
        hero.level > 20 ||
        first == null ||
        hero.primaryClassLevel < 1 ||
        (!hero.hasSecondClass && hero.secondaryClassLevel != 0) ||
        (hero.hasSecondClass &&
            (second == null ||
                second == first ||
                hero.secondaryClassLevel < 1))) {
      throw const FormatException(
        'Die eigenen Klassenstufen sind nicht bestätigt.',
      );
    }
    return {
      first: hero.primaryClassLevel,
      if (second != null) second: hero.secondaryClassLevel,
    };
  }

  static List<String> _validateSpells(
    HeroCharacter hero, {
    required String castingClass,
    required Iterable<String> names,
    required SrdSpellCatalog catalog,
  }) {
    final result = <String>[];
    final seen = <String>{};
    final selected = names.toList();
    if (selected.isEmpty || selected.length > 100) {
      throw const FormatException(
        'Für den Austausch wird eine vorhandene vorbereitete Liste benötigt.',
      );
    }
    for (final name in selected) {
      // This isolated helper intentionally accepts canonical English SRD
      // names only, not guessed translations of legacy sheet entries.
      final spell = catalog.find(name);
      if (name.isEmpty ||
          name != name.trim() ||
          !seen.add(name) ||
          !hero.spells.contains(name) ||
          spell == null ||
          spell.level < 1 ||
          !spell.classes.contains(_englishClasses[castingClass]) ||
          spell.level >
              HealingSpellRules.maximumPreparedSpellLevel(hero, castingClass)) {
        throw const FormatException(
          'Zauber ist nicht für diese Klasse vorbereitet und freigegeben.',
        );
      }
      result.add(name);
    }
    return List.unmodifiable(result);
  }

  /// A swap replaces the same number of level 1+ spells; it cannot increase
  /// the list size. A new spell granted by leveling is NOT an exchange.
  static SrdSpellPreparationExchangePlan preview({
    required HeroCharacter before,
    required HeroCharacter after,
    required String castingClass,
    required List<String> previouslyPrepared,
    required List<String> proposedPrepared,
    required SrdSpellCatalog catalog,
    required SrdSpellPreparationTrigger trigger,
    required bool playerChangeConfirmed,
    bool completedLongRestConfirmed = false,
    bool wizardSpellbookAccessConfirmed = false,
  }) {
    if (!playerChangeConfirmed) {
      throw const FormatException(
        'Ein Zauberaustausch benötigt eine ausdrückliche Spielerentscheidung.',
      );
    }
    final originalLevels = _classLevels(before);
    final subsequentLevels = _classLevels(after);
    final canonical = findSrdClass(castingClass)?.name;
    if (canonical == null ||
        !_englishClasses.containsKey(canonical) ||
        !originalLevels.containsKey(canonical) ||
        !subsequentLevels.containsKey(canonical) ||
        originalLevels.keys
            .toSet()
            .difference(subsequentLevels.keys.toSet())
            .isNotEmpty ||
        subsequentLevels.keys
            .toSet()
            .difference(originalLevels.keys.toSet())
            .isNotEmpty ||
        before.className != after.className ||
        before.secondaryClassName != after.secondaryClassName) {
      throw const FormatException(
        'Der Austausch gehört nicht zu derselben eigenen Zauberklasse.',
      );
    }

    if (trigger == SrdSpellPreparationTrigger.completedLongRest) {
      if (!completedLongRestConfirmed ||
          !_longRestClasses.contains(canonical) ||
          before.level != after.level ||
          originalLevels[canonical] != subsequentLevels[canonical] ||
          originalLevels.keys.any(
            (name) => originalLevels[name] != subsequentLevels[name],
          )) {
        throw const FormatException(
          'Diese Klasse darf bei dieser Rast keinen Zauber austauschen.',
        );
      }
    } else {
      if (_longRestClasses.contains(canonical) ||
          after.level != before.level + 1 ||
          subsequentLevels[canonical] != originalLevels[canonical]! + 1 ||
          originalLevels.keys.any(
            (name) =>
                name != canonical &&
                originalLevels[name] != subsequentLevels[name],
          )) {
        throw const FormatException(
          'Der Austausch setzt einen Stufenanstieg in genau dieser Klasse voraus.',
        );
      }
    }

    final existing = _validateSpells(
      before,
      castingClass: canonical,
      names: previouslyPrepared,
      catalog: catalog,
    );
    final chosen = _validateSpells(
      after,
      castingClass: canonical,
      names: proposedPrepared,
      catalog: catalog,
    );
    if (existing.length != chosen.length) {
      throw const FormatException(
        'Ein Austausch darf keine zusätzlichen Zauber vorbereiten.',
      );
    }
    final beforeSet = existing.toSet();
    final afterSet = chosen.toSet();
    final removed = existing.where((name) => !afterSet.contains(name)).toList();
    final added = chosen.where((name) => !beforeSet.contains(name)).toList();
    if (removed.isEmpty ||
        added.length != removed.length ||
        (!_multipleAtRest.contains(canonical) && removed.length != 1)) {
      throw const FormatException(
        'Die zulässige Anzahl auszutauschender Zauber wurde überschritten.',
      );
    }
    if (canonical == 'Magier' && !wizardSpellbookAccessConfirmed) {
      throw const FormatException(
        'Neue Magierzauber müssen im Zauberbuch ausdrücklich bestätigt sein.',
      );
    }
    return SrdSpellPreparationExchangePlan._(
      beforeSnapshot: jsonEncode(before.toJson()),
      afterSnapshot: jsonEncode(after.toJson()),
      castingClass: canonical,
      trigger: trigger,
      removed: removed,
      added: added,
    );
  }
}

class SrdSpellPreparationExchangePlan {
  SrdSpellPreparationExchangePlan._({
    required this.beforeSnapshot,
    required this.afterSnapshot,
    required this.castingClass,
    required this.trigger,
    required List<String> removed,
    required List<String> added,
  }) : removed = List.unmodifiable(removed),
       added = List.unmodifiable(added);

  /// These snapshots prevent accidental replay after further hero changes.
  /// They are NOT cryptographic proof and authorize no write by themselves.
  final String beforeSnapshot, afterSnapshot;
  final String castingClass;
  final SrdSpellPreparationTrigger trigger;
  final List<String> removed, added;

  void verifyUnchanged(HeroCharacter before, HeroCharacter after) {
    if (jsonEncode(before.toJson()) != beforeSnapshot ||
        jsonEncode(after.toJson()) != afterSnapshot) {
      throw const FormatException(
        'Die Figuren haben sich seit der Austauschprüfung verändert.',
      );
    }
  }
}
