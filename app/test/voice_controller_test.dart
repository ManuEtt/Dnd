import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import 'package:lebendiger_spielleiter/services/voice_controller.dart';

class FakeSpeech implements SpeechToText {
  final initializeResult = Completer<bool>();
  Completer<void>? stopResult;
  Completer<void>? cancelResult;
  Completer<dynamic>? listenResult;
  bool failCancel = false;
  int initializations = 0;
  int listenCalls = 0;
  int cancels = 0;
  SpeechResultListener? resultListener;
  @override
  SpeechErrorListener? errorListener;
  @override
  SpeechStatusListener? statusListener;
  Future<List<LocaleName>>? localesResult;
  List<LocaleName> deviceLocales = [LocaleName('de_DE', 'Deutsch')];
  String? listenedLocale;

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    dynamic debugLogging = false,
    Duration finalTimeout = const Duration(seconds: 2),
    List<SpeechConfigOption>? options,
  }) {
    initializations++;
    // Real speech_to_text caches these callbacks after first successful init.
    errorListener ??= onError;
    statusListener ??= onStatus;
    return initializeResult.future;
  }

  @override
  Future<List<LocaleName>> locales() async =>
      await (localesResult ?? Future.value(deviceLocales));

  @override
  Future<dynamic> listen({
    SpeechResultListener? onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    SpeechSoundLevelChange? onSoundLevelChange,
    dynamic cancelOnError = false,
    dynamic partialResults = true,
    dynamic onDevice = false,
    ListenMode listenMode = ListenMode.confirmation,
    dynamic sampleRate = 0,
    SpeechListenOptions? listenOptions,
  }) async {
    listenCalls++;
    listenedLocale = localeId;
    resultListener = onResult;
    return await listenResult?.future;
  }

  @override
  Future<void> stop() async {
    await stopResult?.future;
  }

  @override
  Future<void> cancel() async {
    cancels++;
    await cancelResult?.future;
    if (failCancel) throw StateError('Plugin absent');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTts implements FlutterTts {
  int speakCalls = 0;
  int stops = 0;
  bool failStop = false;
  bool failVoice = false;
  dynamic speakResult = 1;
  Completer<dynamic>? pendingSpeak;
  Completer<dynamic>? pendingVoices;
  Completer<dynamic>? pendingVoice;
  dynamic voiceResult = 1;
  dynamic languageResult = 1;
  Map<String, dynamic> languageResults = {};
  dynamic deviceVoices = [];
  List<String> languages = ['de-DE'];
  List<String> languageCalls = [];
  List<Map<String, String>> voiceCalls = [];
  @override
  void Function()? startHandler;
  @override
  void Function()? completionHandler;
  @override
  void Function()? cancelHandler;
  @override
  void Function(dynamic)? errorHandler;

  @override
  Future<dynamic> stop() async {
    stops++;
    if (failStop) throw StateError('Plugin absent');
    return 1;
  }

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    speakCalls++;
    return pendingSpeak == null ? speakResult : await pendingSpeak!.future;
  }

  @override
  Future<dynamic> setVoice(Map<String, String> voice) async {
    voiceCalls.add(voice);
    if (failVoice) throw StateError('Voice absent');
    return pendingVoice == null ? voiceResult : await pendingVoice!.future;
  }

  @override
  Future<dynamic> setLanguage(String language) async {
    languageCalls.add(language);
    return languageResults[language] ?? languageResult;
  }

  @override
  Future<dynamic> setSpeechRate(double rate) async => 1;

  @override
  Future<dynamic> awaitSpeakCompletion(bool value) async => 1;

  @override
  Future<dynamic> get getVoices async =>
      pendingVoices == null ? deviceVoices : await pendingVoices!.future;

  @override
  Future<dynamic> get getLanguages async => languages;

  @override
  Future<dynamic> get getDefaultEngine async => 'fake.tts';

  @override
  void setStartHandler(void Function() callback) => startHandler = callback;

  @override
  void setCompletionHandler(void Function() callback) =>
      completionHandler = callback;

  @override
  void setCancelHandler(void Function() callback) => cancelHandler = callback;

  @override
  void setErrorHandler(void Function(dynamic) callback) =>
      errorHandler = callback;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> flushAsync() => Future<void>.delayed(Duration.zero);

FakeSpeech readySpeech() => FakeSpeech()..initializeResult.complete(true);

VoiceController shortController({
  FakeSpeech? speech,
  FakeTts? tts,
  Future<void> Function(Map<String, Object?>)? save,
}) => VoiceController(
  speech: speech ?? readySpeech(),
  tts: tts ?? FakeTts(),
  onPreferencesChanged: save,
  localeTimeout: const Duration(milliseconds: 10),
  serviceTimeout: const Duration(milliseconds: 50),
  playbackTimeout: const Duration(milliseconds: 50),
  initializationTimeout: const Duration(milliseconds: 50),
);

void main() {
  test(
    'stop cancels microphone initialization before it can start listening',
    () async {
      final speech = FakeSpeech();
      final controller = VoiceController(speech: speech, tts: FakeTts());
      final pending = controller.startListening((_) {});
      await flushAsync();
      expect(speech.initializations, 1);
      await controller.stopListening();
      speech.initializeResult.complete(true);
      await pending;
      expect(speech.listenCalls, 0);
      expect(controller.listening, false);
      controller.dispose();
      await flushAsync();
    },
  );

  test(
    'dispose cannot reopen microphone after a delayed permission response',
    () async {
      final speech = FakeSpeech();
      final controller = VoiceController(speech: speech, tts: FakeTts());
      final pending = controller.startListening((_) {});
      await flushAsync();
      controller.dispose();
      speech.initializeResult.complete(true);
      await pending;
      expect(speech.listenCalls, 0);
      expect(speech.cancels, 1);
    },
  );

  test(
    'repeated taps issue one microphone initialization and one listen',
    () async {
      final speech = FakeSpeech();
      final controller = VoiceController(speech: speech, tts: FakeTts());
      final first = controller.startListening((_) {});
      final duplicate = controller.startListening((_) {});
      await flushAsync();
      speech.initializeResult.complete(true);
      await Future.wait([first, duplicate]);
      expect(speech.initializations, 1);
      expect(speech.listenCalls, 1);
      controller.dispose();
      await flushAsync();
    },
  );

  test(
    'stop cancels pending speech playback before a delayed recognizer stops',
    () async {
      final speech = FakeSpeech()..stopResult = Completer<void>();
      final tts = FakeTts();
      final controller = VoiceController(speech: speech, tts: tts);
      final pending = controller.speak('Eine Antwort');
      await flushAsync();
      await controller.stopSpeaking();
      speech.stopResult!.complete();
      await pending;
      expect(tts.speakCalls, 0);
      controller.dispose();
      await flushAsync();
    },
  );

  test(
    'disposal stops playback while microphone cancellation is delayed',
    () async {
      final speech = FakeSpeech()..cancelResult = Completer<void>();
      final tts = FakeTts();
      final controller = VoiceController(speech: speech, tts: tts);
      controller.dispose();
      await flushAsync();
      expect(tts.stops, 1);
      speech.cancelResult!.complete();
      await flushAsync();
    },
  );

  test(
    'missing plugins during disposal do not produce unhandled futures',
    () async {
      final speech = FakeSpeech()..failCancel = true;
      final tts = FakeTts()..failStop = true;
      final controller = VoiceController(speech: speech, tts: tts);
      controller.dispose();
      await flushAsync();
      expect(speech.cancels, 1);
      expect(tts.stops, 1);
    },
  );

  test(
    'unavailable voice reports an error without throwing to the UI',
    () async {
      final controller = VoiceController(
        speech: FakeSpeech(),
        tts: FakeTts()..failVoice = true,
      );
      controller.voices = [
        {'name': 'Deutsch', 'locale': 'de-DE'},
      ];
      await controller.setVoice('de-DE|Deutsch');
      expect(controller.error, contains('Stimme'));
      expect(controller.selectedVoice, isNull);
      controller.dispose();
      await flushAsync();
    },
  );

  test(
    'refresh validates German voice metadata without opening microphone',
    () async {
      final speech = readySpeech();
      final tts = FakeTts()
        ..deviceVoices = [
          {
            'name': 'network',
            'locale': 'de-DE',
            'network_required': '1',
            'features': 'networkTts',
          },
          {
            'name': 'installed',
            'locale': 'DE_de',
            'network_required': '0',
            'features': 'embeddedTts',
          },
          {'name': 'installed', 'locale': 'de-DE', 'network_required': '0'},
          {'name': 'Austria', 'locale': 'de-AT', 'network_required': '0'},
          {
            'name': 'missing',
            'locale': 'de-DE',
            'features': 'networkTts\tnotInstalled',
          },
          {'name': 'English', 'locale': 'en-US'},
          {'name': 'Not German', 'locale': 'del'},
          {'name': null, 'locale': 'de-DE'},
          {'name': '', 'locale': 'de-DE'},
          {'name': 'Invalid', 'locale': null},
        ];
      final controller = shortController(speech: speech, tts: tts);
      await controller.initialize();
      expect(speech.initializations, 0);
      expect(controller.voices.map((voice) => voice['name']), [
        'installed',
        'network',
        'Austria',
      ]);
      expect(controller.voices.first['features'], 'embeddedTts');
      expect(controller.voices[1]['network_required'], '1');
      expect(controller.ttsAvailable, true);
      expect(controller.ttsLocale, 'de-DE');
      expect(controller.ttsEngine, 'fake.tts');
      expect(controller.refreshingVoices, false);
      controller.dispose();
      await flushAsync();
    },
  );

  for (final rejected in [0, false]) {
    test(
      'language result $rejected never reports German output available',
      () async {
        final tts = FakeTts()..languageResult = rejected;
        final controller = shortController(tts: tts);
        await controller.refreshVoices();
        expect(controller.ttsAvailable, false);
        expect(controller.ttsLocale, isNull);
        expect(controller.error, contains('Sprachpaket'));
        await controller.speak('Text bleibt erhalten');
        expect(tts.speakCalls, 0);
        controller.dispose();
        await flushAsync();
      },
    );

    test(
      'voice result $rejected preserves verified choice and never saves rejection',
      () async {
        final saved = <Map<String, Object?>>[];
        final tts = FakeTts()
          ..deviceVoices = [
            {'name': 'good', 'locale': 'de-DE'},
            {'name': 'bad', 'locale': 'de-DE'},
          ];
        final controller = shortController(
          tts: tts,
          save: (prefs) async => saved.add(prefs),
        );
        await controller.initialize();
        await controller.setVoice('de-DE|good');
        tts.voiceResult = rejected;
        await controller.setVoice('de-DE|bad');
        expect(controller.selectedVoice, 'de-DE|good');
        expect(saved.map((prefs) => prefs['voice']), ['de-DE|good']);
        expect(controller.error, contains('Stimme'));
        expect(controller.ttsAvailable, true);
        controller.dispose();
        await flushAsync();
      },
    );

    test(
      'speak result $rejected exposes output failure and returns to text',
      () async {
        final tts = FakeTts()..speakResult = rejected;
        final controller = shortController(tts: tts);
        await controller.initialize();
        await controller.speak('Eine lesbare Antwort');
        expect(tts.speakCalls, 1);
        expect(controller.speaking, false);
        expect(controller.error, contains('Text'));
        controller.dispose();
        await flushAsync();
      },
    );
  }

  test(
    'disappeared persisted voice recovers and saves verified system default',
    () async {
      final saved = <Map<String, Object?>>[];
      final controller = shortController(
        save: (prefs) async => saved.add(prefs),
      );
      controller.configure({'voice': 'de-DE|removed', 'autoSpeak': true});
      await controller.refreshVoices();
      expect(controller.selectedVoice, isNull);
      expect(controller.ttsAvailable, true);
      expect(saved.single, {'voice': null, 'autoSpeak': true});
      expect(controller.error, contains('Systemstandard'));
      controller.dispose();
      await flushAsync();
    },
  );

  test('German regional default recovers if Germany is rejected', () async {
    final tts = FakeTts()
      ..deviceVoices = [
        {'name': 'Austria', 'locale': 'de-AT'},
      ]
      ..languageResults = {'de-DE': 0, 'de-AT': 1};
    final controller = shortController(tts: tts);
    await controller.initialize();
    expect(tts.languageCalls, ['de-DE', 'de-AT']);
    expect(controller.ttsLocale, 'de-AT');
    expect(controller.ttsAvailable, true);
    controller.dispose();
    await flushAsync();
  });

  test('refresh discovers a subsequently installed German package', () async {
    final tts = FakeTts()..languageResult = 0;
    final controller = shortController(tts: tts);
    await controller.initialize();
    expect(controller.ttsAvailable, false);
    tts.languageResult = 1;
    tts.deviceVoices = [
      {'name': 'new', 'locale': 'de-DE', 'network_required': '0'},
    ];
    await controller.refreshVoices();
    expect(controller.ttsAvailable, true);
    expect(controller.error, isNull);
    expect(controller.voices.single['name'], 'new');
    controller.dispose();
    await flushAsync();
  });

  test(
    'output error callback releases hung native speak and supports retry',
    () async {
      final tts = FakeTts()..pendingSpeak = Completer<dynamic>();
      final controller = shortController(tts: tts);
      await controller.initialize();
      final pending = controller.speak('Antwort');
      await flushAsync();
      tts.startHandler!();
      tts.errorHandler!('Error from TextToSpeech (speak) - -6');
      await pending;
      expect(controller.error, contains('Verbindung'));
      expect(controller.speaking, false);
      expect(tts.stops, greaterThanOrEqualTo(3));
      tts.pendingSpeak!.complete(0);
      tts.pendingSpeak = null;
      await controller.speak('Erneut');
      expect(controller.error, isNull);
      expect(tts.speakCalls, 2);
      controller.dispose();
      await flushAsync();
    },
  );

  test('missing package callback never exposes raw provider payload', () async {
    final tts = FakeTts()..pendingSpeak = Completer<dynamic>();
    final controller = shortController(tts: tts);
    await controller.initialize();
    final pending = controller.speak('Antwort');
    await flushAsync();
    tts.errorHandler!('Error from TextToSpeech (speak) - -9');
    await pending;
    expect(controller.error, contains('nicht installiert'));
    expect(controller.error, isNot(contains('TextToSpeech')));
    tts.pendingSpeak!.complete(0);
    controller.dispose();
    await flushAsync();
  });

  test('hung playback times out and stops native output', () async {
    final tts = FakeTts()..pendingSpeak = Completer<dynamic>();
    final controller = shortController(tts: tts);
    await controller.initialize();
    await controller.speak('Antwort');
    expect(controller.error, contains('antwortet nicht mehr'));
    expect(controller.speaking, false);
    tts.pendingSpeak!.complete(0);
    controller.dispose();
    await flushAsync();
  });

  test(
    'explicit stop releases hung playback and late cancel does not fail next playback',
    () async {
      final tts = FakeTts()..pendingSpeak = Completer<dynamic>();
      final controller = shortController(tts: tts);
      await controller.initialize();
      final first = controller.speak('Erste Antwort');
      await flushAsync();
      await controller.stopSpeaking();
      await first;
      expect(controller.error, isNull);
      tts.pendingSpeak!.complete(0);
      tts.pendingSpeak = Completer<dynamic>();
      final second = controller.speak('Zweite Antwort');
      await flushAsync();
      tts.startHandler!();
      tts.cancelHandler!();
      expect(controller.speaking, true);
      expect(controller.error, isNull);
      tts.pendingSpeak!.complete(1);
      await second;
      controller.dispose();
      await flushAsync();
    },
  );

  test(
    'recognition prefers Germany and preserves provider locale spelling',
    () async {
      final speech = readySpeech()
        ..deviceLocales = [
          LocaleName('de_AT', 'Deutsch Österreich'),
          LocaleName('del', 'Andere Sprache'),
          LocaleName('DE_de', 'Deutsch Deutschland'),
        ];
      final controller = shortController(speech: speech);
      await controller.startListening((_) {});
      expect(speech.listenedLocale, 'DE_de');
      expect(controller.recognitionLocale, 'DE_de');
      expect(controller.listening, true);
      controller.dispose();
      await flushAsync();
    },
  );

  test(
    'hung recognition locale query attempts explicit German after timeout',
    () async {
      final speech = readySpeech()
        ..localesResult = Completer<List<LocaleName>>().future;
      final controller = shortController(speech: speech);
      await controller.startListening((_) {});
      expect(speech.listenedLocale, 'de-DE');
      expect(speech.listenCalls, 1);
      expect(controller.error, isNull);
      controller.dispose();
      await flushAsync();
    },
  );

  for (final locales in <List<LocaleName>>[
    [],
    [LocaleName('en_US', 'English')],
  ]) {
    test(
      'incomplete on-device locale list still attempts explicit German',
      () async {
        final speech = readySpeech()..deviceLocales = locales;
        final controller = shortController(speech: speech);
        await controller.startListening((_) {});
        expect(speech.listenedLocale, 'de-DE');
        speech.errorListener!(
          SpeechRecognitionError('error_language_unavailable', true),
        );
        expect(controller.error, contains('Sprachpaket'));
        expect(controller.listening, false);
        controller.dispose();
        await flushAsync();
      },
    );
  }

  test(
    'cached recognition error callback handles retry and ignores failed results',
    () async {
      final speech = readySpeech();
      final controller = shortController(speech: speech);
      final words = <String>[];
      await controller.startListening(words.add);
      final firstResult = speech.resultListener!;
      speech.errorListener!(SpeechRecognitionError('error_network', true));
      expect(controller.error, contains('Verbindung'));
      await controller.startListening(words.add);
      expect(speech.initializations, 2);
      firstResult(
        SpeechRecognitionResult([
          SpeechRecognitionWords('alte Worte', null, 1),
        ], true),
      );
      expect(words, isEmpty);
      speech.errorListener!(SpeechRecognitionError('error_permission', true));
      expect(controller.error, contains('Mikrofonzugriff verweigert'));
      expect(controller.listening, false);
      speech.resultListener!(
        SpeechRecognitionResult([
          SpeechRecognitionWords('verworfen', null, 1),
        ], true),
      );
      expect(words, isEmpty);
      controller.dispose();
      await flushAsync();
    },
  );

  test(
    'refresh is single flight and playback never overlaps native refresh',
    () async {
      final tts = FakeTts()..pendingVoices = Completer<dynamic>();
      final controller = shortController(tts: tts);
      final first = controller.refreshVoices();
      final duplicate = controller.refreshVoices();
      expect(identical(first, duplicate), true);
      final pending = controller.speak('Antwort');
      await flushAsync();
      expect(tts.speakCalls, 0);
      tts.pendingVoices!.complete([]);
      await Future.wait([first, duplicate, pending]);
      expect(tts.speakCalls, 0);
      expect(controller.ttsAvailable, true);
      await controller.speak('Nach der Suche');
      expect(tts.speakCalls, 1);
      controller.dispose();
      await flushAsync();
    },
  );

  test(
    'playback waits for an active voice setter and respects stop while waiting',
    () async {
      final tts = FakeTts()
        ..deviceVoices = [
          {'name': 'German', 'locale': 'de-DE'},
        ];
      final controller = shortController(tts: tts);
      await controller.initialize();
      tts.pendingVoice = Completer<dynamic>();
      final selection = controller.setVoice('de-DE|German');
      await flushAsync();
      final pending = controller.speak('Antwort');
      await flushAsync();
      expect(tts.speakCalls, 0);
      await controller.stopSpeaking();
      tts.pendingVoice!.complete(1);
      await Future.wait([selection, pending]);
      expect(tts.speakCalls, 0);
      controller.dispose();
      await flushAsync();
    },
  );

  test(
    'a hung output voice enumeration is bounded and does not block German default',
    () async {
      final tts = FakeTts()..pendingVoices = Completer<dynamic>();
      final controller = shortController(tts: tts);
      await controller.refreshVoices();
      expect(controller.refreshingVoices, false);
      expect(controller.ttsAvailable, true);
      expect(controller.voices, isEmpty);
      expect(controller.error, isNull);
      tts.pendingVoices!.complete([]);
      controller.dispose();
      await flushAsync();
    },
  );

  test(
    'disposed controller releases pending playback even if native speak never returns',
    () async {
      final tts = FakeTts()..pendingSpeak = Completer<dynamic>();
      final controller = shortController(tts: tts);
      await controller.initialize();
      final pending = controller.speak('Antwort');
      await flushAsync();
      controller.dispose();
      await pending;
      expect(controller.error, isNull);
      tts.pendingSpeak!.complete(0);
      await flushAsync();
    },
  );

  test(
    'recognizer start timeout cancels native capture and discards late results',
    () async {
      final speech = readySpeech()..listenResult = Completer<dynamic>();
      final controller = shortController(speech: speech);
      final words = <String>[];
      await controller.startListening(words.add);
      expect(speech.cancels, 1);
      expect(controller.listening, false);
      expect(controller.error, contains('eintippen'));
      speech.resultListener!(
        SpeechRecognitionResult([
          SpeechRecognitionWords('zu spät', null, 1),
        ], true),
      );
      expect(words, isEmpty);
      speech.listenResult!.complete(null);
      controller.dispose();
      await flushAsync();
    },
  );
}
