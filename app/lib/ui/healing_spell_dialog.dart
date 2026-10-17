import 'package:flutter/material.dart';

import '../domain/condition_rules.dart';
import '../domain/healing_spell_rules.dart';
import '../domain/models.dart';
import '../domain/rules_engine.dart';
import '../domain/spellcasting_rules.dart';
import '../domain/srd_character_classes.dart';
import '../domain/srd_class_feature_catalog.dart';

/// Input for the game engine. The dialog never rolls, heals or spends slots.
class HealingSpellChoice {
  const HealingSpellChoice({
    required this.spellName,
    required this.castingClass,
    required this.slotLevel,
    required this.pactMagic,
    required this.verbalComponentConfirmed,
    required this.somaticComponentConfirmed,
  });

  final String spellName, castingClass;
  final int? slotLevel;
  final bool pactMagic, verbalComponentConfirmed, somaticComponentConfirmed;
}

class HealingSpellDialog extends StatefulWidget {
  const HealingSpellDialog({super.key, required this.hero});

  final HeroCharacter hero;

  @override
  State<HealingSpellDialog> createState() => _HealingSpellDialogState();
}

class _HealingSlotOption {
  const _HealingSlotOption(this.level, this.remaining, {this.pact = false});

  final int level, remaining;
  final bool pact;
  String get key => pact ? 'pact' : 'slot-$level';
  String get label => '${pact ? 'Pakt ' : ''}Grad $level · $remaining frei';
}

class _HealingSpellDialogState extends State<HealingSpellDialog> {
  List<HealingSpellDefinition> _spells = const [];
  List<_HealingSlotOption> _slots = const [];
  HealingSpellDefinition? _spell;
  String? _castingClass, _slotKey, _setupError, _error;
  bool _verbal = false, _somatic = false;

  static const _abilityForClass = {
    'Barde': 'charisma',
    'Kleriker': 'wisdom',
    'Druide': 'wisdom',
    'Paladin': 'charisma',
    'Waldläufer': 'wisdom',
  };

  @override
  void initState() {
    super.initState();
    try {
      _spells = HealingSpellRules.availableSpells(widget.hero);
      if (_spells.isEmpty) return;
      _spell = _spells.first;
      _castingClass = _castingClasses.first;
      // The existing slot table takes canonical class names. Preserve the
      // original sheet, including English and historical class spellings.
      final normalized = widget.hero.copyWith(
        className: findSrdClass(widget.hero.className)!.name,
        secondaryClassName: widget.hero.hasSecondClass
            ? findSrdClass(widget.hero.secondaryClassName)!.name
            : '',
      );
      final ordinary = SpellcastingRules.availableSlots(normalized);
      final pactLeft = SpellcastingRules.availablePactSlots(normalized);
      final pactLevel = SpellcastingRules.pactSlotLevel(normalized);
      _slots = [
        for (final entry in ordinary.entries)
          if (entry.value > 0 && entry.key >= _spell!.level)
            _HealingSlotOption(entry.key, entry.value),
        if (pactLeft > 0 && pactLevel >= _spell!.level)
          _HealingSlotOption(pactLevel, pactLeft, pact: true),
      ];
      if (_slots.isNotEmpty) _slotKey = _slots.first.key;
    } on FormatException catch (error) {
      _setupError = error.message;
    } on StateError catch (error) {
      _setupError = error.message;
    }
  }

  List<String> get _castingClasses => _spell == null
      ? const []
      : HealingSpellRules.castingClasses(widget.hero, _spell!);

  _HealingSlotOption? get _slot {
    for (final option in _slots) {
      if (option.key == _slotKey) return option;
    }
    return null;
  }

  String get _ability => _abilityForClass[_castingClass] ?? 'wisdom';
  String get _abilityLabel => _ability == 'wisdom' ? 'Weisheit' : 'Charisma';
  int? get _abilityModifier {
    final score = widget.hero.abilities[_ability];
    return score == null || score < 1 || score > 30
        ? null
        : RulesEngine.abilityModifier(score);
  }

  Set<String> get _lifeFeatures => SrdClassFeatureCatalog.unlocked(widget.hero)
      .where((feature) => feature.className == 'Kleriker' && feature.isSubclass)
      .map((feature) => feature.name)
      .toSet();

  void _selectSpell(String? name) {
    if (name == null) return;
    setState(() {
      _spell = _spells.firstWhere((spell) => spell.name == name);
      if (!_castingClasses.contains(_castingClass)) {
        _castingClass = _castingClasses.first;
      }
      _verbal = false;
      _somatic = false;
      _error = null;
    });
  }

  String? _confirmationError() {
    if (!_verbal) {
      return 'Bitte bestätigen, dass die verbalen Komponenten möglich sind.';
    }
    if (_spell!.requiresSomatic && !_somatic) {
      return 'Bitte bestätigen, dass die gestischen Komponenten möglich sind.';
    }
    if (_abilityModifier == null) {
      return 'Bitte zuerst $_abilityLabel im Charakterbogen bestätigen.';
    }
    final hero = widget.hero;
    if (hero.hitPoints == null ||
        hero.maxHitPoints == null ||
        hero.hitPoints! <= 0 ||
        hero.maxHitPoints! < 1 ||
        hero.hitPoints! > hero.maxHitPoints! ||
        !ConditionRules.canTakeActions(hero)) {
      return 'Selbstheilung erfordert einen lebenden, handlungsfähigen '
          'Charakter mit bestätigten Trefferpunkten.';
    }
    if ((hero.equippedArmorId.isNotEmpty && !hero.equippedArmorTrained) ||
        (hero.equippedShieldId.isNotEmpty && !hero.equippedShieldTrained)) {
      return 'Ungeübte Rüstung oder Schild verhindern Zauberwirken.';
    }
    if (_spell!.actionType == 'bonusAction' &&
        const ['blind', 'unsichtbar'].any(hero.conditions.contains)) {
      return 'Heilendes Wort benötigt Sicht auf dich selbst; bei Blindheit '
          'oder Unsichtbarkeit ist diese Selbstheilung gesperrt.';
    }
    return null;
  }

  void _confirm() {
    if (_spell == null || _slot == null || _castingClass == null) return;
    final error = _confirmationError();
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(
      context,
      HealingSpellChoice(
        spellName: _spell!.name,
        castingClass: _castingClass!,
        slotLevel: _slot!.pact ? null : _slot!.level,
        pactMagic: _slot!.pact,
        verbalComponentConfirmed: _verbal,
        somaticComponentConfirmed: _spell!.requiresSomatic && _somatic,
      ),
    );
  }

  Widget _component(
    String key,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> update,
  ) => CheckboxListTile(
    key: ValueKey('healing-spell-$key'),
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    title: Text(title),
    subtitle: Text(subtitle),
    value: value,
    onChanged: (checked) => setState(() {
      update(checked ?? false);
      _error = null;
    }),
  );

  List<Widget> _preview() {
    final spell = _spell!;
    final slot = _slot;
    final modifier = _abilityModifier;
    final abilityText = modifier == null
        ? '$_abilityLabel noch nicht bestätigt'
        : '$_abilityLabel (${modifier >= 0 ? '+' : ''}$modifier)';
    final count = 2 * (slot?.level ?? spell.level);
    final life = _lifeFeatures;
    final disciple = slot != null && life.contains('Disciple of Life')
        ? 2 + slot.level
        : 0;
    return [
      Text(
        'Kosten im Kampf: ${spell.actionType == 'bonusAction' ? 'Bonusaktion' : 'Aktion (Magie)'}.',
        key: const ValueKey('healing-spell-action'),
      ),
      if (slot != null)
        Text(
          'Verbrauch: 1 ${slot.pact ? 'Paktmagieplatz' : 'Zauberplatz'} '
          'Grad ${slot.level}.',
        ),
      Text(
        'Heilung: ${count}W${spell.dieSides} + $abilityText.',
        key: const ValueKey('healing-spell-preview'),
      ),
      if (disciple > 0) Text('Jünger des Lebens: zusätzlich $disciple TP.'),
      if (life.contains('Supreme Healing') && modifier != null && slot != null)
        Text(
          'Höchste Heilung: ${count * spell.dieSides + modifier + disciple} TP '
          'durch Höchstwerte statt Würfelwurf.',
        ),
      const SizedBox(height: 8),
      Text(
        spell.requiresSomatic
            ? 'Ziel: nur du selbst, durch Berührung. Sicht ist nicht erforderlich.'
            : 'Ziel: nur du selbst. Du musst dich selbst sehen können; '
                  'bei Blindheit oder Unsichtbarkeit ist diese Selbstheilung gesperrt.',
      ),
      const Text(
        'Die Heilung erhöht deine Trefferpunkte höchstens bis zum '
        'Maximum. Im Kampf ist pro Zug nur ein Zauber mit Zauberplatz möglich.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          key: const ValueKey('healing-spell-scroll'),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Heilzauber auf dich selbst wirken',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.hero.name}: ${widget.hero.hitPoints ?? '–'} / '
                '${widget.hero.maxHitPoints ?? '–'} TP',
              ),
              const SizedBox(height: 12),
              if (_setupError != null)
                Text(
                  'Bitte zuerst die Charakterdaten prüfen: $_setupError',
                  style: TextStyle(color: errorColor),
                )
              else if (_spells.isEmpty)
                const Text(
                  'Kein unterstützter vorbereiteter Heilzauber '
                  'vorhanden. Trage Wunden heilen oder Heilendes Wort im '
                  'Charakterbogen ein, wenn deine eigene Zauberklasse '
                  'diesen Zauber vorbereitet hat.',
                )
              else ...[
                const Text(
                  'Wähle einen bestätigten vorbereiteten Heilzauber '
                  'und die Klasse, mit der du ihn wirkst.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const ValueKey('healing-spell-name'),
                  initialValue: _spell!.name,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Heilzauber'),
                  items: [
                    for (final spell in _spells)
                      DropdownMenuItem(
                        value: spell.name,
                        child: Text(
                          spell.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _selectSpell,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const ValueKey('healing-spell-class'),
                  initialValue: _castingClass,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Zauberklasse'),
                  items: [
                    for (final name in _castingClasses)
                      DropdownMenuItem(
                        value: name,
                        child: Text(name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (name) => setState(() {
                    _castingClass = name;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 16),
                if (_slots.isEmpty)
                  const Text(
                    'Kein ausreichender freier Zauberplatz vorhanden. '
                    'Verbrauch und Rast im Charakterbogen prüfen.',
                  )
                else
                  DropdownButtonFormField<String>(
                    key: const ValueKey('healing-spell-slot'),
                    initialValue: _slotKey,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Verwendeter Platz',
                    ),
                    items: [
                      for (final option in _slots)
                        DropdownMenuItem(
                          value: option.key,
                          child: Text(
                            option.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (key) => setState(() {
                      _slotKey = key;
                      _error = null;
                    }),
                  ),
                const SizedBox(height: 16),
                ..._preview(),
                const SizedBox(height: 12),
                _component(
                  'verbal',
                  'Verbale Komponenten möglich',
                  'Ich kann die Worte mit normaler Sprechstimme äußern; '
                      'ich bin weder geknebelt noch in magischem Schweigen.',
                  _verbal,
                  (value) => _verbal = value,
                ),
                if (_spell!.requiresSomatic)
                  _component(
                    'somatic',
                    'Gestische Komponenten möglich',
                    'Ich kann die erforderlichen Gesten mit mindestens '
                        'einer Hand ausführen.',
                    _somatic,
                    (value) => _somatic = value,
                  ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_error!, style: TextStyle(color: errorColor)),
                ),
              const SizedBox(height: 20),
              FilledButton(
                key: const ValueKey('healing-spell-confirm'),
                onPressed:
                    _setupError != null || _spell == null || _slot == null
                    ? null
                    : _confirm,
                child: const Text(
                  'Wirken bestätigen',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const ValueKey('healing-spell-cancel'),
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
