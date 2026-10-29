import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/domain/srd_magic_missile_multi_target_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';

const _first = SrdMagicMissileTarget(
  id: 'enemy-1',
  creatureConfirmed: true,
  visibleConfirmed: true,
  within120FeetConfirmed: true,
  noTotalCoverConfirmed: true,
);
const _second = SrdMagicMissileTarget(
  id: 'enemy-2',
  creatureConfirmed: true,
  visibleConfirmed: true,
  within120FeetConfirmed: true,
  noTotalCoverConfirmed: true,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SrdSpellCatalog catalog;
  late SrdSpellDefinition missile;

  setUpAll(() async {
    catalog = await SrdSpellCatalogLoader.load();
    missile = catalog.find('Magic Missile')!;
  });

  SrdMagicMissileAllocation plan({
    int slotLevel = 1,
    Iterable<SrdMagicMissileTarget> targets = const [_first],
    List<String> allocation = const ['enemy-1', 'enemy-1', 'enemy-1'],
    SrdSpellDefinition? spell,
  }) => SrdMagicMissileMultiTargetRules.prepare(
    spell: spell ?? missile,
    slotLevel: slotLevel,
    confirmedTargets: targets,
    dartTargetIds: allocation,
  );

  test('one creature may receive all three simultaneous level-1 darts', () {
    final result = plan();
    expect(result.slotLevel, 1);
    expect(result.dartCount, 3);
    expect(result.dartTargetIds, ['enemy-1', 'enemy-1', 'enemy-1']);
    expect(result.dartsPerTarget, {'enemy-1': 3});
  });

  test('level 2 darts split by confirmed identity in original order', () {
    final result = plan(
      slotLevel: 2,
      targets: const [_first, _second],
      allocation: const ['enemy-2', 'enemy-1', 'enemy-2', 'enemy-1'],
    );
    expect(result.dartCount, 4);
    expect(result.dartTargetIds, [
      'enemy-2',
      'enemy-1',
      'enemy-2',
      'enemy-1',
    ]);
    expect(result.dartsPerTarget, {'enemy-2': 2, 'enemy-1': 2});
  });

  test('ninth-level slots require exactly eleven assigned darts', () {
    final ids = List.filled(11, 'enemy-1');
    final result = plan(slotLevel: 9, allocation: ids);
    expect(result.dartCount, 11);
    expect(result.dartsPerTarget['enemy-1'], 11);
  });

  test('no missing, extra or unassigned darts and no unknown IDs', () {
    for (final ids in <List<String>>[
      const [],
      const ['enemy-1', 'enemy-1'],
      const ['enemy-1', 'enemy-1', 'enemy-1', 'enemy-1'],
      const ['enemy-1', 'unknown', 'enemy-1'],
    ]) {
      expect(() => plan(allocation: ids), throwsFormatException);
    }
    expect(
      () => plan(
        targets: const [_first, _second],
        allocation: const ['enemy-1', 'enemy-1', 'enemy-1'],
      ),
      throwsFormatException,
    );
    expect(() => plan(targets: const []), throwsFormatException);
    expect(
      () => plan(targets: const [_first, _first]),
      throwsFormatException,
    );
  });

  test('unconfirmed target evidence fails closed for every dart', () {
    for (final target in [
      const SrdMagicMissileTarget(
        id: 'enemy-1',
        creatureConfirmed: false,
        visibleConfirmed: true,
        within120FeetConfirmed: true,
        noTotalCoverConfirmed: true,
      ),
      const SrdMagicMissileTarget(
        id: 'enemy-1',
        creatureConfirmed: true,
        visibleConfirmed: false,
        within120FeetConfirmed: true,
        noTotalCoverConfirmed: true,
      ),
      const SrdMagicMissileTarget(
        id: 'enemy-1',
        creatureConfirmed: true,
        visibleConfirmed: true,
        within120FeetConfirmed: false,
        noTotalCoverConfirmed: true,
      ),
      const SrdMagicMissileTarget(
        id: 'enemy-1',
        creatureConfirmed: true,
        visibleConfirmed: true,
        within120FeetConfirmed: true,
        noTotalCoverConfirmed: false,
      ),
    ]) {
      expect(() => plan(targets: [target]), throwsFormatException);
    }
  });

  test('invalid or ambiguous creature identities are rejected', () {
    for (final id in ['', 'enemy 1', ' enemy-1', 'enemy-1\n', '🧙']) {
      expect(
        () => plan(
          targets: [
            SrdMagicMissileTarget(
              id: id,
              creatureConfirmed: true,
              visibleConfirmed: true,
              within120FeetConfirmed: true,
              noTotalCoverConfirmed: true,
            ),
          ],
        ),
        throwsFormatException,
      );
    }
  });

  test('slot boundaries and other spells never authorize allocation', () {
    for (final slot in [-1, 0, 10]) {
      expect(() => plan(slotLevel: slot), throwsFormatException);
    }
    expect(
      () => plan(spell: catalog.find('Shield')!),
      throwsUnsupportedError,
    );
    expect(
      () => plan(spell: catalog.find('Fireball')!),
      throwsUnsupportedError,
    );
  });

  test('plan is immutable and uses snapshots of mutable caller lists', () {
    final selected = ['enemy-1', 'enemy-1', 'enemy-1'];
    final targets = <SrdMagicMissileTarget>[_first];
    final result = plan(targets: targets, allocation: selected);
    selected[0] = 'enemy-2';
    targets.clear();
    expect(result.dartTargetIds, ['enemy-1', 'enemy-1', 'enemy-1']);
    expect(result.dartsPerTarget, {'enemy-1': 3});
    expect(() => result.dartTargetIds.clear(), throwsUnsupportedError);
    expect(
      () => result.dartsPerTarget['enemy-2'] = 1,
      throwsUnsupportedError,
    );
  });
}
