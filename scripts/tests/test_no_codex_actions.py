"""Prevent reintroducing autonomous paid Codex jobs into repository Actions."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
WORKFLOWS = ROOT / '.github' / 'workflows'


class NoCodexActionsTests(unittest.TestCase):
    def test_codex_workflow_not_present(self):
        self.assertFalse((WORKFLOWS / 'autonomous-development.yml').exists())

    def test_android_quality_workflow_is_preserved(self):
        text = (WORKFLOWS / 'android-build.yml').read_text(encoding='utf-8')
        for stage in ('flutter analyze', 'flutter test', 'flutter build apk --debug', 'actions/upload-artifact@v4'):
            with self.subTest(stage=stage):
                self.assertIn(stage, text)

    def test_no_codex_invocations_in_actions(self):
        found = sorted(WORKFLOWS.glob('*.yml')) + sorted(WORKFLOWS.glob('*.yaml'))
        self.assertTrue(found, 'Android quality workflow must be present')
        for file in found:
            with self.subTest(workflow=file.name):
                content = file.read_text(encoding='utf-8').lower()
                self.assertNotIn('openai/codex-action', content)
                self.assertNotIn('enable_paid_codex', content)
                self.assertNotIn('codex', content)


if __name__ == '__main__':
    unittest.main()
