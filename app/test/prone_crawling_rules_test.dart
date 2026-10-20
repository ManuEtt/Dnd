import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/cover_rules.dart';
import 'package:lebendiger_spielleiter/domain/crawling_movement_rules.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

Campaign combat({
  int remaining = 9,
  int remainder = 0,
  int speed = 9,
  String participant = 'hero',
  List<String> conditions = const ['liegend'],
}) {
  final initial = GameEngine().createDemo();
  return initial.copyWith(
    hero: initial.hero.copyWith(conditions: conditions, speed: speed),
    encounter: Encounter(
      id: 'crawl-fixture',
      enemyName: 'Wache',
      enemyHitPoints: 10,
      enemyMaxHitPoints: 10,
      movementRemaining: remaining,
      movementRemainderDecimeters: remainder,
      activeParticipant: participant,
      heroCover: CoverLevel.half,
    ),
  );
}

void main() {
  test('5 Fuß kosten 3 m, keine Kampfaktion, Liegend bleibt', () {
    final before = combat();
    final result = GameEngine().crawl(
      before,
      distanceFeet: 5,
      difficultTerrain: false,
    );
    final after = result.campaign;
    expect(after.encounter!.remainingMovementDecimeters, 60);
    expect(after.encounter!.actionUsed, isFalse);
    expect(after.encounter!.bonusActionUsed, isFalse);
    expect(after.encounter!.heroCover, CoverLevel.none);
    expect(after.hero.conditions, contains('liegend'));
    expect(after.revision, before.revision + 1);
    expect(result.events.single.type, 'combat.crawled');
    expect(result.events.single.payload['movementSpentDecimeters'], 30);
    expect(result.events.single.payload['distanceFeet'], 5);
    expect(before.encounter!.heroCover, CoverLevel.half);
  });

  test('Schwieriges Gelände: 10 Fuß verbrauchen 9 m', () {
    final result = GameEngine().crawl(
      combat(),
      distanceFeet: 10,
      difficultTerrain: true,
    );
    expect(result.campaign.encounter!.remainingMovementDecimeters, 0);
    expect(result.events.single.payload['movementSpentDecimeters'], 90);
    expect(result.events.single.payload['difficultTerrain'], isTrue);
  });

  test('Dezimeter-Rest aus Aufstehen bleibt erhalten und serialisierbar', () {
    final engine = GameEngine();
    final stood = engine.standUp(combat()).campaign;
    final proneAgain = stood.copyWith(
      hero: stood.hero.copyWith(conditions: ['liegend']),
    );
    final after = engine.crawl(
      proneAgain,
      distanceFeet: 5,
      difficultTerrain: false,
    ).campaign;
    expect(after.encounter!.movementRemainingLabel, '1.5 m');
    expect(Campaign.fromJson(after.toJson()).toJson(), after.toJson());
  });

  test('Falscher Zug, nicht liegend, Tempo null sperren Kriechen', () {
    final engine = GameEngine();
    for (final invalid in [
      combat(conditions: const []),
      combat(participant: 'enemy'),
      combat(speed: 0),
      combat(conditions: const ['liegend', 'bewusstlos']),
    ]) {
      expect(
        () => engine.crawl(
          invalid,
          distanceFeet: 5,
          difficultTerrain: false,
        ),
        throwsFormatException,
      );
    }
  });

  test('Ungültige Strecke oder unzureichendes Budget: kein Commit', () {
    final engine = GameEngine();
    final before = combat(remaining: 2, remainder: 9);
    for (final distance in [0, -1, 101, 5]) {
      expect(
        () => engine.crawl(
          before,
          distanceFeet: distance,
          difficultTerrain: false,
        ),
        throwsFormatException,
      );
    }
    expect(before.encounter!.movementRemainingLabel, '2.9 m');
  });

  test('Unzulässige freie Laufbewegung bleibt gesperrt', () {
    final engine = GameEngine();
    final result = engine.act(combat(), 'Ich gehe 3 Meter.');
    expect(result.events.single.type, 'rules.blocked');
    expect(result.campaign.encounter!.movementRemainingLabel, '9 m');
  });

  test('SRD-Kosten: einfach und schwieriges Gelände', () {
    expect(
      CrawlingMovementRules.costDecimeters(
        distanceFeet: 5,
        difficultTerrain: false,
      ),
      30,
    );
    expect(
      CrawlingMovementRules.costDecimeters(
        distanceFeet: 5,
        difficultTerrain: true,
      ),
      45,
    );
  });
}
