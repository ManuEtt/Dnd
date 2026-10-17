import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/healing_spell_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/spellcasting_rules.dart';

class HealingRandom implements Random {
  HealingRandom({this.high = false});

  final bool high;
  int calls = 0;
  final sides = <int>[];

  @override
  int nextInt(int max) {
    calls++;
    sides.add(max);
    return high ? max - 1 : 0;
  }

  @override
  bool nextBool() => high;

  @override
  double nextDouble() => high ? 0.999 : 0;
}

HeroCharacter healer({String className = 'Kleriker', int level = 5}) =>
    HeroCharacter(
      id: 'healer',
      name: 'Neria',
      className: className,
      level: level,
      abilities: const {
        'strength': 14,
        'dexterity': 14,
        'constitution': 14,
        'intelligence': 14,
        'wisdom': 16,
        'charisma': 18,
      },
      hitPoints: 5,
      maxHitPoints: 200,
      armorClass: 14,
      speed: 9,
      weaponDamage: '1d6',
      spells: const ['Wunden heilen', 'Heilendes Wort'],
    );

HealingSpellResult cast(
  HeroCharacter hero, {
  DiceEngine? dice,
  String spell = 'Wunden heilen',
  String castingClass = 'Kleriker',
  int? slotLevel,
  bool pactMagic = false,
  bool verbal = true,
  bool somatic = true,
}) => HealingSpellRules.castSelf(
  hero,
  dice: dice ?? DiceEngine(random: HealingRandom()),
  spellName: spell,
  castingClass: castingClass,
  slotLevel: slotLevel,
  pactMagic: pactMagic,
  verbalComponentConfirmed: verbal,
  somaticComponentConfirmed: somatic,
);

void main() {
  // Official SRD 5.2.1 pp. 25–26, 40, 105–106, 121, 139.
  // These tests deliberately use 2024's TWO dice, not the 2014 versions.
  group('SRD 5.2.1 ausführbare Selbstheilung', () {
    test('Wunden heilen würfelt 2W8 und addiert Weisheit genau einmal', () {
      final random = HealingRandom(high: true);
      final before = healer();
      final result = cast(before, dice: DiceEngine(random: random));

      expect(result.roll.rolls, [8, 8]);
      expect(random.sides, [8, 8]);
      expect(result.roll.modifier, 3);
      expect(result.roll.total, 19);
      expect(result.roll.natural, isNull);
      expect(result.recovered, 19);
      expect(result.hero.hitPoints, 24);
      expect(result.hero.spentSpellSlots, {'1': 1});
      expect(result.spellcastingAbility, 'wisdom');
      expect(result.actionType, 'action');
      expect(result.slotLevel, 1);
      expect(result.pactMagic, isFalse);
      expect(before.hitPoints, 5);
      expect(before.spentSpellSlots, isEmpty);
    });

    test('Heilendes Wort benötigt nur verbal und heilt mit 2W4', () {
      final random = HealingRandom(high: true);
      final result = cast(
        healer(className: 'Barde'),
        dice: DiceEngine(random: random),
        spell: 'Heilendes Wort',
        castingClass: 'Barde',
        somatic: false,
      );

      expect(random.sides, [4, 4]);
      expect(result.roll.total, 12);
      expect(result.spellcastingAbility, 'charisma');
      expect(result.actionType, 'bonusAction');
    });

    test('Höhere Plätze skalieren um zwei Würfel je zusätzlichem Grad', () {
      final cure = cast(healer(), slotLevel: 3);
      expect(cure.roll.rolls, List.filled(6, 1));
      expect(cure.roll.total, 9);
      expect(cure.hero.spentSpellSlots, {'3': 1});

      final word = cast(healer(), spell: 'Heilendes Wort', slotLevel: 2);
      expect(word.roll.rolls, List.filled(4, 1));
      expect(word.roll.total, 7);
      expect(word.hero.spentSpellSlots, {'2': 1});
    });

    test(
      'Alle fünf zulässigen Klassen erhalten ihr eigenes Zauberattribut',
      () {
        for (final entry in {
          'Barde': 'charisma',
          'Kleriker': 'wisdom',
          'Druide': 'wisdom',
          'Paladin': 'charisma',
          'Waldläufer': 'wisdom',
        }.entries) {
          final result = cast(
            healer(className: entry.key, level: 1),
            castingClass: entry.key,
          );
          expect(result.spellcastingAbility, entry.value, reason: entry.key);
          expect(result.hero.spentSpellSlots, {'1': 1}, reason: entry.key);
        }
      },
    );

    test('Klassenaliasse werden nur zur Berechnung normalisiert', () {
      final before = healer(className: 'Cleric');
      expect(
        HealingSpellRules.castingClasses(
          before,
          HealingSpellRules.find('Wunden heilen')!,
        ),
        ['Kleriker'],
      );
      final result = cast(before, castingClass: 'Klerikerin');
      expect(result.castingClass, 'Kleriker');
      expect(result.hero.className, 'Cleric');
      expect(result.hero.spentSpellSlots, {'1': 1});
    });

    test(
      'Deutsche und englische Zaubernamen verweisen auf dieselbe Vorbereitung',
      () {
        final english = healer().copyWith(
          spells: ['Cure Wounds', 'Healing Word'],
        );
        expect(HealingSpellRules.availableSpells(english).map((s) => s.name), [
          'Wunden heilen',
          'Heilendes Wort',
        ]);
        final localized = cast(english);
        expect(localized.spellName, 'Wunden heilen');
        expect(localized.hero.spells, ['Cure Wounds', 'Healing Word']);
        expect(cast(healer(), spell: 'Cure Wounds').recovered, 5);
        expect(cast(english, spell: ' Heilendes Wort ').recovered, 5);
        expect(HealingSpellRules.find('Unbekannter Zauber'), isNull);
      },
    );

    test(
      'Heilung wird bei maximalen TP gedeckelt, Platz dennoch verbraucht',
      () {
        final before = healer().copyWith(hitPoints: 199);
        final result = cast(before);
        expect(result.roll.total, 5);
        expect(result.recovered, 1);
        expect(result.hero.hitPoints, 200);
        expect(result.hero.spentSpellSlots, {'1': 1});
        final full = cast(result.hero);
        expect(full.recovered, 0);
        expect(full.hero.spentSpellSlots, {'1': 2});
      },
    );

    test('Negativer Zauberattributmodifikator verursacht keinen Schaden', () {
      final before = healer().copyWith(abilities: {'wisdom': 1});
      final result = cast(before);
      expect(result.roll.modifier, -5);
      expect(result.roll.total, -3);
      expect(result.recovered, 0);
      expect(result.hero.hitPoints, before.hitPoints);
      expect(result.hero.spentSpellSlots, {'1': 1});
    });

    test('Konzentration und temporäre TP bleiben bei Heilung erhalten', () {
      final result = cast(
        healer().copyWith(
          temporaryHitPoints: 10,
          concentratingOn: 'Segen',
          conditions: ['vergiftet'],
        ),
      );
      expect(result.hero.temporaryHitPoints, 10);
      expect(result.hero.concentratingOn, 'Segen');
      expect(result.hero.conditions, ['vergiftet']);
      final reloaded = HeroCharacter.fromJson(result.hero.toJson());
      expect(reloaded.hitPoints, result.hero.hitPoints);
      expect(reloaded.spentSpellSlots, {'1': 1});
      expect(reloaded.concentratingOn, 'Segen');
    });

    test(
      'Bekannter Name allein erteilt weder Klassenliste noch Zaubervorbereitung',
      () {
        final random = HealingRandom();
        final dice = DiceEngine(random: random);
        expect(
          () => cast(healer().copyWith(spells: []), dice: dice),
          throwsFormatException,
        );
        expect(
          () => cast(healer(), spell: 'Segen', dice: dice),
          throwsFormatException,
        );
        expect(
          () => cast(
            healer(className: 'Magier'),
            castingClass: 'Magier',
            dice: dice,
          ),
          throwsFormatException,
        );
        expect(
          () => cast(
            healer(className: 'Paladin'),
            spell: 'Heilendes Wort',
            castingClass: 'Paladin',
            dice: dice,
          ),
          throwsFormatException,
        );
        expect(
          () => cast(healer(), castingClass: 'Druide', dice: dice),
          throwsFormatException,
        );
        expect(
          HealingSpellRules.availableSpells(healer(className: 'Magier')),
          isEmpty,
        );
        expect(random.calls, 0);
      },
    );

    test(
      'Fehlende oder ungültige bestätigte Werte werden vor Würfeln abgewiesen',
      () {
        final random = HealingRandom();
        final dice = DiceEngine(random: random);
        for (final abilities in <Map<String, int?>>[
          {},
          {'wisdom': null},
          {'wisdom': 0},
          {'wisdom': 31},
        ]) {
          expect(
            () => cast(healer().copyWith(abilities: abilities), dice: dice),
            throwsStateError,
          );
        }
        for (final before in [
          HeroCharacter(
            id: 'incomplete',
            name: 'Unvollständig',
            className: 'Kleriker',
            abilities: {'wisdom': 16},
            spells: ['Wunden heilen'],
          ),
          healer().copyWith(hitPoints: 0),
          healer().copyWith(hitPoints: -1),
          healer().copyWith(maxHitPoints: 0),
          healer().copyWith(hitPoints: 201),
          healer().copyWith(conditions: ['tot']),
          healer().copyWith(exhaustionLevel: 6),
        ]) {
          expect(() => cast(before, dice: dice), throwsStateError);
        }
        expect(random.calls, 0);
      },
    );

    test(
      'Komponenten müssen bestätigt sein; Taubheit blockiert verbal nicht',
      () {
        final random = HealingRandom();
        final dice = DiceEngine(random: random);
        expect(
          () => cast(healer(), verbal: false, dice: dice),
          throwsStateError,
        );
        expect(
          () => cast(healer(), somatic: false, dice: dice),
          throwsStateError,
        );
        expect(
          () => cast(
            healer(),
            spell: 'Heilendes Wort',
            verbal: false,
            dice: dice,
          ),
          throwsStateError,
        );
        expect(random.calls, 0);
        expect(cast(healer().copyWith(conditions: ['taub'])).recovered, 5);
      },
    );

    test(
      'Heilendes Wort verlangt Sicht; Berührungsheilung ist blind möglich',
      () {
        final random = HealingRandom();
        final dice = DiceEngine(random: random);
        for (final condition in ['blind', 'unsichtbar']) {
          expect(
            () => cast(
              healer().copyWith(conditions: [condition]),
              spell: 'Heilendes Wort',
              dice: dice,
            ),
            throwsStateError,
          );
        }
        expect(random.calls, 0);
        expect(cast(healer().copyWith(conditions: ['blind'])).recovered, 5);
      },
    );

    test(
      'Handlungsunfähigkeit und ungeübte Rüstung blockieren beide Zauber',
      () {
        final random = HealingRandom();
        final dice = DiceEngine(random: random);
        final blocked = [
          for (final condition in [
            'bewusstlos',
            'handlungsunfähig',
            'gelähmt',
            'versteinert',
            'betäubt',
          ])
            healer().copyWith(conditions: [condition]),
          healer().copyWith(
            equippedArmorId: 'armor',
            equippedArmorTrained: false,
          ),
          healer().copyWith(
            equippedShieldId: 'shield',
            equippedShieldTrained: false,
          ),
        ];
        for (final hero in blocked) {
          for (final name in ['Wunden heilen', 'Heilendes Wort']) {
            expect(() => cast(hero, spell: name, dice: dice), throwsStateError);
          }
        }
        expect(random.calls, 0);
        expect(
          cast(
            healer().copyWith(
              equippedArmorId: 'armor',
              equippedArmorTrained: true,
            ),
          ).recovered,
          5,
        );
      },
    );

    test(
      'Ausgeschöpfte, zu niedrige oder nicht vorhandene Plätze werden abgewiesen',
      () {
        final random = HealingRandom();
        final dice = DiceEngine(random: random);
        expect(
          () => cast(healer().copyWith(spentSpellSlots: {'1': 4}), dice: dice),
          throwsStateError,
        );
        for (final level in [-1, 0, 4, 10]) {
          expect(
            () => cast(healer(), slotLevel: level, dice: dice),
            throwsStateError,
          );
        }
        expect(
          () => cast(healer(), pactMagic: true, dice: dice),
          throwsStateError,
        );
        expect(random.calls, 0);
      },
    );

    test(
      'Manipulierte Klassenstufen und Ressourcenkarten werden abgewiesen',
      () {
        final random = HealingRandom();
        final dice = DiceEngine(random: random);
        for (final hero in [
          healer(level: 0),
          healer(level: 21),
          healer().copyWith(className: 'Unbekannt'),
          healer().copyWith(secondaryClassLevel: 1),
          healer().copyWith(
            secondaryClassName: 'Druide',
            secondaryClassLevel: 0,
          ),
          healer().copyWith(
            secondaryClassName: 'Cleric',
            secondaryClassLevel: 1,
          ),
          healer().copyWith(
            secondaryClassName: 'Magier',
            secondaryClassLevel: 5,
          ),
          healer().copyWith(
            secondaryClassName: 'Unbekannt',
            secondaryClassLevel: 1,
          ),
          healer().copyWith(spentSpellSlots: {'01': 0}),
          healer().copyWith(spentSpellSlots: {'0': 1}),
          healer().copyWith(spentSpellSlots: {'1': -1}),
          healer().copyWith(spentSpellSlots: {'1': 5}),
          healer().copyWith(spentSpellSlots: {'4': 1}),
          healer().copyWith(spentPactSlots: 1),
          healer().copyWith(spentPactSlots: -1),
        ]) {
          expect(() => cast(hero, dice: dice), throwsFormatException);
        }
        expect(random.calls, 0);
      },
    );
  });

  group('SRD 5.2.1 Mehrklassen-Heilzauber', () {
    test(
      'Klassenstufe bestimmt Vorbereitung, gemeinsamer Pool erlaubt Hochstufen',
      () {
        final before = healer(level: 6).copyWith(
          className: 'Magier',
          secondaryClassName: 'Kleriker',
          secondaryClassLevel: 1,
        );
        expect(
          HealingSpellRules.maximumPreparedSpellLevel(before, 'Kleriker'),
          1,
        );
        expect(
          HealingSpellRules.maximumPreparedSpellLevel(before, 'Magier'),
          3,
        );
        expect(
          HealingSpellRules.maximumPreparedSpellLevel(before, 'Druide'),
          0,
        );
        final result = cast(before, slotLevel: 3);
        expect(result.roll.rolls, List.filled(6, 1));
        expect(result.roll.modifier, 3);
        expect(result.hero.spentSpellSlots, {'3': 1});
        expect(result.hero.secondaryClassLevel, 1);
      },
    );

    test('Halbzauberer verwenden ihre eigene Vorbereitungstabelle', () {
      const expected = {
        1: 1,
        4: 1,
        5: 2,
        8: 2,
        9: 3,
        12: 3,
        13: 4,
        16: 4,
        17: 5,
        20: 5,
      };
      for (final name in ['Paladin', 'Waldläufer']) {
        for (final entry in expected.entries) {
          expect(
            HealingSpellRules.maximumPreparedSpellLevel(
              healer(className: name, level: entry.key),
              name,
            ),
            entry.value,
            reason: '$name ${entry.key}',
          );
        }
      }
    });

    test(
      'Wahl zwischen zwei heilkundigen Klassen benutzt deren eigenes Attribut',
      () {
        final before = healer(
          className: 'Barde',
          level: 6,
        ).copyWith(secondaryClassName: 'Kleriker', secondaryClassLevel: 1);
        expect(
          HealingSpellRules.castingClasses(
            before,
            HealingSpellRules.find('Wunden heilen')!,
          ),
          ['Barde', 'Kleriker'],
        );
        expect(cast(before, castingClass: 'Barde').roll.total, 6);
        expect(cast(before, castingClass: 'Kleriker').roll.total, 5);
      },
    );

    test(
      'Paktplätze können vorbereiteten Klerikerzauber wirken und skalieren',
      () {
        final before = healer(
          level: 6,
        ).copyWith(secondaryClassName: 'Warlock', secondaryClassLevel: 5);
        final result = cast(before, pactMagic: true);
        expect(result.slotLevel, 3);
        expect(result.pactMagic, isTrue);
        expect(result.roll.rolls, List.filled(6, 1));
        expect(result.hero.spentPactSlots, 1);
        expect(result.hero.spentSpellSlots, isEmpty);
        expect(result.hero.secondaryClassName, 'Warlock');
        expect(HeroCharacter.fromJson(result.hero.toJson()).spentPactSlots, 1);
        expect(SpellcastingRules.availableSlots(result.hero), {1: 2});

        final random = HealingRandom();
        final dice = DiceEngine(random: random);
        expect(
          () => cast(before, pactMagic: true, slotLevel: 2, dice: dice),
          throwsFormatException,
        );
        expect(
          () => cast(
            before.copyWith(spentPactSlots: 2),
            pactMagic: true,
            dice: dice,
          ),
          throwsStateError,
        );
        expect(
          () => cast(
            before,
            pactMagic: true,
            castingClass: 'Hexenmeister',
            dice: dice,
          ),
          throwsFormatException,
        );
        expect(random.calls, 0);
      },
    );
  });

  group('SRD 5.2.1 Lebensdomäne bei Selbstheilung', () {
    test(
      'Lebensdomänenbonus gilt auch für eigene andere Zauberklassen und Paktplätze',
      () {
        final bardCleric = healer(level: 4).copyWith(
          secondaryClassName: 'Barde',
          secondaryClassLevel: 1,
          subclass: 'Life Domain',
        );
        final bardSpell = cast(bardCleric, castingClass: 'Barde');
        expect(bardSpell.spellcastingAbility, 'charisma');
        expect(bardSpell.discipleOfLifeBonus, 3);
        expect(bardSpell.recovered, 9);

        final pactCleric = healer(level: 8).copyWith(
          secondaryClassName: 'Hexenmeister',
          secondaryClassLevel: 5,
          subclass: 'Life Domain',
        );
        final pactSpell = cast(pactCleric, pactMagic: true);
        expect(pactSpell.slotLevel, 3);
        expect(pactSpell.discipleOfLifeBonus, 5);
        expect(pactSpell.recovered, 14);
        expect(pactSpell.hero.spentPactSlots, 1);
        expect(pactSpell.hero.spentSpellSlots, isEmpty);
      },
    );

    test(
      'Jünger des Lebens addiert 2 plus tatsächlich verbrauchten Platzgrad',
      () {
        for (final subclass in [
          'Life Domain',
          'Domäne des Lebens',
          'Lebensdomäne',
        ]) {
          final before = healer(level: 3).copyWith(subclass: subclass);
          final result = cast(before, slotLevel: 2);
          expect(result.discipleOfLifeBonus, 4);
          expect(result.roll.modifier, 7);
          expect(result.roll.total, 11);
          expect(result.recovered, 11);
          expect(result.maximizedHealing, isFalse);
        }
      },
    );

    test(
      'Gesegneter Heiler gewährt bei Selbstheilung keine zweite Heilung',
      () {
        final before = healer(
          level: 6,
        ).copyWith(subclass: 'Life Domain', features: ['Blessed Healer']);
        final result = cast(before, spell: 'Heilendes Wort');
        expect(result.discipleOfLifeBonus, 3);
        expect(result.roll.total, 8);
        expect(result.recovered, 8);
      },
    );

    test(
      'Höchste Heilung ab Kleriker 17 ersetzt Würfel ohne Zufallsverbrauch',
      () {
        final random = HealingRandom();
        final before = healer(level: 17).copyWith(subclass: 'Life Domain');
        final result = cast(
          before,
          slotLevel: 9,
          dice: DiceEngine(random: random),
        );
        expect(result.maximizedHealing, isTrue);
        expect(result.discipleOfLifeBonus, 11);
        expect(result.roll.rolls, List.filled(18, 8));
        expect(result.roll.total, 158);
        expect(result.recovered, 158);
        expect(result.hero.spentSpellSlots, {'9': 1});
        expect(random.calls, 0);

        final word = cast(
          before,
          spell: 'Heilendes Wort',
          dice: DiceEngine(random: random),
        );
        expect(word.roll.rolls, [4, 4]);
        expect(word.recovered, 14);
        expect(random.calls, 0);
      },
    );

    test('Gesamtstufe schaltet keine höheren Klerikermerkmale frei', () {
      final random = HealingRandom();
      final before = healer(level: 18).copyWith(
        secondaryClassName: 'Magier',
        secondaryClassLevel: 2,
        subclass: 'Life Domain',
      );
      final result = cast(
        before,
        slotLevel: 9,
        dice: DiceEngine(random: random),
      );
      expect(result.maximizedHealing, isFalse);
      expect(result.discipleOfLifeBonus, 11);
      expect(result.recovered, 32);
      expect(random.calls, 18);
    });

    test(
      'Zweitklasse und Freitextmerkmale erteilen keine Lebensdomänenboni',
      () {
        final random = HealingRandom();
        final dice = DiceEngine(random: random);
        for (final before in [
          healer(level: 2).copyWith(subclass: 'Life Domain'),
          healer().copyWith(features: ['Disciple of Life']),
          healer().copyWith(features: ['Jünger des Lebens']),
          healer(
            level: 3,
          ).copyWith(subclass: 'Life Domain', features: ['Supreme Healing']),
          healer(
            level: 5,
          ).copyWith(subclass: 'Life Domain', features: ['Blessed Healer']),
          healer(level: 10).copyWith(
            className: 'Magier',
            secondaryClassName: 'Kleriker',
            secondaryClassLevel: 9,
            subclass: 'Life Domain',
          ),
        ]) {
          expect(() => cast(before, dice: dice), throwsStateError);
        }
        expect(random.calls, 0);
        final ordinary = cast(healer().copyWith(subclass: 'Unbekannte Domäne'));
        expect(ordinary.discipleOfLifeBonus, 0);
        expect(ordinary.maximizedHealing, isFalse);
      },
    );
  });
}
