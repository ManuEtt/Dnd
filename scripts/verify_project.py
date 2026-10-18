#!/usr/bin/env python3
"""Check common incomplete GitHub uploads before installing build tools."""
from pathlib import Path
import argparse
import json
import re
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
        if not path.is_file():
            hint = ' Versteckte Dateien beim Entpacken und Upload einblenden.' if name.startswith('.') else ''
            errors.append(f'Pflichtdatei fehlt: {name}.{hint}')
        elif path.stat().st_size == 0:
            errors.append(f'Pflichtdatei ist leer: {name}. Aus dem Quell-ZIP erneut übernehmen.')

    for name in ('backend/package.json', 'backend/package-lock.json'):
        path = root / name
        if path.is_file() and path.stat().st_size:
            try:
                if not isinstance(json.loads(path.read_text(encoding='utf-8')), dict):
                    raise ValueError('object expected')
            except (OSError, UnicodeError, ValueError):
                errors.append(f'Ungültige JSON-Datei: {name}. Originaldatei aus dem Quell-ZIP übernehmen.')

    wrapper = root / 'app/android/gradle/wrapper/gradle-wrapper.jar'
    if wrapper.is_file() and wrapper.stat().st_size:
        try:
            with zipfile.ZipFile(wrapper) as archive:
                if archive.testzip() is not None or not archive.read(WRAPPER_MAIN).startswith(b'\xca\xfe\xba\xbe'):
                    raise ValueError('invalid wrapper')
        except (OSError, KeyError, ValueError, RuntimeError, zipfile.BadZipFile, zlib.error):
            errors.append(
                'Gradle-Wrapper-JAR enthält keinen gültigen Startcode oder ist beschädigt. '
                'app/android/gradle/wrapper/gradle-wrapper.jar unverändert aus dem Quell-ZIP übernehmen.',
            )

    properties = root / 'app/android/gradle/wrapper/gradle-wrapper.properties'
    if properties.is_file() and properties.stat().st_size:
        try:
            text = properties.read_text(encoding='utf-8')
        except (OSError, UnicodeError):
            text = ''
        if not re.search(r'^distributionSha256Sum=[a-fA-F0-9]{64}\s*$', text, re.MULTILINE):
            errors.append('Gradle-Distributionsprüfsumme fehlt oder ist ungültig in gradle-wrapper.properties.')
        if not re.search(r'^distributionUrl=https\\?://[^\s]+/gradle-\d+\.\d+(?:\.\d+)?-(?:all|bin)\.zip\s*$', text, re.MULTILINE):
            errors.append('Gradle benötigt eine festgelegte HTTPS-Distribution in gradle-wrapper.properties.')

    launcher = root / 'app/android/gradlew'
    if launcher.is_file() and launcher.stat().st_size:
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
