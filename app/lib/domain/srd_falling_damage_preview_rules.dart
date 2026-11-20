/// SRD 5.2.1 Falling: 1d6 bludgeoning damage for every complete
/// 10 feet fallen, to a maximum of 20d6. Landing prone is a separate
/// consequence unless damage is avoided. This is a read-only dice preview:
/// it does not decide whether a creature falls, reduces damage, rolls dice,
/// changes hit points, or adjudicates other falling features.
class SrdFallingDamagePreview {
  const SrdFallingDamagePreview({
    required this.confirmedFallFeet,
    required this.diceCount,
  });

  final int confirmedFallFeet;
  final int diceCount;

  int get minimumDamage => diceCount;
  int get maximumDamage => diceCount * 6;
  double get expectedDamage => diceCount * 3.5;
  String get diceExpression => diceCount == 0 ? '0' : '${diceCount}d6';

  /// Null when the actual damage roll and mitigation are not confirmed.
  /// Even a zero-dice fall does not authorize an automatic prone ruling.
  bool get damageRollRequired => diceCount > 0;
}

class SrdFallingDamageRules {
  const SrdFallingDamageRules._();

  /// The distance must be independently confirmed, in whole feet.
  /// Distances beyond the cap are still accepted because the dice are capped.
  static SrdFallingDamagePreview preview({
    required int confirmedFallFeet,
    required bool fallDistanceConfirmed,
  }) {
    if (!fallDistanceConfirmed) {
      throw const FormatException(
        'Die tatsächliche Fallstrecke muss ausdrücklich bestätigt sein.',
      );
    }
    if (confirmedFallFeet < 0 || confirmedFallFeet > 1000000) {
      throw RangeError.range(
        confirmedFallFeet, 0, 1000000, 'confirmedFallFeet',
      );
    }
    final dice = confirmedFallFeet ~/ 10;
    return SrdFallingDamagePreview(
      confirmedFallFeet: confirmedFallFeet,
      diceCount: dice > 20 ? 20 : dice,
    );
  }
}
