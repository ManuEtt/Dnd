import 'package:flutter/material.dart';
import 'fantasy_buttons.dart';

import '../domain/models.dart';

/// Registers HP-only creatures; it does not invent initiative, attacks,
/// placement, faction or other monster statistics.
class AreaCreatureRegistrationDialog extends StatefulWidget {
  const AreaCreatureRegistrationDialog({super.key});

  @override
  State<AreaCreatureRegistrationDialog> createState() =>
      _AreaCreatureRegistrationDialogState();
}

class _AreaCreatureRegistrationDialogState
    extends State<AreaCreatureRegistrationDialog> {
  final _id = TextEditingController();
  final _name = TextEditingController();
  final _hitPoints = TextEditingController();
  final _maximum = TextEditingController();
  bool _confirmed = false;
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    _name.dispose();
    _hitPoints.dispose();
    _maximum.dispose();
    super.dispose();
  }

  void _submit() {
    final hp = int.tryParse(_hitPoints.text.trim());
    final max = int.tryParse(_maximum.text.trim());
    if (!_confirmed || hp == null || max == null) {
      setState(
        () => _error =
            'Bitte alle Werte anhand eines bekannten '
            'Kreaturenprofils bestätigen.',
      );
      return;
    }
    try {
      final creature = TrackedAreaCreature.fromJson({
        'id': _id.text.trim(),
        'name': _name.text.trim(),
        'hitPoints': hp,
        'maxHitPoints': max,
      });
      if (creature.hitPoints == 0) {
        throw const FormatException(
          'Eine neue Kreatur benötigt noch Trefferpunkte.',
        );
      }
      Navigator.of(context).pop(creature);
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Kreatur mit TP erfassen'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Zusätzliche Kreaturen können bei Flächenzaubern '
              'Schaden erhalten. Angriffe, Initiative, Ausrüstung und '
              'Bewegung werden für sie noch nicht simuliert.',
            ),
            TextField(
              key: const ValueKey('area-creature-id'),
              controller: _id,
              decoration: const InputDecoration(
                labelText: 'Eindeutige ID, z. B. goblin-2',
              ),
            ),
            TextField(
              key: const ValueKey('area-creature-name'),
              controller: _name,
              decoration: const InputDecoration(labelText: 'Kreaturenname'),
            ),
            TextField(
              key: const ValueKey('area-creature-hp'),
              controller: _hitPoints,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Aktuelle Trefferpunkte',
              ),
            ),
            TextField(
              key: const ValueKey('area-creature-maxhp'),
              controller: _maximum,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Maximale Trefferpunkte',
              ),
            ),
            CheckboxListTile(
              key: const ValueKey('area-creature-confirmed'),
              contentPadding: EdgeInsets.zero,
              value: _confirmed,
              onChanged: (value) => setState(() => _confirmed = value ?? false),
              title: const Text('Identität und Trefferpunkte geprüft.'),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
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
        key: const ValueKey('area-creature-register'),
        label: 'Kreatur speichern',
        style: FantasyButtonStyle.woodGold,
        onPressed: _submit,
      ),
    ],
  );
}
