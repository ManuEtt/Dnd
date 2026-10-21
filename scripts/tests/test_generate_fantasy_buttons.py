"""Regression tests for reproducible, standalone fantasy PNG generation."""
import importlib.util
import struct
import tempfile
import unittest
from pathlib import Path

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
                    expected = (64, 64) if any(
                        image.name.startswith(f"btn_{prefix}_")
                        for prefix in ("dice", "icon_gold")
                    ) else (192, 64)
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


if __name__ == "__main__":
    unittest.main()
