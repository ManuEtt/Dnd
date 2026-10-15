/// SRD 5.2.1 equipment table (CC BY 4.0). Generated, original German labels.
/// Reference: https://www.dndbeyond.com/srd, Equipment pp. 89–102,
/// Magic Items pp. 204–253. Magical entries are catalog only; no automatic effects.
/// Do not silently substitute historical/unknown inventory with these values.
enum EquipmentCategory {
  simpleMelee,
  simpleRanged,
  martialMelee,
  martialRanged,
  lightArmor,
  mediumArmor,
  heavyArmor,
  shield,
  gear,
  pack,
  ammunition,
  focus,
  tool,
  game,
  instrument,
  mount,
  vehicle,
  magic,
 }

extension EquipmentCategoryLabel on EquipmentCategory {
  String get label => switch (this) {
    EquipmentCategory.simpleMelee => "Einfache Nahkampfwaffen",
    EquipmentCategory.simpleRanged => "Einfache Fernkampfwaffen",
    EquipmentCategory.martialMelee => "Kriegs-Nahkampfwaffen",
    EquipmentCategory.martialRanged => "Kriegs-Fernkampfwaffen",
    EquipmentCategory.lightArmor => "Leichte Rüstung",
    EquipmentCategory.mediumArmor => "Mittelschwere Rüstung",
    EquipmentCategory.heavyArmor => "Schwere Rüstung",
    EquipmentCategory.shield => "Schilde",
    EquipmentCategory.gear => "Abenteuerausrüstung",
    EquipmentCategory.pack => "Ausrüstungspakete",
    EquipmentCategory.ammunition => "Munition",
    EquipmentCategory.focus => "Magische Foki",
    EquipmentCategory.tool => "Werkzeuge",
    EquipmentCategory.game => "Spiele",
    EquipmentCategory.instrument => "Musikinstrumente",
    EquipmentCategory.mount => "Reittiere",
    EquipmentCategory.vehicle => "Fahrzeuge",
    EquipmentCategory.magic => "Magische Gegenstände",
  };
}

class EquipmentEntry {
  const EquipmentEntry({
    required this.id, required this.name, required this.englishName,
    required this.category, this.priceCp, this.weightLb, this.damage,
    this.damageType, this.twoHandDamage, this.properties = const [],
    this.mastery, this.rangeNormal, this.rangeLong, this.ammunitionType, this.armorBaseAc,
    this.dexCap, this.strengthMin, this.stealthDisadvantage = false,
    this.note,
  });
  final String id, name, englishName;
  final EquipmentCategory category;
  /// Prices use copper pieces (100 CP = 1 GP), null means no fixed SRD price.
  final int? priceCp;
  /// Original SRD weight in pounds, null means not specified.
  final double? weightLb;
  final String? damage, damageType, twoHandDamage, mastery, ammunitionType;
  final List<String> properties;
  /// Ranges in feet; null for melee attacks without Thrown.
  final int? rangeNormal, rangeLong;
  /// For armor: fixed base AC; for shields: AC bonus. See isShield.
  final int? armorBaseAc, dexCap, strengthMin;
  final bool stealthDisadvantage;
  final String? note;

  bool get isWeapon => const [EquipmentCategory.simpleMelee,
    EquipmentCategory.simpleRanged, EquipmentCategory.martialMelee,
    EquipmentCategory.martialRanged].contains(category);
  bool get isShield => category == EquipmentCategory.shield;
  bool get isArmor => const [EquipmentCategory.lightArmor,
    EquipmentCategory.mediumArmor, EquipmentCategory.heavyArmor].contains(category);
  bool hasProperty(String property) => properties.contains(property);

  /// Preview only: trained/attuned status and other AC features are external.
  /// A shield is an AC bonus, not an armor base; caller must verify training.
  int? armorClassWithDex(int? dexModifier) {
    if (!isArmor || armorBaseAc == null) return null;
    if (category == EquipmentCategory.heavyArmor) return armorBaseAc;
    if (dexModifier == null) return null;
    final capped = dexCap == null ? dexModifier :
        (dexModifier > dexCap! ? dexCap! : dexModifier);
    return armorBaseAc! + capped;
  }

  String get priceLabel {
    if (priceCp == null) return 'Preis nicht festgelegt';
    if (priceCp! >= 100 && priceCp! % 100 == 0) return '${priceCp! ~/ 100} GM';
    if (priceCp! >= 10 && priceCp! % 10 == 0) return '${priceCp! ~/ 10} SM';
    return '$priceCp KM';
  }

  /// No magic equipment effects are applied just by selecting a catalog entry.
  String get detail {
    final parts = <String>[category.label];
    if (damage != null) parts.add('Schaden $damage $damageType');
    if (twoHandDamage != null) parts.add('Zweihändig $twoHandDamage');
    if (mastery != null) parts.add('Meisterschaft: $mastery');
    if (properties.isNotEmpty) parts.add('Eigenschaften: ${properties.join(', ')}');
    if (rangeNormal != null) parts.add('Reichweite $rangeNormal/$rangeLong Fuß');
    if (ammunitionType != null) parts.add('Munition: $ammunitionType');
    if (isShield) parts.add('RK +$armorBaseAc (bei Übung)');
    if (isArmor) parts.add('Basis-RK $armorBaseAc${dexCap == 0 ? '' : ' + GE'}');
    if (strengthMin != null) parts.add('ST $strengthMin erforderlich, sonst -10 Fuß');
    if (stealthDisadvantage) parts.add('Heimlichkeit: Nachteil');
    if (weightLb != null) parts.add('$weightLb lb');
    parts.add(priceLabel);
    if (note != null) parts.add(note!);
    return parts.join(' · ');
  }
}

class SrdEquipmentCatalog {
  const SrdEquipmentCatalog._();
  static const source = 'D&D SRD 5.2.1 (CC BY 4.0)';
  static const all = <EquipmentEntry>[

    EquipmentEntry(id: "weapon-club", name: "Knüppel", englishName: "Club", category: EquipmentCategory.simpleMelee, priceCp: 10, weightLb: 2.0, damage: "1d4", damageType: "Wucht", properties: ["light"], mastery: "slow"),
    EquipmentEntry(id: "weapon-dagger", name: "Dolch", englishName: "Dagger", category: EquipmentCategory.simpleMelee, priceCp: 200, weightLb: 1.0, damage: "1d4", damageType: "Stich", properties: ["finesse", "light", "thrown"], mastery: "nick", rangeNormal: 20, rangeLong: 60),
    EquipmentEntry(id: "weapon-greatclub", name: "Großer Knüppel", englishName: "Greatclub", category: EquipmentCategory.simpleMelee, priceCp: 20, weightLb: 10.0, damage: "1d8", damageType: "Wucht", properties: ["two-handed"], mastery: "push"),
    EquipmentEntry(id: "weapon-handaxe", name: "Handaxt", englishName: "Handaxe", category: EquipmentCategory.simpleMelee, priceCp: 500, weightLb: 2.0, damage: "1d6", damageType: "Hieb", properties: ["light", "thrown"], mastery: "vex", rangeNormal: 20, rangeLong: 60),
    EquipmentEntry(id: "weapon-javelin", name: "Wurfspeer", englishName: "Javelin", category: EquipmentCategory.simpleMelee, priceCp: 50, weightLb: 2.0, damage: "1d6", damageType: "Stich", properties: ["thrown"], mastery: "slow", rangeNormal: 30, rangeLong: 120),
    EquipmentEntry(id: "weapon-light-hammer", name: "Leichter Hammer", englishName: "Light Hammer", category: EquipmentCategory.simpleMelee, priceCp: 200, weightLb: 2.0, damage: "1d4", damageType: "Wucht", properties: ["light", "thrown"], mastery: "nick", rangeNormal: 20, rangeLong: 60),
    EquipmentEntry(id: "weapon-mace", name: "Streitkolben", englishName: "Mace", category: EquipmentCategory.simpleMelee, priceCp: 500, weightLb: 4.0, damage: "1d6", damageType: "Wucht", properties: [], mastery: "sap"),
    EquipmentEntry(id: "weapon-quarterstaff", name: "Kampfstab", englishName: "Quarterstaff", category: EquipmentCategory.simpleMelee, priceCp: 20, weightLb: 4.0, damage: "1d6", damageType: "Wucht", twoHandDamage: "1d8", properties: ["versatile"], mastery: "topple"),
    EquipmentEntry(id: "weapon-sickle", name: "Sichel", englishName: "Sickle", category: EquipmentCategory.simpleMelee, priceCp: 100, weightLb: 2.0, damage: "1d4", damageType: "Hieb", properties: ["light"], mastery: "nick"),
    EquipmentEntry(id: "weapon-spear", name: "Speer", englishName: "Spear", category: EquipmentCategory.simpleMelee, priceCp: 100, weightLb: 3.0, damage: "1d6", damageType: "Stich", twoHandDamage: "1d8", properties: ["thrown", "versatile"], mastery: "sap", rangeNormal: 20, rangeLong: 60),
    EquipmentEntry(id: "weapon-dart", name: "Wurfpfeil", englishName: "Dart", category: EquipmentCategory.simpleRanged, priceCp: 5, weightLb: 0.25, damage: "1d4", damageType: "Stich", properties: ["finesse", "thrown"], mastery: "vex", rangeNormal: 20, rangeLong: 60),
    EquipmentEntry(id: "weapon-light-crossbow", name: "Leichte Armbrust", englishName: "Light Crossbow", category: EquipmentCategory.simpleRanged, priceCp: 2500, weightLb: 5.0, damage: "1d8", damageType: "Stich", properties: ["ammunition", "loading", "two-handed"], mastery: "slow", rangeNormal: 80, rangeLong: 320, ammunitionType: "bolts"),
    EquipmentEntry(id: "weapon-shortbow", name: "Kurzbogen", englishName: "Shortbow", category: EquipmentCategory.simpleRanged, priceCp: 2500, weightLb: 2.0, damage: "1d6", damageType: "Stich", properties: ["ammunition", "two-handed"], mastery: "vex", rangeNormal: 80, rangeLong: 320, ammunitionType: "arrows"),
    EquipmentEntry(id: "weapon-sling", name: "Schleuder", englishName: "Sling", category: EquipmentCategory.simpleRanged, priceCp: 10, damage: "1d4", damageType: "Wucht", properties: ["ammunition"], mastery: "slow", rangeNormal: 30, rangeLong: 120, ammunitionType: "sling bullets"),
    EquipmentEntry(id: "weapon-battleaxe", name: "Streitaxt", englishName: "Battleaxe", category: EquipmentCategory.martialMelee, priceCp: 1000, weightLb: 4.0, damage: "1d8", damageType: "Hieb", twoHandDamage: "1d10", properties: ["versatile"], mastery: "topple"),
    EquipmentEntry(id: "weapon-flail", name: "Flegel", englishName: "Flail", category: EquipmentCategory.martialMelee, priceCp: 1000, weightLb: 2.0, damage: "1d8", damageType: "Wucht", properties: [], mastery: "sap"),
    EquipmentEntry(id: "weapon-glaive", name: "Glefe", englishName: "Glaive", category: EquipmentCategory.martialMelee, priceCp: 2000, weightLb: 6.0, damage: "1d10", damageType: "Hieb", properties: ["heavy", "reach", "two-handed"], mastery: "graze"),
    EquipmentEntry(id: "weapon-greataxe", name: "Großaxt", englishName: "Greataxe", category: EquipmentCategory.martialMelee, priceCp: 3000, weightLb: 7.0, damage: "1d12", damageType: "Hieb", properties: ["heavy", "two-handed"], mastery: "cleave"),
    EquipmentEntry(id: "weapon-greatsword", name: "Zweihandschwert", englishName: "Greatsword", category: EquipmentCategory.martialMelee, priceCp: 5000, weightLb: 6.0, damage: "2d6", damageType: "Hieb", properties: ["heavy", "two-handed"], mastery: "graze"),
    EquipmentEntry(id: "weapon-halberd", name: "Hellebarde", englishName: "Halberd", category: EquipmentCategory.martialMelee, priceCp: 2000, weightLb: 6.0, damage: "1d10", damageType: "Hieb", properties: ["heavy", "reach", "two-handed"], mastery: "cleave"),
    EquipmentEntry(id: "weapon-lance", name: "Lanze", englishName: "Lance", category: EquipmentCategory.martialMelee, priceCp: 1000, weightLb: 6.0, damage: "1d10", damageType: "Stich", properties: ["heavy", "reach", "two-handed"], mastery: "topple", note: "Zweihändig außer bei berittener Verwendung."),
    EquipmentEntry(id: "weapon-longsword", name: "Langschwert", englishName: "Longsword", category: EquipmentCategory.martialMelee, priceCp: 1500, weightLb: 3.0, damage: "1d8", damageType: "Hieb", twoHandDamage: "1d10", properties: ["versatile"], mastery: "sap"),
    EquipmentEntry(id: "weapon-maul", name: "Zweihandhammer", englishName: "Maul", category: EquipmentCategory.martialMelee, priceCp: 1000, weightLb: 10.0, damage: "2d6", damageType: "Wucht", properties: ["heavy", "two-handed"], mastery: "topple"),
    EquipmentEntry(id: "weapon-morningstar", name: "Morgenstern", englishName: "Morningstar", category: EquipmentCategory.martialMelee, priceCp: 1500, weightLb: 4.0, damage: "1d8", damageType: "Stich", properties: [], mastery: "sap"),
    EquipmentEntry(id: "weapon-pike", name: "Pike", englishName: "Pike", category: EquipmentCategory.martialMelee, priceCp: 500, weightLb: 18.0, damage: "1d10", damageType: "Stich", properties: ["heavy", "reach", "two-handed"], mastery: "push"),
    EquipmentEntry(id: "weapon-rapier", name: "Rapier", englishName: "Rapier", category: EquipmentCategory.martialMelee, priceCp: 2500, weightLb: 2.0, damage: "1d8", damageType: "Stich", properties: ["finesse"], mastery: "vex"),
    EquipmentEntry(id: "weapon-scimitar", name: "Krummsäbel", englishName: "Scimitar", category: EquipmentCategory.martialMelee, priceCp: 2500, weightLb: 3.0, damage: "1d6", damageType: "Hieb", properties: ["finesse", "light"], mastery: "nick"),
    EquipmentEntry(id: "weapon-shortsword", name: "Kurzschwert", englishName: "Shortsword", category: EquipmentCategory.martialMelee, priceCp: 1000, weightLb: 2.0, damage: "1d6", damageType: "Stich", properties: ["finesse", "light"], mastery: "vex"),
    EquipmentEntry(id: "weapon-trident", name: "Dreizack", englishName: "Trident", category: EquipmentCategory.martialMelee, priceCp: 500, weightLb: 4.0, damage: "1d8", damageType: "Stich", twoHandDamage: "1d10", properties: ["thrown", "versatile"], mastery: "topple", rangeNormal: 20, rangeLong: 60),
    EquipmentEntry(id: "weapon-warhammer", name: "Kriegshammer", englishName: "Warhammer", category: EquipmentCategory.martialMelee, priceCp: 1500, weightLb: 5.0, damage: "1d8", damageType: "Wucht", twoHandDamage: "1d10", properties: ["versatile"], mastery: "push"),
    EquipmentEntry(id: "weapon-war-pick", name: "Kriegspicke", englishName: "War Pick", category: EquipmentCategory.martialMelee, priceCp: 500, weightLb: 2.0, damage: "1d8", damageType: "Stich", twoHandDamage: "1d10", properties: ["versatile"], mastery: "sap"),
    EquipmentEntry(id: "weapon-whip", name: "Peitsche", englishName: "Whip", category: EquipmentCategory.martialMelee, priceCp: 200, weightLb: 3.0, damage: "1d4", damageType: "Hieb", properties: ["finesse", "reach"], mastery: "slow"),
    EquipmentEntry(id: "weapon-blowgun", name: "Blasrohr", englishName: "Blowgun", category: EquipmentCategory.martialRanged, priceCp: 1000, weightLb: 1.0, damage: "1", damageType: "Stich", properties: ["ammunition", "loading"], mastery: "vex", rangeNormal: 25, rangeLong: 100, ammunitionType: "needles"),
    EquipmentEntry(id: "weapon-hand-crossbow", name: "Handarmbrust", englishName: "Hand Crossbow", category: EquipmentCategory.martialRanged, priceCp: 7500, weightLb: 3.0, damage: "1d6", damageType: "Stich", properties: ["ammunition", "light", "loading"], mastery: "vex", rangeNormal: 30, rangeLong: 120, ammunitionType: "bolts"),
    EquipmentEntry(id: "weapon-heavy-crossbow", name: "Schwere Armbrust", englishName: "Heavy Crossbow", category: EquipmentCategory.martialRanged, priceCp: 5000, weightLb: 18.0, damage: "1d10", damageType: "Stich", properties: ["ammunition", "heavy", "loading", "two-handed"], mastery: "push", rangeNormal: 100, rangeLong: 400, ammunitionType: "bolts"),
    EquipmentEntry(id: "weapon-longbow", name: "Langbogen", englishName: "Longbow", category: EquipmentCategory.martialRanged, priceCp: 5000, weightLb: 2.0, damage: "1d8", damageType: "Stich", properties: ["ammunition", "heavy", "two-handed"], mastery: "slow", rangeNormal: 150, rangeLong: 600, ammunitionType: "arrows"),
    EquipmentEntry(id: "weapon-musket", name: "Muskete", englishName: "Musket", category: EquipmentCategory.martialRanged, priceCp: 50000, weightLb: 10.0, damage: "1d12", damageType: "Stich", properties: ["ammunition", "loading", "two-handed"], mastery: "slow", rangeNormal: 40, rangeLong: 120, ammunitionType: "firearm bullets"),
    EquipmentEntry(id: "weapon-pistol", name: "Pistole", englishName: "Pistol", category: EquipmentCategory.martialRanged, priceCp: 25000, weightLb: 3.0, damage: "1d10", damageType: "Stich", properties: ["ammunition", "loading"], mastery: "vex", rangeNormal: 30, rangeLong: 90, ammunitionType: "firearm bullets"),
    EquipmentEntry(id: "armor-padded-armor", name: "Wattierte Rüstung", englishName: "Padded Armor", category: EquipmentCategory.lightArmor, priceCp: 500, weightLb: 8.0, armorBaseAc: 11, stealthDisadvantage: true),
    EquipmentEntry(id: "armor-leather-armor", name: "Lederrüstung", englishName: "Leather Armor", category: EquipmentCategory.lightArmor, priceCp: 1000, weightLb: 10.0, armorBaseAc: 11, stealthDisadvantage: false),
    EquipmentEntry(id: "armor-studded-leather-armor", name: "Beschlagene Lederrüstung", englishName: "Studded Leather Armor", category: EquipmentCategory.lightArmor, priceCp: 4500, weightLb: 13.0, armorBaseAc: 12, stealthDisadvantage: false),
    EquipmentEntry(id: "armor-hide-armor", name: "Fellrüstung", englishName: "Hide Armor", category: EquipmentCategory.mediumArmor, priceCp: 1000, weightLb: 12.0, armorBaseAc: 12, dexCap: 2, stealthDisadvantage: false),
    EquipmentEntry(id: "armor-chain-shirt", name: "Kettenhemd", englishName: "Chain Shirt", category: EquipmentCategory.mediumArmor, priceCp: 5000, weightLb: 20.0, armorBaseAc: 13, dexCap: 2, stealthDisadvantage: false),
    EquipmentEntry(id: "armor-scale-mail", name: "Schuppenpanzer", englishName: "Scale Mail", category: EquipmentCategory.mediumArmor, priceCp: 5000, weightLb: 45.0, armorBaseAc: 14, dexCap: 2, stealthDisadvantage: true),
    EquipmentEntry(id: "armor-breastplate", name: "Brustplatte", englishName: "Breastplate", category: EquipmentCategory.mediumArmor, priceCp: 40000, weightLb: 20.0, armorBaseAc: 14, dexCap: 2, stealthDisadvantage: false),
    EquipmentEntry(id: "armor-half-plate-armor", name: "Halbe Plattenrüstung", englishName: "Half Plate Armor", category: EquipmentCategory.mediumArmor, priceCp: 75000, weightLb: 40.0, armorBaseAc: 15, dexCap: 2, stealthDisadvantage: true),
    EquipmentEntry(id: "armor-ring-mail", name: "Ringpanzer", englishName: "Ring Mail", category: EquipmentCategory.heavyArmor, priceCp: 3000, weightLb: 40.0, armorBaseAc: 14, dexCap: 0, stealthDisadvantage: true),
    EquipmentEntry(id: "armor-chain-mail", name: "Kettenpanzer", englishName: "Chain Mail", category: EquipmentCategory.heavyArmor, priceCp: 7500, weightLb: 55.0, armorBaseAc: 16, dexCap: 0, strengthMin: 13, stealthDisadvantage: true),
    EquipmentEntry(id: "armor-splint-armor", name: "Schienenpanzer", englishName: "Splint Armor", category: EquipmentCategory.heavyArmor, priceCp: 20000, weightLb: 60.0, armorBaseAc: 17, dexCap: 0, strengthMin: 15, stealthDisadvantage: true),
    EquipmentEntry(id: "armor-plate-armor", name: "Plattenrüstung", englishName: "Plate Armor", category: EquipmentCategory.heavyArmor, priceCp: 150000, weightLb: 65.0, armorBaseAc: 18, dexCap: 0, strengthMin: 15, stealthDisadvantage: true),
    EquipmentEntry(id: "armor-shield", name: "Schild", englishName: "Shield", category: EquipmentCategory.shield, priceCp: 1000, weightLb: 6.0, armorBaseAc: 2, dexCap: 0, stealthDisadvantage: false),
    EquipmentEntry(id: "item-acid", name: "Säurefläschchen", englishName: "Acid", category: EquipmentCategory.gear, priceCp: 2500, weightLb: 1.0),
    EquipmentEntry(id: "item-alchemist-s-fire", name: "Alchemistenfeuer", englishName: "Alchemist's Fire", category: EquipmentCategory.gear, priceCp: 5000, weightLb: 1.0),
    EquipmentEntry(id: "item-antitoxin", name: "Gegengift", englishName: "Antitoxin", category: EquipmentCategory.gear, priceCp: 5000),
    EquipmentEntry(id: "item-backpack", name: "Rucksack", englishName: "Backpack", category: EquipmentCategory.gear, priceCp: 200, weightLb: 5.0),
    EquipmentEntry(id: "item-ball-bearings", name: "Kugellagerkugeln", englishName: "Ball Bearings", category: EquipmentCategory.gear, priceCp: 100, weightLb: 2.0),
    EquipmentEntry(id: "item-barrel", name: "Fass", englishName: "Barrel", category: EquipmentCategory.gear, priceCp: 200, weightLb: 70.0),
    EquipmentEntry(id: "item-basket", name: "Korb", englishName: "Basket", category: EquipmentCategory.gear, priceCp: 40, weightLb: 2.0),
    EquipmentEntry(id: "item-bedroll", name: "Schlafsack", englishName: "Bedroll", category: EquipmentCategory.gear, priceCp: 100, weightLb: 7.0),
    EquipmentEntry(id: "item-bell", name: "Glocke", englishName: "Bell", category: EquipmentCategory.gear, priceCp: 100),
    EquipmentEntry(id: "item-blanket", name: "Decke", englishName: "Blanket", category: EquipmentCategory.gear, priceCp: 50, weightLb: 3.0),
    EquipmentEntry(id: "item-block-and-tackle", name: "Flaschenzug", englishName: "Block and Tackle", category: EquipmentCategory.gear, priceCp: 100, weightLb: 5.0),
    EquipmentEntry(id: "item-book", name: "Buch", englishName: "Book", category: EquipmentCategory.gear, priceCp: 2500, weightLb: 5.0),
    EquipmentEntry(id: "item-bottle-glass", name: "Glasflasche", englishName: "Bottle, Glass", category: EquipmentCategory.gear, priceCp: 200, weightLb: 2.0),
    EquipmentEntry(id: "item-bucket", name: "Eimer", englishName: "Bucket", category: EquipmentCategory.gear, priceCp: 5, weightLb: 2.0),
    EquipmentEntry(id: "item-burglar-s-pack", name: "Einbrecherausrüstung", englishName: "Burglar's Pack", category: EquipmentCategory.pack, priceCp: 1600, weightLb: 42.0),
    EquipmentEntry(id: "item-caltrops", name: "Krähenfüße", englishName: "Caltrops", category: EquipmentCategory.gear, priceCp: 100, weightLb: 2.0),
    EquipmentEntry(id: "item-candle", name: "Kerze", englishName: "Candle", category: EquipmentCategory.gear, priceCp: 1),
    EquipmentEntry(id: "item-case-crossbow-bolt", name: "Bolzenbehälter", englishName: "Case, Crossbow Bolt", category: EquipmentCategory.gear, priceCp: 100, weightLb: 1.0),
    EquipmentEntry(id: "item-case-map-or-scroll", name: "Karten-/Schriftrollenbehälter", englishName: "Case, Map or Scroll", category: EquipmentCategory.gear, priceCp: 100, weightLb: 1.0),
    EquipmentEntry(id: "item-chain", name: "Kette", englishName: "Chain", category: EquipmentCategory.gear, priceCp: 500, weightLb: 10.0),
    EquipmentEntry(id: "item-chest", name: "Truhe", englishName: "Chest", category: EquipmentCategory.gear, priceCp: 500, weightLb: 25.0),
    EquipmentEntry(id: "item-climber-s-kit", name: "Kletterausrüstung", englishName: "Climber's Kit", category: EquipmentCategory.gear, priceCp: 2500, weightLb: 12.0),
    EquipmentEntry(id: "item-clothes-fine", name: "Feine Kleidung", englishName: "Clothes, Fine", category: EquipmentCategory.gear, priceCp: 1500, weightLb: 6.0),
    EquipmentEntry(id: "item-clothes-traveler-s", name: "Reisekleidung", englishName: "Clothes, Traveler's", category: EquipmentCategory.gear, priceCp: 200, weightLb: 4.0),
    EquipmentEntry(id: "item-component-pouch", name: "Komponentenbeutel", englishName: "Component Pouch", category: EquipmentCategory.gear, priceCp: 2500, weightLb: 2.0),
    EquipmentEntry(id: "item-costume", name: "Kostüm", englishName: "Costume", category: EquipmentCategory.gear, priceCp: 500, weightLb: 4.0),
    EquipmentEntry(id: "item-crowbar", name: "Brecheisen", englishName: "Crowbar", category: EquipmentCategory.gear, priceCp: 200, weightLb: 5.0),
    EquipmentEntry(id: "item-diplomat-s-pack", name: "Diplomatenausrüstung", englishName: "Diplomat's Pack", category: EquipmentCategory.pack, priceCp: 3900, weightLb: 39.0),
    EquipmentEntry(id: "item-dungeoneer-s-pack", name: "Gewölbeforscherausrüstung", englishName: "Dungeoneer's Pack", category: EquipmentCategory.pack, priceCp: 1200, weightLb: 55.0),
    EquipmentEntry(id: "item-entertainer-s-pack", name: "Unterhalterausrüstung", englishName: "Entertainer's Pack", category: EquipmentCategory.pack, priceCp: 4000, weightLb: 58.5),
    EquipmentEntry(id: "item-explorer-s-pack", name: "Entdeckerausrüstung", englishName: "Explorer's Pack", category: EquipmentCategory.pack, priceCp: 1000, weightLb: 55.0),
    EquipmentEntry(id: "item-flask", name: "Feldflasche", englishName: "Flask", category: EquipmentCategory.gear, priceCp: 2, weightLb: 1.0),
    EquipmentEntry(id: "item-grappling-hook", name: "Wurfhaken", englishName: "Grappling Hook", category: EquipmentCategory.gear, priceCp: 200, weightLb: 4.0),
    EquipmentEntry(id: "item-healer-s-kit", name: "Heilerausrüstung", englishName: "Healer's Kit", category: EquipmentCategory.gear, priceCp: 500, weightLb: 3.0),
    EquipmentEntry(id: "item-holy-water", name: "Weihwasser", englishName: "Holy Water", category: EquipmentCategory.gear, priceCp: 2500, weightLb: 1.0),
    EquipmentEntry(id: "item-hunting-trap", name: "Jagdfalle", englishName: "Hunting Trap", category: EquipmentCategory.gear, priceCp: 500, weightLb: 25.0),
    EquipmentEntry(id: "item-ink", name: "Tinte", englishName: "Ink", category: EquipmentCategory.gear, priceCp: 1000),
    EquipmentEntry(id: "item-ink-pen", name: "Schreibfeder", englishName: "Ink Pen", category: EquipmentCategory.gear, priceCp: 2),
    EquipmentEntry(id: "item-jug", name: "Krug", englishName: "Jug", category: EquipmentCategory.gear, priceCp: 2, weightLb: 4.0),
    EquipmentEntry(id: "item-ladder", name: "Leiter", englishName: "Ladder", category: EquipmentCategory.gear, priceCp: 10, weightLb: 25.0),
    EquipmentEntry(id: "item-lamp", name: "Öllampe", englishName: "Lamp", category: EquipmentCategory.gear, priceCp: 50, weightLb: 1.0),
    EquipmentEntry(id: "item-lantern-bullseye", name: "Blendlaterne", englishName: "Lantern, Bullseye", category: EquipmentCategory.gear, priceCp: 1000, weightLb: 2.0),
    EquipmentEntry(id: "item-lantern-hooded", name: "Abdeckbare Laterne", englishName: "Lantern, Hooded", category: EquipmentCategory.gear, priceCp: 500, weightLb: 2.0),
    EquipmentEntry(id: "item-lock", name: "Schloss", englishName: "Lock", category: EquipmentCategory.gear, priceCp: 1000, weightLb: 1.0),
    EquipmentEntry(id: "item-magnifying-glass", name: "Lupe", englishName: "Magnifying Glass", category: EquipmentCategory.gear, priceCp: 10000),
    EquipmentEntry(id: "item-manacles", name: "Fesseln", englishName: "Manacles", category: EquipmentCategory.gear, priceCp: 200, weightLb: 6.0),
    EquipmentEntry(id: "item-map", name: "Karte", englishName: "Map", category: EquipmentCategory.gear, priceCp: 100),
    EquipmentEntry(id: "item-mirror", name: "Spiegel", englishName: "Mirror", category: EquipmentCategory.gear, priceCp: 500, weightLb: 0.5),
    EquipmentEntry(id: "item-net", name: "Netz", englishName: "Net", category: EquipmentCategory.gear, priceCp: 100, weightLb: 3.0),
    EquipmentEntry(id: "item-oil", name: "Öl", englishName: "Oil", category: EquipmentCategory.gear, priceCp: 10, weightLb: 1.0),
    EquipmentEntry(id: "item-paper", name: "Papier", englishName: "Paper", category: EquipmentCategory.gear, priceCp: 20),
    EquipmentEntry(id: "item-parchment", name: "Pergament", englishName: "Parchment", category: EquipmentCategory.gear, priceCp: 10),
    EquipmentEntry(id: "item-perfume", name: "Parfüm", englishName: "Perfume", category: EquipmentCategory.gear, priceCp: 500),
    EquipmentEntry(id: "item-poison-basic", name: "Einfaches Gift", englishName: "Poison, Basic", category: EquipmentCategory.gear, priceCp: 10000),
    EquipmentEntry(id: "item-pole", name: "Stange", englishName: "Pole", category: EquipmentCategory.gear, priceCp: 5, weightLb: 7.0),
    EquipmentEntry(id: "item-pot-iron", name: "Eisentopf", englishName: "Pot, Iron", category: EquipmentCategory.gear, priceCp: 200, weightLb: 10.0),
    EquipmentEntry(id: "item-potion-of-healing", name: "Heiltrank", englishName: "Potion of Healing", category: EquipmentCategory.gear, priceCp: 5000, weightLb: 0.5),
    EquipmentEntry(id: "item-pouch", name: "Beutel", englishName: "Pouch", category: EquipmentCategory.gear, priceCp: 50, weightLb: 1.0),
    EquipmentEntry(id: "item-priest-s-pack", name: "Priesterausrüstung", englishName: "Priest's Pack", category: EquipmentCategory.pack, priceCp: 3300, weightLb: 29.0),
    EquipmentEntry(id: "item-quiver", name: "Köcher", englishName: "Quiver", category: EquipmentCategory.gear, priceCp: 100, weightLb: 1.0),
    EquipmentEntry(id: "item-ram-portable", name: "Tragbarer Rammbock", englishName: "Ram, Portable", category: EquipmentCategory.gear, priceCp: 400, weightLb: 35.0),
    EquipmentEntry(id: "item-rations", name: "Reiseproviant", englishName: "Rations", category: EquipmentCategory.gear, priceCp: 50, weightLb: 2.0),
    EquipmentEntry(id: "item-robe", name: "Robe", englishName: "Robe", category: EquipmentCategory.gear, priceCp: 100, weightLb: 4.0),
    EquipmentEntry(id: "item-rope", name: "Seil", englishName: "Rope", category: EquipmentCategory.gear, priceCp: 100, weightLb: 5.0),
    EquipmentEntry(id: "item-sack", name: "Sack", englishName: "Sack", category: EquipmentCategory.gear, priceCp: 1, weightLb: 0.5),
    EquipmentEntry(id: "item-scholar-s-pack", name: "Gelehrtenausrüstung", englishName: "Scholar's Pack", category: EquipmentCategory.pack, priceCp: 4000, weightLb: 22.0),
    EquipmentEntry(id: "item-shovel", name: "Schaufel", englishName: "Shovel", category: EquipmentCategory.gear, priceCp: 200, weightLb: 5.0),
    EquipmentEntry(id: "item-signal-whistle", name: "Signalpfeife", englishName: "Signal Whistle", category: EquipmentCategory.gear, priceCp: 5),
    EquipmentEntry(id: "item-spell-scroll-cantrip", name: "Zauberschriftrolle (Zaubertrick)", englishName: "Spell Scroll (Cantrip)", category: EquipmentCategory.gear, priceCp: 3000),
    EquipmentEntry(id: "item-spell-scroll-level-1", name: "Zauberschriftrolle (Grad 1)", englishName: "Spell Scroll (Level 1)", category: EquipmentCategory.gear, priceCp: 5000),
    EquipmentEntry(id: "item-spikes-iron", name: "Eisennägel", englishName: "Spikes, Iron", category: EquipmentCategory.gear, priceCp: 100, weightLb: 5.0),
    EquipmentEntry(id: "item-spyglass", name: "Fernrohr", englishName: "Spyglass", category: EquipmentCategory.gear, priceCp: 100000, weightLb: 1.0),
    EquipmentEntry(id: "item-string", name: "Schnur", englishName: "String", category: EquipmentCategory.gear, priceCp: 10),
    EquipmentEntry(id: "item-tent", name: "Zelt", englishName: "Tent", category: EquipmentCategory.gear, priceCp: 200, weightLb: 20.0),
    EquipmentEntry(id: "item-tinderbox", name: "Zunderkästchen", englishName: "Tinderbox", category: EquipmentCategory.gear, priceCp: 50, weightLb: 1.0),
    EquipmentEntry(id: "item-torch", name: "Fackel", englishName: "Torch", category: EquipmentCategory.gear, priceCp: 1, weightLb: 1.0),
    EquipmentEntry(id: "item-vial", name: "Phiole", englishName: "Vial", category: EquipmentCategory.gear, priceCp: 100),
    EquipmentEntry(id: "item-waterskin", name: "Wasserschlauch", englishName: "Waterskin", category: EquipmentCategory.gear, priceCp: 20, weightLb: 5.0),
    EquipmentEntry(id: "item-arrows-20", name: "Pfeile (20 Stück)", englishName: "Arrows (20)", category: EquipmentCategory.ammunition, priceCp: 100, weightLb: 1.0),
    EquipmentEntry(id: "item-bolts-20", name: "Armbrustbolzen (20 Stück)", englishName: "Bolts (20)", category: EquipmentCategory.ammunition, priceCp: 100, weightLb: 1.5),
    EquipmentEntry(id: "item-bullets-firearm-10", name: "Schusswaffenkugeln (10 Stück)", englishName: "Bullets, Firearm (10)", category: EquipmentCategory.ammunition, priceCp: 300, weightLb: 2.0),
    EquipmentEntry(id: "item-bullets-sling-20", name: "Schleuderkugeln (20 Stück)", englishName: "Bullets, Sling (20)", category: EquipmentCategory.ammunition, priceCp: 4, weightLb: 1.5),
    EquipmentEntry(id: "item-needles-50", name: "Blasrohrnadeln (50 Stück)", englishName: "Needles (50)", category: EquipmentCategory.ammunition, priceCp: 100, weightLb: 1.0),
    EquipmentEntry(id: "item-arcane-focus-crystal", name: "Arkaner Fokus: Kristall", englishName: "Arcane Focus, Crystal", category: EquipmentCategory.focus, priceCp: 1000, weightLb: 1.0),
    EquipmentEntry(id: "item-arcane-focus-orb", name: "Arkaner Fokus: Kugel", englishName: "Arcane Focus, Orb", category: EquipmentCategory.focus, priceCp: 2000, weightLb: 3.0),
    EquipmentEntry(id: "item-arcane-focus-rod", name: "Arkaner Fokus: Stab", englishName: "Arcane Focus, Rod", category: EquipmentCategory.focus, priceCp: 1000, weightLb: 2.0),
    EquipmentEntry(id: "item-arcane-focus-staff", name: "Arkaner Fokus: Kampfstab", englishName: "Arcane Focus, Staff", category: EquipmentCategory.focus, priceCp: 500, weightLb: 4.0),
    EquipmentEntry(id: "item-arcane-focus-wand", name: "Arkaner Fokus: Zauberstab", englishName: "Arcane Focus, Wand", category: EquipmentCategory.focus, priceCp: 1000, weightLb: 1.0),
    EquipmentEntry(id: "item-alchemist-s-supplies", name: "Alchemistenausrüstung", englishName: "Alchemist's Supplies", category: EquipmentCategory.tool, priceCp: 5000, weightLb: 8.0),
    EquipmentEntry(id: "item-brewer-s-supplies", name: "Brauausrüstung", englishName: "Brewer's Supplies", category: EquipmentCategory.tool, priceCp: 2000, weightLb: 9.0),
    EquipmentEntry(id: "item-calligrapher-s-supplies", name: "Kalligrafenwerkzeug", englishName: "Calligrapher's Supplies", category: EquipmentCategory.tool, priceCp: 1000, weightLb: 5.0),
    EquipmentEntry(id: "item-carpenter-s-tools", name: "Zimmermannswerkzeug", englishName: "Carpenter's Tools", category: EquipmentCategory.tool, priceCp: 800, weightLb: 6.0),
    EquipmentEntry(id: "item-cartographer-s-tools", name: "Kartografenwerkzeug", englishName: "Cartographer's Tools", category: EquipmentCategory.tool, priceCp: 1500, weightLb: 6.0),
    EquipmentEntry(id: "item-cobbler-s-tools", name: "Schusterwerkzeug", englishName: "Cobbler's Tools", category: EquipmentCategory.tool, priceCp: 500, weightLb: 5.0),
    EquipmentEntry(id: "item-cook-s-utensils", name: "Kochutensilien", englishName: "Cook's Utensils", category: EquipmentCategory.tool, priceCp: 100, weightLb: 8.0),
    EquipmentEntry(id: "item-glassblower-s-tools", name: "Glasbläserwerkzeug", englishName: "Glassblower's Tools", category: EquipmentCategory.tool, priceCp: 3000, weightLb: 5.0),
    EquipmentEntry(id: "item-jeweler-s-tools", name: "Juwelierwerkzeug", englishName: "Jeweler's Tools", category: EquipmentCategory.tool, priceCp: 2500, weightLb: 2.0),
    EquipmentEntry(id: "item-leatherworker-s-tools", name: "Lederbearbeitungswerkzeug", englishName: "Leatherworker's Tools", category: EquipmentCategory.tool, priceCp: 500, weightLb: 5.0),
    EquipmentEntry(id: "item-mason-s-tools", name: "Steinmetzwerkzeug", englishName: "Mason's Tools", category: EquipmentCategory.tool, priceCp: 1000, weightLb: 8.0),
    EquipmentEntry(id: "item-painter-s-supplies", name: "Malutensilien", englishName: "Painter's Supplies", category: EquipmentCategory.tool, priceCp: 1000, weightLb: 5.0),
    EquipmentEntry(id: "item-potter-s-tools", name: "Töpferwerkzeug", englishName: "Potter's Tools", category: EquipmentCategory.tool, priceCp: 1000, weightLb: 3.0),
    EquipmentEntry(id: "item-smith-s-tools", name: "Schmiedewerkzeug", englishName: "Smith's Tools", category: EquipmentCategory.tool, priceCp: 2000, weightLb: 8.0),
    EquipmentEntry(id: "item-tinker-s-tools", name: "Tüftlerwerkzeug", englishName: "Tinker's Tools", category: EquipmentCategory.tool, priceCp: 5000, weightLb: 10.0),
    EquipmentEntry(id: "item-weaver-s-tools", name: "Weberwerkzeug", englishName: "Weaver's Tools", category: EquipmentCategory.tool, priceCp: 100, weightLb: 5.0),
    EquipmentEntry(id: "item-woodcarver-s-tools", name: "Holzschnitzwerkzeug", englishName: "Woodcarver's Tools", category: EquipmentCategory.tool, priceCp: 100, weightLb: 5.0),
    EquipmentEntry(id: "item-disguise-kit", name: "Verkleidungsset", englishName: "Disguise Kit", category: EquipmentCategory.tool, priceCp: 2500, weightLb: 3.0),
    EquipmentEntry(id: "item-forgery-kit", name: "Fälscherwerkzeug", englishName: "Forgery Kit", category: EquipmentCategory.tool, priceCp: 1500, weightLb: 5.0),
    EquipmentEntry(id: "item-herbalism-kit", name: "Kräuterkundeausrüstung", englishName: "Herbalism Kit", category: EquipmentCategory.tool, priceCp: 500, weightLb: 3.0),
    EquipmentEntry(id: "item-navigator-s-tools", name: "Navigatorenwerkzeug", englishName: "Navigator's Tools", category: EquipmentCategory.tool, priceCp: 2500, weightLb: 2.0),
    EquipmentEntry(id: "item-poisoner-s-kit", name: "Giftmischerausrüstung", englishName: "Poisoner's Kit", category: EquipmentCategory.tool, priceCp: 5000, weightLb: 2.0),
    EquipmentEntry(id: "item-thieves-tools", name: "Diebeswerkzeug", englishName: "Thieves' Tools", category: EquipmentCategory.tool, priceCp: 2500, weightLb: 1.0),
    EquipmentEntry(id: "item-dice-set", name: "Würfelspiel", englishName: "Dice Set", category: EquipmentCategory.game, priceCp: 10),
    EquipmentEntry(id: "item-dragonchess-set", name: "Drachenschach", englishName: "Dragonchess Set", category: EquipmentCategory.game, priceCp: 100),
    EquipmentEntry(id: "item-playing-cards", name: "Spielkarten", englishName: "Playing Cards", category: EquipmentCategory.game, priceCp: 50),
    EquipmentEntry(id: "item-three-dragon-ante-set", name: "Drei-Drachen-Ante", englishName: "Three-Dragon Ante Set", category: EquipmentCategory.game, priceCp: 100),
    EquipmentEntry(id: "item-bagpipes", name: "Dudelsack", englishName: "Bagpipes", category: EquipmentCategory.instrument, priceCp: 3000, weightLb: 6.0),
    EquipmentEntry(id: "item-drum", name: "Trommel", englishName: "Drum", category: EquipmentCategory.instrument, priceCp: 600, weightLb: 3.0),
    EquipmentEntry(id: "item-dulcimer", name: "Hackbrett", englishName: "Dulcimer", category: EquipmentCategory.instrument, priceCp: 2500, weightLb: 10.0),
    EquipmentEntry(id: "item-flute", name: "Flöte", englishName: "Flute", category: EquipmentCategory.instrument, priceCp: 200, weightLb: 1.0),
    EquipmentEntry(id: "item-horn", name: "Horn", englishName: "Horn", category: EquipmentCategory.instrument, priceCp: 300, weightLb: 2.0),
    EquipmentEntry(id: "item-lute", name: "Laute", englishName: "Lute", category: EquipmentCategory.instrument, priceCp: 3500, weightLb: 2.0),
    EquipmentEntry(id: "item-lyre", name: "Leier", englishName: "Lyre", category: EquipmentCategory.instrument, priceCp: 3000, weightLb: 2.0),
    EquipmentEntry(id: "item-pan-flute", name: "Panflöte", englishName: "Pan Flute", category: EquipmentCategory.instrument, priceCp: 1200, weightLb: 2.0),
    EquipmentEntry(id: "item-shawm", name: "Schalmei", englishName: "Shawm", category: EquipmentCategory.instrument, priceCp: 200, weightLb: 1.0),
    EquipmentEntry(id: "item-viol", name: "Gambe", englishName: "Viol", category: EquipmentCategory.instrument, priceCp: 3000, weightLb: 1.0),
    EquipmentEntry(id: "item-camel", name: "Kamel", englishName: "Camel", category: EquipmentCategory.mount, priceCp: 5000),
    EquipmentEntry(id: "item-elephant", name: "Elefant", englishName: "Elephant", category: EquipmentCategory.mount, priceCp: 20000),
    EquipmentEntry(id: "item-draft-horse", name: "Zugpferd", englishName: "Draft Horse", category: EquipmentCategory.mount, priceCp: 5000),
    EquipmentEntry(id: "item-riding-horse", name: "Reitpferd", englishName: "Riding Horse", category: EquipmentCategory.mount, priceCp: 7500),
    EquipmentEntry(id: "item-mastiff", name: "Dogge", englishName: "Mastiff", category: EquipmentCategory.mount, priceCp: 2500),
    EquipmentEntry(id: "item-mule", name: "Maultier", englishName: "Mule", category: EquipmentCategory.mount, priceCp: 800),
    EquipmentEntry(id: "item-pony", name: "Pony", englishName: "Pony", category: EquipmentCategory.mount, priceCp: 3000),
    EquipmentEntry(id: "item-warhorse", name: "Schlachtross", englishName: "Warhorse", category: EquipmentCategory.mount, priceCp: 40000),
    EquipmentEntry(id: "item-carriage", name: "Kutsche", englishName: "Carriage", category: EquipmentCategory.vehicle, priceCp: 10000, weightLb: 600.0),
    EquipmentEntry(id: "item-cart", name: "Karren", englishName: "Cart", category: EquipmentCategory.vehicle, priceCp: 1500, weightLb: 200.0),
    EquipmentEntry(id: "item-chariot", name: "Streitwagen", englishName: "Chariot", category: EquipmentCategory.vehicle, priceCp: 25000, weightLb: 100.0),
    EquipmentEntry(id: "item-sled", name: "Schlitten", englishName: "Sled", category: EquipmentCategory.vehicle, priceCp: 2000, weightLb: 300.0),
    EquipmentEntry(id: "item-wagon", name: "Wagen", englishName: "Wagon", category: EquipmentCategory.vehicle, priceCp: 3500, weightLb: 400.0),
    EquipmentEntry(id: "item-feed-per-day", name: "Tierfutter (1 Tag)", englishName: "Feed, per Day", category: EquipmentCategory.gear, priceCp: 5, weightLb: 10.0),
    EquipmentEntry(id: "item-saddle-exotic", name: "Exotischer Sattel", englishName: "Saddle, Exotic", category: EquipmentCategory.gear, priceCp: 6000, weightLb: 40.0),
    EquipmentEntry(id: "item-saddle-military", name: "Militärsattel", englishName: "Saddle, Military", category: EquipmentCategory.gear, priceCp: 2000, weightLb: 30.0),
    EquipmentEntry(id: "item-saddle-riding", name: "Reitsattel", englishName: "Saddle, Riding", category: EquipmentCategory.gear, priceCp: 1000, weightLb: 25.0),
    EquipmentEntry(id: "magic-bead-of-nourishment", name: "Perle der Nahrung", englishName: "Bead of Nourishment", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-cloak-of-invisibility", name: "Umhang der Unsichtbarkeit", englishName: "Cloak of Invisibility", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-elixir-of-health", name: "Elixier der Gesundheit", englishName: "Elixir of Health", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-energy-bow", name: "Energiebogen", englishName: "Energy Bow", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-gloves-of-thievery", name: "Handschuhe des Diebstahls", englishName: "Gloves of Thievery", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-hat-of-many-spells", name: "Hut der vielen Zauber", englishName: "Hat of Many Spells", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-potion-of-invulnerability", name: "Trank der Unverwundbarkeit", englishName: "Potion of Invulnerability", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-potion-of-longevity", name: "Trank der Langlebigkeit", englishName: "Potion of Longevity", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-potion-of-vitality", name: "Trank der Lebenskraft", englishName: "Potion of Vitality", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-quarterstaff-of-the-acrobat", name: "Kampfstab des Akrobaten", englishName: "Quarterstaff of the Acrobat", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-rod-of-resurrection", name: "Stab der Auferstehung", englishName: "Rod of Resurrection", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-sending-stones", name: "Nachrichtensteine", englishName: "Sending Stones", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-sentinel-shield", name: "Wächterschild", englishName: "Sentinel Shield", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-shield-of-the-cavalier", name: "Schild des Kavalleristen", englishName: "Shield of the Cavalier", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-thunderous-greatclub", name: "Donnernder Großknüppel", englishName: "Thunderous Greatclub", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-bag-of-holding", name: "Nimmervoller Beutel", englishName: "Bag of Holding", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-boots-of-elvenkind", name: "Elfenstiefel", englishName: "Boots of Elvenkind", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-cloak-of-elvenkind", name: "Elfenumhang", englishName: "Cloak of Elvenkind", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-cloak-of-protection", name: "Schutzumhang", englishName: "Cloak of Protection", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-ring-of-protection", name: "Schutzring", englishName: "Ring of Protection", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-ring-of-spell-storing", name: "Ring des Zauberspeicherns", englishName: "Ring of Spell Storing", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-ring-of-evasion", name: "Ring des Entrinnens", englishName: "Ring of Evasion", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-ring-of-invisibility", name: "Ring der Unsichtbarkeit", englishName: "Ring of Invisibility", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-ring-of-regeneration", name: "Ring der Regeneration", englishName: "Ring of Regeneration", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-ring-of-telekinesis", name: "Ring der Telekinese", englishName: "Ring of Telekinesis", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-wand-of-magic-missiles", name: "Zauberstab der magischen Geschosse", englishName: "Wand of Magic Missiles", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-wand-of-fireballs", name: "Zauberstab der Feuerbälle", englishName: "Wand of Fireballs", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-wand-of-lightning-bolts", name: "Zauberstab der Blitze", englishName: "Wand of Lightning Bolts", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-wand-of-secrets", name: "Zauberstab der Geheimnisse", englishName: "Wand of Secrets", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-wand-of-the-war-mage", name: "Zauberstab des Kriegsmagiers", englishName: "Wand of the War Mage", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-staff-of-healing", name: "Stab der Heilung", englishName: "Staff of Healing", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-staff-of-power", name: "Stab der Macht", englishName: "Staff of Power", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-staff-of-the-magi", name: "Stab der Magier", englishName: "Staff of the Magi", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-staff-of-frost", name: "Stab des Frostes", englishName: "Staff of Frost", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-staff-of-fire", name: "Stab des Feuers", englishName: "Staff of Fire", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-potion-of-climbing", name: "Klettertrank", englishName: "Potion of Climbing", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-potion-of-flying", name: "Flugtrank", englishName: "Potion of Flying", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-potion-of-gaseous-form", name: "Trank der Gasgestalt", englishName: "Potion of Gaseous Form", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-potion-of-heroism", name: "Trank des Heldentums", englishName: "Potion of Heroism", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-potion-of-invisibility", name: "Unsichtbarkeitstrank", englishName: "Potion of Invisibility", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-potion-of-speed", name: "Trank der Schnelligkeit", englishName: "Potion of Speed", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-potion-of-water-breathing", name: "Trank der Wasseratmung", englishName: "Potion of Water Breathing", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-potion-of-resistance", name: "Trank der Resistenz", englishName: "Potion of Resistance", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-potion-of-superior-healing", name: "Trank der überlegenen Heilung", englishName: "Potion of Superior Healing", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-potion-of-greater-healing", name: "Trank der großen Heilung", englishName: "Potion of Greater Healing", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-potion-of-supreme-healing", name: "Trank der höchsten Heilung", englishName: "Potion of Supreme Healing", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-amulet-of-health", name: "Amulett der Gesundheit", englishName: "Amulet of Health", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-amulet-of-proof-against-detection-and-location", name: "Amulett gegen Ortung und Ausspähung", englishName: "Amulet of Proof against Detection and Location", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-belt-of-giant-strength", name: "Gürtel der Riesenstärke", englishName: "Belt of Giant Strength", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-boots-of-levitation", name: "Stiefel des Schwebens", englishName: "Boots of Levitation", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-boots-of-speed", name: "Stiefel der Schnelligkeit", englishName: "Boots of Speed", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-boots-of-striding-and-springing", name: "Stiefel des Schreitens und Springens", englishName: "Boots of Striding and Springing", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-bracers-of-defense", name: "Armschienen der Verteidigung", englishName: "Bracers of Defense", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-broom-of-flying", name: "Fliegender Besen", englishName: "Broom of Flying", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-cape-of-the-mountebank", name: "Umhang des Taschenspielers", englishName: "Cape of the Mountebank", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-decanter-of-endless-water", name: "Karaffe des endlosen Wassers", englishName: "Decanter of Endless Water", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-dust-of-disappearance", name: "Staub des Verschwindens", englishName: "Dust of Disappearance", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-dust-of-dryness", name: "Staub der Trockenheit", englishName: "Dust of Dryness", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-elemental-gem", name: "Elementaredelstein", englishName: "Elemental Gem", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-gauntlets-of-ogre-power", name: "Handschuhe der Ogerkraft", englishName: "Gauntlets of Ogre Power", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-gem-of-seeing", name: "Edelstein des Sehens", englishName: "Gem of Seeing", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-hat-of-disguise", name: "Hut der Verkleidung", englishName: "Hat of Disguise", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-headband-of-intellect", name: "Stirnband des Verstandes", englishName: "Headband of Intellect", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-helm-of-telepathy", name: "Helm der Telepathie", englishName: "Helm of Telepathy", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-immovable-rod", name: "Unbeweglicher Stab", englishName: "Immovable Rod", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-instrument-of-the-bards", name: "Instrument der Barden", englishName: "Instrument of the Bards", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-lantern-of-revealing", name: "Laterne der Enthüllung", englishName: "Lantern of Revealing", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-manual-of-gainful-exercise", name: "Handbuch körperlicher Ertüchtigung", englishName: "Manual of Gainful Exercise", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-necklace-of-fireballs", name: "Halskette der Feuerbälle", englishName: "Necklace of Fireballs", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-pearl-of-power", name: "Perle der Macht", englishName: "Pearl of Power", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-periapt-of-wound-closure", name: "Amulett der Wundschließung", englishName: "Periapt of Wound Closure", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-robe-of-eyes", name: "Robe der Augen", englishName: "Robe of Eyes", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-robe-of-the-archmagi", name: "Robe des Erzmagiers", englishName: "Robe of the Archmagi", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-rope-of-climbing", name: "Kletterseil", englishName: "Rope of Climbing", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-stone-of-good-luck", name: "Glücksstein", englishName: "Stone of Good Luck", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-sword-of-sharpness", name: "Schwert der Schärfe", englishName: "Sword of Sharpness", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-sword-of-wounding", name: "Schwert der Verwundung", englishName: "Sword of Wounding", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-vorpal-sword", name: "Vorpalschwert", englishName: "Vorpal Sword", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
    EquipmentEntry(id: "magic-winged-boots", name: "Geflügelte Stiefel", englishName: "Winged Boots", category: EquipmentCategory.magic, note: "Magischer Gegenstand: Wirkung und Anforderungen vor Nutzung anhand des SRD prüfen. Keine automatische Regeländerung."),
  ];

  static EquipmentEntry? byId(String id) {
    for (final item in all) {
      if (item.id == id) return item;
    }
    return null;
  }

  static List<EquipmentEntry> search(String query, {EquipmentCategory? category}) {
    final text = query.trim().toLowerCase();
    return all.where((item) =>
      (category == null || item.category == category) &&
      (text.isEmpty || item.name.toLowerCase().contains(text) ||
        item.englishName.toLowerCase().contains(text) ||
        item.category.label.toLowerCase().contains(text) ||
        item.id.contains(text))
    ).toList(growable: false);
  }
}
