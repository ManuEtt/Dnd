import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:lebendiger_spielleiter/services/voice_controller.dart';
import 'package:lebendiger_spielleiter/ui/app.dart';
import 'package:lebendiger_spielleiter/ui/character_effect_dialog.dart';

class _SilentVoice extends VoiceController {
  @override
  Future<void> stopListening() async {}

  @override
  Future<void> stopSpeaking() async {}

  @override
  Future<void> speak(String text) async {}
}

class _Fixture {
  _Fixture(this.directory, this.databasePath, this.repository, this.controller);

  final Directory directory;
  final String databasePath;
  SqliteCampaignRepository repository;
  GameController controller;
  final voice = _SilentVoice();

  Future<void> mount(WidgetTester tester) =>
      tester.pumpWidget(LivingGameApp(controller: controller, voice: voice));

  Future<void> restart(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    await tester.runAsync(repository.close);
    repository = (await tester.runAsync(
      () => SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: databasePath,
      ),
    ))!;
    controller = GameController(repository: repository);
    await tester.runAsync(controller.initialize);
    expect(controller.error, isNull);
    await mount(tester);
    await tester.pumpAndSettle();
  }
}

Future<_Fixture> _start(WidgetTester tester) async {
  final directory = (await tester.runAsync(
    () => Directory.systemTemp.createTemp('wuerfelraunen-effects-'),
  ))!;
  final databasePath = paths.join(directory.path, 'effects.sqlite');
  final repository = (await tester.runAsync(
    () => SqliteCampaignRepository.open(
      factory: databaseFactoryFfi,
      path: databasePath,
    ),
  ))!;
  final controller = GameController(repository: repository);
  final fixture = _Fixture(directory, databasePath, repository, controller);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    fixture.controller.dispose();
    fixture.voice.dispose();
    await tester.runAsync(fixture.repository.close);
    await tester.runAsync(() => directory.delete(recursive: true));
  });
  await tester.runAsync(controller.createDemo);
  expect(controller.error, isNull);
  await fixture.mount(tester);
  await tester.tap(find.text('Abenteuer'));
  await tester.pumpAndSettle();
  return fixture;
}

Finder _control(String name) => find.byKey(ValueKey('character-effect-$name'));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  expect(finder.hitTestable(), findsOneWidget);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester) async {
  await _tap(
    tester,
    find.byKey(const ValueKey('adventure-confirm-character-effect')),
  );
  expect(find.byType(CharacterEffectDialog), findsOneWidget);
}

Future<void> _enter(WidgetTester tester, String name, String value) async {
  await tester.ensureVisible(_control(name));
  await tester.enterText(_control(name), value);
  await tester.pump();
}

Future<void> _submit(WidgetTester tester, GameController controller) async {
  await tester.ensureVisible(_control('confirm'));
  await tester.pumpAndSettle();
  await tester.tap(_control('confirm'));
  await tester.pump();
  await tester.runAsync(() async {
    for (var i = 0; i < 200 && controller.busy; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });
  expect(controller.busy, isFalse);
  await tester.pumpAndSettle();
}

Future<void> _expectStored(
  WidgetTester tester,
  _Fixture fixture,
  Campaign expected,
) async {
  final stored = await tester.runAsync(
    () => fixture.repository.getCampaign(expected.id),
  );
  expect(stored!.toJson(), expected.toJson());
}

Future<void> _showHeader(WidgetTester tester) async {
  // Confirmed effects scroll the story to its new message. Return to the
  // lazily built header before checking the visible character summary.
  await tester.scrollUntilVisible(
    find.byKey(const ValueKey('adventure-confirm-character-effect')),
    -200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(sqfliteFfiInit);
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets(
    'bestätigter UI-Schaden speichert TP, Quelle und Ereignis bis Neustart',
    (tester) async {
      final fixture = await _start(tester);
      final before = fixture.controller.currentCampaign!;
      await _open(tester);
      await _enter(tester, 'source', '  Bestätigte Feuerfalle  ');
      await _enter(tester, 'amount', '9');
      await _tap(tester, _control('damage-type'));
      await tester.tap(find.text('Feuer').last);
      await tester.pumpAndSettle();
      await _tap(tester, _control('resistant'));
      await _submit(tester, fixture.controller);

      expect(fixture.controller.error, isNull);
      expect(find.byType(CharacterEffectDialog), findsNothing);
      final confirmed = fixture.controller.currentCampaign!;
      expect(confirmed.hero.hitPoints, 8);
      expect(confirmed.revision, before.revision + 1);
      expect(confirmed.events, hasLength(before.events.length + 1));
      expect(confirmed.events.last.type, 'effect.damage');
      expect(confirmed.events.last.payload['source'], 'Bestätigte Feuerfalle');
      expect(confirmed.events.last.payload['targetId'], before.hero.id);
      expect(confirmed.events.last.payload['damage'], 4);
      expect(confirmed.events.last.payload['components'], [
        {
          'type': 'fire',
          'incoming': 9,
          'applied': 4,
          'immune': false,
          'resistant': true,
          'vulnerable': false,
        },
      ]);
      await _showHeader(tester);
      expect(find.textContaining('Liora · TP 8/12'), findsOneWidget);
      await _expectStored(tester, fixture, confirmed);

      await fixture.restart(tester);
      expect(fixture.controller.currentCampaign!.toJson(), confirmed.toJson());
      await tester.tap(find.text('Abenteuer'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Liora · TP 8/12'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Abbruch des tatsächlichen Effektdialogs schreibt keine Revision',
    (tester) async {
      final fixture = await _start(tester);
      final before = fixture.controller.currentCampaign!;
      await _open(tester);
      await _enter(tester, 'source', 'Verworfene Falle');
      await _enter(tester, 'amount', '9');
      await _tap(tester, _control('cancel'));
      expect(fixture.controller.currentCampaign!.toJson(), before.toJson());
      expect(find.textContaining('Liora · TP 12/12'), findsOneWidget);
      await _expectStored(tester, fixture, before);
      expect(
        await tester.runAsync(
          () => fixture.repository.reconstructCampaign(
            before.id,
            revision: before.revision + 1,
          ),
        ),
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'später SQLite-Fehler rollt UI-Schaden, Snapshot und Ereignis zurück',
    (tester) async {
      final fixture = await _start(tester);
      final before = fixture.controller.currentCampaign!;
      // Failure occurs after the snapshot update, at the event insertion.
      final database = (await tester.runAsync(
        () => databaseFactoryFfi.openDatabase(fixture.databasePath),
      ))!;
      await tester.runAsync(
        () => database.execute('''
CREATE TRIGGER reject_character_effect
BEFORE INSERT ON game_events
WHEN instr(NEW.event_json, '"effect.damage"') > 0
BEGIN
  SELECT RAISE(ABORT, 'controlled effect write rejection');
END
'''),
      );
      await _open(tester);
      await _enter(tester, 'source', 'Bestätigte Falle');
      await _enter(tester, 'amount', '5');
      await _submit(tester, fixture.controller);

      expect(fixture.controller.error, isNotNull);
      expect(find.byType(MaterialBanner), findsOneWidget);
      expect(find.textContaining('Liora · TP 12/12'), findsOneWidget);
      expect(fixture.controller.currentCampaign!.toJson(), before.toJson());
      await _expectStored(tester, fixture, before);
      expect(
        await tester.runAsync(
          () => fixture.repository.reconstructCampaign(
            before.id,
            revision: before.revision + 1,
          ),
        ),
        isNull,
      );
      await fixture.restart(tester);
      expect(fixture.controller.currentCampaign!.toJson(), before.toJson());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'zwischenzeitlich geänderter Charakter verwirft offene Effekteingabe',
    (tester) async {
      final fixture = await _start(tester);
      final before = fixture.controller.currentCampaign!;
      await _open(tester);
      await _enter(tester, 'source', 'Veraltete bestätigte Falle');
      await _enter(tester, 'amount', '5');
      await tester.runAsync(
        () => fixture.controller.saveHero(before.hero.copyWith(hitPoints: 11)),
      );
      expect(fixture.controller.error, isNull);
      final newer = fixture.controller.currentCampaign!;
      expect(newer.revision, before.revision + 1);
      await tester.pump();
      await _submit(tester, fixture.controller);

      expect(fixture.controller.error, contains('erneut öffnen'));
      expect(fixture.controller.currentCampaign!.toJson(), newer.toJson());
      expect(find.textContaining('Liora · TP 11/12'), findsOneWidget);
      expect(
        newer.events.where((event) => event.type == 'effect.damage'),
        isEmpty,
      );
      await _expectStored(tester, fixture, newer);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('älterer UI-Stand überschreibt neuere SQLite-Revision nicht', (
    tester,
  ) async {
    final fixture = await _start(tester);
    final before = fixture.controller.currentCampaign!;
    await _open(tester);
    await _enter(tester, 'source', 'Bestätigte Falle');
    await _enter(tester, 'amount', '5');
    final newer = before.copyWith(
      revision: before.revision + 1,
      scene: 'Inzwischen bestätigte neue Szene',
      hero: before.hero.copyWith(hitPoints: 10),
    );
    await tester.runAsync(() => fixture.repository.saveCampaign(newer));
    await _submit(tester, fixture.controller);

    expect(fixture.controller.error, contains('inzwischen geändert'));
    expect(fixture.controller.currentCampaign!.toJson(), before.toJson());
    expect(find.textContaining('Liora · TP 12/12'), findsOneWidget);
    await _expectStored(tester, fixture, newer);
    await fixture.restart(tester);
    expect(fixture.controller.currentCampaign!.toJson(), newer.toJson());
    expect(tester.takeException(), isNull);
  });

  for (final temporary in [false, true]) {
    testWidgets(
      'UI-${temporary ? 'temporäre TP' : 'Heilung'} verwendet eigenen Effekt und speichert ihn',
      (tester) async {
        final fixture = await _start(tester);
        await tester.runAsync(
          () => fixture.controller.saveHero(
            fixture.controller.currentCampaign!.hero.copyWith(hitPoints: 4),
          ),
        );
        expect(fixture.controller.error, isNull);
        final before = fixture.controller.currentCampaign!;
        await tester.pumpAndSettle();
        await _open(tester);
        await _tap(tester, _control('kind'));
        await tester.tap(
          find.text(temporary ? 'Temporäre TP' : 'Heilung').last,
        );
        await tester.pumpAndSettle();
        await _enter(tester, 'source', 'Bestätigter Schutz');
        await _enter(tester, 'amount', '6');
        await _submit(tester, fixture.controller);

        expect(fixture.controller.error, isNull);
        final confirmed = fixture.controller.currentCampaign!;
        expect(confirmed.revision, before.revision + 1);
        expect(confirmed.events, hasLength(before.events.length + 1));
        expect(
          confirmed.events.last.type,
          temporary ? 'effect.temporaryHitPoints' : 'effect.healing',
        );
        expect(confirmed.hero.hitPoints, temporary ? 4 : 10);
        expect(confirmed.hero.temporaryHitPoints, temporary ? 6 : 0);
        await _expectStored(tester, fixture, confirmed);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
