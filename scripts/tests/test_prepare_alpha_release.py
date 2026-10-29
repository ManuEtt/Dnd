"""Unit tests for a strictly gated, versioned Android ARM64 release bundle."""

import importlib.util
import hashlib
from pathlib import Path
import tempfile
import stat
import unittest
from unittest import mock
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


    def test_oversized_apk_is_rejected_before_zip_probe(self):
        with self.apk.open('wb') as stream:
            stream.seek(release.MAX_ALPHA_APK_BYTES)
            stream.write(b'x')
        with mock.patch.object(zipfile, 'is_zipfile',
                               side_effect=AssertionError('ZIP probe before size guard')):
            with self.assertRaisesRegex(ValueError, 'zulässige Dateigröße'):
                release.prepare_release(self.root, self.out)
        self.assertFalse(self.out.exists())

    def test_highly_compressible_apk_member_is_rejected_before_crc(self):
        with zipfile.ZipFile(self.apk, 'a', compression=zipfile.ZIP_DEFLATED) as archive:
            archive.writestr('assets/compressed-bomb.bin', b'x' * (4 * 1024 * 1024))
        with mock.patch.object(zipfile.ZipFile, 'testzip',
                               side_effect=AssertionError('CRC decompression attempted')):
            with self.assertRaisesRegex(ValueError, 'stark komprimierte'):
                release.prepare_release(self.root, self.out)
        self.assertFalse(self.out.exists())

    def test_declared_apk_expansion_over_budget_is_rejected_before_crc(self):
        original_infolist = zipfile.ZipFile.infolist

        def oversized_members(archive):
            extra = zipfile.ZipInfo('assets/oversized.bin')
            extra.file_size = release.MAX_ALPHA_APK_UNCOMPRESSED_BYTES + 1
            extra.compress_size = extra.file_size
            return list(original_infolist(archive)) + [extra]

        with mock.patch.object(zipfile.ZipFile, 'infolist', oversized_members):
            with mock.patch.object(zipfile.ZipFile, 'testzip',
                                   side_effect=AssertionError('CRC decompression attempted')):
                with self.assertRaisesRegex(ValueError, 'übergroße'):
                    release.validate_arm64_apk(self.apk)

    def test_excessive_apk_member_count_is_rejected_before_crc(self):
        original_infolist = zipfile.ZipFile.infolist

        def too_many_members(archive):
            return list(original_infolist(archive)) + [
                zipfile.ZipInfo(f'assets/extra-{index}')
                for index in range(release.MAX_ALPHA_APK_ENTRIES)
            ]

        with mock.patch.object(zipfile.ZipFile, 'infolist', too_many_members):
            with mock.patch.object(zipfile.ZipFile, 'testzip',
                                   side_effect=AssertionError('CRC decompression attempted')):
                with self.assertRaisesRegex(ValueError, 'übergroße'):
                    release.validate_arm64_apk(self.apk)

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

    def test_dangling_symlinks_never_publish_or_write_outside_release(self):
        self.out.mkdir()
        stem = 'Wuerfelraunen_v0.5.4_24'
        for suffix in ('Source.zip', 'arm64.apk', 'ReleaseNotes.md',
                       'SHA256.txt', 'Source.zip.sha256'):
            with self.subTest(suffix=suffix):
                target = self.out / f'{stem}_{suffix}'
                destination = self.base / f'outside-{suffix}'
                target.symlink_to(destination)
                self.assertTrue(target.is_symlink())
                self.assertFalse(target.exists())
                with self.assertRaisesRegex(ValueError, 'bereits Release-Dateien'):
                    release.prepare_release(self.root, self.out)
                self.assertFalse(destination.exists())
                self.assertTrue(target.is_symlink())
                self.assertEqual([target], list(self.out.iterdir()))
                target.unlink()

    def test_existing_checksum_sidecar_is_preserved(self):
        self.out.mkdir()
        sidecar = self.out / 'Wuerfelraunen_v0.5.4_24_Source.zip.sha256'
        sidecar.write_bytes(b'previous verified checksum')
        with self.assertRaisesRegex(ValueError, 'bereits Release-Dateien'):
            release.prepare_release(self.root, self.out)
        self.assertEqual(sidecar.read_bytes(), b'previous verified checksum')
        self.assertEqual([sidecar], list(self.out.iterdir()))

    def test_concurrent_same_version_attempt_cannot_delete_owner_release(self):
        lock = self.out / '.Wuerfelraunen_v0.5.4_24_Release.lock'

        def competing_attempt(root, archive, *, layout):
            with self.assertRaisesRegex(ValueError, 'bereits in Bearbeitung'):
                release.prepare_release(root, self.out)
            self.assertTrue(lock.is_dir())
            return packaging.create_archive(root, archive, layout=layout)

        with mock.patch.object(release, 'create_archive', side_effect=competing_attempt):
            result = release.prepare_release(self.root, self.out)
        self.assertTrue(all(path.is_file() for path in result))
        self.assertFalse(lock.exists())

    def test_failed_release_releases_lock_and_allows_retry(self):
        lock = self.out / '.Wuerfelraunen_v0.5.4_24_Release.lock'
        with mock.patch.object(release, 'create_archive',
                               side_effect=RuntimeError('interrupted')):
            with self.assertRaisesRegex(RuntimeError, 'interrupted'):
                release.prepare_release(self.root, self.out)
        self.assertFalse(lock.exists())
        self.assertEqual(list(self.out.iterdir()), [])
        result = release.prepare_release(self.root, self.out)
        self.assertTrue(all(path.is_file() for path in result))

    def test_keyboard_interrupt_after_partial_apk_copy_removes_own_release(self):
        stem = 'Wuerfelraunen_v0.5.4_24'
        lock = self.out / f'.{stem}_Release.lock'

        def interrupt_during_copy(_source, target):
            Path(target).write_bytes(b'PARTIAL_APK')
            raise KeyboardInterrupt()

        with mock.patch.object(release.shutil, 'copy2', side_effect=interrupt_during_copy):
            with self.assertRaises(KeyboardInterrupt):
                release.prepare_release(self.root, self.out)
        self.assertFalse(lock.exists())
        self.assertEqual(list(self.out.iterdir()), [])
        result = release.prepare_release(self.root, self.out)
        self.assertTrue(all(path.is_file() for path in result))

    def test_system_exit_during_checksums_removes_own_release(self):
        stem = 'Wuerfelraunen_v0.5.4_24'
        lock = self.out / f'.{stem}_Release.lock'
        with mock.patch.object(release, 'sha256', side_effect=SystemExit(15)):
            with self.assertRaises(SystemExit) as error:
                release.prepare_release(self.root, self.out)
        self.assertEqual(error.exception.code, 15)
        self.assertFalse(lock.exists())
        self.assertEqual(list(self.out.iterdir()), [])
        result = release.prepare_release(self.root, self.out)
        self.assertTrue(all(path.is_file() for path in result))

    def test_stale_release_lock_fails_closed_without_deleting_it(self):
        self.out.mkdir()
        lock = self.out / '.Wuerfelraunen_v0.5.4_24_Release.lock'
        lock.mkdir()
        with self.assertRaisesRegex(ValueError, 'bereits in Bearbeitung'):
            release.prepare_release(self.root, self.out)
        self.assertEqual(list(self.out.iterdir()), [lock])
        self.assertTrue(lock.is_dir())

    def test_never_overwrite_a_verified_release(self):
        release.prepare_release(self.root, self.out)
        with self.assertRaisesRegex(ValueError, 'bereits Release-Dateien'):
            release.prepare_release(self.root, self.out)


if __name__ == '__main__':
    unittest.main()
