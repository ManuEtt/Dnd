import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/experience_progression.dart';
import '../domain/models.dart';
import 'fantasy_buttons.dart';
import 'fantasy_ui.dart';

/// A deterministic request ID is derived from the explicitly supplied reward
/// ID. Reopening the form after a lost acknowledgement uses the same receipt.
class ExperienceRewardChoice {
  const ExperienceRewardChoice({required this.rewardId, required this.amount});

  final String rewardId;
  final int amount;

  String get requestId => 'xp_$rewardId';
}

/// This form previews only. No XP, game events or hero data are mutated until
/// the controller completes the explicit confirmExperienceReward transaction.
class ExperienceRewardDialog extends StatefulWidget {
  const ExperienceRewardDialog({super.key, required this.campaign});

  final Campaign campaign;

  @override
  State<ExperienceRewardDialog> createState() => _ExperienceRewardDialogState();
}

class _ExperienceRewardDialogState extends State<ExperienceRewardDialog> {
  final _rewardId = TextEditingController();
  final _amount = TextEditingController();
  bool _approved = false;

  @override
  void dispose() {
    _rewardId.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = _rewardId.text.trim();
    final amount = int.tryParse(_amount.text);
    Campaign? preview;
    String? error;
    if (widget.campaign.hero.experience == null) {
      error =
          'Bitte zuerst den bisherigen EP-Stand im Charakterbogen bestätigen.';
    } else if (id.isNotEmpty || _amount.text.isNotEmpty) {
      if (!RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(id)) {
        error =
            'Eindeutige Kennung: 1–100 Zeichen, Buchstaben, Ziffern, _ oder -.';
      } else if (amount == null || amount < 1 || amount > 100000) {
        error = 'Bitte 1 bis 100000 EP eingeben.';
      } else {
        try {
          preview = ExperienceProgression.grant(
            widget.campaign,
            rewardId: id,
            amount: amount,
          );
        } on FormatException catch (failure) {
          error = failure.message;
        }
      }
    }
    final alreadyBooked =
        preview != null && identical(preview, widget.campaign);
    final canSubmit = preview != null && _approved;
    final currentXp = widget.campaign.hero.experience;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      // Keep action buttons outside the scrollable content when the IME
      // consumes most of a compact Android display.
      scrollable: true,
      title: const Text('EP-Belohnung bestätigen'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nur tatsächlich vereinbarte Belohnungen eintragen. '
              'Eine KI-Erzählung vergibt niemals eigenständig EP.',
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('xp-reward-id'),
              controller: _rewardId,
              maxLength: 100,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
              decoration: const InputDecoration(
                labelText: 'Eindeutige Belohnungskennung',
                hintText: 'z. B. quest-kapitel-1',
                helperText:
                    'Für dieselbe Belohnung immer dieselbe Kennung nutzen.',
                helperMaxLines: 2,
              ),
              onChanged: (_) => setState(() => _approved = false),
            ),
            const SizedBox(height: 6),
            TextField(
              key: const ValueKey('xp-reward-amount'),
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Erfahrungspunkte (EP)',
                hintText: 'z. B. 300',
              ),
              onChanged: (_) => setState(() => _approved = false),
            ),
            const SizedBox(height: 8),
            FantasyPanel(
              padding: const EdgeInsets.all(12),
              material: FantasyPanelMaterial.parchment,
              child: Semantics(
                liveRegion: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Buchungsvorschau',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bisher: ${currentXp?.toString() ?? 'nicht bestätigt'} EP',
                    ),
                    if (preview != null)
                      Text(
                        alreadyBooked
                            ? 'Bereits gebucht: keine zusätzlichen EP. '
                                  'Die vorhandene Quittung wird geprüft.'
                            : 'Nach Bestätigung: ${preview.hero.experience} EP',
                        key: const ValueKey('xp-reward-preview'),
                      ),
                    if (error != null)
                      Text(
                        error,
                        key: const ValueKey('xp-reward-validation'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              key: const ValueKey('xp-reward-consent'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _approved,
              title: const Text(
                'Ich bestätige diese EP-Belohnung ausdrücklich.',
              ),
              onChanged: (value) => setState(() => _approved = value ?? false),
            ),
          ],
        ),
      ),
      actionsOverflowDirection: VerticalDirection.down,
      actions: [
        FantasyTextButton(
          key: const ValueKey('xp-reward-cancel'),
          label: 'Abbrechen',
          style: FantasyButtonStyle.iron,
          onPressed: () => Navigator.of(context).pop(),
        ),
        FantasyTextButton(
          key: const ValueKey('xp-reward-confirm'),
          label: alreadyBooked ? 'Buchung prüfen' : 'EP verbindlich buchen',
          style: FantasyButtonStyle.arcane,
          onPressed: canSubmit
              ? () => Navigator.of(
                  context,
                ).pop(ExperienceRewardChoice(rewardId: id, amount: amount!))
              : null,
        ),
      ],
    );
  }
}
