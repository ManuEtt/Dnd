"""Regression for malformed YAML metadata that blocks `flutter pub get`."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]


def description_is_safe_yaml_scalar(value: str) -> bool:
    """Validate the scalar form we use; flutter pub get remains the real parser test."""
    value = value.strip()
    if value.startswith('"'):
        return len(value) >= 2 and value.endswith('"') and '\"' not in value[1:-1]
    if value.startswith("'"):
        return len(value) >= 2 and value.endswith("'")
    return ': ' not in value and not value.startswith(('{', '[', '#'))


class PubspecMetadataTests(unittest.TestCase):
    def test_description_with_colon_must_be_quoted(self):
        text = (ROOT / 'app/pubspec.yaml').read_text(encoding='utf-8')
        match = re.search(r'^description:\s*(.+)$', text, re.MULTILINE)
        self.assertIsNotNone(match, 'pubspec description missing')
        self.assertTrue(description_is_safe_yaml_scalar(match.group(1)),
                        'app/pubspec.yaml: quote descriptions containing a colon and a space')

    def test_regression_unquoted_colon_is_rejected(self):
        self.assertFalse(description_is_safe_yaml_scalar('Würfelraunen: Fantasy-App'))
        self.assertTrue(description_is_safe_yaml_scalar('"Würfelraunen: Fantasy-App"'))

    def test_version_code_is_positive(self):
        text = (ROOT / 'app/pubspec.yaml').read_text(encoding='utf-8')
        match = re.search(r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$',
                          text, re.MULTILINE)
        self.assertIsNotNone(match, 'Flutter version must be X.Y.Z+build')
        self.assertGreater(int(match.group(4)), 0)


if __name__ == '__main__':
    unittest.main()
