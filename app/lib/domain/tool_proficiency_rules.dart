import 'models.dart';
import 'srd_equipment_catalog.dart';
import 'ability_generation.dart';

/// Confirmed sources only. Item possession and free-text feature names never
/// grant proficiency. SRD 5.2.1 pp.8–9,49,83,93 (CC BY 4.0).
class ToolProficiencyRules {
  const ToolProficiencyRules._();

  static Set<String> catalogIds(HeroCharacter hero) {
    final result = <String>{};
    final firstClass = hero.startingClassChoice;
    if (firstClass != null &&
        firstClass.version >= 3 &&
        firstClass.className == 'Mönch') {
      result.add(firstClass.toolProficiencyCatalogId!);
    }
    final background = hero.startingBackgroundPackage;
    if (background != null) {
      result.add(switch (background.background) {
        SrdBackground.acolyte ||
        SrdBackground.sage => 'item-calligrapher-s-supplies',
        SrdBackground.criminal => 'item-thieves-tools',
        SrdBackground.soldier => background.gamingSetCatalogId,
      });
    }
    return Set.unmodifiable(result);
  }

  static List<EquipmentEntry> entries(HeroCharacter hero) => List.unmodifiable(
    catalogIds(hero).map((id) => SrdEquipmentCatalog.byId(id)!),
  );
}
