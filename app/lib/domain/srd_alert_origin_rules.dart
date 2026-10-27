import 'ability_generation.dart';
import 'models.dart';

/// SRD 5.2.1 Origin Feat: Alert / Wachsam – Initiative Proficiency.
///
/// An editable name, a free-text feature or a background field alone must not
/// grant the bonus. Only the explicit, previously confirmed SRD background
/// package for Criminal can establish the feat. Its other benefit, swapping
/// Initiative with a willing non-incapacitated ally after rolling, remains
/// unavailable until an authenticated multi-combatant flow exists.
class SrdAlertOriginRules {
  const SrdAlertOriginRules._();

  static bool hasInitiativeProficiency(HeroCharacter hero) {
    final choice = hero.startingBackgroundPackage;
    return choice != null &&
        choice.background == SrdBackground.criminal &&
        hero.background == SrdBackground.criminal.label;
  }
}
