#!/usr/bin/env bash
# Repariert dieselben Formatierungsfehler lokal bei installiertem Flutter/Dart.
set -euo pipefail
cd "$(dirname "$0")/../app"
if ! command -v dart >/dev/null 2>&1; then
  echo 'Dart-SDK fehlt. Alternativ GitHub Actions > Dart-Formatierung reparieren starten.' >&2
  exit 2
fi
dart format lib test
dart format --output=none --set-exit-if-changed lib test
printf '\nDart-Formatierung repariert. Nun flutter analyze und flutter test ausfuehren.\n'
