"""Regression check for the audited, history-preserving integration of source PRs.

GitHub Actions checks out the full git history (fetch-depth: 0). After the
source ancestry commit, every reviewed original source PR head must remain an
ancestor of this commit. A source ZIP without .git can still validate the
manifest without depending on network access.
"""
import json
import re
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "docs" / "parallel" / "INTEGRATED_SOURCE_ANCESTRY_20261030.json"


class IntegratedSourceAncestryTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))

    def test_manifest_is_allowlisted_and_immutable(self):
        manifest = self.manifest
        self.assertEqual(manifest["schema_version"], 1)
        self.assertEqual(manifest["repository"], "ManuEtt/Dnd")
        self.assertEqual(manifest["integration_pr"], 435)
        self.assertEqual(
            set(record["pr"] for record in manifest["source_prs"]),
            {391, 401, 402, 406, 430, 433},
        )
        self.assertEqual(len(manifest["source_prs"]), 6)
        seen_branches = set()
        for record in manifest["source_prs"]:
            self.assertRegex(record["sha"], r"^[0-9a-f]{40}$")
            self.assertTrue(record["branch"].startswith("fix/chat-d/"))
            self.assertNotIn(record["branch"], seen_branches)
            seen_branches.add(record["branch"])

    def test_original_source_heads_are_git_ancestors(self):
        if not (ROOT / ".git").exists():
            self.skipTest("ZIP ohne Git-Historie; nur Manifest validierbar")
        commits = [
            self.manifest["integration_main_commit"],
            *(record["sha"] for record in self.manifest["source_prs"]),
        ]
        for sha in commits:
            with self.subTest(commit=sha):
                result = subprocess.run(
                    ["git", "merge-base", "--is-ancestor", sha, "HEAD"],
                    cwd=ROOT, capture_output=True, text=True, check=False,
                )
                self.assertEqual(
                    result.returncode, 0,
                    f"Quelle {sha} ist kein Git-Vorfahre von HEAD: {result.stderr}",
                )


if __name__ == "__main__":
    unittest.main()
