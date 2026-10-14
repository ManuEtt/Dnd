# Korrektur-ZIP in ManuEtt/Dnd übernehmen

Das neue **Dnd-GitHub-Korrektur-0.2.3.zip** enthält die Projektdateien direkt
in der ZIP-Wurzel. Nach dem Entpacken müssen `README.md`, `app/`, `backend/`,
`scripts/` und `.github/` nebeneinander liegen. Das ältere Paket mit äußerem
`Dnd/`-Ordner bleibt lesbar; beim Übertragen sind dessen **Inhalte** zu wählen.

Die bestehende GitHub-Codebasis konnte noch nicht gelesen werden. Deshalb ist
dieses Paket ein geprüfter lokaler Stand und kein geprüfter Merge mit einer
älteren Repositoryversion. Bestehende Dateien zuerst vergleichen und auf einem
neuen Branch arbeiten. Die ZIP selbst allein als Datei im Repository startet
keinen Flutter-Build.

## Zugriff herstellen

Bei der erneuten Prüfung ist die Verbindung als `ManuEtt` angemeldet, sieht
aber keine installierten GitHub-App-Konten/Installationen. `ManuEtt/Dnd` liefert
über den Connector HTTP 404; Git liefert HTTP 403 „Write access to repository
not granted“. Das beweist keine Löschung oder Umbenennung des Repositorys.

1. Mit dem Eigentümerkonto [ManuEtt/Dnd](https://github.com/ManuEtt/Dnd) öffnen.
2. Unter [GitHub-App-Installationen](https://github.com/settings/installations)
   die ChatGPT-/Codex-Verbindung prüfen und bei einer vorhandenen Installation
   `ManuEtt/Dnd` in **Repository access** freigeben. Ist keine passende
   Installation vorhanden, die GitHub-Verbindung in ChatGPT neu einrichten.
3. Nach der Freigabe den Repositoryabruf erneut prüfen. Keine Zugangstokens,
   privaten SSH-Schlüssel oder Passwörter im Chat ausgeben.

## Über die GitHub-Webseite

1. **Dnd-GitHub-Korrektur-0.2.3.zip entpacken**. In den Ordner wechseln, der
   direkt `README.md` und `app/` enthält.
2. Im Repository einen Entwicklungsbranch erstellen, beispielsweise
   `fix/upload-and-alpha-download`. Vorhandene Dateien vergleichen.
3. Über **Add file → Upload files** die entpackten **Projektinhalte** übertragen.
   Weder die ZIP-Datei allein noch den gesamten äußeren Entpackordner als
   zusätzliche Ebene hochladen. Unter der Repositorywurzel muss
   `app/pubspec.yaml` liegen, nicht `Dnd/app/pubspec.yaml`.
4. `.github/workflows/android-build.yml`, `.gitignore` und `.gitattributes`
   ausdrücklich mit übernehmen. Manche Dateimanager blenden Punktdateien aus.
   Fehlt der Workflow, ihn über **Add file → Create new file** mit genau diesem
   Namen anlegen und seinen Inhalt aus der entpackten Datei kopieren.
5. Änderungen committen. Bei mehreren Uploads denselben Entwicklungsbranch
   verwenden; anschließend den Workflow neu starten.

GitHub begrenzt einzelne Web-Uploads auf 25 MiB pro Datei und einen Stapel auf
100 Dateien. Bei mehr Dateien kleinere Stapel verwenden. Das Quell-ZIP enthält
keine APKs, SDKs, Buildordner, persönliche Spielstände oder Geheimnisse.
Die frühere universelle Debug-APK mit etwa 136 MiB gehört nicht in den
Quellcode-Upload. Git ist für viele Dateien zuverlässiger.

Referenz: https://docs.github.com/en/repositories/working-with-files/managing-files/adding-a-file-to-a-repository

## Mit Git

Voraussetzung: vorhandener sicher eingerichteter GitHub-Zugriff.

```bash
git clone git@github.com:ManuEtt/Dnd.git
cd Dnd
git switch -c fix/upload-and-alpha-download
```

Die entpackten **Inhalte** des Korrektur-ZIPs in diesen Checkout kopieren;
vorhandene Dateien vorher vergleichen. `.git/` erhalten. Das ZIP enthält keine
Git-Historie.

```bash
python3 scripts/verify_project.py
python3 -m unittest discover -s scripts/tests -v
git status --short
git diff --check
git add README.md ARCHITECTURE.md DEVELOPMENT_STATUS.md ROADMAP.md CHANGELOG.md TESTING.md AGENTS.md THIRD_PARTY_NOTICES.md app backend docs scripts .github .gitignore .gitattributes
git diff --cached --stat
git commit -m "fix: repair project upload and provide smaller alpha APKs"
git push -u origin fix/upload-and-alpha-download
```

Die Projektprüfung braucht Python 3, aber kein Flutter oder Android SDK.
Sie erklärt fehlende Dateien, einen zusätzlichen `Dnd/`-Ordner, ungültige
Lock-JSON-Dateien oder einen beschädigten Gradle-Wrapper. Sie ersetzt weder
Flutter-Analyse noch Tests und Android-Build. Ohne Python kann der vorhandene
CI-Workflow diese Prüfung übernehmen, sobald `.github/` korrekt hochgeladen ist.

## APK aus GitHub Actions herunterladen

1. In GitHub anmelden, **Actions → Android-Alpha bauen** öffnen. Workflows
   gegebenenfalls für das Repository aktivieren.
2. Nach dem vollständigen Upload **Run workflow** für den richtigen Branch
   starten. Fehlt dieser Knopf/Workflow, zuerst den Pfad `.github/workflows/`
   prüfen. Ein ausschließlich verschachtelter Workflow startet keinen Lauf.
3. Bei einem roten Lauf den fehlgeschlagenen Schritt und dessen Fehlertext
   öffnen. Nur diesen Text, Branch und Commit weitergeben; keine Geheimnisse.
4. Bei einem grünen Lauf das Artefakt
   **lebendiger-spielleiter-alpha-kleine-apks** herunterladen. Es enthält drei
   optimierte, weiterhin mit der Debug-Testsignatur versehene Alpha-APKs:
   `app-arm64-v8a-alpha.apk` für übliche 64-Bit-Android-Geräte,
   `app-armeabi-v7a-alpha.apk` für ältere 32-Bit-ARM-Geräte und
   `app-x86_64-alpha.apk` für passende Emulatoren/Intel-Geräte.
5. Das heruntergeladene **Artefakt-ZIP entpacken** und die passende `.apk`
   installieren. Die ZIP selbst ist keine installierbare Android-App.

Die kleinen Alpha-APKs werden 30 Tage aufbewahrt. Das zusätzliche große Artefakt
**lebendiger-spielleiter-android-debug** bleibt 14 Tage verfügbar.
Ältere abgelaufene Artefakte brauchen einen neuen erfolgreichen Build. Ein
fehlgeschlagener Lauf erzeugt keine neue installierbare APK. Artefaktdownloads
benötigen Zugriff auf das Repository und eine GitHub-Anmeldung.

Die kleinen APKs verwenden alle die normale App-Buildnummer, damit sich spätere
Alpha-/Debug-Versionen mit derselben Signatur aktualisieren lassen. Sie sind
kein Store-Release. Die Debug-Signatur eines fremden GitHub-Runners kann von der
lokal bereitgestellten APK abweichen; bei einem Signaturkonflikt Spielstände
zuerst exportieren. Eine Deinstallation entfernt lokale Appdaten.

Referenz: https://docs.github.com/en/actions/managing-workflow-runs/downloading-workflow-artifacts
Gerätetest: [TESTING.md](../TESTING.md). Downloadhilfe:
[APK_DOWNLOAD.md](APK_DOWNLOAD.md).
