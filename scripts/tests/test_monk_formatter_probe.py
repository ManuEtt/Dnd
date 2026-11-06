"""Temporary CI-only diagnosis: print Dart's canonical formatted test source."""

import os
from pathlib import Path
import subprocess
import unittest


class TestMonkFormatterProbe(unittest.TestCase):
    def test_output_canonical_dart_style(self):
        root = Path(__file__).resolve().parents[2]
        sdk = Path(os.environ.get("FLUTTER_ROOT", "/nonexistent"))
        dart = sdk / "bin" / "cache" / "dart-sdk" / "bin" / "dart"
        if not dart.is_file():
            self.skipTest("Flutter's Dart SDK is not present in this CI step")
        target = root / "app" / "test" / "monk_self_restoration_class_preflight_test.dart"
        result = subprocess.run(
            [str(dart), "format", "--output=show", str(target)],
            capture_output=True,
            text=True,
            check=False,
            timeout=30,
        )
        print("\n--- BEGIN CANONICAL MONK DART FORMAT ---\n", flush=True)
        print(result.stdout, flush=True)
        print("\n--- END CANONICAL MONK DART FORMAT ---\n", flush=True)
        print(result.stderr, flush=True)
        self.assertEqual(result.returncode, 0, result.stderr)
