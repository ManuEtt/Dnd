import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'ability_assignment_dialog.dart' show abilityLabels;
import 'fantasy_ui.dart';

/// Historical, confirmed starting values. The current ability scores and all
/// rule calculations remain owned by the hero and the domain layer.
class StartingAbilityOriginPanel extends StatelessWidget {
  const StartingAbilityOriginPanel({super.key, required this.hero});

  final HeroCharacter hero;

  @override
  Widget build(BuildContext context) {
    final origin = hero.startingAbilityOrigin;
    if (origin == null) return const SizedBox.shrink();

    final startingScores = origin.startingScores;
    final rolledScores = origin.rolledScores;
    final methodLabel = switch (origin.method) {
      'standardArray' => 'Standardsatz',
      'pointBuy' => 'Punktekauf (27 Punkte)',
      'randomRoll' => 'Gewürfelt (4W6)',
      _ => 'Gespeicherte Attributmethode',
    };

    return ExpansionTile(
      key: ValueKey('starting-ability-origin-${hero.id}'),
      title: const Text(
        'Startwerte der Attribute',
        style: TextStyle(
          color: FantasyPalette.gold,
          fontFamily: 'serif',
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        methodLabel,
        style: const TextStyle(color: FantasyPalette.muted),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      expandedAlignment: Alignment.centerLeft,
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Gespeicherte Werte bei der Erstellung. Aktuelle Attribute können '
          'inzwischen abweichen.',
          style: TextStyle(color: FantasyPalette.muted),
        ),
        const SizedBox(height: 10),
        Text('Hintergrund: ${origin.background}'),
        const SizedBox(height: 8),
        for (final ability in abilityNames)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${abilityLabels[ability]}: Basis ${origin.baseScores[ability]} '
              '+ Hintergrund ${origin.increases[ability] ?? 0} '
              '= Startwert ${startingScores[ability]}.',
              key: ValueKey('starting-ability-origin-score-$ability'),
            ),
          ),
        if (origin.diceRolls.isNotEmpty) ...[
          const Divider(),
          const Text(
            'Gespeicherte Würfelwürfe',
            style: TextStyle(
              color: FantasyPalette.gold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Je Wurf zählt die Summe der drei höchsten W6.',
            style: TextStyle(color: FantasyPalette.muted),
          ),
          for (var index = 0; index < origin.diceRolls.length; index++)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${index + 1}. Wurf: ${origin.diceRolls[index].join(' · ')} '
                '→ ${rolledScores[index]}',
                key: ValueKey('starting-ability-origin-roll-$index'),
              ),
            ),
        ],
      ],
    );
  }
}
