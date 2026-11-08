#!/usr/bin/env python3
"""Import the approved original artwork ZIP into an existing Würfelraunen tree.

No Pillow, Flutter or network dependency. Each source file is verified against
the SHA-256 manifest before writing. Do not overwrite divergent local art.
"""
import argparse
import hashlib
import json
import os
import pathlib
import sys
import tempfile
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
# The official archive contains small WebP images plus a few concept assets.
# Reject unreasonable ZIP metadata before testzip() decompresses *all* entries.
MAX_ZIP_ENTRIES = 256
MAX_ZIP_UNCOMPRESSED_BYTES = 64 * 1024 * 1024
MAX_MANIFEST_BYTES = 512 * 1024
MAX_ASSET_BYTES = 8 * 1024 * 1024


def read_bounded_zip_member(archive: zipfile.ZipFile, name: str, limit: int) -> bytes:
    """Read only a bounded regular ZIP member, even with malformed size metadata."""
    entry = archive.getinfo(name)
    if entry.is_dir() or entry.file_size < 0 or entry.file_size > limit:
        raise ValueError(f"Grafik-ZIP-Eintrag zu gross oder kein Dateiinhalt: {name}")
    with archive.open(entry) as source:
        data = source.read(limit + 1)
    if len(data) > limit:
        raise ValueError(f"Grafik-ZIP-Eintrag zu gross: {name}")
    return data



def parse_strict_manifest(data: bytes) -> dict:
    """Reject ambiguous JSON before trusting declared asset digests or sizes.

    Python's default JSON parser silently keeps the last duplicate key and
    accepts non-standard NaN/Infinity values. Original artwork metadata must
    have one unambiguous interpretation across tools.
    """
    def unique_object(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError("Grafikmanifest enthaelt doppelte JSON-Schluessel")
            result[key] = value
        return result

    def reject_constant(_value):
        raise ValueError("Grafikmanifest enthaelt ungueltige JSON-Zahl")

    manifest = json.loads(
        data, object_pairs_hook=unique_object, parse_constant=reject_constant
    )
    if not isinstance(manifest, dict):
        raise ValueError("Grafikmanifest muss ein Objekt sein")
    return manifest


def ensure_safe_destination(path: pathlib.Path, target_root: pathlib.Path) -> None:
    """Never follow symlinks in the destination or any of its ancestors."""
    try:
        components = path.relative_to(target_root).parts
    except ValueError as error:
        raise ValueError("Grafikziel liegt ausserhalb des Projektordners") from error
    # A target like /work/alias/project may itself be a normal directory,
    # even though /work/alias redirects the import outside the selected tree.
    # Check the entire target ancestry before validating its child assets.
    for ancestor in (target_root, *target_root.parents):
        if ancestor.is_symlink():
            raise ValueError(f"Grafik-Zielordner enthaelt Symlink: {ancestor}")
    current = target_root
    for component in components:
        current = current / component
        # Path.exists() is false for dangling symlinks, so test is_symlink()
        # explicitly before reading, creating directories or writing assets.
        if current.is_symlink():
            raise ValueError(f"Grafik-Zielpfad enthaelt Symlink: {current}")


def imported_assets(zip_path: pathlib.Path, target_root: pathlib.Path):
    with zipfile.ZipFile(zip_path) as archive:
        entries = archive.infolist()
        if (len(entries) > MAX_ZIP_ENTRIES
                or any(entry.file_size < 0 for entry in entries)
                or sum(entry.file_size for entry in entries) > MAX_ZIP_UNCOMPRESSED_BYTES):
            raise ValueError("Grafik-ZIP enthaelt zu viele oder zu grosse Eintraege")
        if len({entry.filename for entry in entries}) != len(entries):
            raise ValueError("Grafik-ZIP enthaelt doppelte Dateinamen")

        manifest = parse_strict_manifest(read_bounded_zip_member(
            archive, MANIFEST, MAX_MANIFEST_BYTES
        ))
        # Validate every requested asset's declared size before testzip() can
        # decompress untrusted contents, including unrelated extra files.
        for name in ASSETS:
            rel = PREFIX + name
            info = manifest[rel]
            if not isinstance(info, dict) or type(info.get("bytes")) is not int:
                raise ValueError(f"Ungueltige Grafikmanifest-Groesse: {name}")
            size = info["bytes"]
            if not (0 < size <= MAX_ASSET_BYTES):
                raise ValueError(f"Grafikmanifest-Groesse ausserhalb des Limits: {name}")
            entry = archive.getinfo(rel)
            if entry.is_dir() or entry.file_size != size:
                raise ValueError(f"Grafik-ZIP-Groesse stimmt nicht: {name}")

        if archive.testzip():
            raise ValueError("Grafik-ZIP beschaedigt")
        validated = []
        for name in ASSETS:
            rel = PREFIX + name
            data = read_bounded_zip_member(archive, rel, MAX_ASSET_BYTES)
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



def publish_verified_asset(
    path: pathlib.Path, data: bytes, target_root: pathlib.Path
) -> None:
    """Publish one complete file without exposing a truncated target.

    Stage in the destination directory and hard-link only after the entire
    verified payload has been written and synced. os.link fails if another
    writer creates the target meanwhile, so existing artwork is never replaced.
    A failed write or link only leaves a private temporary file to clean up.
    """
    ensure_safe_destination(path, target_root)
    path.parent.mkdir(parents=True, exist_ok=True)
    ensure_safe_destination(path, target_root)
    if path.exists():
        if path.read_bytes() != data:
            raise FileExistsError(f"Abweichendes Original nicht ueberschreiben: {path}")
        return
    descriptor, temp_name = tempfile.mkstemp(
        prefix=f".{path.name}.", suffix=".partial", dir=path.parent
    )
    try:
        with os.fdopen(descriptor, "wb") as staged:
            staged.write(data)
            staged.flush()
            os.fsync(staged.fileno())
        # A link or a newly created destination must not be followed.
        ensure_safe_destination(path, target_root)
        os.link(temp_name, path)
    finally:
        pathlib.Path(temp_name).unlink(missing_ok=True)


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
                # Publish via a complete temporary file; a failed write must
                # never leave a corrupt original that blocks later retries.
                publish_verified_asset(path, data, args.target)
            print(f"{'OK' if args.verify_only else 'Bereit'}: {path.name} ({len(data)} Bytes)")
        print(f"{len(files)} Originaldateien verifiziert.")
        return 0
    except (ValueError, OSError, KeyError, zipfile.BadZipFile) as exc:
        print(f"Grafikimport fehlgeschlagen: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
