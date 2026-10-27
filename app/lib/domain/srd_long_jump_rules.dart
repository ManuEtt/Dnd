/// SRD 5.2.1, Rules Glossary: Long Jump (printed pages 184-185).
///
/// Pure assessment of supplied, already confirmed facts. No game state,
/// rolls, movement, resources, or events are changed by this class.
/// This project represents one foot as 30 centimeters.
enum SrdLongJumpCheckOutcome { notRequired, pending, success, failure }

class SrdLongJumpAssessment {
  const SrdLongJumpAssessment({
    required this.runningStart,
    required this.maximumDistanceCentimeters,
    required this.distanceCentimeters,
    required this.movementCostCentimeters,
    required this.movementRemainingCentimeters,
    required this.landingAcrobatics,
    required this.obstacleAthletics,
  });

  final bool runningStart;
  final int maximumDistanceCentimeters;
  final int distanceCentimeters;
  final int movementCostCentimeters;
  final int movementRemainingCentimeters;

  /// An unresolved landing check is not an automatic success.
  final SrdLongJumpCheckOutcome landingAcrobatics;

  /// Failure means the obstacle was hit, not that it was cleared.
  final SrdLongJumpCheckOutcome obstacleAthletics;

  /// Null means the difficult-terrain landing check is still pending.
  bool? get wouldLandProne => switch (landingAcrobatics) {
    SrdLongJumpCheckOutcome.pending => null,
    SrdLongJumpCheckOutcome.failure => true,
    _ => false,
  };

  /// This is only a read-only preflight result. The caller must still
  /// confirm turn ownership, movement, revisions, and event persistence.
  bool get readyForConfirmation =>
      landingAcrobatics != SrdLongJumpCheckOutcome.pending &&
      (obstacleAthletics == SrdLongJumpCheckOutcome.notRequired ||
          obstacleAthletics == SrdLongJumpCheckOutcome.success);
}

class SrdLongJumpRules {
  const SrdLongJumpRules._();

  static int maximumDistanceCentimeters({
    required int? strengthScore,
    required int runUpFeet,
    required bool runUpOnFootConfirmed,
  }) {
    if (strengthScore == null || strengthScore < 1 || strengthScore > 30) {
      throw const FormatException(
        'Für einen Weitsprung ist ein bestätigter Stärkewert erforderlich.',
      );
    }
    if (runUpFeet < 0 ||
        (runUpFeet > 0 && !runUpOnFootConfirmed) ||
        (runUpFeet == 0 && runUpOnFootConfirmed)) {
      throw const FormatException(
        'Der unmittelbar vorangegangene Anlauf muss bestätigt sein.',
      );
    }

    // Running: Strength feet. Standing: half of Strength feet, retaining
    // half-foot precision when Strength is odd.
    return strengthScore * (runUpFeet >= 10 ? 30 : 15);
  }

  /// All distances are exact centimeters, without rounding to whole meters.
  ///
  /// [movementRemainingCentimeters] excludes the already-spent run-up.
  /// A null landing terrain fact is unknown and must fail closed.
  /// [obstacleFreePathConfirmed] means the path has explicitly been checked.
  /// For a known low obstacle, the DM must explicitly decide whether to
  /// request the optional DC 10 Athletics check. Taller obstacles require
  /// separate adjudication; they are not automatically cleared.
  ///
  /// Check totals are accepted only when already confirmed by the caller's
  /// authoritative dice boundary. A missing total remains pending.
  static SrdLongJumpAssessment preflight({
    required int? strengthScore,
    required int runUpFeet,
    required bool runUpOnFootConfirmed,
    required int jumpDistanceCentimeters,
    required int movementRemainingCentimeters,
    required bool? landingInDifficultTerrainConfirmed,
    required bool obstacleFreePathConfirmed,
    int? lowObstacleHeightCentimeters,
    bool? dmRequiresAthleticsCheck,
    int? confirmedLandingAcrobaticsTotal,
    int? confirmedObstacleAthleticsTotal,
  }) {
    final maximum = maximumDistanceCentimeters(
      strengthScore: strengthScore,
      runUpFeet: runUpFeet,
      runUpOnFootConfirmed: runUpOnFootConfirmed,
    );

    if (jumpDistanceCentimeters <= 0 ||
        jumpDistanceCentimeters > maximum) {
      throw const FormatException(
        'Die Weitsprungstrecke überschreitet das bestätigte SRD-Limit.',
      );
    }
    if (movementRemainingCentimeters < jumpDistanceCentimeters) {
      throw const FormatException(
        'Das verbleibende Bewegungsbudget reicht nicht für den Weitsprung.',
      );
    }
    if (landingInDifficultTerrainConfirmed == null) {
      throw const FormatException(
        'Das Landegelände muss ausdrücklich bestätigt sein.',
      );
    }
    if (!landingInDifficultTerrainConfirmed &&
        confirmedLandingAcrobaticsTotal != null) {
      throw const FormatException(
        'Eine Akrobatikprobe ist für diese Landung nicht erforderlich.',
      );
    }

    final landingCheck = landingInDifficultTerrainConfirmed
        ? _resolvedCheck(confirmedLandingAcrobaticsTotal)
        : SrdLongJumpCheckOutcome.notRequired;

    SrdLongJumpCheckOutcome obstacleCheck;
    if (obstacleFreePathConfirmed) {
      if (lowObstacleHeightCentimeters != null ||
          dmRequiresAthleticsCheck != null ||
          confirmedObstacleAthleticsTotal != null) {
        throw const FormatException(
          'Widersprüchliche Angaben zum freien Sprungweg.',
        );
      }
      obstacleCheck = SrdLongJumpCheckOutcome.notRequired;
    } else {
      if (lowObstacleHeightCentimeters == null ||
          lowObstacleHeightCentimeters <= 0 ||
          dmRequiresAthleticsCheck == null) {
        throw const FormatException(
          'Hindernishöhe und Spielleitungsentscheidung fehlen.',
        );
      }
      if (lowObstacleHeightCentimeters * 4 > jumpDistanceCentimeters) {
        throw UnsupportedError(
          'Höhere Hindernisse erfordern eine gesonderte Regelentscheidung.',
        );
      }
      if (dmRequiresAthleticsCheck) {
        obstacleCheck = _resolvedCheck(confirmedObstacleAthleticsTotal);
      } else {
        if (confirmedObstacleAthleticsTotal != null) {
          throw const FormatException(
            'Nicht verlangte Hindernisprobe darf nicht verwendet werden.',
          );
        }
        obstacleCheck = SrdLongJumpCheckOutcome.notRequired;
      }
    }

    return SrdLongJumpAssessment(
      runningStart: runUpFeet >= 10,
      maximumDistanceCentimeters: maximum,
      distanceCentimeters: jumpDistanceCentimeters,
      movementCostCentimeters: jumpDistanceCentimeters,
      movementRemainingCentimeters:
          movementRemainingCentimeters - jumpDistanceCentimeters,
      landingAcrobatics: landingCheck,
      obstacleAthletics: obstacleCheck,
    );
  }

  static SrdLongJumpCheckOutcome _resolvedCheck(int? total) {
    if (total == null) {
      return SrdLongJumpCheckOutcome.pending;
    }
    return total >= 10
        ? SrdLongJumpCheckOutcome.success
        : SrdLongJumpCheckOutcome.failure;
  }
}
