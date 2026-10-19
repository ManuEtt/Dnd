import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/condition_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_starting_combat_values.dart';

void main() {
  test('Acht bekannte SRD-Spezies mit 30 Fuß erhalten 9 Meter', () {
    for (final name in [
      'Mensch',
      'Zwerg',
      'Elf',
      'Gnom',
      'Halbling',
      'Drachenblütiger',
      'Orc',
      'Tiefling',
    ]) {
      expect(SrdStartingCombatValues.speedDecimeters(name), 90, reason: name);
    }
    expect(SrdStartingCombatValues.speedDecimeters('Goliath'), 105);
    expect(SrdStartingCombatValues.speedDecimeters('Waldelf'), 105);
    expect(SrdStartingCombatValues.speedDecimeters('Wood Elf'), 105);
    expect(
      SrdStartingCombatValues.speedDecimeters('frei erfundene Spezies'),
      isNull,
    );
  });

  test('Start-RK folgt bestätigten Attributen und Klassenmerkmalen', () {
    expect(
      SrdStartingCombatValues.unarmoredArmorClass(
        className: 'Waldläufer',
        dexterity: 16,
      ),
      13,
    );
    expect(
      SrdStartingCombatValues.unarmoredArmorClass(
        className: 'Barbar',
        dexterity: 14,
        constitution: 16,
      ),
      15,
    );
    expect(
      SrdStartingCombatValues.unarmoredArmorClass(
        className: 'Mönch',
        dexterity: 16,
        wisdom: 14,
      ),
      15,
    );
    expect(
      SrdStartingCombatValues.unarmoredArmorClass(
        className: 'Mönch',
        dexterity: 16,
      ),
      isNull,
    );
    expect(
      SrdStartingCombatValues.unarmoredArmorClass(
        className: 'Waldläufer',
        dexterity: null,
      ),
      isNull,
    );
  });

  test('Goliath-Geschwindigkeit 10,5 m bleibt beim Speichern exakt', () {
    final dm = SrdStartingCombatValues.parseSpeedDecimeters('10,5');
    expect(dm, 105);
    expect(SrdStartingCombatValues.formatSpeedDecimeters(dm), '10,5');
    final hero = HeroCharacter(
      id: 'goliath',
      name: 'Skara',
      species: 'Goliath',
      speed: dm ~/ 10,
      speedRemainderDecimeters: dm % 10,
    );
    expect(hero.baseSpeedMeters, 10.5);
    expect(ExhaustionRules.effectiveSpeedMeters(hero), 10.5);
    expect(
      ExhaustionRules.effectiveSpeedMeters(hero.copyWith(exhaustionLevel: 1)),
      9.0,
    );
    final json = hero.toJson();
    expect(json['speed'], 10);
    expect(json['speedRemainderDecimeters'], 5);
    expect(HeroCharacter.fromJson(json).toJson(), json);
  });

  test(
    'Alt-Spielstand ohne Bruchteil bleibt unverändert und unbekannt bleibt null',
    () {
      final old = HeroCharacter(
        id: 'legacy',
        name: 'Altfigur',
        speed: 9,
      ).toJson();
      expect(old.containsKey('speedRemainderDecimeters'), isFalse);
      expect(HeroCharacter.fromJson(old).toJson(), old);
      final unknown = HeroCharacter(id: 'unknown', name: 'Unbekannt');
      expect(unknown.baseSpeedMeters, isNull);
      expect(HeroCharacter.fromJson(unknown.toJson()).baseSpeedMeters, isNull);
    },
  );

  test('Manipulierte Werte werden zurückgewiesen', () {
    for (final raw in ['10.25', '0', '201', 'zehn']) {
      expect(
        () => SrdStartingCombatValues.parseSpeedDecimeters(raw),
        throwsFormatException,
        reason: raw,
      );
    }
    final base = HeroCharacter(id: 'test', name: 'Test', speed: 10).toJson();
    for (final remainder in [1, 2, 3, 4, 6, -1, '5']) {
      expect(
        () => HeroCharacter.fromJson({
          ...base,
          'speedRemainderDecimeters': remainder,
        }),
        throwsFormatException,
        reason: '$remainder',
      );
    }
  });
}
