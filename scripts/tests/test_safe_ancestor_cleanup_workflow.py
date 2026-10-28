"""Guard the ancestor-only branch retirement workflow against unsafe triggers."""
from pathlib import Path
import unittest


WORKFLOW = (
    Path(__file__).resolve().parents[2]
    / ".github" / "workflows" / "cleanup-merged-safe-20261027.yml"
)


class SafeAncestorCleanupWorkflowTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")

    def test_requires_successful_current_main_ci(self):
        script = self.workflow
        self.assertIn("workflow_run:", script)
        self.assertIn("github.event.workflow_run.conclusion == 'success'", script)
        self.assertIn("github.event.workflow_run.event == 'push'", script)
        self.assertIn("context.payload.workflow_run.head_sha !== mainSha", script)
        self.assertNotIn("workflow_dispatch:", script)
        self.assertNotIn("  push:\n    branches:", script)

    def test_keep_active_heads_and_pr_bases(self):
        script = self.workflow
        self.assertIn("protectedNames.add(pr.base.ref)", script)
        self.assertIn("protectedNames.add(pr.head.ref)", script)
        self.assertIn("protectedNames.has(name)", script)
        self.assertIn("new Set(['main'])", script)

    def test_exact_ancestry_archive_and_ref_lease(self):
        script = self.workflow
        self.assertIn("compareCommits(", script)
        self.assertIn("base: sha, head: mainSha", script)
        self.assertIn("comparison.data.behind_by !== 0", script)
        self.assertIn("['ahead', 'identical']", script)
        self.assertIn("refs/' + archive, sha", script)
        self.assertIn("currentBranch.data.object.sha !== sha", script)
        self.assertIn("currentMain.data.object.sha !== mainSha", script)
        self.assertIn("github.rest.git.deleteRef", script)
        self.assertNotIn("const mergedPr", script)


if __name__ == "__main__":
    unittest.main()
