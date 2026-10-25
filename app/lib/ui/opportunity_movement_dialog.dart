import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/srd_equipment_catalog.dart';
import '../domain/srd_opportunity_attack_rules.dart';
import 'fantasy_buttons.dart';

/// Reviews explicit movement facts. Closing this dialog never changes a save.
class OpportunityMovementDialog extends StatefulWidget {
  const OpportunityMovementDialog({super.key, required this.campaign});

  final Campaign campaign;

  @override
  State<OpportunityMovementDialog> createState() =>
      _OpportunityMovementDialogState();
}

class _OpportunityMovementDialogState extends State<OpportunityMovementDialog> {
  final _before = TextEditingController();
  final _after = TextEditingController();
  final _reach = TextEditingController();
  OpportunityMovement? _movement;
  String? _strike;
  bool _visible = false, _authorized = false;

  @override
  void dispose() {
    _before.dispose();
    _after.dispose();
    _reach.dispose();
    super.dispose();
  }

  void _change(VoidCallback update) => setState(() {
    update();
    _authorized = false;
  });

  InventoryItem? get _weapon {
    final hero = widget.campaign.hero;
    final matches = hero.inventory.where(
      (item) => item.id == hero.equippedWeaponId,
    );
    if (hero.equippedWeaponId.isEmpty || matches.length != 1) return null;
    final item = matches.single;
    final entry = SrdEquipmentCatalog.byId(item.catalogId);
    if (item.quantity <= 0 ||
        entry == null ||
        (entry.category != EquipmentCategory.simpleMelee &&
            entry.category != EquipmentCategory.martialMelee)) {
      return null;
    }
    return item;
  }

  int? _feet(TextEditingController field) {
    final text = field.text.trim();
    return RegExp(r'^\d+$').hasMatch(text) ? int.tryParse(text) : null;
  }

  ConfirmedOpportunityTrigger? get _trigger {
    final fight = widget.campaign.encounter;
    final before = _feet(_before), after = _feet(_after), reach = _feet(_reach);
    if (fight == null ||
        before == null ||
        after == null ||
        reach == null ||
        _movement == null ||
        _strike == null ||
        (_strike == 'weapon' && _weapon == null)) {
      return null;
    }
    return ConfirmedOpportunityTrigger(
      encounterId: fight.id,
      beforeDistanceFeet: before,
      afterDistanceFeet: after,
      reachFeet: reach,
      targetVisibleConfirmed: _visible,
      playerAuthorizedReaction: _authorized,
      movement: _movement!,
      strike: _strike == 'weapon'
          ? OpportunityStrike.equippedMeleeWeapon
          : OpportunityStrike.unarmedStrike,
      weaponId: _strike == 'weapon' ? _weapon!.id : '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final trigger = _trigger;
    String? failure;
    var valid = false;
    if (trigger != null) {
      try {
        SrdOpportunityAttackRules.prepare(widget.campaign, trigger);
        valid = true;
      } on FormatException catch (error) {
        failure = error.message;
      }
    }
    final weapon = _weapon;
    return AlertDialog(
      key: const ValueKey('opportunity-movement-dialog'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      title: const Text('Gegnerbewegung bestätigen'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Gegner: ${widget.campaign.encounter?.enemyName ?? "–"}'),
              const SizedBox(height: 8),
              const Text(
                'Bestätige die tatsächliche Bewegung aus deiner '
                'Nahkampfreichweite. Entfernungen werden nicht aus der '
                'Erzählung übernommen. Die Bewegung wird als offenes '
                'Gelegenheitsangriffs-Angebot festgehalten. '
                'Ein Angriff wird hier noch nicht gewürfelt.',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<OpportunityMovement>(
                key: const ValueKey('opportunity-movement-kind'),
                initialValue: _movement,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Bewegungsart'),
                items: const [
                  DropdownMenuItem(
                    value: OpportunityMovement.ordinary,
                    child: Text('Eigene gewöhnliche Bewegung'),
                  ),
                  DropdownMenuItem(
                    value: OpportunityMovement.disengage,
                    child: Text('Rückzug (Disengage)'),
                  ),
                  DropdownMenuItem(
                    value: OpportunityMovement.teleport,
                    child: Text('Teleportation'),
                  ),
                  DropdownMenuItem(
                    value: OpportunityMovement.forced,
                    child: Text('Erzwungene Fremdbewegung'),
                  ),
                ],
                onChanged: (value) => _change(() => _movement = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const ValueKey('opportunity-strike'),
                initialValue: _strike,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Nahkampfangriff'),
                items: [
                  if (weapon != null)
                    DropdownMenuItem(
                      value: 'weapon',
                      child: Text(
                        weapon.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const DropdownMenuItem(
                    value: 'unarmed',
                    child: Text('Waffenloser Schlag'),
                  ),
                ],
                onChanged: (value) => _change(() => _strike = value),
              ),
              if (weapon == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Keine eindeutige angelegte SRD-Nahkampfwaffe bestätigt.',
                  ),
                ),
              for (final field in [
                (
                  key: 'before',
                  label: 'Abstand vorher (Fuß)',
                  controller: _before,
                ),
                (
                  key: 'after',
                  label: 'Abstand danach (Fuß)',
                  controller: _after,
                ),
                (
                  key: 'reach',
                  label: 'Bestätigte Reichweite (Fuß)',
                  controller: _reach,
                ),
              ]) ...[
                const SizedBox(height: 12),
                TextField(
                  key: ValueKey('opportunity-${field.key}'),
                  controller: field.controller,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: field.label),
                  onChanged: (_) => _change(() {}),
                ),
              ],
              const SizedBox(height: 8),
              CheckboxListTile(
                key: const ValueKey('opportunity-visible'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Ich kann den bewegten Gegner sehen.'),
                value: _visible,
                onChanged: (value) => _change(() => _visible = value ?? false),
              ),
              CheckboxListTile(
                key: const ValueKey('opportunity-authorized'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Ich bestätige diese Angaben und möchte die Bewegung '
                  'für meine Reaktionsentscheidung unterbrechen. '
                  'Noch keine Reaktion verbrauchen.',
                ),
                value: _authorized,
                onChanged: (value) =>
                    setState(() => _authorized = value ?? false),
              ),
              if (_movement != null &&
                  _movement != OpportunityMovement.ordinary)
                const Text(
                  'Rückzug, Teleportation und erzwungene Fremdbewegung '
                  'lösen keinen Gelegenheitsangriff aus.',
                )
              else if (failure != null)
                Text(failure)
              else if (valid)
                const Text(
                  'Vorprüfung gültig: Angebot speichern. '
                  'Trefferpunkte und Reaktion bleiben unverändert.',
                  key: ValueKey('opportunity-movement-preview'),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('opportunity-movement-cancel'),
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FantasyTextButton(
          key: const ValueKey('opportunity-movement-confirm'),
          label: 'Bewegung bestätigen',
          icon: Icons.pause_circle_outline,
          style: FantasyButtonStyle.iron,
          onPressed: valid ? () => Navigator.pop(context, trigger) : null,
        ),
      ],
    );
  }
}
