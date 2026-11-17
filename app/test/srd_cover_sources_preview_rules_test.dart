import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/cover_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_cover_sources_preview_rules.dart';

SrdCoverSourceEvidence obstacle(
  String id,
  CoverLevel grade, {
  bool opposite = true,
}) => SrdCoverSourceEvidence(
  sourceId: id,
  grade: grade,
  oppositeAttackOriginConfirmed: opposite,
);

SrdCoverSourcesPreview preview(List<SrdCoverSourceEvidence> sources) =>
    SrdCoverSourcesRules.preview(
      sources: sources,
      attackOriginAndCoverConfirmed: true,
    );

void main() {
  test('multiple cover grades do not stack', () {
    final result = preview([
      obstacle('crate', CoverLevel.half),
      obstacle('wall', CoverLevel.threeQuarters),
    ]);
    expect(result.effectiveCover, CoverLevel.threeQuarters);
    expect(result.armorClassBonus, 5);
    expect(result.dexteritySaveBonus, 5);
    expect(result.directlyTargetable, isTrue);
  });

  test('wrong-side obstacles grant no cover', () {
    final result = preview([
      obstacle('wall', CoverLevel.total, opposite: false),
      obstacle('crate', CoverLevel.half),
    ]);
    expect(result.effectiveCover, CoverLevel.half);
    expect(result.armorClassBonus, 2);
    expect(result.directlyTargetable, isTrue);
  });

  test('full cover forbids direct targeting without infinite AC', () {
    final result = preview([
      obstacle('wall', CoverLevel.total),
      obstacle('crate', CoverLevel.half),
    ]);
    expect(result.effectiveCover, CoverLevel.total);
    expect(result.armorClassBonus, 0);
    expect(result.directlyTargetable, isFalse);
  });

  test('no sources means no cover', () {
    final result = preview([]);
    expect(result.effectiveCover, CoverLevel.none);
    expect(result.armorClassBonus, 0);
    expect(result.dexteritySaveBonus, 0);
  });

  test('unconfirmed directions and ambiguous IDs are rejected', () {
    expect(
      () => SrdCoverSourcesRules.preview(
        sources: [],
        attackOriginAndCoverConfirmed: false,
      ),
      throwsFormatException,
    );
    for (final sources in [
      [obstacle('x', CoverLevel.half), obstacle('x', CoverLevel.total)],
      [obstacle(' x', CoverLevel.half)],
      [obstacle('x\u200b', CoverLevel.half)],
    ]) {
      expect(() => preview(sources), throwsFormatException);
    }
  });
}
