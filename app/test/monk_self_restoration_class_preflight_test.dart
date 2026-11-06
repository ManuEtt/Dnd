import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/monk_self_restoration.dart';

HeroCharacter _monk({
  String primary = 'Mönch',
  String secondary = '',
  int secondLevel = 0,
  int level = 10,
  List<String> conditions = const ['vergiftet'],
}) => HeroCharacter(
  id: 'self-restoration-preflight',
  name: 'Liora',
  className: primary,
  secondaryClassName: secondary,
  secondaryClassLevel: secondLevel,
  level: level,
  hitPoints: 25,
  maxHitPoints: 25,
  conditions: conditions,
);

void main() {
  group('SRD 5.2.1 Monk 10: confirmed class-profile preflight', () {
    test('single class and English/ASCII aliases still work', () {
      for (final name in ['Mönch', 'Monk', 'moench']) {
        final hero = _monk(primary: name);
        expect(MonkSelfRestoration.unlocked(hero), isTrue);
        expect(MonkSelfRestoration.choices(hero), ['vergiftet']);
        expect(
          () => MonkSelfRestoration.validateChoice(hero, 'vergiftet'),
          returnsNormally,
        );
        final result = MonkSelfRestoration.atEndOfTurn(hero);
        expect(result.removed, 'vergiftet');
        expect(result.hero.conditions, isEmpty);
        expect(hero.conditions, ['vergiftet']);
      }
    });

    test('valid multiclass uses Monk levels, not total character level', () {
      for (final hero in [
        _monk(
          primary: 'Fighter',
          secondary: 'Monk',
          level: 12,
          secondLevel: 10,
        ),
        _monk(
          primary: 'moench',
          secondary: 'Kämpfer',
          level: 12,
          secondLevel: 2,
        ),
      ]) {
        expect(MonkSelfRestoration.unlocked(hero), isTrue);
        expect(MonkSelfRestoration.atEndOfTurn(hero).removed, 'vergiftet');
      }
      final below = _monk(
        primary: 'Kämpfer',
        secondary: 'Mönch',
        level: 19,
        secondLevel: 9,
      );
      expect(MonkSelfRestoration.unlocked(below), isFalse);
      expect(MonkSelfRestoration.atEndOfTurn(below).removed, isEmpty);
    });

    test('unknown or duplicate classes cannot unlock automatic healing', () {
      final invalid = <HeroCharacter>[
        _monk(
          primary: 'Drachenritter',
          secondary: 'Mönch',
          level: 12,
          secondLevel: 10,
        ),
        _monk(
          primary: 'Mönch',
          secondary: 'Drachenritter',
          level: 12,
          secondLevel: 2,
        ),
        _monk(primary: 'Mönch', secondary: 'Monk', level: 20, secondLevel: 10),
        _monk(primary: 'Mönch', secondary: 'Kämpfer', level: 10),
        _monk(primary: 'Mönch', level: 12, secondLevel: 2),
        _monk(
          primary: 'Kämpfer',
          secondary: 'Mönch',
          level: 10,
          secondLevel: 10,
        ),
        _monk(level: 0),
        _monk(level: 21),
        _monk(level: 10, secondLevel: -1),
        _monk(
          primary: 'Kämpfer',
          secondary: 'Mönch',
          level: 20,
          secondLevel: 21,
        ),
      ];
      for (final hero in invalid) {
        final before = hero.toJson();
        expect(
          MonkSelfRestoration.unlocked(hero),
          isFalse,
          reason: hero.classSummary,
        );
        expect(
          MonkSelfRestoration.choices(hero),
          isEmpty,
          reason: hero.classSummary,
        );
        expect(
          () => MonkSelfRestoration.validateChoice(hero, 'vergiftet'),
          throwsStateError,
        );
        final result = MonkSelfRestoration.atEndOfTurn(
          hero,
          choice: 'vergiftet',
        );
        expect(
          identical(result.hero, hero),
          isTrue,
          reason: hero.classSummary,
        );
        expect(result.removed, isEmpty);
        expect(result.choiceRequired, isFalse);
        expect(hero.toJson(), before);
      }
    });

    test('valid multi-condition choice still requires player confirmation', () {
      final hero = _monk(conditions: ['bezaubert', 'vergiftet', 'blind']);
      final pending = MonkSelfRestoration.atEndOfTurn(hero);
      expect(pending.choiceRequired, isTrue);
      expect(identical(pending.hero, hero), isTrue);
      final chosen = MonkSelfRestoration.atEndOfTurn(
        hero,
        choice: 'bezaubert',
      );
      expect(chosen.removed, 'bezaubert');
      expect(chosen.hero.conditions, ['vergiftet', 'blind']);
      expect(hero.conditions, ['bezaubert', 'vergiftet', 'blind']);
    });
  });
}
