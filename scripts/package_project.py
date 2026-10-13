#!/usr/bin/env python3
"""Create a source ZIP without SDKs, personal data, secrets or build caches."""
from pathlib import Path
import argparse
import hashlib
import zipfile

ROOT = Path(__file__).resolve().parent.parent
EXCLUDED_DIRS = {
    '.git', '.dart_tool', '.gradle', '.cxx', '.idea', '.vscode', '__pycache__',
    'node_modules', 'build', 'dist', 'coverage', '.pytest_cache',
}
EXCLUDED_NAMES = {
    'local.properties', 'key.properties', '.flutter-plugins',
    '.flutter-plugins-dependencies', '.DS_Store', 'GeneratedPluginRegistrant.java',
}
EXCLUDED_SUFFIXES = {
    '.apk', '.aab', '.log', '.iml', '.jks', '.keystore', '.db', '.sqlite', '.sqlite3',
}

def include(path: Path) -> bool:
    relative = path.relative_to(ROOT)
    if any(part in EXCLUDED_DIRS for part in relative.parts):
        return False
    if path.name in EXCLUDED_NAMES or path.suffix in EXCLUDED_SUFFIXES:
        return False
    if path.name.startswith('.env') and path.name != '.env.example':
        return False
    if any(path.name.endswith(suffix) for suffix in ('-wal', '-shm', '-journal')):
        return False
    return True

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    output = args.output.resolve()
    if output.is_relative_to(ROOT):
        parser.error('Write the archive outside the project directory.')
    output.parent.mkdir(parents=True, exist_ok=True)
    paths = sorted(p for p in ROOT.rglob('*') if p.is_file() and include(p))
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in paths:
            archive.write(path, Path('Dnd') / path.relative_to(ROOT))
    with zipfile.ZipFile(output) as archive:
        bad = archive.testzip()
        if bad:
            raise RuntimeError(f'Corrupt ZIP entry: {bad}')
        required = {
            'Dnd/app/lib/main.dart', 'Dnd/app/pubspec.lock',
            'Dnd/backend/package-lock.json',
            'Dnd/.github/workflows/android-build.yml',
            'Dnd/app/assets/arescan.json', 'Dnd/README.md',
        }
        missing = required - set(archive.namelist())
        if missing:
            raise RuntimeError(f'Missing required project files: {sorted(missing)}')
    digest = hashlib.sha256(output.read_bytes()).hexdigest()
    output.with_suffix(output.suffix + '.sha256').write_text(
        f'{digest}  {output.name}\n', encoding='utf-8',
    )
    print(f'{output}: {len(paths)} files, {output.stat().st_size} bytes, SHA256 {digest}')

if __name__ == '__main__':
    main()
