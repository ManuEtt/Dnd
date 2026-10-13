import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Uses the device recognizer and TTS. Audio is never written to our database.
/// The device provider can require a network connection; offline is not promised.
class VoiceController extends ChangeNotifier {
  VoiceController({
    SpeechToText? speech,
    FlutterTts? tts,
    this.onPreferencesChanged,
  }) : _speech = speech ?? SpeechToText(),
       _tts = tts ?? FlutterTts();

  final SpeechToText _speech;
  final FlutterTts _tts;
  final Future<void> Function(Map<String, Object?>)? onPreferencesChanged;
  bool listening = false;
  bool speaking = false;
  bool available = true;
  bool autoSpeak = false;
  String? error;
  String? selectedVoice;
  List<Map<String, String>> voices = [];
  bool _disposed = false;
  bool _speechReady = false;
  String? _germanLocale;
  bool _startingListening = false;
  int _listenGeneration = 0;
  int _resultGeneration = -1;
  int _speakGeneration = 0;

  bool _canListen(int generation) =>
      !_disposed && generation == _listenGeneration;
  bool _canSpeak(int generation) =>
      !_disposed && generation == _speakGeneration;

  void configure(Map<String, Object?> preferences) {
    autoSpeak = preferences['autoSpeak'] == true;
    final voice = preferences['voice'];
    selectedVoice = voice is String ? voice : null;
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    if (_disposed) return;
    // Microphone initialization waits for an explicit user action.
    try {
      await _tts.setLanguage('de-DE');
      if (_disposed) return;
      await _tts.setSpeechRate(0.45);
      if (_disposed) return;
      await _tts.awaitSpeakCompletion(true);
      if (_disposed) return;
      _tts.setStartHandler(() {
        if (_disposed) return;
        speaking = true;
        _changed();
      });
      void finished() {
        if (_disposed) return;
        speaking = false;
        _changed();
      }

      _tts.setCompletionHandler(finished);
      _tts.setCancelHandler(finished);
      _tts.setErrorHandler((message) {
        if (_disposed) return;
        error = 'Sprachausgabe nicht verfügbar: $message';
        finished();
      });
      final dynamic deviceVoices = await _tts.getVoices;
      if (_disposed) return;
      if (deviceVoices is List) {
        voices = deviceVoices
            .whereType<Map>()
            .where((voice) {
              return (voice['locale']?.toString() ?? '').startsWith('de');
            })
            .map((voice) {
              return {
                'name': voice['name'].toString(),
                'locale': voice['locale'].toString(),
              };
            })
            .toList();
      }
      if (selectedVoice != null) await setVoice(selectedVoice);
    } catch (_) {
      error =
          'Auf diesem Gerät ist keine deutsche Sprachausgabe verfügbar. '
          'Installiere bei Bedarf ein deutsches System-Sprachpaket.';
    }
    _changed();
  }

  Future<void> startListening(void Function(String) onText) async {
    if (_disposed || listening || _startingListening) return;
    _startingListening = true;
    final generation = ++_listenGeneration;
    _resultGeneration = -1;
    error = null;
    try {
      await stopSpeaking();
      if (!_canListen(generation)) return;
      if (!_speechReady) {
        available = await _speech.initialize(
          onError: (failure) {
            if (_disposed) return;
            ++_listenGeneration;
            _resultGeneration = -1;
            listening = false;
            error =
                'Spracherkennung: ${failure.errorMsg}. '
                'Prüfe Mikrofonberechtigung und Verbindung und versuche es erneut.';
            _speechReady = false;
            _changed();
          },
          onStatus: (status) {
            if (_disposed) return;
            if (status == 'done' || status == 'notListening') {
              listening = false;
              _changed();
            }
          },
        );
        if (!_canListen(generation)) return;
        if (!available) {
          throw StateError('Mikrofon oder Erkennungsdienst nicht verfügbar');
        }
        final locales = await _speech.locales();
        if (!_canListen(generation)) return;
        _germanLocale = null;
        for (final locale in locales) {
          if (locale.localeId.toLowerCase().startsWith('de')) {
            _germanLocale = locale.localeId;
            break;
          }
        }
        if (_germanLocale == null) {
          throw StateError('Kein deutsches Spracherkennungspaket installiert');
        }
        _speechReady = true;
      }
      if (!_canListen(generation)) return;
      listening = true;
      _resultGeneration = generation;
      _changed();
      await _speech.listen(
        localeId: _germanLocale,
        onResult: (result) {
          if (!_disposed && _resultGeneration == generation) {
            onText(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 5),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (_) {
      if (!_canListen(generation)) return;
      listening = false;
      _resultGeneration = -1;
      _speechReady = false;
      error =
          'Deutsche Spracherkennung nicht verfügbar. Prüfe die '
          'Mikrofonberechtigung, ein deutsches Sprachpaket und die Verbindung. '
          'Du kannst deinen Text jederzeit eintippen.';
      _changed();
    } finally {
      _startingListening = false;
    }
  }

  Future<void> stopListening() async {
    ++_listenGeneration;
    if (_disposed) return;
    try {
      await _speech.stop();
    } catch (_) {
      // A missing system plugin must not block the text game.
    }
    listening = false;
    _changed();
  }

  Future<void> speak(String text) async {
    if (_disposed) return;
    final generation = ++_speakGeneration;
    await stopListening();
    if (!_canSpeak(generation)) return;
    await _stopPlayback();
    if (!_canSpeak(generation)) return;
    error = null;
    try {
      final plain = text.replaceAll(RegExp(r'[*_#`|]'), '');
      await _tts.speak(plain);
    } catch (_) {
      if (!_canSpeak(generation)) return;
      error =
          'Sprachausgabe nicht verfügbar. Die Antwort bleibt als Text lesbar.';
      speaking = false;
    }
    _changed();
  }

  Future<void> stopSpeaking() async {
    ++_speakGeneration;
    if (_disposed) return;
    await _stopPlayback();
  }

  Future<void> _stopPlayback() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Text interaction still works without a speech service.
    }
    speaking = false;
    _changed();
  }

  Future<void> setVoice(String? value) async {
    if (_disposed) return;
    try {
      if (value != null) {
        final matches = voices.where((voice) {
          return '${voice['locale']}|${voice['name']}' == value;
        });
        if (matches.isEmpty) {
          selectedVoice = null;
        } else {
          await _tts.setVoice(matches.first);
          if (_disposed) return;
          selectedVoice = value;
        }
      } else {
        await _tts.setLanguage('de-DE');
        if (_disposed) return;
        selectedVoice = null;
      }
      await _savePreferences();
    } catch (_) {
      error =
          'Die Stimme konnte nicht eingestellt werden. '
          'Prüfe das deutsche System-Sprachpaket.';
    }
    _changed();
  }

  Future<void> setAutoSpeak(bool value) async {
    if (_disposed) return;
    autoSpeak = value;
    await _savePreferences();
    _changed();
  }

  Future<void> _savePreferences() async {
    if (_disposed) return;
    try {
      await onPreferencesChanged?.call({
        'autoSpeak': autoSpeak,
        'voice': selectedVoice,
      });
    } catch (_) {
      error = 'Spracheinstellungen konnten nicht gespeichert werden.';
    }
  }

  Future<void> _ignoreAudioFailure(Future<dynamic> Function() release) async {
    try {
      await release();
    } catch (_) {
      // The controller is disposed; absent plugins must not leak future errors.
    }
  }

  Future<void> _releaseAudio() async {
    // Stop both services immediately, even if one device plugin takes time.
    await Future.wait([
      _ignoreAudioFailure(_speech.cancel),
      _ignoreAudioFailure(_tts.stop),
    ]);
  }

  @override
  void dispose() {
    _disposed = true;
    ++_listenGeneration;
    ++_speakGeneration;
    _resultGeneration = -1;
    unawaited(_releaseAudio());
    super.dispose();
  }
}
