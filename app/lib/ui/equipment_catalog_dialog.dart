import 'package:flutter/material.dart';

import 'fantasy_buttons.dart';

import '../domain/srd_equipment_catalog.dart';
import 'equipment_fields.dart';

/// Searchable, opt-in SRD equipment chooser. Selection never spends gold or
/// modifies AC, combat damage, attunement, or other confirmed character rules.
class EquipmentCatalogDialog extends StatefulWidget {
  const EquipmentCatalogDialog({super.key});

  @override
  State<EquipmentCatalogDialog> createState() => _EquipmentCatalogDialogState();
}

class _EquipmentCatalogDialogState extends State<EquipmentCatalogDialog> {
  String _query = '';
  EquipmentCategory? _category;

  @override
  Widget build(BuildContext context) {
    final items = SrdEquipmentCatalog.search(_query, category: _category);
    final media = MediaQuery.of(context);
    final compact = media.size.width < 500 && media.textScaler.scale(1) >= 1.8;
    // Account for the Android keyboard before reserving the catalog's
    // results area. The dialog itself can still scroll on very short screens.
    final resultsHeight =
        (media.size.height - media.viewInsets.bottom - (compact ? 260 : 210))
            .clamp(90.0, 570.0)
            .toDouble();
    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      title: const Text('SRD-Ausrüstungskatalog'),
      content: SizedBox(
        width: 560,
        height: resultsHeight,
        child: ListView.builder(
          key: const ValueKey('equipment-catalog-results'),
          itemCount: items.isEmpty ? 2 : items.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Auswahl zum Inventar hinzufügen. '
                    'Weder Gold noch Kampfwerte werden automatisch verändert.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    key: const ValueKey('equipment-catalog-search'),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    onChanged: (query) => setState(() => _query = query),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Gegenstand suchen (Deutsch oder Englisch)',
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButton<EquipmentCategory?>(
                    key: const ValueKey('equipment-catalog-category'),
                    value: _category,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<EquipmentCategory?>(
                        value: null,
                        child: Text('Alle Kategorien'),
                      ),
                      for (final category in EquipmentCategory.values)
                        DropdownMenuItem<EquipmentCategory?>(
                          value: category,
                          child: Text(category.label),
                        ),
                    ],
                    onChanged: (selected) =>
                        setState(() => _category = selected),
                  ),
                  Text(
                    '${items.length} Treffer',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                ],
              );
            }
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Keine Gegenstände gefunden.'),
              );
            }
            final entry = items[index - 1];
            final buttons = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FantasyIconButton(
                  tooltip: 'Werte für ${entry.name} anzeigen',
                  icon: Icons.info_outline,
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (sheetContext) => SafeArea(
                      child: FractionallySizedBox(
                        heightFactor: .8,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                entry.name,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 12),
                              EquipmentFields(entry: entry),
                              const SizedBox(height: 16),
                              FantasyTextButton(
                                icon: Icons.add,
                                label: 'Zum Inventar hinzufügen',
                                onPressed: () {
                                  Navigator.pop(sheetContext);
                                  Navigator.pop(context, entry);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                FantasyIconButton(
                  tooltip: '${entry.name} hinzufügen',
                  icon: Icons.add_circle_outline,
                  onPressed: () => Navigator.pop(context, entry),
                ),
              ],
            );
            final tile = ListTile(
              key: ValueKey('equipment-catalog-item-${entry.id}'),
              dense: !compact,
              title: Text(entry.name),
              subtitle: Text(
                entry.category.label,
                maxLines: compact ? null : 1,
                overflow: compact
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
              // At 200% text on narrow phones, the two buttons
              // must not consume the item's readable name width.
              trailing: compact ? null : buttons,
              onTap: () => Navigator.pop(context, entry),
            );
            if (!compact) return tile;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                tile,
                Align(alignment: Alignment.centerRight, child: buttons),
                const Divider(height: 8),
              ],
            );
          },
        ),
      ),
      actions: [
        FantasyTextButton(
          label: 'Abbrechen',
          style: FantasyButtonStyle.iron,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
