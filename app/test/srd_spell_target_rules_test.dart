import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_preflight_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_target_rules.dart';

const _self = SrdSpellTargetFacts(
  mode: SrdSpellOriginMode.caster,
  originDistanceFeet: 0,
);
const _touch = SrdSpellTargetFacts(
  mode: SrdSpellOriginMode.touched,
  withinTouchReachConfirmed: true,
  clearPathConfirmed: true,
);
SrdSpellTargetFacts _ranged(int feet, {bool pathClear = true}) =>
    SrdSpellTargetFacts(
      mode: SrdSpellOriginMode.distant,
      originDistanceFeet: feet,
      clearPathConfirmed: pathClear,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('all 339 spell ranges classify without inventing unsupported ranges', () {
    var unsupported = 0;
    for (final spell in catalog.spells) {
      final facts = switch (spell.range) {
        'Self' => _self,
        'Touch' => _touch,
        _ => _ranged(0),
      };
      if (const {'Sight', 'Unlimited', 'Special'}.contains(spell.range)) {
        unsupported++;
        expect(
          () => SrdSpellTargetRules.validateOrigin(spell, facts),
          throwsUnsupportedError,
          reason: spell.name,
        );
      } else {
        final checked = SrdSpellTargetRules.validateOrigin(spell, facts);
        expect(checked.range, spell.range, reason: spell.name);
      }
    }
    expect(unsupported, 3);
  });

  test('distance origin accepts boundary but rejects excess and missing path',
      () {
    final missile = catalog.find('Magic Missile')!;
    expect(missile.range, '120 feet');
    final valid = SrdSpellTargetRules.validateOrigin(missile, _ranged(120));
    expect(valid.maxOriginDistanceFeet, 120);
    expect(valid.originDistanceFeet, 120);
    expect(valid.mode, SrdSpellOriginMode.distant);
    for (final facts in [
      _ranged(121),
      _ranged(-1),
      _ranged(30, pathClear: false),
      const SrdSpellTargetFacts(
        mode: SrdSpellOriginMode.distant,
        clearPathConfirmed: true,
      ),
      _self,
    ]) {
      expect(
        () => SrdSpellTargetRules.validateOrigin(missile, facts),
        throwsFormatException,
      );
    }
    // Line of sight is NOT a blanket precondition: only a clear path is.
    expect(
      SrdSpellTargetRules.validateOrigin(missile, _ranged(0))
          .originDistanceFeet,
      0,
    );
  });

  test('Touch needs explicit contact within reach and no total cover', () {
    final heal = catalog.find('Cure Wounds')!;
    expect(
      SrdSpellTargetRules.validateOrigin(heal, _touch).range,
      'Touch',
    );
    for (final facts in [
      _ranged(0),
      _self,
      const SrdSpellTargetFacts(
        mode: SrdSpellOriginMode.touched,
        clearPathConfirmed: true,
      ),
      const SrdSpellTargetFacts(
        mode: SrdSpellOriginMode.touched,
        withinTouchReachConfirmed: true,
      ),
      const SrdSpellTargetFacts(
        mode: SrdSpellOriginMode.touched,
        originDistanceFeet: 5,
        withinTouchReachConfirmed: true,
        clearPathConfirmed: true,
      ),
    ]) {
      expect(
        () => SrdSpellTargetRules.validateOrigin(heal, facts),
        throwsFormatException,
      );
    }
  });

  test('Self specifies origin, not automatically all affected creatures', () {
    final cone = catalog.find('Burning Hands')!;
    expect(cone.range, 'Self');
    expect(
      SrdSpellTargetRules.validateOrigin(cone, _self).mode,
      SrdSpellOriginMode.caster,
    );
    for (final facts in [
      _ranged(0),
      _touch,
      const SrdSpellTargetFacts(mode: SrdSpellOriginMode.caster),
      const SrdSpellTargetFacts(
        mode: SrdSpellOriginMode.caster,
        originDistanceFeet: 15,
      ),
    ]) {
      expect(
        () => SrdSpellTargetRules.validateOrigin(cone, facts),
        throwsFormatException,
      );
    }
  });

  test('feet and mile conversions are exact, special ranges fail closed', () {
    expect(SrdSpellTargetRules.maxRangeFeet('1 mile'), 5280);
    expect(SrdSpellTargetRules.maxRangeFeet('500 miles'), 2640000);
    expect(SrdSpellTargetRules.maxRangeFeet('5 feet'), 5);
    expect(SrdSpellTargetRules.maxRangeFeet('Sight'), isNull);
    expect(SrdSpellTargetRules.maxRangeFeet('Unlimited'), isNull);
    expect(SrdSpellTargetRules.maxRangeFeet('Special'), isNull);
    final far = catalog.spells.firstWhere((s) => s.range == '1 mile');
    expect(
      SrdSpellTargetRules.validateOrigin(far, _ranged(5280))
          .originDistanceFeet,
      5280,
    );
    expect(
      () => SrdSpellTargetRules.validateOrigin(far, _ranged(5281)),
      throwsFormatException,
    );
  });

  test('typed geometry joins preflight without overruling specific targeting',
      () {
    final missile = catalog.find('Magic Missile')!;
    final hero = HeroCharacter(
      id: 'target-caster',
      name: 'Raumtest',
      className: 'Magier',
      level: 5,
      spells: const ['Magisches Geschoss'],
      abilities: const {
        'strength': 10,
        'dexterity': 12,
        'constitution': 14,
        'intelligence': 16,
        'wisdom': 12,
        'charisma': 14,
      },
      hitPoints: 25,
      maxHitPoints: 25,
    );

    SrdSpellCastPlan preflight({
      bool targetApproved = true,
      SrdSpellTargetFacts? facts,
    }) => SrdSpellPreflightRules.preflight(
      hero,
      spell: missile,
      castingClass: 'Magier',
      slotLevel: 1,
      actionAvailableConfirmed: true,
      targetRulesConfirmed: targetApproved,
      targetFacts: facts,
      verbalComponentConfirmed: true,
      somaticComponentConfirmed: true,
      slotTurnLimitConfirmed: true,
    );

    final checked = preflight(facts: _ranged(119));
    expect(checked.targetAssessment!.originDistanceFeet, 119);
    expect(preflight().targetAssessment, isNull);
    expect(
      () => preflight(targetApproved: false, facts: _ranged(119)),
      throwsFormatException,
    );
    expect(
      () => preflight(facts: _ranged(121)),
      throwsFormatException,
    );
    expect(
      () => preflight(facts: _ranged(10, pathClear: false)),
      throwsFormatException,
    );
  });
}
