import 'package:flutter/material.dart';
import 'fantasy_buttons.dart';

import '../domain/cover_rules.dart';
import '../domain/damage_rules.dart';
import '../domain/models.dart';
import '../domain/srd_extra_creature_attack_rules.dart';

class ManualAttackChoice {
  const ManualAttackChoice({
    required this.attackerId,
    required this.targetId,
    required this.attack,
  });
  final String attackerId, targetId;
  final ConfirmedExtraCreatureAttack attack;
}

/// Conservative one-attack form: no monster traits are derived from names.
class ManualExtraCreatureAttackDialog extends StatefulWidget {
  const ManualExtraCreatureAttackDialog({super.key, required this.campaign});

  final Campaign campaign;

  @override
  State<ManualExtraCreatureAttackDialog> createState() =>
      _ManualExtraCreatureAttackDialogState();
}

class _ManualExtraCreatureAttackDialogState
    extends State<ManualExtraCreatureAttackDialog> {
  final _bonus = TextEditingController();
  final _damage = TextEditingController();
  final _ac = TextEditingController();
  String? _targetId, _error;
  DamageType? _damageType;
  CoverLevel? _cover;
  bool _opposite = false;
  bool _reach = false, _actorCanAct = false, _targetAvailable = false;
  bool _modifiers = false, _defenses = false, _reactions = false;
  bool _noEffects = false, _advantage = false, _disadvantage = false;

  @override
  void dispose() {
    _bonus.dispose();
    _damage.dispose();
    _ac.dispose();
    super.dispose();
  }

  Widget _check(
    String suffix,
    String title,
    bool value,
    ValueChanged<bool> change,
  ) => CheckboxListTile(
    key: ValueKey('manual-attack-$suffix'),
    title: Text(title),
    dense: true,
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    value: value,
    onChanged: (next) => setState(() {
      change(next ?? false);
      _error = null;
    }),
  );

  void _confirm() {
    final queue = widget.campaign.manualTurnQueue;
    final attackerId = queue?.activeActorId;
    final bonus = int.tryParse(_bonus.text.trim());
    final ac = int.tryParse(_ac.text.trim());
    final damage = _damage.text.trim();
    if (attackerId == null ||
        _targetId == null ||
        bonus == null ||
        bonus < -30 ||
        bonus > 30 ||
        ac == null ||
        ac < 1 ||
        ac > 95 ||
        _cover == null ||
        _damageType == null ||
        !_reach ||
        !_actorCanAct ||
        !_targetAvailable ||
        !_modifiers ||
        !_defenses ||
        !_reactions ||
        !_noEffects) {
      setState(
        () => _error =
            'Bestätigte Angriffs- und Zielwerte '
            'sowie alle geltenden Voraussetzungen sind erforderlich.',
      );
      return;
    }
    final attack = ConfirmedExtraCreatureAttack(
      attackBonus: bonus,
      weaponDamage: damage,
      damageType: _damageType!,
      targetArmorClass: ac,
      targetCover: _cover!,
      coverOppositeAttacker: _opposite,
      targetInReachConfirmed: _reach,
      attackerCanActConfirmed: _actorCanAct,
      targetCanBeAttackedConfirmed: _targetAvailable,
      noUnmodelledAttackModifiersConfirmed: _modifiers,
      noUnmodelledDamageAdjustmentsConfirmed: _defenses,
      noTargetReactionConfirmed: _reactions,
      noAdditionalAttackEffectsConfirmed: _noEffects,
      advantage: _advantage,
      disadvantage: _disadvantage,
    );
    // The domain resolver validates the dice expression before rolling.
    // The UI performs an equivalent lightweight check to avoid closing.
    if (!RegExp(
          r'^([1-9][0-9]?)[dDwW](4|6|8|10|12)([+-][0-9]{1,2})?$',
        ).hasMatch(damage) ||
        int.parse(RegExp(r'^[0-9]+').firstMatch(damage)!.group(0)!) > 10) {
      setState(
        () => _error =
            'Waffenschaden als bestätigter Würfelausdruck (z. B. 1d6+2).',
      );
      return;
    }
    Navigator.of(context).pop(
      ManualAttackChoice(
        attackerId: attackerId,
        targetId: _targetId!,
        attack: attack,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final queue = widget.campaign.manualTurnQueue;
    final attacker = widget.campaign.trackedAreaCreatures
        .where((creature) => creature.id == queue?.activeActorId)
        .toList();
    final eligible = widget.campaign.trackedAreaCreatures
        .where(
          (creature) =>
              creature.id != queue?.activeActorId && creature.hitPoints > 0,
        )
        .toList();
    final available =
        queue != null &&
        !queue.actionUsed &&
        attacker.length == 1 &&
        attacker.single.hitPoints > 0 &&
        attacker.single.initiativeController == 'gm' &&
        eligible.isNotEmpty;
    return AlertDialog(
      title: const Text('Zusätzlicher Kreaturenangriff'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Eine bestätigte einfache Waffen-Aktion der '
                'aktuellen Zusatzkreatur gegen eine ANDERE erfasste '
                'Zusatzkreatur. Held und Hauptgegner bleiben im '
                'bisherigen Kampfsystem. Keine automatischen '
                'Monsterwerte, Reaktionen oder Sonderfähigkeiten.',
              ),
              if (queue != null)
                Text(
                  'Angreifer-ID: ${queue.activeActorId}, '
                  'manuelle Runde ${queue.round}, '
                  'Aktion ${queue.actionUsed ? 'verbraucht' : 'frei'}.',
                ),
              DropdownButtonFormField<String>(
                key: const ValueKey('manual-attack-target'),
                initialValue: _targetId,
                decoration: const InputDecoration(
                  labelText: 'Lebendes Zusatzkreaturen-Ziel',
                ),
                items: [
                  for (final creature in eligible)
                    DropdownMenuItem(
                      value: creature.id,
                      child: Text(
                        '${creature.name} '
                        '(${creature.hitPoints} TP)',
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _targetId = v),
              ),
              TextField(
                key: const ValueKey('manual-attack-bonus'),
                controller: _bonus,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Vollständiger Angriffsbonus, z. B. +4',
                ),
              ),
              TextField(
                key: const ValueKey('manual-attack-damage'),
                controller: _damage,
                decoration: const InputDecoration(
                  labelText: 'Bestätigter Waffenschaden, z. B. 1d6+2',
                ),
              ),
              DropdownButtonFormField<DamageType>(
                key: const ValueKey('manual-attack-damage-type'),
                initialValue: _damageType,
                decoration: const InputDecoration(
                  labelText: 'Bestätigte Schadensart',
                ),
                items: [
                  for (final type in DamageType.values)
                    DropdownMenuItem(value: type, child: Text(type.name)),
                ],
                onChanged: (v) => setState(() {
                  if (v != null) _damageType = v;
                }),
              ),
              TextField(
                key: const ValueKey('manual-attack-ac'),
                controller: _ac,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Bestätigte Grund-RK des Ziels',
                ),
              ),
              DropdownButtonFormField<CoverLevel>(
                key: const ValueKey('manual-attack-cover'),
                initialValue: _cover,
                decoration: const InputDecoration(
                  labelText: 'Deckung des Ziels',
                ),
                items: [
                  for (final cover in CoverLevel.values)
                    DropdownMenuItem(
                      value: cover,
                      child: Text(CoverRules.label(cover)),
                    ),
                ],
                onChanged: (v) => setState(() => _cover = v),
              ),
              _check(
                'opposite',
                'Deckung ist zwischen Angreifer und Ziel.',
                _opposite,
                (v) => _opposite = v,
              ),
              _check(
                'reach',
                'Ziel ist innerhalb bestätigter Waffenreichweite.',
                _reach,
                (v) => _reach = v,
              ),
              _check(
                'actor',
                'Angreifer ist handlungsfähig; '
                    'keine unbekannten Bewegungs-/Zustandseffekte.',
                _actorCanAct,
                (v) => _actorCanAct = v,
              ),
              _check(
                'target-valid',
                'Dieses Ziel darf aktuell '
                    'angegriffen werden.',
                _targetAvailable,
                (v) => _targetAvailable = v,
              ),
              _check(
                'modifiers',
                'Alle Angriffs-Modifikatoren einschließlich '
                    'Sonderfähigkeiten geprüft.',
                _modifiers,
                (v) => _modifiers = v,
              ),
              _check(
                'defenses',
                'Keine ungeklärte Schadensabwehr, '
                    'Immunität, Anfälligkeit, Zustands- oder andere '
                    'Schadensmodifikation.',
                _defenses,
                (v) => _defenses = v,
              ),
              _check(
                'reactions',
                'Keine anstehende Ziel-Reaktion '
                    'wie Schild oder Abwehr.',
                _reactions,
                (v) => _reactions = v,
              ),
              _check(
                'no-effects',
                'Kein zusätzliches Angriffs-'
                    'oder kritisches Treffereffekt-Merkmal.',
                _noEffects,
                (v) => _noEffects = v,
              ),
              _check(
                'advantage',
                'Bestätigter Vorteil auf Angriff.',
                _advantage,
                (v) => _advantage = v,
              ),
              _check(
                'disadvantage',
                'Bestätigter Nachteil auf Angriff.',
                _disadvantage,
                (v) => _disadvantage = v,
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
          key: const ValueKey('manual-attack-confirm'),
          label: 'Angriff würfeln',
          style: FantasyButtonStyle.wax,
          onPressed: available ? _confirm : null,
        ),
      ],
    );
  }
}
