import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/campaign_repository.dart';
import '../domain/game_engine.dart';
import '../domain/models.dart';

/// UI state changes only after an atomic repository commit succeeds.
class GameController extends ChangeNotifier {
  GameController({required this.repository, GameEngine? engine})
    : engine = engine ?? GameEngine();

  final CampaignRepository repository;
  final GameEngine engine;
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
    await _commit(engine.act(campaign, text));
  });

  Future<void> resolveRoll({int? natural, int? total}) => _run(() async {
    final campaign = currentCampaign;
    if (campaign == null) throw const FormatException('Keine aktive Kampagne.');
    await _commit(engine.resolveRoll(campaign, natural: natural, total: total));
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
    super.dispose();
  }
}
