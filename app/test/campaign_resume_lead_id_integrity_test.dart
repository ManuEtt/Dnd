import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/campaign_resume_context.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Campaign _campaign(List<StoryThread> threads) => Campaign(
  id: 'resume-lead-id-integrity',
  name: 'Die offenen Spuren',
  world: 'Valdorn',
  sessionId: 'session-two',
  hero: HeroCharacter(id: 'aria', name: 'Aria', hitPoints: 12),
  scene: 'Unbestätigt: Der Held bekommt 9000 Gold.',
  storyThreads: threads,
);

void main() {
  sqfliteFfiInit();

  test('colliding saved IDs cannot revive resolved or abandoned leads', () {
    final campaign = _campaign(const [
      StoryThread(
        id: 'gate',
        title: 'Altes Tor',
        description: 'Früher offen, inzwischen erledigt.',
      ),
      StoryThread(
        id: 'gate',
        title: 'Altes Tor',
        description: 'Die Sperre wurde aufgehoben.',
        status: 'resolved',
      ),
      StoryThread(
        id: 'bridge',
        title: 'Die Brücke',
        description: 'Die Wache befragen.',
      ),
      StoryThread(
        id: 'lake',
        title: 'Der See',
        description: 'Der Auftrag wurde aufgegeben.',
        status: 'abandoned',
      ),
      StoryThread(
        id: 'lake',
        title: 'Der See',
        description: 'Historisch noch offen.',
      ),
      StoryThread(
        id: 'tavern',
        title: 'Die Taverne',
        description: 'Mira nach dem Siegel fragen.',
      ),
    ]);
    final before = jsonEncode(campaign.toJson());

    final snapshot = CampaignResumeReader.read(campaign);

    expect(snapshot.openLeads, [
      'Die Taverne: Mira nach dem Siegel fragen.',
      'Die Brücke: Die Wache befragen.',
    ]);
    expect(snapshot.playerOverview, isNot(contains('Altes Tor')));
    expect(snapshot.playerOverview, isNot(contains('Der See')));
    expect(snapshot.playerOverview, contains('kein bestätigter Regelzustand'));
    expect(snapshot.openLeads.join(' '), isNot(contains('9000 Gold')));
    expect(campaign.storyThreads, hasLength(6));
    expect(jsonEncode(campaign.toJson()), before);
  });

  test('unsafe IDs and identical duplicates never become confirmed leads', () {
    final campaign = _campaign([
      const StoryThread(
        id: 'same',
        title: 'Falscher Doppelter',
        description: 'Duplikat 1.',
      ),
      const StoryThread(
        id: 'same',
        title: 'Falscher Doppelter',
        description: 'Duplikat 2.',
      ),
      const StoryThread(
        id: 'bad id',
        title: 'Leerstelle',
        description: 'Nicht vertrauenswürdig.',
      ),
      const StoryThread(
        id: 'unsafe\n',
        title: 'Zeilenende',
        description: 'Nicht vertrauenswürdig.',
      ),
      const StoryThread(
        id: 'spoof\u202e',
        title: 'Bidi',
        description: 'Nicht vertrauenswürdig.',
      ),
      const StoryThread(
        id: 'über',
        title: 'Unicode-ID',
        description: 'Nicht vertrauenswürdig.',
      ),
      StoryThread(
        id: List.filled(65, 'x').join(),
        title: 'Lange ID',
        description: 'Nicht vertrauenswürdig.',
      ),
      const StoryThread(
        id: 'safe_1',
        title: 'Sichere Spur',
        description: 'Nur diese Spur ist eindeutig.',
      ),
    ]);

    final snapshot = CampaignResumeReader.read(campaign);

    expect(snapshot.openLeads, ['Sichere Spur: Nur diese Spur ist eindeutig.']);
    expect(snapshot.playerOverview, isNot(contains('Falscher Doppelter')));
    expect(snapshot.playerOverview, isNot(contains('Bidi')));
    expect(snapshot.playerOverview, isNot(contains('Zeilenende')));
    expect(snapshot.playerOverview, isNot(contains('Unicode-ID')));
  });

  test('limit counts only unique valid open leads, newest first', () {
    final campaign = _campaign(const [
      StoryThread(id: 'old', title: 'Alt', description: 'Offen.'),
      StoryThread(id: 'conflict', title: 'Doppelt', description: 'Offen.'),
      StoryThread(id: 'new', title: 'Neu', description: 'Offen.'),
      StoryThread(
        id: 'conflict',
        title: 'Doppelt',
        description: 'Jetzt abgeschlossen.',
        status: 'resolved',
      ),
      StoryThread(id: 'newest', title: 'Neueste', description: 'Offen.'),
    ]);

    final one = CampaignResumeReader.read(campaign, maxLeads: 1);
    final three = CampaignResumeReader.read(campaign, maxLeads: 3);

    expect(one.openLeads, ['Neueste: Offen.']);
    expect(three.openLeads, ['Neueste: Offen.', 'Neu: Offen.', 'Alt: Offen.']);
    expect(() => three.openLeads.clear(), throwsUnsupportedError);
    expect(three.openLeads.join(' '), isNot(contains('Doppelt')));
  });

  test('duplicate JSON is rejected; valid SQLite resumes safely', () async {
    final original = _campaign(const [
      StoryThread(id: 'old', title: 'Die Gruft', description: 'Offen.'),
      StoryThread(
        id: 'old',
        title: 'Die Gruft',
        description: 'Abgeschlossen.',
        status: 'resolved',
      ),
      StoryThread(id: 'safe', title: 'Der Turm', description: 'Untersuchen.'),
    ]);
    final invalidJson = jsonEncode(original.toJson());
    expect(
      () => Campaign.fromJson(jsonDecode(invalidJson) as Map<String, dynamic>),
      throwsFormatException,
    );
    expect(CampaignResumeReader.read(original).openLeads, [
      'Der Turm: Untersuchen.',
    ]);
    expect(jsonEncode(original.toJson()), invalidJson);

    // Import validation rejects duplicates. A valid saved campaign must
    // still retain its unique open lead after the database restarts.
    final clean = _campaign(const [
      StoryThread(id: 'safe', title: 'Der Turm', description: 'Untersuchen.'),
    ]);
    final cleanJson = jsonEncode(clean.toJson());
    final decoded = Campaign.fromJson(
      jsonDecode(cleanJson) as Map<String, dynamic>,
    );
    expect(jsonEncode(decoded.toJson()), cleanJson);

    final folder = await Directory.systemTemp.createTemp('resume-lead-id-');
    final path = paths.join(folder.path, 'campaign.sqlite');
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      await repository.saveCampaign(decoded);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final restored = (await repository.getCampaign(decoded.id))!;
      final before = jsonEncode(restored.toJson());
      final snapshot = CampaignResumeReader.read(restored);

      expect(snapshot.openLeads, ['Der Turm: Untersuchen.']);
      expect(restored.storyThreads, hasLength(1));
      expect(restored.hero.hitPoints, 12);
      expect(jsonEncode(restored.toJson()), before);
      expect(
        (await repository.reconstructCampaign(decoded.id))!.toJson(),
        restored.toJson(),
      );
    } finally {
      await repository.close();
      await folder.delete(recursive: true);
    }
  });
}
