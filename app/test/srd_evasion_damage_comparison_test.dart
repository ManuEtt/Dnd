import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_evasion_rules.dart';

HeroCharacter _monk() => HeroCharacter(
  id: 'evasion-comparison',
  name: 'Leiser Schritt',
  className: 'Mönch',
  level: 7,
  hitPoints: 20,
  maxHitPoints: 20,
);

SrdEvasionDamageComparison _compare(
  HeroCharacter hero, {
  int? damage = 25,
  bool confirmed = true,
  bool? success = true,
}) => SrdEvasionRules.compareConfirmedDexteritySave(
  hero,
  incomingDamage: damage,
  incomingDamageConfirmed: confirmed,
  dexteritySaveForHalfConfirmed: true,
  saveSucceeded: success,
);

void main() {
  test('successful odd-damage save shows exact additional prevention', () {
    final hero = _monk();
    final before = hero.toJson();
    final result = _compare(hero);
    expect(result.ordinaryDamage, 12);
    expect(result.evasion.damageAfterEvasion, 0);
    expect(result.additionalPreventedDamage, 12);
    expect(hero.toJson(), before);
  });

  test('failed save reduces ordinary full damage to half', () {
    final result = _compare(_monk(), success: false);
    expect(result.ordinaryDamage, 25);
    expect(result.evasion.damageAfterEvasion, 12);
    expect(result.additionalPreventedDamage, 13);
  });

  test('zero damage gives no benefit and unconfirmed saves are rejected', () {
    expect(_compare(_monk(), damage: 0).additionalPreventedDamage, 0);
    expect(() => _compare(_monk(), confirmed: false), throwsFormatException);
    expect(() => _compare(_monk(), success: null), throwsFormatException);
    expect(() => _compare(_monk(), damage: -1), throwsFormatException);
    expect(
      () => _compare(_monk().copyWith(level: 6)),
      throwsFormatException,
    );
  });
}
