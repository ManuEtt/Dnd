import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_falling_damage_preview_rules.dart';

SrdFallingDamagePreview preview(int feet, {bool confirmed = true}) =>
    SrdFallingDamageRules.preview(
      confirmedFallFeet: feet,
      fallDistanceConfirmed: confirmed,
    );

void main() {
  test('short fall below ten feet has no damage dice', () {
    final result = preview(9);
    expect(result.diceCount, 0);
    expect(result.diceExpression, '0');
    expect(result.minimumDamage, 0);
    expect(result.maximumDamage, 0);
    expect(result.damageRollRequired, isFalse);
  });

  test('complete ten-foot increments determine damage dice', () {
    final result = preview(35);
    expect(result.diceCount, 3);
    expect(result.diceExpression, '3d6');
    expect(result.minimumDamage, 3);
    expect(result.maximumDamage, 18);
    expect(result.expectedDamage, 10.5);
    expect(result.damageRollRequired, isTrue);
  });

  test('damage dice cap at twenty for long falls', () {
    for (final feet in [200, 201, 1000000]) {
      final result = preview(feet);
      expect(result.diceCount, 20);
      expect(result.diceExpression, '20d6');
      expect(result.maximumDamage, 120);
      expect(result.expectedDamage, 70);
    }
  });

  test('unknown and invalid fall distances fail closed', () {
    expect(
      () => preview(20, confirmed: false),
      throwsA(isA<FormatException>()),
    );
    expect(() => preview(-1), throwsRangeError);
    expect(() => preview(1000001), throwsRangeError);
  });
}
