# Vollständiges Würfelraunen-Projekt importieren (0.5.4+24)

Dieses Archiv enthält **den vollständigen Projektquellcode**; nicht nur einen Patch. Im ZIP liegen `app/`, `backend/`, `scripts/`, `.github/`, `docs/` und die Root-Dokumentation direkt auf oberster Ebene. Die Android-APK wird **erst beim Build erzeugt**. Das Archiv ist noch kein validierter Android-Release.

## Lokal in Android Studio / VS Code / Codex

1. ZIP in einen **leeren** Ordner `Dnd` entpacken. Nicht über einen anderen Checkout hinweg entpacken.
2. Im Editor diesen Ordner als Arbeitsbereich öffnen. Für Flutter ist `Dnd/app` das Projektverzeichnis; darin liegt `pubspec.yaml`.
3. Mit Flutter 3.35.7 / Dart 3.9.2 und Java 17 (Android SDK entsprechend dem CI-Workflow):

   ```bash
   cd app
   flutter pub get
   flutter analyze
   flutter test
   flutter build apk --debug
   ```

4. Backend separat aus `Dnd/backend` mit Node.js 22.14.0 einrichten:

   ```bash
   npm ci
   npm run typecheck
   npm run build
   npm test
   ```

5. Vor dem Build im Root ausführen:

   ```bash
   python3 scripts/verify_project.py .
   python3 -m unittest discover -s scripts/tests -v
   ```

## Import in GitHub `ManuEtt/Dnd`

- Das Paket baut auf der lokalen Version `0.5.4+24` auf; GitHub `main` war beim Zusammenstellen auf `0.5.2+22` (`bb5383b`). Zum Vermeiden verlorener Änderungen **nicht blind in `main` hochladen oder über bestehende Dateien entpacken**.
- Einen neuen Branch `auto-development` von `main` erstellen und dort den vollständigen Archivinhalt **mit verstecktem `.github/`-Ordner** übernehmen. Ein Commit und Pull Request müssen auf Änderungen seit der Archivbasis überprüft werden.
- Die GitHub-App verweigerte dem Assistenten das Schreiben (HTTP 403). Dieses Archiv ist daher nicht automatisch in GitHub eingecheckt.
- **Codex aus GitHub Actions entfernt:** Das ZIP enthält keine `.github/workflows/autonomous-development.yml` und keine planmäßigen KI-Entwicklungsjobs. `android-build.yml` bleibt vollständig erhalten und führt weiterhin Qualitätstests, normale Android-APK-Builds und die versionierte Artefaktauslieferung aus. Codex kann außerhalb von GitHub Actions weiterhin manuell zur Entwicklung genutzt werden.
- **Wichtig bei einem bereits vorhandenen GitHub-Repository:** Das Kopieren/Entpacken des ZIP allein löscht die alte GitHub-Datei nicht. Sie muss explizit in einem Commit entfernt werden: `git rm .github/workflows/autonomous-development.yml` (wenn die Datei noch verfolgt wird). Nach Push/PR-Merge prüfen, dass unter GitHub → Actions kein neuer Codex-Workflow mehr starten kann. Bei akuter Abschaltung: Den Codex-Workflow bis zum Lösch-Commit über das GitHub-Actions-Menü deaktivieren.
- `android-build.yml` bietet bei CI-Läufen zusätzlich einen Quellcode-Checkpoint an. Nach erfolgreich absolvierten Tests und Builds erstellt er jetzt ein **versioniertes vollständiges Projekt-ZIP samt ARM64-APK, Release-Notizen und SHA-256-Prüfsummen**; die APK trägt bis zur Einrichtung einer stabilen Signierung noch eine Debug-Testsignatur. Erst ein **grüner CI-Lauf** erlaubt es, diese APK als getestet zu bezeichnen.

## Archivintegrität und Datenschutz

- Die externe `.sha256`-Datei enthält den SHA-256-Hash des ZIPs. Auf dem Computer `sha256sum -c DATEINAME.zip.sha256` ausführen.
- Keine privaten API-Schlüssel, Signatur-Dateien, lokalen `.env`-Dateien, `node_modules`, Build-Caches oder APKs im Quell-ZIP.
- Für dein Android-Gerät ist eine ARM64-APK nach einem erfolgreichen Build erforderlich; ein Quellcode-ZIP lässt sich nicht direkt auf dem Smartphone installieren.
