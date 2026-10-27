import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/models.dart';
import '../domain/srd_spell_audited_inventory_rules.dart';
import '../domain/srd_spell_catalog.dart';
import '../domain/srd_spell_component_rules.dart';
import 'fantasy_buttons.dart';

/// Read-only declaration for a later, separately authorized cast action.
/// The controller must still verify the hero snapshot and spell effect.
class SrdMaterialInventoryChoice {
  SrdMaterialInventoryChoice({
    required List<SrdAuditedInventoryBinding> bindings,
    required List<SrdMaterialItemConfirmation> confirmations,
    required this.confirmedTargetCount,
  }) : bindings = List.unmodifiable(bindings),
       confirmations = List.unmodifiable(confirmations);

  final List<SrdAuditedInventoryBinding> bindings;
  final List<SrdMaterialItemConfirmation> confirmations;
  final int? confirmedTargetCount;
}

/// Material binding and confirmation UI, without mutating inventory or slots.
/// Neither free-text names nor narrative claims prove an item's price.
class SrdMaterialInventoryDialog extends StatefulWidget {
  const SrdMaterialInventoryDialog({
    super.key,
    required this.hero,
    required this.spell,
  });

  final HeroCharacter hero;
  final SrdSpellDefinition spell;

  @override
  State<SrdMaterialInventoryDialog> createState() =>
      _SrdMaterialInventoryDialogState();
}

class _SrdMaterialInventoryDialogState
    extends State<SrdMaterialInventoryDialog> {
  List<SrdAuditedMaterialItem> _requirements = const [];
  final Map<String, String> _selectedStacks = {};
  final Set<String> _identityConfirmed = {};
  final Set<String> _quantityConfirmed = {};
  final Set<String> _consumptionConfirmed = {};
  String _targetCountText = '';
  String? _setupError;
  String? _error;

  @override
  void initState() {
    super.initState();
    try {
      _requirements = SrdSpellComponentRules.auditedItems(widget.spell);
      if (_requirements.isEmpty) {
        _setupError = 'Für diesen Zauber ist kein Materialrezept geprüft.';
      }
    } on FormatException catch (exception) {
      _setupError = exception.message;
    }
  }

  void _toggle(Set<String> confirmed, String id, bool enabled) {
    setState(() {
      if (enabled) {
        confirmed.add(id);
      } else {
        confirmed.remove(id);
      }
      _error = null;
    });
  }

  Widget _check(
    String key,
    String label,
    Set<String> selected,
    String id,
  ) => CheckboxListTile(
    key: ValueKey('material-$key-$id'),
    dense: true,
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    title: Text(label),
    value: selected.contains(id),
    onChanged: (value) => _toggle(selected, id, value ?? false),
  );

  void _confirm() {
    if (_setupError != null) return;
    try {
      final bindings = <SrdAuditedInventoryBinding>[];
      final confirmations = <SrdMaterialItemConfirmation>[];
      for (final requirement in _requirements) {
        final inventoryId = _selectedStacks[requirement.id];
        if (inventoryId == null) {
          throw const FormatException(
            'Bitte für jede Materialposition einen Stapel auswählen.',
          );
        }
        final identity = _identityConfirmed.contains(requirement.id);
        final quantity = _quantityConfirmed.contains(requirement.id);
        final reserved = _consumptionConfirmed.contains(requirement.id);
        bindings.add(
          SrdAuditedInventoryBinding(
            materialId: requirement.id,
            inventoryId: inventoryId,
            identityAndValueConfirmed: identity,
            requiredQuantityConfirmed: quantity,
          ),
        );
        confirmations.add(
          SrdMaterialItemConfirmation(
            id: requirement.id,
            identityAndCostConfirmed: identity,
            requiredQuantityConfirmed: quantity,
            consumptionReservedConfirmed: reserved,
          ),
        );
      }

      final targets = widget.spell.name == 'Astral Projection'
          ? int.tryParse(_targetCountText)
          : null;
      SrdSpellComponentRules.validateMaterial(
        widget.spell,
        materialComponentConfirmed: true,
        costlyComponentAvailableConfirmed: true,
        consumedComponentReservedConfirmed: true,
        confirmedMaterialItems: confirmations,
      );
      SrdSpellAuditedInventoryRules.consumedQuantities(
        widget.hero,
        widget.spell,
        bindings: bindings,
        confirmedTargetCount: targets,
      );
      Navigator.of(context).pop(
        SrdMaterialInventoryChoice(
          bindings: bindings,
          confirmations: confirmations,
          confirmedTargetCount: targets,
        ),
      );
    } on FormatException catch (exception) {
      setState(() => _error = exception.message);
    } on StateError catch (exception) {
      setState(() => _error = exception.toString());
    } on UnsupportedError catch (exception) {
      setState(() => _error = exception.toString());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Zaubermaterialien bestätigen'),
    content: SizedBox(
      width: 470,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.spell.name),
            const SizedBox(height: 8),
            const Text(
              'Inventarname und Anzahl beweisen keinen Gegenstandswert. '
              'Jede Materialposition muss unabhängig geprüft werden. '
              'Es wird noch nichts verbraucht oder gewirkt.',
            ),
            if (_setupError != null)
              Text(
                _setupError!,
                key: const ValueKey('material-setup-error'),
              ),
            for (final requirement in _requirements) ...[
              const SizedBox(height: 12),
              Text(requirement.label),
              DropdownButtonFormField<String>(
                key: ValueKey('material-stack-'
                    '${requirement.id}'),
                isExpanded: true,
                initialValue: _selectedStacks[requirement.id],
                decoration: const InputDecoration(
                  labelText: 'Bestätigter Inventarstapel',
                ),
                items: [
                  for (final item in widget.hero.inventory)
                    if (item.id.isNotEmpty && item.quantity > 0)
                      DropdownMenuItem(
                        value: item.id,
                        child: Text(
                          '${item.name} (${item.quantity}×) · ${item.id}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                ],
                onChanged: (value) => setState(() {
                  if (value == null) {
                    _selectedStacks.remove(requirement.id);
                  } else {
                    _selectedStacks[requirement.id] = value;
                  }
                  _error = null;
                }),
              ),
              _check(
                'identity',
                'Identität und vorgeschriebener Wert sind geprüft.',
                _identityConfirmed,
                requirement.id,
              ),
              _check(
                'quantity',
                'Die vollständige benötigte Anzahl ist geprüft.',
                _quantityConfirmed,
                requirement.id,
              ),
              if (requirement.isConsumed)
                _check(
                  'reserved',
                  'Der Verbrauch dieser Position ist ausdrücklich bestätigt.',
                  _consumptionConfirmed,
                  requirement.id,
                ),
            ],
            if (widget.spell.name == 'Astral Projection') ...[
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('material-target-count'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Bestätigte Anzahl der Ziele',
                ),
                onChanged: (value) => setState(() {
                  _targetCountText = value;
                  _error = null;
                }),
              ),
            ],
            if (_error != null)
              Text(
                _error!,
                key: const ValueKey('material-validation-error'),
                style: const TextStyle(color: Colors.redAccent),
              ),
          ],
        ),
      ),
    ),
    actions: [
      FantasyTextButton(
        label: 'Abbrechen',
        style: FantasyButtonStyle.iron,
        onPressed: () => Navigator.of(context).pop(),
      ),
      FantasyTextButton(
        key: const ValueKey('material-confirm'),
        label: 'Materialien prüfen',
        style: FantasyButtonStyle.arcane,
        onPressed: _setupError != null ? null : _confirm,
      ),
    ],
  );
}
