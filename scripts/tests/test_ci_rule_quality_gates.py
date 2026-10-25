"""Guard the required architecture and SRD inventory gates in local and remote CI.

The checks are intentionally dependency-free and reject commented-out commands
or commands that only print the required check names.
"""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = ROOT / ".github" / "workflows" / "android-build.yml"
LOCAL_CHECK = ROOT / "scripts" / "check.sh"
GATES = (
    "python3 scripts/check_domain_boundaries.py",
    "python3 scripts/srd_coverage.py --json",
)


def has_active_gate(content: str, command: str) -> bool:
    """Recognize a direct shell invocation or single-line Actions run step."""
    return any(
        line.strip() in (command, f"run: {command}")
        for line in content.splitlines()
        if not line.lstrip().startswith("#")
    )


class CiRuleQualityGateTests(unittest.TestCase):
    def test_android_workflow_runs_both_gates(self):
        content = WORKFLOW.read_text(encoding="utf-8")
        for command in GATES:
            with self.subTest(command=command):
                self.assertTrue(has_active_gate(content, command))
                self.assertLess(
                    content.index(f"run: {command}"),
                    content.index("python3 -m unittest discover -s scripts/tests -v"),
                )

    def test_local_check_runs_both_gates(self):
        content = LOCAL_CHECK.read_text(encoding="utf-8")
        for command in GATES:
            with self.subTest(command=command):
                self.assertTrue(has_active_gate(content, command))
                self.assertLess(
                    content.index(command),
                    content.index("python3 -m unittest discover -s scripts/tests -v"),
                )

    def test_inactive_or_printed_commands_are_rejected(self):
        for command in GATES:
            with self.subTest(command=command):
                self.assertFalse(has_active_gate(f"# {command}", command))
                self.assertFalse(has_active_gate(f"run: echo {command}", command))
                self.assertFalse(has_active_gate(f"echo '{command}'", command))
                self.assertTrue(has_active_gate(f"run: {command}", command))
                self.assertTrue(has_active_gate(command, command))

    def test_different_or_strict_srd_commands_are_not_substitutes(self):
        command = GATES[1]
        self.assertFalse(
            has_active_gate(
                "run: python3 scripts/srd_coverage.py --require-complete-inventory",
                command,
            )
        )
        self.assertFalse(
            has_active_gate("run: python3 scripts/srd_coverage.py", command)
        )


if __name__ == "__main__":
    unittest.main()
