import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/models.dart';
import '../domain/srd_monk_slow_fall_rules.dart';

/// Player-approved fall damage after all separately resolved defenses.
/// The caller must recheck campaign revision and encounter before committing.
class ConfirmedSlowFallChoice {
  const ConfirmedSlowFallChoice({required this.damageAfterDefenses});
  final int damageAfterDefenses;
}

/// No fall, roll, modifier or player consent is inferred from GM narration.
/// Confirming closes the dialog; the controller remains the sole state writer.
class MonkSlowFallDialog extends StatefulWidget {
  const MonkSlowFallDialog({
    super.key,
    required this.hero,
    required this.encounter,
  });

  final HeroCharacter hero;
  final Encounter encounter;

  @override
  State<MonkSlowFallDialog> createState() => _MonkSlowFallDialogState();
}

class _MonkSlowFallDialogState extends State<MonkSlowFallDialog> {
  final _damage = TextEditingController();
  bool _fallConfirmed = false;
  bool _defensesConfirmed = false;

  @override
  void dispose() {
    _damage.dispose();
    super.dispose();
  }

  int? get _confirmedDamage {
    final raw = _damage.text.trim();
    if (raw.isEmpty || !RegExp(r'^[0-9]{1,6}$').hasMatch(raw)) return null;
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed > 100000) return null;
    return parsed;
  }

  SrdMonkSlowFallResult? get _preview {
    final damage = _confirmedDamage;
    if (damage == null) return null;
    try {
      return SrdMonkSlowFallRules.previewConfirmedReaction(
        widget.hero,
        confirmedFallDamage: damage,
        fallConfirmed: true,
        reactionAvailable: !widget.encounter.reactionUsed,
        reactionConfirmed: true,
        encounter: widget.encounter,
      );
    } on FormatException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _preview;
    final canCommit =
        plan != null && _fallConfirmed && _defensesConfirmed;
    return AlertDialog(
      title: const Text('Sanfter Fall – Reaktion'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nur einen tatsächlich bestätigten Sturz auswerten. '
              'Schaden zuerst außerhalb dieses Dialogs würfeln und '
              'alle anderen Schadensanpassungen klären.',
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('slow-fall-damage-input'),
              controller: _damage,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Bestätigter Sturzschaden (TP)',
                helperText: 'Schaden nach anderen Abzügen; 0 bis 100.000',
                counterText: '',
              ),
            ),
            CheckboxListTile(
              key: const ValueKey('slow-fall-confirm-fall'),
              contentPadding: EdgeInsets.zero,
              value: _fallConfirmed,
              onChanged: (value) =>
                  setState(() => _fallConfirmed = value ?? false),
              title: const Text('Der Sturz ist tatsächlich bestätigt'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              key: const ValueKey('slow-fall-confirm-defenses'),
              contentPadding: EdgeInsets.zero,
              value: _defensesConfirmed,
              onChanged: (value) =>
                  setState(() => _defensesConfirmed = value ?? false),
              title: const Text(
                'Alle anderen Schadensanpassungen sind abgeschlossen',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (plan != null)
              Text(
                'Mönch ${plan.monkClassLevel}: '
                '${plan.preventedDamage} Schaden verhindert, '
                '${plan.remainingDamage} Schaden verbleiben. '
                'Die Reaktion wird ausgegeben.',
                key: const ValueKey('slow-fall-preview'),
              )
            else
              const Text(
                'Gültigen Schaden und eine verfügbare Reaktion benötigt.',
                key: ValueKey('slow-fall-preview-unavailable'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          key: const ValueKey('slow-fall-commit'),
          onPressed: canCommit
              ? () => Navigator.pop(
                    context,
                    ConfirmedSlowFallChoice(
                      damageAfterDefenses: plan!.confirmedFallDamage,
                    ),
                  )
              : null,
          child: const Text('Reaktion einsetzen'),
        ),
      ],
    );
  }
}
