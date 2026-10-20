import 'package:flutter/material.dart';

import '../domain/character_creation_progression.dart';
import '../domain/experience_progression.dart';
import '../domain/class_progression_rules.dart';
import '../domain/models.dart';
import '../domain/srd_class_feature_catalog.dart';
import '../domain/srd_class_level_up.dart';
import 'ability_assignment_dialog.dart';

/// A preview only; no campaign data changes until the editor is saved.
class SrdClassLevelUpDialog extends StatefulWidget {
  const SrdClassLevelUpDialog({super.key, required this.hero});
  final HeroCharacter hero;

  @override
  State<SrdClassLevelUpDialog> createState() => _SrdClassLevelUpDialogState();
}

class _SrdClassLevelUpDialogState extends State<SrdClassLevelUpDialog> {
  late String _target = widget.hero.className;
  LevelUpMethod _method = LevelUpMethod.experience;
  bool _chooseSubclass = false;
  String _abilityChoice = 'pending';
  String? _firstAbility;
  String? _secondAbility;
  String? _error;

  String get _subclass => SrdClassFeatureCatalog.defaultSubclass[_target] ?? '';

  Map<String, int> get _chosenAbilityBoost => switch (_abilityChoice) {
    'two' when _firstAbility != null => {_firstAbility!: 2},
    'split'
        when _firstAbility != null &&
            _secondAbility != null &&
            _firstAbility != _secondAbility =>
      {_firstAbility!: 1, _secondAbility!: 1},
    _ => const {},
  };

  SrdClassLevelUpProposal? _proposal() {
    try {
      return SrdClassLevelUpRules.propose(
        hero: widget.hero,
        className: _target,
        method: _method,
        chosenSubclass: _chooseSubclass ? _subclass : '',
        abilityIncreases: _chosenAbilityBoost,
      );
    } on FormatException catch (exception) {
      _error = exception.message;
      return null;
    }
  }

  void _confirm() {
    if (_abilityChoice != 'pending' && _chosenAbilityBoost.isEmpty) {
      setState(
        () => _error =
            'Bitte die Attributswerte für '
            'die gewählte Verbesserung vollständig auswählen.',
      );
      return;
    }
    final proposal = _proposal();
    if (proposal == null) {
      setState(() {});
      return;
    }
    Navigator.of(context).pop(proposal);
  }

  @override
  Widget build(BuildContext context) {
    final classNames = [
      widget.hero.className,
      if (widget.hero.hasSecondClass) widget.hero.secondaryClassName,
    ];
    final chosenLevel =
        (_target == widget.hero.className
            ? widget.hero.primaryClassLevel
            : widget.hero.secondaryClassLevel) +
        1;
    final existingSubclass = _target == widget.hero.className
        ? widget.hero.subclass
        : widget.hero.secondarySubclass;
    final canChooseSubclass =
        chosenLevel == 3 &&
        existingSubclass.trim().isEmpty &&
        _subclass.isNotEmpty;
    final featDue = ClassProgressionRules.milestonesForClass(_target).any(
      (milestone) =>
          milestone.classLevel == chosenLevel &&
          milestone.type == ClassMilestoneType.featChoice,
    );
    // The preview errors may depend on the selected XP/milestone mode.
    final proposal = _proposal();
    final message = proposal == null ? _error : null;
    final availableAdvancements = ExperienceProgression.pendingLevels(
      widget.hero,
    );
    final trainingBefore = CharacterCreationProgression.proficiencyBonus(
      widget.hero.level,
    );
    final trainingAfter = widget.hero.level < 20
        ? CharacterCreationProgression.proficiencyBonus(widget.hero.level + 1)
        : trainingBefore;
    final thresholdLabel = widget.hero.level >= 20
        ? 'Höchststufe 20'
        : '${CharacterCreationProgression.startingExperience(widget.hero.level + 1)}';
    return AlertDialog(
      title: const Text('Klasse um eine Stufe steigern'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Gesamtstufe ${widget.hero.level} → ${widget.hero.level + 1}',
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const ValueKey('levelup-class'),
                initialValue: _target,
                decoration: const InputDecoration(labelText: 'Klasse steigern'),
                items: [
                  for (final className in classNames)
                    DropdownMenuItem(value: className, child: Text(className)),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _target = value;
                      _chooseSubclass = false;
                      _abilityChoice = 'pending';
                      _firstAbility = null;
                      _secondAbility = null;
                      _error = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              SegmentedButton<LevelUpMethod>(
                segments: const [
                  ButtonSegment(
                    value: LevelUpMethod.experience,
                    label: Text('Erfahrung'),
                  ),
                  ButtonSegment(
                    value: LevelUpMethod.milestone,
                    label: Text('Meilenstein'),
                  ),
                ],
                selected: {_method},
                onSelectionChanged: (values) => setState(() {
                  _method = values.single;
                  _error = null;
                }),
              ),
              const SizedBox(height: 10),
              Text(
                'EP vorhanden: ${widget.hero.experience?.toString() ?? 'nicht bestätigt'}'
                ' · Schwelle: $thresholdLabel',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (availableAdvancements > 0) ...[
                const SizedBox(height: 6),
                Text(
                  availableAdvancements == 1
                      ? 'Ein Aufstieg mit bestätigten EP verfügbar.'
                      : '$availableAdvancements Aufstiege mit EP verfügbar. '
                            'Jede Klassenstufe wird einzeln bestätigt.',
                  key: const ValueKey('levelup-available-levels'),
                ),
              ],
              if (canChooseSubclass)
                CheckboxListTile(
                  key: const ValueKey('levelup-subclass'),
                  contentPadding: EdgeInsets.zero,
                  value: _chooseSubclass,
                  title: Text(
                    'SRD-Unterklasse „$_subclass“ ausdrücklich wählen',
                  ),
                  subtitle: const Text(
                    'Nur der SRD-Katalogeintrag wird notiert. '
                    'Nicht implementierte Unterklassenwirkungen '
                    'werden dadurch nicht erfunden.',
                  ),
                  onChanged: (value) =>
                      setState(() => _chooseSubclass = value ?? false),
                ),
              if (featDue) ...[
                const SizedBox(height: 10),
                const Text('Talentauswahl dieser Klassenstufe:'),
                DropdownButtonFormField<String>(
                  key: const ValueKey('levelup-asi-choice'),
                  initialValue: _abilityChoice,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'pending',
                      child: Text('Talent/ASI noch offen lassen'),
                    ),
                    DropdownMenuItem(
                      value: 'two',
                      child: Text('Attributsverbesserung +2'),
                    ),
                    DropdownMenuItem(
                      value: 'split',
                      child: Text('Attributsverbesserung +1 / +1'),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _abilityChoice = value ?? 'pending';
                    _firstAbility = null;
                    _secondAbility = null;
                  }),
                ),
                if (_abilityChoice == 'two' || _abilityChoice == 'split')
                  DropdownButtonFormField<String>(
                    key: const ValueKey('levelup-asi-first'),
                    initialValue: _firstAbility,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Erstes Attribut',
                    ),
                    items: [
                      for (final ability in abilityLabels.entries)
                        DropdownMenuItem(
                          value: ability.key,
                          child: Text(
                            '${ability.value} (${widget.hero.abilities[ability.key] ?? '–'})',
                          ),
                        ),
                    ],
                    onChanged: (value) => setState(() => _firstAbility = value),
                  ),
                if (_abilityChoice == 'split')
                  DropdownButtonFormField<String>(
                    key: const ValueKey('levelup-asi-second'),
                    initialValue: _secondAbility,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Zweites Attribut',
                    ),
                    items: [
                      for (final ability in abilityLabels.entries)
                        if (ability.key != _firstAbility)
                          DropdownMenuItem(
                            value: ability.key,
                            child: Text(
                              '${ability.value} (${widget.hero.abilities[ability.key] ?? '–'})',
                            ),
                          ),
                    ],
                    onChanged: (value) =>
                        setState(() => _secondAbility = value),
                  ),
                if (_abilityChoice != 'pending' && _chosenAbilityBoost.isEmpty)
                  const Text('Bitte die passenden Attribute auswählen.'),
              ],
              if (proposal != null) ...[
                const SizedBox(height: 10),
                Text(
                  '${proposal.className}, Klassenstufe ${proposal.classLevel}'
                  ' · W${proposal.hitDie}: feste +${proposal.hpGain} TP',
                ),
                const SizedBox(height: 6),
                Text(
                  'TP-Vorschau: ${widget.hero.hitPoints} → '
                  '${widget.hero.hitPoints! + proposal.hpGain} / '
                  '${widget.hero.maxHitPoints! + proposal.hpGain}',
                  key: const ValueKey('levelup-hp-preview'),
                ),
                Text(
                  'Übungsbonus: +$trainingBefore → +$trainingAfter',
                  key: const ValueKey('levelup-proficiency-preview'),
                ),
                if (proposal.features.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('Neue SRD-Tabellenmerkmale:'),
                  for (final feature in proposal.features)
                    Text('• ${feature.name} – ${feature.automation.name}'),
                ],
                if (proposal.abilityIncreases.isNotEmpty)
                  Text(
                    'Attributsverbesserung: ${proposal.abilityIncreases.entries.map((e) => '${abilityLabels[e.key]} +${e.value}').join(', ')}',
                  ),
                if (proposal.requiredChoices.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Offene Entscheidungen (als offene Wahl gespeichert, '
                    'nicht automatisch gewährt):',
                  ),
                  for (final choice in proposal.requiredChoices)
                    Text('• $choice'),
                ],
              ],
              if (message != null) ...[
                const SizedBox(height: 12),
                Text(
                  message,
                  key: const ValueKey('levelup-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 10),
              const Text(
                'Nach Bestätigung werden Klassenstufe, feste Trefferpunkte '
                'und nur ausdrücklich gewählte Attributsverbesserungen '
                '(einschließlich rückwirkender TP durch KO) übernommen. '
                'Andere Talente, Zauber und Unterklassenwirkungen '
                'müssen separat bestätigt werden.',
                style: TextStyle(fontSize: 12),
              ),
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
          key: const ValueKey('levelup-confirm'),
          onPressed: _confirm,
          child: const Text('Stufenaufstieg übernehmen'),
        ),
      ],
    );
  }
}
