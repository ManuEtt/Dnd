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



    def test_domain_conditional_import_rejects_story_relative_alternative(self):
        source = (
            "import 'models.dart'\n"
            "    if (dart.library.io) '../story/story_campaign_engine.dart';"
        )
        self.assertEqual(
            [
                "app/lib/domain/rules.dart: rule module imports story "
                "../story/story_campaign_engine.dart"
            ],
            check_imports("app/lib/domain/rules.dart", source),
        )

    def test_domain_conditional_export_checks_all_package_alternatives(self):
        source = (
            'export "package:lebendiger_spielleiter/domain/models.dart"\n'
            '    if (dart.library.html) "package:flutter/foundation.dart"\n'
            '    if (dart.library.io) '
            '"package:lebendiger_spielleiter/story/story_api.dart";'
        )
        messages = check_imports("app/lib/domain/rules.dart", source)
        self.assertEqual(1, len(messages))
        self.assertIn("package:lebendiger_spielleiter/story/story_api.dart", messages[0])

    def test_facade_whitelist_does_not_allow_new_conditional_story_import(self):
        source = (
            "import '../story/story_campaign_engine.dart'\n"
            "    if (dart.library.io) '../story/story_rule_port.dart';"
        )
        self.assertEqual(
            [
                "app/lib/domain/game_engine.dart: rule module imports story "
                "../story/story_rule_port.dart"
            ],
            check_imports("app/lib/domain/game_engine.dart", source),
        )

    def test_story_module_rejects_conditional_framework_import(self):
        source = (
            "import 'story_rule_boundary.dart'\n"
            "    if (dart.library.io) 'dart:io';"
        )
        self.assertEqual(
            [
                "app/lib/story/story_campaign_engine.dart: forbidden platform "
                "dependency dart:io"
            ],
            check_imports("app/lib/story/story_campaign_engine.dart", source),
        )

    def test_conditional_uri_with_string_config_value_is_inspected(self):
        source = (
            "import 'models.dart' if (dart.library.io == 'true') "
            "'../story/story_rule_port.dart';"
        )
        self.assertEqual(
            1, len(check_imports("app/lib/domain/rules.dart", source))
        )

    def test_allowed_conditional_domain_and_framework_imports_remain_valid(self):
        source = (
            "import 'models.dart'\n"
            "    if (dart.library.io) 'package:lebendiger_spielleiter/domain/models.dart'\n"
            "    if (dart.library.html) 'package:flutter/foundation.dart';"
        )
        self.assertEqual([], check_imports("app/lib/domain/rules.dart", source))

    def test_non_directive_strings_do_not_create_false_positive(self):
        source = (
            "// import 'models.dart' if (dart.library.io) '../story/unsafe.dart';\n"
            "final text = \"if (dart.library.io) '../story/unsafe.dart'\";"
        )
        self.assertEqual([], check_imports("app/lib/domain/rules.dart", source))


    def test_conditional_import_with_block_comments_still_blocks_story(self):
        source = (
            "import /* safe comment */ 'models.dart' /* between */\n"
            "    if /* platform */ (dart.library.io) /* before URI */\n"
            "       '../story/story_rule_port.dart';"
        )
        messages = check_imports("app/lib/domain/rules.dart", source)
        self.assertEqual(1, len(messages))
        self.assertIn("../story/story_rule_port.dart", messages[0])

    def test_conditional_export_with_line_comments_still_blocks_story(self):
        source = (
            "export 'models.dart' // default implementation\n"
            "    if (dart.library.io) // platform implementation\n"
            "       'package:lebendiger_spielleiter/story/story_api.dart';"
        )
        messages = check_imports("app/lib/domain/rules.dart", source)
        self.assertEqual(1, len(messages))
        self.assertIn("package:lebendiger_spielleiter/story/story_api.dart", messages[0])


    def test_domain_part_and_part_of_reject_relative_story_sources(self):
        for directive in ('part', 'part of'):
            with self.subTest(directive=directive):
                self.assertEqual(
                    ['app/lib/domain/rules.dart: rule module includes story '
                     '../story/story_memory_engine.dart'],
                    check_imports(
                        'app/lib/domain/rules.dart',
                        f"{directive} '../story/story_memory_engine.dart';",
                    ),
                )

    def test_domain_part_cannot_bypass_whitelist_or_package_alias(self):
        sources = (
            "part '../story/story_campaign_engine.dart';",
            "part of 'package:lebendiger_spielleiter/story/../story/story_api.dart';",
        )
        for source in sources:
            with self.subTest(source=source):
                messages = check_imports('app/lib/domain/game_engine.dart', source)
                self.assertEqual(1, len(messages), messages)
                self.assertIn('rule module includes story', messages[0])

    def test_story_parts_cannot_include_shared_domain_models(self):
        for directive in ('part', 'part of'):
            with self.subTest(directive=directive):
                self.assertEqual(
                    ['app/lib/story/chapter.dart: story must not include '
                     '../domain/models.dart'],
                    check_imports(
                        'app/lib/story/chapter.dart',
                        f"{directive} '../domain/models.dart';",
                    ),
                )
        self.assertEqual(
            [],
            check_imports(
                'app/lib/story/chapter.dart',
                "import '../domain/models.dart';",
            ),
        )

    def test_local_parts_and_commented_part_of_remain_valid(self):
        self.assertEqual(
            [],
            check_imports(
                'app/lib/story/chapter.dart',
                "part 'chapter_scene.dart';\n"
                "part /* comment */ of /* comment */ 'story_api.dart';",
            ),
        )
        self.assertEqual(
            [],
            check_imports(
                'app/lib/domain/rules.dart',
                "part 'rules_generated.g.dart';\n"
                "part of 'rules.dart';",
            ),
        )

    def test_commented_part_of_cannot_escape_story_boundary(self):
        source = (
            "part /* marker */ of // URI follows\n"
            "  '../domain/ai_story.dart';"
        )
        self.assertEqual(
            ['app/lib/story/chapter.dart: story must not include '
             '../domain/ai_story.dart'],
            check_imports('app/lib/story/chapter.dart', source),
        )

if __name__ == "__main__":
    unittest.main()
