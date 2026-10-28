import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_indomitable_might_rules.dart';

class _FixedRandom implements Random {
  const _FixedRandom(this.d20);
  final int d20;

  @override
  int nextInt(int max) => (d20 - 1) % max;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

HeroCharacter _barbarian(
  int barbarianLevel, {
  bool secondClass = false,
  int? strength = 18,
}) => HeroCharacter(
  id: 'indomitable-might-hero',
  name: 'Probe',
  className: secondClass ? 'Paladin' : 'Barbar',
  level: barbarianLevel + (secondClass ? 2 : 0),
  secondaryClassName: secondClass ? 'Barbar' : '',
  secondaryClassLevel: secondClass ? barbarianLevel : 0,
  abilities: {
    'strength': strength,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 10,
    'wisdom': 10,
    'charisma': 10,
  },
  savingThrowProficiencies: const ['strength'],
  hitPoints: 60,
  maxHitPoints: 60,
  armorClass: 15,
  speed: 9,
  weaponDamage: '1d12',
);

int _resolve(
  HeroCharacter hero,
  String ability,
  SrdD20CheckKind kind,
  int total,
) => SrdIndomitableMightRules.effectiveTotal(
  hero: hero,
  ability: ability,
  kind: kind,
  rolledTotal: total,
);

void main() {
  group('SRD 5.2.1 Barbar 18: Unbezwingbare Stärke', () {
    test('erst ab bestätigter Barbaren-Klassenstufe 18', () {
      final before = _barbarian(17);
      final after = _barbarian(18);
      expect(SrdIndomitableMightRules.isEligible(before), isFalse);
      expect(SrdIndomitableMightRules.isEligible(after), isTrue);
      expect(_resolve(before, 'strength', SrdD20CheckKind.abilityCheck, 5), 5);
      expect(_resolve(after, 'strength', SrdD20CheckKind.abilityCheck, 5), 18);
      expect(
        _resolve(after, 'strength', SrdD20CheckKind.savingThrow, 10),
        18,
      );
      expect(_resolve(after, 'strength', SrdD20CheckKind.abilityCheck, 22), 22);
      expect(_resolve(after, 'strength', SrdD20CheckKind.abilityCheck, 18), 18);
    });

    test('keine Wirkung auf Angriffe, Initiative, Todesrettung, GE oder KO', () {
      final hero = _barbarian(18);
      for (final kind in [
        SrdD20CheckKind.attack,
        SrdD20CheckKind.initiative,
        SrdD20CheckKind.deathSave,
      ]) {
        expect(_resolve(hero, 'strength', kind, 2), 2);
      }
      expect(_resolve(hero, 'dexterity', SrdD20CheckKind.abilityCheck, 2), 2);
      expect(_resolve(hero, 'constitution', SrdD20CheckKind.savingThrow, 2), 2);
    });

    test('Zweitklasse benötigt 18 Barbarenstufen, nicht Gesamtstufe', () {
      final valid = _barbarian(18, secondClass: true);
      final tooEarly = _barbarian(17, secondClass: true);
      expect(valid.level, 20);
      expect(_resolve(valid, 'strength', SrdD20CheckKind.savingThrow, 7), 18);
      expect(
        _resolve(tooEarly, 'strength', SrdD20CheckKind.savingThrow, 7),
        7,
      );
    });

    test('unbestätigte Stärke erzeugt keine erfundene Zahl', () {
      final hero = _barbarian(18, strength: null);
      expect(
        () => _resolve(hero, 'strength', SrdD20CheckKind.abilityCheck, 2),
        throwsStateError,
      );
      expect(_resolve(hero, 'wisdom', SrdD20CheckKind.abilityCheck, 2), 2);
      expect(
        _resolve(_barbarian(17, strength: null),
            'strength', SrdD20CheckKind.savingThrow, 2),
        2,
      );
    });

    test('Anwendung ist rein und verändert keinen gespeicherten Charakter', () {
      final hero = _barbarian(18);
      final original = hero.toJson();
      expect(_resolve(hero, 'strength', SrdD20CheckKind.savingThrow, 1), 18);
      expect(hero.toJson(), original);
      expect(HeroCharacter.fromJson(original).toJson(), original);
    });

    test('manueller Stärke-Rettungswurf nutzt nur den effektiven Gesamtwert', () {
      final engine = GameEngine(
        dice: DiceEngine(random: _FixedRandom(1)),
        clock: () => DateTime.utc(2026, 10, 28),
      );
      final demo = engine.createDemo();
      final campaign = demo.copyWith(
        hero: _barbarian(18).copyWith(id: demo.hero.id),
      );
      final result = engine.act(campaign, 'Rettungswurf: Stärke SG 17');
      expect(result.events.single.type, 'saving.roll');
      expect(result.events.single.payload['total'], 18);
      expect(result.events.single.payload['rawTotal'], 11);
      expect(result.events.single.payload['classFeature'], 'indomitableMight');
      expect(result.events.single.payload['failed'], isFalse);
      expect(
        Campaign.fromJson(result.campaign.toJson()).hero.toJson(),
        campaign.hero.toJson(),
      );
      final noFeature = engine.act(
        demo.copyWith(hero: _barbarian(17).copyWith(id: demo.hero.id)),
        'Rettungswurf: Stärke SG 17',
      );
      expect(noFeature.events.single.payload['failed'], isTrue);
      expect(noFeature.events.single.payload.containsKey('classFeature'), isFalse);
    });

    test('Rettungswürfe anderer Attribute erhalten keine Mindestwerte', () {
      final engine = GameEngine(
        dice: DiceEngine(random: _FixedRandom(1)),
      );
      final demo = engine.createDemo();
      final campaign = demo.copyWith(
        hero: _barbarian(18).copyWith(id: demo.hero.id),
      );
      final result = engine.act(campaign, 'Rettungswurf: Geschicklichkeit SG 17');
      expect(result.events.single.type, 'saving.roll');
      expect(result.events.single.payload.containsKey('classFeature'), isFalse);
      expect(result.events.single.payload['failed'], isTrue);
    });
    test('Athletik in Rabenwacht nutzt den bestätigten Stärke-Mindestwert', () {
      final engine = GameEngine(
        dice: DiceEngine(random: _FixedRandom(1)),
      );
      final hero = _barbarian(18);
      final base = engine.createRabenwacht(hero);
      final campaign = base.copyWith(
        storyBible: {...base.storyBible, 'stage': 'stairs'},
      );
      final requested = engine
          .act(campaign, 'Ich klettere über den Abgrund.')
          .campaign;
      expect(requested.pendingRoll?.type, 'preparedCheck');
      expect(requested.pendingRoll?.targetName, 'strength|Athletik');
      final saved = Campaign.fromJson(requested.toJson());
      final resolved = engine.resolveRoll(saved, natural: 1);
      expect(resolved.events.single.type, 'roll.resolved');
      expect(resolved.events.single.payload['classFeature'], 'indomitableMight');
      expect(resolved.events.single.payload['effectiveTotal'], 18);
      expect(resolved.events.single.payload['roll']['natural'], 1);
      expect(resolved.events.single.payload['passed'], isTrue);
      expect(
        Campaign.fromJson(resolved.campaign.toJson()).toJson(),
        resolved.campaign.toJson(),
      );
    });

  });
}
