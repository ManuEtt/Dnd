# Vollständiges Import-Projekt Würfelraunen 0.5.6+26

Dieses ZIP enthält die gesamte Repositorywurzel, inklusive `app`, `backend`, `scripts`, `docs`, `.github`, Lockdateien und Assets. ZIP-Inhalt *ohne zusätzlichen äußeren Ordner* direkt in einen Arbeitsordner `Dnd` entpacken.

**Wichtig:** Im bestehenden Git-Repository Änderungen anderer Beteiligter nicht überschreiben. Vor dem Übernehmen den Branch und HEAD mit der Basis `a8e77778c171132c9d9cabdb56d5a19c9e170953` vergleichen. Vorzugsweise in einem neuen Branch die Änderungen nach Prüfung übernehmen und Pull Request erstellen.

**Neu:** Die drei Flutter-Widgettest-Fehler aus CI #38728029583 wurden lokal korrigiert. Noch **nicht** in GitHub Actions abgenommen. Keine neue installierbare APK enthalten.

**GitHub Actions:** nur `.github/workflows/android-build.yml`; kein automatischer Codex-Workflow.

Befehle:

```bash
python3 scripts/verify_project.py
python3 -m unittest discover -s scripts/tests -v
cd backend && npm ci && npm run typecheck && npm run build && npm test
cd ../app && flutter pub get && flutter analyze && flutter test
flutter build apk --debug
```

Kleine ARM64-APK nur nach allen grünen Prüfungen freigeben.
