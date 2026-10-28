import 'class_feature_resources.dart';
import 'class_progression_rules.dart';
import 'class_resource_rules.dart';
import 'models.dart';
import 'spellcasting_rules.dart';
import 'srd_character_classes.dart';
import 'srd_class_feature_catalog.dart';

/// Runtime evidence for a class-feature unlock. A feature appearing in an SRD
/// table does not imply that all of its mechanical consequences are supported.
enum SrdFeatureRuntimeStatus {
  computed,
  confirmedAction,
  partial,
  playerChoice,
  notImplemented,
}

class SrdFeatureRuntimeEntry {
  const SrdFeatureRuntimeEntry({
    required this.feature,
    required this.status,
    this.evidence = '',
  });

  final SrdClassFeature feature;
  final SrdFeatureRuntimeStatus status;

  /// Concrete rule-engine boundary. This is not an SRD source citation.
  final String evidence;

  bool get hasSupportedMechanics =>
      status == SrdFeatureRuntimeStatus.computed ||
      status == SrdFeatureRuntimeStatus.confirmedAction;

  String get statusLabel => switch (status) {
    SrdFeatureRuntimeStatus.computed => 'Berechnet',
    SrdFeatureRuntimeStatus.confirmedAction => 'Bestätigte Regelaktion',
    SrdFeatureRuntimeStatus.partial => 'Teilautomatik',
    SrdFeatureRuntimeStatus.playerChoice => 'Auswahl erforderlich',
    SrdFeatureRuntimeStatus.notImplemented => 'Regelprüfung erforderlich',
  };
}

class SrdClassAutomaticValue {
  const SrdClassAutomaticValue(this.className, this.name, this.value);

  final String className;
  final String name;
  final String value;
}

/// Combines the *actual* implemented rule boundaries with SRD class unlocks.
///
/// In particular the catalogue's historical FeatureAutomation.automatic field
/// must not be treated as proof that a feature's whole effect executes. These
/// mappings are deliberately explicit and fail closed for new SRD entries.
class SrdClassAutomation {
  const SrdClassAutomation._();

  // Passive/calculated aspects backed by existing production rule engines.
  static const Map<String, String> _computedEvidence = {
    'Extra Attack': 'ClassProgressionRules.attacksPerAttackAction',
    'Two Extra Attacks': 'ClassProgressionRules.attacksPerAttackAction',
    'Three Extra Attacks': 'ClassProgressionRules.attacksPerAttackAction',
    'Unarmored Movement': 'CharacterRuleEngine.effectiveSpeed',
    'Fast Movement': 'CharacterRuleEngine.effectiveSpeed',
    'Feral Instinct': 'CharacterRuleEngine.initiative',
    'Danger Sense': 'CharacterRuleEngine.savingThrow',
    'Improved Critical': 'ClassCombatFeatures.weaponCriticalThreshold',
    'Superior Critical': 'ClassCombatFeatures.weaponCriticalThreshold',
    'Jack of All Trades': 'CharacterRuleEngine.abilityCheck',
    'Slippery Mind': 'CharacterRuleEngine.savingThrowBonus',
    'Primal Champion': 'SrdClassLevelUpRules.propose',
    'Body and Mind': 'SrdClassLevelUpRules.propose',
  };

  // Confirmed local actions; the caller still validates turn, targeting and
  // context. Never spend resources simply because a feature is unlocked.
  static const Map<String, String> _actionEvidence = {
    'Second Wind': 'ClassFeatureResources.useSecondWind',
    'Action Surge': 'ClassFeatureResources.spendActionSurge',
    'Lay On Hands': 'PaladinLayOnHands',
    'Font of Inspiration': 'GameEngine.confirmBardFontOfInspiration',
    'Superior Inspiration': 'SrdBardSuperiorInspirationRules.onInitiative',
  };

  // Rule fragments exist (e.g. counters, dice, prerequisite checks), but
  // their complete SRD action/effect cycle has NOT been demonstrated.
  static const Map<String, String> _partialEvidence = {
    'Spellcasting': 'SpellcastingRules',
    'Pact Magic': 'SpellcastingRules',
    'Magical Cunning':
        'SrdWarlockMagicalCunningRules.restoreAfterCompletedRite',
    'Eldritch Master': 'SrdWarlockMagicalCunningRules.maximumRecoveredSlots',
    'Channel Divinity': 'ClassResourceRules',
    'Rage': 'ClassResourceRules',
    "Monk's Focus": 'ClassResourceRules',
    'Bardic Inspiration': 'ClassResourceRules',
    'Font of Magic': 'ClassResourceRules',
    'Wild Shape': 'ClassResourceRules',
    'Favored Enemy': 'ClassResourceRules',
    'Weapon Mastery': 'SrdEquipmentCatalog',
    'Sneak Attack': 'ClassCombatFeatures.eligibleSneakAttackDice',
    'Martial Arts': 'ClassResourceRules.martialArtsDie',
    'Unarmored Defense': 'SrdStartingCombatValues',
    'Remarkable Athlete': 'CharacterRuleEngine.initiative',
    'Indomitable Might':
        'SrdIndomitableMightRules (bestätigte Stärke-Proben/Rettungswürfe)',
    'Roving': 'SrdTerrainMovementRules',
    'Tireless': 'SrdRangerTirelessRules (Short Rest + Magic action)',
    'Reliable Talent': 'CharacterRuleEngine.abilityCheck (nur Fertigkeiten)',
    'Slow Fall': 'SrdMonkSlowFallRules (Situations- und Ablaufprüfung)',
    'Feral Senses': 'SrdRangerFeralSensesRules (bestätigte Sinnesdaten)',
  };

  static SrdFeatureRuntimeEntry inspect(SrdClassFeature feature) {
    // Choice-sensitive entries cannot be auto-executed, regardless of a
    // same-named passive registered for a different class.
    if (feature.automation == FeatureAutomation.choiceRequired) {
      return SrdFeatureRuntimeEntry(
        feature: feature,
        status: SrdFeatureRuntimeStatus.playerChoice,
      );
    }
    final computed = _computedEvidence[feature.name];
    if (computed != null && feature.automation == FeatureAutomation.automatic) {
      return SrdFeatureRuntimeEntry(
        feature: feature,
        status: SrdFeatureRuntimeStatus.computed,
        evidence: computed,
      );
    }
    final action = _actionEvidence[feature.name];
    if (action != null) {
      return SrdFeatureRuntimeEntry(
        feature: feature,
        status: SrdFeatureRuntimeStatus.confirmedAction,
        evidence: action,
      );
    }
    final partial = _partialEvidence[feature.name];
    if (partial != null) {
      return SrdFeatureRuntimeEntry(
        feature: feature,
        status: SrdFeatureRuntimeStatus.partial,
        evidence: partial,
      );
    }
    return SrdFeatureRuntimeEntry(
      feature: feature,
      status: SrdFeatureRuntimeStatus.notImplemented,
    );
  }

  /// Scope is the *level of each class*, never total multiclass level.
  /// The catalogue also excludes unselected and unsupported subclasses.
  static List<SrdFeatureRuntimeEntry> unlocked(HeroCharacter hero) =>
      List.unmodifiable(SrdClassFeatureCatalog.unlocked(hero).map(inspect));

  /// Automatic, read-only scaling values from existing proven calculators.
  /// These are NOT grants of invocations, spells, feats or active effects.
  /// Each value is computed again after a level-up and does not alter a save.
  static List<SrdClassAutomaticValue> derivedValues(HeroCharacter hero) {
    final result = <SrdClassAutomaticValue>[];
    for (final klass in srdCharacterClasses) {
      final level = ClassResourceRules.level(hero, klass.name);
      if (level == 0) continue;
      void add(String label, Object value) {
        result.add(SrdClassAutomaticValue(klass.name, label, '$value'));
      }

      switch (klass.name) {
        case 'Barbar':
          add(
            'Kampfrausch-Schadensbonus',
            '+${ClassResourceRules.rageDamageBonus(level)}',
          );
          add(
            'Kampfrausch-Nutzungen',
            ClassResourceRules.maximum(hero, 'rage'),
          );
        case 'Barde':
          add('Inspirationswürfel', 'W${ClassResourceRules.bardicDie(level)}');
          add(
            'Inspiration gesamt',
            ClassResourceRules.maximum(hero, 'bardicInspiration'),
          );
        case 'Kleriker':
          add(
            'Göttlicher Kanal gesamt',
            ClassResourceRules.maximum(hero, 'channelDivinityCleric'),
          );
        case 'Druide':
          add(
            'Tiergestalt gesamt',
            ClassResourceRules.maximum(hero, 'wildShape'),
          );
        case 'Kämpfer':
          add(
            'Angriffe je Angriffsaktion (gesamt)',
            ClassProgressionRules.attacksPerAttackAction(hero),
          );
          add(
            'Zweite Luft gesamt',
            ClassFeatureResources.secondWindMaximum(hero),
          );
          if (level >= 2) {
            add(
              'Aktionsschub gesamt',
              ClassFeatureResources.actionSurgeMaximum(hero),
            );
          }
        case 'Mönch':
          add(
            'Kampfkünste-Schadenswürfel',
            'W${ClassResourceRules.martialArtsDie(level)}',
          );
          if (level >= 2) {
            add(
              'Fokuspunkte gesamt',
              ClassResourceRules.maximum(hero, 'focusPoints'),
            );
          }
        case 'Paladin':
          add(
            'Handauflegen-TP-Vorrat',
            ClassResourceRules.maximum(hero, 'layOnHands'),
          );
        case 'Waldläufer':
          add(
            'Erzfeind-Nutzungen',
            ClassResourceRules.maximum(hero, 'favoredEnemy'),
          );
        case 'Schurke':
          add(
            'Hinterhältiger Angriff',
            '${ClassResourceRules.sneakAttackDice(level)}W6',
          );
        case 'Zauberer':
          if (level >= 2) {
            add(
              'Zaubereipunkte gesamt',
              ClassResourceRules.maximum(hero, 'sorceryPoints'),
            );
          }
        case 'Hexenmeister':
          add('Paktplätze gesamt', SpellcastingRules.pactSlotCount(hero));
          add('Paktplatz-Grad', SpellcastingRules.pactSlotLevel(hero));
          add(
            'Anrufungs-Auswahlplätze (nicht gewählt)',
            ClassResourceRules.warlockInvocationChoices(level),
          );
        case 'Magier':
          // Wizard spell slots are shared with other non-pact spellcasting
          // classes; do not misattribute the combined pool to Wizard alone.
          final slots = SpellcastingRules.availableSlots(hero);
          add(
            'Gemeinsame verfügbare Zauberplätze',
            slots.values.fold<int>(0, (sum, count) => sum + count),
          );
      }
    }
    return List.unmodifiable(result);
  }
}
