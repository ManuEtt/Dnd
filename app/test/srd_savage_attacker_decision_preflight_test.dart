import 'package:flutter_test/flutter_test.dart';

import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/rules_engine.dart';
import 'package:lebendiger_spielleiter/domain/srd_background_package.dart';
import 'package:lebendiger_spielleiter/domain/srd_savage_attacker_decision_preflight.dart';
import 'package:lebendiger_spielleiter/domain/srd_savage_attacker_pending_hit.dart';
import 'package:lebendiger_spielleiter/domain/ability_generation.dart';

DiceResult dice(List<int> faces) => DiceResult(
  expression: '2d6',
  rolls: faces,
  modifier: 0,
  total: faces.fold<int>(0, (a, b) => a + b),
);

Campaign campaign({bool critical = false}) {
  final demo = GameEngine().createDemo();
  final hero = demo.hero.copyWith(
    background: SrdBackground.soldier.label,
    startingBackgroundPackage: SrdBackgroundPackageChoice(
      background: SrdBackground.soldier,
      takeGold: true,
      gamingSetCatalogId: SrdBackgroundPackageChoice.gamingSets.first.id,
    ),
    weaponDamage: '2d6',
    hitPoints: 20,
    maxHitPoints: 20,
  );
  return demo.copyWith(
    revision: 9,
    hero: hero,
    encounter: const Encounter(
      id: 'enemy-1',
      enemyName: 'Wächter',
      enemyHitPoints: 70,
      enemyMaxHitPoints: 70,
      round: 3,
    ),
    pendingSavageAttackerHit: PendingSavageAttackerHit(
      attackRollId: 'roll-45',
      encounterId: 'enemy-1',
      offeredAtRevision: 9,
      round: 3,
      weaponDamageExpression: '2d6',
      original: dice([1, 2]),
      alternative: dice([5, 6]),
      critical: critical,
      originalCriticalExtra: critical ? dice([2, 3]) : null,
      alternativeCriticalExtra: critical ? dice([6, 6]) : null,
    ),
  );
}

SavageAttackerDecisionPreview request(
  Campaign state, {
  bool alternative = true,
  String rollId = 'roll-45',
  String encounterId = 'enemy-1',
  int revision = 9,
}) => SrdSavageAttackerDecisionPreflight.preview(
  campaign: state,
  attackRollId: rollId,
  encounterId: encounterId,
  expectedRevision: revision,
  chooseAlternative: alternative,
);

void main() {
  test('only the stored dice are used; either result may be selected', () {
    final state = campaign();
    final first = request(state, alternative: false);
    final second = request(state);
    expect(first.attackRollId, 'roll-45');
    expect(first.encounterId, 'enemy-1');
    expect(first.expectedRevision, 9);
    expect(first.chooseAlternative, false);
    expect(first.selectedWeaponSubtotal, first.originalWeaponSubtotal);
    expect(first.weaponDamageDelta, 0);
    expect(second.selectedWeaponSubtotal, second.alternativeWeaponSubtotal);
    expect(second.weaponDamageDelta, 8);
    expect(
      first.originalWeaponSubtotal,
      RulesEngine.weaponDamageSubtotal(state.hero, baseRoll: dice([1, 2])),
    );
    expect(
      second.alternativeWeaponSubtotal,
      RulesEngine.weaponDamageSubtotal(state.hero, baseRoll: dice([5, 6])),
    );
  });

  test('critical alternatives include independent extra weapon dice', () {
    final state = campaign(critical: true);
    final choice = request(state);
    expect(choice.weaponDamageDelta, 15);
    expect(choice.damageComparison.choice.critical, true);
    expect(choice.damageComparison.choice.usedAlternative, true);
  });

  test('save/restart preserves exact decision and never consumes it', () {
    final before = campaign();
    final serialized = before.toJson();
    final loaded = Campaign.fromJson(serialized);
    final preview = request(loaded);
    expect(preview.weaponDamageDelta, 8);
    expect(loaded.toJson(), serialized);
    expect(loaded.encounter!.enemyHitPoints, 70);
    expect(loaded.encounter!.savageAttackerUsedThisTurn, false);
    expect(loaded.revision, 9);
  });

  test('wrong roll, encounter or stale revision is rejected', () {
    final state = campaign();
    expect(() => request(state, rollId: 'roll-46'), throwsFormatException);
    expect(() => request(state, encounterId: 'enemy-2'), throwsFormatException);
    expect(() => request(state, revision: 8), throwsFormatException);
    expect(() => request(state, rollId: 'roll/../../'), throwsFormatException);
    expect(
      () => request(state.copyWith(revision: 10), revision: 10),
      throwsFormatException,
    );
  });

  test('expired proposals and already-used feat cannot be replayed', () {
    final state = campaign();
    expect(
      () => request(state.copyWith(pendingSavageAttackerHit: null)),
      throwsFormatException,
    );
    expect(
      () => request(
        state.copyWith(
          encounter: state.encounter!.copyWith(
            savageAttackerUsedThisTurn: true,
          ),
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => request(
        state.copyWith(
          encounter: state.encounter!.copyWith(round: 4),
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => request(
        state.copyWith(
          encounter: state.encounter!.copyWith(activeParticipant: 'enemy'),
        ),
      ),
      throwsFormatException,
    );
  });

  test('unrelated pending choices cannot authorize a second action', () {
    final state = campaign();
    expect(
      () => request(state.copyWith(
        pendingRoll: const PendingRoll(
          id: 'another',
          type: 'attack',
          modifier: 2,
          difficulty: 10,
          targetId: 'enemy-1',
        ),
      )),
      throwsFormatException,
    );
    expect(
      () => request(state.copyWith(
        pendingDeathSave: const PendingDeathSave(
          originalNatural: 1,
          modifier: 0,
        ),
      )),
      throwsFormatException,
    );
  });

  test('forged total and changed weapon fail independently of UI state', () {
    final state = campaign();
    final json = state.toJson();
    final raw = Map<String, dynamic>.from(
      json['pendingSavageAttackerHit'] as Map<String, dynamic>,
    );
    final tampered = <String, dynamic>{
      ...json,
      'pendingSavageAttackerHit': {
        ...raw,
        'alternative': {
          ...raw['alternative'] as Map,
          'total': 999,
        },
      },
    };
    expect(() => Campaign.fromJson(tampered), throwsFormatException);
    expect(
      () => request(state.copyWith(
        hero: state.hero.copyWith(weaponDamage: '1d6'),
      )),
      throwsFormatException,
    );
  });
}
