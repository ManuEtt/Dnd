"""Verify retained heads of integration drafts after the all-branches merge."""
import json
import re
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "docs" / "parallel" / "POST_MERGE_SOURCE_ANCESTRY_20261031.json"


class PostMergeSourceAncestryTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))

    def test_fixed_manifest_and_parent_mapping(self):
        data = self.manifest
        self.assertEqual(data["schema_version"], 1)
        self.assertEqual(data["repository"], "ManuEtt/Dnd")
        self.assertEqual(data["merged_pr"], 440)
        self.assertRegex(data["main_before_link"], r"^[0-9a-f]{40}$")
        entries = data["source_prs"]
        self.assertEqual({entry["pr"] for entry in entries}, {438, 439, 441, 442, 443})
        self.assertEqual(len(entries), 5)
        self.assertEqual(len({entry["branch"] for entry in entries}), 5)
        self.assertEqual(len({entry["sha"] for entry in entries}), 5)
        self.assertEqual(
            set(data["direct_additional_parents"]),
            {entry["sha"] for entry in entries if entry["pr"] in {441, 442, 443}},
        )
        for entry in entries:
            self.assertRegex(entry["sha"], r"^[0-9a-f]{40}$")
            self.assertIn(entry["via_parent_pr"], {441, 442, 443})
            self.assertIn(
                entry["via_parent_pr"],
                {entry["pr"], 442},
            )
        self.assertEqual(
            set(data["provenance_files_from_439"]),
            {"docs/parallel/INTEGRATED_SOURCE_ANCESTRY_20261030.json",
             "scripts/tests/test_integrated_source_ancestry.py"},
        )

    def test_all_original_heads_are_ancestors_of_current_checkout(self):
        if not (ROOT / ".git").exists():
            self.skipTest("Source archive without Git history")
        shallow = subprocess.run(
            ["git", "rev-parse", "--is-shallow-repository"],
            cwd=ROOT, capture_output=True, text=True, check=False,
        )
        if shallow.returncode or shallow.stdout.strip() == "true":
            self.skipTest("Full Git history is needed for ancestry proof")
        for entry in self.manifest["source_prs"]:
            with self.subTest(pr=entry["pr"]):
                result = subprocess.run(
                    ["git", "merge-base", "--is-ancestor", entry["sha"], "HEAD"],
                    cwd=ROOT, capture_output=True, text=True, check=False,
                )
                self.assertEqual(
                    result.returncode, 0,
                    f"Original PR #{entry['pr']} is not an ancestor of HEAD: {result.stderr}",
                )


if __name__ == "__main__":
    unittest.main()
