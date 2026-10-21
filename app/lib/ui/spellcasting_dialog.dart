import 'package:flutter/material.dart';

import 'fantasy_buttons.dart';

import '../domain/models.dart';
import '../domain/spellcasting_rules.dart';

/// Only accounts for explicitly confirmed spell resource expenditure.
/// It does not resolve a spell's targets, damage or any other magical effects.
class SpellcastingChoice {
  const SpellcastingChoice({
    required this.name,
    required this.level,
    required this.pact,
    required this.concentration,
  });
  final String name;
  final int level;
  final bool pact;
  final bool concentration;
}

class SpellcastingDialog extends StatefulWidget {
  const SpellcastingDialog({super.key, required this.hero});
  final HeroCharacter hero;

  @override
  State<SpellcastingDialog> createState() => _SpellcastingDialogState();
}

class _SpellcastingDialogState extends State<SpellcastingDialog> {
  String? _spell;
  int _level = 0;
  bool _pact = false;
  bool _concentration = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.hero.spells.isNotEmpty) _spell = widget.hero.spells.first;
  }

  @override
  Widget build(BuildContext context) {
    final hero = widget.hero;
    final slots = SpellcastingRules.availableSlots(hero);
    final pactLeft = SpellcastingRules.availablePactSlots(hero);
    final slotText = slots.isEmpty
        ? 'Keine regulären Zauberplätze'
        : slots.entries.map((e) => '${e.key}: ${e.value} frei').join(' · ');
    return AlertDialog(
      title: const Text('Zauberressourcen verwalten'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(slotText),
              if (SpellcastingRules.pactSlotCount(hero) > 0)
                Text(
                  'Paktmagie Grad ${SpellcastingRules.pactSlotLevel(hero)}: '
                  '$pactLeft/${SpellcastingRules.pactSlotCount(hero)} frei',
                ),
              if (hero.concentratingOn.isNotEmpty)
                Text('Konzentration: ${hero.concentratingOn}'),
              const SizedBox(height: 16),
              if (hero.spells.isEmpty)
                const Text(
                  'Zuerst im Charakterbogen bekannte Zauber eintragen.',
                ),
              if (hero.spells.isNotEmpty)
                DropdownButtonFormField<String>(
                  key: const ValueKey('spell-dialog-name'),
                  initialValue: _spell,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Bestätigter Zauber',
                  ),
                  items: hero.spells
                      .toSet()
                      .map(
                        (name) => DropdownMenuItem(
                          value: name,
                          child: Text(name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() {
                    _spell = v;
                    _error = null;
                  }),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: const ValueKey('spell-dialog-level'),
                isExpanded: true,
                initialValue: _level,
                decoration: const InputDecoration(
                  labelText: 'Zaubergrad / verwendeter Platz',
                ),
                items: [
                  for (var i = 0; i <= 9; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(
                        i == 0 ? 'Zaubertrick (kein Platz)' : 'Grad $i',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setState(() {
                  _level = v ?? 0;
                  if (_level == 0) _pact = false;
                  _error = null;
                }),
              ),
              if (_level > 0 && SpellcastingRules.pactSlotCount(hero) > 0)
                SwitchListTile.adaptive(
                  key: const ValueKey('spell-dialog-pact'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Paktmagieplatz statt regulärem Platz'),
                  value: _pact,
                  onChanged: (v) => setState(() => _pact = v),
                ),
              SwitchListTile.adaptive(
                key: const ValueKey('spell-dialog-concentration'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Der Zauber erfordert Konzentration'),
                subtitle: const Text(
                  'Nur nach Prüfung der Zauberbeschreibung bestätigen.',
                ),
                value: _concentration,
                onChanged: (v) => setState(() => _concentration = v),
              ),
              const Text(
                'Der gewählte Grad und die Konzentration müssen zur '
                'offiziellen Zauberbeschreibung passen. Zaubereffekte werden '
                'hier nicht automatisch angewendet.',
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        if (hero.concentratingOn.isNotEmpty)
          FantasyTextButton(
            key: const ValueKey('spell-dialog-end-concentration'),
            label: 'Konzentration beenden',
            style: FantasyButtonStyle.iron,
            onPressed: () => Navigator.pop(
              context,
              const SpellcastingChoice(
                name: '',
                level: -1,
                pact: false,
                concentration: false,
              ),
            ),
          ),
        FantasyTextButton(
          label: 'Abbrechen',
          style: FantasyButtonStyle.iron,
          onPressed: () => Navigator.pop(context),
        ),
        FantasyTextButton(
          key: const ValueKey('spell-dialog-cast'),
          label: 'Verbrauch bestätigen',
          style: FantasyButtonStyle.arcane,
          onPressed: hero.spells.isEmpty
              ? null
              : () {
                  try {
                    final choice = SpellcastingChoice(
                      name: _spell!,
                      level: _level,
                      pact: _pact,
                      concentration: _concentration,
                    );
                    SpellcastingRules.cast(
                      hero,
                      spellName: choice.name,
                      spellLevel: choice.level,
                      pactMagic: choice.pact,
                      concentration: choice.concentration,
                    );
                    Navigator.pop(context, choice);
                  } catch (e) {
                    setState(() => _error = '$e');
                  }
                },
        ),
      ],
    );
  }
}
