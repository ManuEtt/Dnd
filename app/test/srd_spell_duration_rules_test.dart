import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_duration_rules.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('all known catalogue duration forms classify or fail closed', () {
    var classified = 0;
    var unsupported = 0;
    for (final spell in catalog.spells) {
      if (spell.duration == 'Special') {
        unsupported++;
        expect(
          () => SrdSpellDurationRules.inspect(spell),
          throwsUnsupportedError,
          reason: spell.name,
        );
        continue;
      }
      final result = SrdSpellDurationRules.inspect(spell);
      expect(
        result.requiresConcentration,
        spell.concentration,
        reason: spell.name,
      );
      expect(result.hasTimeLimit, result.amount != null, reason: spell.name);
      classified++;
    }
    expect(classified, 338);
    expect(unsupported, 1);
  });

  test('instantaneous, timed and concentration metadata are distinct', () {
    final instant = SrdSpellDurationRules.inspect(catalog.find('Acid Arrow')!);
    expect(instant.kind, SrdSpellDurationKind.instantaneous);
    expect(instant.hasTimeLimit, isFalse);
    expect(instant.requiresConcentration, isFalse);

    final timed = SrdSpellDurationRules.inspect(catalog.find('Aid')!);
    expect(timed.kind, SrdSpellDurationKind.fixedTime);
    expect(timed.amount, 8);
    expect(timed.unit, SrdSpellDurationUnit.hour);
    expect(timed.hasExplicitEarlyEnding, isFalse);

    final concentrated = SrdSpellDurationRules.inspect(
      catalog.find('Alter Self')!,
    );
    expect(concentrated.kind, SrdSpellDurationKind.concentration);
    expect(concentrated.amount, 1);
    expect(concentrated.unit, SrdSpellDurationUnit.hour);
    expect(concentrated.requiresConcentration, isTrue);
    expect(concentrated.hasExplicitEarlyEnding, isTrue);
  });

  test('rounds and long time spans remain unconverted', () {
    final round = SrdSpellDurationRules.inspect(catalog.find('Shield')!);
    expect(round.amount, 1);
    expect(round.unit, SrdSpellDurationUnit.round);
    final days = SrdSpellDurationRules.inspect(catalog.find('Geas')!);
    expect(days.amount, 30);
    expect(days.unit, SrdSpellDurationUnit.day);
    final tsunami = SrdSpellDurationRules.inspect(catalog.find('Tsunami')!);
    expect(tsunami.amount, 6);
    expect(tsunami.unit, SrdSpellDurationUnit.round);
    expect(tsunami.requiresConcentration, isTrue);
  });

  test('conditional or dispelled durations invent no expiry time', () {
    final forever = SrdSpellDurationRules.inspect(
      catalog.find('Arcane Lock')!,
    );
    expect(forever.kind, SrdSpellDurationKind.untilDispelled);
    expect(forever.hasTimeLimit, isFalse);
    expect(forever.explicitlyEndsOnDispel, isTrue);

    final trigger = SrdSpellDurationRules.inspect(
      catalog.find('Glyph of Warding')!,
    );
    expect(trigger.kind, SrdSpellDurationKind.conditional);
    expect(trigger.hasTimeLimit, isFalse);
    expect(trigger.hasExplicitEarlyEnding, isTrue);
    expect(trigger.explicitlyEndsOnDispel, isTrue);

    final upTo = SrdSpellDurationRules.inspect(catalog.find('Etherealness')!);
    expect(upTo.kind, SrdSpellDurationKind.upTo);
    expect(upTo.amount, 8);
    expect(upTo.unit, SrdSpellDurationUnit.hour);
    expect(upTo.hasExplicitEarlyEnding, isTrue);
  });

  test('untrusted and contradictory durations fail closed', () {
    for (final invalid in [
      'Special',
      'Never',
      '0 minutes',
      '-1 minute',
      '1 rounds',
      '2 minute',
      '1 century',
      'Concentration, up to 0 minutes',
    ]) {
      expect(
        () => SrdSpellDurationRules.parse(
          invalid,
          concentrationRequired: invalid.startsWith('Concentration'),
        ),
        throwsA(anyOf(isA<FormatException>(), isA<UnsupportedError>())),
        reason: invalid,
      );
    }
    expect(
      () => SrdSpellDurationRules.parse(
        'Concentration, up to 1 minute',
        concentrationRequired: false,
      ),
      throwsFormatException,
    );
    expect(
      () => SrdSpellDurationRules.parse(
        '1 minute',
        concentrationRequired: true,
      ),
      throwsFormatException,
    );
  });
}
