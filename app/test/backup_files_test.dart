import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/services/backup_files.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/backups');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late AndroidBackupFiles files;

  Matcher backupError(String message) => isA<BackupFileException>().having(
    (error) => error.message,
    'message',
    contains(message),
  );

  setUp(() {
    files = AndroidBackupFiles(channel: channel);
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('save sends exact UTF-8 bytes with a safe JSON filename', () async {
    const json = ' {"held":"Ärescan 🐉","zeile":"\\n"}\n';
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'saveJson');
      final arguments = call.arguments as Map<Object?, Object?>;
      expect(arguments['name'], 'held-aerescan.json');
      expect(arguments['bytes'], isA<Uint8List>());
      expect(arguments['bytes'], utf8.encode(json));
      return true;
    });
    expect(await files.saveJson(name: 'Held Ärescan.JSON', json: json), true);
  });

  test(
    'open returns UTF-8 content without normalizing its formatting',
    () async {
      const json = '\n{ "name": "Elöwen 🐉" }  \r\n';
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'openJson');
        expect(call.arguments, null);
        return Uint8List.fromList(utf8.encode(json));
      });
      expect(await files.openJson(), json);
    },
  );

  test('open removes an initial BOM and keeps an interior BOM', () async {
    const json = '{"name":"\uFEFFLiora"}';
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => Uint8List.fromList(utf8.encode('\uFEFF$json')),
    );
    expect(await files.openJson(), json);
  });

  test('empty files reach semantic import validation unchanged', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => Uint8List(0));
    expect(await files.openJson(), '');
  });

  test(
    'open strips only one initial BOM rather than additional content',
    () async {
      const json = '\uFEFF{}';
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => Uint8List.fromList(utf8.encode('\uFEFF$json')),
      );
      expect(await files.openJson(), json);
    },
  );

  test('save cancellation is false and permits the next operation', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => false);
    expect(await files.saveJson(name: 'save', json: '{}'), false);
    messenger.setMockMethodCallHandler(channel, (_) async => true);
    expect(await files.saveJson(name: 'save', json: '{}'), true);
  });

  test('open cancellation is null and permits the next operation', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => null);
    expect(await files.openJson(), null);
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => Uint8List.fromList(utf8.encode('{}')),
    );
    expect(await files.openJson(), '{}');
  });

  test(
    'one pending picker blocks overlapping open and save requests',
    () async {
      final picker = Completer<Object?>();
      var calls = 0;
      messenger.setMockMethodCallHandler(channel, (_) {
        calls++;
        return picker.future;
      });
      final pending = files.openJson();
      await expectLater(
        files.openJson(),
        throwsA(backupError('bereits geöffnet')),
      );
      await expectLater(
        files.saveJson(name: 'test', json: '{}'),
        throwsA(backupError('bereits geöffnet')),
      );
      expect(calls, 1);
      picker.complete(null);
      expect(await pending, null);
      messenger.setMockMethodCallHandler(channel, (_) async => true);
      expect(await files.saveJson(name: 'test', json: '{}'), true);
    },
  );

  test('oversized ASCII export is rejected before reaching Android', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (_) async {
      calls++;
      return true;
    });
    final text = String.fromCharCodes(
      Uint8List(maxBackupFileBytes + 1)
        ..fillRange(0, maxBackupFileBytes + 1, 97),
    );
    await expectLater(
      files.saveJson(name: 'big', json: text),
      throwsA(backupError('10 MiB')),
    );
    expect(calls, 0);
    expect(await files.saveJson(name: 'small', json: '{}'), true);
  });

  test('UTF-8 byte limit also rejects short multibyte export', () async {
    var calls = 0;
    messenger.setMockMethodCallHandler(channel, (_) async {
      calls++;
      return true;
    });
    final length = maxBackupFileBytes ~/ 3 + 1;
    final text = String.fromCharCodes(
      Uint16List(length)..fillRange(0, length, 0x20ac),
    );
    expect(text.length, lessThan(maxBackupFileBytes));
    await expectLater(
      files.saveJson(name: 'big', json: text),
      throwsA(backupError('10 MiB')),
    );
    expect(calls, 0);
  });

  test('exact byte limit remains a valid export', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      final arguments = call.arguments as Map<Object?, Object?>;
      expect((arguments['bytes'] as Uint8List).length, maxBackupFileBytes);
      return true;
    });
    final text = String.fromCharCodes(
      Uint8List(maxBackupFileBytes)..fillRange(0, maxBackupFileBytes, 97),
    );
    expect(await files.saveJson(name: 'limit', json: text), true);
  });

  test('oversized import is rejected before decoding', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => Uint8List(maxBackupFileBytes + 1),
    );
    await expectLater(files.openJson(), throwsA(backupError('10 MiB')));
  });

  test(
    'invalid UTF-8 import is rejected without replacement characters',
    () async {
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => Uint8List.fromList([0x7b, 0xc3, 0x28, 0x7d]),
      );
      await expectLater(files.openJson(), throwsA(backupError('UTF-8')));
    },
  );

  test('invalid import bridge results are rejected', () async {
    for (final result in [
      '{}',
      true,
      <int>[123, 125],
      12,
    ]) {
      messenger.setMockMethodCallHandler(channel, (_) async => result);
      await expectLater(files.openJson(), throwsA(backupError('gelesen')));
    }
  });

  test(
    'invalid save bridge results never report success or cancellation',
    () async {
      for (final result in [null, 'true', 1, Uint8List(0)]) {
        messenger.setMockMethodCallHandler(channel, (_) async => result);
        await expectLater(
          files.saveJson(name: 'test', json: '{}'),
          throwsA(backupError('bestätigt')),
        );
      }
    },
  );

  test(
    'native errors hide private URI and token details and release guard',
    () async {
      messenger.setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(
          code: 'file_read_failed',
          message: 'content://private/access?token=secret-token',
          details: 'backend-password',
        );
      });
      try {
        await files.openJson();
        fail('Expected a friendly error');
      } on BackupFileException catch (error) {
        expect(error.message, contains('Speicherort'));
        expect(error.toString(), isNot(contains('private')));
        expect(error.toString(), isNot(contains('secret-token')));
        expect(error.toString(), isNot(contains('backend-password')));
      }
      messenger.setMockMethodCallHandler(channel, (_) async => true);
      expect(await files.saveJson(name: 'test', json: '{}'), true);
    },
  );

  test(
    'native size and busy failures have specific friendly messages',
    () async {
      messenger.setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(code: 'too_large');
      });
      await expectLater(files.openJson(), throwsA(backupError('10 MiB')));
      messenger.setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(code: 'busy');
      });
      await expectLater(
        files.openJson(),
        throwsA(backupError('bereits geöffnet')),
      );
    },
  );

  test('missing native implementation points to clipboard fallback', () async {
    await expectLater(files.openJson(), throwsA(backupError('Zwischenablage')));
    await expectLater(
      files.saveJson(name: 'test', json: '{}'),
      throwsA(backupError('Zwischenablage')),
    );
  });

  test('filename helper preserves recognizable German labels safely', () {
    expect(
      backupFileName('Das Herz der Ewigkeit'),
      'kampagne-das-herz-der-ewigkeit.json',
    );
    expect(
      backupFileName('Ärescan, Grüße! 🐉', kind: 'Charakter'),
      'charakter-aerescan-gruesse.json',
    );
    expect(backupFileName(''), 'kampagne-sicherung.json');
    expect(backupFileName('🐉', kind: '...'), 'kampagne-sicherung.json');
  });

  test(
    'suggested filenames cannot traverse, hide, or exceed 80 characters',
    () {
      final long = List.filled(100, 'Lang-').join();
      for (final label in [
        r'../../secret.json',
        r'C:\user\../save',
        '.env',
        long,
      ]) {
        final name = backupFileName(label, kind: long);
        expect(name.length, lessThanOrEqualTo(80));
        expect(name, matches(RegExp(r'^[a-z0-9]+(?:-[a-z0-9]+)*\.json$')));
        expect(name, isNot(contains('..')));
        expect(name, isNot(contains('/')));
        expect(name, isNot(contains('\\')));
      }
    },
  );

  test('save also sanitizes caller-supplied paths without helper', () async {
    final names = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      final arguments = call.arguments as Map<Object?, Object?>;
      names.add(arguments['name'] as String);
      return true;
    });
    await files.saveJson(name: '../../.env', json: '{}');
    await files.saveJson(name: '...', json: '{}');
    await files.saveJson(name: List.filled(100, 'x').join(), json: '{}');
    expect(names[0], 'env.json');
    expect(names[1], 'sicherung.json');
    expect(names[2].length, 80);
  });
}
