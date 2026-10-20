import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/srd_initiative_roster_rules.dart';

class ConfirmedInitiativeChoice {
  const ConfirmedInitiativeChoice({
    required this.creatureId,
    required this.total,
    required this.controller,
  });

  final String creatureId, controller;
  final int total;
}

/// Initiative is a **preview** until all totals and tied-actor orders are
/// confirmed. The existing Encounter only automates the primary opponent.
class TrackedCreatureInitiativeDialog extends StatefulWidget {
  const TrackedCreatureInitiativeDialog({
    super.key,
    required this.campaign,
  });

  final Campaign campaign;

  @override
  State<TrackedCreatureInitiativeDialog> createState() =>
      _TrackedCreatureInitiativeDialogState();
}

class _TrackedCreatureInitiativeDialogState
    extends State<TrackedCreatureInitiativeDialog> {
  final _total = TextEditingController();
  String? _selectedId, _controller, _error;
  bool _confirmed = false;
  bool _baseConfirmed = false;

  @override
  void dispose() {
    _total.dispose();
    super.dispose();
  }

  void _save() {
    final total = int.tryParse(_total.text.trim());
    if (_selectedId == null ||
        total == null ||
        total < -30 ||
        total > 100 ||
        _controller == null ||
        !_confirmed) {
      setState(() => _error =
          'Kreatur, vollständiges Initiativeergebnis, '
          'SL-/Spieler-Kontrolle und Bestätigung sind erforderlich.');
      return;
    }
    Navigator.of(context).pop(
      ConfirmedInitiativeChoice(
        creatureId: _selectedId!,
        total: total,
        controller: _controller!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final campaign = widget.campaign;
    final living = campaign.trackedAreaCreatures
        .where((creature) => creature.hitPoints > 0)
        .toList();
    final roster = SrdInitiativeRosterRules.preview(
      campaign,
      baseInitiativeConfirmed: _baseConfirmed,
    );
    return AlertDialog(
      title: const Text('Mehrgegner-Initiative'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'SRD 5.2.1: Absteigende Initiative. Bei Gleichstand '
                'bestimmen Spieler bzw. SL die tatsächliche Reihenfolge. '
                'Die Anzeige steuert noch KEINE zusätzlichen Kampfzüge.',
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                key: const ValueKey('initiative-base-confirmed'),
                contentPadding: EdgeInsets.zero,
                value: _baseConfirmed,
                title: const Text(
                  'Initiative des Helden und Hauptgegners '
                  'aus dem Kampfstart bestätigt.',
                ),
                onChanged: (v) => setState(() =>
                    _baseConfirmed = v ?? false),
              ),
              for (final group in roster.groups) ...[
                const Divider(),
                Text('Initiative ${group.total}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                for (final entry in group.entries)
                  Text('${entry.name} '
                      '(${entry.controller == 'gm' ? 'SL' : 'Spieler'}, '
                      '${entry.kind == 'additional' ? 'Zusatzkreatur' : 'Hauptakteur'})'),
                if (group.hasUnresolvedTie)
                  const Text(
                    'Gleichstand – Reihenfolge ausdrücklich klären.',
                  ),
              ],
              if (roster.missing.isNotEmpty)
                Text(
                  'Ohne bestätigte Initiative: '
                  '${roster.missing.map((creature) => creature.name).join(', ')}.',
                ),
              if (!roster.baseInitiativeConfirmed)
                const Text('Hauptinitiative ist noch nicht bestätigt.'),
              if (roster.readyForManualAdjudication)
                const Text(
                  'Initiativliste zur manuellen Reihenfolge bereit. '
                  'Keine automatische Zugausführung.',
                ),
              const SizedBox(height: 14),
              const Text('Zusatzkreatur-Initiative erfassen oder korrigieren'),
              DropdownButtonFormField<String>(
                key: const ValueKey('initiative-target'),
                initialValue: _selectedId,
                decoration: const InputDecoration(
                  labelText: 'Lebende Zusatzkreatur',
                ),
                items: [
                  for (final creature in living)
                    DropdownMenuItem(
                      value: creature.id,
                      child: Text(creature.name),
                    ),
                ],
                onChanged: (value) =>
                    setState(() => _selectedId = value),
              ),
              TextField(
                key: const ValueKey('initiative-total'),
                controller: _total,
                keyboardType:
                    const TextInputType.numberWithOptions(signed: true),
                decoration: const InputDecoration(
                  labelText: 'Bestätigtes Initiative-Ergebnis',
                  hintText: 'z. B. 14, einschließlich aller Modifikatoren',
                ),
                onChanged: (_) => setState(() => _error = null),
              ),
              DropdownButtonFormField<String>(
                key: const ValueKey('initiative-controller'),
                initialValue: _controller,
                decoration: const InputDecoration(
                  labelText: 'Wer entscheidet bei Initiative-Gleichstand?',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'gm',
                    child: Text('Spielleitung (Monster/NSC)'),
                  ),
                  DropdownMenuItem(
                    value: 'player',
                    child: Text('Spieler (Spielercharakter)'),
                  ),
                ],
                onChanged: (v) => setState(() => _controller = v),
              ),
              CheckboxListTile(
                key: const ValueKey('initiative-entry-confirmed'),
                contentPadding: EdgeInsets.zero,
                value: _confirmed,
                title: const Text(
                  'Würfelergebnis und Kontrolle anhand des '
                  'Kampfes ausdrücklich bestätigt.',
                ),
                onChanged: (v) =>
                    setState(() => _confirmed = v ?? false),
              ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Schließen'),
        ),
        FilledButton(
          key: const ValueKey('initiative-save'),
          onPressed: living.isEmpty ? null : _save,
          child: const Text('Initiative speichern'),
        ),
      ],
    );
  }
}
