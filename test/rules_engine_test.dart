import 'package:aetheria/domain/models.dart';
import 'package:aetheria/domain/rules_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('5e modifiers include negative odd ability scores', () {
    expect(RulesEngine.modifier(7), -2);
    expect(RulesEngine.modifier(8), -1);
    expect(RulesEngine.modifier(10), 0);
    expect(RulesEngine.modifier(16), 3);
  });

  test('proficiency increases at levels 5, 9, 13, 17', () {
    expect(RulesEngine.proficiencyBonus(1), 2);
    expect(RulesEngine.proficiencyBonus(5), 3);
    expect(RulesEngine.proficiencyBonus(9), 4);
    expect(RulesEngine.proficiencyBonus(13), 5);
    expect(RulesEngine.proficiencyBonus(17), 6);
  });

  test('natural die and total are distinct', () {
    final result = RulesEngine.rollCheck(SequenceDice([16]), sides: 20, modifier: 3);
    expect(result.natural, 16);
    expect(result.total, 19);
  });

  test('manual roll applies exactly one modifier', () {
    final result = RulesEngine.manualCheck(10, modifier: 3);
    expect(result.total, 13);
  });

  test('out-of-bounds natural rolls are rejected', () {
    expect(() => RulesEngine.manualCheck(0), throwsRangeError);
    expect(() => RulesEngine.manualCheck(21), throwsRangeError);
    expect(() => RulesEngine.rollCheck(SequenceDice([21]), sides: 20), throwsRangeError);
  });

  test('Arescan has no confirmed dexterity', () {
    const arescan = CharacterSheet(
      id: 'arescan', name: 'Arescan', species: 'Mensch', characterClass: 'Waldläufer',
    );
    expect(RulesEngine.dexterityModifier(arescan), isNull);
    expect(arescan.isComplete, isFalse);
  });

  test('damage cannot produce negative hit points', () {
    expect(RulesEngine.applyDamage(7, 14), 0);
    expect(() => RulesEngine.applyDamage(7, -1), throwsRangeError);
  });
}
