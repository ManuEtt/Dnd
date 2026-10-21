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


if __name__ == "__main__":
    unittest.main()
