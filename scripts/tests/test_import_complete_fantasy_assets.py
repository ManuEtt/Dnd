"""Tests for the optional, verified original artwork ZIP importer."""
import hashlib
import importlib.util
import json
import pathlib
import tempfile
import unittest
import warnings
from unittest import mock
import zipfile

SCRIPT = pathlib.Path(__file__).resolve().parents[1] / "import_complete_fantasy_assets.py"
SPEC = importlib.util.spec_from_file_location("fantasy_import", SCRIPT)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class FantasyImportTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = pathlib.Path(self.temp.name)
        self.archive = self.root / "approved.zip"

    def _make_archive(self, corrupt=None):
        payload = b"RIFF" + bytes([4, 0, 0, 0]) + b"WEBP"
        manifest = {}
        with zipfile.ZipFile(self.archive, "w") as z:
            for name in MODULE.ASSETS:
                path = MODULE.PREFIX + name
                filedata = payload + (b"oops" if name == corrupt else b"")
                z.writestr(path, filedata)
                manifest[path] = {
                    "sha256": hashlib.sha256(payload).hexdigest(),
                    "bytes": len(payload),
                }
            z.writestr(MODULE.MANIFEST, json.dumps(manifest))
        return payload

    def test_import_and_reimport_idempotent(self):
        payload = self._make_archive()
        first = MODULE.imported_assets(self.archive, self.root)
        self.assertEqual(len(first), 13)
        for path, data in first:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
        self.assertEqual((self.root / MODULE.PREFIX / MODULE.ASSETS[0]).read_bytes(), payload)
        self.assertEqual(len(MODULE.imported_assets(self.archive, self.root)), 13)

    def test_modified_original_is_rejected(self):
        self._make_archive()
        destination = self.root / MODULE.PREFIX / MODULE.ASSETS[0]
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_bytes(b"do not overwrite")
        with self.assertRaises(FileExistsError):
            MODULE.imported_assets(self.archive, self.root)
        self.assertEqual(destination.read_bytes(), b"do not overwrite")

    def test_main_import_and_reimport_write_only_regular_assets(self):
        payload = self._make_archive()
        destination = self.root / "project"
        self.assertEqual(
            MODULE.main([str(self.archive), "--target", str(destination)]), 0
        )
        asset = destination / MODULE.PREFIX / MODULE.ASSETS[0]
        self.assertEqual(asset.read_bytes(), payload)
        self.assertFalse(asset.is_symlink())
        self.assertEqual(
            MODULE.main([str(self.archive), "--target", str(destination)]), 0
        )

    def test_symlinked_asset_directory_is_rejected_before_writing(self):
        self._make_archive()
        destination = self.root / "project"
        outside = self.root / "elsewhere"
        outside.mkdir()
        fantasy = destination / MODULE.PREFIX.rstrip("/")
        fantasy.parent.mkdir(parents=True)
        fantasy.symlink_to(outside, target_is_directory=True)

        with self.assertRaisesRegex(ValueError, "Symlink"):
            MODULE.imported_assets(self.archive, destination)
        self.assertEqual(
            MODULE.main([str(self.archive), "--target", str(destination)]), 1
        )
        self.assertEqual(list(outside.iterdir()), [])

    def test_dangling_symlinked_asset_is_rejected_before_writing(self):
        self._make_archive()
        destination = self.root / "project"
        outside = self.root / "elsewhere"
        outside.mkdir()
        fantasy = destination / MODULE.PREFIX.rstrip("/")
        fantasy.mkdir(parents=True)
        escaped = outside / "escaped.webp"
        (fantasy / MODULE.ASSETS[0]).symlink_to(escaped)

        with self.assertRaisesRegex(ValueError, "Symlink"):
            MODULE.imported_assets(self.archive, destination)
        self.assertEqual(
            MODULE.main([str(self.archive), "--target", str(destination)]), 1
        )
        self.assertFalse(escaped.exists())

    def test_symlinked_target_root_is_rejected(self):
        self._make_archive()
        outside = self.root / "real-project"
        outside.mkdir()
        alias = self.root / "project-alias"
        alias.symlink_to(outside, target_is_directory=True)
        with self.assertRaisesRegex(ValueError, "Symlink"):
            MODULE.imported_assets(self.archive, alias)
        self.assertEqual(
            MODULE.main([str(self.archive), "--target", str(alias)]), 1
        )
        self.assertFalse((outside / MODULE.PREFIX).exists())

    def test_corrupt_zip_asset_is_rejected(self):
        self._make_archive(corrupt=MODULE.ASSETS[4])
        with self.assertRaises(ValueError):
            MODULE.imported_assets(self.archive, self.root)



    def test_excess_zip_entries_are_rejected_before_crc_scan(self):
        self._make_archive()
        with zipfile.ZipFile(self.archive) as archive:
            original_count = len(archive.infolist())
        with zipfile.ZipFile(self.archive, "a") as archive:
            archive.writestr("unrelated/extra.bin", b"new")
        with (mock.patch.object(MODULE, "MAX_ZIP_ENTRIES", original_count),
              mock.patch.object(zipfile.ZipFile, "testzip",
                                side_effect=AssertionError("ZIP scan started"))):
            with self.assertRaisesRegex(ValueError, "zu viele oder zu grosse"):
                MODULE.imported_assets(self.archive, self.root)

    def test_excess_total_expanded_size_is_rejected_before_crc_scan(self):
        self._make_archive()
        with zipfile.ZipFile(self.archive) as archive:
            original_bytes = sum(entry.file_size for entry in archive.infolist())
        with zipfile.ZipFile(self.archive, "a") as archive:
            archive.writestr("unrelated/extra.bin", b"more")
        with (mock.patch.object(
                MODULE, "MAX_ZIP_UNCOMPRESSED_BYTES", original_bytes + 1
              ),
              mock.patch.object(zipfile.ZipFile, "testzip",
                                side_effect=AssertionError("ZIP scan started"))):
            with self.assertRaisesRegex(ValueError, "zu viele oder zu grosse"):
                MODULE.imported_assets(self.archive, self.root)

    def test_oversized_manifest_is_rejected_before_crc_scan(self):
        self._make_archive()
        with (mock.patch.object(MODULE, "MAX_MANIFEST_BYTES", 32),
              mock.patch.object(zipfile.ZipFile, "testzip",
                                side_effect=AssertionError("ZIP scan started"))):
            with self.assertRaisesRegex(ValueError, "zu gross"):
                MODULE.imported_assets(self.archive, self.root)

    def test_oversized_artwork_declaration_is_rejected_before_crc_scan(self):
        self._make_archive()
        with (mock.patch.object(MODULE, "MAX_ASSET_BYTES", 8),
              mock.patch.object(zipfile.ZipFile, "testzip",
                                side_effect=AssertionError("ZIP scan started"))):
            with self.assertRaisesRegex(ValueError, "ausserhalb des Limits"):
                MODULE.imported_assets(self.archive, self.root)

    def test_duplicate_zip_names_are_rejected_without_importing(self):
        payload = self._make_archive()
        with warnings.catch_warnings():
            warnings.simplefilter("ignore", UserWarning)
            with zipfile.ZipFile(self.archive, "a") as archive:
                archive.writestr(MODULE.PREFIX + MODULE.ASSETS[0], payload)
        with (mock.patch.object(zipfile.ZipFile, "testzip",
                                side_effect=AssertionError("ZIP scan started"))):
            with self.assertRaisesRegex(ValueError, "doppelte Dateinamen"):
                MODULE.imported_assets(self.archive, self.root)
        self.assertFalse((self.root / MODULE.PREFIX).exists())

    def test_non_object_manifest_is_rejected_without_importing(self):
        with zipfile.ZipFile(self.archive, "w") as archive:
            archive.writestr(MODULE.MANIFEST, '["not a manifest"]')
        with self.assertRaisesRegex(ValueError, "muss ein Objekt sein"):
            MODULE.imported_assets(self.archive, self.root)
        self.assertEqual(
            MODULE.main([str(self.archive), "--target", str(self.root / "project")]),
            1,
        )
        self.assertFalse((self.root / "project").exists())



    def test_interrupted_disk_write_never_publishes_partial_image(self):
        payload = self._make_archive()
        target = self.root / "project"
        image_dir = target / MODULE.PREFIX.rstrip("/")
        with mock.patch.object(
            MODULE.os, "fsync", side_effect=OSError("simulated full disk")
        ):
            self.assertEqual(
                MODULE.main([str(self.archive), "--target", str(target)]), 1
            )
        self.assertFalse((image_dir / MODULE.ASSETS[0]).exists())
        self.assertEqual(list(image_dir.glob("*.partial")), [])
        self.assertEqual(list(image_dir.glob(".*.partial")), [])

        # A failed attempt has not poisoned the next import.
        self.assertEqual(
            MODULE.main([str(self.archive), "--target", str(target)]), 0
        )
        self.assertEqual((image_dir / MODULE.ASSETS[0]).read_bytes(), payload)

    def test_late_competing_target_is_never_overwritten(self):
        self._make_archive()
        target = self.root / "project"
        image_dir = target / MODULE.PREFIX.rstrip("/")
        original_link = MODULE.os.link
        rival = b"competing writer's original artwork"

        def competing_link(source, destination):
            pathlib.Path(destination).write_bytes(rival)
            return original_link(source, destination)

        with mock.patch.object(MODULE.os, "link", side_effect=competing_link):
            self.assertEqual(
                MODULE.main([str(self.archive), "--target", str(target)]), 1
            )
        self.assertEqual((image_dir / MODULE.ASSETS[0]).read_bytes(), rival)
        self.assertEqual(list(image_dir.glob(".*.partial")), [])

    def test_changed_existing_asset_after_preflight_is_rejected(self):
        self._make_archive()
        target = self.root / "project"
        image = target / MODULE.PREFIX / MODULE.ASSETS[0]
        original_preflight = MODULE.imported_assets

        def create_rival_after_preflight(*args):
            validated = original_preflight(*args)
            image.parent.mkdir(parents=True, exist_ok=True)
            image.write_bytes(b"modified after validation")
            return validated

        with mock.patch.object(
            MODULE, "imported_assets", side_effect=create_rival_after_preflight
        ):
            self.assertEqual(
                MODULE.main([str(self.archive), "--target", str(target)]), 1
            )
        self.assertEqual(image.read_bytes(), b"modified after validation")
        self.assertEqual(list(image.parent.glob(".*.partial")), [])

    def test_later_publication_failure_allows_idempotent_resume(self):
        payload = self._make_archive()
        target = self.root / "project"
        image_dir = target / MODULE.PREFIX.rstrip("/")
        original_link = MODULE.os.link
        attempts = 0

        def fail_second_link(source, destination):
            nonlocal attempts
            attempts += 1
            if attempts == 2:
                raise OSError("simulated link publication failure")
            return original_link(source, destination)

        with mock.patch.object(MODULE.os, "link", side_effect=fail_second_link):
            self.assertEqual(
                MODULE.main([str(self.archive), "--target", str(target)]), 1
            )
        self.assertEqual(attempts, 2)
        self.assertEqual((image_dir / MODULE.ASSETS[0]).read_bytes(), payload)
        self.assertFalse((image_dir / MODULE.ASSETS[1]).exists())
        self.assertEqual(list(image_dir.glob(".*.partial")), [])

        self.assertEqual(
            MODULE.main([str(self.archive), "--target", str(target)]), 0
        )
        self.assertEqual(
            {file.name for file in image_dir.glob("*.webp")}, set(MODULE.ASSETS)
        )
        self.assertEqual(list(image_dir.glob(".*.partial")), [])

if __name__ == "__main__":
    unittest.main()
