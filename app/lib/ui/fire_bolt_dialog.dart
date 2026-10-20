import 'package:flutter/material.dart';

import '../domain/cover_rules.dart';
import '../domain/fire_bolt_rules.dart';
import '../domain/models.dart';

/// Confirmation only. The rules engine owns the dice, damage and checkpoint.
class FireBoltChoice {
  const FireBoltChoice({
    required this.castingClass,
    required this.targetVisibleConfirmed,
    required this.targetWithinRangeConfirmed,
    required this.verbalComponentConfirmed,
    required this.somaticComponentConfirmed,
    required this.noFireResistanceOrImmunityConfirmed,
    required this.noUnresolvedShieldReactionConfirmed,
    required this.situationalAttackConditionsConfirmed,
    required this.advantage,
    required this.disadvantage,
    required this.targetProne,
    required this.targetWithinFiveFeet,
  });

  final String castingClass;
  final bool targetVisibleConfirmed, targetWithinRangeConfirmed;
  final bool verbalComponentConfirmed, somaticComponentConfirmed;
  final bool noFireResistanceOrImmunityConfirmed;
  final bool noUnresolvedShieldReactionConfirmed;
  final bool situationalAttackConditionsConfirmed;
  final bool advantage, disadvantage, targetProne, targetWithinFiveFeet;
}

class FireBoltDialog extends StatefulWidget {
  const FireBoltDialog({
    super.key,
    required this.hero,
    required this.encounter,
  });

  final HeroCharacter hero;
  final Encounter encounter;

  @override
  State<FireBoltDialog> createState() => _FireBoltDialogState();
}

class _FireBoltDialogState extends State<FireBoltDialog> {
  String? _castingClass;
  List<String> _classes = const [];
  String? _setupError, _error;
  bool _visible = false;
  bool _withinRange = false;
  bool _verbal = false;
  bool _somatic = false;
  bool _fireDefenses = false;
  bool _shieldReaction = false;
  bool _circumstances = false;
  bool _advantage = false;
  bool _disadvantage = false;
  bool _prone = false;
  bool _fiveFeet = false;

  @override
  void initState() {
    super.initState();
    try {
      _classes = FireBoltRules.castingClasses(widget.hero);
      if (_classes.isNotEmpty) _castingClass = _classes.first;
    } on FormatException catch (e) {
      _setupError = e.message;
    } on StateError catch (e) {
      _setupError = e.message;
    }
  }

  Widget _check(
    String id,
    String label,
    bool current,
    ValueChanged<bool> change,
  ) => CheckboxListTile(
    key: ValueKey('fire-bolt-$id'),
    dense: true,
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    title: Text(label),
    value: current,
    onChanged: (value) => setState(() {
      change(value ?? false);
      _error = null;
    }),
  );

  void _confirm() {
    if (_castingClass == null ||
        _setupError != null ||
        !_visible ||
        !_withinRange ||
        !_verbal ||
        !_somatic ||
        !_fireDefenses ||
        !_shieldReaction ||
        !_circumstances ||
        widget.encounter.enemyCover == CoverLevel.total) {
      setState(() {
        _error =
            'Bitte alle tatsächlichen Voraussetzungen bestätigen. '
            'Vollständige Deckung verhindert den Angriff.';
      });
      return;
    }
    Navigator.of(context).pop(
      FireBoltChoice(
        castingClass: _castingClass!,
        targetVisibleConfirmed: _visible,
        targetWithinRangeConfirmed: _withinRange,
        verbalComponentConfirmed: _verbal,
        somaticComponentConfirmed: _somatic,
        noFireResistanceOrImmunityConfirmed: _fireDefenses,
        noUnresolvedShieldReactionConfirmed: _shieldReaction,
        situationalAttackConditionsConfirmed: _circumstances,
        advantage: _advantage,
        disadvantage: _disadvantage,
        targetProne: _prone,
        targetWithinFiveFeet: _fiveFeet,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Feuerpfeil wirken'),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Ziel: ${widget.encounter.enemyName}. '
              '120 Fuß, Aktion, V/S, Fernkampf-Zauberangriff. '
              'Zaubertrick ohne Zauberplatz. Keine automatische '
              'Objektentzündung oder ungeprüfte Monsterfähigkeit.',
            ),
            const SizedBox(height: 8),
            if (_setupError != null)
              Text(_setupError!)
            else if (_classes.isEmpty ||
                FireBoltRules.preparedName(widget.hero) == null)
              const Text('Kein bestätigter Feuerpfeil verfügbar.')
            else
              DropdownButtonFormField<String>(
                key: const ValueKey('fire-bolt-class'),
                initialValue: _castingClass,
                decoration: const InputDecoration(
                  labelText: 'Zaubernde Klasse',
                ),
                items: [
                  for (final name in _classes)
                    DropdownMenuItem(value: name, child: Text(name)),
                ],
                onChanged: (value) => setState(() => _castingClass = value),
              ),
            _check('visible', 'Das Ziel ist sichtbar.', _visible, (v) {
              _visible = v;
            }),
            _check('range', 'Das Ziel ist innerhalb von 120 Fuß.', _withinRange, (
              v,
            ) {
              _withinRange = v;
            }),
            _check('verbal', 'Verbale Komponente ist möglich.', _verbal, (v) {
              _verbal = v;
            }),
            _check('somatic', 'Gestische Komponente ist möglich.', _somatic, (v) {
              _somatic = v;
            }),
            _check(
              'defenses',
              'Keine bekannte Feuerresistenz, -immunität, '
                  '-anfälligkeit oder andere Schadensmodifikation.',
              _fireDefenses,
              (v) => _fireDefenses = v,
            ),
            _check(
              'shield',
              'Keine ungeklärte gegnerische Schildreaktion.',
              _shieldReaction,
              (v) => _shieldReaction = v,
            ),
            _check(
              'circumstances',
              'Angriffsumstände (Vorteil, Nachteil, Liegend) sind geprüft.',
              _circumstances,
              (v) => _circumstances = v,
            ),
            _check('advantage', 'Bestätigter Vorteil.', _advantage, (v) {
              _advantage = v;
            }),
            _check('disadvantage', 'Bestätigter Nachteil.', _disadvantage, (v) {
              _disadvantage = v;
            }),
            _check('prone', 'Ziel liegt am Boden.', _prone, (v) {
              _prone = v;
            }),
            _check(
              'five-feet',
              'Ziel befindet sich innerhalb von 5 Fuß.',
              _fiveFeet,
              (v) => _fiveFeet = v,
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Abbrechen'),
      ),
      FilledButton(
        key: const ValueKey('fire-bolt-cast'),
        onPressed: _castingClass == null ||
                _setupError != null ||
                FireBoltRules.preparedName(widget.hero) == null
            ? null
            : _confirm,
        child: const Text('W20 und Schaden würfeln'),
      ),
    ],
  );
}
