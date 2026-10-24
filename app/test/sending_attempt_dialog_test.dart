import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lebendiger_spielleiter/data/srd_spell_catalog_loader.dart';
import 'package:lebendiger_spielleiter/data/sqlite_campaign_repository.dart';
import 'package:lebendiger_spielleiter/domain/models.dart';
import 'package:lebendiger_spielleiter/domain/srd_sending_rules.dart';
import 'package:lebendiger_spielleiter/domain/srd_spell_catalog.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:lebendiger_spielleiter/services/voice_controller.dart';
import 'package:lebendiger_spielleiter/ui/app.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';
import 'package:lebendiger_spielleiter/ui/sending_attempt_dialog.dart';

HeroCharacter _sendingHero() => HeroCharacter(
  id: 'sending-ui-mage',
  name: 'Nora',
  className: 'Magier',
  level: 5,
  spells: ['Sending'],
  abilities: {
    'strength': 10,
    'dexterity': 12,
    'constitution': 14,
    'intelligence': 16,
    'wisdom': 14,
    'charisma': 12,
  },
  maxHitPoints: 28,
  hitPoints: 28,
);

class _SilentSendingVoice extends VoiceController {
  @override
  Future<void> stopListening() async {}

  @override
  Future<void> stopSpeaking() async {}

  @override
  Future<void> speak(String text) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  late SrdSpellDefinition sending;

  setUpAll(() async {
    sending = (await SrdSpellCatalogLoader.load()).find('Sending')!;
  });

  Finder key(String id) => find.byKey(ValueKey(id));

  Future<void> press(WidgetTester tester, String id) async {
    final target = key(id);
    FocusManager.instance.primaryFocus?.unfocus();
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    if (target.hitTestable().evaluate().isEmpty &&
        find.byType(SendingAttemptDialog).evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(
        target,
        100,
        scrollable: find
            .descendant(
              of: find.byType(SendingAttemptDialog),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
    }
    expect(target.hitTestable(), findsOneWidget);
    await tester.tap(target);
    if (id == 'sending-confirm') {
      // The full adventure view animates continuously while SQLite commits.
      // Advance the dialog pop without waiting for every app animation to stop.
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
    } else {
      await tester.pumpAndSettle();
    }
  }

  Future<void> open(
    WidgetTester tester, {
    required HeroCharacter hero,
    required ValueChanged<SendingAttemptChoice?> onChoice,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: fantasyTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const ValueKey('sending-open'),
              onPressed: () async {
                onChoice(
                  await showDialog<SendingAttemptChoice>(
                    context: context,
                    builder: (_) =>
                        SendingAttemptDialog(hero: hero, sending: sending),
                  ),
                );
              },
              child: const Text('Sending öffnen'),
            ),
          ),
        ),
      ),
    );
    await press(tester, 'sending-open');
  }

  Future<void> fillFacts(WidgetTester tester) async {
    await tester.enterText(key('sending-recipient'), 'npc-tarek');
    await tester.enterText(key('sending-message'), 'Bitte melde dich.');
    await press(tester, 'sending-knowledge');
    await tester.tap(find.text('Persönlich getroffen').last);
    await tester.pumpAndSettle();
    await press(tester, 'sending-creature');
    await press(tester, 'sending-action');
    await press(tester, 'sending-components');
  }

  FantasyTextButton submit(WidgetTester tester) =>
      tester.widget<FantasyTextButton>(key('sending-confirm'));

  testWidgets('Abbruch verbraucht nichts, und alle Fakten brauchen Belege', (
    tester,
  ) async {
    final hero = _sendingHero();
    SendingAttemptChoice? choice;
    await open(tester, hero: hero, onChoice: (value) => choice = value);
    expect(submit(tester).onPressed, isNull);
    await tester.enterText(key('sending-recipient'), 'npc-tarek');
    await tester.enterText(key('sending-message'), 'Bitte melde dich.');
    expect(submit(tester).onPressed, isNull);
    await press(tester, 'sending-cancel');
    expect(find.byType(SendingAttemptDialog), findsNothing);
    expect(choice, isNull);
    expect(hero.spentSpellSlots, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Nur bestätigter Preview lässt Kostenbuchung zu; Änderungen widerrufen Zustimmung',
    (tester) async {
      final hero = _sendingHero();
      SendingAttemptChoice? choice;
      await open(tester, hero: hero, onChoice: (value) => choice = value);
      await fillFacts(tester);
      expect(find.textContaining('Danach: 1'), findsOneWidget);
      expect(find.textContaining('Wörter: 3 / 25'), findsOneWidget);
      expect(find.textContaining('Zustellung ungeklärt'), findsOneWidget);
      expect(submit(tester).onPressed, isNull);
      await press(tester, 'sending-consent');
      expect(submit(tester).onPressed, isNotNull);

      await tester.enterText(key('sending-message'), 'Bitte antworte.');
      await tester.pump();
      expect(submit(tester).onPressed, isNull);
      await press(tester, 'sending-consent');
      await press(tester, 'sending-confirm');
      expect(choice, isNotNull);
      expect(choice!.preview.recipient.recipientId, 'npc-tarek');
      expect(choice!.preview.recipient.message, 'Bitte antworte.');
      expect(
        choice!.preview.assessment.outcome,
        SendingDeliveryOutcome.unresolved,
      );
      expect(choice!.preview.slotLevel, 3);
      expect(choice!.requestId, startsWith('sending_'));
      expect(hero.spentSpellSlots, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('25 Wörter, unsichtbare Zeichen und Ebenenwürfe werden geprüft', (
    tester,
  ) async {
    await open(tester, hero: _sendingHero(), onChoice: (_) {});
    await fillFacts(tester);
    await tester.enterText(
      key('sending-message'),
      List.filled(26, 'Wort').join(' '),
    );
    await tester.pump();
    expect(find.textContaining('höchstens 25 Wörter'), findsWidgets);
    expect(submit(tester).onPressed, isNull);

    await tester.enterText(key('sending-message'), 'Hallo\u2063Welt');
    await tester.pump();
    expect(find.textContaining('unsichtbare Steuerzeichen'), findsOneWidget);
    expect(submit(tester).onPressed, isNull);

    await tester.enterText(key('sending-message'), 'Bitte melde dich.');
    await press(tester, 'sending-block');
    await tester.tap(find.text('Nicht blockiert – bestätigt').last);
    await tester.pumpAndSettle();
    await press(tester, 'sending-plane');
    await tester.tap(find.text('Andere Ebene – bestätigt').last);
    await tester.pumpAndSettle();
    expect(key('sending-percentile'), findsOneWidget);
    expect(find.textContaining('W100-Wurf erforderlich'), findsOneWidget);
    await tester.enterText(key('sending-percentile'), '5');
    await tester.pump();
    expect(find.textContaining('scheitert'), findsOneWidget);
    expect(submit(tester).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'W100 erscheint nur bei bestätigter anderer Ebene ohne Blockade',
    (tester) async {
      await open(tester, hero: _sendingHero(), onChoice: (_) {});
      await fillFacts(tester);
      await press(tester, 'sending-plane');
      await tester.tap(find.text('Andere Ebene – bestätigt').last);
      await tester.pumpAndSettle();

      // A confirmed other plane alone cannot authorize a roll:
      // unverified blocking status must remain an unresolved preview.
      expect(key('sending-percentile'), findsNothing);
      expect(find.textContaining('Zustellung ungeklärt'), findsOneWidget);
      await press(tester, 'sending-consent');
      expect(submit(tester).onPressed, isNotNull);

      await press(tester, 'sending-block');
      await tester.tap(find.text('Nicht blockiert – bestätigt').last);
      await tester.pumpAndSettle();
      expect(key('sending-percentile'), findsOneWidget);
      expect(find.textContaining('W100-Wurf erforderlich'), findsOneWidget);
      await tester.enterText(key('sending-percentile'), '6');
      await tester.pump();
      expect(
        find.textContaining('keine tatsächliche Zustellung'),
        findsOneWidget,
      );
      await press(tester, 'sending-consent');
      expect(submit(tester).onPressed, isNotNull);

      await press(tester, 'sending-block');
      await tester.tap(find.text('Blockiert – bestätigt').last);
      await tester.pumpAndSettle();
      expect(key('sending-percentile'), findsNothing);
      expect(find.textContaining('Bestätigte Blockade'), findsOneWidget);
      expect(submit(tester).onPressed, isNull);

      await press(tester, 'sending-block');
      await tester.tap(find.text('Nicht blockiert – bestätigt').last);
      await tester.pumpAndSettle();
      expect(key('sending-percentile'), findsOneWidget);
      expect(
        tester.widget<TextField>(key('sending-percentile')).controller!.text,
        isEmpty,
      );
      expect(find.textContaining('W100-Wurf erforderlich'), findsOneWidget);
      expect(submit(tester).onPressed, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Unbestätigte Blockade verwirft vorherigen W100 und Zustimmung', (
    tester,
  ) async {
    await open(tester, hero: _sendingHero(), onChoice: (_) {});
    await fillFacts(tester);
    await press(tester, 'sending-block');
    await tester.tap(find.text('Nicht blockiert – bestätigt').last);
    await tester.pumpAndSettle();
    await press(tester, 'sending-plane');
    await tester.tap(find.text('Andere Ebene – bestätigt').last);
    await tester.pumpAndSettle();
    await tester.enterText(key('sending-percentile'), '5');
    await tester.pump();
    expect(find.textContaining('scheitert'), findsOneWidget);
    await press(tester, 'sending-consent');
    expect(submit(tester).onPressed, isNotNull);

    await press(tester, 'sending-block');
    await tester.tap(find.text('Unbekannt').last);
    await tester.pumpAndSettle();
    expect(key('sending-percentile'), findsNothing);
    expect(find.textContaining('Zustellung ungeklärt'), findsOneWidget);
    expect(submit(tester).onPressed, isNull);
    await press(tester, 'sending-block');
    await tester.tap(find.text('Nicht blockiert – bestätigt').last);
    await tester.pumpAndSettle();
    expect(key('sending-percentile'), findsOneWidget);
    expect(
      tester.widget<TextField>(key('sending-percentile')).controller!.text,
      isEmpty,
    );
    expect(find.textContaining('W100-Wurf erforderlich'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('320 dp mit großer Schrift: Dialog bleibt bedienbar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await open(tester, hero: _sendingHero(), onChoice: (_) {}, textScale: 1.4);
    await fillFacts(tester);
    await press(tester, 'sending-consent');
    expect(submit(tester).onPressed, isNotNull);
    await tester.ensureVisible(key('sending-confirm'));
    await tester.pumpAndSettle();
    expect(key('sending-confirm').hitTestable(), findsOneWidget);
    expect(key('sending-cancel').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Abenteuer-Button bestätigt genau ein SQLite-Ereignis', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = (await tester.runAsync(
      () => SqliteCampaignRepository.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      ),
    ))!;
    final controller = GameController(repository: repository);
    final voice = _SilentSendingVoice();
    try {
      await tester.runAsync(() => controller.newCampaign(_sendingHero()));
      expect(controller.error, isNull);
      await tester.pumpWidget(
        LivingGameApp(controller: controller, voice: voice),
      );
      await tester.tap(find.text('Abenteuer'));
      await tester.pumpAndSettle();
      final action = key('adventure-confirm-sending');
      await tester.scrollUntilVisible(
        action,
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      // The adventure outbox loads asynchronously; do not tap a disabled
      // action before its pending-command check has completed.
      for (var retry = 0; retry < 100; retry++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
        if (tester.widget<FantasyTextButton>(action).onPressed != null) {
          break;
        }
      }
      expect(tester.widget<FantasyTextButton>(action).onPressed, isNotNull);
      await tester.tap(action);
      for (var retry = 0; retry < 100; retry++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
        if (find.byType(SendingAttemptDialog).evaluate().isNotEmpty) {
          break;
        }
      }
      expect(find.byType(SendingAttemptDialog), findsOneWidget);
      await fillFacts(tester);
      await press(tester, 'sending-consent');
      await press(tester, 'sending-confirm');
      for (var retry = 0; retry < 120; retry++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
        if (controller.currentCampaign?.revision == 1 && !controller.busy) {
          break;
        }
      }
      expect(controller.error, isNull);
      final campaign = controller.currentCampaign!;
      expect(campaign.hero.spentSpellSlots['3'], 1);
      expect(campaign.revision, 1);
      expect(campaign.events, hasLength(1));
      expect(campaign.events.single.type, 'spell.sending.attemptConfirmed');
      expect(campaign.events.single.payload['message'], 'Bitte melde dich.');
      expect(campaign.events.single.payload['deliveryNotPerformed'], true);
      expect(
        (await tester.runAsync(
          () => repository.getCampaign(campaign.id),
        ))!.toJson(),
        campaign.toJson(),
      );
      expect(key('sending-attempt-receipt'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      voice.dispose();
      await tester.runAsync(repository.close);
    }
  });
}
