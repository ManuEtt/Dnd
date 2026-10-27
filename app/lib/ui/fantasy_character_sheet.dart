import 'package:flutter/material.dart';

import '../domain/character_rule_engine.dart';
import '../domain/class_progression_rules.dart';
import '../domain/class_feature_resources.dart';
import '../domain/class_resource_rules.dart';
import '../domain/srd_class_feature_catalog.dart';
import '../domain/models.dart';
import '../domain/multiclass_rules.dart';
import '../domain/rest_rules.dart';
import '../domain/spellcasting_rules.dart';
import '../domain/rules_engine.dart';
import 'fantasy_art.dart';
import 'fantasy_experience.dart';
import 'fantasy_ui.dart';
import 'fantasy_effect_ward.dart';
import 'fantasy_buttons.dart';
import 'fantasy_character_overview.dart';
import 'fantasy_character_ornaments.dart';
import 'character_portrait_picker.dart';

// A read-only presentation of the actual, confirmed character data. No state,
// rule changes, generated portrait, or assumed missing character values.
const _night = Color(0xff09121f);
const _panel = Color(0xff142536);
const _gold = Color(0xffddb96c);
const _ivory = Color(0xfff4ead6);
const _muted = Color(0xffadc0cf);

class CharacterSheetPage extends StatefulWidget {
  const CharacterSheetPage({
    super.key,
    required this.hero,
    this.onEdit,
    this.onRoll,
  });

  final HeroCharacter hero;
  final VoidCallback? onEdit;
  final VoidCallback? onRoll;

  @override
  State<CharacterSheetPage> createState() => _CharacterSheetPageState();
}

class _CharacterSheetPageState extends State<CharacterSheetPage> {
  int _section = 0;
  final ScrollController _sheetScroll = ScrollController();

  @override
  void dispose() {
    _sheetScroll.dispose();
    super.dispose();
  }

  void _showCollection(String title, List<String> values) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _night,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .7,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 22),
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _gold,
                  fontFamily: 'serif',
                  fontSize: 24,
                ),
              ),
              const Divider(color: _gold),
              if (values.isEmpty)
                const Text(
                  'Keine bestätigten Einträge.',
                  style: TextStyle(color: _muted),
                ),
              for (final value in values)
                ListTile(
                  dense: true,
                  leading: const Icon(
                    Icons.auto_awesome,
                    color: _gold,
                    size: 19,
                  ),
                  title: Text(value, style: const TextStyle(color: _ivory)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _rollFromSheet() {
    if (widget.onRoll != null) {
      widget.onRoll!();
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Würfeln'),
        content: const Text(
          'Würfelwürfe werden im aktiven Abenteuer über den '
          'bestätigten Würfeldialog ausgeführt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Verstanden'),
          ),
        ],
      ),
    );
  }

  void _moreDetails() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _night,
      builder: (context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in [
              (0, 'Regeln und Rettungswürfe'),
              (1, 'Zustände und Merkmale'),
              (2, 'Verteidigung und Trefferwürfel'),
            ])
              ListTile(
                leading: const Icon(Icons.auto_awesome, color: _gold),
                title: Text(entry.$2, style: const TextStyle(color: _ivory)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _section = entry.$1);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _sheetScroll.hasClients) {
                      _sheetScroll.animateTo(
                        _sheetScroll.position.maxScrollExtent,
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOut,
                      );
                    }
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hero = widget.hero;
    return Scaffold(
      backgroundColor: _night,
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FantasyRuneEmblem(rune: FantasyRune.hero, size: 30),
            SizedBox(width: 9),
            Flexible(
              child: Text(
                'Charakterbogen',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: _night,
        actions: [
          if (widget.onEdit != null)
            FantasyIconButton(
              tooltip: 'Charakter bearbeiten',
              icon: Icons.edit_outlined,
              onPressed: widget.onEdit,
            ),
        ],
      ),
      body: FantasyBackdrop(
        scene: FantasyBackdropScene.heroes,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: ListView(
              key: const ValueKey('fantasy-character-sheet-scroll'),
              controller: _sheetScroll,
              padding: const EdgeInsets.fromLTRB(12, 13, 12, 30),
              children: [
                _CharacterHeader(hero: hero),
                const SizedBox(height: 14),
                _SummaryGrid(hero: hero),
                const SizedBox(height: 12),
                _PassivePerceptionStrip(hero: hero),
                const SizedBox(height: 16),
                FantasyCharacterOverview(hero: hero),
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
      bottomNavigationBar: FantasyCharacterQuickNavigation(
        onCharacter: () {
          if (_sheetScroll.hasClients) {
            _sheetScroll.animateTo(
              0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
            );
          }
        },
        onInventory: () => _showCollection('Ausrüstung und Inventar', [
          for (final item in widget.hero.inventory)
            '${item.name}${item.quantity > 1 ? ' ×${item.quantity}' : ''}',
        ]),
        onRoll: _rollFromSheet,
        onSpells: () => _showCollection('Bekannte Zauber', [
          ...widget.hero.spells,
          if (widget.hero.concentratingOn.isNotEmpty)
            'Konzentration: ${widget.hero.concentratingOn}',
        ]),
        onMore: _moreDetails,
      ),
    );
  }
}

class _CharacterHeader extends StatelessWidget {
  const _CharacterHeader({required this.hero});
  final HeroCharacter hero;

  @override
  Widget build(BuildContext context) {
    final initials = hero.name.trim().isEmpty
        ? '?'
        : hero.name
              .trim()
              .split(RegExp(r'\\s+'))
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join();
    return FantasyApprovedCornerFrame(
      cornerSize: 30,
      child: Container(
        key: const ValueKey('sheet-reference-header'),
        constraints: const BoxConstraints(minHeight: 154),
        decoration: BoxDecoration(
          border: Border.all(color: _gold.withValues(alpha: .72)),
          borderRadius: BorderRadius.circular(14),
          color: _night,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: ExcludeSemantics(
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0x99ffffff), Color(0x33ffffff)],
                  ).createShader(bounds),
                  child: Image.asset(
                    FantasyArtwork.castle,
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                children: [
                  FantasyPortraitMedallion(
                    size: 112,
                    child:
                        hero.portraitPreset >= 0 ||
                            hero.portraitPhotoBase64.isNotEmpty
                        ? FantasyCharacterPortrait(
                            key: const ValueKey('sheet-hero-portrait'),
                            preset: hero.portraitPreset,
                            photoBase64: hero.portraitPhotoBase64,
                            name: hero.name,
                            size: 105,
                          )
                        : Container(
                            key: const ValueKey('sheet-avatar-placeholder'),
                            color: const Color(0xff243749),
                            alignment: Alignment.center,
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'WÜRFELRAUNEN',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 12,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.bold,
                            color: _gold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          hero.name.isEmpty ? 'Unbenannter Held' : hero.name,
                          key: const ValueKey('sheet-hero-name'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 24,
                            color: _ivory,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${hero.species}  •  ${hero.classSummary}  •  Stufe ${hero.level}',
                          style: const TextStyle(color: _ivory, fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (hero.subclass.isNotEmpty ||
                            hero.secondarySubclass.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            [
                              if (hero.subclass.isNotEmpty) hero.subclass,
                              if (hero.secondarySubclass.isNotEmpty)
                                hero.secondarySubclass,
                            ].join(' · '),
                            maxLines: 2,
                            style: const TextStyle(color: _gold, fontSize: 11),
                          ),
                        ],
                        const SizedBox(height: 7),
                        Text(
                          hero.background.isEmpty
                              ? 'Dein Weg durch die Chroniken'
                              : hero.background,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.hero});
  final HeroCharacter hero;

  @override
  Widget build(BuildContext context) {
    final dex = _modifier(hero.abilities['dexterity']);
    final initiative = dex == null
        ? '–'
        : _signed(RulesEngine.initiativeBonus(hero));
    final maximum = hero.maxHitPoints;
    final current = hero.hitPoints;
    final hpFraction = current != null && maximum != null && maximum > 0
        ? (current / maximum).clamp(0.0, 1.0).toDouble()
        : null;
    final values =
        <({String label, String value, IconData icon, Color accent})>[
          (
            label: 'TREFFERPUNKTE',
            value: '${current ?? '–'} / ${maximum ?? '–'}',
            icon: Icons.favorite,
            accent: const Color(0xffdb7064),
          ),
          (
            label: 'RÜSTUNGSKLASSE',
            value: hero.armorClass?.toString() ?? '–',
            icon: Icons.shield_outlined,
            accent: const Color(0xffa7c8dc),
          ),
          (
            label: 'INITIATIVE',
            value: initiative,
            icon: Icons.sports_martial_arts,
            accent: _gold,
          ),
          (
            label: 'BEWEGUNG',
            value: _meters(CharacterRuleEngine.speedMeters(hero)),
            icon: Icons.directions_run_outlined,
            accent: _gold,
          ),
        ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 580 ? 2 : 4;
        final scaler = MediaQuery.textScalerOf(context);
        final tileHeight = (76 + scaler.scale(50))
            .clamp(124.0, 230.0)
            .toDouble();
        return GridView(
          key: const ValueKey('sheet-summary-grid'),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: tileHeight,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var i = 0; i < values.length; i++)
              FantasyApprovedCornerFrame(
                cornerSize: 20,
                child: Container(
                  key: ValueKey(
                    'sheet-summary-${i == 0
                        ? 'hp'
                        : i == 1
                        ? 'ac'
                        : i == 2
                        ? 'initiative'
                        : 'speed'}',
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: i == 0 ? const Color(0xff351c25) : _panel,
                    border: Border.all(color: _gold.withValues(alpha: .55)),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(values[i].icon, size: 23, color: values[i].accent),
                      const SizedBox(height: 3),
                      Text(
                        values[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _ivory,
                          fontSize: 10,
                          fontFamily: 'serif',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          values[i].value,
                          key: i == 0
                              ? const ValueKey('sheet-hit-points')
                              : null,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            color: _ivory,
                          ),
                        ),
                      ),
                      if (i == 0 && hpFraction != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: hpFraction,
                              minHeight: 6,
                              backgroundColor: const Color(0xff1c1015),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xffde5a59),
                              ),
                            ),
                          ),
                        ),
                      if (i == 0 && hpFraction == null)
                        const Text(
                          'Noch nicht erfasst',
                          style: TextStyle(color: _muted, fontSize: 10),
                        ),
                      if (i == 0 && hero.temporaryHitPoints > 0)
                        Text(
                          '+${hero.temporaryHitPoints} temporäre TP',
                          key: const ValueKey('sheet-temporary-hit-points'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _gold, fontSize: 10),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PassivePerceptionStrip extends StatelessWidget {
  const _PassivePerceptionStrip({required this.hero});
  final HeroCharacter hero;

  @override
  Widget build(BuildContext context) {
    final score = CharacterRuleEngine.passivePerception(hero);
    final proficiency = _signed(RulesEngine.proficiencyBonus(hero.level));
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.15;
    final description = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'PASSIVE WAHRNEHMUNG',
          style: TextStyle(
            color: _ivory,
            fontWeight: FontWeight.w700,
            letterSpacing: .5,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          score == null
              ? 'Nicht verfügbar oder Weisheit unbestätigt'
              : 'Ohne Würfeln · situationsabhängig',
          style: const TextStyle(color: _muted, fontSize: 10),
        ),
      ],
    );
    final numbers = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ÜBUNGSBONUS',
              style: TextStyle(color: _muted, fontSize: 9, letterSpacing: .25),
            ),
            Text(
              proficiency,
              style: const TextStyle(color: _gold, fontSize: 17),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Text(
          score?.toString() ?? '–',
          key: const ValueKey('sheet-passive-perception-score'),
          style: const TextStyle(
            color: _gold,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
    return _FantasyFrame(
      child: largeText
          ? Column(
              key: const ValueKey('sheet-passive-perception'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.visibility_outlined,
                      color: _gold,
                      size: 24,
                    ),
                    const SizedBox(width: 9),
                    Expanded(child: description),
                  ],
                ),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: numbers),
              ],
            )
          : Row(
              key: const ValueKey('sheet-passive-perception'),
              children: [
                const Icon(Icons.visibility_outlined, color: _gold, size: 24),
                const SizedBox(width: 9),
                Expanded(child: description),
                const SizedBox(width: 7),
                numbers,
              ],
            ),
    );
  }
}

class _SectionNavigation extends StatelessWidget {
  const _SectionNavigation({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) {
    const labels = ['Regeln', 'Zustände', 'Verteidigung'];
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
              child: FantasyToggleButton(
                key: ValueKey('sheet-tab-$i'),
                label: labels[i],
                icon: icons[i],
                compact: true,
                selected: selected == i,
                onPressed: () => onSelected(i),
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
                    key: ValueKey('sheet-saving-throw-${ability.id}'),
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
          'Die Rettungswurfboni basieren auf bestätigten Attributen und dem Übungsbonus. '
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

class _SavingThrowTile extends StatelessWidget {
  const _SavingThrowTile({
    super.key,
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
      FantasyEffectWard(hero: hero, expandDetailsInitially: true),
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
        if (ClassResourceRules.level(hero, 'Waldläufer') >= 6)
          _DetailRow(
            icon: Icons.pool_outlined,
            label: 'Roving: Klettern / Schwimmen',
            value:
                '${_meters(CharacterRuleEngine.rovingClimbSpeedMeters(hero))} / '
                '${_meters(CharacterRuleEngine.rovingSwimSpeedMeters(hero))}',
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
  const _FantasyFrame({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(15),
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
