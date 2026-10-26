import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_duration_rules.dart';

void main() {
  test('known durations keep their meaning', () {
    final instant = SrdSpellDurationRules.parse(
      'Instantaneous',
      concentrationRequired: false,
    );
    expect(instant.kind, SrdSpellDurationKind.instantaneous);

    final timed = SrdSpellDurationRules.parse(
      '1 minute',
      concentrationRequired: false,
    );
    expect(timed.amount, 1);

    final focused = SrdSpellDurationRules.parse(
      'Concentration, up to 10 minutes',
      concentrationRequired: true,
    );
    expect(focused.requiresConcentration, isTrue);
    expect(focused.amount, 10);
  });

  test('altered duration borders are rejected', () {
    final invalid = [
      ' Instantaneous',
      'Instantaneous ',
      '\nInstantaneous',
      'Instantaneous\n',
      '\t1 hour',
      '1 hour\r\n',
      'Up to 1 minute ',
      ' Until dispelled',
    ];
    for (final value in invalid) {
      expect(
        () => SrdSpellDurationRules.parse(
          value,
          concentrationRequired: false,
        ),
        throwsFormatException,
      );
    }
    expect(
      () => SrdSpellDurationRules.parse(
        'Concentration, up to 1 minute\n',
        concentrationRequired: true,
      ),
      throwsFormatException,
    );
  });

  test('unsupported syntax is not converted to a duration', () {
    for (final value in ['Special', '1 minute\n2 minutes', '1 minute\u200B']) {
      expect(
        () => SrdSpellDurationRules.parse(
          value,
          concentrationRequired: false,
        ),
        throwsUnsupportedError,
      );
    }
  });
}
