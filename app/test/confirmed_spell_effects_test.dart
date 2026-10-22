import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/confirmed_spell_effects.dart';
import 'package:lebendiger_spielleiter/domain/condition_effects.dart';
import 'package:lebendiger_spielleiter/domain/cover_rules.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

void main() {
  final engine = GameEngine();

  Campaign prepared({
    bool combat = true,
    int round = 3,
    String concentration = 'Segen',
  }) {
    final original = engine.createDemo();
    final hero = original.hero.copyWith(
      spells: ['Segen', 'Magische Rüstung'],
      concentratingOn: concentration,
    );
    return original.copyWith(
      hero: hero,
      encounter: combat
          ? Encounter(
              id: 'battle',
              enemyName: 'Wächter',
              enemyHitPoints: 60,
              enemyMaxHitPoints: 60,
              round: round,
              heroCover: CoverLevel.total,
            )
          : null,
    );
  }

  test('bestätigter Eintrag hat keine Zauber-, Ressourcen- oder Schadenswirkung', () {
    final before = prepared();
    final result = engine.registerConfirmedSpellEffect(
      before,
      spellName: 'Segen',
      source: 'Regelgeprüfte Zauberwirkung',
      concentrationBound: true,
      ownTurnEnds: 3,
    );
    final effect = result.campaign.hero.confirmedSpellEffects.single;
    expect(effect.id, isNotEmpty);
    expect(effect.spellName, 'Segen');
    expect(effect.source, 'Regelgeprüfte Zauberwirkung');
    expect(effect.concentrationBound, isTrue);
    expect(effect.expiresInEncounterId, 'battle');
    expect(effect.expiresAtOwnTurnEndRound, 5);
    expect(result.campaign.hero.spentSpellSlots, before.hero.spentSpellSlots);
    expect(result.campaign.hero.hitPoints, before.hero.hitPoints);
    expect(result.campaign.hero.conditions, before.hero.conditions);
    expect(result.campaign.encounter!.actionUsed, isFalse);
    expect(result.events.single.type, 'spell.effect.confirmed');
    expect(result.events.single.payload['effect'], effect.toJson());
    expect(result.campaign.revision, before.revision + 1);
  });

  test('eigene bestätigte Zugenden beenden eine Zauberwirkung genau einmal', () {
    var state = engine.registerConfirmedSpellEffect(
      prepared(),
      spellName: 'Segen',
      source: 'Bestätigter Effekt',
      concentrationBound: true,
      ownTurnEnds: 3,
    ).campaign;
    final record = state.hero.confirmedSpellEffects.single;
    expect(ConfirmedSpellEffectRules.remainingOwnTurnEnds(
      record,
      state.encounter,
    ), 3);
    for (var n = 1; n <= 3; n++) {
      state = engine.endHeroTurn(state).campaign;
      expect(state.encounter!.round, 3 + n);
      expect(state.hero.confirmedSpellEffects.isEmpty, n == 3);
      expect(state.hero.concentratingOn, n == 3 ? '' : 'Segen');
    }
    expect(state.hero.hitPoints, 12);
  });

  test('Konzentrationsverlust räumt bestätigte Quelle atomar ab', () {
    final tracked = engine.registerConfirmedSpellEffect(
      prepared(),
      spellName: 'Segen',
      source: 'Bestätigte Quelle',
      concentrationBound: true,
      ownTurnEnds: 10,
    ).campaign;
    final stunned = engine.applyConditionEffect(
      tracked,
      source: 'Betäubungsfalle',
      condition: 'betäubt',
      duration: ConditionEffectDuration.untilRemoved,
    );
    expect(stunned.campaign.hero.concentratingOn, isEmpty);
    expect(stunned.campaign.hero.confirmedSpellEffects, isEmpty);
    expect(stunned.events.single.type, 'condition.effect.added');
    expect(stunned.events.single.payload['concentrationEnded'], isTrue);
  });

  test('Fremde und alte Begegnungen ändern den Countdown nicht', () {
    final effect = ConfirmedSpellEffect(
      id: 'fixed',
      spellName: 'Segen',
      source: 'Bestätigt',
      expiresInEncounterId: 'battle',
      expiresAtOwnTurnEndRound: 7,
    );
    final own = prepared(round: 5).encounter!;
    expect(ConfirmedSpellEffectRules.remainingOwnTurnEnds(effect, own), 3);
    expect(
      ConfirmedSpellEffectRules.remainingOwnTurnEnds(
        effect,
        own.copyWith(activeParticipant: 'enemy'),
      ),
      isNull,
    );
    expect(
      ConfirmedSpellEffectRules.remainingOwnTurnEnds(
        effect,
        own.copyWith(id: 'another'),
      ),
      isNull,
    );
    expect(
      ConfirmedSpellEffectRules.remainingOwnTurnEnds(
        effect,
        own.copyWith(round: 8),
      ),
      isNull,
    );
    expect(ConfirmedSpellEffectRules.remainingOwnTurnEnds(effect, null), isNull);
    final hero = prepared().hero.copyWith(confirmedSpellEffects: [effect]);
    expect(ConfirmedSpellEffectRules.expireAtOwnTurnEnd(
      hero,
      encounterId: 'another',
      round: 7,
    ).confirmedSpellEffects, hasLength(1));
  });

  test('fehlende Belege, fremde Züge und Endrundengrenze sind abgewiesen', () {
    final before = prepared();
    for (final scenario in [
      () => engine.registerConfirmedSpellEffect(
        before,
        spellName: 'Nicht bekannt',
        source: 'Quelle',
        concentrationBound: false,
        ownTurnEnds: 3,
      ),
      () => engine.registerConfirmedSpellEffect(
        before,
        spellName: 'Magische Rüstung',
        source: 'Quelle',
        concentrationBound: true,
        ownTurnEnds: 3,
      ),
      () => engine.registerConfirmedSpellEffect(
        before,
        spellName: 'Segen',
        source: 'Quelle',
        concentrationBound: false,
        ownTurnEnds: 101,
      ),
      () => engine.registerConfirmedSpellEffect(
        prepared(round: 999999),
        spellName: 'Segen',
        source: 'Quelle',
        concentrationBound: false,
        ownTurnEnds: 10,
      ),
      () => engine.registerConfirmedSpellEffect(
        prepared(combat: false),
        spellName: 'Segen',
        source: 'Quelle',
        concentrationBound: false,
        ownTurnEnds: 3,
      ),
      () => engine.registerConfirmedSpellEffect(
        before.copyWith(
          encounter: before.encounter!.copyWith(activeParticipant: 'enemy'),
        ),
        spellName: 'Segen',
        source: 'Quelle',
        concentrationBound: false,
        ownTurnEnds: 3,
      ),
    ]) {
      expect(scenario, throwsFormatException);
    }
    expect(before.hero.confirmedSpellEffects, isEmpty);
    expect(before.revision, 0);
  });

  test('Alt-Schema 1 bleibt ohne neues Feld identisch', () {
    final old = prepared().toJson();
    final oldHero = old['hero'] as Map<String, dynamic>;
    expect(oldHero.containsKey('confirmedSpellEffects'), isFalse);
    final restored = Campaign.fromJson(old);
    expect(restored.hero.confirmedSpellEffects, isEmpty);
    expect(restored.toJson(), old);
  });

  test('neue Einträge sind serialisierbar; Fälschungen fail-closed', () {
    final state = engine.registerConfirmedSpellEffect(
      prepared(),
      spellName: 'Segen',
      source: 'Bestätigt',
      concentrationBound: true,
      ownTurnEnds: 10,
    ).campaign;
    final restored = Campaign.fromJson(
      jsonDecode(jsonEncode(state.toJson())) as Map<String, dynamic>,
    );
    expect(restored.toJson(), state.toJson());
    final forgedId = state.toJson();
    final hero = forgedId['hero'] as Map<String, dynamic>;
    final existing = (hero['confirmedSpellEffects'] as List).single;
    hero['confirmedSpellEffects'] = [existing, existing];
    expect(() => Campaign.fromJson(forgedId), throwsFormatException);
    final forgedConcentration = state.toJson();
    (forgedConcentration['hero'] as Map<String, dynamic>)
        .remove('concentratingOn');
    expect(
      () => Campaign.fromJson(forgedConcentration),
      throwsFormatException,
    );
    expect(
      () => ConfirmedSpellEffect.fromJson({
        ...restored.hero.confirmedSpellEffects.single.toJson(),
        'expiresAtOwnTurnEndRound': '5',
      }),
      throwsFormatException,
    );
  });

  test('einzelnes Entfernen ist revisionspflichtig, ohne Konzentration zu erfinden', () {
    final before = prepared();
    final tracked = engine.registerConfirmedSpellEffect(
      before,
      spellName: 'Segen',
      source: 'Bestätigt',
      concentrationBound: true,
      ownTurnEnds: null,
    ).campaign;
    final removed = engine.removeConfirmedSpellEffect(
      tracked,
      effectId: tracked.hero.confirmedSpellEffects.single.id,
    );
    expect(removed.campaign.hero.confirmedSpellEffects, isEmpty);
    expect(removed.campaign.hero.concentratingOn, 'Segen');
    expect(removed.events.single.type, 'spell.effect.recordRemoved');
    expect(
      () => engine.removeConfirmedSpellEffect(
        removed.campaign,
        effectId: 'unknown',
      ),
      throwsFormatException,
    );
  });
}
