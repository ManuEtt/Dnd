import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../domain/models.dart';
import '../domain/character_creation_progression.dart';
import '../domain/srd_class_level_up.dart';
import '../domain/srd_character_creation_audit.dart';
import '../domain/starting_ability_origin.dart';
import '../domain/ability_generation.dart';
import '../domain/srd_background_package.dart';
import '../domain/srd_character_classes.dart';
import '../domain/srd_equipment_catalog.dart';
import '../domain/starting_equipment_import.dart';
import '../domain/srd_starting_combat_values.dart';
import '../domain/equipment_rules.dart';
import '../domain/multiclass_rules.dart';
import '../domain/rules_engine.dart';
import '../domain/starting_hit_points.dart';
import '../domain/spellcasting_rules.dart';
import 'ability_assignment_dialog.dart';
import 'srd_background_package_dialog.dart';
import 'srd_class_selection_dialog.dart';
import 'srd_class_level_up_dialog.dart';
import 'fantasy_ui.dart';
import 'fantasy_buttons.dart';
import 'fantasy_experience.dart';
import 'character_portrait_picker.dart';
import 'multiclass_selection_dialog.dart';
import 'equipment_catalog_dialog.dart';
import 'equipment_loadout_dialog.dart';
import 'spellcasting_dialog.dart';

/// Edits nullable values explicitly: an imported unknown score stays unknown.
class CharacterEditor extends StatefulWidget {
  const CharacterEditor({
    super.key,
    this.hero,
    this.autoFillExistingCombatValues = false,
  });

  final HeroCharacter? hero;

  /// Opt-in for the live archive/campaign views. Generic editors preserve
  /// historical unknown values until the player explicitly confirms them.
  final bool autoFillExistingCombatValues;

  @override
  State<CharacterEditor> createState() => _CharacterEditorState();
}

class _CharacterEditorState extends State<CharacterEditor> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  final _scores = <String, TextEditingController>{};
  late final Map<String, dynamic> _original;
  String? _error;
  Map<String, int>? _generatedStartingAbilities;
  StartingAbilityOrigin? _confirmedStartingAbilityOrigin;
  bool _manualAbilityException = false;
  bool _experienceManuallyEdited = false;
  bool _fighterSetupConfirmed = false;
  // Only wizard-confirmed intermediate levels may be advanced again before
  // the editor is saved; manually edited level numbers are still rejected.
  int? _lastWizardLevel;
  int? _lastWizardSecondaryLevel;
  String? _autoArmorClass;
  String? _autoSpeed;

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
          experience: 0,
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
      'exhaustionLevel',
    ]) {
      final initial =
          _original[key]?.toString() ?? (key == 'exhaustionLevel' ? '0' : '');
      _fields[key] = TextEditingController(
        text: key == 'speed' && _original['speed'] != null
            ? SrdStartingCombatValues.formatSpeedDecimeters(
                (_original['speed'] as int) * 10 +
                    ((_original['speedRemainderDecimeters'] as int?) ?? 0),
              )
            : initial,
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
    for (final key in abilityLabels.keys) {
      _scores[key] = TextEditingController(text: scores[key]?.toString() ?? '');
    }
    // The live hero screens opt in; legacy/manual editor flows retain their
    // original null values when an unrelated dialog is cancelled or saved.
    _autofillCombatValues();
  }

  @override
  void dispose() {
    for (final field in [..._fields.values, ..._scores.values]) {
      field.dispose();
    }
    super.dispose();
  }

  int? _confirmedAbility(String ability) {
    final score = int.tryParse(_scores[ability]!.text.trim());
    return score != null && score >= 1 && score <= 30 ? score : null;
  }

  int? _suggestedArmorClass() {
    // A worn armor or shield requires the selected SRD item's rule formula.
    // Never use merely imported but not equipped starter armor.
    final armorId = _original['equippedArmorId'] as String? ?? '';
    final shieldId = _original['equippedShieldId'] as String? ?? '';
    if (armorId.isNotEmpty || shieldId.isNotEmpty) {
      try {
        final hero = _draftForEquipment();
        return EquipmentRules.preview(
          hero,
          EquipmentSelection(
            armorId: armorId,
            shieldId: shieldId,
            armorTrained: _original['equippedArmorTrained'] == true,
            shieldTrained: _original['equippedShieldTrained'] == true,
          ),
        ).armorClass;
      } catch (_) {
        return null; // Keep unknown equipment outcomes explicit.
      }
    }
    return SrdStartingCombatValues.unarmoredArmorClass(
      className: _fields['className']!.text,
      dexterity: _confirmedAbility('dexterity'),
      constitution: _confirmedAbility('constitution'),
      wisdom: _confirmedAbility('wisdom'),
    );
  }

  /// Fill only unknown values or previously auto-proposed values. Existing
  /// confirmed values and manual overrides always remain authoritative.
  /// Unrelated editing actions must not silently confirm legacy unknowns.
  void _autofillCombatValues({bool explicit = false}) {
    if (widget.hero != null &&
        !widget.autoFillExistingCombatValues &&
        !explicit) {
      return;
    }
    final speciesDm = SrdStartingCombatValues.speedDecimeters(
      _fields['species']!.text,
    );
    final speedField = _fields['speed']!;
    final canUpdateSpeed =
        speedField.text.trim().isEmpty ||
        (_autoSpeed != null && speedField.text == _autoSpeed);
    if (canUpdateSpeed) {
      final suggested = speciesDm == null
          ? ''
          : SrdStartingCombatValues.formatSpeedDecimeters(speciesDm);
      speedField.text = suggested;
      _autoSpeed = suggested;
    }

    final acField = _fields['armorClass']!;
    final canUpdateAc =
        acField.text.trim().isEmpty ||
        (_autoArmorClass != null && acField.text == _autoArmorClass);
    if (canUpdateAc) {
      final ac = _suggestedArmorClass();
      final suggested = ac?.toString() ?? '';
      acField.text = suggested;
      _autoArmorClass = suggested;
    }
  }

  Widget _speedField() => SizedBox(
    width: 195,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: const ValueKey('character-speed-meters'),
        controller: _fields['speed'],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          labelText: 'Bewegung',
          suffixText: 'm',
          helperText: 'Spezies-Basiswert; z. B. 9 oder 10,5',
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return null;
          try {
            SrdStartingCombatValues.parseSpeedDecimeters(value);
            return null;
          } on FormatException catch (error) {
            return error.message;
          }
        },
      ),
    ),
  );

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
        onChanged: (value) {
          if (key == 'species' || key == 'className') {
            setState(() => _autofillCombatValues());
          }
        },
        validator: required
            ? (value) => value == null || value.trim().isEmpty
                  ? 'Bitte $label eintragen.'
                  : null
            : null,
      ),
    );
  }

  /// Pure preview only: invalid or missing values never become rule defaults.
  String? _abilityModifierPreview(String value) {
    final score = int.tryParse(value.trim());
    if (score == null || score < 1 || score > 30) return null;
    final modifier = RulesEngine.abilityModifier(score);
    return 'Modifikator: ${modifier >= 0 ? '+' : ''}$modifier';
  }

  Widget _number(
    String key,
    String label, {
    int min = 0,
    int max = 999999,
    bool required = false,
    String? suffix,
  }) {
    final isAbilityScore = _scores.containsKey(key);
    final modifierPreview = isAbilityScore
        ? _abilityModifierPreview(_scores[key]!.text)
        : null;
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
            helperText:
                modifierPreview ?? (required ? null : 'Leer = nicht bestätigt'),
          ),
          onChanged: (value) {
            if (isAbilityScore || key == 'exhaustionLevel') {
              setState(() {
                _error = null;
                if (isAbilityScore) _autofillCombatValues();
              });
            } else if (widget.hero == null && key == 'level') {
              final level = int.tryParse(value.trim());
              if (level != null &&
                  level >= 1 &&
                  level <= 20 &&
                  !_experienceManuallyEdited) {
                _fields['experience']!.text =
                    CharacterCreationProgression.startingExperience(
                      level,
                    ).toString();
              }
            } else if (widget.hero == null && key == 'experience') {
              _experienceManuallyEdited = true;
            }
          },
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
    _autofillCombatValues();
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
        'experience',
        'gold',
        'exhaustionLevel',
      ]) {
        json[key] = int.tryParse(_fields[key]!.text.trim());
      }
      final speedText = _fields['speed']!.text.trim();
      if (speedText.isEmpty) {
        json['speed'] = null;
        json.remove('speedRemainderDecimeters');
      } else {
        final dm = SrdStartingCombatValues.parseSpeedDecimeters(speedText);
        json['speed'] = dm ~/ 10;
        if (dm % 10 == 0) {
          json.remove('speedRemainderDecimeters');
        } else {
          json['speedRemainderDecimeters'] = dm % 10;
        }
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
      if (widget.hero == null &&
          findSrdClass(json['className'] as String)?.name == 'Kämpfer' &&
          !_fighterSetupConfirmed) {
        throw const FormatException(
          'Für einen neuen Kämpfer die D&D-Klassenwahl vollständig '
          'bestätigen (Attribute, Kampfstil, drei Waffenmeisterschaften, '
          'Fertigkeiten und Startausrüstung).',
        );
      }
      // Level-1 SRD generation and freehand entries must not be conflated.
      // Historical/imported characters intentionally remain editable.
      if (widget.hero == null) {
        final nonempty = _scores.values.any(
          (value) => value.text.trim().isNotEmpty,
        );
        final matchesConfirmedGeneration =
            _generatedStartingAbilities != null &&
            _scores.entries.every(
              (entry) =>
                  int.tryParse(entry.value.text.trim()) ==
                  _generatedStartingAbilities![entry.key],
            );
        if (nonempty &&
            !matchesConfirmedGeneration &&
            !_manualAbilityException) {
          throw const FormatException(
            'Für einen neuen Charakter Attribute regelkonform über '
            '„Attribute ermitteln“ verteilen oder die manuelle '
            'Hausregel-Ausnahme ausdrücklich bestätigen.',
          );
        }
      }
      if (widget.hero == null) {
        final level = json['level'] as int?;
        if (level != null) {
          final minimum = CharacterCreationProgression.startingExperience(
            level,
          );
          // A new character always has a known starting XP total.
          final experience = (json['experience'] as int?) ?? minimum;
          final nextThreshold = level < 20
              ? CharacterCreationProgression.startingExperience(level + 1)
              : null;
          if (experience < minimum ||
              (nextThreshold != null && experience >= nextThreshold)) {
            throw const FormatException(
              'Die Erfahrungspunkte passen nicht zur gewählten '
              'Charakterstufe nach D&D SRD 5.2.1.',
            );
          }
          json['experience'] = experience;
        }
      }
      if (widget.hero == null &&
          _original['startingBackgroundPackage'] != null) {
        final recorded = SrdBackgroundPackageChoice.fromJson(
          Map<String, dynamic>.from(
            _original['startingBackgroundPackage'] as Map,
          ),
        );
        if (json['background'] != recorded.background.label ||
            json['level'] != 1) {
          throw const FormatException(
            'Das bestätigte Hintergrundpaket darf nicht unbemerkt '
            'einem anderen Hintergrund oder einer anderen Stufe zugeordnet werden.',
          );
        }
      }
      json['abilities'] = {
        for (final entry in _scores.entries)
          entry.key: int.tryParse(entry.value.text.trim()),
      };
      // Only an explicitly confirmed level-1 choice receives initial
      // provenance. Historical heroes without metadata stay unchanged.
      final origin = _confirmedStartingAbilityOrigin;
      if (origin != null &&
          json['level'] == 1 &&
          json['background'] == origin.background &&
          abilityNames.every(
            (key) => json['abilities'][key] == origin.startingScores[key],
          )) {
        json['startingAbilityOrigin'] = origin.toJson();
      } else if (widget.hero == null) {
        json.remove('startingAbilityOrigin');
      }
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

  Future<void> _choosePortrait() async {
    final choice = await Navigator.of(context).push<CharacterPortraitChoice>(
      MaterialPageRoute(
        builder: (_) => CharacterPortraitPicker(
          initialPreset: (_original['portraitPreset'] as int?) ?? -1,
          initialPhotoBase64:
              (_original['portraitPhotoBase64'] as String?) ?? '',
        ),
      ),
    );
    if (!mounted || choice == null) return;
    setState(() {
      if (choice.preset < 0) {
        _original.remove('portraitPreset');
      } else {
        _original['portraitPreset'] = choice.preset;
      }
      if (choice.photoBase64.isEmpty) {
        _original.remove('portraitPhotoBase64');
      } else {
        _original['portraitPhotoBase64'] = choice.photoBase64;
      }
    });
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
          if (item!.catalogId != result.catalogId) {
            for (final slot in [
              'equippedArmorId',
              'equippedShieldId',
              'equippedWeaponId',
            ]) {
              if (_original[slot] == item.id) {
                _original[slot] = '';
                if (slot == 'equippedArmorId') {
                  _original['equippedArmorTrained'] = false;
                }
                if (slot == 'equippedShieldId') {
                  _original['equippedShieldTrained'] = false;
                }
                _error =
                    'Bearbeiteter Gegenstand ist nicht mehr kataloggebunden. '
                    'Ausrüstungswerte erneut prüfen.';
              }
            }
          }
          inventory[index] = result.toJson();
        }
      });
    }
  }

  Future<void> _addFromCatalog() async {
    final selected = await showDialog<EquipmentEntry>(
      context: context,
      builder: (_) => const EquipmentCatalogDialog(),
    );
    if (!mounted || selected == null) return;
    setState(() {
      (_original['inventory'] as List).add(
        InventoryItem(
          id: const Uuid().v4(),
          name: selected.name,
          quantity: 1,
          description:
              selected.note ?? '', // Reference-only note; mechanics in stats.
          catalogId: selected.id,
          stats: InventoryItemStats.fromCatalog(selected),
        ).toJson(),
      );
    });
  }

  /// Older starting kits stored only a name and quantity. Require an
  /// explicit preview/confirmation before adding reviewed SRD metadata.
  Future<void> _enrichInventoryFromCatalog() async {
    final entries = (_original['inventory'] as List)
        .map(
          (value) =>
              InventoryItem.fromJson(Map<String, dynamic>.from(value as Map)),
        )
        .toList();
    final updated = entries
        .map(StartingEquipmentImport.enrichLegacyItem)
        .toList();
    final changed = <int>[
      for (var i = 0; i < entries.length; i++)
        if (entries[i].catalogId != updated[i].catalogId) i,
    ];
    if (changed.isEmpty) {
      setState(
        () => _error =
            'Keine eindeutig passenden Gegenstände ohne Katalogwerte gefunden. '
            'Offene Ausrüstungswahlen bitte im SRD-Katalog auswählen.',
      );
      return;
    }
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('SRD-Gegenstandswerte nachtragen'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nur eindeutig zugeordnete Gegenstände erhalten '
                'ihre veröffentlichten Katalogattribute. '
                'Eigene Gegenstandswerte und nicht eindeutige '
                'Auswahlmöglichkeiten bleiben unverändert.',
              ),
              const SizedBox(height: 12),
              for (final i in changed)
                Text(
                  '${entries[i].name} → ${updated[i].name} '
                  '(Anzahl ${updated[i].quantity})',
                ),
            ],
          ),
        ),
        actions: [
          FantasyTextButton(
            label: 'Abbrechen',
            style: FantasyButtonStyle.iron,
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          FantasyButton(
            key: const ValueKey('character-enrich-confirm'),
            label: 'Attribute übernehmen',
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() {
      _original['inventory'] = updated.map((item) => item.toJson()).toList();
      _error = null;
    });
  }

  /// A snapshot of the current editor values, not only the originally loaded
  /// character. Invalid or unconfirmed attributes may not be silently guessed.
  HeroCharacter _draftForEquipment() {
    final json = Map<String, dynamic>.from(_original);
    json['name'] = _fields['name']!.text.trim();
    json['level'] = int.tryParse(_fields['level']!.text.trim());
    json['armorClass'] = int.tryParse(_fields['armorClass']!.text.trim());
    json['weaponDamage'] = _fields['weaponDamage']!.text.trim();
    json['abilities'] = {
      for (final entry in _scores.entries)
        entry.key: int.tryParse(entry.value.text.trim()),
    };
    return HeroCharacter.fromJson(json);
  }

  Future<void> _equipFromInventory() async {
    HeroCharacter draft;
    try {
      draft = _draftForEquipment();
    } catch (error) {
      setState(() => _error = 'Ausrüstung: $error');
      return;
    }
    final proposal = await showDialog<EquipmentRulePreview>(
      context: context,
      builder: (_) => EquipmentLoadoutDialog(hero: draft),
    );
    if (!mounted || proposal == null) return;
    try {
      final confirmed = EquipmentRules.confirm(_draftForEquipment(), proposal);
      setState(() {
        _original['equippedArmorId'] = confirmed.equippedArmorId;
        _original['equippedShieldId'] = confirmed.equippedShieldId;
        _original['equippedWeaponId'] = confirmed.equippedWeaponId;
        _original['equippedArmorTrained'] = confirmed.equippedArmorTrained;
        _original['equippedShieldTrained'] = confirmed.equippedShieldTrained;
        _original['weaponAbility'] = confirmed.weaponAbility;
        _original['weaponProficient'] = confirmed.weaponProficient;
        if (proposal.armorClass != null) {
          _fields['armorClass']!.text = '${confirmed.armorClass}';
          _autoArmorClass = null; // Equipment was explicitly confirmed.
        }
        if (proposal.weaponDamage != null) {
          _fields['weaponDamage']!.text = confirmed.weaponDamage;
        }
        _error = null;
      });
    } catch (error) {
      setState(
        () => _error = 'Ausrüstung konnte nicht angewendet werden: $error',
      );
    }
  }

  /// Persist resource changes only after the user confirms the complete editor.
  /// Revalidate against current field values rather than a stale dialog state.
  HeroCharacter _draftForSpellcasting() {
    final json = Map<String, dynamic>.from(_original);
    json['name'] = _fields['name']!.text.trim();
    json['className'] = _fields['className']!.text.trim();
    json['level'] = int.tryParse(_fields['level']!.text.trim());
    json['hitPoints'] = int.tryParse(_fields['hitPoints']!.text.trim());
    json['maxHitPoints'] = int.tryParse(_fields['maxHitPoints']!.text.trim());
    json['spells'] = _fields['spells']!.text
        .split('\n')
        .map((x) => x.trim())
        .where((x) => x.isNotEmpty)
        .toList();
    json['conditions'] = _fields['conditions']!.text
        .split('\n')
        .map((x) => x.trim())
        .where((x) => x.isNotEmpty)
        .toList();
    json['exhaustionLevel'] = int.tryParse(
      _fields['exhaustionLevel']!.text.trim(),
    );
    json['abilities'] = {
      for (final entry in _scores.entries)
        entry.key: int.tryParse(entry.value.text.trim()),
    };
    return HeroCharacter.fromJson(json);
  }

  Future<void> _manageSpellcasting() async {
    HeroCharacter draft;
    try {
      draft = _draftForSpellcasting();
      SpellcastingRules.availableSlots(draft);
      SpellcastingRules.availablePactSlots(draft);
    } catch (error) {
      setState(() => _error = 'Zauberressourcen: $error');
      return;
    }
    final choice = await showDialog<SpellcastingChoice>(
      context: context,
      builder: (_) => SpellcastingDialog(hero: draft),
    );
    if (!mounted || choice == null) return;
    try {
      final current = _draftForSpellcasting();
      final hero = choice.level == -1
          ? SpellcastingRules.endConcentration(current)
          : SpellcastingRules.cast(
              current,
              spellName: choice.name,
              spellLevel: choice.level,
              pactMagic: choice.pact,
              concentration: choice.concentration,
            ).hero;
      setState(() {
        _original['spentSpellSlots'] = Map<String, int>.from(
          hero.spentSpellSlots,
        );
        _original['spentPactSlots'] = hero.spentPactSlots;
        _original['concentratingOn'] = hero.concentratingOn;
        _error = null;
      });
    } catch (error) {
      setState(
        () =>
            _error = 'Zauberressourcen konnten nicht bestätigt werden: $error',
      );
    }
  }

  bool _isEquippedItem(dynamic id) => [
    'equippedArmorId',
    'equippedShieldId',
    'equippedWeaponId',
  ].any((slot) => _original[slot] == id);

  String _inventoryStatSummary(dynamic raw) {
    if (raw is! Map) return '';
    final stats = InventoryItemStats.fromJson(Map<String, dynamic>.from(raw));
    final parts = <String>[
      stats.kind.label,
      if (stats.damage != null) 'Schaden ${stats.damage}',
      if (stats.armorBaseAc != null)
        '${stats.kind == InventoryItemKind.shield ? 'RK-Bonus' : 'RK'} ${stats.armorBaseAc}',
      if (stats.weightLb != null) 'Gewicht ${stats.weightLb} lb',
      if (stats.priceCp != null) 'Wert ${stats.priceCp} KM',
      if (stats.charges != null) 'Ladungen ${stats.charges}',
    ];
    return parts.join(' · ');
  }

  void _removeInventoryItem(int index) {
    final inventory = _original['inventory'] as List;
    final id = (inventory[index] as Map)['id'];
    setState(() {
      for (final slot in [
        'equippedArmorId',
        'equippedShieldId',
        'equippedWeaponId',
      ]) {
        if (_original[slot] == id) {
          _original[slot] = '';
          if (slot == 'equippedArmorId') {
            _original['equippedArmorTrained'] = false;
          }
          if (slot == 'equippedShieldId') {
            _original['equippedShieldTrained'] = false;
          }
          _error =
              'Ausrüstung wurde abgelegt. Manuell bestätigte RK- und '
              'Waffenwerte bitte erneut prüfen.';
        }
      }
      inventory.removeAt(index);
    });
  }

  /// Calculate, preview and explicitly confirm SRD level-1 hit points.
  /// Existing characters and imported unknown values remain untouched on cancel.
  Future<void> _suggestStartingHitPoints() async {
    final proposal = (() {
      try {
        return StartingHitPoints.propose(
          className: _fields['className']!.text,
          constitutionScore: int.tryParse(_scores['constitution']!.text.trim()),
          characterLevel: int.tryParse(_fields['level']!.text.trim()),
        );
      } catch (error) {
        setState(() => _error = error.toString());
        return null;
      }
    })();
    if (proposal == null || !mounted) return;

    final previousHp = _fields['hitPoints']!.text.trim();
    final previousMax = _fields['maxHitPoints']!.text.trim();
    final overwrites = previousHp.isNotEmpty || previousMax.isNotEmpty;
    final sign = proposal.constitutionModifier >= 0 ? '+' : '';
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start-Trefferpunkte berechnen'),
        content: Text(
          '${proposal.characterClass}: W${proposal.hitDie} '
          '$sign${proposal.constitutionModifier} Konstitution = '
          '${proposal.maximum} TP.\n\n'
          '${overwrites ? 'Achtung: Die bisher eingetragenen Trefferpunkte '
                    'werden nur bei Bestätigung ersetzt. ' : ''}'
          'Für andere Stufen und bestehende Verletzungen darf dieser '
          'Startwert nicht automatisch verwendet werden.',
        ),
        actions: [
          FantasyTextButton(
            label: 'Abbrechen',
            style: FantasyButtonStyle.iron,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          FantasyTextButton(
            label: 'Trefferpunkte übernehmen',
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    setState(() {
      _fields['hitPoints']!.text = proposal.maximum.toString();
      _fields['maxHitPoints']!.text = proposal.maximum.toString();
      _error = null;
    });
  }

  Future<void> _inspectSrdCreation() async {
    try {
      final json = Map<String, dynamic>.from(_original);
      for (final field in ['name', 'species', 'className', 'background']) {
        json[field] = _fields[field]!.text.trim();
      }
      for (final field in [
        'level',
        'hitPoints',
        'maxHitPoints',
        'armorClass',
        'speed',
        'gold',
      ]) {
        json[field] = int.tryParse(_fields[field]!.text.trim());
      }
      for (final field in ['skills', 'savingThrowProficiencies']) {
        json[field] = _listFieldValues(field);
      }
      json['abilities'] = {
        for (final entry in _scores.entries)
          entry.key: int.tryParse(entry.value.text.trim()),
      };
      final draft = HeroCharacter.fromJson(json);
      final steps = SrdCharacterCreationAudit.inspect(draft);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('SRD-Charaktererstellung prüfen'),
          content: SizedBox(
            width: 430,
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text(
                  'Die Übersicht unterscheidet bestätigte Daten, '
                  'fehlende Angaben und noch nicht automatisierte Regeln. '
                  'Sie bescheinigt noch keine vollständige SRD-Regeltreue.',
                ),
                for (final step in steps)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      step.status == CreationStepStatus.confirmed
                          ? Icons.check_circle_outline
                          : step.status == CreationStepStatus.missing
                          ? Icons.error_outline
                          : Icons.info_outline,
                    ),
                    title: Text(step.title),
                    subtitle: Text(step.detail),
                    trailing: Text(
                      step.status == CreationStepStatus.confirmed
                          ? 'Erfasst'
                          : step.status == CreationStepStatus.missing
                          ? 'Fehlt'
                          : 'Offen',
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Schließen'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) setState(() => _error = 'SRD-Prüfung: $error');
    }
  }

  HeroCharacter _draftForLevelUp() {
    final json = Map<String, dynamic>.from(_original);
    json['name'] = _fields['name']!.text.trim();
    json['className'] = _fields['className']!.text.trim();
    json['subclass'] = _fields['subclass']!.text.trim();
    json['level'] = int.tryParse(_fields['level']!.text.trim());
    json['experience'] = int.tryParse(_fields['experience']!.text.trim());
    json['hitPoints'] = int.tryParse(_fields['hitPoints']!.text.trim());
    json['maxHitPoints'] = int.tryParse(_fields['maxHitPoints']!.text.trim());
    json['abilities'] = {
      for (final entry in _scores.entries)
        entry.key: int.tryParse(entry.value.text.trim()),
    };
    return HeroCharacter.fromJson(json);
  }

  Future<void> _advanceExistingClass() async {
    if (widget.hero == null) {
      setState(
        () => _error =
            'Für den Stufenaufstieg zuerst den '
            'Startcharakter speichern.',
      );
      return;
    }
    try {
      final draft = _draftForLevelUp();
      // This wizard may advance only a confirmed current level, not an
      // independent manual editing change already entered in the level box.
      final approvedLevel = _lastWizardLevel ?? widget.hero!.level;
      final approvedSecondary =
          _lastWizardSecondaryLevel ?? widget.hero!.secondaryClassLevel;
      if (draft.level != approvedLevel ||
          draft.primaryClassLevel != approvedLevel - approvedSecondary ||
          draft.secondaryClassLevel != approvedSecondary ||
          draft.className != widget.hero!.className ||
          draft.secondaryClassName != widget.hero!.secondaryClassName) {
        throw const FormatException(
          'Bitte unbestätigte Klassen-/Stufenänderungen zuerst '
          'zurücknehmen oder den Charakter speichern.',
        );
      }
      final proposal = await showDialog<SrdClassLevelUpProposal>(
        context: context,
        builder: (_) => SrdClassLevelUpDialog(hero: draft),
      );
      if (proposal == null || !mounted) return;
      // Refuse stale dialogs and modified editor values.
      final current = _draftForLevelUp();
      final result = proposal.applyTo(current);
      setState(() {
        _lastWizardLevel = result.level;
        _lastWizardSecondaryLevel = result.secondaryClassLevel;
        _fields['level']!.text = result.level.toString();
        _fields['hitPoints']!.text = result.hitPoints!.toString();
        _fields['maxHitPoints']!.text = result.maxHitPoints!.toString();
        _fields['subclass']!.text = result.subclass;
        for (final entry in result.abilities.entries) {
          _scores[entry.key]!.text = entry.value?.toString() ?? '';
        }
        _original['secondaryClassLevel'] = result.secondaryClassLevel;
        if (result.secondarySubclass.isNotEmpty) {
          _original['secondarySubclass'] = result.secondarySubclass;
        }
        _original['unverifiedNotes'] = [...result.unverifiedNotes];
        _error = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Stufenaufstieg nicht übernommen: $error');
      }
    }
  }

  Future<void> _configureSecondClass() async {
    // Existing second-class levels use the full SRD level-up wizard, including
    // subclass selection, class-level features and ability-score increases.
    if (widget.hero?.hasSecondClass == true) {
      await _advanceExistingClass();
      return;
    }
    // New characters first finish their initial level-1 character creation.
    if (widget.hero == null) {
      setState(
        () => _error =
            'Erstelle und speichere zuerst deinen '
            'Startcharakter. Die zweite Klasse kommt bei einem Stufenaufstieg hinzu.',
      );
      return;
    }
    try {
      // Work with the current confirmed fields, not stale initial values.
      final current = widget.hero!.copyWith(
        className: _fields['className']!.text.trim(),
        level: int.tryParse(_fields['level']!.text.trim()),
        abilities: {
          for (final entry in _scores.entries)
            entry.key: int.tryParse(entry.value.text.trim()),
        },
        skills: _listFieldValues('skills'),
        hitPoints: int.tryParse(_fields['hitPoints']!.text.trim()),
        maxHitPoints: int.tryParse(_fields['maxHitPoints']!.text.trim()),
      );
      // Refuse inconsistent manual changes to multi-class metadata.
      HeroCharacter.fromJson(current.toJson());
      final proposal = await showDialog<MulticlassProposal>(
        context: context,
        builder: (_) => MulticlassSelectionDialog(hero: current),
      );
      if (proposal == null || !mounted) return;
      final result = proposal.applyTo(current);
      setState(() {
        _original['secondaryClassName'] = result.secondaryClassName;
        _original['secondaryClassLevel'] = result.secondaryClassLevel;
        _fields['level']!.text = result.level.toString();
        _fields['hitPoints']!.text = result.hitPoints?.toString() ?? '';
        _fields['maxHitPoints']!.text = result.maxHitPoints?.toString() ?? '';
        _fields['skills']!.text = result.skills.join('\n');
        _error = null;
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => _error =
              'Zweitklasse konnte nicht hinzugefügt '
              'werden: $error',
        );
      }
    }
  }

  Future<void> _configureSrdClass() async {
    if (int.tryParse(_fields['level']!.text.trim()) != 1) {
      setState(
        () => _error =
            'Der SRD-Klassenassistent gilt für Charaktere auf Stufe 1. '
            'Bestehende höhere Stufen bleiben manuell editierbar.',
      );
      return;
    }
    final selected = await showDialog<SrdClassSetupResult>(
      context: context,
      builder: (_) => SrdClassSelectionDialog(
        currentClass: _fields['className']!.text,
        isNewCharacter: widget.hero == null,
        existingSkills: _listFieldValues('skills'),
        existingSavingThrows: _listFieldValues('savingThrowProficiencies'),
        characterLevel: int.tryParse(_fields['level']!.text.trim()),
        constitutionScore: int.tryParse(_scores['constitution']!.text.trim()),
        hasExistingHitPoints:
            _fields['hitPoints']!.text.trim().isNotEmpty ||
            _fields['maxHitPoints']!.text.trim().isNotEmpty,
        allowEquipment:
            widget.hero == null &&
            (_original['inventory'] as List).isEmpty &&
            _fields['gold']!.text.trim().isEmpty,
      ),
    );
    if (selected == null || !mounted) return;

    // Explicit dialog acceptance: only change the fields it actually covers.
    final choice = selected.selection;
    final skills = selected.replaceExistingProficiencies
        ? choice.skills
        : {..._listFieldValues('skills'), ...choice.skills}.toList();
    final saves = selected.replaceExistingProficiencies
        ? choice.characterClass.savingThrows
        : {
            ..._listFieldValues('savingThrowProficiencies'),
            ...choice.characterClass.savingThrows,
          }.toList();
    StartingHitPoints? hp;
    if (selected.useSuggestedHitPoints) {
      hp = StartingHitPoints.propose(
        className: choice.characterClass.name,
        constitutionScore: int.tryParse(_scores['constitution']!.text.trim()),
        characterLevel: int.tryParse(_fields['level']!.text.trim()),
      );
    }
    final kit = choice.startingKit;
    final fighterChoices = selected.fighterChoices;
    final selectedFeatures = _listFieldValues('features')
        .where(
          (name) =>
              !name.startsWith('Kampfstil: ') &&
              !name.startsWith('Zweite Luft (') &&
              !name.startsWith('Waffenmeisterschaft: '),
        )
        .toList();
    if (fighterChoices != null) {
      selectedFeatures.addAll(fighterChoices.featureLabels);
    }
    setState(() {
      if (widget.hero == null) {
        _fighterSetupConfirmed = fighterChoices != null;
        _fields['features']!.text = selectedFeatures.join('\n');
      } else if (fighterChoices != null) {
        _fields['features']!.text = [
          ..._listFieldValues('features'),
          ...fighterChoices.featureLabels.where(
            (f) => !_listFieldValues('features').contains(f),
          ),
        ].join('\n');
      }

      _fields['className']!.text = choice.characterClass.name;
      _fields['skills']!.text = skills.join('\n');
      _fields['savingThrowProficiencies']!.text = saves.join('\n');
      if (hp != null) {
        _fields['hitPoints']!.text = hp.maximum.toString();
        _fields['maxHitPoints']!.text = hp.maximum.toString();
      }
      if (kit != null) {
        _fields['gold']!.text = kit.gold.toString();
        final inventory = _original['inventory'] as List;
        for (final item in kit.items) {
          inventory.add(
            StartingEquipmentImport.fromSelectedStartingItem(
              item,
              const Uuid().v4(),
              selectedCatalogId: selected.equipmentChoices[item.name],
            ).toJson(),
          );
        }
      }
      _autofillCombatValues();
      _error = null;
    });
  }

  List<String> _listFieldValues(String name) => _fields[name]!.text
      .split('\n')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();

  Future<void> _chooseBackgroundPackage() async {
    if (widget.hero != null ||
        _original['startingBackgroundPackage'] != null) {
      setState(() => _error =
          'Hintergrund-Startpakete dürfen nicht doppelt angewendet '
          'oder nachträglich stillschweigend vergeben werden.');
      return;
    }
    if (int.tryParse(_fields['level']!.text.trim()) != 1) {
      setState(() => _error =
          'Das SRD-Hintergrundpaket ist nur für Stufe 1 verfügbar.');
      return;
    }
    final matches = SrdBackground.values.where(
      (item) => item.label == _fields['background']!.text.trim(),
    );
    if (matches.length != 1) {
      setState(() => _error =
          'Zuerst einen der vier SRD-Hintergründe über '
          '„Attribute ermitteln“ auswählen.');
      return;
    }
    final background = matches.single;
    if (_confirmedStartingAbilityOrigin != null &&
        _confirmedStartingAbilityOrigin!.background != background.label) {
      setState(() => _error =
          'Die Attributverteilung wurde für einen anderen '
          'Hintergrund bestätigt.');
      return;
    }
    final selected = await showDialog<SrdBackgroundPackageChoice>(
      context: context,
      builder: (_) => SrdBackgroundPackageDialog(background: background),
    );
    if (!mounted || selected == null) return;
    try {
      final inventory = (_original['inventory'] as List)
          .map(
            (value) => InventoryItem.fromJson(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .toList();
      final preview = selected.applyTo(
        HeroCharacter(
          id: 'background-preview',
          name: 'Entwurf',
          background: background.label,
          skills: _listFieldValues('skills'),
          features: _listFieldValues('features'),
          inventory: inventory,
          gold: int.tryParse(_fields['gold']!.text.trim()),
        ),
        nextId: () => const Uuid().v4(),
      );
      setState(() {
        _fields['skills']!.text = preview.skills.join('\n');
        _fields['features']!.text = preview.features.join('\n');
        _fields['gold']!.text = preview.gold.toString();
        _original['inventory'] =
            preview.inventory.map((item) => item.toJson()).toList();
        _original['startingBackgroundPackage'] = selected.toJson();
        _error = null;
      });
    } catch (error) {
      setState(() => _error =
          'Hintergrundpaket nicht übernommen: $error');
    }
  }

  Future<void> _assignAbilities() async {
    final result = await showDialog<AbilityAssignment>(
      context: context,
      builder: (_) => AbilityAssignmentDialog(
        hasExistingValues:
            _scores.values.any((field) => field.text.trim().isNotEmpty) ||
            _fields['background']!.text.trim().isNotEmpty,
        level: int.tryParse(_fields['level']!.text.trim()) ?? 1,
      ),
    );
    if (result == null || !mounted) return;
    final existingPackage = _original['startingBackgroundPackage'];
    if (existingPackage != null) {
      final recorded = SrdBackgroundPackageChoice.fromJson(
        Map<String, dynamic>.from(existingPackage as Map),
      );
      if (result.background != recorded.background.label) {
        setState(() => _error =
            'Die neue Attributverteilung gehört zu einem anderen '
            'Hintergrund als das bereits bestätigte Startpaket.');
        return;
      }
    }
    setState(() {
      for (final entry in result.scores.entries) {
        _scores[entry.key]!.text = entry.value.toString();
      }
      _fields['background']!.text = result.background;
      _generatedStartingAbilities = result.scores;
      _confirmedStartingAbilityOrigin = result.origin;
      _autofillCombatValues();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const FantasyRuneEmblem(rune: FantasyRune.hero, size: 30),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.hero == null
                    ? 'Neuen Helden erschaffen'
                    : 'Charakter bearbeiten',
              ),
            ),
          ],
        ),
      ),
      body: FantasyBackdrop(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const FantasyMoonlitBanner(height: 110),
                  const SizedBox(height: 15),
                  const FantasySectionTitle(
                    title: 'Dein Held',
                    icon: Icons.person_outline,
                  ),
                  FantasyPanel(
                    child: Row(
                      children: [
                        FantasyCharacterPortrait(
                          key: const ValueKey('editor-current-portrait'),
                          preset: (_original['portraitPreset'] as int?) ?? -1,
                          photoBase64:
                              (_original['portraitPhotoBase64'] as String?) ??
                              '',
                          name: _fields['name']!.text,
                          size: 116,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Charakterbild',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Eigenes Bild oder Fantasy-Vorlage wählen',
                              ),
                              const SizedBox(height: 8),
                              FantasyTextButton(
                                key: const ValueKey('editor-choose-portrait'),
                                label: 'Bild wählen',
                                icon: Icons.add_photo_alternate_outlined,
                                style: FantasyButtonStyle.iron,
                                onPressed: _choosePortrait,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const SizedBox(height: 8),
                  const Text(
                    'Unbekannte Werte dürfen leer bleiben. Für regelgebundene '
                    'Proben müssen Attribute, Trefferpunkte, Rüstung und Bewegung bestätigt sein.',
                  ),
                  const SizedBox(height: 20),
                  _text('name', 'Charaktername', required: true),
                  _text('species', 'Spezies', required: true),
                  _text('className', 'Klasse', required: true),
                  FantasyTextButton(
                    key: const ValueKey('open-srd-class-selection'),
                    label: 'D&D-Klasse und Fertigkeiten wählen',
                    icon: Icons.shield_outlined,
                    style: FantasyButtonStyle.woodGold,
                    onPressed: _configureSrdClass,
                  ),
                  if ((_original['secondaryClassName'] as String? ?? '')
                      .isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Mehrklassenheld: ${_fields['className']!.text} '
                        'Stufe ${((int.tryParse(_fields['level']!.text) ?? 1) - ((_original['secondaryClassLevel'] as int?) ?? 0))} '
                        '/ ${_original['secondaryClassName']} '
                        'Stufe ${_original['secondaryClassLevel']}',
                      ),
                    ),
                  if (widget.hero != null)
                    FantasyTextButton(
                      key: const ValueKey('open-class-level-up'),
                      label: 'Bestehende Klasse nach SRD steigern',
                      icon: Icons.trending_up_outlined,
                      style: FantasyButtonStyle.woodGold,
                      onPressed: _advanceExistingClass,
                    ),
                  FantasyTextButton(
                    key: const ValueKey('open-multiclass-selection'),
                    label: widget.hero?.hasSecondClass == true
                        ? 'Zweitklasse im Aufstiegsassistenten steigern'
                        : 'Zweitklasse nach SRD hinzufügen',
                    icon: Icons.auto_awesome_outlined,
                    style: FantasyButtonStyle.arcane,
                    onPressed: _configureSecondClass,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 5, bottom: 12),
                    child: Text(
                      'Mehrklassen nach D&D SRD 5.2.1: Voraussetzungen '
                      'prüfen, zusätzliche Fertigkeit wählen und TP-Zuwachs '
                      'erst nach Bestätigung übernehmen. Stufe 20 ist das Maximum.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  _text('subclass', 'Unterklasse'),
                  _text('background', 'Hintergrund'),
                  if (widget.hero == null)
                    FantasyTextButton(
                      key: const ValueKey('open-srd-background-package'),
                      label: 'SRD-Hintergrund: Talent, Übungen und Startpaket',
                      icon: Icons.backpack_outlined,
                      style: FantasyButtonStyle.woodGold,
                      onPressed: _chooseBackgroundPackage,
                    ),
                  _text('backstory', 'Charaktergeschichte', lines: 3),
                  Wrap(
                    spacing: 14,
                    children: [
                      _number(
                        'level',
                        'Stufe',
                        min: 1,
                        max: 20,
                        required: true,
                      ),
                      _number('experience', 'Erfahrungspunkte'),
                      _number('gold', 'Gold'),
                    ],
                  ),
                  if (widget.hero == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'D&D SRD: EP ab Stufe '
                        '${_fields['level']!.text.trim()} werden automatisch '
                        'vorbelegt. Der Übungsbonus ergibt sich aus der Stufe.',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const FantasySectionTitle(
                    title: 'Attribute',
                    icon: Icons.auto_awesome_outlined,
                    approvedIconIndex: 3,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      'Startwerte für Stufe 1 mit Standardverteilung oder '
                      'Punkte-Kauf bestimmen. Unbekannte Werte können auch '
                      'weiterhin einzeln bestätigt werden.',
                    ),
                  ),
                  FantasyTextButton(
                    key: const ValueKey('open-srd-creation-audit'),
                    label:
                        'Charaktererstellung auf fehlende SRD-Schritte prüfen',
                    icon: Icons.fact_check_outlined,
                    style: FantasyButtonStyle.iron,
                    onPressed: _inspectSrdCreation,
                  ),
                  FantasyTextButton(
                    key: const ValueKey('open-ability-assignment'),
                    label: 'Attribute ermitteln',
                    icon: Icons.auto_fix_high_outlined,
                    style: FantasyButtonStyle.arcane,
                    onPressed: _assignAbilities,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 14,
                    children: [
                      for (final ability in abilityLabels.entries)
                        _number(ability.key, ability.value, min: 1, max: 30),
                    ],
                  ),
                  if (widget.hero == null)
                    CheckboxListTile(
                      key: const ValueKey('allow-manual-abilities'),
                      contentPadding: EdgeInsets.zero,
                      value: _manualAbilityException,
                      onChanged: (value) => setState(
                        () => _manualAbilityException = value ?? false,
                      ),
                      title: const Text(
                        'Manuelle Attribute als Hausregel zulassen',
                      ),
                      subtitle: const Text(
                        'Nur für bewusst freie Werte oder '
                        'Änderungen nach der SRD-Verteilung. Das kann vom '
                        '27-Punkte-System abweichen.',
                      ),
                    ),
                  const SizedBox(height: 16),
                  const FantasySectionTitle(
                    title: 'Kampfwerte',
                    icon: Icons.shield_outlined,
                    approvedIconIndex: 0,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    children: [
                      _number('hitPoints', 'Aktuelle TP'),
                      _number('maxHitPoints', 'Maximale TP', min: 1),
                      _number('armorClass', 'Rüstungsklasse', min: 1, max: 40),
                      _speedField(),
                    ],
                  ),
                  FantasyTextButton(
                    key: const ValueKey('character-recalculate-combat-values'),
                    label: 'Fehlende RK und Bewegung berechnen',
                    icon: Icons.calculate_outlined,
                    style: FantasyButtonStyle.iron,
                    onPressed: () => setState(() {
                      _autofillCombatValues(explicit: true);
                      _error =
                          _fields['armorClass']!.text.isEmpty ||
                              _fields['speed']!.text.isEmpty
                          ? 'Für die automatische Berechnung bitte eine bekannte '
                                'SRD-Spezies und den Geschicklichkeitswert '
                                '(beim Mönch/Barbaren auch den zweiten Wert) bestätigen.'
                          : null;
                    }),
                  ),
                  FantasyTextButton(
                    key: const ValueKey('suggest-level1-hit-points'),
                    label: 'Start-TP nach D&D vorschlagen',
                    icon: Icons.favorite_outline,
                    style: FantasyButtonStyle.woodGold,
                    onPressed: _suggestStartingHitPoints,
                  ),
                  const SizedBox(height: 12),
                  _text('weaponDamage', 'Waffenschaden (z. B. 1d8)'),
                  DropdownButtonFormField<String>(
                    key: ValueKey(
                      'weapon-ability-${_original['weaponAbility']}',
                    ),
                    initialValue: _original['weaponAbility'] as String,
                    decoration: const InputDecoration(
                      labelText: 'Attribut der verwendeten Waffe',
                    ),
                    items: [
                      for (final ability in abilityLabels.entries)
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
                      FantasyTextButton(
                        key: const ValueKey('open-spellcasting-resources'),
                        label: 'Zauberplätze und Konzentration verwalten',
                        icon: Icons.auto_awesome_outlined,
                        style: FantasyButtonStyle.arcane,
                        onPressed: _manageSpellcasting,
                      ),
                      if ((_original['concentratingOn'] as String? ?? '')
                          .isNotEmpty)
                        Text(
                          'Aktive Konzentration: ${_original['concentratingOn']}',
                        ),
                      _text('conditions', 'Manuelle Zustände', lines: 2),
                      _number(
                        'exhaustionLevel',
                        'Erschöpfung (0–6)',
                        min: 0,
                        max: 6,
                        required: true,
                      ),
                      Builder(
                        builder: (context) {
                          final level = int.tryParse(
                            _fields['exhaustionLevel']!.text.trim(),
                          );
                          if (level == null || level < 0 || level > 6) {
                            return const SizedBox.shrink();
                          }
                          final speed = int.tryParse(
                            _fields['speed']!.text.trim(),
                          );
                          final remaining = speed == null
                              ? null
                              : (speed - level * 1.5).clamp(0, 1000);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              'SRD 5.2.1: W20-Tests ${level == 0 ? 'ohne Abzug' : '−${level * 2}'}'
                              ' · Bewegung ${remaining == null ? 'nicht bestätigt' : '$remaining m'}'
                              '${level == 6 ? ' · Stufe 6: Tod' : ''}.',
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const FantasySectionTitle(
                    title: 'Inventar & Ausrüstung',
                    icon: Icons.backpack_outlined,
                  ),
                  for (
                    var index = 0;
                    index < (_original['inventory'] as List).length;
                    index++
                  )
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        (_original['inventory'] as List)[index]['name']
                            as String,
                      ),
                      subtitle: Text(
                        'Anzahl: ${(_original['inventory'] as List)[index]['quantity']}'
                        '${_isEquippedItem((_original['inventory'] as List)[index]['id']) ? ' · angelegt' : ''}'
                        '${_inventoryStatSummary((_original['inventory'] as List)[index]['stats']).isEmpty ? '' : '\n${_inventoryStatSummary((_original['inventory'] as List)[index]['stats'])}'}',
                      ),
                      onTap: () => _editInventory(index: index),
                      trailing: IconButton(
                        tooltip: 'Gegenstand entfernen',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _removeInventoryItem(index),
                      ),
                    ),
                  FantasyTextButton(
                    key: const ValueKey('character-loadout-open'),
                    label: 'Waffen und Rüstung anlegen / RK berechnen',
                    icon: Icons.shield_outlined,
                    style: FantasyButtonStyle.woodGold,
                    onPressed: _equipFromInventory,
                  ),
                  const SizedBox(height: 8),
                  FantasyTextButton(
                    key: const ValueKey('character-loadout-clear'),
                    label: 'Ausrüstung ablegen (Werte manuell prüfen)',
                    icon: Icons.remove_circle_outline,
                    style: FantasyButtonStyle.iron,
                    onPressed: () => setState(() {
                      _original['equippedArmorId'] = '';
                      _original['equippedShieldId'] = '';
                      _original['equippedWeaponId'] = '';
                      _original['equippedArmorTrained'] = false;
                      _original['equippedShieldTrained'] = false;
                      _error =
                          'Ausrüstung abgelegt. Bisher manuell bestätigte '
                          'Rüstungs- und Waffenwerte bitte prüfen.';
                    }),
                  ),
                  const SizedBox(height: 8),
                  FantasyTextButton(
                    key: const ValueKey('character-enrich-equipment'),
                    label: 'Fehlende SRD-Gegenstandswerte ergänzen',
                    icon: Icons.auto_fix_high_outlined,
                    style: FantasyButtonStyle.iron,
                    onPressed: _enrichInventoryFromCatalog,
                  ),
                  const SizedBox(height: 8),
                  FantasyTextButton(
                    key: const ValueKey('character-catalog-open'),
                    label: 'Aus SRD-Ausrüstungskatalog wählen',
                    icon: Icons.menu_book_outlined,
                    style: FantasyButtonStyle.woodGold,
                    onPressed: _addFromCatalog,
                  ),
                  const SizedBox(height: 8),
                  FantasyTextButton(
                    key: const ValueKey('character-inventory-add'),
                    label: 'Gegenstand hinzufügen',
                    icon: Icons.add,
                    style: FantasyButtonStyle.woodGold,
                    onPressed: () => _editInventory(),
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
                  const SizedBox(height: 20),
                  // Permanently visible primary action in the footer below.
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          decoration: BoxDecoration(
            color: FantasyPalette.ink,
            border: Border(
              top: BorderSide(
                color: FantasyPalette.gold.withValues(alpha: .55),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 100),
                    child: SingleChildScrollView(
                      child: Text(
                        _error!,
                        key: const ValueKey('editor-validation-error'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: FantasyTextButton(
                      label: 'Abbrechen',
                      icon: Icons.close,
                      style: FantasyButtonStyle.iron,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FantasyTextButton(
                      key: const ValueKey('editor-save-fixed'),
                      label: 'Charakter speichern',
                      icon: Icons.save_outlined,
                      style: FantasyButtonStyle.woodGold,
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ],
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

  InventoryItemStats _catalogDefaults() {
    final catalog = SrdEquipmentCatalog.byId(widget.item?.catalogId ?? '');
    return catalog == null
        ? const InventoryItemStats()
        : InventoryItemStats.fromCatalog(catalog);
  }

  late final InventoryItemStats _initial =
      widget.item?.stats ?? _catalogDefaults();
  late InventoryItemKind _kind = _initial.kind;
  late bool? _stealthDisadvantage = _initial.stealthDisadvantage;
  late bool? _attunement = _initial.requiresAttunement;
  late final Map<String, TextEditingController> _values = {
    'priceCp': TextEditingController(text: _initial.priceCp?.toString() ?? ''),
    'weightLb': TextEditingController(
      text: _initial.weightLb?.toString() ?? '',
    ),
    'damage': TextEditingController(text: _initial.damage ?? ''),
    'damageType': TextEditingController(text: _initial.damageType ?? ''),
    'versatileDamage': TextEditingController(
      text: _initial.versatileDamage ?? '',
    ),
    'weaponProperties': TextEditingController(
      text: _initial.weaponProperties.join(', '),
    ),
    'mastery': TextEditingController(text: _initial.mastery ?? ''),
    'rangeNormalFt': TextEditingController(
      text: _initial.rangeNormalFt?.toString() ?? '',
    ),
    'rangeLongFt': TextEditingController(
      text: _initial.rangeLongFt?.toString() ?? '',
    ),
    'ammunitionType': TextEditingController(
      text: _initial.ammunitionType ?? '',
    ),
    'armorBaseAc': TextEditingController(
      text: _initial.armorBaseAc?.toString() ?? '',
    ),
    'dexCap': TextEditingController(text: _initial.dexCap?.toString() ?? ''),
    'strengthMin': TextEditingController(
      text: _initial.strengthMin?.toString() ?? '',
    ),
    'rarity': TextEditingController(text: _initial.rarity ?? ''),
    'charges': TextEditingController(text: _initial.charges?.toString() ?? ''),
    'maxCharges': TextEditingController(
      text: _initial.maxCharges?.toString() ?? '',
    ),
    'effect': TextEditingController(text: _initial.effect ?? ''),
  };

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _description.dispose();
    for (final controller in _values.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _textValue(String key) {
    final value = _values[key]!.text.trim();
    return value.isEmpty ? null : value;
  }

  int? _intValue(String key) {
    final value = _textValue(key);
    return value == null ? null : int.parse(value);
  }

  double? _doubleValue(String key) {
    final value = _textValue(key);
    return value == null ? null : double.parse(value.replaceAll(',', '.'));
  }

  Widget _itemText(String key, String label, {int lines = 1}) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: TextFormField(
      key: ValueKey('item-stat-$key'),
      controller: _values[key],
      maxLines: lines,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          (value?.length ?? 0) > 2000 ? 'Maximal 2000 Zeichen.' : null,
    ),
  );

  Widget _itemNumber(
    String key,
    String label, {
    bool decimal = false,
    int max = 1000000,
  }) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: TextFormField(
      key: ValueKey('item-stat-$key'),
      controller: _values[key],
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      decoration: InputDecoration(labelText: label),
      validator: (raw) {
        final value = raw?.trim() ?? '';
        if (value.isEmpty) return null;
        final parsed = decimal
            ? double.tryParse(value.replaceAll(',', '.'))
            : int.tryParse(value)?.toDouble();
        if (parsed == null || !parsed.isFinite || parsed < 0 || parsed > max) {
          return 'Ungültiger nicht-negativer Wert.';
        }
        return null;
      },
    ),
  );

  Widget _optionalFlag(
    String label,
    bool? value,
    void Function(bool?) onChanged,
  ) => DropdownButtonFormField<bool?>(
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: const [
      DropdownMenuItem<bool?>(value: null, child: Text('Unbekannt')),
      DropdownMenuItem<bool?>(value: true, child: Text('Ja')),
      DropdownMenuItem<bool?>(value: false, child: Text('Nein')),
    ],
    onChanged: (next) => setState(() => onChanged(next)),
  );

  InventoryItemStats _buildStats() {
    return InventoryItemStats.fromJson({
      'kind': _kind.name,
      if (_intValue('priceCp') != null) 'priceCp': _intValue('priceCp'),
      if (_doubleValue('weightLb') != null)
        'weightLb': _doubleValue('weightLb'),
      if (_textValue('damage') != null) 'damage': _textValue('damage'),
      if (_textValue('damageType') != null)
        'damageType': _textValue('damageType'),
      if (_textValue('versatileDamage') != null)
        'versatileDamage': _textValue('versatileDamage'),
      'weaponProperties': _values['weaponProperties']!.text
          .split(',')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList(),
      if (_textValue('mastery') != null) 'mastery': _textValue('mastery'),
      if (_intValue('rangeNormalFt') != null)
        'rangeNormalFt': _intValue('rangeNormalFt'),
      if (_intValue('rangeLongFt') != null)
        'rangeLongFt': _intValue('rangeLongFt'),
      if (_textValue('ammunitionType') != null)
        'ammunitionType': _textValue('ammunitionType'),
      if (_intValue('armorBaseAc') != null)
        'armorBaseAc': _intValue('armorBaseAc'),
      if (_intValue('dexCap') != null) 'dexCap': _intValue('dexCap'),
      if (_intValue('strengthMin') != null)
        'strengthMin': _intValue('strengthMin'),
      if (_stealthDisadvantage != null)
        'stealthDisadvantage': _stealthDisadvantage,
      if (_textValue('rarity') != null) 'rarity': _textValue('rarity'),
      if (_attunement != null) 'requiresAttunement': _attunement,
      if (_intValue('charges') != null) 'charges': _intValue('charges'),
      if (_intValue('maxCharges') != null)
        'maxCharges': _intValue('maxCharges'),
      if (_textValue('effect') != null) 'effect': _textValue('effect'),
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.item == null ? 'Gegenstand hinzufügen' : 'Gegenstand bearbeiten',
    ),
    content: SizedBox(
      width: 530,
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                validator: (value) {
                  final count = int.tryParse(value ?? '');
                  return count == null || count < 1 || count > 1000000
                      ? 'Anzahl zwischen 1 und 1000000.'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<InventoryItemKind>(
                key: const ValueKey('item-stat-kind'),
                initialValue: _kind,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Gegenstandsart'),
                items: [
                  for (final kind in InventoryItemKind.values)
                    DropdownMenuItem(value: kind, child: Text(kind.label)),
                ],
                onChanged: (next) => setState(() {
                  if (next != null) _kind = next;
                }),
              ),
              const SizedBox(height: 8),
              const Text(
                'Individuelle Werte werden einzeln gespeichert. Änderungen '
                'ersetzen noch keine SRD-Kampfberechnung.',
                style: TextStyle(fontSize: 12),
              ),
              _itemNumber('priceCp', 'Preis (Kupfermünzen)'),
              _itemNumber('weightLb', 'Gewicht (Pfund)', decimal: true),
              if (_kind == InventoryItemKind.weapon ||
                  _kind == InventoryItemKind.ammunition) ...[
                _itemText('damage', 'Schadenswürfel (z. B. 1d8)'),
                _itemText('damageType', 'Schadensart'),
                _itemText('versatileDamage', 'Vielseitiger Schaden'),
                _itemText('weaponProperties', 'Waffeneigenschaften (Kommas)'),
                _itemText('mastery', 'Waffenmeisterschaft'),
                _itemNumber('rangeNormalFt', 'Normale Reichweite (Fuß)'),
                _itemNumber('rangeLongFt', 'Maximale Reichweite (Fuß)'),
                _itemText('ammunitionType', 'Munitionstyp'),
              ],
              if (_kind == InventoryItemKind.armor ||
                  _kind == InventoryItemKind.shield) ...[
                _itemNumber(
                  'armorBaseAc',
                  _kind == InventoryItemKind.shield
                      ? 'Rüstungsklassen-Bonus'
                      : 'Basis-Rüstungsklasse',
                  max: 50,
                ),
                _itemNumber(
                  'dexCap',
                  'Maximaler Geschicklichkeitsbonus',
                  max: 50,
                ),
                _itemNumber('strengthMin', 'Stärkemindestwert', max: 30),
                _optionalFlag(
                  'Nachteil auf Heimlichkeit',
                  _stealthDisadvantage,
                  (next) => _stealthDisadvantage = next,
                ),
              ],
              if (_kind == InventoryItemKind.magic ||
                  _kind == InventoryItemKind.consumable) ...[
                _itemText('rarity', 'Seltenheit'),
                _optionalFlag(
                  'Einstimmung notwendig',
                  _attunement,
                  (next) => _attunement = next,
                ),
                _itemNumber('charges', 'Verbleibende Ladungen'),
                _itemNumber('maxCharges', 'Maximale Ladungen'),
              ],
              _itemText('effect', 'Eigene Wirkung / Wirkungshinweis', lines: 2),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Beschreibung (nur Freitext)',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      FantasyTextButton(
        key: const ValueKey('inventory-item-cancel'),
        label: 'Abbrechen',
        style: FantasyButtonStyle.iron,
        onPressed: () => Navigator.pop(context),
      ),
      FantasyTextButton(
        key: const ValueKey('inventory-item-save'),
        label: 'Speichern',
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          try {
            final stats = _buildStats();
            Navigator.pop(
              context,
              InventoryItem(
                id: widget.item?.id ?? const Uuid().v4(),
                name: _name.text.trim(),
                quantity: int.parse(_quantity.text),
                description: _description.text.trim(),
                catalogId: _name.text.trim() == widget.item?.name
                    ? (widget.item?.catalogId ?? '')
                    : '',
                stats: stats,
              ),
            );
          } on FormatException catch (error) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error.message)));
          }
        },
      ),
    ],
  );
}
