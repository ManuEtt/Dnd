import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';

void main() {
  final engine = GameEngine();

  Campaign start() {
    final first = engine.createRabenwacht(
      engine.createDemo().hero.copyWith(name: 'Valen', experience: 900),
    );
    final finished = first.copyWith(
      storyBible: {...first.storyBible, 'stage': 'end-seal'},
      facts: {...first.facts, 'ending': 'end-seal'},
    );
    return engine.act(finished, 'Fortsetzung beginnen').campaign;
  }

  Campaign collect(Campaign campaign, String witness) {
    campaign = engine.act(
      campaign,
      witness == 'elda' ? 'Ich besuche Elda.' : 'Ich suche Tarek.',
    ).campaign;
    campaign = engine.act(
      campaign,
      witness == 'elda'
          ? 'Ich untersuche die Zeichnungen.'
          : 'Ich untersuche die Tinte im Brief.',
    ).campaign;
    expect(campaign.pendingRoll, isNotNull);
    return engine.resolveRoll(campaign, natural: 20).campaign;
  }

  Campaign gallery() {
    var campaign = start();
    campaign = collect(campaign, 'elda');
    campaign = collect(campaign, 'tarek');
    campaign = engine.act(campaign, 'Ich gehe zum Haus ohne Türen.').campaign;
    expect(campaign.storyBible['stage'], 'voice-house');
    campaign = engine.act(campaign, 'Ich betrachte die Porträts.').campaign;
    expect(campaign.storyBible['stage'], 'voice-gallery');
    return campaign;
  }

  Campaign library() {
    var campaign = gallery();
    campaign = engine.act(campaign, 'Ich betrete die Bibliothek.').campaign;
    expect(campaign.storyBible['stage'], 'voice-library');
    return campaign;
  }

  test('Akt VII wird in Akt VI an der Galerie angeschlossen', () {
    final before = gallery();
    expect(before.facts['voice:chronistMet'], isNull);
    expect(
      before.quests.where((q) => q.id == 'voice-chronist'),
      isEmpty,
    );
    var campaign = engine.act(
      before,
      'Ich vergleiche die Porträts.',
    ).campaign;
    expect(campaign.facts['voice:portraitCompared'], 'true');
    expect(campaign.hero.toJson(), before.hero.toJson());
    campaign = engine.act(campaign, 'Ich betrete die Bibliothek.').campaign;
    expect(campaign.facts['voice:chronistMet'], 'true');
    expect(
      campaign.quests.where((q) => q.id == 'voice-chronist').length,
      1,
    );
    expect(campaign.storyBible['stage'], 'voice-library');
    expect(Campaign.fromJson(campaign.toJson()).toJson(), campaign.toJson());
  });

  test('Keine Chronist-Spoiler vor der Bibliothek', () {
    final campaign = gallery();
    final clues = engine.act(campaign, 'Hinweise').campaign.messages.last.text;
    expect(clues, isNot(contains('Chronist')));
    expect(clues, isNot(contains('Zeugenfolge')));
    final revealed = engine.act(library(), 'Hinweise');
    expect(revealed.campaign.messages.last.text, contains('Chronist'));
  });

  test('Ablehnung bleibt endgültig, ohne Charakter- oder EP-Änderung', () {
    final before = library();
    var campaign = engine.act(
      before,
      'Ich lehne das Angebot ab.',
    ).campaign;
    expect(campaign.facts['voice:chronistChoice'], 'refused');
    expect(campaign.hero.toJson(), before.hero.toJson());
    expect(
      campaign.quests.singleWhere((q) => q.id == 'voice-chronist').status,
      'completed',
    );
    campaign = engine.act(
      campaign,
      'Ich täusche Zustimmung vor.',
    ).campaign;
    expect(campaign.facts['voice:chronistChoice'], 'refused');
    expect(campaign.facts['voice:chronistSuspicious'], isNull);
  });

  test('Verhandlung ist keine Zustimmung, Täuschung hat Folgen', () {
    var campaign = library();
    campaign = engine.act(campaign, 'Ich verhandle Bedingungen.').campaign;
    expect(campaign.facts['voice:termsQuestioned'], 'true');
    expect(campaign.facts['voice:chronistChoice'], isNull);
    campaign = engine.act(campaign, 'Ich täusche Zustimmung vor.').campaign;
    expect(campaign.facts['voice:chronistChoice'], 'feigned');
    expect(campaign.facts['voice:chronistSuspicious'], 'true');
    expect(Campaign.fromJson(campaign.toJson()).toJson(), campaign.toJson());
  });

  test('Preis erfordert exakte bewusste Zustimmung', () {
    final before = library();
    var campaign = engine.act(
      before,
      'Ich frage nach dem Preis.',
    ).campaign;
    expect(campaign.storyBible['stage'], 'voice-price');
    campaign = engine.act(
      campaign,
      'Ich bestätige den Preis nicht.',
    ).campaign;
    expect(campaign.storyBible['stage'], 'voice-price');
    expect(campaign.facts['voice:chronistChoice'], isNull);
    campaign = engine.act(
      campaign,
      'Ich bestätige den Preis: Eine andere Person wird vergessen.',
    ).campaign;
    expect(campaign.storyBible['stage'], 'voice-library');
    expect(campaign.facts['voice:chronistChoice'], 'accepted');
    expect(campaign.facts['voice:chronistDebt'], 'pending');
    expect(campaign.hero.toJson(), before.hero.toJson());
    expect(campaign.npcs.map((n) => n.id).toList(),
        before.npcs.map((n) => n.id).toList());
    expect(Campaign.fromJson(campaign.toJson()).toJson(), campaign.toJson());
  });

  test('Eine Preisfrage kann ohne Konsequenzen abgebrochen werden', () {
    var campaign = engine.act(
      library(),
      'Was kostet der Handel?',
    ).campaign;
    campaign = engine.act(campaign, 'Ich lehne ab.').campaign;
    expect(campaign.storyBible['stage'], 'voice-library');
    expect(campaign.facts['voice:chronistChoice'], isNull);
    expect(campaign.facts['voice:chronistDebt'], isNull);
  });

  test('Blattbelege müssen vor Übergabe tatsächlich entdeckt werden', () {
    var campaign = engine.act(
      library(),
      'Ich suche das vierzehnte Blatt.',
    ).campaign;
    expect(campaign.storyBible['stage'], 'voice-ledger');
    campaign = engine.act(
      campaign,
      'Ich vertraue Liora den Namen an.',
    ).campaign;
    expect(campaign.storyBible['stage'], 'voice-ledger');
    expect(campaign.facts['voice:nameCustody'], isNull);
    campaign = engine.act(
      campaign,
      'Ich untersuche das Blatt.',
    ).campaign;
    expect(campaign.facts['voice:oathPageFound'], 'true');
    campaign = engine.act(
      campaign,
      'Ich vertraue Liora den Namen an.',
    ).campaign;
    expect(campaign.storyBible['stage'], 'voice-threshold');
    expect(campaign.facts['voice:nameCustody'], 'liora');
    expect(campaign.quests.singleWhere((q) => q.id == 'voice-main').status,
        'active');
    expect(Campaign.fromJson(campaign.toJson()).toJson(), campaign.toJson());
    final paused = engine.act(campaign, 'Ich besiege den Chronisten.').campaign;
    expect(paused.storyBible['stage'], 'voice-threshold');
    expect(paused.facts['voice:act7Reached'], 'true');
  });

  test('Zurückkehren und Namen selbst verwahren ist ein anderer Weg', () {
    var campaign = gallery();
    campaign = engine.act(campaign, 'Ich verlasse das Haus.').campaign;
    expect(campaign.storyBible['stage'], 'voice-house');
    campaign = engine.act(campaign, 'Ich betrachte die Porträts.').campaign;
    campaign = engine.act(campaign, 'Ich betrete die Bibliothek.').campaign;
    campaign = engine.act(campaign, 'Ich suche das vierzehnte Blatt.').campaign;
    campaign = engine.act(campaign, 'Ich untersuche das Blatt.').campaign;
    campaign = engine
        .act(campaign, 'Ich will den Namen selbst bewahren.')
        .campaign;
    expect(campaign.storyBible['stage'], 'voice-threshold');
    expect(campaign.facts['voice:nameCustody'], 'hero');
    expect(campaign.facts['voice:chronistChoice'], isNull);
  });
}
