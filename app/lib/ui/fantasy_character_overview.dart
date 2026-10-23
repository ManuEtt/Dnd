import 'package:flutter/material.dart';

import '../domain/character_rule_engine.dart';
import '../domain/models.dart';
import '../domain/srd_skill_ability_catalog.dart';
import '../domain/rules_engine.dart';
import 'fantasy_ui.dart';
import 'fantasy_character_ornaments.dart';

/// The reference-design's parchment attributes and four compact information
/// panels. All labels and values are derived from the CONFIRMED hero snapshot.
/// This is a view: no slot, skill or inventory edit is performed here.
class FantasyCharacterOverview extends StatelessWidget {
  const FantasyCharacterOverview({super.key, required this.hero});

  final HeroCharacter hero;

  static const ink = Color(0xff30231b);
  static const parchment = Color(0xffddc49c);
  static const ivory = Color(0xfff4ead6);
  static const gold = Color(0xffddb96c);
  static const dim = Color(0xffb4c1ce);

  static const abilities = <({String id, String label, IconData icon, Color color})>[
    (id: 'strength', label: 'Stärke', icon: Icons.fitness_center, color: Color(0xff974f48)),
    (id: 'dexterity', label: 'Geschicklichkeit', icon: Icons.air, color: Color(0xff397f6a)),
    (id: 'constitution', label: 'Konstitution', icon: Icons.favorite, color: Color(0xffaa5849)),
    (id: 'intelligence', label: 'Intelligenz', icon: Icons.menu_book, color: Color(0xff376d98)),
    (id: 'wisdom', label: 'Weisheit', icon: Icons.visibility, color: Color(0xff9d781f)),
    (id: 'charisma', label: 'Charisma', icon: Icons.auto_awesome, color: Color(0xff674980)),
  ];

  static const skills = <({String name, String ability, IconData icon})>[
    (name: 'Religion', ability: 'intelligence', icon: Icons.menu_book_outlined),
    (name: 'Überzeugen', ability: 'charisma', icon: Icons.handshake_outlined),
    (name: 'Medizin', ability: 'wisdom', icon: Icons.healing_outlined),
    (name: 'Einschüchtern', ability: 'charisma', icon: Icons.theater_comedy_outlined),
    (name: 'Wahrnehmung', ability: 'wisdom', icon: Icons.visibility_outlined),
    (name: 'Athletik', ability: 'strength', icon: Icons.sports_martial_arts_outlined),
  ];

  /// Resolve display-only historical skill labels without changing saves.
  /// For example, older sheets may contain "Medizin", while the canonical
  /// SRD class-creation choice is "Heilkunde".
  String _canonicalSkill(String name) {
    for (final alias in srdLegacySkillAliases.entries) {
      if (alias.value == name) return alias.key;
    }
    return name;
  }

  String _recordedSkill(String name) {
    final canonical = _canonicalSkill(name);
    if (hero.skills.contains(canonical)) return canonical;
    final oldName = srdLegacySkillAliases[canonical];
    if (oldName != null && hero.skills.contains(oldName)) return oldName;
    return canonical;
  }

  bool _isSkillProficient(String name) =>
      hero.skills.contains(_recordedSkill(name));

  String _skillBonus(String name, String ability) {
    if (hero.abilities[ability] == null) return '–';
    final recorded = _recordedSkill(name);
    final rule = CharacterRuleEngine.abilityCheck(
      hero,
      ability,
      proficient: hero.skills.contains(recorded),
      skill: recorded,
    );
    return rule.modifier < 0 ? '${rule.modifier}' : '+${rule.modifier}';
  }

  void _all(
    BuildContext context,
    String title,
    List<String> lines, {
    bool searchable = false,
  }) {
    var query = '';
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: FantasyPalette.night,
      builder: (context) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .72,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final normalized = query.trim().toLowerCase();
              final visible = normalized.isEmpty
                  ? lines
                  : lines.where((line) =>
                      line.toLowerCase().contains(normalized)).toList();
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (searchable)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                      child: TextField(
                        key: const ValueKey('sheet-skill-search'),
                        onChanged: (value) =>
                            setModalState(() => query = value),
                        style: const TextStyle(color: ivory),
                        decoration: InputDecoration(
                          labelText: 'Fertigkeit suchen',
                          labelStyle: const TextStyle(color: dim),
                          hintText: 'Name, Bonus oder geübt',
                          hintStyle: const TextStyle(color: dim),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: gold,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: gold.withValues(alpha: .65),
                            ),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: gold, width: 2),
                          ),
                        ),
                      ),
                    ),
                  Flexible(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      shrinkWrap: true,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 23,
                            color: gold,
                          ),
                        ),
                        const Divider(color: gold),
                        if (visible.isEmpty)
                          Text(
                            lines.isEmpty
                                ? 'Keine bestätigten Einträge vorhanden.'
                                : 'Keine passenden Fertigkeiten.',
                            key: const ValueKey('sheet-skill-search-empty'),
                            style: const TextStyle(color: dim),
                          ),
                        for (final line in visible)
                          ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.auto_awesome_outlined,
                              color: gold,
                              size: 19,
                            ),
                            title: Text(
                              line,
                              style: const TextStyle(color: ivory),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    // All 18 canonical SRD skills in the details view, not just the six
    // selected for the compact graphic. Unknown ability scores stay "–".
    final skillLines = [
      for (final skill in srdSkillAbilities)
        '${skill.name}: ${_skillBonus(skill.name, skill.ability)}'
        '${_isSkillProficient(skill.name) ? ' · geübt' : ''}',
      // Preserve genuinely noncatalogued names from imported/old sheets.
      // The known "Medizin" alias is already represented by "Heilkunde".
      for (final other in hero.skills)
        if (!srdSkillAbilities.any((skill) => skill.name == other) &&
            !srdLegacySkillAliases.containsValue(other))
          '$other · historischer Eintrag (keine automatische Berechnung)',
    ];
    final itemLines = [
      for (final item in hero.inventory)
        '${item.name}${item.quantity == 1 ? '' : ' (×${item.quantity})'}',
    ];
    return Column(
      key: const ValueKey('sheet-reference-overview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ParchmentAbilities(hero: hero),
        const SizedBox(height: 13),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 630 && scale <= 1.15;
            final cards = <Widget>[
              _ReferencePanel(
                title: 'Fertigkeiten',
                icon: Icons.stars_outlined,
                onAll: () => _all(context, 'Fertigkeiten', skillLines, searchable: true),
                child: Column(
                  children: [
                    for (final skill in skills)
                      _ReferenceRow(
                        icon: skill.icon,
                        label: skill.name,
                        value: _skillBonus(skill.name, skill.ability),
                        selected: _isSkillProficient(skill.name),
                      ),
                  ],
                ),
              ),
              _ReferencePanel(
                title: 'Zauber',
                icon: Icons.auto_awesome,
                accent: const Color(0xff70b9ed),
                onAll: () => _all(
                  context,
                  'Bekannte Zauber',
                  [
                    ...hero.spells,
                    if (hero.concentratingOn.isNotEmpty)
                      'Konzentration: ${hero.concentratingOn}',
                  ],
                ),
                child: hero.spells.isEmpty
                    ? const _ReferenceEmpty('Keine bekannten Zauber erfasst.')
                    : Column(
                        children: [
                          for (final spell in hero.spells.take(4))
                            _ReferenceRow(
                              icon: Icons.auto_awesome_outlined,
                              label: spell,
                              value: spell == hero.concentratingOn ? 'Konz.' : '',
                              selected: spell == hero.concentratingOn,
                              color: const Color(0xff70b9ed),
                            ),
                          const SizedBox(height: 3),
                          const Text(
                            'Grad und Wirkung werden nicht aus dem Namen abgeleitet.',
                            style: TextStyle(color: dim, fontSize: 10),
                          ),
                        ],
                      ),
              ),
              _ReferencePanel(
                title: 'Zustände',
                icon: Icons.favorite_outline,
                accent: const Color(0xffe0837c),
                onAll: () => _all(
                  context,
                  'Bestätigte Zustände',
                  [
                    ...hero.conditions,
                    if (hero.exhaustionLevel > 0)
                      'Erschöpfung: Stufe ${hero.exhaustionLevel}',
                  ],
                ),
                child: hero.conditions.isEmpty && hero.exhaustionLevel == 0
                    ? const Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: FantasyPalette.success, size: 29),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text('Keine Zustände', style: TextStyle(color: ivory)),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final condition in hero.conditions.take(4))
                            _ReferenceRow(
                              icon: Icons.warning_amber_outlined,
                              label: condition,
                              value: '',
                              color: const Color(0xffe0837c),
                            ),
                          if (hero.exhaustionLevel > 0)
                            Text('Erschöpfung: Stufe ${hero.exhaustionLevel}', style: const TextStyle(color: dim)),
                        ],
                      ),
              ),
              _ReferencePanel(
                title: 'Ausrüstung',
                icon: Icons.backpack_outlined,
                onAll: () => _all(context, 'Inventar', itemLines),
                child: hero.inventory.isEmpty
                    ? const _ReferenceEmpty('Keine Ausrüstung eingetragen.')
                    : Column(
                        children: [
                          for (final item in hero.inventory.take(4))
                            _ReferenceRow(
                              icon: Icons.inventory_2_outlined,
                              label: item.name,
                              value: item.quantity > 1 ? '×${item.quantity}' : '',
                            ),
                        ],
                      ),
              ),
            ];
            if (!wide) {
              return Column(
                children: [
                  for (final card in cards) ...[
                    card,
                    const SizedBox(height: 12),
                  ],
                ],
              );
            }
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[1]),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: cards[2]),
                    const SizedBox(width: 12),
                    Expanded(child: cards[3]),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ParchmentAbilities extends StatelessWidget {
  const _ParchmentAbilities({required this.hero});
  final HeroCharacter hero;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return FantasyApprovedCornerFrame(
      cornerSize: 31,
      child: FantasyEngravedFrame(
      parchment: true,
      child: Container(
        key: const ValueKey('sheet-parchment-abilities'),
        padding: const EdgeInsets.fromLTRB(9, 12, 9, 14),
        decoration: BoxDecoration(
          color: FantasyCharacterOverview.parchment,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: FantasyCharacterOverview.gold, width: 2),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xfff0dab4), Color(0xffc8aa7a)],
          ),
          boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 10)],
        ),
        child: Column(
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 17,
                  color: FantasyCharacterOverview.ink,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Attribute',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: FantasyCharacterOverview.ink,
                    ),
                  ),
                ),
                SizedBox(width: 9),
                Icon(
                  Icons.auto_awesome,
                  size: 17,
                  color: FantasyCharacterOverview.ink,
                ),
              ],
            ),
            const Divider(color: Color(0x994a351d), height: 13),
            LayoutBuilder(
              builder: (context, box) {
                final columns = box.maxWidth >= 705
                    ? 6
                    : box.maxWidth >= 270
                    ? 3
                    : 2;
                final rowsHeight = 93 + scaler.scale(49);
                return GridView(
                  key: const ValueKey('sheet-preview-attributes-grid'),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent: rowsHeight,
                    mainAxisSpacing: 5,
                    crossAxisSpacing: 5,
                  ),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    for (final a in FantasyCharacterOverview.abilities)
                      _ParchmentAbility(
                        label: a.label,
                        icon: a.icon,
                        color: a.color,
                        value: hero.abilities[a.id],
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _ParchmentAbility extends StatelessWidget {
  const _ParchmentAbility({
    required this.label,
    required this.icon,
    required this.color,
    required this.value,
  });

  final String label;
  final IconData icon;
  final Color color;
  final int? value;

  @override
  Widget build(BuildContext context) {
    final mod = value == null ? null : RulesEngine.abilityModifier(value!);
    return Container(
      key: ValueKey('sheet-parchment-ability-$label'),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x44fff4df),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0x775e422b)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: const TextStyle(
                fontFamily: 'serif',
                color: FantasyCharacterOverview.ink,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Container(
            width: 43,
            height: 43,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: FantasyCharacterOverview.gold, width: 1.3),
              boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 5)],
            ),
            child: Icon(icon, color: FantasyCharacterOverview.ivory, size: 25),
          ),
          Text(
            value?.toString() ?? '–',
            style: const TextStyle(
              fontSize: 24,
              color: FantasyCharacterOverview.ink,
              fontWeight: FontWeight.bold,
              height: 1.05,
            ),
          ),
          Text(
            mod == null ? '–' : mod < 0 ? '$mod' : '+$mod',
            style: const TextStyle(
              fontSize: 15,
              color: FantasyCharacterOverview.ink,
              fontWeight: FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferencePanel extends StatelessWidget {
  const _ReferencePanel({
    required this.title,
    required this.icon,
    required this.child,
    required this.onAll,
    this.accent = FantasyCharacterOverview.gold,
  });
  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback onAll;
  final Color accent;

  @override
  Widget build(BuildContext context) => FantasyApprovedCornerFrame(
    cornerSize: 24,
    child: FantasyEngravedFrame(
      child: Container(
      key: ValueKey('sheet-preview-${title.toLowerCase()}'),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xff172a38), Color(0xff0c1825)]),
        border: Border.all(color: accent.withValues(alpha: .65)),
        borderRadius: BorderRadius.circular(11),
      ),
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 23),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: FantasyCharacterOverview.ivory,
                    fontFamily: 'serif',
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton(
                onPressed: onAll,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xffa9d6ef),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                child: const Text('Alle anzeigen', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          Divider(color: accent.withValues(alpha: .3), height: 10),
          child,
        ],
      ),
    ),
    ),
  );
}

class _ReferenceRow extends StatelessWidget {
  const _ReferenceRow({
    required this.icon,
    required this.label,
    required this.value,
    this.selected = false,
    this.color = FantasyCharacterOverview.gold,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          size: 14,
          color: selected ? color : FantasyCharacterOverview.dim,
        ),
        const SizedBox(width: 7),
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: FantasyCharacterOverview.ivory, fontSize: 13),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(
            color: FantasyCharacterOverview.ivory,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    ),
  );
}

class _ReferenceEmpty extends StatelessWidget {
  const _ReferenceEmpty(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 13),
    child: Text(message, style: const TextStyle(color: FantasyCharacterOverview.dim)),
  );
}

/// Permanently pinned action navigation, backed by real actions. Adventure
/// dice rolls remain owned by its controller, never rolled by this widget.
/// Fixed bottom navigation for the character sheet. Buttons only invoke
/// supplied callbacks; they never create game actions or dice results.
class FantasyCharacterQuickNavigation extends StatelessWidget {
  const FantasyCharacterQuickNavigation({
    super.key,
    required this.onCharacter,
    required this.onInventory,
    required this.onRoll,
    required this.onSpells,
    required this.onMore,
  });

  final VoidCallback onCharacter;
  final VoidCallback onInventory;
  final VoidCallback onRoll;
  final VoidCallback onSpells;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: DecoratedBox(
      key: const ValueKey('sheet-fixed-quick-navigation'),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xff172a3a), Color(0xff081421)],
        ),
        border: const Border(
          top: BorderSide(color: FantasyCharacterOverview.gold, width: 1.5),
        ),
        boxShadow: const [
          BoxShadow(color: Color(0xaa000000), blurRadius: 12),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 6, 5, 6),
        child: Row(
          children: [
            _action('Charakter', Icons.person_outline, onCharacter, selected: true),
            _action('Inventar', Icons.backpack_outlined, onInventory),
            Expanded(
              flex: 2,
              child: Semantics(
                label: 'W20 würfeln',
                button: true,
                child: Tooltip(
                  message: 'Würfeln',
                  child: InkWell(
                    key: const ValueKey('sheet-quick-roll'),
                    onTap: onRoll,
                    borderRadius: BorderRadius.circular(38),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 72),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            key: const ValueKey('sheet-d20-medallion'),
                            width: 58,
                            height: 58,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(colors: [
                                Color(0xff329ad8),
                                Color(0xff164580),
                                Color(0xff081a32),
                              ]),
                              border: Border.all(
                                color: FantasyCharacterOverview.gold,
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xaa237fc5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                const CustomPaint(
                                  size: Size(40, 40),
                                  painter: _ReferenceD20Painter(),
                                ),
                                Text(
                                  '20',
                                  style: const TextStyle(
                                    fontFamily: 'serif',
                                    fontWeight: FontWeight.bold,
                                    color: FantasyCharacterOverview.ivory,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Würfeln',
                              maxLines: 1,
                              style: TextStyle(
                                color: FantasyCharacterOverview.ivory,
                                fontSize: 11,
                                fontFamily: 'serif',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _action('Zauber', Icons.auto_awesome_outlined, onSpells),
            _action('Mehr', Icons.more_horiz, onMore),
          ],
        ),
      ),
    ),
  );

  Widget _action(
    String label,
    IconData icon,
    VoidCallback tap, {
    bool selected = false,
  }) => Expanded(
    child: Semantics(
      label: label,
      button: true,
      selected: selected,
      child: Tooltip(
        message: label,
        child: InkWell(
          key: ValueKey('sheet-quick-${label.toLowerCase()}'),
          onTap: tap,
          borderRadius: BorderRadius.circular(10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 66),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 1),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: selected ? const Color(0x333fa8dd) : Colors.transparent,
                  border: selected
                      ? Border.all(color: const Color(0x99ddb96c))
                      : null,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 23,
                      color: selected
                          ? FantasyCharacterOverview.gold
                          : FantasyCharacterOverview.dim,
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: TextStyle(
                          color: selected
                              ? FantasyCharacterOverview.ivory
                              : FantasyCharacterOverview.dim,
                          fontFamily: 'serif',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Vector-only twenty-sided die outline: no opaque screenshot or baked
/// placeholder values enter the actual saved character sheet.
class _ReferenceD20Painter extends CustomPainter {
  const _ReferenceD20Painter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final line = Paint()
      ..color = const Color(0xffb5e8ff)
      ..strokeWidth = 1.45
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final contour = Path()
      ..moveTo(w * .5, h * .06)
      ..lineTo(w * .91, h * .32)
      ..lineTo(w * .78, h * .85)
      ..lineTo(w * .22, h * .85)
      ..lineTo(w * .09, h * .32)
      ..close();
    canvas.drawPath(contour, line);
    final facets = Path()
      ..moveTo(w * .09, h * .32)
      ..lineTo(w * .5, h * .41)
      ..lineTo(w * .91, h * .32)
      ..moveTo(w * .5, h * .06)
      ..lineTo(w * .5, h * .41)
      ..moveTo(w * .22, h * .85)
      ..lineTo(w * .5, h * .41)
      ..lineTo(w * .78, h * .85);
    canvas.drawPath(facets, line);
  }

  @override
  bool shouldRepaint(covariant _ReferenceD20Painter oldDelegate) => false;
}
