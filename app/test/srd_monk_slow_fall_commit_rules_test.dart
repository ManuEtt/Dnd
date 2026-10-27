import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

Campaign monkFallCampaign({
  int monkLevel = 4,
  int hitPoints = 20,
  int temporaryHitPoints = 0,
  String encounterId = 'fall-encounter',
  String participant = 'enemy',
  bool reactionUsed = false,
  List<String> conditions = const [],
}) {
  final base = GameEngine().createDemo();
  return base.copyWith(
    hero: base.hero.copyWith(
      className: 'Mönch',
      level: monkLevel,
      hitPoints: hitPoints,
      maxHitPoints: 20,
      temporaryHitPoints: temporaryHitPoints,
      conditions: conditions,
    ),
    encounter: Encounter(
      id: encounterId,
      enemyName: 'Wache',
      enemyHitPoints: 10,
      enemyMaxHitPoints: 10,
      activeParticipant: participant,
      reactionUsed: reactionUsed,
    ),
  );
}

GameUpdate applyFall(
  Campaign before, {
  String encounterId = 'fall-encounter',
  int damage = 37,
  bool fallConfirmed = true,
  bool reactionConfirmed = true,
  bool damageAfterDefensesConfirmed = true,
}) => GameEngine().applyConfirmedSlowFall(
  before,
  encounterId: encounterId,
  confirmedFallDamage: damage,
  fallConfirmed: fallConfirmed,
  playerConfirmedReaction: reactionConfirmed,
  damageAfterOtherDefensesConfirmed: damageAfterDefensesConfirmed,
);

void main() {
  test('Off-turn Slow Fall consumes Reaction and applies remaining HP loss', () {
    final before = monkFallCampaign();
    final update = applyFall(before);
    final after = update.campaign;
    expect(after.hero.hitPoints, 3);
    expect(after.encounter!.reactionUsed, isTrue);
    expect(after.encounter!.activeParticipant, 'enemy');
    expect(after.revision, before.revision + 1);
    expect(after.events.last.type, 'combat.slowFallResolved');
    expect(after.events.last.payload['monkClassLevel'], 4);
    expect(after.events.last.payload['incomingFallDamage'], 37);
    expect(after.events.last.payload['damagePrevented'], 20);
    expect(after.events.last.payload['damage'], 17);
    expect(after.events.last.payload['hitPointDamage'], 17);
    expect(after.events.last.payload['reactionUsed'], isTrue);
    expect(after.events.last.payload['stateAfter'], isA<Map>());
    expect(before.hero.hitPoints, 20);
    expect(before.encounter!.reactionUsed, isFalse);
    expect(before.revision + 1, after.revision);
  });

  test('Temporary HP absorb residual fall damage while spending Reaction', () {
    final before = monkFallCampaign(temporaryHitPoints: 5);
    final after = applyFall(before, damage: 25).campaign;
    expect(after.hero.temporaryHitPoints, 0);
    expect(after.hero.hitPoints, 20);
    expect(after.encounter!.reactionUsed, isTrue);
    expect(after.events.last.payload['temporaryHitPointsAbsorbed'], 5);
    expect(after.events.last.payload['hitPointDamage'], 0);
  });

  test('Below Monk 4, wrong encounter and unconfirmed fall all fail closed', () {
    final before = monkFallCampaign();
    final actions = <GameUpdate Function()>[
      () => applyFall(before.copyWith(
        hero: before.hero.copyWith(className: 'Mönch', level: 3),
      )),
      () => applyFall(before, encounterId: 'another-fight'),
      () => applyFall(before, fallConfirmed: false),
      () => applyFall(before, reactionConfirmed: false),
      () => applyFall(before, damageAfterDefensesConfirmed: false),
      () => applyFall(before, damage: -1),
      () => applyFall(before, damage: 100001),
      () => applyFall(before.copyWith(
        encounter: before.encounter!.copyWith(reactionUsed: true),
      )),
      () => applyFall(before.copyWith(
        pendingRoll: const PendingRoll(
          id: 'fall-roll',
          type: 'attack',
          modifier: 0,
          difficulty: 10,
        ),
      )),
      () => applyFall(before.copyWith(
        hero: before.hero.copyWith(conditions: const ['betäubt']),
      )),
      () => applyFall(before.copyWith(
        encounter: null,
      )),
    ];
    for (final action in actions) {
      expect(action, throwsFormatException);
    }
    expect(before.hero.hitPoints, 20);
    expect(before.encounter!.reactionUsed, isFalse);
    expect(before.events.where((event) =>
      event.type == 'combat.slowFallResolved'), isEmpty);
  });

  test('A second fall cannot consume the same encounter Reaction twice', () {
    final first = applyFall(monkFallCampaign());
    expect(() => applyFall(first.campaign), throwsFormatException);
    expect(first.campaign.hero.hitPoints, 3);
    expect(first.campaign.encounter!.reactionUsed, isTrue);
  });

  test('Reducing enough fall damage to zero still spends Reaction', () {
    final after = applyFall(monkFallCampaign(), damage: 12).campaign;
    expect(after.hero.hitPoints, 20);
    expect(after.encounter!.reactionUsed, isTrue);
    expect(after.events.last.payload['damage'], 0);
    expect(after.events.last.payload['damagePrevented'], 12);
  });

  test('Remaining fall damage at zero HP follows existing death rules', () {
    final after = applyFall(monkFallCampaign(hitPoints: 5), damage: 28).campaign;
    expect(after.hero.hitPoints, 0);
    expect(after.hero.conditions, contains('bewusstlos'));
    expect(after.hero.conditions, contains('liegend'));
    expect(after.encounter!.reactionUsed, isTrue);
    expect(after.events.last.payload['damage'], 8);
  });

  test('Monk secondary class uses its own level and keeps old JSON schema', () {
    final before = monkFallCampaign().copyWith(
      hero: monkFallCampaign().hero.copyWith(
        className: 'Kämpfer',
        secondaryClassName: 'Mönch',
        secondaryClassLevel: 4,
        level: 7,
      ),
    );
    final after = applyFall(before, damage: 24).campaign;
    expect(after.events.last.payload['monkClassLevel'], 4);
    expect(after.events.last.payload['damage'], 4);
    final restored = Campaign.fromJson(after.toJson());
    expect(restored.toJson(), after.toJson());
    expect(restored.encounter!.reactionUsed, isTrue);
    expect(restored.hero.hitPoints, 16);
  });
}
