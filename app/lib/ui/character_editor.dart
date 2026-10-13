import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../domain/models.dart';

const _abilityNames = <String, String>{
  'strength': 'Stärke',
  'dexterity': 'Geschicklichkeit',
  'constitution': 'Konstitution',
  'intelligence': 'Intelligenz',
  'wisdom': 'Weisheit',
  'charisma': 'Charisma',
};

/// Edits nullable values explicitly: an imported unknown score stays unknown.
class CharacterEditor extends StatefulWidget {
  const CharacterEditor({super.key, this.hero});

  final HeroCharacter? hero;

  @override
  State<CharacterEditor> createState() => _CharacterEditorState();
}

class _CharacterEditorState extends State<CharacterEditor> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  final _scores = <String, TextEditingController>{};
  late final Map<String, dynamic> _original;
  String? _error;

  @override
  void initState() {
    super.initState();
    _original =
        widget.hero?.toJson() ??
        HeroCharacter(
          id: const Uuid().v4(),
          name: '',
          species: 'Mensch',
          className: 'Waldläufer',
        ).toJson();
    for (final key in <String>[
      'name',
      'species',
      'className',
      'subclass',
      'level',
      'background',
      'backstory',
      'hitPoints',
      'maxHitPoints',
      'armorClass',
      'speed',
      'experience',
      'gold',
      'weaponDamage',
    ]) {
      _fields[key] = TextEditingController(
        text: _original[key]?.toString() ?? '',
      );
    }
    for (final key in [
      'skills',
      'savingThrowProficiencies',
      'features',
      'spells',
      'conditions',
    ]) {
      _fields[key] = TextEditingController(
        text: (_original[key] as List).join('\n'),
      );
    }
    final scores = _original['abilities'] as Map? ?? <String, dynamic>{};
    for (final key in _abilityNames.keys) {
      _scores[key] = TextEditingController(text: scores[key]?.toString() ?? '');
    }
  }

  @override
  void dispose() {
    for (final field in [..._fields.values, ..._scores.values]) {
      field.dispose();
    }
    super.dispose();
  }

  Widget _text(
    String key,
    String label, {
    int lines = 1,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: _fields[key],
        decoration: InputDecoration(labelText: label),
        minLines: lines,
        maxLines: lines == 1 ? 1 : 6,
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                  ? 'Bitte $label eintragen.'
                  : null
            : null,
      ),
    );
  }

  Widget _number(
    String key,
    String label, {
    int min = 0,
    int max = 999999,
    bool required = false,
    String? suffix,
  }) {
    return SizedBox(
      width: 195,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: _fields[key] ?? _scores[key],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: label,
            suffixText: suffix,
            helperText: required ? null : 'Leer = nicht bestätigt',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return required ? 'Bitte einen Wert eintragen.' : null;
            }
            final n = int.tryParse(value);
            return n == null || n < min || n > max
                ? '$min bis $max eingeben.'
                : null;
          },
        ),
      ),
    );
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    try {
      final json = Map<String, dynamic>.from(_original);
      for (final key in [
        'name',
        'species',
        'className',
        'subclass',
        'background',
        'backstory',
        'weaponDamage',
      ]) {
        json[key] = _fields[key]!.text.trim();
      }
      for (final key in [
        'level',
        'hitPoints',
        'maxHitPoints',
        'armorClass',
        'speed',
        'experience',
        'gold',
      ]) {
        json[key] = int.tryParse(_fields[key]!.text.trim());
      }
      for (final key in [
        'skills',
        'savingThrowProficiencies',
        'features',
        'spells',
        'conditions',
      ]) {
        json[key] = _fields[key]!.text
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      json['abilities'] = {
        for (final entry in _scores.entries)
          entry.key: int.tryParse(entry.value.text.trim()),
      };
      final hp = json['hitPoints'] as int?;
      final maxHp = json['maxHitPoints'] as int?;
      if (hp != null && maxHp != null && hp > maxHp) {
        throw const FormatException(
          'Aktuelle Trefferpunkte dürfen das Maximum nicht überschreiten.',
        );
      }
      Navigator.of(context).pop(HeroCharacter.fromJson(json));
    } catch (error) {
      setState(
        () => _error = 'Charakter konnte nicht gespeichert werden: $error',
      );
    }
  }

  Future<void> _editInventory({int? index}) async {
    final inventory = _original['inventory'] as List;
    final item = index == null
        ? null
        : InventoryItem.fromJson(
            Map<String, dynamic>.from(inventory[index] as Map),
          );
    final result = await showDialog<InventoryItem>(
      context: context,
      builder: (context) => _InventoryItemDialog(item: item),
    );
    if (result != null && mounted) {
      setState(() {
        if (index == null) {
          inventory.add(result.toJson());
        } else {
          inventory[index] = result.toJson();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.hero == null
              ? 'Neuen Helden erschaffen'
              : 'Charakter bearbeiten',
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Dein Held',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Unbekannte Werte dürfen leer bleiben. Für regelgebundene '
                  'Proben müssen Attribute, Trefferpunkte, Rüstung und Bewegung bestätigt sein.',
                ),
                const SizedBox(height: 20),
                _text('name', 'Charaktername', required: true),
                _text('species', 'Spezies', required: true),
                _text('className', 'Klasse', required: true),
                _text('subclass', 'Unterklasse'),
                _text('background', 'Hintergrund'),
                _text('backstory', 'Charaktergeschichte', lines: 3),
                Wrap(
                  spacing: 14,
                  children: [
                    _number('level', 'Stufe', min: 1, max: 20, required: true),
                    _number('experience', 'Erfahrungspunkte'),
                    _number('gold', 'Gold'),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Attribute',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'Standardverteilung zur Auswahl: 15, 14, 13, 12, 10, 8. '
                    'Modifikatoren und Übungsbonus werden aus bestätigten Werten berechnet.',
                  ),
                ),
                Wrap(
                  spacing: 14,
                  children: [
                    for (final ability in _abilityNames.entries)
                      _number(ability.key, ability.value, min: 1, max: 30),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Kampfwerte',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  children: [
                    _number('hitPoints', 'Aktuelle TP'),
                    _number('maxHitPoints', 'Maximale TP', min: 1),
                    _number('armorClass', 'Rüstungsklasse', min: 1, max: 40),
                    _number('speed', 'Bewegung', min: 1, max: 200, suffix: 'm'),
                  ],
                ),
                _text('weaponDamage', 'Waffenschaden (z. B. 1d8)'),
                DropdownButtonFormField<String>(
                  initialValue: _original['weaponAbility'] as String,
                  decoration: const InputDecoration(
                    labelText: 'Attribut der verwendeten Waffe',
                  ),
                  items: [
                    for (final ability in _abilityNames.entries)
                      DropdownMenuItem(
                        value: ability.key,
                        child: Text(ability.value),
                      ),
                  ],
                  onChanged: (value) => _original['weaponAbility'] = value,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mit dieser Waffe geübt'),
                  subtitle: const Text(
                    'Übungsbonus bei Angriffen einmal berücksichtigen.',
                  ),
                  value: _original['weaponProficient'] == true,
                  onChanged: (value) =>
                      setState(() => _original['weaponProficient'] = value),
                ),
                const SizedBox(height: 20),
                ExpansionTile(
                  title: const Text('Fertigkeiten, Fähigkeiten & Zauber'),
                  subtitle: const Text(
                    'Ein Eintrag pro Zeile. Gespeicherte Werte bleiben erhalten.',
                  ),
                  children: [
                    _text('skills', 'Geübte Fertigkeiten', lines: 3),
                    _text(
                      'savingThrowProficiencies',
                      'Geübte Rettungswürfe',
                      lines: 2,
                    ),
                    _text('features', 'Klassenfähigkeiten', lines: 3),
                    _text('spells', 'Bekannte Zauber', lines: 3),
                    _text('conditions', 'Aktuelle Zustände', lines: 2),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Inventar & Ausrüstung',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                for (
                  var index = 0;
                  index < (_original['inventory'] as List).length;
                  index++
                )
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      (_original['inventory'] as List)[index]['name'] as String,
                    ),
                    subtitle: Text(
                      'Anzahl: ${(_original['inventory'] as List)[index]['quantity']}',
                    ),
                    onTap: () => _editInventory(index: index),
                    trailing: IconButton(
                      tooltip: 'Gegenstand entfernen',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => setState(
                        () => (_original['inventory'] as List).removeAt(index),
                      ),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _editInventory(),
                  icon: const Icon(Icons.add),
                  label: const Text('Gegenstand hinzufügen'),
                ),
                if ((_original['unverifiedNotes'] as List).isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Historische, ungeprüfte Angaben',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  for (final note in _original['unverifiedNotes'] as List)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(note as String),
                    ),
                ],
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Charakter speichern'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InventoryItemDialog extends StatefulWidget {
  const _InventoryItemDialog({this.item});
  final InventoryItem? item;

  @override
  State<_InventoryItemDialog> createState() => _InventoryItemDialogState();
}

class _InventoryItemDialogState extends State<_InventoryItemDialog> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.name ?? '');
  late final _quantity = TextEditingController(
    text: (widget.item?.quantity ?? 1).toString(),
  );
  late final _description = TextEditingController(
    text: widget.item?.description ?? '',
  );

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.item == null ? 'Gegenstand hinzufügen' : 'Gegenstand bearbeiten',
    ),
    content: SizedBox(
      width: 500,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value?.trim().isEmpty != false
                    ? 'Bitte einen Namen eingeben.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantity,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Anzahl'),
                validator: (value) => (int.tryParse(value ?? '') ?? 0) < 1
                    ? 'Mindestens 1.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Beschreibung'),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Abbrechen'),
      ),
      FilledButton(
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          Navigator.pop(
            context,
            InventoryItem(
              id: widget.item?.id ?? const Uuid().v4(),
              name: _name.text.trim(),
              quantity: int.parse(_quantity.text),
              description: _description.text.trim(),
            ),
          );
        },
        child: const Text('Speichern'),
      ),
    ],
  );
}
