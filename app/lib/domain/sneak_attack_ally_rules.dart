import 'class_combat_features.dart';
import 'condition_rules.dart';
import 'models.dart';

/// Explicit player observations for one pending main-hand attack. SRD 5.2.1,
/// Rogue: Sneak Attack, pp.61–62, CC BY 4.0. No facts come from narration.
class SneakAttackAllyConfirmation {
  const SneakAttackAllyConfirmation({
    required this.campaignId,
    required this.rollId,
    required this.targetId,
    required this.allyName,
    required this.withinFiveFeetOfTargetConfirmed,
    required this.notIncapacitatedConfirmed,
  });

  final String campaignId, rollId, targetId, allyName;
  final bool withinFiveFeetOfTargetConfirmed, notIncapacitatedConfirmed;

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'campaignId': campaignId,
    'rollId': rollId,
    'targetId': targetId,
    'allyName': allyName,
    'withinFiveFeetOfTargetConfirmed': withinFiveFeetOfTargetConfirmed,
    'notIncapacitatedConfirmed': notIncapacitatedConfirmed,
  };

  factory SneakAttackAllyConfirmation.fromJson(Map<String, dynamic> json) {
    const keys = {
      'schemaVersion',
      'campaignId',
      'rollId',
      'targetId',
      'allyName',
      'withinFiveFeetOfTargetConfirmed',
      'notIncapacitatedConfirmed',
    };
    if (json['schemaVersion'] is! int ||
        json['schemaVersion'] != 1 ||
        json.keys.any((key) => !keys.contains(key)) ||
        json['withinFiveFeetOfTargetConfirmed'] != true ||
        json['notIncapacitatedConfirmed'] != true) {
      throw const FormatException(
        'Beide Verbündeten-Fakten müssen ausdrücklich bestätigt sein.',
      );
    }
    String text(String key, int limit) {
      final value = json[key];
      if (value is! String ||
          value.isEmpty ||
          value.length > limit ||
          value != value.trim() ||
          RegExp(r'[\x00-\x1f\x7f]').hasMatch(value)) {
        throw const FormatException(
          'Ungültige Verbündeten- oder Angriffszuordnung.',
        );
      }
      return value;
    }

    return SneakAttackAllyConfirmation(
      campaignId: text('campaignId', 200),
      rollId: text('rollId', 200),
      targetId: text('targetId', 200),
      allyName: text('allyName', 120),
      withinFiveFeetOfTargetConfirmed: true,
      notIncapacitatedConfirmed: true,
    );
  }
}

class SneakAttackAllyRules {
  const SneakAttackAllyRules._();

  /// This increment covers the pending primary attack in the existing solo
  /// encounter. No general ally movement, offhand or opportunity attack model.
  static bool canPrepare(Campaign campaign) =>
      campaign.pendingDeathSave == null &&
      campaign.pendingEnemyShieldHit == null &&
      eligible(campaign.hero, campaign.pendingRoll, campaign.encounter);

  static bool eligible(
    HeroCharacter hero,
    PendingRoll? pending,
    Encounter? fight,
  ) =>
      pending != null &&
      pending.type == 'attack' &&
      fight != null &&
      !fight.isFinished &&
      fight.activeParticipant == 'hero' &&
      fight.id == pending.targetId &&
      hero.hitPoints != null &&
      hero.hitPoints! > 0 &&
      !hero.isDead &&
      ConditionRules.canTakeActions(hero) &&
      ClassCombatFeatures.eligibleSneakAttackDice(
            hero,
            hasAdvantage: pending.advantage,
            hasDisadvantage: pending.disadvantage,
            adjacentConsciousAlly: true,
            allyWithinFiveFeetOfTargetConfirmed: true,
            allyNotIncapacitatedConfirmed: true,
            alreadyUsedThisTurn: fight.sneakAttackUsedThisTurn,
          ) >
          0;

  /// Import and execution use the same target, roll, turn and feature checks.
  static void validate({
    required String campaignId,
    required HeroCharacter hero,
    required PendingRoll pending,
    required Encounter? fight,
  }) {
    final confirmation = pending.sneakAttackAlly;
    if (confirmation == null) return;
    SneakAttackAllyConfirmation.fromJson(confirmation.toJson());
    if (confirmation.campaignId != campaignId ||
        confirmation.rollId != pending.id ||
        confirmation.targetId != pending.targetId ||
        !eligible(hero, pending, fight)) {
      throw const FormatException(
        'Die Verbündetenbestätigung gehört nicht zu einem zulässigen offenen Angriff.',
      );
    }
  }
}
