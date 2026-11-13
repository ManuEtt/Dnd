import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_monk_slow_fall_rules.dart';

HeroCharacter _monk({int level = 4, int hp = 12}) => HeroCharacter(
  id: 'slow-fall-hp-preview',
  name: 'Mönch',
  className: 'Mönch',
  level: level,
  hitPoints: hp,
  maxHitPoints: 30,
);

SrdMonkSlowFallHitPointPreview _preview(
  HeroCharacter hero, {
  int damage = 25,
  bool confirmed = true,
}) => SrdMonkSlowFallRules.previewHitPointsAfterReaction(
  hero,
  confirmedFallDamage: damage,
  fallConfirmed: confirmed,
  reactionAvailable: true,
  reactionConfirmed: true,
);

void main() {
  test('damage reduction and HP preview do not mutate hero', () {
    final hero = _monk();
    final before = hero.toJson();
    final result = _preview(hero);
    expect(result.slowFall.preventedDamage, 20);
    expect(result.slowFall.remainingDamage, 5);
    expect(result.hitPointsBefore, 12);
    expect(result.hitPointsAfter, 7);
    expect(result.wouldDropToZero, isFalse);
    expect(hero.toJson(), before);
  });

  test('lethal damage clamps preview HP to zero', () {
    final result = _preview(_monk(hp: 8), damage: 100);
    expect(result.slowFall.remainingDamage, 80);
    expect(result.hitPointsAfter, 0);
    expect(result.wouldDropToZero, isTrue);
  });

  test('zero damage and exactly lethal damage are distinguished', () {
    final zero = _preview(_monk(), damage: 0);
    expect(zero.hitPointsAfter, 12);
    expect(zero.wouldDropToZero, isFalse);
    final exact = _preview(_monk(), damage: 32);
    expect(exact.hitPointsAfter, 0);
    expect(exact.wouldDropToZero, isTrue);
  });

  test('unconfirmed fall and unavailable feature remain rejected', () {
    expect(() => _preview(_monk(), confirmed: false), throwsFormatException);
    expect(() => _preview(_monk(level: 3)), throwsFormatException);
  });
}
