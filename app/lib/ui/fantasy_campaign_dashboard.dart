import 'package:flutter/material.dart';

import '../domain/campaign_experience.dart';
import '../domain/models.dart';
import 'character_portrait_picker.dart';
import 'fantasy_art.dart';
import 'fantasy_experience.dart';
import 'fantasy_ui.dart';
import 'fantasy_buttons.dart';

/// Read-only overview of the saved hero. Values always come from the supplied
/// campaign character, never from illustrations or invented defaults.
class FantasyActiveHeroCard extends StatelessWidget {
  const FantasyActiveHeroCard({
    super.key,
    required this.hero,
    required this.campaignName,
    required this.onContinue,
    required this.onHeroes,
  });

  final HeroCharacter hero;
  final String campaignName;
  final VoidCallback? onContinue;
  final VoidCallback onHeroes;

  String get _hitPoints => hero.hitPoints == null || hero.maxHitPoints == null
      ? '? / ?'
      : '${hero.hitPoints} / ${hero.maxHitPoints}';

  String get _movement {
    final meters = hero.baseSpeedMeters;
    if (meters == null) return '?';
    return meters == meters.roundToDouble()
        ? '${meters.toInt()} m'
        : '${meters.toStringAsFixed(1).replaceAll('.', ',')} m';
  }

  @override
  Widget build(BuildContext context) {
    final maxHp = hero.maxHitPoints;
    final hitPointsRatio = hero.hitPoints != null && maxHp != null && maxHp > 0
        ? (hero.hitPoints! / maxHp).clamp(0.0, 1.0).toDouble()
        : null;
    final nextExperience = CampaignExperience.nextThreshold(hero);
    final experienceProgress = CampaignExperience.levelProgress(hero);

    return Container(
      key: const ValueKey('fantasy-active-hero-card'),
      decoration: BoxDecoration(
        color: FantasyPalette.ink,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FantasyPalette.gold.withValues(alpha: .65)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: .22,
                child: Image.asset(
                  FantasyArtwork.castle,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stack) =>
                      const ColoredBox(color: FantasyPalette.ink),
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xf50c1827),
                      Color(0xe6172d41),
                      Color(0xe80b1725),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    FantasyRuneEmblem(rune: FantasyRune.hero, size: 37),
                    SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        'DEIN AKTIVER HELD',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: FantasyPalette.gold,
                          letterSpacing: 1.2,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FantasyCharacterPortrait(
                      preset: hero.portraitPreset,
                      photoBase64: hero.portraitPhotoBase64,
                      name: hero.name,
                      size: 79,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hero.name.isEmpty ? 'Unbenannter Held' : hero.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${hero.species} · ${hero.classSummary} · Stufe ${hero.level}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: FantasyPalette.ivory),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            campaignName,
                            maxLines: 1,
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
                const SizedBox(height: 13),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final largeText =
                        MediaQuery.textScalerOf(context).scale(1) >= 1.8;
                    final singleColumn =
                        largeText && constraints.maxWidth < 500;
                    final tileWidth = singleColumn
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 14) / 3;
                    return Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        SizedBox(
                          width: tileWidth,
                          child: _HeroMetric(
                            key: const ValueKey('active-hero-metric-hp'),
                            label: 'Trefferpunkte',
                            value: _hitPoints,
                            spokenValue:
                                hero.hitPoints == null ||
                                    hero.maxHitPoints == null
                                ? null
                                : '${hero.hitPoints} von ${hero.maxHitPoints}',
                            icon: Icons.favorite_border,
                            color: FantasyPalette.danger,
                          ),
                        ),
                        SizedBox(
                          width: tileWidth,
                          child: _HeroMetric(
                            key: const ValueKey('active-hero-metric-ac'),
                            label: 'Rüstungsklasse',
                            value: hero.armorClass?.toString() ?? '?',
                            icon: Icons.shield_outlined,
                            color: FantasyPalette.gold,
                          ),
                        ),
                        SizedBox(
                          width: tileWidth,
                          child: _HeroMetric(
                            key: const ValueKey('active-hero-metric-speed'),
                            label: 'Bewegung',
                            value: _movement,
                            icon: Icons.directions_run,
                            color: FantasyPalette.blue,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (hitPointsRatio == null) ...[
                  const SizedBox(height: 9),
                  const Text(
                    'Trefferpunkte noch nicht bestätigt',
                    style: TextStyle(fontSize: 12, color: FantasyPalette.muted),
                  ),
                ] else ...[
                  const SizedBox(height: 10),
                  Semantics(
                    label: 'Trefferpunkte: ${hero.hitPoints} von $maxHp',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: hitPointsRatio,
                        minHeight: 7,
                        backgroundColor: FantasyPalette.night,
                        valueColor: AlwaysStoppedAnimation(
                          hitPointsRatio > .5
                              ? FantasyPalette.success
                              : hitPointsRatio > .2
                              ? FantasyPalette.gold
                              : FantasyPalette.danger,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (hero.experience == null)
                  const Text(
                    'Erfahrungspunkte: nicht bestätigt',
                    style: TextStyle(fontSize: 12, color: FantasyPalette.muted),
                  )
                else ...[
                  Text(
                    nextExperience == null
                        ? 'Erfahrung: ${hero.experience} EP · Höchststufe'
                        : 'Erfahrung: ${hero.experience} / $nextExperience EP',
                    style: const TextStyle(
                      fontSize: 12,
                      color: FantasyPalette.ivory,
                    ),
                  ),
                  if (experienceProgress != null) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: experienceProgress,
                        minHeight: 5,
                        backgroundColor: FantasyPalette.night,
                        color: FantasyPalette.blue,
                      ),
                    ),
                  ],
                  if (CampaignExperience.canLevelUp(hero)) ...[
                    const SizedBox(height: 6),
                    Text(
                      CampaignExperience.pendingLevels(hero) == 1
                          ? 'Stufenaufstieg möglich'
                          : '${CampaignExperience.pendingLevels(hero)} '
                                'Stufenaufstiege möglich – einzeln bestätigen',
                      key: const ValueKey('hero-pending-level-ups'),
                      style: const TextStyle(
                        color: FantasyPalette.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
                if (!hero.isComplete) ...[
                  const SizedBox(height: 10),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: FantasyPalette.gold,
                        size: 17,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Einige Charakterwerte müssen noch bestätigt werden.',
                          style: TextStyle(
                            color: FantasyPalette.ivory,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 13),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FantasyTextButton(
                      key: const ValueKey('fantasy-hero-continue'),
                      label: 'Abenteuer fortsetzen',
                      icon: Icons.play_arrow,
                      style: FantasyButtonStyle.woodGold,
                      onPressed: onContinue,
                    ),
                    FantasyTextButton(
                      key: const ValueKey('fantasy-hero-archive'),
                      label: 'Helden verwalten',
                      icon: Icons.people_outline,
                      style: FantasyButtonStyle.iron,
                      onPressed: onHeroes,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Adaptable metric tile with compact artwork and explicit unknown values.
class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.spokenValue,
  });

  final String label;
  final String value;
  final String? spokenValue;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final accessibleValue = value.contains('?')
        ? 'nicht bestätigt'
        : (spokenValue ?? value);
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '$label: $accessibleValue',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: FantasyPalette.night.withValues(alpha: .80),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withValues(alpha: .35)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 3),
              Text(
                value,
                softWrap: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: FantasyPalette.ivory,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                softWrap: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: FantasyPalette.muted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
