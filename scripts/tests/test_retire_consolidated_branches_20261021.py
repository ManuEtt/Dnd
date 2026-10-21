"""Safety regression tests for the 2026-10-21 branch-retirement allowlist."""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from retire_consolidated_branches_20261021 import (
    SNAPSHOT, ALLOWED_EVOLUTION, STORY_ANCHORS, MAINTENANCE, eligible, covered
)


class ConsolidatedBranchRetirementTests(unittest.TestCase):
    def test_snapshot_is_closed_and_exact(self):
        self.assertEqual(len(SNAPSHOT), 7)
        self.assertNotIn("main", SNAPSHOT)
        self.assertNotIn(MAINTENANCE, SNAPSHOT)
        self.assertEqual({mode for _, mode in SNAPSHOT.values()}, {"ancestor", "covered"})
        self.assertTrue(all(len(sha) == 40 for sha, _ in SNAPSHOT.values()))
        self.assertEqual(len(STORY_ANCHORS), 7)

    def test_old_branch_files_cannot_disappear(self):
        self.assertTrue(covered({"old.dart": "a"}, {"old.dart": "a"}))
        self.assertFalse(covered({"old.dart": "a"}, {}))
        self.assertFalse(covered({"old.dart": "a"}, {"old.dart": "b"}))
        self.assertFalse(covered({}, {"old.dart": "a"}))

    def test_only_preapproved_modifications_allowed(self):
        path = "app/lib/story/fourteenth_voice_campaign.dart"
        self.assertIn(path, ALLOWED_EVOLUTION)
        self.assertTrue(covered({path: "old"}, {path: "later"}))
        self.assertFalse(covered({path: "old"}, {}))
        self.assertFalse(covered({"secret/file.dart": "old"}, {"secret/file.dart": "later"}))

    def test_git_ancestor_must_be_unchanged(self):
        name = "feature/srd-sphere-area-preview-20261021"
        sha, mode = SNAPSHOT[name]
        self.assertTrue(eligible(name, sha, False, mode, ahead_by=0))
        self.assertFalse(eligible(name, sha, False, mode, ahead_by=1))
        self.assertFalse(eligible(name, "0" * 40, False, mode, ahead_by=0))
        self.assertFalse(eligible(name, sha, True, mode, ahead_by=0))

    def test_squash_integrated_branch_requires_content_coverage(self):
        name = "integration/rabenwacht-story-current-main-20261021"
        sha, mode = SNAPSHOT[name]
        self.assertTrue(eligible(name, sha, False, mode, files_ok=True))
        self.assertFalse(eligible(name, sha, False, mode, files_ok=False))
        self.assertFalse(eligible(name, "0" * 40, False, mode, files_ok=True))
        self.assertFalse(eligible("main", sha, False, mode, files_ok=True))
        self.assertFalse(eligible("../main", sha, False, mode, files_ok=True))


if __name__ == "__main__":
    unittest.main()
