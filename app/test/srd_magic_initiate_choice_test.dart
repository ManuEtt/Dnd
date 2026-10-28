import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_background_package.dart';
import 'package:lebendiger_spielleiter/domain/srd_magic_initiate_choice.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_creation_audit.dart';

SrdMagicInitiateChoice choose(SrdBackground background) {
  return SrdMagicInitiateChoice(
    background: background,
    cantrips: SrdMagicInitiateChoice.availableCantrips(
      background,
    ).take(2).toList(),
    levelOneSpell: SrdMagicInitiateChoice.availableLevelOne(background).first,
    castingAbility: 'wisdom',
  );
}

HeroCharacter makeHero(SrdBackground background) {
  return HeroCharacter(
    id: 'feat-${background.name}',
    name: 'Held',
    background: background.label,
    startingBackgroundPackage: SrdBackgroundPackageChoice(
      background: background,
      takeGold: true,
    ),
    startingMagicInitiate: choose(background),
  );
}

void main() {
  test('SRD spell menus precisely match the bundled canonical catalog', () {
    final json = File('assets/srd_5_2_1_spells.json').readAsStringSync();
    final catalog = SrdSpellCatalog.fromJsonString(json);
    for (final pair in [
      (SrdBackground.acolyte, 'Cleric'),
      (SrdBackground.sage, 'Wizard'),
    ]) {
      final cantrips = catalog.spells
          .where((spell) => spell.level == 0 && spell.classes.contains(pair.$2))
          .map((spell) => spell.name)
          .toList();
      final firstLevel = catalog.spells
          .where((spell) => spell.level == 1 && spell.classes.contains(pair.$2))
          .map((spell) => spell.name)
          .toList();
      expect(SrdMagicInitiateChoice.availableCantrips(pair.$1), cantrips);
      expect(SrdMagicInitiateChoice.availableLevelOne(pair.$1), firstLevel);
    }
  });

  test(
    'Acolyte and Sage persist all choices across hero JSON copy and read',
    () {
      for (final background in [SrdBackground.acolyte, SrdBackground.sage]) {
        final hero = makeHero(background);
        final json = hero.toJson();
        expect(json['schemaVersion'], 1);
        final restored = HeroCharacter.fromJson(json);
        expect(restored.toJson(), json);
        expect(
          restored.spells,
          isEmpty,
          reason: 'No untracked or free-slot spellcasting is granted.',
        );
        expect(
          restored.startingMagicInitiate!.sourceList,
          background == SrdBackground.acolyte ? 'Cleric' : 'Wizard',
        );
        expect(
          restored.copyWith(level: 2).startingMagicInitiate!.toJson(),
          hero.startingMagicInitiate!.toJson(),
        );
        final step = SrdCharacterCreationAudit.inspect(
          restored,
        ).singleWhere((item) => item.id == 'origin.magic-initiate-choice');
        expect(step.status, CreationStepStatus.confirmed);
        expect(
          () => restored.startingMagicInitiate!.cantrips[0] = 'Fake',
          throwsUnsupportedError,
        );
      }
    },
  );

  test('missing spell choices explicitly block magic feat audit', () {
    final hero = makeHero(
      SrdBackground.sage,
    ).copyWith(startingMagicInitiate: null);
    final step = SrdCharacterCreationAudit.inspect(
      hero,
    ).singleWhere((item) => item.id == 'origin.magic-initiate-choice');
    expect(step.status, CreationStepStatus.missing);
    expect(step.detail, contains('Zauberattribut'));
  });

  test(
    'wrong background, unsupported class and invalid spells fail closed',
    () {
      final good = choose(SrdBackground.acolyte).toJson();
      for (final changed in <Map<String, dynamic>>[
        {...good, 'version': 2},
        {...good, 'version': 1.0},
        {...good, 'background': 'soldier'},
        {
          ...good,
          'cantrips': ['Guidance', 'Guidance'],
        },
        {
          ...good,
          'cantrips': ['Guidance'],
        },
        {
          ...good,
          'cantrips': ['Guidance', 'Fire Bolt'],
        },
        {...good, 'levelOneSpell': 'Magic Missile'},
        {...good, 'castingAbility': 'strength'},
        {
          ...good,
          'cantrips': [14, 'Guidance'],
        },
      ]) {
        expect(
          () => SrdMagicInitiateChoice.fromJson(changed),
          throwsFormatException,
          reason: changed.toString(),
        );
      }
      final hero = makeHero(SrdBackground.sage);
      final wrong = hero.toJson();
      wrong['background'] = 'Akolyth';
      expect(() => HeroCharacter.fromJson(wrong), throwsFormatException);
      final absent = hero.toJson();
      absent.remove('startingBackgroundPackage');
      expect(() => HeroCharacter.fromJson(absent), throwsFormatException);
      final forged = hero.toJson();
      forged['startingMagicInitiate'] = choose(SrdBackground.acolyte).toJson();
      expect(() => HeroCharacter.fromJson(forged), throwsFormatException);
    },
  );

  test('old saves with no feat record retain identical JSON', () {
    final original = HeroCharacter(id: 'old', name: 'Legacy');
    final json = original.toJson();
    expect(json.containsKey('startingMagicInitiate'), false);
    expect(HeroCharacter.fromJson(json).toJson(), json);
  });
}
