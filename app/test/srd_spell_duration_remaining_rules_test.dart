import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_duration_remaining_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_duration_rules.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  SrdSpellDurationRemainingPreview preview(
    String spellName,
    int elapsed, {
    bool confirmed = true,
  }) => SrdSpellDurationRemainingRules.preview(
    spell: catalog.find(spellName)!,
    elapsedGameSeconds: elapsed,
    elapsedGameTimeConfirmed: confirmed,
  );

  test('fixed duration reports exact seconds remaining', () {
    final result = preview('Aid', 3600);
    expect(result.maximumSeconds, 28800);
    expect(result.remainingSeconds, 25200);
    expect(result.durationKind, SrdSpellDurationKind.fixedTime);
    expect(result.timeLimitReached, isFalse);
    expect(result.canEndEarly, isFalse);
  });

  test('concentration has an upper bound but may end early', () {
    final result = preview('Bless', 12);
    expect(result.maximumSeconds, 60);
    expect(result.remainingSeconds, 48);
    expect(result.canEndEarly, isTrue);
  });

  test('round duration uses six-second rounds', () {
    final result = preview('Shield', 3);
    expect(result.maximumSeconds, 6);
    expect(result.remainingSeconds, 3);
  });

  test('elapsed time beyond maximum clamps remaining time to zero', () {
    final result = preview('Aid', 999999);
    expect(result.remainingSeconds, 0);
    expect(result.timeLimitReached, isTrue);
  });

  test('unconfirmed time and nonnumeric durations fail closed', () {
    expect(() => preview('Aid', 10, confirmed: false), throwsFormatException);
    expect(() => preview('Aid', -1), throwsFormatException);
    expect(() => preview('Magic Missile', 0), throwsUnsupportedError);
    expect(() => preview('Arcane Lock', 0), throwsUnsupportedError);
  });
}
