"""Ensure the retired cleanup workflow cannot race with its successor.

The older Actions workflow hit a 404 after another cleanup had removed a
branch (Actions run 40589220593). Keep its historical path available as a
manual, read-only notice, with no branch/tag mutation API at all.
"""
from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]
WORKFLOWS = ROOT / ".github" / "workflows"
RETIRED = WORKFLOWS / "retire-verified-branches-20261026.yml"
ACTIVE = WORKFLOWS / "cleanup-merged-safe-20261027.yml"


def retired_workflow_is_inert(content: str) -> bool:
    """Fail closed if triggers, permissions, or mutation calls reappear."""
    if "\non:\n" not in content or "\npermissions:\n" not in content:
        return False
    events = content.split("\non:\n", 1)[1].split("\npermissions:\n", 1)[0]
    event_lines = [
        line.strip() for line in events.splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]
    if event_lines != ["workflow_dispatch:"]:
        return False
    permissions = content.split("\npermissions:\n", 1)[1].split("\njobs:\n", 1)[0]
    permission_lines = [
        line.strip() for line in permissions.splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    ]
    if permission_lines != ["contents: read"]:
        return False
    return not any(token in content for token in (
        "github.rest.git.deleteRef",
        "github.rest.git.createRef",
        "github.rest.git.updateRef",
        "github.rest.repos.delete",
        "github-script@",
    ))


class RetiredCleanupWorkflowTests(unittest.TestCase):
    def test_legacy_cleanup_is_read_only_and_manual_only(self):
        self.assertTrue(RETIRED.is_file())
        self.assertTrue(retired_workflow_is_inert(
            RETIRED.read_text(encoding="utf-8")
        ))

    def test_unsafe_trigger_and_branch_writes_are_rejected(self):
        original = RETIRED.read_text(encoding="utf-8")
        self.assertFalse(retired_workflow_is_inert(
            original.replace(
                "  workflow_dispatch:",
                "  workflow_run:\n    workflows: ['Android-Alpha bauen']",
            )
        ))
        self.assertFalse(retired_workflow_is_inert(
            original.replace("  contents: read", "  contents: write")
        ))
        self.assertFalse(retired_workflow_is_inert(
            original + "\n# github.rest.git.deleteRef must stay absent"
        ))

    def test_maintained_replacement_retains_archive_and_safety_checks(self):
        content = ACTIVE.read_text(encoding="utf-8")
        for fragment in (
            "workflow_run:",
            "branches: [main]",
            "merged_at",
            "protectedNames",
            "mainSha",
            "compareCommits",
            "getRef",
            "archive/merged-",
            "git.deleteRef",
        ):
            with self.subTest(fragment=fragment):
                self.assertIn(fragment, content)


if __name__ == "__main__":
    unittest.main()
