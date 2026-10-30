#!/usr/bin/env python3
"""Import the approved original artwork ZIP into an existing Würfelraunen tree.

No Pillow, Flutter or network dependency. Each source file is verified against
the SHA-256 manifest before writing. Do not overwrite divergent local art.
"""
import argparse
import hashlib
import json
import pathlib
import sys
import zipfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
PREFIX = "app/assets/fantasy/"
ASSETS = tuple(f"portrait_{i}.webp" for i in range(1, 10)) + (
    "ornate_panel_background.webp",
    "ornate_button_background.webp",
    "ornate_card_background.webp",
    "ornate_portrait_border.webp",
)
MANIFEST = "docs/graphics/GRAFIK_MANIFEST.json"



def ensure_safe_destination(path: pathlib.Path, target_root: pathlib.Path) -> None:
    """Never follow symlinks inside the chosen artwork import destination."""
    try:
        components = path.relative_to(target_root).parts
    except ValueError as error:
        raise ValueError("Grafikziel liegt ausserhalb des Projektordners") from error
    current = target_root
    if current.is_symlink():
        raise ValueError(f"Grafik-Zielordner ist ein Symlink: {current}")
    for component in components:
        current = current / component
        # Path.exists() is false for dangling symlinks, so test is_symlink()
        # explicitly before reading, creating directories or writing assets.
        if current.is_symlink():
            raise ValueError(f"Grafik-Zielpfad enthaelt Symlink: {current}")


def imported_assets(zip_path: pathlib.Path, target_root: pathlib.Path):
    with zipfile.ZipFile(zip_path) as archive:
        if archive.testzip():
            raise ValueError("Grafik-ZIP beschaedigt")
        manifest = json.loads(archive.read(MANIFEST))
        validated = []
        for name in ASSETS:
            rel = PREFIX + name
            data = archive.read(rel)
            info = manifest[rel]
            if hashlib.sha256(data).hexdigest() != info["sha256"]:
                raise ValueError(f"SHA256 stimmt nicht: {name}")
            if len(data) != info["bytes"] or not (
                data[:4] == b"RIFF" and data[8:12] == b"WEBP"
            ):
                raise ValueError(f"Keine gueltige WebP-Datei: {name}")
            path = target_root / rel
            ensure_safe_destination(path, target_root)
            if path.exists() and path.read_bytes() != data:
                raise FileExistsError(f"Abweichendes Original nicht ueberschreiben: {path}")
            validated.append((path, data))
        return validated


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("graphics_zip", type=pathlib.Path)
    parser.add_argument("--target", type=pathlib.Path, default=ROOT)
    parser.add_argument("--verify-only", action="store_true")
    args = parser.parse_args(argv)
    try:
        files = imported_assets(args.graphics_zip, args.target)
        for path, data in files:
            if not args.verify_only:
                # Revalidate immediately before filesystem mutation; the
                # initial ZIP scan and this write phase are separate.
                ensure_safe_destination(path, args.target)
                path.parent.mkdir(parents=True, exist_ok=True)
                ensure_safe_destination(path, args.target)
                if not path.exists():
                    # Exclusive creation refuses late symlink/file replacement
                    # instead of following a link or overwriting existing art.
                    with path.open("xb") as stream:
                        stream.write(data)
            print(f"{'OK' if args.verify_only else 'Bereit'}: {path.name} ({len(data)} Bytes)")
        print(f"{len(files)} Originaldateien verifiziert.")
        return 0
    except (ValueError, OSError, KeyError, zipfile.BadZipFile) as exc:
        print(f"Grafikimport fehlgeschlagen: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
