import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/cover_rules.dart';
import 'package:lebendiger_spielleiter/domain/game_engine.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test(
    'bestätigte Zauberwirkung übersteht Neustart, drei Runden und Journal',
    () async {
      final folder = await Directory.systemTemp.createTemp(
        'spell-effect-sqlite-',
      );
      final path = p.join(folder.path, 'save.sqlite');
      var repo = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final engine = GameEngine();
      try {
        final hero = engine.createDemo().hero.copyWith(
          spells: ['Segen'],
          concentratingOn: 'Segen',
        );
        final original = engine
            .createDemo(hero: hero)
            .copyWith(
              encounter: const Encounter(
                id: 'sql-battle',
                enemyName: 'Wächter',
                enemyHitPoints: 40,
                enemyMaxHitPoints: 40,
                heroCover: CoverLevel.total,
                round: 2,
              ),
            );
        await repo.saveCampaign(original);
        final updated = engine.registerConfirmedSpellEffect(
          original,
          spellName: 'Segen',
          source: 'Bestätigter Regeleffekt',
          concentrationBound: true,
          ownTurnEnds: 3,
        );
        await repo.saveCampaign(
          updated.campaign,
          events: updated.events,
          expectedRevision: original.revision,
        );
        var state = (await repo.getCampaign(original.id))!;
        expect(state.hero.confirmedSpellEffects, hasLength(1));
        expect(
          state.hero.confirmedSpellEffects.single.expiresAtOwnTurnEndRound,
          4,
        );
        expect(state.events.last.type, 'spell.effect.confirmed');

        final first = engine.endHeroTurn(state);
        await repo.saveCampaign(
          first.campaign,
          events: first.events,
          expectedRevision: state.revision,
        );
        await repo.close();
        repo = await SqliteCampaignRepository.open(
          factory: databaseFactoryFfi,
          path: path,
        );
        state = (await repo.getCampaign(original.id))!;
        expect(state.hero.confirmedSpellEffects, hasLength(1));
        expect(state.encounter!.round, 3);
        for (var i = 0; i < 2; i++) {
          final after = engine.endHeroTurn(state);
          await repo.saveCampaign(
            after.campaign,
            events: after.events,
            expectedRevision: state.revision,
          );
          state = (await repo.getCampaign(original.id))!;
        }
        expect(state.hero.confirmedSpellEffects, isEmpty);
        expect(state.hero.concentratingOn, isEmpty);
        expect(state.encounter!.round, 5);
        final journal = await repo.reconstructCampaign(
          original.id,
          revision: updated.campaign.revision,
        );
        expect(journal?.hero.confirmedSpellEffects, hasLength(1));
        expect(journal?.hero.concentratingOn, 'Segen');
      } finally {
        await repo.close();
        await folder.delete(recursive: true);
      }
    },
  );

  test(
    'veraltete Controllerrevision darf Zaubereffekt nicht doppelt speichern',
    () async {
      final folder = await Directory.systemTemp.createTemp(
        'spell-effect-revision-',
      );
      final path = p.join(folder.path, 'save.sqlite');
      final repo = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: path,
      );
      final controller = GameController(repository: repo);
      try {
        await controller.createDemo();
        final initial = controller.currentCampaign!;
        await controller.registerConfirmedSpellEffect(
          campaignId: initial.id,
          expectedRevision: initial.revision,
          spellName: 'Nicht bekannt',
          source: 'Quelle',
          concentrationBound: false,
          ownTurnEnds: null,
        );
        expect(controller.error, isNotNull);
        expect(controller.currentCampaign!.toJson(), initial.toJson());
        expect(
          (await repo.getCampaign(initial.id))!.toJson(),
          initial.toJson(),
        );
      } finally {
        controller.dispose();
        await repo.close();
        await folder.delete(recursive: true);
      }
    },
  );
}
