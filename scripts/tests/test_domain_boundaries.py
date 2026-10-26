import unittest
from pathlib import Path

from scripts.check_domain_boundaries import check_imports, check_repository


class StoryRulesBoundaryTests(unittest.TestCase):
    def test_repositories_are_separate(self):
        root = Path(__file__).resolve().parents[2]
        self.assertEqual([], check_repository(root))

    def test_story_rejects_rule_engine_dependency(self):
        self.assertEqual(
            ["app/lib/story/example.dart: story must not import ../domain/rules_engine.dart"],
            check_imports(
                "app/lib/story/example.dart",
                "import '../domain/rules_engine.dart';",
            ),
        )

    def test_story_rejects_framework_import(self):
        messages = check_imports(
            "app/lib/story/example.dart",
            "import 'package:flutter/material.dart';",
        )
        self.assertEqual(1, len(messages))

    def test_rules_cannot_import_story(self):
        messages = check_imports(
            "app/lib/domain/magic_missile_rules.dart",
            "import '../story/story_campaign_engine.dart';",
        )
        self.assertEqual(1, len(messages))

    def test_followup_story_adapter_is_explicitly_allowed(self):
        self.assertEqual(
            [],
            check_imports(
                "app/lib/domain/rabenwacht_campaign.dart",
                "import '../story/fourteenth_voice_campaign.dart';",
            ),
        )
        self.assertEqual(
            [
                "app/lib/domain/character_rule_engine.dart: rule module imports story "
                "../story/fourteenth_voice_campaign.dart"
            ],
            check_imports(
                "app/lib/domain/character_rule_engine.dart",
                "import '../story/fourteenth_voice_campaign.dart';",
            ),
        )

    def test_facade_and_shared_model_are_allowed(self):
        self.assertEqual(
            [],
            check_imports(
                "app/lib/domain/game_engine.dart",
                "import '../story/story_campaign_engine.dart';",
            ),
        )
        self.assertEqual(
            [],
            check_imports(
                "app/lib/story/story_campaign_engine.dart",
                "import '../domain/models.dart';\n"
                "import '../domain/ai_story.dart';\n"
                "import 'story_rule_boundary.dart';",
            ),
        )


    def test_current_package_name_matches_boundary_guard(self):
        from scripts.check_domain_boundaries import APPLICATION_PACKAGE

        root = Path(__file__).resolve().parents[2]
        pubspec = (root / "app/pubspec.yaml").read_text(encoding="utf-8")
        declared = next(
            line.split(":", 1)[1].strip()
            for line in pubspec.splitlines()
            if line.startswith("name:")
        )
        self.assertEqual(declared, APPLICATION_PACKAGE)

    def test_domain_package_import_and_export_cannot_reach_story(self):
        uri = "package:lebendiger_spielleiter/story/story_api.dart"
        for directive in ("import", "export"):
            with self.subTest(directive=directive):
                self.assertEqual(
                    [f"app/lib/domain/rules.dart: rule module imports story {uri}"],
                    check_imports(
                        "app/lib/domain/rules.dart",
                        f"{directive} '{uri}';",
                    ),
                )

    def test_domain_package_aliases_cannot_bypass_story_boundary(self):
        for uri in (
            "package:lebendiger_spielleiter/./story/story_api.dart",
            "package:lebendiger_spielleiter/domain/../story/story_api.dart",
            "package:lebendiger_spielleiter//story/story_api.dart",
        ):
            with self.subTest(uri=uri):
                messages = check_imports(
                    "app/lib/domain/deep/rules.dart",
                    f"import '{uri}';",
                )
                self.assertEqual(1, len(messages))
                self.assertIn("rule module imports story", messages[0])

    def test_domain_package_imports_outside_story_stay_allowed(self):
        self.assertEqual(
            [],
            check_imports(
                "app/lib/domain/rules.dart",
                "import 'package:lebendiger_spielleiter/domain/models.dart';\n"
                "import 'package:lebendiger_spielleiter/story/../domain/models.dart';\n"
                "import 'package:flutter/foundation.dart';\n"
                "import 'dart:convert';",
            ),
        )

    def test_story_package_import_restriction_stays_strict(self):
        self.assertEqual(
            1,
            len(check_imports(
                "app/lib/story/example.dart",
                "import 'package:lebendiger_spielleiter/domain/models.dart';",
            )),
        )



if __name__ == "__main__":
    unittest.main()
