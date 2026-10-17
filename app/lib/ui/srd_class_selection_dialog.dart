import 'package:flutter/material.dart';

import '../domain/srd_character_classes.dart';
import '../domain/starting_hit_points.dart';

const _savingThrowLabels = <String, String>{
  'strength': 'Stärke',
  'dexterity': 'Geschicklichkeit',
  'constitution': 'Konstitution',
  'intelligence': 'Intelligenz',
  'wisdom': 'Weisheit',
  'charisma': 'Charisma',
};

/// Explicit wizard proposal: no persisted data changes until the editor saves.
class SrdClassSetupResult {
  const SrdClassSetupResult({
    required this.selection,
    required this.replaceExistingProficiencies,
    required this.useSuggestedHitPoints,
  });

  final SrdClassSelection selection;
  final bool replaceExistingProficiencies;
  final bool useSuggestedHitPoints;
}

class SrdClassSelectionDialog extends StatefulWidget {
  const SrdClassSelectionDialog({
    super.key,
    required this.currentClass,
    required this.existingSkills,
    required this.existingSavingThrows,
    required this.characterLevel,
    required this.constitutionScore,
    required this.hasExistingHitPoints,
    required this.allowEquipment,
  });

  final String currentClass;
  final List<String> existingSkills;
  final List<String> existingSavingThrows;
  final int? characterLevel;
  final int? constitutionScore;
  final bool hasExistingHitPoints;
  final bool allowEquipment;

  @override
  State<SrdClassSelectionDialog> createState() =>
      _SrdClassSelectionDialogState();
}

class _SrdClassSelectionDialogState extends State<SrdClassSelectionDialog> {
  late SrdCharacterClass _selectedClass;
  late final Set<String> _skills;
  bool _replace = false;
  bool _useHp = false;
  int _kitIndex = -1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedClass =
        findSrdClass(widget.currentClass) ?? srdCharacterClasses.first;
    _skills = widget.existingSkills
        .where((value) => _selectedClass.skillChoices.contains(value))
        .take(_selectedClass.skillCount)
        .toSet();
    _useHp =
        !widget.hasExistingHitPoints &&
        widget.characterLevel == 1 &&
        widget.constitutionScore != null;
  }

  StartingHitPoints? get _startingHitPoints {
    if (widget.characterLevel != 1 || widget.constitutionScore == null) {
      return null;
    }
    try {
      return StartingHitPoints.propose(
        className: _selectedClass.name,
        constitutionScore: widget.constitutionScore,
        characterLevel: widget.characterLevel,
      );
    } on FormatException {
      return null;
    }
  }

  void _accept() {
    try {
      final selection = SrdClassSelection(
        characterClass: _selectedClass,
        skills: _skills,
        kitIndex: _kitIndex == -1 ? null : _kitIndex,
      );
      Navigator.of(context).pop(
        SrdClassSetupResult(
          selection: selection,
          replaceExistingProficiencies: _replace,
          useSuggestedHitPoints: _useHp && _startingHitPoints != null,
        ),
      );
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hp = _startingHitPoints;
    final hasProficiencies =
        widget.existingSkills.isNotEmpty ||
        widget.existingSavingThrows.isNotEmpty;
    return AlertDialog(
      key: const ValueKey('srd-class-dialog'),
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      title: const Text('D&D-Klasse und Startwerte'),
      content: SizedBox(
        width: 540,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'SRD 5.2.1: Die Klassenwahl ist ein Vorschlag für einen '
              'Charakter der Stufe 1, kein automatischer Stufenaufstieg. '
              'Andere Herkunfts- und Klassenmerkmale bleiben unverändert.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<SrdCharacterClass>(
              key: ValueKey('srd-class-${_selectedClass.name}'),
              initialValue: _selectedClass,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Charakterklasse'),
              items: [
                for (final value in srdCharacterClasses)
                  DropdownMenuItem(value: value, child: Text(value.name)),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedClass = value;
                  _skills.clear();
                  _kitIndex = -1;
                  _error = null;
                });
              },
            ),
            const SizedBox(height: 12),
            Text('Trefferwürfel: W${_selectedClass.hitDie}'),
            Text('Rüstungsübung: ${_selectedClass.armorTraining}'),
            const SizedBox(height: 12),
            Text(
              'Rettungswurf-Übungen: ${_selectedClass.savingThrows.map((key) => _savingThrowLabels[key]).join(', ')}',
            ),
            const SizedBox(height: 16),
            Text(
              'Klassenfertigkeiten: ${_skills.length} / ${_selectedClass.skillCount}',
              key: const ValueKey('srd-selected-skills-count'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 2,
              children: [
                for (final skill in _selectedClass.skillChoices)
                  FilterChip(
                    key: ValueKey('srd-skill-$skill'),
                    label: Text(skill),
                    selected: _skills.contains(skill),
                    onSelected:
                        _skills.contains(skill) ||
                            _skills.length < _selectedClass.skillCount
                        ? (selected) => setState(() {
                            selected
                                ? _skills.add(skill)
                                : _skills.remove(skill);
                            _error = null;
                          })
                        : null,
                  ),
              ],
            ),
            if (hasProficiencies) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                key: const ValueKey('srd-replace-proficiencies'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Bestehende Übungen ersetzen'),
                subtitle: const Text(
                  'Aus: bisherige Fertigkeiten und Rettungswürfe erhalten '
                  'und neue ergänzen. Ein: bestehende Listen ausdrücklich '
                  'durch die Klassenauswahl ersetzen. Herkunftsübungen '
                  'gegebenenfalls separat wieder hinzufügen.',
                ),
                value: _replace,
                onChanged: (value) => setState(() => _replace = value),
              ),
            ],
            if (hp != null) ...[
              const SizedBox(height: 12),
              CheckboxListTile(
                key: const ValueKey('srd-confirm-start-hp'),
                contentPadding: EdgeInsets.zero,
                value: _useHp,
                onChanged: (value) => setState(() => _useHp = value ?? false),
                title: Text('Start-TP vorschlagen: ${hp.maximum} TP'),
                subtitle: Text(
                  widget.hasExistingHitPoints
                      ? 'Achtung: Dies ersetzt nur nach deiner Bestätigung '
                            'bisherige aktuelle und maximale TP.'
                      : 'W${hp.hitDie} plus Konstitutionsmodifikator. '
                            'Übernahme erst mit der Bestätigung.',
                ),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Start-TP erst auf Stufe 1 und mit bestätigtem '
                  'Konstitutionswert berechenbar.',
                ),
              ),
            if (widget.allowEquipment) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: ValueKey('srd-equipment-$_kitIndex'),
                initialValue: _kitIndex,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Optionale Startausrüstung',
                ),
                items: [
                  const DropdownMenuItem(
                    value: -1,
                    child: Text('Keine Ausrüstung hinzufügen'),
                  ),
                  for (var i = 0; i < _selectedClass.kits.length; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(_selectedClass.kits[i].label),
                    ),
                ],
                onChanged: (value) => setState(() => _kitIndex = value ?? -1),
              ),
              if (_kitIndex >= 0) ...[
                const SizedBox(height: 8),
                Text('Startgold: ${_selectedClass.kits[_kitIndex].gold} GM'),
                for (final item in _selectedClass.kits[_kitIndex].items)
                  Text('• ${item.quantity} × ${item.name}'),
                const Text(
                  'Noch keine automatische Ausrüstung oder RK-Berechnung.',
                ),
              ],
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'Bestehendes Inventar und Gold bleiben unverändert. '
                  'Neue Ausrüstung kann im Inventar manuell ergänzt werden.',
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          key: const ValueKey('srd-confirm-class'),
          onPressed: _skills.length == _selectedClass.skillCount
              ? _accept
              : null,
          child: const Text('Klasse und Fertigkeiten übernehmen'),
        ),
      ],
    );
  }
}
