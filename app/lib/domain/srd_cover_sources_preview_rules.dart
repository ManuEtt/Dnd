import 'cover_rules.dart';

/// A confirmed obstacle's cover relative to one specific incoming attack.
/// An obstacle on the wrong side of the target grants no cover.
class SrdCoverSourceEvidence {
  const SrdCoverSourceEvidence({
    required this.sourceId,
    required this.grade,
    required this.oppositeAttackOriginConfirmed,
  });

  final String sourceId;
  final CoverLevel grade;
  final bool oppositeAttackOriginConfirmed;
}

class SrdCoverSourcesPreview {
  const SrdCoverSourcesPreview({
    required this.effectiveCover,
    required this.armorClassBonus,
    required this.dexteritySaveBonus,
    required this.directlyTargetable,
  });

  final CoverLevel effectiveCover;
  final int armorClassBonus;
  final int dexteritySaveBonus;
  final bool directlyTargetable;
}

/// Read-only cover assessment for a confirmed incoming direction.
/// Cover does not stack: only the strongest applicable source counts.
/// Full cover prevents direct targeting; it is not an infinite AC bonus.
class SrdCoverSourcesRules {
  const SrdCoverSourcesRules._();

  static final RegExp _unsafeId = RegExp(
    r'[\x00-\x1f\x7f-\x9f\u00ad\u034f\u061c\u180e\u200b-\u200f\u2028-\u202e\u2060-\u206f\ufeff\ufff9-\ufffb]',
  );

  static SrdCoverSourcesPreview preview({
    required List<SrdCoverSourceEvidence> sources,
    required bool attackOriginAndCoverConfirmed,
  }) {
    if (!attackOriginAndCoverConfirmed) {
      throw const FormatException(
        'Angriffsrichtung und Deckungsquellen müssen bestätigt sein.',
      );
    }
    final ids = <String>{};
    final applicable = <CoverLevel>[];
    for (final source in sources) {
      final id = source.sourceId;
      if (id.isEmpty ||
          id.length > 128 ||
          id != id.trim() ||
          _unsafeId.hasMatch(id) ||
          !ids.add(id)) {
        throw const FormatException(
          'Deckungsquelle ist ungültig oder doppelt vorhanden.',
        );
      }
      if (source.oppositeAttackOriginConfirmed) {
        applicable.add(source.grade);
      }
    }
    final cover = CoverRules.strongest(applicable);
    return SrdCoverSourcesPreview(
      effectiveCover: cover,
      armorClassBonus: CoverRules.getBonus(cover),
      dexteritySaveBonus: CoverRules.savingThrowBonus(
        cover,
        ability: 'dexterity',
        sourceOppositeCover: true,
      ),
      directlyTargetable: CoverRules.canTargetDirectly(cover),
    );
  }
}
