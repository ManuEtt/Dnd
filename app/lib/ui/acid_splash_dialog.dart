import 'package:flutter/material.dart';

import '../domain/acid_splash_rules.dart';
import '../domain/cover_rules.dart';
import '../domain/models.dart';

/// Confirmation-only form. A stored Encounter currently has one active foe.
/// The multi-target rule engine is ready, but this UI MUST NOT resolve a
/// genuine multi-creature Sphere without HP storage for every creature.
class AcidSplashChoice {
  const AcidSplashChoice({
    required this.castingClass,
    required this.targetDexteritySaveModifier,
    required this.originWithin60FeetConfirmed,
    required this.onlyCreatureInSphereConfirmed,
    required this.verbalConfirmed,
    required this.somaticConfirmed,
    required this.noUnmodelledDcConfirmed,
    required this.saveCircumstancesConfirmed,
    required this.coverRelationshipConfirmed,
    required this.effectPathConfirmed,
    required this.noAcidDamageAdjustmentConfirmed,
    required this.sourceOppositeCover,
    required this.saveAdvantage,
    required this.saveDisadvantage,
  });

  final String castingClass;
  final int targetDexteritySaveModifier;
  final bool originWithin60FeetConfirmed, onlyCreatureInSphereConfirmed;
  final bool verbalConfirmed, somaticConfirmed, noUnmodelledDcConfirmed;
  final bool saveCircumstancesConfirmed, coverRelationshipConfirmed;
  final bool effectPathConfirmed, noAcidDamageAdjustmentConfirmed;
  final bool sourceOppositeCover, saveAdvantage, saveDisadvantage;
}

class AcidSplashDialog extends StatefulWidget {
  const AcidSplashDialog({
    super.key,
    required this.hero,
    required this.encounter,
  });

  final HeroCharacter hero;
  final Encounter encounter;

  @override
  State<AcidSplashDialog> createState() => _AcidSplashDialogState();
}

class _AcidSplashDialogState extends State<AcidSplashDialog> {
  final _dexModifier = TextEditingController();
  List<String> _classes = const [];
  String? _selectedClass, _error, _setupError;
  bool _origin = false, _only = false, _verbal = false, _somatic = false;
  bool _dc = false, _circumstances = false, _coverConfirmed = false;
  bool _effectPath = false, _acidDefense = false, _oppositeCover = false;
  bool _advantage = false, _disadvantage = false;

  @override
  void initState() {
    super.initState();
    try {
      _classes = AcidSplashRules.castingClasses(widget.hero);
      if (_classes.isNotEmpty) _selectedClass = _classes.first;
    } on FormatException catch (error) {
      _setupError = error.message;
    } on StateError catch (error) {
      _setupError = error.message;
    }
  }

  @override
  void dispose() {
    _dexModifier.dispose();
    super.dispose();
  }

  Widget _check(
    String key,
    String label,
    bool value,
    ValueChanged<bool> update,
  ) => CheckboxListTile(
    key: ValueKey('acid-splash-$key'),
    title: Text(label),
    value: value,
    dense: true,
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    onChanged: (next) => setState(() {
      update(next ?? false);
      _error = null;
    }),
  );

  void _confirm() {
    final modifier = int.tryParse(_dexModifier.text.trim());
    if (modifier == null ||
        modifier < -30 ||
        modifier > 30 ||
        _selectedClass == null ||
        _setupError != null ||
        !_origin ||
        !_only ||
        !_verbal ||
        !_somatic ||
        !_dc ||
        !_circumstances ||
        !_coverConfirmed ||
        !_effectPath ||
        !_acidDefense ||
        widget.encounter.enemyCover == CoverLevel.total) {
      setState(() => _error =
          'GES-Rettungswurfbonus (−30 bis +30) und alle '
          'tatsächlich zutreffenden Voraussetzungen bestätigen. '
          'Bei mehreren Kreaturen in der Kugel ist dieser '
          'Einzelgegner-Ablauf nicht zulässig.');
      return;
    }
    Navigator.of(context).pop(
      AcidSplashChoice(
        castingClass: _selectedClass!,
        targetDexteritySaveModifier: modifier,
        originWithin60FeetConfirmed: _origin,
        onlyCreatureInSphereConfirmed: _only,
        verbalConfirmed: _verbal,
        somaticConfirmed: _somatic,
        noUnmodelledDcConfirmed: _dc,
        saveCircumstancesConfirmed: _circumstances,
        coverRelationshipConfirmed: _coverConfirmed,
        effectPathConfirmed: _effectPath,
        noAcidDamageAdjustmentConfirmed: _acidDefense,
        sourceOppositeCover: _oppositeCover,
        saveAdvantage: _advantage,
        saveDisadvantage: _disadvantage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Säurespritzer wirken'),
    content: SizedBox(
      width: 500,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'SRD 2024: Kugel, Radius 5 Fuß (1,5 m), '
              'Ursprung bis 60 Fuß. Jede Kreatur würfelt einen GES-'
              'Rettungswurf. Alle fehlgeschlagenen Würfe erhalten '
              'denselben W6-Schadenswurf. Aktuell kann nur '
              'der gespeicherte Gegner als einziges Kugelziel '
              'im Kampf verarbeitet werden: ${widget.encounter.enemyName}.',
            ),
            const SizedBox(height: 8),
            if (_setupError != null) Text(_setupError!),
            if (AcidSplashRules.preparedName(widget.hero) == null)
              const Text('Säurespritzer ist nicht vorbereitet.'),
            if (_classes.isNotEmpty)
              DropdownButtonFormField<String>(
                key: const ValueKey('acid-splash-class'),
                initialValue: _selectedClass,
                decoration: const InputDecoration(
                  labelText: 'Zaubernde Klasse',
                ),
                items: [
                  for (final name in _classes)
                    DropdownMenuItem(value: name, child: Text(name)),
                ],
                onChanged: (value) =>
                    setState(() => _selectedClass = value),
              ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('acid-splash-save-modifier'),
              controller: _dexModifier,
              keyboardType: const TextInputType.numberWithOptions(
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Vollständiger GES-Rettungswurfbonus des Gegners',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _error = null),
            ),
            _check(
              'origin',
              'Ursprung der 5-Fuß-Kugel liegt innerhalb von 60 Fuß.',
              _origin,
              (v) => _origin = v,
            ),
            _check(
              'only',
              'Der angezeigte Gegner ist die EINZIGE Kreatur in der '
                  'gesamten Kugel, einschließlich Verbündeter.',
              _only,
              (v) => _only = v,
            ),
            _check('verbal', 'Verbale Komponente möglich.', _verbal,
                (v) => _verbal = v),
            _check('somatic', 'Gestische Komponente möglich.', _somatic,
                (v) => _somatic = v),
            _check(
              'dc',
              'Keine unmodellierten Zauber-SG-Boni vorhanden.',
              _dc,
              (v) => _dc = v,
            ),
            _check(
              'save',
              'Vorteil/Nachteil und automatische Rettungswurf-Effekte '
                  'des Gegners sind berücksichtigt.',
              _circumstances,
              (v) => _circumstances = v,
            ),
            _check(
              'cover',
              'Deckung relativ zum Kugel-Ursprung ist geprüft.',
              _coverConfirmed,
              (v) => _coverConfirmed = v,
            ),
            _check(
              'opposite',
              'Die Deckung liegt zwischen Kugel-Ursprung und Ziel.',
              _oppositeCover,
              (v) => _oppositeCover = v,
            ),
            _check(
              'path',
              'Die Kugel erreicht das Ziel ohne blockierenden '
                  'vollständigen Schutz.',
              _effectPath,
              (v) => _effectPath = v,
            ),
            _check(
              'acid-defense',
              'Keine unbekannte Säureresistenz, Immunität, '
                  'Anfälligkeit oder andere Schadensänderung.',
              _acidDefense,
              (v) => _acidDefense = v,
            ),
            _check(
              'advantage',
              'Gegner hat bestätigten Vorteil auf GES-Rettung.',
              _advantage,
              (v) => _advantage = v,
            ),
            _check(
              'disadvantage',
              'Gegner hat bestätigten Nachteil auf GES-Rettung.',
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
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Abbrechen'),
      ),
      FilledButton(
        key: const ValueKey('acid-splash-cast'),
        onPressed: _selectedClass == null ||
                AcidSplashRules.preparedName(widget.hero) == null ||
                _setupError != null
            ? null
            : _confirm,
        child: const Text('Rettungswurf würfeln'),
      ),
    ],
  );
}
