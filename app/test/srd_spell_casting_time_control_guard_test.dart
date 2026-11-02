import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_casting_time_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';

SrdSpellDefinition _withCastingTime(
  SrdSpellDefinition source,
  String castingTime,
) => SrdSpellDefinition(
  id: source.id,
  name: source.name,
  level: source.level,
  school: source.school,
  classes: source.classes,
  castingTime: castingTime,
  range: source.range,
  components: source.components,
  duration: source.duration,
  verbal: source.verbal,
  somatic: source.somatic,
  material: source.material,
  concentration: source.concentration,
  ritual: source.ritual,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('legitimate triggered spell timings still classify exactly', () {
    final triggered = catalog.spells.where(
      (spell) =>
          spell.castingTime.startsWith('Reaction, which you take ') ||
          spell.castingTime.startsWith('Bonus Action, which you take '),
    ).toList();
    expect(triggered.length, 8);
    for (final spell in triggered) {
      final assessment = SrdSpellCastingTimeRules.inspect(spell);
      expect(
        assessment.kind,
        spell.castingTime.startsWith('Reaction,')
            ? SrdSpellCastingTimeKind.triggeredReaction
            : SrdSpellCastingTimeKind.triggeredBonusAction,
        reason: spell.name,
      );
      expect(assessment.permitsExistingSingleTurnPreflight, isFalse);
      expect(
        () => SrdSpellCastingTimeRules.requireSingleTurn(spell),
        throwsUnsupportedError,
      );
    }
    expect(
      SrdSpellCastingTimeRules.requireSingleTurn(
        catalog.find('Magic Missile')!,
      ).kind,
      SrdSpellCastingTimeKind.action,
    );
  });

  test('hidden legacy bidi controls and annotations cannot forge triggers', () {
    final triggered = catalog.spells.where(
      (spell) =>
          spell.castingTime.startsWith('Reaction, which you take ') ||
          spell.castingTime.startsWith('Bonus Action, which you take '),
    );
    // Deprecated bidi formatting controls and interlinear annotations were
    // previously accepted in trigger suffixes; never normalize them away.
    for (final control in [
      '\u206a',
      '\u206b',
      '\u206c',
      '\u206d',
      '\u206e',
      '\u206f',
      '\ufff9',
      '\ufffa',
      '\ufffb',
    ]) {
      for (final spell in triggered) {
        final forged = _withCastingTime(
          spell,
          spell.castingTime.replaceFirst(
            'which you take ',
            'which you take $control',
          ),
        );
        expect(
          () => SrdSpellCastingTimeRules.inspect(forged),
          throwsFormatException,
          reason: '${spell.name} / U+${control.runes.single.toRadixString(16)}',
        );
        expect(
          () => SrdSpellCastingTimeRules.requireSingleTurn(forged),
          throwsFormatException,
        );
      }
    }
  });
}
