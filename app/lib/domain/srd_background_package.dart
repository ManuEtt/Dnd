import 'ability_generation.dart';
import 'models.dart';
import 'srd_character_classes.dart';
import 'srd_equipment_catalog.dart';
import 'starting_equipment_import.dart';

/// An explicit, one-time SRD 5.2.1 background gear choice.
/// Feat choices/effects are not claimed to be automated by this record.
class SrdBackgroundPackageChoice {
  SrdBackgroundPackageChoice({
    required this.background,
    required this.takeGold,
    this.gamingSetCatalogId = '',
    this.holySymbolCatalogId = '',
  }) {
    _validate();
  }

  final SrdBackground background;
  final bool takeGold;
  final String gamingSetCatalogId;

  /// Only Acolyte equipment A may select a concrete holy-symbol catalog ID.
  /// Omitted in pre-existing saved backgrounds for backwards compatibility.
  final String holySymbolCatalogId;

  static const _skills = <SrdBackground, List<String>>{
    SrdBackground.acolyte: ['Motiv erkennen', 'Religion'],
    SrdBackground.criminal: ['Fingerfertigkeit', 'Heimlichkeit'],
    SrdBackground.sage: ['Arkane Kunde', 'Geschichte'],
    SrdBackground.soldier: ['Athletik', 'Einschüchtern'],
  };

  static const _feat = <SrdBackground, String>{
    SrdBackground.acolyte: 'Magieinitiierter (Kleriker)',
    SrdBackground.criminal: 'Wachsam',
    SrdBackground.sage: 'Magieinitiierter (Magier)',
    SrdBackground.soldier: 'Wilder Angreifer',
  };

  static const _kit = <SrdBackground, List<SrdStartingItem>>{
    SrdBackground.acolyte: [
      SrdStartingItem('Kalligrafenwerkzeug'),
      SrdStartingItem('Buch (Gebete)'),
      SrdStartingItem('Heiliges Symbol (Auswahl offen)'),
      SrdStartingItem('Pergament', 10),
      SrdStartingItem('Robe'),
    ],
    SrdBackground.criminal: [
      SrdStartingItem('Dolch', 2),
      SrdStartingItem('Diebeswerkzeug'),
      SrdStartingItem('Brecheisen'),
      SrdStartingItem('Beutel', 2),
      SrdStartingItem('Reisekleidung'),
    ],
    SrdBackground.sage: [
      SrdStartingItem('Kampfstab'),
      SrdStartingItem('Kalligrafenwerkzeug'),
      SrdStartingItem('Buch (Geschichte)'),
      SrdStartingItem('Pergament', 8),
      SrdStartingItem('Robe'),
    ],
    SrdBackground.soldier: [
      SrdStartingItem('Speer'),
      SrdStartingItem('Kurzbogen'),
      SrdStartingItem('Pfeil', 20),
      SrdStartingItem('Spielset (nach Wahl)'),
      SrdStartingItem('Heilerausrüstung'),
      SrdStartingItem('Köcher'),
      SrdStartingItem('Reisekleidung'),
    ],
  };

  static const _kitGold = <SrdBackground, int>{
    SrdBackground.acolyte: 8,
    SrdBackground.criminal: 16,
    SrdBackground.sage: 8,
    SrdBackground.soldier: 14,
  };

  static List<EquipmentEntry> get gamingSets => List.unmodifiable(
    SrdEquipmentCatalog.all.where(
      (entry) => entry.category == EquipmentCategory.game,
    ),
  );

  static const _holySymbolIds = <String>{
    'item-holy-symbol-amulet',
    'item-holy-symbol-emblem',
    'item-holy-symbol-reliquary',
  };

  static List<EquipmentEntry> get holySymbols => List.unmodifiable(
    SrdEquipmentCatalog.all.where(
      (entry) => _holySymbolIds.contains(entry.id),
    ),
  );

  String itemDisplayName(SrdStartingItem item) {
    if (item.name == 'Spielset (nach Wahl)') return toolProficiency;
    if (item.name == 'Heiliges Symbol (Auswahl offen)' &&
        holySymbolCatalogId.isNotEmpty) {
      return SrdEquipmentCatalog.byId(holySymbolCatalogId)!.name;
    }
    return item.name;
  }

  List<String> get skills => List.unmodifiable(_skills[background]!);
  String get originFeat => _feat[background]!;
  int get startingGold => takeGold ? 50 : _kitGold[background]!;
  String get toolProficiency => background == SrdBackground.soldier
      ? SrdEquipmentCatalog.byId(gamingSetCatalogId)!.name
      : background == SrdBackground.criminal
      ? 'Diebeswerkzeug'
      : 'Kalligrafenwerkzeug';
  List<SrdStartingItem> get kitItems => List.unmodifiable(
    takeGold ? const <SrdStartingItem>[] : _kit[background]!,
  );

  /// Returns false for Magic Initiate; choice of cantrips, spell, ability
  /// and actual spellcasting implementation must be completed separately.
  bool get requiresFeatSpellChoices =>
      background == SrdBackground.acolyte || background == SrdBackground.sage;

  void _validate() {
    if (background == SrdBackground.soldier) {
      if (!gamingSets.any((set) => set.id == gamingSetCatalogId)) {
        throw const FormatException(
          'Für den Soldaten ein konkretes SRD-Spielset wählen.',
        );
      }
    } else if (gamingSetCatalogId.isNotEmpty) {
      throw const FormatException('Dieser Hintergrund erhält kein Spielset.');
    }
    if (holySymbolCatalogId.isNotEmpty &&
        (background != SrdBackground.acolyte ||
            takeGold ||
            !holySymbols.any((symbol) => symbol.id == holySymbolCatalogId))) {
      throw const FormatException('Ungültige Auswahl des Heiligen Symbols.');
    }
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'background': background.name,
    'takeGold': takeGold,
    if (gamingSetCatalogId.isNotEmpty) 'gamingSetCatalogId': gamingSetCatalogId,
    if (holySymbolCatalogId.isNotEmpty) 'holySymbolCatalogId': holySymbolCatalogId,
  };

  factory SrdBackgroundPackageChoice.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1 ||
        json['background'] is! String ||
        json['takeGold'] is! bool ||
        (json['gamingSetCatalogId'] != null &&
            json['gamingSetCatalogId'] is! String) ||
        (json['holySymbolCatalogId'] != null &&
            json['holySymbolCatalogId'] is! String)) {
      throw const FormatException('Ungültige SRD-Hintergrundpaket-Version.');
    }
    final values = SrdBackground.values.where(
      (entry) => entry.name == json['background'],
    );
    if (values.length != 1) {
      throw const FormatException('Unbekannter SRD-Hintergrund.');
    }
    return SrdBackgroundPackageChoice(
      background: values.single,
      takeGold: json['takeGold'] as bool,
      gamingSetCatalogId: (json['gamingSetCatalogId'] as String?) ?? '',
      holySymbolCatalogId: (json['holySymbolCatalogId'] as String?) ?? '',
    );
  }

  /// Proposes all safe benefits together, then the editor commits them
  /// atomically after the user's explicit acceptance. No hidden reroll,
  /// feat effect, spell or duplicate starting package is granted.
  HeroCharacter applyTo(
    HeroCharacter hero, {
    required String Function() nextId,
  }) {
    if (hero.level != 1 ||
        hero.background != background.label ||
        hero.startingBackgroundPackage != null) {
      throw const FormatException(
        'Hintergrundpaket nur für einen neuen passenden Stufe-1-Helden.',
      );
    }
    // Older saves without this optional choice remain loadable and unchanged,
    // but a *new* Acolyte equipment-A grant must resolve the actual item.
    if (background == SrdBackground.acolyte &&
        !takeGold &&
        holySymbolCatalogId.isEmpty) {
      throw const FormatException(
        'Vor dem Übernehmen ein konkretes Heiliges Symbol wählen.',
      );
    }
    final duplicates = skills.where(hero.skills.contains).toList();
    if (duplicates.isNotEmpty) {
      throw FormatException(
        'Fertigkeit bereits aus anderer Quelle vorhanden: '
        '${duplicates.join(', ')}. Bitte die Klassenwahl anpassen.',
      );
    }
    final additions = <InventoryItem>[];
    if (!takeGold) {
      for (final item in kitItems) {
        if (item.name == 'Spielset (nach Wahl)') {
          final selected = SrdEquipmentCatalog.byId(gamingSetCatalogId)!;
          additions.add(
            InventoryItem(
              id: nextId(),
              name: selected.name,
              catalogId: selected.id,
              stats: InventoryItemStats.fromCatalog(selected),
            ),
          );
        } else if (item.name == 'Heiliges Symbol (Auswahl offen)') {
          final selected = SrdEquipmentCatalog.byId(holySymbolCatalogId)!;
          additions.add(
            InventoryItem(
              id: nextId(),
              name: selected.name,
              catalogId: selected.id,
              description: selected.note ?? '',
              stats: InventoryItemStats.fromCatalog(selected),
            ),
          );
        } else {
          additions.add(
            StartingEquipmentImport.fromStartingItem(item, nextId()),
          );
        }
      }
    }
    final featureLabels = <String>[
      'Herkunftstalent: $originFeat (Regelwirkung noch nicht automatisiert)',
      'Werkzeugübung: $toolProficiency',
    ];
    return hero.copyWith(
      skills: [...hero.skills, ...skills],
      features: [
        ...hero.features,
        for (final label in featureLabels)
          if (!hero.features.contains(label)) label,
      ],
      inventory: [...hero.inventory, ...additions],
      gold: (hero.gold ?? 0) + startingGold,
      startingBackgroundPackage: this,
    );
  }
}
