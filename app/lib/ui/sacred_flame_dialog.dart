import 'package:flutter/material.dart';

import '../domain/cover_rules.dart';
import '../domain/models.dart';
import '../domain/sacred_flame_rules.dart';

/// The monster's complete, verified Dexterity saving throw modifier is an
/// explicit input. Neither AI prose nor the monster's AC determines it.
class SacredFlameChoice {
  const SacredFlameChoice({
    required this.confirmedTargetDexteritySaveModifier,
    required this.targetVisibleConfirmed,
    required this.targetWithinRangeConfirmed,
    required this.verbalComponentConfirmed,
    required this.somaticComponentConfirmed,
    required this.noRadiantDamageAdjustmentConfirmed,
    required this.noUnmodelledDcModifiersConfirmed,
    required this.saveCircumstancesConfirmed,
    required this.saveAdvantage,
    required this.saveDisadvantage,
  });

  final int confirmedTargetDexteritySaveModifier;
  final bool targetVisibleConfirmed, targetWithinRangeConfirmed;
  final bool verbalComponentConfirmed, somaticComponentConfirmed;
  final bool noRadiantDamageAdjustmentConfirmed;
  final bool noUnmodelledDcModifiersConfirmed;
  final bool saveCircumstancesConfirmed, saveAdvantage, saveDisadvantage;
}

class SacredFlameDialog extends StatefulWidget {
  const SacredFlameDialog({
    super.key,
    required this.hero,
    required this.encounter,
  });

  final HeroCharacter hero;
  final Encounter encounter;

  @override
  State<SacredFlameDialog> createState() => _SacredFlameDialogState();
}

class _SacredFlameDialogState extends State<SacredFlameDialog> {
  final _saveModifier = TextEditingController();
  bool _visible = false;
  bool _range = false;
  bool _verbal = false;
  bool _somatic = false;
  bool _noRadiantDefense = false;
  bool _noExtraDc = false;
  bool _saveCircumstances = false;
  bool _saveAdvantage = false;
  bool _saveDisadvantage = false;
  String? _error;

  @override
  void dispose() {
    _saveModifier.dispose();
    super.dispose();
  }

  Widget _check(
    String key,
    String title,
    bool value,
    ValueChanged<bool> change,
  ) => CheckboxListTile(
    key: ValueKey('sacred-flame-$key'),
    title: Text(title),
    dense: true,
    controlAffinity: ListTileControlAffinity.leading,
    contentPadding: EdgeInsets.zero,
    value: value,
    onChanged: (next) => setState(() {
      change(next ?? false);
      _error = null;
    }),
  );

  void _confirm() {
    final parsed = int.tryParse(_saveModifier.text.trim());
    if (!SacredFlameRules.isClericCaster(widget.hero) ||
        SacredFlameRules.preparedName(widget.hero) == null ||
        parsed == null ||
        parsed < -30 ||
        parsed > 30 ||
        !_visible ||
        !_range ||
        !_verbal ||
        !_somatic ||
        !_noRadiantDefense ||
        !_noExtraDc ||
        !_saveCircumstances ||
        widget.encounter.enemyCover == CoverLevel.total) {
      setState(
        () => _error =
            'Gegner-Rettungswurfbonus (−30 bis +30) und alle '
            'tatsächlichen Voraussetzungen müssen bestätigt sein.',
      );
      return;
    }
    Navigator.of(context).pop(
      SacredFlameChoice(
        confirmedTargetDexteritySaveModifier: parsed,
        targetVisibleConfirmed: _visible,
        targetWithinRangeConfirmed: _range,
        verbalComponentConfirmed: _verbal,
        somaticComponentConfirmed: _somatic,
        noRadiantDamageAdjustmentConfirmed: _noRadiantDefense,
        noUnmodelledDcModifiersConfirmed: _noExtraDc,
        saveCircumstancesConfirmed: _saveCircumstances,
        saveAdvantage: _saveAdvantage,
        saveDisadvantage: _saveDisadvantage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Heilige Flamme wirken'),
    content: SizedBox(
      width: 470,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ziel: ${widget.encounter.enemyName}. '
              '60 Fuß, Aktion, V/S. Geschicklichkeitsrettungswurf '
              'gegen deinen Kleriker-Zauber-SG. Halbe und '
              'Dreivierteldeckung geben keinen Rettungswurfbonus.',
            ),
            if (!SacredFlameRules.isClericCaster(widget.hero) ||
                SacredFlameRules.preparedName(widget.hero) == null)
              const Text('Kein bestätigter Kleriker-Zaubertrick verfügbar.'),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('sacred-flame-enemy-save-modifier'),
              controller: _saveModifier,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: const InputDecoration(
                labelText: 'Bestätigter vollständiger GES-Rettungswurfbonus',
                helperText: 'Aus bestätigtem SRD-Statblock, z. B. +2 oder −1',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            _check('visible', 'Ziel ist sichtbar.', _visible, (v) {
              _visible = v;
            }),
            _check('range', 'Ziel ist innerhalb von 60 Fuß.', _range, (v) {
              _range = v;
            }),
            _check('verbal', 'Verbale Komponente ist möglich.', _verbal, (v) {
              _verbal = v;
            }),
            _check('somatic', 'Gestische Komponente ist möglich.', _somatic, (
              v,
            ) {
              _somatic = v;
            }),
            _check(
              'radiant-defense',
              'Keine ungeklärte Strahlenschaden-Resistenz, '
                  '-immunität, -anfälligkeit oder sonstige Modifikation.',
              _noRadiantDefense,
              (v) => _noRadiantDefense = v,
            ),
            _check(
              'dc',
              'Keine weiteren Zauber-SG-Modifikatoren durch '
                  'Ausrüstung, magische Gegenstände oder Fähigkeiten.',
              _noExtraDc,
              (v) => _noExtraDc = v,
            ),
            _check(
              'circumstances',
              'Rettungswurf-Vorteil, -Nachteil und automatische '
                  'Fehlschläge aus Zuständen sind geprüft.',
              _saveCircumstances,
              (v) => _saveCircumstances = v,
            ),
            _check(
              'advantage',
              'Gegner hat bestätigten Vorteil auf diesen Rettungswurf.',
              _saveAdvantage,
              (v) => _saveAdvantage = v,
            ),
            _check(
              'disadvantage',
              'Gegner hat bestätigten Nachteil auf diesen Rettungswurf.',
              _saveDisadvantage,
              (v) => _saveDisadvantage = v,
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
        child: const Text('Abbrechen'),
      ),
      FilledButton(
        key: const ValueKey('sacred-flame-cast'),
        onPressed:
            !SacredFlameRules.isClericCaster(widget.hero) ||
                SacredFlameRules.preparedName(widget.hero) == null
            ? null
            : _confirm,
        child: const Text('Rettungswurf würfeln'),
      ),
    ],
  );
}
