import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/campaign_repository.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/campaign_experience.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late String databasePath;
  late SqliteCampaignRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('rabenwacht-xp-');
    databasePath = paths.join(directory.path, 'rewards.sqlite');
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: databasePath,
    );
  });

  tearDown(() async {
    await repository.close();
    await directory.delete(recursive: true);
  });

  test('Rabenwacht milestone survives SQLite restart without duplicate XP', () async {
    final engine = GameEngine();
    var campaign = engine.createRabenwacht(engine.createDemo().hero);
    final original = campaign;
    await repository.saveCampaign(campaign);

    for (final action in [
      'Ich gehe zum Dorfplatz.',
      'Ich gehe zum Wirt Tarek.',
      'Ich gehe zur Mühle.',
    ]) {
      final update = engine.act(campaign, action);
      await repository.saveCampaign(
        update.campaign,
        events: update.events,
        expectedRevision: campaign.revision,
      );
      campaign = update.campaign;
    }

    expect(campaign.hero.experience, 200);
    expect(campaign.facts['xpReward:reach-mill'], 'true');
    final confirmedRevision = campaign.revision;
    final confirmedEvents = campaign.events.length;

    await repository.close();
    repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: databasePath,
    );

    final restored = (await repository.getCampaign(campaign.id))!;
    expect(restored.revision, confirmedRevision);
    expect(restored.hero.experience, 200);
    expect(restored.events, hasLength(confirmedEvents));
    expect(
      CampaignExperience.awardOnce(restored, 'reach-mill').campaign.toJson(),
      restored.toJson(),
    );

    // A damaged receipt must not enable a second award. There is no write
    // before explicit transaction confirmation, so SQLite remains intact.
    final damaged = restored.copyWith(
      facts: {...restored.facts, 'xpReward:reach-mill': 'false'},
    );
    expect(
      () => CampaignExperience.awardOnce(damaged, 'reach-mill'),
      throwsFormatException,
    );
    expect(
      (await repository.getCampaign(campaign.id))!.toJson(),
      restored.toJson(),
    );

    // A stale second writer cannot overwrite the later, confirmed history.
    final stale = original.copyWith(
      revision: 1,
      hero: original.hero.copyWith(experience: 200),
      facts: {...original.facts, 'xpReward:reach-mill': 'true'},
    );
    await expectLater(
      repository.saveCampaign(stale, expectedRevision: 0),
      throwsA(isA<CampaignConflictException>()),
    );
    expect(
      (await repository.getCampaign(campaign.id))!.toJson(),
      restored.toJson(),
    );
  });
}
