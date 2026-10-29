import importlib.util
from pathlib import Path
import os
import tempfile
import stat
import unittest
from unittest import mock
import zipfile


SPEC = importlib.util.spec_from_file_location(
    'package_project', Path(__file__).resolve().parents[1] / 'package_project.py',
)
packaging = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(packaging)


class ProjectArchiveTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.root = self.base / 'project'
        self.root.mkdir()
        for name in packaging.REQUIRED_FILES:
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('fixture: ' + name, encoding='utf-8')

    def test_root_and_folder_archives_preserve_same_source_without_double_nesting(self):
        for layout, prefix in [('root', ''), ('folder', 'Dnd/')]:
            output = self.base / f'{layout}.zip'
            count, digest = packaging.create_archive(self.root, output, layout=layout)
            with zipfile.ZipFile(output) as archive:
                self.assertEqual(set(archive.namelist()),
                                 {prefix + n for n in packaging.REQUIRED_FILES})
                for name in packaging.REQUIRED_FILES:
                    self.assertEqual(archive.read(prefix + name),
                                     (self.root / name).read_bytes())
                self.assertIsNone(archive.testzip())
            self.assertEqual(count, len(packaging.REQUIRED_FILES))
            self.assertEqual(output.with_suffix('.zip.sha256').read_text(),
                             f'{digest}  {output.name}\n')

    def test_arescan_is_only_a_compatibility_test_fixture(self):
        root = Path(__file__).resolve().parents[2]
        self.assertFalse((root / 'app/assets/arescan.json').exists())
        self.assertTrue((root / 'app/test/fixtures/arescan_legacy.json').is_file())
        runtime_ui = (root / 'app/lib/ui/app.dart').read_text(encoding='utf-8')
        engine = (root / 'app/lib/domain/game_engine.dart').read_text(encoding='utf-8')
        self.assertNotIn('Arescan-Spielstand laden', runtime_ui)
        self.assertNotIn('createArescan(', engine)
        self.assertNotIn('_arescan(', engine)

    def test_secrets_personal_saves_and_build_outputs_never_enter_archive(self):
        for name in ['.env', 'backend/.env.production', 'save.db', 'save.db-wal',
                     'signing.keystore', 'app/build/app-debug.apk',
                     'app/android/local.properties', 'node_modules/private.txt',
                     '__pycache__/secret.pyc']:
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('private fixture')
        (self.root / 'backend/.env.example').write_text('EXAMPLE=')
        output = self.base / 'safe.zip'
        packaging.create_archive(self.root, output, layout='root')
        with zipfile.ZipFile(output) as archive:
            self.assertEqual(set(archive.namelist()),
                             packaging.REQUIRED_FILES | {'backend/.env.example'})

    @unittest.skipUnless(os.name == 'posix', 'POSIX symlinks required')
    def test_existing_output_symlink_never_overwrites_external_target(self):
        external = self.base / 'private-existing.txt'
        external.write_bytes(b'personal original content')
        output = self.base / 'export.zip'
        output.symlink_to(external)
        with self.assertRaisesRegex(ValueError, 'symlinks'):
            packaging.create_archive(self.root, output, layout='root')
        self.assertTrue(output.is_symlink())
        self.assertEqual(external.read_bytes(), b'personal original content')
        self.assertFalse(output.with_suffix('.zip.sha256').exists())

    @unittest.skipUnless(os.name == 'posix', 'POSIX symlinks required')
    def test_dangling_output_symlink_does_not_create_target(self):
        missing = self.base / 'not-created.zip'
        output = self.base / 'export.zip'
        output.symlink_to(missing)
        with self.assertRaisesRegex(ValueError, 'symlinks'):
            packaging.create_archive(self.root, output)
        self.assertTrue(output.is_symlink())
        self.assertFalse(missing.exists())

    @unittest.skipUnless(os.name == 'posix', 'POSIX symlinks required')
    def test_checksum_symlink_keeps_previous_zip_and_external_content(self):
        output = self.base / 'export.zip'
        output.write_bytes(b'previous archive')
        external = self.base / 'private-checksum.txt'
        external.write_bytes(b'leave untouched')
        checksum = output.with_suffix('.zip.sha256')
        checksum.symlink_to(external)
        with self.assertRaisesRegex(ValueError, 'symlinks'):
            packaging.create_archive(self.root, output)
        self.assertEqual(output.read_bytes(), b'previous archive')
        self.assertTrue(checksum.is_symlink())
        self.assertEqual(external.read_bytes(), b'leave untouched')

    @unittest.skipUnless(
        os.name == 'posix' and hasattr(os, 'O_NOFOLLOW'),
        'POSIX no-follow descriptors required',
    )
    def test_swapped_output_symlink_is_rejected_during_previous_backup(self):
        output = self.base / 'export.zip'
        output.write_bytes(b'old regular output')
        external = self.base / 'private.zip'
        external.write_bytes(b'confidential external contents')
        source_paths = packaging.source_paths

        def swap_after_output_check(root):
            paths = source_paths(root)
            output.rename(self.base / 'original-export.zip')
            output.symlink_to(external)
            return paths

        with mock.patch.object(
            packaging, 'source_paths', side_effect=swap_after_output_check
        ):
            with self.assertRaisesRegex(ValueError, 'symlink'):
                packaging.create_archive(self.root, output, layout='root')
        self.assertTrue(output.is_symlink())
        self.assertEqual(external.read_bytes(), b'confidential external contents')
        self.assertEqual((self.base / 'original-export.zip').read_bytes(),
                         b'old regular output')
        self.assertFalse(output.with_suffix('.zip.sha256').exists())

    def test_missing_workflow_rejects_export_before_replacing_existing_file(self):
        (self.root / '.github/workflows/android-build.yml').unlink()
        output = self.base / 'existing.zip'
        output.write_bytes(b'previous archive')
        with self.assertRaisesRegex(ValueError, 'Missing required'):
            packaging.create_archive(self.root, output)
        self.assertEqual(output.read_bytes(), b'previous archive')

    def test_output_inside_source_is_rejected_without_recursive_archive(self):
        output = self.root / 'backup.zip'
        with self.assertRaisesRegex(ValueError, 'outside'):
            packaging.create_archive(self.root, output)
        self.assertFalse(output.exists())


    def test_case_insensitive_filename_collision_is_rejected(self):
        first = self.root / 'app/assets/Card.png'
        second = self.root / 'app/assets/card.PNG'
        first.write_bytes(b'card one')
        second.write_bytes(b'card two')
        output = self.base / 'collision.zip'
        with self.assertRaisesRegex(ValueError, 'case-insensitive'):
            packaging.create_archive(self.root, output, layout='root')
        self.assertFalse(output.exists())

    def test_case_insensitive_directory_collision_is_rejected(self):
        for name in ('app/assets/Icons/sword.svg',
                     'app/assets/icons/shield.svg'):
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('fixture', encoding='utf-8')
        output = self.base / 'directory-collision.zip'
        with self.assertRaisesRegex(ValueError, 'case-insensitive'):
            packaging.create_archive(self.root, output, layout='root')
        self.assertFalse(output.exists())

    def test_nfc_unicode_filename_collision_is_rejected(self):
        first = self.root / 'app/assets/café.txt'
        second = self.root / 'app/assets/cafe\u0301.txt'
        first.write_text('composed', encoding='utf-8')
        second.write_text('decomposed', encoding='utf-8')
        if first.samefile(second):
            self.skipTest('The filesystem already normalizes Unicode filenames')
        output = self.base / 'unicode-collision.zip'
        with self.assertRaisesRegex(ValueError, 'Unicode-equivalent'):
            packaging.create_archive(self.root, output, layout='root')
        self.assertFalse(output.exists())

    def test_unsupported_windows_filenames_are_rejected(self):
        for name in ('CON.txt', 'LPT1.txt', 'notes?.txt', 'trailing.',
                     'tailspace ', 'line\nbreak.txt'):
            with self.subTest(name=name):
                path = self.root / 'app/assets' / name
                path.write_text('non portable', encoding='utf-8')
                output = self.base / 'nonportable.zip'
                with self.assertRaisesRegex(ValueError, 'non-portable'):
                    packaging.create_archive(self.root, output)
                self.assertFalse(output.exists())
                path.unlink()

    def test_excluded_log_does_not_enter_archive_or_block_safe_export(self):
        log = self.root / 'app/assets/LPT1.log'
        log.write_text('excluded log data', encoding='utf-8')
        output = self.base / 'ignored-log.zip'
        packaging.create_archive(self.root, output, layout='root')
        with zipfile.ZipFile(output) as archive:
            self.assertNotIn('app/assets/LPT1.log', archive.namelist())
            self.assertEqual(set(archive.namelist()), packaging.REQUIRED_FILES)

    def test_failed_portability_check_keeps_prior_zip_and_checksum(self):
        output = self.base / 'existing.zip'
        packaging.create_archive(self.root, output, layout='root')
        previous_zip = output.read_bytes()
        previous_sum = output.with_suffix('.zip.sha256').read_bytes()
        (self.root / 'app/assets/Card.svg').write_text('first', encoding='utf-8')
        (self.root / 'app/assets/card.svg').write_text('second', encoding='utf-8')
        with self.assertRaisesRegex(ValueError, 'case-insensitive'):
            packaging.create_archive(self.root, output, layout='root')
        self.assertEqual(previous_zip, output.read_bytes())
        self.assertEqual(previous_sum, output.with_suffix('.zip.sha256').read_bytes())

    def test_legitimate_distinct_filenames_still_export(self):
        (self.root / 'app/assets/Icon.svg').write_bytes(b'sword')
        (self.root / 'app/assets/Shield.svg').write_bytes(b'shield')
        output = self.base / 'portable.zip'
        packaging.create_archive(self.root, output, layout='root')
        with zipfile.ZipFile(output) as archive:
            self.assertIn('app/assets/Icon.svg', archive.namelist())
            self.assertIn('app/assets/Shield.svg', archive.namelist())

    def test_symlink_to_external_file_is_rejected(self):
        outside = self.base / 'external.txt'
        outside.write_text('external fixture')
        (self.root / 'linked.txt').symlink_to(outside)
        output = self.base / 'linked.zip'
        with self.assertRaisesRegex(ValueError, 'symlinked'):
            packaging.create_archive(self.root, output)
        self.assertFalse(output.exists())

    def test_local_sdks_and_virtual_environments_are_skipped_without_losing_source_assets(self):
        for name in ['personal-python/pyvenv.cfg', 'personal-python/lib/large.bin',
                     'local-flutter/bin/internal/engine.version',
                     'local-flutter/packages/flutter/pubspec.yaml',
                     'local-flutter/bin/cache/large.bin', 'backup.ZIP',
                     'signing.pem', 'signing.key', 'certificates/client.p12']:
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('local fixture')
        source_asset = self.root / 'app/assets/needed.bin'
        source_asset.write_bytes(b'\x00legitimate asset')
        output = self.base / 'safe.zip'
        packaging.create_archive(self.root, output, layout='root')
        with zipfile.ZipFile(output) as archive:
            self.assertEqual(set(archive.namelist()),
                             packaging.REQUIRED_FILES | {'app/assets/needed.bin'})

    def test_directory_symlink_is_rejected_even_when_empty(self):
        external = self.base / 'external'
        external.mkdir()
        (self.root / 'linked').symlink_to(external, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, 'symlinked directories'):
            packaging.create_archive(self.root, self.base / 'bad.zip')

    def test_mixed_case_secrets_and_cache_directories_are_excluded(self):
        # A ZIP generated on Linux must not leak names supplied by a
        # case-insensitive filesystem or imported with mixed casing.
        secrets = [
            '.ENV', 'backend/.Env.production', 'backend/.NPMRC',
            'credentials.JSON', 'signing.JKS', 'app/backup.DB-WAL',
            'app/backup.db-ShM', 'app/backup.db-JOURNAL',
            'NODE_MODULES/sensitive.txt', 'Build/private.txt',
            '.GIT/config', 'app/.DART_TOOL/secrets.json',
        ]
        for name in secrets:
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('must not export', encoding='utf-8')

        # Public samples and ordinary case-preserved assets remain valid.
        allowed = ['backend/.ENV.EXAMPLE', 'app/assets/FantasyArt.PNG']
        for name in allowed:
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('safe to export', encoding='utf-8')
        output = self.base / 'mixed-case.zip'
        count, _ = packaging.create_archive(self.root, output, layout='root')
        with zipfile.ZipFile(output) as archive:
            self.assertEqual(set(archive.namelist()),
                             packaging.REQUIRED_FILES | set(allowed))
            self.assertIsNone(archive.testzip())
        self.assertEqual(count, len(packaging.REQUIRED_FILES) + len(allowed))

    def test_generated_and_system_files_stay_excluded_in_all_casings(self):
        for name in ['.DS_Store', '.ds_store', '.Ds_StOrE',
                     'GeneratedPluginRegistrant.java',
                     'app/android/GeneratedPluginRegistrant.java',
                     'app/android/generatedpluginregistrant.JAVA']:
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text('generated or system fixture', encoding='utf-8')
        output = self.base / 'no-generated-files.zip'
        packaging.create_archive(self.root, output, layout='root')
        with zipfile.ZipFile(output) as archive:
            self.assertEqual(set(archive.namelist()), packaging.REQUIRED_FILES)
            self.assertIsNone(archive.testzip())

    @unittest.skipUnless(os.name == 'posix', 'POSIX no-follow descriptors required')
    def test_swapped_source_file_link_is_rejected_before_export(self):
        output = self.base / 'previous.zip'
        packaging.create_archive(self.root, output, layout='root')
        old_pair = (
            output.read_bytes(),
            output.with_suffix('.zip.sha256').read_bytes(),
        )
        enumerated = packaging.source_paths(self.root)
        private = self.base / 'external-private.txt'
        private.write_text('never package this secret', encoding='utf-8')
        target = self.root / 'README.md'
        target.unlink()
        target.symlink_to(private)
        with mock.patch.object(packaging, 'source_paths', return_value=enumerated):
            with self.assertRaisesRegex(ValueError, 'symlinked'):
                packaging.create_archive(self.root, output, layout='root')
        self.assertEqual(old_pair, (
            output.read_bytes(),
            output.with_suffix('.zip.sha256').read_bytes(),
        ))
        with zipfile.ZipFile(output) as archive:
            self.assertNotIn(b'never package this secret', archive.read('README.md'))

    @unittest.skipUnless(os.name == 'posix', 'POSIX no-follow descriptors required')
    def test_swapped_parent_directory_symlink_is_rejected(self):
        original_paths = packaging.source_paths(self.root)
        assets = self.root / 'app/assets'
        moved = self.base / 'original-assets'
        assets.rename(moved)
        outside = self.base / 'outside-assets'
        outside.mkdir()
        (outside / 'demo.json').write_text('outside secret', encoding='utf-8')
        assets.symlink_to(outside, target_is_directory=True)
        output = self.base / 'unsafe-parent.zip'
        with mock.patch.object(packaging, 'source_paths', return_value=original_paths):
            with self.assertRaisesRegex(ValueError, 'symlinked'):
                packaging.create_archive(self.root, output, layout='root')
        self.assertFalse(output.exists())
        self.assertFalse(output.with_suffix('.zip.sha256').exists())

    @unittest.skipUnless(os.name == 'posix', 'POSIX no-follow descriptors required')
    def test_symlink_swapped_for_regular_file_cannot_be_used_as_source(self):
        original_paths = packaging.source_paths(self.root)
        private = self.base / 'outside'
        private.write_text('outside content', encoding='utf-8')
        target = self.root / 'app/lib/main.dart'
        target.unlink()
        target.symlink_to(private)
        with mock.patch.object(packaging, 'source_paths', return_value=original_paths):
            with self.assertRaisesRegex(ValueError, 'symlinked'):
                packaging.create_archive(self.root, self.base / 'new.zip')
        self.assertFalse((self.base / 'new.zip').exists())

    def test_source_change_during_read_does_not_replace_published_zip(self):
        output = self.base / 'existing.zip'
        packaging.create_archive(self.root, output, layout='root')
        checksum = output.with_suffix('.zip.sha256')
        previous = output.read_bytes(), checksum.read_bytes()
        original_fstat = packaging.os.fstat
        altered = False

        def changed_stat(fd):
            nonlocal altered
            stat = original_fstat(fd)
            if not altered:
                altered = True
                class Changed:
                    st_mode = stat.st_mode
                    st_dev = stat.st_dev
                    st_ino = stat.st_ino
                    st_size = stat.st_size
                    st_mtime_ns = stat.st_mtime_ns + 1
                    st_ctime_ns = stat.st_ctime_ns
                return Changed()
            return stat

        with mock.patch.object(packaging.os, 'fstat', side_effect=changed_stat):
            with self.assertRaisesRegex(RuntimeError, 'Source changed'):
                packaging.create_archive(self.root, output, layout='root')
        self.assertEqual((output.read_bytes(), checksum.read_bytes()), previous)

    def test_verified_source_zip_preserves_executable_flags(self):
        runnable = self.root / 'app/lib/main.dart'
        ordinary = self.root / 'README.md'
        runnable.chmod(0o755)
        ordinary.chmod(0o644)
        output = self.base / 'modes.zip'
        packaging.create_archive(self.root, output, layout='root')
        with zipfile.ZipFile(output) as archive:
            runnable_mode = archive.getinfo('app/lib/main.dart').external_attr >> 16
            ordinary_mode = archive.getinfo('README.md').external_attr >> 16
            self.assertTrue(stat.S_ISREG(runnable_mode))
            self.assertTrue(stat.S_ISREG(ordinary_mode))
            self.assertEqual(runnable_mode & 0o777, 0o755)
            self.assertEqual(ordinary_mode & 0o777, 0o644)

    def test_failed_zip_write_does_not_damage_previous_zip_or_checksum(self):
        output = self.base / 'saved.zip'
        packaging.create_archive(self.root, output, layout='root')
        checksum = output.with_suffix('.zip.sha256')
        previous = (output.read_bytes(), checksum.read_bytes())
        before = set(self.base.iterdir())

        with mock.patch.object(packaging.zipfile.ZipFile, 'writestr',
                               side_effect=OSError('simulated disk full')):
            with self.assertRaisesRegex(OSError, 'simulated disk full'):
                packaging.create_archive(self.root, output, layout='root')

        self.assertEqual((output.read_bytes(), checksum.read_bytes()), previous)
        self.assertEqual(set(self.base.iterdir()), before)
        with zipfile.ZipFile(output) as archive:
            self.assertIsNone(archive.testzip())

    def test_failed_new_zip_write_leaves_no_partial_publication(self):
        output = self.base / 'new.zip'
        before = set(self.base.iterdir())
        with mock.patch.object(packaging.zipfile.ZipFile, 'writestr',
                               side_effect=OSError('simulated write failure')):
            with self.assertRaisesRegex(OSError, 'simulated write failure'):
                packaging.create_archive(self.root, output, layout='folder')
        self.assertFalse(output.exists())
        self.assertFalse(output.with_suffix('.zip.sha256').exists())
        self.assertEqual(set(self.base.iterdir()), before)

    def test_failed_checksum_publication_rolls_back_previous_archive(self):
        output = self.base / 'published.zip'
        packaging.create_archive(self.root, output, layout='root')
        checksum = output.with_suffix('.zip.sha256')
        previous = (output.read_bytes(), checksum.read_bytes())
        before = set(self.base.iterdir())
        (self.root / 'app/lib/main.dart').write_text('new version', encoding='utf-8')

        original_replace = packaging.os.replace

        def fail_checksum_replacement(source, destination):
            if Path(destination) == checksum:
                raise OSError('simulated checksum replacement failure')
            return original_replace(source, destination)

        with mock.patch.object(packaging.os, 'replace',
                               side_effect=fail_checksum_replacement):
            with self.assertRaisesRegex(OSError, 'checksum replacement failure'):
                packaging.create_archive(self.root, output, layout='root')

        self.assertEqual((output.read_bytes(), checksum.read_bytes()), previous)
        self.assertEqual(set(self.base.iterdir()), before)

    def test_successful_overwrite_replaces_zip_and_checksum_together(self):
        output = self.base / 'published.zip'
        packaging.create_archive(self.root, output, layout='root')
        old_archive = output.read_bytes()
        (self.root / 'app/lib/main.dart').write_text('new version', encoding='utf-8')
        count, digest = packaging.create_archive(self.root, output, layout='root')
        self.assertEqual(count, len(packaging.REQUIRED_FILES))
        self.assertNotEqual(output.read_bytes(), old_archive)
        with zipfile.ZipFile(output) as archive:
            self.assertEqual(archive.read('app/lib/main.dart'), b'new version')
            self.assertIsNone(archive.testzip())
        self.assertEqual(output.with_suffix('.zip.sha256').read_text(),
                         f'{digest}  {output.name}\n')
        self.assertEqual(set(self.base.iterdir()),
                         {self.root, output, output.with_suffix('.zip.sha256')})

    def test_invalid_layout_cannot_create_an_ambiguous_archive(self):
        with self.assertRaisesRegex(ValueError, 'layout'):
            packaging.create_archive(self.root, self.base / 'bad.zip', layout='nested')


if __name__ == '__main__':
    unittest.main()
