import 'dart:convert';

import 'ability_generation.dart';
import 'models.dart';
import 'srd_character_classes.dart';
import 'srd_skill_ability_catalog.dart';
import 'starting_equipment_import.dart';

/// Read-only assessment of recorded choices, not authority to grant benefits.
/// SRD 5.2.1 Character Creation p. 21, Backgrounds p. 83, Species pp. 84–86.
/// Historical or free-text data never acquires an invented source of truth.
enum CreationStepStatus {
  confirmed,
  missing,
  invalid,
  dependent,
  notAutomated,
  houseRule,
  notInSrd,
}

class CreationStep {
  const CreationStep(this.id, this.title, this.status, this.detail);
  final String id, title, detail;
  final CreationStepStatus status;
}

class SrdCharacterCreationAudit {
  const SrdCharacterCreationAudit._();

  // Names identify only the licensed family/lineage, never its full traits.
  // Actual size, ancestry, cantrip and feat decisions still need typed records.
  static const _species = {
    'drachenblütiger',
    'drachenblütige',
    'drachenblut',
    'dragonborn',
    'zwerg',
    'dwarf',
    'elf',
    'elfe',
    'elfin',
    'elfer',
    'drow',
    'hochelf',
    'high elf',
    'waldelf',
    'waldelfe',
    'wood elf',
    'gnom',
    'gnome',
    'waldgnom',
    'forest gnome',
    'felsengnom',
    'rock gnome',
    'goliath',
    'halbling',
    'halfling',
    'mensch',
    'human',
    'ork',
    'orc',
    'tiefling',
  };

  static String _normalized(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static String _skill(String value) {
    final normalized = _normalized(value);
    for (final alias in srdLegacySkillAliases.entries) {
      if (_normalized(alias.value) == normalized) return _normalized(alias.key);
    }
    return normalized;
  }

  static bool _duplicates(Iterable<String> values) {
    final names = values.toList();
    return names.toSet().length != names.length;
  }

  static List<CreationStep> inspect(
    HeroCharacter hero, {
    bool manualAbilityHouseRule = false,
  }) {
    final definition = findSrdClass(hero.className);
    final origin = hero.startingAbilityOrigin;
    final classChoice = hero.startingClassChoice;
    final classChoiceMatches =
        classChoice != null && classChoice.className == definition?.name;
    final package = hero.startingBackgroundPackage;
    final backgroundName = _normalized(hero.background);
    final backgrounds = SrdBackground.values.where(
      (entry) =>
          _normalized(entry.label) == backgroundName ||
          entry.name == backgroundName,
    );
    final backgroundDefinition = backgrounds.isEmpty
        ? null
        : backgrounds.single;
    final atStart = hero.level == 1;
    final scores = abilityNames.map((key) => hero.abilities[key]).toList();
    final invalidScores =
        hero.abilities.keys.any((key) => !abilityNames.contains(key)) ||
        scores.any((value) => value != null && (value < 1 || value > 30));
    final allScores = scores.every((value) => value != null);
    final matchesOrigin =
        origin != null &&
        abilityNames.every(
          (key) => hero.abilities[key] == origin.startingScores[key],
        );
    final skills = hero.skills.map(_skill).toList();
    final saves = hero.savingThrowProficiencies.map(_normalized).toList();

    CreationStep choice(
      String id,
      String title,
      CreationStepStatus status,
      String detail,
    ) => CreationStep(id, title, status, detail);

    CreationStep species() {
      if (hero.species.trim().isEmpty) {
        return choice(
          'origin.species',
          'Spezies und Merkmale',
          CreationStepStatus.missing,
          'Spezies ausdrücklich wählen. Ein Name allein bestätigt noch keine Merkmale.',
        );
      }
      return _species.contains(_normalized(hero.species))
          ? choice(
              'origin.species',
              'Spezies und Merkmale',
              CreationStepStatus.notAutomated,
              'SRD-Spezies benannt; Größe, Herkunftswahlen und sämtliche Startmerkmale sind noch nicht strukturiert nachgewiesen.',
            )
          : choice(
              'origin.species',
              'Spezies und Merkmale',
              CreationStepStatus.notInSrd,
              'Diese Bezeichnung ist keiner unterstützten SRD-5.2.1-Spezies zugeordnet. Vorhandene Angaben bleiben erhalten.',
            );
    }

    CreationStep background() {
      const id = 'origin.background';
      const title = 'Hintergrundwahl und Attributserhöhungen';
      final name = hero.background.trim();
      if (name.isEmpty) {
        return choice(
          id,
          title,
          CreationStepStatus.missing,
          'Hintergrund wählen.',
        );
      }
      if (backgroundDefinition == null) {
        return choice(
          id,
          title,
          CreationStepStatus.notInSrd,
          'Keiner der vier SRD-Hintergründe. Eine freie Angabe ist kein offizieller Herkunftsnachweis.',
        );
      }
      if (!atStart) {
        return choice(
          id,
          title,
          CreationStepStatus.notAutomated,
          'Historische Herkunft und spätere Änderungen bleiben getrennt. Der Audit rekonstruiert keine ursprünglichen Entscheidungen aus heutigen Werten.',
        );
      }
      if ((origin != null && origin.background != backgroundDefinition.label) ||
          (package != null && package.background != backgroundDefinition)) {
        return choice(
          id,
          title,
          CreationStepStatus.invalid,
          'Der aktuelle Hintergrund widerspricht dem gespeicherten Attribut- oder Paketnachweis. Entscheidung erneut prüfen.',
        );
      }
      if (origin == null || package == null || !allScores) {
        return choice(
          id,
          title,
          CreationStepStatus.dependent,
          'Attributsverteilung und Hintergrundpaket ausdrücklich bestätigen; der Name allein belegt keine Wahl.',
        );
      }
      if (invalidScores || (!manualAbilityHouseRule && !matchesOrigin)) {
        return choice(
          id,
          title,
          CreationStepStatus.invalid,
          'Die aktuellen Attribute stimmen nicht mit den bestätigten Anfangswerten überein.',
        );
      }
      if (manualAbilityHouseRule) {
        return choice(
          id,
          title,
          CreationStepStatus.houseRule,
          'Manuelle Attribute sind ausdrücklich als Hausregel gewählt; die ursprünglichen Hintergrundboni legitimieren sie nicht als SRD-Erzeugung.',
        );
      }
      if (!package.skills.every((skill) => skills.contains(_skill(skill)))) {
        return choice(
          id,
          title,
          CreationStepStatus.invalid,
          'Die im Hintergrundpaket bestätigten Fertigkeiten fehlen in den aktuellen Übungen.',
        );
      }
      if (_duplicates(skills)) {
        return choice(
          id,
          title,
          CreationStepStatus.invalid,
          'Doppelte Fertigkeitsübungen müssen bereinigt werden; es wird keine Ersatzwahl erfunden.',
        );
      }
      return choice(
        id,
        title,
        CreationStepStatus.confirmed,
        'Hintergrundwahl, Anfangswerte und Paketfertigkeiten sind belegt. Das bestätigt noch nicht sämtliche Talentwirkungen oder Klassenstartentscheidungen.',
      );
    }

    CreationStep abilities() {
      const id = 'abilities.scores';
      const title = 'Attributsmethode und Anfangswerte';
      if (invalidScores) {
        return choice(
          id,
          title,
          CreationStepStatus.invalid,
          'Sechs bekannte Attribut-IDs und Werte von 1 bis 30 erforderlich; die Erzeugungsmethode wird zusätzlich geprüft.',
        );
      }
      if (!allScores) {
        return choice(
          id,
          title,
          CreationStepStatus.missing,
          'Die sechs Attribute sind noch nicht vollständig eingetragen.',
        );
      }
      if (manualAbilityHouseRule) {
        return choice(
          id,
          title,
          CreationStepStatus.houseRule,
          'Manuelle Attributswerte sind ausdrücklich als Hausregel ausgewählt, nicht als SRD-Methode bestätigt.',
        );
      }
      if (!atStart) {
        return choice(
          id,
          title,
          CreationStepStatus.notAutomated,
          'Spätere Attributswerte dürfen von gespeicherten Anfangswerten abweichen. Keine rückwirkende Neuberechnung oder Bonusvergabe.',
        );
      }
      if (origin == null) {
        return choice(
          id,
          title,
          CreationStepStatus.notAutomated,
          'Werte vorhanden, aber Standardsatz, Punktekauf oder 4W6 und Hintergrundboni sind nicht nachgewiesen. Aus Zahlen allein wird keine Methode geraten.',
        );
      }
      if (!matchesOrigin || origin.background != backgroundDefinition?.label) {
        return choice(
          id,
          title,
          CreationStepStatus.invalid,
          'Attribute oder Hintergrund weichen vom bestätigten Startnachweis ab. Vor der Übernahme die Verteilung erneut bestätigen.',
        );
      }
      return choice(
        id,
        title,
        CreationStepStatus.confirmed,
        'Versionierter Nachweis einer gültigen SRD-Methode, sechs Basiswerte und genau einmal angewendete Hintergrundboni stimmen überein.',
      );
    }

    CreationStep klass() {
      const id = 'class.selection';
      const title = 'SRD-Klasse und Stufe';
      if (hero.level < 1 ||
          hero.level > 20 ||
          (atStart &&
              (hero.secondaryClassName.isNotEmpty ||
                  hero.secondaryClassLevel != 0))) {
        return choice(
          id,
          title,
          CreationStepStatus.invalid,
          'Regulärer Start auf Stufe 1 ohne Zweitklasse; eine weitere Klasse wird erst im zulässigen Stufenaufstieg erworben.',
        );
      }
      final hasSecondaryName = hero.secondaryClassName.trim().isNotEmpty;
      if ((hasSecondaryName &&
              (hero.secondaryClassLevel < 1 ||
                  hero.secondaryClassLevel >= hero.level)) ||
          (!hasSecondaryName && hero.secondaryClassLevel != 0)) {
        return choice(
          id,
          title,
          CreationStepStatus.invalid,
          'Hauptklasse, Zweitklasse und Gesamtstufe ergeben keine gültige Aufteilung.',
        );
      }
      if (hasSecondaryName && findSrdClass(hero.secondaryClassName) == null) {
        return choice(
          id,
          title,
          CreationStepStatus.notInSrd,
          'Die Zweitklasse ist keiner unterstützten SRD-Klasse zugeordnet.',
        );
      }
      if (hero.className.trim().isEmpty) {
        return choice(id, title, CreationStepStatus.missing, 'Klasse wählen.');
      }
      if (definition == null) {
        return choice(
          id,
          title,
          CreationStepStatus.notInSrd,
          'Die gewählte Klasse ist keiner der zwölf SRD-Klassen zugeordnet.',
        );
      }
      if (hasSecondaryName) {
        return choice(
          id,
          title,
          CreationStepStatus.notAutomated,
          'Gültige Klassenbezeichnungen und Stufenaufteilung; ursprüngliche Mehrklassen-Voraussetzungen und alle Stufenentscheidungen sind damit noch nicht nachgewiesen.',
        );
      }
      if (atStart && classChoice != null) {
        return choice(
          id,
          title,
          classChoiceMatches
              ? CreationStepStatus.confirmed
              : CreationStepStatus.invalid,
          classChoiceMatches
              ? 'Die erste Klasse wurde ausdrücklich bestätigt und versioniert gespeichert. Dies bestätigt noch nicht alle Klassenmerkmale oder Zauber.'
              : 'Die aktuelle Startklasse widerspricht der ausdrücklich bestätigten Klassenwahl.',
        );
      }
      return choice(
        id,
        title,
        CreationStepStatus.notAutomated,
        'Die Klassenbezeichnung gehört zum SRD; ein Katalogeintrag oder eine Editor-Vorauswahl belegt noch keine ausdrückliche Klassenentscheidung.',
      );
    }

    CreationStep classSkills() {
      const id = 'class.skills';
      const title = 'Klassenfertigkeiten';
      if (definition == null) {
        return choice(
          id,
          title,
          CreationStepStatus.dependent,
          'Zuerst eine unterstützte Klasse wählen.',
        );
      }
      if (_duplicates(skills)) {
        return choice(
          id,
          title,
          CreationStepStatus.invalid,
          'Eine Fertigkeit darf nicht mehrfach gezählt werden, auch nicht über den historischen Medizin-Alias.',
        );
      }
      if (skills.any((s) => !srdSkills.map(_skill).contains(s))) {
        return choice(
          id,
          title,
          CreationStepStatus.notInSrd,
          'Mindestens eine Fertigkeit gehört nicht zur SRD-Liste. Freie Einträge bleiben ungeprüft erhalten.',
        );
      }
      final backgroundSkills =
          package?.skills.map(_skill).toSet() ?? <String>{};
      if (atStart && classChoice != null) {
        final selected = classChoice.skills.map(_skill);
        if (!classChoiceMatches ||
            selected.any(
              (skill) =>
                  !skills.contains(skill) || backgroundSkills.contains(skill),
            )) {
          return choice(
            id,
            title,
            CreationStepStatus.invalid,
            'Die gespeicherte Klassenfertigkeitswahl fehlt im Entwurf oder überschneidet sich mit der bestätigten Hintergrundwahl.',
          );
        }
        return choice(
          id,
          title,
          CreationStepStatus.confirmed,
          'Die erforderlichen Klassenfertigkeiten sind ausdrücklich gewählt, getrennt vom Hintergrund belegt und im Charakter vorhanden. Weitere Übungen sind damit nicht vollständig geprüft.',
        );
      }

      final eligible = skills
          .where(
            (s) =>
                definition.skillChoices.map(_skill).contains(s) &&
                !backgroundSkills.contains(s),
          )
          .length;
      if (atStart && eligible < definition.skillCount) {
        return choice(
          id,
          title,
          CreationStepStatus.missing,
          'Es fehlen eigenständige Klassenfertigkeiten. Bereits dem Hintergrund zugeordnete Übungen zählen nicht nochmals als Klassenwahl.',
        );
      }
      return choice(
        id,
        title,
        CreationStepStatus.notAutomated,
        'Fertigkeitsnamen vorhanden; eine vollständige quellengetrennte Klassenwahl ist noch nicht dauerhaft belegt. Zusätzliche Übungen und Ersatzwahlen werden nicht erfunden.',
      );
    }

    CreationStep savingThrows() {
      const id = 'class.saving-throws';
      const title = 'Klassenrettungswürfe';
      if (definition == null) {
        return choice(
          id,
          title,
          CreationStepStatus.dependent,
          'Zuerst eine unterstützte Klasse wählen.',
        );
      }
      if (_duplicates(saves)) {
        return choice(
          id,
          title,
          CreationStepStatus.invalid,
          'Doppelte Rettungswurfübungen zählen nicht mehrfach.',
        );
      }
      if (saves.any((s) => !abilityNames.contains(s))) {
        return choice(
          id,
          title,
          CreationStepStatus.notInSrd,
          'Unbekannte Rettungswurfbezeichnung.',
        );
      }
      if (!definition.savingThrows.every(saves.contains)) {
        return choice(
          id,
          title,
          CreationStepStatus.missing,
          'Die Rettungswurfübungen der ersten Klasse sind nicht vollständig vorhanden.',
        );
      }
      if (atStart && classChoice != null) {
        return choice(
          id,
          title,
          classChoiceMatches
              ? CreationStepStatus.confirmed
              : CreationStepStatus.invalid,
          classChoiceMatches
              ? 'Die Rettungswurfübungen der ausdrücklich bestätigten ersten Klasse sind vorhanden. Weitere Übungsquellen bleiben getrennt zu prüfen.'
              : 'Die Startklasse passt nicht zum gespeicherten Vergabenachweis.',
        );
      }
      return choice(
        id,
        title,
        CreationStepStatus.notAutomated,
        'Die passenden Übungen sind notiert; vollständige Vergabequelle und zusätzliche Übungen sind noch nicht strukturiert nachgewiesen.',
      );
    }

    CreationStep hitPoints() {
      const id = 'class.hit-points';
      const title = 'Start-Trefferpunkte';
      if ((hero.maxHitPoints != null && hero.maxHitPoints! < 1) ||
          (hero.hitPoints != null && hero.hitPoints! < 0) ||
          (hero.hitPoints != null &&
              hero.maxHitPoints != null &&
              hero.hitPoints! > hero.maxHitPoints!)) {
        return choice(
          id,
          title,
          CreationStepStatus.invalid,
          'Aktuelle und maximale Trefferpunkte widersprechen sich.',
        );
      }
      if (hero.hitPoints == null || hero.maxHitPoints == null) {
        return choice(
          id,
          title,
          CreationStepStatus.missing,
          'Aktuelle und maximale Trefferpunkte sind nicht beide bestätigt.',
        );
      }
      if (definition == null || hero.abilities['constitution'] == null) {
        return choice(
          id,
          title,
          CreationStepStatus.dependent,
          'Klasse und Konstitution werden für die Start-TP benötigt.',
        );
      }
      return choice(
        id,
        title,
        CreationStepStatus.notAutomated,
        'Aktuelle TP sind keine historische Startberechnung. Klassen-, Spezies- und Talentbeiträge sind nicht vollständig belegt; Verletzungen werden nicht rückwirkend geändert.',
      );
    }

    CreationStep combatValues() {
      const id = 'combat.armor-speed';
      const title = 'Rüstungsklasse und Bewegung';
      if ((hero.armorClass != null && hero.armorClass! < 1) ||
          (hero.speed != null && hero.speed! < 0)) {
        return choice(
          id,
          title,
          CreationStepStatus.invalid,
          'Rüstungsklasse oder Bewegung ist ungültig.',
        );
      }
      if (hero.armorClass == null || hero.speed == null) {
        return choice(
          id,
          title,
          CreationStepStatus.missing,
          'Rüstungsklasse oder Bewegung fehlt.',
        );
      }
      if (hero.species.trim().isEmpty || hero.abilities['dexterity'] == null) {
        return choice(
          id,
          title,
          CreationStepStatus.dependent,
          'Spezies und Geschicklichkeit zuerst bestätigen.',
        );
      }
      return choice(
        id,
        title,
        CreationStepStatus.notAutomated,
        'Zahlen allein belegen weder angelegte Ausrüstung noch alle Spezies- und Klassenbeiträge. Es erfolgt keine Neuberechnung beim Prüfen.',
      );
    }

    CreationStep equipment() {
      const id = 'class.equipment';
      const title = 'Klassen-Startausrüstung oder Gold';
      if ((hero.gold != null && hero.gold! < 0) ||
          _duplicates(hero.inventory.map((i) => i.id))) {
        return choice(
          id,
          title,
          CreationStepStatus.invalid,
          'Gold oder eindeutige Inventar-IDs sind ungültig.',
        );
      }
      if (atStart && classChoice != null && !classChoiceMatches) {
        return choice(
          id,
          title,
          CreationStepStatus.invalid,
          'Die aktuelle Startklasse stimmt nicht mit dem Paketnachweis überein.',
        );
      }
      if (atStart && classChoiceMatches && classChoice.kitIndex != null) {
        final kit = classChoice.selection.startingKit!;
        final expected = [
          for (final item in kit.items)
            StartingEquipmentImport.fromSelectedStartingItem(
              item,
              'audit-only',
              selectedCatalogId: classChoice.equipmentChoices[item.name],
              choiceVersion: classChoice.version,
            ),
        ];
        if (expected.any(
          (item) => item.catalogId.isEmpty || item.stats == null,
        )) {
          return choice(
            id,
            title,
            CreationStepStatus.notAutomated,
            'Die Paketwahl ist belegt; mindestens ein Startgegenstand oder eine notwendige Variante ist noch nicht strukturiert aufgelöst. Freitext bestätigt keine vollständige Ausrüstung.',
          );
        }
        // Monk equipment must be the same tool/instrument chosen for tool
        // proficiency (SRD p.49). That source decision is not typed yet.
        if (classChoice.className == 'Mönch' &&
            classChoice.equipmentChoices.isNotEmpty) {
          return choice(
            id,
            title,
            CreationStepStatus.notAutomated,
            'Die zulässige Werkzeug-/Instrumentausrüstung ist gewählt. Ihre Übereinstimmung mit der erforderlichen Werkzeugübung ist noch nicht strukturiert nachgewiesen.',
          );
        }
        // Names alone never substitute for catalog IDs and typed stats.
        String signature(InventoryItem item) =>
            jsonEncode([item.catalogId, item.name, item.stats?.toJson()]);
        final quantities = <String, int>{};
        for (final item in hero.inventory) {
          quantities.update(
            signature(item),
            (n) => n + item.quantity,
            ifAbsent: () => item.quantity,
          );
        }
        for (final item in expected) {
          quantities.update(
            signature(item),
            (n) => n - item.quantity,
            ifAbsent: () => -item.quantity,
          );
        }
        final present =
            quantities.values.every((n) => n >= 0) &&
            hero.gold != null &&
            hero.gold! >= kit.gold;
        return choice(
          id,
          title,
          present
              ? CreationStepStatus.confirmed
              : CreationStepStatus.notAutomated,
          present
              ? 'Die ausdrückliche Klassenpaketwahl ist gespeichert; die typisierten Startgegenstände und das Paketgold sind vorhanden. Anlegen, spätere Käufe und weitere Quellen sind damit nicht vollständig geprüft.'
              : 'Die historische Paketwahl ist erhalten; heutige Gegenstände oder Gold weichen ab. Verbrauch, Verkauf oder spätere Käufe werden nicht rückgängig gemacht oder erfunden.',
        );
      }
      if (hero.inventory.isEmpty && hero.gold == null) {
        return choice(
          id,
          title,
          CreationStepStatus.missing,
          'Eine Klassenpaket- oder Startgoldwahl ist noch nicht belegt.',
        );
      }
      return choice(
        id,
        title,
        CreationStepStatus.notAutomated,
        'Inventar und Gold einschließlich 0 belegen keine Klassenpaketwahl. Ein Hintergrundpaket ist keine zusätzliche Bestätigung eines Klassenpakets.',
      );
    }

    return List.unmodifiable([
      species(),
      background(),
      abilities(),
      klass(),
      classSkills(),
      savingThrows(),
      hitPoints(),
      combatValues(),
      equipment(),
      if (package?.requiresFeatSpellChoices == true ||
          hero.startingMagicInitiate != null)
        choice(
          'origin.magic-initiate-choice',
          'Magieinitiierter: Zauberwahl und Zauberattribut',
          hero.startingMagicInitiate == null
              ? CreationStepStatus.missing
              : package?.background != hero.startingMagicInitiate!.background ||
                    backgroundDefinition !=
                        hero.startingMagicInitiate!.background
              ? CreationStepStatus.invalid
              : CreationStepStatus.confirmed,
          hero.startingMagicInitiate == null
              ? 'Zwei verschiedene SRD-Zaubertricks, einen Zauber des '
                    '1. Grades und das Zauberattribut bestätigen.'
              : package?.background != hero.startingMagicInitiate!.background ||
                    backgroundDefinition !=
                        hero.startingMagicInitiate!.background
              ? 'Die gespeicherte Zauberwahl widerspricht dem bestätigten Hintergrund.'
              : 'Die versionierte Herkunfts-Zauberwahl ist bestätigt und gespeichert. '
                    'Kostenlose Nutzung, Zauberplatzwirken und Zauberaustausch '
                    'sind damit nicht automatisiert oder freigeschaltet.',
        ),
      const CreationStep(
        'origin.feat',
        'Herkunftstalent und Pflichtwahlen',
        CreationStepStatus.notAutomated,
        'Ein Talentvermerk oder eine einzelne implementierte Wirkung belegt nicht alle Pflichtwahlen, Zauber und Anwendungen des Herkunftstalents.',
      ),
      CreationStep(
        'class.choices',
        'Spezielle Klassenwahlen und Zauber',
        definition == null
            ? CreationStepStatus.dependent
            : CreationStepStatus.notAutomated,
        'Klassenmerkmale, Expertise, Zauber und Ressourcen benötigen konkrete bestätigte Entscheidungen. Ein Klassenkatalog genügt nicht.',
      ),
    ]);
  }
}
