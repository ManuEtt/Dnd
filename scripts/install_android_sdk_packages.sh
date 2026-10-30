#!/usr/bin/env bash
# Retry temporary Android SDK download failures without hiding a persistent error.
set -euo pipefail

sdk_root="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
if [[ -z "$sdk_root" || "$sdk_root" == "/" || "$sdk_root" != /* ]]; then
  echo "::error::ANDROID_SDK_ROOT or ANDROID_HOME must name an absolute SDK directory." >&2
  exit 2
fi

attempts="${ANDROID_SDK_INSTALL_ATTEMPTS:-3}"
retry_delay="${ANDROID_SDK_RETRY_DELAY_SECONDS:-5}"
if [[ ! "$attempts" =~ ^[1-5]$ || ! "$retry_delay" =~ ^[0-9]+$ ]]; then
  echo "::error::Invalid Android SDK retry configuration." >&2
  exit 2
fi

packages=(
  "platforms;android-34"
  "platforms;android-35"
  "platforms;android-36"
  "build-tools;35.0.0"
  "ndk;27.0.12077973"
  "cmake;3.22.1"
)

for (( attempt = 1; attempt <= attempts; attempt++ )); do
  echo "Android SDK package installation (attempt $attempt/$attempts)"
  if sdkmanager "${packages[@]}"; then
    echo "Android SDK packages installed successfully."
    exit 0
  fi

  if (( attempt == attempts )); then
    echo "::error::Android SDK package installation failed after $attempts attempts." >&2
    exit 1
  fi

  echo "::warning::SDK download/extraction failed; removing temporary SDK archives before retry."
  # A broken NDK ZIP is known to leave an incomplete directory and download cache.
  rm -rf -- "$sdk_root/.temp"
  # A failure while installing a different package must not destroy a
  # previously installed NDK. Remove only an incomplete NDK directory;
  # source.properties is the package's installation metadata marker.
  if [[ ! -f "$sdk_root/ndk/27.0.12077973/source.properties" ]]; then
    rm -rf -- "$sdk_root/ndk/27.0.12077973"
  fi
  if [[ -n "${HOME:-}" ]]; then
    rm -rf -- "$HOME/.android/cache"
  fi
  sleep "$(( attempt * retry_delay ))"
done
