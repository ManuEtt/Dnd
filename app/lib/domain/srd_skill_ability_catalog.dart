/// German UI labels and default abilities for all 18 skills listed in
/// D&D SRD 5.2.1 ("Playing the Game" / "Skills" table).
///
/// The order and spelling deliberately match [srdSkills] in
/// srd_character_classes.dart, used by class-specific skill selection.
/// A skill's normal ability is only the default; the game master may
/// explicitly call for a different ability in a particular situation.
/// These entries never roll dice or change proficiency.
const srdSkillAbilities = <({String name, String ability})>[
  (name: 'Akrobatik', ability: 'dexterity'),
  (name: 'Mit Tieren umgehen', ability: 'wisdom'),
  (name: 'Arkane Kunde', ability: 'intelligence'),
  (name: 'Athletik', ability: 'strength'),
  (name: 'Täuschen', ability: 'charisma'),
  (name: 'Geschichte', ability: 'intelligence'),
  (name: 'Motiv erkennen', ability: 'wisdom'),
  (name: 'Einschüchtern', ability: 'charisma'),
  (name: 'Nachforschungen', ability: 'intelligence'),
  (name: 'Heilkunde', ability: 'wisdom'),
  (name: 'Naturkunde', ability: 'intelligence'),
  (name: 'Wahrnehmung', ability: 'wisdom'),
  (name: 'Auftreten', ability: 'charisma'),
  (name: 'Überzeugen', ability: 'charisma'),
  (name: 'Religion', ability: 'intelligence'),
  (name: 'Fingerfertigkeit', ability: 'dexterity'),
  (name: 'Heimlichkeit', ability: 'dexterity'),
  (name: 'Überlebenskunst', ability: 'wisdom'),
];

/// The old character-sheet mock-up called the Medicine skill "Medizin",
/// whereas confirmed class creation and the canonical SRD roster use
/// "Heilkunde". Historical saves must not lose that trained skill.
/// Never silently rewrite saved data or assign proficiency to a new skill.
const srdLegacySkillAliases = <String, String>{
  'Heilkunde': 'Medizin',
};
