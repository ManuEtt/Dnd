import 'dice_engine.dart';
import 'models.dart';
import 'rules_engine.dart';
import 'spellcasting_rules.dart';
import 'srd_character_classes.dart';
import 'srd_class_feature_catalog.dart';

/// Executable self-target effects, not authority to learn an arbitrary spell.
/// SRD 5.2.1 (CC BY 4.0): Multiclassing pp. 25–26; Components p. 105;
/// Targeting Yourself p. 106; Cure Wounds p. 121; Healing Word p. 139.
/// Life Domain: Disciple of Life / Blessed Healer / Supreme Healing p. 40.
/// https://www.dndbeyond.com/srd
/// Turn economy and the one-slot-per-turn rule belong to the game engine.
class HealingSpellRules {
  const HealingSpellRules._();

  static const definitions = <HealingSpellDefinition>[
    HealingSpellDefinition(
      name: 'Wunden heilen',
      englishName: 'Cure Wounds',
      castingClasses: ['Barde', 'Kleriker', 'Druide', 'Paladin', 'Waldläufer'],
      dieSides: 8,
      actionType: 'action',
      requiresSomatic: true,
    ),
    HealingSpellDefinition(
      name: 'Heilendes Wort',
      englishName: 'Healing Word',
      castingClasses: ['Barde', 'Kleriker', 'Druide'],
      dieSides: 4,
      actionType: 'bonusAction',
      requiresSomatic: false,
    ),
  ];

  static HealingSpellDefinition? find(String spellName) {
    for (final definition in definitions) {
      if (definition.names.contains(spellName.trim())) return definition;
    }
    return null;
  }

  /// The sheet's confirmed spell list is treated as the prepared list for this
  /// operation. It does not grant feats, subclass spells, or spell-list access.
  static List<HealingSpellDefinition> availableSpells(HeroCharacter hero) =>
      List.unmodifiable(
        definitions.where(
          (spell) =>
              spell.names.any(hero.spells.contains) &&
              castingClasses(hero, spell).isNotEmpty,
        ),
      );

  static List<String> castingClasses(
    HeroCharacter hero,
    HealingSpellDefinition spell,
  ) {
    final classes = _classLevels(hero);
    return List.unmodifiable(
      classes.keys.where(
        (name) =>
            spell.castingClasses.contains(name) &&
            maximumPreparedSpellLevel(hero, name) >= spell.level,
      ),
    );
  }

  /// Individual class levels determine preparation; shared higher slots only
  /// enhance spells already allowed by that class. This is NOT a prepared-list
  /// editor and does not implement bonus spells from feats/subclasses.
  static int maximumPreparedSpellLevel(
    HeroCharacter hero,
    String castingClass,
  ) {
    final name = findSrdClass(castingClass)?.name;
    final level = _classLevels(hero)[name] ?? 0;
    if (level == 0) return 0;
    if (const [
      'Barde',
      'Kleriker',
      'Druide',
      'Magier',
      'Zauberer',
    ].contains(name)) {
      return ((level + 1) ~/ 2).clamp(1, 9).toInt();
    }
    if (const ['Paladin', 'Waldläufer'].contains(name)) {
      // Their single-class slot table gains level 2 at class level 5, then
      // level 3/4/5 at 9/13/17, including level-1 casting from class level 1.
      return ((level + 3) ~/ 4).clamp(1, 5).toInt();
    }
    if (name == 'Hexenmeister') {
      return ((level + 1) ~/ 2).clamp(1, 5).toInt();
    }
    return 0;
  }

  static HealingSpellResult castSelf(
    HeroCharacter hero, {
    required DiceEngine dice,
    required String spellName,
    required String castingClass,
    int? slotLevel,
    bool pactMagic = false,
    required bool verbalComponentConfirmed,
    bool somaticComponentConfirmed = false,
  }) {
    final selectedName = spellName.trim();
    final definition = find(selectedName);
    if (definition == null || !definition.names.any(hero.spells.contains)) {
      throw const FormatException(
        'Bitte einen bestätigten vorbereiteten Heilzauber wählen.',
      );
    }
    final selectedClass = findSrdClass(castingClass)?.name;
    if (selectedClass == null ||
        !castingClasses(hero, definition).contains(selectedClass)) {
      throw const FormatException(
        'Dieser vorbereitete Zauber gehört nicht zur gewählten eigenen Klasse.',
      );
    }
    final ability = const {
      'Barde': 'charisma',
      'Kleriker': 'wisdom',
      'Druide': 'wisdom',
      'Paladin': 'charisma',
      'Waldläufer': 'wisdom',
    }[selectedClass]!;
    final score = hero.abilities[ability];
    if (score == null || score < 1 || score > 30) {
      throw StateError('Das Zauberattribut muss bestätigt sein.');
    }
    if (hero.hitPoints == null ||
        hero.maxHitPoints == null ||
        hero.hitPoints! <= 0 ||
        hero.maxHitPoints! < 1 ||
        hero.hitPoints! > hero.maxHitPoints! ||
        hero.isDead) {
      throw StateError(
        'Selbstheilung erfordert einen lebenden Zaubernden mit bestätigten TP.',
      );
    }
    if (!verbalComponentConfirmed ||
        (definition.requiresSomatic && !somaticComponentConfirmed)) {
      throw StateError(
        'Die benötigten verbalen und gegebenenfalls gestischen Komponenten '
        'müssen möglich und ausdrücklich bestätigt sein.',
      );
    }
    if (definition.actionType == 'bonusAction' &&
        const ['blind', 'unsichtbar'].any(hero.conditions.contains)) {
      // No special senses are represented in the sheet. Do not assume that
      // the caster can see the self-target of Healing Word.
      throw StateError('Heilendes Wort benötigt Sicht auf das Ziel.');
    }
    final healingFeatures = _validatedHealingFeatures(hero);
    final resourceHero = _normalizedResourceHero(hero);
    _validateResources(resourceHero);
    // Reuse the authoritative slot/Pact selection, equipment and inability-to-
    // act checks before consuming random numbers or creating an effect.
    final spent = SpellcastingRules.cast(
      resourceHero,
      spellName: definition.names.firstWhere(hero.spells.contains),
      spellLevel: definition.level,
      slotLevel: slotLevel,
      pactMagic: pactMagic,
    );
    final modifier = RulesEngine.abilityModifier(score);
    final discipleBonus = healingFeatures.contains('Disciple of Life')
        ? 2 + spent.slotLevel
        : 0;
    final maximizedHealing = healingFeatures.contains('Supreme Healing');
    final totalModifier = modifier + discipleBonus;
    final suffix = totalModifier < 0 ? '$totalModifier' : '+$totalModifier';
    final count = 2 * spent.slotLevel;
    final expression = '${count}d${definition.dieSides}$suffix';
    // Supreme Healing replaces the dice entirely; it must not advance RNG.
    // The stored values document the substituted maximum for each die.
    final roll = maximizedHealing
        ? DiceResult(
            expression: expression,
            rolls: List.filled(count, definition.dieSides),
            modifier: totalModifier,
            total: count * definition.dieSides + totalModifier,
          )
        : dice.roll(expression);
    final consumed = hero.copyWith(
      spentSpellSlots: spent.hero.spentSpellSlots,
      spentPactSlots: spent.hero.spentPactSlots,
    );
    // Regaining HP never deals damage if a negative ability modifier outweighs
    // the dice. Keep the original roll and clamp only the applied healing.
    final healed = RulesEngine.heal(consumed, roll.total < 0 ? 0 : roll.total);
    return HealingSpellResult(
      hero: healed,
      roll: roll,
      spellName: definition.name,
      castingClass: selectedClass,
      spellcastingAbility: ability,
      slotLevel: spent.slotLevel,
      pactMagic: spent.pactMagic,
      recovered: healed.hitPoints! - hero.hitPoints!,
      actionType: definition.actionType,
      discipleOfLifeBonus: discipleBonus,
      maximizedHealing: maximizedHealing,
    );
  }

  static Map<String, int> _classLevels(HeroCharacter hero) {
    final first = findSrdClass(hero.className)?.name;
    final second = findSrdClass(hero.secondaryClassName)?.name;
    if (hero.level < 1 ||
        hero.level > 20 ||
        first == null ||
        hero.primaryClassLevel < 1 ||
        (!hero.hasSecondClass && hero.secondaryClassLevel != 0) ||
        (hero.hasSecondClass &&
            (second == null ||
                second == first ||
                hero.secondaryClassLevel < 1))) {
      throw const FormatException('Die eigenen Klassenstufen sind ungültig.');
    }
    return {
      first: hero.primaryClassLevel,
      if (second != null) second: hero.secondaryClassLevel,
    };
  }

  static HeroCharacter _normalizedResourceHero(HeroCharacter hero) {
    _classLevels(hero);
    return hero.copyWith(
      className: findSrdClass(hero.className)!.name,
      secondaryClassName: hero.hasSecondClass
          ? findSrdClass(hero.secondaryClassName)!.name
          : '',
    );
  }

  static void _validateResources(HeroCharacter hero) {
    if (hero.spentSpellSlots.keys.any(
      (key) =>
          !const ['1', '2', '3', '4', '5', '6', '7', '8', '9'].contains(key),
    )) {
      throw const FormatException('Ungültiger Zauberplatzverbrauch.');
    }
    SpellcastingRules.availableSlots(hero);
    SpellcastingRules.availablePactSlots(hero);
  }

  static Set<String> _validatedHealingFeatures(HeroCharacter hero) {
    // The model's sole subclass belongs to the primary class. Do not grant a
    // second-class Life Domain, or grant features from free-form feature names.
    final unlocked = SrdClassFeatureCatalog.unlocked(hero)
        .where(
          (feature) => feature.className == 'Kleriker' && feature.isSubclass,
        )
        .map((feature) => feature.name)
        .toSet();
    final declarations = [
      hero.subclass,
      ...hero.features,
    ].map((value) => value.trim().toLowerCase());
    const featureAliases = {
      'disciple of life': 'Disciple of Life',
      'jünger des lebens': 'Disciple of Life',
      'blessed healer': 'Blessed Healer',
      'gesegneter heiler': 'Blessed Healer',
      'supreme healing': 'Supreme Healing',
      'höchste heilung': 'Supreme Healing',
    };
    final declaredDomain = declarations.any(
      (value) => const [
        'life domain',
        'domäne des lebens',
        'lebensdomäne',
        'domäne: leben',
        'leben',
      ].contains(value),
    );
    if ((declaredDomain && !unlocked.contains('Disciple of Life')) ||
        declarations.any(
          (value) =>
              featureAliases.containsKey(value) &&
              !unlocked.contains(featureAliases[value]),
        )) {
      throw StateError(
        'Lebensdomänenmerkmale benötigen eine bestätigte primäre '
        'Kleriker-Unterklasse und die passende Klerikerstufe.',
      );
    }
    // Blessed Healer requires healing a creature other than yourself, so this
    // self-target operation never adds its separate caster-healing benefit.
    return unlocked;
  }
}

class HealingSpellDefinition {
  const HealingSpellDefinition({
    required this.name,
    required this.englishName,
    required this.castingClasses,
    required this.dieSides,
    required this.actionType,
    required this.requiresSomatic,
  });
  final String name, englishName, actionType;
  final List<String> castingClasses;
  final int dieSides;
  final bool requiresSomatic;
  int get level => 1;
  List<String> get names => [name, englishName];
}

class HealingSpellResult {
  const HealingSpellResult({
    required this.hero,
    required this.roll,
    required this.spellName,
    required this.castingClass,
    required this.spellcastingAbility,
    required this.slotLevel,
    required this.pactMagic,
    required this.recovered,
    required this.actionType,
    this.discipleOfLifeBonus = 0,
    this.maximizedHealing = false,
  });
  final HeroCharacter hero;
  final DiceResult roll;
  final String spellName, castingClass, spellcastingAbility, actionType;
  final int slotLevel, recovered;
  final bool pactMagic;
  final int discipleOfLifeBonus;
  final bool maximizedHealing;
}
