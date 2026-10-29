import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/enemy_force_defense.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_magic_missile_encounter_hp_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_magic_missile_multi_target_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_magic_missile_volley_damage_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';

const _main = SrdMagicMissileTarget(
  id: 'primary',
  creatureConfirmed: true,
  visibleConfirmed: true,
  within120FeetConfirmed: true,
  noTotalCoverConfirmed: true,
);
const _extraA = SrdMagicMissileTarget(
  id: 'extra-a',
  creatureConfirmed: true,
  visibleConfirmed: true,
  within120FeetConfirmed: true,
  noTotalCoverConfirmed: true,
);
const _extraB = SrdMagicMissileTarget(
  id: 'extra-b',
  creatureConfirmed: true,
  visibleConfirmed: true,
  within120FeetConfirmed: true,
  noTotalCoverConfirmed: true,
);
const _defensePrimary = SrdMissileTargetDefense(
  targetId: 'primary',
  shieldState: SrdMissileShieldState.absentConfirmed,
  forceDefense: EnemyForceDefense.normal,
);
const _defenseA = SrdMissileTargetDefense(
  targetId: 'extra-a',
  shieldState: SrdMissileShieldState.absentConfirmed,
  forceDefense: EnemyForceDefense.normal,
);
const _defenseB = SrdMissileTargetDefense(
  targetId: 'extra-b',
  shieldState: SrdMissileShieldState.absentConfirmed,
  forceDefense: EnemyForceDefense.normal,
);

const _fight = Encounter(
  id: 'primary',
  enemyName: 'Schattenwächter',
  enemyHitPoints: 12,
  enemyMaxHitPoints: 12,
);
const _creatureA = TrackedAreaCreature(
  id: 'extra-a',
  name: 'Wächter eins',
  hitPoints: 6,
  maxHitPoints: 6,
);
const _creatureB = TrackedAreaCreature(
  id: 'extra-b',
  name: 'Wächter zwei',
  hitPoints: 4,
  maxHitPoints: 4,
);

Campaign _campaign({
  Encounter? fight,
  List<TrackedAreaCreature> extras = const [_creatureA, _creatureB],
}) {
  final seed = GameEngine(dice: DiceEngine()).createDemo();
  return seed.copyWith(encounter: fight ?? _fight, trackedAreaCreatures: extras);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellDefinition missile;

  setUpAll(() async {
    missile = (await SrdSpellCatalogLoader.load()).find('Magic Missile')!;
  });

  SrdMagicMissileAllocation plan({
    List<String> ids = const ['primary', 'extra-a', 'primary'],
    List<SrdMagicMissileTarget> targets = const [_main, _extraA],
  }) => SrdMagicMissileMultiTargetRules.prepare(
    spell: missile,
    slotLevel: 1,
    confirmedTargets: targets,
    dartTargetIds: ids,
  );

  SrdMagicMissileVolleyDamage volley({
    List<String> ids = const ['primary', 'extra-a', 'primary'],
    List<SrdMissileTargetDefense> defenses = const [
      _defensePrimary,
      _defenseA,
    ],
  }) => SrdMagicMissileVolleyDamageRules.resolve(
    slotLevel: 1,
    allocationAndReactionsConfirmed: true,
    darts: [
      for (final id in ids)
        SrdMissileDartEvidence(
          targetId: id,
          naturalD4: defenses
                  .firstWhere((target) => target.targetId == id)
                  .shieldState ==
              SrdMissileShieldState.activeConfirmed
              ? null
              : 1,
        ),
    ],
    targetDefenses: defenses,
  );

  SrdMagicMissileEncounterHpPreview preview(
    Campaign campaign, {
    SrdMagicMissileAllocation? allocation,
    SrdMagicMissileVolleyDamage? damage,
    bool evidence = true,
    String encounterId = 'primary',
    int? revision,
  }) => SrdMagicMissileEncounterHpRules.preview(
    campaign: campaign,
    encounterId: encounterId,
    expectedRevision: revision ?? campaign.revision,
    currentTargetEvidenceConfirmed: evidence,
    allocation: allocation ?? plan(),
    damage: damage ?? volley(),
  );

  test('binds ordered darts to stable IDs, not ambiguous display names', () {
    final before = _campaign();
    final result = preview(before);
    expect(result.encounterId, 'primary');
    expect(result.expectedRevision, before.revision);
    expect(result.targets.map((target) => target.targetId), [
      'primary',
      'extra-a',
    ]);
    expect(result.targets.map((target) => target.primaryOpponent), [
      true,
      false,
    ]);
    expect(result.targets.map((target) => target.appliedDamage), [4, 2]);
    expect(result.remainingHitPoints('primary'), 8);
    expect(result.remainingHitPoints('extra-a'), 4);
    expect(result.remainingHitPoints('extra-b'), isNull);
    expect(result.primaryDefeated, isFalse);
    expect(result.livingTrackedCreaturesRemain, isTrue);
    expect(result.requiresMultiActorVictoryResolution, isFalse);
  });

  test('darts can hit two tracked creatures without changing primary HP', () {
    final before = _campaign();
    final ids = ['extra-a', 'extra-b', 'extra-b'];
    final result = preview(
      before,
      allocation: plan(ids: ids, targets: const [_extraA, _extraB]),
      damage: volley(ids: ids, defenses: const [_defenseA, _defenseB]),
    );
    expect(result.remainingHitPoints('extra-a'), 4);
    expect(result.remainingHitPoints('extra-b'), 0);
    expect(result.primaryDefeated, isFalse);
    expect(before.encounter!.enemyHitPoints, 12);
  });

  test('active Shield and Force immunity leave target HP unchanged', () {
    final before = _campaign();
    final result = preview(
      before,
      damage: volley(
        defenses: const [
          SrdMissileTargetDefense(
            targetId: 'primary',
            shieldState: SrdMissileShieldState.activeConfirmed,
            forceDefense: EnemyForceDefense.unknown,
          ),
          SrdMissileTargetDefense(
            targetId: 'extra-a',
            shieldState: SrdMissileShieldState.absentConfirmed,
            forceDefense: EnemyForceDefense.immune,
          ),
        ],
      ),
    );
    expect(result.remainingHitPoints('primary'), 12);
    expect(result.remainingHitPoints('extra-a'), 6);
    expect(result.targets.every((hit) => hit.appliedDamage == 0), isTrue);
  });

  test('primary defeat with living extras requires separate victory logic', () {
    final before = _campaign(fight: _fight.copyWith(enemyHitPoints: 1));
    final result = preview(before);
    expect(result.remainingHitPoints('primary'), 0);
    expect(result.remainingHitPoints('extra-a'), 4);
    expect(result.primaryDefeated, isTrue);
    expect(result.livingTrackedCreaturesRemain, isTrue);
    expect(result.requiresMultiActorVictoryResolution, isTrue);
    expect(before.encounter!.isFinished, isFalse);
  });

  test('primary defeat without living tracked creatures is unambiguous', () {
    final before = _campaign(
      fight: _fight.copyWith(enemyHitPoints: 1),
      extras: const [
        TrackedAreaCreature(
          id: 'extra-a',
          name: 'Letzter Begleiter',
          hitPoints: 2,
          maxHitPoints: 2,
        ),
      ],
    );
    final result = preview(before);
    expect(result.primaryDefeated, isTrue);
    expect(result.livingTrackedCreaturesRemain, isFalse);
    expect(result.requiresMultiActorVictoryResolution, isFalse);
  });

  test('wrong revision, encounter, confirmation and actor fail closed', () {
    final before = _campaign();
    expect(() => preview(before, revision: before.revision + 1), throwsFormatException);
    expect(() => preview(before, encounterId: 'other'), throwsFormatException);
    expect(() => preview(before, evidence: false), throwsFormatException);
    expect(
      () => preview(before.copyWith(encounter: _fight.copyWith(activeParticipant: 'enemy'))),
      throwsFormatException,
    );
    expect(
      () => preview(before.copyWith(encounter: _fight.copyWith(enemyHitPoints: 0))),
      throwsFormatException,
    );
    expect(
      () => preview(before.copyWith(pendingRoll: const PendingRoll(
        id: 'pending',
        type: 'attack',
        modifier: 0,
        difficulty: 12,
      ))),
      throwsFormatException,
    );
  });

  test('unknown, dead, and duplicate saved target IDs are refused', () {
    final before = _campaign();
    final ids = ['primary', 'foreign', 'foreign'];
    final unknown = const SrdMagicMissileTarget(
      id: 'foreign',
      creatureConfirmed: true,
      visibleConfirmed: true,
      within120FeetConfirmed: true,
      noTotalCoverConfirmed: true,
    );
    expect(
      () => preview(
        before,
        allocation: plan(ids: ids, targets: [_main, unknown]),
        damage: volley(
          ids: ids,
          defenses: const [
            _defensePrimary,
            SrdMissileTargetDefense(
              targetId: 'foreign',
              shieldState: SrdMissileShieldState.absentConfirmed,
              forceDefense: EnemyForceDefense.normal,
            ),
          ],
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => preview(before.copyWith(trackedAreaCreatures: [
        _creatureA.copyWith(hitPoints: 0),
        _creatureB,
      ])),
      throwsFormatException,
    );
    expect(
      () => preview(before.copyWith(trackedAreaCreatures: [
        _creatureA,
        _creatureA,
      ])),
      throwsFormatException,
    );
    expect(
      () => preview(before.copyWith(trackedAreaCreatures: [
        const TrackedAreaCreature(
          id: 'primary',
          name: 'Gefälschte ID',
          hitPoints: 5,
          maxHitPoints: 5,
        ),
      ])),
      throwsFormatException,
    );
  });

  test('different allocation order is rejected before any HP preview', () {
    final before = _campaign();
    final allocation = plan();
    final alternative = volley(ids: const ['primary', 'primary', 'extra-a']);
    expect(
      () => preview(before, allocation: allocation, damage: alternative),
      throwsFormatException,
    );
  });

  test('no caller data or serialized campaign is mutated; preview is frozen', () {
    final before = _campaign();
    final initial = before.toJson();
    final result = preview(before);
    expect(before.toJson(), initial);
    expect(before.trackedAreaCreatures.first.hitPoints, 6);
    expect(before.encounter!.enemyHitPoints, 12);
    expect(before.revision, 0);
    expect(before.events, isEmpty);
    expect(() => result.targets.clear(), throwsUnsupportedError);
    final restored = Campaign.fromJson(before.toJson());
    final restoredResult = preview(restored);
    expect(restoredResult.remainingHitPoints('primary'), 8);
    expect(restoredResult.remainingHitPoints('extra-a'), 4);
  });
}
