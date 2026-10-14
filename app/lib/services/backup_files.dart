import 'dart:convert';

import 'package:flutter/services.dart';

/// A backup is bounded before encoding or decoding it into another allocation.
const maxBackupFileBytes = 10 * 1024 * 1024;

abstract class BackupFiles {
  /// Returns false when the user dismisses the document picker.
  Future<bool> saveJson({required String name, required String json});

  /// Returns null when the user dismisses the document picker.
  Future<String?> openJson();
}

class BackupFileException implements Exception {
  const BackupFileException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Suggests a basename, never a directory or a hidden file.
String backupFileName(String label, {String kind = 'kampagne'}) {
  final prefix = _boundedSlug(_slug(kind), 20, fallback: 'kampagne');
  final title = _boundedSlug(
    _slug(label),
    75 - prefix.length - 1,
    fallback: 'sicherung',
  );
  return '$prefix-$title.json';
}

String _slug(String value) {
  return value
      .toLowerCase()
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss')
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

String _boundedSlug(String value, int length, {required String fallback}) {
  final slug = value.isEmpty ? fallback : value;
  final bounded = slug.length > length ? slug.substring(0, length) : slug;
  return bounded.replaceAll(RegExp(r'-+$'), '');
}

String _safeJsonName(String value) {
  final label = value.trim().replaceFirst(
    RegExp(r'\.json$', caseSensitive: false),
    '',
  );
  return '${_boundedSlug(_slug(label), 75, fallback: 'sicherung')}.json';
}

/// Android uses the system document picker; this layer holds no storage access
/// or game-state authority. A platform error never exposes its raw details.
class AndroidBackupFiles implements BackupFiles {
  AndroidBackupFiles({MethodChannel? channel})
    : _channel =
          channel ??
          const MethodChannel('de.aetheria.lebendiger_spielleiter/backups');

  final MethodChannel _channel;
  bool _busy = false;

  @override
  Future<bool> saveJson({required String name, required String json}) {
    return _operation(() async {
      // UTF-8 needs at least as many bytes as Dart UTF-16 code units. Count the
      // remaining cases before allocating an encoded copy (e.g. many umlauts).
      if (json.length > maxBackupFileBytes) _tooLarge();
      var bytes = 0;
      for (final rune in json.runes) {
        bytes += rune <= 0x7f
            ? 1
            : rune <= 0x7ff
            ? 2
            : rune <= 0xffff
            ? 3
            : 4;
        if (bytes > maxBackupFileBytes) _tooLarge();
      }
      final result = await _channel.invokeMethod<Object?>('saveJson', {
        'name': _safeJsonName(name),
        'bytes': Uint8List.fromList(utf8.encode(json)),
      });
      if (result is! bool) {
        throw const BackupFileException(
          'Das Speichern konnte nicht bestätigt werden. Bitte versuche es erneut.',
        );
      }
      return result;
    });
  }

  @override
  Future<String?> openJson() {
    return _operation(() async {
      final result = await _channel.invokeMethod<Object?>('openJson');
      if (result == null) return null;
      if (result is! Uint8List) {
        throw const BackupFileException(
          'Die ausgewählte Datei konnte nicht gelesen werden.',
        );
      }
      if (result.length > maxBackupFileBytes) _tooLarge();
      try {
        // The decoder removes one initial UTF-8 byte-order mark, as used by
        // some external editors, and retains any further content verbatim.
        return utf8.decode(result, allowMalformed: false);
      } on FormatException {
        throw const BackupFileException(
          'Die Datei enthält keinen gültigen UTF-8-Text. Bitte wähle eine JSON-Sicherung.',
        );
      }
    });
  }

  Future<T> _operation<T>(Future<T> Function() action) async {
    if (_busy) {
      throw const BackupFileException(
        'Eine Dateiauswahl ist bereits geöffnet. Bitte schließe sie zuerst.',
      );
    }
    _busy = true;
    try {
      return await action();
    } on BackupFileException {
      rethrow;
    } on MissingPluginException {
      throw const BackupFileException(
        'Dateisicherungen sind hier nicht verfügbar. Nutze die JSON-Zwischenablage.',
      );
    } on PlatformException catch (error) {
      if (error.code == 'too_large') _tooLarge();
      if (error.code == 'busy') {
        throw const BackupFileException(
          'Eine Dateiauswahl ist bereits geöffnet. Bitte schließe sie zuerst.',
        );
      }
      throw const BackupFileException(
        'Die Datei konnte nicht verarbeitet werden. Prüfe den Speicherort und versuche es erneut.',
      );
    } catch (_) {
      throw const BackupFileException(
        'Die Datei konnte nicht verarbeitet werden. Bitte versuche es erneut.',
      );
    } finally {
      _busy = false;
    }
  }

  Never _tooLarge() {
    throw const BackupFileException(
      'Die Sicherung ist zu groß. Erlaubt sind höchstens 10 MiB.',
    );
  }
}
