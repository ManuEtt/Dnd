import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/services/player_action_outbox.dart';

void main() {
  sqfliteFfiInit();

  late Directory directory;
  late SqliteCampaignRepository firstRepository;
  late SqliteCampaignRepository secondRepository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('npc-two-writers-');
    final path = paths.join(directory.path, 'campaign.sqlite');
    firstRepository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    secondRepository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
  });

  tearDown(() async {
    await secondRepository.close();
    await firstRepository.close();
    await directory.delete(recursive: true);
  });

  test('stale writer cannot clear replacement for another same-named NPC',
      () async {
    final first = PlayerActionOutbox(
      firstRepository,
      newRequestId: () => 'replayed-action-key',
    );
    final second = PlayerActionOutbox(secondRepository);
    final old = await first.stage(
      'campaign-one',
      'Ich spreche mit Mira.',
      selectedNpcId: 'mira-one',
      selectedNpcRevision: 7,
    );
    final cached = (await second.pendingFor(old.campaignId))!;
    expect(cached.toJson(), old.toJson());

    // The player explicitly discards the old intent and selects another NPC.
    await first.remove(old);
    final replacement = await first.stage(
      'campaign-one',
      'Ich spreche mit Mira.',
      selectedNpcId: 'mira-two',
      selectedNpcRevision: 8,
    );
    expect(replacement.requestId, old.requestId);
    expect(replacement.text, old.text);

    // An ACK arriving on another connection cannot delete the new choice.
    await expectLater(second.remove(cached), throwsStateError);
    expect(
      (await first.pendingFor(old.campaignId))!.toJson(),
      replacement.toJson(),
    );
    expect(
      (await second.pendingFor(old.campaignId))!.toJson(),
      replacement.toJson(),
    );

    await second.remove(replacement);
    expect(await first.pendingFor(old.campaignId), isNull);
  });

  test('stale writer cannot clear a newer revision of the same NPC', () async {
    final first = PlayerActionOutbox(
      firstRepository,
      newRequestId: () => 'same-id-and-text',
    );
    final second = PlayerActionOutbox(secondRepository);
    final old = await first.stage(
      'campaign-one',
      'Ich frage Mira nach dem Hafen.',
      selectedNpcId: 'mira-two',
      selectedNpcRevision: 10,
    );
    final cached = (await second.pendingFor(old.campaignId))!;
    await first.remove(old);
    final replacement = await first.stage(
      'campaign-one',
      old.text,
      selectedNpcId: 'mira-two',
      selectedNpcRevision: 11,
    );

    await expectLater(second.remove(cached), throwsStateError);
    expect(
      (await second.pendingFor(old.campaignId))!.toJson(),
      replacement.toJson(),
    );
    await first.remove(replacement);
    expect(await second.pendingFor(old.campaignId), isNull);
  });

  test('legacy text-only ACK never clears a newer selected NPC intent',
      () async {
    final first = PlayerActionOutbox(
      firstRepository,
      newRequestId: () => 'legacy-reused-key',
    );
    final second = PlayerActionOutbox(secondRepository);
    final plain = await first.stage('campaign-one', 'Ich rede mit Mira.');
    final cached = (await second.pendingFor(plain.campaignId))!;
    expect(cached.selectedNpcId, isNull);

    await first.remove(plain);
    final selected = await first.stage(
      plain.campaignId,
      plain.text,
      selectedNpcId: 'mira-one',
      selectedNpcRevision: 12,
    );
    await expectLater(second.remove(cached), throwsStateError);
    expect(
      (await second.pendingFor(plain.campaignId))!.toJson(),
      selected.toJson(),
    );

    await second.remove(selected);
    expect(await first.pendingFor(plain.campaignId), isNull);

    // The reverse direction must be safe too: selected -> text-only.
    final chosen = await first.stage(
      plain.campaignId,
      plain.text,
      selectedNpcId: 'mira-two',
      selectedNpcRevision: 13,
    );
    final previousSelection =
        (await second.pendingFor(plain.campaignId))!;
    await first.remove(chosen);
    final currentPlain = await first.stage(plain.campaignId, plain.text);
    await expectLater(
      second.remove(previousSelection),
      throwsStateError,
    );
    expect(
      (await first.pendingFor(plain.campaignId))!.toJson(),
      currentPlain.toJson(),
    );
  });

  test('two concurrent NPC intents cannot overwrite each other', () async {
    final first = PlayerActionOutbox(
      firstRepository,
      newRequestId: () => 'writer-one',
    );
    final second = PlayerActionOutbox(
      secondRepository,
      newRequestId: () => 'writer-two',
    );
    final results = await Future.wait([
      first
          .stage(
            'campaign-one',
            'Ich rede mit Mira.',
            selectedNpcId: 'mira-one',
            selectedNpcRevision: 20,
          )
          .then((_) => true)
          .catchError((_) => false),
      second
          .stage(
            'campaign-one',
            'Ich rede mit Mira.',
            selectedNpcId: 'mira-two',
            selectedNpcRevision: 20,
          )
          .then((_) => true)
          .catchError((_) => false),
    ]);
    expect(results.where((success) => success).length, 1);

    final saved = (await first.pendingFor('campaign-one'))!;
    expect(
      (await second.pendingFor('campaign-one'))!.toJson(),
      saved.toJson(),
    );
    expect(
      saved.selectedNpcId,
      anyOf('mira-one', 'mira-two'),
    );
    expect(saved.selectedNpcRevision, 20);

    final losingId = saved.selectedNpcId == 'mira-one'
        ? 'mira-two'
        : 'mira-one';
    await expectLater(
      second.remove(
        PendingPlayerAction(
          campaignId: saved.campaignId,
          requestId: saved.requestId,
          text: saved.text,
          selectedNpcId: losingId,
          selectedNpcRevision: saved.selectedNpcRevision,
        ),
      ),
      throwsStateError,
    );
    expect((await first.pendingFor(saved.campaignId))!.toJson(), saved.toJson());
    await first.remove(saved);
    expect(await second.pendingFor(saved.campaignId), isNull);
  });
}
