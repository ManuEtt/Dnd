"""Regression coverage for Story/Rules dependency boundary enforcement.

Run: python3 -m unittest discover -s scripts/tests -p 'test_domain_boundary_regressions.py' -v
"""
from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "check_domain_boundaries.py"
SPEC = importlib.util.spec_from_file_location("check_domain_boundaries", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
boundary = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(boundary)


class DirectiveRegressionTests(unittest.TestCase):
    def test_allowed_story_dependencies(self):
        source = (
            "import 'dart:convert';\n"
            "import '../domain/models.dart';\n"
            "import 'story_memory_engine.dart';\n"
        )
        self.assertEqual(boundary.check_imports("app/lib/story/sample.dart", source), [])

    def test_nested_comment_does_not_create_fake_import(self):
        source = (
            "/* outer /* inner */ import '../domain/game_engine.dart'; */\n"
            "import '../domain/models.dart';\n"
        )
        self.assertEqual(boundary.check_imports("app/lib/story/sample.dart", source), [])

    def test_multiline_string_does_not_create_fake_import(self):
        source = (
            "final example = '''\n"
            "import '../domain/game_engine.dart';\n"
            "''';\n"
        )
        self.assertEqual(boundary.check_imports("app/lib/story/sample.dart", source), [])

    def test_configurable_import_checks_alternate_uri(self):
        source = (
            "import 'story_memory_engine.dart' "
            "if (dart.library.io) '../domain/game_engine.dart';\n"
        )
        problems = boundary.check_imports("app/lib/story/sample.dart", source)
        self.assertTrue(any("game_engine.dart" in item for item in problems), problems)

    def test_package_uri_cannot_cross_into_story(self):
        source = "import 'package:lebendiger_spielleiter/story/story_memory_engine.dart';\n"
        problems = boundary.check_imports("app/lib/domain/rules.dart", source)
        self.assertTrue(any("story" in item for item in problems), problems)

    def test_encoded_story_uri_fails_closed(self):
        source = "import '../domain/%67ame_engine.dart';\n"
        problems = boundary.check_imports("app/lib/story/sample.dart", source)
        self.assertTrue(any("unverifiable" in item for item in problems), problems)


class RepositoryTraversalRegressionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "app/lib/story").mkdir(parents=True)
        (self.root / "app/lib/domain").mkdir(parents=True)

    def test_regular_modules_are_scanned(self):
        (self.root / "app/lib/story/sample.dart").write_text(
            "import '../domain/game_engine.dart';\n", encoding="utf-8"
        )
        problems = boundary.check_repository(self.root)
        self.assertTrue(any("game_engine.dart" in item for item in problems), problems)

    def test_missing_module_is_not_success(self):
        (self.root / "app/lib/domain").rmdir()
        self.assertTrue(any("missing app/lib/domain" in item
                            for item in boundary.check_repository(self.root)))

    def test_nested_symlink_is_rejected_without_following_it(self):
        outside = self.root / "outside.dart"
        outside.write_text("import 'dart:convert';\n", encoding="utf-8")
        link = self.root / "app/lib/story/linked.dart"
        try:
            link.symlink_to(outside)
        except (OSError, NotImplementedError) as exc:
            self.skipTest(f"symlinks unavailable: {exc}")
        problems = boundary.check_repository(self.root)
        self.assertTrue(any("symlinked app/lib/story/linked.dart" in item
                            for item in problems), problems)

    def test_clean_modules_pass(self):
        (self.root / "app/lib/story/sample.dart").write_text(
            "import '../domain/models.dart';\n", encoding="utf-8"
        )
        self.assertEqual(boundary.check_repository(self.root), [])


if __name__ == "__main__":
    unittest.main()
