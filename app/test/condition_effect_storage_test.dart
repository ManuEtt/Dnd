import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/condition_effects.dart';
import 'package:lebendiger_spielleiter/domain/cover_rules.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test(
    'Quellenänderung wird atomar gespeichert, neu gestartet und entfernt',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'condition-source-',
      );
      final path = p.join(directory.path, 'save.sqlite');
      var repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      var controller = GameController(repository: repository);
      try {
        await controller.createDemo();
        expect(controller.error, isNull);
        final initial = controller.currentCampaign!;
        await controller.applyConditionEffect(
          campaignId: initial.id,
          expectedRevision: initial.revision,
          source: 'Falle',
          condition: 'vergiftet',
          duration: ConditionEffectDuration.untilRemoved,
        );
        expect(controller.error, isNull);
        final confirmed = controller.currentCampaign!;
        expect(confirmed.revision, initial.revision + 1);
        expect(confirmed.hero.conditionEffects, hasLength(1));
        expect(confirmed.events.last.type, 'condition.effect.added');
        expect(
          (await repository.getCampaign(initial.id))!.toJson(),
          confirmed.toJson(),
        );
        controller.dispose();
        await repository.close();
        repository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        controller = GameController(repository: repository);
        await controller.initialize();
        expect(controller.error, isNull);
        expect(controller.currentCampaign!.toJson(), confirmed.toJson());

        await controller.removeConditionEffect(
          campaignId: confirmed.id,
          expectedRevision: confirmed.revision,
          effectId: confirmed.hero.conditionEffects.single.id,
        );
        expect(controller.error, isNull);
        expect(controller.currentCampaign!.hero.conditionEffects, isEmpty);
        expect(
          controller.currentCampaign!.events.last.type,
          'condition.effect.removed',
        );
        expect(
          (await repository.getCampaign(initial.id))!.toJson(),
          controller.currentCampaign!.toJson(),
        );
      } finally {
        controller.dispose();
        await repository.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'alte Dialogrevision und fehlgeschlagener SQLite-Insert ändern nichts',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'condition-rollback-',
      );
      final path = p.join(directory.path, 'save.sqlite');
      final repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final controller = GameController(repository: repository);
      try {
        await controller.createDemo();
        final initial = controller.currentCampaign!;
        await controller.applyConditionEffect(
          campaignId: initial.id,
          expectedRevision: initial.revision,
          condition: 'vergiftet',
          source: 'Quelle A',
          duration: ConditionEffectDuration.untilRemoved,
        );
        final latest = controller.currentCampaign!;
        await controller.applyConditionEffect(
          campaignId: latest.id,
          expectedRevision: initial.revision,
          condition: 'blind',
          source: 'Veralteter Dialog',
          duration: ConditionEffectDuration.untilRemoved,
        );
        expect(controller.error, contains('erneut öffnen'));
        expect(controller.currentCampaign!.toJson(), latest.toJson());

        final database = await databaseFactoryFfi.openDatabase(path);
        try {
          await database.execute('''
CREATE TRIGGER reject_sourced_condition
BEFORE INSERT ON game_events
WHEN instr(NEW.event_json, '"condition.effect.removed"') > 0
BEGIN
  SELECT RAISE(ABORT, 'condition insert failed');
END
''');
          await controller.removeConditionEffect(
            campaignId: latest.id,
            expectedRevision: latest.revision,
            effectId: latest.hero.conditionEffects.single.id,
          );
          expect(controller.error, isNotNull);
          expect(controller.currentCampaign!.toJson(), latest.toJson());
          expect(
            (await repository.getCampaign(latest.id))!.toJson(),
            latest.toJson(),
          );
          expect(
            await repository.reconstructCampaign(
              latest.id,
              revision: latest.revision + 1,
            ),
            isNull,
          );
        } finally {
          await database.close();
        }
      } finally {
        controller.dispose();
        await repository.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'bestätigte Drei-Zug-Dauer bleibt über SQLite-Neustart erhalten und endet genau einmal',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'condition-multiturn-',
      );
      final path = p.join(directory.path, 'save.sqlite');
      var repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final engine = GameEngine();
      try {
        final initial = engine.createDemo().copyWith(
          encounter: const Encounter(
            id: 'dauer-kampf',
            enemyName: 'Wächter',
            enemyHitPoints: 20,
            enemyMaxHitPoints: 20,
            heroCover: CoverLevel.total,
            round: 2,
          ),
        );
        await repository.saveCampaign(initial);
        final confirmed = engine.applyConditionEffect(
          initial,
          source: 'Bestätigte Zauberquelle',
          condition: 'vergiftet',
          duration: ConditionEffectDuration.threeOwnTurnEnds,
        );
        await repository.saveCampaign(
          confirmed.campaign,
          events: confirmed.events,
          expectedRevision: initial.revision,
        );
        final withEffect = (await repository.getCampaign(initial.id))!;
        expect(withEffect.hero.conditionEffects.single.expiresAtOwnTurnEndRound, 4);
        final firstTurn = engine.endHeroTurn(withEffect);
        await repository.saveCampaign(
          firstTurn.campaign,
          events: firstTurn.events,
          expectedRevision: withEffect.revision,
        );
        await repository.close();
        repository = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        var restored = (await repository.getCampaign(initial.id))!;
        expect(restored.encounter!.round, 3);
        expect(restored.hero.conditionEffects.single.expiresAtOwnTurnEndRound, 4);
        for (var i = 0; i < 2; i++) {
          final next = engine.endHeroTurn(restored);
          await repository.saveCampaign(
            next.campaign,
            events: next.events,
            expectedRevision: restored.revision,
          );
          restored = (await repository.getCampaign(initial.id))!;
        }
        expect(restored.hero.conditionEffects, isEmpty);
        expect(restored.hero.conditions, isNot(contains('vergiftet')));
        expect(restored.encounter!.round, 5);
        expect((await repository.getCampaign(initial.id))!.toJson(), restored.toJson());
      } finally {
        await repository.close();
        await directory.delete(recursive: true);
      }
    },
  );

}
