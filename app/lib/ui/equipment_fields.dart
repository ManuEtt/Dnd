import 'package:flutter/material.dart';

import '../domain/srd_equipment_catalog.dart';
import 'fantasy_ui.dart';

/// Displays SRD mechanics from typed catalog fields, never from a prose string.
/// The same widget is suitable for weapon, armor, and inventory detail screens.
class EquipmentFields extends StatelessWidget {
  const EquipmentFields({super.key, required this.entry, this.compact = false});

  final EquipmentEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final values = attributes(entry);
    final shown = compact ? values.take(3).toList() : values;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final tileWidth = compact || width < 420 ? width : (width - 10) / 2;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                for (final field in shown)
                  SizedBox(
                    width: tileWidth,
                    child: _AttributeCard(
                      key: ValueKey('equipment-value-${entry.id}-${field.id}'),
                      field: field,
                      compact: compact,
                    ),
                  ),
              ],
            ),
            if (!compact && entry.note != null && entry.note!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hinweis',
                      style: TextStyle(color: FantasyPalette.gold),
                    ),
                    Text(entry.note!),
                  ],
                ),
              ),
            if (!compact && entry.category == EquipmentCategory.magic)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  'Magische Regelwirkungen werden nur angezeigt, '
                  'soweit sie durch bestätigte Katalogwerte belegt sind.',
                ),
              ),
          ],
        );
      },
    );
  }

  /// Explicit, consistently labelled fields; no parsing of `entry.detail`.
  static List<EquipmentAttribute> attributes(EquipmentEntry entry) {
    final values = <EquipmentAttribute>[
      EquipmentAttribute('category', 'Kategorie', entry.category.label),
      if (entry.damage != null)
        EquipmentAttribute('damage', 'Schaden', entry.damage!),
      if (entry.damageType != null)
        EquipmentAttribute('damageType', 'Schadensart', entry.damageType!),
      if (entry.twoHandDamage != null)
        EquipmentAttribute(
          'twoHand',
          'Vielseitiger Schaden',
          entry.twoHandDamage!,
        ),
      if (entry.properties.isNotEmpty)
        EquipmentAttribute(
          'properties',
          'Waffeneigenschaften',
          entry.properties.join(', '),
        ),
      if (entry.mastery != null)
        EquipmentAttribute('mastery', 'Waffenmeisterschaft', entry.mastery!),
      if (entry.rangeNormal != null)
        EquipmentAttribute(
          'rangeNormal',
          'Normale Reichweite',
          '${entry.rangeNormal} ft',
        ),
      if (entry.rangeLong != null)
        EquipmentAttribute(
          'rangeLong',
          'Maximale Reichweite',
          '${entry.rangeLong} ft',
        ),
      if (entry.ammunitionType != null)
        EquipmentAttribute('ammunitionType', 'Munition', entry.ammunitionType!),
      if (entry.armorBaseAc != null)
        EquipmentAttribute(
          'armorBaseAc',
          entry.isShield ? 'RK-Bonus' : 'Basis-Rüstungsklasse',
          '${entry.armorBaseAc}',
        ),
      if (entry.dexCap != null)
        EquipmentAttribute('dexCap', 'Maximaler GE-Bonus', '${entry.dexCap}'),
      if (entry.strengthMin != null)
        EquipmentAttribute(
          'strengthMin',
          'Stärkeanforderung',
          '${entry.strengthMin}',
        ),
      if (entry.isArmor)
        EquipmentAttribute(
          'stealthDisadvantage',
          'Heimlichkeitsnachteil',
          entry.stealthDisadvantage ? 'Ja' : 'Nein',
        ),
      if (entry.weightLb != null)
        EquipmentAttribute(
          'weight',
          'Gewicht',
          '${_number(entry.weightLb!)} lb',
        ),
      if (entry.priceCp != null)
        EquipmentAttribute('price', 'Preis', entry.priceLabel),
    ];
    return values;
  }

  static String _number(double value) => value == value.truncateToDouble()
      ? value.toInt().toString()
      : value.toString();
}

class EquipmentAttribute {
  const EquipmentAttribute(this.id, this.label, this.value);

  final String id;
  final String label;
  final String value;
}

class _AttributeCard extends StatelessWidget {
  const _AttributeCard({super.key, required this.field, required this.compact});

  final EquipmentAttribute field;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      border: Border.all(color: FantasyPalette.gold.withValues(alpha: .28)),
      borderRadius: BorderRadius.circular(9),
      color: FantasyPalette.surface,
    ),
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: compact ? 5 : 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          field.label,
          style: const TextStyle(fontSize: 11, color: FantasyPalette.muted),
        ),
        Text(
          field.value,
          softWrap: true,
          style: TextStyle(
            fontSize: compact ? 12 : 15,
            fontWeight: FontWeight.w600,
            color: FantasyPalette.ivory,
          ),
        ),
      ],
    ),
  );
}
