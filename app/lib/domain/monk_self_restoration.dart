import 'class_resource_rules.dart';
import 'models.dart';

/// SRD 5.2.1, Monk 10: Self-Restoration.
/// Exactly one eligible condition can end at the end of the Monk's own turn.
/// Multiple eligible conditions require an explicit player selection: choosing
/// one silently would invent a character decision. No focus/action is spent.
class MonkSelfRestoration {
  const MonkSelfRestoration._();

  static const curable = <String>{'bezaubert', 'verängstigt', 'vergiftet'};

  static bool unlocked(HeroCharacter hero) =>
      ClassResourceRules.level(hero, 'Mönch') >= 10;

  static List<String> choices(HeroCharacter hero) =>
      !unlocked(hero) ? const [] : List.unmodifiable(
        hero.conditions.where(curable.contains).toSet(),
      );

  static void validateChoice(HeroCharacter hero, String choice) {
    if (!choices(hero).contains(choice)) {
      throw StateError('Selbstwiederherstellung kann diesen Zustand nicht beenden.');
    }
  }

  static SelfRestorationResult atEndOfTurn(HeroCharacter hero,
      {String choice = ''}) {
    final eligible = choices(hero);
    // A condition may have been removed by a separately confirmed effect
    // after the player made the choice. Do not crash the turn on stale data.
    final validChoice = choice.isNotEmpty && eligible.contains(choice);
    final selected = validChoice ? choice :
        eligible.length == 1 ? eligible.single : '';
    if (selected.isEmpty) {
      return SelfRestorationResult(hero: hero, removed: '',
          choiceRequired: eligible.length > 1);
    }
    return SelfRestorationResult(
      hero: hero.copyWith(conditions: [
        for (final condition in hero.conditions)
          if (condition != selected) condition,
      ]),
      removed: selected,
      choiceRequired: false,
    );
  }
}

class SelfRestorationResult {
  const SelfRestorationResult({required this.hero, required this.removed,
    required this.choiceRequired});
  final HeroCharacter hero;
  final String removed;
  final bool choiceRequired;
}
