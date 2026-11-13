import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_indomitable_might_rules.dart';

HeroCharacter _barbarian(int? strength) => HeroCharacter(
  id: 'strength-boundary',
  name: 'Barbar',
  className: 'Barbar',
  level: 18,
  abilities: {'strength': strength},
  hitPoints: 40,
  maxHitPoints: 40,
);

int _total(HeroCharacter hero, SrdD20CheckKind kind) =>
    SrdIndomitableMightRules.effectiveTotal(
      hero: hero,
      ability: 'strength',
      kind: kind,
      rolledTotal: 8,
    );

void main() {
  test('invalid Strength never fabricates an Indomitable Might total', () {
    for (final strength in <int?>[null, -1, 0, 31, 100]) {
      final hero = _barbarian(strength);
      final before = hero.toJson();
      expect(
        () => _total(hero, SrdD20CheckKind.abilityCheck),
        throwsStateError,
      );
      expect(
        () => _total(hero, SrdD20CheckKind.savingThrow),
        throwsStateError,
      );
      expect(_total(hero, SrdD20CheckKind.attack), 8);
      expect(hero.toJson(), before);
    }
  });

  test('confirmed Strength boundaries remain valid', () {
    expect(_total(_barbarian(1), SrdD20CheckKind.abilityCheck), 8);
    expect(_total(_barbarian(30), SrdD20CheckKind.savingThrow), 30);
  });
}
