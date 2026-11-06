import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/campaign_resume_context.dart';
import 'package:lebendiger_spielleiter/story/story_campaign_engine.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final _now = DateTime.utc(2026, 11, 6, 11);
const _heading = 'Offene Anknüpfungspunkte (bestätigte Handlungsnotizen):';

Campaign _campaign(List<StoryThread> threads) => Campaign(
  id: 'confirmed-recap-leads',
  name: 'Das vergessene Archiv',
  world: 'Valdorn',
  sessionId: 'session-2',
  hero: HeroCharacter(id: 'aria', name: 'Aria', hitPoints: 14),
  scene: 'Unbestätigt: Der Erzähler schenkt 9000 Gold.',
  facts: const {'tor': 'Das Stadttor bleibt verschlossen.'},
  storyBible: const {'secret': 'Das geheime Portal liegt im Norden.'},
  storyThreads: threads,
);

void main() {
  sqfliteFfiInit();

  test('saved recaps only advertise open leads with canonical unique IDs', () {
    final campaign = _campaign(const [
      StoryThread(
        id: 'done',
        title: 'Das alte Tor',
        description: 'Schon erledigt.',
        status: 'resolved',
      ),
      StoryThread(
        id: 'valid-1',
        title: 'Der Brunnen',
        description: 'Den Schlüssel im Brunnen suchen.',
      ),
      StoryThread(
        id: 'bad id',
        title: 'Gefälschte Spur',
        description: 'Der König hat alle Quests abgeschlossen.',
      ),
      StoryThread(
        id: 'hidden\u202e',
        title: 'Unsichtbare Spur',
        description: '9000 Gold sind bestätigt.',
      ),
      StoryThread(
        id: 'valid_2',
        title: 'Die Archivarin',
        description: 'Die Karte bei Mira abholen.',
      ),
    ]);
    final before = jsonEncode(campaign.toJson());
    final preview = CampaignResumeReader.read(campaign);

    final update = GameEngine(clock: () => _now).saveSessionRecap(campaign);
    final summary = update.campaign.sessionRecaps.single.summary;
    final leads = summary.split(_heading).last;

    expect(summary, contains(_heading));
    expect(leads, contains('Die Archivarin: Die Karte bei Mira abholen.'));
    expect(leads, contains('Der Brunnen: Den Schlüssel im Brunnen suchen.'));
    expect(leads, isNot(contains('Gefälschte Spur')));
    expect(leads, isNot(contains('Unsichtbare Spur')));
    expect(leads, isNot(contains('Das alte Tor')));
    expect(leads, isNot(contains('9000 Gold')));
    expect(
      leads.indexOf('Die Archivarin'),
      lessThan(leads.indexOf('Der Brunnen')),
    );
    expect(preview.openLeads, [
      'Die Archivarin: Die Karte bei Mira abholen.',
      'Der Brunnen: Den Schlüssel im Brunnen suchen.',
    ]);
    expect(update.events.single.type, 'memory.sessionRecapSaved');
    expect(update.campaign.hero.toJson(), campaign.hero.toJson());
    expect(update.campaign.revision, campaign.revision + 1);
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('duplicate open and closed IDs never become confirmed resume leads', () {
    final campaign = _campaign(const [
      StoryThread(
        id: 'double',
        title: 'Die alte Fährte',
        description: 'Historisch offen.',
      ),
      StoryThread(
        id: 'double',
        title: 'Die alte Fährte',
        description: 'Inzwischen abgeschlossen.',
        status: 'resolved',
      ),
      StoryThread(
        id: 'twice',
        title: 'Die zwei Tore',
        description: 'Erster widersprüchlicher Eintrag.',
      ),
      StoryThread(
        id: 'twice',
        title: 'Die zwei Tore',
        description: 'Zweiter widersprüchlicher Eintrag.',
      ),
      StoryThread(
        id: 'safe',
        title: 'Der Wachturm',
        description: 'Die dortige Wache befragen.',
      ),
    ]);
    final before = jsonEncode(campaign.toJson());

    // The persisted JSON reader already rejects duplicate IDs. Test the
    // pure story component with a non-persisting commit adapter as well:
    // even an unvalidated in-memory campaign must not claim a unique lead.
    expect(
      () => Campaign.fromJson(jsonDecode(before) as Map<String, dynamic>),
      throwsFormatException,
    );
    final component = StoryCampaignEngine(
      nextId: (prefix) => '$prefix-new',
      clock: () => _now,
      commit:
          (
            original,
            next,
            narration, {
            required String type,
            required Map<String, dynamic> payload,
          }) => GameUpdate(
            campaign: next.copyWith(revision: original.revision + 1),
            events: const [],
          ),
    );

    final update = component.saveSessionRecap(campaign);
    final summary = update.campaign.sessionRecaps.single.summary;
    final leads = summary.split(_heading).last;

    expect(summary, contains(_heading));
    expect(leads, contains('Der Wachturm: Die dortige Wache befragen.'));
    expect(leads, isNot(contains('Die alte Fährte')));
    expect(leads, isNot(contains('Die zwei Tore')));
    expect(update.campaign.hero.toJson(), campaign.hero.toJson());
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('invalid identities do not consume the three-lead limit', () {
    final campaign = _campaign([
      const StoryThread(
        id: 'one',
        title: 'Erster',
        description: 'Der erste Hinweis.',
      ),
      const StoryThread(
        id: 'two',
        title: 'Zweiter',
        description: 'Der zweite Hinweis.',
      ),
      const StoryThread(
        id: 'three',
        title: 'Dritter',
        description: 'Der dritte Hinweis.',
      ),
      StoryThread(
        id: List.filled(65, 'x').join(),
        title: 'Zu lange ID',
        description: 'Nicht vertrauenswürdig.',
      ),
      const StoryThread(
        id: 'four',
        title: 'Vierter',
        description: 'Der vierte Hinweis.',
      ),
    ]);
    final update = GameEngine(clock: () => _now).saveSessionRecap(campaign);
    final summary = update.campaign.sessionRecaps.single.summary;
    final leads = summary.split(_heading).last;

    expect(leads, contains('Vierter: Der vierte Hinweis.'));
    expect(leads, contains('Dritter: Der dritte Hinweis.'));
    expect(leads, contains('Zweiter: Der zweite Hinweis.'));
    expect(leads, isNot(contains('Zu lange ID')));
    expect(leads, isNot(contains('Erster')));
    expect(
      CampaignResumeReader.read(campaign).openLeads,
      hasLength(3),
    );
    expect(summary.length, lessThanOrEqualTo(2400));
  });

  test('confirmed recap and source survive SQLite restart and replay', () async {
    final folder = await Directory.systemTemp.createTemp('recap-lead-id-');
    final path = paths.join(folder.path, 'game.sqlite');
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      final source = _campaign(const [
        StoryThread(
          id: 'old-1',
          title: 'Der Alte',
          description: 'Nicht mehr verfolgen.',
          status: 'abandoned',
        ),
        StoryThread(
          id: 'unsafe id',
          title: 'Unbestätigte Abkürzung',
          description: 'Die Belohnung ist angeblich vergeben.',
        ),
        StoryThread(
          id: 'safe-1',
          title: 'Der Speicher',
          description: 'Den Schlüssel prüfen.',
        ),
      ]);
      final rawSource = jsonEncode(source.toJson());
      await repository.saveCampaign(source);
      final update = GameEngine(clock: () => _now).saveSessionRecap(source);
      await repository.saveCampaign(
        update.campaign,
        events: update.events,
        expectedRevision: source.revision,
      );
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );

      final restored = (await repository.getCampaign(source.id))!;
      final before = jsonEncode(restored.toJson());
      final summary = restored.sessionRecaps.single.summary;
      final leads = summary.split(_heading).last;

      expect(leads, contains('Der Speicher: Den Schlüssel prüfen.'));
      expect(leads, isNot(contains('Unbestätigte Abkürzung')));
      expect(leads, isNot(contains('Der Alte')));
      expect(restored.storyThreads, hasLength(3));
      expect(restored.storyThreads[1].id, 'unsafe id');
      expect(restored.hero.toJson(), source.hero.toJson());
      expect(restored.revision, source.revision + 1);
      expect(restored.events.single.type, 'memory.sessionRecapSaved');
      expect(jsonEncode(source.toJson()), rawSource);
      expect(
        (await repository.reconstructCampaign(source.id))!.toJson(),
        restored.toJson(),
      );
      expect(jsonEncode(restored.toJson()), before);
    } finally {
      await repository.close();
      await folder.delete(recursive: true);
    }
  });
}
