import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/campaign_repository.dart';
import '../domain/game_engine.dart';
import '../domain/ai_story.dart';
import '../domain/models.dart';
import '../domain/acid_splash_rules.dart';
import '../domain/srd_extra_creature_attack_rules.dart';
import '../domain/srd_spell_preflight_rules.dart';
import '../domain/srd_spell_inventory_rules.dart';
import '../domain/hero_shield_reaction_rules.dart';
import '../domain/damage_rules.dart';
import '../domain/enemy_force_defense.dart';
import '../domain/condition_effects.dart';
import '../domain/saving_throw_class_actions.dart';
import 'backend_narrator.dart';

/// UI state changes only after an atomic repository commit succeeds.
class GameController extends ChangeNotifier {
  GameController({
    required this.repository,
    GameEngine? engine,
    BackendNarrator? narrator,
  }) : engine = engine ?? GameEngine(),
       narrator = narrator ?? BackendNarrator();

  final CampaignRepository repository;
  final GameEngine engine;
  final BackendNarrator narrator;
  List<Campaign> campaigns = [];
  List<HeroCharacter> characters = [];
  Campaign? currentCampaign;
  bool busy = false;
  String? error;
  bool _disposed = false;

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void clearError() {
    error = null;
    _changed();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;
    busy = true;
    error = null;
    _changed();
    try {
      await action();
    } catch (failure) {
      error = switch (failure) {
        FormatException() => failure.message,
        CampaignConflictException() => failure.message,
        InvalidSaveException() => failure.message,
        StateError() => failure.message.toString(),
        _ =>
          'Die Änderung konnte nicht bestätigt werden. '
              'Dein letzter gespeicherter Spielstand bleibt erhalten.',
      };
    } finally {
      busy = false;
      _changed();
    }
  }

  Future<void> _reload() async {
    campaigns = await repository.loadCampaigns();
    characters = await repository.loadCharacters();
  }

  Future<void> initialize() => _run(() async {
    await _reload();
    final settings = await repository.loadSettings();
    // A saved address is a preference, never permission to transmit a campaign.
    // Session tokens and paid-provider consent deliberately do not survive restart.
    final url = settings['backendUrl'];
    if (url is String && url.length <= 2048) narrator.backendUrl = url;
    final limit = settings['backendRequestLimit'];
    if (limit is int && limit >= 1 && limit <= 100) {
      narrator.requestLimit = limit;
    }
    final id = settings['lastCampaignId'];
    if (id is String) currentCampaign = await repository.getCampaign(id);
  });

  Future<void> _remember(String? id) async {
    final settings = await repository.loadSettings();
    settings['lastCampaignId'] = id;
    await repository.saveSettings(settings);
  }

  Future<void> _create(Campaign campaign) async {
    await repository.saveCampaign(campaign, events: campaign.events);
    currentCampaign = campaign;
    await _remember(campaign.id);
    await _reload();
  }

  Future<void> createDemo() => _run(() => _create(engine.createDemo()));
  Future<void> newCampaign(HeroCharacter hero) => _run(() async {
    final valid = HeroCharacter.fromJson(hero.toJson());
    await _create(engine.createDemo(hero: valid));
  });

  /// Starts the fully prewritten German solo adventure without a provider.
  Future<void> newRabenwachtCampaign(HeroCharacter hero) => _run(() async {
    final valid = HeroCharacter.fromJson(hero.toJson());
    await _create(engine.createRabenwacht(valid));
  });

  /// Opt-in generative campaign creation. No story is saved on network,
  /// validation or provider failure; the hero sheet is kept unchanged.
  Future<void> newAiCampaign(
    HeroCharacter hero, {
    required String theme,
  }) => _run(() async {
    if (!narrator.enabled) {
      throw const FormatException(
        'Verbinde unter Optionen einen KI-Spielleiter-Server.',
      );
    }
    if (theme.trim().isEmpty || theme.length > 300) {
      throw const FormatException(
        'Das Thema muss 1 bis 300 Zeichen enthalten.',
      );
    }
    final valid = HeroCharacter.fromJson(hero.toJson());
    final response = await narrator.planStory(
      heroName: valid.name,
      heroClass: valid.classSummary,
      theme: theme,
    );
    if (response == null) {
      throw const FormatException(
        'Die Geschichte konnte nicht erzeugt werden. Es wurde keine Kampagne gespeichert.',
      );
    }
    final plan = AiStoryPlan.fromJson(response);
    final campaign = engine.createAiCampaign(
      valid,
      plan,
      provider: narrator.provider ?? 'mock',
    );
    await _create(campaign);
  });

  Future<void> acceptAdventure() => _run(() async {
    final current = currentCampaign;
    if (current == null) {
      throw const FormatException('Keine Kampagne geöffnet.');
    }
    await _commit(engine.acceptAdventure(current));
  });

  Future<void> rejectAdventure() => _run(() async {
    final current = currentCampaign;
    if (current == null) {
      throw const FormatException('Keine Kampagne geöffnet.');
    }
    await _commit(engine.rejectAdventure(current));
  });

  Future<void> openCampaign(String id) => _run(() async {
    final loaded = await repository.getCampaign(id);
    if (loaded == null) {
      throw const FormatException('Spielstand nicht gefunden.');
    }
    currentCampaign = loaded;
    await _remember(id);
  });

  Future<void> _commit(GameUpdate update) async {
    final previous = currentCampaign;
    await repository.saveCampaign(
      update.campaign,
      events: update.events,
      expectedRevision: previous?.revision,
    );
    currentCampaign = update.campaign;
    await _reload();
  }

  /// Stable request IDs let callers retry after a lost acknowledgement.
  /// A matching confirmed event is never executed or narrated again.
  Future<void> sendAction(String text, {String? requestId}) => _run(() async {
    final campaign = currentCampaign;
    if (campaign == null) {
      throw const FormatException('Starte zuerst ein Abenteuer.');
    }
    if (text.trim().isEmpty || text.length > 4000) {
      throw const FormatException(
        'Gib eine Handlung mit 1 bis 4000 Zeichen ein.',
      );
    }
    if (requestId != null) {
      if (requestId.isEmpty ||
          requestId.length > 128 ||
          RegExp(r'[^A-Za-z0-9_-]').hasMatch(requestId)) {
        throw const FormatException('Ungültige Handlungskennung.');
      }
      // The persisted journal is checked before rolls or provider requests.
      final saved = await repository.getCampaign(campaign.id);
      if (saved == null) {
        throw const FormatException('Der Spielstand wurde nicht gefunden.');
      }
      for (final event in saved.events) {
        if (event.payload['actionRequestId'] != requestId) continue;
        if (event.payload['actionRequestText'] != text.trim()) {
          throw const FormatException(
            'Diese Handlungskennung gehört bereits zu einem anderen Text.',
          );
        }
        currentCampaign = saved;
        await _reload();
        return; // Previously confirmed: no second application of rules.
      }
      if (saved.revision != campaign.revision) {
        throw const CampaignConflictException(
          'Der Spielstand wurde inzwischen geändert. Bitte neu laden.',
        );
      }
    }
    final update = await _withNarration(engine.act(campaign, text), text);
    await _commit(requestId == null
        ? update
        : _withActionReceipt(update, requestId, text.trim()));
  });

  /// Attaches a durable receipt to the first confirmed event, without an
  /// additional event or a migration of the existing SQLite schema.
  GameUpdate _withActionReceipt(
    GameUpdate update,
    String requestId,
    String action,
  ) {
    if (update.events.isEmpty) {
      throw StateError('Die Handlung besitzt kein bestätigbares Ereignis.');
    }
    final original = update.events.first;
    final receipt = GameEvent(
      id: original.id,
      campaignId: original.campaignId,
      sessionId: original.sessionId,
      timestamp: original.timestamp,
      type: original.type,
      entities: original.entities,
      payload: {
        ...original.payload,
        'actionRequestId': requestId,
        'actionRequestText': action,
      },
    );
    return GameUpdate(
      campaign: update.campaign.copyWith(events: [
        for (final event in update.campaign.events)
          event.id == original.id ? receipt : event,
      ]),
      events: [receipt, ...update.events.skip(1)],
    );
  }
  Future<GameUpdate> _withNarration(GameUpdate update, String action) async {
    // Mechanical results and roll requests always use the authoritative local
    // text. External narration can enrich only a validated narrative turn.
    if (!narrator.enabled ||
        update.events.length != 1 ||
        update.events.single.type != 'narrative.turn') {
      return update;
    }
    final campaign = update.campaign;
    final memories = MemoryEngine.retrieve(campaign, action);
    if (campaign.storyBible['mode'] == 'ai') {
      try {
        final context = campaign.storyBible;
        final recent = campaign.messages
            .where((message) => message.role == 'player')
            .map((message) => message.text)
            .where((value) => value.trim().isNotEmpty)
            .toList();
        final response = await narrator.advanceStory(
          campaignId: campaign.id,
          heroName: campaign.hero.name,
          action: action.length > 2000 ? action.substring(0, 2000) : action,
          scene: campaign.scene,
          premise: context['premise'] ?? '',
          goal: context['goal'] ?? '',
          secret: context['secret'] ?? '',
          threads: [
            for (final t in campaign.storyThreads)
              {
                'id': t.id,
                'title': t.title,
                'description': t.description,
                'status': t.status,
              },
          ],
          npcs: [
            for (final npc in campaign.npcs)
              {
                'id': npc.id,
                'name': npc.name,
                'relationship': npc.relationship,
              },
          ],
          memories: memories
              .take(12)
              .map(
                (value) => value.length > 400 ? value.substring(0, 400) : value,
              )
              .toList(),
          recentActions: recent.reversed
              .take(6)
              .toList()
              .reversed
              .map(
                (value) =>
                    value.length > 2000 ? value.substring(0, 2000) : value,
              )
              .toList(),
        );
        if (response == null) return update;
        final step = AiStoryStep.fromJson(response, campaign);
        return engine.applyAiStoryStep(
          update,
          step,
          provider: narrator.provider ?? 'mock',
          decision: action,
        );
      } catch (_) {
        narrator.statusMessage =
            'Der KI-Fortschritt wurde nicht übernommen. Der bestätigte lokale Spielzug bleibt erhalten.';
        return update;
      }
    }
    try {
      final response = await narrator.narrate(
        campaignId: campaign.id,
        playerName: campaign.hero.name,
        action: action,
        scene: campaign.scene,
        outcome: update.narration,
        memories: memories,
      );
      if (response == null) return update;
      return engine.replaceNarration(
        update,
        text: response.text,
        provider: response.provider,
      );
    } catch (_) {
      narrator.statusMessage =
          'Die Backendantwort konnte nicht sicher übernommen werden. '
          'Deine Handlung wird mit der lokalen Demo fortgesetzt.';
      return update;
    }
  }

  Future<void> connectNarrator({
    required String url,
    required String sessionToken,
    bool allowPaidProvider = false,
    int requestLimit = 20,
  }) => _run(() async {
    await narrator.connect(
      url: url,
      sessionToken: sessionToken,
      allowPaidProvider: allowPaidProvider,
      requestLimit: requestLimit,
    );
    if (!narrator.enabled) return;
    try {
      final settings = await repository.loadSettings();
      settings['backendUrl'] = narrator.backendUrl;
      settings['backendRequestLimit'] = narrator.requestLimit;
      await repository.saveSettings(settings);
    } catch (_) {
      narrator.disconnect();
      rethrow;
    }
  });

  Future<void> disconnectNarrator() async {
    narrator.disconnect();
    _changed();
  }

  Future<void> resolveRoll({int? natural, int? total}) => _run(() async {
    final campaign = currentCampaign;
    if (campaign == null) throw const FormatException('Keine aktive Kampagne.');
    await _commit(engine.resolveRoll(campaign, natural: natural, total: total));
  });

  Future<void> resolveDeathSaveDecision({
    required String campaignId,
    required int expectedRevision,
    SavingThrowRerollFeature? feature,
  }) => _run(() async {
    final current = _effectCampaign(campaignId, expectedRevision);
    await _commit(engine.resolveDeathSaveDecision(current, feature: feature));
  });

  Campaign _effectCampaign(String campaignId, int expectedRevision) {
    final current = currentCampaign;
    if (current == null ||
        current.id != campaignId ||
        current.revision != expectedRevision) {
      throw const FormatException(
        'Der Spielstand hat sich geändert. Bitte den Effekt erneut öffnen.',
      );
    }
    return current;
  }

  /// The caller must supply a plan from verified SRD preflight.
  /// This action only books previously resolved effects and material costs;
  /// no free-text story or generic combat spell effect may use this endpoint.
  Future<void> commitConfirmedSpellMaterialCast({
    required String campaignId,
    required int expectedRevision,
    required SrdSpellCastPlan plan,
    required bool effectResolvedSeparatelyConfirmed,
    required bool materialIdentityAndQuantityConfirmed,
    List<SrdConsumedMaterial> consumedMaterials = const [],
  }) => _run(() async {
    final current = _effectCampaign(campaignId, expectedRevision);
    await _commit(
      engine.commitConfirmedSpellMaterialCast(
        current,
        plan: plan,
        effectResolvedSeparatelyConfirmed: effectResolvedSeparatelyConfirmed,
        materialIdentityAndQuantityConfirmed:
            materialIdentityAndQuantityConfirmed,
        consumedMaterials: consumedMaterials,
      ),
    );
  });

  Future<void> standUp({
    required String campaignId,
    required int expectedRevision,
  }) => _run(() async {
    final current = _effectCampaign(campaignId, expectedRevision);
    await _commit(engine.standUp(current));
  });

  Future<void> crawl({
    required String campaignId,
    required int expectedRevision,
    required int distanceFeet,
    required bool difficultTerrain,
  }) => _run(() async {
    final current = _effectCampaign(campaignId, expectedRevision);
    await _commit(
      engine.crawl(
        current,
        distanceFeet: distanceFeet,
        difficultTerrain: difficultTerrain,
      ),
    );
  });

  Future<void> registerConfirmedSpellEffect({
    required String campaignId,
    required int expectedRevision,
    required String spellName,
    required String source,
    required bool concentrationBound,
    required int? ownTurnEnds,
  }) => _run(() async {
    final current = _effectCampaign(campaignId, expectedRevision);
    await _commit(
      engine.registerConfirmedSpellEffect(
        current,
        spellName: spellName,
        source: source,
        concentrationBound: concentrationBound,
        ownTurnEnds: ownTurnEnds,
      ),
    );
  });

  Future<void> removeConfirmedSpellEffect({
    required String campaignId,
    required int expectedRevision,
    required String effectId,
  }) => _run(() async {
    final current = _effectCampaign(campaignId, expectedRevision);
    await _commit(engine.removeConfirmedSpellEffect(
      current,
      effectId: effectId,
    ));
  });

  Future<void> applyConditionEffect({
    required String campaignId,
    required int expectedRevision,
    required String source,
    required String condition,
    required ConditionEffectDuration duration,
  }) => _run(() async {
    final current = _effectCampaign(campaignId, expectedRevision);
    await _commit(
      engine.applyConditionEffect(
        current,
        source: source,
        condition: condition,
        duration: duration,
      ),
    );
  });

  Future<void> removeConditionEffect({
    required String campaignId,
    required int expectedRevision,
    required String effectId,
  }) => _run(() async {
    final current = _effectCampaign(campaignId, expectedRevision);
    await _commit(engine.removeConditionEffect(current, effectId: effectId));
  });

  Future<void> applyDamage({
    required String campaignId,
    required int expectedRevision,
    required String source,
    required List<DamageComponent> components,
    required DamageDefenses defenses,
    bool critical = false,
  }) => _run(() async {
    final current = _effectCampaign(campaignId, expectedRevision);
    await _commit(
      engine.applyDamage(
        current,
        source: source,
        components: components,
        defenses: defenses,
        critical: critical,
      ),
    );
  });

  Future<void> applyHealing({
    required String campaignId,
    required int expectedRevision,
    required String source,
    required int amount,
  }) => _run(() async {
    final current = _effectCampaign(campaignId, expectedRevision);
    await _commit(engine.applyHealing(current, source: source, amount: amount));
  });

  Future<void> grantTemporaryHitPoints({
    required String campaignId,
    required int expectedRevision,
    required String source,
    required int amount,
    bool replaceExisting = false,
  }) => _run(() async {
    final current = _effectCampaign(campaignId, expectedRevision);
    await _commit(
      engine.grantTemporaryHitPoints(
        current,
        source: source,
        amount: amount,
        replaceExisting: replaceExisting,
      ),
    );
  });

  Future<void> endTurnWithShield({
    required String campaignId,
    required int expectedRevision,
    required HeroShieldReactionPlan plan,
  }) => _run(() async {
    final current = _effectCampaign(campaignId, expectedRevision);
    await _commit(engine.endHeroTurn(current, shieldPlan: plan));
  });

  Future<void> resolveEnemyShieldHit({
    required String campaignId,
    required int expectedRevision,
    HeroShieldReactionPlan? plan,
  }) => _run(() async {
    final current = _effectCampaign(campaignId, expectedRevision);
    await _commit(
      engine.resolvePendingEnemyShieldHit(current, shieldPlan: plan),
    );
  });

  Future<void> establishManualTurnQueue({
    required String campaignId,
    required int expectedRevision,
    required List<String> orderedActorIds,
    required bool baseInitiativeConfirmed,
    required bool tiedOrderConfirmed,
  }) => _run(() async {
    final current = _effectCampaign(campaignId, expectedRevision);
    await _commit(
      engine.establishManualTurnQueue(
        current,
        orderedActorIds: orderedActorIds,
        baseInitiativeConfirmed: baseInitiativeConfirmed,
        tiedOrderConfirmed: tiedOrderConfirmed,
      ),
    );
  });

  Future<void> manualExtraCreatureAttack({
    required String campaignId,
    required int expectedRevision,
    required String attackerId,
    required String targetId,
    required ConfirmedExtraCreatureAttack attack,
  }) => _run(() async {
    final current = _effectCampaign(campaignId, expectedRevision);
    await _commit(
      engine.manualExtraCreatureAttack(
        current,
        attackerId: attackerId,
        targetId: targetId,
        attack: attack,
      ),
    );
  });

  Future<void> advanceManualTurnQueue({
    required String campaignId,
    required int expectedRevision,
  }) => _run(() async {
    final current = _effectCampaign(campaignId, expectedRevision);
    await _commit(engine.advanceManualTurnQueue(current));
  });

  Future<void> confirmAreaCreatureInitiative({
    required String campaignId,
    required int expectedRevision,
    required String creatureId,
    required int initiativeTotal,
    required String initiativeController,
    required bool initiativeConfirmed,
  }) => _run(() async {
    final current = _effectCampaign(campaignId, expectedRevision);
    await _commit(
      engine.confirmAreaCreatureInitiative(
        current,
        creatureId: creatureId,
        initiativeTotal: initiativeTotal,
        initiativeController: initiativeController,
        initiativeConfirmed: initiativeConfirmed,
      ),
    );
  });

  Future<void> trackAreaCreature({
    required String campaignId,
    required int expectedRevision,
    required String creatureId,
    required String creatureName,
    required int hitPoints,
    required int maxHitPoints,
    required bool valuesConfirmed,
  }) => _run(() async {
    final current = _effectCampaign(campaignId, expectedRevision);
    await _commit(
      engine.trackAreaCreature(
        current,
        creatureId: creatureId,
        creatureName: creatureName,
        hitPoints: hitPoints,
        maxHitPoints: maxHitPoints,
        valuesConfirmed: valuesConfirmed,
      ),
    );
  });

  Future<void> castAcidSplash({
    required String campaignId,
    required int expectedRevision,
    required String castingClass,
    required int confirmedTargetDexteritySaveModifier,
    required bool originWithin60FeetConfirmed,
    required bool currentEnemyIsOnlyCreatureInSphereConfirmed,
    required bool verbalComponentConfirmed,
    required bool somaticComponentConfirmed,
    required bool noUnmodelledDcModifiersConfirmed,
    required bool targetSaveCircumstancesConfirmed,
    required bool targetCoverRelationshipConfirmed,
    required bool effectPathConfirmed,
    required bool noAcidDamageAdjustmentConfirmed,
    bool targetSourceOppositeCover = false,
    bool targetSaveAdvantage = false,
    bool targetSaveDisadvantage = false,
    List<AcidSplashTarget> additionalTargets = const [],
    bool allCreaturesInSphereAccountedForConfirmed = false,
  }) => _run(() async {
    final current = _effectCampaign(campaignId, expectedRevision);
    await _commit(
      engine.castAcidSplash(
        current,
        castingClass: castingClass,
        confirmedTargetDexteritySaveModifier:
            confirmedTargetDexteritySaveModifier,
        originWithin60FeetConfirmed: originWithin60FeetConfirmed,
        currentEnemyIsOnlyCreatureInSphereConfirmed:
            currentEnemyIsOnlyCreatureInSphereConfirmed,
        verbalComponentConfirmed: verbalComponentConfirmed,
        somaticComponentConfirmed: somaticComponentConfirmed,
        noUnmodelledDcModifiersConfirmed: noUnmodelledDcModifiersConfirmed,
        targetSaveCircumstancesConfirmed: targetSaveCircumstancesConfirmed,
        targetCoverRelationshipConfirmed: targetCoverRelationshipConfirmed,
        effectPathConfirmed: effectPathConfirmed,
        noAcidDamageAdjustmentConfirmed: noAcidDamageAdjustmentConfirmed,
        targetSourceOppositeCover: targetSourceOppositeCover,
        targetSaveAdvantage: targetSaveAdvantage,
        targetSaveDisadvantage: targetSaveDisadvantage,
        additionalTargets: additionalTargets,
        allCreaturesInSphereAccountedForConfirmed:
            allCreaturesInSphereAccountedForConfirmed,
      ),
    );
  });

  Future<void> castSacredFlame({
    required String campaignId,
    required int expectedRevision,
    required int confirmedTargetDexteritySaveModifier,
    required bool targetVisibleConfirmed,
    required bool targetWithinRangeConfirmed,
    required bool verbalComponentConfirmed,
    required bool somaticComponentConfirmed,
    required bool noRadiantDamageAdjustmentConfirmed,
    required bool noUnmodelledDcModifiersConfirmed,
    required bool saveCircumstancesConfirmed,
    bool saveAdvantage = false,
    bool saveDisadvantage = false,
  }) => _run(() async {
    final current = _effectCampaign(campaignId, expectedRevision);
    await _commit(
      engine.castSacredFlame(
        current,
        confirmedTargetDexteritySaveModifier:
            confirmedTargetDexteritySaveModifier,
        targetVisibleConfirmed: targetVisibleConfirmed,
        targetWithinRangeConfirmed: targetWithinRangeConfirmed,
        verbalComponentConfirmed: verbalComponentConfirmed,
        somaticComponentConfirmed: somaticComponentConfirmed,
        noRadiantDamageAdjustmentConfirmed: noRadiantDamageAdjustmentConfirmed,
        noUnmodelledDcModifiersConfirmed: noUnmodelledDcModifiersConfirmed,
        saveCircumstancesConfirmed: saveCircumstancesConfirmed,
        saveAdvantage: saveAdvantage,
        saveDisadvantage: saveDisadvantage,
      ),
    );
  });

  Future<void> castFireBolt({
    required String campaignId,
    required int expectedRevision,
    required String castingClass,
    required bool targetVisibleConfirmed,
    required bool targetWithinRangeConfirmed,
    required bool verbalComponentConfirmed,
    required bool somaticComponentConfirmed,
    required bool noFireResistanceOrImmunityConfirmed,
    required bool noUnresolvedShieldReactionConfirmed,
    required bool situationalAttackConditionsConfirmed,
    bool advantage = false,
    bool disadvantage = false,
    bool targetProne = false,
    bool targetWithinFiveFeet = false,
  }) => _run(() async {
    final current = _effectCampaign(campaignId, expectedRevision);
    await _commit(
      engine.castFireBolt(
        current,
        castingClass: castingClass,
        targetVisibleConfirmed: targetVisibleConfirmed,
        targetWithinRangeConfirmed: targetWithinRangeConfirmed,
        verbalComponentConfirmed: verbalComponentConfirmed,
        somaticComponentConfirmed: somaticComponentConfirmed,
        noFireResistanceOrImmunityConfirmed:
            noFireResistanceOrImmunityConfirmed,
        noUnresolvedShieldReactionConfirmed:
            noUnresolvedShieldReactionConfirmed,
        situationalAttackConditionsConfirmed:
            situationalAttackConditionsConfirmed,
        advantage: advantage,
        disadvantage: disadvantage,
        targetProne: targetProne,
        targetWithinFiveFeet: targetWithinFiveFeet,
      ),
    );
  });

  Future<void> castMagicMissile({
    required String campaignId,
    required int expectedRevision,
    required String castingClass,
    required int slotLevel,
    required bool pactMagic,
    required bool targetVisibleConfirmed,
    required bool targetWithinRangeConfirmed,
    required bool verbalComponentConfirmed,
    required bool somaticComponentConfirmed,
    required bool noProtectionConfirmed,
    EnemyForceDefense? confirmedForceDefense,
    bool shieldReactionConfirmed = false,
    bool shieldPreparedAndComponentsConfirmed = false,
    int? confirmedEnemyShieldSlots,
  }) => _run(() async {
    final current = _effectCampaign(campaignId, expectedRevision);
    await _commit(
      engine.castMagicMissile(
        current,
        castingClass: castingClass,
        slotLevel: slotLevel,
        pactMagic: pactMagic,
        targetVisibleConfirmed: targetVisibleConfirmed,
        targetWithinRangeConfirmed: targetWithinRangeConfirmed,
        verbalComponentConfirmed: verbalComponentConfirmed,
        somaticComponentConfirmed: somaticComponentConfirmed,
        noProtectionConfirmed: noProtectionConfirmed,
        confirmedForceDefense: confirmedForceDefense,
        shieldReactionConfirmed: shieldReactionConfirmed,
        shieldPreparedAndComponentsConfirmed:
            shieldPreparedAndComponentsConfirmed,
        confirmedEnemyShieldSlots: confirmedEnemyShieldSlots,
      ),
    );
  });

  Future<void> castHealingSpell({
    required String campaignId,
    required int expectedRevision,
    required String spellName,
    required String castingClass,
    int? slotLevel,
    bool pactMagic = false,
    required bool verbalComponentConfirmed,
    bool somaticComponentConfirmed = false,
  }) => _run(() async {
    final current = _effectCampaign(campaignId, expectedRevision);
    await _commit(
      engine.castHealingSpell(
        current,
        spellName: spellName,
        castingClass: castingClass,
        slotLevel: slotLevel,
        pactMagic: pactMagic,
        verbalComponentConfirmed: verbalComponentConfirmed,
        somaticComponentConfirmed: somaticComponentConfirmed,
      ),
    );
  });

  Future<void> saveSessionRecap() => _run(() async {
    final campaign = currentCampaign;
    if (campaign == null) throw const FormatException('Keine aktive Kampagne.');
    await _commit(engine.saveSessionRecap(campaign));
  });

  Future<void> recordNpcRelationship({
    required String npcId,
    required String relationship,
    required String note,
  }) => _run(() async {
    final campaign = currentCampaign;
    if (campaign == null) throw const FormatException('Keine aktive Kampagne.');
    await _commit(
      engine.recordNpcRelationship(
        campaign,
        npcId: npcId,
        relationship: relationship,
        note: note,
      ),
    );
  });

  Future<void> saveStoryThread({
    String? threadId,
    required String title,
    required String description,
    required String status,
  }) => _run(() async {
    final campaign = currentCampaign;
    if (campaign == null) throw const FormatException('Keine aktive Kampagne.');
    await _commit(
      engine.saveStoryThread(
        campaign,
        threadId: threadId,
        title: title,
        description: description,
        status: status,
      ),
    );
  });

  Future<void> rollDice(String expression) => _run(() async {
    final campaign = currentCampaign;
    if (campaign == null) throw const FormatException('Keine aktive Kampagne.');
    await _commit(engine.rollDice(campaign, expression));
  });

  Future<void> saveHero(HeroCharacter hero) => _run(() async {
    final campaign = currentCampaign;
    if (campaign == null) throw const FormatException('Keine aktive Kampagne.');
    final valid = HeroCharacter.fromJson(hero.toJson());
    if (valid.id != campaign.hero.id) {
      throw const FormatException(
        'Dieser Charakter gehört nicht zum Abenteuer.',
      );
    }
    await _commit(engine.updateHero(campaign, valid));
  });

  Future<void> saveStandaloneHero(HeroCharacter hero) => _run(() async {
    final valid = HeroCharacter.fromJson(hero.toJson());
    final campaign = currentCampaign;
    if (campaign != null && campaign.hero.id == valid.id) {
      // The hero archive and the active campaign share one character identity.
      // Commit through the rule engine so pending rolls and game-state
      // constraints stay valid; SQLite updates both snapshots atomically.
      await _commit(engine.updateHero(campaign, valid));
    } else {
      await repository.saveCharacter(valid);
      await _reload();
    }
  });

  Future<void> deleteCampaign(String id) => _run(() async {
    await repository.deleteCampaign(id);
    if (currentCampaign?.id == id) {
      currentCampaign = null;
      await _remember(null);
    }
    await _reload();
  });

  Future<void> deleteCharacter(String id) => _run(() async {
    await repository.deleteCharacter(id);
    await _reload();
  });

  Future<void> importCampaign(String source) => _run(() async {
    if (source.length > 10 * 1024 * 1024) {
      throw const FormatException(
        'Der Spielstand ist zu groß (maximal 10 MB).',
      );
    }
    final imported = await repository.importCampaign(source);
    currentCampaign = imported;
    await _remember(imported.id);
    await _reload();
  });

  String exportCampaign() {
    final campaign = currentCampaign;
    if (campaign == null) return '';
    return const JsonEncoder.withIndent('  ').convert(campaign.toJson());
  }

  Future<void> importHero(String source) => _run(() async {
    if (source.length > 1024 * 1024) {
      throw const FormatException('Der Charakterbogen ist zu groß.');
    }
    final json = jsonDecode(source);
    if (json is! Map<String, dynamic>) {
      throw const FormatException(
        'Der Charakterbogen muss ein JSON-Objekt sein.',
      );
    }
    await repository.saveCharacter(HeroCharacter.fromJson(json));
    await _reload();
  });

  String exportHero(HeroCharacter hero) =>
      const JsonEncoder.withIndent('  ').convert(hero.toJson());

  Future<void> deleteAllData() => _run(() async {
    narrator.disconnect();
    for (final campaign in await repository.loadCampaigns()) {
      await repository.deleteCampaign(campaign.id);
    }
    for (final hero in await repository.loadCharacters()) {
      await repository.deleteCharacter(hero.id);
    }
    await repository.saveSettings({});
    currentCampaign = null;
    await _reload();
  });

  @override
  void dispose() {
    _disposed = true;
    narrator.dispose();
    super.dispose();
  }
}
