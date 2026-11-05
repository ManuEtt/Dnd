"""Protect the main Android CI pipeline against Node.js 20 action regressions.

This only checks first-party setup/artifact actions actually invoked by
android-build.yml. Flutter, JDK, Node toolchain and ABI requirements are
asserted separately, because action runtime != installed project runtime.
"""
from collections import Counter
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github" / "workflows" / "android-build.yml"
ACTION_USES = re.compile(
    r"^[ \t]*(?:-[ \t]*)?uses:[ \t]*actions/"
    r"(checkout|setup-java|setup-node|upload-artifact|download-artifact)"
    r"@(v[0-9]+)[ \t]*(?:#.*)?$",
    re.MULTILINE,
)
EXPECTED = Counter({
    ("checkout", "v6"): 4,
    ("setup-java", "v6"): 2,
    ("setup-node", "v6"): 1,
    ("upload-artifact", "v6"): 5,
    ("download-artifact", "v7"): 1,
})


def action_versions(workflow: str) -> Counter[tuple[str, str]]:
    """Collect real YAML action steps, excluding comments and prose."""
    return Counter(ACTION_USES.findall(workflow))


class AndroidActionsNode24Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.workflow = WORKFLOW.read_text(encoding="utf-8")

    def test_core_actions_run_on_supported_node24_majors(self):
        self.assertEqual(action_versions(self.workflow), EXPECTED)
        self.assertNotIn("ACTIONS_ALLOW_USE_UNSECURE_NODE_VERSION", self.workflow)
        self.assertIn("permissions:\n  contents: read", self.workflow)

    def test_regression_rejects_downgrade_missing_or_extra_step(self):
        for action, version in (
            ("checkout", "v6"),
            ("setup-java", "v6"),
            ("setup-node", "v6"),
            ("upload-artifact", "v6"),
            ("download-artifact", "v7"),
        ):
            original = f"uses: actions/{action}@{version}"
            self.assertIn(original, self.workflow)
            for replacement in (
                f"uses: actions/{action}@v4",
                "run: echo missing-action",
                original + f"\n      - uses: actions/{action}@v4",
            ):
                with self.subTest(action=action, replacement=replacement):
                    mutated = self.workflow.replace(original, replacement, 1)
                    self.assertNotEqual(action_versions(mutated), EXPECTED)

    def test_comment_is_not_counted_as_legacy_step(self):
        annotated = self.workflow + (
            "\n# - uses: actions/checkout@v4\n"
            "# uses: actions/upload-artifact@v4\n"
        )
        self.assertEqual(action_versions(annotated), EXPECTED)

    def test_explicit_toolchains_artifact_paths_and_three_abis_remain(self):
        unchanged = (
            "flutter-version: '3.35.7'",
            "java-version: '17'",
            "node-version: '22.14.0'",
            "cache-dependency-path: backend/package-lock.json",
            "fetch-depth: 0",
            "path: app/build/app/outputs/flutter-apk/app-debug.apk",
            "merge-multiple: true",
            "app-arm64-v8a-alpha.apk",
            "app-armeabi-v7a-alpha.apk",
            "app-x86_64-alpha.apk",
            "scripts/prepare_alpha_release.py",
            "scripts/create_checkpoint.py",
        )
        for token in unchanged:
            with self.subTest(token=token):
                self.assertIn(token, self.workflow)


if __name__ == "__main__":
    unittest.main()
