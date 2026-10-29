import 'fighter_creation_rules.dart';
import 'srd_character_classes.dart';
import 'starting_equipment_import.dart';

/// Historical evidence of an explicit first-class choice, never a grant.
/// SRD 5.2.1, Character Creation / Choose Class and Classes / Core Traits.
/// It covers skills, saving throws, starter kits and the Monk tool choice;
/// it does not certify spells, all class features or complete SRD creation.
class StartingClassChoice {
  StartingClassChoice.confirmed({
    required String className,
    required Iterable<String> skills,
    int? kitIndex,
    Map<String, String> equipmentChoices = const {},
    FighterStartingChoices? fighterChoices,
    String? toolProficiencyCatalogId,
  }) : this._validated(
         version: 3,
         className: className,
         skills: skills,
         kitIndex: kitIndex,
         equipmentChoices: equipmentChoices,
         fighterChoices: fighterChoices,
         toolProficiencyCatalogId: toolProficiencyCatalogId,
       );

  StartingClassChoice._validated({
    required this.version,
    required this.className,
    required Iterable<String> skills,
    this.kitIndex,
    Map<String, String> equipmentChoices = const {},
    this.fighterChoices,
    this.toolProficiencyCatalogId,
  }) : skills = List.unmodifiable(skills),
       equipmentChoices = Map.unmodifiable(equipmentChoices) {
    final definition = findSrdClass(className);
    if (definition == null || definition.name != className) {
      throw const FormatException('Ungültige SRD-Startklasse.');
    }
    final selected = selection;
    if (selected.startingKit case final kit?) {
      StartingEquipmentImport.validateKitChoices(
        kit,
        this.equipmentChoices,
        choiceVersion: version,
      );
    } else if (this.equipmentChoices.isNotEmpty) {
      throw const FormatException('Ausrüstungswahl benötigt ein Startpaket.');
    }
    if ((className == 'Kämpfer') != (fighterChoices != null)) {
      throw const FormatException(
        'Kämpferstart benötigt die passenden Klassenwahlen.',
      );
    }
    if (version >= 3 && className == 'Mönch') {
      if (!StartingEquipmentImport.monkTools.any(
        (item) => item.id == toolProficiencyCatalogId,
      )) {
        throw const FormatException(
          'Für den Mönch eine Handwerkszeug- oder Instrumentübung wählen.',
        );
      }
      if (kitIndex == 0 &&
          this.equipmentChoices[StartingEquipmentImport.monkToolLabel] !=
              toolProficiencyCatalogId) {
        throw const FormatException(
          'Das Mönch-Startpaket muss das für die Übung gewählte Werkzeug enthalten.',
        );
      }
    } else if (toolProficiencyCatalogId != null) {
      throw const FormatException(
        'Diese Klassenstartversion belegt keine Werkzeugwahl.',
      );
    }
  }

  final int version;
  final String className;
  final List<String> skills;
  final int? kitIndex;
  final Map<String, String> equipmentChoices;
  final FighterStartingChoices? fighterChoices;
  final String? toolProficiencyCatalogId;

  /// Changing skills does not reselect, upgrade or grant historical equipment.
  StartingClassChoice withUpdatedClassDecisions(StartingClassChoice updated) {
    if (updated.className != className) {
      throw const FormatException(
        'Ein übernommenes Startpaket darf nicht die Klasse wechseln.',
      );
    }
    if (version >= 3 &&
        className == 'Mönch' &&
        kitIndex == 0 &&
        updated.toolProficiencyCatalogId != toolProficiencyCatalogId) {
      throw const FormatException(
        'Die Werkzeugübung gehört zum bereits übernommenen Mönch-Paket. '
        'Ein Wechsel würde die historische Ausrüstungswahl verändern.',
      );
    }
    return StartingClassChoice._validated(
      version: version,
      className: className,
      skills: updated.skills,
      kitIndex: kitIndex,
      equipmentChoices: equipmentChoices,
      fighterChoices: updated.fighterChoices,
      toolProficiencyCatalogId: version >= 3
          ? updated.toolProficiencyCatalogId
          : null,
    );
  }

  SrdClassSelection get selection => SrdClassSelection(
    characterClass: findSrdClass(className)!,
    skills: skills,
    kitIndex: kitIndex,
  );

  Map<String, dynamic> toJson() => {
    'version': version,
    'className': className,
    'skills': skills,
    'kitIndex': kitIndex,
    'equipmentChoices': equipmentChoices,
    if (toolProficiencyCatalogId != null)
      'toolProficiencyCatalogId': toolProficiencyCatalogId,
    if (fighterChoices case final fighter?)
      'fighterChoices': {
        'styleId': fighter.styleId,
        'masteryWeaponIds': fighter.masteryWeaponIds,
      },
  };

  factory StartingClassChoice.fromJson(Map<String, dynamic> json) {
    final version = json['version'];
    final className = json['className'];
    final skills = json['skills'];
    final kit = json['kitIndex'];
    final equipment = json['equipmentChoices'];
    final tool = json['toolProficiencyCatalogId'];
    if (version is! int ||
        (version < 1 || version > 3) ||
        (tool != null && tool is! String) ||
        (version < 3 && json.containsKey('toolProficiencyCatalogId')) ||
        className is! String ||
        skills is! List ||
        skills.length > 4 ||
        skills.any((value) => value is! String) ||
        (kit != null && kit is! int) ||
        equipment is! Map ||
        equipment.length > 10 ||
        equipment.entries.any(
          (entry) => entry.key is! String || entry.value is! String,
        )) {
      throw const FormatException(
        'Ungültiger versionierter Klassenstartnachweis.',
      );
    }
    FighterStartingChoices? fighter;
    final rawFighter = json['fighterChoices'];
    if (rawFighter != null) {
      if (rawFighter is! Map ||
          rawFighter['styleId'] is! String ||
          rawFighter['masteryWeaponIds'] is! List ||
          (rawFighter['masteryWeaponIds'] as List).length != 3 ||
          (rawFighter['masteryWeaponIds'] as List).any(
            (value) => value is! String,
          )) {
        throw const FormatException('Ungültige Kämpferstartwahlen.');
      }
      fighter = FighterStartingChoices(
        styleId: rawFighter['styleId'] as String,
        masteryWeaponIds: List<String>.from(
          rawFighter['masteryWeaponIds'] as List,
        ),
      );
    }
    return StartingClassChoice._validated(
      version: version,
      className: className,
      skills: List<String>.from(skills),
      kitIndex: kit as int?,
      equipmentChoices: Map<String, String>.from(equipment),
      fighterChoices: fighter,
      toolProficiencyCatalogId: tool as String?,
    );
  }
}
