import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/saved_quest_resume_selection.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Campaign _campaign({
  String id = 'quest-recall',
  String sessionId = 'continued-session',
  int revision = 3,
  List<Quest> quests = const [
    Quest(
      id: 'old-quest',
      title: 'Das alte Siegel',
      description: 'Das Siegel liegt im Archiv.',
      status: 'completed',
    ),
    Quest(id: 'new-quest', title: 'Der Hafen'),
  ],
}) => Campaign(
  id: id,
  name: 'Die Chronik',
  world: 'Valdorn',
  sessionId: sessionId,
  revision: revision,
  hero: HeroCharacter(id: 'aria', name: 'Aria', hitPoints: 17),
  scene: 'Unbestätigt: Die KI behauptet 999 Gold als Belohnung.',
  quests: quests,
);

bool _validUtf16(String text) {
  for (var i = 0; i < text.length; i++) {
    final code = text.codeUnitAt(i);
    if (code >= 0xd800 && code <= 0xdbff) {
      i++;
      if (i >= text.length) return false;
      if (text.codeUnitAt(i) < 0xdc00 || text.codeUnitAt(i) > 0xdfff) {
        return false;
      }
    } else if (code >= 0xdc00 && code <= 0xdfff) {
      return false;
    }
  }
  return true;
}

void main() {
  sqfliteFfiInit();

  test('older completed quest has ID-bound history without reward claims', () {
    final campaign = _campaign();
    final before = jsonEncode(campaign.toJson());
    final selection = SavedQuestResumeSelector.readSelected(
      campaign,
      expectedRevision: 3,
      questId: 'old-quest',
    );

    expect(selection.questId, 'old-quest');
    expect(selection.status, 'completed');
    expect(selection.statusLabel, 'abgeschlossen');
    expect(selection.title, 'Das alte Siegel');
    expect(selection.playerOverview, contains('ID: old-quest'));
    expect(selection.playerOverview, contains('Siegel liegt im Archiv'));
    expect(selection.playerOverview, contains('Kein Nachweis über EP'));
    expect(selection.playerOverview, isNot(contains('999 Gold als Belohnung')));
    expect(selection.playerOverview, isNot(contains('Der Hafen')));
    selection.requireCurrent(campaign);
    expect(campaign.hero.hitPoints, 17);
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('saved statuses are displayed without changing quests', () {
    for (final status in [
      ('active', 'aktiv'),
      ('completed', 'abgeschlossen'),
      ('failed', 'gescheitert'),
    ]) {
      final campaign = _campaign(
        quests: [
          Quest(id: 'quest', title: 'Ein Auftrag', status: status.$1),
        ],
      );
      final before = jsonEncode(campaign.toJson());
      final selection = SavedQuestResumeSelector.readSelected(
        campaign,
        expectedRevision: 3,
        questId: 'quest',
      );

      expect(selection.status, status.$1);
      expect(selection.statusLabel, status.$2);
      expect(
        selection.playerOverview,
        contains('Gespeicherter Queststatus: ${status.$2}'),
      );
      expect(
        selection.playerOverview,
        contains('Gespeicherte Beschreibung: keine'),
      );
      expect(jsonEncode(campaign.toJson()), before);
    }
  });

  test('unsafe, unknown and duplicate quest identities fail closed', () {
    final source = _campaign();
    final before = jsonEncode(source.toJson());
    for (final questId in [
      '',
      'old-quest\n',
      'old-quest\r\n',
      'old-quest\u2028',
      'old-quest\u200b',
      'old quest',
      List.filled(65, 'a').join(),
      'missing',
    ]) {
      expect(
        () => SavedQuestResumeSelector.readSelected(
          source,
          expectedRevision: 3,
          questId: questId,
        ),
        throwsFormatException,
      );
    }

    final duplicate = _campaign(
      quests: const [
        Quest(id: 'same', title: 'Erste Quest', status: 'active'),
        Quest(id: 'same', title: 'Zweite Quest', status: 'completed'),
      ],
    );
    expect(
      () => SavedQuestResumeSelector.readSelected(
        duplicate,
        expectedRevision: 3,
        questId: 'same',
      ),
      throwsFormatException,
    );
    expect(jsonEncode(source.toJson()), before);
    expect(duplicate.quests, hasLength(2));
  });

  test('invalid revisions and untrusted legacy quest content fail closed', () {
    for (final revision in [-1, 2, 2147483648]) {
      expect(
        () => SavedQuestResumeSelector.readSelected(
          _campaign(),
          expectedRevision: revision,
          questId: 'old-quest',
        ),
        throwsFormatException,
      );
    }
    for (final invalid in [
      const Quest(id: 'bad', title: '\u200b\n'),
      const Quest(id: 'bad', title: 'Ein Titel', status: 'unknown'),
    ]) {
      expect(
        () => SavedQuestResumeSelector.readSelected(
          _campaign(quests: [invalid]),
          expectedRevision: 3,
          questId: 'bad',
        ),
        throwsFormatException,
      );
    }
    expect(
      () => SavedQuestResumeSelector.readSelected(
        _campaign(sessionId: ' '),
        expectedRevision: 3,
        questId: 'old-quest',
      ),
      throwsFormatException,
    );
    final legacy = _campaign().toJson()..remove('quests');
    expect(
      () => SavedQuestResumeSelector.readSelected(
        Campaign.fromJson(legacy),
        expectedRevision: 3,
        questId: 'old-quest',
      ),
      throwsFormatException,
    );
  });

  test('unicode spoofing stays line-safe and does not modify saved text', () {
    final dragons = List.filled(220, '🐉').join();
    final campaign = _campaign(
      quests: [
        Quest(
          id: 'quest',
          title: 'Mi\u200bra\nStatus: erledigt\u202e',
          description: 'Hinweis:\n$dragons\u206a',
          status: 'failed',
        ),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final selection = SavedQuestResumeSelector.readSelected(
      campaign,
      expectedRevision: 3,
      questId: 'quest',
    );
    final text = selection.playerOverview;

    expect(selection.title, 'Mira Status: erledigt');
    expect(text, contains('Gespeicherter Queststatus: gescheitert'));
    expect(text.split('\n'), hasLength(4));
    expect(text, isNot(contains('\u200b')));
    expect(text, isNot(contains('\u202e')));
    expect(text, isNot(contains('\u206a')));
    expect(text, contains('…'));
    expect(text.length, lessThanOrEqualTo(900));
    expect(_validUtf16(text), isTrue);
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('same-revision hidden edits and other quests invalidate selection', () {
    final campaign = _campaign(
      quests: [
        Quest(
          id: 'old-quest',
          title: 'Eine lange Erinnerung',
          description: List.filled(400, 'a').join(),
          status: 'completed',
        ),
        const Quest(id: 'other', title: 'Eine andere Quest'),
      ],
    );
    final before = jsonEncode(campaign.toJson());
    final selection = SavedQuestResumeSelector.readSelected(
      campaign,
      expectedRevision: 3,
      questId: 'old-quest',
    );
    final changedOld = campaign.copyWith(
      quests: [
        Quest(
          id: 'old-quest',
          title: 'Eine lange Erinnerung',
          description: '${List.filled(399, 'a').join()}b',
          status: 'completed',
        ),
        const Quest(id: 'other', title: 'Eine andere Quest'),
      ],
    );
    final changedOther = campaign.copyWith(
      quests: [
        ...campaign.quests.take(1),
        const Quest(id: 'other', title: 'Geänderte Quest'),
      ],
    );
    for (final invalid in [
      changedOld,
      changedOther,
      campaign.copyWith(revision: 4),
      _campaign(id: 'other', quests: campaign.quests),
      _campaign(sessionId: 'other', quests: campaign.quests),
    ]) {
      expect(() => selection.requireCurrent(invalid), throwsFormatException);
    }
    selection.requireCurrent(campaign);
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('JSON and SQLite reopen preserve saved quest history', () async {
    final original = _campaign(revision: 0);
    final encoded = jsonEncode(original.toJson());
    final restoredJson = Campaign.fromJson(
      jsonDecode(encoded) as Map<String, dynamic>,
    );
    final folder = await Directory.systemTemp.createTemp('quest-recall-');
    final path = paths.join(folder.path, 'campaign.sqlite');
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );

    try {
      await repository.saveCampaign(restoredJson);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final saved = (await repository.getCampaign(original.id))!;
      final before = jsonEncode(saved.toJson());
      final selection = SavedQuestResumeSelector.readSelected(
        saved,
        expectedRevision: 0,
        questId: 'old-quest',
      );

      expect(selection.status, 'completed');
      expect(selection.title, 'Das alte Siegel');
      expect(selection.playerOverview, isNot(contains('999 Gold')));
      selection.requireCurrent(saved);
      expect(saved.hero.toJson(), original.hero.toJson());
      expect(jsonEncode(saved.toJson()), before);
      expect(
        (await repository.reconstructCampaign(saved.id))!.toJson(),
        saved.toJson(),
      );
    } finally {
      await repository.close();
      await folder.delete(recursive: true);
    }
  });
}
