/// Starting class choices from the Creative Commons D&D SRD 5.2.1, "Classes".
/// https://www.dndbeyond.com/srd
/// Only level-1 single-class proficiencies are implemented here. Multiclass
/// proficiencies, origin feats, tool choices and class features are separate.
import 'models.dart';

class SrdStartingItem {
  const SrdStartingItem(this.name, [this.quantity = 1]);
  final String name;
  final int quantity;
}

class SrdStartingKit {
  const SrdStartingKit(this.label, this.items, this.gold);
  final String label;
  final List<SrdStartingItem> items;
  final int gold;
}

class SrdCharacterClass {
  const SrdCharacterClass({
    required this.name,
    required this.hitDie,
    required this.savingThrows,
    required this.skillChoices,
    required this.skillCount,
    required this.kits,
    required this.armorTraining,
  });

  final String name;
  final int hitDie;
  /// Canonical engine keys, not German labels.
  final List<String> savingThrows;
  /// German labels consistent with the existing campaign engine.
  final List<String> skillChoices;
  final int skillCount;
  final List<SrdStartingKit> kits;
  /// Informational only: armor class depends on actual equipped armor.
  final String armorTraining;

  /// Exactly [skillCount] distinct eligible class skills are required.
  void validateSkills(Iterable<String> selected) {
    final values = selected.toList();
    if (values.length != skillCount ||
        values.toSet().length != values.length ||
        values.any((item) => !skillChoices.contains(item))) {
      throw FormatException(
        '$name benötigt genau $skillCount unterschiedliche Fertigkeiten '
        'aus seiner Klassenliste.',
      );
    }
  }
}

/// All 18 SRD skills with German labels. Do not replace known existing labels.
const srdSkills = <String>[
  'Akrobatik', 'Mit Tieren umgehen', 'Arkane Kunde', 'Athletik',
  'Täuschen', 'Geschichte', 'Motiv erkennen', 'Einschüchtern',
  'Nachforschungen', 'Heilkunde', 'Naturkunde', 'Wahrnehmung',
  'Auftreten', 'Überzeugen', 'Religion', 'Fingerfertigkeit',
  'Heimlichkeit', 'Überlebenskunst',
];

const _all = srdSkills;
const _barbarian = ['Mit Tieren umgehen', 'Athletik', 'Einschüchtern', 'Naturkunde', 'Wahrnehmung', 'Überlebenskunst'];
const _cleric = ['Geschichte', 'Motiv erkennen', 'Heilkunde', 'Überzeugen', 'Religion'];
const _druid = ['Arkane Kunde', 'Mit Tieren umgehen', 'Motiv erkennen', 'Heilkunde', 'Naturkunde', 'Wahrnehmung', 'Religion', 'Überlebenskunst'];
const _fighter = ['Akrobatik', 'Mit Tieren umgehen', 'Athletik', 'Geschichte', 'Motiv erkennen', 'Einschüchtern', 'Überzeugen', 'Wahrnehmung', 'Überlebenskunst'];
const _monk = ['Akrobatik', 'Athletik', 'Geschichte', 'Motiv erkennen', 'Religion', 'Heimlichkeit'];
const _paladin = ['Athletik', 'Motiv erkennen', 'Einschüchtern', 'Heilkunde', 'Überzeugen', 'Religion'];
const _ranger = ['Mit Tieren umgehen', 'Athletik', 'Motiv erkennen', 'Nachforschungen', 'Naturkunde', 'Wahrnehmung', 'Heimlichkeit', 'Überlebenskunst'];
const _rogue = ['Akrobatik', 'Athletik', 'Täuschen', 'Motiv erkennen', 'Einschüchtern', 'Nachforschungen', 'Wahrnehmung', 'Überzeugen', 'Fingerfertigkeit', 'Heimlichkeit'];
const _sorcerer = ['Arkane Kunde', 'Täuschen', 'Motiv erkennen', 'Einschüchtern', 'Überzeugen', 'Religion'];
const _warlock = ['Arkane Kunde', 'Täuschen', 'Geschichte', 'Einschüchtern', 'Nachforschungen', 'Naturkunde', 'Religion'];
const _wizard = ['Arkane Kunde', 'Geschichte', 'Motiv erkennen', 'Nachforschungen', 'Heilkunde', 'Naturkunde', 'Religion'];

/// Full starting-equipment package is optional, explicitly confirmed in UI.
/// "B" is starting gold, not an item. Fighter offers two item packages (A/B)
/// and gold-only option C. The app does not automatically equip armor/weapons.
const srdCharacterClasses = <SrdCharacterClass>[
  SrdCharacterClass(name: 'Barbar', hitDie: 12, savingThrows: ['strength', 'constitution'], skillChoices: _barbarian, skillCount: 2, armorTraining: 'Leichte und mittelschwere Rüstung, Schilde', kits: [
    SrdStartingKit('A – Ausrüstung', [SrdStartingItem('Großaxt'), SrdStartingItem('Handaxt', 4), SrdStartingItem('Entdeckerausrüstung')], 15),
    SrdStartingKit('B – Startgold', [], 75),
  ]),
  SrdCharacterClass(name: 'Barde', hitDie: 8, savingThrows: ['dexterity', 'charisma'], skillChoices: _all, skillCount: 3, armorTraining: 'Leichte Rüstung', kits: [
    SrdStartingKit('A – Ausrüstung', [SrdStartingItem('Lederrüstung'), SrdStartingItem('Dolch', 2), SrdStartingItem('Musikinstrument (nach Wahl)'), SrdStartingItem('Unterhalterausrüstung')], 19),
    SrdStartingKit('B – Startgold', [], 90),
  ]),
  SrdCharacterClass(name: 'Kleriker', hitDie: 8, savingThrows: ['wisdom', 'charisma'], skillChoices: _cleric, skillCount: 2, armorTraining: 'Leichte und mittelschwere Rüstung, Schilde', kits: [
    SrdStartingKit('A – Ausrüstung', [SrdStartingItem('Kettenhemd'), SrdStartingItem('Schild'), SrdStartingItem('Streitkolben'), SrdStartingItem('Heiliges Symbol'), SrdStartingItem('Priesterausrüstung')], 7),
    SrdStartingKit('B – Startgold', [], 110),
  ]),
  SrdCharacterClass(name: 'Druide', hitDie: 8, savingThrows: ['intelligence', 'wisdom'], skillChoices: _druid, skillCount: 2, armorTraining: 'Leichte Rüstung, Schilde', kits: [
    SrdStartingKit('A – Ausrüstung', [SrdStartingItem('Lederrüstung'), SrdStartingItem('Schild'), SrdStartingItem('Sichel'), SrdStartingItem('Druidischer Fokus (Kampfstab)'), SrdStartingItem('Entdeckerausrüstung'), SrdStartingItem('Kräuterkunde-Ausrüstung')], 9),
    SrdStartingKit('B – Startgold', [], 50),
  ]),
  SrdCharacterClass(name: 'Kämpfer', hitDie: 10, savingThrows: ['strength', 'constitution'], skillChoices: _fighter, skillCount: 2, armorTraining: 'Leichte, mittelschwere und schwere Rüstung, Schilde', kits: [
    SrdStartingKit('A – Schwere Ausrüstung', [SrdStartingItem('Kettenpanzer'), SrdStartingItem('Zweihänder'), SrdStartingItem('Flegel'), SrdStartingItem('Wurfspeer', 8), SrdStartingItem('Gewölbeforscherausrüstung')], 4),
    SrdStartingKit('B – Leichte Ausrüstung', [SrdStartingItem('Beschlagene Lederrüstung'), SrdStartingItem('Krummsäbel'), SrdStartingItem('Kurzschwert'), SrdStartingItem('Langbogen'), SrdStartingItem('Pfeil', 20), SrdStartingItem('Köcher'), SrdStartingItem('Gewölbeforscherausrüstung')], 11),
    SrdStartingKit('C – Startgold', [], 155),
  ]),
  SrdCharacterClass(name: 'Mönch', hitDie: 8, savingThrows: ['strength', 'dexterity'], skillChoices: _monk, skillCount: 2, armorTraining: 'Keine', kits: [
    SrdStartingKit('A – Ausrüstung', [SrdStartingItem('Speer'), SrdStartingItem('Dolch', 5), SrdStartingItem('Handwerkszeug oder Musikinstrument (nach Wahl)'), SrdStartingItem('Entdeckerausrüstung')], 11),
    SrdStartingKit('B – Startgold', [], 50),
  ]),
  SrdCharacterClass(name: 'Paladin', hitDie: 10, savingThrows: ['wisdom', 'charisma'], skillChoices: _paladin, skillCount: 2, armorTraining: 'Leichte, mittelschwere und schwere Rüstung, Schilde', kits: [
    SrdStartingKit('A – Ausrüstung', [SrdStartingItem('Kettenpanzer'), SrdStartingItem('Schild'), SrdStartingItem('Langschwert'), SrdStartingItem('Wurfspeer', 6), SrdStartingItem('Heiliges Symbol'), SrdStartingItem('Priesterausrüstung')], 9),
    SrdStartingKit('B – Startgold', [], 150),
  ]),
  SrdCharacterClass(name: 'Waldläufer', hitDie: 10, savingThrows: ['strength', 'dexterity'], skillChoices: _ranger, skillCount: 3, armorTraining: 'Leichte und mittelschwere Rüstung, Schilde', kits: [
    SrdStartingKit('A – Ausrüstung', [SrdStartingItem('Beschlagene Lederrüstung'), SrdStartingItem('Krummsäbel'), SrdStartingItem('Kurzschwert'), SrdStartingItem('Langbogen'), SrdStartingItem('Pfeil', 20), SrdStartingItem('Köcher'), SrdStartingItem('Druidischer Fokus (Mistelkraut)'), SrdStartingItem('Entdeckerausrüstung')], 7),
    SrdStartingKit('B – Startgold', [], 150),
  ]),
  SrdCharacterClass(name: 'Schurke', hitDie: 8, savingThrows: ['dexterity', 'intelligence'], skillChoices: _rogue, skillCount: 4, armorTraining: 'Leichte Rüstung', kits: [
    SrdStartingKit('A – Ausrüstung', [SrdStartingItem('Lederrüstung'), SrdStartingItem('Dolch', 2), SrdStartingItem('Kurzschwert'), SrdStartingItem('Kurzbogen'), SrdStartingItem('Pfeil', 20), SrdStartingItem('Köcher'), SrdStartingItem('Diebeswerkzeug'), SrdStartingItem('Einbrecherausrüstung')], 8),
    SrdStartingKit('B – Startgold', [], 100),
  ]),
  SrdCharacterClass(name: 'Zauberer', hitDie: 6, savingThrows: ['constitution', 'charisma'], skillChoices: _sorcerer, skillCount: 2, armorTraining: 'Keine', kits: [
    SrdStartingKit('A – Ausrüstung', [SrdStartingItem('Speer'), SrdStartingItem('Dolch', 2), SrdStartingItem('Arkaner Fokus (Kristall)'), SrdStartingItem('Gewölbeforscherausrüstung')], 28),
    SrdStartingKit('B – Startgold', [], 50),
  ]),
  SrdCharacterClass(name: 'Hexenmeister', hitDie: 8, savingThrows: ['wisdom', 'charisma'], skillChoices: _warlock, skillCount: 2, armorTraining: 'Leichte Rüstung', kits: [
    SrdStartingKit('A – Ausrüstung', [SrdStartingItem('Lederrüstung'), SrdStartingItem('Sichel'), SrdStartingItem('Dolch', 2), SrdStartingItem('Arkaner Fokus (Kugel)'), SrdStartingItem('Buch (okkultes Wissen)'), SrdStartingItem('Gelehrtenausrüstung')], 15),
    SrdStartingKit('B – Startgold', [], 100),
  ]),
  SrdCharacterClass(name: 'Magier', hitDie: 6, savingThrows: ['intelligence', 'wisdom'], skillChoices: _wizard, skillCount: 2, armorTraining: 'Keine', kits: [
    SrdStartingKit('A – Ausrüstung', [SrdStartingItem('Dolch', 2), SrdStartingItem('Arkaner Fokus (Kampfstab)'), SrdStartingItem('Robe'), SrdStartingItem('Zauberbuch'), SrdStartingItem('Gelehrtenausrüstung')], 5),
    SrdStartingKit('B – Startgold', [], 55),
  ]),
];

/// Existing character names include feminine, umlaut ASCII and English forms.
SrdCharacterClass? findSrdClass(String raw) {
  final name = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  const aliases = <String, String>{
    'barbarin': 'Barbar', 'barbarian': 'Barbar',
    'bardin': 'Barde', 'bard': 'Barde',
    'klerikerin': 'Kleriker', 'cleric': 'Kleriker',
    'druidin': 'Druide', 'druid': 'Druide',
    'kämpferin': 'Kämpfer', 'kaempfer': 'Kämpfer', 'fighter': 'Kämpfer',
    'mönchin': 'Mönch', 'moench': 'Mönch', 'monk': 'Mönch',
    'waldläuferin': 'Waldläufer', 'waldlaeufer': 'Waldläufer', 'ranger': 'Waldläufer',
    'schurkin': 'Schurke', 'rogue': 'Schurke',
    'zauberin': 'Zauberer', 'sorcerer': 'Zauberer',
    'hexenmeisterin': 'Hexenmeister', 'warlock': 'Hexenmeister',
    'magierin': 'Magier', 'wizard': 'Magier',
  };
  final canonical = aliases[name]?.toLowerCase() ?? name;
  for (final candidate in srdCharacterClasses) {
    if (candidate.name.toLowerCase() == canonical) return candidate;
  }
  return null;
}

class SrdClassSelection {
  SrdClassSelection({
    required this.characterClass,
    required Iterable<String> skills,
    this.kitIndex,
  }) : skills = List.unmodifiable(skills) {
    characterClass.validateSkills(this.skills);
    if (kitIndex != null &&
        (kitIndex! < 0 || kitIndex! >= characterClass.kits.length)) {
      throw const FormatException('Ungültige Startausrüstung.');
    }
  }

  final SrdCharacterClass characterClass;
  final List<String> skills;
  final int? kitIndex;
  SrdStartingKit? get startingKit =>
      kitIndex == null ? null : characterClass.kits[kitIndex!];

  /// Applies *only* the selected fields; no implicit class features, armor
  /// class, spells, background proficiencies, or other effects are claimed.
  HeroCharacter applyTo(HeroCharacter existing, {bool replaceSkills = false}) {
    return existing.copyWith(
      className: characterClass.name,
      skills: replaceSkills ? skills : {...existing.skills, ...skills}.toList(),
      savingThrowProficiencies: replaceSkills
          ? characterClass.savingThrows
          : {...existing.savingThrowProficiencies, ...characterClass.savingThrows}.toList(),
    );
  }
}
