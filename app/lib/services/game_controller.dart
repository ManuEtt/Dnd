import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/campaign_repository.dart';
import '../domain/game_engine.dart';
import '../domain/ai_story.dart';
import '../domain/models.dart';
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
  Future<void> createArescan() => _run(() => _create(engine.createArescan()));
  Future<void> newCampaign(HeroCharacter hero) => _run(() async {
    final valid = HeroCharacter.fromJson(hero.toJson());
    await _create(engine.createDemo(hero: valid));
  });

  /// Opt-in generative campaign creation. No story is saved on network,
  /// validation or provider failure; the hero sheet is kept unchanged.
  Future<void> newAiCampaign(HeroCharacter hero, {required String theme}) =>
      _run(() async {
    if (!narrator.enabled) {
      throw const FormatException(
        'Verbinde unter Optionen einen KI-Spielleiter-Server.');
    }
    if (theme.trim().isEmpty || theme.length > 300) {
      throw const FormatException('Das Thema muss 1 bis 300 Zeichen enthalten.');
    }
    final valid = HeroCharacter.fromJson(hero.toJson());
    final response = await narrator.planStory(
      heroName: valid.name, heroClass: valid.className, theme: theme,
    );
    if (response == null) {
      throw const FormatException(
        'Die Geschichte konnte nicht erzeugt werden. Es wurde keine Kampagne gespeichert.');
    }
    final plan = AiStoryPlan.fromJson(response);
    final campaign = engine.createAiCampaign(valid, plan,
      provider: narrator.provider ?? 'mock');
    await _create(campaign);
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

  Future<void> sendAction(String text) => _run(() async {
    final campaign = currentCampaign;
    if (campaign == null) {
      throw const FormatException('Starte zuerst ein Abenteuer.');
    }
    if (text.trim().isEmpty || text.length > 4000) {
      throw const FormatException(
        'Gib eine Handlung mit 1 bis 4000 Zeichen ein.',
      );
    }
    final update = engine.act(campaign, text);
    await _commit(await _withNarration(update, text));
  });

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
          campaignId: campaign.id, heroName: campaign.hero.name,
          action: action.length > 2000 ? action.substring(0, 2000) : action,
          scene: campaign.scene, premise: context['premise'] ?? '',
          goal: context['goal'] ?? '', secret: context['secret'] ?? '',
          threads: [for (final t in campaign.storyThreads)
            {'id': t.id, 'title': t.title, 'description': t.description,
              'status': t.status}],
          npcs: [for (final npc in campaign.npcs)
            {'id': npc.id, 'name': npc.name, 'relationship': npc.relationship}],
          memories: memories.take(12).map((value) =>
              value.length > 400 ? value.substring(0, 400) : value).toList(),
          recentActions: recent.reversed.take(6).toList().reversed
              .map((value) => value.length > 2000
                  ? value.substring(0, 2000) : value).toList(),
        );
        if (response == null) return update;
        final step = AiStoryStep.fromJson(response, campaign);
        return engine.applyAiStoryStep(update, step,
          provider: narrator.provider ?? 'mock', decision: action);
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
    await _commit(engine.recordNpcRelationship(
      campaign, npcId: npcId, relationship: relationship, note: note,
    ));
  });

  Future<void> saveStoryThread({
    String? threadId,
    required String title,
    required String description,
    required String status,
  }) => _run(() async {
    final campaign = currentCampaign;
    if (campaign == null) throw const FormatException('Keine aktive Kampagne.');
    await _commit(engine.saveStoryThread(
      campaign, threadId: threadId, title: title,
      description: description, status: status,
    ));
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
    await repository.saveCharacter(HeroCharacter.fromJson(hero.toJson()));
    await _reload();
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
