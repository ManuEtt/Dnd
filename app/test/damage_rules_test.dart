import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/damage_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rules_engine.dart';

void main() {
  group('SRD 5.2.1 typed damage and defenses', () {
    test('13 SRD damage types are available', () {
      expect(DamageType.values, hasLength(13));
    });

    test('resistance rounds down; same type never stacks', () {
      final defenses = DamageDefenses(
        resistances: [DamageType.fire, DamageType.fire],
        resistAll: true,
      );
      final result = DamageRules.resolve(const [
        DamageComponent(DamageType.fire, 23),
      ], defenses: defenses);
      expect(result.total, 11);
      expect(result.parts.single.incoming, 23);
      expect(result.parts.single.resistant, isTrue);
    });

    test('resistance precedes vulnerability (odd amounts)', () {
      final result = DamageRules.resolve(
        const [DamageComponent(DamageType.fire, 23)],
        defenses: DamageDefenses(
          resistances: [DamageType.fire],
          vulnerabilities: [DamageType.fire, DamageType.fire],
        ),
      );
      expect(result.total, 22); // 23 ~/ 2 = 11, then 11 * 2.
    });

    test('immunity overrides resistance and vulnerability', () {
      final result = DamageRules.resolve(
        const [DamageComponent(DamageType.poison, 50)],
        defenses: DamageDefenses(
          resistances: [DamageType.poison],
          vulnerabilities: [DamageType.poison],
          immunities: [DamageType.poison],
        ),
      );
      expect(result.total, 0);
      expect(result.parts.single.immune, isTrue);
    });

    test('mixed types resolve separately and can be inspected', () {
      final result = DamageRules.resolve(
        const [
          DamageComponent(DamageType.fire, 7),
          DamageComponent(DamageType.cold, 9),
          DamageComponent(DamageType.force, 5),
        ],
        defenses: DamageDefenses(
          resistances: [DamageType.fire],
          vulnerabilities: [DamageType.cold],
        ),
      );
      expect(result.parts.map((p) => p.applied).toList(), [3, 18, 5]);
      expect(result.total, 26);
      expect(() => result.parts.clear(), throwsUnsupportedError);
    });

    test('invalid inputs are rejected before HP is changed', () {
      final defenses = DamageDefenses();
      expect(
        () => DamageRules.resolve([], defenses: defenses),
        throwsArgumentError,
      );
      expect(
        () => DamageRules.resolve(const [
          DamageComponent(DamageType.fire, -1),
        ], defenses: defenses),
        throwsRangeError,
      );
    });

    test('typed damage enters the existing HP and death rules', () {
      final hero = HeroCharacter(
        id: 'typed-damage',
        name: 'Eira',
        hitPoints: 24,
        maxHitPoints: 24,
        concentratingOn: 'Segen',
      );
      final after = RulesEngine.damageWithDefenses(
        hero,
        components: const [DamageComponent(DamageType.fire, 9)],
        defenses: DamageDefenses(resistances: [DamageType.fire]),
      );
      expect(after.hitPoints, 20); // 9 ~/ 2 = 4.
      expect(after.concentratingOn, 'Segen');
      expect(hero.hitPoints, 24); // Pure input state.
    });

    test('immunity leaves zero-HP saving throws unchanged', () {
      final downed = HeroCharacter(
        id: 'down',
        name: 'Eira',
        hitPoints: 0,
        maxHitPoints: 20,
        deathFailures: 1,
      );
      final after = RulesEngine.damageWithDefenses(
        downed,
        components: const [DamageComponent(DamageType.poison, 20)],
        defenses: DamageDefenses(immunities: [DamageType.poison]),
      );
      expect(after.deathFailures, 1);
    });
  });
}
