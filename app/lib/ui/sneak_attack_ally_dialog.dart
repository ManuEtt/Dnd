import 'package:flutter/material.dart';

import 'fantasy_buttons.dart';

/// A local form result only. The controller validates the current attack and
/// stores the two independently confirmed facts after explicit acceptance.
class SneakAttackAllyChoice {
  const SneakAttackAllyChoice({
    required this.allyName,
    required this.withinFiveFeetOfTargetConfirmed,
    required this.notIncapacitatedConfirmed,
  });

  final String allyName;
  final bool withinFiveFeetOfTargetConfirmed, notIncapacitatedConfirmed;
}

class SneakAttackAllyDialog extends StatefulWidget {
  const SneakAttackAllyDialog({super.key, required this.targetName});

  final String targetName;

  @override
  State<SneakAttackAllyDialog> createState() => _SneakAttackAllyDialogState();
}

class _SneakAttackAllyDialogState extends State<SneakAttackAllyDialog> {
  final _name = TextEditingController();
  bool _nearTarget = false, _notIncapacitated = false;

  bool get _validName =>
      _name.text.trim().isNotEmpty &&
      _name.text.trim().length <= 120 &&
      !RegExp(r'[\x00-\x1f\x7f]').hasMatch(_name.text);

  bool get _canConfirm => _validName && _nearTarget && _notIncapacitated;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_canConfirm) return;
    Navigator.pop(
      context,
      SneakAttackAllyChoice(
        allyName: _name.text.trim(),
        withinFiveFeetOfTargetConfirmed: _nearTarget,
        notIncapacitatedConfirmed: _notIncapacitated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    key: const ValueKey('sneak-attack-ally-dialog'),
    title: const Text('Hinterhältiger Angriff: Verbündeter'),
    content: SizedBox(
      width: 360,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Angriffsziel: ${widget.targetName}'),
            const SizedBox(height: 12),
            const Text(
              'Bestätige beide Tatsachen für diesen bevorstehenden Angriff. '
              'Die Nähe zum Helden allein reicht nicht. '
              'Erzähltext bestätigt weder die Position noch den Zustand.',
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('sneak-attack-ally-name'),
              controller: _name,
              maxLength: 120,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Verbündeter',
                errorText: _name.text.isNotEmpty && !_validName
                    ? 'Name ohne Steuerzeichen eingeben.'
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
            CheckboxListTile(
              key: const ValueKey('sneak-attack-ally-near-target'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Der Verbündete steht innerhalb von 5 Fuß des Angriffsziels.',
              ),
              value: _nearTarget,
              onChanged: (value) =>
                  setState(() => _nearTarget = value ?? false),
            ),
            CheckboxListTile(
              key: const ValueKey('sneak-attack-ally-not-incapacitated'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Der Verbündete ist nicht handlungsunfähig (Incapacitated).',
              ),
              subtitle: const Text(
                'Nur bei Bewusstsein zu sein genügt dafür nicht.',
              ),
              value: _notIncapacitated,
              onChanged: (value) =>
                  setState(() => _notIncapacitated = value ?? false),
            ),
            const SizedBox(height: 8),
            const Text(
              'Die Bestätigung gilt nur für diesen Angriff. Schaden entsteht '
              'erst bei einem regelgültigen Treffer; Waffenanforderung, '
              'Vorteil/Nachteil und die Begrenzung pro Zug bleiben maßgeblich.',
            ),
          ],
        ),
      ),
    ),
    actions: [
      FantasyTextButton(
        key: const ValueKey('sneak-attack-ally-cancel'),
        label: 'Abbrechen',
        style: FantasyButtonStyle.iron,
        onPressed: () => Navigator.pop(context),
      ),
      FantasyTextButton(
        key: const ValueKey('sneak-attack-ally-confirm'),
        label: 'Verbündeten bestätigen',
        icon: Icons.group_outlined,
        onPressed: _canConfirm ? _confirm : null,
      ),
    ],
  );
}
