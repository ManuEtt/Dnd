# Würfelraunen 0.7.1+41 – vollständiges Projekt importieren

**Ausgangsbasis:** `ManuEtt/Dnd`, `main` Commit `47b549125d95973b2d9e066e9a2401488ef322d2` mit Version `0.7.0+40`.

Das Vollprojekt-ZIP enthält die gesamten Flutter-, Android- und Backend-Dateien einschließlich `.github/workflows/android-build.yml` und `app/android/gradle/wrapper/gradle-wrapper.jar`. Beim Entpacken müssen `README.md`, `app`, `backend`, `.github` und `docs` unmittelbar im Projektroot liegen.

Für einen bereits bestehenden lokalen Checkout ist der begleitende Patch eine Alternative. Vor dessen Anwendung sicherstellen, dass die Basis dem obigen Commit entspricht. Bestehende Speicherdaten nicht löschen; die neuen Regeln benutzen die bereits vorhandenen Felder `spentClassResources`, `bonusActionUsed` und `enemyHitPoints` und bleiben bei `schemaVersion: 1`.

Testsequenz nach Import:

```bash
python3 scripts/verify_project.py .
python3 -m unittest discover -s scripts/tests -v
cd app
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

**Wichtig:** Ein ZIP ist keine vorgebaute APK. Neue Flutter-Tests müssen erst im Zielsystem bzw. in GitHub Actions erfolgreich laufen. Der GitHub-Connector kann derzeit das Repository lesen, aber keinen Schreibbranch erstellen (HTTP 403).

Fachliche Grenzen siehe `docs/MONK_FLURRY_0_7_1.md`.
