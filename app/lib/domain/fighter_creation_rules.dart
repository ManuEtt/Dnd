import 'srd_equipment_catalog.dart';

/// D&D SRD 5.2.1 Fighter level 1. Choices are explicit and do not by
/// themselves execute their combat effects; the rule engine is authoritative.
/// Source: https://www.dndbeyond.com/srd
class FighterCreationRules {
  const FighterCreationRules._();

  /// Only the Fighting Style feats actually published in SRD 5.2.1.
  static const fightingStyles = <String, String>{
    'archery': 'Bogenschießen',
    'defense': 'Verteidigung',
    'great-weapon-fighting': 'Kampf mit großen Waffen',
    'two-weapon-fighting': 'Kampf mit zwei Waffen',
  };

  static List<EquipmentEntry> get masteryWeapons => SrdEquipmentCatalog.all
      .where((item) => item.isWeapon && item.mastery != null)
      .toList(growable: false);

  static int get secondWindUses => 2;
  static int get hitDie => 10;
  static int get masteryCount => 3;
}

/// Selected Fighting Style and exactly three distinct kinds of weapons.
class FighterStartingChoices {
  FighterStartingChoices({
    required this.styleId,
    required Iterable<String> masteryWeaponIds,
  }) : masteryWeaponIds = List.unmodifiable(masteryWeaponIds) {
    if (!FighterCreationRules.fightingStyles.containsKey(styleId)) {
      throw const FormatException('Wähle einen SRD-Kampfstil für den Kämpfer.');
    }
    final available = FighterCreationRules.masteryWeapons
        .map((item) => item.id)
        .toSet();
    if (this.masteryWeaponIds.length != FighterCreationRules.masteryCount ||
        this.masteryWeaponIds.toSet().length !=
            FighterCreationRules.masteryCount ||
        this.masteryWeaponIds.any((id) => !available.contains(id))) {
      throw const FormatException(
        'Wähle genau drei unterschiedliche SRD-Waffenmeisterschaften.',
      );
    }
  }

  final String styleId;
  final List<String> masteryWeaponIds;

  /// Explicitly described choices in the existing save schema's feature list.
  /// Existing features are not silently discarded and no rules are inferred
  /// from this display text by the rules engine.
  List<String> get featureLabels => [
    'Kampfstil: ${FighterCreationRules.fightingStyles[styleId]}',
    'Zweite Luft (${FighterCreationRules.secondWindUses} Anwendungen)',
    for (final id in masteryWeaponIds)
      'Waffenmeisterschaft: ${SrdEquipmentCatalog.byId(id)!.name}',
  ];
}
