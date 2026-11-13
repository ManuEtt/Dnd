import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_warlock_magical_cunning_rules.dart';

HeroCharacter _warlock({
  int level = 11,
  int spent = 3,
  int used = 0,
  int? hp = 20,
}) => HeroCharacter(
  id: 'cunning-preview',
  name: 'Mira',
  className: 'Hexenmeister',
  level: level,
  hitPoints: hp,
  maxHitPoints: 30,
  spentPactSlots: spent,
  spentClassResources: {
    SrdWarlockMagicalCunningRules.resourceKey: used,
  },
);

void main() {
  test('preview respects half-slot recovery and Eldritch Master', () {
    expect(
      SrdWarlockMagicalCunningRules.previewRecoverablePactSlots(_warlock()),
      2,
    );
    expect(
      SrdWarlockMagicalCunningRules.previewRecoverablePactSlots(
        _warlock(level: 20, spent: 4),
      ),
      4,
    );
    expect(
      SrdWarlockMagicalCunningRules.previewRecoverablePactSlots(
        _warlock(level: 1, spent: 1),
      ),
      0,
    );
    expect(
      SrdWarlockMagicalCunningRules.previewRecoverablePactSlots(
        _warlock(used: 1),
      ),
      0,
    );
  });

  test('invalid state is unknown and preview cannot spend resources', () {
    for (final hero in [
      _warlock(spent: -1),
      _warlock(spent: 4),
      _warlock(used: -1),
      _warlock(used: 2),
      _warlock(hp: null),
      _warlock(hp: 0),
      _warlock().copyWith(className: 'Unbekannt'),
    ]) {
      final original = hero.toJson();
      expect(
        SrdWarlockMagicalCunningRules.previewRecoverablePactSlots(hero),
        isNull,
      );
      expect(hero.toJson(), original);
    }
  });

  test('preview agrees with confirmed ritual without consuming preview', () {
    final hero = _warlock();
    final before = hero.toJson();
    final preview =
        SrdWarlockMagicalCunningRules.previewRecoverablePactSlots(hero);
    final restored =
        SrdWarlockMagicalCunningRules.restoreAfterCompletedRite(hero);
    expect(preview, restored.recoveredSlots);
    expect(hero.toJson(), before);
    expect(restored.hero.spentPactSlots, 1);
  });
}
