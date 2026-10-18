import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/dice_engine.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MinimumRandom implements Random {
  @override
  int nextInt(int max) => 0;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => 0;
}

GameEngine _engine() => GameEngine(
  dice: DiceEngine(random: _MinimumRandom()),
  clock: () => DateTime.utc(2026, 10, 16),
);

const _commands = {
  'attack': 'Ich greife an.',
  'escape': 'Ich fliehe.',
  'perception': 'Ich untersuche die Umgebung.',
};

// Demo modifiers: Strength +3, Dexterity +2, Wisdom +1, proficiency +2.
const _baseModifiers = {'attack': 5, 'escape': 2, 'perception': 3};

Campaign _fixture(GameEngine engine, String type, int exhaustion) {
  final demo = engine.createDemo();
  return demo.copyWith(
    hero: demo.hero.copyWith(exhaustionLevel: exhaustion),
    encounter: type == 'perception'
        ? null
        : const Encounter(
            id: 'verified-target',
            enemyName: 'Testgegner',
            enemyHitPoints: 30,
            enemyMaxHitPoints: 30,
          ),
  );
}

void main() {
  group('Erschöpfte offene W20-Proben', () {
    for (final type in _commands.keys) {
      test('$type: Erschöpfung 0–5 bleibt nach JSON-Rundlauf spielbar', () {
        for (var exhaustion = 0; exhaustion < 6; exhaustion++) {
          final engine = _engine();
          final initial = _fixture(engine, type, exhaustion);
          final requested = engine.act(initial, _commands[type]!).campaign;
          final expected = _baseModifiers[type]! - 2 * exhaustion;
          expect(requested.pendingRoll?.type, type);
          expect(requested.pendingRoll?.modifier, expected);
          final restored = Campaign.fromJson(requested.toJson());
          final resolved = engine.resolveRoll(restored, natural: 12);
          final recorded = resolved.events.single.payload['roll'] as Map;
          expect(recorded['natural'], 12);
          expect(recorded['modifier'], expected);
          expect(recorded['total'], 12 + expected);
          expect(resolved.campaign.pendingRoll, isNull);
          expect(initial.hero.exhaustionLevel, exhaustion);
        }
      });

      test('$type: Import weist ausgelassenen oder doppelten Malus ab', () {
        final engine = _engine();
        final requested = engine
            .act(_fixture(engine, type, 2), _commands[type]!)
            .campaign;
        for (final forged in [
          _baseModifiers[type]!,
          _baseModifiers[type]! - 8,
        ]) {
          final json = requested.toJson();
          final pending = Map<String, dynamic>.from(json['pendingRoll'] as Map);
          json['pendingRoll'] = {...pending, 'modifier': forged};
          expect(() => Campaign.fromJson(json), throwsFormatException);
        }
      });
    }

    test('Todesrettung behält Naturwurf; Erschöpfung zählt einmal', () {
      final engine = _engine();
      final initial = _fixture(engine, 'perception', 2);
      final fallen = initial.copyWith(
        hero: initial.hero.copyWith(hitPoints: 0, conditions: ['bewusstlos']),
      );
      final requested = engine.act(fallen, 'Todesrettung').campaign;
      final restored = Campaign.fromJson(requested.toJson());
      expect(restored.pendingRoll?.modifier, -4);
      expect(restored.pendingRoll?.deathSaveRulesVersion, 1);
      expect(
        engine.resolveRoll(restored, natural: 13).campaign.hero.deathFailures,
        1,
      );
      expect(
        engine.resolveRoll(restored, natural: 14).campaign.hero.deathSuccesses,
        1,
      );
    });
  });

  group('Erschöpfte Proben über Controller und echtes SQLite', () {
    sqfliteFfiInit();
    late Directory directory;
    late String databasePath;
    late SqliteCampaignRepository repository;
    late GameController controller;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('exhausted-roll-');
      databasePath = paths.join(directory.path, 'campaign.sqlite');
      repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: databasePath,
      );
      controller = GameController(repository: repository, engine: _engine());
      await controller.initialize();
    });

    tearDown(() async {
      controller.dispose();
      await repository.close();
      await directory.delete(recursive: true);
    });

    for (final type in _commands.keys) {
      test(
        '$type: offener Wurf überlebt Neustart und bleibt auflösbar',
        () async {
          final engine = controller.engine;
          final initial = _fixture(engine, type, 2);
          await repository.saveCampaign(initial);
          await controller.openCampaign(initial.id);
          await controller.sendAction(_commands[type]!);
          expect(controller.error, isNull);
          final checkpoint = controller.currentCampaign!;
          expect(checkpoint.pendingRoll?.modifier, _baseModifiers[type]! - 4);
          expect(
            checkpoint.events.last.payload['stateAfter'],
            checkpoint.copyWith(events: const []).toJson(),
          );

          controller.dispose();
          await repository.close();
          repository = await SqliteCampaignRepository.open(
            factory: databaseFactoryFfi,
            path: databasePath,
          );
          controller = GameController(
            repository: repository,
            engine: _engine(),
          );
          await controller.initialize();
          expect(controller.error, isNull);
          expect(controller.currentCampaign!.toJson(), checkpoint.toJson());
          await controller.resolveRoll(natural: 12);
          expect(controller.error, isNull);
          final confirmed = controller.currentCampaign!;
          final recorded = confirmed.events.last.payload['roll'] as Map;
          expect(recorded['total'], 12 + _baseModifiers[type]! - 4);
          expect(confirmed.pendingRoll, isNull);
          expect(
            (await repository.getCampaign(initial.id))!.toJson(),
            confirmed.toJson(),
          );
        },
      );
    }
  });
}
