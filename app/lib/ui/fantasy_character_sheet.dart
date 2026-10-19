import 'package:flutter/material.dart';

import '../domain/character_rule_engine.dart';
import '../domain/class_progression_rules.dart';
import '../domain/class_feature_resources.dart';
import '../domain/class_resource_rules.dart';
import '../domain/srd_class_feature_catalog.dart';
import '../domain/condition_rules.dart';
import '../domain/models.dart';
import '../domain/multiclass_rules.dart';
import '../domain/rest_rules.dart';
import '../domain/spellcasting_rules.dart';
import '../domain/rules_engine.dart';
import 'fantasy_art.dart';
import 'character_portrait_picker.dart';

// A read-only presentation of the actual, confirmed character data. No state,
// rule changes, generated portrait, or assumed missing character values.
const _night = Color(0xff09121f);
const _panel = Color(0xff142536);
const _gold = Color(0xffddb96c);
const _ivory = Color(0xfff4ead6);
const _muted = Color(0xffadc0cf);

class CharacterSheetPage extends StatefulWidget {
  const CharacterSheetPage({super.key, required this.hero, this.onEdit});

  final HeroCharacter hero;
  final VoidCallback? onEdit;

  @override
  State<CharacterSheetPage> createState() => _CharacterSheetPageState();
}

class _CharacterSheetPageState extends State<CharacterSheetPage> {
  int _section = 0;

  @override
  Widget build(BuildContext context) {
    final hero = widget.hero;
    return Scaffold(
      backgroundColor: _night,
      appBar: AppBar(
        title: const Text('Charakterbogen'),
        centerTitle: true,
        backgroundColor: _night,
        actions: [
          if (widget.onEdit != null)
            IconButton(
              tooltip: 'Charakter bearbeiten',
              icon: const Icon(Icons.edit_outlined),
              onPressed: widget.onEdit,
            ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff142c42), _night, Color(0xff0b1725)],
            stops: [0, .42, 1],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: ListView(
              key: const ValueKey('fantasy-character-sheet-scroll'),
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 36),
              children: [
                _CharacterHeader(hero: hero),
                const SizedBox(height: 14),
                _SummaryGrid(hero: hero),
                const SizedBox(height: 20),
                _SectionNavigation(
                  selected: _section,
                  onSelected: (index) => setState(() => _section = index),
                ),
                const SizedBox(height: 24),
                if (_section == 0) _AbilitiesSection(hero: hero),
                if (_section == 1) _ConditionsSection(hero: hero),
                if (_section == 2) _DefensesSection(hero: hero),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CharacterHeader extends StatelessWidget {
  const _CharacterHeader({required this.hero});
  final HeroCharacter hero;

  @override
  Widget build(BuildContext context) {
    final current = hero.hitPoints;
    final maximum = hero.maxHitPoints;
    final ratio = current != null && maximum != null && maximum > 0
        ? (current / maximum).clamp(0.0, 1.0).toDouble()
        : null;
    final initials = hero.name.trim().isEmpty
        ? '?'
        : hero.name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((p) => p[0].toUpperCase())
              .join();
    return _FantasyFrame(
      child: Column(
        children: [
          const FantasyMoonlitBanner(height: 80),
          const SizedBox(height: 12),
          Text(
            hero.name.isEmpty ? 'Unbenannter Held' : hero.name,
            key: const ValueKey('sheet-hero-name'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ivory,
              fontFamily: 'serif',
              fontSize: 29,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${hero.species}  •  ${hero.classSummary}  •  Stufe ${hero.level}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
              letterSpacing: .75,
            ),
          ),
          if (hero.subclass.isNotEmpty || hero.secondarySubclass.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                [
                  if (hero.subclass.isNotEmpty)
                    '${hero.className}: ${hero.subclass}',
                  if (hero.hasSecondClass && hero.secondarySubclass.isNotEmpty)
                    '${hero.secondaryClassName}: ${hero.secondarySubclass}',
                ].join(' · '),
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 11),
              ),
            ),
          const SizedBox(height: 18),
          Row(
            children: [
              if (hero.portraitPreset >= 0 ||
                  hero.portraitPhotoBase64.isNotEmpty)
                FantasyCharacterPortrait(
                  key: const ValueKey('sheet-hero-portrait'),
                  preset: hero.portraitPreset,
                  photoBase64: hero.portraitPhotoBase64,
                  name: hero.name,
                  size: 88,
                )
              else
                Container(
                  key: const ValueKey('sheet-avatar-placeholder'),
                  width: 88,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xff39546c), Color(0xff0c1929)],
                    ),
                    border: Border.all(color: _gold, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Semantics(
                    label: 'Platzhalter für das Charakterporträt',
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _gold,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TREFFERPUNKTE',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 11,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${current ?? '–'} / ${maximum ?? '–'}',
                        key: const ValueKey('sheet-hit-points'),
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontWeight: FontWeight.bold,
                          fontSize: 31,
                          color: _ivory,
                        ),
                      ),
                    ),
                    if (hero.temporaryHitPoints > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '+${hero.temporaryHitPoints} temporäre TP',
                        key: const ValueKey('sheet-temporary-hit-points'),
                        style: const TextStyle(color: _gold, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (ratio != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 9,
                          backgroundColor: const Color(0xff273746),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ratio > .5
                                ? const Color(0xff3fc38b)
                                : ratio > .2
                                ? const Color(0xffe2af5d)
                                : const Color(0xffd65f65),
                          ),
                        ),
                      )
                    else
                      const Text(
                        'Noch nicht erfasst',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                    const SizedBox(height: 9),
                    Text(
                      hero.background.isEmpty
                          ? 'Ein Abenteuer wartet auf dich'
                          : hero.background,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _gold, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.hero});
  final HeroCharacter hero;

  @override
  Widget build(BuildContext context) {
    final level = hero.level;
    final proficiency = level >= 1 && level <= 20
        ? RulesEngine.proficiencyBonus(level)
        : null;
    final dex = _modifier(hero.abilities['dexterity']);
    final values = <({String label, String value, IconData icon})>[
      (
        label: 'ÜBUNGSBONUS',
        value: proficiency == null ? '–' : _signed(proficiency),
        icon: Icons.stars_outlined,
      ),
      (
        label: 'BEWEGUNG',
        value: _meters(CharacterRuleEngine.speedMeters(hero)),
        icon: Icons.directions_run_outlined,
      ),
      (
        label: 'INITIATIVE',
        value: dex == null ? '–' : _signed(RulesEngine.initiativeBonus(hero)),
        icon: Icons.casino_outlined,
      ),
      (
        label: 'RÜSTUNGSKLASSE',
        value: hero.armorClass?.toString() ?? '–',
        icon: Icons.shield_outlined,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 580 ? 2 : 4;
        // A width-derived aspect ratio makes these tiles too short on phones:
        // the icon, score and label overflow by a few pixels at 320/360 dp.
        // Reserve two label lines and scale the row height with system text size
        // instead of clipping text or ignoring Flutter's overflow reports.
        final scaler = MediaQuery.textScalerOf(context);
        final tileHeight =
            (20 +
                    22 +
                    5 +
                    scaler.scale(23) * 1.35 +
                    2 +
                    scaler.scale(10) * 1.45 * 2 +
                    12)
                .clamp(124.0, 320.0)
                .toDouble();
        // GridView.count has no mainAxisExtent parameter. An explicit
        // SliverGridDelegateWithFixedCrossAxisCount supports fixed row heights
        // and prevents narrow-screen RenderFlex overflow without clipping text.
        return GridView(
          key: const ValueKey('sheet-summary-grid'),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: tileHeight,
            mainAxisSpacing: 9,
            crossAxisSpacing: 9,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final item in values)
              _FantasyFrame(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, size: 22, color: _gold),
                    const SizedBox(height: 5),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        item.value,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _ivory,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 10,
                        letterSpacing: .6,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SectionNavigation extends StatelessWidget {
  const _SectionNavigation({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) {
    const labels = ['Attribute', 'Zustände', 'Verteidigung'];
    const icons = [
      Icons.auto_awesome_outlined,
      Icons.healing_outlined,
      Icons.security_outlined,
    ];
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: OutlinedButton(
                key: ValueKey('sheet-tab-$i'),
                onPressed: () => onSelected(i),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  foregroundColor: selected == i ? _gold : _muted,
                  backgroundColor: selected == i ? _panel : _night,
                  side: BorderSide(
                    color: selected == i ? _gold : const Color(0xff334658),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icons[i], size: 18),
                    const SizedBox(height: 3),
                    Text(
                      labels[i],
                      maxLines: 1,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

const _abilities = <({String id, String label, IconData icon, Color color})>[
  (
    id: 'strength',
    label: 'Stärke',
    icon: Icons.fitness_center,
    color: Color(0xffc96b64),
  ),
  (
    id: 'dexterity',
    label: 'Geschicklichkeit',
    icon: Icons.air,
    color: Color(0xff78b593),
  ),
  (
    id: 'constitution',
    label: 'Konstitution',
    icon: Icons.favorite_outline,
    color: Color(0xffd6ae67),
  ),
  (
    id: 'intelligence',
    label: 'Intelligenz',
    icon: Icons.menu_book_outlined,
    color: Color(0xff79b9eb),
  ),
  (
    id: 'wisdom',
    label: 'Weisheit',
    icon: Icons.visibility_outlined,
    color: Color(0xffac96d9),
  ),
  (
    id: 'charisma',
    label: 'Charisma',
    icon: Icons.wb_sunny_outlined,
    color: Color(0xffe6bf6f),
  ),
];

int? _modifier(int? score) => score == null ? null : ((score - 10) / 2).floor();
String _signed(int value) => value >= 0 ? '+$value' : '$value';

/// Format effective SRD movement without a misleading '.0' suffix.
/// Exhaustion can produce half-metre steps that must be preserved.
String _meters(double? speed, {String unknown = '–'}) {
  if (speed == null) return unknown;
  final value = speed == speed.truncateToDouble()
      ? speed.toInt().toString()
      : speed.toString();
  return '$value m';
}

class _AbilitiesSection extends StatelessWidget {
  const _AbilitiesSection({required this.hero});
  final HeroCharacter hero;

  @override
  Widget build(BuildContext context) {
    final proficiency = hero.level >= 1 && hero.level <= 20
        ? RulesEngine.proficiencyBonus(hero.level)
        : null;
    final remainingSlots = SpellcastingRules.availableSlots(hero);
    final regularSummary = remainingSlots.entries
        .map(
          (e) =>
              '${e.key}. Grad: ${e.value}/${MulticlassRules.spellSlots(hero)[e.key - 1]}',
        )
        .join(' · ');
    final pactMax = SpellcastingRules.pactSlotCount(hero);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (SrdClassFeatureCatalog.unlocked(hero).isNotEmpty) ...[
          const _OrnateHeading(
            'Klassenmerkmale (SRD 5.2.1)',
            icon: Icons.auto_stories_outlined,
          ),
          const SizedBox(height: 8),
          _FantasyFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final feature in SrdClassFeatureCatalog.unlocked(hero))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${feature.className} ${feature.classLevel} · '
                      '${feature.name}${feature.isSubclass ? ' (Unterklasse)' : ''} '
                      '· ${feature.automation == FeatureAutomation.automatic ? 'Berechnet' : 'Regelprüfung erforderlich'}',
                      style: TextStyle(
                        color: feature.automation == FeatureAutomation.automatic
                            ? _ivory
                            : _muted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 6),
                const Text(
                  'Die Auflistung ist kein Nachweis, dass sämtliche '
                  'Merkmalswirkungen automatisch simuliert werden.',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (ClassResourceRules.supported.any(
          (id) => ClassResourceRules.maximum(hero, id) > 0,
        )) ...[
          const _OrnateHeading('Klassenressourcen', icon: Icons.bolt_outlined),
          const SizedBox(height: 8),
          _FantasyFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final id in ClassResourceRules.supported)
                  if (ClassResourceRules.maximum(hero, id) > 0)
                    Text(
                      '$id: ${ClassResourceRules.remaining(hero, id)}/'
                      '${ClassResourceRules.maximum(hero, id)}',
                      style: const TextStyle(color: _ivory),
                    ),
                const Text(
                  'Verbrauch wird nur über bestätigte Regelaktionen '
                  'gespeichert; besondere Effekte brauchen eine eigene Prüfung.',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (ClassFeatureResources.fighterLevel(hero) > 0) ...[
          const _OrnateHeading('Kämpferressourcen', icon: Icons.bolt_outlined),
          const SizedBox(height: 8),
          _FantasyFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Second Wind: '
                  '${ClassFeatureResources.remainingSecondWind(hero)}/'
                  '${ClassFeatureResources.secondWindMaximum(hero)}',
                  style: const TextStyle(color: _ivory),
                ),
                if (ClassFeatureResources.actionSurgeMaximum(hero) > 0)
                  Text(
                    'Action Surge: '
                    '${ClassFeatureResources.remainingActionSurge(hero)}/'
                    '${ClassFeatureResources.actionSurgeMaximum(hero)}',
                    style: const TextStyle(color: _ivory),
                  ),
                const Text(
                  'Second Wind benötigt eine Bonusaktion. '
                  'Action Surge gewährt im vereinfachten Kampf eine weitere '
                  'Angriffsaktion.',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
        ],
        if (remainingSlots.isNotEmpty ||
            pactMax > 0 ||
            hero.concentratingOn.isNotEmpty) ...[
          const _OrnateHeading('Zauberei', icon: Icons.auto_awesome_outlined),
          const SizedBox(height: 8),
          _FantasyFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (remainingSlots.isNotEmpty)
                  Text(
                    'Freie Zauberplätze: $regularSummary',
                    style: const TextStyle(color: _ivory),
                  ),
                if (pactMax > 0)
                  Text(
                    'Paktmagie (Grad ${SpellcastingRules.pactSlotLevel(hero)}): '
                    '${SpellcastingRules.availablePactSlots(hero)}/$pactMax frei',
                    style: const TextStyle(color: _ivory),
                  ),
                Text(
                  'Konzentration: ${hero.concentratingOn.isEmpty ? 'keine' : hero.concentratingOn}',
                  style: const TextStyle(color: _muted),
                ),
                const Text(
                  'Zauberwirkungen und vorbereitete Zauber werden separat bestätigt.',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
        ],
        if (hero.hasSecondClass) ...[
          const _OrnateHeading(
            'Mehrklassen',
            icon: Icons.auto_awesome_outlined,
          ),
          const SizedBox(height: 8),
          _FantasyFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${hero.className} ${hero.primaryClassLevel} / '
                  '${hero.secondaryClassName} ${hero.secondaryClassLevel}',
                  style: const TextStyle(color: _ivory, fontSize: 16),
                ),
                const SizedBox(height: 5),
                Text(
                  'Gesamtstufe ${hero.level} · Übungsbonus '
                  '${proficiency == null ? '–' : _signed(proficiency)}',
                  style: const TextStyle(color: _muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
        ],
        const _OrnateHeading('Attribute', icon: Icons.auto_awesome),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 560 ? 3 : 2;
            // A fixed childAspectRatio shrinks the six ability cards to roughly
            // 112 dp on narrow screens. Icon, label, modifier and score need
            // independent vertical space (especially with large system text).
            // Size the rows from the active text scaler, not the tile width.
            final scaler = MediaQuery.textScalerOf(context);
            final abilityHeight = 80.0 + scaler.scale(90);
            return GridView(
              key: const ValueKey('sheet-abilities-grid'),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisExtent: abilityHeight,
                mainAxisSpacing: 11,
                crossAxisSpacing: 11,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final ability in _abilities)
                  _AbilityCard(
                    label: ability.label,
                    score: hero.abilities[ability.id],
                    icon: ability.icon,
                    color: ability.color,
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        const _OrnateHeading('Rettungswürfe', icon: Icons.shield_outlined),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 500 ? 2 : 1;
            return GridView.count(
              crossAxisCount: columns,
              childAspectRatio: columns == 2 ? 4.4 : 5.6,
              crossAxisSpacing: 10,
              mainAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final ability in _abilities)
                  _SavingThrowTile(
                    label: ability.label,
                    icon: ability.icon,
                    color: ability.color,
                    total: CharacterRuleEngine.savingThrowBonus(
                      hero,
                      ability.id,
                    ),
                    trained: hero.savingThrowProficiencies.contains(ability.id),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        const Text(
          'Angezeigt werden die gespeicherten Attribute und der Übungsbonus. '
          'Erschöpfung ist eingerechnet. Vorteile/Nachteile und nicht bestätigte Zaubereffekte sind hier nicht als Zahlen dargestellt.',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
        const SizedBox(height: 24),
        const _OrnateHeading(
          'Fertigkeiten',
          icon: Icons.workspace_premium_outlined,
        ),
        const SizedBox(height: 8),
        if (hero.skills.isEmpty)
          const _EmptyDetails('Noch keine Fertigkeiten eingetragen.')
        else
          Wrap(
            spacing: 7,
            runSpacing: 3,
            children: [
              for (final skill in hero.skills)
                Chip(
                  avatar: const Icon(Icons.check, size: 15, color: _gold),
                  label: Text(skill),
                ),
            ],
          ),
      ],
    );
  }
}

class _AbilityCard extends StatelessWidget {
  const _AbilityCard({
    required this.label,
    required this.score,
    required this.icon,
    required this.color,
  });
  final String label;
  final int? score;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final modifier = _modifier(score);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: .7)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: .26), _panel, _night],
        ),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Icon(icon, color: color, size: 25),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              style: const TextStyle(
                fontSize: 11,
                color: _ivory,
                fontWeight: FontWeight.w700,
                letterSpacing: .6,
              ),
            ),
          ),
          Text(
            modifier == null ? '–' : _signed(modifier),
            style: const TextStyle(
              fontSize: 31,
              color: _ivory,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
              color: _night,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              score?.toString() ?? '–',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _ivory,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavingThrowTile extends StatelessWidget {
  const _SavingThrowTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.total,
    required this.trained,
  });
  final String label;
  final IconData icon;
  final Color color;
  final int? total;
  final bool trained;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: color.withValues(alpha: .4)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _ivory, fontSize: 13),
            ),
          ),
          if (trained)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Tooltip(
                message: 'Rettungswurf geübt',
                child: Icon(Icons.verified, color: _gold, size: 16),
              ),
            ),
          Text(
            total == null ? '–' : _signed(total!),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: _ivory,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionsSection extends StatelessWidget {
  const _ConditionsSection({required this.hero});
  final HeroCharacter hero;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const _OrnateHeading('Zustände', icon: Icons.healing_outlined),
      const SizedBox(height: 12),
      if (hero.exhaustionLevel > 0)
        _FantasyFrame(
          child: Text(
            'Erschöpfung ${hero.exhaustionLevel}/6 · W20-Tests '
            '−${hero.exhaustionLevel * 2} · Bewegung '
            '${_meters(CharacterRuleEngine.speedMeters(hero), unknown: 'nicht bestätigt')}',
            key: const ValueKey('sheet-exhaustion-effects'),
          ),
        ),

      if (hero.conditions.isEmpty)
        const _EmptyDetails('Keine Zustände eingetragen.')
      else
        for (final condition in hero.conditions)
          _FantasyFrame(
            child: Row(
              children: [
                const Icon(Icons.warning_amber_outlined, color: _gold),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(condition),
                      if (hero.manualConditions.contains(condition))
                        const Text(
                          'Manuell / historisch',
                          style: TextStyle(color: _muted, fontSize: 12),
                        ),
                      for (final effect in hero.conditionEffects.where(
                        (entry) => entry.condition == condition,
                      ))
                        Text(
                          'Quelle: ${effect.source}'
                          '${effect.expiresAtOwnTurnEndRound == null ? ' · Bis zur ausdrücklichen Entfernung' : ' · Ende deines Zugs: Runde ${effect.expiresAtOwnTurnEndRound} (${effect.expiresInEncounterId})'}',
                          key: ValueKey('source-effect-${effect.id}'),
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                      if (ConditionRules.descriptions.containsKey(condition))
                        Text(
                          ConditionRules.descriptions[condition]!,
                          style: const TextStyle(color: _muted, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      const SizedBox(height: 20),
      const _OrnateHeading(
        'Charaktermerkmale',
        icon: Icons.auto_awesome_outlined,
      ),
      const SizedBox(height: 12),
      if (hero.features.isEmpty)
        const _EmptyDetails('Noch keine besonderen Merkmale erfasst.')
      else
        for (final feature in hero.features)
          _FantasyFrame(child: Text(feature)),
    ],
  );
}

class _DefensesSection extends StatelessWidget {
  const _DefensesSection({required this.hero});
  final HeroCharacter hero;
  @override
  Widget build(BuildContext context) {
    String diceText;
    try {
      final available = RestRules.availableHitDice(hero);
      diceText = available.entries
          .map((entry) {
            final maximum = entry.value + (hero.spentHitDice[entry.key] ?? 0);
            return '${entry.key.toUpperCase()}: ${entry.value}/$maximum';
          })
          .join(' · ');
    } on FormatException {
      diceText = 'Nicht erfasst';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _OrnateHeading('Verteidigung', icon: Icons.shield_outlined),
        const SizedBox(height: 12),
        _DetailRow(
          icon: Icons.shield_outlined,
          label: 'Rüstungsklasse',
          value: hero.armorClass?.toString() ?? 'Nicht erfasst',
        ),
        _DetailRow(
          icon: Icons.favorite_outline,
          label: 'Aktuelle Trefferpunkte',
          value: hero.hitPoints?.toString() ?? 'Nicht erfasst',
        ),
        _DetailRow(
          icon: Icons.favorite_border,
          label: 'Maximale Trefferpunkte',
          value: hero.maxHitPoints?.toString() ?? 'Nicht erfasst',
        ),
        _DetailRow(
          icon: Icons.shield_outlined,
          label: 'Temporäre Trefferpunkte',
          value: hero.temporaryHitPoints.toString(),
        ),
        _DetailRow(
          icon: Icons.casino_outlined,
          label: 'Verfügbare Trefferwürfel',
          value: diceText,
        ),
        if (ClassResourceRules.level(hero, 'Paladin') >= 1)
          _DetailRow(
            icon: Icons.healing_outlined,
            label: 'Handauflegen (Heilpunktevorrat)',
            value:
                '${ClassResourceRules.remaining(hero, 'layOnHands')} / ${ClassResourceRules.maximum(hero, 'layOnHands')}',
          ),
        if (ClassResourceRules.level(hero, 'Kämpfer') >= 9)
          _DetailRow(
            icon: Icons.autorenew_outlined,
            label: 'Unbeugsam (Rettungswürfe)',
            value:
                '${ClassResourceRules.remaining(hero, 'indomitable')} / ${ClassResourceRules.maximum(hero, 'indomitable')}',
          ),
        _DetailRow(
          icon: Icons.directions_run,
          label: 'Bewegung (effektiv)',
          value: CharacterRuleEngine.speedMeters(hero) == null
              ? 'Nicht erfasst'
              : '${_meters(CharacterRuleEngine.speedMeters(hero))} (Basis ${hero.speed} m)',
        ),
        _DetailRow(
          icon: Icons.gps_fixed,
          label: 'Angriffe pro Angriffsaktion',
          value: '${ClassProgressionRules.attacksPerAttackAction(hero)}',
        ),
        _DetailRow(
          icon: Icons.check_circle_outline,
          label: 'Erfolgreiche Todesrettungswürfe',
          value: '${hero.deathSuccesses} / 3',
        ),
        _DetailRow(
          icon: Icons.cancel_outlined,
          label: 'Fehlgeschlagene Todesrettungswürfe',
          value: '${hero.deathFailures} / 3',
        ),
        const SizedBox(height: 20),
        const _EmptyDetails(
          'Resistenzen und Immunitäten sind im aktuellen Charaktermodell nicht gesondert erfasst.',
        ),
        const SizedBox(height: 20),
        const _OrnateHeading('Klassenmeilensteine', icon: Icons.timeline),
        const SizedBox(height: 10),
        for (final milestone in ClassProgressionRules.nextMilestones(hero))
          _FantasyFrame(
            child: Text(
              '${milestone.className} ${milestone.classLevel}: ${milestone.label}',
              style: const TextStyle(color: _ivory),
            ),
          ),
        const SizedBox(height: 8),
        const _EmptyDetails(
          'Vorschau, keine automatische Freischaltung von Talenten oder Unterklassen.',
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: _FantasyFrame(
      child: Row(
        children: [
          Icon(icon, color: _gold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(color: _muted)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: _ivory,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptyDetails extends StatelessWidget {
  const _EmptyDetails(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => _FantasyFrame(
    child: Text(message, style: const TextStyle(color: _muted)),
  );
}

class _OrnateHeading extends StatelessWidget {
  const _OrnateHeading(this.title, {required this.icon});
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: _gold, size: 23),
      const SizedBox(width: 9),
      Flexible(
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'serif',
            color: _ivory,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.1,
          ),
        ),
      ),
      const SizedBox(width: 12),
      const Expanded(child: Divider(color: _gold, thickness: .65)),
    ],
  );
}

class _FantasyFrame extends StatelessWidget {
  const _FantasyFrame({
    required this.child,
    this.padding = const EdgeInsets.all(15),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: _panel.withValues(alpha: .9),
      border: Border.all(color: _gold.withValues(alpha: .35)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .18),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: CustomPaint(
      foregroundPainter: const FantasyOrnamentPainter(),
      child: child,
    ),
  );
}
