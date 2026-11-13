import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_bard_superior_inspiration_rules.dart';

HeroCharacter _bard(int? charisma) => HeroCharacter(
  id: 'bard-charisma-bound',
  name: 'Lyra',
  className: 'Barde',
  level: 18,
  hitPoints: 40,
  maxHitPoints: 40,
  abilities: {'charisma': charisma},
  spentClassResources: const {'bardicInspiration': 3},
);

void main() {
  test('invalid Charisma cannot restore Bardic Inspiration', () {
    for (final charisma in <int?>[null, -1, 0, 31, 100]) {
      final hero = _bard(charisma);
      final original = hero.toJson();
      expect(
        () => SrdBardSuperiorInspirationRules.onInitiative(hero),
        throwsStateError,
      );
      expect(hero.toJson(), original);
      expect(hero.spentClassResources['bardicInspiration'], 3);
    }
  });

  test('confirmed minimum and maximum Charisma still restore two uses', () {
    for (final charisma in [1, 30]) {
      final hero = _bard(charisma);
      final result = SrdBardSuperiorInspirationRules.onInitiative(hero);
      expect(result.recovered, 2);
      expect(result.hero.spentClassResources['bardicInspiration'], 1);
      expect(hero.spentClassResources['bardicInspiration'], 3);
    }
  });

  test('ineligible class does not consume resources', () {
    final hero = _bard(0).copyWith(level: 17);
    final result = SrdBardSuperiorInspirationRules.onInitiative(hero);
    expect(result.recovered, 0);
    expect(result.hero.toJson(), hero.toJson());
  });
}
