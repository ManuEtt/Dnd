import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_cone_area_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_grid_target_rules.dart';

void main() {
  test('opposite cone directions preserve candidate geometry by rotation', () {
    const origin = SrdGridCell(20, 20);
    final map = SrdSpellGridMap(
      width: 41,
      height: 41,
      fullBlockers: const [],
      fullBlockersSurveyedConfirmed: true,
    );
    const opposites = [
      (SrdConeDirection.north, SrdConeDirection.south),
      (SrdConeDirection.northEast, SrdConeDirection.southWest),
      (SrdConeDirection.east, SrdConeDirection.west),
      (SrdConeDirection.southEast, SrdConeDirection.northWest),
    ];

    for (final (forward, reverse) in opposites) {
      final first = SrdConeAreaRules.preview(
        map: map,
        origin: origin,
        lengthFeet: 30,
        direction: forward,
      );
      final opposite = SrdConeAreaRules.preview(
        map: map,
        origin: origin,
        lengthFeet: 30,
        direction: reverse,
      );
      expect(first.candidates, isNotEmpty);
      expect(first.candidates.length, opposite.candidates.length);
      for (final candidate in first.candidates) {
        final rotated = SrdGridCell(
          2 * origin.column - candidate.cell.column,
          2 * origin.row - candidate.cell.row,
        );
        final counterpart = opposite.at(rotated);
        expect(counterpart, isNotNull, reason: '$forward: ${candidate.cell}');
        expect(
          counterpart!.centerWithinCone,
          candidate.centerWithinCone,
          reason: '$forward: ${candidate.cell}',
        );
        expect(
          counterpart.originCellRequiresReview,
          candidate.originCellRequiresReview,
        );
      }
    }
  });

  test('cone preview cannot turn an unconfirmed map into a valid area', () {
    const origin = SrdGridCell(20, 20);
    final map = SrdSpellGridMap(
      width: 41,
      height: 41,
      fullBlockers: const [],
      fullBlockersSurveyedConfirmed: false,
    );
    for (final direction in SrdConeDirection.values) {
      expect(
        () => SrdConeAreaRules.preview(
          map: map,
          origin: origin,
          lengthFeet: 30,
          direction: direction,
        ),
        throwsFormatException,
      );
    }
  });
}
