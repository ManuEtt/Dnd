import 'package:flutter_test/flutter_test.dart';
import 'package:lebendiger_spielleiter/ui/app_build_info.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Version und Buildnummer stammen aus dem Paketmanifest', () {
    const pubspec = '''
name: lebendiger_spielleiter
description: "Würfelraunen"
version: 0.8.5+55
dependencies:
  flutter:
    sdk: flutter
''';
    final info = AppBuildInfo.fromPubspec(pubspec);
    expect(info.version, '0.8.5');
    expect(info.buildNumber, '55');
    expect(info.display, 'Version 0.8.5 (Build 55)');
  });

  test(
    'Vorabversionen bleiben sichtbar und ein fehlender Build wird erkannt',
    () {
      expect(
        AppBuildInfo.fromPubspec('version: 1.2.3-beta.1+41').display,
        'Version 1.2.3-beta.1 (Build 41)',
      );
      expect(
        AppBuildInfo.fromPubspec('version: 2.0.0').display,
        'Version 2.0.0 (Build 0)',
      );
    },
  );

  test('Unbekannte und manipulierte Versionsangaben werden nicht geraten', () {
    for (final invalid in [
      '',
      'name: test',
      'version: unknown',
      'version: 1.0',
    ]) {
      expect(
        () => AppBuildInfo.fromPubspec(invalid),
        throwsFormatException,
        reason: invalid,
      );
    }
  });

  test('Die aktuell gebündelte pubspec.yaml zeigt die Paketversion', () async {
    final info = await AppBuildInfo.current;
    expect(info.version, matches(RegExp(r'^\d+\.\d+\.\d+')));
    expect(int.parse(info.buildNumber), greaterThanOrEqualTo(0));
  });
}
