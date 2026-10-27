/// SRD 5.2.1, Rules Glossary, "High Jump" (printed page 183).
///
/// Pure preflight only: the caller supplies already-confirmed Strength,
/// on-foot run-up and *remaining* movement. No movement, condition, position,
/// resource, or persistent state is changed here. One foot is 30 cm.
class SrdHighJumpAssessment {
  const SrdHighJumpAssessment({
    required this.runningStart,
    required this.maximumHeightCentimeters,
    required this.jumpHeightCentimeters,
    required this.movementCostCentimeters,
    required this.remainingMovementCentimeters,
    required this.reachableHeightHalfCentimeters,
  });

  /// A confirmed run-up of at least 10 feet immediately before this jump.
  final bool runningStart;

  /// SRD maximum vertical rise, including the standing-jump half-distance.
  final int maximumHeightCentimeters;

  /// Explicitly selected vertical rise, never an inferred maximum jump.
  final int jumpHeightCentimeters;

  /// Every centimeter jumped vertically costs one centimeter of movement.
  final int movementCostCentimeters;

  /// Remaining budget *after* the jump, excluding the already-spent run-up.
  final int remainingMovementCentimeters;

  /// Optional reach above ground, in half-centimeters to avoid rounding
  /// 1.5 times an odd creature height. Null when height was not confirmed.
  final int? reachableHeightHalfCentimeters;
}

class SrdHighJumpRules {
  const SrdHighJumpRules._();

  static int _maximumHeight({
    required int? strengthScore,
    required int runUpFeet,
    required bool runUpOnFootConfirmed,
  }) {
    if (strengthScore == null || strengthScore < 1 || strengthScore > 30) {
      throw const FormatException(
        'Für einen Hochsprung ist ein gültiger Stärkewert erforderlich.',
      );
    }
    if (runUpFeet < 0 ||
        (runUpFeet > 0 && !runUpOnFootConfirmed) ||
        (runUpFeet == 0 && runUpOnFootConfirmed)) {
      throw const FormatException(
        'Der unmittelbar vorausgehende Anlauf muss bestätigt sein.',
      );
    }

    // Dart's ~/ truncates negative halves toward zero: floor is required
    // for odd ability scores below 10 (Strength 9 has modifier -1).
    final strengthModifier = ((strengthScore - 10) / 2).floor();
    final heightFeet = 3 + strengthModifier;
    if (heightFeet <= 0) {
      return 0;
    }

    // A standing High Jump covers half of the running distance, without
    // prematurely rounding fractional feet.
    return heightFeet * (runUpFeet >= 10 ? 30 : 15);
  }

  /// Maximum unmodified jump height in centimeters. A special effect or
  /// DM-adjudicated exception must be validated separately.
  static int maximumHeightCentimeters({
    required int? strengthScore,
    required int runUpFeet,
    required bool runUpOnFootConfirmed,
  }) {
    return _maximumHeight(
      strengthScore: strengthScore,
      runUpFeet: runUpFeet,
      runUpOnFootConfirmed: runUpOnFootConfirmed,
    );
  }

  /// Validate a proposed high jump without spending movement or updating
  /// the encounter. [movementRemainingCentimeters] is authoritative and
  /// already excludes the run-up; this method must not subtract it twice.
  ///
  /// This does not validate turn order, movement-blocking conditions,
  /// unmodelled jump bonuses, special terrain, or a GM override. Those
  /// checks belong to the calling rule/confirmation boundary.
  static SrdHighJumpAssessment preflight({
    required int? strengthScore,
    required int runUpFeet,
    required bool runUpOnFootConfirmed,
    required int jumpHeightCentimeters,
    required int movementRemainingCentimeters,
    int? creatureHeightCentimeters,
  }) {
    final maximum = _maximumHeight(
      strengthScore: strengthScore,
      runUpFeet: runUpFeet,
      runUpOnFootConfirmed: runUpOnFootConfirmed,
    );
    if (jumpHeightCentimeters <= 0 || jumpHeightCentimeters > maximum) {
      throw const FormatException(
        'Die Hochsprunghöhe überschreitet das bestätigte SRD-Limit.',
      );
    }
    if (movementRemainingCentimeters < jumpHeightCentimeters) {
      throw const FormatException(
        'Das verbleibende Bewegungsbudget reicht nicht für den Hochsprung.',
      );
    }
    if (creatureHeightCentimeters != null && creatureHeightCentimeters <= 0) {
      throw const FormatException(
        'Für die Reichhöhe ist eine bestätigte Körpergröße erforderlich.',
      );
    }

    return SrdHighJumpAssessment(
      runningStart: runUpFeet >= 10,
      maximumHeightCentimeters: maximum,
      jumpHeightCentimeters: jumpHeightCentimeters,
      movementCostCentimeters: jumpHeightCentimeters,
      remainingMovementCentimeters:
          movementRemainingCentimeters - jumpHeightCentimeters,
      reachableHeightHalfCentimeters: creatureHeightCentimeters == null
          ? null
          : jumpHeightCentimeters * 2 + creatureHeightCentimeters * 3,
    );
  }
}
