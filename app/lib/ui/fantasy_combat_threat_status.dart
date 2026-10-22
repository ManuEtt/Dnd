import 'package:flutter/material.dart';

import 'fantasy_ui.dart';

/// Visualizes confirmed, persisted encounter flags only. The rule engine
/// remains responsible for resolving attacks, damage and Shield reactions.
class FantasyCombatThreatStatus extends StatelessWidget {
  const FantasyCombatThreatStatus({
    super.key,
    required this.enemyAttacksPerTurn,
    required this.enemyAttacksRemaining,
    required this.activeParticipant,
    required this.pendingShieldDecision,
    required this.heroShieldActive,
    required this.enemyShieldActive,
    required this.enemyShieldReactionUsed,
    required this.isFinished,
  });

  final int enemyAttacksPerTurn;
  final int enemyAttacksRemaining;
  final String activeParticipant;
  final bool pendingShieldDecision;
  final bool heroShieldActive;
  final bool enemyShieldActive;
  final bool enemyShieldReactionUsed;
  final bool isFinished;

  bool get isEnemyTurn => !isFinished && activeParticipant == 'enemy';

  @override
  Widget build(BuildContext context) {
    return FantasyPanel(
      key: const ValueKey('combat-threat-status'),
      title: 'Angriffsfolge & Reaktionen',
      icon: Icons.shield_moon_outlined,
      material: FantasyPanelMaterial.iron,
      accent: FantasyPalette.danger,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            enemyAttacksPerTurn > 1
                ? '$enemyAttacksPerTurn bestätigte Angriffe je Gegnerzug'
                : '1 Gegnerangriff (Standardwert; kein Mehrfachangriff bestätigt)',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (isEnemyTurn)
                _ThreatSeal(
                  key: const ValueKey('combat-enemy-turn-state'),
                  icon: Icons.sports_martial_arts,
                  label: 'Gegnerzug läuft',
                  accent: FantasyPalette.danger,
                ),
              if (isEnemyTurn && enemyAttacksRemaining > 0)
                _ThreatSeal(
                  key: const ValueKey('combat-remaining-attacks'),
                  icon: Icons.repeat_outlined,
                  label: enemyAttacksRemaining == 1
                      ? '1 weiterer Gegnerangriff'
                      : '$enemyAttacksRemaining weitere Gegnerangriffe',
                  accent: FantasyPalette.danger,
                ),
              if (pendingShieldDecision && !isFinished)
                const _ThreatSeal(
                  key: ValueKey('combat-pending-shield'),
                  icon: Icons.gpp_maybe_outlined,
                  label: 'Schildentscheidung offen – Schaden nicht gewürfelt',
                  accent: FantasyPalette.gold,
                ),
              if (heroShieldActive && !isFinished)
                const _ThreatSeal(
                  key: ValueKey('combat-hero-shield-active'),
                  icon: Icons.shield_outlined,
                  label: 'Schild des Helden aktiv',
                  accent: FantasyPalette.blue,
                ),
              if (enemyShieldActive && !isFinished)
                const _ThreatSeal(
                  key: ValueKey('combat-enemy-shield-active'),
                  icon: Icons.shield_outlined,
                  label: 'Gegnerschild aktiv',
                  accent: FantasyPalette.danger,
                ),
              if (enemyShieldReactionUsed && !isFinished)
                const _ThreatSeal(
                  key: ValueKey('combat-enemy-reaction-used'),
                  icon: Icons.hourglass_bottom_outlined,
                  label: 'Gegnerreaktion verbraucht',
                  accent: FantasyPalette.muted,
                ),
              if (isFinished)
                const _ThreatSeal(
                  key: ValueKey('combat-threat-finished'),
                  icon: Icons.check_circle_outline,
                  label: 'Begegnung beendet',
                  accent: FantasyPalette.gold,
                ),
              if (!isEnemyTurn &&
                  !isFinished &&
                  !pendingShieldDecision &&
                  !heroShieldActive &&
                  !enemyShieldActive &&
                  !enemyShieldReactionUsed)
                const _ThreatSeal(
                  key: ValueKey('combat-no-pending-threat'),
                  icon: Icons.visibility_outlined,
                  label: 'Keine laufende Gegneraktion',
                  accent: FantasyPalette.muted,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThreatSeal extends StatelessWidget {
  const _ThreatSeal({
    super.key,
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: BoxDecoration(
          color: FantasyPalette.night.withValues(alpha: .85),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: accent.withValues(alpha: .52)),
        ),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(icon, size: 17, color: accent),
            Text(
              label,
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
  );
}
