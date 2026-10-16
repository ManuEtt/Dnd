import 'character_rule_engine.dart';
import 'condition_rules.dart';
import 'models.dart';
import 'multiclass_rules.dart';
import 'srd_character_classes.dart';

/// SRD 5.2.1 resource rules. Spell effects, preparation limits, casting time,
/// components and concentration duration must be verified separately.
/// Neither free narration nor a spell name can mutate the game state by itself.
class SpellcastingRules {
  const SpellcastingRules._();

  static Map<int, int> availableSlots(HeroCharacter hero) {
    final maxima = MulticlassRules.spellSlots(hero);
    final available = <int, int>{};
    for (var grade = 1; grade <= 9; grade++) {
      final maximum = maxima[grade - 1];
      final used = hero.spentSpellSlots['$grade'] ?? 0;
      if (used < 0 || used > maximum) {
        throw const FormatException('Zauberplatzverbrauch passt nicht zu den Klassenstufen.');
      }
      if (maximum > 0) available[grade] = maximum - used;
    }
    return Map.unmodifiable(available);
  }

  static int pactClassLevel(HeroCharacter hero) {
    var levels = 0;
    if (findSrdClass(hero.className)?.name == 'Hexenmeister') {
      levels += hero.primaryClassLevel;
    }
    if (findSrdClass(hero.secondaryClassName)?.name == 'Hexenmeister') {
      levels += hero.secondaryClassLevel;
    }
    return levels;
  }

  static int pactSlotCount(HeroCharacter hero) {
    final level = pactClassLevel(hero);
    if (level == 0) return 0;
    if (level < 2) return 1;
    if (level < 11) return 2;
    if (level < 17) return 3;
    return 4;
  }

  static int pactSlotLevel(HeroCharacter hero) {
    final level = pactClassLevel(hero);
    if (level == 0) return 0;
    if (level < 3) return 1;
    if (level < 5) return 2;
    if (level < 7) return 3;
    if (level < 9) return 4;
    return 5;
  }

  static int availablePactSlots(HeroCharacter hero) {
    final rest = pactSlotCount(hero) - hero.spentPactSlots;
    if (rest < 0 || hero.spentPactSlots < 0) {
      throw const FormatException('Paktmagie-Verbrauch passt nicht zur Stufe.');
    }
    return rest;
  }

  static SpellCastResult cast(HeroCharacter hero, {
    required String spellName,
    required int spellLevel,
    int? slotLevel,
    bool pactMagic = false,
    bool concentration = false,
  }) {
    final name = spellName.trim();
    if (name.isEmpty || name.length > 200 ||
        !hero.spells.contains(name)) {
      throw const FormatException('Bitte einen bestätigten bekannten Zauber wählen.');
    }
    if (hero.isDead || (hero.hitPoints != null && hero.hitPoints! <= 0) ||
        !ConditionRules.canTakeActions(hero)) {
      throw StateError('Dieser Charakter kann derzeit keinen Zauber wirken.');
    }
    if ((hero.equippedArmorId.isNotEmpty && !hero.equippedArmorTrained) ||
        (hero.equippedShieldId.isNotEmpty && !hero.equippedShieldTrained)) {
      throw StateError('Ungeübte Rüstung oder Schild verhindern Zauberwirken.');
    }
    if (spellLevel < 0 || spellLevel > 9) {
      throw RangeError.range(spellLevel, 0, 9, 'spellLevel');
    }
    if (spellLevel == 0) {
      if (slotLevel != null || pactMagic) {
        throw const FormatException('Zaubertricks verbrauchen keine Zauberplätze.');
      }
      return SpellCastResult(hero: hero.copyWith(
        concentratingOn: concentration ? name : hero.concentratingOn),
        spellName: name, slotLevel: 0, pactMagic: false);
    }
    if (pactMagic) {
      if (slotLevel != null && slotLevel != pactSlotLevel(hero)) {
        throw const FormatException('Paktmagie verwendet immer ihre aktuelle Platzstufe.');
      }
      final level = pactSlotLevel(hero);
      if (spellLevel > level || availablePactSlots(hero) < 1) {
        throw StateError('Kein ausreichender Paktmagieplatz verfügbar.');
      }
      return SpellCastResult(hero: hero.copyWith(
        spentPactSlots: hero.spentPactSlots + 1,
        concentratingOn: concentration ? name : hero.concentratingOn),
        spellName: name, slotLevel: level, pactMagic: true);
    }
    final chosen = slotLevel ?? spellLevel;
    if (chosen < spellLevel || chosen > 9 ||
        (availableSlots(hero)[chosen] ?? 0) < 1) {
      throw StateError('Kein passender Zauberplatz verfügbar.');
    }
    return SpellCastResult(hero: hero.copyWith(
      spentSpellSlots: {...hero.spentSpellSlots,
        '$chosen': (hero.spentSpellSlots['$chosen'] ?? 0) + 1},
      concentratingOn: concentration ? name : hero.concentratingOn),
      spellName: name, slotLevel: chosen, pactMagic: false);
  }

  static HeroCharacter endConcentration(HeroCharacter hero) =>
      hero.concentratingOn.isEmpty ? hero : hero.copyWith(concentratingOn: '');

  /// DC is at least 10 or half the damage, rounded down.
  static int concentrationDc(int damage) {
    if (damage < 0) throw RangeError.value(damage, 'damage');
    // SRD 5.2.1: minimum 10, maximum 30 (round down).
    return (damage ~/ 2).clamp(10, 30).toInt();
  }

  static ConcentrationResult saveAfterDamage(HeroCharacter hero, {
    required int damage, required int d20,
  }) {
    if (damage <= 0) throw RangeError.value(damage, 'damage');
    if (d20 < 1 || d20 > 20) throw RangeError.range(d20, 1, 20, 'd20');
    if (hero.concentratingOn.isEmpty) {
      throw StateError('Keine laufende Konzentration vorhanden.');
    }
    if (hero.hitPoints == 0 || hero.isDead ||
        !ConditionRules.canTakeActions(hero)) {
      return ConcentrationResult(hero: endConcentration(hero),
          dc: concentrationDc(damage), total: 0, maintained: false);
    }
    final rule = CharacterRuleEngine.savingThrow(hero, 'constitution');
    // Advantage/disadvantage, if situational, must be resolved by dice engine
    // before passing the selected natural d20 value to this function.
    final total = d20 + rule.modifier;
    final dc = concentrationDc(damage);
    return ConcentrationResult(
      hero: total >= dc ? hero : endConcentration(hero),
      dc: dc, total: total, maintained: total >= dc);
  }

  static HeroCharacter afterShortRest(HeroCharacter hero) =>
      hero.copyWith(spentPactSlots: 0);

  static HeroCharacter afterLongRest(HeroCharacter hero) =>
      hero.copyWith(spentSpellSlots: const {}, spentPactSlots: 0,
          concentratingOn: '');
}

class SpellCastResult {
  const SpellCastResult({required this.hero, required this.spellName,
      required this.slotLevel, required this.pactMagic});
  final HeroCharacter hero;
  final String spellName;
  final int slotLevel;
  final bool pactMagic;
}

class ConcentrationResult {
  const ConcentrationResult({required this.hero, required this.dc,
      required this.total, required this.maintained});
  final HeroCharacter hero;
  final int dc, total;
  final bool maintained;
}
