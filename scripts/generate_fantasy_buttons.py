#!/usr/bin/env python3
"""Generate original transparent Fantasy Button PNGs without dependencies.

Run from repository root: python3 scripts/generate_fantasy_buttons.py
Each wide 192x64 PNG has a safe 24px left/right and 20px top/bottom
9-slice edge. No text is baked into the graphic; Flutter supplies labels.
"""
from __future__ import annotations

import math
import os
import stat
import struct
import tempfile
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "app/assets/fantasy/buttons"
STYLES = {
    "wood_gold": ((74, 42, 24), (218, 177, 95)),
    "rune_arcane": ((17, 48, 74), (95, 190, 237)),
    "iron": ((38, 51, 60), (178, 183, 173)),
    "wax": ((91, 29, 34), (215, 101, 83)),
    "dice": ((19, 46, 78), (230, 185, 89)),
    "icon_gold": ((64, 39, 25), (218, 177, 95)),
}
STATES = ("normal", "hover", "pressed", "active", "disabled")


def _mix(a: tuple[int, int, int], b: tuple[int, int, int], t: float):
    return tuple(max(0, min(255, round(x * (1 - t) + y * t))) for x, y in zip(a, b))


def _png(width: int, height: int, data: bytes) -> bytes:
    def chunk(tag: bytes, payload: bytes) -> bytes:
        return (
            struct.pack("!I", len(payload))
            + tag
            + payload
            + struct.pack("!I", zlib.crc32(tag + payload) & 0xFFFFFFFF)
        )

    rows = b"".join(
        b"\x00" + data[row * width * 4 : (row + 1) * width * 4]
        for row in range(height)
    )
    return (
        b"\x89PNG\r\n\x1a\n"
        + chunk(b"IHDR", struct.pack("!2I5B", width, height, 8, 6, 0, 0, 0))
        + chunk(b"IDAT", zlib.compress(rows, 9))
        + chunk(b"IEND", b"")
    )


def draw(style: str, state: str) -> bytes:
    # Dice buttons have a label and therefore need wide, 9-slice-safe frames.
    square = style == "icon_gold"
    width, height = (64, 64) if square else (192, 64)
    base, metal = STYLES[style]
    if state == "disabled":
        base = _mix(base, (70, 70, 70), 0.82)
        metal = _mix(metal, (103, 105, 108), 0.85)
    elif state in ("pressed", "active"):
        base = _mix(base, metal, 0.24)
    elif state == "hover":
        base = _mix(base, metal, 0.12)

    glow = state in ("hover", "pressed", "active")
    image = bytearray()
    radius = 11
    seed = len(style) * 17 + len(state) * 31
    for y in range(height):
        for x in range(width):
            dx = max(0, radius - x, x - (width - 1 - radius))
            dy = max(0, radius - y, y - (height - 1 - radius))
            if dx * dx + dy * dy > radius * radius:
                image.extend((0, 0, 0, 0))
                continue
            inset = min(x, y, width - 1 - x, height - 1 - y)
            noise = ((x * 103 + y * 71 + seed * 29) ^ (x * y * 3)) & 15
            wood = math.sin(y * 0.51 + math.sin(x * 0.08) * 2)
            light = (height - y) / height
            tone = max(-.14, min(.28, (light - .5) * .3 + (noise - 7) / 115 + wood / 48))
            rgb = _mix(base, metal, max(0, tone))
            if tone < 0:
                rgb = _mix(rgb, (0, 0, 0), -tone)
            if inset <= 2:
                rgb = metal if inset == 1 else _mix(metal, (15, 11, 9), .45)
            elif inset in (4, 5):
                rgb = _mix(base, metal, .52)
            elif glow and inset < 8:
                rgb = _mix(rgb, metal, .42)
            # Engraved top/bottom grooves remain inside the fixed slice.
            if 8 <= x < width - 8 and y in (9, height - 10):
                rgb = _mix(rgb, metal, .22)
            # End-cap rivets: safe for 9-slice stretching.
            for cx in (12, width - 13):
                dist = math.hypot(x - cx, y - height / 2)
                if dist < 3.6:
                    rgb = _mix(base, metal, .85 if dist < 2.3 else .28)
            # Geometric arcane seal behind the icon, no baked-in label.
            if square:
                d = math.hypot(x - width / 2, y - height / 2)
                if 22 <= d <= 23.5:
                    rgb = _mix(rgb, metal, .75)
                elif 15 <= d < 15.9 and (x + y) % 3 != 0:
                    rgb = _mix(rgb, metal, .33)
            image.extend((*rgb, 255))
    return _png(width, height, bytes(image))


def _reject_symlink_path(path: Path) -> None:
    """Do not generate through any pre-existing symlinked path component."""
    for component in (path, *path.parents):
        if component.is_symlink():
            raise ValueError(f"Fantasy button output contains a symlink: {component}")


def _write_png(path: Path, data: bytes) -> None:
    """Stage complete PNG bytes before atomically replacing a regular output."""
    _reject_symlink_path(path)
    if path.exists() and not path.is_file():
        raise ValueError(f"Fantasy button output is not a regular file: {path}")
    staged = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="wb", prefix=f".{path.name}.", suffix=".tmp",
            dir=path.parent, delete=False,
        ) as stream:
            staged = Path(stream.name)
            stream.write(data)
        # On failure, do not damage a previously generated PNG or leave
        # a partial PNG behind. A late leaf symlink is rejected before rename.
        _reject_symlink_path(path)
        if path.exists() and not path.is_file():
            raise ValueError(f"Fantasy button output is not a regular file: {path}")
        previous_mode = stat.S_IMODE(path.stat().st_mode) if path.exists() else 0o644
        staged.chmod(previous_mode)
        os.replace(staged, path)
    finally:
        if staged is not None:
            staged.unlink(missing_ok=True)


def main() -> None:
    # mkdir(parents=True) itself could otherwise create directories through a
    # symlinked ancestor outside the selected asset tree.
    _reject_symlink_path(ROOT)
    ROOT.mkdir(parents=True, exist_ok=True)
    _reject_symlink_path(ROOT)
    for style in STYLES:
        for state in STATES:
            out = ROOT / f"btn_{style}_{state}.png"
            _reject_symlink_path(out)
            _write_png(out, draw(style, state))
            print(out.name)
    print(f"Generated {len(STYLES) * len(STATES)} transparent images.")


if __name__ == "__main__":
    main()
