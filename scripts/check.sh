#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"
python3 scripts/verify_project.py
python3 -m unittest discover -s scripts/tests -v
cd "$PROJECT_ROOT/backend"
npm ci
npm run typecheck
npm test
npm run build
cd "$PROJECT_ROOT/app"
flutter pub get
flutter analyze
RUN_BACKEND_SMOKE=1 flutter test
# APK building is separate so tests also run without a local Android SDK:
# flutter build apk --debug
