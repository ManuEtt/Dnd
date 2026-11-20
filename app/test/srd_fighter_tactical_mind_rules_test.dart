import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/class_feature_resources.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/rules/rules_api.dart';

class _CountingRandom implements Random {
  _CountingRandom(this.natural);

  final int natural;
  final bounds = <int>[];

  @override
  int nextInt(int max) {
    bounds.add(max);
    return natural - 1;
  }

  @override
  bool nextBool() => throw UnsupportedError('Only the d10 is expected.');

  @override
  double nextDouble() => throw UnsupportedError('Only the d10 is expected.');
}

HeroCharacter _fighter({
  String primary = 'Kämpfer',
  String secondary = '',
  int secondaryLevel = 0,
  int level = 2,
  int spentWind = 0,
}) => HeroCharacter(
  id: 'tactical-mind-hero',
  name: 'Liora',
  className: primary,
  secondaryClassName: secondary,
  secondaryClassLevel: secondaryLevel,
  level: level,
  hitPoints: 10,
  maxHitPoints: 30,
  temporaryHitPoints: 5,
  spentSecondWind: spentWind,
  abilities: const {
    'strength': 14,
    'dexterity': 14,
    'constitution': 14,
    'intelligence': 14,
    'wisdom': 12,
    'charisma': 10,
  },
);

PendingRoll _check({
  String id = 'tactical-check',
  String type = 'preparedCheck',
  int modifier = 2,
  int difficulty = 15,
  int minimumNatural = 0,
  bool advantage = false,
  bool disadvantage = false,
  String expression = '1d20',
  String weaponId = '',
}) => PendingRoll(
  id: id,
  type: type,
  targetId: 'confirmed-check-target',
  targetName: 'dexterity|stealth',
  modifier: modifier,
  difficulty: difficulty,
  minimumNatural: minimumNatural,
  advantage: advantage,
  disadvantage: disadvantage,
  expression: expression,
  weaponId: weaponId,
);

DiceResult _roll({int natural = 8, int modifier = 2}) => DiceResult(
  expression: modifier == 0
      ? '1d20'
      : modifier > 0
      ? '1d20+$modifier'
      : '1d20$modifier',
  rolls: [natural],
  modifier: modifier,
  total: natural + modifier,
  natural: natural,
);

SrdFighterTacticalMindDecision _prepare(
  HeroCharacter hero, {
  PendingRoll? check,
  DiceResult? failedRoll,
  Set<String> attempted = const {},
}) => SrdFighterTacticalMindRules.prepare(
  hero: hero,
  check: check ?? _check(),
  failedRoll: failedRoll ?? _roll(),
  previouslyAttemptedCheckIds: attempted,
);

Matcher get _rejected => throwsA(
  anyOf(isA<FormatException>(), isA<StateError>(), isA<ArgumentError>()),
);

void main() {
  group('Tactical Mind: tatsächlich ausgewertete Attributsprobe', () {
    for (final entry in [
      (natural: 4, total: 14, passed: false, spent: 0),
      (natural: 5, total: 15, passed: true, spent: 1),
      (natural: 10, total: 20, passed: true, spent: 1),
    ]) {
      test('W10 ${entry.natural}: Erfolg und tatsächlicher Verbrauch', () {
        final hero = _fighter();
        final before = hero.toJson();
        final check = _check();
        final original = _roll();
        final decision = _prepare(hero, check: check, failedRoll: original);
        final random = _CountingRandom(entry.natural);
        final result = SrdFighterTacticalMindRules.resolve(
          hero: hero,
          decision: decision,
          dice: DiceEngine(random: random),
          playerConfirmed: true,
          previouslyAttemptedCheckIds: const {},
        );

        expect(random.bounds, [10]);
        expect(result.checkId, check.id);
        expect(result.originalRoll.toJson(), original.toJson());
        expect(result.bonusRoll.rolls, [entry.natural]);
        expect(result.bonusRoll.modifier, 0);
        expect(result.originalEffectiveTotal, 10);
        expect(result.total, entry.total);
        expect(result.difficulty, 15);
        expect(result.passed, entry.passed);
        expect(result.secondWindSpent, entry.spent);
        expect(result.hero.spentSecondWind, entry.spent);
        expect(result.attemptedCheckIds, {check.id});
        expect(result.hero.hitPoints, 10);
        expect(result.hero.temporaryHitPoints, 5);
        expect(hero.toJson(), before);
      });
    }

    test('Unerreichbarer SG würfelt trotzdem und erhält die Nutzung', () {
      final hero = _fighter();
      final decision = _prepare(hero, check: _check(difficulty: 100));
      final random = _CountingRandom(10);
      final result = SrdFighterTacticalMindRules.resolve(
        hero: hero,
        decision: decision,
        dice: DiceEngine(random: random),
        playerConfirmed: true,
        previouslyAttemptedCheckIds: const {},
      );
      expect(random.bounds, [10]);
      expect(result.total, 20);
      expect(result.passed, false);
      expect(result.secondWindSpent, 0);
      expect(result.hero.toJson(), hero.toJson());
      expect(result.attemptedCheckIds, {'tactical-check'});
    });

    test('Hohe Kämpferstufe wird nicht zum W10 addiert', () {
      final hero = _fighter(level: 20, spentWind: 3);
      final result = SrdFighterTacticalMindRules.resolve(
        hero: hero,
        decision: _prepare(hero),
        dice: DiceEngine(random: _CountingRandom(5)),
        playerConfirmed: true,
        previouslyAttemptedCheckIds: const {},
      );
      expect(result.total, 15);
      expect(result.hero.spentSecondWind, 4);
      expect(ClassFeatureResources.remainingSecondWind(result.hero), 0);
      expect(result.hero.hitPoints, hero.hitPoints);
    });

    for (final alias in ['Kämpfer', 'Fighter', ' fighter ']) {
      test('Bestätigter Klassenalias $alias', () {
        final hero = _fighter(primary: alias);
        final result = SrdFighterTacticalMindRules.resolve(
          hero: hero,
          decision: _prepare(hero),
          dice: DiceEngine(random: _CountingRandom(5)),
          playerConfirmed: true,
          previouslyAttemptedCheckIds: const {},
        );
        expect(result.passed, true);
        expect(result.hero.spentSecondWind, 1);
      });
    }

    for (final fighterSecond in [false, true]) {
      test('Mehrklasse: Kämpfer als ${fighterSecond ? 2 : 1}. Klasse', () {
        final hero = _fighter(
          primary: fighterSecond ? 'Barbar' : 'Fighter',
          secondary: fighterSecond ? 'Fighter' : 'Barbar',
          secondaryLevel: 2,
          level: 4,
        ).copyWith(
          spentActionSurge: 1,
          spentClassResources: {'rage': 1},
        );
        final before = hero.toJson();
        final result = SrdFighterTacticalMindRules.resolve(
          hero: hero,
          decision: _prepare(hero),
          dice: DiceEngine(random: _CountingRandom(5)),
          playerConfirmed: true,
          previouslyAttemptedCheckIds: const {},
        );
        expect(result.hero.spentSecondWind, 1);
        expect(result.hero.spentActionSurge, 1);
        expect(result.hero.spentClassResources, {'rage': 1});
        expect(result.hero.hitPoints, 10);
        expect(hero.toJson(), before);
      });
    }

    for (final type in ['preparedCheck', 'perception', 'escape']) {
      test('Bestätigter fehlgeschlagener Probentyp $type', () {
        final hero = _fighter();
        final check = _check(type: type);
        final result = SrdFighterTacticalMindRules.resolve(
          hero: hero,
          decision: _prepare(hero, check: check),
          dice: DiceEngine(random: _CountingRandom(5)),
          playerConfirmed: true,
          previouslyAttemptedCheckIds: const {},
        );
        expect(result.checkId, check.id);
        expect(result.passed, true);
      });
    }

    test('Manuelles Gesamtergebnis erhält den Modifikator nicht erneut', () {
      final hero = _fighter();
      final manual = DiceResult(
        expression: 'Manuelles Gesamtergebnis',
        rolls: const [],
        modifier: 0,
        total: 10,
      );
      final result = SrdFighterTacticalMindRules.resolve(
        hero: hero,
        decision: _prepare(hero, failedRoll: manual),
        dice: DiceEngine(random: _CountingRandom(5)),
        playerConfirmed: true,
        previouslyAttemptedCheckIds: const {},
      );
      expect(result.originalRoll.natural, isNull);
      expect(result.originalRoll.rolls, isEmpty);
      expect(result.originalEffectiveTotal, 10);
      expect(result.total, 15);
    });

    test('Verlässliches Talent bleibt vom tatsächlichen W20 getrennt', () {
      final hero = _fighter(
        secondary: 'Schurke',
        secondaryLevel: 7,
        level: 9,
      );
      final original = _roll(natural: 5);
      final decision = _prepare(
        hero,
        check: _check(minimumNatural: 10),
        failedRoll: original,
      );
      expect(decision.originalEffectiveTotal, 12);
      final result = SrdFighterTacticalMindRules.resolve(
        hero: hero,
        decision: decision,
        dice: DiceEngine(random: _CountingRandom(3)),
        playerConfirmed: true,
        previouslyAttemptedCheckIds: const {},
      );
      expect(result.originalRoll.natural, 5);
      expect(result.originalRoll.total, 7);
      expect(result.originalEffectiveTotal, 12);
      expect(result.total, 15);
      expect(result.passed, true);
    });

    for (final advantage in [true, false]) {
      test('Beide Originalwürfe mit ${advantage ? 'Vorteil' : 'Nachteil'} bleiben', () {
        final hero = _fighter();
        final natural = advantage ? 8 : 3;
        final original = DiceResult(
          expression: '1d20+2',
          rolls: [3, 8],
          modifier: 2,
          total: natural + 2,
          natural: natural,
        );
        final result = SrdFighterTacticalMindRules.resolve(
          hero: hero,
          decision: _prepare(
            hero,
            check: _check(advantage: advantage, disadvantage: !advantage),
            failedRoll: original,
          ),
          dice: DiceEngine(random: _CountingRandom(10)),
          playerConfirmed: true,
          previouslyAttemptedCheckIds: const {},
        );
        expect(result.originalRoll.rolls, [3, 8]);
        expect(result.originalRoll.natural, natural);
        expect(result.total, natural + 12);
      });
    }

    test('Natürliche Eins kann durch den Bonus noch Erfolg erzielen', () {
      final hero = _fighter();
      final result = SrdFighterTacticalMindRules.resolve(
        hero: hero,
        decision: _prepare(
          hero,
          check: _check(difficulty: 10),
          failedRoll: _roll(natural: 1),
        ),
        dice: DiceEngine(random: _CountingRandom(7)),
        playerConfirmed: true,
        previouslyAttemptedCheckIds: const {},
      );
      expect(result.total, 10);
      expect(result.passed, true);
    });

    test('Natürliche Zwanzig ist bei Attributsproben kein automatischer Erfolg', () {
      final hero = _fighter();
      final result = SrdFighterTacticalMindRules.resolve(
        hero: hero,
        decision: _prepare(
          hero,
          check: _check(difficulty: 30),
          failedRoll: _roll(natural: 20),
        ),
        dice: DiceEngine(random: _CountingRandom(8)),
        playerConfirmed: true,
        previouslyAttemptedCheckIds: const {},
      );
      expect(result.originalRoll.natural, 20);
      expect(result.total, 30);
      expect(result.passed, true);
    });

    test('Handlungsunfähigkeit allein führt keine zusätzliche Aktionsbarriere ein', () {
      final hero = _fighter().copyWith(conditions: ['handlungsunfähig']);
      final result = SrdFighterTacticalMindRules.resolve(
        hero: hero,
        decision: _prepare(hero),
        dice: DiceEngine(random: _CountingRandom(5)),
        playerConfirmed: true,
        previouslyAttemptedCheckIds: const {},
      );
      expect(result.passed, true);
      expect(result.hero.conditions, ['handlungsunfähig']);
    });
  });

  group('Tactical Mind: Ablehnung ohne Würfel oder Charakteränderung', () {
    test('Vorbereitung ist lesend; fehlende Zustimmung verbraucht keinen W10', () {
      final hero = _fighter();
      final before = hero.toJson();
      final ledger = <String>{'prior-check'};
      final decision = _prepare(hero, attempted: ledger);
      final random = _CountingRandom(10);
      expect(hero.toJson(), before);
      expect(ledger, {'prior-check'});
      expect(
        () => SrdFighterTacticalMindRules.resolve(
          hero: hero,
          decision: decision,
          dice: DiceEngine(random: random),
          playerConfirmed: false,
          previouslyAttemptedCheckIds: ledger,
        ),
        _rejected,
      );
      expect(random.bounds, isEmpty);
      expect(hero.toJson(), before);
      expect(ledger, {'prior-check'});
    });

    final invalidHeroes = <String, HeroCharacter>{
      'Kämpfer eins': _fighter(level: 1),
      'unbekannte Erstklasse': _fighter(primary: 'Unbekannt'),
      'unbekannte Zweitklasse': _fighter(
        secondary: 'Unbekannt',
        secondaryLevel: 1,
        level: 3,
      ),
      'doppelte Klassenaliase': _fighter(
        secondary: 'Fighter',
        secondaryLevel: 2,
        level: 4,
      ),
      'Gesamtstufe über zwanzig': _fighter(level: 21),
      'negative Zweitklassenstufe': _fighter(secondaryLevel: -1),
      'keine Erstklassenstufe': _fighter(
        secondary: 'Wizard',
        secondaryLevel: 2,
      ),
      'Zweitstufe ohne Klasse': _fighter(secondaryLevel: 1),
      'Zweitklasse ohne Stufe': _fighter(secondary: 'Wizard'),
      'negative Nutzungszahl': _fighter(spentWind: -1),
      'zu hoher Verbrauch': _fighter(spentWind: 3),
      'keine freie Nutzung': _fighter(spentWind: 2),
      'fehlende TP': _fighter().copyWith(hitPoints: null),
      'null TP': _fighter().copyWith(hitPoints: 0),
      'tot': _fighter().copyWith(conditions: ['tot']),
      'bewusstlos': _fighter().copyWith(conditions: ['bewusstlos']),
    };
    for (final entry in invalidHeroes.entries) {
      test('${entry.key}: kein neuer Versuch', () {
        final before = entry.value.toJson();
        expect(() => _prepare(entry.value), _rejected);
        expect(entry.value.toJson(), before);
      });
    }

    for (final type in [
      'attack',
      'offhandAttack',
      'death',
      'save',
      'initiative',
    ]) {
      test('Nicht unterstützter Probentyp $type', () {
        expect(
          () => _prepare(
            _fighter(),
            check: _check(
              type: type,
              weaponId: type == 'offhandAttack' ? 'offhand-weapon' : '',
            ),
          ),
          _rejected,
        );
      });
    }

    for (final check in [
      _check(id: ''),
      _check(difficulty: 0),
      _check(difficulty: 101),
      _check(modifier: 31),
      _check(minimumNatural: 9),
      _check(type: 'escape', minimumNatural: 10),
      _check(expression: '1d10'),
    ]) {
      test('Ungültiger Probenauftrag ${check.toJson()}', () {
        expect(() => _prepare(_fighter(), check: check), _rejected);
      });
    }

    test('Bereits gelungene Probe erlaubt keinen Bonus', () {
      expect(
        () => _prepare(_fighter(), check: _check(difficulty: 10)),
        _rejected,
      );
    });

    test('Verlässliches Talent wird vor der Fehlschlagprüfung berücksichtigt', () {
      final hero = _fighter(
        secondary: 'Schurke',
        secondaryLevel: 7,
        level: 9,
      );
      expect(
        () => _prepare(
          hero,
          check: _check(minimumNatural: 10, difficulty: 12),
          failedRoll: _roll(natural: 1),
        ),
        _rejected,
      );
    });

    final forgedRolls = <String, DiceResult>{
      'falsches Gesamtergebnis': DiceResult(
        expression: '1d20+2',
        rolls: const [8],
        modifier: 2,
        total: 9,
        natural: 8,
      ),
      'Naturwurf passt nicht zum Würfel': DiceResult(
        expression: '1d20+2',
        rolls: const [8],
        modifier: 2,
        total: 9,
        natural: 7,
      ),
      'Naturwurf außerhalb W20': _roll(natural: 0),
      'falscher Modifikator': _roll(modifier: 3),
      'zusätzlicher Würfel ohne Vorteil': DiceResult(
        expression: '1d20+2',
        rolls: const [3, 8],
        modifier: 2,
        total: 10,
        natural: 8,
      ),
      'fehlender Naturwurf mit Würfeln': DiceResult(
        expression: 'Manuelles Gesamtergebnis',
        rolls: const [8],
        modifier: 0,
        total: 10,
      ),
    };
    for (final entry in forgedRolls.entries) {
      test('Manipuliertes Ergebnis: ${entry.key}', () {
        expect(
          () => _prepare(_fighter(), failedRoll: entry.value),
          _rejected,
        );
      });
    }

    test('Falscher ausgewählter Vorteilswürfel ist kein bestätigter Wurf', () {
      final original = DiceResult(
        expression: '1d20+2',
        rolls: const [3, 8],
        modifier: 2,
        total: 5,
        natural: 3,
      );
      expect(
        () => _prepare(
          _fighter(),
          check: _check(advantage: true),
          failedRoll: original,
        ),
        _rejected,
      );
    });

    test('Veränderte Heldenwerte sperren eine alte Entscheidung vor dem W10', () {
      final source = _fighter();
      final decision = _prepare(source);
      final stale = source.copyWith(hitPoints: 9);
      final random = _CountingRandom(10);
      expect(
        () => SrdFighterTacticalMindRules.resolve(
          hero: stale,
          decision: decision,
          dice: DiceEngine(random: random),
          playerConfirmed: true,
          previouslyAttemptedCheckIds: const {},
        ),
        _rejected,
      );
      expect(random.bounds, isEmpty);
      expect(source.hitPoints, 10);
      expect(stale.hitPoints, 9);
      expect(stale.spentSecondWind, 0);
    });

    test('Andere Heldenidentität sperrt die vorbereitete Entscheidung', () {
      final source = _fighter();
      final decision = _prepare(source);
      final random = _CountingRandom(10);
      expect(
        () => SrdFighterTacticalMindRules.resolve(
          hero: source.copyWith(id: 'another-hero'),
          decision: decision,
          dice: DiceEngine(random: random),
          playerConfirmed: true,
          previouslyAttemptedCheckIds: const {},
        ),
        _rejected,
      );
      expect(random.bounds, isEmpty);
    });

    test('Schon protokollierte Probe kann nicht vorbereitet werden', () {
      expect(
        () => _prepare(_fighter(), attempted: {'tactical-check'}),
        _rejected,
      );
    });

    test('Auch kostenloser Fehlschlag ist nicht erneut würfelbar', () {
      final hero = _fighter();
      final decision = _prepare(hero);
      final random = _CountingRandom(1);
      final dice = DiceEngine(random: random);
      final result = SrdFighterTacticalMindRules.resolve(
        hero: hero,
        decision: decision,
        dice: dice,
        playerConfirmed: true,
        previouslyAttemptedCheckIds: const {},
      );
      expect(result.passed, false);
      expect(result.hero.toJson(), hero.toJson());
      expect(result.secondWindSpent, 0);
      expect(result.attemptedCheckIds, {'tactical-check'});
      expect(
        () => SrdFighterTacticalMindRules.resolve(
          hero: result.hero,
          decision: decision,
          dice: dice,
          playerConfirmed: true,
          previouslyAttemptedCheckIds: result.attemptedCheckIds,
        ),
        _rejected,
      );
      expect(random.bounds, [10]);
    });
  });

  group('Tactical Mind: unveränderlicher und serialisierbarer Nachweis', () {
    test('Eingabe-Ledger bleibt erhalten und Ausgabe ist nicht veränderbar', () {
      final hero = _fighter();
      final ledger = <String>{'older-check'};
      final decision = _prepare(hero, attempted: ledger);
      final result = SrdFighterTacticalMindRules.resolve(
        hero: hero,
        decision: decision,
        dice: DiceEngine(random: _CountingRandom(5)),
        playerConfirmed: true,
        previouslyAttemptedCheckIds: ledger,
      );
      expect(ledger, {'older-check'});
      expect(result.attemptedCheckIds, {'older-check', 'tactical-check'});
      expect(() => result.attemptedCheckIds.add('forged'), throwsUnsupportedError);
      expect(() => result.originalRoll.rolls.add(20), throwsUnsupportedError);
      expect(() => result.bonusRoll.rolls.add(10), throwsUnsupportedError);
      expect(() => result.hero.spentClassResources['rage'] = 1, throwsUnsupportedError);
    });

    test('JSON erhält Originalwurf, Bonuswurf, Verbrauch und Versuchskennung', () {
      final hero = _fighter();
      final original = _roll();
      final decision = _prepare(hero, failedRoll: original);
      final result = SrdFighterTacticalMindRules.resolve(
        hero: hero,
        decision: decision,
        dice: DiceEngine(random: _CountingRandom(5)),
        playerConfirmed: true,
        previouslyAttemptedCheckIds: const {},
      );
      final json = jsonDecode(jsonEncode(result.toJson())) as Map<String, dynamic>;
      expect(json['checkId'], 'tactical-check');
      expect(json['originalRoll'], original.toJson());
      expect(json['bonusRoll'], result.bonusRoll.toJson());
      expect(json['originalEffectiveTotal'], 10);
      expect(json['total'], 15);
      expect(json['difficulty'], 15);
      expect(json['passed'], true);
      expect(json['secondWindSpent'], 1);
      expect(json['feature'], 'Tactical Mind');
      expect(json.containsKey('attemptedCheckIds'), false);
      expect(json.containsKey('hero'), false);
      expect(HeroCharacter.fromJson(result.hero.toJson()).toJson(), result.hero.toJson());
      expect(hero.spentSecondWind, 0);
    });
  });
}
