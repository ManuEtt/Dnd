import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lebendiger_spielleiter/data/campaign_repository.dart';
import 'package:lebendiger_spielleiter/services/game_controller.dart';
import 'package:lebendiger_spielleiter/services/voice_controller.dart';
import 'package:lebendiger_spielleiter/ui/app.dart';
import 'package:lebendiger_spielleiter/ui/fantasy_buttons.dart';

// These settings never access campaign storage. Unexpected storage calls fail.
class _UnusedRepository implements CampaignRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected repository call: ${invocation.memberName}');
}

class _SettingsVoice extends VoiceController {
  int refreshes = 0;
  int microphoneStarts = 0;
  int stops = 0;
  final spoken = <String>[];
  Completer<void>? refreshPending;
  List<Map<String, String>>? refreshedVoices;

  void update() => notifyListeners();

  @override
  Future<void> refreshVoices() async {
    refreshes++;
    refreshingVoices = true;
    update();
    await refreshPending?.future;
    if (refreshedVoices != null) voices = refreshedVoices!;
    refreshingVoices = false;
    update();
  }

  @override
  Future<void> setVoice(String? value) async {
    selectedVoice = value;
    update();
  }

  @override
  Future<void> speak(String text) async {
    spoken.add(text);
    speaking = true;
    update();
  }

  @override
  Future<void> stopSpeaking() async {
    stops++;
    speaking = false;
    update();
  }

  @override
  Future<void> startListening(void Function(String) onText) async {
    microphoneStarts++;
  }
}

Future<void> _openSettings(
  WidgetTester tester,
  _SettingsVoice voice, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final controller = GameController(repository: _UnusedRepository());
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    voice.dispose();
  });
  await tester.pumpWidget(LivingGameApp(controller: controller, voice: voice));
  await tester.tap(find.byTooltip('Einstellungen'));
  await tester.pumpAndSettle();
}

Future<void> _show(
  WidgetTester tester,
  Finder finder, {
  bool upward = false,
}) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      upward ? -150 : 150,
      scrollable: find.byType(Scrollable).first,
    );
  }
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Finder get _choice => find.byType(DropdownButtonFormField<String>);

void main() {
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  for (final scale in [1.3, 2.0]) {
    testWidgets(
      '360 px voice settings fit long Android identifiers at text scale $scale',
      (tester) async {
        final longName = 'de-de-x-${'narrator-'.padRight(150, 'n')}-local';
        final voice = _SettingsVoice()
          ..ttsAvailable = true
          ..ttsLocale = 'de-DE'
          ..ttsEngine = 'com.android.a.long.texttospeech.provider'
          ..recognitionLocale = 'de_DE'
          ..selectedVoice = 'de-DE|$longName'
          ..voices = [
            {'name': longName, 'locale': 'de-DE', 'network_required': '0'},
          ];
        await _openSettings(tester, voice, textScale: scale);
        expect(
          find.text('Sprachausgabe: Anbieter meldet Deutsch'),
          findsOneWidget,
        );
        expect(find.text('Ausgabe-Sprache: de-DE'), findsOneWidget);
        await _show(tester, find.text('Eingabe-Sprache: de_DE'));
        expect(find.text('Eingabe-Sprache: de_DE'), findsOneWidget);
        await _show(tester, _choice);
        expect(
          tester
              .widget<DropdownButton<String>>(
                find.descendant(
                  of: _choice,
                  matching: find.byType(DropdownButton<String>),
                ),
              )
              .isExpanded,
          isTrue,
        );
        expect(find.text('de-DE · lokal laut Anbieter'), findsOneWidget);
        await tester.tap(_choice);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Systemstandard').last);
        await tester.pumpAndSettle();
        expect(voice.selectedVoice, isNull);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('voice menu distinguishes provider network metadata', (
    tester,
  ) async {
    final voice = _SettingsVoice()
      ..ttsAvailable = true
      ..voices = [
        {'name': 'Lokale Stimme', 'locale': 'de-DE', 'network_required': '0'},
        {'name': 'Netzstimme', 'locale': 'de-AT', 'network_required': '1'},
        {'name': 'Unbekannte Stimme', 'locale': 'de-CH'},
      ];
    await _openSettings(tester, voice);
    await _show(tester, _choice);
    await tester.tap(_choice);
    await tester.pumpAndSettle();
    expect(find.text('de-DE · lokal laut Anbieter'), findsOneWidget);
    expect(find.text('de-AT · Internet benötigt'), findsOneWidget);
    expect(find.text('de-CH · Netzwerkstatus unbekannt'), findsOneWidget);
    await tester.tap(find.text('Netzstimme'));
    await tester.pumpAndSettle();
    expect(voice.selectedVoice, 'de-AT|Netzstimme');
    await _show(
      tester,
      find.textContaining('es garantiert keinen Offlinebetrieb'),
    );
    expect(
      find.textContaining('es garantiert keinen Offlinebetrieb'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('available system default can be tested without a voice list', (
    tester,
  ) async {
    final voice = _SettingsVoice()..ttsAvailable = true;
    await _openSettings(tester, voice);
    await _show(tester, _choice);
    expect(
      tester.widget<DropdownButtonFormField<String>>(_choice).onChanged,
      isNotNull,
    );
    await _show(
      tester,
      find.textContaining('keine einzelnen deutschen Stimmen'),
    );
    expect(
      find.textContaining('keine einzelnen deutschen Stimmen'),
      findsOneWidget,
    );
    await _show(tester, find.byKey(const ValueKey('test-voice')));
    await tester.tap(find.byKey(const ValueKey('test-voice')));
    await tester.pumpAndSettle();
    expect(voice.spoken, [
      'Willkommen bei Würfelraunen. Deine Geschichte wartet auf dich.',
    ]);
    expect(voice.microphoneStarts, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('refresh blocks voice changes while stop remains usable', (
    tester,
  ) async {
    final voice = _SettingsVoice()
      ..ttsAvailable = true
      ..refreshPending = Completer<void>();
    await _openSettings(tester, voice);
    await tester.tap(find.byKey(const ValueKey('refresh-voices')));
    await tester.pump();
    expect(voice.refreshes, 1);
    expect(voice.microphoneStarts, 0);
    expect(find.text('Sprachausgabe wird geprüft …'), findsOneWidget);
    expect(
      tester
          .widget<FantasyTextButton>(find.byKey(const ValueKey('refresh-voices')))
          .onPressed,
      isNull,
    );
    await _show(tester, _choice);
    expect(
      tester.widget<DropdownButtonFormField<String>>(_choice).onChanged,
      isNull,
    );
    await _show(tester, find.byKey(const ValueKey('test-voice')));
    expect(
      tester
          .widget<FantasyTextButton>(find.byKey(const ValueKey('test-voice')))
          .onPressed,
      isNull,
    );
    await _show(tester, find.byKey(const ValueKey('stop-voice')));
    await tester.tap(find.byKey(const ValueKey('stop-voice')));
    await tester.pumpAndSettle();
    expect(voice.stops, 1);
    voice.refreshPending!.complete();
    await tester.pumpAndSettle();
    expect(voice.refreshingVoices, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unavailable TTS disables testing but permits refresh and stop', (
    tester,
  ) async {
    final voice = _SettingsVoice()
      ..ttsAvailable = false
      ..error = 'Bitte installiere ein deutsches System-Sprachpaket.';
    await _openSettings(tester, voice);
    expect(find.text('Sprachausgabe: Deutsch nicht verfügbar'), findsOneWidget);
    expect(
      find.text('Spracheingabe wird beim Mikrofontipp geprüft.'),
      findsOneWidget,
    );
    await _show(tester, _choice);
    expect(
      tester.widget<DropdownButtonFormField<String>>(_choice).onChanged,
      isNull,
    );
    await _show(tester, find.byKey(const ValueKey('test-voice')));
    expect(
      tester
          .widget<FantasyTextButton>(find.byKey(const ValueKey('test-voice')))
          .onPressed,
      isNull,
    );
    await _show(tester, find.byKey(const ValueKey('stop-voice')));
    expect(
      tester
          .widget<FantasyTextButton>(find.byKey(const ValueKey('stop-voice')))
          .onPressed,
      isNotNull,
    );
    expect(find.text(voice.error!), findsOneWidget);
    await _show(
      tester,
      find.byKey(const ValueKey('refresh-voices')),
      upward: true,
    );
    await tester.tap(find.byKey(const ValueKey('refresh-voices')));
    await tester.pumpAndSettle();
    expect(voice.refreshes, 1);
    expect(voice.microphoneStarts, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('device reload replaces removed selection with system default', (
    tester,
  ) async {
    final voice = _SettingsVoice()
      ..ttsAvailable = true
      ..selectedVoice = 'de-DE|Alte Stimme'
      ..voices = [
        {'name': 'Alte Stimme', 'locale': 'de-DE'},
      ]
      ..refreshedVoices = [
        {'name': 'Neue Stimme', 'locale': 'de-DE'},
      ];
    await _openSettings(tester, voice);
    await _show(tester, _choice);
    expect(
      tester.state<FormFieldState<String>>(_choice).value,
      'de-DE|Alte Stimme',
    );
    await _show(
      tester,
      find.byKey(const ValueKey('refresh-voices')),
      upward: true,
    );
    await tester.tap(find.byKey(const ValueKey('refresh-voices')));
    await tester.pumpAndSettle();
    await _show(tester, _choice);
    expect(tester.state<FormFieldState<String>>(_choice).value, isNull);
    expect(find.byKey(const ValueKey('voice-choice-system')), findsOneWidget);
    await tester.tap(_choice);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Neue Stimme'));
    await tester.pumpAndSettle();
    expect(voice.selectedVoice, 'de-DE|Neue Stimme');
    expect(
      tester.state<FormFieldState<String>>(_choice).value,
      'de-DE|Neue Stimme',
    );
    expect(tester.takeException(), isNull);
  });
}
