import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'fantasy_art.dart';

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
        : hero.name.trim().split(RegExp(r'\s+')).take(2).map((p) => p[0].toUpperCase()).join();
    return _FantasyFrame(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.asset(FantasyArtwork.castle,
              height: 80, width: double.infinity, fit: BoxFit.cover,
              semanticLabel: 'Illustration einer Fantasy-Burg'),
          ),
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
            '${hero.species}  •  ${hero.className}  •  Stufe ${hero.level}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 12, letterSpacing: .75),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
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
                      style: TextStyle(color: _muted, fontSize: 11, letterSpacing: 1.6),
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
                      hero.background.isEmpty ? 'Ein Abenteuer wartet auf dich' : hero.background,
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
    final proficiency = level >= 1 && level <= 20 ? 2 + (level - 1) ~/ 4 : null;
    final dex = _modifier(hero.abilities['dexterity']);
    final values = <({String label, String value, IconData icon})>[
      (label: 'ÜBUNGSBONUS', value: proficiency == null ? '–' : _signed(proficiency), icon: Icons.stars_outlined),
      (label: 'BEWEGUNG', value: hero.speed == null ? '–' : '${hero.speed} m', icon: Icons.directions_run_outlined),
      (label: 'INITIATIVE', value: dex == null ? '–' : _signed(dex), icon: Icons.casino_outlined),
      (label: 'RÜSTUNGSKLASSE', value: hero.armorClass?.toString() ?? '–', icon: Icons.shield_outlined),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth < 580 ? 2 : 4;
      // A width-derived aspect ratio makes these tiles too short on phones:
      // the icon, score and label overflow by a few pixels at 320/360 dp.
      // Reserve two label lines and scale the row height with system text size
      // instead of clipping text or ignoring Flutter's overflow reports.
      final scaler = MediaQuery.textScalerOf(context);
      final tileHeight = (20 + 22 + 5 + scaler.scale(23) * 1.35 + 2 +
              scaler.scale(10) * 1.45 * 2 + 12)
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
                      style: const TextStyle(color: _ivory, fontSize: 23, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: _muted, fontSize: 10, letterSpacing: .6),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}

class _SectionNavigation extends StatelessWidget {
  const _SectionNavigation({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) {
    const labels = ['Attribute', 'Zustände', 'Verteidigung'];
    const icons = [Icons.auto_awesome_outlined, Icons.healing_outlined, Icons.security_outlined];
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
                  side: BorderSide(color: selected == i ? _gold : const Color(0xff334658)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icons[i], size: 18),
                    const SizedBox(height: 3),
                    Text(labels[i], maxLines: 1, style: const TextStyle(fontSize: 11)),
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
  (id: 'strength', label: 'Stärke', icon: Icons.fitness_center, color: Color(0xffc96b64)),
  (id: 'dexterity', label: 'Geschicklichkeit', icon: Icons.air, color: Color(0xff78b593)),
  (id: 'constitution', label: 'Konstitution', icon: Icons.favorite_outline, color: Color(0xffd6ae67)),
  (id: 'intelligence', label: 'Intelligenz', icon: Icons.menu_book_outlined, color: Color(0xff79b9eb)),
  (id: 'wisdom', label: 'Weisheit', icon: Icons.visibility_outlined, color: Color(0xffac96d9)),
  (id: 'charisma', label: 'Charisma', icon: Icons.wb_sunny_outlined, color: Color(0xffe6bf6f)),
];

int? _modifier(int? score) => score == null ? null : ((score - 10) / 2).floor();
String _signed(int value) => value >= 0 ? '+$value' : '$value';

class _AbilitiesSection extends StatelessWidget {
  const _AbilitiesSection({required this.hero});
  final HeroCharacter hero;

  @override
  Widget build(BuildContext context) {
    final proficiency = hero.level >= 1 && hero.level <= 20
        ? 2 + (hero.level - 1) ~/ 4
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _OrnateHeading('Attribute', icon: Icons.auto_awesome),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
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
        }),
        const SizedBox(height: 24),
        const _OrnateHeading('Rettungswürfe', icon: Icons.shield_outlined),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, constraints) {
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
                  score: hero.abilities[ability.id],
                  trained: hero.savingThrowProficiencies.contains(ability.id),
                  proficiency: proficiency,
                ),
            ],
          );
        }),
        const SizedBox(height: 12),
        const Text(
          'Angezeigt werden die gespeicherten Attribute und der Übungsbonus. '
          'Zusätzliche Effekte aus Zaubern oder Gegenständen sind nicht eingerechnet.',
          style: TextStyle(color: _muted, fontSize: 12),
        ),
        const SizedBox(height: 24),
        const _OrnateHeading('Fertigkeiten', icon: Icons.workspace_premium_outlined),
        const SizedBox(height: 8),
        if (hero.skills.isEmpty)
          const _EmptyDetails('Noch keine Fertigkeiten eingetragen.')
        else
          Wrap(spacing: 7, runSpacing: 3, children: [
            for (final skill in hero.skills)
              Chip(avatar: const Icon(Icons.check, size: 15, color: _gold), label: Text(skill)),
          ]),
      ],
    );
  }
}

class _AbilityCard extends StatelessWidget {
  const _AbilityCard({required this.label, required this.score, required this.icon, required this.color});
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
            child: Text(label.toUpperCase(),
                maxLines: 1,
                style: const TextStyle(fontSize: 11, color: _ivory, fontWeight: FontWeight.w700, letterSpacing: .6)),
          ),
          Text(modifier == null ? '–' : _signed(modifier),
              style: const TextStyle(fontSize: 31, color: _ivory, fontWeight: FontWeight.bold)),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
              color: _night,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(score?.toString() ?? '–',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _ivory)),
          ),
        ],
      ),
    );
  }
}

class _SavingThrowTile extends StatelessWidget {
  const _SavingThrowTile({
    required this.label, required this.icon, required this.color,
    required this.score, required this.trained, required this.proficiency,
  });
  final String label;
  final IconData icon;
  final Color color;
  final int? score;
  final bool trained;
  final int? proficiency;

  @override
  Widget build(BuildContext context) {
    final base = _modifier(score);
    final total = base == null || (trained && proficiency == null)
        ? null : base + (trained ? proficiency! : 0);
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
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: _ivory, fontSize: 13)),
          ),
          if (trained)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Tooltip(message: 'Rettungswurf geübt', child: Icon(Icons.verified, color: _gold, size: 16)),
            ),
          Text(total == null ? '–' : _signed(total),
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: _ivory)),
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
          if (hero.conditions.isEmpty)
            const _EmptyDetails('Keine Zustände eingetragen.')
          else
            for (final condition in hero.conditions)
              _FantasyFrame(child: Row(children: [
                const Icon(Icons.warning_amber_outlined, color: _gold),
                const SizedBox(width: 10),
                Expanded(child: Text(condition)),
              ])),
          const SizedBox(height: 20),
          const _OrnateHeading('Charaktermerkmale', icon: Icons.auto_awesome_outlined),
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
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _OrnateHeading('Verteidigung', icon: Icons.shield_outlined),
          const SizedBox(height: 12),
          _DetailRow(icon: Icons.shield_outlined, label: 'Rüstungsklasse', value: hero.armorClass?.toString() ?? 'Nicht erfasst'),
          _DetailRow(icon: Icons.favorite_outline, label: 'Aktuelle Trefferpunkte', value: hero.hitPoints?.toString() ?? 'Nicht erfasst'),
          _DetailRow(icon: Icons.favorite_border, label: 'Maximale Trefferpunkte', value: hero.maxHitPoints?.toString() ?? 'Nicht erfasst'),
          _DetailRow(icon: Icons.directions_run, label: 'Bewegung', value: hero.speed == null ? 'Nicht erfasst' : '${hero.speed} m'),
          _DetailRow(icon: Icons.check_circle_outline, label: 'Erfolgreiche Todesrettungswürfe', value: '${hero.deathSuccesses} / 3'),
          _DetailRow(icon: Icons.cancel_outlined, label: 'Fehlgeschlagene Todesrettungswürfe', value: '${hero.deathFailures} / 3'),
          const SizedBox(height: 20),
          const _EmptyDetails('Resistenzen und Immunitäten sind im aktuellen Charaktermodell nicht gesondert erfasst.'),
        ],
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: _FantasyFrame(
          child: Row(children: [
            Icon(icon, color: _gold),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(color: _muted))),
            Flexible(child: Text(value, textAlign: TextAlign.end,
                style: const TextStyle(color: _ivory, fontWeight: FontWeight.bold))),
          ]),
        ),
      );
}

class _EmptyDetails extends StatelessWidget {
  const _EmptyDetails(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => _FantasyFrame(child: Text(message,
      style: const TextStyle(color: _muted)));
}

class _OrnateHeading extends StatelessWidget {
  const _OrnateHeading(this.title, {required this.icon});
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: _gold, size: 23),
        const SizedBox(width: 9),
        Flexible(child: Text(title.toUpperCase(),
            style: const TextStyle(fontFamily: 'serif', color: _ivory,
                fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1.1))),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: _gold, thickness: .65)),
      ]);
}

class _FantasyFrame extends StatelessWidget {
  const _FantasyFrame({required this.child, this.padding = const EdgeInsets.all(15)});
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: _panel.withValues(alpha: .9),
          border: Border.all(color: _gold.withValues(alpha: .35)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .18), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: CustomPaint(
          foregroundPainter: const FantasyOrnamentPainter(),
          child: child,
        ),
      );
}
