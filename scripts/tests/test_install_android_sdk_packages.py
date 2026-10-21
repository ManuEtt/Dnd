"""Offline checks for the bounded Android SDK install retry used in CI."""

from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "install_android_sdk_packages.sh"


class AndroidSdkPackageRetryTests(unittest.TestCase):
    def _run_mock(self, *, failures: int) -> tuple[subprocess.CompletedProcess[str], int, str, bool]:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            bin_dir = root / "bin"
            bin_dir.mkdir()
            sdk_root = root / "sdk"
            partial_ndk = sdk_root / "ndk" / "27.0.12077973"
            partial_ndk.mkdir(parents=True)
            (partial_ndk / "corrupt.zip").write_text("incomplete", encoding="utf-8")
            home = root / "home"
            cache = home / ".android" / "cache"
            cache.mkdir(parents=True)
            (cache / "corrupt.zip").write_text("incomplete", encoding="utf-8")

            counter = root / "counter"
            args_log = root / "args"
            mock = bin_dir / "sdkmanager"
            mock.write_text(
                "#!/usr/bin/env bash\n"
                'n=$(cat "$SDK_TEST_COUNT" 2>/dev/null || echo 0)\n'
                'n=$(( n + 1 ))\n'
                'echo "$n" > "$SDK_TEST_COUNT"\n'
                'printf "%s\\n" "$*" >> "$SDK_TEST_ARGS"\n'
                'if (( n <= SDK_TEST_FAILURES )); then exit 1; fi\n',
                encoding="utf-8",
            )
            mock.chmod(0o755)

            env = os.environ.copy()
            env.update(
                {
                    "PATH": f"{bin_dir}{os.pathsep}{env.get('PATH', '')}",
                    "HOME": str(home),
                    "ANDROID_SDK_ROOT": str(sdk_root),
                    "ANDROID_SDK_INSTALL_ATTEMPTS": "3",
                    "ANDROID_SDK_RETRY_DELAY_SECONDS": "0",
                    "SDK_TEST_COUNT": str(counter),
                    "SDK_TEST_ARGS": str(args_log),
                    "SDK_TEST_FAILURES": str(failures),
                }
            )
            env.pop("ANDROID_HOME", None)
            result = subprocess.run(
                ["bash", str(SCRIPT)],
                env=env,
                capture_output=True,
                text=True,
                check=False,
            )
            return (
                result,
                int(counter.read_text(encoding="utf-8")),
                args_log.read_text(encoding="utf-8"),
                partial_ndk.exists() or cache.exists(),
            )

    def test_transient_failure_retries_same_packages_and_cleans_cache(self) -> None:
        result, attempts, packages, cache_remains = self._run_mock(failures=1)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(attempts, 2)
        self.assertEqual(packages.count("ndk;27.0.12077973"), 2)
        self.assertIn("platforms;android-35", packages)
        self.assertFalse(cache_remains)

    def test_persistent_failure_stops_after_three_attempts(self) -> None:
        result, attempts, packages, cache_remains = self._run_mock(failures=5)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(attempts, 3)
        self.assertEqual(packages.count("cmake;3.22.1"), 3)
        self.assertFalse(cache_remains)
        self.assertIn("failed after 3 attempts", result.stderr)

    def test_missing_sdk_root_fails_closed(self) -> None:
        env = os.environ.copy()
        env.pop("ANDROID_SDK_ROOT", None)
        env.pop("ANDROID_HOME", None)
        result = subprocess.run(
            ["bash", str(SCRIPT)],
            env=env,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 2)
        self.assertIn("must name an absolute SDK directory", result.stderr)


if __name__ == "__main__":
    unittest.main()
