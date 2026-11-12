import 'srd_spell_catalog.dart';

/// Strict catalogue identity for the read-only Wall of Fire previews.
///
/// These metadata values match the SRD 5.2.1 Wall of Fire entry (CC BY 4.0).
/// This check prevents a publicly constructed spell snapshot with altered
/// casting, components, classes, duration or concentration from being treated
/// as the catalogued spell. It does not authorize a cast or prove that the
/// entire spell effect has been implemented.
/// Source: https://www.dndbeyond.com/srd
class SrdWallOfFireCatalogIdentity {
  const SrdWallOfFireCatalogIdentity._();

  static void validate(SrdSpellDefinition spell) {
    final classes = spell.classes;
    if (spell.id != 'spell-wall-of-fire' ||
        spell.name != 'Wall of Fire' ||
        spell.level != 4 ||
        spell.school != 'Evocation' ||
        classes.length != 3 ||
        classes[0] != 'Druid' ||
        classes[1] != 'Sorcerer' ||
        classes[2] != 'Wizard' ||
        spell.castingTime != 'Action' ||
        spell.range != '120 feet' ||
        spell.components != 'V, S, M (a piece of charcoal)' ||
        spell.duration != 'Concentration, up to 1 minute' ||
        !spell.verbal ||
        !spell.somatic ||
        !spell.material ||
        !spell.concentration ||
        spell.ritual) {
      throw const FormatException(
        'Keine vollständige bestätigte Wall-of-Fire-Katalogidentität.',
      );
    }
  }
}
