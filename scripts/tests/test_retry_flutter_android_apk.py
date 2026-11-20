"""Offline regression checks for Android APK retries under transient Gradle outages."""
from __future__ import annotations

import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "retry_flutter_android_apk.sh"


class GradleBuildRetryTests(unittest.TestCase):
    def _run(self, *, failures=0, message="", attempts="3", delay="0"):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            bin_dir = root / "bin"
            bin_dir.mkdir()
            counter = root / "count"
            args_log = root / "args"
            mock_flutter = bin_dir / "flutter"
            mock_flutter.write_text(
                '#!/usr/bin/env bash\n'
                'count=$(cat "$MOCK_COUNT" 2>/dev/null || echo 0)\n'
                'count=$((count + 1))\n'
                'printf "%s" "$count" > "$MOCK_COUNT"\n'
                'printf "%s\\n" "$*" >> "$MOCK_ARGS"\n'
                'if (( count <= MOCK_FAILURES )); then\n'
                '  printf "%s\\n" "$MOCK_MESSAGE" >&2\n'
                '  exit 17\n'
                'fi\n'
                'printf "%s\\n" "Build succeeded"\n',
                encoding="utf-8",
            )
            mock_flutter.chmod(0o755)
            env = os.environ.copy()
            env.update({
                "PATH": str(bin_dir) + os.pathsep + env.get("PATH", ""),
                "MOCK_COUNT": str(counter),
                "MOCK_ARGS": str(args_log),
                "MOCK_FAILURES": str(failures),
                "MOCK_MESSAGE": message,
                "ANDROID_GRADLE_BUILD_ATTEMPTS": attempts,
                "ANDROID_GRADLE_RETRY_DELAY_SECONDS": delay,
            })
            result = subprocess.run(
                ["bash", str(SCRIPT), "--release", "--target-platform", "android-arm64"],
                env=env, capture_output=True, text=True, check=False,
            )
            count = int(counter.read_text(encoding="utf-8")) if counter.exists() else 0
            args = args_log.read_text(encoding="utf-8").splitlines() if args_log.exists() else []
            return result, count, args

    def test_success_runs_once_and_preserves_argv(self):
        result, count, args = self._run()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(count, 1)
        self.assertEqual(args, ["build apk --release --target-platform android-arm64"])

    def test_maven_rate_limit_is_retried_and_succeeds(self):
        result, count, args = self._run(
            failures=2,
            message="Could not GET 'https://repo.maven.apache.org/maven2/foo'. Received status code 429 from server: Too Many Requests",
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(count, 3)
        self.assertEqual(len(args), 3)
        self.assertIn("retrying APK build", result.stdout)

    def test_persistent_rate_limit_preserves_final_exit_code(self):
        result, count, _ = self._run(
            failures=10, message="Received status code 429 from server: Too Many Requests"
        )
        self.assertEqual(result.returncode, 17)
        self.assertEqual(count, 3)

    def test_gateway_and_transport_errors_can_retry(self):
        for message in (
            "Received status code 503 from server: Service Unavailable",
            "Temporary failure in name resolution",
            "Connection timed out",
        ):
            with self.subTest(message=message):
                result, count, _ = self._run(failures=1, message=message)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(count, 2)

    def test_compilation_error_is_never_retried(self):
        result, count, _ = self._run(
            failures=10, message="Execution failed for task ':app:compileReleaseKotlin'."
        )
        self.assertEqual(result.returncode, 17)
        self.assertEqual(count, 1)
        self.assertNotIn("retrying APK build", result.stdout)

    def test_unrelated_429_text_does_not_retrigger_build(self):
        result, count, _ = self._run(failures=10, message="Test case ID 429 failed")
        self.assertEqual(result.returncode, 17)
        self.assertEqual(count, 1)

    def test_invalid_retry_settings_fail_before_flutter_is_called(self):
        for attempts, delay in (("0", "0"), ("5", "0"), ("03", "0"), ("3", "31"), ("3", "08"), ("abc", "0")):
            with self.subTest(attempts=attempts, delay=delay):
                result, count, _ = self._run(attempts=attempts, delay=delay)
                self.assertEqual(result.returncode, 2)
                self.assertEqual(count, 0)
