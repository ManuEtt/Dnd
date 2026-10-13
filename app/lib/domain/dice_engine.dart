import 'dart:math';

/// A roll keeps its natural die separate from its modified total.
/// A manually entered total has no natural die and never adds a bonus again.
class DiceResult {
  DiceResult({
    required this.expression,
    required List<int> rolls,
    required this.modifier,
    required this.total,
    this.natural,
  }) : rolls = List<int>.unmodifiable(rolls);

  final String expression;
  final List<int> rolls;
  final int modifier;
  final int total;
  final int? natural;

  Map<String, dynamic> toJson() => {
    'expression': expression,
    'rolls': rolls,
    'modifier': modifier,
    'total': total,
    'natural': natural,
  };
}

/// Small, deterministic dice service. Inject Random for reproducible tests.
class DiceEngine {
  DiceEngine({Random? random}) : _random = random ?? Random.secure();

  static const supportedSides = {4, 6, 8, 10, 12, 20, 100};
  static const maxDice = 100;
  static const maxModifier = 1000;
  final Random _random;

  DiceResult roll(String expression) {
    if (expression.length > 50) {
      throw const FormatException('Der Würfelausdruck ist zu lang.');
    }
    final match = RegExp(
      r'^\s*(\d{1,3})[dDwW](\d{1,3})\s*([+-]\s*\d{1,4})?\s*$',
    ).firstMatch(expression);
    if (match == null) {
      throw const FormatException('Bitte Würfel als 1W20+2 angeben.');
    }
    final count = int.parse(match.group(1)!);
    final sides = int.parse(match.group(2)!);
    final modifier = match.group(3) == null
        ? 0
        : int.parse(match.group(3)!.replaceAll(RegExp(r'\s'), ''));
    if (count < 1 || count > maxDice || !supportedSides.contains(sides)) {
      throw const FormatException('Anzahl oder Würfeltyp ist ungültig.');
    }
    _validateModifier(modifier);
    final rolls = List<int>.generate(count, (_) => _random.nextInt(sides) + 1);
    return DiceResult(
      expression:
          '$count'
          'd$sides${_suffix(modifier)}',
      rolls: rolls,
      natural: count == 1 && sides == 20 ? rolls.single : null,
      modifier: modifier,
      total: rolls.fold<int>(0, (sum, die) => sum + die) + modifier,
    );
  }

  DiceResult check({
    required int modifier,
    int? natural,
    int? total,
    bool advantage = false,
    bool disadvantage = false,
  }) {
    _validateModifier(modifier);
    if (natural != null && total != null) {
      throw ArgumentError('Entweder Naturwurf oder Gesamtergebnis eingeben.');
    }
    if (total != null) {
      if (total < -maxModifier || total > maxModifier + 20) {
        throw RangeError.range(total, -maxModifier, maxModifier + 20, 'total');
      }
      return DiceResult(
        expression: 'Manuelles Gesamtergebnis',
        rolls: const [],
        modifier: 0,
        total: total,
      );
    }
    if (natural != null) {
      if (natural < 1 || natural > 20) {
        throw RangeError.range(natural, 1, 20, 'natural');
      }
      return DiceResult(
        expression: 'Manueller W20${_suffix(modifier)}',
        rolls: [natural],
        modifier: modifier,
        total: natural + modifier,
        natural: natural,
      );
    }
    // Advantage and disadvantage cancel, regardless of their sources.
    final rolls = List<int>.generate(
      advantage != disadvantage ? 2 : 1,
      (_) => _random.nextInt(20) + 1,
    );
    final chosen = rolls.length == 1
        ? rolls.single
        : advantage
        ? max(rolls[0], rolls[1])
        : min(rolls[0], rolls[1]);
    return DiceResult(
      expression: '1d20${_suffix(modifier)}',
      rolls: rolls,
      modifier: modifier,
      total: chosen + modifier,
      natural: chosen,
    );
  }

  static void _validateModifier(int modifier) {
    if (modifier < -maxModifier || modifier > maxModifier) {
      throw RangeError.range(modifier, -maxModifier, maxModifier, 'modifier');
    }
  }

  static String _suffix(int modifier) => modifier == 0
      ? ''
      : modifier > 0
      ? '+$modifier'
      : '$modifier';
}
