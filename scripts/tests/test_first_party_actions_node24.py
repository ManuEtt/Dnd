"""Regression guard for every first-party GitHub Action runtime in active workflows."""
from collections import Counter
from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]
WORKFLOWS = ROOT / ".github" / "workflows"
USES = re.compile(
    r"^[ \t]*(?:-[ \t]*)?uses:[ \t]*actions/"
    r"(checkout|setup-java|setup-node|upload-artifact|download-artifact)"
    r"@(v[0-9]+)[ \t]*(?:#.*)?$",
    re.MULTILINE,
)
EXPECTED = {
    "android-build.yml": Counter({
        ("checkout", "v6"): 4,
        ("setup-java", "v6"): 2,
        ("setup-node", "v6"): 1,
        ("upload-artifact", "v6"): 5,
        ("download-artifact", "v7"): 1,
    }),
    "dart-format-reparieren.yml": Counter({
        ("checkout", "v6"): 1, ("upload-artifact", "v6"): 1,
    }),
    "chat-a-eldritch-regression.yml": Counter({("checkout", "v6"): 1}),
    "srd-monk-class-regression.yml": Counter({("checkout", "v6"): 1}),
    "cleanup-merged-safe-20261027.yml": Counter(),
}


def first_party_actions(source: str) -> Counter:
    return Counter(USES.findall(source))


class FirstPartyActionsNode24Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.sources = {
            file: (WORKFLOWS / file).read_text(encoding="utf-8")
            for file in EXPECTED
        }

    def test_every_active_workflow_uses_supported_runtime_majors(self):
        actual_names = {path.name for path in WORKFLOWS.glob("*.yml")}
        actual_names |= {path.name for path in WORKFLOWS.glob("*.yaml")}
        self.assertEqual(actual_names, set(EXPECTED))
        for file, expected in EXPECTED.items():
            with self.subTest(file=file):
                source = self.sources[file]
                self.assertEqual(first_party_actions(source), expected)
                self.assertNotIn("ACTIONS_ALLOW_USE_UNSECURE_NODE_VERSION", source)

    def test_runtime_downgrades_are_detected(self):
        for file, source in self.sources.items():
            for (action, version), count in EXPECTED[file].items():
                self.assertGreater(count, 0)
                original = "uses: actions/" + action + "@" + version
                with self.subTest(file=file, action=action):
                    self.assertIn(original, source)
                    downgraded = source.replace(
                        original, "uses: actions/" + action + "@v4", 1
                    )
                    self.assertNotEqual(
                        first_party_actions(downgraded), EXPECTED[file]
                    )

    def test_comments_do_not_count_as_action_steps(self):
        source = self.sources["dart-format-reparieren.yml"]
        commented = source + (
            "\n# - uses: actions/checkout@v4"
            "\n# uses: actions/upload-artifact@v4\n"
        )
        self.assertEqual(
            first_party_actions(commented),
            EXPECTED["dart-format-reparieren.yml"],
        )

    def test_manual_repair_remains_manual_and_regressions_are_preserved(self):
        manual = self.sources["dart-format-reparieren.yml"]
        self.assertIn("workflow_dispatch:", manual)
        self.assertIn("git diff --check", manual)
        self.assertIn("dart format lib test", manual)
        self.assertIn("git push origin", manual)
        self.assertIn("retention-days: 30", manual)
        for file in ("chat-a-eldritch-regression.yml", "srd-monk-class-regression.yml"):
            with self.subTest(file=file):
                source = self.sources[file]
                self.assertIn("pull_request:", source)
                self.assertIn("flutter test", source)
        cleanup = self.sources["cleanup-merged-safe-20261027.yml"]
        self.assertIn("uses: actions/github-script@v8", cleanup)
        self.assertIn("github.rest.git.deleteRef", cleanup)
        self.assertIn("github.rest.git.createRef", cleanup)


if __name__ == "__main__":
    unittest.main()
