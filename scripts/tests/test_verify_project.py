"""Regression tests for incomplete uploads; no Flutter, Java or network required."""
from pathlib import Path
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest
from unittest import mock
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from verify_project import (
    MAX_WRAPPER_ENTRIES, MAX_WRAPPER_JAR_BYTES, MAX_WRAPPER_UNCOMPRESSED_BYTES,
    REQUIRED_FILES, ROOT, WRAPPER_MAIN, verify_project,
)


class VerifyProjectTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name) / 'repository'
        self.root.mkdir()
        for name in REQUIRED_FILES:
            destination = self.root / name
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / name, destination)

    def test_complete_source_and_additional_files_are_allowed(self):
        (self.root / 'other-existing-project.txt').write_text('retain me')
        self.assertEqual(verify_project(self.root), [])

    def test_outer_zip_directory_has_specific_actionable_error(self):
        nested = self.root.parent / 'nested'
        nested.mkdir()
        shutil.move(str(self.root), nested / 'Dnd')
        errors = verify_project(nested)
        self.assertEqual(len(errors), 1)
        self.assertIn('Zusätzlicher Ordner Dnd/', errors[0])
        self.assertIn('Repositorywurzel', errors[0])

    def test_missing_hidden_workflow_explains_hidden_files(self):
        (self.root / '.github/workflows/android-build.yml').unlink()
        errors = verify_project(self.root)
        self.assertTrue(any('android-build.yml' in error and 'Versteckte Dateien' in error for error in errors))

    def test_missing_flutter_and_backend_lockfiles_are_reported(self):
        for name in ('app/pubspec.lock', 'backend/package-lock.json'):
            (self.root / name).unlink()
        errors = verify_project(self.root)
        self.assertEqual(len(errors), 2)
        self.assertTrue(any('app/pubspec.lock' in error for error in errors))
        self.assertTrue(any('backend/package-lock.json' in error for error in errors))

    def test_empty_required_file_is_rejected(self):
        (self.root / 'app/lib/main.dart').write_bytes(b'')
        self.assertTrue(any('Pflichtdatei ist leer' in error for error in verify_project(self.root)))

    def test_truncated_json_is_rejected_without_echoing_contents(self):
        marker = 'private-do-not-print'
        (self.root / 'backend/package-lock.json').write_text('{"secret":"' + marker)
        errors = verify_project(self.root)
        self.assertTrue(any('Ungültige JSON-Datei' in error for error in errors))
        self.assertNotIn(marker, '\n'.join(errors))

    def test_missing_wrapper_is_reported(self):
        (self.root / 'app/android/gradle/wrapper/gradle-wrapper.jar').unlink()
        self.assertTrue(any('Pflichtdatei fehlt' in error and 'gradle-wrapper.jar' in error for error in verify_project(self.root)))

    def test_text_instead_of_wrapper_is_rejected(self):
        (self.root / 'app/android/gradle/wrapper/gradle-wrapper.jar').write_text('not a binary JAR')
        self.assertTrue(any('Gradle-Wrapper-JAR' in error for error in verify_project(self.root)))

    def test_valid_zip_without_start_class_is_rejected(self):
        path = self.root / 'app/android/gradle/wrapper/gradle-wrapper.jar'
        with zipfile.ZipFile(path, 'w') as archive:
            archive.writestr('README.txt', 'wrong archive')
        self.assertTrue(any('Gradle-Wrapper-JAR' in error for error in verify_project(self.root)))

    def test_duplicate_start_class_is_rejected_even_with_valid_crc(self):
        path = self.root / 'app/android/gradle/wrapper/gradle-wrapper.jar'
        with zipfile.ZipFile(path, 'w') as archive:
            archive.writestr(WRAPPER_MAIN, b'\xca\xfe\xba\xbeoriginal')
            with self.assertWarns(UserWarning):
                archive.writestr(WRAPPER_MAIN, b'\xca\xfe\xba\xbeother')
        errors = verify_project(self.root)
        self.assertTrue(any('Gradle-Wrapper-JAR' in message for message in errors))

    def test_wrapper_rejects_unsafe_archive_paths(self):
        jar = self.root / 'app/android/gradle/wrapper/gradle-wrapper.jar'
        for bad_name in ('../escape', 'META-INF/../../outside',
                         '/absolute', 'C:/drive', 'META-INF\\evil',
                         'META-INF/./normalized'):
            with self.subTest(name=bad_name):
                with zipfile.ZipFile(jar, 'w') as archive:
                    archive.writestr(WRAPPER_MAIN, b'\xca\xfe\xba\xbevalid')
                    archive.writestr(bad_name, b'other')
                self.assertTrue(any(
                    'Gradle-Wrapper-JAR' in msg for msg in verify_project(self.root)
                ))

    def test_symlink_wrapper_member_is_rejected(self):
        jar = self.root / 'app/android/gradle/wrapper/gradle-wrapper.jar'
        link = zipfile.ZipInfo('META-INF/short-cut')
        link.create_system = 3
        link.external_attr = (stat.S_IFLNK | 0o777) << 16
        with zipfile.ZipFile(jar, 'w') as archive:
            archive.writestr(WRAPPER_MAIN, b'\xca\xfe\xba\xbevalid')
            archive.writestr(link, '../outside')
        self.assertTrue(any(
            'Gradle-Wrapper-JAR' in msg for msg in verify_project(self.root)
        ))

    def test_normal_wrapper_jar_directory_is_allowed(self):
        jar = self.root / 'app/android/gradle/wrapper/gradle-wrapper.jar'
        with zipfile.ZipFile(jar, 'w') as archive:
            archive.writestr('META-INF/', b'')
            archive.writestr(WRAPPER_MAIN, b'\xca\xfe\xba\xbevalid')
        self.assertEqual([], verify_project(self.root))

    def test_oversized_wrapper_jar_is_rejected_before_zip_open(self):
        jar = self.root / 'app/android/gradle/wrapper/gradle-wrapper.jar'
        # A sparse file avoids allocating a large payload for the negative test.
        with jar.open('wb') as stream:
            stream.seek(MAX_WRAPPER_JAR_BYTES)
            stream.write(b'0')
        with mock.patch.object(zipfile, 'ZipFile',
                               side_effect=AssertionError('unexpected ZIP parsing')):
            errors = verify_project(self.root)
        self.assertTrue(any('Gradle-Wrapper-JAR' in msg for msg in errors))

    def test_compressed_wrapper_zip_bomb_is_rejected_before_crc_decompression(self):
        jar = self.root / 'app/android/gradle/wrapper/gradle-wrapper.jar'
        with zipfile.ZipFile(jar, 'w', zipfile.ZIP_DEFLATED) as archive:
            archive.writestr(WRAPPER_MAIN, b'\\xca\\xfe\\xba\\xbevalid')
            archive.writestr('META-INF/oversized.bin',
                             b'x' * (MAX_WRAPPER_UNCOMPRESSED_BYTES + 1))
        # Fail closed before reading even the first CRC chunk of this ZIP bomb.
        with mock.patch.object(zipfile.ZipFile, 'testzip',
                               side_effect=AssertionError('unexpected decompression')):
            errors = verify_project(self.root)
        self.assertTrue(any('Gradle-Wrapper-JAR' in msg for msg in errors))

    def test_wrapper_with_excessive_member_count_is_rejected_before_crc(self):
        jar = self.root / 'app/android/gradle/wrapper/gradle-wrapper.jar'
        with zipfile.ZipFile(jar, 'w') as archive:
            archive.writestr(WRAPPER_MAIN, b'\\xca\\xfe\\xba\\xbevalid')
            for index in range(MAX_WRAPPER_ENTRIES):
                archive.writestr(f'META-INF/extra-{index}.txt', b'x')
        with mock.patch.object(zipfile.ZipFile, 'testzip',
                               side_effect=AssertionError('unexpected decompression')):
            errors = verify_project(self.root)
        self.assertTrue(any('Gradle-Wrapper-JAR' in msg for msg in errors))

    def test_existing_wrapper_jar_stays_within_validation_limits(self):
        jar = ROOT / 'app/android/gradle/wrapper/gradle-wrapper.jar'
        with zipfile.ZipFile(jar) as archive:
            self.assertLessEqual(len(archive.infolist()), MAX_WRAPPER_ENTRIES)
            self.assertLessEqual(sum(info.file_size for info in archive.infolist()),
                                 MAX_WRAPPER_UNCOMPRESSED_BYTES)
        self.assertEqual([], verify_project(self.root))

    def test_start_class_replaced_by_text_is_rejected(self):
        path = self.root / 'app/android/gradle/wrapper/gradle-wrapper.jar'
        with zipfile.ZipFile(path, 'w') as archive:
            archive.writestr(WRAPPER_MAIN, 'incorrect upload')
        self.assertTrue(any('Gradle-Wrapper-JAR' in error for error in verify_project(self.root)))

    def test_changed_jar_bytes_fail_crc_validation(self):
        path = self.root / 'app/android/gradle/wrapper/gradle-wrapper.jar'
        with zipfile.ZipFile(path, 'w', zipfile.ZIP_STORED) as archive:
            archive.writestr(WRAPPER_MAIN, b'\xca\xfe\xba\xbeoriginal')
        content = path.read_bytes().replace(b'original', b'modified')
        path.write_bytes(content)
        self.assertTrue(any('Gradle-Wrapper-JAR' in error for error in verify_project(self.root)))

    def test_damaged_compressed_jar_has_actionable_error(self):
        path = self.root / 'app/android/gradle/wrapper/gradle-wrapper.jar'
        with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED) as archive:
            archive.writestr(WRAPPER_MAIN, b'\xca\xfe\xba\xbe' + b'original' * 100)
        content = bytearray(path.read_bytes())
        # The first local ZIP header contains no extra fields; corrupt deflate data.
        content[30 + len(WRAPPER_MAIN)] = 0xff
        path.write_bytes(content)
        self.assertTrue(any('Gradle-Wrapper-JAR' in error for error in verify_project(self.root)))

    def test_distribution_requires_checksum_and_fixed_https_version(self):
        path = self.root / 'app/android/gradle/wrapper/gradle-wrapper.properties'
        path.write_text('distributionUrl=http://example.test/gradle-latest-all.zip\n')
        errors = verify_project(self.root)
        self.assertTrue(any('prüfsumme' in error for error in errors))
        self.assertTrue(any('HTTPS-Distribution' in error for error in errors))


    def test_duplicate_distribution_url_is_rejected_before_gradle_runs(self):
        path = self.root / 'app/android/gradle/wrapper/gradle-wrapper.properties'
        path.write_text(path.read_text() +
                        'distributionUrl=http://untrusted.example/gradle-8.12-all.zip\n')
        errors = verify_project(self.root)
        self.assertTrue(any('HTTPS-Distribution' in error for error in errors))

    def test_duplicate_checksum_is_rejected_even_if_values_match(self):
        path = self.root / 'app/android/gradle/wrapper/gradle-wrapper.properties'
        original = path.read_text()
        checksum = next(line for line in original.splitlines()
                        if line.startswith('distributionSha256Sum='))
        path.write_text(original + checksum + '\n')
        errors = verify_project(self.root)
        self.assertTrue(any('prüfsumme' in error for error in errors))

    def test_mixed_gradle_properties_separators_still_detect_duplicates(self):
        path = self.root / 'app/android/gradle/wrapper/gradle-wrapper.properties'
        content = path.read_text()
        path.write_text(content +
                        'distributionUrl : https://services.gradle.org/distributions/gradle-8.13-bin.zip\n'
                        'distributionSha256Sum ' + 'a' * 64 + '\n')
        errors = verify_project(self.root)
        self.assertTrue(any('HTTPS-Distribution' in error for error in errors))
        self.assertTrue(any('prüfsumme' in error for error in errors))

    def test_comments_do_not_count_as_duplicate_gradle_properties(self):
        path = self.root / 'app/android/gradle/wrapper/gradle-wrapper.properties'
        path.write_text(path.read_text() +
                        '# distributionUrl=http://invalid.example/gradle-8.12-bin.zip\n'
                        '! distributionSha256Sum=not-a-checksum\n')
        self.assertEqual([], verify_project(self.root))

    def test_single_unescaped_https_url_and_valid_checksum_are_allowed(self):
        path = self.root / 'app/android/gradle/wrapper/gradle-wrapper.properties'
        current = path.read_text()
        path.write_text(current.replace('https\\:', 'https:'))
        self.assertEqual([], verify_project(self.root))

    def test_empty_second_distribution_value_is_rejected(self):
        path = self.root / 'app/android/gradle/wrapper/gradle-wrapper.properties'
        path.write_text(path.read_text() + 'distributionUrl\n')
        self.assertTrue(any(
            'HTTPS-Distribution' in msg for msg in verify_project(self.root)
        ))

    def test_unicode_escaped_distribution_url_key_is_duplicate(self):
        properties = self.root / 'app/android/gradle/wrapper/gradle-wrapper.properties'
        properties.write_text(
            properties.read_text() +
            r'distribution\u0055rl=http://untrusted.invalid/gradle-8.12-all.zip' + '\n'
        )
        self.assertTrue(any(
            'HTTPS-Distribution' in error for error in verify_project(self.root)
        ))

    def test_unicode_escaped_checksum_key_is_duplicate(self):
        properties = self.root / 'app/android/gradle/wrapper/gradle-wrapper.properties'
        properties.write_text(
            properties.read_text() +
            r'distributionSha256S\u0075m=' + 'a' * 64 + '\n'
        )
        self.assertTrue(any(
            'prüfsumme' in error for error in verify_project(self.root)
        ))

    def test_simple_escaped_first_letter_is_duplicate(self):
        properties = self.root / 'app/android/gradle/wrapper/gradle-wrapper.properties'
        properties.write_text(
            properties.read_text() +
            r'\distributionUrl=http://untrusted.invalid/gradle-8.12-all.zip' + '\n'
        )
        self.assertTrue(any(
            'HTTPS-Distribution' in error for error in verify_project(self.root)
        ))

    def test_continued_distribution_key_is_duplicate(self):
        properties = self.root / 'app/android/gradle/wrapper/gradle-wrapper.properties'
        properties.write_text(
            properties.read_text() +
            'distributionU\\\n   rl=http://untrusted.invalid/gradle-8.12-all.zip\n'
        )
        self.assertTrue(any(
            'HTTPS-Distribution' in error for error in verify_project(self.root)
        ))

    def test_escaped_colon_in_other_key_is_not_a_duplicate(self):
        properties = self.root / 'app/android/gradle/wrapper/gradle-wrapper.properties'
        properties.write_text(
            properties.read_text() +
            r'distributionUrl\:=not-the-distribution-url' + '\n'
        )
        self.assertEqual([], verify_project(self.root))

    def test_single_unicode_escaped_key_stays_valid(self):
        properties = self.root / 'app/android/gradle/wrapper/gradle-wrapper.properties'
        content = properties.read_text()
        self.assertIn('distributionUrl=', content)
        properties.write_text(
            content.replace('distributionUrl=', r'distribution\u0055rl=')
        )
        self.assertEqual([], verify_project(self.root))

    def test_comments_with_escaped_key_names_stay_ignored(self):
        properties = self.root / 'app/android/gradle/wrapper/gradle-wrapper.properties'
        properties.write_text(
            properties.read_text() +
            '# ' + r'distribution\u0055rl=http://ignored.invalid' + '\n' +
            '! ' + r'distributionSha256S\u0075m=ignored' + '\n'
        )
        self.assertEqual([], verify_project(self.root))

    def test_continuation_with_even_backslashes_is_not_combined(self):
        properties = self.root / 'app/android/gradle/wrapper/gradle-wrapper.properties'
        properties.write_text(
            properties.read_text() +
            'unusedValue=two\\\\\n'
            '   safeSubkey=ok\n'
        )
        self.assertEqual([], verify_project(self.root))

    def test_windows_shebang_is_rejected(self):
        (self.root / 'app/android/gradlew').write_bytes(b'#!/usr/bin/env bash\r\n')
        self.assertTrue(any('LF-Zeilenende' in error for error in verify_project(self.root)))

    def test_cli_nonzero_for_missing_directory_with_german_message(self):
        result = subprocess.run(
            [sys.executable, str(ROOT / 'scripts/verify_project.py'), str(self.root / 'absent')],
            capture_output=True, text=True, check=False,
        )
        self.assertEqual(result.returncode, 1)
        self.assertIn('Projektübertragung unvollständig', result.stderr)
        self.assertIn('existiert nicht', result.stderr)

    def test_cli_success_without_build_tools(self):
        result = subprocess.run(
            [sys.executable, str(ROOT / 'scripts/verify_project.py'), str(self.root)],
            capture_output=True, text=True, check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('vollständig', result.stdout)


if __name__ == '__main__':
    unittest.main()
