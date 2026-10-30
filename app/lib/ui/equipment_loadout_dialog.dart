import 'package:flutter/material.dart';

import 'fantasy_buttons.dart';

import '../domain/equipment_rules.dart';
import '../domain/condition_rules.dart';
import '../domain/models.dart';
import '../domain/srd_equipment_catalog.dart';

/// Explicit, non-mutating equipment preview. Applies only after the user taps
/// the confirmation button; the caller rechecks the current character.
class EquipmentLoadoutDialog extends StatefulWidget {
  const EquipmentLoadoutDialog({super.key, required this.hero});
  final HeroCharacter hero;

  @override
  State<EquipmentLoadoutDialog> createState() => _EquipmentLoadoutDialogState();
}

class _EquipmentLoadoutDialogState extends State<EquipmentLoadoutDialog> {
  late String _armor = widget.hero.equippedArmorId;
  late String _shield = widget.hero.equippedShieldId;
  late String _weapon = widget.hero.equippedWeaponId;
  late bool _armorTrained = widget.hero.equippedArmorTrained;
  late bool _shieldTrained = widget.hero.equippedShieldTrained;
  late bool _weaponTrained = widget.hero.weaponProficient;
  bool _dexFinesse = false;
  bool _twoHands = false;
  bool _thrown = false;

  List<InventoryItem> _items(bool Function(EquipmentEntry) isAllowed) {
    final seen = <String>{};
    return widget.hero.inventory.where((item) {
      final entry = SrdEquipmentCatalog.byId(item.catalogId);
      return entry != null && isAllowed(entry) && seen.add(item.id);
    }).toList();
  }

  Widget _chooser(
    String label,
    String key,
    String selected,
    List<InventoryItem> options,
    ValueChanged<String> update,
  ) {
    return DropdownButtonFormField<String>(
      key: ValueKey(key),
      initialValue: options.any((item) => item.id == selected) ? selected : '',
      decoration: InputDecoration(labelText: label),
      isExpanded: true,
      items: [
        const DropdownMenuItem(value: '', child: Text('Nicht auswählen')),
        for (final item in options)
          DropdownMenuItem(
            value: item.id,
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: (next) => setState(() => update(next ?? '')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final armors = _items((e) => e.isArmor);
    final shields = _items((e) => e.isShield);
    final weapons = _items((e) => e.isWeapon);
    final selection = EquipmentSelection(
      armorId: _armor,
      shieldId: _shield,
      weaponId: _weapon,
      armorTrained: _armorTrained,
      shieldTrained: _shieldTrained,
      weaponProficient: _weaponTrained,
      preferDexterity: _dexFinesse,
      twoHands: _twoHands,
      thrown: _thrown,
    );
    EquipmentRulePreview? preview;
    String? validation;
    try {
      preview = EquipmentRules.preview(widget.hero, selection);
    } catch (error) {
      validation = error.toString();
    }
    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      title: const Text('Ausrüstung nach D&D prüfen'),
      content: SizedBox(
        width: 560,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Nur bereits im Inventar vorhandene SRD-Gegenstände. '
                'Rüstung, Schild und Waffe werden erst nach Bestätigung wirksam.',
              ),
              const SizedBox(height: 12),
              _chooser('Rüstung', 'loadout-armor', _armor, armors, (id) {
                _armor = id;
                if (id.isEmpty) _armorTrained = false;
              }),
              if (_armor.isNotEmpty)
                CheckboxListTile(
                  key: const ValueKey('loadout-armor-trained'),
                  value: _armorTrained,
                  title: Text(
                    MediaQuery.textScalerOf(context).scale(1) >= 1.8
                        ? 'Rüstungsübung bestätigt'
                        : 'Übung mit dieser Rüstungsart bestätigt',
                  ),
                  onChanged: (value) =>
                      setState(() => _armorTrained = value ?? false),
                ),
              _chooser('Schild', 'loadout-shield', _shield, shields, (id) {
                _shield = id;
                if (id.isEmpty) _shieldTrained = false;
              }),
              if (_shield.isNotEmpty)
                CheckboxListTile(
                  key: const ValueKey('loadout-shield-trained'),
                  value: _shieldTrained,
                  title: const Text('Schildübung bestätigt (+2 RK)'),
                  onChanged: (value) =>
                      setState(() => _shieldTrained = value ?? false),
                ),
              _chooser('Waffe', 'loadout-weapon', _weapon, weapons, (id) {
                _weapon = id;
                _twoHands = false;
                _dexFinesse = false;
                _thrown = false;
              }),
              if (_weapon.isNotEmpty) ...[
                CheckboxListTile(
                  key: const ValueKey('loadout-weapon-trained'),
                  value: _weaponTrained,
                  title: const Text('Waffenübung bestätigt'),
                  onChanged: (value) =>
                      setState(() => _weaponTrained = value ?? false),
                ),
                CheckboxListTile(
                  key: const ValueKey('loadout-finesse'),
                  value: _dexFinesse,
                  title: const Text('Finesse: Geschicklichkeit wählen'),
                  onChanged: (value) =>
                      setState(() => _dexFinesse = value ?? false),
                ),
                CheckboxListTile(
                  key: const ValueKey('loadout-two-hands'),
                  value: _twoHands,
                  title: const Text('Zweihändig führen'),
                  onChanged: (value) =>
                      setState(() => _twoHands = value ?? false),
                ),
                CheckboxListTile(
                  key: const ValueKey('loadout-thrown'),
                  value: _thrown,
                  title: const Text('Waffe werfen'),
                  onChanged: (value) =>
                      setState(() => _thrown = value ?? false),
                ),
              ],
              const SizedBox(height: 10),
              if (preview != null) ...[
                Text(
                  'Vorschau (noch nicht gespeichert)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (preview.armorClass != null)
                  Text('Rüstungsklasse: ${preview.armorClass}'),
                if (preview.weaponDamage != null)
                  Text(
                    'Waffenschaden: ${preview.weaponDamage}; '
                    'Angriff (Grundwert): ${preview.attackBonus! >= 0 ? '+' : ''}${preview.attackBonus} '
                    '(${preview.weaponAbility == 'dexterity' ? 'GE' : 'ST'})',
                  ),
                if (preview.weaponDamage != null &&
                    widget.hero.exhaustionLevel > 0)
                  Text(
                    'Im Spiel mit Erschöpfung: Angriff '
                    '${preview.attackBonus! - widget.hero.exhaustionLevel * 2} '
                    '(−${widget.hero.exhaustionLevel * 2} auf W20-Tests).',
                  ),
                if (preview.speedPenaltyFeet != 0)
                  Text('Bewegungsabzug: ${preview.speedPenaltyFeet} Fuß'),
                if (preview.weaponDamage != null &&
                    ConditionRules.hasUnconditionalAttackDisadvantage(
                      widget.hero,
                    ))
                  const Text('Aktueller Zustand: Waffenangriff mit Nachteil.'),
                for (final note in preview.warnings)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('• $note'),
                  ),
                const SizedBox(height: 6),
                const Text(
                  'Keine automatische Abbuchung von Gold oder Munition; '
                  'magische Effekte und alternative RK-Formeln sind ausgenommen.',
                  style: TextStyle(fontSize: 12),
                ),
              ] else
                Text(
                  validation ?? 'Ausrüstung unvollständig',
                  key: const ValueKey('loadout-validation'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
        ),
      ),
      actions: [
        FantasyTextButton(
          label: 'Abbrechen',
          style: FantasyButtonStyle.iron,
          onPressed: () => Navigator.pop(context),
        ),
        FantasyTextButton(
          key: const ValueKey('loadout-confirm'),
          label: 'Werte übernehmen',
          style: FantasyButtonStyle.woodGold,
          onPressed: preview == null
              ? null
              : () => Navigator.pop(context, preview),
        ),
      ],
    );
  }
}
