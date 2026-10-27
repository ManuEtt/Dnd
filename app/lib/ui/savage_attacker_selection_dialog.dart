import 'package:flutter/material.dart';

import '../domain/dice_engine.dart';
import '../domain/models.dart';
import '../domain/srd_savage_attacker_rules.dart';
import 'fantasy_buttons.dart';

/// User intent only. The combat controller MUST independently verify the
/// stored dice, attack identity and expected revision before any HP changes.
/// No dice or damage totals from the UI are trusted for persistence.
class SavageAttackerSelectionRequest {
  const SavageAttackerSelectionRequest({
    required this.attackRollId,
    required this.encounterId,
    required this.expectedRevision,
    required this.chooseAlternative,
  });

  final String attackRollId, encounterId;
  final int expectedRevision;
  final bool chooseAlternative;
}

/// Displays two already rolled, rule-verified weapon dice pools.
///
/// This dialog does not generate dice, commit an attack or consume a feat.
/// Only a future revision-checked GameController action may apply the choice.
class SavageAttackerSelectionDialog extends StatefulWidget {
  const SavageAttackerSelectionDialog({
    super.key,
    required this.campaign,
    required this.attackRollId,
    required this.encounterId,
    required this.weaponDamageExpression,
    required this.original,
    required this.alternative,
    required this.confirmedWeaponHit,
    required this.confirmedWeaponAttack,
    this.critical = false,
    this.originalCriticalExtra,
    this.alternativeCriticalExtra,
  });

  final Campaign campaign;
  final String attackRollId, encounterId, weaponDamageExpression;
  final DiceResult original, alternative;
  final DiceResult? originalCriticalExtra, alternativeCriticalExtra;
  final bool confirmedWeaponHit, confirmedWeaponAttack, critical;

  @override
  State<SavageAttackerSelectionDialog> createState() =>
      _SavageAttackerSelectionDialogState();
}

class _SavageAttackerSelectionDialogState
    extends State<SavageAttackerSelectionDialog> {
  bool? _chooseAlternative;

  SavageAttackerChoice? _verified() {
    final fight = widget.campaign.encounter;
    if (fight == null ||
        fight.id != widget.encounterId ||
        widget.attackRollId.isEmpty ||
        widget.attackRollId.length > 128 ||
        widget.campaign.revision < 0 ||
        !SrdSavageAttackerRules.canOfferOnTurn(
          widget.campaign.hero,
          fight,
        )) {
      return null;
    }
    try {
      return SrdSavageAttackerRules.choose(
        hero: widget.campaign.hero,
        weaponDamageExpression: widget.weaponDamageExpression,
        original: widget.original,
        alternative: widget.alternative,
        confirmedWeaponHit: widget.confirmedWeaponHit,
        confirmedWeaponAttack: widget.confirmedWeaponAttack,
        alreadyUsedThisTurn: fight.savageAttackerUsedThisTurn,
        chooseAlternative: _chooseAlternative ?? false,
        critical: widget.critical,
        originalCriticalExtra: widget.originalCriticalExtra,
        alternativeCriticalExtra: widget.alternativeCriticalExtra,
      );
    } on FormatException {
      return null;
    }
  }

  void _submit() {
    if (_chooseAlternative == null || _verified() == null) return;
    Navigator.of(context).pop(
      SavageAttackerSelectionRequest(
        attackRollId: widget.attackRollId,
        encounterId: widget.encounterId,
        expectedRevision: widget.campaign.revision,
        chooseAlternative: _chooseAlternative!,
      ),
    );
  }

  String _diceFaces(DiceResult roll, DiceResult? criticalExtra) {
    final faces = roll.rolls.join(' + ');
    if (criticalExtra == null) return faces;
    return '$faces + kritisch: ${criticalExtra.rolls.join(' + ')}';
  }

  @override
  Widget build(BuildContext context) {
    final verified = _verified();
    final valid = verified != null;
    final fight = widget.campaign.encounter;
    return AlertDialog(
      key: const ValueKey('savage-attacker-selection-dialog'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      title: const Text('Wilder Angreifer: Schaden wählen'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (fight != null) Text('Angriffsziel: ${fight.enemyName}'),
              const SizedBox(height: 8),
              const Text(
                'Wähle ausdrücklich einen der beiden Waffenwürfe. '
                'Der höhere Wert wird nicht automatisch übernommen. '
                'Attributs-, Klassen- und andere Schadensboni '
                'sind hier nicht enthalten.',
              ),
              if (widget.critical) ...[
                const SizedBox(height: 8),
                const Text(
                  'Kritischer Treffer: Beide Möglichkeiten enthalten '
                  'ihre eigenen zusätzlichen Waffenwürfel.',
                  key: ValueKey('savage-attacker-critical-explanation'),
                ),
              ],
              const SizedBox(height: 12),
              if (!valid)
                const Text(
                  'Auswahl nicht verfügbar: Der bestätigte Treffer, '
                  'die unverbrauchten Talentvoraussetzungen oder die '
                  'Würfelnachweise sind ungültig.',
                  key: ValueKey('savage-attacker-invalid'),
                )
              else ...[
                ListTile(
                  key: const ValueKey('savage-attacker-original'),
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _chooseAlternative == false
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(
                    'Erster Wurf: ${verified.originalWeaponDiceTotal}',
                  ),
                  subtitle: Text(
                    _diceFaces(
                      widget.original,
                      widget.originalCriticalExtra,
                    ),
                  ),
                  selected: _chooseAlternative == false,
                  onTap: () => setState(() => _chooseAlternative = false),
                ),
                ListTile(
                  key: const ValueKey('savage-attacker-alternative'),
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _chooseAlternative == true
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(
                    'Zweiter Wurf: ${verified.alternativeWeaponDiceTotal}',
                  ),
                  subtitle: Text(
                    _diceFaces(
                      widget.alternative,
                      widget.alternativeCriticalExtra,
                    ),
                  ),
                  selected: _chooseAlternative == true,
                  onTap: () => setState(() => _chooseAlternative = true),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fester Waffenbonus: ${verified.weaponFlatModifier >= 0 ? '+' : ''}${verified.weaponFlatModifier} '
                  '(wird nur einmal berücksichtigt).',
                  key: const ValueKey('savage-attacker-flat-modifier'),
                ),
              ],
              const SizedBox(height: 12),
              const Text(
                'Erst der Kampfcontroller darf die gewählte Alternative '
                'nach einer erneuten Revisions- und Zielprüfung auf '
                'Schaden und Talentverbrauch anwenden.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        FantasyTextButton(
          key: const ValueKey('savage-attacker-cancel'),
          label: 'Abbrechen',
          style: FantasyButtonStyle.iron,
          onPressed: () => Navigator.of(context).pop(),
        ),
        FantasyTextButton(
          key: const ValueKey('savage-attacker-confirm'),
          label: 'Wurf bestätigen',
          icon: Icons.check_circle_outline,
          onPressed: valid && _chooseAlternative != null ? _submit : null,
        ),
      ],
    );
  }
}
