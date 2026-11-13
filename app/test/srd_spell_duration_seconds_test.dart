import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_duration_rules.dart';

SrdSpellDurationAssessment _parse(
  String duration, {
  bool concentration = false,
}) => SrdSpellDurationRules.parse(
  duration,
  concentrationRequired: concentration,
);

void main() {
  test('known fixed durations convert without advancing game time', () {
    expect(_parse('1 round').maximumDurationSeconds, 6);
    expect(_parse('1 minute').maximumDurationSeconds, 60);
    expect(_parse('1 hour').maximumDurationSeconds, 3600);
    expect(_parse('8 hours').maximumDurationSeconds, 28800);
    expect(_parse('1 day').maximumDurationSeconds, 86400);
    expect(_parse('30 days').maximumDurationSeconds, 2592000);
  });

  test('up-to and concentration durations are nominal maxima only', () {
    final upTo = _parse('Up to 8 hours');
    expect(upTo.kind, SrdSpellDurationKind.upTo);
    expect(upTo.maximumDurationSeconds, 28800);
    expect(upTo.hasExplicitEarlyEnding, isTrue);
    final concentration = _parse(
      'Concentration, up to 6 rounds',
      concentration: true,
    );
    expect(concentration.maximumDurationSeconds, 36);
    expect(concentration.requiresConcentration, isTrue);
    expect(concentration.hasExplicitEarlyEnding, isTrue);
  });

  test('untimed and instantaneous effects have no time bound', () {
    for (final duration in [
      'Instantaneous',
      'Until dispelled',
      'Until dispelled or triggered',
    ]) {
      expect(_parse(duration).maximumDurationSeconds, isNull);
    }
  });

  test('unknown duration cannot invent a time bound', () {
    expect(
      () => _parse('999 days').maximumDurationSeconds,
      throwsUnsupportedError,
    );
  });
}
