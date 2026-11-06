"""Unit tests for a strictly gated, versioned Android ARM64 release bundle."""

import contextlib
import importlib.util
import os
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

    @unittest.skipIf(sys.platform == 'win32', 'POSIX symlinks required')
    def test_symlinked_default_apk_is_rejected_before_release_publication(self):
        original = self.base / 'original-valid.apk'
        self.apk.rename(original)
        self.apk.symlink_to(original)
        with self.assertRaisesRegex(ValueError, 'symbolischen Pfadlinks'):
            release.prepare_release(self.root, self.out)
        self.assertFalse(self.out.exists())
        self.assertTrue(self.apk.is_symlink())
        self.assertTrue(original.is_file())

    @unittest.skipIf(sys.platform == 'win32', 'POSIX symlinks required')
    def test_explicit_apk_under_symlinked_parent_is_rejected(self):
        link = self.base / 'linked-build-dir'
        link.symlink_to(self.apk.parent, target_is_directory=True)
        alias = link / self.apk.name
        with self.assertRaisesRegex(ValueError, 'symbolischen Pfadlinks'):
            release.validate_arm64_apk(alias)
        with self.assertRaisesRegex(ValueError, 'symbolischen Pfadlinks'):
            release.prepare_release(self.root, self.out, apk=alias)
        self.assertFalse(self.out.exists())

    @unittest.skipIf(sys.platform == 'win32', 'POSIX symlinks required')
    def test_source_swapped_to_symlink_after_staging_cleans_own_release(self):
        original_create = release.create_archive
        outside = self.base / 'outside-valid.apk'
        original_bytes = self.apk.read_bytes()
        outside.write_bytes(original_bytes)

        def swap_after_archive(root, target, *, layout):
            result = original_create(root, target, layout=layout)
            self.apk.unlink()
            self.apk.symlink_to(outside)
            return result

        with mock.patch.object(
            release, 'create_archive', side_effect=swap_after_archive
        ):
            with self.assertRaisesRegex(ValueError, 'symbolischen Pfadlinks'):
                release.prepare_release(self.root, self.out)
        self.assertTrue(self.apk.is_symlink())
        self.assertEqual(outside.read_bytes(), original_bytes)
        self.assertEqual(list(self.out.iterdir()), [])

    @unittest.skipIf(sys.platform == 'win32', 'POSIX symlinks required')
    def test_source_link_swap_after_final_precheck_cannot_publish_external_apk(self):
        outside = self.base / 'outside-valid.apk'
        original_bytes = self.apk.read_bytes()
        outside.write_bytes(original_bytes)
        actual_copy = release.copy_validated_apk

        def swap_immediately_before_copy(source, target, expected):
            self.apk.unlink()
            self.apk.symlink_to(outside)
            return actual_copy(source, target, expected)

        with mock.patch.object(
            release, 'copy_validated_apk', side_effect=swap_immediately_before_copy,
        ):
            with self.assertRaisesRegex(ValueError, 'Pfadlink|Pfadlinks|ersetzt'):
                release.prepare_release(self.root, self.out)
        self.assertTrue(self.apk.is_symlink())
        self.assertEqual(outside.read_bytes(), original_bytes)
        self.assertEqual(list(self.out.iterdir()), [])

    def test_regular_apk_replacement_after_validation_cannot_be_published(self):
        replacement = self.base / 'replacement.apk'
        with zipfile.ZipFile(replacement, 'w') as archive:
            for path in release.REQUIRED_ARM64:
                archive.writestr(path, b'another valid APK content')
        actual_copy = release.copy_validated_apk
        previous = self.apk.read_bytes()

        def swap_immediately_before_copy(source, target, expected):
            self.apk.write_bytes(replacement.read_bytes())
            return actual_copy(source, target, expected)

        with mock.patch.object(
            release, 'copy_validated_apk', side_effect=swap_immediately_before_copy,
        ):
            with self.assertRaisesRegex(ValueError, 'Quelle.*verändert'):
                release.prepare_release(self.root, self.out)
        self.assertNotEqual(self.apk.read_bytes(), previous)
        self.assertEqual(list(self.out.iterdir()), [])

    @unittest.skipIf(sys.platform == 'win32', 'POSIX symlinks required')
    def test_parent_directory_link_swap_after_validation_is_rejected(self):
        actual_copy = release.copy_validated_apk
        source_bytes = self.apk.read_bytes()

        def replace_parent_before_copy(source, target, expected):
            moved = self.base / 'original-alpha'
            self.apk.parent.rename(moved)
            self.apk.parent.symlink_to(moved, target_is_directory=True)
            return actual_copy(source, target, expected)

        with mock.patch.object(
            release, 'copy_validated_apk', side_effect=replace_parent_before_copy,
        ):
            with self.assertRaisesRegex(ValueError, 'Pfadlink|Pfadlinks|ersetzt'):
                release.prepare_release(self.root, self.out)
        self.assertEqual((self.base / 'original-alpha' / self.apk.name).read_bytes(),
                         source_bytes)
        self.assertEqual(list(self.out.iterdir()), [])

    def test_explicit_regular_apk_remains_accepted(self):
        published = release.prepare_release(self.root, self.out, apk=self.apk)
        self.assertTrue(all(path.is_file() for path in published))

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

    def test_apk_rejects_trailing_space_or_dot_in_any_path_component_before_crc(self):
        # Windows-compatible tools may collapse these names onto existing
        # entries, even when the ZIP itself has unique literal names.
        unsafe = (
            'assets/map.json.',
            'assets/map.json ',
            'assets./map.json',
            'assets /map.json',
            'assets/room./scene.dat',
            'assets/room /scene.dat',
        )
        for name in unsafe:
            with self.subTest(path=name):
                self.create_apk()
                with zipfile.ZipFile(self.apk, 'a') as archive:
                    archive.writestr(name, b'unportable asset')
                with mock.patch.object(
                    zipfile.ZipFile, 'testzip',
                    side_effect=AssertionError('CRC reached before path validation'),
                ):
                    with self.assertRaisesRegex(ValueError, 'unsichere ZIP-Pfade'):
                        release.validate_arm64_apk(self.apk)

    def test_apk_allows_internal_spaces_and_dots_in_path_components(self):
        self.create_apk()
        with zipfile.ZipFile(self.apk, 'a') as archive:
            archive.writestr('assets/map.v2/alte karte.json', b'valid asset')
        release.validate_arm64_apk(self.apk)

    def test_unportable_apk_path_never_creates_release_files(self):
        with zipfile.ZipFile(self.apk, 'a') as archive:
            archive.writestr('assets/room./scene.json', b'unportable asset')
        with self.assertRaisesRegex(ValueError, 'unsichere ZIP-Pfade'):
            release.prepare_release(self.root, self.out)
        self.assertFalse(self.out.exists())

    def test_apk_rejects_windows_invalid_zip_characters_before_crc(self):
        # Windows-invalid characters are unsafe even without ZIP traversal
        # or collisions. Validate names before any expensive ZIP CRC work.
        for char in ('<', '>', ':', '"', '|', '?', '*'):
            for bad_name in (
                f'assets/scene{char}1.json',
                f'assets/folder{char}/scene.json',
                f'assets/folder{char}/',
            ):
                with self.subTest(name=bad_name):
                    self.create_apk()
                    with zipfile.ZipFile(self.apk, 'a') as archive:
                        archive.writestr(bad_name, b'unsafe member')
                    with mock.patch.object(
                        zipfile.ZipFile, 'testzip',
                        side_effect=AssertionError('CRC reached before path guard'),
                    ):
                        with self.assertRaisesRegex(ValueError, 'unsichere ZIP-Pfade'):
                            release.validate_arm64_apk(self.apk)

    def test_apk_accepts_safe_punctuation_and_unicode(self):
        self.create_apk()
        with zipfile.ZipFile(self.apk, 'a') as archive:
            archive.writestr('assets/Karte @2+Rätsel #7.json', b'valid')
        release.validate_arm64_apk(self.apk)

    def test_windows_invalid_apk_path_never_publishes_release(self):
        with zipfile.ZipFile(self.apk, 'a') as archive:
            archive.writestr('assets/scene?final.json', b'unsafe')
        with self.assertRaisesRegex(ValueError, 'unsichere ZIP-Pfade'):
            release.prepare_release(self.root, self.out)
        self.assertFalse(self.out.exists())

    def test_apk_rejects_windows_reserved_device_names_before_crc(self):
        # Windows treats these basenames as device names even when a ZIP
        # member has a normal extension or lives in a nested directory.
        reserved = (
            'CON', 'assets/con.txt', 'assets/PRN.json', 'assets/aux',
            'assets/NUL.bin', 'assets/COM1.dll', 'assets/com9.txt',
            'assets/LPT1.out', 'assets/lpt9.log', 'assets/CON.txt/sub.dat',
            'assets/NUL/',
        )
        for name in reserved:
            with self.subTest(name=name):
                self.create_apk()
                with zipfile.ZipFile(self.apk, 'a') as archive:
                    archive.writestr(name, b'unsafe member')
                with mock.patch.object(
                    zipfile.ZipFile, 'testzip',
                    side_effect=AssertionError('CRC reached before reserved-name guard'),
                ):
                    with self.assertRaisesRegex(ValueError, 'unsichere ZIP-Pfade'):
                        release.validate_arm64_apk(self.apk)

    def test_apk_accepts_ordinary_names_resembling_windows_devices(self):
        self.create_apk()
        with zipfile.ZipFile(self.apk, 'a') as archive:
            for name in (
                'assets/CONTEXT.txt', 'assets/COM10.txt',
                'assets/LPT0.txt', 'assets/PRN-archiv/datei.json',
            ):
                archive.writestr(name, b'valid member')
        release.validate_arm64_apk(self.apk)

    def test_apk_device_name_rejects_release_without_publishing(self):
        with zipfile.ZipFile(self.apk, 'a') as archive:
            archive.writestr('assets/NUL.dat', b'unsafe member')
        with self.assertRaisesRegex(ValueError, 'unsichere ZIP-Pfade'):
            release.prepare_release(self.root, self.out)
        self.assertFalse(self.out.exists())

    def test_apk_rejects_file_used_as_implicit_directory_before_crc(self):
        for reversed_order in (False, True):
            with self.subTest(reversed_order=reversed_order):
                self.create_apk()
                with zipfile.ZipFile(self.apk, 'a') as archive:
                    members = [('assets', b'file'),
                               ('assets/scene.json', b'child')]
                    if reversed_order:
                        members.reverse()
                    for name, data in members:
                        archive.writestr(name, data)
                with mock.patch.object(
                    zipfile.ZipFile, 'testzip',
                    side_effect=AssertionError('CRC reached before path type guard'),
                ):
                    with self.assertRaisesRegex(
                        ValueError, 'widersprüchliche Datei-/Verzeichnispfade'
                    ):
                        release.validate_arm64_apk(self.apk)

    def test_apk_rejects_file_and_explicit_directory_collision(self):
        for reversed_order in (False, True):
            with self.subTest(reversed_order=reversed_order):
                self.create_apk()
                with zipfile.ZipFile(self.apk, 'a') as archive:
                    members = [('assets', b'file'), ('assets/', b'')]
                    if reversed_order:
                        members.reverse()
                    for name, data in members:
                        archive.writestr(name, data)
                with mock.patch.object(
                    zipfile.ZipFile, 'testzip',
                    side_effect=AssertionError('CRC reached before collision guard'),
                ):
                    with self.assertRaisesRegex(
                        ValueError, 'widersprüchliche Datei-/Verzeichnispfade'
                    ):
                        release.validate_arm64_apk(self.apk)

    def test_apk_allows_explicit_directories_and_descendants(self):
        with zipfile.ZipFile(self.apk, 'a') as archive:
            archive.writestr('assets/', b'')
            archive.writestr('assets/maps/', b'')
            archive.writestr('assets/maps/scene.json', b'valid')
            archive.writestr('assets/readme.txt', b'valid')
        release.validate_arm64_apk(self.apk)

    def test_apk_file_directory_conflict_preserves_previous_release(self):
        previous = release.prepare_release(self.root, self.out)
        contents = {path.name: path.read_bytes() for path in previous}
        with zipfile.ZipFile(self.apk, 'a') as archive:
            archive.writestr('assets', b'file')
            archive.writestr('assets/map.json', b'child')
        with self.assertRaisesRegex(ValueError, 'widersprüchliche Datei-/Verzeichnispfade'):
            release.prepare_release(self.root, self.out)
        self.assertEqual(
            {path.name: path.read_bytes() for path in previous}, contents
        )
        self.assertEqual(set(self.out.iterdir()), set(previous))

    def test_casefold_apk_path_collisions_are_rejected_before_crc(self):
        for first, second in (
            ('assets/Map.png', 'assets/map.png'),
            ('assets/straße.txt', 'assets/strasse.txt'),
        ):
            with self.subTest(first=first, second=second):
                self.create_apk()
                with zipfile.ZipFile(self.apk, 'a') as archive:
                    archive.writestr(first, b'original')
                    archive.writestr(second, b'different')
                with mock.patch.object(
                    zipfile.ZipFile, 'testzip',
                    side_effect=AssertionError('CRC reached before collision guard'),
                ):
                    with self.assertRaisesRegex(ValueError, 'kollidierende ZIP-Pfade'):
                        release.validate_arm64_apk(self.apk)

    def test_unicode_equivalent_apk_names_are_rejected_before_crc(self):
        for first, second in (
            ('assets/café.txt', 'assets/cafe\u0301.txt'),
            ('assets/Résumé/entry.json', 'assets/Re\u0301sume\u0301/other.json'),
        ):
            with self.subTest(first=first, second=second):
                self.create_apk()
                with zipfile.ZipFile(self.apk, 'a') as archive:
                    archive.writestr(first, b'first')
                    archive.writestr(second, b'second')
                with mock.patch.object(
                    zipfile.ZipFile, 'testzip',
                    side_effect=AssertionError('CRC reached before collision guard'),
                ):
                    with self.assertRaisesRegex(ValueError, 'kollidierende ZIP-Pfade'):
                        release.validate_arm64_apk(self.apk)

    def test_casefold_collision_in_implicit_apk_directory_is_rejected(self):
        with zipfile.ZipFile(self.apk, 'a') as archive:
            archive.writestr('assets/Maps/first.json', b'first')
            archive.writestr('assets/maps/second.json', b'second')
        with mock.patch.object(
            zipfile.ZipFile, 'testzip',
            side_effect=AssertionError('CRC reached before directory guard'),
        ):
            with self.assertRaisesRegex(ValueError, 'kollidierende ZIP-Pfade'):
                release.validate_arm64_apk(self.apk)

    def test_distinct_international_apk_names_remain_valid(self):
        with zipfile.ZipFile(self.apk, 'a') as archive:
            for name in ('assets/Würfel.txt', 'assets/Wurfel.txt',
                         'assets/cafe\u0301.txt', 'assets/地图.txt',
                         'assets/Mapa/one.json', 'assets/Other/two.json'):
                archive.writestr(name, b'valid')
        release.validate_arm64_apk(self.apk)

    def test_apk_path_collision_keeps_previously_published_release(self):
        published = release.prepare_release(self.root, self.out)
        original = {path.name: path.read_bytes() for path in published}
        with zipfile.ZipFile(self.apk, 'a') as archive:
            archive.writestr('assets/Café/scene.txt', b'first')
            archive.writestr('assets/Cafe\u0301/other.txt', b'second')
        with self.assertRaisesRegex(ValueError, 'kollidierende ZIP-Pfade'):
            release.prepare_release(self.root, self.out)
        self.assertEqual(
            {path.name: path.read_bytes() for path in published}, original
        )
        self.assertEqual(set(self.out.iterdir()), set(published))

    def test_invisible_unicode_apk_entry_names_are_rejected_before_crc(self):
        # A ZIP can carry deceptive names even when its CRC is otherwise valid.
        # Reject C1 controls, format/bidi marks and line/paragraph separators
        # before decompression and before any release is published.
        for character in ('\u0085', '\u200b', '\u202e', '\u2066',
                          '\u2028', '\u2029'):
            with self.subTest(codepoint=ord(character)):
                self.create_apk()
                with zipfile.ZipFile(self.apk, 'a') as archive:
                    archive.writestr(f'assets/map{character}notes.txt', b'unsafe')
                with mock.patch.object(
                    zipfile.ZipFile, 'testzip',
                    side_effect=AssertionError('CRC checked before path validation'),
                ):
                    with self.assertRaisesRegex(ValueError, 'unsichere ZIP-Pfade'):
                        release.prepare_release(self.root, self.out)
                self.assertFalse(self.out.exists())

    def test_unicode_control_in_apk_directory_is_rejected(self):
        with zipfile.ZipFile(self.apk, 'a') as archive:
            archive.writestr('assets/map\u2028/scene.json', b'unsafe')
        with self.assertRaisesRegex(ValueError, 'unsichere ZIP-Pfade'):
            release.validate_arm64_apk(self.apk)

    def test_surrogate_apk_name_is_rejected_before_crc(self):
        # Python's ZIP writer cannot encode an isolated surrogate to UTF-8.
        # Inject a malformed ZipInfo at the metadata boundary instead.
        original_infolist = zipfile.ZipFile.infolist

        def invalid_entry(archive):
            return list(original_infolist(archive)) + [
                zipfile.ZipInfo('assets/name\ud800.txt'),
            ]

        with mock.patch.object(zipfile.ZipFile, 'infolist', invalid_entry):
            with mock.patch.object(
                zipfile.ZipFile, 'testzip',
                side_effect=AssertionError('CRC checked before path validation'),
            ):
                with self.assertRaisesRegex(ValueError, 'unsichere ZIP-Pfade'):
                    release.validate_arm64_apk(self.apk)

    def test_visible_unicode_apk_assets_remain_valid(self):
        for name in ('assets/Würfel.txt', 'assets/cafe\u0301.txt',
                     'assets/Karte🗺️.txt', 'assets/世界.txt'):
            with zipfile.ZipFile(self.apk, 'a') as archive:
                archive.writestr(name, b'valid')
        release.validate_arm64_apk(self.apk)

    def test_invalid_unicode_apk_does_not_damage_previous_release(self):
        published = release.prepare_release(self.root, self.out)
        originals = {file.name: file.read_bytes() for file in published}
        with zipfile.ZipFile(self.apk, 'a') as archive:
            archive.writestr('assets/scene\u2029notes.json', b'unsafe')
        with self.assertRaisesRegex(ValueError, 'unsichere ZIP-Pfade'):
            release.prepare_release(self.root, self.out)
        self.assertEqual(
            {file.name: file.read_bytes() for file in published},
            originals,
        )
        self.assertEqual(
            set(self.out.iterdir()), set(published),
        )

    def test_apk_symlink_entry_is_rejected(self):
        link = zipfile.ZipInfo('assets/shortcut')
        link.create_system = 3
        link.external_attr = (stat.S_IFLNK | 0o777) << 16
        with zipfile.ZipFile(self.apk, 'a') as archive:
            archive.writestr(link, b'../../secrets')
        with self.assertRaisesRegex(ValueError, 'symbolische ZIP-Links'):
            release.prepare_release(self.root, self.out)
        self.assertFalse(self.out.exists())

    def test_unix_special_file_entries_are_rejected(self):
        for kind in (stat.S_IFIFO, stat.S_IFCHR, stat.S_IFBLK, stat.S_IFSOCK):
            with self.subTest(kind=kind):
                self.create_apk()
                special = zipfile.ZipInfo('assets/unsupported')
                special.create_system = 3
                special.external_attr = (kind | 0o644) << 16
                with zipfile.ZipFile(self.apk, 'a') as archive:
                    archive.writestr(special, b'not a regular asset')
                with self.assertRaisesRegex(ValueError, 'unzulässige ZIP-Dateitypen'):
                    release.validate_arm64_apk(self.apk)

    def test_required_native_library_cannot_be_disguised_as_directory(self):
        self.create_apk(omit={'lib/arm64-v8a/libapp.so'})
        disguised = zipfile.ZipInfo('lib/arm64-v8a/libapp.so')
        disguised.create_system = 3
        disguised.external_attr = (stat.S_IFDIR | 0o755) << 16
        with zipfile.ZipFile(self.apk, 'a') as archive:
            archive.writestr(disguised, b'fake library')
        with self.assertRaisesRegex(ValueError, 'widersprüchliche ZIP-Dateitypen'):
            release.validate_arm64_apk(self.apk)

    def test_unix_regular_file_and_directory_modes_are_allowed(self):
        regular = zipfile.ZipInfo('assets/valid.dat')
        regular.create_system = 3
        regular.external_attr = (stat.S_IFREG | 0o644) << 16
        directory = zipfile.ZipInfo('assets/new-dir/')
        directory.create_system = 3
        directory.external_attr = (stat.S_IFDIR | 0o755) << 16
        with zipfile.ZipFile(self.apk, 'a') as archive:
            archive.writestr(regular, b'normal asset')
            archive.writestr(directory, b'')
        release.validate_arm64_apk(self.apk)

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

        def interrupt_during_copy(_source, target, *, length=None):
            target.write(b'PARTIAL_APK')
            raise KeyboardInterrupt()

        # Publication now uses a pinned source descriptor and copyfileobj,
        # not shutil.copy2(path, path). Interrupt the actual copy boundary.
        with mock.patch.object(
            release.shutil, 'copyfileobj', side_effect=interrupt_during_copy,
        ):
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


    @unittest.skipIf(sys.platform == 'win32', 'POSIX symlinks required')
    def test_late_apk_symlink_does_not_overwrite_external_file(self):
        # A competing writer inserts a target link after the version check.
        outside = self.base / 'external-apk'
        outside.write_bytes(b'untouched external APK')
        target = self.out / 'Wuerfelraunen_v0.5.4_24_arm64.apk'
        actual_archive = release.create_archive

        def create_then_insert_link(root, destination, *, layout):
            result = actual_archive(root, destination, layout=layout)
            target.symlink_to(outside)
            return result

        with mock.patch.object(release, 'create_archive',
                               side_effect=create_then_insert_link):
            with self.assertRaisesRegex(ValueError, 'Release-Zieldatei'):
                release.prepare_release(self.root, self.out)
        self.assertEqual(outside.read_bytes(), b'untouched external APK')
        self.assertTrue(target.is_symlink())
        self.assertEqual(set(self.out.iterdir()), {target})

    def test_late_notes_regular_file_is_not_overwritten_or_deleted(self):
        # Even a normal (non-symlink) collision must be left untouched.
        notes = self.out / 'Wuerfelraunen_v0.5.4_24_ReleaseNotes.md'
        actual_copy = release.copy_validated_apk

        def copy_then_insert_file(source, target, expected):
            identity = actual_copy(source, target, expected)
            notes.write_bytes(b'other writer notes')
            return identity

        with mock.patch.object(release, 'copy_validated_apk',
                               side_effect=copy_then_insert_file):
            with self.assertRaisesRegex(ValueError, 'Release-Zieldatei'):
                release.prepare_release(self.root, self.out)
        self.assertEqual(notes.read_bytes(), b'other writer notes')
        self.assertEqual(set(self.out.iterdir()), {notes})

    @unittest.skipIf(sys.platform == 'win32', 'POSIX symlinks required')
    def test_late_checksum_symlink_cannot_modify_external_file(self):
        sums = self.out / 'Wuerfelraunen_v0.5.4_24_SHA256.txt'
        outside = self.base / 'external-hashes'
        outside.write_bytes(b'untouched hashes')
        # The checksum file is opened before SHA256 calculation. Inject the
        # collision at the actual exclusive-open boundary, not during hashing.
        actual_writer = release._new_release_file

        def insert_before_open(path, *, binary=False):
            if path == sums:
                sums.symlink_to(outside)
            return actual_writer(path, binary=binary)

        with mock.patch.object(release, '_new_release_file',
                               side_effect=insert_before_open):
            with self.assertRaisesRegex(ValueError, 'Release-Zieldatei'):
                release.prepare_release(self.root, self.out)
        self.assertEqual(outside.read_bytes(), b'untouched hashes')
        self.assertTrue(sums.is_symlink())
        self.assertEqual(set(self.out.iterdir()), {sums})


    def test_apk_replaced_after_copy_before_file_close_is_not_published(self):
        target = self.out / 'Wuerfelraunen_v0.5.4_24_arm64.apk'
        replacement = self.base / 'foreign-target.apk'
        replacement.write_bytes(b'other writer APK')
        actual_copy = release.shutil.copyfileobj

        def copy_then_replace(source, output, *, length=None):
            actual_copy(source, output, length=length)
            os.replace(replacement, target)

        with mock.patch.object(release.shutil, 'copyfileobj',
                               side_effect=copy_then_replace):
            with self.assertRaisesRegex(ValueError, 'Release-Zieldatei.*ersetzt'):
                release.prepare_release(self.root, self.out)
        self.assertEqual(target.read_bytes(), b'other writer APK')
        self.assertEqual(set(self.out.iterdir()), {target})

    def test_notes_replaced_after_open_are_not_deleted_on_failure(self):
        target = self.out / 'Wuerfelraunen_v0.5.4_24_ReleaseNotes.md'
        replacement = self.base / 'foreign-notes.md'
        replacement.write_bytes(b'other writer notes')
        original_writer = release._new_release_file

        @contextlib.contextmanager
        def swap_after_note_write(path, *, binary=False):
            with original_writer(path, binary=binary) as stream:
                yield stream
                if path == target:
                    os.replace(replacement, target)

        with mock.patch.object(release, '_new_release_file',
                               side_effect=swap_after_note_write):
            with self.assertRaisesRegex(ValueError, 'Release-Zieldatei.*ersetzt'):
                release.prepare_release(self.root, self.out)
        self.assertEqual(target.read_bytes(), b'other writer notes')
        self.assertEqual(set(self.out.iterdir()), {target})

    @unittest.skipIf(sys.platform == 'win32', 'POSIX symlinks required')
    def test_checksum_replaced_by_symlink_after_open_keeps_target(self):
        target = self.out / 'Wuerfelraunen_v0.5.4_24_SHA256.txt'
        outside = self.base / 'external-checksums.txt'
        outside.write_bytes(b'untouched external hashes')
        original_writer = release._new_release_file

        @contextlib.contextmanager
        def link_after_checksum_write(path, *, binary=False):
            with original_writer(path, binary=binary) as stream:
                yield stream
                if path == target:
                    target.unlink()
                    target.symlink_to(outside)

        with mock.patch.object(release, '_new_release_file',
                               side_effect=link_after_checksum_write):
            with self.assertRaisesRegex(ValueError, 'Release-Zieldatei.*ersetzt'):
                release.prepare_release(self.root, self.out)
        self.assertEqual(outside.read_bytes(), b'untouched external hashes')
        self.assertTrue(target.is_symlink())
        self.assertEqual(set(self.out.iterdir()), {target})

    def test_valid_apk_swapped_after_release_validation_is_not_published(self):
        target = self.out / 'Wuerfelraunen_v0.5.4_24_arm64.apk'
        replacement = self.base / 'foreign-validated.apk'
        with zipfile.ZipFile(replacement, 'w') as archive:
            for name in release.REQUIRED_ARM64:
                archive.writestr(name, b'other valid APK bytes')
        expected = replacement.read_bytes()
        actual_validate = release.validate_arm64_apk

        def validate_then_replace(path):
            actual_validate(path)
            if path == target:
                os.replace(replacement, target)

        with mock.patch.object(release, 'validate_arm64_apk',
                               side_effect=validate_then_replace):
            with self.assertRaisesRegex(ValueError, 'Release-Zieldatei.*ersetzt'):
                release.prepare_release(self.root, self.out)
        self.assertEqual(target.read_bytes(), expected)
        self.assertEqual(set(self.out.iterdir()), {target})


    def test_final_hashes_match_source_apk_and_both_manifests(self):
        published = release.prepare_release(self.root, self.out)
        self.assertEqual(len(published), 5)
        source, target_apk, notes, sums, sidecar = published
        self.assertEqual(target_apk.read_bytes(), self.apk.read_bytes())
        self.assertEqual(
            sidecar.read_text(encoding='utf-8'),
            f'{release.sha256(source)}  {source.name}\n',
        )
        self.assertEqual(
            sums.read_text(encoding='utf-8'),
            ''.join(f'{release.sha256(path)}  {path.name}\n'
                    for path in (source, target_apk, notes)),
        )

    def test_same_inode_valid_apk_mutation_after_hash_is_rejected(self):
        target = self.out / 'Wuerfelraunen_v0.5.4_24_arm64.apk'
        actual_validate = release.validate_arm64_apk

        def mutate_on_final_validation(path):
            if path == target:
                # Rewrite the same inode as another CRC-valid native APK.
                with zipfile.ZipFile(target, 'w') as archive:
                    for name in release.REQUIRED_ARM64:
                        archive.writestr(name, b'new valid content')
                    archive.writestr('assets/extra.txt', b'in-place tampering')
            return actual_validate(path)

        with mock.patch.object(release, 'validate_arm64_apk',
                               side_effect=mutate_on_final_validation):
            with self.assertRaisesRegex(ValueError, 'nach der Prüfsumme'):
                release.prepare_release(self.root, self.out)
        self.assertEqual(list(self.out.iterdir()), [])

    def test_same_inode_valid_source_zip_mutation_is_rejected(self):
        source = self.out / 'Wuerfelraunen_v0.5.4_24_Source.zip'
        target = self.out / 'Wuerfelraunen_v0.5.4_24_arm64.apk'
        actual_validate = release.validate_arm64_apk

        def mutate_source_on_final_validation(path):
            if path == target:
                with zipfile.ZipFile(source, 'a') as archive:
                    archive.writestr('docs/late-added.txt', b'changed source bundle')
            return actual_validate(path)

        with mock.patch.object(release, 'validate_arm64_apk',
                               side_effect=mutate_source_on_final_validation):
            with self.assertRaisesRegex(ValueError, 'nach der Prüfsumme'):
                release.prepare_release(self.root, self.out)
        self.assertEqual(list(self.out.iterdir()), [])

    def test_inplace_notes_mutation_after_hash_is_rejected(self):
        target = self.out / 'Wuerfelraunen_v0.5.4_24_arm64.apk'
        notes = self.out / 'Wuerfelraunen_v0.5.4_24_ReleaseNotes.md'
        actual_validate = release.validate_arm64_apk

        def mutate_notes_on_final_validation(path):
            if path == target:
                notes.write_text('unapproved notes', encoding='utf-8')
            return actual_validate(path)

        with mock.patch.object(release, 'validate_arm64_apk',
                               side_effect=mutate_notes_on_final_validation):
            with self.assertRaisesRegex(ValueError, 'nach der Prüfsumme'):
                release.prepare_release(self.root, self.out)
        self.assertEqual(list(self.out.iterdir()), [])

    def test_checksum_manifest_mutation_after_write_is_rejected(self):
        target = self.out / 'Wuerfelraunen_v0.5.4_24_arm64.apk'
        sums = self.out / 'Wuerfelraunen_v0.5.4_24_SHA256.txt'
        actual_validate = release.validate_arm64_apk

        def mutate_sums_on_final_validation(path):
            if path == target:
                sums.write_text('wrong SHA256 records', encoding='utf-8')
            return actual_validate(path)

        with mock.patch.object(release, 'validate_arm64_apk',
                               side_effect=mutate_sums_on_final_validation):
            with self.assertRaisesRegex(ValueError, 'Prüfsummen wurden verändert'):
                release.prepare_release(self.root, self.out)
        self.assertEqual(list(self.out.iterdir()), [])

    def test_source_sidecar_mutation_after_write_is_rejected(self):
        target = self.out / 'Wuerfelraunen_v0.5.4_24_arm64.apk'
        sidecar = self.out / 'Wuerfelraunen_v0.5.4_24_Source.zip.sha256'
        actual_validate = release.validate_arm64_apk

        def mutate_sidecar_on_final_validation(path):
            if path == target:
                sidecar.write_text('wrong source checksum', encoding='utf-8')
            return actual_validate(path)

        with mock.patch.object(release, 'validate_arm64_apk',
                               side_effect=mutate_sidecar_on_final_validation):
            with self.assertRaisesRegex(ValueError, 'Prüfsummen wurden verändert'):
                release.prepare_release(self.root, self.out)
        self.assertEqual(list(self.out.iterdir()), [])


    def test_source_archive_pair_published_without_staging_leftovers(self):
        published = release.prepare_release(self.root, self.out)
        self.assertEqual(set(self.out.iterdir()), set(published))
        source = self.out / 'Wuerfelraunen_v0.5.4_24_Source.zip'
        sidecar = source.with_suffix('.zip.sha256')
        self.assertEqual(
            sidecar.read_text(encoding='utf-8'),
            f'{release.sha256(source)}  {source.name}\n',
        )
        with zipfile.ZipFile(source) as archive:
            self.assertIsNone(archive.testzip())

    def test_late_source_archive_regular_file_survives_staged_publication(self):
        source = self.out / 'Wuerfelraunen_v0.5.4_24_Source.zip'
        actual_archive = release.create_archive

        def stage_then_insert_file(root, destination, *, layout):
            result = actual_archive(root, destination, layout=layout)
            source.write_bytes(b'foreign source archive')
            return result

        with mock.patch.object(release, 'create_archive',
                               side_effect=stage_then_insert_file):
            with self.assertRaisesRegex(ValueError, 'Release-Zieldatei'):
                release.prepare_release(self.root, self.out)
        self.assertEqual(source.read_bytes(), b'foreign source archive')
        self.assertEqual(set(self.out.iterdir()), {source})

    @unittest.skipIf(sys.platform == 'win32', 'POSIX symlinks required')
    def test_late_source_archive_symlink_keeps_external_file(self):
        source = self.out / 'Wuerfelraunen_v0.5.4_24_Source.zip'
        outside = self.base / 'outside-source.zip'
        outside.write_bytes(b'keep external archive')
        actual_archive = release.create_archive

        def stage_then_insert_link(root, destination, *, layout):
            result = actual_archive(root, destination, layout=layout)
            source.symlink_to(outside)
            return result

        with mock.patch.object(release, 'create_archive',
                               side_effect=stage_then_insert_link):
            with self.assertRaisesRegex(ValueError, 'Release-Zieldatei'):
                release.prepare_release(self.root, self.out)
        self.assertTrue(source.is_symlink())
        self.assertEqual(outside.read_bytes(), b'keep external archive')
        self.assertEqual(set(self.out.iterdir()), {source})

    def test_late_source_sidecar_collision_rolls_back_only_own_zip(self):
        source = self.out / 'Wuerfelraunen_v0.5.4_24_Source.zip'
        sidecar = source.with_suffix('.zip.sha256')
        actual_link = release.os.link

        def link_then_insert_foreign_sidecar(staged, published):
            actual_link(staged, published)
            if published == source:
                sidecar.write_bytes(b'foreign SHA256 sidecar')

        with mock.patch.object(release.os, 'link',
                               side_effect=link_then_insert_foreign_sidecar):
            with self.assertRaisesRegex(ValueError, 'Release-Zieldatei'):
                release.prepare_release(self.root, self.out)
        self.assertEqual(sidecar.read_bytes(), b'foreign SHA256 sidecar')
        self.assertEqual(set(self.out.iterdir()), {sidecar})

    def test_source_replaced_after_exclusive_link_keeps_foreign_replacement(self):
        source = self.out / 'Wuerfelraunen_v0.5.4_24_Source.zip'
        replacement = self.base / 'replacement-source.zip'
        replacement.write_bytes(b'other writer after public link')
        actual_link = release.os.link

        def link_then_replace_source(staged, published):
            actual_link(staged, published)
            if published == source:
                release.os.replace(replacement, source)

        with mock.patch.object(release.os, 'link',
                               side_effect=link_then_replace_source):
            with self.assertRaisesRegex(ValueError, 'Release-Zieldatei.*ersetzt'):
                release.prepare_release(self.root, self.out)
        self.assertEqual(source.read_bytes(), b'other writer after public link')
        self.assertEqual(set(self.out.iterdir()), {source})


if __name__ == '__main__':
    unittest.main()
