#!/usr/bin/env python3
"""Check common incomplete GitHub uploads before installing build tools."""
from pathlib import Path
import argparse
import json
import re
import stat
import sys
import zipfile
import zlib

ROOT = Path(__file__).resolve().parent.parent
REQUIRED_FILES = (
    'README.md', '.gitattributes', '.gitignore',
    '.github/workflows/android-build.yml',
    'app/pubspec.yaml', 'app/pubspec.lock', 'app/lib/main.dart',
    'app/lib/domain/ability_generation.dart', 'app/lib/ui/ability_assignment_dialog.dart',
    'app/assets/demo.json',
    'app/android/settings.gradle.kts', 'app/android/app/build.gradle.kts',
    'app/android/app/src/main/AndroidManifest.xml',
    'app/android/gradlew', 'app/android/gradlew.bat',
    'app/android/gradle/wrapper/gradle-wrapper.jar',
    'app/android/gradle/wrapper/gradle-wrapper.properties',
    'backend/package.json', 'backend/package-lock.json', 'backend/src/server.ts',
)
WRAPPER_MAIN = 'org/gradle/wrapper/GradleWrapperMain.class'
# A copied Gradle wrapper is small. Bound validation work before ZIP CRC reads:
# a compressed archive with a tiny on-disk footprint can expand enormously.
MAX_WRAPPER_JAR_BYTES = 16 * 1024 * 1024
MAX_WRAPPER_UNCOMPRESSED_BYTES = 16 * 1024 * 1024
MAX_WRAPPER_ENTRIES = 512


def _gradle_logical_lines(text: str):
    """Join Java-properties continuation lines before inspecting keys.

    Odd trailing backslashes continue a logical line. Leading whitespace on
    subsequent physical lines is ignored by java.util.Properties.
    """
    pending = ''
    continued = False
    for physical in text.splitlines():
        fragment = physical.lstrip(' \t\f') if continued else physical
        trailing = len(fragment) - len(fragment.rstrip('\\'))
        if trailing % 2:
            pending += fragment[:-1]
            continued = True
            continue
        yield pending + fragment
        pending = ''
        continued = False
    if continued:
        yield pending


def _decode_java_property_key(raw: str) -> str | None:
    """Interpret Java Properties key escapes without normalizing their value."""
    decoded = []
    index = 0
    while index < len(raw):
        char = raw[index]
        if char != '\\':
            decoded.append(char)
            index += 1
            continue
        index += 1
        if index >= len(raw):
            return None
        escape = raw[index]
        if escape == 'u':
            digits = raw[index + 1:index + 5]
            if len(digits) != 4 or re.fullmatch(r'[0-9a-fA-F]{4}', digits) is None:
                return None
            decoded.append(chr(int(digits, 16)))
            index += 5
            continue
        decoded.append({'t': '\t', 'r': '\r', 'n': '\n', 'f': '\f'}.get(escape, escape))
        index += 1
    return ''.join(decoded)


def unique_gradle_property(text: str, key: str) -> str | None:
    """Require exactly one effective Java-Properties declaration of *key*.

    Java supports escaped key names (including backslash-u escapes) and continued physical
    lines. Comparing the raw spelling could approve a safe URL while Gradle
    uses a second, hidden declaration. Leave values in their original form
    for the existing strict HTTPS/SHA-256 checks.
    """
    candidates: list[str] = []
    for line in _gradle_logical_lines(text):
        stripped = line.lstrip(' \t\f')
        if not stripped or stripped.startswith(('#', '!')):
            continue
        index = 0
        while index < len(stripped):
            char = stripped[index]
            if char == '\\':
                index += 2
                continue
            if char in ' \t\f=:':
                break
            index += 1
        decoded_key = _decode_java_property_key(stripped[:index])
        if decoded_key != key:
            continue
        suffix = stripped[index:].lstrip(' \t\f')
        if suffix.startswith(('=', ':')):
            suffix = suffix[1:]
        candidates.append(suffix.strip())
    return candidates[0] if len(candidates) == 1 else None


def _has_symlink_component(root: Path, relative_path: str) -> bool:
    """Reject links in a required file or any of its parent directories.

    Checking only Path.is_file() follows symlinks and can mistake external
    files for uploaded project contents.
    """
    current = root
    for part in Path(relative_path).parts:
        current = current / part
        if current.is_symlink():
            return True
    return False


def verify_project(root: Path) -> list[str]:
    """Return safe, actionable errors; allow arbitrary additional project files."""
    if not root.is_dir():
        return ['Der gewählte Projektordner existiert nicht.']
    if not (root / 'app/pubspec.yaml').is_file() and (root / 'Dnd/app/pubspec.yaml').is_file():
        return [
            'Zusätzlicher Ordner Dnd/ erkannt. README.md, app/, backend/ und '
            '.github/ müssen direkt in der Repositorywurzel liegen. '
            'Die Inhalte aus Dnd/ in die Wurzel übertragen.',
        ]
    errors = []
    for name in REQUIRED_FILES:
        path = root / name
        if _has_symlink_component(root, name):
            errors.append(
                f'Pflichtdatei oder Elternverzeichnis ist ein symbolischer Link: {name}. '
                'Originaldatei aus dem Quell-ZIP übernehmen.'
            )
            continue
        if not path.is_file():
            hint = ' Versteckte Dateien beim Entpacken und Upload einblenden.' if name.startswith('.') else ''
            errors.append(f'Pflichtdatei fehlt: {name}.{hint}')
        elif path.stat().st_size == 0:
            errors.append(f'Pflichtdatei ist leer: {name}. Aus dem Quell-ZIP erneut übernehmen.')

    for name in ('backend/package.json', 'backend/package-lock.json'):
        path = root / name
        if (not _has_symlink_component(root, name)
                and path.is_file() and path.stat().st_size):
            try:
                if not isinstance(json.loads(path.read_text(encoding='utf-8')), dict):
                    raise ValueError('object expected')
            except (OSError, UnicodeError, ValueError):
                errors.append(f'Ungültige JSON-Datei: {name}. Originaldatei aus dem Quell-ZIP übernehmen.')

    wrapper = root / 'app/android/gradle/wrapper/gradle-wrapper.jar'
    if (not _has_symlink_component(root, 'app/android/gradle/wrapper/gradle-wrapper.jar')
            and wrapper.is_file() and wrapper.stat().st_size):
        try:
            if wrapper.stat().st_size > MAX_WRAPPER_JAR_BYTES:
                raise ValueError('wrapper JAR is too large')
            with zipfile.ZipFile(wrapper) as archive:
                # Reject oversized or excessively populated compressed archives
                # before testzip() decompresses any member or read() loads the class.
                members = archive.infolist()
                if (len(members) > MAX_WRAPPER_ENTRIES
                        or any(member.file_size < 0 for member in members)
                        or sum(member.file_size for member in members)
                        > MAX_WRAPPER_UNCOMPRESSED_BYTES):
                    raise ValueError('wrapper JAR has excessive expanded size')
                # A valid CRC does not make duplicate ZIP names or path
                # traversal unambiguous. Reject these before reading the JAR.
                names = [member.filename for member in members]
                if len(names) != len(set(names)):
                    raise ValueError('duplicate wrapper JAR entries')
                for member in members:
                    name = member.filename
                    segments = name.rstrip('/').split('/')
                    if (not name or name.startswith('/') or '\\' in name
                            or re.match(r'^[A-Za-z]:', name)
                            or any(segment in ('', '.', '..') for segment in segments)
                            or any(ord(char) < 32 or ord(char) == 127 for char in name)
                            or stat.S_ISLNK(member.external_attr >> 16)):
                        raise ValueError('unsafe wrapper JAR entry')
                if (archive.testzip() is not None
                        or not archive.read(WRAPPER_MAIN).startswith(b'\xca\xfe\xba\xbe')):
                    raise ValueError('invalid wrapper')
        except (OSError, KeyError, ValueError, RuntimeError, zipfile.BadZipFile, zlib.error):
            errors.append(
                'Gradle-Wrapper-JAR enthält keinen gültigen Startcode oder ist beschädigt. '
                'app/android/gradle/wrapper/gradle-wrapper.jar unverändert aus dem Quell-ZIP übernehmen.',
            )



    properties = root / 'app/android/gradle/wrapper/gradle-wrapper.properties'
    if (not _has_symlink_component(root, 'app/android/gradle/wrapper/gradle-wrapper.properties')
            and properties.is_file() and properties.stat().st_size):
        try:
            text = properties.read_text(encoding='utf-8')
        except (OSError, UnicodeError):
            text = ''
        checksum = unique_gradle_property(text, 'distributionSha256Sum')
        if checksum is None or re.fullmatch(r'[a-fA-F0-9]{64}', checksum) is None:
            errors.append('Gradle-Distributionsprüfsumme fehlt, ist mehrfach oder ungültig in gradle-wrapper.properties.')
        distribution_url = unique_gradle_property(text, 'distributionUrl')
        if (distribution_url is None or re.fullmatch(
                r'https\\?://[^\s]+/gradle-\d+\.\d+(?:\.\d+)?-(?:all|bin)\.zip',
                distribution_url) is None):
            errors.append('Gradle benötigt genau eine gültige festgelegte HTTPS-Distribution in gradle-wrapper.properties.')

    launcher = root / 'app/android/gradlew'
    if (not _has_symlink_component(root, 'app/android/gradlew')
            and launcher.is_file() and launcher.stat().st_size):
        try:
            first_line = launcher.read_bytes().split(b'\n', 1)[0]
            if not first_line.startswith(b'#!') or first_line.endswith(b'\r'):
                errors.append('app/android/gradlew benötigt einen Unix-Shebang mit LF-Zeilenende; Originaldatei übernehmen.')
        except OSError:
            errors.append('app/android/gradlew kann nicht gelesen werden.')
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('root', nargs='?', type=Path, default=ROOT, help='Repositorywurzel (Standard: Projektordner dieses Skripts)')
    args = parser.parse_args()
    errors = verify_project(args.root)
    if errors:
        print('Projektübertragung unvollständig:', file=sys.stderr)
        for error in errors:
            print(f'- {error}', file=sys.stderr)
        print('Anleitung: docs/UPLOAD_TO_GITHUB.md. Danach diese Prüfung erneut ausführen.', file=sys.stderr)
        return 1
    print('Projektstruktur, Pflichtdateien und Gradle-Wrapper vollständig. Anschließend Analyse, Tests und Build ausführen.')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
