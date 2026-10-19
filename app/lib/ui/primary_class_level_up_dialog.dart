import 'package:flutter/material.dart';

import '../domain/character_creation_progression.dart';
import '../domain/models.dart';
import '../domain/primary_class_level_up.dart';
import '../domain/srd_class_feature_catalog.dart';
import '../domain/srd_character_classes.dart';
import 'ability_assignment_dialog.dart';

/// Preview-only SRD primary-class advancement. The editor persists changes
/// only after the player confirms the proposal and saves their character.
class PrimaryClassLevelUpDialog extends StatefulWidget {
  const PrimaryClassLevelUpDialog({super.key, required this.hero});

  final HeroCharacter hero;

  @override
  State<PrimaryClassLevelUpDialog> createState() =>
      _PrimaryClassLevelUpDialogState();
}

class _PrimaryClassLevelUpDialogState extends State<PrimaryClassLevelUpDialog> {
  bool _milestone = false;
  bool _confirmSubclass = false;
  String? _featMode;
  String? _firstAbility;
  String? _secondAbility;
  String? _error;

  bool get _featDue => PrimaryClassLevelUp.needsAbilityFeat(
    widget.hero.className,
    widget.hero.primaryClassLevel + 1,
  );
  bool get _subclassDue =>
      widget.hero.primaryClassLevel == 2 && widget.hero.subclass.trim().isEmpty;

  Map<String, int> get _boost => switch (_featMode) {
    'two' when _firstAbility != null => {_firstAbility!: 2},
    'split'
        when _firstAbility != null &&
            _secondAbility != null &&
            _firstAbility != _secondAbility =>
      {_firstAbility!: 1, _secondAbility!: 1},
    _ => const {},
  };

  void _accept() {
    try {
      final selectedClass = findSrdClass(widget.hero.className)!.name;
      final subclass = _subclassDue && _confirmSubclass
          ? SrdClassFeatureCatalog.defaultSubclass[selectedClass]
          : null;
      if (_featDue && _featMode == null) {
        throw const FormatException(
          'Bitte die Attributsverbesserung auswählen oder ausdrücklich aufschieben.',
        );
      }
      final proposal = PrimaryClassLevelUp.propose(
        hero: widget.hero,
        milestoneAdvancement: _milestone,
        chosenSubclass: subclass,
        abilityIncreases: _boost,
        deferFeat: _featMode == 'pending',
      );
      Navigator.of(context).pop(proposal);
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    } on RangeError catch (e) {
      setState(() => _error = e.message?.toString() ?? '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hero = widget.hero;
    final nextLevel = hero.level + 1;
    final classLevel = hero.primaryClassLevel + 1;
    final threshold = CharacterCreationProgression.startingExperience(
      nextLevel,
    );
    final className = findSrdClass(hero.className)?.name ?? hero.className;
    final due = SrdClassFeatureCatalog.atClassLevel(
      className,
      classLevel,
      subclass: _subclassDue && _confirmSubclass
          ? SrdClassFeatureCatalog.defaultSubclass[className]!
          : hero.subclass,
    );
    return AlertDialog(
      key: const ValueKey('primary-class-level-up-dialog'),
      title: const Text('D&D-Stufenaufstieg'),
      scrollable: true,
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$className: Klassenstufe ${hero.primaryClassLevel} → $classLevel',
            ),
            Text('Gesamtstufe ${hero.level} → $nextLevel'),
            const SizedBox(height: 8),
            Text(
              'Erforderlich: $threshold EP · vorhanden: '
              '${hero.experience?.toString() ?? 'nicht bestätigt'}',
            ),
            CheckboxListTile(
              key: const ValueKey('primary-level-milestone'),
              contentPadding: EdgeInsets.zero,
              value: _milestone,
              onChanged: (value) => setState(() => _milestone = value ?? false),
              title: const Text('Meilenstein statt Erfahrungspunkte'),
              subtitle: const Text(
                'Nur bei ausdrücklicher Bestätigung durch die Spielleitung. '
                'Bestehende EP werden nicht erhöht.',
              ),
            ),
            if (_subclassDue) ...[
              const Divider(),
              CheckboxListTile(
                key: const ValueKey('primary-level-subclass'),
                contentPadding: EdgeInsets.zero,
                value: _confirmSubclass,
                title: Text(
                  'Unterklasse wählen: '
                  '${SrdClassFeatureCatalog.defaultSubclass[className]}',
                ),
                subtitle: const Text(
                  'Nur die im SRD enthaltene Unterklasse kann '
                  'hier automatisch zugeordnet werden.',
                ),
                onChanged: (value) =>
                    setState(() => _confirmSubclass = value ?? false),
              ),
            ],
            if (_featDue) ...[
              const Divider(),
              DropdownButtonFormField<String>(
                key: const ValueKey('primary-level-feat-mode'),
                isExpanded: true,
                initialValue: _featMode,
                decoration: const InputDecoration(
                  labelText: 'Talentwahl dieser Klassenstufe',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'two',
                    child: Text('Attributsverbesserung: +2'),
                  ),
                  DropdownMenuItem(
                    value: 'split',
                    child: Text('Attributsverbesserung: +1 / +1'),
                  ),
                  DropdownMenuItem(
                    value: 'pending',
                    child: Text('Andere Talentwahl – noch offen lassen'),
                  ),
                ],
                onChanged: (value) => setState(() {
                  _featMode = value;
                  _firstAbility = null;
                  _secondAbility = null;
                }),
              ),
              if (_featMode == 'two' || _featMode == 'split')
                DropdownButtonFormField<String>(
                  key: const ValueKey('primary-level-first-ability'),
                  isExpanded: true,
                  initialValue: _firstAbility,
                  decoration: const InputDecoration(
                    labelText: 'Erstes Attribut',
                  ),
                  items: [
                    for (final ability in abilityLabels.entries)
                      DropdownMenuItem(
                        value: ability.key,
                        child: Text(
                          '${ability.value} (${hero.abilities[ability.key] ?? '–'})',
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _firstAbility = value),
                ),
              if (_featMode == 'split')
                DropdownButtonFormField<String>(
                  key: const ValueKey('primary-level-second-ability'),
                  isExpanded: true,
                  initialValue: _secondAbility,
                  decoration: const InputDecoration(
                    labelText: 'Zweites Attribut',
                  ),
                  items: [
                    for (final ability in abilityLabels.entries)
                      if (ability.key != _firstAbility)
                        DropdownMenuItem(
                          value: ability.key,
                          child: Text(
                            '${ability.value} (${hero.abilities[ability.key] ?? '–'})',
                          ),
                        ),
                  ],
                  onChanged: (value) => setState(() => _secondAbility = value),
                ),
            ],
            const Divider(),
            const Text(
              'Neue Klassenmerkmale:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (due.isEmpty)
              const Text('Keine neuen Merkmale in der SRD-Tabelle'),
            for (final feature in due)
              Text(
                '• ${feature.name} '
                '(${feature.automation == FeatureAutomation.automatic
                    ? 'Regel automatisch verfügbar'
                    : feature.automation == FeatureAutomation.choiceRequired
                    ? 'Spielerwahl nötig'
                    : 'Wirkung separat prüfen'})',
              ),
            const SizedBox(height: 10),
            const Text(
              'TP-Wachstum: fester Klassen-Trefferwürfelwert + '
              'Konstitutionsmodifikator (mindestens 1 TP), '
              'mit rückwirkender Anpassung bei verbesserter Konstitution.',
              style: TextStyle(fontSize: 12),
            ),
            const Text(
              'Noch offene Zauber-, Talent- und Ausstattungsentscheidungen '
              'werden nur als offen notiert, nicht erfunden.',
              style: TextStyle(fontSize: 12),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                key: const ValueKey('primary-level-error'),
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
          key: const ValueKey('primary-level-confirm'),
          onPressed: _accept,
          child: const Text('Aufstieg vorbereiten'),
        ),
      ],
    );
  }
}
