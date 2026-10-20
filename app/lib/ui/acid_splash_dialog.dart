import 'package:flutter/material.dart';

import '../domain/acid_splash_rules.dart';
import '../domain/cover_rules.dart';
import '../domain/models.dart';

/// Manual HP-only targets can join the saved foe, with verified save/cover.
/// The editor does not infer positions, monster traits or initiative.
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
    required this.additionalTargets,
    required this.everyCreatureInSphereIncludedConfirmed,
  });

  final String castingClass;
  final int targetDexteritySaveModifier;
  final bool originWithin60FeetConfirmed, onlyCreatureInSphereConfirmed;
  final bool verbalConfirmed, somaticConfirmed, noUnmodelledDcConfirmed;
  final bool saveCircumstancesConfirmed, coverRelationshipConfirmed;
  final bool effectPathConfirmed, noAcidDamageAdjustmentConfirmed;
  final bool sourceOppositeCover, saveAdvantage, saveDisadvantage;
  final List<AcidSplashTarget> additionalTargets;
  final bool everyCreatureInSphereIncludedConfirmed;
}

class AcidSplashDialog extends StatefulWidget {
  const AcidSplashDialog({
    super.key,
    required this.hero,
    required this.encounter,
    this.trackedAreaCreatures = const [],
  });

  final HeroCharacter hero;
  final Encounter encounter;
  final List<TrackedAreaCreature> trackedAreaCreatures;

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
  bool _allIncluded = false;
  final _extraSelected = <String>{};
  final _extraModifiers = <String, TextEditingController>{};
  final _extraCovers = <String, CoverLevel?>{};
  final _extraVerified = <String>{};
  final _extraOpposite = <String>{};
  final _extraAdvantage = <String>{};
  final _extraDisadvantage = <String>{};

  @override
  void initState() {
    super.initState();
    for (final creature in widget.trackedAreaCreatures) {
      if (creature.hitPoints > 0) {
        _extraModifiers[creature.id] = TextEditingController();
      }
    }
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
    for (final controller in _extraModifiers.values) {
      controller.dispose();
    }
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
    final additions = <AcidSplashTarget>[];
    for (final creature in widget.trackedAreaCreatures) {
      if (!_extraSelected.contains(creature.id)) continue;
      final targetSave = int.tryParse(
        _extraModifiers[creature.id]?.text.trim() ?? '',
      );
      final cover = _extraCovers[creature.id];
      if (targetSave == null ||
          targetSave < -30 ||
          targetSave > 30 ||
          cover == null ||
          cover == CoverLevel.total ||
          !_extraVerified.contains(creature.id)) {
        setState(
          () => _error =
              'Für jedes ausgewählte Zusatz-Ziel den GES-Bonus, '
              'den Deckungsgrad und alle Defensivwerte bestätigen.',
        );
        return;
      }
      additions.add(
        AcidSplashTarget(
          id: creature.id,
          name: creature.name,
          hitPoints: creature.hitPoints,
          maxHitPoints: creature.maxHitPoints,
          dexteritySaveModifier: targetSave,
          cover: cover,
          sourceOppositeCover: _extraOpposite.contains(creature.id),
          coverRelationshipConfirmed: true,
          inSphereConfirmed: true,
          effectPathConfirmed: true,
          noAcidDamageAdjustmentConfirmed: true,
          saveCircumstancesConfirmed: true,
          saveAdvantage: _extraAdvantage.contains(creature.id),
          saveDisadvantage: _extraDisadvantage.contains(creature.id),
        ),
      );
    }
    final isMulti = additions.isNotEmpty;
    if (modifier == null ||
        modifier < -30 ||
        modifier > 30 ||
        _selectedClass == null ||
        _setupError != null ||
        !_origin ||
        (isMulti ? !_allIncluded || _only : !_only) ||
        !_verbal ||
        !_somatic ||
        !_dc ||
        !_circumstances ||
        !_coverConfirmed ||
        !_effectPath ||
        !_acidDefense ||
        widget.encounter.enemyCover == CoverLevel.total) {
      setState(
        () => _error =
            'GES-Rettungswurfbonus (−30 bis +30) und alle '
            'tatsächlich zutreffenden Voraussetzungen bestätigen. '
            'Bei mehreren Kreaturen alle getroffenen Wesen '
            'einschließlich Verbündeter vollständig erfassen.',
      );
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
        additionalTargets: additions,
        everyCreatureInSphereIncludedConfirmed: isMulti && _allIncluded,
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
              'denselben W6-Schadenswurf. Gespeicherter Gegner: '
              '${widget.encounter.enemyName}. Weitere manuell erfasste '
              'Kreaturen können einbezogen werden. Keine automatische '
              'Erkennung von Positionen oder Monsterfähigkeiten.',
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
                onChanged: (value) => setState(() => _selectedClass = value),
              ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('acid-splash-save-modifier'),
              controller: _dexModifier,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
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
              'Der Hauptgegner ist die EINZIGE Kreatur in der Kugel '
                  '(nur bei keinem weiteren Ziel anhaken).',
              _only,
              (v) => _only = v,
            ),
            _check(
              'verbal',
              'Verbale Komponente möglich.',
              _verbal,
              (v) => _verbal = v,
            ),
            _check(
              'somatic',
              'Gestische Komponente möglich.',
              _somatic,
              (v) => _somatic = v,
            ),
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
            if (_extraModifiers.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Weitere gespeicherte Kugelziele',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              for (final creature in widget.trackedAreaCreatures)
                if (creature.hitPoints > 0) ...[
                  CheckboxListTile(
                    key: ValueKey('acid-extra-select-${creature.id}'),
                    title: Text(
                      '${creature.name} '
                      '(${creature.hitPoints}/${creature.maxHitPoints} TP)',
                    ),
                    value: _extraSelected.contains(creature.id),
                    onChanged: (v) => setState(() {
                      if (v ?? false) {
                        _extraSelected.add(creature.id);
                      } else {
                        _extraSelected.remove(creature.id);
                      }
                      _error = null;
                    }),
                  ),
                  if (_extraSelected.contains(creature.id)) ...[
                    TextField(
                      key: ValueKey('acid-extra-save-${creature.id}'),
                      controller: _extraModifiers[creature.id],
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'GES-Rettungswurfbonus ${creature.name}',
                      ),
                    ),
                    DropdownButtonFormField<CoverLevel>(
                      key: ValueKey('acid-extra-cover-${creature.id}'),
                      initialValue: _extraCovers[creature.id],
                      decoration: const InputDecoration(
                        labelText: 'Deckung vom Kugel-Ursprung',
                      ),
                      items: [
                        for (final cover in CoverLevel.values)
                          DropdownMenuItem(
                            value: cover,
                            child: Text(CoverRules.label(cover)),
                          ),
                      ],
                      onChanged: (v) =>
                          setState(() => _extraCovers[creature.id] = v),
                    ),
                    _check(
                      'extra-opposite-${creature.id}',
                      'Deckung liegt zwischen diesem Ziel und Ursprung.',
                      _extraOpposite.contains(creature.id),
                      (v) => v
                          ? _extraOpposite.add(creature.id)
                          : _extraOpposite.remove(creature.id),
                    ),
                    _check(
                      'extra-adv-${creature.id}',
                      'Bestätigter Rettungswurf-Vorteil.',
                      _extraAdvantage.contains(creature.id),
                      (v) => v
                          ? _extraAdvantage.add(creature.id)
                          : _extraAdvantage.remove(creature.id),
                    ),
                    _check(
                      'extra-disadv-${creature.id}',
                      'Bestätigter Rettungswurf-Nachteil.',
                      _extraDisadvantage.contains(creature.id),
                      (v) => v
                          ? _extraDisadvantage.add(creature.id)
                          : _extraDisadvantage.remove(creature.id),
                    ),
                    _check(
                      'extra-confirm-${creature.id}',
                      'Kugelzugehörigkeit, Wirkpfad, Deckung, Rettungs-'
                          'umstände und Säureabwehr dieses Ziels geprüft.',
                      _extraVerified.contains(creature.id),
                      (v) => v
                          ? _extraVerified.add(creature.id)
                          : _extraVerified.remove(creature.id),
                    ),
                  ],
                ],
              _check(
                'all-included',
                'ALLE Kreaturen in der Kugel, auch Verbündete, sind '
                    'als Haupt- oder Zusatz-Ziele erfasst.',
                _allIncluded,
                (v) => _allIncluded = v,
              ),
            ],
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
        onPressed:
            _selectedClass == null ||
                AcidSplashRules.preparedName(widget.hero) == null ||
                _setupError != null
            ? null
            : _confirm,
        child: const Text('Rettungswurf würfeln'),
      ),
    ],
  );
}
