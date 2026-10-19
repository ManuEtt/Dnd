import 'package:flutter/material.dart';

import '../domain/condition_effects.dart';
import '../domain/condition_rules.dart';
import '../domain/models.dart';

/// A confirmed source change; the controller still validates revision and rules.
class ConditionEffectChoice {
  const ConditionEffectChoice.add({
    required this.condition,
    required this.source,
    required this.duration,
  }) : effectId = '';

  const ConditionEffectChoice.remove(this.effectId)
    : condition = '',
      source = '',
      duration = ConditionEffectDuration.untilRemoved;

  final String condition, source, effectId;
  final ConditionEffectDuration duration;
  bool get isRemoval => effectId.isNotEmpty;
}

class ConditionEffectDialog extends StatefulWidget {
  const ConditionEffectDialog({
    super.key,
    required this.hero,
    required this.encounter,
  });

  final HeroCharacter hero;
  final Encounter? encounter;

  @override
  State<ConditionEffectDialog> createState() => _ConditionEffectDialogState();
}

class _ConditionEffectDialogState extends State<ConditionEffectDialog> {
  final _source = TextEditingController();
  String _condition = 'vergiftet';
  ConditionEffectDuration _duration = ConditionEffectDuration.untilRemoved;
  bool _remove = false;
  String? _selectedId;
  String? _validationError;

  bool get _activeOwnTurn =>
      widget.encounter != null &&
      !widget.encounter!.isFinished &&
      widget.encounter!.activeParticipant == 'hero';

  @override
  void initState() {
    super.initState();
    if (widget.hero.conditionEffects.isNotEmpty) {
      _selectedId = widget.hero.conditionEffects.first.id;
    }
  }

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_remove) {
      final id = _selectedId;
      if (id == null ||
          !widget.hero.conditionEffects.any((effect) => effect.id == id)) {
        setState(() => _validationError = 'Wähle eine vorhandene Quelle.');
        return;
      }
      Navigator.of(context).pop(ConditionEffectChoice.remove(id));
      return;
    }
    final source = _source.text.trim();
    if (source.isEmpty || source.length > 200) {
      setState(
        () => _validationError = 'Quelle mit 1 bis 200 Zeichen eingeben.',
      );
      return;
    }
    if (_duration != ConditionEffectDuration.untilRemoved && !_activeOwnTurn) {
      setState(
        () => _validationError = 'Ein Zugendpunkt benötigt deinen Kampfzug.',
      );
      return;
    }
    Navigator.of(context).pop(
      ConditionEffectChoice.add(
        condition: _condition,
        source: source,
        duration: _duration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effects = widget.hero.conditionEffects;
    final canRemove = effects.isNotEmpty;
    return AlertDialog(
      title: const Text('Zustandsquelle verwalten'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (canRemove)
                SwitchListTile(
                  key: const ValueKey('condition-effect-remove-mode'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Bestehende Quelle beenden'),
                  value: _remove,
                  onChanged: (value) => setState(() {
                    _remove = value;
                    _validationError = null;
                  }),
                ),
              if (_remove)
                DropdownButtonFormField<String>(
                  key: const ValueKey('condition-effect-existing-source'),
                  isExpanded: true,
                  initialValue: _selectedId,
                  decoration: const InputDecoration(
                    labelText: 'Zustand und Quelle',
                  ),
                  items: [
                    for (final effect in effects)
                      DropdownMenuItem(
                        value: effect.id,
                        child: Text(
                          '${effect.condition}: ${effect.source}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _selectedId = value),
                )
              else ...[
                DropdownButtonFormField<String>(
                  key: const ValueKey('condition-effect-condition'),
                  initialValue: _condition,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Zustand'),
                  items: [
                    for (final condition in ConditionRules.descriptions.keys)
                      DropdownMenuItem(
                        value: condition,
                        child: Text(condition),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _condition = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('condition-effect-source'),
                  controller: _source,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Bestätigte Quelle',
                    hintText: 'z. B. Giftfalle',
                  ),
                ),
                DropdownButtonFormField<ConditionEffectDuration>(
                  key: const ValueKey('condition-effect-duration'),
                  initialValue: _duration,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Wirkungsende'),
                  items: [
                    const DropdownMenuItem(
                      value: ConditionEffectDuration.untilRemoved,
                      child: Text('Bis zur ausdrücklichen Entfernung'),
                    ),
                    if (_activeOwnTurn) ...const [
                      DropdownMenuItem(
                        value: ConditionEffectDuration.currentTurnEnd,
                        child: Text('Ende des aktuellen eigenen Zugs'),
                      ),
                      DropdownMenuItem(
                        value: ConditionEffectDuration.nextTurnEnd,
                        child: Text('Ende des nächsten eigenen Zugs'),
                      ),
                    ],
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _duration = value);
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nur bestätigte Ursachen. Erzählungen lösen keine '
                  'Regeländerung aus. Allgemeine Zauberzeiten sind noch offen.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
              if (_validationError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _validationError!,
                  key: const ValueKey('condition-effect-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('condition-effect-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          key: const ValueKey('condition-effect-confirm'),
          onPressed: _confirm,
          child: Text(_remove ? 'Quelle beenden' : 'Zustand bestätigen'),
        ),
      ],
    );
  }
}
