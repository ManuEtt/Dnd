import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/campaign_repository.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_metamagic_choice_record.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _two = <String>['Distant Spell', 'Subtle Spell'];
const _four = <String>[
  'Distant Spell',
  'Subtle Spell',
  'Quickened Spell',
  'Careful Spell',
];
const _six = <String>[
  'Distant Spell',
  'Subtle Spell',
  'Quickened Spell',
  'Careful Spell',
  'Twinned Spell',
  'Extended Spell',
];

HeroCharacter _hero({
  String primary = 'Zauberer',
  int level = 2,
  String secondary = '',
  int secondaryLevel = 0,
  int hp = 18,
  Map<String, int> spent = const {},
}) => HeroCharacter(
  id: 'metamagic-hero',
  name: 'Yara',
  className: primary,
  secondaryClassName: secondary,
  secondaryClassLevel: secondaryLevel,
  level: level,
  hitPoints: hp,
  maxHitPoints: 22,
  spentClassResources: spent,
);

SrdMetamagicChoiceRecord _confirm(
  HeroCharacter hero,
  List<String> options, {
  bool confirmed = true,
}) => SrdMetamagicChoiceRules.confirm(
  hero: hero,
  selectedOptions: options,
  playerChoiceConfirmed: confirmed,
);

SrdMetamagicChoiceRecord _advance(
  HeroCharacter before,
  HeroCharacter after,
  SrdMetamagicChoiceRecord previous,
  List<String> choices, {
  bool levelConfirmed = true,
  bool playerConfirmed = true,
}) => SrdMetamagicChoiceRules.advanceSorcererLevel(
  before: before,
  after: after,
  previous: previous,
  selectedOptions: choices,
  levelGainConfirmed: levelConfirmed,
  playerChoiceConfirmed: playerConfirmed,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(sqfliteFfiInit);

  test('SRD Metamagic knows 2 / 4 / 6 choices only at Sorcerer levels', () {
    expect(SrdMetamagicChoiceRules.maximumChoices(1), 0);
    expect(SrdMetamagicChoiceRules.maximumChoices(2), 2);
    expect(SrdMetamagicChoiceRules.maximumChoices(9), 2);
    expect(SrdMetamagicChoiceRules.maximumChoices(10), 4);
    expect(SrdMetamagicChoiceRules.maximumChoices(16), 4);
    expect(SrdMetamagicChoiceRules.maximumChoices(17), 6);
    expect(SrdMetamagicChoiceRules.maximumChoices(20), 6);
    expect(SrdMetamagicChoiceRules.maximumChoices(21), 0);
    expect(SrdMetamagicChoiceRules.officialOptions.length, 10);
    expect(_confirm(_hero(level: 2), _two).options, _two);
    expect(_confirm(_hero(level: 10), _four).options, _four);
    expect(_confirm(_hero(level: 17), _six).options, _six);
  });

  test('explicit selection cannot be synthesized from features or class', () {
    final hero = _hero().copyWith(
      features: const ['Metamagic', 'Distant Spell', 'Subtle Spell'],
    );
    final source = hero.toJson();
    expect(() => _confirm(hero, _two, confirmed: false), throwsFormatException);
    expect(() => _confirm(hero, const []), throwsFormatException);
    expect(hero.toJson(), source);
  });

  test('unknown options, duplicate options and wrong counts fail closed', () {
    final hero = _hero();
    for (final options in <List<String>>[
      ['Distant Spell', 'Distant Spell'],
      ['Distant Spell', 'Random Metamagic'],
      ['Distant Spell'],
      ['Distant Spell', 'Subtle Spell', 'Quickened Spell'],
      ['distant spell', 'Subtle Spell'],
      [' Distant Spell', 'Subtle Spell'],
    ]) {
      expect(() => _confirm(hero, options), throwsFormatException);
    }
    expect(hero.spentClassResources, isEmpty);
  });

  test(
    'Sorcerer can be primary or secondary but never inferred from total',
    () {
      final second = _hero(
        primary: 'Kleriker',
        secondary: 'Sorcerer',
        secondaryLevel: 2,
        level: 8,
      );
      final record = _confirm(second, _two);
      expect(record.primaryClassLabel, 'Kleriker');
      expect(record.secondaryClassLabel, 'Sorcerer');
      expect(record.sorcererClassLevel, 2);
      expect(record.matchesHero(second), isTrue);
      expect(record.matchesHero(second.copyWith(level: 9)), isTrue);
      expect(
        record.matchesHero(second.copyWith(secondaryClassLevel: 3, level: 9)),
        isFalse,
      );
      expect(
        _confirm(
          _hero(primary: 'Sorcerer'),
          _two,
        ).containsOption('Distant Spell'),
        isTrue,
      );
      for (final hero in [
        _hero(primary: 'Kleriker', level: 12),
        _hero(level: 1),
        _hero(primary: 'Unknown', level: 5),
        _hero(
          primary: 'Zauberer',
          secondary: 'Sorcerer',
          level: 6,
          secondaryLevel: 2,
        ),
        _hero(
          primary: 'Zauberer',
          secondary: 'Unknown',
          level: 6,
          secondaryLevel: 2,
        ),
        _hero(
          primary: 'Zauberer',
          secondary: 'Kleriker',
          level: 4,
          secondaryLevel: 4,
        ),
        _hero(level: 21),
      ]) {
        expect(() => _confirm(hero, _two), throwsFormatException);
      }
    },
  );

  test('record is immutable and exact versioned JSON round-trip', () {
    final choices = <String>['Distant Spell', 'Subtle Spell'];
    final hero = _hero();
    final record = _confirm(hero, choices);
    choices[0] = 'Careful Spell';
    expect(record.options, _two);
    expect(() => record.options.add('Careful Spell'), throwsUnsupportedError);
    final json = record.toJson();
    final restored = SrdMetamagicChoiceRecord.fromJson(json);
    expect(restored.toJson(), json);
    expect(restored.options, _two);
    json['options'] = ['Careful Spell', 'Subtle Spell'];
    expect(restored.options, _two);
    expect(restored.matchesHero(hero), isTrue);
    expect(
      restored.matchesHero(
        hero.copyWith(
          hitPoints: 17,
          spentClassResources: const {'sorceryPoints': 1},
        ),
      ),
      isTrue,
    );
    expect(restored.matchesHero(hero.copyWith(level: 3)), isFalse);
  });

  test('malformed or tampered JSON is rejected, including unknown fields', () {
    final good = _confirm(_hero(), _two).toJson();
    final altered = <Map<String, dynamic>>[
      {...good, 'schemaVersion': 2},
      {...good, 'schemaVersion': '1'},
      {...good, 'schemaVersion': 1.0},
      {...good, 'sorcererClassLevel': 1},
      {...good, 'sorcererClassLevel': 21},
      {...good, 'sorcererClassLevel': '2'},
      {...good, 'primaryClassLabel': 'Wizard'},
      {...good, 'primaryClassLabel': 'Unknown'},
      {...good, 'primaryClassLabel': 'Kleriker'},
      {...good, 'secondaryClassLabel': 'Sorcerer'},
      {
        ...good,
        'options': ['Distant Spell', 'Distant Spell'],
      },
      {
        ...good,
        'options': ['Distant Spell', 'Unconfirmed'],
      },
      {
        ...good,
        'options': ['Distant Spell'],
      },
      {
        ...good,
        'options': [3, 'Subtle Spell'],
      },
      {...good, 'options': 'Distant Spell'},
      {...good, 'extra': true},
      {...good}..remove('options'),
    ];
    for (final json in altered) {
      expect(
        () => SrdMetamagicChoiceRecord.fromJson(json),
        throwsFormatException,
        reason: json.toString(),
      );
    }
    expect(_confirm(_hero(), _two).toJson(), good);
  });

  test('level 3 gains no slots and allows at most one replacement', () {
    final before = _hero();
    final previous = _confirm(before, _two);
    final after = before.copyWith(level: 3);
    final unchanged = _advance(before, after, previous, _two);
    expect(unchanged.options, _two);
    final replaced = _advance(before, after, previous, const [
      'Careful Spell',
      'Subtle Spell',
    ]);
    expect(replaced.options, ['Careful Spell', 'Subtle Spell']);
    expect(
      () => _advance(before, after, previous, const [
        'Careful Spell',
        'Quickened Spell',
      ]),
      throwsFormatException,
    );
    expect(previous.options, _two);
  });

  test('level 10 adds two options and optionally replaces exactly one', () {
    final before = _hero(level: 9);
    final previous = _confirm(before, _two);
    final after = before.copyWith(level: 10);
    expect(_advance(before, after, previous, _four).options, _four);
    final changed = _advance(before, after, previous, const [
      'Careful Spell',
      'Subtle Spell',
      'Quickened Spell',
      'Heightened Spell',
    ]);
    expect(changed.options.length, 4);
    expect(changed.containsOption('Distant Spell'), isFalse);
    expect(
      () => _advance(before, after, previous, const [
        'Careful Spell',
        'Extended Spell',
        'Quickened Spell',
        'Heightened Spell',
      ]),
      throwsFormatException,
    );
  });

  test('level 17 adds two, other-class level-ups cannot grant options', () {
    final before = _hero(level: 16);
    final previous = _confirm(before, _four);
    final after = before.copyWith(level: 17);
    expect(_advance(before, after, previous, _six).options, _six);
    final multiclass = _hero(
      primary: 'Kleriker',
      secondary: 'Sorcerer',
      level: 11,
      secondaryLevel: 9,
    );
    final record = _confirm(multiclass, _two);
    final anotherClassLevel = multiclass.copyWith(level: 12);
    expect(record.matchesHero(anotherClassLevel), isTrue);
    expect(
      () => _advance(multiclass, anotherClassLevel, record, _two),
      throwsFormatException,
    );
    final sorcererLevel = multiclass.copyWith(
      level: 12,
      secondaryClassLevel: 10,
    );
    expect(_advance(multiclass, sorcererLevel, record, _four).options, _four);
  });

  test(
    'unconfirmed, wrong-source, stale and skipped level-ups are rejected',
    () {
      final before = _hero();
      final record = _confirm(before, _two);
      final after = before.copyWith(level: 3);
      final cases = [
        () => _advance(before, after, record, _two, levelConfirmed: false),
        () => _advance(before, after, record, _two, playerConfirmed: false),
        () => _advance(before, before, record, _two),
        () => _advance(before, before.copyWith(level: 4), record, _two),
        () => _advance(before.copyWith(level: 3), after, record, _two),
        () =>
            _advance(before, after.copyWith(className: 'Wizard'), record, _two),
        () => _advance(
          before,
          after.copyWith(
            secondaryClassName: 'Kleriker',
            secondaryClassLevel: 1,
          ),
          record,
          _two,
        ),
      ];
      for (final invalid in cases) {
        expect(invalid, throwsFormatException);
      }
    },
  );

  test(
    'old Hero JSON remains unchanged and record is an external artifact',
    () {
      final hero = _hero();
      final source = hero.toJson();
      expect(source.containsKey('metamagicChoiceRecord'), isFalse);
      expect(HeroCharacter.fromJson(source).toJson(), source);
      final proof = _confirm(hero, _two);
      expect(proof.matchesHero(HeroCharacter.fromJson(source)), isTrue);
      expect(hero.toJson(), source);
      expect(source.containsKey('metamagicChoiceRecord'), isFalse);
    },
  );

  test(
    'SQLite restart and revisions preserve hero; choices remain external',
    () async {
      final folder = await Directory.systemTemp.createTemp('metamagic-choice-');
      final path = '${folder.path}/campaign.sqlite';
      var repo = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      try {
        final original = Campaign(
          id: 'metamagic-provenance',
          name: 'Metamagie-Auswahl',
          world: 'Testwelt',
          sessionId: 'session',
          scene: 'Anfang',
          hero: _hero(),
        );
        await repo.saveCampaign(original);
        final choiceJson = _confirm(original.hero, _two).toJson();
        await repo.close();
        repo = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        final restored = (await repo.getCampaign(original.id))!;
        final proof = SrdMetamagicChoiceRecord.fromJson(choiceJson);
        expect(proof.matchesHero(restored.hero), isTrue);
        expect(restored.hero.spentClassResources, isEmpty);
        expect(
          restored.hero.toJson().containsKey('metamagicChoiceRecord'),
          isFalse,
        );
        final accepted = restored.copyWith(
          revision: 1,
          hero: restored.hero.copyWith(hitPoints: 17),
        );
        await repo.saveCampaign(accepted, expectedRevision: 0);
        await repo.saveCampaign(accepted, expectedRevision: 0);
        await expectLater(
          repo.saveCampaign(
            restored.copyWith(
              revision: 1,
              hero: restored.hero.copyWith(hitPoints: 16),
            ),
            expectedRevision: 0,
          ),
          throwsA(isA<CampaignConflictException>()),
        );
        await repo.close();
        repo = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        final after = (await repo.getCampaign(original.id))!;
        expect(after.revision, 1);
        expect(after.hero.hitPoints, 17);
        expect(proof.matchesHero(after.hero), isTrue);
        expect(proof.matchesHero(after.hero.copyWith(level: 3)), isFalse);
        expect(after.hero.spentClassResources, isEmpty);
      } finally {
        await repo.close();
        await folder.delete(recursive: true);
      }
    },
  );
}
