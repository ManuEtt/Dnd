import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:lebendiger_spielleiter/services/voice_controller.dart';

class FakeSpeech implements SpeechToText {
  final initializeResult = Completer<bool>();
  Completer<void>? stopResult;
  Completer<void>? cancelResult;
  bool failCancel = false;
  int initializations = 0;
  int listenCalls = 0;
  int cancels = 0;
  SpeechResultListener? resultListener;

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    dynamic debugLogging = false,
    Duration finalTimeout = const Duration(seconds: 2),
    List<SpeechConfigOption>? options,
  }) {
    initializations++;
    return initializeResult.future;
  }

  @override
  Future<List<LocaleName>> locales() async => [LocaleName('de_DE', 'Deutsch')];

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
    resultListener = onResult;
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

  @override
  Future<dynamic> stop() async {
    stops++;
    if (failStop) throw StateError('Plugin absent');
  }

  @override
  Future<dynamic> speak(String text, {bool focus = false}) async {
    speakCalls++;
  }

  @override
  Future<dynamic> setVoice(Map<String, String> voice) async {
    if (failVoice) throw StateError('Voice absent');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> flushAsync() => Future<void>.delayed(Duration.zero);

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
}
