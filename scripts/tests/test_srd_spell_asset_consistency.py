"""Keep the SRD spell asset and requirement inventory in sync."""
from pathlib import Path
import json
import unittest

ROOT = Path(__file__).resolve().parents[2]
ASSET = ROOT / "app/assets/srd_5_2_1_spells.json"
ENTITY_INDEX = ROOT / "docs/srd_5_2_1_entities.json"
BASE_REQUIREMENTS = ROOT / "docs/srd_5_2_1_requirements.json"
KNOWN_CLASSES = {
    "Bard", "Cleric", "Druid", "Paladin", "Ranger",
    "Sorcerer", "Warlock", "Wizard",
}


class SrdSpellAssetConsistencyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.asset = json.loads(ASSET.read_text(encoding="utf-8"))
        cls.entities = json.loads(ENTITY_INDEX.read_text(encoding="utf-8"))
        cls.requirements = json.loads(BASE_REQUIREMENTS.read_text(encoding="utf-8"))

    def test_339_names_are_unique_and_cross_reference_all_requirements(self):
        spells = self.asset["spells"]
        self.assertEqual(len(spells), 339)
        names = [s["name"] for s in spells]
        self.assertEqual(len(set(names)), 339)
        self.assertEqual(len(set(s["id"] for s in spells)), 339)
        named_entities = {
            r["name"] for r in self.entities["entries"]
            if r["kind"] == "spell_definition"
        }
        existing = {
            r["name"] for r in self.requirements["requirements"]
            if r["kind"] == "spell_definition"
        }
        self.assertEqual(existing, {"Magic Missile", "Shield"})
        self.assertEqual(len(named_entities), 337)
        self.assertEqual(set(names), named_entities | existing)

    def test_metadata_shape_and_provenance_are_consistent(self):
        self.assertEqual(self.asset["srd_version"], "5.2.1")
        self.assertFalse(self.asset["official_full_reconciliation_complete"])
        self.assertFalse(self.asset["effect_engine_complete"])
        for spell in self.asset["spells"]:
            self.assertIn(spell["level"], range(10), spell["name"])
            self.assertTrue(spell["school"], spell["name"])
            self.assertTrue(spell["classes"], spell["name"])
            self.assertLessEqual(set(spell["classes"]), KNOWN_CLASSES, spell["name"])
            self.assertTrue(spell["casting_time"], spell["name"])
            self.assertTrue(spell["range"], spell["name"])
            self.assertTrue(spell["duration"], spell["name"])
            self.assertTrue(spell["components"], spell["name"])
            components = {
                x.strip() for x in spell["components"].split("(", 1)[0].split(",")
            }
            self.assertLessEqual(components, {"V", "S", "M"}, spell["name"])
            for key, symbol in (("verbal", "V"), ("somatic", "S"), ("material", "M")):
                self.assertIs(spell[key], symbol in components, spell["name"])
            self.assertIs(
                spell["concentration"],
                spell["duration"].startswith("Concentration"),
                spell["name"],
            )
            self.assertIs(
                spell["ritual"],
                "Ritual" in spell["casting_time"],
                spell["name"],
            )
            self.assertIs(spell["mechanical_effect_implemented"], False)


if __name__ == "__main__":
    unittest.main()
