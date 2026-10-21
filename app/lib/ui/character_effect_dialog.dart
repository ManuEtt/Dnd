import 'package:flutter/material.dart';

import 'fantasy_buttons.dart';

import '../domain/damage_rules.dart';
import '../domain/models.dart';

enum CharacterEffectKind { damage, healing, temporaryHitPoints }

/// Explicit input only. The caller must resolve and persist this effect through
/// the rule engine against the current hero, after the dialog has closed.
class CharacterEffectChoice {
  const CharacterEffectChoice({
    required this.kind,
    required this.source,
    required this.amount,
    this.damageType = DamageType.force,
    this.resistant = false,
    this.vulnerable = false,
    this.immune = false,
    this.critical = false,
    this.replaceTemporary = false,
  });

  final CharacterEffectKind kind;
  final String source;
  final int amount;
  final DamageType damageType;
  final bool resistant, vulnerable, immune, critical, replaceTemporary;
}

/// Collects confirmed external values; narration cannot confirm any field.
/// Opening or cancelling this dialog never changes the supplied hero.
class CharacterEffectDialog extends StatefulWidget {
  const CharacterEffectDialog({super.key, required this.hero});

  final HeroCharacter hero;

  @override
  State<CharacterEffectDialog> createState() => _CharacterEffectDialogState();
}

class _CharacterEffectDialogState extends State<CharacterEffectDialog> {
  final _form = GlobalKey<FormState>();
  final _source = TextEditingController();
  final _amount = TextEditingController();
  CharacterEffectKind _kind = CharacterEffectKind.damage;
  DamageType _damageType = DamageType.force;
  bool _resistant = false;
  bool _vulnerable = false;
  bool _immune = false;
  bool _critical = false;
  bool _replaceTemporary = false;

  static const _damageLabels = {
    DamageType.acid: 'Säure',
    DamageType.bludgeoning: 'Wucht',
    DamageType.cold: 'Kälte',
    DamageType.fire: 'Feuer',
    DamageType.force: 'Energie',
    DamageType.lightning: 'Blitz',
    DamageType.necrotic: 'Nekrotisch',
    DamageType.piercing: 'Stich',
    DamageType.poison: 'Gift',
    DamageType.psychic: 'Psychisch',
    DamageType.radiant: 'Gleißend',
    DamageType.slashing: 'Hieb',
    DamageType.thunder: 'Schall',
  };

  @override
  void dispose() {
    _source.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_form.currentState!.validate()) return;
    final damage = _kind == CharacterEffectKind.damage;
    Navigator.pop(
      context,
      CharacterEffectChoice(
        kind: _kind,
        source: _source.text.trim(),
        amount: int.parse(_amount.text.trim()),
        damageType: damage ? _damageType : DamageType.force,
        resistant: damage && _resistant,
        vulnerable: damage && _vulnerable,
        immune: damage && _immune,
        critical: damage && _critical,
        replaceTemporary:
            _kind == CharacterEffectKind.temporaryHitPoints &&
            _replaceTemporary,
      ),
    );
  }

  Widget _checkbox(
    String key,
    String title,
    bool value,
    ValueChanged<bool> onChanged, {
    String? subtitle,
  }) {
    return CheckboxListTile(
      key: ValueKey(key),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      value: value,
      onChanged: (next) => setState(() => onChanged(next ?? false)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hero = widget.hero;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          key: const ValueKey('character-effect-scroll'),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Äußeren Effekt bestätigen',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  '${hero.name}: ${hero.hitPoints ?? '–'} / '
                  '${hero.maxHitPoints ?? '–'} TP; '
                  '${hero.temporaryHitPoints} temporäre TP',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Nur bereits feststehende Werte aus einer geprüften '
                  'Regelquelle oder einem bestätigten Würfelwurf eintragen. '
                  'Eine Erzählung allein bestätigt keinen Effekt.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<CharacterEffectKind>(
                  key: const ValueKey('character-effect-kind'),
                  initialValue: _kind,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Effekt'),
                  items: const [
                    DropdownMenuItem(
                      value: CharacterEffectKind.damage,
                      child: Text('Schaden', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: CharacterEffectKind.healing,
                      child: Text('Heilung', overflow: TextOverflow.ellipsis),
                    ),
                    DropdownMenuItem(
                      value: CharacterEffectKind.temporaryHitPoints,
                      child: Text(
                        'Temporäre TP',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  onChanged: (next) {
                    if (next != null) setState(() => _kind = next);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('character-effect-source'),
                  controller: _source,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Quelle',
                    helperText:
                        'Zum Beispiel: bestätigter Fallenwurf '
                        '(1–200 Zeichen).',
                    helperMaxLines: 4,
                    errorMaxLines: 4,
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    if (text.isEmpty) {
                      return 'Bitte die bestätigte Quelle nennen.';
                    }
                    if (text.length > 200) {
                      return 'Höchstens 200 Zeichen verwenden.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const ValueKey('character-effect-amount'),
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Betrag',
                    helperText: 'Ganze Zahl von 1 bis 100000.',
                    helperMaxLines: 3,
                    errorMaxLines: 4,
                  ),
                  validator: (value) {
                    final text = (value ?? '').trim();
                    final amount = int.tryParse(text);
                    if (!RegExp(r'^[0-9]+$').hasMatch(text) ||
                        amount == null ||
                        amount < 1 ||
                        amount > 100000) {
                      return 'Eine ganze Zahl von 1 bis 100000 eingeben.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_kind == CharacterEffectKind.damage) ...[
                  DropdownButtonFormField<DamageType>(
                    key: const ValueKey('character-effect-damage-type'),
                    initialValue: _damageType,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Schadensart'),
                    items: [
                      for (final type in DamageType.values)
                        DropdownMenuItem(
                          value: type,
                          child: Text(
                            _damageLabels[type]!,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (next) {
                      if (next != null) setState(() => _damageType = next);
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Die folgenden Angaben gelten nur für diesen '
                    'Schaden. Mehrere bestätigte Angaben sind möglich.',
                  ),
                  _checkbox(
                    'character-effect-resistant',
                    'Resistenz bestätigt',
                    _resistant,
                    (v) => _resistant = v,
                  ),
                  _checkbox(
                    'character-effect-vulnerable',
                    'Anfälligkeit bestätigt',
                    _vulnerable,
                    (v) => _vulnerable = v,
                  ),
                  _checkbox(
                    'character-effect-immune',
                    'Immunität bestätigt',
                    _immune,
                    (v) => _immune = v,
                  ),
                  _checkbox(
                    'character-effect-critical',
                    'Kritischer Treffer bestätigt',
                    _critical,
                    (v) => _critical = v,
                    subtitle:
                        'Der Betrag enthält bereits alle gewürfelten '
                        'kritischen Schadenswürfel. Er wird hier nicht '
                        'erneut verdoppelt.',
                  ),
                ],
                if (_kind == CharacterEffectKind.healing)
                  const Text(
                    'Heilung erhöht die regulären TP höchstens bis '
                    'zum bestätigten Maximum. Sie gewährt keine temporären TP.',
                  ),
                if (_kind == CharacterEffectKind.temporaryHitPoints) ...[
                  const Text(
                    'Temporäre TP werden niemals addiert. Ohne '
                    'Ersetzbestätigung bleibt der größere Vorrat erhalten. '
                    'Sie heilen keine regulären TP und wecken nicht auf.',
                  ),
                  _checkbox(
                    'character-effect-replace-temporary',
                    'Vorhandenen Vorrat ausdrücklich ersetzen',
                    _replaceTemporary,
                    (v) => _replaceTemporary = v,
                    subtitle:
                        'Auch dann ersetzen, wenn der neue Vorrat '
                        'kleiner ist.',
                  ),
                ],
                const SizedBox(height: 12),
                const Text(
                  'Aktions-, Zauberplatz- und andere Ressourcenkosten '
                  'sowie weitere Quelleneffekte werden hier nicht gebucht. '
                  'Diese müssen separat regelgerecht geklärt sein.',
                ),
                const SizedBox(height: 20),
                FantasyTextButton(
                  key: const ValueKey('character-effect-confirm'),
                  label: 'Effekt bestätigen',
                  style: FantasyButtonStyle.arcane,
                  onPressed: _confirm,
                ),
                const SizedBox(height: 8),
                FantasyTextButton(
                  key: const ValueKey('character-effect-cancel'),
                  label: 'Abbrechen',
                  style: FantasyButtonStyle.iron,
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
