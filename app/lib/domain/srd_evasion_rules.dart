import 'class_resource_rules.dart';
import 'condition_rules.dart';
import 'models.dart';

/// SRD 5.2.1: Monk/Rogue level 7 Evasion (Entrinnen).
///
/// This is a *read-only* calculation for an already confirmed Dexterity
/// saving throw against an effect whose ordinary success grants half damage.
/// The rule never invents a save, determines a target, spends a resource,
/// or changes HeroCharacter HP / an encounter.
class SrdEvasionResult {
  const SrdEvasionResult({
    required this.incomingDamage,
    required this.damageAfterEvasion,
    required this.preventedDamage,
    required this.saveSucceeded,
  });

  final int incomingDamage;
  final int damageAfterEvasion;
  final int preventedDamage;
  final bool saveSucceeded;
}

class SrdEvasionRules {
  const SrdEvasionRules._();

  static bool unlocked(HeroCharacter hero) =>
      ClassResourceRules.level(hero, 'Mönch') >= 7 ||
      ClassResourceRules.level(hero, 'Schurke') >= 7;

  /// A creature with Incapacitated (including its explicitly modelled
  /// derived conditions) cannot benefit. HP and conditions are checked
  /// without mutating the saved character. A dead/unconfirmed-HP hero is
  /// never offered a positive effect by an incomplete imported sheet.
  static bool eligible(HeroCharacter hero) =>
      unlocked(hero) &&
      ConditionRules.canTakeActions(hero) &&
      !hero.isDead &&
      hero.hitPoints != null &&
      hero.hitPoints! > 0;

  /// [incomingDamage] is the explicitly verified *pre-save* damage before
  /// resistance, vulnerability and other separately applied modifiers.
  /// The caller must not pass a value already halved by an ordinary save.
  ///
  /// Unknown save outcomes or effects not confirmed to use the Dexterity
  /// save-for-half rule are rejected instead of fabricating a game outcome.
  static SrdEvasionResult previewConfirmedDexteritySave(
    HeroCharacter hero, {
    required int? incomingDamage,
    required bool incomingDamageConfirmed,
    required bool dexteritySaveForHalfConfirmed,
    required bool? saveSucceeded,
  }) {
    if (!eligible(hero)) {
      throw const FormatException(
        'Entrinnen erfordert Mönch/Schurke ab Klassenstufe 7 '
        'ohne Handlungsunfähigkeit.',
      );
    }
    if (!incomingDamageConfirmed ||
        !dexteritySaveForHalfConfirmed ||
        saveSucceeded == null ||
        incomingDamage == null ||
        incomingDamage < 0 ||
        incomingDamage > 100000) {
      throw const FormatException(
        'Geschicklichkeitsrettungswurf, Schaden und '
        'Halbschadenswirkung müssen bestätigt sein.',
      );
    }
    final remaining = saveSucceeded ? 0 : incomingDamage ~/ 2;
    return SrdEvasionResult(
      incomingDamage: incomingDamage,
      damageAfterEvasion: remaining,
      preventedDamage: incomingDamage - remaining,
      saveSucceeded: saveSucceeded,
    );
  }
}
