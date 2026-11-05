import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_bard_font_of_inspiration.dart';

HeroCharacter _bard({
  String primary = 'Barde',
  String secondary = '',
  int level = 5,
  int secondaryLevel = 0,
}) => HeroCharacter(
  id: 'font-class-profile',
  name: 'Inspiration',
  className: primary,
  secondaryClassName: secondary,
  level: level,
  secondaryClassLevel: secondaryLevel,
  hitPoints: 12,
  maxHitPoints: 12,
  abilities: const {
    'strength': 10,
    'dexterity': 12,
    'constitution': 12,
    'intelligence': 10,
    'wisdom': 12,
    'charisma': 16,
  },
  spentClassResources: const {'bardicInspiration': 1},
);

void main() {
  group('Quelle der Inspiration: Klassenprofil vor Zauberplatzumwandlung', () {
    test('ungültige Klassen-Snapshots dürfen keinen Platz umwandeln', () {
      final invalid = <HeroCharacter>[
        _bard(primary: 'Unbekannt'),
        _bard(
          primary: 'Unbekannt',
          secondary: 'Barde',
          level: 7,
          secondaryLevel: 5,
        ),
        _bard(
          primary: 'Barde',
          secondary: 'Unbekannt',
          level: 7,
          secondaryLevel: 2,
        ),
        _bard(
          primary: 'Barde',
          secondary: 'Bard',
          level: 10,
          secondaryLevel: 5,
        ),
        _bard(
          primary: 'Bardin',
          secondary: 'Barde',
          level: 10,
          secondaryLevel: 5,
        ),
        _bard(secondary: 'Magier', level: 7),
        _bard(secondaryLevel: 1),
        _bard(
          primary: 'Magier',
          secondary: 'Barde',
          level: 5,
          secondaryLevel: 5,
        ),
        _bard(
          primary: 'Barde',
          secondary: 'Magier',
          level: 7,
          secondaryLevel: 7,
        ),
        _bard(level: 21),
        _bard(level: 0),
        _bard(secondaryLevel: -1),
      ];
      for (final hero in invalid) {
        final before = hero.toJson();
        expect(
          () => SrdBardFontOfInspirationRules.propose(hero: hero, slotLevel: 1),
          throwsFormatException,
        );
        final fabricated = SrdBardFontProposal(
          sourceSnapshot: jsonEncode(before),
          slotLevel: 1,
          usePactSlot: false,
        );
        expect(() => fabricated.applyTo(hero), throwsFormatException);
        expect(hero.toJson(), before);
      }
    });

    test('deutsche und englische Aliase und Mehrklassen bleiben nutzbar', () {
      final valid = <HeroCharacter>[
        _bard(primary: 'Bard'),
        _bard(primary: 'Bardin'),
        _bard(
          primary: 'Barde',
          secondary: 'Fighter',
          level: 7,
          secondaryLevel: 2,
        ),
        _bard(
          primary: 'Fighter',
          secondary: 'Bard',
          level: 7,
          secondaryLevel: 5,
        ),
        _bard(
          primary: 'Barde',
          secondary: 'Wizard',
          level: 7,
          secondaryLevel: 2,
        ),
      ];
      for (final hero in valid) {
        final before = hero.toJson();
        final proposal = SrdBardFontOfInspirationRules.propose(
          hero: hero,
          slotLevel: 1,
        );
        final after = proposal.applyTo(hero);
        expect(after.spentClassResources['bardicInspiration'], isNull);
        expect(after.spentSpellSlots['1'], 1);
        expect(hero.toJson(), before);
        expect(HeroCharacter.fromJson(after.toJson()).toJson(), after.toJson());
        expect(() => proposal.applyTo(after), throwsFormatException);
      }
    });

    test('gültige Bardenstufe 4 bleibt regulär gesperrt', () {
      final early = _bard(level: 4);
      final before = early.toJson();
      expect(
        () => SrdBardFontOfInspirationRules.propose(hero: early, slotLevel: 1),
        throwsStateError,
      );
      expect(early.toJson(), before);
    });

    test('veraltete Wahl weist neue Klassenkonstellation zurück', () {
      final original = _bard();
      final proposal = SrdBardFontOfInspirationRules.propose(
        hero: original,
        slotLevel: 1,
      );
      final changed = original.copyWith(
        secondaryClassName: 'Bard',
        secondaryClassLevel: 1,
      );
      final before = changed.toJson();
      expect(() => proposal.applyTo(changed), throwsFormatException);
      expect(changed.toJson(), before);
    });
  });
}
