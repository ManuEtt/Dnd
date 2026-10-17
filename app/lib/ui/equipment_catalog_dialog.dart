import 'package:flutter/material.dart';

import '../domain/srd_equipment_catalog.dart';

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
    final screen = MediaQuery.sizeOf(context);
    return AlertDialog(
      title: const Text('SRD-Ausrüstungskatalog'),
      content: SizedBox(
        width: 560,
        height: (screen.height - 210).clamp(220.0, 570.0).toDouble(),
        child: Column(
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
              onChanged: (selected) => setState(() => _category = selected),
            ),
            Text(
              '${items.length} Treffer',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('Keine Gegenstände gefunden.'))
                  : ListView.builder(
                      key: const ValueKey('equipment-catalog-results'),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final entry = items[index];
                        return ListTile(
                          key: ValueKey('equipment-catalog-item-${entry.id}'),
                          dense: true,
                          title: Text(entry.name),
                          subtitle: Text(
                            entry.detail,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            tooltip: '${entry.name} hinzufügen',
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => Navigator.pop(context, entry),
                          ),
                          onTap: () => Navigator.pop(context, entry),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
      ],
    );
  }
}
