import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Device-native speech services. Android speech recognition may need network
/// access depending on the installed recognizer and language packs.
class VoiceService {
  final stt.SpeechToText _recognizer = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechAvailable = false;
  bool get listening => _recognizer.isListening;

  Future<bool> initialize() async {
    _speechAvailable = await _recognizer.initialize();
    await _tts.setLanguage('de-DE');
    await _tts.setSpeechRate(0.48);
    return _speechAvailable;
  }

  Future<void> listen(void Function(String) onWords) async {
    if (!_speechAvailable) throw StateError('Keine Spracherkennung auf diesem Gerät verfügbar.');
    await _recognizer.listen(
      onResult: (result) => onWords(result.recognizedWords),
      localeId: 'de_DE',
    );
  }

  Future<void> stopListening() => _recognizer.stop();
  Future<void> speak(String message) async {
    await _tts.stop();
    await _tts.speak(message);
  }
  Future<void> stopSpeaking() async { await _tts.stop(); }
  Future<void> dispose() async {
    await _recognizer.stop();
    await _tts.stop();
  }
}
