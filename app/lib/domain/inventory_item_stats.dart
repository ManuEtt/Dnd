import 'srd_equipment_catalog.dart';

/// Individuell bestätigte Gegenstandswerte, unabhängig von der Beschreibung.
/// Diese Daten sind optionale Inventarmetadaten: Die Kampfregelengine verwendet
/// weiterhin ausschließlich bestätigte SRD-Katalogeinträge für Ausrüstung.
enum InventoryItemKind {
  weapon,
  armor,
  shield,
  ammunition,
  consumable,
  magic,
  tool,
  gear,
  other,
}

extension InventoryItemKindLabel on InventoryItemKind {
  String get label => switch (this) {
    InventoryItemKind.weapon => 'Waffe',
    InventoryItemKind.armor => 'Rüstung',
    InventoryItemKind.shield => 'Schild',
    InventoryItemKind.ammunition => 'Munition',
    InventoryItemKind.consumable => 'Verbrauchsgegenstand',
    InventoryItemKind.magic => 'Magischer Gegenstand',
    InventoryItemKind.tool => 'Werkzeug',
    InventoryItemKind.gear => 'Ausrüstung',
    InventoryItemKind.other => 'Sonstiges',
  };
}

class InventoryItemStats {
  const InventoryItemStats({
    this.kind = InventoryItemKind.other,
    this.priceCp,
    this.weightLb,
    this.damage,
    this.damageType,
    this.versatileDamage,
    this.weaponProperties = const [],
    this.mastery,
    this.rangeNormalFt,
    this.rangeLongFt,
    this.ammunitionType,
    this.armorBaseAc,
    this.dexCap,
    this.strengthMin,
    this.stealthDisadvantage,
    this.rarity,
    this.requiresAttunement,
    this.charges,
    this.maxCharges,
    this.effect,
  });

  final InventoryItemKind kind;
  final int? priceCp;
  final double? weightLb;
  final String? damage, damageType, versatileDamage, mastery, ammunitionType;
  final List<String> weaponProperties;
  final int? rangeNormalFt, rangeLongFt;
  /// Basis-RK bei Rüstungen; RK-Bonus bei Schilden.
  final int? armorBaseAc, dexCap, strengthMin;
  final bool? stealthDisadvantage;
  final String? rarity;
  final bool? requiresAttunement;
  final int? charges, maxCharges;
  final String? effect;

  /// Kopie der expliziten Katalogspalten, keine Auflösung aus Freitext.
  /// Diese Werte werden noch nicht als individuelle Regel-Overrides genutzt.
  factory InventoryItemStats.fromCatalog(EquipmentEntry entry) {
    final kind = entry.isWeapon
        ? InventoryItemKind.weapon
        : entry.isArmor
        ? InventoryItemKind.armor
        : entry.isShield
        ? InventoryItemKind.shield
        : switch (entry.category) {
            EquipmentCategory.ammunition => InventoryItemKind.ammunition,
            EquipmentCategory.magic => InventoryItemKind.magic,
            EquipmentCategory.tool ||
            EquipmentCategory.game ||
            EquipmentCategory.instrument => InventoryItemKind.tool,
            _ => InventoryItemKind.gear,
          };
    return InventoryItemStats(
      kind: kind,
      priceCp: entry.priceCp,
      weightLb: entry.weightLb,
      damage: entry.damage,
      damageType: entry.damageType,
      versatileDamage: entry.twoHandDamage,
      weaponProperties: List<String>.unmodifiable(entry.properties),
      mastery: entry.mastery,
      rangeNormalFt: entry.rangeNormal,
      rangeLongFt: entry.rangeLong,
      ammunitionType: entry.ammunitionType,
      armorBaseAc: entry.armorBaseAc,
      dexCap: entry.dexCap,
      strengthMin: entry.strengthMin,
      stealthDisadvantage: entry.isArmor
          ? entry.stealthDisadvantage
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    if (priceCp != null) 'priceCp': priceCp,
    if (weightLb != null) 'weightLb': weightLb,
    if (damage != null) 'damage': damage,
    if (damageType != null) 'damageType': damageType,
    if (versatileDamage != null) 'versatileDamage': versatileDamage,
    if (weaponProperties.isNotEmpty) 'weaponProperties': weaponProperties,
    if (mastery != null) 'mastery': mastery,
    if (rangeNormalFt != null) 'rangeNormalFt': rangeNormalFt,
    if (rangeLongFt != null) 'rangeLongFt': rangeLongFt,
    if (ammunitionType != null) 'ammunitionType': ammunitionType,
    if (armorBaseAc != null) 'armorBaseAc': armorBaseAc,
    if (dexCap != null) 'dexCap': dexCap,
    if (strengthMin != null) 'strengthMin': strengthMin,
    if (stealthDisadvantage != null)
      'stealthDisadvantage': stealthDisadvantage,
    if (rarity != null) 'rarity': rarity,
    if (requiresAttunement != null)
      'requiresAttunement': requiresAttunement,
    if (charges != null) 'charges': charges,
    if (maxCharges != null) 'maxCharges': maxCharges,
    if (effect != null) 'effect': effect,
  };

  static int? _integer(dynamic value, String name, {int min = 0, int max = 1000000}) {
    if (value == null) return null;
    if (value is! int || value < min || value > max) {
      throw FormatException('$name ist ungültig.');
    }
    return value;
  }

  static double? _weight(dynamic value) {
    if (value == null) return null;
    if (value is! num || !value.isFinite || value < 0 || value > 1000000) {
      throw const FormatException('Gegenstandsgewicht ist ungültig.');
    }
    return value.toDouble();
  }

  static String? _text(dynamic value, String name) {
    if (value == null) return null;
    if (value is! String || value.length > 2000) {
      throw FormatException('$name ist ungültig.');
    }
    return value;
  }

  static bool? _flag(dynamic value, String name) {
    if (value == null) return null;
    if (value is! bool) throw FormatException('$name ist ungültig.');
    return value;
  }

  factory InventoryItemStats.fromJson(Map<String, dynamic> data) {
    final rawKind = data['kind'] ?? 'other';
    if (rawKind is! String) {
      throw const FormatException('Gegenstandskategorie ist ungültig.');
    }
    InventoryItemKind kind;
    try {
      kind = InventoryItemKind.values.byName(rawKind);
    } on ArgumentError {
      throw const FormatException('Unbekannte Gegenstandskategorie.');
    }
    final props = data['weaponProperties'];
    if (props != null &&
        (props is! List ||
            props.length > 30 ||
            props.any((p) => p is! String || p.length > 100))) {
      throw const FormatException('Waffeneigenschaften sind ungültig.');
    }
    final charges = _integer(data['charges'], 'Aktuelle Ladungen');
    final maxCharges = _integer(data['maxCharges'], 'Maximale Ladungen');
    if (charges != null && maxCharges != null && charges > maxCharges) {
      throw const FormatException('Aktuelle Ladungen überschreiten das Maximum.');
    }
    final normal = _integer(data['rangeNormalFt'], 'Normale Reichweite');
    final long = _integer(data['rangeLongFt'], 'Maximale Reichweite');
    if (normal != null && long != null && normal > long) {
      throw const FormatException('Normale Reichweite überschreitet maximale Reichweite.');
    }
    return InventoryItemStats(
      kind: kind,
      priceCp: _integer(data['priceCp'], 'Gegenstandspreis'),
      weightLb: _weight(data['weightLb']),
      damage: _text(data['damage'], 'Schaden'),
      damageType: _text(data['damageType'], 'Schadensart'),
      versatileDamage: _text(data['versatileDamage'], 'Vielseitiger Schaden'),
      weaponProperties: props == null
          ? const []
          : List<String>.unmodifiable(props.cast<String>()),
      mastery: _text(data['mastery'], 'Waffenmeisterschaft'),
      rangeNormalFt: normal,
      rangeLongFt: long,
      ammunitionType: _text(data['ammunitionType'], 'Munition'),
      armorBaseAc: _integer(data['armorBaseAc'], 'Rüstungsklasse', max: 50),
      dexCap: _integer(data['dexCap'], 'Geschicklichkeitsgrenze', max: 50),
      strengthMin: _integer(data['strengthMin'], 'Stärkeanforderung', max: 30),
      stealthDisadvantage: _flag(data['stealthDisadvantage'], 'Heimlichkeitsnachteil'),
      rarity: _text(data['rarity'], 'Seltenheit'),
      requiresAttunement: _flag(data['requiresAttunement'], 'Einstimmung'),
      charges: charges,
      maxCharges: maxCharges,
      effect: _text(data['effect'], 'Wirkung'),
    );
  }
}
