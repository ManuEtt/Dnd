import 'package:flutter/material.dart';

import '../domain/models.dart';
import 'fantasy_buttons.dart';

/// An effect record is created only after the user explicitly confirms that
/// an independent rule path already resolved the spell. No casting occurs.
class ConfirmedSpellEffectChoice {
  const ConfirmedSpellEffectChoice.add({
    required this.spellName,
    required this.source,
    required this.concentrationBound,
    required this.ownTurnEnds,
  }) : effectId = '';

  const ConfirmedSpellEffectChoice.remove(this.effectId)
    : spellName = '',
      source = '',
      concentrationBound = false,
      ownTurnEnds = null;

  final String spellName;
  final String source;
  final bool concentrationBound;
  final int? ownTurnEnds;
  final String effectId;
  bool get isRemoval => effectId.isNotEmpty;
}

class ConfirmedSpellEffectDialog extends StatefulWidget {
  const ConfirmedSpellEffectDialog({
    super.key,
    required this.hero,
    required this.encounter,
  });

  final HeroCharacter hero;
  final Encounter? encounter;

  @override
  State<ConfirmedSpellEffectDialog> createState() =>
      _ConfirmedSpellEffectDialogState();
}

class _ConfirmedSpellEffectDialogState
    extends State<ConfirmedSpellEffectDialog> {
  final _source = TextEditingController();
  String? _spellName;
  int? _ownTurnEnds;
  bool _bound = false;
  bool _remove = false;
  String? _effectId;
  String? _error;

  bool get _ownTurn =>
      widget.encounter != null &&
      !widget.encounter!.isFinished &&
      widget.encounter!.activeParticipant == 'hero';

  @override
  void initState() {
    super.initState();
    if (widget.hero.spells.isNotEmpty) {
      _spellName = widget.hero.spells.first;
    }
    if (widget.hero.confirmedSpellEffects.isNotEmpty) {
      _effectId = widget.hero.confirmedSpellEffects.first.id;
    }
  }

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  void _submit() {
    if (_remove) {
      if (_effectId == null ||
          !widget.hero.confirmedSpellEffects.any((e) => e.id == _effectId)) {
        setState(() => _error = 'Bitte einen vorhandenen Eintrag wählen.');
        return;
      }
      Navigator.pop(context, ConfirmedSpellEffectChoice.remove(_effectId!));
      return;
    }
    final name = _spellName;
    final source = _source.text.trim();
    if (name == null || !widget.hero.spells.contains(name)) {
      setState(() => _error = 'Bekannten Zauber wählen.');
      return;
    }
    if (source.isEmpty || source.length > 200) {
      setState(() => _error = 'Bestätigte Quelle mit 1–200 Zeichen eingeben.');
      return;
    }
    if (_ownTurnEnds != null && !_ownTurn) {
      setState(() => _error = 'Zugdauer benötigt deinen aktiven Kampfzug.');
      return;
    }
    if (_bound && widget.hero.concentratingOn != name) {
      setState(
        () => _error = 'Zuerst aktive Konzentration auf diesen Zauber bestätigen.',
      );
      return;
    }
    Navigator.pop(
      context,
      ConfirmedSpellEffectChoice.add(
        spellName: name,
        source: source,
        concentrationBound: _bound,
        ownTurnEnds: _ownTurnEnds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final known = widget.hero.spells;
    final existing = widget.hero.confirmedSpellEffects;
    return AlertDialog(
      title: const Text('Bestätigte Zauberwirkung'),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (existing.isNotEmpty)
                SwitchListTile(
                  key: const ValueKey('spell-effect-remove-mode'),
                  title: const Text('Eintrag beenden'),
                  contentPadding: EdgeInsets.zero,
                  value: _remove,
                  onChanged: (value) => setState(() {
                    _remove = value;
                    _error = null;
                  }),
                ),
              if (_remove)
                DropdownButtonFormField<String>(
                  key: const ValueKey('spell-effect-existing'),
                  isExpanded: true,
                  initialValue: _effectId,
                  decoration: const InputDecoration(labelText: 'Zaubereintrag'),
                  items: [
                    for (final effect in existing)
                      DropdownMenuItem(
                        value: effect.id,
                        child: Text(
                          '${effect.spellName} · ${effect.source}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _effectId = value),
                )
              else ...[
                DropdownButtonFormField<String>(
                  key: const ValueKey('spell-effect-name'),
                  isExpanded: true,
                  initialValue: _spellName,
                  decoration: const InputDecoration(labelText: 'Bekannter Zauber'),
                  items: [
                    for (final name in known)
                      DropdownMenuItem(
                        value: name,
                        child: Text(name, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _spellName = value;
                    _bound = false;
                  }),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('spell-effect-source'),
                  controller: _source,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Unabhängig bestätigte Quelle',
                    hintText: 'z. B. geprüfter Zaubereffekt',
                  ),
                ),
                DropdownButtonFormField<int?>(
                  key: const ValueKey('spell-effect-duration'),
                  isExpanded: true,
                  initialValue: _ownTurnEnds,
                  decoration: const InputDecoration(labelText: 'Bestätigtes Ende'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Nur ausdrückliche Beendigung'),
                    ),
                    if (_ownTurn) ...const [
                      DropdownMenuItem<int?>(
                        value: 1,
                        child: Text('Aktuelles eigenes Zugende'),
                      ),
                      DropdownMenuItem<int?>(
                        value: 3,
                        child: Text('Nach 3 eigenen Zugenden'),
                      ),
                      DropdownMenuItem<int?>(
                        value: 10,
                        child: Text('Nach 10 eigenen Zugenden'),
                      ),
                    ],
                  ],
                  onChanged: (value) => setState(() => _ownTurnEnds = value),
                ),
                if (widget.hero.concentratingOn == _spellName)
                  CheckboxListTile(
                    key: const ValueKey('spell-effect-concentration'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text('An aktive Konzentration binden'),
                    value: _bound,
                    onChanged: (value) =>
                        setState(() => _bound = value ?? false),
                  ),
                const SizedBox(height: 8),
                const Text(
                  'Diese Aktion registriert nur eine bereits separat '
                  'regelgeprüfte Wirkung. Sie wirkt keinen Zauber, '
                  'verbraucht keine Zauberplätze und verursacht '
                  'keinen Schaden. Zugdauern benötigen bestätigte Regelbelege.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  key: const ValueKey('spell-effect-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        FantasyTextButton(
          key: const ValueKey('spell-effect-cancel'),
          label: 'Abbrechen',
          style: FantasyButtonStyle.iron,
          onPressed: () => Navigator.pop(context),
        ),
        FantasyTextButton(
          key: const ValueKey('spell-effect-confirm'),
          label: _remove ? 'Eintrag beenden' : 'Wirkung bestätigen',
          style: FantasyButtonStyle.arcane,
          onPressed: _submit,
        ),
      ],
    );
  }
}
