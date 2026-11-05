"""Keep the active, privileged branch-cleanup action on a supported runtime.

These checks cover the executable workflow, not archived examples or comments.
The separate ancestor/protection tests verify deletion safety gates.
"""
from pathlib import Path
import re
import unittest


WORKFLOW = (
    Path(__file__).resolve().parents[2]
    / ".github"
    / "workflows"
    / "cleanup-merged-safe-20261027.yml"
)

ACTION_USES = re.compile(
    r"^[ \t]*uses:[ \t]*actions/github-script@([^\s#]+)[ \t]*(?:#.*)?$",
    re.MULTILINE,
)


def github_script_versions(workflow: str) -> list[str]:
    """Return only actual github-script action step versions."""
    return ACTION_USES.findall(workflow)


class CleanupGithubScriptRuntimeTests(unittest.TestCase):
    def test_only_supported_node24_script_action_is_used(self):
        workflow = WORKFLOW.read_text(encoding="utf-8")
        self.assertEqual(github_script_versions(workflow), ["v8"])
        self.assertNotIn("ACTIONS_ALLOW_USE_UNSECURE_NODE_VERSION", workflow)

    def test_missing_legacy_or_second_script_step_is_rejected(self):
        workflow = WORKFLOW.read_text(encoding="utf-8")
        active_step = "uses: actions/github-script@v8"
        self.assertEqual(workflow.count(active_step), 1)
        mutations = (
            workflow.replace(active_step, "uses: actions/github-script@v7"),
            workflow.replace(active_step, "uses: actions/checkout@v4"),
            workflow.replace(
                active_step,
                active_step + "\n      - uses: actions/github-script@v7",
            ),
        )
        for mutated in mutations:
            with self.subTest(versions=github_script_versions(mutated)):
                self.assertNotEqual(github_script_versions(mutated), ["v8"])

    def test_documentation_comment_does_not_count_as_action(self):
        workflow = WORKFLOW.read_text(encoding="utf-8")
        commented = workflow + "\n# uses: actions/github-script@v7\n"
        self.assertEqual(github_script_versions(commented), ["v8"])


if __name__ == "__main__":
    unittest.main()
