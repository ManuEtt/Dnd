#!/usr/bin/env python3
"""Create a source ZIP without SDKs, personal data, secrets or build caches."""
from pathlib import Path
import argparse
import hashlib
import contextlib
import errno
import os
import shutil
import stat
import tempfile
import unicodedata
import zipfile

ROOT = Path(__file__).resolve().parent.parent
EXCLUDED_DIRS = {
    '.git', '.dart_tool', '.gradle', '.cxx', '.idea', '.vscode', '__pycache__',
    'node_modules', 'build', 'dist', 'coverage', '.pytest_cache',
    '.venv', 'venv', '.cache', '.pub-cache', '.npm', '.m2', '.tox',
    '.android', '.ssh', '.aws', '.azure', '.config', '.credentials',
    'flutter-sdk', 'dart-sdk', 'android-sdk', 'android-sdk-linux',
}
EXCLUDED_NAMES = {
    'local.properties', 'key.properties', '.flutter-plugins',
    '.flutter-plugins-dependencies', '.DS_Store', 'GeneratedPluginRegistrant.java',
    '.netrc', '.npmrc', '.pypirc', '.git-credentials', 'credentials.json',
    'service-account.json', 'id_rsa', 'id_dsa', 'id_ecdsa', 'id_ed25519',
}
# Normalize both sides: the historical names intentionally retain their
# spelling, including .DS_Store and GeneratedPluginRegistrant.java.
_CASEFOLDED_EXCLUDED_NAMES = frozenset(name.casefold() for name in EXCLUDED_NAMES)
EXCLUDED_SUFFIXES = {
    '.apk', '.aab', '.log', '.iml', '.jks', '.keystore', '.db', '.sqlite', '.sqlite3',
    '.pem', '.key', '.p12', '.pfx', '.pyc', '.pyo', '.zip', '.tar', '.tgz',
    '.gz', '.bz2', '.xz', '.7z', '.rar', '.patch', '.diff',
}

def include(path: Path, root: Path = ROOT) -> bool:
    relative = path.relative_to(root)
    # File names on Android/Windows may arrive with different casing. Protect
    # exports on case-sensitive hosts too, including mixed-case secrets.
    if any(part.casefold() in EXCLUDED_DIRS for part in relative.parts):
        return False
    name = path.name.casefold()
    if name in _CASEFOLDED_EXCLUDED_NAMES or path.suffix.casefold() in EXCLUDED_SUFFIXES:
        return False
    if name.startswith('.env') and name != '.env.example':
        return False
    if any(name.endswith(suffix) for suffix in ('-wal', '-shm', '-journal')):
        return False
    return True


def source_paths(root: Path) -> list[Path]:
    """Prune caches before walking them and reject links, including directory links."""
    paths = []
    def walk_error(error: OSError) -> None:
        raise error

    for directory, dirs, files in os.walk(root, followlinks=False, onerror=walk_error):
        current = Path(directory)
        dirs[:] = [name for name in dirs if include(current / name, root)]
        if any((current / name).is_symlink() for name in dirs):
            raise ValueError('Source archive must not contain symlinked directories.')
        # SDKs/venvs can have arbitrary local folder names. Recognize their own
        # markers rather than excluding legitimate source folders named "tools".
        dirs[:] = [name for name in dirs
                   if not (current / name / 'pyvenv.cfg').is_file()
                   and not ((current / name / 'bin/internal/engine.version').is_file()
                            and (current / name / 'packages/flutter/pubspec.yaml').is_file())]
        for name in files:
            path = current / name
            if include(path, root):
                if path.is_symlink():
                    raise ValueError('Source archive must not contain symlinked files.')
                paths.append(path)
    return sorted(paths)


# ZIP names are case-sensitive, but common extraction targets (Windows and
# many macOS filesystems) are not. Preserve the original names and reject
# collisions before replacing any previously verified source archive.
WINDOWS_RESERVED_STEMS = frozenset(
    ('CON', 'PRN', 'AUX', 'NUL')
    + tuple(f'COM{number}' for number in range(1, 10))
    + tuple(f'LPT{number}' for number in range(1, 10))
)
WINDOWS_INVALID_CHARACTERS = frozenset('<>:"\\|?*')


def validate_portable_source_paths(root: Path, paths: list[Path]) -> None:
    """Reject archive names that can collide or fail on another filesystem."""
    prefixes: dict[str, str] = {}
    for path in paths:
        parts = path.relative_to(root).parts
        canonical: list[str] = []
        for index, part in enumerate(parts):
            if (part in ('.', '..') or part.endswith((' ', '.'))
                    or any(char in WINDOWS_INVALID_CHARACTERS or
                           ord(char) < 32 or ord(char) == 127 for char in part)
                    or part.split('.', 1)[0].upper() in WINDOWS_RESERVED_STEMS):
                raise ValueError('Source archive contains a non-portable filename.')
            canonical.append(unicodedata.normalize('NFC', part).casefold())
            folded_path = '/'.join(canonical)
            original_path = '/'.join(parts[:index + 1])
            previous = prefixes.setdefault(folded_path, original_path)
            if previous != original_path:
                raise ValueError(
                    'Source archive contains case-insensitive or Unicode-equivalent '
                    'filename collisions.'
                )

REQUIRED_FILES = {
    'app/lib/main.dart', 'app/pubspec.lock', 'backend/package-lock.json',
    '.github/workflows/android-build.yml', 'app/assets/demo.json', 'README.md',
}

def read_verified_source(root: Path, path: Path) -> tuple[bytes, os.stat_result]:
    """Read one source file without following newly swapped symlinks.

    On POSIX each directory component is opened relative to the previous
    directory descriptor with O_NOFOLLOW, so replacing an enumerated parent
    directory or leaf file with a link cannot escape the repository root.
    """
    relative = path.relative_to(root)
    before = path.lstat()
    if not stat.S_ISREG(before.st_mode):
        raise ValueError('Source archive must not contain symlinked or non-regular files.')
    with contextlib.ExitStack() as stack:
        if (os.name == 'posix' and hasattr(os, 'O_NOFOLLOW')
                and hasattr(os, 'O_DIRECTORY')):
            flags = os.O_RDONLY | os.O_NOFOLLOW | os.O_DIRECTORY
            try:
                directory_fd = os.open(root, flags)
                stack.callback(os.close, directory_fd)
                for component in relative.parts[:-1]:
                    next_fd = os.open(component, flags, dir_fd=directory_fd)
                    stack.callback(os.close, next_fd)
                    directory_fd = next_fd
                file_fd = os.open(
                    relative.name,
                    os.O_RDONLY | os.O_NOFOLLOW | getattr(os, 'O_NONBLOCK', 0),
                    dir_fd=directory_fd,
                )
                source = stack.enter_context(os.fdopen(file_fd, 'rb'))
                after = os.fstat(source.fileno())
                if not stat.S_ISREG(after.st_mode):
                    raise ValueError('Source archive requires regular source files.')
                data = source.read()
            except OSError as error:
                if error.errno in (errno.ELOOP, errno.ENOTDIR):
                    raise ValueError(
                        'Source archive must not follow symlinked directories or files.'
                    ) from error
                raise
        else:
            # Best-effort fallback for platforms without descriptor-relative,
            # no-follow opens. POSIX builds use the race-safe branch above.
            parent = root
            for component in relative.parts[:-1]:
                parent = parent / component
                if parent.is_symlink():
                    raise ValueError('Source archive must not follow symlinked directories.')
            if path.is_symlink() or not path.resolve().is_relative_to(root):
                raise ValueError('Source archive must not follow symlinked files.')
            source = stack.enter_context(path.open('rb'))
            after = os.fstat(source.fileno())
            if not stat.S_ISREG(after.st_mode):
                raise ValueError('Source archive requires regular source files.')
            data = source.read()
    final = path.lstat()
    identity = lambda item: (
        item.st_dev, item.st_ino, item.st_size, item.st_mtime_ns, item.st_ctime_ns,
    )
    if not (identity(before) == identity(after) == identity(final)
            and len(data) == before.st_size):
        raise RuntimeError('Source changed during archive creation.')
    return data, before


def copy_previous_archive(output: Path, backup: Path) -> None:
    """Preserve an existing ZIP without following a swapped output symlink.

    POSIX uses O_NOFOLLOW for the last path component. os.replace() below
    always replaces the directory entry, not the destination of a symlink.
    """
    if os.name == 'posix' and hasattr(os, 'O_NOFOLLOW'):
        try:
            fd = os.open(
                output, os.O_RDONLY | os.O_NOFOLLOW | getattr(os, 'O_NONBLOCK', 0)
            )
        except FileNotFoundError:
            return
        except OSError as error:
            if error.errno in (errno.ELOOP, errno.ENOTDIR):
                raise ValueError('Output archive must not be a symlink.') from error
            raise
        with os.fdopen(fd, 'rb') as previous:
            before = os.fstat(previous.fileno())
            if not stat.S_ISREG(before.st_mode):
                raise ValueError('Previous archive must be a regular file.')
            with backup.open('wb') as staged:
                shutil.copyfileobj(previous, staged)
            backup.chmod(stat.S_IMODE(before.st_mode))
            os.utime(backup, ns=(before.st_atime_ns, before.st_mtime_ns))
    else:
        # Best-effort fallback; descriptor-relative no-follow is POSIX-only.
        if output.is_symlink():
            raise ValueError('Output archive must not be a symlink.')
        if output.is_file():
            shutil.copy2(output, backup)


@contextlib.contextmanager
def exclusive_archive_output(output: Path):
    """One writer per ZIP+checksum pair, across threads and processes.

    The adjacent directory is claimed atomically. A crash can leave a stale
    lock: fail closed rather than risk corrupting a previously valid pair.
    Never delete a lock that this invocation did not successfully create.
    """
    lock = output.with_name(f'.{output.name}.lock')
    try:
        lock.mkdir()
    except FileExistsError as error:
        raise ValueError('Source archive publication already in progress.') from error
    try:
        yield
    finally:
        lock.rmdir()


def create_archive(root: Path, output: Path, *, layout: str = 'folder') -> tuple[int, str]:
    """A root layout can be copied straight into a GitHub repository."""
    if layout not in {'folder', 'root'}:
        raise ValueError('Unknown archive layout.')
    root, output = root.resolve(), output.absolute()
    checksum = output.with_suffix(output.suffix + '.sha256')
    # Keep the named output path: Path.resolve() would redirect an existing
    # output symlink and let publication overwrite its external target.
    if output.is_symlink() or checksum.is_symlink():
        raise ValueError('Output archive and checksum must not be symlinks.')
    if (output.resolve().is_relative_to(root)
            or checksum.resolve().is_relative_to(root)):
        raise ValueError('Write the archive outside the project directory.')
    if any(path.exists() and not path.is_file() for path in (output, checksum)):
        raise ValueError('Output archive and checksum must be regular files.')
    output.parent.mkdir(parents=True, exist_ok=True)
    with exclusive_archive_output(output):
        paths = source_paths(root)
        relative_names = {p.relative_to(root).as_posix() for p in paths}
        missing = REQUIRED_FILES - relative_names
        if missing:
            raise ValueError(f'Missing required project files: {sorted(missing)}')
        validate_portable_source_paths(root, paths)
        prefix = Path('Dnd') if layout == 'folder' else Path()
        # Build and validate outside the published archive. A partial write must
        # never truncate a previously usable ZIP or its checksum.
        with tempfile.TemporaryDirectory(prefix=f'.{output.name}.', dir=output.parent) as tmp:
            temporary = Path(tmp)
            staged_zip = temporary / output.name
            staged_sha = temporary / checksum.name
            with zipfile.ZipFile(staged_zip, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
                for path in paths:
                    data, before = read_verified_source(root, path)
                    # writestr() does not inherit filesystem mode bits, unlike
                    # ZipFile.write(). Keep executable source scripts recoverable
                    # while retaining the verified same-file read above.
                    info = zipfile.ZipInfo((prefix / path.relative_to(root)).as_posix())
                    info.create_system = 3
                    info.external_attr = (
                        stat.S_IFREG | stat.S_IMODE(before.st_mode)
                    ) << 16
                    info.compress_type = zipfile.ZIP_DEFLATED
                    archive.writestr(info, data)
            with zipfile.ZipFile(staged_zip) as archive:
                bad = archive.testzip()
                if bad:
                    raise RuntimeError(f'Corrupt ZIP entry: {bad}')
            digest = hashlib.sha256(staged_zip.read_bytes()).hexdigest()
            staged_sha.write_text(f'{digest}  {output.name}\n', encoding='utf-8')

            # Preserve both previous files until the staged pair is ready. If the
            # second replacement fails, restore the previous ZIP as well.
            previous_zip = temporary / 'previous.zip'
            copy_previous_archive(output, previous_zip)
            published_zip = False
            try:
                os.replace(staged_zip, output)
                published_zip = True
                os.replace(staged_sha, checksum)
            except BaseException:
                if published_zip:
                    if previous_zip.is_file():
                        os.replace(previous_zip, output)
                    else:
                        output.unlink(missing_ok=True)
                raise
        return len(paths), digest

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    parser.add_argument('--layout', choices=('folder', 'root'), default='folder',
                        help='root: no outer Dnd folder; suitable for GitHub upload')
    args = parser.parse_args()
    try:
        count, digest = create_archive(ROOT, args.output, layout=args.layout)
    except ValueError as error:
        parser.error(str(error))
    output = args.output.resolve()
    print(f'{output}: {count} files, {output.stat().st_size} bytes, SHA256 {digest}')

if __name__ == '__main__':
    main()
