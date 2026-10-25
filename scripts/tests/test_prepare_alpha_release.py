"""Unit tests for a strictly gated, versioned Android ARM64 release bundle."""

import importlib.util
import hashlib
from pathlib import Path
import tempfile
import stat
import unittest
import zipfile

SCRIPTS = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location('package_project', SCRIPTS / 'package_project.py')
packaging = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(packaging)
import sys
sys.modules['package_project'] = packaging
RELEASE_SPEC = importlib.util.spec_from_file_location('prepare_alpha_release',
                                                     SCRIPTS / 'prepare_alpha_release.py')
release = importlib.util.module_from_spec(RELEASE_SPEC)
RELEASE_SPEC.loader.exec_module(release)


class AlphaReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.root = self.base / 'project'
        self.root.mkdir()
        for name in packaging.REQUIRED_FILES:
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('test file ' + name, encoding='utf-8')
        (self.root / 'app/pubspec.yaml').write_text('name: lebendiger_spielleiter\n'
                                                    'version: 0.5.4+24\n')
        self.apk = self.root / 'app/build/alpha/app-arm64-v8a-alpha.apk'
        self.apk.parent.mkdir(parents=True, exist_ok=True)
        self.create_apk()
        self.out = self.base / 'release'

    def create_apk(self, *, omit=()):
        with zipfile.ZipFile(self.apk, 'w') as archive:
            for path in release.REQUIRED_ARM64 - set(omit):
                archive.writestr(path, b'fixture bytes')

    def test_versioned_release_contains_source_apk_hashes_and_notes(self):
        result = release.prepare_release(self.root, self.out, commit='abcd1234',
                                         run_url='https://example.invalid/actions/42')
        self.assertEqual(len(result), 5)
        self.assertTrue(all(path.is_file() for path in result))
        names = [p.name for p in result]
        self.assertIn('Wuerfelraunen_v0.5.4_24_arm64.apk', names)
        self.assertIn('Wuerfelraunen_v0.5.4_24_Source.zip', names)
        archive = self.out / 'Wuerfelraunen_v0.5.4_24_Source.zip'
        with zipfile.ZipFile(archive) as z:
            self.assertIsNone(z.testzip())
            self.assertTrue(packaging.REQUIRED_FILES.issubset(set(z.namelist())))
            self.assertNotIn('app/build/alpha/app-arm64-v8a-alpha.apk', z.namelist())
        checksum_file = self.out / 'Wuerfelraunen_v0.5.4_24_SHA256.txt'
        checksums = checksum_file.read_text().splitlines()
        self.assertEqual(len(checksums), 3)
        for line in checksums:
            digest, filename = line.split('  ', 1)
            self.assertEqual(digest, hashlib.sha256((self.out / filename).read_bytes()).hexdigest())
        self.assertIn('Debug-Testschlüssel',
                      (self.out / 'Wuerfelraunen_v0.5.4_24_ReleaseNotes.md').read_text())

    def test_missing_apk_does_not_publish_artifacts(self):
        self.apk.unlink()
        with self.assertRaisesRegex(ValueError, 'Keine gebaute ARM64-APK'):
            release.prepare_release(self.root, self.out)
        self.assertFalse(self.out.exists())


    def test_duplicate_required_component_is_rejected(self):
        with zipfile.ZipFile(self.apk, 'a') as archive:
            with self.assertWarns(UserWarning):
                archive.writestr('lib/arm64-v8a/libapp.so', b'other bytes')
        with self.assertRaisesRegex(ValueError, 'doppelte ZIP-Einträge'):
            release.prepare_release(self.root, self.out)
        self.assertFalse(self.out.exists())

    def test_unsafe_apk_entry_paths_are_rejected(self):
        for unsafe in ('../escape', 'assets/../../private',
                       '/absolute', 'C:/drive', 'assets\\payload',
                       'assets/./dot'):
            with self.subTest(path=unsafe):
                self.create_apk()
                with zipfile.ZipFile(self.apk, 'a') as archive:
                    archive.writestr(unsafe, b'unsafe')
                with self.assertRaisesRegex(ValueError, 'unsichere ZIP-Pfade'):
                    release.prepare_release(self.root, self.out)
                self.assertFalse(self.out.exists())

    def test_apk_symlink_entry_is_rejected(self):
        link = zipfile.ZipInfo('assets/shortcut')
        link.create_system = 3
        link.external_attr = (stat.S_IFLNK | 0o777) << 16
        with zipfile.ZipFile(self.apk, 'a') as archive:
            archive.writestr(link, b'../../secrets')
        with self.assertRaisesRegex(ValueError, 'symbolische ZIP-Links'):
            release.prepare_release(self.root, self.out)
        self.assertFalse(self.out.exists())

    def test_normal_directory_entry_remains_accepted(self):
        with zipfile.ZipFile(self.apk, 'a') as archive:
            archive.writestr('assets/', b'')
        release.validate_arm64_apk(self.apk)

    def test_wrong_architecture_is_rejected(self):
        self.create_apk(omit={'lib/arm64-v8a/libapp.so'})
        with self.assertRaisesRegex(ValueError, 'nativen Komponenten'):
            release.prepare_release(self.root, self.out)
        self.assertFalse(self.out.exists())

    def test_corrupt_apk_is_rejected(self):
        self.apk.write_bytes(b'not an APK')
        with self.assertRaisesRegex(ValueError, 'kein gültiges ZIP'):
            release.prepare_release(self.root, self.out)

    def test_malformed_pubspec_version_is_rejected(self):
        (self.root / 'app/pubspec.yaml').write_text('version: invalid\n')
        with self.assertRaisesRegex(ValueError, 'X.Y.Z'):
            release.prepare_release(self.root, self.out)
        self.assertFalse(self.out.exists())

    def test_output_inside_project_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'außerhalb'):
            release.prepare_release(self.root, self.root / 'release')

    def test_never_overwrite_a_verified_release(self):
        release.prepare_release(self.root, self.out)
        with self.assertRaisesRegex(ValueError, 'bereits Release-Dateien'):
            release.prepare_release(self.root, self.out)


if __name__ == '__main__':
    unittest.main()
