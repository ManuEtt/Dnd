import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/campaign_repository.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_class_prepared_spell_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_prepared_spell_record.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

HeroCharacter _hero({
  String first = 'Magier',
  String second = 'Zauberer',
  int level = 6,
  int secondaryLevel = 3,
  List<String> spells = const [
    'Magisches Geschoss',
    'Licht',
    'Fireball',
  ],
}) => HeroCharacter(
  id: 'record-caster',
  name: 'Arina',
  className: first,
  secondaryClassName: second,
  secondaryClassLevel: secondaryLevel,
  level: level,
  spells: spells,
  hitPoints: 22,
  maxHitPoints: 22,
);

Map<String, List<String>> get _selections => {
  'Wizard': ['Magisches Geschoss', 'Licht'],
  'Sorcerer': ['Magisches Geschoss'],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late dynamic catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('explicit selections remain class-specific and immutable', () {
    final original = _hero();
    final oldJson = original.toJson();
    final selected = SrdClassPreparedSpellRules.confirm(
      original,
      catalog: catalog,
      selectedByClass: _selections,
      preparationChoicesConfirmed: true,
    );
    final record = selected.preparedSpellRecord!;
    expect(record.spellsByClass.keys, containsAll(['Magier', 'Zauberer']));
    expect(record.spellsByClass['Magier'], ['Magisches Geschoss', 'Licht']);
    expect(record.spellsByClass['Zauberer'], ['Magisches Geschoss']);
    expect(original.toJson(), oldJson);
    expect(original.preparedSpellRecord, isNull);
    expect(selected.spells, original.spells);
    expect(
      SrdClassPreparedSpellRules.isPreparedForClass(
        selected,
        catalog: catalog,
        castingClass: 'Wizard',
        spellName: 'Licht',
      ),
      isTrue,
    );
    expect(
      SrdClassPreparedSpellRules.isPreparedForClass(
        selected,
        catalog: catalog,
        castingClass: 'Sorcerer',
        spellName: 'Licht',
      ),
      isFalse,
    );
    expect(
      () => record.spellsByClass['Magier']!.add('Fireball'),
      throwsUnsupportedError,
    );
    expect(
      () => record.spellsByClass['Kleriker'] = ['Fireball'],
      throwsUnsupportedError,
    );
  });

  test('unconfirmed choices never change the existing character', () {
    final hero = _hero();
    final before = hero.toJson();
    expect(
      () => SrdClassPreparedSpellRules.confirm(
        hero,
        catalog: catalog,
        selectedByClass: _selections,
        preparationChoicesConfirmed: false,
      ),
      throwsFormatException,
    );
    expect(hero.toJson(), before);
    expect(hero.preparedSpellRecord, isNull);
    expect(
      SrdClassPreparedSpellRules.isPreparedForClass(
        hero,
        catalog: catalog,
        castingClass: 'Magier',
        spellName: 'Magisches Geschoss',
      ),
      isFalse,
    );
  });

  test('unknown, duplicate and unowned class keys fail closed', () {
    final hero = _hero();
    for (final selections in <Map<String, List<String>>>[
      {'Wizard': ['Magisches Geschoss']},
      {..._selections, 'Cleric': <String>[]},
      {'Wizard': ['Licht'], 'Magier': ['Magisches Geschoss']},
      {'Magier': ['Magisches Geschoss'], 'Unverified': <String>[]},
    ]) {
      expect(
        () => SrdClassPreparedSpellRules.confirm(
          hero,
          catalog: catalog,
          selectedByClass: selections,
          preparationChoicesConfirmed: true,
        ),
        throwsFormatException,
      );
    }
  });

  test('spell-list, class level and alias duplicates are validated', () {
    final hero = _hero();
    for (final names in <List<String>>[
      ['Fireball'],
      ['Magisches Geschoss', 'Magic Missile'],
      ['Magisches Geschoss', 'Magisches Geschoss'],
      ['Zauber ohne SRD'],
    ]) {
      final candidate = hero.copyWith(
        spells: [...hero.spells, 'Magic Missile', 'Zauber ohne SRD'],
      );
      expect(
        () => SrdClassPreparedSpellRules.confirm(
          candidate,
          catalog: catalog,
          selectedByClass: {
            'Magier': names,
            'Zauberer': <String>[],
          },
          preparationChoicesConfirmed: true,
        ),
        throwsFormatException,
      );
    }
    final legal = SrdClassPreparedSpellRules.confirm(
      hero.copyWith(level: 10, secondaryClassLevel: 5),
      catalog: catalog,
      selectedByClass: {
        'Magier': ['Fireball'],
        'Zauberer': <String>[],
      },
      preparationChoicesConfirmed: true,
    );
    expect(legal.preparedSpellRecord!.spellsByClass['Magier'], ['Fireball']);
  });

  test('wrong class list cannot be bypassed by confirmation', () {
    final hero = _hero(
      second: 'Kleriker',
      spells: const ['Wunden heilen', 'Magisches Geschoss'],
    );
    expect(
      () => SrdClassPreparedSpellRules.confirm(
        hero,
        catalog: catalog,
        selectedByClass: {
          'Magier': ['Wunden heilen'],
          'Kleriker': ['Magisches Geschoss'],
        },
        preparationChoicesConfirmed: true,
      ),
      throwsFormatException,
    );
    final selected = SrdClassPreparedSpellRules.confirm(
      hero,
      catalog: catalog,
      selectedByClass: {
        'Magier': ['Magisches Geschoss'],
        'Kleriker': ['Wunden heilen'],
      },
      preparationChoicesConfirmed: true,
    );
    expect(selected.preparedSpellRecord!.spellsByClass.keys, {
      'Magier',
      'Kleriker',
    });
  });

  test('changing source classes, levels or spells clears stale evidence', () {
    final hero = SrdClassPreparedSpellRules.confirm(
      _hero(),
      catalog: catalog,
      selectedByClass: _selections,
      preparationChoicesConfirmed: true,
    );
    expect(hero.copyWith(level: 7).preparedSpellRecord, isNull);
    expect(hero.copyWith(secondaryClassLevel: 2).preparedSpellRecord, isNull);
    expect(hero.copyWith(className: 'Wizard').preparedSpellRecord, isNull);
    expect(
      hero.copyWith(spells: const ['Magisches Geschoss'])
          .preparedSpellRecord,
      isNull,
    );
    expect(hero.copyWith(spentSpellSlots: const {'1': 1})
        .preparedSpellRecord, isNotNull);
    expect(hero.copyWith(preparedSpellRecord: null).preparedSpellRecord, isNull);
  });

  test('versioned JSON roundtrip leaves older spell lists byte-equivalent', () {
    final old = _hero();
    final oldJson = old.toJson();
    expect(oldJson.containsKey('preparedSpellRecord'), isFalse);
    final restoredOld = HeroCharacter.fromJson(oldJson);
    expect(restoredOld.toJson(), oldJson);
    expect(restoredOld.preparedSpellRecord, isNull);
    final recorded = SrdClassPreparedSpellRules.confirm(
      old,
      catalog: catalog,
      selectedByClass: _selections,
      preparationChoicesConfirmed: true,
    );
    final raw = recorded.toJson();
    expect(raw['schemaVersion'], 1);
    final replay = HeroCharacter.fromJson(raw);
    expect(replay.toJson(), raw);
    expect(replay.spells, old.spells);
    expect(replay.preparedSpellRecord!.spellsByClass, {
      'Magier': ['Magisches Geschoss', 'Licht'],
      'Zauberer': ['Magisches Geschoss'],
    });
  });

  test('tampered record versions, sources and maps cannot be imported', () {
    final recorded = SrdClassPreparedSpellRules.confirm(
      _hero(),
      catalog: catalog,
      selectedByClass: _selections,
      preparationChoicesConfirmed: true,
    );
    final valid = recorded.toJson();
    for (final alter in <void Function(Map<String, dynamic>)>[
      (raw) =>
          (raw['preparedSpellRecord'] as Map<String, dynamic>)['schemaVersion'] = 2,
      (raw) =>
          (raw['preparedSpellRecord'] as Map<String, dynamic>)['level'] = 7,
      (raw) =>
          (raw['preparedSpellRecord'] as Map<String, dynamic>)['sourceSpells'] =
              <String>['Fireball'],
      (raw) =>
          (raw['preparedSpellRecord'] as Map<String, dynamic>)['spellsByClass'] =
              <String, dynamic>{'Magier': ['Zauber ohne SRD']},
      (raw) => raw['level'] = 7,
    ]) {
      final tampered = {
        ...valid,
        'preparedSpellRecord': {
          ...(valid['preparedSpellRecord'] as Map<String, dynamic>),
        },
      };
      alter(tampered);
      expect(() => HeroCharacter.fromJson(tampered), throwsFormatException);
    }
  });

  test('SQLite restart, idempotent retry and stale revision keep proof', () async {
    final directory = await Directory.systemTemp.createTemp('prepared-class-');
    final path = '${directory.path}/campaign.sqlite';
    var repository = await SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: path,
    );
    try {
      final original = Campaign(
        id: 'prepared-record-campaign',
        name: 'Klassen-Zauber',
        world: 'Test',
        sessionId: 'session',
        scene: 'Beginn',
        hero: _hero(),
      );
      await repository.saveCampaign(original);
      final confirmed = SrdClassPreparedSpellRules.confirm(
        original.hero,
        catalog: catalog,
        selectedByClass: _selections,
        preparationChoicesConfirmed: true,
      );
      final commit = original.copyWith(hero: confirmed, revision: 1);
      await repository.saveCampaign(commit, expectedRevision: 0);
      await repository.saveCampaign(commit, expectedRevision: 0);
      final stale = original.copyWith(
        hero: original.hero.copyWith(spells: const ['Fireball']),
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
      final loaded = (await repository.getCampaign(original.id))!;
      expect(loaded.revision, 1);
      expect(loaded.hero.toJson(), confirmed.toJson());
      expect(loaded.hero.spells, original.hero.spells);
      expect(
        SrdClassPreparedSpellRules.isPreparedForClass(
          loaded.hero,
          catalog: catalog,
          castingClass: 'Sorcerer',
          spellName: 'Magisches Geschoss',
        ),
        isTrue,
      );
    } finally {
      await repository.close();
      await directory.delete(recursive: true);
    }
  });
}
