import 'package:flutter/material.dart';
import 'fantasy_buttons.dart';

import '../domain/hero_shield_reaction_rules.dart';
import '../domain/magic_missile_rules.dart';
import '../domain/models.dart';

/// Explicit consent before the enemy turn; no Shield slot is consumed unless
/// a subsequent enemy attack hits AND +5 AC prevents that hit.
class HeroShieldReactionDialog extends StatefulWidget {
  const HeroShieldReactionDialog({super.key, required this.hero});
  final HeroCharacter hero;

  @override
  State<HeroShieldReactionDialog> createState() =>
      _HeroShieldReactionDialogState();
}

class _HeroShieldReactionDialogState extends State<HeroShieldReactionDialog> {
  List<String> _classes = const [];
  List<MagicMissileSlot> _slots = const [];
  String? _castingClass;
  String? _slotKey;
  String? _error;
  bool _verbal = false;
  bool _somatic = false;

  @override
  void initState() {
    super.initState();
    try {
      _classes = HeroShieldReactionRules.castingClasses(widget.hero);
      _slots = HeroShieldReactionRules.slots(widget.hero);
      if (_classes.isNotEmpty) _castingClass = _classes.first;
      if (_slots.isNotEmpty) _slotKey = _slots.first.key;
    } on FormatException catch (e) {
      _error = e.message;
    } on StateError catch (e) {
      _error = e.message;
    }
  }

  MagicMissileSlot? get _selectedSlot {
    for (final slot in _slots) {
      if (slot.key == _slotKey) return slot;
    }
    return null;
  }

  void _confirm() {
    final slot = _selectedSlot;
    if (_castingClass == null || slot == null || !_verbal || !_somatic) {
      setState(
        () => _error = 'Eigene Klasse, Platz und beide Komponenten bestätigen.',
      );
      return;
    }
    Navigator.of(context).pop(
      HeroShieldReactionPlan(
        castingClass: _castingClass!,
        slotLevel: slot.level,
        pactMagic: slot.pactMagic,
        verbalConfirmed: _verbal,
        somaticConfirmed: _somatic,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Schildreaktion für Gegnerzug'),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Hiermit autorisierst du die Schild-Reaktion (Shield) '
            'für den unmittelbar folgenden gegnerischen Angriff. '
            'Ein Zauberplatz wird NUR verbraucht, wenn der Angriff trifft '
            'und +5 RK den Treffer tatsächlich verhindert. '
            'Kritische Treffer können dadurch nicht abgewehrt werden. '
            'Andernfalls bleibt dein Zauberplatz erhalten.',
          ),
          if (_error != null)
            Text(_error!, key: const ValueKey('hero-shield-error')),
          if (HeroShieldReactionRules.preparedName(widget.hero) == null)
            const Text('Der Zauber Schild ist nicht vorbereitet.'),
          DropdownButtonFormField<String>(
            key: const ValueKey('hero-shield-class'),
            initialValue: _castingClass,
            decoration: const InputDecoration(labelText: 'Zauberklasse'),
            items: [
              for (final name in _classes)
                DropdownMenuItem(value: name, child: Text(name)),
            ],
            onChanged: (value) => setState(() => _castingClass = value),
          ),
          DropdownButtonFormField<String>(
            key: const ValueKey('hero-shield-slot'),
            initialValue: _slotKey,
            decoration: const InputDecoration(labelText: 'Zauberplatz'),
            items: [
              for (final slot in _slots)
                DropdownMenuItem(
                  value: slot.key,
                  child: Text(
                    '${slot.pactMagic ? 'Pakt ' : ''}Grad ${slot.level} – ${slot.remaining} frei',
                  ),
                ),
            ],
            onChanged: (value) => setState(() => _slotKey = value),
          ),
          CheckboxListTile(
            key: const ValueKey('hero-shield-verbal'),
            value: _verbal,
            onChanged: (v) => setState(() => _verbal = v ?? false),
            title: const Text('Verbale Komponente ist möglich'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            key: const ValueKey('hero-shield-somatic'),
            value: _somatic,
            onChanged: (v) => setState(() => _somatic = v ?? false),
            title: const Text('Gestische Komponente ist möglich'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    ),
    actions: [
      FantasyTextButton(
        label: 'Abbrechen',
        style: FantasyButtonStyle.iron,
        onPressed: () => Navigator.of(context).pop(),
      ),
      FantasyTextButton(
        key: const ValueKey('hero-shield-confirm'),
        label: 'Zug beenden und ggf. Schild wirken',
        style: FantasyButtonStyle.arcane,
        onPressed:
            HeroShieldReactionRules.preparedName(widget.hero) == null ||
                _classes.isEmpty ||
                _slots.isEmpty
            ? null
            : _confirm,
      ),
    ],
  );
}
