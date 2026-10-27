import 'package:flutter/material.dart';

import '../domain/ability_generation.dart';
import '../domain/srd_magic_initiate_choice.dart';

/// Explicit SRD 5.2.1 Magic Initiate spell/ability decisions.
/// A confirmed selection is persisted by the editor, but does not
/// pre-authorize a slotless cast or grant spells to the combat engine.
class SrdMagicInitiateDialog extends StatefulWidget {
  const SrdMagicInitiateDialog({super.key, required this.background});

  final SrdBackground background;

  @override
  State<SrdMagicInitiateDialog> createState() => _SrdMagicInitiateDialogState();
}

class _SrdMagicInitiateDialogState extends State<SrdMagicInitiateDialog> {
  String? _first;
  String? _second;
  String? _levelOne;
  String? _ability;

  Widget _spellDropdown({
    required String keyName,
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) => DropdownButtonFormField<String>(
    key: ValueKey(keyName),
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(labelText: label),
    items: [
      for (final option in options)
        DropdownMenuItem(value: option, child: Text(option)),
    ],
    onChanged: onChanged,
  );

  @override
  Widget build(BuildContext context) {
    final cantrips = SrdMagicInitiateChoice.availableCantrips(
      widget.background,
    );
    final levelOne = SrdMagicInitiateChoice.availableLevelOne(
      widget.background,
    );
    final valid =
        _first != null &&
        _second != null &&
        _first != _second &&
        _levelOne != null &&
        _ability != null;
    final source = widget.background == SrdBackground.acolyte
        ? 'Kleriker'
        : 'Magier';
    return AlertDialog(
      title: Text('Magieinitiierter ($source)'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Wähle zwei verschiedene Zaubertricks, einen Zauber des '
                '1. Grades aus derselben SRD-Liste und das Zauberattribut.',
              ),
              const SizedBox(height: 14),
              _spellDropdown(
                keyName: 'magic-initiate-cantrip-one',
                label: 'Zaubertrick 1',
                value: _first,
                options: cantrips,
                onChanged: (value) => setState(() => _first = value),
              ),
              const SizedBox(height: 8),
              _spellDropdown(
                keyName: 'magic-initiate-cantrip-two',
                label: 'Zaubertrick 2',
                value: _second,
                options: cantrips,
                onChanged: (value) => setState(() => _second = value),
              ),
              const SizedBox(height: 8),
              _spellDropdown(
                keyName: 'magic-initiate-level-one',
                label: 'Zauber des 1. Grades',
                value: _levelOne,
                options: levelOne,
                onChanged: (value) => setState(() => _levelOne = value),
              ),
              const SizedBox(height: 8),
              _spellDropdown(
                keyName: 'magic-initiate-ability',
                label: 'Zauberattribut',
                value: _ability,
                options: SrdMagicInitiateChoice.abilities,
                onChanged: (value) => setState(() => _ability = value),
              ),
              if (_first != null && _first == _second)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Bitte zwei unterschiedliche Zaubertricks auswählen.',
                  ),
                ),
              const Padding(
                padding: EdgeInsets.only(top: 14),
                child: Text(
                  'Die Auswahl wird im Charakterbogen gespeichert. '
                  'Einmaliges Wirken ohne Zauberplatz, Erholung nach '
                  'langer Rast, erneutes Wirken mit Zauberplätzen '
                  'und Zauberaustausch beim Stufenaufstieg sind '
                  'noch nicht an die Spielmechanik angebunden.',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          key: const ValueKey('confirm-magic-initiate-choice'),
          onPressed: !valid
              ? null
              : () => Navigator.of(context).pop(
                  SrdMagicInitiateChoice(
                    background: widget.background,
                    cantrips: [_first!, _second!],
                    levelOneSpell: _levelOne!,
                    castingAbility: _ability!,
                  ),
                ),
          child: const Text('Zauberwahl bestätigen'),
        ),
      ],
    );
  }
}
