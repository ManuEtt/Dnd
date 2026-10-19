"""Tests for the optional, verified original artwork ZIP importer."""
import hashlib
import importlib.util
import json
import pathlib
import tempfile
import unittest
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
        payload = b"RIFF" + b"\\x04\\x00\\x00\\x00" + b"WEBP"
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

    def test_corrupt_zip_asset_is_rejected(self):
        self._make_archive(corrupt=MODULE.ASSETS[4])
        with self.assertRaises(ValueError):
            MODULE.imported_assets(self.archive, self.root)


if __name__ == "__main__":
    unittest.main()
