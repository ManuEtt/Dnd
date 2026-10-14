import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum _PlaybackOutcome { completed, cancelled, failed }

class _Playback {
  _Playback(this.generation);
  final int generation;
  final result = Completer<_PlaybackOutcome>();

  void complete(_PlaybackOutcome outcome) {
    if (!result.isCompleted) result.complete(outcome);
  }
}

/// Uses device speech services without storing audio or promising offline use.
class VoiceController extends ChangeNotifier {
  VoiceController({
    SpeechToText? speech,
    FlutterTts? tts,
    this.onPreferencesChanged,
    this.serviceTimeout = const Duration(seconds: 5),
    this.localeTimeout = const Duration(seconds: 2),
    this.initializationTimeout = const Duration(seconds: 60),
    this.playbackTimeout = const Duration(seconds: 90),
  }) : _speech = speech ?? SpeechToText(),
       _tts = tts ?? FlutterTts();

  final SpeechToText _speech;
  final FlutterTts _tts;
  final Future<void> Function(Map<String, Object?>)? onPreferencesChanged;
  final Duration serviceTimeout;
  final Duration localeTimeout;
  final Duration initializationTimeout;
  final Duration playbackTimeout;
  bool listening = false;
  bool speaking = false;
  bool available = true;
  bool autoSpeak = false;
  bool refreshingVoices = false;
  bool ttsAvailable = false;
  String? ttsLocale;
  String? recognitionLocale;
  String? ttsEngine;
  String? error;
  String? selectedVoice;
  List<Map<String, String>> voices = [];
  bool _disposed = false;
  bool _speechReady = false;
  bool _ttsHandlersReady = false;
  bool _startingListening = false;
  int _listenGeneration = 0;
  int _resultGeneration = -1;
  int _speakGeneration = 0;
  Future<void>? _refreshFuture;
  Future<void> _outputChanges = Future<void>.value();
  _Playback? _playback;

  bool _canListen(int generation) =>
      !_disposed && generation == _listenGeneration;
  bool _canSpeak(int generation) =>
      !_disposed && generation == _speakGeneration;
  static bool _accepted(dynamic result) => result == 1 || result == true;
  static String _localeKey(String locale) =>
      locale.trim().replaceAll('_', '-').toLowerCase();
  static bool _isGerman(String locale) =>
      RegExp(r'^de(?:-[a-z0-9]+)*$').hasMatch(_localeKey(locale));
  static String _voiceId(Map<String, String> voice) =>
      '${voice['locale']}|${voice['name']}';

  void configure(Map<String, Object?> preferences) {
    autoSpeak = preferences['autoSpeak'] == true;
    final voice = preferences['voice'];
    selectedVoice = voice is String ? voice : null;
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() => refreshVoices();

  Future<void> _queueOutputChange(Future<void> Function() change) {
    final next = _outputChanges.then((_) async {
      if (!_disposed) await change();
    });
    _outputChanges = next.catchError((Object _) {});
    return next;
  }

  void _registerTtsHandlers() {
    if (_ttsHandlersReady) return;
    _tts.setStartHandler(() {
      final playback = _playback;
      if (playback == null || !_canSpeak(playback.generation)) return;
      speaking = true;
      _changed();
    });
    _tts.setCompletionHandler(() {
      final playback = _playback;
      if (playback == null || !_canSpeak(playback.generation)) return;
      playback.complete(_PlaybackOutcome.completed);
    });
    // Explicit stop releases our local wait before invoking the plugin. Its
    // delayed cancel event has no utterance ID and must not fail a newer turn.
    _tts.setCancelHandler(() {});
    _tts.setErrorHandler((message) {
      final playback = _playback;
      if (playback == null || !_canSpeak(playback.generation)) return;
      error = _ttsError(message.toString());
      playback.complete(_PlaybackOutcome.failed);
      speaking = false;
      _changed();
    });
    _ttsHandlersReady = true;
  }

  List<Map<String, String>> _germanVoices(dynamic deviceVoices) {
    if (deviceVoices is! List) return [];
    final unique = <String, Map<String, String>>{};
    for (final item in deviceVoices.whereType<Map>()) {
      final name = item['name'];
      final locale = item['locale'];
      if (name is! String ||
          name.trim().isEmpty ||
          locale is! String ||
          !_isGerman(locale)) {
        continue;
      }
      final features = item['features'];
      if (features is String &&
          features
              .split(RegExp(r'[\s,]+'))
              .any((feature) => feature.toLowerCase() == 'notinstalled')) {
        continue;
      }
      final voice = <String, String>{'name': name, 'locale': locale};
      for (final field in [
        'network_required',
        'features',
        'quality',
        'latency',
      ]) {
        final value = item[field];
        if (value is String) voice[field] = value;
      }
      unique.putIfAbsent('${_localeKey(locale)}|$name', () => voice);
    }
    final result = unique.values.toList();
    result.sort((a, b) {
      final aPreferred = _localeKey(a['locale']!) == 'de-de' ? 0 : 1;
      final bPreferred = _localeKey(b['locale']!) == 'de-de' ? 0 : 1;
      final regional = aPreferred.compareTo(bPreferred);
      if (regional != 0) return regional;
      int networkRank(Map<String, String> voice) =>
          switch (voice['network_required']) {
            '0' => 0,
            '1' => 2,
            _ => 1,
          };
      final network = networkRank(a).compareTo(networkRank(b));
      if (network != 0) return network;
      return _voiceId(a).compareTo(_voiceId(b));
    });
    return result;
  }

  Map<String, String>? _findVoice(String value) {
    for (final voice in voices) {
      if (_voiceId(voice) == value) return voice;
    }
    return null;
  }

  Future<bool> _useGermanDefault() async {
    final candidates = <String>['de-DE'];
    for (final voice in voices) {
      final locale = voice['locale']!;
      if (!candidates.any((item) => _localeKey(item) == _localeKey(locale))) {
        candidates.add(locale.replaceAll('_', '-'));
      }
    }
    // Some engines expose languages, but no individual voice list.
    if (voices.isEmpty) {
      try {
        final dynamic languages = await _tts.getLanguages.timeout(
          serviceTimeout,
        );
        if (languages is List) {
          for (final language in languages.whereType<String>()) {
            if (_isGerman(language) &&
                !candidates.any(
                  (item) => _localeKey(item) == _localeKey(language),
                )) {
              candidates.add(language.replaceAll('_', '-'));
            }
          }
        }
      } catch (_) {
        // A failed enumeration does not prove that de-DE is unavailable.
      }
    }
    for (final locale in candidates.take(4)) {
      if (_disposed) return false;
      try {
        final result = await _tts.setLanguage(locale).timeout(serviceTimeout);
        if (_disposed) return false;
        if (_accepted(result)) {
          ttsLocale = locale;
          ttsAvailable = true;
          return true;
        }
      } catch (_) {
        // Try another explicitly German regional language from the provider.
      }
    }
    ttsAvailable = false;
    ttsLocale = null;
    return false;
  }

  /// Rechecks installed output services. This never requests microphone access.
  Future<void> refreshVoices() {
    if (_disposed) return Future<void>.value();
    final existing = _refreshFuture;
    if (existing != null) return existing;
    refreshingVoices = true;
    error = null;
    _changed();
    final pending = _queueOutputChange(() async {
      await stopSpeaking();
      if (_disposed) return;
      try {
        _registerTtsHandlers();
        await _tts.setSpeechRate(0.45).timeout(serviceTimeout);
        final completion = await _tts
            .awaitSpeakCompletion(true)
            .timeout(serviceTimeout);
        if (!_accepted(completion)) throw StateError('Completion unavailable');
        dynamic deviceVoices;
        try {
          deviceVoices = await _tts.getVoices.timeout(serviceTimeout);
        } catch (_) {
          // The language setter remains the authoritative availability check.
        }
        if (_disposed) return;
        voices = _germanVoices(deviceVoices);
        try {
          final dynamic engine = await _tts.getDefaultEngine.timeout(
            serviceTimeout,
          );
          ttsEngine = engine is String && engine.trim().isNotEmpty
              ? engine
              : null;
        } catch (_) {
          ttsEngine = null;
        }
        if (_disposed) return;
        final preference = selectedVoice;
        final match = preference == null ? null : _findVoice(preference);
        var chosen = false;
        if (match != null) {
          try {
            chosen = _accepted(
              await _tts
                  .setVoice({
                    'name': match['name']!,
                    'locale': match['locale']!,
                  })
                  .timeout(serviceTimeout),
            );
          } catch (_) {
            chosen = false;
          }
          if (_disposed) return;
          if (chosen) {
            ttsAvailable = true;
            ttsLocale = match['locale'];
          }
        }
        if (!chosen) {
          final hasDefault = await _useGermanDefault();
          if (_disposed) return;
          if (hasDefault) {
            selectedVoice = null;
            if (preference != null) {
              error =
                  'Die gespeicherte Stimme ist nicht verfügbar. '
                  'Der deutsche Systemstandard wird verwendet.';
              await _savePreferences();
            }
          } else {
            error =
                'Keine deutsche Sprachausgabe verfügbar. Installiere ein '
                'deutsches Sprachpaket in den Android-Sprachausgabe-Einstellungen '
                'und suche danach erneut nach Stimmen. Text bleibt verfügbar.';
          }
        }
      } catch (_) {
        if (_disposed) return;
        ttsAvailable = false;
        ttsLocale = null;
        error =
            'Der Sprachausgabedienst antwortet nicht. Prüfe die '
            'Android-Sprachausgabe-Einstellungen und suche erneut nach Stimmen.';
      }
    });
    final complete = pending.whenComplete(() {
      _refreshFuture = null;
      refreshingVoices = false;
      _changed();
    });
    _refreshFuture = complete;
    return complete;
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
        available = await _speech
            .initialize(
              // The plugin retains these callbacks after successful initialize.
              // They consult live state rather than one initialization generation.
              onError: (failure) {
                if (_disposed || (!listening && !_startingListening)) return;
                ++_listenGeneration;
                _resultGeneration = -1;
                listening = false;
                error = _recognitionError(failure.errorMsg);
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
            )
            .timeout(initializationTimeout);
        if (!_canListen(generation)) return;
        if (!available) throw StateError('Recognizer unavailable');
        List<LocaleName>? locales;
        try {
          locales = await _speech.locales().timeout(localeTimeout);
        } catch (_) {
          // Android 13+ provider support queries can fail without completing the
          // locale future. An explicit de-DE attempt still gets a real outcome.
        }
        if (!_canListen(generation)) return;
        if (locales == null) {
          recognitionLocale = 'de-DE';
        } else {
          final german = locales
              .where((locale) => _isGerman(locale.localeId))
              .toList();
          german.sort((a, b) {
            final aPreferred = _localeKey(a.localeId) == 'de-de' ? 0 : 1;
            final bPreferred = _localeKey(b.localeId) == 'de-de' ? 0 : 1;
            return aPreferred.compareTo(bPreferred);
          });
          recognitionLocale = german.isEmpty ? 'de-DE' : german.first.localeId;
        }
        _speechReady = true;
      }
      if (!_canListen(generation)) return;
      listening = true;
      _resultGeneration = generation;
      _changed();
      // speech_to_text.listen normally returns null, not a success boolean.
      await _speech
          .listen(
            localeId: recognitionLocale,
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
          )
          .timeout(serviceTimeout);
    } catch (_) {
      if (!_canListen(generation)) return;
      listening = false;
      _resultGeneration = -1;
      _speechReady = false;
      unawaited(_ignoreAudioFailure(_speech.cancel));
      error ??=
          'Deutsche Spracherkennung nicht verfügbar. Prüfe die '
          'Mikrofonberechtigung, den Sprachdienst und die Verbindung. '
          'Du kannst deinen Text jederzeit eintippen.';
      _changed();
    } finally {
      _startingListening = false;
    }
  }

  static String _recognitionError(String code) {
    final hint = switch (code) {
      'error_permission' || 'not-allowed' =>
        'Mikrofonzugriff verweigert. Erlaube das Mikrofon in den App-Einstellungen.',
      'error_language_not_supported' || 'error_language_unavailable' =>
        'Deutsch ist beim gewählten Erkennungsdienst nicht verfügbar. '
            'Installiere dessen deutsches Sprachpaket oder wähle einen anderen '
            'Android-Spracherkennungsdienst.',
      'error_network' ||
      'error_network_timeout' ||
      'error_server_disconnected' =>
        'Der Sprachdienst konnte keine Verbindung herstellen. '
            'Prüfe die Internetverbindung und versuche es erneut.',
      'error_no_match' || 'error_speech_timeout' || 'no-speech' =>
        'Keine Sprache erkannt. Tippe erneut auf das Mikrofon und sprich deutlich.',
      'error_busy' || 'error_too_many_requests' =>
        'Der Sprachdienst ist gerade beschäftigt. Warte kurz und versuche es erneut.',
      _ =>
        'Der Sprachdienst ist nicht verfügbar. Prüfe Mikrofonberechtigung, '
            'Sprachpaket und Verbindung und versuche es erneut.',
    };
    return '$hint Du kannst deinen Text jederzeit eintippen.';
  }

  static String _ttsError(String message) {
    final code = RegExp(r' - (-?\d+)\s*$').firstMatch(message)?.group(1);
    if (code == '-6' || code == '-7') {
      return 'Die Stimme benötigt eine erreichbare Verbindung. Prüfe das '
          'Internet oder wähle eine Stimme ohne Netzwerkanforderung. '
          'Die Antwort bleibt als Text lesbar.';
    }
    if (code == '-9') {
      return 'Das Sprachpaket dieser Stimme ist nicht installiert. Installiere '
          'es in den Android-Sprachausgabe-Einstellungen und suche erneut '
          'nach Stimmen. Die Antwort bleibt als Text lesbar.';
    }
    return 'Die Sprachausgabe konnte nicht wiedergegeben werden. Prüfe die '
        'Stimme, das System-Sprachpaket und die Medienlautstärke. '
        'Die Antwort bleibt als Text lesbar.';
  }

  Future<void> stopListening() async {
    ++_listenGeneration;
    if (_disposed) return;
    listening = false;
    _changed();
    try {
      await _speech.stop().timeout(serviceTimeout);
    } catch (_) {
      // A missing system plugin must not block the text game.
    }
  }

  Future<void> speak(String text) async {
    if (_disposed) return;
    final generation = ++_speakGeneration;
    await stopListening();
    if (!_canSpeak(generation)) return;
    await _outputChanges;
    if (!_canSpeak(generation)) return;
    await _stopPlayback();
    if (!_canSpeak(generation)) return;
    if (!_ttsHandlersReady || !ttsAvailable) {
      // Refresh can invalidate a pending speak by stopping playback. Resume only
      // if no explicit stop occurred after this lazy initialization.
      final beforeRefresh = _speakGeneration;
      await refreshVoices();
      if (_disposed || _speakGeneration != beforeRefresh + 1) return;
      if (!ttsAvailable) return;
    }
    final activeGeneration = _speakGeneration;
    error = null;
    final playback = _Playback(activeGeneration);
    _playback = playback;
    speaking = true;
    _changed();
    try {
      final plain = text.replaceAll(RegExp(r'[*_#`|]'), '');
      final native = _tts
          .speak(plain)
          .then(
            (result) => _accepted(result)
                ? _PlaybackOutcome.completed
                : _PlaybackOutcome.failed,
            onError: (Object _) => _PlaybackOutcome.failed,
          );
      final result = await Future.any([
        native,
        playback.result.future,
      ]).timeout(playbackTimeout);
      if (!_canSpeak(activeGeneration)) return;
      if (result == _PlaybackOutcome.failed) {
        error ??= _ttsError('');
        unawaited(_ignoreAudioFailure(_tts.stop));
      }
    } catch (_) {
      if (!_canSpeak(activeGeneration)) return;
      error =
          'Der Sprachausgabedienst antwortet nicht mehr. Suche erneut nach '
          'Stimmen und teste die Ausgabe. Die Antwort bleibt als Text lesbar.';
      unawaited(_ignoreAudioFailure(_tts.stop));
    } finally {
      if (identical(_playback, playback)) {
        _playback = null;
        speaking = false;
        _changed();
      }
    }
  }

  Future<void> stopSpeaking() async {
    ++_speakGeneration;
    _playback?.complete(_PlaybackOutcome.cancelled);
    _playback = null;
    if (_disposed) return;
    await _stopPlayback();
  }

  Future<void> _stopPlayback() async {
    _playback?.complete(_PlaybackOutcome.cancelled);
    _playback = null;
    speaking = false;
    _changed();
    await _ignoreAudioFailure(_tts.stop);
  }

  Future<void> setVoice(String? value) => _queueOutputChange(() async {
    await stopSpeaking();
    if (_disposed) return;
    error = null;
    final previous = selectedVoice;
    try {
      if (value == null) {
        if (!await _useGermanDefault()) throw StateError('Default unavailable');
        if (_disposed) return;
        selectedVoice = null;
      } else {
        final voice = _findVoice(value);
        if (voice == null) throw StateError('Voice unavailable');
        final result = await _tts
            .setVoice({'name': voice['name']!, 'locale': voice['locale']!})
            .timeout(serviceTimeout);
        if (_disposed) return;
        if (!_accepted(result)) throw StateError('Voice rejected');
        selectedVoice = value;
        ttsLocale = voice['locale'];
        ttsAvailable = true;
      }
      await _savePreferences();
    } catch (_) {
      if (_disposed) return;
      selectedVoice = previous;
      if (!ttsAvailable) await _useGermanDefault();
      if (_disposed) return;
      error =
          'Die Stimme konnte nicht eingestellt werden. Die bisherige Auswahl '
          'bleibt erhalten. Prüfe das deutsche System-Sprachpaket und suche '
          'erneut nach Stimmen.';
    }
    _changed();
  });

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
      final pending = release();
      // Disposal is fire-and-forget; a timeout timer adds no useful guarantee
      // here. Both native release calls are dispatched independently.
      if (_disposed) {
        await pending;
      } else {
        await pending.timeout(serviceTimeout);
      }
    } catch (_) {
      // Missing or unresponsive device plugins must not leak future errors.
    }
  }

  Future<void> _releaseAudio() async {
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
    _playback?.complete(_PlaybackOutcome.cancelled);
    _playback = null;
    unawaited(_releaseAudio());
    super.dispose();
  }
}
