#!/usr/bin/env python3
"""Import the approved Würfelraunen fantasy ZIP without touching user saves.

Usage: python3 scripts/import_fantasy_assets.py <zip> [--dry-run]
"""
import argparse
import hashlib
import json
from pathlib import Path
from zipfile import ZipFile, BadZipFile

NAMES = (
    *(f"app/assets/fantasy/portrait_{number}.webp" for number in range(1, 10)),
    "app/assets/fantasy/ornate_button_background.webp",
    "app/assets/fantasy/ornate_card_background.webp",
    "app/assets/fantasy/ornate_panel_background.webp",
    "app/assets/fantasy/ornate_portrait_border.webp",
)
MANIFEST = "docs/graphics/GRAFIK_MANIFEST.json"


def install(source: Path, destination: Path, dry_run: bool = False) -> list[str]:
    """Validate all binary assets first; never replace unlike existing files."""
    if not source.is_file():
        raise FileNotFoundError(source)
    if not (destination / "app" / "pubspec.yaml").is_file():
        raise ValueError(f"No Flutter project at {destination}")
    with ZipFile(source) as archive:
        if archive.testzip() is not None:
            raise BadZipFile("Asset ZIP failed CRC verification")
        manifest = json.loads(archive.read(MANIFEST))
        pending = []
        for relative in NAMES:
            payload = archive.read(relative)
            expected = manifest.get(relative)
            digest = hashlib.sha256(payload).hexdigest()
            if expected is None or digest != expected["sha256"] or len(payload) != expected["bytes"]:
                raise ValueError(f"Manifest mismatch: {relative}")
            if len(payload) < 12 or payload[:4] != b"RIFF" or payload[8:12] != b"WEBP":
                raise ValueError(f"Invalid WebP image: {relative}")
            target = destination / relative
            if target.exists():
                if target.read_bytes() != payload:
                    raise FileExistsError(f"Existing asset differs; refusing to overwrite: {target}")
                continue
            pending.append((target, payload))
        if not dry_run:
            for target, payload in pending:
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes(payload)
        return [str(target.relative_to(destination)) for target, _ in pending]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("zip_file", type=Path)
    parser.add_argument("--repo-root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--dry-run", action="store_true")
    arguments = parser.parse_args()
    files = install(arguments.zip_file, arguments.repo_root.resolve(), arguments.dry_run)
    action = "Would import" if arguments.dry_run else "Imported"
    print(f"{action} {len(files)} approved graphic files.")
    for path in files:
        print(f"  {path}")
    print("Existing identical images are skipped. No game saves were modified.")


if __name__ == "__main__":
    main()
