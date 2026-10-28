import 'fighter_creation_rules.dart';
import 'srd_character_classes.dart';
import 'starting_equipment_import.dart';

/// Historical evidence of an explicit first-class choice, never a grant.
/// SRD 5.2.1, Character Creation / Choose Class and Classes / Core Traits.
/// It covers only the existing skill, saving-throw and starter-kit decisions;
/// it does not certify spells, all class features or complete SRD creation.
class StartingClassChoice {
  StartingClassChoice.confirmed({
    required this.className,
    required Iterable<String> skills,
    this.kitIndex,
    Map<String, String> equipmentChoices = const {},
    this.fighterChoices,
  }) : skills = List.unmodifiable(skills),
       equipmentChoices = Map.unmodifiable(equipmentChoices) {
    final definition = findSrdClass(className);
    if (definition == null || definition.name != className) {
      throw const FormatException('Ungültige SRD-Startklasse.');
    }
    final selected = selection;
    if (selected.startingKit case final kit?) {
      StartingEquipmentImport.validateKitChoices(kit, this.equipmentChoices);
    } else if (this.equipmentChoices.isNotEmpty) {
      throw const FormatException('Ausrüstungswahl benötigt ein Startpaket.');
    }
    if ((className == 'Kämpfer') != (fighterChoices != null)) {
      throw const FormatException(
        'Kämpferstart benötigt die passenden Klassenwahlen.',
      );
    }
  }

  final String className;
  final List<String> skills;
  final int? kitIndex;
  final Map<String, String> equipmentChoices;
  final FighterStartingChoices? fighterChoices;

  SrdClassSelection get selection => SrdClassSelection(
    characterClass: findSrdClass(className)!,
    skills: skills,
    kitIndex: kitIndex,
  );

  Map<String, dynamic> toJson() => {
    'version': 1,
    'className': className,
    'skills': skills,
    'kitIndex': kitIndex,
    'equipmentChoices': equipmentChoices,
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
    if (version is! int ||
        version != 1 ||
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
    return StartingClassChoice.confirmed(
      className: className,
      skills: List<String>.from(skills),
      kitIndex: kit as int?,
      equipmentChoices: Map<String, String>.from(equipment),
      fighterChoices: fighter,
    );
  }
}
