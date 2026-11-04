"""Regression: nested Dart modules must obey the same Story/Rules boundaries."""
from pathlib import Path
import os
from unittest import mock
from tempfile import TemporaryDirectory
import unittest

from scripts.check_domain_boundaries import check_imports, check_repository


class NestedDomainBoundaryTests(unittest.TestCase):
    def test_nested_story_rejects_rule_engine(self):
        messages = check_imports(
            "app/lib/story/chapters/scenes/scene.dart",
            "import '../../../domain/rules_engine.dart';",
        )
        self.assertEqual(1, len(messages))
        self.assertIn("story must not import", messages[0])

    def test_nested_domain_rejects_story(self):
        messages = check_imports(
            "app/lib/domain/features/feature.dart",
            "import '../../story/story_memory_engine.dart';",
        )
        self.assertEqual(1, len(messages))
        self.assertIn("rule module imports story", messages[0])

    def test_path_aliases_do_not_bypass_boundary(self):
        self.assertEqual(
            1,
            len(check_imports(
                "app/lib/story/scene.dart",
                "import './../domain/rules_engine.dart';",
            )),
        )
        self.assertEqual(
            1,
            len(check_imports(
                "app/lib/domain/encounter_rules.dart",
                "export './../story/story_memory_engine.dart';",
            )),
        )

    def test_nested_story_can_use_shared_model_and_local_stories(self):
        self.assertEqual(
            [],
            check_imports(
                "app/lib/story/chapters/scene.dart",
                "import '../../domain/models.dart';\n"
                "import '../story_api.dart';\n"
                "import 'subchapter.dart';",
            ),
        )

    def test_recursive_repository_scan_catches_both_nesting_paths(self):
        with TemporaryDirectory() as temp:
            root = Path(temp)
            story = root / "app/lib/story/chapters"
            domain = root / "app/lib/domain/features"
            story.mkdir(parents=True)
            domain.mkdir(parents=True)
            (story / "scene.dart").write_text(
                "import '../../domain/rules_engine.dart';", encoding="utf-8"
            )
            (domain / "rules.dart").write_text(
                "import '../../story/story_memory_engine.dart';", encoding="utf-8"
            )
            problems = check_repository(root)
            self.assertEqual(2, len(problems), problems)

    @unittest.skipUnless(os.name == "posix", "POSIX symlinks required")
    def test_symlinked_nested_dart_file_is_rejected_without_reading_target(self):
        with TemporaryDirectory() as temp:
            root = Path(temp) / "repository"
            story = root / "app/lib/story/chapters"
            story.mkdir(parents=True)
            (root / "app/lib/domain").mkdir(parents=True)
            private_source = Path(temp) / "private-outside.dart"
            private_source.write_text("import 'dart:io';", encoding="utf-8")
            (story / "linked.dart").symlink_to(private_source)
            with mock.patch.object(
                Path, "read_text",
                side_effect=AssertionError("external Dart source was opened"),
            ):
                problems = check_repository(root)
            self.assertEqual(
                ["symlinked app/lib/story/chapters/linked.dart source entry"],
                problems,
            )

    @unittest.skipUnless(os.name == "posix", "POSIX symlinks required")
    def test_symlinked_nested_directory_is_rejected_without_traversal(self):
        with TemporaryDirectory() as temp:
            root = Path(temp) / "repository"
            story = root / "app/lib/story"
            story.mkdir(parents=True)
            (root / "app/lib/domain").mkdir(parents=True)
            external = Path(temp) / "external-source"
            external.mkdir()
            (external / "forbidden.dart").write_text(
                "import 'dart:io';", encoding="utf-8"
            )
            (story / "chapter_alias").symlink_to(external, target_is_directory=True)
            self.assertEqual(
                ["symlinked app/lib/story/chapter_alias source entry"],
                check_repository(root),
            )

    @unittest.skipUnless(os.name == "posix", "POSIX symlinks required")
    def test_non_dart_symlink_inside_module_is_not_accepted(self):
        with TemporaryDirectory() as temp:
            root = Path(temp) / "repository"
            story = root / "app/lib/story"
            story.mkdir(parents=True)
            (root / "app/lib/domain").mkdir(parents=True)
            external = Path(temp) / "outside-notes.txt"
            external.write_text("private notes", encoding="utf-8")
            (story / "notes.txt").symlink_to(external)
            self.assertEqual(
                ["symlinked app/lib/story/notes.txt source entry"],
                check_repository(root),
            )

    def test_recursive_repository_scan_allows_valid_nested_imports(self):
        with TemporaryDirectory() as temp:
            root = Path(temp)
            story = root / "app/lib/story/chapters"
            story.mkdir(parents=True)
            (root / "app/lib/domain").mkdir(parents=True)
            (story / "scene.dart").write_text(
                "import '../../domain/models.dart';\nimport '../story_api.dart';",
                encoding="utf-8",
            )
            self.assertEqual([], check_repository(root))


if __name__ == "__main__":
    unittest.main()
