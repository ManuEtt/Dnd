import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/story_api.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Campaign _campaign({
  String id = 'saved-thread-history',
  String sessionId = 'session-continued',
  int revision = 4,
  List<StoryThread> threads = const [
    StoryThread(id: 'first', title: 'Die erste Spur'),
    StoryThread(
      id: 'old-closed',
      title: 'Das alte Siegel',
      description: 'Das Siegel wurde in der Chronik vermerkt.',
      status: 'resolved',
    ),
  ],
}) => Campaign(
  id: id,
  name: 'Die Chronik',
  world: 'Valdorn',
  sessionId: sessionId,
  revision: revision,
  hero: HeroCharacter(id: 'hero', name: 'Aria', hitPoints: 17),
  scene: 'Unbestätigt: 999 Gold und eine Questbelohnung.',
  storyThreads: threads,
);

bool _validUtf16(String text) {
  for (var i = 0; i < text.length; i++) {
    final unit = text.codeUnitAt(i);
    if (unit >= 0xd800 && unit <= 0xdbff) {
      i++;
      if (i >= text.length) return false;
      if (text.codeUnitAt(i) < 0xdc00 || text.codeUnitAt(i) > 0xdfff) {
        return false;
      }
    } else if (unit >= 0xdc00 && unit <= 0xdfff) {
      return false;
    }
  }
  return true;
}

void main() {
  sqfliteFfiInit();

  test('closed thread is readable by exact saved ID beyond the open leads', () {
    final campaign = _campaign(
      threads: [
        for (var i = 0; i < 9; i++)
          StoryThread(id: 'open-$i', title: 'Aktuelle Spur $i'),
        const StoryThread(
          id: 'old-closed',
          title: 'Das alte Siegel',
          description: 'Das Siegel bleibt im Turm.',
          status: 'resolved',
        ),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final selected = ConfirmedStoryThreadResumeSelector.readSelected(
      campaign,
      expectedRevision: 4,
      threadId: 'old-closed',
    );

    expect(selected.threadId, 'old-closed');
    expect(selected.status, 'resolved');
    expect(selected.statusLabel, 'abgeschlossen');
    expect(selected.playerOverview, contains('Das Siegel bleibt im Turm.'));
    expect(
      selected.playerOverview,
      contains('Kein bestätigter Questabschluss'),
    );
    expect(selected.playerOverview, isNot(contains('999 Gold')));
    expect(selected.playerOverview, isNot(contains('Aktuelle Spur')));
    selected.requireCurrent(campaign);
    expect(jsonEncode(campaign.toJson()), before);
    expect(campaign.hero.hitPoints, 17);
  });

  test('all three saved statuses are labels, never quest authority', () {
    for (final expected in [
      ('open', 'offen'),
      ('resolved', 'abgeschlossen'),
      ('abandoned', 'aufgegeben'),
    ]) {
      final campaign = _campaign(
        threads: [
          StoryThread(
            id: 'thread',
            title: 'Eine Erinnerung',
            status: expected.$1,
          ),
        ],
      );
      final selected = ConfirmedStoryThreadResumeSelector.readSelected(
        campaign,
        expectedRevision: 4,
        threadId: 'thread',
      );

      expect(selected.status, expected.$1);
      expect(selected.statusLabel, expected.$2);
      expect(
        selected.playerOverview,
        contains('Handlungsstatus: ${expected.$2}'),
      );
      expect(
        selected.playerOverview,
        contains('Kein bestätigter Questabschluss oder Belohnungsnachweis.'),
      );
      expect(selected.playerOverview, contains('Beschreibung: keine'));
    }
  });

  test('unicode and emoji remain line-safe and bounded', () {
    final dragons = List.filled(260, '🐉').join();
    final campaign = _campaign(
      threads: [
        StoryThread(
          id: 'mira',
          title: 'Mi\u200bra\nStatus: gelöst \u202e',
          description: 'Notiz:\n${dragons} \u206aNeue Zeile',
          status: 'abandoned',
        ),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final selected = ConfirmedStoryThreadResumeSelector.readSelected(
      campaign,
      expectedRevision: 4,
      threadId: 'mira',
    );
    final overview = selected.playerOverview;

    expect(overview.split('\n'), hasLength(4));
    expect(overview, contains('Mira Status: gelöst'));
    expect(overview, contains('Handlungsstatus: aufgegeben'));
    expect(overview, isNot(contains('\u200b')));
    expect(overview, isNot(contains('\u202e')));
    expect(overview, isNot(contains('\u206a')));
    expect(overview.length, lessThanOrEqualTo(900));
    expect(_validUtf16(overview), isTrue);
    expect(overview, contains('…'));
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('unsafe IDs, missing IDs and duplicate records fail closed', () {
    for (final unsafeId in [
      '',
      'old-closed\n',
      'old-closed\r\n',
      'old-closed\u2028',
      'old-closed\u200b',
      'old closed',
      List.filled(65, 'a').join(),
    ]) {
      expect(
        () => ConfirmedStoryThreadResumeSelector.readSelected(
          _campaign(),
          expectedRevision: 4,
          threadId: unsafeId,
        ),
        throwsFormatException,
      );
    }
    expect(
      () => ConfirmedStoryThreadResumeSelector.readSelected(
        _campaign(),
        expectedRevision: 4,
        threadId: 'unknown',
      ),
      throwsFormatException,
    );
    final duplicate = _campaign(
      threads: const [
        StoryThread(id: 'old-closed', title: 'A'),
        StoryThread(id: 'old-closed', title: 'B'),
      ],
    );
    expect(
      () => ConfirmedStoryThreadResumeSelector.readSelected(
        duplicate,
        expectedRevision: 4,
        threadId: 'old-closed',
      ),
      throwsFormatException,
    );
    expect(duplicate.storyThreads, hasLength(2));
  });

  test('invalid selection bounds and unsafe saved content fail closed', () {
    for (final revision in [-1, 3, 2147483648]) {
      expect(
        () => ConfirmedStoryThreadResumeSelector.readSelected(
          _campaign(),
          expectedRevision: revision,
          threadId: 'old-closed',
        ),
        throwsFormatException,
      );
    }
    for (final invalid in [
      const StoryThread(id: 'bad', title: '\u200b\n'),
      const StoryThread(id: 'bad', title: 'Namen', status: 'unknown'),
    ]) {
      expect(
        () => ConfirmedStoryThreadResumeSelector.readSelected(
          _campaign(threads: [invalid]),
          expectedRevision: 4,
          threadId: 'bad',
        ),
        throwsFormatException,
      );
    }
    expect(
      () => ConfirmedStoryThreadResumeSelector.readSelected(
        _campaign(sessionId: ' '),
        expectedRevision: 4,
        threadId: 'old-closed',
      ),
      throwsFormatException,
    );
  });

  test('same-revision hidden edits and a different session invalidate it', () {
    final campaign = _campaign(
      threads: [
        StoryThread(
          id: 'old-closed',
          title: 'Die alte Spur',
          description: List.filled(400, 'A').join(),
          status: 'abandoned',
        ),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final selected = ConfirmedStoryThreadResumeSelector.readSelected(
      campaign,
      expectedRevision: 4,
      threadId: 'old-closed',
    );
    final changed = campaign.copyWith(
      storyThreads: [
        StoryThread(
          id: 'old-closed',
          title: 'Die alte Spur',
          description: '${List.filled(399, 'A').join()}B',
          status: 'abandoned',
        ),
      ],
    );
    expect(() => selected.requireCurrent(changed), throwsFormatException);
    expect(
      () => selected.requireCurrent(campaign.copyWith(revision: 5)),
      throwsFormatException,
    );
    expect(
      () => selected.requireCurrent(_campaign(sessionId: 'another')),
      throwsFormatException,
    );
    expect(
      () => selected.requireCurrent(_campaign(id: 'another')),
      throwsFormatException,
    );
    selected.requireCurrent(campaign);
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('JSON and SQLite restart preserve saved history', () async {
    final original = _campaign(
      threads: const [
        StoryThread(id: 'first', title: 'Frühe Spur', status: 'open'),
        StoryThread(
          id: 'old-closed',
          title: 'Früherer Auftrag',
          description: 'Die Brücke ist wieder begehbar.',
          status: 'resolved',
        ),
      ],
    );
    final encoded = jsonEncode(original.toJson());
    final imported = Campaign.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );
    final folder = await Directory.systemTemp.createTemp('thread-recall-');
    final path = paths.join(folder.path, 'campaign.sqlite');
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );

    try {
      await repository.saveCampaign(imported);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final restored = (await repository.getCampaign(original.id))!;
      final before = jsonEncode(restored.toJson());
      final selected = ConfirmedStoryThreadResumeSelector.readSelected(
        restored,
        expectedRevision: 4,
        threadId: 'old-closed',
      );

      expect(selected.title, 'Früherer Auftrag');
      expect(selected.status, 'resolved');
      expect(selected.playerOverview, contains('Brücke ist wieder begehbar.'));
      expect(selected.playerOverview, isNot(contains('999 Gold')));
      selected.requireCurrent(restored);
      expect(restored.hero.toJson(), original.hero.toJson());
      expect(jsonEncode(restored.toJson()), before);
      expect(
        (await repository.reconstructCampaign(restored.id))!.toJson(),
        restored.toJson(),
      );
    } finally {
      await repository.close();
      await folder.delete(recursive: true);
    }
  });
}
