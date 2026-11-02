import 'dart:convert';

import 'class_resource_rules.dart';
import 'healing_spell_rules.dart';
import 'models.dart';
import 'srd_character_classes.dart';
import 'srd_class_feature_catalog.dart';
import 'srd_spell_catalog.dart';
import 'srd_spell_grid_target_rules.dart';

/// SRD 5.2.1, Sorcerer / Metamagic / Distant Spell (CC BY 4.0).
///
/// The one-Sorcery-Point option changes a Touch spell's range to 30 feet.
/// This is an isolated, fail-closed *proposal*, not a substitute for the
/// authoritative spellcasting/target/effect/slot transaction. In particular,
/// neither free-form feature text nor a bool is durable proof of a learned
/// Metamagic choice; the caller must separately confirm that choice.
class SrdDistantTouchMetamagicRules {
  const SrdDistantTouchMetamagicRules._();

  static const int sorceryPointCost = 1;
  static const int maximumRangeFeet = 30;

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

  static Map<String, int> _validatedClassLevels(HeroCharacter hero) {
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
        'Eigene Klassenstufen für Metamagie nicht bestätigt.',
      );
    }
    return Map.unmodifiable({
      first: hero.primaryClassLevel,
      if (second != null) second: hero.secondaryClassLevel,
    });
  }

  /// Only a loaded catalogue entry is authoritative. Feature selection,
  /// material payments, target validity, casting action, spell slot and other
  /// Metamagic options must be validated separately by their own rule engines.
  static SrdDistantTouchPlan preview({
    required HeroCharacter hero,
    required SrdSpellCatalog catalog,
    required String spellName,
    required String castingClass,
    required SrdSpellGridTargetRequest gridTarget,
    required bool distantSpellChoiceConfirmed,
    required bool preparedForCastingClassConfirmed,
    required bool targetRulesConfirmed,
    required bool metamagicCombinationAllowedConfirmed,
  }) {
    final classLevels = _validatedClassLevels(hero);
    if ((classLevels['Zauberer'] ?? 0) < 2 ||
        !SrdClassFeatureCatalog.unlocked(hero).any(
          (feature) =>
              feature.className == 'Zauberer' &&
              feature.name == 'Metamagic' &&
              feature.classLevel <= classLevels['Zauberer']!,
        )) {
      throw const FormatException(
        'Distant Spell benötigt Metamagie aus mindestens Zaubererstufe 2.',
      );
    }
    if (!distantSpellChoiceConfirmed ||
        !preparedForCastingClassConfirmed ||
        !targetRulesConfirmed ||
        !metamagicCombinationAllowedConfirmed) {
      throw const FormatException(
        'Metamagiewahl, Klassenzuordnung und Ziel müssen bestätigt sein.',
      );
    }
    if (spellName.isEmpty || spellName != spellName.trim()) {
      throw const FormatException('Ungültiger bestätigter Zaubername.');
    }
    final spell = catalog.find(spellName);
    final canonicalClass = findSrdClass(castingClass)?.name;
    if (spell == null ||
        spell.range != 'Touch' ||
        spell.name != spellName ||
        !hero.spells.contains(spellName) ||
        canonicalClass == null ||
        !classLevels.containsKey(canonicalClass) ||
        !_englishClasses.containsKey(canonicalClass) ||
        !spell.classes.contains(_englishClasses[canonicalClass]) ||
        HealingSpellRules.maximumPreparedSpellLevel(hero, canonicalClass) <
            spell.level) {
      throw const FormatException(
        'Zauber ist für die eigene bestätigte Klasse nicht verfügbar.',
      );
    }

    if (hero.hitPoints == null ||
        hero.hitPoints! < 1 ||
        hero.maxHitPoints == null ||
        hero.maxHitPoints! < hero.hitPoints! ||
        hero.isDead) {
      throw StateError('Metamagie erfordert eine handlungsfähige Figur.');
    }
    if (ClassResourceRules.remaining(hero, 'sorceryPoints') <
        sorceryPointCost) {
      throw StateError('Nicht genügend bestätigte Zaubereipunkte.');
    }

    // Unlike an ordinary Touch cast, Distant Spell has 30 feet of actual
    // range. The grid still needs an independently confirmed clear route.
    final map = gridTarget.map;
    if (!SrdSpellGridTargetRules.hasClearCenterRay(
      map,
      gridTarget.caster,
      gridTarget.origin,
    )) {
      throw const FormatException(
        'Der Rasterweg für Distant Spell ist blockiert.',
      );
    }
    final distance = SrdSpellGridTargetRules.distanceFeet(
      gridTarget.caster,
      gridTarget.origin,
    );
    if (distance > maximumRangeFeet) {
      throw const FormatException(
        'Distant Spell reicht bei Berührung höchstens 30 Fuß.',
      );
    }
    return SrdDistantTouchPlan._(
      heroSnapshot: jsonEncode(hero.toJson()),
      castingClass: canonicalClass,
      spellName: spell.name,
      distanceFeet: distance,
    );
  }
}

/// Read-only audited distance plus the exact source hero snapshot.
/// The plan is not persisted and does not itself authorize a spell effect.
class SrdDistantTouchPlan {
  const SrdDistantTouchPlan._({
    required this.heroSnapshot,
    required this.castingClass,
    required this.spellName,
    required this.distanceFeet,
  });

  final String heroSnapshot;
  final String castingClass;
  final String spellName;
  final int distanceFeet;
  int get maximumRangeFeet => SrdDistantTouchMetamagicRules.maximumRangeFeet;
  int get sorceryPointCost => SrdDistantTouchMetamagicRules.sorceryPointCost;

  void verifyUnchanged(HeroCharacter hero) {
    if (jsonEncode(hero.toJson()) != heroSnapshot) {
      throw const FormatException(
        'Metamagieprüfung ist durch Änderungen am Charakter veraltet.',
      );
    }
  }

  /// Stages a resource debit in a *new* hero object. The caller must combine
  /// this with all casting costs and the resolved effect in ONE optimistic
  /// repository transaction; saving this standalone would be incorrect.
  HeroCharacter stageSorceryPointCost(
    HeroCharacter hero, {
    required bool castingCostsAndEffectResolvedSeparatelyConfirmed,
  }) {
    verifyUnchanged(hero);
    if (!castingCostsAndEffectResolvedSeparatelyConfirmed) {
      throw const FormatException(
        'Metamagiepunkte erst nach bestätigter Zauberauflösung vormerken.',
      );
    }
    return ClassResourceRules.spend(
      hero,
      'sorceryPoints',
      amount: sorceryPointCost,
    );
  }
}
