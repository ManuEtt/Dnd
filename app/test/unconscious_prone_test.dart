import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/condition_effects.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rules_engine.dart';

HeroCharacter hero({
  int hitPoints = 5,
  List<String> conditions = const [],
  List<ConditionEffect> effects = const [],
}) => HeroCharacter(
  id: 'prone-hero',
  name: 'Liora',
  hitPoints: hitPoints,
  maxHitPoints: 12,
  armorClass: 16,
  speed: 9,
  weaponDamage: '1d8',
  abilities: const {
    'strength': 12,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 10,
    'wisdom': 12,
    'charisma': 10,
  },
  conditions: conditions,
  conditionEffects: effects,
);

ConditionEffect unconscious(String id, {String? encounterId, int? round}) =>
    ConditionEffect(
      id: id,
      condition: 'bewusstlos',
      source: 'Bestätigter Effekt',
      expiresInEncounterId: encounterId,
      expiresAtOwnTurnEndRound: round,
    );

void main() {
  test('0 TP geben Bewusstlos und Liegend; Heilung erhält Liegend', () {
    final before = hero(hitPoints: 3);
    final fallen = RulesEngine.damage(before, 4);
    expect(fallen.hitPoints, 0);
    expect(fallen.conditions, containsAll(['bewusstlos', 'liegend']));
    expect(fallen.manualConditions, contains('liegend'));
    expect(before.conditions, isEmpty);

    final healed = RulesEngine.heal(fallen, 2);
    expect(healed.hitPoints, 2);
    expect(healed.conditions, contains('liegend'));
    expect(healed.conditions, isNot(contains('bewusstlos')));
    expect(healed.manualConditions, ['liegend']);
    expect(RulesEngine.heal(healed, 1).manualConditions, ['liegend']);
  });

  test('natürliche Todesrettung 20 lässt historischen Helden liegen', () {
    final legacy = hero(hitPoints: 0, conditions: ['bewusstlos']);
    final restored = RulesEngine.deathSave(legacy, 20);
    expect(restored.hitPoints, 1);
    expect(restored.conditions, ['liegend']);
    expect(legacy.conditions, ['bewusstlos']);
  });

  test('tödlicher Angriff fügt Liegend nur einmal als getrennte Folge hinzu', () {
    final dead = RulesEngine.damage(hero(hitPoints: 12), 24);
    expect(dead.isDead, isTrue);
    expect(dead.manualConditions.where((c) => c == 'liegend'), hasLength(1));

    final fallen = RulesEngine.damage(
      hero(hitPoints: 0, conditions: ['bewusstlos']),
      1,
    );
    expect(fallen.manualConditions.where((c) => c == 'liegend'), hasLength(1));
    expect(RulesEngine.damage(fallen, 1).manualConditions, contains('liegend'));
  });

  test('mehrere Bewusstlos-Quellen verlieren nie Liegend', () {
    var current = hero();
    current = ConditionEffectRules.add(current, unconscious('source-1'));
    current = ConditionEffectRules.add(current, unconscious('source-2'));
    expect(current.conditions, containsAll(['bewusstlos', 'liegend']));
    expect(current.conditions.where((c) => c == 'liegend'), hasLength(1));
    expect(current.manualConditions, ['liegend']);

    final afterOne = ConditionEffectRules.removeById(current, 'source-1');
    expect(afterOne.conditions, containsAll(['bewusstlos', 'liegend']));
    final awake = ConditionEffectRules.removeById(afterOne, 'source-2');
    expect(awake.conditions, ['liegend']);
    expect(awake.conditionEffects, isEmpty);

    final restored = HeroCharacter.fromJson(
      jsonDecode(jsonEncode(awake.toJson())) as Map<String, dynamic>,
    );
    expect(restored.manualConditions, ['liegend']);
  });

  test('Zugablauf einer Quelle lässt Liegend und andere Quellen bestehen', () {
    final prone = ConditionEffectRules.add(
      hero(),
      unconscious('expired', encounterId: 'fight-1', round: 2),
    );
    final other = ConditionEffectRules.add(
      prone,
      unconscious('stays', encounterId: 'fight-2', round: 2),
    );
    final after = ConditionEffectRules.expireAtOwnTurnEnd(
      other,
      encounterId: 'fight-1',
      round: 2,
    );
    expect(after.conditionEffects.map((e) => e.id), ['stays']);
    expect(after.conditions, containsAll(['bewusstlos', 'liegend']));
    final cleared = ConditionEffectRules.expireAtOwnTurnEnd(
      after,
      encounterId: 'fight-2',
      round: 2,
    );
    expect(cleared.conditions, ['liegend']);
  });

  test('Legacy-JSON bleibt beim reinen Lesen unverändert; Erholung korrigiert', () {
    final old = hero(hitPoints: 0, conditions: ['bewusstlos']).toJson();
    expect(old['conditions'], ['bewusstlos']);
    final loaded = HeroCharacter.fromJson(old);
    expect(loaded.toJson()['conditions'], ['bewusstlos']);
    expect(RulesEngine.heal(loaded, 1).manualConditions, ['liegend']);
  });

  test('Bestätigte manuelle Bewusstlosigkeit erzeugt Liegend und beendet Fokus', () {
    final engine = GameEngine();
    final before = engine.createDemo();
    final changed = before.hero.copyWith(
      conditions: ['bewusstlos'],
      concentratingOn: 'Segen',
    );
    final updated = engine.updateHero(before, changed);
    expect(
      updated.campaign.hero.conditions,
      containsAll(['bewusstlos', 'liegend']),
    );
    expect(updated.campaign.hero.concentratingOn, isEmpty);
    expect(updated.campaign.hero.manualConditions, ['bewusstlos', 'liegend']);

    final awake = engine.updateHero(
      updated.campaign,
      updated.campaign.hero.copyWith(conditions: ['liegend']),
    );
    expect(awake.campaign.hero.conditions, ['liegend']);
    expect(awake.campaign.hero.concentratingOn, isEmpty);
  });

  test('Quellen-Bewusstlosigkeit beendet Konzentration ohne Quellenverlust', () {
    final engine = GameEngine();
    final before = engine.createDemo();
    final concentrating = before.copyWith(
      hero: before.hero.copyWith(concentratingOn: 'Segen'),
    );
    final applied = engine.applyConditionEffect(
      concentrating,
      source: 'Magischer Schlaf',
      condition: 'bewusstlos',
      duration: ConditionEffectDuration.untilRemoved,
    );
    expect(applied.campaign.hero.concentratingOn, isEmpty);
    expect(applied.campaign.hero.manualConditions, ['liegend']);
    expect(applied.campaign.hero.conditionEffects, hasLength(1));
    final awake = engine.removeConditionEffect(
      applied.campaign,
      effectId: applied.campaign.hero.conditionEffects.single.id,
    );
    expect(awake.campaign.hero.conditions, ['liegend']);
    expect(awake.campaign.hero.concentratingOn, isEmpty);
  });
}
