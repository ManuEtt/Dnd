"""Regression tests for reproducible, standalone fantasy PNG generation."""
import importlib.util
import os
import struct
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

SCRIPT = Path(__file__).resolve().parents[1] / "generate_fantasy_buttons.py"
spec = importlib.util.spec_from_file_location("fantasy_buttons_generator", SCRIPT)
generator = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(generator)


class FantasyButtonArtTests(unittest.TestCase):
    def test_all_visual_states_generate_valid_rgba_pngs(self):
        with tempfile.TemporaryDirectory() as temp:
            original = generator.ROOT
            generator.ROOT = Path(temp)
            try:
                generator.main()
                files = sorted(Path(temp).glob("*.png"))
                self.assertEqual(len(files), 30)
                self.assertEqual(len({p.name for p in files}), len(files))
                for image in files:
                    data = image.read_bytes()
                    self.assertTrue(data.startswith(b"\x89PNG\r\n\x1a\n"))
                    width, height = struct.unpack("!2I", data[16:24])
                    # Only icon-only art is square. Labeled W4-W100 buttons
                    # need wide 9-slice-safe textures for readable text.
                    expected = (
                        (64, 64)
                        if image.name.startswith("btn_icon_gold_")
                        else (192, 64)
                    )
                    self.assertEqual((width, height), expected)
                    self.assertGreater(len(data), 300)
                first = (Path(temp) / "btn_wood_gold_pressed.png").read_bytes()
                generator.main()
                self.assertEqual(
                    (Path(temp) / "btn_wood_gold_pressed.png").read_bytes(),
                    first,
                )
            finally:
                generator.ROOT = original


    @unittest.skipIf(sys.platform == "win32", "POSIX symlinks required")
    def test_symlinked_destination_directory_is_rejected_without_external_writes(self):
        with tempfile.TemporaryDirectory() as temp:
            base = Path(temp)
            outside = base / "external"
            outside.mkdir()
            link = base / "linked-buttons"
            link.symlink_to(outside, target_is_directory=True)
            with mock.patch.object(generator, "ROOT", link):
                with self.assertRaisesRegex(ValueError, "symlink"):
                    generator.main()
            self.assertEqual(list(outside.iterdir()), [])

    @unittest.skipIf(sys.platform == "win32", "POSIX symlinks required")
    def test_symlinked_parent_is_rejected_before_creating_child_directory(self):
        with tempfile.TemporaryDirectory() as temp:
            base = Path(temp)
            outside = base / "external"
            outside.mkdir()
            link = base / "art"
            link.symlink_to(outside, target_is_directory=True)
            with mock.patch.object(generator, "ROOT", link / "buttons"):
                with self.assertRaisesRegex(ValueError, "symlink"):
                    generator.main()
            self.assertFalse((outside / "buttons").exists())

    @unittest.skipIf(sys.platform == "win32", "POSIX symlinks required")
    def test_symlinked_png_is_rejected_without_overwriting_external_file(self):
        with tempfile.TemporaryDirectory() as temp:
            base = Path(temp)
            destination = base / "buttons"
            destination.mkdir()
            external = base / "external.png"
            external.write_bytes(b"protected")
            (destination / "btn_wood_gold_normal.png").symlink_to(external)
            with (mock.patch.object(generator, "ROOT", destination),
                  mock.patch.object(generator, "STYLES", {"wood_gold": generator.STYLES["wood_gold"]}),
                  mock.patch.object(generator, "STATES", ("normal",))):
                with self.assertRaisesRegex(ValueError, "symlink"):
                    generator.main()
            self.assertEqual(external.read_bytes(), b"protected")
            self.assertTrue((destination / "btn_wood_gold_normal.png").is_symlink())

    def test_failed_atomic_publish_preserves_previous_png_and_cleans_staging(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            target = root / "button.png"
            target.write_bytes(b"previous-good-png")
            with mock.patch.object(generator.os, "replace", side_effect=OSError("write failed")):
                with self.assertRaisesRegex(OSError, "write failed"):
                    generator._write_png(target, b"new-complete-png")
            self.assertEqual(target.read_bytes(), b"previous-good-png")
            self.assertEqual([p.name for p in root.iterdir()], ["button.png"])

    def test_non_regular_png_output_does_not_get_replaced(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            target = root / "button.png"
            target.mkdir()
            with self.assertRaisesRegex(ValueError, "not a regular file"):
                generator._write_png(target, b"content")
            self.assertTrue(target.is_dir())


if __name__ == "__main__":
    unittest.main()
