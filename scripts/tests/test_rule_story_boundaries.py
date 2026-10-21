"""CI guardrails for parallel rule-engine and narrative development.

Temporary legacy facade domain/game_engine.dart is the ONLY adapter allowed
to reach into both domains. New logic belongs in rules/ or story/.
"""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]
LIB = ROOT / "app" / "lib"
IMPORT = re.compile(r'''^\s*(?:import|export)\s+["']([^"']+)["']''', re.M)

def sources(folder: str):
    return sorted((LIB / folder).rglob("*.dart"))

def deps(file: Path):
    return IMPORT.findall(file.read_text(encoding="utf-8"))

class RuleStoryBoundariesTest(unittest.TestCase):
    def test_rule_modules_cannot_import_story_or_narration(self):
        self.assertTrue(sources("rules"))
        for file in sources("rules"):
            for uri in deps(file):
                self.assertNotIn("/story/", "/" + uri, file.as_posix())
                self.assertNotIn("ai_story.dart", uri, file.as_posix())
                self.assertNotIn("rabenwacht_campaign.dart", uri, file.as_posix())
                self.assertNotIn("backend_narrator.dart", uri, file.as_posix())

    def test_story_modules_never_import_game_engine_or_rule_effects(self):
        self.assertTrue(sources("story"))
        blocked = (
            "game_engine.dart", "dice_engine.dart", "rules_engine.dart",
            "spellcasting_rules.dart", "srd_extra_creature_attack_rules.dart",
            "combat_class_actions.dart", "backend_narrator.dart", "rules_api.dart",
        )
        for file in sources("story"):
            for uri in deps(file):
                self.assertFalse(
                    any(uri.endswith(name) for name in blocked),
                    f"{file}: story code must request game changes through a boundary, not import {uri}",
                )

    def test_shared_event_committer_only_knows_versioned_data(self):
        file = LIB / "domain" / "campaign_event_committer.dart"
        self.assertEqual(deps(file), ["models.dart"])
        src = file.read_text(encoding="utf-8")
        self.assertIn("revision: before.revision + 1", src)
        self.assertIn("Campaign.fromJson(result.toJson())", src)

    def test_legacy_facade_delegates_story_work_instead_of_reimplementing(self):
        engine = (LIB / "domain" / "game_engine.dart").read_text(encoding="utf-8")
        self.assertIn("import '../story/campaign_story_engine.dart';", engine)
        self.assertIn("_events.commit(", engine)
        for call in (
            "story.replaceNarration", "story.createAiCampaign",
            "story.applyAiStoryStep", "story.rejectAdventure",
            "story.saveSessionRecap", "story.recordNpcRelationship",
            "story.saveStoryThread", "story.createDemo",
            "story.createRabenwacht",
        ):
            with self.subTest(call=call):
                self.assertIn(call, engine)
        self.assertNotIn("final recap = SessionRecap(", engine)
        self.assertNotIn("final entry = NpcRelationshipNote(", engine)

if __name__ == "__main__":
    unittest.main()
