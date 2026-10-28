"""Prevent PR301's historical cleanup from becoming a competing writer again.

The archived workflow is retained verbatim for migration provenance. Only its
read-only notice can remain executable; reference deletion belongs to the
maintained workflow after exact-current-main Android CI.
"""
import hashlib
import json
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]
RETIRED = ROOT / ".github/workflows/retire-verified-story-ui-branches-20261027.yml"
ARCHIVE = ROOT / (
    "docs/history/branch_migration_tooling_20261028/"
    "pr301-c190227--retire-verified-story-ui-branches-20261027.yml"
)
ACTIVE = ROOT / ".github/workflows/cleanup-merged-safe-20261027.yml"


def is_read_only_notice(text: str) -> bool:
    """Accept only the inert entrypoint, without interpreting JavaScript/YAML.

    This deliberately rejects a changed executable workflow for review rather
    than attempting to classify arbitrary actions as safe.
    """
    uncommented = "\n".join(
        line for line in text.splitlines()
        if line.strip() and not line.lstrip().startswith("#")
    )
    # Full-match the entire executable document: an extra job, inline run or
    # shell command substitution must not sneak past a dispatch-only header.
    # Echo text may not contain shell expansion, escaping or quote syntax.
    return re.fullmatch(
        r"name: [^\n]+\n"
        r"on:\n  workflow_dispatch:\n"
        r"permissions:\n  contents: read\n"
        r"jobs:\n  deprecated:\n    runs-on: ubuntu-latest\n"
        r"    steps:\n      - name: [^\n]+\n"
        r"        run: \|\n"
        r'(?:          echo "[^"$`\\\n]+"\n?)+',
        uncommented,
    ) is not None


class RetiredStoryUiCleanupTests(unittest.TestCase):
    def test_historical_entrypoint_is_dispatch_only_read_only_notice(self):
        self.assertTrue(is_read_only_notice(RETIRED.read_text(encoding="utf-8")))

    def test_original_pr301_writer_cannot_pass_as_inert(self):
        original = ARCHIVE.read_text(encoding="utf-8")
        self.assertIn("push:", original)
        self.assertIn("git.deleteRef", original)
        self.assertFalse(is_read_only_notice(original))

    def test_reintroduced_automatic_trigger_writer_or_action_is_rejected(self):
        notice = RETIRED.read_text(encoding="utf-8")
        replacements = (
            notice.replace("  workflow_dispatch:", "  push:\n  workflow_dispatch:"),
            notice.replace("contents: read", "contents: write"),
            notice.replace("        run: |", "        uses: actions/github-script@v7\n        run: |"),
            notice + "\n          await github.rest.git.deleteRef({ref: 'heads/old'});\n",
            notice.replace("Dieser historische PR301-Workflow ist deaktiviert.",
                           "$(gh api --method DELETE repos/owner/repo/git/refs/heads/old)"),
            notice.replace("    steps:\n", "    steps:\n      - run: gh api --method DELETE repos/owner/repo/git/refs/heads/old\n"),
        )
        for replacement in replacements:
            with self.subTest(workflow=replacement):
                self.assertFalse(is_read_only_notice(replacement))

    def test_original_source_is_preserved_and_checksum_verified(self):
        manifest = json.loads(ARCHIVE.with_suffix(".manifest.json").read_text())
        self.assertEqual("c190227882e0b96d31c036fe436640a36d4d0b47",
                         manifest["source_commit"])
        self.assertEqual(hashlib.sha256(ARCHIVE.read_bytes()).hexdigest(),
                         manifest["sha256"])

    def test_maintained_cleanup_still_waits_for_exact_green_main(self):
        workflow = ACTIVE.read_text(encoding="utf-8")
        for guard in (
            "workflow_run:", "workflows: ['Android-Alpha bauen']",
            "github.event.workflow_run.event == 'push'",
            "github.event.workflow_run.conclusion == 'success'",
            "context.payload.workflow_run.head_sha !== mainSha",
            "branch.protected || protectedNames.has(name)",
            "comparison.data.behind_by !== 0",
            "currentMain.data.object.sha !== mainSha",
            "currentBranch.data.object.sha !== sha",
        ):
            with self.subTest(guard=guard):
                self.assertIn(guard, workflow)


if __name__ == "__main__":
    unittest.main()
