import 'package:flutter/material.dart';

import '../domain/magic_missile_rules.dart';
import '../domain/cover_rules.dart';
import '../domain/models.dart';

/// Only collects confirmations. Casting, rolling and persistence are delegated
/// to GameEngine through GameController after revision validation.
class MagicMissileChoice {
  const MagicMissileChoice({
    required this.castingClass,
    required this.slotLevel,
    required this.pactMagic,
    required this.targetVisibleConfirmed,
    required this.targetWithinRangeConfirmed,
    required this.verbalComponentConfirmed,
    required this.somaticComponentConfirmed,
    required this.noProtectionConfirmed,
  });

  final String castingClass;
  final int slotLevel;
  final bool pactMagic;
  final bool targetVisibleConfirmed, targetWithinRangeConfirmed;
  final bool verbalComponentConfirmed, somaticComponentConfirmed;
  final bool noProtectionConfirmed;
}

class MagicMissileDialog extends StatefulWidget {
  const MagicMissileDialog({
    super.key,
    required this.hero,
    required this.encounter,
  });
  final HeroCharacter hero;
  final Encounter encounter;

  @override
  State<MagicMissileDialog> createState() => _MagicMissileDialogState();
}

class _MagicMissileDialogState extends State<MagicMissileDialog> {
  List<String> _classes = const [];
  List<MagicMissileSlot> _slots = const [];
  String? _className, _slotKey, _setupError, _error;
  bool _visible = false, _range = false, _verbal = false;
  bool _somatic = false, _unprotected = false;

  @override
  void initState() {
    super.initState();
    try {
      _classes = MagicMissileRules.castingClasses(widget.hero);
      _slots = MagicMissileRules.slots(widget.hero);
      if (_classes.isNotEmpty) _className = _classes.first;
      if (_slots.isNotEmpty) _slotKey = _slots.first.key;
    } on FormatException catch (e) {
      _setupError = e.message;
    } on StateError catch (e) {
      _setupError = e.message;
    }
  }

  MagicMissileSlot? get _slot {
    for (final slot in _slots) {
      if (slot.key == _slotKey) return slot;
    }
    return null;
  }

  Widget _check(
    String key,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) => CheckboxListTile(
    key: ValueKey('missile-$key'),
    title: Text(title),
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
    value: value,
    onChanged: (next) => setState(() {
      onChanged(next ?? false);
      _error = null;
    }),
  );

  void _confirm() {
    final slot = _slot;
    if (_className == null || slot == null || _setupError != null) return;
    if (!_visible || !_range || !_verbal || !_somatic || !_unprotected) {
      setState(
        () => _error = 'Bitte alle tatsächlichen Ziel- und '
            'Komponentenvoraussetzungen bestätigen.',
      );
      return;
    }
    if (widget.encounter.enemyCover == CoverLevel.total) {
      setState(() => _error = 'Das Ziel hat vollständige Deckung.');
      return;
    }
    Navigator.pop(
      context,
      MagicMissileChoice(
        castingClass: _className!,
        slotLevel: slot.level,
        pactMagic: slot.pactMagic,
        targetVisibleConfirmed: _visible,
        targetWithinRangeConfirmed: _range,
        verbalComponentConfirmed: _verbal,
        somaticComponentConfirmed: _somatic,
        noProtectionConfirmed: _unprotected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final slot = _slot;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: SingleChildScrollView(
          key: const ValueKey('missile-dialog-scroll'),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Magisches Geschoss wirken',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text('Ziel: ${widget.encounter.enemyName}. '
                  'Alle Geschosse treffen dieses eine Ziel gleichzeitig.'),
              const SizedBox(height: 10),
              if (_setupError != null)
                Text('Regelprüfung: $_setupError')
              else if (MagicMissileRules.preparedName(widget.hero) == null ||
                  _classes.isEmpty ||
                  _slots.isEmpty)
                const Text(
                  'Der vorbereitete Zauber, die passende eigene Klasse '
                  'oder ein verfügbarer Zauberplatz fehlt.',
                )
              else ...[
                DropdownButtonFormField<String>(
                  key: const ValueKey('missile-class'),
                  initialValue: _className,
                  decoration: const InputDecoration(labelText: 'Zauberklasse'),
                  items: [
                    for (final name in _classes)
                      DropdownMenuItem(value: name, child: Text(name)),
                  ],
                  onChanged: (v) => setState(() => _className = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const ValueKey('missile-slot'),
                  initialValue: _slotKey,
                  decoration: const InputDecoration(labelText: 'Zauberplatz'),
                  items: [
                    for (final choice in _slots)
                      DropdownMenuItem(
                        value: choice.key,
                        child: Text(
                          '${choice.pactMagic ? 'Pakt ' : ''}Grad '
                          '${choice.level}: ${choice.remaining} frei',
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _slotKey = v),
                ),
                if (slot != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Wirkung: ${slot.level + 2} Geschosse, '
                    'jedes 1W4+1 Energieschaden; '
                    'verbraucht Magieaktion und einen Zauberplatz.',
                  ),
                ],
                const SizedBox(height: 12),
                _check(
                  'visible',
                  'Ich kann das Ziel sehen.',
                  _visible,
                  (v) => _visible = v,
                ),
                _check(
                  'range',
                  'Ziel ist höchstens 120 Fuß entfernt.',
                  _range,
                  (v) => _range = v,
                ),
                _check(
                  'verbal',
                  'Verbale Komponenten sind möglich.',
                  _verbal,
                  (v) => _verbal = v,
                ),
                _check(
                  'somatic',
                  'Gestische Komponenten mit einer Hand sind möglich.',
                  _somatic,
                  (v) => _somatic = v,
                ),
                _check(
                  'protection',
                  'Keine bekannte Schildzauber-Abwehr oder '
                  'Energiestärke-Immunität/-Resistenz des Ziels.',
                  _unprotected,
                  (v) => _unprotected = v,
                ),
                const Text(
                  'Dieses Inkrement unterstützt nur einen Gegner ohne '
                  'bestätigte Schutzwirkung. Bei unbekannten Schutzwerten '
                  'nicht bestätigen; keine Positionsdaten werden erfunden.',
                ),
              ],
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton(
                key: const ValueKey('missile-confirm'),
                onPressed:
                    _setupError != null ||
                        MagicMissileRules.preparedName(widget.hero) == null ||
                        _classes.isEmpty ||
                        slot == null
                    ? null
                    : _confirm,
                child: const Text('Wirken bestätigen'),
              ),
              TextButton(
                key: const ValueKey('missile-cancel'),
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
