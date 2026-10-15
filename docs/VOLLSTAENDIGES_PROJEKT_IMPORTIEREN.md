# Vollständiges Würfelraunen-Projekt importieren (0.5.3+23)

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

- Das Paket baut auf der lokalen Version `0.5.3+23` auf; GitHub `main` war beim Zusammenstellen auf `0.5.2+22` (`bb5383b`). Zum Vermeiden verlorener Änderungen **nicht blind in `main` hochladen oder über bestehende Dateien entpacken**.
- Einen neuen Branch `auto-development` von `main` erstellen und dort den vollständigen Archivinhalt **mit verstecktem `.github/`-Ordner** übernehmen. Ein Commit und Pull Request müssen auf Änderungen seit der Archivbasis überprüft werden.
- Die GitHub-App verweigerte dem Assistenten das Schreiben (HTTP 403). Dieses Archiv ist daher nicht automatisch in GitHub eingecheckt.
- Der neue Workflow `.github/workflows/autonomous-development.yml` ist nur vorbereitet. Er bleibt inaktiv, solange die Variable `ENABLE_PAID_CODEX` nicht auf `true` gesetzt und das geheime `OPENAI_API_KEY` nicht sicher hinterlegt wurde. Jeder bezahlte Einsatz muss separat freigegeben werden.
- `android-build.yml` bietet bei CI-Läufen zusätzlich einen Quellcode-Checkpoint an; erst ein **grüner CI-Lauf** erlaubt es, die APK als getestet zu bezeichnen.

## Archivintegrität und Datenschutz

- Die externe `.sha256`-Datei enthält den SHA-256-Hash des ZIPs. Auf dem Computer `sha256sum -c DATEINAME.zip.sha256` ausführen.
- Keine privaten API-Schlüssel, Signatur-Dateien, lokalen `.env`-Dateien, `node_modules`, Build-Caches oder APKs im Quell-ZIP.
- Für dein Android-Gerät ist eine ARM64-APK nach einem erfolgreichen Build erforderlich; ein Quellcode-ZIP lässt sich nicht direkt auf dem Smartphone installieren.
