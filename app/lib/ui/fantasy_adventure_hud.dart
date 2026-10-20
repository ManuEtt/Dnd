import 'package:flutter/material.dart';

import '../domain/campaign_experience.dart';
import '../domain/models.dart';
import 'fantasy_experience.dart';
import 'fantasy_ui.dart';

/// A read-only in-game HUD. Every stat is derived from confirmed campaign
/// state. Missing values stay unknown; this widget never changes game rules.
class FantasyAdventureStatusHud extends StatelessWidget {
  const FantasyAdventureStatusHud({super.key, required this.hero});

  final HeroCharacter hero;

  @override
  Widget build(BuildContext context) {
    final hpRatio =
        hero.hitPoints != null &&
            hero.maxHitPoints != null &&
            hero.maxHitPoints! > 0
        ? (hero.hitPoints! / hero.maxHitPoints!).clamp(0.0, 1.0).toDouble()
        : null;
    final experienceRatio = CampaignExperience.levelProgress(hero);
    final hpValue = hero.hitPoints == null || hero.maxHitPoints == null
        ? '? / ?'
        : '${hero.hitPoints} / ${hero.maxHitPoints}';
    final speed = hero.baseSpeedMeters;
    final speedText = speed == null
        ? '?'
        : speed == speed.roundToDouble()
        ? '${speed.toInt()} m'
        : '${speed.toStringAsFixed(1).replaceAll('.', ',')} m';

    return Container(
      key: const ValueKey('adventure-live-status'),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        border: Border.all(color: FantasyPalette.gold.withValues(alpha: .50)),
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xf4122636), Color(0xf20c1726)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              FantasyRuneEmblem(rune: FantasyRune.hero, size: 28),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'HELDENSTATUS',
                  style: TextStyle(
                    color: FantasyPalette.gold,
                    letterSpacing: 1,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 380 ? 4 : 2;
              final tileWidth =
                  (constraints.maxWidth - 8 * (columns - 1)) / columns;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: tileWidth,
                    child: _StatusTile(
                      label: 'TP',
                      value: hpValue,
                      icon: Icons.favorite_outline,
                      color: FantasyPalette.danger,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _StatusTile(
                      label: 'RK',
                      value: hero.armorClass?.toString() ?? '?',
                      icon: Icons.shield_outlined,
                      color: FantasyPalette.gold,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _StatusTile(
                      label: 'Tempo',
                      value: speedText,
                      icon: Icons.directions_run_outlined,
                      color: FantasyPalette.blue,
                    ),
                  ),
                  SizedBox(
                    width: tileWidth,
                    child: _StatusTile(
                      label: 'EP',
                      value: hero.experience == null
                          ? '?'
                          : '${hero.experience}',
                      icon: Icons.auto_awesome_outlined,
                      color: FantasyPalette.success,
                    ),
                  ),
                ],
              );
            },
          ),
          if (hpRatio != null) ...[
            const SizedBox(height: 9),
            Semantics(
              label:
                  'Trefferpunkte: ${hero.hitPoints} von ${hero.maxHitPoints}',
              child: _MeterTrack(
                value: hpRatio,
                height: 6,
                color: hpRatio > .5
                    ? FantasyPalette.success
                    : hpRatio > .2
                    ? FantasyPalette.gold
                    : FantasyPalette.danger,
              ),
            ),
          ],
          if (experienceRatio != null) ...[
            const SizedBox(height: 7),
            Semantics(
              label: 'Erfahrungsfortschritt',
              child: _MeterTrack(
                key: const ValueKey('adventure-xp-progress'),
                value: experienceRatio,
                height: 4,
                color: FantasyPalette.blue,
              ),
            ),
          ],
          if (hero.temporaryHitPoints > 0 ||
              hero.conditions.isNotEmpty ||
              hero.concentratingOn.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              [
                if (hero.temporaryHitPoints > 0)
                  '+${hero.temporaryHitPoints} temporäre TP',
                if (hero.conditions.isNotEmpty)
                  'Zustände: ${hero.conditions.join(', ')}',
                if (hero.concentratingOn.isNotEmpty)
                  'Konzentration: ${hero.concentratingOn}',
              ].join(' · '),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: FantasyPalette.ivory),
            ),
          ],
          if (CampaignExperience.canLevelUp(hero)) ...[
            const SizedBox(height: 7),
            Text(
              CampaignExperience.pendingLevels(hero) == 1
                  ? 'Stufenaufstieg möglich – Charakterbogen öffnen'
                  : '${CampaignExperience.pendingLevels(hero)} '
                        'Stufenaufstiege möglich – einzeln im Charakterbogen bestätigen',
              key: const ValueKey('adventure-pending-level-ups'),
              style: const TextStyle(
                color: FantasyPalette.gold,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: FantasyPalette.night.withValues(alpha: .85),
      border: Border.all(color: color.withValues(alpha: .32)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FantasyPalette.muted,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 16,
                color: FantasyPalette.ivory,
                fontWeight: FontWeight.bold,
                fontFamily: 'serif',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// The painted HUD meters must not look like an async loading indicator.
/// A linear progress indicator elsewhere in the app means a pending action.
class _MeterTrack extends StatelessWidget {
  const _MeterTrack({
    super.key,
    required this.value,
    required this.color,
    required this.height,
  });

  final double value;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: ColoredBox(
      color: FantasyPalette.night,
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value,
            heightFactor: 1,
            child: ColoredBox(color: color),
          ),
        ),
      ),
    ),
  );
}

/// Collapsible quest board for verified Quest entries in the current campaign.
/// An empty list is explicitly an unknown/no-recorded-quests state, not a
/// fabricated objective. The journal action is a normal Flutter callback.
class FantasyAdventureQuestBoard extends StatelessWidget {
  const FantasyAdventureQuestBoard({
    super.key,
    required this.campaign,
    required this.onOpenJournal,
  });

  final Campaign campaign;
  final VoidCallback onOpenJournal;

  @override
  Widget build(BuildContext context) {
    final active = campaign.quests
        .where((quest) => quest.status == 'active')
        .toList();
    final resolved = campaign.quests
        .where((quest) => quest.status != 'active')
        .toList();

    return Container(
      key: const ValueKey('adventure-quest-board'),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: FantasyPalette.ink,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FantasyPalette.gold.withValues(alpha: .45)),
      ),
      child: ExpansionTile(
        key: ValueKey('adventure-quest-tiles-${campaign.id}'),
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: const FantasyRuneEmblem(rune: FantasyRune.tome, size: 35),
        title: const Text(
          'Auftragsübersicht',
          style: TextStyle(
            color: FantasyPalette.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          active.isEmpty
              ? 'Keine aktiven Aufträge bestätigt'
              : '${active.length} aktiv · ${active.first.title}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: FantasyPalette.muted),
        ),
        children: [
          const Divider(height: 1, color: Color(0x55ddb96c)),
          if (campaign.quests.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 14, 12, 4),
              child: Text(
                'Noch keine Aufträge im Spielstand dokumentiert.',
                style: TextStyle(color: FantasyPalette.muted),
              ),
            ),
          for (final quest in active)
            _QuestLine(
              key: ValueKey('adventure-quest-${quest.id}'),
              quest: quest,
            ),
          if (resolved.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Abgeschlossen / gescheitert: ${resolved.length}',
                  style: const TextStyle(
                    color: FantasyPalette.muted,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            for (final quest in resolved.take(3))
              _QuestLine(
                key: ValueKey('adventure-quest-${quest.id}'),
                quest: quest,
              ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 7),
              child: TextButton.icon(
                key: const ValueKey('adventure-quest-open-journal'),
                onPressed: onOpenJournal,
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Tagebuch öffnen'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestLine extends StatelessWidget {
  const _QuestLine({super.key, required this.quest});

  final Quest quest;

  @override
  Widget build(BuildContext context) {
    final color = quest.status == 'completed'
        ? FantasyPalette.success
        : quest.status == 'failed'
        ? FantasyPalette.danger
        : FantasyPalette.gold;
    final status = quest.status == 'completed'
        ? 'Abgeschlossen'
        : quest.status == 'failed'
        ? 'Gescheitert'
        : 'Aktiv';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            quest.status == 'completed'
                ? Icons.check_circle_outline
                : quest.status == 'failed'
                ? Icons.cancel_outlined
                : Icons.adjust,
            size: 21,
            color: color,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quest.title, maxLines: 3, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(status, style: TextStyle(color: color, fontSize: 11)),
                if (quest.description.trim().isNotEmpty)
                  Text(
                    quest.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FantasyPalette.muted,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
