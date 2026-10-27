/// Versioned, immutable evidence of a player's *initial* SRD ability choice.
/// It never grants bonuses: combat mechanics read only confirmed hero.abilities.
/// SRD 5.2.1, Character Creation / Generate Your Scores and Backgrounds.
class StartingAbilityOrigin {
  StartingAbilityOrigin._({
    required this.method,
    required Map<String, int> baseScores,
    required this.background,
    required Map<String, int> increases,
    required List<List<int>> diceRolls,
  }) : baseScores = Map.unmodifiable(baseScores),
       increases = Map.unmodifiable(increases),
       diceRolls = List.unmodifiable(
         diceRolls.map((roll) => List<int>.unmodifiable(roll)),
       ) {
    _validate();
  }

  static const _abilities = <String>[
    'strength',
    'dexterity',
    'constitution',
    'intelligence',
    'wisdom',
    'charisma',
  ];
  static const _standard = <int>[15, 14, 13, 12, 10, 8];
  static const _prices = <int, int>{
    8: 0, 9: 1, 10: 2, 11: 3, 12: 4, 13: 5, 14: 7, 15: 9,
  };
  static const _backgrounds = <String, List<String>>{
    'Akolyth': ['intelligence', 'wisdom', 'charisma'],
    'Krimineller': ['dexterity', 'constitution', 'intelligence'],
    'Weiser': ['constitution', 'intelligence', 'wisdom'],
    'Soldat': ['strength', 'dexterity', 'constitution'],
  };

  /// Literal enum name: standardArray, pointBuy or randomRoll.
  final String method;
  final Map<String, int> baseScores;
  final String background;
  final Map<String, int> increases;
  final List<List<int>> diceRolls;

  Map<String, int> get startingScores => Map.unmodifiable({
    for (final key in _abilities) key: baseScores[key]! + (increases[key] ?? 0),
  });

  /// Strictly validates even imported data; never fabricates historical rolls.
  factory StartingAbilityOrigin.confirmed({
    required String method,
    required Map<String, int> baseScores,
    required String background,
    required Map<String, int> increases,
    List<List<int>> diceRolls = const [],
  }) => StartingAbilityOrigin._(
    method: method,
    baseScores: baseScores,
    background: background,
    increases: increases,
    diceRolls: diceRolls,
  );

  static Map<String, int> _readScores(Object? raw, String label) {
    if (raw is! Map ||
        raw.keys.any((key) => key is! String) ||
        raw.values.any((value) => value is! int)) {
      throw FormatException('$label muss gültige ganze Attributswerte enthalten.');
    }
    return Map<String, int>.from(raw);
  }

  factory StartingAbilityOrigin.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1 || json['method'] is! String ||
        json['background'] is! String) {
      throw const FormatException('Unbekannte Attribut-Herkunftsversion.');
    }
    final rolls = json['diceRolls'];
    if (rolls is! List || rolls.length > 6) {
      throw const FormatException('Ungültige W6-Wurfhistorie.');
    }
    final dice = <List<int>>[];
    for (final roll in rolls) {
      if (roll is! List || roll.length != 4 ||
          roll.any((value) => value is! int || value < 1 || value > 6)) {
        throw const FormatException('Ein Wurf benötigt vier gültige W6.');
      }
      dice.add(List<int>.from(roll));
    }
    return StartingAbilityOrigin.confirmed(
      method: json['method'] as String,
      baseScores: _readScores(json['baseScores'], 'Basisattribute'),
      background: json['background'] as String,
      increases: _readScores(json['increases'], 'Hintergrunderhöhungen'),
      diceRolls: dice,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'method': method,
    'baseScores': baseScores,
    'background': background,
    'increases': increases,
    'diceRolls': diceRolls,
  };

  void _validate() {
    if (baseScores.length != _abilities.length ||
        baseScores.keys.any((key) => !_abilities.contains(key)) ||
        baseScores.values.any((value) => value < 1 || value > 20)) {
      throw const FormatException('Die Basisattribute sind unvollständig.');
    }
    switch (method) {
      case 'standardArray':
        final actual = baseScores.values.toList()..sort();
        final expected = _standard.toList()..sort();
        if (!_same(actual, expected) || diceRolls.isNotEmpty) {
          throw const FormatException('Ungültiger Standardsatz oder Wurfbeleg.');
        }
      case 'pointBuy':
        if (diceRolls.isNotEmpty ||
            baseScores.values.any((value) => !_prices.containsKey(value)) ||
            baseScores.values.fold<int>(
              0, (sum, value) => sum + (_prices[value] ?? 100),
            ) > 27) {
          throw const FormatException('Ungültiger 27-Punkte-Kauf.');
        }
      case 'randomRoll':
        if (diceRolls.length != 6 ||
            diceRolls.any((roll) =>
              roll.length != 4 ||
              roll.any((die) => die < 1 || die > 6))) {
          throw const FormatException('Es fehlen sechs gültige 4W6-Würfe.');
        }
        final actual = baseScores.values.toList()..sort();
        final expected = diceRolls.map((roll) {
          final sorted = roll.toList()..sort();
          return sorted.skip(1).fold<int>(0, (sum, die) => sum + die);
        }).toList()..sort();
        if (!_same(actual, expected)) {
          throw const FormatException('Attributwerte passen nicht zu den Würfen.');
        }
      default:
        throw const FormatException('Unbekannte Methode zur Attributerzeugung.');
    }

    final eligible = _backgrounds[background];
    if (eligible == null ||
        increases.keys.any((key) => !eligible.contains(key))) {
      throw const FormatException('Ungültiger SRD-Hintergrund.');
    }
    final values = increases.values.toList()..sort();
    if (!(_same(values, [1, 2]) || _same(values, [1, 1, 1])) ||
        (values.length == 3 && increases.length != 3)) {
      throw const FormatException('Ungültige Hintergrund-Attributserhöhung.');
    }
    if (_abilities.any(
      (key) => baseScores[key]! + (increases[key] ?? 0) > 20,
    )) {
      throw const FormatException('Attribut über 20 durch Hintergrund.');
    }
  }

  static bool _same(List<int> a, List<int> b) =>
      a.length == b.length &&
      List.generate(a.length, (i) => i).every((i) => a[i] == b[i]);
}
