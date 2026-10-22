import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/condition_effects.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

HeroCharacter _caster() => HeroCharacter(
  id: 'ward-caster',
  name: 'Liora',
  level: 3,
  hitPoints: 18,
  maxHitPoints: 18,
  concentratingOn: 'Schutzzauber',
);

ConditionEffect _effect(String id, String condition) => ConditionEffect(
  id: id,
  condition: condition,
  source: 'Bestätigte Falle',
);

void main() {
  for (final condition in [
    'gelähmt',
    'handlungsunfähig',
    'betäubt',
    'versteinert',
    'bewusstlos',
  ]) {
    test('$condition unterbricht Konzentration atomar', () {
      final original = _caster();
      final updated = ConditionEffectRules.add(
        original,
        _effect('effect-$condition', condition),
      );
      expect(original.concentratingOn, 'Schutzzauber');
      expect(updated.concentratingOn, isEmpty);
      expect(updated.conditionEffects, hasLength(1));
      expect(updated.conditions, contains(condition));
      expect(HeroCharacter.fromJson(updated.toJson()).concentratingOn, isEmpty);
      if (condition == 'bewusstlos') {
        expect(updated.conditions, contains('liegend'));
      }
    });
  }

  for (final condition in ['vergiftet', 'liegend', 'blind']) {
    test('$condition beendet die Konzentration nicht', () {
      final updated = ConditionEffectRules.add(
        _caster(),
        _effect('effect-$condition', condition),
      );
      expect(updated.concentratingOn, 'Schutzzauber');
      expect(updated.conditionEffects.single.condition, condition);
    });
  }

  test('nur die bestätigte eigene Zuggrenze beendet eine befristete Quelle', () {
    final caster = _caster();
    final updated = ConditionEffectRules.add(
      caster,
      ConditionEffect(
        id: 'poison',
        condition: 'vergiftet',
        source: 'Giftwolke',
        expiresInEncounterId: 'encounter-a',
        expiresAtOwnTurnEndRound: 4,
      ),
    );
    expect(
      ConditionEffectRules.expireAtOwnTurnEnd(
        updated,
        encounterId: 'encounter-b',
        round: 99,
      ).conditionEffects,
      hasLength(1),
    );
    expect(
      ConditionEffectRules.expireAtOwnTurnEnd(
        updated,
        encounterId: 'encounter-a',
        round: 3,
      ).conditionEffects,
      hasLength(1),
    );
    final expired = ConditionEffectRules.expireAtOwnTurnEnd(
      updated,
      encounterId: 'encounter-a',
      round: 4,
    );
    expect(expired.conditionEffects, isEmpty);
    expect(expired.concentratingOn, 'Schutzzauber');
    expect(updated.conditionEffects, hasLength(1));
  });

  test('Doppelte Quellen-ID verändert Konzentration nicht', () {
    final first = ConditionEffectRules.add(
      _caster(),
      _effect('same', 'vergiftet'),
    );
    expect(
      () => ConditionEffectRules.add(first, _effect('same', 'gelähmt')),
      throwsStateError,
    );
    expect(first.concentratingOn, 'Schutzzauber');
    expect(first.conditionEffects.single.condition, 'vergiftet');
  });
}
