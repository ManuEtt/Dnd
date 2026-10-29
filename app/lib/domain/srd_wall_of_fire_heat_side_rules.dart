import 'srd_spell_catalog.dart';

/// Horizontal sides are named relative to a separately confirmed wall
/// placement. The naming does not infer facing, target height, or cover.
enum SrdWallOfFireTopology { straight, ring }

enum SrdWallOfFireHotSide {
  straightLeft,
  straightRight,
  ringInside,
  ringOutside,
}

enum SrdWallOfFireTargetRegion {
  onWall,
  straightLeft,
  straightRight,
  ringInside,
  ringOutside,
}

enum SrdWallOfFireHeatTrigger { endTurn, firstWallEntryOnTurn }

/// Confirmed facts measured at the moment of the requested trigger.
///
/// Distance is the shortest horizontal distance from the target's confirmed
/// position to the nearest face of the wall on its declared side, NOT the
/// distance to the origin or to a tile center. This module cannot compute
/// distance, cover, elevation, creature footprint, or exact target eligibility.
class SrdWallOfFireHeatSideRequest {
  const SrdWallOfFireHeatSideRequest({
    required this.spell,
    required this.topology,
    required this.selectedHotSide,
    required this.hotSideSelectedAtCastConfirmed,
    required this.targetRegion,
    required this.targetRegionConfirmed,
    required this.distanceToWallFaceFeet,
    required this.distanceConfirmed,
    required this.wallStillActiveConfirmed,
    required this.trigger,
    this.firstWallEntryOnTurnConfirmed = false,
  });

  final SrdSpellDefinition spell;
  final SrdWallOfFireTopology topology;
  final SrdWallOfFireHotSide selectedHotSide;
  final bool hotSideSelectedAtCastConfirmed;
  final SrdWallOfFireTargetRegion targetRegion;
  final bool targetRegionConfirmed;
  final double distanceToWallFaceFeet;
  final bool distanceConfirmed;
  final bool wallStillActiveConfirmed;
  final SrdWallOfFireHeatTrigger trigger;
  final bool firstWallEntryOnTurnConfirmed;
}

/// A review candidate, NOT a damage result or a committed game event.
class SrdWallOfFireHeatSideAssessment {
  const SrdWallOfFireHeatSideAssessment({
    required this.trigger,
    required this.insideWall,
    required this.withinTenFeetOfHotSide,
    required this.requiresDamageReview,
  });

  final SrdWallOfFireHeatTrigger trigger;
  final bool insideWall;
  final bool withinTenFeetOfHotSide;

  /// Even when true, 3D placement, cover, target eligibility, timing,
  /// concentration, damage rolls and duplicate-event safety remain external.
  final bool requiresDamageReview;
}

/// SRD 5.2.1 / Wall of Fire: explicitly chosen damaging side and 10-foot
/// end-of-turn band; first entry into the wall is a separate trigger.
///
/// Pure read-only preflight. This cannot decide whether a creature is actually
/// exposed, whether a trigger was already applied, or how much damage occurs.
/// Wizards of the Coast LLC, SRD 5.2.1, CC BY 4.0:
/// https://www.dndbeyond.com/srd
class SrdWallOfFireHeatSideRules {
  const SrdWallOfFireHeatSideRules._();

  static bool _matchesTopology(
    SrdWallOfFireTopology topology,
    SrdWallOfFireHotSide selected,
  ) => switch (topology) {
    SrdWallOfFireTopology.straight =>
      selected == SrdWallOfFireHotSide.straightLeft ||
          selected == SrdWallOfFireHotSide.straightRight,
    SrdWallOfFireTopology.ring =>
      selected == SrdWallOfFireHotSide.ringInside ||
          selected == SrdWallOfFireHotSide.ringOutside,
  };

  static bool _validRegion(
    SrdWallOfFireTopology topology,
    SrdWallOfFireTargetRegion region,
  ) => switch (topology) {
    SrdWallOfFireTopology.straight =>
      region == SrdWallOfFireTargetRegion.onWall ||
          region == SrdWallOfFireTargetRegion.straightLeft ||
          region == SrdWallOfFireTargetRegion.straightRight,
    SrdWallOfFireTopology.ring =>
      region == SrdWallOfFireTargetRegion.onWall ||
          region == SrdWallOfFireTargetRegion.ringInside ||
          region == SrdWallOfFireTargetRegion.ringOutside,
  };

  static bool _onChosenSide(
    SrdWallOfFireHotSide selected,
    SrdWallOfFireTargetRegion region,
  ) => switch (selected) {
    SrdWallOfFireHotSide.straightLeft =>
      region == SrdWallOfFireTargetRegion.straightLeft,
    SrdWallOfFireHotSide.straightRight =>
      region == SrdWallOfFireTargetRegion.straightRight,
    SrdWallOfFireHotSide.ringInside =>
      region == SrdWallOfFireTargetRegion.ringInside,
    SrdWallOfFireHotSide.ringOutside =>
      region == SrdWallOfFireTargetRegion.ringOutside,
  };

  static SrdWallOfFireHeatSideAssessment previewConfirmedTrigger(
    SrdWallOfFireHeatSideRequest facts,
  ) {
    final spell = facts.spell;
    if (spell.id != 'spell-wall-of-fire' ||
        spell.name != 'Wall of Fire' ||
        spell.level != 4 ||
        spell.range.trim() != '120 feet') {
      throw const FormatException('Kein bestätigter Wall-of-Fire-Zauber.');
    }
    if (!facts.hotSideSelectedAtCastConfirmed ||
        !facts.targetRegionConfirmed ||
        !facts.distanceConfirmed ||
        !facts.wallStillActiveConfirmed) {
      throw const FormatException(
        'Wandseite, Zielposition, Abstand und aktive Wand '
        'müssen bestätigt sein.',
      );
    }
    if (!_matchesTopology(facts.topology, facts.selectedHotSide) ||
        !_validRegion(facts.topology, facts.targetRegion)) {
      throw const FormatException(
        'Gewählte Wandseite oder Zielseite passt nicht zur Wandform.',
      );
    }
    final distance = facts.distanceToWallFaceFeet;
    if (!distance.isFinite ||
        distance < 0 ||
        (facts.targetRegion == SrdWallOfFireTargetRegion.onWall &&
            distance != 0)) {
      throw const FormatException('Ungültiger bestätigter Wandabstand.');
    }
    final insideWall = facts.targetRegion == SrdWallOfFireTargetRegion.onWall;
    final withinHotSide =
        !insideWall &&
        _onChosenSide(facts.selectedHotSide, facts.targetRegion) &&
        distance <= 10;

    if (facts.trigger == SrdWallOfFireHeatTrigger.firstWallEntryOnTurn &&
        (!facts.firstWallEntryOnTurnConfirmed || !insideWall)) {
      throw const FormatException(
        'Erstmaliges Betreten der Wand auf diesem Zug ist nicht bestätigt.',
      );
    }
    final candidate = switch (facts.trigger) {
      SrdWallOfFireHeatTrigger.endTurn => insideWall || withinHotSide,
      SrdWallOfFireHeatTrigger.firstWallEntryOnTurn => insideWall,
    };
    return SrdWallOfFireHeatSideAssessment(
      trigger: facts.trigger,
      insideWall: insideWall,
      withinTenFeetOfHotSide: withinHotSide,
      requiresDamageReview: candidate,
    );
  }
}
