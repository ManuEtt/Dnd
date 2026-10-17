import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/damage_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rules_engine.dart';

HeroCharacter _fallen({int failures = 0, bool stable = false}) => HeroCharacter(
  id: 'fallen',
  name: 'Liora',
  hitPoints: 0,
  maxHitPoints: 12,
  temporaryHitPoints: 20,
  deathFailures: failures,
  conditions: ['bewusstlos', if (stable) 'stabil'],
);

void main() {
  // SRD 5.2.1 p. 18, Damage at 0 Hit Points / Temporary Hit Points.
  test('Schaden bei 0 TP verursacht Fehlschlag trotz temporärer TP', () {
    final original = _fallen();
    final next = RulesEngine.damage(original, 1);
    expect(next.hitPoints, 0);
    expect(next.temporaryHitPoints, 19);
    expect(next.deathFailures, 1);
    expect(next.isDead, isFalse);
    expect(next.conditions, contains('bewusstlos'));
    expect(original.deathFailures, 0);
    expect(HeroCharacter.fromJson(next.toJson()).deathFailures, 1);
  });

  test('vollständig aufgefangener Schaden beendet Stabilität', () {
    final next = RulesEngine.damage(_fallen(stable: true), 2);
    expect(next.conditions, isNot(contains('stabil')));
    expect(next.deathFailures, 1);
    expect(next.temporaryHitPoints, 18);
  });

  test('kritischer Treffer zählt zwei Fehlschläge; dritter bedeutet Tod', () {
    final critical = RulesEngine.damage(_fallen(), 1, critical: true);
    expect(critical.deathFailures, 2);
    expect(critical.isDead, isFalse);
    final death = RulesEngine.damage(_fallen(failures: 2), 1, critical: true);
    expect(death.deathFailures, 3);
    expect(death.isDead, isTrue);
    expect(death.temporaryHitPoints, 19);
  });

  test('Schaden ab TP-Maximum tötet bei bereits 0 TP sofort', () {
    final next = RulesEngine.damage(_fallen(), 12);
    expect(next.isDead, isTrue);
    expect(next.temporaryHitPoints, 8);
    expect(next.deathFailures, 3);
  });

  test('null Schaden und Schadensimmunität verursachen keinen Fehlschlag', () {
    final original = _fallen(stable: true);
    expect(RulesEngine.damage(original, 0), same(original));
    final immune = RulesEngine.damageWithDefenses(
      original,
      components: const [DamageComponent(DamageType.fire, 12)],
      defenses: DamageDefenses(immunities: [DamageType.fire]),
    );
    expect(immune, same(original));
    expect(immune.deathFailures, 0);
    expect(immune.conditions, contains('stabil'));
  });

  test('bei positiven TP schützt der Puffer weiter vor Bewusstlosigkeit', () {
    final next = RulesEngine.damage(
      _fallen().copyWith(hitPoints: 1, conditions: []),
      12,
    );
    expect(next.hitPoints, 1);
    expect(next.temporaryHitPoints, 8);
    expect(next.deathFailures, 0);
    expect(next.isDead, isFalse);
  });
}
