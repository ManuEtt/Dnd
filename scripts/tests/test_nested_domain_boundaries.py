"""Regression: nested Dart modules must obey the same Story/Rules boundaries."""
from pathlib import Path
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
