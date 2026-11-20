import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_sorcerous_restoration_rules.dart';

HeroCharacter _hero({
  int level = 5,
  int spent = 4,
  int used = 0,
  int? hp = 12,
}) => HeroCharacter(
  id: 'sorcerous-preview',
  name: 'Ela',
  className: 'Zauberer',
  level: level,
  hitPoints: hp,
  maxHitPoints: 20,
  spentClassResources: {
    'sorceryPoints': spent,
    SrdSorcerousRestorationRules.resourceKey: used,
  },
);

void main() {
  test('preview uses Sorcerer class level and remaining spent points', () {
    expect(SrdSorcerousRestorationRules.previewRecoverablePoints(_hero()), 2);
    expect(
      SrdSorcerousRestorationRules.previewRecoverablePoints(
        _hero(level: 9, spent: 3),
      ),
      3,
    );
    expect(
      SrdSorcerousRestorationRules.previewRecoverablePoints(
        _hero(level: 4, spent: 2),
      ),
      0,
    );
    expect(
      SrdSorcerousRestorationRules.previewRecoverablePoints(
        _hero(used: 1),
      ),
      0,
    );
    expect(
      SrdSorcerousRestorationRules.previewRecoverablePoints(
        _hero(spent: 0),
      ),
      0,
    );
  });

  test('invalid snapshots remain unknown without mutation', () {
    for (final hero in [
      _hero(spent: -1),
      _hero(spent: 6),
      _hero(used: -1),
      _hero(used: 2),
      _hero(hp: null),
      _hero(hp: 0),
      _hero().copyWith(className: 'Unbekannt'),
    ]) {
      final original = hero.toJson();
      expect(
        SrdSorcerousRestorationRules.previewRecoverablePoints(hero),
        isNull,
      );
      expect(hero.toJson(), original);
    }
  });

  test('preview and confirmed rest agree without consuming preview', () {
    final hero = _hero();
    final original = hero.toJson();
    final preview =
        SrdSorcerousRestorationRules.previewRecoverablePoints(hero);
    final confirmed =
        SrdSorcerousRestorationRules.restoreAfterCompletedShortRest(hero);
    expect(preview, confirmed.recoveredPoints);
    expect(hero.toJson(), original);
    expect(confirmed.hero.spentClassResources['sorceryPoints'], 2);
  });
}
