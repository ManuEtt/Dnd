"""Regression tests for SRD requirement inventory and honest progress reporting."""
import copy
import json
from pathlib import Path
import unittest

from scripts.srd_coverage import MATRIX, CATALOGUE, ENTITIES, summary, validate_matrix, validate_entities


class SrdRequirementsMatrixTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.matrix = json.loads(MATRIX.read_text(encoding="utf-8"))
        cls.catalogue = json.loads(CATALOGUE.read_text(encoding="utf-8"))
        cls.entities = json.loads(ENTITIES.read_text(encoding="utf-8"))

    def test_matrix_is_valid_and_ids_are_unique(self):
        self.assertEqual(validate_matrix(self.matrix, self.catalogue), [])
        rows = self.matrix["requirements"]
        self.assertEqual(len({r["id"] for r in rows}), len(rows))

    def test_class_features_match_all_catalogue_entries(self):
        features = [r for r in self.matrix["requirements"] if r["kind"] == "level_feature"]
        self.assertEqual(len(features), 282)
        self.assertEqual(len({r["class_name"] for r in features}), 12)
        self.assertEqual(len({r["subclass"] for r in features if r["subclass"]}), 12)
        self.assertTrue(all(1 <= r["class_level"] <= 20 for r in features))
        self.assertTrue(all(r["rule_implemented"] != "tested" for r in features))

    def test_incomplete_inventory_does_not_claim_global_percent(self):
        result = summary(self.matrix, self.entities)
        self.assertEqual(result["counted_requirements"], 1419)
        self.assertFalse(result["scope_complete"])
        self.assertGreater(result["open_inventory_gaps"], 0)
        self.assertIsNone(result["global_srd_coverage_percent"])

    def test_944_named_entities_and_srd_spell_levels(self):
        self.assertEqual(validate_entities(self.entities, self.matrix), [])
        self.assertEqual(len(self.entities["entries"]), 944)
        rows = self.entities["entries"]
        self.assertEqual(sum(r["kind"] == "spell_definition" for r in rows), 337)
        self.assertEqual(sum(r["kind"] == "monster_statblock" for r in rows), 330)
        self.assertEqual(sum(r["kind"] == "magic_item" for r in rows), 260)
        self.assertEqual(sum(r["kind"] == "feat" for r in rows), 17)
        self.assertFalse(self.entities["verified_against_official_pdf"])

    def test_duplicates_across_both_inventories_rejected(self):
        changed = copy.deepcopy(self.entities)
        changed["entries"][0]["id"] = self.matrix["requirements"][0]["id"]
        self.assertTrue(any("Doppelte Entity-/Requirement-ID" in e
                            for e in validate_entities(changed, self.matrix)))

    def test_duplicate_id_is_rejected(self):
        changed = copy.deepcopy(self.matrix)
        changed["requirements"].append(copy.deepcopy(changed["requirements"][0]))
        self.assertTrue(any("Doppelte Anforderungs-ID" in e for e in validate_matrix(changed, self.catalogue)))

    def test_unproved_test_claim_is_rejected(self):
        changed = copy.deepcopy(self.matrix)
        feature = next(r for r in changed["requirements"] if r["kind"] == "level_feature")
        feature["rule_implemented"] = "tested"
        self.assertTrue(any("voll getestet ohne konkrete Testreferenz" in e for e in validate_matrix(changed, self.catalogue)))

    def test_malformed_matrix_records_report_errors_without_traceback(self):
        broken = copy.deepcopy(self.matrix)
        broken["requirements"][0]["area"] = ["combat"]
        broken["requirements"][0]["rule_implemented"] = {"status": "tested"}
        feature = next(r for r in broken["requirements"] if r["kind"] == "level_feature")
        feature["catalogue_reference"] = ["not-a-string"]
        feature["class_name"] = ["not-a-string"]
        broken["inventory_gaps"].append(["not-an-object"])
        errors = validate_matrix(broken, self.catalogue)
        self.assertTrue(any("unbekannter Bereich" in e for e in errors))
        self.assertTrue(any("ungültiger Umsetzungsstatus" in e for e in errors))
        self.assertTrue(any("Katalogreferenz" in e for e in errors))
        self.assertTrue(any("Metadaten" in e for e in errors))
        self.assertTrue(any("Inventarlücke muss" in e for e in errors))

    def test_invalid_reference_catalogue_entries_report_errors(self):
        broken = copy.deepcopy(self.catalogue)
        broken["entries"] = [None, {"id": ["not-a-string"]}]
        errors = validate_matrix(self.matrix, broken)
        self.assertTrue(any("Katalogeintrag ohne gültige ID" in e for e in errors))
        broken["entries"] = {"unexpected": "object"}
        self.assertTrue(any("entries-Liste" in e
                            for e in validate_matrix(self.matrix, broken)))

    def test_malformed_entities_and_requirement_rows_report_errors(self):
        broken = copy.deepcopy(self.entities)
        broken["entries"][0]["name"] = ["not-a-string"]
        broken["entries"][0]["area"] = {"bogus": "area"}
        broken["entries"][0]["kind"] = ["spell_definition"]
        broken["entries"][0]["rule_implemented"] = ["tested"]
        matrix = copy.deepcopy(self.matrix)
        matrix["requirements"].append(None)
        errors = validate_entities(broken, matrix)
        self.assertTrue(any("Name fehlt" in e for e in errors))
        self.assertTrue(any("Kategorie" in e for e in errors))
        self.assertTrue(any("Implementierungsstatus" in e for e in errors))

    def test_nonobject_inventory_roots_are_rejected(self):
        self.assertTrue(validate_matrix([], self.catalogue))
        self.assertTrue(validate_matrix(self.matrix, []))
        self.assertTrue(validate_entities([], self.matrix))
        self.assertTrue(validate_entities(self.entities, []))

    def test_false_complete_flag_is_rejected(self):
        changed = copy.deepcopy(self.matrix)
        changed["scope_complete"] = True
        changed["global_percent_permitted"] = True
        errors = validate_matrix(changed, self.catalogue)
        self.assertTrue(any("trotz offener Inventurlücken" in e for e in errors))
        self.assertTrue(any("Inventar darf" in e for e in errors))


if __name__ == "__main__":
    unittest.main()
