import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_ranger_feral_senses_rules.dart';

HeroCharacter _hero({int level = 18}) => HeroCharacter(
  id: 'feral-grid',
  name: 'Waldwacht',
  className: 'Waldläufer',
  level: level,
  hitPoints: 12,
  maxHitPoints: 12,
);

void main() {
  test('confirmed grid distances include the exact 90 dm boundary', () {
    final hero = _hero();
    for (final distance in [0, 1, 89, 90]) {
      expect(
        SrdRangerFeralSensesRules.withinConfirmedRangeDecimeters(
          hero,
          distanceDecimeters: distance,
          distanceConfirmed: true,
        ),
        isTrue,
      );
    }
    for (final distance in [91, 120, 3000000]) {
      expect(
        SrdRangerFeralSensesRules.withinConfirmedRangeDecimeters(
          hero,
          distanceDecimeters: distance,
          distanceConfirmed: true,
        ),
        isFalse,
      );
    }
  });

  test('missing evidence and impossible grid distances remain unknown', () {
    final hero = _hero();
    for (final distance in <int?>[null, -1, 3000001]) {
      expect(
        SrdRangerFeralSensesRules.withinConfirmedRangeDecimeters(
          hero,
          distanceDecimeters: distance,
          distanceConfirmed: true,
        ),
        isNull,
      );
    }
    expect(
      SrdRangerFeralSensesRules.withinConfirmedRangeDecimeters(
        hero,
        distanceDecimeters: 1,
        distanceConfirmed: false,
      ),
      isNull,
    );
    expect(
      SrdRangerFeralSensesRules.withinConfirmedRangeDecimeters(
        _hero(level: 17),
        distanceDecimeters: 10,
        distanceConfirmed: true,
      ),
      isNull,
    );
  });
}
