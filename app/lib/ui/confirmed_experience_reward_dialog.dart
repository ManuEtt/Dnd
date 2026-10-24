import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'fantasy_buttons.dart';
import 'fantasy_experience.dart';
import 'fantasy_ui.dart';

/// A human-confirmed reward selection. It is not a grant until GameController
/// commits the matching request ID, event, revision and hero to SQLite.
class ConfirmedExperienceRewardChoice {
  const ConfirmedExperienceRewardChoice({
    required this.rewardId,
    required this.amount,
  });

  final String rewardId;
  final int amount;

  /// Derived from the campaign-local reward key: retrying after restart uses
  /// the exact same receipt, never a fresh timestamp or random request ID.
  String get requestId => 'xp-ui-$rewardId';
}

/// Explicit player confirmation of a manually established milestone.
/// No narrator or AI response can fill, approve or submit this form.
class ConfirmedExperienceRewardDialog extends StatefulWidget {
  const ConfirmedExperienceRewardDialog({
    super.key,
    required this.campaign,
  });

  final Campaign campaign;

  @override
  State<ConfirmedExperienceRewardDialog> createState() =>
      _ConfirmedExperienceRewardDialogState();
}

class _ConfirmedExperienceRewardDialogState
    extends State<ConfirmedExperienceRewardDialog> {
  final _form = GlobalKey<FormState>();
  final _rewardId = TextEditingController();
  final _amount = TextEditingController();

  @override
  void dispose() {
    _rewardId.dispose();
    _amount.dispose();
    super.dispose();
  }

  int? get _parsedAmount => int.tryParse(_amount.text.trim());
  String get _id => _rewardId.text.trim();
  String? get _receipt => widget.campaign.facts['xp.reward.$_id'];

  String? _validateId(String? value) {
    final id = (value ?? '').trim();
    if (!RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(id)) {
      return '1–100 Zeichen: Buchstaben, Ziffern, _ oder -.';
    }
    return null;
  }

  String? _validateAmount(String? value) {
    final points = int.tryParse((value ?? '').trim());
    if (points == null || points < 1 || points > 100000) {
      return 'Bitte 1 bis 100.000 EP eingeben.';
    }
    final xp = widget.campaign.hero.experience;
    if (xp == null) return 'Bisherigen EP-Stand zuerst bestätigen.';
    if (_receipt != null && _receipt != points.toString()) {
      return 'Diese Kennung hat bereits einen anderen EP-Betrag.';
    }
    if (_receipt == null && xp > 1000000 - points) {
      return 'Die maximale EP-Grenze würde überschritten.';
    }
    return null;
  }

  void _confirm() {
    if (!_form.currentState!.validate()) return;
    Navigator.of(context).pop(
      ConfirmedExperienceRewardChoice(
        rewardId: _id,
        amount: _parsedAmount!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final xp = widget.campaign.hero.experience;
    final points = _parsedAmount;
    final validId = _validateId(_id) == null;
    final duplicate = validId && _receipt != null;
    final amountOk = _validateAmount(_amount.text) == null;
    final after = amountOk && xp != null && points != null
        ? xp + (duplicate ? 0 : points)
        : null;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          key: const ValueKey('xp-reward-scroll'),
          padding: const EdgeInsets.all(12),
          child: FantasyPanel(
            padding: const EdgeInsets.all(12),
            material: FantasyPanelMaterial.leather,
            child: Form(
              key: _form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      FantasyRuneEmblem(
                        rune: FantasyRune.tome,
                        size: 38,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'EP-Belohnung bestätigen',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Held: ${widget.campaign.hero.name}'),
                  Text('Bisher: ${xp == null ? 'nicht bestätigt' : '$xp EP'}'),
                  const SizedBox(height: 10),
                  const Text(
                    'Nur tatsächlich erreichte, geprüfte Questziele '
                    'manuell vergeben. Die Erzählung allein ist kein Beleg.',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('xp-reward-id'),
                    controller: _rewardId,
                    textInputAction: TextInputAction.next,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      labelText: 'Eindeutige Belohnungskennung',
                      hintText: 'z. B. kapitel-1',
                      helperText: 'Gleiche Kennung wird nur einmal gutgeschrieben.',
                    ),
                    validator: _validateId,
                    onChanged: (_) => setState(() {}),
                  ),
                  TextFormField(
                    key: const ValueKey('xp-reward-amount'),
                    controller: _amount,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Erfahrungspunkte (EP)',
                      hintText: 'z. B. 300',
                    ),
                    validator: _validateAmount,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Danach: ${after == null ? '—' : '$after EP'}',
                    key: const ValueKey('xp-reward-preview'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (duplicate && amountOk)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Diese Belohnung ist bereits gespeichert. '
                        'Eine erneute Bestätigung bucht keine weiteren EP.',
                        key: ValueKey('xp-reward-already-confirmed'),
                      ),
                    ),
                  if (xp == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Unbestätigter EP-Stand: erst den Charakterbogen ergänzen.',
                        key: ValueKey('xp-reward-unconfirmed-history'),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      FantasyTextButton(
                        key: const ValueKey('xp-reward-cancel'),
                        label: 'Abbrechen',
                        icon: Icons.close,
                        style: FantasyButtonStyle.iron,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      FantasyTextButton(
                        key: const ValueKey('xp-reward-confirm'),
                        label: 'EP verbindlich bestätigen',
                        icon: Icons.check_circle_outline,
                        style: FantasyButtonStyle.woodGold,
                        onPressed: xp == null ? null : _confirm,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
