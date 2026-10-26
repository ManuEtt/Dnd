import 'package:flutter/material.dart';

import '../domain/cover_rules.dart';
import 'fantasy_ui.dart';

/// A presentation-only view over confirmed encounter resource consumption.
/// The game engine alone decides when an action becomes spent or available.
class FantasyCombatActionEconomy extends StatelessWidget {
  const FantasyCombatActionEconomy({
    super.key,
    required this.actionUsed,
    required this.bonusActionUsed,
    required this.reactionUsed,
    required this.movementRemainingLabel,
    required this.spellSlotExpendedThisTurn,
  });

  final bool actionUsed;
  final bool bonusActionUsed;
  final bool reactionUsed;
  final String movementRemainingLabel;
  final bool spellSlotExpendedThisTurn;

  @override
  Widget build(BuildContext context) => FantasyPanel(
    key: const ValueKey('combat-action-economy'),
    title: 'Deine Möglichkeiten',
    icon: Icons.hourglass_bottom_outlined,
    accent: FantasyPalette.blue,
    material: FantasyPanelMaterial.iron,
    child: LayoutBuilder(
      builder: (context, constraints) {
        // At 200% Android system text, keep each confirmed resource
        // readable in its own row instead of squeezing neighboring seals.
        final useFullWidth =
            constraints.maxWidth < 500 &&
            MediaQuery.textScalerOf(context).scale(1) >= 1.8;
        final sealWidth = useFullWidth ? constraints.maxWidth : null;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ActionSeal(
              key: const ValueKey('combat-action-state'),
              label: 'Aktion',
              value: actionUsed ? 'verbraucht' : 'verfügbar',
              available: !actionUsed,
              icon: Icons.sports_martial_arts,
              width: sealWidth,
            ),
            _ActionSeal(
              key: const ValueKey('combat-bonus-action-state'),
              label: 'Bonusaktion',
              value: bonusActionUsed ? 'verbraucht' : 'verfügbar',
              available: !bonusActionUsed,
              icon: Icons.auto_awesome_outlined,
              width: sealWidth,
            ),
            _ActionSeal(
              key: const ValueKey('combat-reaction-state'),
              label: 'Reaktion',
              value: reactionUsed ? 'verbraucht' : 'verfügbar',
              available: !reactionUsed,
              icon: Icons.shield_outlined,
              width: sealWidth,
            ),
            _ActionSeal(
              key: const ValueKey('combat-movement-state'),
              label: 'Bewegung',
              value: movementRemainingLabel,
              available: false,
              icon: Icons.directions_run_outlined,
              color: FantasyPalette.blue,
              width: sealWidth,
            ),
            if (spellSlotExpendedThisTurn)
              _ActionSeal(
                key: const ValueKey('combat-spell-slot-state'),
                label: 'Zauberplatz',
                value: 'in diesem Zug verbraucht',
                available: false,
                icon: Icons.auto_awesome,
                color: FantasyPalette.danger,
                width: sealWidth,
              ),
          ],
        );
      },
    ),
  );
}

class _ActionSeal extends StatelessWidget {
  const _ActionSeal({
    super.key,
    required this.label,
    required this.value,
    required this.available,
    required this.icon,
    this.color,
    this.width,
  });

  final String label;
  final String value;
  final bool available;
  final IconData icon;
  final Color? color;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final accent =
        color ?? (available ? FantasyPalette.success : FantasyPalette.muted);
    return SizedBox(
      width: width,
      child: Semantics(
        container: true,
        label: '$label: $value',
        child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          decoration: BoxDecoration(
            color: FantasyPalette.night.withValues(alpha: .85),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: accent.withValues(alpha: .48)),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(icon, color: accent, size: 17),
              Text(
                '$label: $value',
                softWrap: true,
                style: const TextStyle(
                  fontSize: 12,
                  color: FantasyPalette.ivory,
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// Confirmation-only cover controls. Popups retain the exact commands and
/// disabled conditions used before the visual redesign.
class FantasyCombatCoverPanel extends StatelessWidget {
  const FantasyCombatCoverPanel({
    super.key,
    required this.heroCover,
    required this.enemyCover,
    required this.canChange,
    required this.onAction,
  });

  final CoverLevel heroCover;
  final CoverLevel enemyCover;
  final bool canChange;
  final ValueChanged<String> onAction;

  @override
  Widget build(BuildContext context) => FantasyPanel(
    key: const ValueKey('combat-cover-panel'),
    title: 'Deckung gegen diesen Gegner',
    icon: Icons.shield_outlined,
    material: FantasyPanelMaterial.iron,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final useFullWidth =
            constraints.maxWidth < 500 &&
            MediaQuery.textScalerOf(context).scale(1) >= 1.8;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nur ausdrücklich bestätigte Hindernisse gelten. '
              'Höchste Deckung zählt; eine Bewegung beendet die '
              'bisher bestätigte Deckungsposition des Helden.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CombatCoverSelector(
                  target: 'Held',
                  cover: heroCover,
                  canChange: canChange,
                  onAction: onAction,
                  fullWidth: useFullWidth ? constraints.maxWidth : null,
                  showFullLabel: useFullWidth,
                ),
                _CombatCoverSelector(
                  target: 'Gegner',
                  cover: enemyCover,
                  canChange: canChange,
                  onAction: onAction,
                  fullWidth: useFullWidth ? constraints.maxWidth : null,
                  showFullLabel: useFullWidth,
                ),
              ],
            ),
          ],
        );
      },
    ),
  );
}

class _CombatCoverSelector extends StatelessWidget {
  const _CombatCoverSelector({
    required this.target,
    required this.cover,
    required this.canChange,
    required this.onAction,
    required this.fullWidth,
    required this.showFullLabel,
  });

  final String target;
  final CoverLevel cover;
  final bool canChange;
  final ValueChanged<String> onAction;
  final double? fullWidth;
  final bool showFullLabel;

  @override
  Widget build(BuildContext context) {
    final coverLabel = CoverRules.label(cover);
    return SizedBox(
      width: fullWidth,
      child: Semantics(
        // Keep the confirmed status independent of the popup's native
        // accessible action and tooltip; both must remain available.
        container: true,
        explicitChildNodes: true,
        label:
            'Deckung für $target: $coverLabel. '
            '${canChange ? 'Änderbar' : 'Nicht änderbar'}.',
        child: PopupMenuButton<CoverLevel>(
          key: ValueKey(
            target == 'Held' ? 'combat-hero-cover' : 'combat-enemy-cover',
          ),
          tooltip: canChange
              ? 'Deckung für $target ändern'
              : 'Deckung für $target derzeit nicht änderbar',
          enabled: canChange,
          onSelected: (grade) =>
              onAction('Deckung: $target ${CoverRules.commandValue(grade)}'),
          itemBuilder: (_) => [
            for (final grade in CoverLevel.values)
              PopupMenuItem<CoverLevel>(
                value: grade,
                child: Text(CoverRules.label(grade)),
              ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: FantasyPalette.night.withValues(alpha: .85),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: FantasyPalette.gold.withValues(
                  alpha: canChange ? .65 : .28,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: canChange ? FantasyPalette.gold : FantasyPalette.muted,
                  size: 17,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '$target: $coverLabel',
                    maxLines: showFullLabel ? null : 2,
                    softWrap: true,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
