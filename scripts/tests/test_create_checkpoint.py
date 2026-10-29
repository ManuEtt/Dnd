"""Exercise complete checkpoint recovery with real isolated Git repositories."""

from datetime import datetime, timezone
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
import zipfile


SCRIPTS = Path(__file__).resolve().parents[1]
for name in ('package_project', 'prepare_alpha_release', 'create_checkpoint'):
    spec = importlib.util.spec_from_file_location(name, SCRIPTS / f'{name}.py')
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
checkpoint = sys.modules['create_checkpoint']
packaging = sys.modules['package_project']
NOW = datetime(2026, 10, 16, 12, 30, tzinfo=timezone.utc)


class CheckpointTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.root = self.directory / 'project'
        self.root.mkdir()
        for name in packaging.REQUIRED_FILES:
            self.write(name, 'fixture: ' + name)
        self.write('app/pubspec.yaml', 'name: fixture\nversion: 0.7.4+44\n')
        self.write('CHECKPOINT.md', 'Fixture checkpoint instructions.\n')
        self.write('deleted.txt', 'Will be deleted after the base commit.\n')
        self.write('mode.sh', '#!/bin/sh\nexit 0\n')
        self.write('.gitignore', 'ignored-required-source.txt\n.env\n')
        self.run_git('init', '--quiet')
        self.run_git('add', '.')
        self.run_git('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
                     'commit', '--quiet', '-m', 'base')
        self.base = self.run_git('rev-parse', 'HEAD').decode().strip()
        self.output = self.directory / 'artifacts'

    def write(self, name, contents):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        if isinstance(contents, bytes):
            path.write_bytes(contents)
        else:
            path.write_text(contents, encoding='utf-8')
        return path

    def run_git(self, *args):
        return subprocess.run(['git', '-C', str(self.root), *args],
                              capture_output=True, check=True).stdout

    def create(self, **kwargs):
        options = {'base': self.base, 'label': 'tested', 'now': NOW}
        options.update(kwargs)
        return checkpoint.create_checkpoint(self.root, self.output, **options)

    def test_working_tree_patch_recovers_binary_untracked_ignored_deletions_and_modes(self):
        self.write('app/lib/main.dart', 'Final worktree.\n')
        self.run_git('add', 'app/lib/main.dart')
        # A staged intermediate version must not override the actual source snapshot.
        self.write('app/lib/main.dart', 'Actual final worktree.\n')
        self.write('app/assets/new image.bin', b'\x00\xffbinary\x00payload')
        self.write('ignored-required-source.txt', 'Required despite gitignore.\n')
        (self.root / 'deleted.txt').unlink()
        (self.root / 'mode.sh').chmod(0o755)
        index = self.run_git('diff', '--cached', '--binary')
        status = self.run_git('status', '--porcelain')
        result = self.create()
        self.assertEqual(self.run_git('diff', '--cached', '--binary'), index)
        self.assertEqual(self.run_git('status', '--porcelain'), status)
        self.assertEqual(self.run_git('rev-parse', 'HEAD').decode().strip(), self.base)
        patch = Path(result['patch']).read_text()
        self.assertIn('GIT binary patch', patch)
        self.assertIn('deleted file mode', patch)
        self.assertIn('old mode 100644\nnew mode 100755', patch)
        manifest = json.loads(Path(result['manifest']).read_text())
        self.assertEqual(manifest['base_commit'], self.base)
        self.assertEqual(manifest['app_version'], '0.7.4+44')
        self.assertTrue(manifest['working_tree_dirty'])
        self.assertTrue(all(manifest['validation'].values()))
        self.assertNotIn('deleted.txt', manifest['files'])
        self.assertEqual(manifest['files']['app/assets/new image.bin']['size'], 16)
        with zipfile.ZipFile(result['archive']) as archive:
            self.assertIn('ignored-required-source.txt', archive.namelist())
            self.assertIn('CHECKPOINT.md', archive.namelist())
            self.assertIn('.github/workflows/android-build.yml', archive.namelist())
            self.assertEqual(archive.read('app/lib/main.dart'), b'Actual final worktree.\n')
        self.assertEqual(Path(result['archive']).read_bytes(),
                         Path(result['latest_archive']).read_bytes())
        for line in Path(result['latest_checksums']).read_text().splitlines():
            digest, filename = line.split('  ', 1)
            self.assertEqual(digest, hashlib.sha256((self.output / filename).read_bytes()).hexdigest())

    def test_clean_base_produces_empty_patch_that_is_still_verified(self):
        result = self.create()
        self.assertEqual(Path(result['patch']).read_bytes(), b'')
        self.assertFalse(json.loads(Path(result['manifest']).read_text())['working_tree_dirty'])

    def test_secrets_caches_sdks_venvs_and_existing_archives_are_absent_from_zip_and_patch(self):
        excluded = ['backend/.env.production', 'app/android/key.properties', 'private.pem',
                    'credentials.json', '.ssh/id_ed25519', '.venv/bin/python',
                    'flutter-sdk/bin/flutter', 'dart-sdk/bin/dart', 'node_modules/a.js',
                    'app/build/a.txt', 'previous.ZIP', 'previous.patch', 'personal.sqlite3',
                    'private.key', 'private.p12', 'cache.pyc']
        for name in excluded:
            self.write(name, 'EXCLUDED_FIXTURE_SECRET')
        # Previously tracked excluded files must never contribute content to the patch.
        self.run_git('add', '--force', 'private.pem')
        self.run_git('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
                     'commit', '--quiet', '-m', 'unrelated excluded file')
        self.write('backend/.env.example', 'PROVIDER=mock\n')
        result = self.create()
        with zipfile.ZipFile(result['archive']) as archive:
            self.assertTrue(set(excluded).isdisjoint(archive.namelist()))
            self.assertIn('backend/.env.example', archive.namelist())
        self.assertNotIn(b'EXCLUDED_FIXTURE_SECRET', Path(result['patch']).read_bytes())
        self.assertNotIn(b'private.pem', Path(result['patch']).read_bytes())

    def test_two_checkpoints_retain_both_versions_and_checksum_history(self):
        first = self.create()
        first_bytes = Path(first['archive']).read_bytes()
        self.write('app/lib/main.dart', 'Second checkpoint.\n')
        second = self.create(label='second')
        self.assertEqual(Path(first['archive']).read_bytes(), first_bytes)
        self.assertTrue(Path(first['patch']).is_file())
        self.assertTrue(Path(second['patch']).is_file())
        self.assertEqual(Path(second['latest_archive']).read_bytes(), Path(second['archive']).read_bytes())
        sums = Path(second['latest_checksums']).read_text()
        self.assertIn(Path(first['archive']).name, sums)
        self.assertIn(Path(second['archive']).name, sums)

    def test_prior_checksum_history_rejects_symlink_without_touching_aliases(self):
        self.create()
        before = {p.name: p.read_bytes() for p in self.output.iterdir()}
        external = self.directory / 'outside-private.zip'
        external.write_bytes(b'DO_NOT_HASH_EXTERNAL')
        link = self.output / 'Wuerfelraunen_old_Vollprojekt.zip'
        link.symlink_to(external)
        with mock.patch.object(checkpoint, 'sha256', wraps=checkpoint.sha256) as digest:
            with self.assertRaisesRegex(ValueError, 'Unsafe previous checkpoint artifact'):
                self.create(label='second')
            self.assertFalse(any(
                call.args and call.args[0] == link
                for call in digest.call_args_list
            ))
        self.assertEqual(
            before,
            {name: (self.output / name).read_bytes() for name in before},
        )
        self.assertTrue(link.is_symlink())

    def test_swapped_historical_zip_symlink_during_hash_is_never_followed(self):
        first = self.create()
        latest = Path(first['latest_archive']).read_bytes()
        checksums = Path(first['latest_checksums']).read_bytes()
        old_archive = Path(first['archive'])
        outside = self.directory / 'external-private.zip'
        outside.write_bytes(b'DO_NOT_HASH_EXTERNAL_CHECKPOINT')
        original_scan = checkpoint.previous_checkpoint_files

        def swap_after_listing(directory):
            entries = original_scan(directory)
            old_archive.unlink()
            old_archive.symlink_to(outside)
            return entries

        with mock.patch.object(
                checkpoint, 'previous_checkpoint_files', side_effect=swap_after_listing):
            with self.assertRaisesRegex(ValueError, 'Unsafe previous checkpoint artifact'):
                self.create(label='swapped')
        self.assertTrue(old_archive.is_symlink())
        self.assertEqual(Path(first['latest_archive']).read_bytes(), latest)
        self.assertEqual(Path(first['latest_checksums']).read_bytes(), checksums)

    def test_historical_zip_rewritten_after_listing_preserves_old_aliases(self):
        first = self.create()
        latest = Path(first['latest_archive']).read_bytes()
        checksums = Path(first['latest_checksums']).read_bytes()
        old_archive = Path(first['archive'])
        original_scan = checkpoint.previous_checkpoint_files

        def rewrite_after_listing(directory):
            entries = original_scan(directory)
            old_archive.write_bytes(b'ALTERED_DURING_CHECKPOINT')
            return entries

        with mock.patch.object(
                checkpoint, 'previous_checkpoint_files', side_effect=rewrite_after_listing):
            with self.assertRaisesRegex(ValueError, 'Historical checkpoint changed'):
                self.create(label='changed')
        self.assertEqual(Path(first['latest_archive']).read_bytes(), latest)
        self.assertEqual(Path(first['latest_checksums']).read_bytes(), checksums)

    def test_prior_checksum_history_rejects_newline_in_filename(self):
        self.create()
        previous = {p.name: p.read_bytes() for p in self.output.iterdir()}
        unsafe = self.output / 'Wuerfelraunen_bogus\nother.zip'
        unsafe.write_bytes(b'unsafe checksum line')
        with self.assertRaisesRegex(ValueError, 'Unsafe previous checkpoint artifact'):
            self.create(label='second')
        self.assertEqual(
            previous,
            {name: (self.output / name).read_bytes() for name in previous},
        )
        self.assertTrue(unsafe.is_file())

    def test_prior_checksum_history_rejects_directory_disguised_as_zip(self):
        self.create()
        previous = {p.name: p.read_bytes() for p in self.output.iterdir()}
        (self.output / 'Wuerfelraunen_old_Vollprojekt.zip').mkdir()
        with self.assertRaisesRegex(ValueError, 'Unsafe previous checkpoint artifact'):
            self.create(label='second')
        self.assertEqual(
            previous,
            {name: (self.output / name).read_bytes() for name in previous},
        )

    def test_previously_tracked_secret_is_not_disclosed_by_patch_or_manifest(self):
        self.write('private.pem', 'ORIGINAL_PRIVATE_FIXTURE')
        self.run_git('add', '--force', 'private.pem')
        self.run_git('-c', 'user.name=Fixture', '-c', 'user.email=fixture@example.invalid',
                     'commit', '--quiet', '-m', 'fixture with excluded file')
        self.base = self.run_git('rev-parse', 'HEAD').decode().strip()
        self.write('private.pem', 'CHANGED_PRIVATE_FIXTURE')
        self.write('app/lib/main.dart', 'Safe source change.\n')
        result = self.create()
        for key in ('patch', 'manifest'):
            contents = Path(result[key]).read_bytes()
            self.assertNotIn(b'private.pem', contents)
            self.assertNotIn(b'PRIVATE_FIXTURE', contents)

    def test_manifest_rejects_source_symlink_swapped_after_listing(self):
        paths = checkpoint.source_paths(self.root)
        outside = self.directory / 'outside-private.txt'
        outside.write_text('DO_NOT_HASH_PRIVATE_CONTENT', encoding='utf-8')
        target = self.root / 'app/lib/main.dart'
        target.unlink()
        target.symlink_to(outside)
        with mock.patch.object(checkpoint, 'source_paths', return_value=paths):
            with self.assertRaisesRegex(ValueError, 'symlinked'):
                checkpoint.file_manifest(self.root)

    def test_manifest_rejects_swapped_parent_directory_symlink(self):
        paths = checkpoint.source_paths(self.root)
        assets = self.root / 'app/assets'
        original_assets = self.directory / 'old-assets'
        assets.rename(original_assets)
        external = self.directory / 'external-assets'
        external.mkdir()
        (external / 'demo.json').write_text('PRIVATE_OUTSIDE', encoding='utf-8')
        assets.symlink_to(external, target_is_directory=True)
        with mock.patch.object(checkpoint, 'source_paths', return_value=paths):
            with self.assertRaisesRegex(ValueError, 'symlinked'):
                checkpoint.file_manifest(self.root)

    def test_swapped_manifest_symlink_preserves_verified_checkpoint_files(self):
        first = self.create()
        previous = {p.name: p.read_bytes() for p in self.output.iterdir()}
        paths = checkpoint.source_paths(self.root)
        outside = self.directory / 'outside'
        outside.write_text('never put this in a checkpoint', encoding='utf-8')
        target = self.root / 'app/lib/main.dart'
        target.unlink()
        target.symlink_to(outside)
        with mock.patch.object(checkpoint, 'source_paths', return_value=paths):
            with self.assertRaisesRegex(ValueError, 'symlinked'):
                self.create(label='swapped')
        self.assertEqual(previous, {
            p.name: p.read_bytes() for p in self.output.iterdir()
        })
        self.assertTrue(Path(first['latest_archive']).is_file())
        self.assertNotIn(
            b'never put this in a checkpoint',
            Path(first['manifest']).read_bytes(),
        )

    def test_concurrent_source_change_is_rejected_before_replacing_latest(self):
        self.create()
        before = {path.name: path.read_bytes() for path in self.output.iterdir()}
        original_create_archive = checkpoint.create_archive

        def change_after_archive(*args, **kwargs):
            result = original_create_archive(*args, **kwargs)
            self.write('app/lib/main.dart', 'Changed while packaging.\n')
            return result

        with mock.patch.object(checkpoint, 'create_archive', side_effect=change_after_archive):
            with self.assertRaisesRegex(ValueError, 'does not reproduce'):
                self.create(label='concurrent')
        after = {path.name: path.read_bytes() for path in self.output.iterdir()}
        self.assertEqual(before, after)

    def test_failed_patch_verification_preserves_previous_verified_latest(self):
        first = self.create()
        before = {path.name: path.read_bytes() for path in self.output.iterdir()}
        self.write('app/lib/main.dart', 'Changed source.\n')
        with mock.patch.object(checkpoint, 'validate_patch', side_effect=ValueError('bad patch')):
            with self.assertRaisesRegex(ValueError, 'bad patch'):
                self.create(label='failed')
        after = {path.name: path.read_bytes() for path in self.output.iterdir()}
        self.assertEqual(before, after)
        self.assertTrue(Path(first['latest_archive']).is_file())

    def test_duplicate_checkpoint_does_not_overwrite_artifacts(self):
        self.create()
        with self.assertRaisesRegex(ValueError, 'already exists'):
            self.create()

    def test_output_inside_repository_is_rejected(self):
        with self.assertRaisesRegex(ValueError, 'outside'):
            checkpoint.create_checkpoint(self.root, self.root / 'output',
                                         base=self.base, label='unsafe')
        self.assertFalse((self.root / 'output').exists())

    def test_invalid_base_fails_before_creating_output(self):
        with self.assertRaisesRegex(ValueError, 'Git rev-parse failed'):
            self.create(base='--not-a-commit')
        self.assertFalse(self.output.exists())

    def test_unsafe_label_is_rejected(self):
        for label in ('../escape', '', 'space in name', 'x' * 65):
            with self.subTest(label=label), self.assertRaisesRegex(ValueError, 'Label'):
                self.create(label=label)
        self.assertFalse(self.output.exists())

    def test_missing_required_source_fails_before_creating_output(self):
        (self.root / 'app/pubspec.lock').unlink()
        with self.assertRaisesRegex(ValueError, 'Missing required'):
            self.create()
        self.assertFalse(self.output.exists())

    def test_directory_symlink_cannot_hide_missing_or_external_source(self):
        external = self.directory / 'external'
        external.mkdir()
        (self.root / 'linked').symlink_to(external, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, 'symlinked directories'):
            self.create()
        self.assertFalse(self.output.exists())

    def test_unusual_source_paths_cannot_create_unsafe_archives_or_checksum_lines(self):
        self.write('line\nbreak.txt', 'unsafe name')
        with self.assertRaisesRegex(ValueError, 'Unsafe source'):
            self.create()

    def test_archive_validation_rejects_traversal_duplicate_and_unexpected_entries(self):
        archive = self.directory / 'malicious.zip'
        payload = b'payload'
        info = {'sha256': hashlib.sha256(payload).hexdigest(), 'size': len(payload)}
        with zipfile.ZipFile(archive, 'w') as writer:
            writer.writestr('../escape', payload)
        with self.assertRaisesRegex(ValueError, 'Unsafe'):
            checkpoint.validate_archive(archive, {'../escape': info})
        with zipfile.ZipFile(archive, 'w') as writer:
            writer.writestr('unexpected.txt', payload)
        with self.assertRaisesRegex(ValueError, 'file list'):
            checkpoint.validate_archive(archive, {})
        with zipfile.ZipFile(archive, 'w') as writer:
            writer.writestr('duplicate.txt', payload)
            with self.assertWarns(UserWarning):
                writer.writestr('duplicate.txt', payload)
        with self.assertRaisesRegex(ValueError, 'file list'):
            checkpoint.validate_archive(archive, {'duplicate.txt': info})

    def test_archive_validation_rejects_modified_contents(self):
        archive = self.directory / 'modified.zip'
        with zipfile.ZipFile(archive, 'w') as writer:
            writer.writestr('file.txt', b'changed')
        expected = {'file.txt': {'sha256': hashlib.sha256(b'original').hexdigest(), 'size': 8}}
        with self.assertRaisesRegex(ValueError, 'differ'):
            checkpoint.validate_archive(archive, expected)


if __name__ == '__main__':
    unittest.main()
