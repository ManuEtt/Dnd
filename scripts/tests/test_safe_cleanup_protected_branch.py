"""Guard the actively maintained branch cleanup against protected ref deletion.

Static checks deliberately anchor the executable guard inside the actual
branch loop, rather than accepting a comment or documentation mention.
"""
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github/workflows/cleanup-merged-safe-20261027.yml"

PROTECTED_GUARD = re.compile(
    r"if\s*\(\s*branch\.protected\s*\|\|\s*"
    r"protectedNames\.has\(name\)\s*\)\s*"
    r"\{\s*skipped\+\+;\s*continue;\s*\}"
)


def skips_protected_branch_before_processing(text: str) -> bool:
    branch_loop = "for (const branch of branches) {"
    sha_read = "const sha = branch.commit.sha;"
    if text.count(branch_loop) != 1:
        return False
    after_loop = text.split(branch_loop, 1)[1]
    if sha_read not in after_loop:
        return False
    initial_guard = after_loop.split(sha_read, 1)[0]
    # Prevent an explanatory comment from masquerading as active code.
    uncommented = "\n".join(
        line for line in initial_guard.splitlines()
        if not line.lstrip().startswith("//")
    )
    return PROTECTED_GUARD.search(uncommented) is not None


class SafeCleanupProtectedBranchTests(unittest.TestCase):
    def test_protected_branches_are_skipped_before_sha_or_delete(self):
        content = WORKFLOW.read_text(encoding="utf-8")
        self.assertTrue(skips_protected_branch_before_processing(content))

    def test_missing_guard_or_missing_skip_fails_closed(self):
        original = WORKFLOW.read_text(encoding="utf-8")
        for replacement in (
            "protectedNames.has(name)",
            "branch.protected",
            "false",
        ):
            with self.subTest(replacement=replacement):
                weakened = original.replace(
                    "branch.protected || protectedNames.has(name)",
                    replacement,
                )
                self.assertFalse(skips_protected_branch_before_processing(weakened))
        self.assertFalse(skips_protected_branch_before_processing(
            original.replace("skipped++;\n                continue;",
                             "skipped++;\n                core.info('warn only');", 1)
        ))

    def test_archival_and_merge_safety_gates_remain(self):
        content = WORKFLOW.read_text(encoding="utf-8")
        required = (
            "['ahead', 'identical']",
            "protectedNames.add(pr.base.ref)",
            "protectedNames.add(pr.head.ref)",
            "compareCommits",
            "behind_by !== 0",
            "archive/merged-",
            "git.createRef",
            "currentMain.data.object.sha !== mainSha",
            "currentBranch.data.object.sha !== sha",
            "git.deleteRef",
        )
        for item in required:
            with self.subTest(item=item):
                self.assertIn(item, content)


if __name__ == "__main__":
    unittest.main()
