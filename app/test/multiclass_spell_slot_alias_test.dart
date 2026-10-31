import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lebendiger_spielleiter/data/campaign_repository.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/multiclass_rules.dart';
import 'package:lebendiger_spielleiter/domain/spellcasting_rules.dart';

HeroCharacter _hero({
  String first = 'Magier',
  String second = '',
  int totalLevel = 5,
  int secondLevel = 0,
  Map<String, int> spent = const {},
}) => HeroCharacter(
  id: 'alias-caster',
  name: 'Arina',
  className: first,
  secondaryClassName: second,
  secondaryClassLevel: secondLevel,
  level: totalLevel,
  hitPoints: 18,
  maxHitPoints: 25,
  spells: const ['Magisches Geschoss'],
  spentSpellSlots: spent,
);

void main() {
  setUpAll(sqfliteFfiInit);

  test('all confirmed full-caster aliases grant identical spell slots', () {
    const aliases = <String, List<String>>{
      'Barde': ['Barde', 'Bard', 'Bardin'],
      'Kleriker': ['Kleriker', 'Cleric', 'Klerikerin'],
      'Druide': ['Druide', 'Druid', 'Druidin'],
      'Magier': ['Magier', 'Wizard', 'Magierin'],
      'Zauberer': ['Zauberer', 'Sorcerer', 'Zauberin'],
    };
    for (final entry in aliases.entries) {
      final expected = MulticlassRules.spellSlots(_hero(first: entry.key));
      for (final alias in entry.value) {
        final character = _hero(first: '  ${alias.toUpperCase()}  ');
        expect(
          MulticlassRules.combinedSpellcasterLevel(character),
          5,
          reason: alias,
        );
        expect(MulticlassRules.spellSlots(character), expected, reason: alias);
        expect(
          SpellcastingRules.availableSlots(character),
          {1: 4, 2: 3, 3: 2},
          reason: alias,
        );
      }
    }
  });

  test('paladin and ranger aliases contribute half rounded up', () {
    for (final name in [
      'Paladin',
      'Waldläufer',
      'Ranger',
      'Waldläuferin',
      'Waldlaeufer',
    ]) {
      final character = _hero(first: name, totalLevel: 5);
      expect(
        MulticlassRules.combinedSpellcasterLevel(character),
        3,
        reason: name,
      );
      expect(
        SpellcastingRules.availableSlots(character),
        {1: 4, 2: 2},
        reason: name,
      );
    }
  });

  test('primary and secondary aliases use individual class levels', () {
    final canonical = _hero(
      first: 'Magier',
      second: 'Waldläufer',
      totalLevel: 8,
      secondLevel: 3,
    );
    final aliases = _hero(
      first: ' Wizard ',
      second: 'RANGER',
      totalLevel: 8,
      secondLevel: 3,
    );
    expect(MulticlassRules.combinedSpellcasterLevel(aliases), 7);
    expect(
      MulticlassRules.spellSlots(aliases),
      MulticlassRules.spellSlots(canonical),
    );
    expect(
      SpellcastingRules.availableSlots(aliases),
      {1: 4, 2: 3, 3: 3, 4: 1},
    );
    expect(aliases.primaryClassLevel, 5);
    expect(aliases.secondaryClassLevel, 3);
  });

  test('warlock pact slots never count as normal spellcaster levels', () {
    final character = _hero(
      first: 'WARLOCK',
      second: 'Wizard',
      totalLevel: 8,
      secondLevel: 5,
    );
    expect(MulticlassRules.combinedSpellcasterLevel(character), 5);
    expect(SpellcastingRules.pactClassLevel(character), 3);
    expect(SpellcastingRules.pactSlotCount(character), 2);
    expect(SpellcastingRules.pactSlotLevel(character), 2);
    expect(SpellcastingRules.availablePactSlots(character), 2);
    expect(
      SpellcastingRules.availableSlots(character),
      {1: 4, 2: 3, 3: 2},
    );
    expect(
      MulticlassRules.spellSlots(_hero(first: 'Hexenmeister')),
      everyElement(0),
    );
  });

  test('unknown class names do not grant slots or mutate old hero data', () {
    final hero = _hero(first: 'Wizard (unverified)');
    final snapshot = hero.toJson();
    expect(MulticlassRules.combinedSpellcasterLevel(hero), 0);
    expect(SpellcastingRules.availableSlots(hero), isEmpty);
    expect(
      () => SpellcastingRules.cast(
        hero,
        spellName: 'Magisches Geschoss',
        spellLevel: 1,
      ),
      throwsStateError,
    );
    expect(hero.toJson(), snapshot);
    final mixed = _hero(
      first: 'Unknown Homebrew',
      second: 'Wizard',
      totalLevel: 6,
      secondLevel: 2,
    );
    expect(MulticlassRules.combinedSpellcasterLevel(mixed), 2);
    expect(MulticlassRules.spellSlots(mixed).first, 3);
    expect(mixed.toJson()['className'], 'Unknown Homebrew');
    expect(mixed.toJson()['secondaryClassName'], 'Wizard');
  });

  test('legacy JSON preserves alias, spent slots and read-only evaluation', () {
    final source = _hero(
      first: 'Wizard',
      second: 'Ranger',
      totalLevel: 8,
      secondLevel: 3,
      spent: const {'1': 2, '4': 1},
    );
    final serialized = source.toJson();
    final old = HeroCharacter.fromJson(serialized);
    expect(old.className, 'Wizard');
    expect(old.secondaryClassName, 'Ranger');
    expect(old.spentSpellSlots, {'1': 2, '4': 1});
    expect(
      SpellcastingRules.availableSlots(old),
      {1: 2, 2: 3, 3: 3, 4: 0},
    );
    expect(old.toJson(), serialized);
    expect(source.toJson(), serialized);
  });

  test('SQLite restart, retry and stale revision preserve slots', () async {
    final directory = await Directory.systemTemp.createTemp('alias-slots-');
    final path = '${directory.path}/campaign.sqlite';
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      final campaign = Campaign(
        id: 'alias-campaign',
        name: 'Alias-Test',
        world: 'Testwelt',
        sessionId: 'alias-session',
        scene: 'Start',
        hero: _hero(first: 'Wizard', spent: const {'1': 1}),
      );
      await repository.saveCampaign(campaign);
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final reloaded = (await repository.getCampaign(campaign.id))!;
      expect(reloaded.hero.className, 'Wizard');
      expect(
        SpellcastingRules.availableSlots(reloaded.hero),
        {1: 3, 2: 3, 3: 2},
      );

      final cast = SpellcastingRules.cast(
        reloaded.hero,
        spellName: 'Magisches Geschoss',
        spellLevel: 1,
      );
      expect(reloaded.hero.spentSpellSlots, {'1': 1});
      final committed = reloaded.copyWith(hero: cast.hero, revision: 1);
      await repository.saveCampaign(committed, expectedRevision: 0);
      await repository.saveCampaign(committed, expectedRevision: 0);

      final stale = reloaded.copyWith(
        hero: reloaded.hero.copyWith(spentSpellSlots: const {'1': 3}),
        revision: 1,
      );
      await expectLater(
        repository.saveCampaign(stale, expectedRevision: 0),
        throwsA(isA<CampaignConflictException>()),
      );
      await repository.close();
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final confirmed = (await repository.getCampaign(campaign.id))!;
      expect(confirmed.revision, 1);
      expect(confirmed.hero.className, 'Wizard');
      expect(confirmed.hero.spentSpellSlots, {'1': 2});
      expect(
        SpellcastingRules.availableSlots(confirmed.hero),
        {1: 2, 2: 3, 3: 2},
      );
    } finally {
      await repository.close();
      await directory.delete(recursive: true);
    }
  });
}
