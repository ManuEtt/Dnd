import 'package:flutter/services.dart';

/// Displays the version from the same pubspec.yaml that Flutter uses when
/// building the APK. No separate hard-coded version needs maintenance.
class AppBuildInfo {
  const AppBuildInfo({required this.version, required this.buildNumber});

  final String version;
  final String buildNumber;

  String get display => 'Version $version (Build $buildNumber)';

  static final Future<AppBuildInfo> current = rootBundle
      .loadString('pubspec.yaml')
      .then(fromPubspec);

  static AppBuildInfo fromPubspec(String content) {
    final match = RegExp(
      r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+(?:[-.][A-Za-z0-9.-]+)?)(?:\+([0-9]+))?\s*$',
      multiLine: true,
    ).firstMatch(content);
    if (match == null) {
      throw const FormatException('Keine gültige App-Version in pubspec.yaml.');
    }
    return AppBuildInfo(
      version: match.group(1)!,
      buildNumber: match.group(2) ?? '0',
    );
  }
}
