import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/class_resource_rules.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rest_rules.dart';
import 'package:lebendiger_spielleiter/domain/spellcasting_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_warlock_magical_cunning_rules.dart';

HeroCharacter warlock({
  int classLevel = 11,
  int spentSlots = 3,
  int spentUses = 0,
  bool multiclass = false,
  bool fighter = false,
  int hp = 20,
}) => HeroCharacter(
  id: 'warlock-test',
  name: 'Mira',
  className: multiclass || fighter ? 'Kämpfer' : 'Hexenmeister',
  secondaryClassName: multiclass ? 'Hexenmeister' : '',
  secondaryClassLevel: multiclass ? classLevel : 0,
  level: classLevel + (multiclass ? 2 : 0),
  hitPoints: hp,
  maxHitPoints: 30,
  armorClass: 13,
  speed: 9,
  weaponDamage: '1d8',
  abilities: const {
    'strength': 10, 'dexterity': 14, 'constitution': 14,
    'intelligence': 12, 'wisdom': 12, 'charisma': 16,
  },
  spentPactSlots: spentSlots,
  spentClassResources: {
    if (spentUses > 0) SrdWarlockMagicalCunningRules.resourceKey: spentUses,
  },
);

void main() {
  group('SRD 5.2.1: Hexenmeister Magical Cunning', () {
    test('Klassenstufe 2 ist Pflicht, nicht Gesamtstufe', () {
      expect(SrdWarlockMagicalCunningRules.maximumUses(warlock()), 1);
      expect(
        SrdWarlockMagicalCunningRules.maximumUses(
          warlock(classLevel: 1, spentSlots: 1),
        ),
        0,
      );
      expect(
        SrdWarlockMagicalCunningRules.maximumUses(
          warlock(fighter: true, spentSlots: 0),
        ),
        0,
      );
      expect(
        () => SrdWarlockMagicalCunningRules.restoreAfterCompletedRite(
          warlock(classLevel: 1, spentSlots: 1),
        ),
        throwsStateError,
      );
    });

    test('Halbe Paktplätze aufgerundet; Stufe 20 volle Erholung', () {
      for (final entry in <(int, int, int)>[
        (2, 2, 1), (10, 2, 1), (11, 3, 2), (16, 3, 2),
        (17, 4, 2), (19, 4, 2), (20, 4, 4),
      ]) {
        final hero = warlock(classLevel: entry.$1, spentSlots: entry.$2);
        expect(
          SrdWarlockMagicalCunningRules.maximumRecoveredSlots(hero),
          entry.$3,
        );
      }
    });

    test('Zwei von drei Paktplätzen regenerieren, Rohzustand erhalten', () {
      final hero = warlock();
      final before = hero.toJson();
      final result = SrdWarlockMagicalCunningRules.restoreAfterCompletedRite(
        hero,
      );
      expect(result.recoveredSlots, 2);
      expect(result.spentPactSlotsBefore, 3);
      expect(result.spentPactSlotsAfter, 1);
      expect(result.usesRemaining, 0);
      expect(result.eldritchMaster, false);
      expect(SpellcastingRules.availablePactSlots(result.hero), 2);
      expect(
        result.hero.spentClassResources[
          SrdWarlockMagicalCunningRules.resourceKey
        ],
        1,
      );
      expect(hero.toJson(), before);
      expect(
        HeroCharacter.fromJson(result.hero.toJson()).toJson(),
        result.hero.toJson(),
      );
    });

    test('Mit nur einem verbrauchten Platz höchstens einen wiedergeben', () {
      final result = SrdWarlockMagicalCunningRules.restoreAfterCompletedRite(
        warlock(spentSlots: 1),
      );
      expect(result.recoveredSlots, 1);
      expect(result.hero.spentPactSlots, 0);
    });

    test('Eldritch Master Hexenmeister 20 regeneriert alle vier Plätze', () {
      final result = SrdWarlockMagicalCunningRules.restoreAfterCompletedRite(
        warlock(classLevel: 20, spentSlots: 4),
      );
      expect(result.recoveredSlots, 4);
      expect(result.spentPactSlotsAfter, 0);
      expect(result.eldritchMaster, true);
    });

    test('Mehrklasse erbt keine fremden Gesamtstufen', () {
      final hero = warlock(multiclass: true);
      expect(hero.level, 13);
      expect(
        SrdWarlockMagicalCunningRules.restoreAfterCompletedRite(
          hero,
        ).recoveredSlots,
        2,
      );
      expect(
        () => SrdWarlockMagicalCunningRules.restoreAfterCompletedRite(
          warlock(multiclass: true, classLevel: 1, spentSlots: 1),
        ),
        throwsStateError,
      );
    });

    test('Ohne verbrauchte Plätze kein Verbrauch der Fähigkeit', () {
      final hero = warlock(spentSlots: 0);
      final old = hero.toJson();
      expect(
        () => SrdWarlockMagicalCunningRules.restoreAfterCompletedRite(hero),
        throwsStateError,
      );
      expect(hero.toJson(), old);
    });

    test('Einmal pro langer Rast, nicht pro kurzer Rast', () {
      final first = SrdWarlockMagicalCunningRules.restoreAfterCompletedRite(
        warlock(),
      );
      expect(
        ClassResourceRules.afterShortRest(first.hero).spentClassResources[
          SrdWarlockMagicalCunningRules.resourceKey
        ],
        1,
      );
      expect(
        () => SrdWarlockMagicalCunningRules.restoreAfterCompletedRite(
          first.hero,
        ),
        throwsStateError,
      );
      final rested = RestRules.longRest(first.hero);
      expect(rested.spentPactSlots, 0);
      expect(
        ClassResourceRules.remaining(
          rested,
          SrdWarlockMagicalCunningRules.resourceKey,
        ),
        1,
      );
    });

    test('Manipulierte Slot- und Nutzungszahlen scheitern', () {
      expect(
        () => SrdWarlockMagicalCunningRules.restoreAfterCompletedRite(
          warlock(spentSlots: 4),
        ),
        throwsFormatException,
      );
      final manipulated = warlock(spentUses: 2);
      expect(
        () => HeroCharacter.fromJson(manipulated.toJson()),
        throwsFormatException,
      );
      expect(
        () => SrdWarlockMagicalCunningRules.restoreAfterCompletedRite(
          manipulated,
        ),
        throwsFormatException,
      );
    });

    test('Bei Null Trefferpunkten kein Ritual', () {
      expect(
        () => SrdWarlockMagicalCunningRules.restoreAfterCompletedRite(
          warlock(hp: 0),
        ),
        throwsStateError,
      );
    });

    test('Bestätigter Befehl speichert Slots und einmaligen Ereignistyp', () {
      final engine = GameEngine(clock: () => DateTime.utc(2026, 10, 28));
      final original = engine.createDemo();
      final start = original.copyWith(
        hero: warlock().copyWith(id: original.hero.id),
      );
      final used = engine.act(start, 'Magische List: Ritual abgeschlossen');
      expect(used.events.single.type, 'class.magicalCunning');
      expect(used.events.single.payload['oneMinuteRiteConfirmed'], true);
      expect(used.events.single.payload['recoveredSlots'], 2);
      expect(used.campaign.hero.spentPactSlots, 1);
      final restored = Campaign.fromJson(used.campaign.toJson());
      final twice = engine.act(restored, 'Magische List: Ritual abgeschlossen');
      expect(twice.events.single.type, 'rules.blocked');
      expect(twice.campaign.hero.spentPactSlots, 1);
    });

    test('Unbestätigter Befehl und laufender Kampf werden blockiert', () {
      final engine = GameEngine(clock: () => DateTime.utc(2026, 10, 28));
      final base = engine.createDemo();
      final start = base.copyWith(
        hero: warlock().copyWith(id: base.hero.id),
      );
      final wrong = engine.act(start, 'Magische List: jetzt');
      expect(wrong.events.single.type, 'rules.blocked');
      expect(wrong.campaign.hero.spentPactSlots, 3);
      final combat = engine.act(start, 'Ich gehe zum Waldschrein.').campaign;
      expect(combat.encounter, isNotNull);
      final denied = engine.act(combat, 'Magische List: Ritual abgeschlossen');
      expect(denied.events.single.type, 'rules.blocked');
      expect(denied.campaign.hero.spentPactSlots, 3);
      expect(denied.campaign.hero.spentClassResources, isEmpty);
    });
  });
}
