import 'srd_high_jump_rules.dart';

/// Read-only ledge reach estimate in exact half-centimeters.
/// It does not spend movement, resolve a grab, or override DM adjudication.
class SrdHighJumpLedgeReachPreview {
  const SrdHighJumpLedgeReachPreview({
    required this.targetHeightHalfCentimeters,
    required this.standingReachHalfCentimeters,
    required this.minimumJumpCentimeters,
    required this.maximumJumpCentimeters,
    required this.movementRemainingCentimeters,
  });

  final int targetHeightHalfCentimeters;
  final int standingReachHalfCentimeters;
  final int minimumJumpCentimeters;
  final int maximumJumpCentimeters;
  final int movementRemainingCentimeters;

  bool get withinJumpLimit => minimumJumpCentimeters <= maximumJumpCentimeters;
  bool get withinMovementBudget =>
      minimumJumpCentimeters <= movementRemainingCentimeters;
  bool get reachable => withinJumpLimit && withinMovementBudget;
  int get movementAfterReachCentimeters =>
      movementRemainingCentimeters - minimumJumpCentimeters;
}

/// SRD 5.2.1 High Jump: reach equals jump height plus 1.5 times
/// creature height. The supplied ledge height and creature height must
/// both be explicitly confirmed, not guessed from narration.
class SrdHighJumpLedgeReachRules {
  const SrdHighJumpLedgeReachRules._();

  static SrdHighJumpLedgeReachPreview preview({
    required int? strengthScore,
    required int runUpFeet,
    required bool runUpOnFootConfirmed,
    required int creatureHeightCentimeters,
    required bool creatureHeightConfirmed,
    required int targetHeightHalfCentimeters,
    required bool targetHeightConfirmed,
    required int movementRemainingCentimeters,
  }) {
    if (!creatureHeightConfirmed ||
        !targetHeightConfirmed ||
        creatureHeightCentimeters <= 0 ||
        creatureHeightCentimeters > 10000 ||
        targetHeightHalfCentimeters <= 0 ||
        targetHeightHalfCentimeters > 1000000 ||
        movementRemainingCentimeters < 0) {
      throw const FormatException(
        'Körpergröße, Zielhöhe und Bewegungsbudget müssen gültig bestätigt sein.',
      );
    }
    final maximum = SrdHighJumpRules.maximumHeightCentimeters(
      strengthScore: strengthScore,
      runUpFeet: runUpFeet,
      runUpOnFootConfirmed: runUpOnFootConfirmed,
    );
    final standingReach = creatureHeightCentimeters * 3;
    final extraHalfCentimeters = targetHeightHalfCentimeters - standingReach;
    final minimum = extraHalfCentimeters <= 0
        ? 0
        : (extraHalfCentimeters + 1) ~/ 2;
    return SrdHighJumpLedgeReachPreview(
      targetHeightHalfCentimeters: targetHeightHalfCentimeters,
      standingReachHalfCentimeters: standingReach,
      minimumJumpCentimeters: minimum,
      maximumJumpCentimeters: maximum,
      movementRemainingCentimeters: movementRemainingCentimeters,
    );
  }
}
