import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/domain/srd_concentration_damage_dc_preview_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_concentration_damage_rules.dart';

SrdConcentrationDamageSource source(
  String id,
  int damage, {
  bool confirmed = true,
}) => SrdConcentrationDamageSource(
  sourceId: id,
  damageTaken: damage,
  damageConfirmed: confirmed,
);

void main() {
  test('separate sources retain separate concentration DCs', () {
    final result = SrdConcentrationDamageDcRules.preview(
      sources: [source('arrow', 8), source('fire', 40)],
    );
    expect(result.checks.length, 2);
    expect(result.checks.map((c) => c.difficultyClass).toList(), [10, 20]);
    expect(result.highestDifficultyClass, 20);
    expect(result.checks.map((c) => c.sourceId).toList(), ['arrow', 'fire']);
  });

  test('damage DC is at least ten and capped at thirty', () {
    final result = SrdConcentrationDamageDcRules.preview(
      sources: [source('scratch', 1), source('impact', 100)],
    );
    expect(result.checks.map((c) => c.difficultyClass).toList(), [10, 30]);
  });

  test('preview is an immutable snapshot', () {
    final sources = [source('first', 20)];
    final result = SrdConcentrationDamageDcRules.preview(sources: sources);
    sources.add(source('second', 40));
    expect(result.checks.length, 1);
    expect(
      () => result.checks.add(
        const SrdConcentrationDamageDcEntry(
          sourceId: 'new',
          damageTaken: 2,
          difficultyClass: 10,
        ),
      ),
      throwsUnsupportedError,
    );
  });

  test('unknown, duplicate or unconfirmed sources fail closed', () {
    for (final sources in [
      <SrdConcentrationDamageSource>[],
      [source('x', 1), source('x', 2)],
      [source(' x', 1)],
      [source('x', 1, confirmed: false)],
      [source('x', 0)],
      [source('x\u200b', 1)],
    ]) {
      expect(
        () => SrdConcentrationDamageDcRules.preview(sources: sources),
        throwsA(anyOf(isA<FormatException>(), isA<RangeError>())),
      );
    }
  });
}
