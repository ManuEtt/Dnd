"""Offline checks for the bounded Android SDK install retry used in CI."""

from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "install_android_sdk_packages.sh"


class AndroidSdkPackageRetryTests(unittest.TestCase):
    def _run_mock(
        self, *, failures: int, existing_ndk: bool = False
    ) -> tuple[subprocess.CompletedProcess[str], int, str, bool, bool]:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            bin_dir = root / "bin"
            bin_dir.mkdir()
            sdk_root = root / "sdk"
            partial_ndk = sdk_root / "ndk" / "27.0.12077973"
            partial_ndk.mkdir(parents=True)
            if existing_ndk:
                (partial_ndk / "source.properties").write_text(
                    "Pkg.Revision = 27.0.12077973\n", encoding="utf-8"
                )
                (partial_ndk / "ndk-build").write_text("installed", encoding="utf-8")
            else:
                (partial_ndk / "corrupt.zip").write_text(
                    "incomplete", encoding="utf-8"
                )
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
                partial_ndk.exists(),
                cache.exists(),
            )

    def test_transient_failure_retries_same_packages_and_cleans_cache(self) -> None:
        result, attempts, packages, ndk_remains, cache_remains = self._run_mock(failures=1)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(attempts, 2)
        self.assertEqual(packages.count("ndk;27.0.12077973"), 2)
        self.assertIn("platforms;android-35", packages)
        self.assertFalse(ndk_remains)
        self.assertFalse(cache_remains)

    def test_persistent_failure_stops_after_three_attempts(self) -> None:
        result, attempts, packages, ndk_remains, cache_remains = self._run_mock(failures=5)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(attempts, 3)
        self.assertEqual(packages.count("cmake;3.22.1"), 3)
        self.assertFalse(ndk_remains)
        self.assertFalse(cache_remains)
        self.assertIn("failed after 3 attempts", result.stderr)

    def test_preinstalled_ndk_survives_transient_failure(self) -> None:
        result, attempts, packages, ndk_remains, cache_remains = self._run_mock(
            failures=1, existing_ndk=True
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(attempts, 2)
        self.assertEqual(packages.count("ndk;27.0.12077973"), 2)
        self.assertTrue(ndk_remains)
        self.assertFalse(cache_remains)

    def test_preinstalled_ndk_survives_persistent_failure(self) -> None:
        result, attempts, _, ndk_remains, cache_remains = self._run_mock(
            failures=5, existing_ndk=True
        )
        self.assertEqual(result.returncode, 1)
        self.assertEqual(attempts, 3)
        self.assertTrue(ndk_remains)
        self.assertFalse(cache_remains)

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


    def test_sdk_root_aliases_of_filesystem_root_fail_before_sdkmanager(self) -> None:
        # The mock succeeds immediately, so even a broken guard cannot run
        # deletion against the filesystem root during this regression test.
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            binary = root / "bin"
            binary.mkdir()
            marker = root / "sdkmanager-was-called"
            manager = binary / "sdkmanager"
            manager.write_text(
                '#!/usr/bin/env bash\n'
                'printf "called" > "$SDK_TEST_MARKER"\n',
                encoding="utf-8",
            )
            manager.chmod(0o755)

            linked_root = root / "sdk-link-to-root"
            linked_root.symlink_to("/", target_is_directory=True)
            env = os.environ.copy()
            env.pop("ANDROID_HOME", None)
            env.update(
                {
                    "PATH": f"{binary}{os.pathsep}{env.get('PATH', '')}",
                    "HOME": str(root),
                    "SDK_TEST_MARKER": str(marker),
                    "ANDROID_SDK_INSTALL_ATTEMPTS": "1",
                    "ANDROID_SDK_RETRY_DELAY_SECONDS": "0",
                }
            )
            for sdk_root in ("/.", "/..", str(linked_root)):
                with self.subTest(sdk_root=sdk_root):
                    env["ANDROID_SDK_ROOT"] = sdk_root
                    result = subprocess.run(
                        ["bash", str(SCRIPT)],
                        env=env,
                        capture_output=True,
                        text=True,
                        check=False,
                    )
                    self.assertEqual(result.returncode, 2, result.stderr)
                    self.assertIn("absolute SDK directory", result.stderr)
                    self.assertFalse(marker.exists())

    def test_sdk_root_must_exist_but_valid_canonical_alias_works(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            binary = root / "bin"
            binary.mkdir()
            marker = root / "sdkmanager-was-called"
            manager = binary / "sdkmanager"
            manager.write_text(
                '#!/usr/bin/env bash\n'
                'printf "called" > "$SDK_TEST_MARKER"\n',
                encoding="utf-8",
            )
            manager.chmod(0o755)
            env = os.environ.copy()
            env.pop("ANDROID_HOME", None)
            env.update(
                {
                    "PATH": f"{binary}{os.pathsep}{env.get('PATH', '')}",
                    "HOME": str(root),
                    "SDK_TEST_MARKER": str(marker),
                    "ANDROID_SDK_INSTALL_ATTEMPTS": "1",
                    "ANDROID_SDK_RETRY_DELAY_SECONDS": "0",
                    "ANDROID_SDK_ROOT": str(root / "missing-sdk"),
                }
            )
            invalid = subprocess.run(
                ["bash", str(SCRIPT)], env=env, capture_output=True, text=True,
                check=False,
            )
            self.assertEqual(invalid.returncode, 2, invalid.stderr)
            self.assertFalse(marker.exists())

            sdk = root / "sdk"
            (sdk / "nested").mkdir(parents=True)
            env["ANDROID_SDK_ROOT"] = str(sdk / "nested" / "..")
            valid = subprocess.run(
                ["bash", str(SCRIPT)], env=env, capture_output=True, text=True,
                check=False,
            )
            self.assertEqual(valid.returncode, 0, valid.stderr)
            self.assertTrue(marker.exists())


    def test_unsafe_home_aliases_skip_cache_cleanup_but_retry_sdk(self) -> None:
        # Mock rm for root aliases: even a regression must never delete
        # anything outside this test sandbox.
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            sdk = root / "sdk"
            sdk.mkdir()
            binary = root / "bin"
            binary.mkdir()
            counter = root / "counter"
            rm_log = root / "removed"
            manager = binary / "sdkmanager"
            manager.write_text(
                '#!/usr/bin/env bash\n'
                'n=$(cat "$SDK_TEST_COUNT" 2>/dev/null || echo 0)\n'
                'n=$((n + 1))\n'
                'echo "$n" > "$SDK_TEST_COUNT"\n'
                '(( n > 1 ))\n',
                encoding="utf-8",
            )
            manager.chmod(0o755)
            removal = binary / "rm"
            removal.write_text(
                '#!/usr/bin/env bash\n'
                'printf "%s\\n" "$*" >> "$SDK_TEST_RM_LOG"\n',
                encoding="utf-8",
            )
            removal.chmod(0o755)
            home_root_link = root / "root-link"
            home_root_link.symlink_to("/", target_is_directory=True)
            env = os.environ.copy()
            env.update(
                {
                    "PATH": f"{binary}{os.pathsep}{env.get('PATH', '')}",
                    "ANDROID_SDK_ROOT": str(sdk),
                    "ANDROID_SDK_INSTALL_ATTEMPTS": "2",
                    "ANDROID_SDK_RETRY_DELAY_SECONDS": "0",
                    "SDK_TEST_COUNT": str(counter),
                    "SDK_TEST_RM_LOG": str(rm_log),
                }
            )
            env.pop("ANDROID_HOME", None)
            for home in ("/", "/..", str(home_root_link), "relative-home"):
                with self.subTest(home=home):
                    counter.unlink(missing_ok=True)
                    rm_log.unlink(missing_ok=True)
                    env["HOME"] = home
                    result = subprocess.run(
                        ["bash", str(SCRIPT)], env=env, capture_output=True,
                        text=True, check=False,
                    )
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(counter.read_text(encoding="utf-8").strip(), "2")
                    self.assertIn("Skipping unsafe Android user cache", result.stderr)
                    removed = rm_log.read_text(encoding="utf-8")
                    self.assertIn(str(sdk / ".temp"), removed)
                    self.assertNotIn(".android/cache", removed)

    def test_symlinked_android_cache_parents_preserve_external_data(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            sdk = root / "sdk"
            sdk.mkdir()
            binary = root / "bin"
            binary.mkdir()
            counter = root / "counter"
            manager = binary / "sdkmanager"
            manager.write_text(
                '#!/usr/bin/env bash\n'
                'n=$(cat "$SDK_TEST_COUNT" 2>/dev/null || echo 0)\n'
                'n=$((n + 1))\n'
                'echo "$n" > "$SDK_TEST_COUNT"\n'
                '(( n > 1 ))\n',
                encoding="utf-8",
            )
            manager.chmod(0o755)
            env = os.environ.copy()
            env.update(
                {
                    "PATH": f"{binary}{os.pathsep}{env.get('PATH', '')}",
                    "ANDROID_SDK_ROOT": str(sdk),
                    "ANDROID_SDK_INSTALL_ATTEMPTS": "2",
                    "ANDROID_SDK_RETRY_DELAY_SECONDS": "0",
                    "SDK_TEST_COUNT": str(counter),
                }
            )
            env.pop("ANDROID_HOME", None)

            for kind in ("android-parent", "cache"):
                with self.subTest(kind=kind):
                    counter.unlink(missing_ok=True)
                    home = root / f"home-{kind}"
                    home.mkdir()
                    external = root / f"external-{kind}"
                    cache = external / "cache"
                    cache.mkdir(parents=True)
                    sentinel = cache / "keep-me"
                    sentinel.write_text("unrelated", encoding="utf-8")
                    if kind == "android-parent":
                        (home / ".android").symlink_to(external, target_is_directory=True)
                    else:
                        (home / ".android").mkdir()
                        (home / ".android/cache").symlink_to(
                            cache, target_is_directory=True
                        )
                    env["HOME"] = str(home)
                    result = subprocess.run(
                        ["bash", str(SCRIPT)], env=env, capture_output=True,
                        text=True, check=False,
                    )
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertIn("Skipping unsafe Android user cache", result.stderr)
                    self.assertEqual(counter.read_text(encoding="utf-8").strip(), "2")
                    self.assertTrue(sentinel.exists())
                    self.assertEqual(sentinel.read_text(encoding="utf-8"), "unrelated")

    def test_canonical_safe_home_alias_clears_cache_after_retry(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            sdk = root / "sdk"
            sdk.mkdir()
            home = root / "home"
            (home / "nested").mkdir(parents=True)
            cache = home / ".android/cache"
            cache.mkdir(parents=True)
            (cache / "temporary.zip").write_text("incomplete", encoding="utf-8")
            binary = root / "bin"
            binary.mkdir()
            counter = root / "counter"
            manager = binary / "sdkmanager"
            manager.write_text(
                '#!/usr/bin/env bash\n'
                'n=$(cat "$SDK_TEST_COUNT" 2>/dev/null || echo 0)\n'
                'n=$((n + 1))\n'
                'echo "$n" > "$SDK_TEST_COUNT"\n'
                '(( n > 1 ))\n',
                encoding="utf-8",
            )
            manager.chmod(0o755)
            env = os.environ.copy()
            env.update(
                {
                    "PATH": f"{binary}{os.pathsep}{env.get('PATH', '')}",
                    "HOME": str(home / "nested" / ".."),
                    "ANDROID_SDK_ROOT": str(sdk),
                    "ANDROID_SDK_INSTALL_ATTEMPTS": "2",
                    "ANDROID_SDK_RETRY_DELAY_SECONDS": "0",
                    "SDK_TEST_COUNT": str(counter),
                }
            )
            env.pop("ANDROID_HOME", None)
            result = subprocess.run(
                ["bash", str(SCRIPT)], env=env, capture_output=True,
                text=True, check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(counter.read_text(encoding="utf-8").strip(), "2")
            self.assertFalse(cache.exists())

if __name__ == "__main__":
    unittest.main()
