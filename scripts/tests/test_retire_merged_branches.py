"""Security regression tests for the one-time cleanup allowlist."""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from retire_merged_branches import BRANCH_SNAPSHOT, MAINTENANCE_BRANCH, eligible


class BranchRetirementTests(unittest.TestCase):
    def test_snapshots_are_exact_and_never_main(self):
        self.assertEqual(len(BRANCH_SNAPSHOT), 12)
        self.assertNotIn("main", BRANCH_SNAPSHOT)
        self.assertTrue(all(len(commit) == 40 for commit in BRANCH_SNAPSHOT.values()))

    def test_eligible_only_when_unchanged_and_merged(self):
        name, sha = next(iter(BRANCH_SNAPSHOT.items()))
        self.assertTrue(
            eligible(name, actual_sha=sha, ahead_by=0, protected=False, is_merged=True)
        )
        for kwargs in (
            {"actual_sha": "0" * 40, "ahead_by": 0, "protected": False, "is_merged": True},
            {"actual_sha": sha, "ahead_by": 1, "protected": False, "is_merged": True},
            {"actual_sha": sha, "ahead_by": 0, "protected": True, "is_merged": True},
            {"actual_sha": sha, "ahead_by": 0, "protected": False, "is_merged": False},
        ):
            self.assertFalse(eligible(name, **kwargs))

    def test_dangerous_and_unlisted_branches_are_never_eligible(self):
        for name in ("main", "develop", "feature/new-work", "../main"):
            self.assertFalse(
                eligible(
                    name, actual_sha="a" * 40, ahead_by=0,
                    protected=False, is_merged=True,
                )
            )

    def test_new_maintenance_branch_only_if_merged(self):
        self.assertTrue(
            eligible(
                MAINTENANCE_BRANCH,
                actual_sha="a" * 40,
                ahead_by=0,
                protected=False,
                is_merged=True,
            )
        )


if __name__ == "__main__":
    unittest.main()
