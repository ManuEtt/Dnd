import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_duration_rules.dart';

void main() {
  test('canonical spell durations remain accepted', () {
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
    expect(timed.unit, SrdSpellDurationUnit.minute);

    final concentration = SrdSpellDurationRules.parse(
      'Concentration, up to 10 minutes',
      concentrationRequired: true,
    );
    expect(concentration.requiresConcentration, isTrue);
    expect(concentration.amount, 10);
  });

  test('leading or trailing whitespace cannot change catalogue meaning', () {
    for (final invalid in [
      ' Instantaneous',
      'Instantaneous ',
      '\nInstantaneous',
      'Instantaneous\n',
      '\t1 hour',
      '1 hour\r\n',
      'Up to 1 minute ',
      'Concentration, up to 1 minute\n',
      ' Until dispelled',
      'Until dispelled or triggered\t',
    ]) {
      expect(
        () => SrdSpellDurationRules.parse(
          invalid,
          concentrationRequired: invalid.trim().startsWith('Concentration'),
        ),
        throwsFormatException,
        reason: invalid,
      );
    }
  });

  test('embedded control characters and special durations stay unsupported', () {
    for (final invalid in [
      '1 minute\n2 minutes',
      '1 minute\u200B',
    ]) {
      expect(
        () => SrdSpellDurationRules.parse(
          invalid,
          concentrationRequired: invalid.startsWith('Concentration'),
        ),
        throwsUnsupportedError,
        reason: invalid,
      );
    }
    expect(
      () => SrdSpellDurationRules.parse(
        'Concentration,\tup to 1 minute',
        concentrationRequired: true,
      ),
      throwsFormatException,
    );
    expect(
      () => SrdSpellDurationRules.parse(
        'Special',
        concentrationRequired: false,
      ),
      throwsUnsupportedError,
    );
  });
}
