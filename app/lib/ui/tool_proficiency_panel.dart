import 'package:flutter/material.dart';

import '../domain/character_rule_engine.dart';
import '../domain/models.dart';
import '../domain/rules_engine.dart';
import '../domain/srd_equipment_catalog.dart';
import '../domain/tool_proficiency_rules.dart';
import 'ability_assignment_dialog.dart' show abilityLabels;
import 'fantasy_ui.dart';

/// Read-only preview from confirmed proficiency sources. Choosing an ability
/// here never rolls dice, grants gear or changes the saved character.
class ToolProficiencyPanel extends StatefulWidget {
  const ToolProficiencyPanel({super.key, required this.hero});

  final HeroCharacter hero;

  @override
  State<ToolProficiencyPanel> createState() => _ToolProficiencyPanelState();
}

class _ToolProficiencyPanelState extends State<ToolProficiencyPanel> {
  String? _ability;

  @override
  void didUpdateWidget(covariant ToolProficiencyPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hero.id != widget.hero.id) _ability = null;
  }

  Widget _preview(EquipmentEntry entry) {
    final ability = _ability;
    if (ability == null) return const SizedBox.shrink();
    String text;
    try {
      final rule = CharacterRuleEngine.toolCheck(
        widget.hero,
        ability,
        toolCatalogId: entry.id,
      );
      final bonus = rule.modifier < 0
          ? '${rule.modifier}'
          : '+${rule.modifier}';
      text = '${abilityLabels[ability]}: $bonus · ${rule.rollHint}';
      if (rule.minimumNatural > 0) {
        text += ' · Natürlicher W20 mindestens ${rule.minimumNatural}';
      }
    } on StateError {
      text = 'Für ${abilityLabels[ability]} ist kein Attributswert bestätigt.';
    } on FormatException {
      text = 'Für dieses Werkzeug ist keine bestätigte Vorschau verfügbar.';
    }
    return Semantics(
      liveRegion: true,
      child: Text(text, key: ValueKey('tool-proficiency-preview-${entry.id}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = ToolProficiencyRules.entries(widget.hero);
    return ExpansionTile(
      key: ValueKey('tool-proficiency-panel-${widget.hero.id}'),
      title: const Text(
        'Werkzeugübungen',
        style: TextStyle(
          color: FantasyPalette.gold,
          fontFamily: 'serif',
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        entries.isEmpty
            ? 'Keine bestätigten Werkzeugübungen'
            : 'Übungsbonus +${RulesEngine.proficiencyBonus(widget.hero.level)}',
        style: const TextStyle(color: FantasyPalette.muted),
      ),
      expandedAlignment: Alignment.centerLeft,
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      children: entries.isEmpty
          ? const [
              Text(
                'Eine Werkzeugwahl ist hier noch nicht bestätigt. '
                'Historische Angaben bleiben im Charakterbogen erhalten.',
                key: ValueKey('tool-proficiency-empty'),
              ),
            ]
          : [
              const Text(
                'Eine erlernte Übung bleibt erhalten, auch wenn du das '
                'Werkzeug gerade nicht besitzt.',
                style: TextStyle(color: FantasyPalette.muted),
              ),
              const SizedBox(height: 12),
              const Text('Attribut für die Vorschau ausdrücklich wählen.'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: const ValueKey('tool-proficiency-ability'),
                initialValue: _ability,
                isExpanded: true,
                isDense: false,
                itemHeight: null,
                decoration: const InputDecoration(
                  labelText: 'Attribut',
                  hintText: 'Attribut wählen',
                ),
                items: [
                  for (final ability in abilityNames)
                    DropdownMenuItem(
                      value: ability,
                      child: Text(abilityLabels[ability]!),
                    ),
                ],
                onChanged: (value) => setState(() => _ability = value),
              ),
              const SizedBox(height: 12),
              for (final entry in entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        key: ValueKey('tool-proficiency-item-${entry.id}'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      _preview(entry),
                    ],
                  ),
                ),
              const Text(
                'Für eine Handlung müssen Attribut und Umstände passen. '
                'Diese Vorschau bestätigt weder Werkzeugbesitz noch eine '
                'konkrete Anwendung und löst keinen Wurf aus.',
                style: TextStyle(color: FantasyPalette.muted),
              ),
            ],
    );
  }
}
