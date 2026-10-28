import 'srd_character_classes.dart';
import 'starting_hit_points.dart';

/// Common SRD 5.2.1 class-start gate; never updates a saved hero.
/// Other required class features, feats and spells need separate validation.
class SrdFirstClassStartValidation {
  const SrdFirstClassStartValidation._();

  static StartingHitPoints? validate({
    required SrdClassSelection selection,
    required bool isNewCharacter,
    required int? characterLevel,
    required int? constitutionScore,
    required bool allowEquipment,
  }) {
    if (!isNewCharacter) return null;
    if (characterLevel != 1) {
      throw const FormatException(
        'Die erste Klassenwahl erfordert einen neuen Charakter der Stufe 1.',
      );
    }
    if (constitutionScore == null ||
        constitutionScore < 1 ||
        constitutionScore > 30) {
      throw const FormatException(
        'Bestätige zuerst einen gültigen Konstitutionswert '
        'für die Start-Trefferpunkte.',
      );
    }
    if (allowEquipment && selection.startingKit == null) {
      throw const FormatException(
        'Wähle die Startausrüstung oder die Startgold-Alternative deiner Klasse.',
      );
    }
    if (!allowEquipment && selection.startingKit != null) {
      throw const FormatException(
        'Die Startausrüstung kann hier nicht erneut vergeben werden.',
      );
    }
    return StartingHitPoints.propose(
      className: selection.characterClass.name,
      constitutionScore: constitutionScore,
      characterLevel: characterLevel,
    );
  }
}
