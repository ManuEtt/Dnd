import 'dart:math';

import 'models.dart';

abstract class DiceSource {
  int roll(int sides);
}

class RandomDice implements DiceSource {
  RandomDice([Random? random]) : _random = random ?? Random.secure();
  final Random _random;
  @override
  int roll(int sides) {
    if (sides < 2) throw ArgumentError.value(sides, 'sides');
    return _random.nextInt(sides) + 1;
  }
}

class SequenceDice implements DiceSource {
  SequenceDice(this.sequence);
  final List<int> sequence;
  int _next = 0;
  @override
  int roll(int sides) {
    if (_next >= sequence.length) throw StateError('Keine Testwürfel mehr');
    final value = sequence[_next++];
    if (value < 1 || value > sides) throw RangeError.range(value, 1, sides);
    return value;
  }
}

class DiceResult {
  const DiceResult(this.natural, this.modifier);
  final int natural;
  final int modifier;
  int get total => natural + modifier;
}

class RulesEngine {
  static const supportedDice = [4, 6, 8, 10, 12, 20, 100];
  static int modifier(int abilityScore) => ((abilityScore - 10) / 2).floor();
  static int proficiencyBonus(int level) {
    if (level < 1 || level > 20) throw RangeError.range(level, 1, 20);
    return 2 + ((level - 1) ~/ 4);
  }
  static DiceResult rollCheck(DiceSource dice, {required int sides, int modifier = 0}) {
    if (!supportedDice.contains(sides)) throw ArgumentError('Würfel nicht unterstützt');
    return DiceResult(dice.roll(sides), modifier);
  }
  static DiceResult manualCheck(int natural, {int sides = 20, int modifier = 0}) {
    if (!supportedDice.contains(sides) || natural < 1 || natural > sides) {
      throw RangeError('Ungültiges natürliches Würfelergebnis');
    }
    return DiceResult(natural, modifier);
  }
  static int? dexterityModifier(CharacterSheet character) {
    final dex = character.dexterity;
    return dex == null ? null : modifier(dex);
  }

  static int applyDamage(int currentHp, int damage) {
    if (currentHp < 0 || damage < 0) throw RangeError('TP und Schaden müssen >= 0 sein');
    return max(0, currentHp - damage);
  }
}
