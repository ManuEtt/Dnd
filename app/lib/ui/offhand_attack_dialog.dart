import 'package:flutter/material.dart';

import '../domain/models.dart';
import '../domain/two_weapon_fighting_rules.dart';
import 'fantasy_buttons.dart';

/// Explicit observations for one Light melee bonus-action attack. This result
/// is only a request; the controller validates the current campaign again.
class OffhandAttackChoice {
  const OffhandAttackChoice({
    required this.weaponId,
    required this.attackAbility,
    required this.weaponProficient,
    required this.weaponsHeldConfirmed,
    required this.playerConfirmed,
  });

  final String weaponId, attackAbility;
  final bool weaponProficient, weaponsHeldConfirmed, playerConfirmed;
}

enum _WeaponTraining { unverified, proficient, untrained }

class OffhandAttackDialog extends StatefulWidget {
  const OffhandAttackDialog({
    super.key,
    required this.hero,
    required this.targetName,
  });

  final HeroCharacter hero;
  final String targetName;

  @override
  State<OffhandAttackDialog> createState() => _OffhandAttackDialogState();
}

class _OffhandAttackDialogState extends State<OffhandAttackDialog> {
  String? _weaponId, _ability;
  _WeaponTraining _training = _WeaponTraining.unverified;
  bool _held = false, _approved = false;

  bool? get _proficient => switch (_training) {
    _WeaponTraining.unverified => null,
    _WeaponTraining.proficient => true,
    _WeaponTraining.untrained => false,
  };

  void _change(VoidCallback update) {
    setState(() {
      update();
      _approved = false;
    });
  }

  String _signed(int value) => value < 0 ? '$value' : '+$value';

  @override
  Widget build(BuildContext context) {
    final weapons = TwoWeaponFightingRules.offhandChoices(widget.hero);
    final weapon = _weaponId == null
        ? null
        : TwoWeaponFightingRules.confirmedOffhand(widget.hero, _weaponId!);
    final finesse = weapon?.hasProperty('finesse') ?? false;
    int? attackBonus, damageModifier;
    String? failure;
    if (weapon != null && _ability != null && _proficient != null) {
      try {
        attackBonus = TwoWeaponFightingRules.attackBonus(
          widget.hero,
          weapon,
          attackAbility: _ability,
          proficient: _proficient,
        );
        damageModifier = TwoWeaponFightingRules.damageModifier(
          widget.hero,
          weapon,
          attackAbility: _ability,
        );
      } catch (error) {
        failure = error.toString().replaceFirst('FormatException: ', '');
      }
    }
    final valid = attackBonus != null && damageModifier != null;
    final canConfirm = valid && _held && _approved;
    return AlertDialog(
      key: const ValueKey('offhand-attack-dialog'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      title: const Text('Nebenhandangriff bestätigen'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Angriffsziel: ${widget.targetName}'),
              const SizedBox(height: 10),
              const Text(
                'Nach dem Angriff mit einer leichten Nahkampfwaffe kannst du '
                'mit einer anderen leichten Nahkampfwaffe einmal als '
                'Bonusaktion angreifen. Bestätige die tatsächlich benutzte '
                'Waffe, ihr Attribut und deine Waffenübung.',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const ValueKey('offhand-weapon'),
                initialValue: _weaponId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Nebenhandwaffe'),
                items: [
                  for (final item in weapons)
                    DropdownMenuItem(
                      value: item.id,
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => _change(() {
                  _weaponId = value;
                  final selected = value == null
                      ? null
                      : TwoWeaponFightingRules.confirmedOffhand(
                          widget.hero,
                          value,
                        );
                  _ability = selected?.hasProperty('finesse') == true
                      ? null
                      : 'strength';
                  _training = _WeaponTraining.unverified;
                  _held = false;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('offhand-ability-${_weaponId ?? "none"}'),
                initialValue: _ability,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Angriffsattribut',
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'strength',
                    child: Text('Stärke'),
                  ),
                  if (finesse)
                    const DropdownMenuItem(
                      value: 'dexterity',
                      child: Text('Geschicklichkeit (Finesse)'),
                    ),
                ],
                onChanged: weapon == null
                    ? null
                    : (value) => _change(() => _ability = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<_WeaponTraining>(
                key: ValueKey('offhand-proficiency-${_weaponId ?? "none"}'),
                initialValue: _training,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Waffenübung'),
                items: const [
                  DropdownMenuItem(
                    value: _WeaponTraining.unverified,
                    child: Text('Nicht bestätigt'),
                  ),
                  DropdownMenuItem(
                    value: _WeaponTraining.proficient,
                    child: Text('Mit dieser Waffe geübt'),
                  ),
                  DropdownMenuItem(
                    value: _WeaponTraining.untrained,
                    child: Text('Mit dieser Waffe nicht geübt'),
                  ),
                ],
                onChanged: (value) => _change(
                  () => _training = value ?? _WeaponTraining.unverified,
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                key: const ValueKey('offhand-weapons-held'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Beide verschiedenen Waffen werden bestätigt gehalten; '
                  'die Nebenhandwaffe ist für diesen Angriff verfügbar.',
                ),
                value: _held,
                onChanged: (value) => _change(() => _held = value ?? false),
              ),
              if (valid) ...[
                const SizedBox(height: 8),
                Text(
                  'Angriff: W20 ${_signed(attackBonus)}. '
                  'Waffenschaden: ${weapon!.damage} '
                  '${_signed(damageModifier)}.',
                  key: const ValueKey('offhand-attack-preview'),
                ),
                Text(
                  TwoWeaponFightingRules.getStyle(widget.hero)
                      ? 'Kampfstil: Der Attributsmodifikator wird beim '
                            'Zusatzangriff genau einmal addiert.'
                      : 'Ohne den Kampfstil wird ein positiver '
                            'Attributsmodifikator nicht zum Schaden addiert. '
                            'Ein negativer Modifikator bleibt wirksam.',
                ),
              ],
              if (failure != null)
                Text(failure, key: const ValueKey('offhand-attack-error')),
              const SizedBox(height: 8),
              const Text(
                'Erst nach deiner Bestätigung wird die freie Bonusaktion '
                'für diese Probe reserviert. Schaden entsteht erst bei '
                'einem regelgültigen Treffer.',
              ),
              CheckboxListTile(
                key: const ValueKey('offhand-attack-approved'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Ich bestätige diese Werte und den Verbrauch '
                  'meiner Bonusaktion.',
                ),
                value: _approved,
                onChanged: valid && _held
                    ? (value) => setState(() => _approved = value ?? false)
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        FantasyTextButton(
          key: const ValueKey('offhand-attack-cancel'),
          label: 'Abbrechen',
          style: FantasyButtonStyle.iron,
          onPressed: () => Navigator.pop(context),
        ),
        FantasyTextButton(
          key: const ValueKey('offhand-attack-confirm'),
          label: 'Nebenhandangriff vorbereiten',
          icon: Icons.sports_martial_arts,
          onPressed: canConfirm
              ? () => Navigator.pop(
                  context,
                  OffhandAttackChoice(
                    weaponId: _weaponId!,
                    attackAbility: _ability!,
                    weaponProficient: _proficient!,
                    weaponsHeldConfirmed: _held,
                    playerConfirmed: _approved,
                  ),
                )
              : null,
        ),
      ],
    );
  }
}
