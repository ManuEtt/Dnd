import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/character_rule_engine.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

class _SequentialRandom implements Random {
  int count = 0;
  @override
  int nextInt(int max) => (count++ % max);
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

HeroCharacter _hero({int exhaustion = 0, List<String> conditions = const [],
    bool armorTrained = false, bool shieldTrained = false,
    String armor = '', String shield = '', String weapon = ''}) => HeroCharacter(
  id: 'hero', name: 'Liora', species: 'Mensch', className: 'Kämpfer',
  level: 5, hitPoints: 30, maxHitPoints: 30, armorClass: 16, speed: 9,
  weaponDamage: '1d8', weaponAbility: 'strength', weaponProficient: true,
  exhaustionLevel: exhaustion, conditions: conditions,
  equippedArmorId: armor, equippedShieldId: shield, equippedWeaponId: weapon,
  equippedArmorTrained: armorTrained, equippedShieldTrained: shieldTrained,
  abilities: const {'strength': 10, 'dexterity': 14, 'constitution': 12,
    'wisdom': 12, 'intelligence': 10, 'charisma': 10},
  skills: const ['Wahrnehmung'],
  savingThrowProficiencies: const ['strength'],
  inventory: [
    const InventoryItem(id: 'plate', name: 'Plattenrüstung',
        catalogId: 'armor-plate-armor'),
    const InventoryItem(id: 'scale', name: 'Schuppenpanzer',
        catalogId: 'armor-scale-mail'),
    const InventoryItem(id: 'shield', name: 'Schild',
        catalogId: 'armor-shield'),
    const InventoryItem(id: 'bow', name: 'Langbogen',
        catalogId: 'weapon-longbow'),
  ],
);

void main() {
  group('Gemeinsame Charakter-Regelengine SRD 5.2.1', () {
    test('Erschöpfung einmal bei Würfen, nicht auf Basisattribute', () {
      final normal = _hero();
      final weary = _hero(exhaustion: 2);
      expect(CharacterRuleEngine.attributeModifier(weary, 'dexterity'), 2);
      expect(CharacterRuleEngine.savingThrowBonus(normal, 'strength'), 3);
      expect(CharacterRuleEngine.savingThrowBonus(weary, 'strength'), -1);
      expect(CharacterRuleEngine.perception(normal).modifier, 4);
      expect(CharacterRuleEngine.perception(weary).modifier, 0);
      expect(CharacterRuleEngine.attack(normal).modifier -
          CharacterRuleEngine.attack(weary).modifier, 4);
      expect(CharacterRuleEngine.initiative(normal).modifier -
          CharacterRuleEngine.initiative(weary).modifier, 4);
    });

    test('Vergiftung, Liegend und Blindheit ergeben Angriffsnachteil', () {
      expect(CharacterRuleEngine.attack(_hero(
        conditions: ['vergiftet'])).disadvantage, isTrue);
      expect(CharacterRuleEngine.attack(_hero(
        conditions: ['liegend'])).disadvantage, isTrue);
      expect(CharacterRuleEngine.attack(_hero(
        conditions: ['blind'])).disadvantage, isTrue);
      expect(CharacterRuleEngine.abilityCheck(_hero(
        conditions: ['vergiftet']), 'wisdom').disadvantage, isTrue);
      expect(CharacterRuleEngine.abilityCheck(_hero(
        conditions: ['verängstigt']), 'wisdom').disadvantage, isFalse);
    });

    test('Initiative: unsichtbar Vorteil, handlungsunfähig Nachteil', () {
      expect(CharacterRuleEngine.initiative(_hero(
        conditions: ['unsichtbar'])).advantage, isTrue);
      expect(CharacterRuleEngine.initiative(_hero(
        conditions: ['handlungsunfähig'])).disadvantage, isTrue);
      expect(CharacterRuleEngine.initiative(_hero(
        conditions: ['vergiftet'])).disadvantage, isTrue);
      final both = CharacterRuleEngine.initiative(_hero(
        conditions: ['unsichtbar', 'handlungsunfähig']));
      expect(both.normalRoll, isTrue);
      expect(both.rollHint, 'Normalwurf');
      expect(() => CharacterRuleEngine.initiative(_hero(
        conditions: ['tot'])), throwsStateError);
    });

    test('RK-Übung und Rüstungsart verhindern/fördern regelgerechte Proben', () {
      final untrained = _hero(armor: 'scale', armorTrained: false);
      expect(CharacterRuleEngine.abilityCheck(untrained, 'strength')
          .disadvantage, isTrue);
      expect(CharacterRuleEngine.savingThrow(untrained, 'dexterity')
          .disadvantage, isTrue);
      expect(CharacterRuleEngine.abilityCheck(untrained, 'wisdom')
          .disadvantage, isFalse);
      expect(CharacterRuleEngine.abilityCheck(_hero(armor: 'scale'),
          'dexterity', stealth: true).disadvantage, isTrue);
      expect(CharacterRuleEngine.abilityCheck(_hero(shield: 'shield',
          shieldTrained: false), 'strength').disadvantage, isTrue);
    });

    test('Schwere Waffen, Bewegung und Erschöpfung kombinieren richtig', () {
      final bow = _hero(weapon: 'bow'); // GE 14 -> no Heavy disadvantage
      expect(CharacterRuleEngine.attack(bow).disadvantage, isFalse);
      final lowDex = bow.copyWith(abilities: {
        ...bow.abilities, 'dexterity': 12,
      });
      expect(CharacterRuleEngine.attack(lowDex).disadvantage, isTrue);
      final armor = _hero(armor: 'plate', exhaustion: 2); // ST 10 < 15
      expect(CharacterRuleEngine.speedMeters(armor), 3);
      expect(CharacterRuleEngine.movementWholeMeters(armor), 3);
      expect(CharacterRuleEngine.speedMeters(_hero(exhaustion: 2)), 6);
      expect(CharacterRuleEngine.speedMeters(
          armor.copyWith(conditions: ['gepackt'])), 0);
      expect(CharacterRuleEngine.speedMeters(_hero().copyWith(speed: null)),
          isNull);
    });

    test('PendingRoll bleibt bei alten Spielständen kompatibel und schützt bools', () {
      const request = PendingRoll(id: 'r', type: 'attack', modifier: 3,
          difficulty: 14, advantage: true, disadvantage: false);
      final restored = PendingRoll.fromJson(request.toJson());
      expect(restored.advantage, isTrue);
      expect(restored.disadvantage, isFalse);
      final old = PendingRoll.fromJson({'id': 'old', 'type': 'attack',
        'modifier': 3, 'difficulty': 12});
      expect(old.advantage, isFalse);
      expect(old.disadvantage, isFalse);
      expect(() => PendingRoll.fromJson({...request.toJson(),
        'advantage': 'yes'}), throwsFormatException);
      final dice = DiceEngine(random: _SequentialRandom());
      final roll = dice.check(modifier: restored.modifier,
        advantage: restored.advantage, disadvantage: restored.disadvantage);
      expect(roll.rolls, [1, 2]);
      expect(roll.natural, 2);
      expect(roll.total, 5);
    });

    test('Kampf speichert Angriffsnachteil im Ereignis und Spielstand', () {
      final gm = GameEngine(dice: DiceEngine(random: _SequentialRandom()),
          clock: () => DateTime.utc(2026, 10, 15));
      var game = gm.createDemo();
      game = gm.act(game, 'Ich gehe zum Waldschrein.').campaign;
      expect(game.encounter, isNotNull);
      game = game.copyWith(hero: game.hero.copyWith(
        conditions: ['vergiftet']));
      final request = gm.act(game, 'Ich greife mit meinem Schwert an.');
      expect(request.campaign.pendingRoll?.type, 'attack');
      expect(request.campaign.pendingRoll?.disadvantage, isTrue);
      final stored = Campaign.fromJson(request.campaign.toJson());
      expect(stored.pendingRoll?.disadvantage, isTrue);
      final roll = gm.resolveRoll(stored, natural: 15);
      expect(roll.events.single.payload['request']['disadvantage'], isTrue);
    });
  });
}
