import 'package:flutter/material.dart';

import '../domain/ability_generation.dart';
import '../domain/models.dart';
import '../domain/rules_engine.dart';

const abilityLabels = <String, String>{
  'strength': 'Stärke',
  'dexterity': 'Geschicklichkeit',
  'constitution': 'Konstitution',
  'intelligence': 'Intelligenz',
  'wisdom': 'Weisheit',
  'charisma': 'Charisma',
};

/// An explicit proposal; the editor applies it only after confirmation.
class AbilityAssignment {
  AbilityAssignment({
    required Map<String, int> scores,
    required this.background,
  }) : scores = Map.unmodifiable(scores);

  final Map<String, int> scores;
  final String background;
}

enum _BonusPattern { split, allThree }

class AbilityAssignmentDialog extends StatefulWidget {
  const AbilityAssignmentDialog({
    super.key,
    this.hasExistingValues = false,
    this.level = 1,
  });

  final bool hasExistingValues;
  final int level;

  @override
  State<AbilityAssignmentDialog> createState() =>
      _AbilityAssignmentDialogState();
}

class _AbilityAssignmentDialogState extends State<AbilityAssignmentDialog> {
  var _method = AbilityGenerationMethod.standardArray;
  final _standard = <String, int>{
    for (var i = 0; i < abilityNames.length; i++)
      abilityNames[i]: AbilityAllocation.standardArray[i],
  };
  final _pointBuy = <String, int>{for (final key in abilityNames) key: 8};
  SrdBackground? _background;
  var _pattern = _BonusPattern.split;
  String? _plusTwo;
  String? _plusOne;
  bool _confirmedReplacement = false;

  AbilityAllocation get _allocation => AbilityAllocation(
    method: _method,
    baseScores: _method == AbilityGenerationMethod.standardArray
        ? _standard
        : _pointBuy,
  );

  BackgroundAbilityBoost? get _boost {
    final background = _background;
    if (background == null) return null;
    if (_pattern == _BonusPattern.allThree) {
      return BackgroundAbilityBoost(
        background: background,
        increases: {for (final key in background.abilityKeys) key: 1},
      );
    }
    if (_plusTwo == null || _plusOne == null) return null;
    return BackgroundAbilityBoost(
      background: background,
      increases: {_plusTwo!: 2, _plusOne!: 1},
    );
  }

  AbilityGenerationResult? get _result {
    final boost = _boost;
    final allocation = _allocation;
    if (boost == null || !boost.isValid || !allocation.isValid) return null;
    return allocation.compose(backgroundBoost: boost);
  }

  bool get _requiresConfirmation =>
      widget.hasExistingValues || widget.level > 1;

  void _setStandard(String key, int value) {
    setState(() {
      final other = _standard.entries.firstWhere(
        (entry) => entry.value == value,
      );
      _standard[other.key] = _standard[key]!;
      _standard[key] = value;
    });
  }

  bool _canIncrease(String key) {
    final value = _pointBuy[key]!;
    if (value >= 15) return false;
    return _allocation.withScore(key, value + 1).isValid;
  }

  String _preview(String key, AbilityGenerationResult? result) {
    final base = _allocation.baseScores[key]!;
    if (result == null) return 'Basis $base · Erhöhung noch wählen';
    final score = result.finalScores[key]!;
    final bonus = score - base;
    final modifier = RulesEngine.abilityModifier(score);
    final signed = modifier >= 0 ? '+$modifier' : '$modifier';
    return 'Basis $base + $bonus = $score · Modifikator $signed';
  }

  Widget _scoreInput(String key, AbilityGenerationResult? result) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_method == AbilityGenerationMethod.standardArray)
          DropdownButtonFormField<int>(
            key: ValueKey('base-$key-${_standard[key]}'),
            initialValue: _standard[key],
            isExpanded: true,
            decoration: InputDecoration(labelText: abilityLabels[key]),
            items: [
              for (final value in AbilityAllocation.standardArray)
                DropdownMenuItem(value: value, child: Text('$value')),
            ],
            onChanged: (value) {
              if (value != null) _setStandard(key, value);
            },
          )
        else
          Row(
            children: [
              Expanded(child: Text(abilityLabels[key]!)),
              IconButton(
                key: ValueKey('decrease-$key'),
                tooltip: '${abilityLabels[key]} verringern',
                onPressed: _pointBuy[key]! > 8
                    ? () => setState(() => _pointBuy[key] = _pointBuy[key]! - 1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              SizedBox(
                width: 30,
                child: Text(
                  '${_pointBuy[key]}',
                  key: ValueKey('point-value-$key'),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                key: ValueKey('increase-$key'),
                tooltip: '${abilityLabels[key]} erhöhen',
                onPressed: _canIncrease(key)
                    ? () => setState(() => _pointBuy[key] = _pointBuy[key]! + 1)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        const SizedBox(height: 6),
        Text(_preview(key, result), key: ValueKey('preview-$key')),
      ],
    ),
  );

  Widget _bonusChoice({required bool plusTwo}) {
    final selected = plusTwo ? _plusTwo : _plusOne;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: DropdownButtonFormField<String>(
        key: ValueKey(
          'bonus-${plusTwo ? 'two' : 'one'}-${_background!.name}-${selected ?? 'unset'}',
        ),
        initialValue: selected,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: plusTwo ? '+2 auf Attribut' : '+1 auf anderes Attribut',
        ),
        items: [
          for (final key in _background!.abilityKeys)
            if (plusTwo || key != _plusTwo)
              DropdownMenuItem(value: key, child: Text(abilityLabels[key]!)),
        ],
        onChanged: (value) => setState(() {
          if (plusTwo) {
            _plusTwo = value;
            if (_plusOne == value) _plusOne = null;
          } else {
            _plusOne = value;
          }
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final allocation = _allocation;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      scrollable: true,
      title: const Text('Stufe-1-Starthilfe'),
      content: SizedBox(
        width: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Startwerte nach SRD 5.2.1. Dies ist kein Stufenaufstieg. '
              'Die Hilfe übernimmt sechs Attributwerte und den Hintergrundnamen. '
              'Hintergrund-Fertigkeiten, Talente, Klasse, Ausrüstung und '
              'Kampfwerte ergänze danach selbst.',
            ),
            const SizedBox(height: 18),
            DropdownButtonFormField<AbilityGenerationMethod>(
              key: const ValueKey('ability-generation-method'),
              initialValue: _method,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Methode'),
              items: const [
                DropdownMenuItem(
                  value: AbilityGenerationMethod.standardArray,
                  child: Text('Standardverteilung'),
                ),
                DropdownMenuItem(
                  value: AbilityGenerationMethod.pointBuy,
                  child: Text('Punkte-Kauf (27 Punkte)'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _method = value);
              },
            ),
            const SizedBox(height: 14),
            if (_method == AbilityGenerationMethod.standardArray)
              const Text(
                '15, 14, 13, 12, 10, 8 jeweils einmal verteilen. '
                'Die Auswahl eines vergebenen Wertes tauscht beide Attribute.',
              )
            else ...[
              Text(
                'Verfügbar: ${allocation.remainingPoints} von 27 Punkten',
                key: const ValueKey('remaining-ability-points'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: (allocation.pointCost ?? 0) / 27),
              const SizedBox(height: 8),
              Text(
                allocation.usesFullBudget
                    ? 'Alle 27 Punkte sind verteilt.'
                    : '${allocation.remainingPoints} Punkte noch ungenutzt. '
                          'Du kannst auch mit Restpunkten übernehmen.',
              ),
              const Text('Basis 8–15; Kosten: 0, 1, 2, 3, 4, 5, 7, 9.'),
            ],
            const SizedBox(height: 18),
            DropdownButtonFormField<SrdBackground>(
              key: const ValueKey('ability-background'),
              initialValue: _background,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'SRD-Hintergrund'),
              hint: const Text('Bitte ausdrücklich wählen'),
              items: [
                for (final background in SrdBackground.values)
                  DropdownMenuItem(
                    value: background,
                    child: Text(background.label),
                  ),
              ],
              onChanged: (value) => setState(() {
                _background = value;
                _plusTwo = null;
                _plusOne = null;
              }),
            ),
            if (_background != null) ...[
              const SizedBox(height: 10),
              Text(
                'Mögliche Erhöhungen: '
                '${_background!.abilityKeys.map((key) => abilityLabels[key]).join(', ')}.',
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<_BonusPattern>(
                key: const ValueKey('ability-bonus-pattern'),
                initialValue: _pattern,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Erhöhungen'),
                items: const [
                  DropdownMenuItem(
                    value: _BonusPattern.split,
                    child: Text('+2 und +1'),
                  ),
                  DropdownMenuItem(
                    value: _BonusPattern.allThree,
                    child: Text('+1 auf alle drei'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _pattern = value;
                    _plusTwo = null;
                    _plusOne = null;
                  });
                },
              ),
              if (_pattern == _BonusPattern.split) ...[
                _bonusChoice(plusTwo: true),
                _bonusChoice(plusTwo: false),
              ],
            ] else ...[
              const SizedBox(height: 8),
              const Text(
                'Wähle einen Hintergrund und seine Attributerhöhungen.',
              ),
            ],
            const SizedBox(height: 20),
            Text('Vorschau', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            for (final key in abilityNames) _scoreInput(key, result),
            if (_requiresConfirmation) ...[
              Text(
                widget.level > 1
                    ? 'Dieser Held ist Stufe ${widget.level}. Die Starthilfe '
                          'ersetzt seine Attribute mit neuen Startwerten; '
                          'spätere Stufensteigerungen musst du selbst ergänzen.'
                    : 'Dieser Held hat bereits Attribute oder einen Hintergrund.',
              ),
              CheckboxListTile(
                key: const ValueKey('confirm-ability-replacement'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _confirmedReplacement,
                onChanged: (value) =>
                    setState(() => _confirmedReplacement = value == true),
                title: const Text(
                  'Vorhandene Attribute und Hintergrund durch diese '
                  'Startwerte ersetzen.',
                ),
              ),
            ],
            const Text(
              'Die Vorschau enthält Hintergrunderhöhungen bereits einmal. '
              'Übernommene Werte werden erst mit „Charakter speichern“ gesichert.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          key: const ValueKey('apply-ability-assignment'),
          onPressed:
              result != null &&
                  (!_requiresConfirmation || _confirmedReplacement)
              ? () => Navigator.pop(
                  context,
                  AbilityAssignment(
                    scores: result.finalScores,
                    background: _background!.label,
                  ),
                )
              : null,
          child: const Text('Attribute übernehmen'),
        ),
      ],
    );
  }
}
