import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/character_rule_engine.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/monk_self_restoration.dart';

class LowRandom implements Random {
  @override int nextInt(int max) => 0;
  @override bool nextBool() => false;
  @override double nextDouble() => 0;
}

HeroCharacter monk({int level = 10, List<String> conditions = const [],
    String primary = 'Mönch', String secondary = '', int secondLevel = 0}) =>
    HeroCharacter(id: 'monk', name: 'Liora', className: primary,
      secondaryClassName: secondary, secondaryClassLevel: secondLevel,
      level: level, hitPoints: 30, maxHitPoints: 30, armorClass: 16,
      speed: 9, weaponDamage: '1d6', weaponProficient: true,
      abilities: const {'strength': 12, 'dexterity': 16,
        'constitution': 14, 'intelligence': 10, 'wisdom': 14,
        'charisma': 10},
      conditions: conditions);

GameEngine gm() => GameEngine(
  dice: DiceEngine(random: LowRandom()),
  clock: () => DateTime.utc(2026, 10, 16),
);

Campaign fighting(GameEngine engine, HeroCharacter hero) {
  final demo = engine.createDemo();
  final campaign = demo.copyWith(hero: hero.copyWith(id: demo.hero.id));
  return engine.act(campaign, 'Ich gehe zum Waldschrein.').campaign;
}

void main() {
  group('SRD 5.2.1 Mönch: Selbstwiederherstellung', () {
    test('Stufe 10: genau ein Zustand endet am Zugende', () {
      final hero = monk(conditions: ['vergiftet', 'blind']);
      final result = MonkSelfRestoration.atEndOfTurn(hero);
      expect(result.removed, 'vergiftet');
      expect(result.choiceRequired, isFalse);
      expect(result.hero.conditions, ['blind']);
      expect(hero.conditions, ['vergiftet', 'blind']);
    });

    test('Stufe 9 und fremde Klasse haben keine Freischaltung', () {
      expect(MonkSelfRestoration.choices(monk(level: 9,
          conditions: ['vergiftet'])), isEmpty);
      expect(MonkSelfRestoration.atEndOfTurn(monk(level: 9,
          conditions: ['vergiftet'])).removed, isEmpty);
      expect(MonkSelfRestoration.choices(monk(primary: 'Schurke',
          conditions: ['vergiftet'])), isEmpty);
    });

    test('Mehrklassen: Mönchsstufe statt Gesamtstufe', () {
      final under = monk(level: 19, primary: 'Kämpfer',
          secondary: 'Mönch', secondLevel: 9,
          conditions: ['verängstigt']);
      expect(MonkSelfRestoration.choices(under), isEmpty);
      final atTen = monk(level: 19, primary: 'Kämpfer',
          secondary: 'Mönch', secondLevel: 10,
          conditions: ['verängstigt']);
      expect(MonkSelfRestoration.atEndOfTurn(atTen).removed, 'verängstigt');
    });

    test('Mehrere passende Zustände benötigen explizite Wahl', () {
      final hero = monk(conditions: ['vergiftet', 'bezaubert', 'blind']);
      final ambiguous = MonkSelfRestoration.atEndOfTurn(hero);
      expect(ambiguous.choiceRequired, isTrue);
      expect(ambiguous.removed, isEmpty);
      expect(ambiguous.hero.conditions, hero.conditions);
      final chosen = MonkSelfRestoration.atEndOfTurn(hero,
          choice: 'bezaubert');
      expect(chosen.hero.conditions, ['vergiftet', 'blind']);
      // An earlier selection may have become stale; no invalid removal.
      expect(MonkSelfRestoration.atEndOfTurn(hero,
          choice: 'blind').choiceRequired, isTrue);
    });

    test('Alte Kämpfe ohne gespeicherte Auswahl laden unverändert', () {
      const encounter = Encounter(id: 'f', enemyName: 'Wache',
          enemyHitPoints: 20, enemyMaxHitPoints: 20);
      final old = encounter.toJson();
      expect(old.containsKey('selfRestorationChoice'), isFalse);
      expect(Encounter.fromJson(old).selfRestorationChoice, isEmpty);
      final chosen = encounter.copyWith(selfRestorationChoice: 'vergiftet');
      expect(Encounter.fromJson(chosen.toJson()).selfRestorationChoice,
          'vergiftet');
      expect(() => Encounter.fromJson({...old,
          'selfRestorationChoice': 'blind'}), throwsFormatException);
      expect(() => Encounter.fromJson({...old,
          'selfRestorationChoice': 20}), throwsFormatException);
    });

    test('Auswahl verändert Zustand erst am Zugende und wird zurückgesetzt', () {
      final engine = gm();
      var campaign = fighting(engine, monk(
          conditions: ['bezaubert', 'vergiftet']));
      final choice = engine.act(campaign, 'Selbstwiederherstellung: vergiftet');
      expect(choice.events.single.type, 'class.selfRestorationSelected');
      campaign = Campaign.fromJson(choice.campaign.toJson());
      expect(campaign.hero.conditions, contains('vergiftet'));
      expect(campaign.encounter!.selfRestorationChoice, 'vergiftet');
      final turn = engine.act(campaign, 'Ich beende meinen Zug.');
      expect(turn.events.single.type, 'combat.turnCompleted');
      expect(turn.events.single.payload['selfRestorationRemoved'], 'vergiftet');
      expect(turn.campaign.hero.conditions, ['bezaubert']);
      expect(turn.campaign.encounter!.selfRestorationChoice, isEmpty);
    });

    test('Ohne Auswahl werden zwei Zustände nicht eigenmächtig beendet', () {
      final engine = gm();
      final campaign = fighting(engine, monk(
          conditions: ['bezaubert', 'vergiftet']));
      final turn = engine.act(campaign, 'Ich beende meinen Zug.');
      expect(turn.events.single.payload['selfRestorationChoiceRequired'], true);
      expect(turn.campaign.hero.conditions, ['bezaubert', 'vergiftet']);
    });

    test('Ein Zustand wird bei normalem Zugende automatisch entfernt', () {
      final engine = gm();
      final campaign = fighting(engine, monk(conditions: ['vergiftet']));
      final turn = engine.act(campaign, 'Ich beende meinen Zug.');
      expect(turn.events.single.payload['selfRestorationRemoved'], 'vergiftet');
      expect(turn.campaign.hero.conditions, isEmpty);
    });

    test('Nicht passende Auswahl und Stufe 9 werden blockiert', () {
      final engine = gm();
      final campaign = fighting(engine, monk(level: 9,
          conditions: ['vergiftet']));
      final blocked = engine.act(campaign,
          'Selbstwiederherstellung: vergiftet');
      expect(blocked.events.single.type, 'rules.blocked');
      expect(blocked.campaign.encounter!.selfRestorationChoice, isEmpty);
    });
  });

  group('Mönch 14: Disziplinierter Überlebender', () {
    test('alle Rettungswürfe erhalten ab Mönchsstufe 14 Übung', () {
      final thirteen = monk(level: 13);
      final fourteen = monk(level: 14);
      expect(CharacterRuleEngine.savingThrowBonus(thirteen, 'wisdom'), 2);
      expect(CharacterRuleEngine.savingThrowBonus(fourteen, 'wisdom'), 7);
      expect(CharacterRuleEngine.savingThrowBonus(fourteen, 'dexterity'), 8);
      expect(CharacterRuleEngine.savingThrowBonus(fourteen, 'charisma'), 5);
      expect(fourteen.savingThrowProficiencies, isEmpty);
    });

    test('Klassenstufe und Erschöpfung werden berücksichtigt', () {
      final multi = monk(level: 18, primary: 'Kämpfer',
          secondary: 'Mönch', secondLevel: 14);
      expect(CharacterRuleEngine.savingThrowBonus(multi, 'wisdom'), 8);
      final weary = multi.copyWith(exhaustionLevel: 2);
      expect(CharacterRuleEngine.savingThrowBonus(weary, 'wisdom'), 4);
      expect(CharacterRuleEngine.savingThrowBonus(monk(level: 14).copyWith(
          abilities: {...monk(level: 14).abilities, 'wisdom': null}),
          'wisdom'), isNull);
    });
  });
}
