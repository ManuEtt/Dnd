import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/story/campaign_resume_context.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Campaign _campaign(Map<String, String> facts) => Campaign(
  id: 'visible-fact-identity',
  name: 'Die Nebelbrücke',
  world: 'Valdorn',
  sessionId: 'session-one',
  revision: 0,
  hero: HeroCharacter(id: 'aria', name: 'Aria', hitPoints: 17),
  scene: 'Eine unbestätigte Erzählung erwähnt 999 Gold.',
  facts: facts,
);

void main() {
  sqfliteFfiInit();

  test('different long keys with the same visible prefix are omitted', () {
    final longPrefix = List.filled(85, 'K').join();
    final campaign = _campaign({
      '$longPrefix-Nord': 'Nur die Nordwache kennt den Ausgang.',
      'Tor': 'Die Wache hat das Stadttor versiegelt.',
      '$longPrefix-Sued': 'Nur die Südwache kennt den Ausgang.',
      'Brücke': 'Die Brücke bleibt geschlossen.',
    });
    final raw = jsonEncode(campaign.toJson());

    final snapshot = CampaignResumeReader.read(campaign, maxFacts: 4);

    expect(snapshot.confirmedFacts, [
      'Brücke: Die Brücke bleibt geschlossen.',
      'Tor: Die Wache hat das Stadttor versiegelt.',
    ]);
    expect(snapshot.playerOverview, isNot(contains('Nordwache')));
    expect(snapshot.playerOverview, isNot(contains('Südwache')));
    expect(snapshot.confirmedFacts.join(' '), isNot(contains('999 Gold')));
    expect(jsonEncode(campaign.toJson()), raw);
    expect(campaign.hero.hitPoints, 17);
  });

  test('invisible marks and collapsed whitespace cannot forge fact names', () {
    final campaign = _campaign({
      'Weg': 'Der erste Weg ist bestätigt.',
      'We\u200bg': 'Ein anderer Weg wird fälschlich bestätigt.',
      'Stadt Tor': 'Die Stadtmauer ist versiegelt.',
      'Stadt\n Tor': 'Die Sperre wurde aufgehoben.',
      '\u200b\u2066': 'Nicht sichtbar.',
      'Hafen': 'Die Anlegestelle ist sicher.',
    });
    final raw = jsonEncode(campaign.toJson());
    final snapshot = CampaignResumeReader.read(campaign);

    expect(snapshot.confirmedFacts, ['Hafen: Die Anlegestelle ist sicher.']);
    expect(snapshot.playerOverview, isNot(contains('erster Weg')));
    expect(snapshot.playerOverview, isNot(contains('Stadtmauer')));
    expect(snapshot.playerOverview, isNot(contains('aufgehoben')));
    expect(snapshot.playerOverview, isNot(contains('fälschlich')));
    expect(jsonEncode(campaign.toJson()), raw);
  });

  test('collisions outside the display limit still exclude both identities', () {
    final longPrefix = List.filled(85, 'L').join();
    final campaign = _campaign({
      '$longPrefix-old': 'Ein alter widersprüchlicher Beleg.',
      'Turm': 'Die Tür des Turms ist abgeschlossen.',
      'See': 'Die Fähre liegt vor Anker.',
      '$longPrefix-new': 'Ein jüngerer widersprüchlicher Beleg.',
      'Wald': 'Der Waldweg ist passierbar.',
    });
    final snapshot = CampaignResumeReader.read(campaign, maxFacts: 2);
    final raw = jsonEncode(campaign.toJson());

    expect(snapshot.confirmedFacts, [
      'Wald: Der Waldweg ist passierbar.',
      'See: Die Fähre liegt vor Anker.',
    ]);
    expect(snapshot.confirmedFacts, hasLength(2));
    expect(snapshot.confirmedFacts.join(' '), isNot(contains('Beleg')));
    expect(jsonEncode(campaign.toJson()), raw);
  });

  test('same visible overview still invalidates changed hidden source', () {
    final longPrefix = List.filled(85, 'N').join();
    final campaign = _campaign({
      '$longPrefix-a': 'Erste alte Aussage.',
      '$longPrefix-b': 'Zweite alte Aussage.',
      'Tor': 'Das Tor ist geschlossen.',
    });
    final snapshot = CampaignResumeReader.read(campaign);
    final changed = campaign.copyWith(
      facts: {
        '$longPrefix-a': 'Erste alte Aussage.',
        '$longPrefix-b': 'Nachträglich verfälschte alte Aussage.',
        'Tor': 'Das Tor ist geschlossen.',
      },
    );

    expect(
      CampaignResumeReader.read(changed).confirmedFacts,
      snapshot.confirmedFacts,
    );
    expect(snapshot.confirmedFacts, ['Tor: Das Tor ist geschlossen.']);
    expect(() => snapshot.requireCurrent(changed), throwsFormatException);
    snapshot.requireCurrent(campaign);
    expect(campaign.revision, changed.revision);
    expect(changed.hero.toJson(), campaign.hero.toJson());
  });

  test('JSON and SQLite restore raw keys without promoting ambiguous facts', () async {
    final longPrefix = List.filled(85, 'R').join();
    final source = _campaign({
      '$longPrefix-a': 'Ein fragwürdiger Befund.',
      '$longPrefix-b': 'Ein widersprüchlicher Befund.',
      'Brunnen': 'Der Brunnen ist geschützt.',
    });
    final raw = jsonEncode(source.toJson());
    final decoded = Campaign.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
    final originalSnapshot = CampaignResumeReader.read(source);
    expect(
      CampaignResumeReader.read(decoded).confirmedFacts,
      originalSnapshot.confirmedFacts,
    );

    final folder = await Directory.systemTemp.createTemp('resume-fact-key-');
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
      final snapshot = CampaignResumeReader.read(restored);

      expect(snapshot.confirmedFacts, [
        'Brunnen: Der Brunnen ist geschützt.',
      ]);
      expect(snapshot.playerOverview, isNot(contains('fragwürdiger')));
      expect(snapshot.playerOverview, isNot(contains('widersprüchlicher')));
      expect(restored.facts, source.facts);
      expect(restored.hero.toJson(), source.hero.toJson());
      expect(restored.revision, source.revision);
      originalSnapshot.requireCurrent(restored);
      expect(jsonEncode(source.toJson()), raw);
      expect(
        (await repository.reconstructCampaign(source.id))!.toJson(),
        restored.toJson(),
      );
    } finally {
      await repository.close();
      await folder.delete(recursive: true);
    }
  });
}
