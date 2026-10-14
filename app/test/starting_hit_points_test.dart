import 'package:flutter_test/flutter_test.dart';

import 'package:lebendiger_spielleiter/domain/starting_hit_points.dart';

void main() {
  group('SRD 5.2.1: Trefferpunkte auf Stufe 1', () {
    const classes = <String, int>{
      'Barbar': 12,
      'Barde': 8,
      'Kleriker': 8,
      'Druide': 8,
      'Kämpfer': 10,
      'Mönch': 8,
      'Paladin': 10,
      'Waldläufer': 10,
      'Schurke': 8,
      'Zauberer': 6,
      'Hexenmeister': 8,
      'Magier': 6,
    };

    for (final entry in classes.entries) {
      test('${entry.key}: Trefferwürfel W${entry.value}, KO 14 ergibt +2', () {
        final result = StartingHitPoints.propose(
          className: entry.key,
          constitutionScore: 14,
          characterLevel: 1,
        );
        expect(result.hitDie, entry.value);
        expect(result.constitutionModifier, 2);
        expect(result.maximum, entry.value + 2);
      });
    }

    test('D&D-englische Klassenbezeichnungen funktionieren ebenfalls', () {
      expect(
        StartingHitPoints.propose(
          className: '  FIGHTER ',
          constitutionScore: 12,
          characterLevel: 1,
        ).maximum,
        11,
      );
      expect(
        StartingHitPoints.propose(
          className: 'wizard',
          constitutionScore: 8,
          characterLevel: 1,
        ).maximum,
        5,
      );
    });

    test('negativer KO-Modifikator wird berücksichtigt', () {
      final result = StartingHitPoints.propose(
        className: 'Magier',
        constitutionScore: 7,
        characterLevel: 1,
      );
      expect(result.constitutionModifier, -2);
      expect(result.maximum, 4);
    });

    test('unterste Trefferpunktgrenze ist 1', () {
      expect(
        StartingHitPoints.propose(
          className: 'Wizard',
          constitutionScore: 1,
          characterLevel: 1,
        ).maximum,
        1,
      );
    });

    test('unbekannte Klasse erzeugt keinen erfundenen Vorschlag', () {
      expect(
        () => StartingHitPoints.propose(
          className: 'Ritter der Nacht',
          constitutionScore: 14,
          characterLevel: 1,
        ),
        throwsFormatException,
      );
    });

    test('unbekannte Konstitution bleibt ausdrücklich unbekannt', () {
      expect(
        () => StartingHitPoints.propose(
          className: 'Waldläufer',
          constitutionScore: null,
          characterLevel: 1,
        ),
        throwsFormatException,
      );
    });

    test('bestehende höhere Stufe darf nicht neu initialisiert werden', () {
      expect(
        () => StartingHitPoints.propose(
          className: 'Kämpfer',
          constitutionScore: 14,
          characterLevel: 2,
        ),
        throwsFormatException,
      );
    });

    test('unzulässige Konstitution wird nicht akzeptiert', () {
      expect(
        () => StartingHitPoints.propose(
          className: 'Kämpfer',
          constitutionScore: 31,
          characterLevel: 1,
        ),
        throwsRangeError,
      );
    });
  });
}
