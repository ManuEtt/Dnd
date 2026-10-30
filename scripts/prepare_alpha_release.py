#!/usr/bin/env python3
"""Package a fully tested ARM64 alpha together with the complete source tree.

This script runs only after the full GitHub CI test/build sequence succeeds.
It does not sign, compile or publish anything by itself.
"""

import argparse
import hashlib
import os
from pathlib import Path
import re
import shutil
import stat
import zipfile

from package_project import create_archive

ROOT = Path(__file__).resolve().parent.parent
VERSION = re.compile(r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$', re.MULTILINE)
REQUIRED_ARM64 = {
    'AndroidManifest.xml',
    'lib/arm64-v8a/libapp.so',
    'lib/arm64-v8a/libflutter.so',
}
# A normal Android alpha is far smaller. Validate ZIP metadata before CRC
# decompression to reject accidental or hostile APK expansion bombs.
MAX_ALPHA_APK_BYTES = 512 * 1024 * 1024
MAX_ALPHA_APK_ENTRIES = 20000
MAX_ALPHA_APK_UNCOMPRESSED_BYTES = 1024 * 1024 * 1024
MAX_ALPHA_APK_EXPANSION_RATIO = 1000
MIN_ALPHA_APK_RATIO_BYTES = 1024 * 1024


def read_version(root: Path) -> tuple[str, str]:
    pubspec = (root / 'app/pubspec.yaml').read_text(encoding='utf-8')
    matches = VERSION.findall(pubspec)
    if len(matches) != 1:
        raise ValueError('app/pubspec.yaml braucht genau eine gültige X.Y.Z+Build-Version.')
    major, minor, patch, build = matches[0]
    if int(build) < 1:
        raise ValueError('Der Android-Versionscode muss positiv sein.')
    return f'{major}.{minor}.{patch}', build


def validate_arm64_apk(apk: Path) -> None:
    if not apk.is_file() or apk.stat().st_size == 0:
        raise ValueError('Keine gebaute ARM64-APK vorhanden: ' + str(apk))
    if apk.stat().st_size > MAX_ALPHA_APK_BYTES:
        raise ValueError('Die ARM64-APK überschreitet die zulässige Dateigröße.')
    if not zipfile.is_zipfile(apk):
        raise ValueError('Die Android-APK ist kein gültiges ZIP-Containerformat.')
    with zipfile.ZipFile(apk) as archive:
        # Check central-directory metadata before testzip() decompresses
        # every member. This also prevents hugely compressible single entries.
        entries = archive.infolist()
        if (len(entries) > MAX_ALPHA_APK_ENTRIES
                or sum(entry.file_size for entry in entries)
                > MAX_ALPHA_APK_UNCOMPRESSED_BYTES
                or any(
                    entry.file_size >= MIN_ALPHA_APK_RATIO_BYTES
                    and entry.file_size
                    > MAX_ALPHA_APK_EXPANSION_RATIO * max(1, entry.compress_size)
                    for entry in entries
                )):
            raise ValueError('Die ARM64-APK hat übergroße oder stark komprimierte ZIP-Inhalte.')
        # CRC-valid ZIPs can still contain ambiguous members, traversal paths
        # or symbolic links. Reject these before checking required resources.
        names = [entry.filename for entry in entries]
        if len(names) != len(set(names)):
            raise ValueError('Die ARM64-APK enthält doppelte ZIP-Einträge.')
        for entry in entries:
            name = entry.filename
            parts = name.rstrip('/').split('/')
            if (not name or name.startswith('/') or '\\' in name
                    or re.match(r'^[A-Za-z]:', name)
                    or any(part in ('', '.', '..') for part in parts)
                    or any(ord(char) < 32 or ord(char) == 127 for char in name)):
                raise ValueError('Die ARM64-APK enthält unsichere ZIP-Pfade.')
            mode = entry.external_attr >> 16
            if stat.S_ISLNK(mode):
                raise ValueError('Die ARM64-APK enthält symbolische ZIP-Links.')
            # The Unix mode can describe a device, pipe, socket or a directory
            # masquerading as a required APK file. ZIP CRC verification alone
            # cannot detect these misleading member types. Mode zero is kept
            # compatible with ZIP producers that omit Unix file-type bits.
            if entry.create_system == 3:
                kind = stat.S_IFMT(mode)
                if kind not in (0, stat.S_IFREG, stat.S_IFDIR):
                    raise ValueError('Die ARM64-APK enthält unzulässige ZIP-Dateitypen.')
                if ((kind == stat.S_IFDIR and not name.endswith('/'))
                        or (kind == stat.S_IFREG and name.endswith('/'))):
                    raise ValueError('Die ARM64-APK enthält widersprüchliche ZIP-Dateitypen.')
        if archive.testzip() is not None:
            raise ValueError('Die ARM64-APK enthält beschädigte ZIP-Einträge.')
        present = set(archive.namelist())
        missing = REQUIRED_ARM64 - present
        if missing:
            raise ValueError('Die ARM64-APK enthält nicht alle nativen Komponenten: '
                             + ', '.join(sorted(missing)))
        if any(archive.getinfo(name).file_size == 0 for name in REQUIRED_ARM64):
            raise ValueError('Eine erforderliche Android-APK-Komponente ist leer.')


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def prepare_release(root: Path, output: Path, *, commit: str = 'lokal',
                    run_url: str = '', apk: Path | None = None) -> list[Path]:
    root = root.resolve()
    output = output.resolve()
    if output == root or output.is_relative_to(root):
        raise ValueError('Das Release-Verzeichnis muss außerhalb des Projektordners liegen.')
    app_version, build = read_version(root)
    source_apk = (apk or root / 'app/build/alpha/app-arm64-v8a-alpha.apk').resolve()
    validate_arm64_apk(source_apk)
    stem = f'Wuerfelraunen_v{app_version}_{build}'
    source = output / f'{stem}_Source.zip'
    target_apk = output / f'{stem}_arm64.apk'
    notes = output / f'{stem}_ReleaseNotes.md'
    sums = output / f'{stem}_SHA256.txt'
    # Also protect the SHA256 sidecar created by package_project.create_archive.
    # Path.exists() alone misses dangling symlinks: later write_text/copy2
    # could otherwise follow those links to a path outside the release folder.
    source_checksum = source.with_suffix(source.suffix + '.sha256')
    generated = [source, target_apk, notes, sums, source_checksum]
    # Reserve this version before checking or publishing its files. Without
    # this atomic directory lock, two CI jobs can both pass the collision check;
    # one failed job could then delete the other's successfully built release.
    # A stale lock after a crashed process deliberately fails closed.
    output.mkdir(parents=True, exist_ok=True)
    publication_lock = output / f'.{stem}_Release.lock'
    try:
        publication_lock.mkdir()
    except FileExistsError as error:
        raise ValueError('Eine Veröffentlichung dieser Version ist bereits in Bearbeitung.') from error
    if any(path.exists() or path.is_symlink() for path in generated):
        publication_lock.rmdir()
        raise ValueError('Es sind bereits Release-Dateien mit derselben Version vorhanden.')
    try:
        create_archive(root, source, layout='root')
        shutil.copy2(source_apk, target_apk)
        notes.write_text(
            f'# Würfelraunen {app_version}+{build} – Android-Alpha\n\n'
            f'- Quellstand: `{commit}`\n'
            f'- CI-Lauf: {run_url or "lokale Quellcodeübergabe"}\n'
            '- Plattform: Android ARM64 (`arm64-v8a`)\n'
            '- Vollständiges Quellarchiv im ZIP-Root-Layout (Flutter, Backend, Tests, Assets).\n'
            '- Diese APK wird derzeit mit einem **Debug-Testschlüssel** signiert. '
            'Sie ist keine dauerhaft signierte Produktivversion; Updates können an '
            'abweichenden Schlüsseln anderer Builds scheitern. Spielstände vorab sichern.\n'
            '- Eine Veröffentlichung bedeutet nur, dass die im zugehörigen GitHub-Job '
            'ausgeführten Tests erfolgreich waren; reale Gerätetests stehen separat an.\n',
            encoding='utf-8',
        )
        sums.write_text(''.join(
            f'{sha256(path)}  {path.name}\n' for path in (source, target_apk, notes)
        ), encoding='utf-8')
        validate_arm64_apk(target_apk)
        with zipfile.ZipFile(source) as archive:
            if archive.testzip() is not None:
                raise ValueError('Das Quellarchiv ist beschädigt.')
    except BaseException:
        # KeyboardInterrupt and SystemExit must not leave a partial release
        # behind after the finally block releases the exclusive version lock.
        for path in generated:
            path.unlink(missing_ok=True)
        # package_project.create_archive creates a sidecar checksum file.
        source.with_suffix(source.suffix + '.sha256').unlink(missing_ok=True)
        raise
    finally:
        publication_lock.rmdir()
    # Retain the existing package project's checksum sidecar as an extra check.
    return [source, target_apk, notes, sums,
            source.with_suffix(source.suffix + '.sha256')]


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    parser.add_argument('--root', type=Path, default=ROOT)
    parser.add_argument('--apk', type=Path, default=None)
    parser.add_argument('--commit', default=os.environ.get('GITHUB_SHA', 'lokal'))
    parser.add_argument('--run-url', default='')
    args = parser.parse_args()
    for path in prepare_release(args.root, args.output, commit=args.commit,
                                run_url=args.run_url, apk=args.apk):
        print(path)


if __name__ == '__main__':
    main()
