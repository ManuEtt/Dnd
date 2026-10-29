import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/ability_generation.dart';
import 'package:lebendiger_spielleiter/domain/character_rule_engine.dart';
import 'package:lebendiger_spielleiter/domain/fighter_creation_rules.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_equipment_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_background_package.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_classes.dart';
import 'package:lebendiger_spielleiter/domain/srd_character_creation_audit.dart';
import 'package:lebendiger_spielleiter/domain/starting_class_choice.dart';
import 'package:lebendiger_spielleiter/domain/starting_equipment_import.dart';
import 'package:lebendiger_spielleiter/domain/tool_proficiency_rules.dart';

StartingClassChoice _choice(String tool, {int? kit = 0}) =>
    StartingClassChoice.confirmed(
      className: 'Mönch',
      skills: const ['Akrobatik', 'Athletik'],
      kitIndex: kit,
      toolProficiencyCatalogId: tool,
      equipmentChoices: {
        if (kit == 0) StartingEquipmentImport.monkToolLabel: tool,
      },
    );

HeroCharacter _hero(StartingClassChoice choice) {
  final kit = choice.selection.startingKit;
  var sequence = 0;
  return choice.selection
      .applyTo(
        HeroCharacter(
          id: 'monk',
          name: 'Liora',
          abilities: {for (final id in abilityNames) id: 14},
        ),
      )
      .copyWith(
        startingClassChoice: choice,
        gold: kit?.gold,
        inventory: [
          if (kit != null)
            for (final item in kit.items)
              StartingEquipmentImport.fromSelectedStartingItem(
                item,
                'item-${sequence++}',
                selectedCatalogId: choice.equipmentChoices[item.name],
                choiceVersion: choice.version,
              ),
        ],
      );
}

CreationStepStatus _status(HeroCharacter hero, String id) =>
    SrdCharacterCreationAudit.inspect(
      hero,
    ).singleWhere((s) => s.id == id).status;

void main() {
  for (final entry in StartingEquipmentImport.monkTools) {
    test(
      '${entry.name}: gleiche Übung/typisierte Ausrüstung und Goldalternative',
      () {
        for (final kit in [0, 1]) {
          final proof = _choice(entry.id, kit: kit);
          final hero = _hero(proof);
          final before = jsonEncode(hero.toJson());
          expect(proof.version, 3);
          expect(ToolProficiencyRules.catalogIds(hero), {entry.id});
          expect(_status(hero, 'class.tools'), CreationStepStatus.confirmed);
          expect(
            _status(hero, 'class.equipment'),
            CreationStepStatus.confirmed,
          );
          expect(hero.gold, kit == 0 ? 11 : 50);
          final chosen = hero.inventory.where((i) => i.catalogId == entry.id);
          expect(chosen, hasLength(kit == 0 ? 1 : 0));
          if (kit == 0) {
            expect(
              chosen.single.stats!.toJson(),
              InventoryItemStats.fromCatalog(entry).toJson(),
            );
            expect(chosen.single.quantity, 1);
          }
          expect(
            HeroCharacter.fromJson(jsonDecode(before)).toJson(),
            hero.toJson(),
          );
          expect(
            CharacterRuleEngine.toolCheck(
              hero,
              'dexterity',
              toolCatalogId: entry.id,
            ).modifier,
            4,
          );
          expect(jsonEncode(hero.toJson()), before);
        }
      },
    );
  }

  test(
    'Fehlende, fremde und widersprüchliche Quellen scheitern vor Übernahme',
    () {
      for (final kit in <int?>[null, 0, 1]) {
        for (final tool in <String?>[
          null,
          '',
          'item-thieves-tools',
          'item-herbalism-kit',
          'item-navigator-s-tools',
          'item-no-such-tool',
          'weapon-dagger',
        ]) {
          expect(
            () => StartingClassChoice.confirmed(
              className: 'Mönch',
              skills: const ['Akrobatik', 'Athletik'],
              kitIndex: kit,
              toolProficiencyCatalogId: tool,
              equipmentChoices: {
                if (kit == 0)
                  StartingEquipmentImport.monkToolLabel: 'item-lute',
              },
            ),
            throwsFormatException,
          );
        }
      }
      expect(
        () => StartingClassChoice.confirmed(
          className: 'Mönch',
          skills: const ['Akrobatik', 'Athletik'],
          kitIndex: 0,
          toolProficiencyCatalogId: 'item-lute',
          equipmentChoices: {
            StartingEquipmentImport.monkToolLabel: 'item-flute',
          },
        ),
        throwsFormatException,
      );
      expect(
        () => StartingClassChoice.confirmed(
          className: 'Barbar',
          skills: const ['Athletik', 'Wahrnehmung'],
          toolProficiencyCatalogId: 'item-lute',
        ),
        throwsFormatException,
      );
      expect(
        () => StartingClassChoice.fromJson({
          ..._choice('item-lute').toJson(),
          'toolProficiencyCatalogId': true,
        }),
        throwsFormatException,
      );
      expect(
        () => StartingClassChoice.fromJson({
          ..._choice('item-lute').toJson(),
          'version': 4,
        }),
        throwsFormatException,
      );
    },
  );

  for (final version in [1, 2]) {
    for (final klass in srdCharacterClasses) {
      test(
        'v$version ${klass.name}: jedes ursprüngliche Paket bleibt lesbar und unverändert',
        () {
          for (var kitIndex = 0; kitIndex < klass.kits.length; kitIndex++) {
            final kit = klass.kits[kitIndex];
            final raw = <String, dynamic>{
              'version': version,
              'className': klass.name,
              'skills': klass.skillChoices.take(klass.skillCount).toList(),
              'kitIndex': kitIndex,
              'equipmentChoices': {
                for (final item in kit.items)
                  if (StartingEquipmentImport.optionsFor(
                    item,
                    choiceVersion: version,
                  ).isNotEmpty)
                    item.name: StartingEquipmentImport.optionsFor(
                      item,
                      choiceVersion: version,
                    ).first.id,
              },
              if (klass.name == 'Kämpfer')
                'fighterChoices': {
                  'styleId': 'defense',
                  'masteryWeaponIds': FighterCreationRules.masteryWeapons
                      .take(3)
                      .map((e) => e.id)
                      .toList(),
                },
            };
            final proof = StartingClassChoice.fromJson(raw);
            expect(proof.toJson(), raw);
            final hero = _hero(proof);
            expect(ToolProficiencyRules.catalogIds(hero), isEmpty);
            if (klass.name == 'Mönch') {
              expect(
                _status(hero, 'class.tools'),
                CreationStepStatus.notAutomated,
              );
              expect(
                _status(hero, 'class.equipment'),
                kitIndex == 0
                    ? CreationStepStatus.notAutomated
                    : CreationStepStatus.confirmed,
              );
              final updated = proof.withUpdatedClassDecisions(
                _choice('item-lute', kit: null),
              );
              expect(updated.version, version);
              expect(updated.toolProficiencyCatalogId, isNull);
              expect(updated.equipmentChoices, proof.equipmentChoices);
              expect(
                () => StartingClassChoice.fromJson({
                  ...raw,
                  'toolProficiencyCatalogId': 'item-lute',
                }),
                throwsFormatException,
              );
            }
          }
        },
      );
    }
  }

  test(
    'Wiederwahl sperrt übernommenes A-Werkzeug; Goldwahl bleibt ohne zweite Gaben bearbeitbar',
    () {
      final a = _choice('item-lute');
      expect(
        a.withUpdatedClassDecisions(_choice('item-lute', kit: null)).toJson(),
        a.toJson(),
      );
      expect(
        () => a.withUpdatedClassDecisions(_choice('item-flute', kit: null)),
        throwsFormatException,
      );
      final b = _choice('item-lute', kit: 1);
      final changed = b.withUpdatedClassDecisions(
        _choice('item-flute', kit: null),
      );
      expect(changed.kitIndex, 1);
      expect(changed.toolProficiencyCatalogId, 'item-flute');
      expect(changed.equipmentChoices, isEmpty);
      expect(_hero(changed).gold, 50);
      expect(_hero(changed).inventory, isEmpty);
    },
  );

  test(
    'Übungsbonus einmal, keine Übung aus Inventar/Freitext oder neuer Zweitklasse',
    () {
      final gold = _hero(_choice('item-lute', kit: 1));
      expect(gold.inventory, isEmpty);
      expect(
        CharacterRuleEngine.toolCheck(
          gold,
          'charisma',
          toolCatalogId: 'item-lute',
        ).modifier,
        4,
      );
      final later = gold.copyWith(
        level: 5,
        secondaryClassName: 'Kämpfer',
        secondaryClassLevel: 4,
      );
      expect(
        CharacterRuleEngine.toolCheck(
          later,
          'charisma',
          toolCatalogId: 'item-lute',
        ).modifier,
        5,
      );
      final other = gold.copyWith(
        className: 'Kämpfer',
        secondaryClassName: 'Mönch',
        secondaryClassLevel: 1,
        level: 2,
      );
      expect(ToolProficiencyRules.catalogIds(other), {'item-lute'});
      final newSecondMonk = other.copyWith(
        startingClassChoice: StartingClassChoice.confirmed(
          className: 'Barbar',
          skills: const ['Athletik', 'Wahrnehmung'],
        ),
      );
      expect(ToolProficiencyRules.catalogIds(newSecondMonk), isEmpty);
      final text = gold.copyWith(
        startingClassChoice: null,
        features: ['Werkzeugübung: Laute'],
      );
      expect(ToolProficiencyRules.catalogIds(text), isEmpty);
      expect(
        () => CharacterRuleEngine.toolCheck(
          text,
          'charisma',
          toolCatalogId: 'item-lute',
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'Typisierte Hintergrundquelle und doppelte Werkzeugübung zählen nur einmal',
    () {
      final hero = _hero(_choice('item-calligrapher-s-supplies', kit: 1))
          .copyWith(
            background: 'Weiser',
            startingBackgroundPackage: SrdBackgroundPackageChoice(
              background: SrdBackground.sage,
              takeGold: true,
            ),
            level: 5,
            features: [
              'Werkzeugübung: Kalligrafenwerkzeug',
              'Werkzeugübung: Kalligrafenwerkzeug',
            ],
          );
      expect(ToolProficiencyRules.catalogIds(hero), {
        'item-calligrapher-s-supplies',
      });
      expect(
        CharacterRuleEngine.toolCheck(
          hero,
          'intelligence',
          toolCatalogId: 'item-calligrapher-s-supplies',
        ).modifier,
        5,
      );
      for (final background in SrdBackground.values) {
        final choice = SrdBackgroundPackageChoice(
          background: background,
          takeGold: true,
          gamingSetCatalogId: background == SrdBackground.soldier
              ? SrdBackgroundPackageChoice.gamingSets.first.id
              : '',
        );
        final h = HeroCharacter(
          id: 'bg',
          name: 'Quelle',
          background: background.label,
          startingBackgroundPackage: choice,
        );
        expect(ToolProficiencyRules.entries(h), hasLength(1));
        expect(
          ToolProficiencyRules.entries(h.copyWith(background: 'Fremd')),
          hasLength(1),
        );
      }
    },
  );

  test(
    'Bekannte relevante Fertigkeit gibt Vorteil, niemals zweiten Bonus; Bedingungen bleiben',
    () {
      final hero = _hero(
        _choice('item-lute', kit: 1),
      ).copyWith(skills: ['Auftreten']);
      final rule = CharacterRuleEngine.toolCheck(
        hero,
        'charisma',
        toolCatalogId: 'item-lute',
        relevantSkill: 'Auftreten',
      );
      expect(rule.modifier, 4);
      expect(rule.advantage, isTrue);
      expect(
        CharacterRuleEngine.toolCheck(
          hero,
          'charisma',
          toolCatalogId: 'item-lute',
          relevantSkill: 'Religion',
        ).advantage,
        isFalse,
      );
      final poisoned = CharacterRuleEngine.toolCheck(
        hero.copyWith(conditions: ['vergiftet'], exhaustionLevel: 1),
        'charisma',
        toolCatalogId: 'item-lute',
        relevantSkill: 'Auftreten',
      );
      expect(poisoned.modifier, 2);
      expect(poisoned.advantage, isTrue);
      expect(poisoned.disadvantage, isTrue);
      expect(poisoned.normalRoll, isTrue);
      expect(
        () => CharacterRuleEngine.toolCheck(
          hero.copyWith(skills: ['Erfundene Kunst']),
          'charisma',
          toolCatalogId: 'item-lute',
          relevantSkill: 'Erfundene Kunst',
        ),
        throwsFormatException,
      );
      final legacy = hero.copyWith(skills: ['Medizin']);
      expect(
        CharacterRuleEngine.toolCheck(
          legacy,
          'wisdom',
          toolCatalogId: 'item-lute',
          relevantSkill: 'Heilkunde',
        ).advantage,
        isTrue,
      );
      expect(
        () => CharacterRuleEngine.toolCheck(
          hero.copyWith(abilities: {...hero.abilities, 'wisdom': null}),
          'wisdom',
          toolCatalogId: 'item-lute',
        ),
        throwsStateError,
      );
    },
  );

  test(
    'Verlässliches Talent gilt auch für reine bestätigte Werkzeugprobe ab Schurke7',
    () {
      final hero = _hero(_choice('item-lute', kit: 1)).copyWith(
        level: 8,
        secondaryClassName: 'Schurke',
        secondaryClassLevel: 7,
      );
      expect(
        CharacterRuleEngine.toolCheck(
          hero,
          'charisma',
          toolCatalogId: 'item-lute',
        ).minimumNatural,
        10,
      );
      expect(
        CharacterRuleEngine.toolCheck(
          hero.copyWith(level: 7, secondaryClassLevel: 6),
          'charisma',
          toolCatalogId: 'item-lute',
        ).minimumNatural,
        0,
      );
      expect(
        CharacterRuleEngine.abilityCheck(
          hero,
          'charisma',
          proficient: true,
        ).minimumNatural,
        0,
      );
    },
  );
  test(
    'Bestätigte Geschicklichkeit-Heimlichkeit berücksichtigt laute trainierte Rüstung',
    () {
      final armor = SrdEquipmentCatalog.byId('armor-scale-mail')!;
      final hero = _hero(_choice('item-lute', kit: 1)).copyWith(
        skills: const ['Heimlichkeit'],
        equippedArmorId: 'scale',
        equippedArmorTrained: true,
        inventory: [
          InventoryItem(
            id: 'scale',
            name: armor.name,
            catalogId: armor.id,
            stats: InventoryItemStats.fromCatalog(armor),
          ),
        ],
      );
      final dex = CharacterRuleEngine.toolCheck(
        hero,
        'dexterity',
        toolCatalogId: 'item-lute',
        relevantSkill: 'Heimlichkeit',
      );
      expect(dex.modifier, 4);
      expect(dex.advantage, isTrue);
      expect(dex.disadvantage, isTrue);
      expect(dex.normalRoll, isTrue);
      // Armor's published penalty specifies Dexterity (Stealth), not any
      // alternative ability the GM may explicitly call for.
      final alternative = CharacterRuleEngine.toolCheck(
        hero,
        'charisma',
        toolCatalogId: 'item-lute',
        relevantSkill: 'Heimlichkeit',
      );
      expect(alternative.advantage, isTrue);
      expect(alternative.disadvantage, isFalse);
    },
  );
}
