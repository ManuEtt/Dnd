#!/usr/bin/env bash
# Retry only transient Gradle dependency-download failures. Never hide a
# persistent compilation/signing error or an unsuccessful final build.
set -euo pipefail

attempts="${ANDROID_GRADLE_BUILD_ATTEMPTS:-3}"
retry_delay="${ANDROID_GRADLE_RETRY_DELAY_SECONDS:-10}"
if [[ ! "$attempts" =~ ^[1-4]$ || ! "$retry_delay" =~ ^(0|[1-9]|[12][0-9]|30)$ ]]; then
  echo "::error::Invalid Android Gradle build retry configuration." >&2
  exit 2
fi
if (( $# == 0 )); then
  echo "::error::Pass Flutter APK build options to the retry script." >&2
  exit 2
fi

# A runner uses isolated temporary storage. Never write logs or clean caches
# inside the checkout, and keep output visible in GitHub Actions via tee.
log_file="$(mktemp)"
trap 'rm -f -- "$log_file"' EXIT

for (( attempt = 1; attempt <= attempts; attempt++ )); do
  echo "Flutter APK build (attempt $attempt/$attempts)"
  if flutter build apk "$@" 2>&1 | tee "$log_file"; then
    exit 0
  else
    status=$?
  fi

  # A missing artifact is not necessarily a network failure. Retry only
  # explicit rate-limit, gateway and transport/download diagnostics.
  if (( attempt == attempts )) || ! grep -Eqi \
      'Received status code (429|502|503|504) from server|Gradle threw an error while downloading artifacts from the network|Temporary failure in name resolution|Connection timed out|Read timed out|Connection reset by peer' \
      "$log_file"; then
    echo "::error::Flutter APK build failed without a retryable network error or attempts exhausted." >&2
    exit "$status"
  fi
  delay=$(( attempt * retry_delay ))
  echo "::warning::Transient Gradle download failure; retrying APK build after ${delay}s."
  sleep "$delay"
done
