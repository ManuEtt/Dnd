"""Regression tests for the deterministic, transparent fantasy button pack."""
from __future__ import annotations

import importlib.util
import struct
import unittest
import zlib
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "generate_fantasy_buttons.py"
spec = importlib.util.spec_from_file_location("fantasy_button_generator", SCRIPT)
assert spec is not None and spec.loader is not None
generator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(generator)


def png_info(png: bytes) -> tuple[int, int, bytes]:
    assert png[:8] == b"\x89PNG\r\n\x1a\n"
    width, height = struct.unpack("!II", png[16:24])
    chunks: list[bytes] = []
    offset = 8
    while offset < len(png):
        count = struct.unpack("!I", png[offset : offset + 4])[0]
        tag = png[offset + 4 : offset + 8]
        data = png[offset + 8 : offset + 8 + count]
        if tag == b"IDAT":
            chunks.append(data)
        offset += 12 + count
    return width, height, zlib.decompress(b"".join(chunks))


class FantasyButtonAssetsTest(unittest.TestCase):
    def test_six_styles_have_five_distinct_states(self) -> None:
        self.assertEqual(len(generator.STYLES), 6)
        self.assertEqual(len(generator.STATES), 5)
        for style in generator.STYLES:
            bitmaps = [generator.draw(style, state) for state in generator.STATES]
            self.assertEqual(len(set(bitmaps)), 5, msg=style)

    def test_wide_dice_buttons_are_safe_for_nine_slice(self) -> None:
        for style in generator.STYLES:
            for state in generator.STATES:
                width, height, pixels = png_info(generator.draw(style, state))
                expected_width = 64 if style == "icon_gold" else 192
                self.assertEqual((width, height), (expected_width, 64))
                self.assertEqual(len(pixels), height * (width * 4 + 1))
                self.assertTrue(pixels.startswith(b"\x00"))
                # A rounded button must have transparent corners.
                self.assertEqual(pixels[1 + 3], 0, msg=f"{style} {state}")

    def test_source_frame_is_deterministic(self) -> None:
        first = generator.draw("dice", "pressed")
        second = generator.draw("dice", "pressed")
        self.assertEqual(first, second)


if __name__ == "__main__":
    unittest.main()
