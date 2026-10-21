import 'package:flutter/material.dart';

import 'fantasy_buttons.dart';

import '../domain/models.dart';
import '../domain/multiclass_rules.dart';
import '../domain/character_creation_progression.dart';
import '../domain/srd_class_level_up.dart';
import '../domain/srd_character_classes.dart';

/// An explicitly confirmed SRD 5.2.1 second-class level-up.
/// It deliberately does not grant class-1 equipment, second-class saving
/// throws or implement features not yet represented by the game engine.
class MulticlassSelectionDialog extends StatefulWidget {
  const MulticlassSelectionDialog({super.key, required this.hero});
  final HeroCharacter hero;

  @override
  State<MulticlassSelectionDialog> createState() =>
      _MulticlassSelectionDialogState();
}

class _MulticlassSelectionDialogState extends State<MulticlassSelectionDialog> {
  late String _className;
  String? _skill;
  LevelUpMethod _method = LevelUpMethod.experience;
  String? _error;

  @override
  void initState() {
    super.initState();
    final hero = widget.hero;
    _className = hero.hasSecondClass
        ? hero.secondaryClassName
        : srdCharacterClasses
              .firstWhere(
                (entry) => entry.name != findSrdClass(hero.className)?.name,
              )
              .name;
  }

  @override
  Widget build(BuildContext context) {
    final hero = widget.hero;
    final classNames = hero.hasSecondClass
        ? [hero.secondaryClassName]
        : [
            for (final definition in srdCharacterClasses)
              if (definition.name != findSrdClass(hero.className)?.name)
                definition.name,
          ];
    final skills = MulticlassRules.availableSkills(hero, _className);
    final chooseSkill =
        !hero.hasSecondClass && MulticlassRules.requiresSkill(_className);
    MulticlassProposal? proposal;
    String? problem;
    try {
      proposal = MulticlassRules.propose(
        hero: hero,
        newClass: _className,
        selectedSkill: chooseSkill ? _skill : null,
        method: _method,
      );
    } on FormatException catch (error) {
      problem = error.message;
    }
    return AlertDialog(
      title: const Text('Zweitklasse nach D&D'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ausgangsklasse: ${hero.className} (Stufe ${hero.primaryClassLevel})',
              ),
              Text('Aktuelle Gesamtstufe: ${hero.level}'),
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
                onSelectionChanged: (selection) => setState(() {
                  _method = selection.single;
                  _error = null;
                }),
              ),
              const SizedBox(height: 8),
              Text(
                'EP: ${hero.experience?.toString() ?? 'unbestätigt'} · '
                'Stufe ${hero.level + 1}: '
                '${hero.level < 20 ? CharacterCreationProgression.startingExperience(hero.level + 1).toString() : 'Höchststufe'} EP',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const ValueKey('multiclass-class'),
                initialValue: _className,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Zweite Klasse'),
                items: [
                  for (final name in classNames)
                    DropdownMenuItem(value: name, child: Text(name)),
                ],
                onChanged: hero.hasSecondClass
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() {
                            _className = value;
                            _skill = null;
                            _error = null;
                          });
                        }
                      },
              ),
              if (chooseSkill && skills.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: ValueKey('multiclass-skill-$_className'),
                  initialValue: _skill,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Eine zusätzliche Fertigkeit',
                  ),
                  items: [
                    for (final name in skills)
                      DropdownMenuItem(value: name, child: Text(name)),
                  ],
                  onChanged: (value) => setState(() {
                    _skill = value;
                    _error = null;
                  }),
                ),
              ],
              const SizedBox(height: 12),
              if (proposal != null) ...[
                Text(
                  'Danach: ${proposal.firstClass} ${proposal.totalLevel - proposal.secondaryLevel} '
                  '/ ${proposal.secondClass} ${proposal.secondaryLevel}',
                ),
                Text(
                  'Trefferwürfel: W${proposal.hitDie}; '
                  'fester TP-Zuwachs: +${proposal.hpGain}',
                ),
                Text('Übungsbonus nach Gesamtstufe ${proposal.totalLevel}.'),
              ] else if (problem != null) ...[
                Text(
                  problem,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 10),
              const Text(
                'Der Stufenaufstieg wird erst nach deiner Bestätigung übernommen. '
                'Keine Startausrüstung und keine zusätzlichen Rettungswurf-Übungen. '
                'Rüstungs- und Waffenübungen, Klassenfähigkeiten, Zauber und '
                'Spezialressourcen können im derzeitigen Regelkern noch nicht '
                'vollautomatisch vergeben werden.',
                style: TextStyle(fontSize: 12),
              ),
              if (hero.maxHitPoints == null || hero.hitPoints == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Fehlende Trefferpunkte bleiben unbekannt; '
                    'der ermittelte Zuwachs wird nicht auf unbestätigte Werte addiert.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        FantasyTextButton(
          label: 'Abbrechen',
          style: FantasyButtonStyle.iron,
          onPressed: () => Navigator.pop(context),
        ),
        FantasyTextButton(
          key: const ValueKey('multiclass-accept'),
          label: 'Stufenaufstieg übernehmen',
          style: FantasyButtonStyle.arcane,
          onPressed: proposal == null
              ? null
              : () => Navigator.pop(context, proposal),
        ),
      ],
    );
  }
}
