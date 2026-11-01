import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/campaign_repository.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_preparation_exchange_rules.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

HeroCharacter _hero({
  String first = 'Magier',
  String second = '',
  int level = 1,
  int secondLevel = 0,
  List<String> spells = const ['Magic Missile', 'Shield'],
}) => HeroCharacter(
  id: 'exchange-caster',
  name: 'Fina',
  className: first,
  secondaryClassName: second,
  secondaryClassLevel: secondLevel,
  level: level,
  hitPoints: 22,
  maxHitPoints: 22,
  spells: spells,
);

SrdSpellPreparationExchangePlan _preview({
  required HeroCharacter before,
  required HeroCharacter after,
  required SrdSpellCatalog catalog,
  required String className,
  required List<String> oldSpells,
  required List<String> newSpells,
  required SrdSpellPreparationTrigger event,
  bool confirmed = true,
  bool restConfirmed = true,
  bool bookConfirmed = true,
}) => SrdSpellPreparationExchangeRules.preview(
  before: before,
  after: after,
  castingClass: className,
  previouslyPrepared: oldSpells,
  proposedPrepared: newSpells,
  catalog: catalog,
  trigger: event,
  playerChangeConfirmed: confirmed,
  completedLongRestConfirmed: restConfirmed,
  wizardSpellbookAccessConfirmed: bookConfirmed,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(sqfliteFfiInit);
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('eight SRD caster classes use exactly their own exchange trigger', () {
    const cases = <String, List<String>>{
      'Barde': ['Cure Wounds', 'Healing Word'],
      'Kleriker': ['Bless', 'Guiding Bolt'],
      'Druide': ['Entangle', 'Longstrider'],
      'Paladin': ['Bless', 'Cure Wounds'],
      'Waldläufer': ['Entangle', "Hunter's Mark"],
      'Zauberer': ['Magic Missile', 'Shield'],
      'Hexenmeister': ['Hex', 'Charm Person'],
      'Magier': ['Magic Missile', 'Shield'],
    };
    const restClasses = {
      'Kleriker',
      'Druide',
      'Paladin',
      'Waldläufer',
      'Magier',
    };
    for (final entry in cases.entries) {
      final isRest = restClasses.contains(entry.key);
      final before = _hero(first: entry.key, spells: entry.value);
      final after = isRest ? before : before.copyWith(level: 2);
      final event = isRest
          ? SrdSpellPreparationTrigger.completedLongRest
          : SrdSpellPreparationTrigger.classLevelGain;
      final accepted = _preview(
        before: before,
        after: after,
        catalog: catalog,
        className: entry.key,
        oldSpells: [entry.value.first],
        newSpells: [entry.value.last],
        event: event,
      );
      expect(accepted.castingClass, entry.key);
      expect(accepted.removed, [entry.value.first]);
      expect(accepted.added, [entry.value.last]);
      expect(() => accepted.removed.add('Invalid'), throwsUnsupportedError);
      accepted.verifyUnchanged(before, after);
      final wrong = isRest
          ? SrdSpellPreparationTrigger.classLevelGain
          : SrdSpellPreparationTrigger.completedLongRest;
      expect(
        () => _preview(
          before: before,
          after: after,
          catalog: catalog,
          className: entry.key,
          oldSpells: [entry.value.first],
          newSpells: [entry.value.last],
          event: wrong,
        ),
        throwsFormatException,
        reason: entry.key,
      );
    }
  });

  test('class name aliases preserve the same confirmed trigger', () {
    final before = _hero(first: 'Wizard');
    final valid = _preview(
      before: before,
      after: before,
      catalog: catalog,
      className: '  WIZARD  ',
      oldSpells: const ['Magic Missile'],
      newSpells: const ['Shield'],
      event: SrdSpellPreparationTrigger.completedLongRest,
    );
    expect(valid.castingClass, 'Magier');
    expect(before.className, 'Wizard');
  });

  test('cleric, druid and wizard can swap more than one after long rest', () {
    const cases = <String, List<List<String>>>{
      'Kleriker': [
        ['Bless', 'Cure Wounds'],
        ['Guiding Bolt', 'Healing Word'],
      ],
      'Druide': [
        ['Entangle', 'Cure Wounds'],
        ['Longstrider', 'Healing Word'],
      ],
      'Magier': [
        ['Magic Missile', 'Shield'],
        ['Mage Armor', 'Detect Magic'],
      ],
    };
    for (final entry in cases.entries) {
      final before = _hero(
        first: entry.key,
        spells: [...entry.value[0], ...entry.value[1]],
      );
      final plan = _preview(
        before: before,
        after: before,
        catalog: catalog,
        className: entry.key,
        oldSpells: entry.value[0],
        newSpells: entry.value[1],
        event: SrdSpellPreparationTrigger.completedLongRest,
      );
      expect(plan.removed, entry.value[0]);
      expect(plan.added, entry.value[1]);
    }
  });

  test('bard, sorcerer, paladin and ranger cannot swap two at once', () {
    const cases = <String, List<List<String>>>{
      'Barde': [
        ['Cure Wounds', 'Healing Word'],
        ['Detect Magic', 'Charm Person'],
      ],
      'Zauberer': [
        ['Magic Missile', 'Shield'],
        ['Mage Armor', 'Burning Hands'],
      ],
      'Paladin': [
        ['Bless', 'Cure Wounds'],
        ['Detect Magic', 'Command'],
      ],
      'Waldläufer': [
        ['Entangle', 'Cure Wounds'],
        ["Hunter's Mark", 'Detect Magic'],
      ],
    };
    for (final entry in cases.entries) {
      final rest =
          entry.key == 'Paladin' || entry.key == 'Waldläufer';
      final before = _hero(
        first: entry.key,
        spells: [...entry.value[0], ...entry.value[1]],
      );
      expect(
        () => _preview(
          before: before,
          after: rest ? before : before.copyWith(level: 2),
          catalog: catalog,
          className: entry.key,
          oldSpells: entry.value[0],
          newSpells: entry.value[1],
          event: rest
              ? SrdSpellPreparationTrigger.completedLongRest
              : SrdSpellPreparationTrigger.classLevelGain,
        ),
        throwsFormatException,
        reason: entry.key,
      );
    }
  });

  test('a rest must be confirmed, and a wizard needs spellbook access', () {
    final hero = _hero();
    final beforeJson = hero.toJson();
    expect(
      () => _preview(
        before: hero,
        after: hero,
        catalog: catalog,
        className: 'Magier',
        oldSpells: const ['Magic Missile'],
        newSpells: const ['Shield'],
        event: SrdSpellPreparationTrigger.completedLongRest,
        restConfirmed: false,
      ),
      throwsFormatException,
    );
    expect(
      () => _preview(
        before: hero,
        after: hero,
        catalog: catalog,
        className: 'Magier',
        oldSpells: const ['Magic Missile'],
        newSpells: const ['Shield'],
        event: SrdSpellPreparationTrigger.completedLongRest,
        bookConfirmed: false,
      ),
      throwsFormatException,
    );
    expect(
      () => _preview(
        before: hero,
        after: hero,
        catalog: catalog,
        className: 'Magier',
        oldSpells: const ['Magic Missile'],
        newSpells: const ['Shield'],
        event: SrdSpellPreparationTrigger.completedLongRest,
        confirmed: false,
      ),
      throwsFormatException,
    );
    expect(hero.toJson(), beforeJson);
  });

  test('cantrips, bogus spells, duplicates, wrong classes and levels fail', () {
    final hero = _hero(
      first: 'Kleriker',
      spells: const [
        'Bless',
        'Cure Wounds',
        'Light',
        'Magic Missile',
        'Fireball',
        'Non-SRD Spell',
      ],
    );
    final badSets = <List<String>>[
      ['Light'],
      ['Fireball'],
      ['Magic Missile'],
      ['Non-SRD Spell'],
      ['Bless', 'Bless'],
      [' Bless'],
    ];
    for (final names in badSets) {
      expect(
        () => _preview(
          before: hero,
          after: hero,
          catalog: catalog,
          className: 'Kleriker',
          oldSpells: const ['Cure Wounds'],
          newSpells: names,
          event: SrdSpellPreparationTrigger.completedLongRest,
        ),
        throwsFormatException,
      );
    }
    expect(
      () => _preview(
        before: hero,
        after: hero,
        catalog: catalog,
        className: 'Warlock',
        oldSpells: const ['Bless'],
        newSpells: const ['Cure Wounds'],
        event: SrdSpellPreparationTrigger.completedLongRest,
      ),
      throwsFormatException,
    );
  });

  test('swaps must preserve count, change content and retain ownership', () {
    final hero = _hero(
      first: 'Kleriker',
      spells: const ['Bless', 'Cure Wounds', 'Guiding Bolt'],
    );
    for (final replacement in <List<String>>[
      ['Bless'],
      ['Bless', 'Cure Wounds', 'Guiding Bolt'],
      ['Bless', 'Guiding Bolt'],
    ]) {
      expect(
        () => _preview(
          before: hero,
          after: hero,
          catalog: catalog,
          className: 'Kleriker',
          oldSpells: const ['Bless', 'Cure Wounds'],
          newSpells: replacement,
          event: SrdSpellPreparationTrigger.completedLongRest,
        ),
        throwsFormatException,
      );
    }
  });

  test('level change must be in the selected owned class, not total alone', () {
    final before = _hero(
      first: 'Magier',
      second: 'Zauberer',
      level: 6,
      secondLevel: 3,
      spells: const ['Magic Missile', 'Shield'],
    );
    final correctlyLeveled = before.copyWith(
      level: 7,
      secondaryClassLevel: 4,
    );
    final plan = _preview(
      before: before,
      after: correctlyLeveled,
      catalog: catalog,
      className: 'Sorcerer',
      oldSpells: const ['Magic Missile'],
      newSpells: const ['Shield'],
      event: SrdSpellPreparationTrigger.classLevelGain,
    );
    expect(plan.castingClass, 'Zauberer');
    expect(
      () => _preview(
        before: before,
        after: correctlyLeveled,
        catalog: catalog,
        className: 'Magier',
        oldSpells: const ['Magic Missile'],
        newSpells: const ['Shield'],
        event: SrdSpellPreparationTrigger.classLevelGain,
      ),
      throwsFormatException,
    );
    final unexpectedClass = before.copyWith(
      className: 'Kleriker',
      level: 7,
      secondaryClassLevel: 4,
    );
    expect(
      () => _preview(
        before: before,
        after: unexpectedClass,
        catalog: catalog,
        className: 'Zauberer',
        oldSpells: const ['Magic Missile'],
        newSpells: const ['Shield'],
        event: SrdSpellPreparationTrigger.classLevelGain,
      ),
      throwsFormatException,
    );
    expect(
      () => _preview(
        before: before,
        after: before.copyWith(level: 7, secondaryClassLevel: 3),
        catalog: catalog,
        className: 'Sorcerer',
        oldSpells: const ['Magic Missile'],
        newSpells: const ['Shield'],
        event: SrdSpellPreparationTrigger.classLevelGain,
      ),
      throwsFormatException,
    );
  });

  test('unverified class and duplicate alias multiclass never grant swaps', () {
    for (final hero in [
      _hero(first: 'Unconfirmed'),
      _hero(first: 'Magier', second: 'Wizard', level: 6, secondLevel: 2),
      _hero(first: 'Magier', second: 'Unknown', level: 6, secondLevel: 2),
      _hero(first: 'Magier', second: 'Zauberer', level: 4, secondLevel: 4),
    ]) {
      expect(
        () => _preview(
          before: hero,
          after: hero,
          catalog: catalog,
          className: 'Magier',
          oldSpells: const ['Magic Missile'],
          newSpells: const ['Shield'],
          event: SrdSpellPreparationTrigger.completedLongRest,
        ),
        throwsFormatException,
      );
    }
  });

  test('preview is read-only, immutable and rejects stale snapshots', () {
    final before = _hero();
    final after = before.copyWith(hitPoints: 21);
    final jsonBefore = before.toJson();
    final jsonAfter = after.toJson();
    final plan = _preview(
      before: before,
      after: after,
      catalog: catalog,
      className: 'Magier',
      oldSpells: const ['Magic Missile'],
      newSpells: const ['Shield'],
      event: SrdSpellPreparationTrigger.completedLongRest,
    );
    plan.verifyUnchanged(before, after);
    expect(before.toJson(), jsonBefore);
    expect(after.toJson(), jsonAfter);
    expect(() => plan.added.add('Fireball'), throwsUnsupportedError);
    expect(
      () => plan.verifyUnchanged(before, after.copyWith(hitPoints: 20)),
      throwsFormatException,
    );
    expect(
      () => plan.verifyUnchanged(before.copyWith(level: 2), after),
      throwsFormatException,
    );
  });

  test('SQLite restart and stale write do not implicitly commit a swap', () async {
    final directory = await Directory.systemTemp.createTemp('spell-swap-');
    final path = '${directory.path}/campaign.sqlite';
    var repo = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      final initial = Campaign(
        id: 'spell-swap',
        name: 'Zauberaustausch',
        world: 'Test',
        sessionId: 'session',
        scene: 'Anfang',
        hero: _hero(),
      );
      await repo.saveCampaign(initial);
      await repo.close();
      repo = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final loaded = (await repo.getCampaign(initial.id))!;
      final plan = _preview(
        before: loaded.hero,
        after: loaded.hero,
        catalog: catalog,
        className: 'Magier',
        oldSpells: const ['Magic Missile'],
        newSpells: const ['Shield'],
        event: SrdSpellPreparationTrigger.completedLongRest,
      );
      plan.verifyUnchanged(loaded.hero, loaded.hero);
      // A read-only preview changes neither the persisted revision nor spells.
      expect((await repo.getCampaign(initial.id))!.revision, 0);
      expect((await repo.getCampaign(initial.id))!.hero.spells, [
        'Magic Missile',
        'Shield',
      ]);
      final next = loaded.copyWith(
        revision: 1,
        hero: loaded.hero.copyWith(hitPoints: 21),
      );
      await repo.saveCampaign(next, expectedRevision: 0);
      await repo.saveCampaign(next, expectedRevision: 0);
      final stale = loaded.copyWith(
        revision: 1,
        hero: loaded.hero.copyWith(hitPoints: 20),
      );
      await expectLater(
        repo.saveCampaign(stale, expectedRevision: 0),
        throwsA(isA<CampaignConflictException>()),
      );
      await repo.close();
      repo = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final reloaded = (await repo.getCampaign(initial.id))!;
      expect(reloaded.revision, 1);
      expect(reloaded.hero.hitPoints, 21);
      expect(
        () => plan.verifyUnchanged(loaded.hero, reloaded.hero),
        throwsFormatException,
      );
      expect(reloaded.hero.spells, loaded.hero.spells);
    } finally {
      await repo.close();
      await directory.delete(recursive: true);
    }
  });
}
