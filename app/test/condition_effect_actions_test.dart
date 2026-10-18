import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/condition_effects.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

void main() {
  final engine = GameEngine();

  test(
    'bestätigte Quelle erzeugt nur einen Zustand mit prüfbarem Ereignis',
    () {
      final before = engine.createDemo();
      final update = engine.applyConditionEffect(
        before,
        source: '  Giftfalle  ',
        condition: 'vergiftet',
        duration: ConditionEffectDuration.untilRemoved,
      );
      final effect = update.campaign.hero.conditionEffects.single;
      expect(effect.source, 'Giftfalle');
      expect(effect.condition, 'vergiftet');
      expect(update.campaign.hero.conditions, contains('vergiftet'));
      expect(update.campaign.hero.manualConditions, isEmpty);
      expect(effect.expiresAtOwnTurnEndRound, isNull);
      expect(update.events.single.type, 'condition.effect.added');
      expect(update.events.single.payload['effect'], effect.toJson());
      expect(update.campaign.revision, before.revision + 1);

      final removed = engine.removeConditionEffect(
        update.campaign,
        effectId: effect.id,
      );
      expect(removed.campaign.hero.conditionEffects, isEmpty);
      expect(removed.campaign.hero.conditions, isNot(contains('vergiftet')));
      expect(removed.events.single.type, 'condition.effect.removed');
      expect(removed.events.single.payload['effectId'], effect.id);
    },
  );

  test('zwei Quellen bleiben trotz Entfernen einer Instanz wirksam', () {
    var campaign = engine.createDemo();
    for (final source in ['Wolke', 'Pfeil']) {
      campaign = engine
          .applyConditionEffect(
            campaign,
            source: source,
            condition: 'vergiftet',
            duration: ConditionEffectDuration.untilRemoved,
          )
          .campaign;
    }
    expect(
      campaign.hero.conditions.where((x) => x == 'vergiftet'),
      hasLength(1),
    );
    final first = campaign.hero.conditionEffects.first;
    final remaining = engine.removeConditionEffect(
      campaign,
      effectId: first.id,
    );
    expect(remaining.campaign.hero.conditionEffects, hasLength(1));
    expect(remaining.campaign.hero.conditions, contains('vergiftet'));
  });

  test('Zugende ohne aktive Begegnung wird vor Veränderung abgewiesen', () {
    final campaign = engine.createDemo();
    expect(
      () => engine.applyConditionEffect(
        campaign,
        source: 'Magischer Nebel',
        condition: 'blind',
        duration: ConditionEffectDuration.currentTurnEnd,
      ),
      throwsFormatException,
    );
    expect(
      () => engine.applyConditionEffect(
        campaign,
        source: 'Giftfalle',
        condition: 'tot',
        duration: ConditionEffectDuration.untilRemoved,
      ),
      throwsFormatException,
    );
    expect(
      () => engine.removeConditionEffect(campaign, effectId: 'unbekannt'),
      throwsFormatException,
    );
  });

  test('nur eigene bestätigte aktuelle/nächste Runde erzeugen Endpunkt', () {
    final before = engine.createDemo();
    final combat = before.copyWith(
      encounter: const Encounter(
        id: 'kampf-123',
        enemyName: 'Wächter',
        enemyHitPoints: 15,
        enemyMaxHitPoints: 15,
        round: 3,
      ),
    );
    final current = engine.applyConditionEffect(
      combat,
      source: 'Falle',
      condition: 'blind',
      duration: ConditionEffectDuration.currentTurnEnd,
    );
    final next = engine.applyConditionEffect(
      current.campaign,
      source: 'Giftpfeil',
      condition: 'vergiftet',
      duration: ConditionEffectDuration.nextTurnEnd,
    );
    expect(
      current.campaign.hero.conditionEffects.single.expiresAtOwnTurnEndRound,
      3,
    );
    expect(
      next.campaign.hero.conditionEffects.last.expiresAtOwnTurnEndRound,
      4,
    );
    expect(
      next.campaign.hero.conditionEffects.last.expiresInEncounterId,
      'kampf-123',
    );

    expect(
      () => engine.applyConditionEffect(
        combat.copyWith(
          encounter: combat.encounter!.copyWith(activeParticipant: 'enemy'),
        ),
        source: 'Fallbeispiel',
        condition: 'blind',
        duration: ConditionEffectDuration.currentTurnEnd,
      ),
      throwsFormatException,
    );
  });

  test(
    'Handlungsunfähigkeit beendet Konzentration und Kampfrausch dauerhaft',
    () {
      final initial = engine.createDemo();
      final withFight = initial.copyWith(
        hero: initial.hero.copyWith(concentratingOn: 'Segen'),
        encounter: const Encounter(
          id: 'kampf-1',
          enemyName: 'Wächter',
          enemyHitPoints: 10,
          enemyMaxHitPoints: 10,
          rageUntilRound: 5,
          dodgeActive: true,
        ),
      );
      final updated = engine.applyConditionEffect(
        withFight,
        source: 'Bestätigter Betäubungseffekt',
        condition: 'betäubt',
        duration: ConditionEffectDuration.untilRemoved,
      );
      expect(updated.campaign.hero.concentratingOn, isEmpty);
      expect(updated.campaign.encounter!.rageUntilRound, 0);
      expect(updated.campaign.encounter!.dodgeActive, isFalse);
      expect(updated.events.single.payload['concentrationEnded'], isTrue);
      final cleared = engine.removeConditionEffect(
        updated.campaign,
        effectId: updated.campaign.hero.conditionEffects.single.id,
      );
      expect(cleared.campaign.encounter!.rageUntilRound, 0);
      expect(cleared.campaign.hero.concentratingOn, isEmpty);
    },
  );
}
