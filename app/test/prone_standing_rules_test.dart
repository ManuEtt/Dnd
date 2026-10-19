import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/prone_movement_rules.dart';
import 'package:lebendiger_spielleiter/domain/condition_effects.dart';

Campaign _combat(GameEngine engine, {
  int meters = 9,
  int remainder = 0,
  int exhaustion = 0,
  int speed = 9,
  String active = 'hero',
}) {
  final initial = engine.createDemo();
  return initial.copyWith(
    hero: initial.hero.copyWith(
      conditions: ['liegend'],
      speed: speed,
      exhaustionLevel: exhaustion,
    ),
    encounter: Encounter(
      id: 'prone-combat',
      enemyName: 'Wächter',
      enemyHitPoints: 12,
      enemyMaxHitPoints: 12,
      movementRemaining: meters,
      movementRemainderDecimeters: remainder,
      activeParticipant: active,
    ),
  );
}

void main() {
  test('9 m Tempo: Aufstehen kostet exakt 4,5 m und keine Aktion', () {
    final engine = GameEngine();
    final before = _combat(engine);
    final update = engine.standUp(before);
    final after = update.campaign;

    expect(after.hero.conditions, isNot(contains('liegend')));
    expect(after.encounter!.movementRemaining, 4);
    expect(after.encounter!.movementRemainderDecimeters, 5);
    expect(after.encounter!.remainingMovementDecimeters, 45);
    expect(after.encounter!.movementRemainingLabel, '4.5 m');
    expect(after.encounter!.actionUsed, isFalse);
    expect(after.encounter!.bonusActionUsed, isFalse);
    expect(after.revision, before.revision + 1);
    expect(update.events.single.type, 'combat.stoodUp');
    expect(update.events.single.payload['movementSpentDecimeters'], 45);
    expect(update.events.single.payload['movementRemainingDecimeters'], 45);
    expect(before.hero.conditions, contains('liegend'));
  });

  test('7,5 m Tempo: 25 ft halbiert und abgerundet = 12 ft = 3,6 m', () {
    final engine = GameEngine();
    final current = _combat(
      engine,
      meters: 7,
      remainder: 5,
      exhaustion: 1,
    );
    expect(ProneMovementRules.standingCostDecimeters(current.hero), 36);
    final updated = engine.standUp(current).campaign;
    expect(updated.encounter!.movementRemaining, 3);
    expect(updated.encounter!.movementRemainderDecimeters, 9);
    expect(updated.encounter!.movementRemainingLabel, '3.9 m');
    expect(updated.hero.conditions, isNot(contains('liegend')));
  });

  test('Bewegungskosten bleiben nach JSON-Neustart und Meterbewegung erhalten', () {
    final engine = GameEngine();
    final standing = engine.standUp(_combat(engine)).campaign;
    final loaded = Campaign.fromJson(standing.toJson());
    expect(loaded.encounter!.movementRemainderDecimeters, 5);
    expect(loaded.toJson(), standing.toJson());
    final moved = engine.act(loaded, 'Ich gehe 3 Meter.').campaign;
    expect(moved.encounter!.movementRemaining, 1);
    expect(moved.encounter!.movementRemainderDecimeters, 5);
    expect(moved.encounter!.movementRemainingLabel, '1.5 m');
  });

  test('altes Schema 1 ohne Nachkommafeld bleibt unverändert lesbar', () {
    final engine = GameEngine();
    final original = _combat(engine);
    final json = original.toJson();
    final encounter = json['encounter'] as Map<String, dynamic>;
    expect(encounter.containsKey('movementRemainderDecimeters'), isFalse);
    final loaded = Campaign.fromJson(json);
    expect(loaded.encounter!.movementRemainderDecimeters, 0);
    expect(loaded.encounter!.movementRemainingLabel, '9 m');
  });

  test('manipulierte Bewegungsreste werden beim Import abgelehnt', () {
    final engine = GameEngine();
    final raw = _combat(engine).toJson();
    final encounter = raw['encounter'] as Map<String, dynamic>;
    for (final value in [-1, 10, '5', 0.5]) {
      encounter['movementRemainderDecimeters'] = value;
      expect(() => Campaign.fromJson(raw), throwsFormatException);
    }
  });

  test('Aufstehen scheitert ohne ausreichendes Budget oder bei Tempo 0', () {
    final engine = GameEngine();
    expect(
      () => engine.standUp(_combat(engine, meters: 4, remainder: 4)),
      throwsFormatException,
    );
    expect(
      () => engine.standUp(_combat(engine, speed: 0)),
      throwsFormatException,
    );
    expect(
      () => engine.standUp(_combat(engine, active: 'enemy')),
      throwsFormatException,
    );
  });

  test('Bewusstlosigkeit und Quellzustand verhindern vorzeitiges Aufstehen', () {
    final engine = GameEngine();
    final before = _combat(engine);
    final unconscious = before.copyWith(
      hero: before.hero.copyWith(conditions: ['liegend', 'bewusstlos']),
    );
    expect(() => engine.standUp(unconscious), throwsFormatException);

    final effect = ConditionEffect(
      id: 'source-prone',
      condition: 'liegend',
      source: 'Bestätigte Falle',
    );
    final sourced = before.copyWith(
      hero: before.hero.copyWith(conditionEffects: [effect]),
    );
    expect(() => engine.standUp(sourced), throwsFormatException);
    expect(sourced.hero.conditionEffects.single.id, 'source-prone');
  });

  test('Editor kann im aktiven Kampf Aufstehen nicht kostenlos erzwingen', () {
    final engine = GameEngine();
    final combat = _combat(engine);
    expect(
      () => engine.updateHero(
        combat,
        combat.hero.copyWith(conditions: const []),
      ),
      throwsFormatException,
    );
    final outside = combat.copyWith(encounter: null);
    // Campaign.copyWith retains nullable encounters; use a completed fight.
    final finished = combat.copyWith(
      encounter: combat.encounter!.copyWith(enemyHitPoints: 0),
    );
    expect(
      engine.updateHero(finished, finished.hero.copyWith(conditions: [])).campaign
          .hero.conditions,
      isNot(contains('liegend')),
    );
  });

  test('außerhalb des aktiven Kampfes ist kein Zugbudget nötig', () {
    final engine = GameEngine();
    final finished = _combat(engine).copyWith(
      encounter: const Encounter(
        id: 'finished',
        enemyName: 'Besiegter Wächter',
        enemyHitPoints: 0,
        enemyMaxHitPoints: 10,
      ),
    );
    final update = engine.standUp(finished);
    expect(update.campaign.hero.conditions, isNot(contains('liegend')));
    expect(update.events.single.payload['movementSpentDecimeters'], 0);
    expect(update.campaign.encounter!.movementRemaining, 9);
  });

  test('Normale Bewegung wird bei liegend abgewiesen statt gratis Laufen', () {
    final engine = GameEngine();
    final before = _combat(engine);
    final update = engine.act(before, 'Ich gehe 3 Meter.');
    expect(update.events.single.type, 'rules.blocked');
    expect(update.campaign.encounter!.movementRemaining, 9);
    expect(update.campaign.hero.conditions, contains('liegend'));
  });
}
