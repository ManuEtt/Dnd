"""Regression tests for SRD requirement inventory and honest progress reporting."""
import copy
import json
from pathlib import Path
import unittest

from scripts.srd_coverage import MATRIX, CATALOGUE, summary, validate_matrix


class SrdRequirementsMatrixTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.matrix = json.loads(MATRIX.read_text(encoding="utf-8"))
        cls.catalogue = json.loads(CATALOGUE.read_text(encoding="utf-8"))

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
        result = summary(self.matrix)
        self.assertFalse(result["scope_complete"])
        self.assertGreater(result["open_inventory_gaps"], 0)
        self.assertIsNone(result["global_srd_coverage_percent"])

    def test_duplicate_id_is_rejected(self):
        changed = copy.deepcopy(self.matrix)
        changed["requirements"].append(copy.deepcopy(changed["requirements"][0]))
        self.assertTrue(any("Doppelte Anforderungs-ID" in e for e in validate_matrix(changed, self.catalogue)))

    def test_unproved_test_claim_is_rejected(self):
        changed = copy.deepcopy(self.matrix)
        feature = next(r for r in changed["requirements"] if r["kind"] == "level_feature")
        feature["rule_implemented"] = "tested"
        self.assertTrue(any("voll getestet ohne konkrete Testreferenz" in e for e in validate_matrix(changed, self.catalogue)))

    def test_false_complete_flag_is_rejected(self):
        changed = copy.deepcopy(self.matrix)
        changed["scope_complete"] = True
        changed["global_percent_permitted"] = True
        errors = validate_matrix(changed, self.catalogue)
        self.assertTrue(any("trotz offener Inventurlücken" in e for e in errors))
        self.assertTrue(any("Inventar darf" in e for e in errors))


if __name__ == "__main__":
    unittest.main()
