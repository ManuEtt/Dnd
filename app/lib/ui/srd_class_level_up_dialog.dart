import 'package:flutter/material.dart';

import '../domain/character_creation_progression.dart';
import '../domain/models.dart';
import '../domain/srd_class_feature_catalog.dart';
import '../domain/srd_class_level_up.dart';

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
  String? _error;

  String get _subclass => SrdClassFeatureCatalog.defaultSubclass[_target] ?? '';

  SrdClassLevelUpProposal? _proposal() {
    try {
      return SrdClassLevelUpRules.propose(
        hero: widget.hero,
        className: _target,
        method: _method,
        chosenSubclass: _chooseSubclass ? _subclass : '',
      );
    } on FormatException catch (exception) {
      _error = exception.message;
      return null;
    }
  }

  void _confirm() {
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
    final canChooseSubclass =
        _target == widget.hero.className &&
        chosenLevel == 3 &&
        widget.hero.subclass.trim().isEmpty &&
        _subclass.isNotEmpty;
    // The preview errors may depend on the selected XP/milestone mode.
    final proposal = _proposal();
    final message = proposal == null ? _error : null;
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
                ' · Schwelle: ${CharacterCreationProgression.startingExperience(widget.hero.level + 1)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
              if (proposal != null) ...[
                const SizedBox(height: 10),
                Text(
                  '${proposal.className}, Klassenstufe ${proposal.classLevel}'
                  ' · W${proposal.hitDie}: feste +${proposal.hpGain} TP',
                ),
                if (proposal.features.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('Neue SRD-Tabellenmerkmale:'),
                  for (final feature in proposal.features)
                    Text('• ${feature.name} – ${feature.automation.name}'),
                ],
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
                'Nach Bestätigung werden ausschließlich Klassenstufe und '
                'feste Trefferpunkte angepasst. Talente, Zauber, '
                'Ressourcen und Unterklassenwirkungen müssen nach ihren '
                'jeweiligen SRD-Regeln separat bestätigt werden.',
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
