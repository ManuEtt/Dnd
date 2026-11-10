import unittest
from pathlib import Path
from tempfile import TemporaryDirectory

from scripts.check_domain_boundaries import check_imports, check_repository


class StoryRulesBoundaryTests(unittest.TestCase):
    def test_repositories_are_separate(self):
        root = Path(__file__).resolve().parents[2]
        self.assertEqual([], check_repository(root))

    def test_missing_module_directories_fail_closed(self):
        with TemporaryDirectory() as temp:
            root = Path(temp)
            self.assertEqual(
                ["missing app/lib/story module", "missing app/lib/domain module"],
                check_repository(root),
            )
            (root / "app/lib/story").mkdir(parents=True)
            self.assertEqual(
                ["missing app/lib/domain module"], check_repository(root)
            )
            (root / "app/lib/domain").mkdir(parents=True)
            self.assertEqual([], check_repository(root))

    def test_regular_file_cannot_replace_module_directory(self):
        with TemporaryDirectory() as temp:
            root = Path(temp)
            (root / "app/lib").mkdir(parents=True)
            (root / "app/lib/story").write_text("not a directory", encoding="utf-8")
            (root / "app/lib/domain").mkdir()
            self.assertEqual(
                ["missing app/lib/story module"], check_repository(root)
            )

    def test_module_symlink_is_not_accepted_as_repository_source(self):
        with TemporaryDirectory() as temp:
            root = Path(temp)
            external = root / "outside"
            external.mkdir()
            (root / "app/lib").mkdir(parents=True)
            (root / "app/lib/domain").mkdir()
            try:
                (root / "app/lib/story").symlink_to(
                    external, target_is_directory=True
                )
            except (OSError, NotImplementedError) as error:
                self.skipTest(f"module symlinks unsupported: {error}")
            self.assertEqual(
                ["symlinked app/lib/story module"], check_repository(root)
            )

    def test_symlinked_parent_cannot_redirect_both_modules(self):
        with TemporaryDirectory() as temp:
            root = Path(temp)
            external = root / "external"
            (external / "story").mkdir(parents=True)
            (external / "domain").mkdir()
            (root / "app").mkdir()
            try:
                (root / "app/lib").symlink_to(
                    external, target_is_directory=True
                )
            except (OSError, NotImplementedError) as error:
                self.skipTest(f"directory symlinks unsupported: {error}")
            self.assertEqual(
                ["symlinked app/lib source root"], check_repository(root)
            )

    def test_symlinked_app_root_is_rejected_before_source_scan(self):
        with TemporaryDirectory() as temp:
            root = Path(temp)
            external = root / "external"
            (external / "lib/story").mkdir(parents=True)
            (external / "lib/domain").mkdir()
            try:
                (root / "app").symlink_to(
                    external, target_is_directory=True
                )
            except (OSError, NotImplementedError) as error:
                self.skipTest(f"directory symlinks unsupported: {error}")
            self.assertEqual(
                ["symlinked app source root"], check_repository(root)
            )

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

    def test_block_comment_before_directive_cannot_hide_forbidden_import(self):
        source = "/* license */ import '../domain/rules_engine.dart';"
        self.assertEqual(
            ["app/lib/story/chapter.dart: story must not import "
             "../domain/rules_engine.dart"],
            check_imports("app/lib/story/chapter.dart", source),
        )

    def test_nested_comment_before_part_of_still_checks_boundary(self):
        source = (
            "/* notice /* nested */ extra */ part /* marker */ of "
            "'../domain/models.dart';"
        )
        self.assertEqual(
            ["app/lib/story/chapter.dart: story must not include "
             "../domain/models.dart"],
            check_imports("app/lib/story/chapter.dart", source),
        )

    def test_multiline_block_comment_does_not_invent_forbidden_import(self):
        source = (
            "/* documentation\n"
            "import '../domain/rules_engine.dart';\n"
            "/* nested export '../domain/models.dart'; */\n"
            "*/\n"
            "import 'story_rule_boundary.dart';"
        )
        self.assertEqual([], check_imports("app/lib/story/chapter.dart", source))

    def test_multiline_string_and_raw_string_do_not_create_imports(self):
        source = (
            "final example = '''\n"
            "import '../domain/rules_engine.dart';\n"
            "''';\n"
            "final rawExample = r\"\"\"\n"
            "part '../domain/models.dart';\n"
            "\"\"\";\n"
            "import 'story_rule_boundary.dart';"
        )
        self.assertEqual([], check_imports("app/lib/story/chapter.dart", source))

    def test_comment_markers_inside_quoted_uri_are_not_comment_openers(self):
        source = (
            "import 'package:third_party/with//slashes.dart';\n"
            "/* header */ import 'story_rule_boundary.dart';"
        )
        messages = check_imports("app/lib/story/chapter.dart", source)
        self.assertEqual(1, len(messages), messages)
        self.assertIn("package:third_party/with//slashes.dart", messages[0])

    def test_comment_preceded_conditional_import_is_inspected(self):
        source = (
            "/* header */ import 'models.dart' /* options */\n"
            "if (dart.library.io) '../story/story_memory_engine.dart';"
        )
        messages = check_imports("app/lib/domain/rules.dart", source)
        self.assertEqual(1, len(messages), messages)
        self.assertIn("../story/story_memory_engine.dart", messages[0])

    def test_legitimate_comment_prefixed_local_directives_remain_allowed(self):
        source = (
            "/* header */ import 'story_rule_boundary.dart';\n"
            "/* other */ part 'chapter_generated.dart';"
        )
        self.assertEqual([], check_imports("app/lib/story/chapter.dart", source))


    def test_raw_dart_uri_directives_cannot_bypass_module_boundaries(self):
        cases = (
            (
                "app/lib/story/scene.dart",
                "import r'dart:io';",
                "forbidden platform dependency dart:io",
            ),
            (
                "app/lib/story/scene.dart",
                'export R"package:flutter/material.dart";',
                "forbidden provider/framework dependency package:flutter/material.dart",
            ),
            (
                "app/lib/story/scene.dart",
                "part r'../domain/models.dart';",
                "story must not include ../domain/models.dart",
            ),
            (
                "app/lib/story/scene.dart",
                "part of r'../domain/ai_story.dart';",
                "story must not include ../domain/ai_story.dart",
            ),
            (
                "app/lib/domain/feature.dart",
                "import r'../story/story_api.dart';",
                "rule module imports story ../story/story_api.dart",
            ),
            (
                "app/lib/domain/feature.dart",
                'export R"package:lebendiger_spielleiter/story/story_api.dart";',
                "rule module imports story package:lebendiger_spielleiter/story/story_api.dart",
            ),
            (
                "app/lib/domain/game_engine.dart",
                "part of r'../story/story_campaign_engine.dart';",
                "rule module includes story ../story/story_campaign_engine.dart",
            ),
        )
        for path, source, reason in cases:
            with self.subTest(source=source):
                self.assertEqual([f"{path}: {reason}"], check_imports(path, source))

    def test_raw_conditional_import_and_export_alternatives_are_checked(self):
        cases = (
            (
                "app/lib/domain/feature.dart",
                "import r'models.dart' if (dart.library.io) "
                "r'../story/story_memory_engine.dart';",
                "rule module imports story ../story/story_memory_engine.dart",
            ),
            (
                "app/lib/domain/feature.dart",
                "export 'models.dart' if (dart.library.io == r'true') "
                'R"package:lebendiger_spielleiter/story/story_api.dart";',
                "rule module imports story package:lebendiger_spielleiter/story/story_api.dart",
            ),
            (
                "app/lib/story/scene.dart",
                "import r'scene_helper.dart' if (dart.library.io) r'dart:io';",
                "forbidden platform dependency dart:io",
            ),
        )
        for path, source, reason in cases:
            with self.subTest(source=source):
                self.assertEqual([f"{path}: {reason}"], check_imports(path, source))

    def test_allowed_raw_uris_and_non_directive_strings_remain_valid(self):
        self.assertEqual(
            [],
            check_imports(
                "app/lib/story/scene.dart",
                "import r'../domain/models.dart';\n"
                "import R'scene_helper.dart';\n"
                "part r'scene_part.dart';",
            ),
        )
        self.assertEqual(
            [],
            check_imports(
                "app/lib/domain/game_engine.dart",
                "import r'../story/story_campaign_engine.dart';\n"
                "import R'package:flutter/foundation.dart';",
            ),
        )
        self.assertEqual(
            [],
            check_imports(
                "app/lib/domain/feature.dart",
                "import r'models.dart' if (dart.library.io) "
                "R'package:lebendiger_spielleiter/domain/models.dart';",
            ),
        )
        self.assertEqual(
            [],
            check_imports(
                "app/lib/story/scene.dart",
                "// import r'dart:io';\n"
                "final example = r\"\"\"\n"
                "import r'../domain/rules_engine.dart';\n"
                "\"\"\";\n",
            ),
        )

    def test_encoded_dependency_uris_cannot_bypass_domain_boundary(self):
        path = "app/lib/domain/rules.dart"
        uris = (
            r"../st\u006fry/hidden.dart",
            r"../st\x6fry/hidden.dart",
            r"package:lebendiger_spielleiter/%73tory/hidden.dart",
            r"package:lebendiger_spielleiter/st%6fry/hidden.dart",
        )
        for directive in ("import", "export", "part", "part of"):
            for uri in uris:
                with self.subTest(directive=directive, uri=uri):
                    self.assertEqual(
                        [f"{path}: unverifiable encoded dependency URI {uri}"],
                        check_imports(path, f"{directive} '{uri}';"),
                    )

    def test_encoded_conditional_import_uris_are_checked_individually(self):
        source = (
            "import 'models.dart'\n"
            r"  if (dart.library.io) '../st\u006fry/story_api.dart'"
            "\n"
            r"  if (dart.library.html) 'package:lebendiger_spielleiter/st%6fry/story_api.dart';"
        )
        self.assertEqual(
            [
                "app/lib/domain/rules.dart: unverifiable encoded dependency URI "
                r"../st\u006fry/story_api.dart",
                "app/lib/domain/rules.dart: unverifiable encoded dependency URI "
                "package:lebendiger_spielleiter/st%6fry/story_api.dart",
            ],
            check_imports("app/lib/domain/rules.dart", source),
        )

    def test_encoded_story_uris_are_rejected_but_plain_uris_remain_valid(self):
        path = "app/lib/story/chapter.dart"
        for uri in (
            r"dart:co\u006evert",
            r"../domain/mo%64els.dart",
            r"../story/scene\_one.dart",
        ):
            with self.subTest(uri=uri):
                self.assertEqual(
                    [f"{path}: unverifiable encoded dependency URI {uri}"],
                    check_imports(path, f"import '{uri}';"),
                )
        self.assertEqual(
            [],
            check_imports(
                path,
                "import 'dart:convert';\n"
                "import '../domain/models.dart';\n"
                "part 'chapter_scene.dart';",
            ),
        )

    def test_comments_and_non_directive_strings_with_escapes_remain_ignored(self):
        source = (
            r"// import '../st\u006fry/unsafe.dart';" "\n"
            r'final instruction = "import ../st\u006fry/unsafe.dart";' "\n"
            "import 'models.dart';"
        )
        self.assertEqual([], check_imports("app/lib/domain/rules.dart", source))


if __name__ == "__main__":
    unittest.main()
