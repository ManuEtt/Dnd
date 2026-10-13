#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# A developer or CI can reproduce the official Android host project.
if [ ! -f android/app/build.gradle.kts ]; then
  flutter create --platforms=android --project-name=aetheria --org=com.aetheria .
fi
python3 tool/patch_android_manifest.py
