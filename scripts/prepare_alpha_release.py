#!/usr/bin/env python3
"""Package a fully tested ARM64 alpha together with the complete source tree.

This script runs only after the full GitHub CI test/build sequence succeeds.
It does not sign, compile or publish anything by itself.
"""

import argparse
import contextlib
import errno
import hashlib
import os
from pathlib import Path
import re
import shutil
import stat
import unicodedata
import zipfile

from package_project import WINDOWS_RESERVED_STEMS, create_archive

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



def _has_symlink_component(path: Path) -> bool:
    """Reject an APK reached through a linked file or parent directory.

    Path.resolve() follows links and would erase that evidence before release
    validation. Walk the supplied spelling without reading the target.
    """
    current = path.absolute()
    while True:
        if current.is_symlink():
            return True
        parent = current.parent
        if parent == current:
            return False
        current = parent


def _source_identity(info: os.stat_result) -> tuple[int, ...]:
    """Detect replacement or in-place modification of a validated APK."""
    return (
        info.st_dev, info.st_ino, info.st_size, info.st_mtime_ns, info.st_ctime_ns,
    )


def copy_validated_apk(source: Path, destination: Path,
                       expected: os.stat_result) -> None:
    """Pin the validated regular APK before copying, without following links.

    On POSIX, pin *each* parent directory with descriptor-relative O_NOFOLLOW.
    A late symlink in the leaf or any parent cannot redirect the copy. The
    identity captured before archive validation must remain unchanged through
    opening, reading and final publication preparation.
    """
    identity = _source_identity(expected)
    with contextlib.ExitStack() as stack:
        try:
            if (os.name == 'posix' and hasattr(os, 'O_NOFOLLOW')
                    and hasattr(os, 'O_DIRECTORY')):
                absolute = source.absolute()
                flags = os.O_RDONLY | os.O_NOFOLLOW | os.O_DIRECTORY
                directory_fd = os.open(absolute.anchor, flags)
                stack.callback(os.close, directory_fd)
                for part in absolute.parts[1:-1]:
                    next_fd = os.open(part, flags, dir_fd=directory_fd)
                    stack.callback(os.close, next_fd)
                    directory_fd = next_fd
                fd = os.open(
                    absolute.name,
                    os.O_RDONLY | os.O_NOFOLLOW | getattr(os, 'O_NONBLOCK', 0),
                    dir_fd=directory_fd,
                )
            else:
                # Platforms without openat/O_NOFOLLOW use the same identity
                # checks, but cannot guarantee race-free parent traversal.
                if _has_symlink_component(source):
                    raise ValueError(
                        'Die ARM64-APK darf keine symbolischen Pfadlinks verwenden.'
                    )
                fd = os.open(source, os.O_RDONLY | getattr(os, 'O_NONBLOCK', 0))
            stream = stack.enter_context(os.fdopen(fd, 'rb'))
            opened = os.fstat(stream.fileno())
            if not stat.S_ISREG(opened.st_mode) or _source_identity(opened) != identity:
                raise ValueError('Die ARM64-APK-Quelle wurde seit der Prüfung verändert.')
            with destination.open('wb') as output:
                shutil.copyfileobj(stream, output, length=1024 * 1024)
            after = os.fstat(stream.fileno())
            if _source_identity(after) != identity:
                raise ValueError('Die ARM64-APK-Quelle wurde beim Kopieren verändert.')
            if (_has_symlink_component(source) or not source.is_file()
                    or _source_identity(source.stat()) != identity):
                raise ValueError('Die ARM64-APK-Quelle wurde beim Kopieren verändert.')
        except OSError as error:
            if error.errno in (errno.ELOOP, errno.ENOTDIR, errno.ENOENT):
                raise ValueError(
                    'Die ARM64-APK-Quelle wurde durch einen Pfadlink oder '
                    'eine andere Datei ersetzt.'
                ) from error
            raise


def validate_arm64_apk(apk: Path) -> None:
    if _has_symlink_component(apk):
        raise ValueError('Die ARM64-APK darf keine symbolischen Pfadlinks verwenden.')
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
        # symbolic links, or invisible Unicode controls. Reject these before
        # checking required resources.
        names = [entry.filename for entry in entries]
        if len(names) != len(set(names)):
            raise ValueError('Die ARM64-APK enthält doppelte ZIP-Einträge.')
        # Keep the spelling of every implicit/explicit directory prefix.
        # Names that differ only by casing or NFC Unicode composition could
        # overwrite each other on common extraction targets. Check metadata
        # before ZIP CRC work, without rewriting any APK resource names.
        canonical_prefixes: dict[str, str] = {}
        file_paths: set[str] = set()
        directory_paths: set[str] = set()
        for entry in entries:
            name = entry.filename
            parts = name.rstrip('/').split('/')
            if (not name or name.startswith('/') or '\\' in name
                    or re.match(r'^[A-Za-z]:', name)
                    or any(part in ('', '.', '..') or part.endswith((' ', '.'))
                           or part.split('.', 1)[0].upper() in WINDOWS_RESERVED_STEMS
                           for part in parts)
                    or any(unicodedata.category(char) in {'Cc', 'Cf', 'Cs', 'Zl', 'Zp'}
                           for char in name)):
                raise ValueError('Die ARM64-APK enthält unsichere ZIP-Pfade.')
            canonical_parts: list[str] = []
            for index, part in enumerate(parts):
                canonical_parts.append(unicodedata.normalize('NFC', part).casefold())
                canonical_path = '/'.join(canonical_parts)
                original_path = '/'.join(parts[:index + 1])
                previous = canonical_prefixes.setdefault(canonical_path, original_path)
                if previous != original_path:
                    raise ValueError('Die ARM64-APK enthält kollidierende ZIP-Pfade.')
                # A bare file must not also be a directory prefix or
                # an explicitly named directory in the same archive.
                if index < len(parts) - 1 or name.endswith('/'):
                    directory_paths.add(canonical_path)
                else:
                    file_paths.add(canonical_path)
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
        if file_paths & directory_paths:
            raise ValueError('Die ARM64-APK enthält widersprüchliche Datei-/Verzeichnispfade.')
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
    # Preserve the caller-supplied path spelling so validation can identify
    # symlinked APK files and any linked parent directories before reading.
    source_apk = apk if apk is not None else root / 'app/build/alpha/app-arm64-v8a-alpha.apk'
    # Record the source identity before validating its ZIP content. A later
    # file swap or in-place rewrite must not publish an unvalidated APK.
    checked_source = (
        source_apk.stat()
        if not _has_symlink_component(source_apk) and source_apk.is_file()
        else None
    )
    validate_arm64_apk(source_apk)
    if (checked_source is None
            or _source_identity(source_apk.stat()) != _source_identity(checked_source)):
        raise ValueError('Die ARM64-APK-Quelle wurde während der Prüfung verändert.')
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
        # Recheck after potentially long source ZIP creation as well.
        if _has_symlink_component(source_apk):
            raise ValueError('Die ARM64-APK darf keine symbolischen Pfadlinks verwenden.')
        copy_validated_apk(source_apk, target_apk, checked_source)
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
