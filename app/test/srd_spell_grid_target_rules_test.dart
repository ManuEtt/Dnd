import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_grid_target_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_preflight_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_target_rules.dart';

const _caster = SrdGridCell(0, 0);

SrdSpellGridMap _map({
  int width = 30,
  int height = 30,
  bool surveyed = true,
  Iterable<SrdGridCell> blockers = const [],
}) => SrdSpellGridMap(
  width: width,
  height: height,
  fullBlockers: blockers,
  fullBlockersSurveyedConfirmed: surveyed,
);

SrdSpellGridTargetRequest _request(
  SrdSpellGridMap map,
  SrdGridCell origin, {
  bool touch = false,
}) => SrdSpellGridTargetRequest(
  map: map,
  caster: _caster,
  origin: origin,
  withinTouchReachConfirmed: touch,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
  });

  test('Chebyshev 5-foot grid distance handles diagonals and boundaries', () {
    expect(SrdSpellGridTargetRules.distanceFeet(_caster, _caster), 0);
    expect(
      SrdSpellGridTargetRules.distanceFeet(
        _caster,
        const SrdGridCell(4, 0),
      ),
      20,
    );
    expect(
      SrdSpellGridTargetRules.distanceFeet(
        _caster,
        const SrdGridCell(4, 4),
      ),
      20,
    );
    expect(
      SrdSpellGridTargetRules.distanceFeet(
        _caster,
        const SrdGridCell(4, 2),
      ),
      20,
    );
    expect(
      SrdSpellGridTargetRules.distanceFeet(
        const SrdGridCell(8, 12),
        const SrdGridCell(3, 9),
      ),
      25,
    );

    final missile = catalog.find('Magic Missile')!;
    final map = _map();
    final onLimit = SrdSpellGridTargetRules.validateOrigin(
      missile,
      _request(map, const SrdGridCell(24, 24)),
    );
    expect(onLimit.range, '120 feet');
    expect(onLimit.originDistanceFeet, 120);
    expect(
      () => SrdSpellGridTargetRules.validateOrigin(
        missile,
        _request(map, const SrdGridCell(25, 24)),
      ),
      throwsFormatException,
    );
  });

  test('full blocker on the ray rejects spell despite valid distance', () {
    final spell = catalog.find('Magic Missile')!;
    final blocked = _map(
      blockers: const [SrdGridCell(2, 0)],
    );
    expect(
      () => SrdSpellGridTargetRules.validateOrigin(
        spell,
        _request(blocked, const SrdGridCell(4, 0)),
      ),
      throwsFormatException,
    );
    final clear = _map(
      blockers: const [SrdGridCell(2, 1)],
    );
    expect(
      SrdSpellGridTargetRules.validateOrigin(
        spell,
        _request(clear, const SrdGridCell(4, 0)),
      ).originDistanceFeet,
      20,
    );
  });

  test('an exact corner graze is conservatively considered blocked', () {
    final spell = catalog.find('Magic Missile')!;
    final map = _map(
      blockers: const [SrdGridCell(1, 0)],
    );
    expect(
      () => SrdSpellGridTargetRules.validateOrigin(
        spell,
        _request(map, const SrdGridCell(2, 2)),
      ),
      throwsFormatException,
    );
    expect(
      SrdSpellGridTargetRules.validateOrigin(
        spell,
        _request(
          _map(blockers: const [SrdGridCell(3, 0)]),
          const SrdGridCell(2, 2),
        ),
      ).originDistanceFeet,
      10,
    );
  });

  test('unknown map, wall in caster/origin square and out-of-bounds fail', () {
    final spell = catalog.find('Magic Missile')!;
    for (final map in [
      _map(surveyed: false),
      _map(blockers: const [SrdGridCell(0, 0)]),
      _map(blockers: const [SrdGridCell(2, 0)]),
    ]) {
      expect(
        () => SrdSpellGridTargetRules.validateOrigin(
          spell,
          _request(map, const SrdGridCell(2, 0)),
        ),
        throwsFormatException,
      );
    }
    expect(
      () => SrdSpellGridTargetRules.validateOrigin(
        spell,
        _request(_map(width: 3), const SrdGridCell(3, 0)),
      ),
      throwsFormatException,
    );
    expect(
      () => SrdSpellGridTargetRules.validateOrigin(
        spell,
        _request(_map(), const SrdGridCell(-1, 0)),
      ),
      throwsFormatException,
    );
    expect(
      () => _map(blockers: const [SrdGridCell(-1, 0)]),
      throwsFormatException,
    );
    expect(() => _map(width: 0), throwsFormatException);
    expect(() => _map(height: 201), throwsFormatException);
  });

  test('obstacles are copied and cannot be mutated after map creation', () {
    final blockers = <SrdGridCell>{const SrdGridCell(1, 0)};
    final map = _map(blockers: blockers);
    blockers.clear();
    expect(map.fullBlockers, contains(const SrdGridCell(1, 0)));
    expect(
      () => map.fullBlockers.add(const SrdGridCell(2, 0)),
      throwsUnsupportedError,
    );
    expect(
      () => SrdSpellGridTargetRules.validateOrigin(
        catalog.find('Magic Missile')!,
        _request(map, const SrdGridCell(3, 0)),
      ),
      throwsFormatException,
    );
  });

  test('Self and Touch preserve origin semantics and real reach confirmation', () {
    final self = catalog.find('Burning Hands')!;
    final touch = catalog.find('Cure Wounds')!;
    expect(
      SrdSpellGridTargetRules.validateOrigin(
        self,
        _request(_map(), _caster),
      ).mode,
      SrdSpellOriginMode.caster,
    );
    expect(
      () => SrdSpellGridTargetRules.validateOrigin(
        self,
        _request(_map(), const SrdGridCell(0, 1)),
      ),
      throwsFormatException,
    );

    expect(
      SrdSpellGridTargetRules.validateOrigin(
        touch,
        _request(_map(), const SrdGridCell(0, 1), touch: true),
      ).mode,
      SrdSpellOriginMode.touched,
    );
    expect(
      () => SrdSpellGridTargetRules.validateOrigin(
        touch,
        _request(_map(), const SrdGridCell(0, 1)),
      ),
      throwsFormatException,
    );
    expect(
      () => SrdSpellGridTargetRules.validateOrigin(
        touch,
        _request(
          _map(blockers: const [SrdGridCell(0, 1)]),
          const SrdGridCell(0, 1),
          touch: true,
        ),
      ),
      throwsFormatException,
    );
  });

  test('unsupported special range stays unsupported with a surveyed map', () {
    final spell = catalog.spells.firstWhere((entry) => entry.range == 'Sight');
    expect(
      () => SrdSpellGridTargetRules.validateOrigin(
        spell,
        _request(_map(), const SrdGridCell(1, 1)),
      ),
      throwsUnsupportedError,
    );
  });

  test('preflight cannot mix manually claimed geometry with grid evidence', () {
    final spell = catalog.find('Magic Missile')!;
    final hero = HeroCharacter(
      id: 'grid-wizard',
      name: 'Rastermagier',
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
    SrdSpellCastPlan plan({
      required SrdSpellGridTargetRequest request,
      bool confirmed = true,
      SrdSpellTargetFacts? extra,
    }) => SrdSpellPreflightRules.preflight(
      hero,
      spell: spell,
      castingClass: 'Magier',
      slotLevel: 1,
      actionAvailableConfirmed: true,
      targetRulesConfirmed: confirmed,
      gridTarget: request,
      targetFacts: extra,
      verbalComponentConfirmed: true,
      somaticComponentConfirmed: true,
      slotTurnLimitConfirmed: true,
    );

    final map = _map();
    final checked = plan(
      request: _request(map, const SrdGridCell(3, 4)),
    );
    expect(checked.targetAssessment!.originDistanceFeet, 20);
    expect(checked.targetAssessment!.maxOriginDistanceFeet, 120);
    expect(hero.spentSpellSlots, isEmpty);

    expect(
      () => plan(
        request: _request(
          _map(blockers: const [SrdGridCell(1, 0)]),
          const SrdGridCell(2, 0),
        ),
      ),
      throwsFormatException,
    );
    expect(
      () => plan(
        request: _request(map, const SrdGridCell(3, 4)),
        confirmed: false,
      ),
      throwsFormatException,
    );
    expect(
      () => plan(
        request: _request(map, const SrdGridCell(3, 4)),
        extra: const SrdSpellTargetFacts(
          mode: SrdSpellOriginMode.distant,
          originDistanceFeet: 5,
          clearPathConfirmed: true,
        ),
      ),
      throwsFormatException,
    );
  });
}
