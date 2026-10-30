#!/usr/bin/env python3
"""Create and verify a complete source checkpoint outside the repository.

Usage: python3 scripts/create_checkpoint.py --output-dir /workspace/artifacts \
    --base <explicit-commit> --label tested-rules

The patch represents the filtered CURRENT WORKING TREE against --base, including
untracked source files and deletions. Commits are recommended before packaging,
but are not required. The real Git index, branch and working tree are untouched.
Excluded secrets/build outputs are also excluded from the patch even if tracked.
CHECKPOINT.md and other development documentation must be updated by the caller.
Every checkpoint keeps its versioned ZIP, patch, JSON file manifest and checksums;
only the LATEST ZIP and SHA256SUMS.txt aliases are replaced after validation.
"""

import argparse
import contextlib
import errno
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import subprocess
import tempfile
import zipfile

from package_project import (REQUIRED_FILES, ROOT, create_archive, include,
                             read_verified_source, source_paths)
from prepare_alpha_release import read_version, sha256


LATEST = 'Wuerfelraunen_LATEST_Vollprojekt.zip'
LABEL = re.compile(r'[A-Za-z0-9][A-Za-z0-9._-]{0,63}')


def git(root: Path, *args: str, env: dict | None = None,
        data: bytes | None = None) -> bytes:
    result = subprocess.run(
        ['git', '-c', 'core.hooksPath=/dev/null', '-c', 'core.fileMode=true',
         '-C', str(root), *args],
        input=data, capture_output=True, env=env, check=False,
    )
    if result.returncode:
        # Do not echo Git output: source paths or configuration can contain secrets.
        raise ValueError(f'Git {args[0]} failed (exit {result.returncode}).')
    return result.stdout


def safe_name(name: str) -> bool:
    path = PurePosixPath(name)
    return (bool(name) and not path.is_absolute() and '\\' not in name
            and all(part not in {'', '.', '..'} for part in name.split('/'))
            and not any(ord(char) < 32 or ord(char) == 127 for char in name)
            and not re.match(r'^[A-Za-z]:', name))


def previous_checkpoint_files(output_dir: Path) -> dict[str, tuple[Path, os.stat_result]]:
    """Select only safe, regular historical artifacts for the checksum ledger.

    Checking lstat rather than is_file rejects links to files outside the
    artifact directory. Reject malformed names instead of writing ambiguous
    SHA256SUMS.txt lines or silently trusting an unsafe old snapshot.
    """
    result = {}
    for path in output_dir.iterdir():
        name = path.name
        if (not name.startswith('Wuerfelraunen_') or name == LATEST
                or not (path.suffix in {'.zip', '.patch'}
                        or name.endswith('_Dateimanifest.json'))):
            continue
        details = path.lstat()
        if not safe_name(name) or not stat.S_ISREG(details.st_mode):
            raise ValueError('Unsafe previous checkpoint artifact in output directory.')
        result[name] = (path, details)
    return result


def sha256_previous_checkpoint(
        output_dir: Path, name: str, expected: os.stat_result) -> str:
    """Stream one earlier checkpoint without following a swapped symlink.

    POSIX pins the output directory with O_DIRECTORY and opens the leaf
    relative to it using O_NOFOLLOW. Stat identity checks also reject
    regular files rewritten after the historical artifact scan.
    """
    if not safe_name(name) or '/' in name:
        raise ValueError('Unsafe previous checkpoint artifact name.')
    path = output_dir / name
    identity = lambda item: (
        item.st_dev, item.st_ino, item.st_size, item.st_mtime_ns, item.st_ctime_ns,
    )
    before = path.lstat()
    if not stat.S_ISREG(before.st_mode):
        raise ValueError('Unsafe previous checkpoint artifact in output directory.')
    if identity(before) != identity(expected):
        raise ValueError('Historical checkpoint changed before hashing.')
    digest = hashlib.sha256()
    total = 0
    with contextlib.ExitStack() as stack:
        if (os.name == 'posix' and hasattr(os, 'O_NOFOLLOW')
                and hasattr(os, 'O_DIRECTORY')):
            directory_fd = os.open(
                output_dir, os.O_RDONLY | os.O_NOFOLLOW | os.O_DIRECTORY,
            )
            stack.callback(os.close, directory_fd)
            try:
                file_fd = os.open(
                    name, os.O_RDONLY | os.O_NOFOLLOW
                    | getattr(os, 'O_NONBLOCK', 0), dir_fd=directory_fd,
                )
            except OSError as error:
                if error.errno in (errno.ELOOP, errno.ENOTDIR):
                    raise ValueError(
                        'Unsafe previous checkpoint artifact in output directory.'
                    ) from error
                raise
        else:
            # Best effort when descriptor-relative, no-follow opens are absent.
            if path.is_symlink():
                raise ValueError('Unsafe previous checkpoint artifact in output directory.')
            file_fd = os.open(path, os.O_RDONLY)
        stream = stack.enter_context(os.fdopen(file_fd, 'rb'))
        opened = os.fstat(stream.fileno())
        if not stat.S_ISREG(opened.st_mode) or identity(opened) != identity(expected):
            raise ValueError('Historical checkpoint changed before hashing.')
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
            total += len(block)
        after = os.fstat(stream.fileno())
        final = path.lstat()
        if (identity(after) != identity(expected)
                or identity(final) != identity(expected)
                or total != expected.st_size):
            raise ValueError('Historical checkpoint changed while hashing.')
    return digest.hexdigest()


def file_manifest(root: Path) -> dict[str, dict]:
    entries = {}
    for path in source_paths(root):
        name = path.relative_to(root).as_posix()
        if not safe_name(name):
            raise ValueError('Unsafe source filename.')
        # Use the same no-follow descriptor-relative source read as the ZIP
        # exporter. The previous sha256(path) followed any symlink swapped
        # in after source_paths(), even though the original scan rejected it.
        data, verified_stat = read_verified_source(root, path)
        entries[name] = {
            'sha256': hashlib.sha256(data).hexdigest(),
            'size': len(data),
            'executable': bool(verified_stat.st_mode & stat.S_IXUSR),
        }
    missing = REQUIRED_FILES - entries.keys()
    if missing:
        raise ValueError('Missing required project files: ' + ', '.join(sorted(missing)))
    return entries


def validate_archive(archive_path: Path, expected: dict[str, dict]) -> None:
    with zipfile.ZipFile(archive_path) as archive:
        names = archive.namelist()
        if len(names) != len(set(names)) or set(names) != set(expected):
            raise ValueError('ZIP file list does not match the complete source manifest.')
        for entry in archive.infolist():
            if (not safe_name(entry.filename) or entry.is_dir()
                    or stat.S_ISLNK(entry.external_attr >> 16)
                    or not include(Path(entry.filename), Path('.'))):
                raise ValueError('Unsafe or excluded ZIP entry.')
            info = expected[entry.filename]
            if bool((entry.external_attr >> 16) & stat.S_IXUSR) != info.get('executable', False):
                raise ValueError('ZIP file mode differs from the source manifest.')
            digest = hashlib.sha256()
            with archive.open(entry) as stream:
                for block in iter(lambda: stream.read(1024 * 1024), b''):
                    digest.update(block)
            if entry.file_size != info['size'] or digest.hexdigest() != info['sha256']:
                raise ValueError('ZIP contents differ from the source manifest.')
        if archive.testzip() is not None:
            raise ValueError('Corrupt ZIP entry.')


def create_patch(root: Path, base: str, output: Path, names: set[str],
                 temporary: Path) -> None:
    # Start at the base so excluded tracked paths stay unchanged and cannot leak.
    env = dict(os.environ, GIT_INDEX_FILE=str(temporary / 'checkpoint.index'),
               GIT_LITERAL_PATHSPECS='1')
    git(root, 'read-tree', base, env=env)
    base_names = git(root, 'ls-tree', '-r', '--name-only', '-z', base).split(b'\0')
    selected = set(names)
    for raw in base_names:
        if raw:
            name = os.fsdecode(raw)
            if include(root / name, root):
                if not safe_name(name):
                    raise ValueError('Unsafe filename in the base commit.')
                selected.add(name)
    if selected:
        paths = b''.join(os.fsencode(name) + b'\0' for name in sorted(selected))
        git(root, 'add', '--all', '--force', '--pathspec-from-file=-',
            '--pathspec-file-nul', env=env, data=paths)
    output.write_bytes(git(root, 'diff', '--cached', '--binary', '--full-index',
                           '--no-ext-diff', '--no-textconv', base, env=env))


def validate_patch(root: Path, base: str, patch: Path,
                   expected: dict[str, dict], temporary: Path) -> None:
    clean = temporary / 'clean-base'
    git(root, 'clone', '--quiet', '--shared', '--no-checkout', str(root), str(clean))
    git(clean, 'checkout', '--quiet', '--detach', base)
    git(clean, 'apply', '--check', '--binary', '--allow-empty', str(patch))
    git(clean, 'apply', '--binary', '--allow-empty', str(patch))
    if file_manifest(clean) != expected:
        raise ValueError('Applied patch does not reproduce the complete source manifest.')


@contextlib.contextmanager
def exclusive_checkpoint_output(output_dir: Path):
    """Keep versioned artifacts and stable aliases under one writer.

    mkdir is atomic across processes. A hard-crash lock intentionally remains
    in place: never steal it and risk publishing over a running checkpoint.
    """
    lock = output_dir / '.checkpoint.lock'
    try:
        lock.mkdir()
    except FileExistsError as error:
        raise ValueError('Checkpoint publication already in progress.') from error
    try:
        yield
    finally:
        lock.rmdir()


def create_checkpoint(root: Path, output_dir: Path, *, base: str, label: str,
                      now: datetime | None = None) -> dict:
    root, output_dir = root.resolve(), output_dir.resolve()
    if output_dir.is_relative_to(root):
        raise ValueError('Write checkpoints outside the project directory.')
    if not LABEL.fullmatch(label):
        raise ValueError('Label must use 1–64 ASCII letters, digits, dots, underscores or hyphens.')
    base_commit = git(root, 'rev-parse', '--verify', '--end-of-options',
                      base + '^{commit}').decode().strip()
    head = git(root, 'rev-parse', '--verify', 'HEAD').decode().strip()
    branch = git(root, 'rev-parse', '--abbrev-ref', 'HEAD').decode().strip()
    version, build = read_version(root)
    moment = now or datetime.now(timezone.utc)
    if moment.tzinfo is None:
        raise ValueError('Checkpoint timestamp must include a timezone.')
    timestamp = moment.astimezone(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
    stem = f'Wuerfelraunen_{version}+{build}_{timestamp}_{label}'
    names = {
        'archive': f'{stem}_Vollprojekt.zip',
        'patch': f'{stem}_Aenderungen.patch',
        'manifest': f'{stem}_Dateimanifest.json',
        'checksums': f'{stem}_SHA256SUMS.txt',
    }
    if any((output_dir / name).exists() for name in names.values()):
        raise ValueError('A checkpoint with this version, timestamp and label already exists.')
    expected = file_manifest(root)
    metadata = {
        'format_version': 1, 'app_version': f'{version}+{build}',
        'created_utc': moment.astimezone(timezone.utc).isoformat(),
        'label': label, 'base_commit': base_commit, 'head_commit': head,
        'branch': branch,
        'working_tree_dirty': bool(git(root, 'status', '--porcelain', '--untracked-files=normal')),
        'patch_source': 'filtered working tree, including untracked source and deletions',
        'validation': {'archive_content_hashes': True, 'git_apply_check': True,
                       'applied_patch_content_hashes': True},
        'file_count': len(expected), 'files': expected,
    }
    output_dir.mkdir(parents=True, exist_ok=True)
    with exclusive_checkpoint_output(output_dir):
        with tempfile.TemporaryDirectory(prefix='.checkpoint-', dir=output_dir) as temp:
            staging = Path(temp)
            archive, patch, manifest, sums = (staging / names[key]
                                              for key in ('archive', 'patch', 'manifest', 'checksums'))
            create_archive(root, archive, layout='root')
            validate_archive(archive, expected)
            create_patch(root, base_commit, patch, set(expected), staging)
            validate_patch(root, base_commit, patch, expected, staging)
            manifest.write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + '\n',
                                encoding='utf-8')
            # Include older versioned artifacts too, so the stable list remains useful.
            historical_files = previous_checkpoint_files(output_dir)
            checksum_files = {name: path for name, (path, _) in historical_files.items()}
            checksum_files.update({path.name: path for path in (archive, patch, manifest)})
            latest = staging / LATEST
            shutil.copyfile(archive, latest)
            checksum_files[LATEST] = latest
            sums.write_text(''.join(
                f'{sha256_previous_checkpoint(output_dir, name, historical_files[name][1]) if name in historical_files else sha256(path)}  {name}\n'
                for name, path in sorted(checksum_files.items())
            ), encoding='utf-8')
            # All verification finishes before replacing either stable alias.
            for key in ('archive', 'patch', 'manifest', 'checksums'):
                os.replace(staging / names[key], output_dir / names[key])
            os.replace(latest, output_dir / LATEST)
            stable_sums = staging / 'SHA256SUMS.txt'
            shutil.copyfile(output_dir / names['checksums'], stable_sums)
            os.replace(stable_sums, output_dir / 'SHA256SUMS.txt')
    return {**{key: str(output_dir / name) for key, name in names.items()},
            'latest_archive': str(output_dir / LATEST),
            'latest_checksums': str(output_dir / 'SHA256SUMS.txt'),
            'base_commit': base_commit, 'head_commit': head, 'branch': branch,
            'file_count': len(expected)}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--output-dir', type=Path, required=True)
    parser.add_argument('--base', required=True, help='Explicit Git commit or ref used by git apply.')
    parser.add_argument('--label', required=True, help='Short checkpoint description used in filenames.')
    args = parser.parse_args()
    try:
        result = create_checkpoint(ROOT, args.output_dir, base=args.base, label=args.label)
    except (ValueError, OSError, zipfile.BadZipFile) as error:
        parser.error(str(error))
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
