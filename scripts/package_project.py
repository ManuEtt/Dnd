#!/usr/bin/env python3
"""Create a source ZIP without SDKs, personal data, secrets or build caches."""
from pathlib import Path
import argparse
import hashlib
import os
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
    if name in EXCLUDED_NAMES or path.suffix.casefold() in EXCLUDED_SUFFIXES:
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

REQUIRED_FILES = {
    'app/lib/main.dart', 'app/pubspec.lock', 'backend/package-lock.json',
    '.github/workflows/android-build.yml', 'app/assets/demo.json', 'README.md',
}

def create_archive(root: Path, output: Path, *, layout: str = 'folder') -> tuple[int, str]:
    """A root layout can be copied straight into a GitHub repository."""
    if layout not in {'folder', 'root'}:
        raise ValueError('Unknown archive layout.')
    root, output = root.resolve(), output.resolve()
    if output.is_relative_to(root):
        raise ValueError('Write the archive outside the project directory.')
    paths = source_paths(root)
    relative_names = {p.relative_to(root).as_posix() for p in paths}
    missing = REQUIRED_FILES - relative_names
    if missing:
        raise ValueError(f'Missing required project files: {sorted(missing)}')
    output.parent.mkdir(parents=True, exist_ok=True)
    prefix = Path('Dnd') if layout == 'folder' else Path()
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in paths:
            archive.write(path, prefix / path.relative_to(root))
    with zipfile.ZipFile(output) as archive:
        bad = archive.testzip()
        if bad:
            raise RuntimeError(f'Corrupt ZIP entry: {bad}')
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    output.with_suffix(output.suffix + '.sha256').write_text(
        f'{digest}  {output.name}\n', encoding='utf-8',
    )
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
