import 'srd_spell_catalog.dart';
import 'srd_spell_duration_rules.dart';

/// A duration ceiling is not proof that a spell effect is still active.
/// Spell-specific endings, dispelling and concentration are adjudicated
/// separately. All values are game-time seconds, never wall-clock time.
class SrdSpellDurationRemainingPreview {
  const SrdSpellDurationRemainingPreview({
    required this.maximumSeconds,
    required this.elapsedSeconds,
    required this.remainingSeconds,
    required this.durationKind,
  });

  final int maximumSeconds;
  final int elapsedSeconds;
  final int remainingSeconds;
  final SrdSpellDurationKind durationKind;

  bool get timeLimitReached => remainingSeconds == 0;
  bool get canEndEarly =>
      durationKind == SrdSpellDurationKind.concentration ||
      durationKind == SrdSpellDurationKind.upTo;
}

/// Read-only timeline estimate from independently confirmed game-time.
/// No timer is started, concentration is not assumed, and the spell is
/// never expired automatically.
class SrdSpellDurationRemainingRules {
  const SrdSpellDurationRemainingRules._();

  static SrdSpellDurationRemainingPreview preview({
    required SrdSpellDefinition spell,
    required int elapsedGameSeconds,
    required bool elapsedGameTimeConfirmed,
  }) {
    if (!elapsedGameTimeConfirmed ||
        elapsedGameSeconds < 0 ||
        elapsedGameSeconds > 1000000000) {
      throw const FormatException(
        'Die vergangene Spielzeit muss gültig bestätigt sein.',
      );
    }
    final assessment = SrdSpellDurationRules.inspect(spell);
    final amount = assessment.amount;
    final unit = assessment.unit;
    if (amount == null || unit == null) {
      throw UnsupportedError(
        'Ohne feste Zeitobergrenze ist keine Restdauer berechenbar.',
      );
    }
    final factor = switch (unit) {
      SrdSpellDurationUnit.round => 6,
      SrdSpellDurationUnit.minute => 60,
      SrdSpellDurationUnit.hour => 3600,
      SrdSpellDurationUnit.day => 86400,
    };
    final maximum = amount * factor;
    final remaining = maximum - elapsedGameSeconds;
    return SrdSpellDurationRemainingPreview(
      maximumSeconds: maximum,
      elapsedSeconds: elapsedGameSeconds,
      remainingSeconds: remaining > 0 ? remaining : 0,
      durationKind: assessment.kind,
    );
  }
}
