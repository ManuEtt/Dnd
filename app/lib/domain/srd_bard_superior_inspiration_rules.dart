import 'class_resource_rules.dart';
import 'models.dart';
import 'srd_character_classes.dart';

/// SRD 5.2.1, Bard 18: Superior Inspiration (CC BY 4.0).
///
/// At an actual Initiative roll, regain expended Bardic Inspiration uses until
/// two uses remain. Never create new uses beyond the confirmed resource maximum
/// or restore on unrelated rounds, a skill roll, or narrative text.
///
/// https://www.dndbeyond.com/srd — Classes / Bard / Superior Inspiration
class SrdBardSuperiorInspirationRules {
  const SrdBardSuperiorInspirationRules._();

  static SrdBardSuperiorInspirationResult onInitiative(HeroCharacter hero) {
    if (!_hasConfirmedClassLevels(hero) ||
        ClassResourceRules.level(hero, 'Barde') < 18) {
      return SrdBardSuperiorInspirationResult(hero: hero, recovered: 0);
    }
    if (hero.abilities['charisma'] == null) {
      throw StateError(
        'Charisma muss für Überlegene Inspiration bestätigt sein.',
      );
    }
    final maximum = ClassResourceRules.maximum(hero, 'bardicInspiration');
    final remaining = ClassResourceRules.remaining(hero, 'bardicInspiration');
    final target = maximum < 2 ? maximum : 2;
    if (remaining >= target) {
      return SrdBardSuperiorInspirationResult(hero: hero, recovered: 0);
    }
    final spent = maximum - target;
    final resources = {...hero.spentClassResources};
    if (spent == 0) {
      resources.remove('bardicInspiration');
    } else {
      resources['bardicInspiration'] = spent;
    }
    return SrdBardSuperiorInspirationResult(
      hero: hero.copyWith(spentClassResources: resources),
      recovered: target - remaining,
    );
  }

  /// An automatic feature cannot grant resources from contradictory legacy
  /// class data. Leave that snapshot untouched and preserve the initiative;
  /// this helper neither validates nor rolls the surrounding combat itself.
  static bool _hasConfirmedClassLevels(HeroCharacter hero) {
    final primary = findSrdClass(hero.className)?.name;
    final secondary = hero.hasSecondClass
        ? findSrdClass(hero.secondaryClassName)?.name
        : null;
    return primary != null &&
        hero.level >= 1 &&
        hero.level <= 20 &&
        hero.secondaryClassLevel >= 0 &&
        hero.secondaryClassLevel < hero.level &&
        (hero.hasSecondClass
            ? hero.secondaryClassLevel > 0 &&
                  secondary != null &&
                  secondary != primary
            : hero.secondaryClassLevel == 0);
  }
}

class SrdBardSuperiorInspirationResult {
  const SrdBardSuperiorInspirationResult({
    required this.hero,
    required this.recovered,
  });

  final HeroCharacter hero;
  final int recovered;
}
