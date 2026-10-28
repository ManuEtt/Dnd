import 'models.dart';
import 'srd_character_classes.dart';

/// SRD 5.2.1, Sorcerer 5: Sorcerous Restoration (CC BY 4.0).
///
/// Only a player-confirmed completed Short Rest may invoke this effect.
/// Short Rest duration and interruptions remain at the existing rest boundary.
/// Source: https://www.dndbeyond.com/srd
class SrdSorcerousRestorationRules {
  const SrdSorcerousRestorationRules._();

  static const resourceKey = 'sorcerousRestoration';

  static int sorcererClassLevel(HeroCharacter hero) {
    final first = findSrdClass(hero.className)?.name == 'Zauberer'
        ? hero.primaryClassLevel
        : 0;
    final second =
        hero.hasSecondClass &&
            findSrdClass(hero.secondaryClassName)?.name == 'Zauberer'
        ? hero.secondaryClassLevel
        : 0;
    return first + second;
  }

  static int maximumUses(HeroCharacter hero) =>
      sorcererClassLevel(hero) >= 5 ? 1 : 0;

  /// SRD 5.2.1: half the Sorcerer class level, rounded down.
  static int maximumRecoveredPoints(HeroCharacter hero) =>
      sorcererClassLevel(hero) >= 5 ? sorcererClassLevel(hero) ~/ 2 : 0;

  /// Pure rule result. A failed request never consumes the one-time charge.
  static SrdSorcerousRestorationResult restoreAfterCompletedShortRest(
    HeroCharacter hero,
  ) {
    final classLevel = sorcererClassLevel(hero);
    if (classLevel < 5) {
      throw StateError('Zauberkraftregeneration erfordert Zaubererstufe 5.');
    }
    if (hero.isDead ||
        hero.hitPoints == null ||
        hero.hitPoints! <= 0 ||
        hero.maxHitPoints == null ||
        hero.maxHitPoints! < hero.hitPoints!) {
      throw StateError('Der Charakter kann keine kurze Rast abschließen.');
    }
    final spent = hero.spentClassResources['sorceryPoints'] ?? 0;
    if (spent < 0 || spent > classLevel) {
      throw const FormatException('Ungültige ausgegebene Zaubereipunkte.');
    }
    final used = hero.spentClassResources[resourceKey] ?? 0;
    if (used < 0 || used > maximumUses(hero)) {
      throw const FormatException('Ungültige Zauberkraftregeneration.');
    }
    if (used > 0) {
      throw StateError(
        'Zauberkraftregeneration ist erst nach einer langen Rast wieder verfügbar.',
      );
    }
    if (spent == 0) {
      throw StateError('Es sind keine Zaubereipunkte ausgegeben.');
    }
    final cap = maximumRecoveredPoints(hero);
    final restored = spent < cap ? spent : cap;
    final result = hero.copyWith(
      spentClassResources: {
        ...hero.spentClassResources,
        'sorceryPoints': spent - restored,
        resourceKey: 1,
      },
    );
    return SrdSorcerousRestorationResult(
      hero: result,
      recoveredPoints: restored,
      spentBefore: spent,
      spentAfter: spent - restored,
      usesRemaining: 0,
    );
  }
}

class SrdSorcerousRestorationResult {
  const SrdSorcerousRestorationResult({
    required this.hero,
    required this.recoveredPoints,
    required this.spentBefore,
    required this.spentAfter,
    required this.usesRemaining,
  });

  final HeroCharacter hero;
  final int recoveredPoints;
  final int spentBefore;
  final int spentAfter;
  final int usesRemaining;
}
