"""Regression tests for symlinked source roots and Dart part directives.

Run: python3 -m unittest discover -s scripts/tests -p 'test_domain_boundary_roots.py' -v
"""
from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path

SPEC = importlib.util.spec_from_file_location(
    "domain_boundary_roots",
    Path(__file__).resolve().parents[1] / "check_domain_boundaries.py",
)
assert SPEC is not None and SPEC.loader is not None
boundary = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(boundary)


class SourceRootSafetyTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "app/lib/story").mkdir(parents=True)
        (self.root / "app/lib/domain").mkdir(parents=True)

    def _symlink(self, link: Path, target: Path):
        try:
            link.symlink_to(target, target_is_directory=True)
        except (OSError, NotImplementedError) as exc:
            self.skipTest(f"directory symlinks unavailable: {exc}")

    def test_app_root_symlink_is_rejected(self):
        outside = self.root / "outside"
        (self.root / "app").rename(outside)
        self._symlink(self.root / "app", outside)
        self.assertTrue(
            any("symlinked app source root" in message
                for message in boundary.check_repository(self.root))
        )

    def test_lib_root_symlink_is_rejected(self):
        outside = self.root / "outside_lib"
        (self.root / "app/lib").rename(outside)
        self._symlink(self.root / "app/lib", outside)
        self.assertTrue(
            any("symlinked app/lib source root" in message
                for message in boundary.check_repository(self.root))
        )

    def test_story_module_root_symlink_is_rejected(self):
        outside = self.root / "outside_story"
        (self.root / "app/lib/story").rename(outside)
        self._symlink(self.root / "app/lib/story", outside)
        self.assertTrue(
            any("symlinked app/lib/story module" in message
                for message in boundary.check_repository(self.root))
        )

    def test_nested_directory_symlink_is_rejected(self):
        outside = self.root / "outside_dir"
        outside.mkdir()
        self._symlink(self.root / "app/lib/story/linked", outside)
        self.assertTrue(
            any("symlinked app/lib/story/linked source entry" in message
                for message in boundary.check_repository(self.root))
        )


class DartPartSafetyTests(unittest.TestCase):
    def test_story_part_of_domain_is_forbidden(self):
        source = "part of '../domain/game_engine.dart';\n"
        problems = boundary.check_imports("app/lib/story/fragment.dart", source)
        self.assertTrue(any("game_engine.dart" in message for message in problems), problems)

    def test_domain_part_of_story_is_forbidden(self):
        source = "part of '../story/story_memory_engine.dart';\n"
        problems = boundary.check_imports("app/lib/domain/fragment.dart", source)
        self.assertTrue(any("story_memory_engine.dart" in message for message in problems), problems)

    def test_same_module_part_is_allowed(self):
        source = "part 'local_fragment.dart';\n"
        self.assertEqual(boundary.check_imports("app/lib/story/main.dart", source), [])


if __name__ == "__main__":
    unittest.main()
