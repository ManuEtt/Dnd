import importlib.util
from pathlib import Path
import tempfile
import unittest
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

    def test_invalid_layout_cannot_create_an_ambiguous_archive(self):
        with self.assertRaisesRegex(ValueError, 'layout'):
            packaging.create_archive(self.root, self.base / 'bad.zip', layout='nested')


if __name__ == '__main__':
    unittest.main()
