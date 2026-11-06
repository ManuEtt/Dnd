import 'srd_spell_catalog.dart';

/// SRD 5.2.1: "Spells / Casting Time". These are classifications, not
/// authorization to cast a spell or spend an action, reaction or spell slot.
enum SrdSpellCastingTimeKind {
  action,
  bonusAction,
  triggeredBonusAction,
  triggeredReaction,
  extended,
  special,
}

class SrdSpellCastingTimeAssessment {
  const SrdSpellCastingTimeAssessment({
    required this.kind,
    required this.ritualOption,
    this.ordinaryMinutes,
  });

  final SrdSpellCastingTimeKind kind;
  final bool ritualOption;

  /// Known longer casting times; no turn timer or concentration is started.
  /// Null for a normal Action, Bonus Action, Reaction, or a special entry.
  final int? ordinaryMinutes;

  bool get permitsExistingSingleTurnPreflight =>
      kind == SrdSpellCastingTimeKind.action ||
      kind == SrdSpellCastingTimeKind.bonusAction;
}

/// Fail-closed classification of EXACT working-catalogue casting-time forms.
///
/// A public SrdSpellDefinition constructor can bypass fromJson validation;
/// therefore preflight must never trust its ritual flag or normalize its
/// untrusted casting-time text. Classifying a triggered Reaction/Bonus Action
/// here never approves its separately required trigger.
class SrdSpellCastingTimeRules {
  // Validate again at preflight; a direct constructor bypasses fromJson.
  const SrdSpellCastingTimeRules._();

  static final RegExp _invisible = RegExp(
    r'[\x00-\x1f\x7f-\x9f\u00ad\u034f\u061c\u180e\u200b-\u200f\u2028-\u202e\u2060-\u206f\ufeff\ufff9-\ufffb]',
  );

  // Only the eight triggered casting times independently identified in the
  // SRD 5.2.1 working catalogue are classified. A matching prefix alone is
  // never proof of the trigger, and an existing triggered spell must not be
  // silently rewritten into an ordinary Action by a direct constructor.
  // Source: Wizards of the Coast LLC, SRD 5.2.1 / Spells (CC BY 4.0).
  static const _triggeredTimeByName = <String, String>{
    'Counterspell':
        'Reaction, which you take when you see a creature within 60 feet of '
        'yourself casting a spell with Verbal, Somatic, or Material components',
    'Feather Fall':
        'Reaction, which you take when you or a creature you can see within '
        '60 feet of you falls',
    'Hellish Rebuke':
        'Reaction, which you take in response to taking damage from a '
        'creature that you can see within 60 feet of yourself',
    'Shield':
        'Reaction, which you take when you are hit by an attack roll or '
        'targeted by the _Magic Missile_ spell',
    'Divine Smite':
        'Bonus Action, which you take immediately after hitting a target '
        'with a Melee weapon or an Unarmed Strike',
    'Searing Smite':
        'Bonus Action, which you take immediately after hitting a target '
        'with a Melee weapon or an Unarmed Strike',
    'Ensnaring Strike':
        'Bonus Action, which you take immediately after hitting a creature '
        'with a weapon',
    'Shining Smite':
        'Bonus Action, which you take immediately after hitting a creature '
        'with a Melee weapon or an Unarmed Strike',
  };

  static SrdSpellCastingTimeAssessment inspect(SrdSpellDefinition spell) {
    final time = spell.castingTime;
    if (time.isEmpty || time != time.trim() || _invisible.hasMatch(time)) {
      throw const FormatException(
        'Zauberwirkzeit enthält unbestätigte Rand- oder Steuerzeichen.',
      );
    }
    final ritual = time.endsWith(' or Ritual');
    if (ritual != spell.ritual) {
      throw const FormatException(
        'Zauberwirkzeit und Ritualangabe widersprechen sich.',
      );
    }
    final expectedTrigger = _triggeredTimeByName[spell.name];
    if (expectedTrigger != null && time != expectedTrigger) {
      throw const FormatException(
        'Die ausgelöste SRD-Zauberwirkzeit passt nicht zum Zauber.',
      );
    }
    switch (time) {
      case 'Action':
        return const SrdSpellCastingTimeAssessment(
          kind: SrdSpellCastingTimeKind.action,
          ritualOption: false,
        );
      case 'Action or Ritual':
        return const SrdSpellCastingTimeAssessment(
          kind: SrdSpellCastingTimeKind.action,
          ritualOption: true,
        );
      case 'Bonus Action':
        return const SrdSpellCastingTimeAssessment(
          kind: SrdSpellCastingTimeKind.bonusAction,
          ritualOption: false,
        );
      case '1 minute':
      case '10 minutes':
      case '1 hour':
      case '8 hours':
      case '12 hours':
      case '24 hours':
      case '1 minute or Ritual':
      case '10 minutes or Ritual':
      case '1 hour or Ritual':
        final ordinary = ritual
            ? time.substring(0, time.length - ' or Ritual'.length)
            : time;
        final minutes = switch (ordinary) {
          '1 minute' => 1,
          '10 minutes' => 10,
          '1 hour' => 60,
          '8 hours' => 480,
          '12 hours' => 720,
          '24 hours' => 1440,
          _ => throw const FormatException(
            'Ungeprüfte längere Zauberwirkzeit.',
          ),
        };
        return SrdSpellCastingTimeAssessment(
          kind: SrdSpellCastingTimeKind.extended,
          ritualOption: ritual,
          ordinaryMinutes: minutes,
        );
      case 'Action (Overgrowth) or 8 hours (Enrichment)':
        return const SrdSpellCastingTimeAssessment(
          kind: SrdSpellCastingTimeKind.special,
          ritualOption: false,
        );
    }

    // A triggered time is valid only for its exact audited spell identity.
    // This classification still never confirms that the trigger occurred.
    const reactionPrefix = 'Reaction, which you take ';
    const bonusPrefix = 'Bonus Action, which you take ';
    if (time.startsWith(reactionPrefix) ||
        time.startsWith(bonusPrefix)) {
      if (expectedTrigger == null || expectedTrigger != time) {
        throw UnsupportedError(
          'Ungeprüfte ausgelöste SRD-Zauberwirkzeit: $time',
        );
      }
      return SrdSpellCastingTimeAssessment(
        kind: time.startsWith(reactionPrefix)
            ? SrdSpellCastingTimeKind.triggeredReaction
            : SrdSpellCastingTimeKind.triggeredBonusAction,
        ritualOption: false,
      );
    }
    throw UnsupportedError('Ungeprüfte SRD-Zauberwirkzeit: $time');
  }

  // A trigger is not an ordinary Bonus Action or Magic action approval.
  static SrdSpellCastingTimeAssessment requireSingleTurn(
    SrdSpellDefinition spell,
  ) {
    final time = inspect(spell);
    if (!time.permitsExistingSingleTurnPreflight) {
      throw UnsupportedError(
        'Reaktionen, ausgelöste Bonusaktionen und längere Zauberzeiten '
        'benötigen ihre eigene bestätigte Regelaktion.',
      );
    }
    return time;
  }
}
