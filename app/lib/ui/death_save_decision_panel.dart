import 'package:flutter/material.dart';
import 'fantasy_buttons.dart';

import '../domain/death_saving_throw_rules.dart';
import '../domain/models.dart';
import '../domain/saving_throw_class_actions.dart';

/// A persisted decision about an already rolled die; opening this view neither
/// applies its consequences nor spends a class resource.
class DeathSaveDecisionPanel extends StatelessWidget {
  const DeathSaveDecisionPanel({
    super.key,
    required this.hero,
    required this.pending,
    required this.busy,
    required this.onAccept,
    required this.onReroll,
  });
  final HeroCharacter hero;
  final PendingDeathSave pending;
  final bool busy;
  final VoidCallback onAccept;
  final ValueChanged<SavingThrowRerollFeature> onReroll;

  @override
  Widget build(BuildContext context) => Card(
    key: const ValueKey('death-save-decision'),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vorläufiger Todesrettungswurf',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            'Naturwurf ${pending.originalNatural}, Bonus ${pending.modifier}: '
            'misslungen. Die Folgen sind noch nicht bestätigt.',
          ),
          const Text(
            'Ein Wiederholungswurf ersetzt diesen Wurf vollständig. '
            'Das neue Ergebnis gilt auch, wenn es schlechter ist.',
          ),
          if (busy) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              label:
                  'Todesrettungswurf: Entscheidung wird verarbeitet. '
                  'Weitere Eingaben sind gesperrt.',
              child: const ExcludeSemantics(
                child: Text(
                  'Entscheidung wird verarbeitet …',
                  key: ValueKey('death-save-busy-status'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FantasyTextButton(
                key: const ValueKey('death-save-accept'),
                label: 'Wurf annehmen',
                style: FantasyButtonStyle.woodGold,
                onPressed: busy ? null : onAccept,
              ),
              if (DeathSavingThrowRules.available(
                hero,
                SavingThrowRerollFeature.disciplinedSurvivor,
              ))
                FantasyTextButton(
                  key: const ValueKey('death-save-reroll-focus'),
                  label: 'Wiederholen · 1 Fokus',
                  style: FantasyButtonStyle.arcane,
                  onPressed: busy
                      ? null
                      : () => onReroll(
                          SavingThrowRerollFeature.disciplinedSurvivor,
                        ),
                ),
              if (DeathSavingThrowRules.available(
                hero,
                SavingThrowRerollFeature.indomitable,
              ))
                FantasyTextButton(
                  key: const ValueKey('death-save-reroll-indomitable'),
                  label: 'Wiederholen · Unbeugsam',
                  style: FantasyButtonStyle.arcane,
                  onPressed: busy
                      ? null
                      : () => onReroll(SavingThrowRerollFeature.indomitable),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
