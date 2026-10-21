"""Architectural contract: parallel story and SRD rule development.

Runs without Flutter in the existing repository CI. A story implementation
must only depend on domain data types and explicit rule ports, not SRD math.
A pure rules API must not export or import story modules.
"""
import re
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2] / "app" / "lib"
IMPORT = re.compile(r"^\s*(?:import|export)\s+['\"]([^'\"]+)['\"]", re.M)


def references(path: Path):
    return IMPORT.findall(path.read_text(encoding="utf-8"))


class ModuleDependenciesTests(unittest.TestCase):
    def test_story_implementation_only_uses_shared_models_and_story_ports(self):
        permitted_domain_imports = {"../domain/models.dart"}
        stories = sorted((ROOT / "story").glob("*.dart"))
        self.assertGreaterEqual(len(stories), 6)
        for path in stories:
            for reference in references(path):
                with self.subTest(source=path.name, import_path=reference):
                    if reference.startswith("../domain/"):
                        self.assertIn(reference, permitted_domain_imports)
                    self.assertNotIn("/rules/", reference)
                    self.assertNotIn("/services/", reference)

    def test_rules_api_never_imports_or_exports_story(self):
        api = ROOT / "rules" / "rules_api.dart"
        self.assertTrue(api.exists())
        for path in (ROOT / "rules").rglob("*.dart"):
            for reference in references(path):
                with self.subTest(source=path.name, import_path=reference):
                    self.assertNotIn("/story/", reference)
                    self.assertNotIn("rabenwacht", reference)
                    self.assertNotIn("ai_story", reference)

    def test_authored_campaign_is_not_duplicated_in_domain(self):
        authored = ROOT / "story" / "rabenwacht_campaign.dart"
        self.assertTrue(authored.exists())
        body = authored.read_text(encoding="utf-8")
        self.assertIn("class RabenwachtStoryModule", body)
        self.assertIn("final StoryRulePort rules", body)
        self.assertNotIn("CharacterRuleEngine.", body)
        self.assertNotIn("CampaignExperience.", body)
        legacy = (ROOT / "domain" / "rabenwacht_campaign.dart").read_text(
            encoding="utf-8"
        )
        self.assertLess(len(legacy.splitlines()), 115)
        self.assertIn("class _RabenwachtRulesAdapter", legacy)
        self.assertNotIn("Glockenturm ragt", legacy)
        self.assertIn("RabenwachtStoryModule", legacy)

    def test_ai_parser_has_single_canonical_story_source(self):
        canonical = (ROOT / "story" / "ai_story.dart").read_text(
            encoding="utf-8"
        )
        legacy = (ROOT / "domain" / "ai_story.dart").read_text(
            encoding="utf-8"
        )
        self.assertIn("class AiStoryPlan", canonical)
        self.assertLess(len(legacy.splitlines()), 8)
        self.assertIn("export '../story/ai_story.dart'", legacy)

    def test_story_rule_boundary_fails_closed(self):
        src = (ROOT / "story" / "story_rule_boundary.dart").read_text(
            encoding="utf-8"
        )
        self.assertIn("ensureRuleStateUnchanged", src)
        self.assertIn("storyOwnedFields", src)
        self.assertIn("if (_canonical(original) != _canonical(candidate))", src)


if __name__ == "__main__":
    unittest.main()
