import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/services/backend_narrator.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  test(
    'real Dart transport, Node backend and SQLite complete a narration turn and fall back after server shutdown',
    () async {
      sqfliteFfiInit();
      final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = probe.port;
      await probe.close();
      // Only synthetic local test credentials; no provider and no paid requests.
      const access = 'local-smoke-access-0123456789abcdef';
      final entry = File('../backend/dist/server.js').absolute;
      expect(entry.existsSync(), isTrue, reason: 'Build backend first.');
      final server = await Process.start(
        'node',
        [entry.path],
        environment: {
          'HOST': '127.0.0.1',
          'PORT': '$port',
          'AI_PROVIDER': 'mock',
          'ALLOW_PAID_AI': 'false',
          'LOCAL_ACCESS_TOKEN': access,
          'SESSION_SECRET': 'local-smoke-signing-0123456789abcdef',
        },
      );
      final ready = Completer<void>();
      final output = server.stdout.transform(utf8.decoder).listen((text) {
        if (text.contains('Spielleiter-Backend auf') && !ready.isCompleted) {
          ready.complete();
        }
      });
      final errors = server.stderr.listen((_) {});
      addTearDown(() async {
        server.kill();
        await server.exitCode.timeout(const Duration(seconds: 10));
        await output.cancel();
        await errors.cancel();
      });
      await ready.future.timeout(const Duration(seconds: 10));
      final address = 'http://127.0.0.1:$port';
      final issued = await Process.run(
        'node',
        [File('../backend/scripts/issue-session.mjs').absolute.path],
        environment: {'PORT': '$port', 'LOCAL_ACCESS_TOKEN': access},
      );
      expect(issued.exitCode, 0);
      final token = (issued.stdout as String).trim();
      expect(
        RegExp(r'^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$').hasMatch(token),
        isTrue,
      );
      final narrator = BackendNarrator(
        allowInsecureLoopbackForTests: true,
        timeout: const Duration(seconds: 2),
      );
      final repository = await SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      );
      final controller = GameController(
        repository: repository,
        narrator: narrator,
      );
      addTearDown(() async {
        controller.dispose();
        await repository.close();
      });
      await controller.initialize();
      await controller.createDemo();
      final originalHero = controller.currentCampaign!.hero.toJson();
      await controller.connectNarrator(url: address, sessionToken: token);
      expect(narrator.enabled, isTrue);
      expect(narrator.provider, 'mock');
      await controller.sendAction('Ich spreche mit Mira.');
      expect(controller.error, isNull);
      final confirmed = controller.currentCampaign!;
      expect(confirmed.events.last.payload['narrationProvider'], 'mock');
      expect(confirmed.hero.toJson(), originalHero);
      expect(
        (await repository.getCampaign(confirmed.id))!.toJson(),
        confirmed.toJson(),
      );
      expect(narrator.requestsUsed, 1);

      server.kill(ProcessSignal.sigterm);
      await server.exitCode.timeout(const Duration(seconds: 10));
      await controller.sendAction('Ich spreche erneut mit Mira.');
      expect(controller.error, isNull);
      expect(controller.currentCampaign!.revision, confirmed.revision + 1);
      expect(
        controller.currentCampaign!.events.last.payload['narrationProvider'],
        isNull,
      );
      expect(controller.currentCampaign!.hero.toJson(), originalHero);
      expect(narrator.statusMessage, contains('lokale Spielleiter'));
    },
    skip: Platform.environment['RUN_BACKEND_SMOKE'] != '1',
  );
}
