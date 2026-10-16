import 'models.dart';
import 'rules_engine.dart';
import 'srd_character_classes.dart';

/// Safe, deterministic class feature resource accounting (SRD 5.2.1).
/// Does not claim to execute a feature's narrative, combat or spell effects.
/// A resource may be spent only by an explicit action and is never inferred
/// from an AI-generated sentence.
class ClassResourceRules {
  const ClassResourceRules._();

  static const supported = <String>{
    'rage', 'bardicInspiration', 'channelDivinityCleric',
    'wildShape', 'focusPoints', 'layOnHands',
    'channelDivinityPaladin', 'favoredEnemy', 'sorceryPoints',
  };

  static int level(HeroCharacter hero, String className) {
    final first = findSrdClass(hero.className)?.name == className
        ? hero.primaryClassLevel : 0;
    final second = hero.hasSecondClass &&
        findSrdClass(hero.secondaryClassName)?.name == className
        ? hero.secondaryClassLevel : 0;
    return first + second;
  }

  static int maximum(HeroCharacter hero, String resource) {
    switch (resource) {
      case 'rage':
        final l = level(hero, 'Barbar');
        if (l < 1) return 0;
        return l >= 17 ? 6 : l >= 12 ? 5 : l >= 6 ? 4 : l >= 3 ? 3 : 2;
      case 'bardicInspiration':
        if (level(hero, 'Barde') < 1) return 0;
        final charisma = hero.abilities['charisma'];
        if (charisma == null) return 0; // Unconfirmed; fail closed.
        final mod = RulesEngine.abilityModifier(charisma);
        return mod < 1 ? 1 : mod;
      case 'channelDivinityCleric':
        final l = level(hero, 'Kleriker');
        return l < 2 ? 0 : l >= 18 ? 4 : l >= 6 ? 3 : 2;
      case 'wildShape':
        final l = level(hero, 'Druide');
        return l < 2 ? 0 : l >= 17 ? 4 : l >= 6 ? 3 : 2;
      case 'focusPoints':
        final l = level(hero, 'Mönch');
        return l < 2 ? 0 : l;
      case 'layOnHands':
        return 5 * level(hero, 'Paladin');
      case 'channelDivinityPaladin':
        final l = level(hero, 'Paladin');
        return l < 3 ? 0 : l >= 11 ? 3 : 2;
      case 'favoredEnemy':
        final l = level(hero, 'Waldläufer');
        return l < 1 ? 0 : l >= 17 ? 6 : l >= 13 ? 5 :
            l >= 9 ? 4 : l >= 5 ? 3 : 2;
      case 'sorceryPoints':
        final l = level(hero, 'Zauberer');
        return l < 2 ? 0 : l;
      default:
        throw ArgumentError.value(resource, 'resource', 'Unbekannte Ressource');
    }
  }

  static void validate(HeroCharacter hero) {
    for (final e in hero.spentClassResources.entries) {
      if (!supported.contains(e.key) || e.value < 0 ||
          e.value > maximum(hero, e.key)) {
        throw const FormatException('Ungültige SRD-Klassenressourcen.');
      }
    }
  }

  static int remaining(HeroCharacter hero, String resource) {
    validate(hero);
    return maximum(hero, resource) - (hero.spentClassResources[resource] ?? 0);
  }

  static HeroCharacter spend(HeroCharacter hero, String resource,
      {int amount = 1}) {
    if (hero.isDead || hero.hitPoints == null || hero.hitPoints! <= 0) {
      throw StateError('Der Charakter kann keine Klassenressource ausgeben.');
    }
    if (amount < 1 || amount > 100) throw RangeError.range(amount, 1, 100);
    if (remaining(hero, resource) < amount) {
      throw StateError('Nicht genügend Klassenressourcen vorhanden.');
    }
    return hero.copyWith(spentClassResources: {
      ...hero.spentClassResources,
      resource: (hero.spentClassResources[resource] ?? 0) + amount,
    });
  }

  static HeroCharacter afterShortRest(HeroCharacter hero) {
    validate(hero);
    final used = Map<String, int>.of(hero.spentClassResources);
    // Short rest regains exactly one of these resources, not all uses.
    for (final id in ['rage', 'channelDivinityCleric',
        'wildShape', 'channelDivinityPaladin']) {
      if ((used[id] ?? 0) > 0) used[id] = used[id]! - 1;
    }
    // Monk regains all Focus Points; Bard from level 5 regains Inspiration.
    used.remove('focusPoints');
    if (level(hero, 'Barde') >= 5) used.remove('bardicInspiration');
    return hero.copyWith(spentClassResources: used);
  }

  static HeroCharacter afterLongRest(HeroCharacter hero) {
    validate(hero);
    return hero.copyWith(spentClassResources: const {});
  }

  /// Maximum invocations the Warlock may select; choices remain explicit.
  static int warlockInvocationChoices(int warlockLevel) {
    if (warlockLevel < 0 || warlockLevel > 20) {
      throw RangeError.range(warlockLevel, 0, 20);
    }
    return warlockLevel == 0 ? 0 : warlockLevel >= 18 ? 10 :
      warlockLevel >= 15 ? 9 : warlockLevel >= 12 ? 8 :
      warlockLevel >= 9 ? 7 : warlockLevel >= 7 ? 6 :
      warlockLevel >= 5 ? 5 : warlockLevel >= 2 ? 3 : 1;
  }

  /// Mastery weapon selections are not assumed automatically.
  static int fighterWeaponMasteries(int fighterLevel) {
    if (fighterLevel < 0 || fighterLevel > 20) {
      throw RangeError.range(fighterLevel, 0, 20);
    }
    return fighterLevel == 0 ? 0 : fighterLevel >= 16 ? 6 :
      fighterLevel >= 10 ? 5 : fighterLevel >= 4 ? 4 : 3;
  }

  static int barbarianWeaponMasteries(int barbarianLevel) {
    if (barbarianLevel < 0 || barbarianLevel > 20) {
      throw RangeError.range(barbarianLevel, 0, 20);
    }
    return barbarianLevel == 0 ? 0 : barbarianLevel >= 10 ? 4 :
      barbarianLevel >= 4 ? 3 : 2;
  }

  static int fighterIndomitableMaximum(int fighterLevel) {
    if (fighterLevel < 0 || fighterLevel > 20) {
      throw RangeError.range(fighterLevel, 0, 20);
    }
    return fighterLevel < 9 ? 0 : fighterLevel >= 17 ? 3 :
      fighterLevel >= 13 ? 2 : 1;
  }

  static int rageDamageBonus(int barbarianLevel) {
    if (barbarianLevel <= 0) return 0;
    if (barbarianLevel > 20) throw RangeError.range(barbarianLevel, 1, 20);
    return barbarianLevel >= 16 ? 4 : barbarianLevel >= 9 ? 3 : 2;
  }

  static int sneakAttackDice(int rogueLevel) {
    if (rogueLevel < 0 || rogueLevel > 20) {
      throw RangeError.range(rogueLevel, 0, 20);
    }
    return rogueLevel == 0 ? 0 : (rogueLevel + 1) ~/ 2;
  }

  static int martialArtsDie(int monkLevel) {
    if (monkLevel < 0 || monkLevel > 20) {
      throw RangeError.range(monkLevel, 0, 20);
    }
    if (monkLevel == 0) return 0;
    return monkLevel >= 17 ? 12 : monkLevel >= 11 ? 10 :
        monkLevel >= 5 ? 8 : 6;
  }

  static int bardicDie(int bardLevel) {
    if (bardLevel < 0 || bardLevel > 20) {
      throw RangeError.range(bardLevel, 0, 20);
    }
    return bardLevel == 0 ? 0 : bardLevel >= 15 ? 12 :
        bardLevel >= 10 ? 10 : bardLevel >= 5 ? 8 : 6;
  }

  /// Calculate a bonus in feet, not metres; the character model uses metres.
  static int monkMovementBonusFeet(int monkLevel) {
    if (monkLevel < 2) return 0;
    if (monkLevel > 20) throw RangeError.range(monkLevel, 2, 20);
    return monkLevel >= 18 ? 30 : monkLevel >= 14 ? 25 :
        monkLevel >= 10 ? 20 : monkLevel >= 6 ? 15 : 10;
  }
}
