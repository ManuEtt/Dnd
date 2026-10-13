# Projekt-ZIP in ManuEtt/Dnd übernehmen

Dieses ZIP enthält einen eigenständigen Projektstand. Weil das bestehende Repository nicht gelesen werden konnte, müssen bestehende Dateien vor der Übernahme verglichen werden. Die ZIP selbst als einzelne Datei im Repository ist kein ausführbares Flutter-Projekt und löst den vorgesehenen Build nicht aus.

## Über die GitHub-Webseite

1. ZIP herunterladen und vollständig entpacken; die Projektdateien liegen im enthaltenen Ordner `Dnd/`. Der richtige Projektordner enthält `README.md`, `app/`, `backend/` und den versteckten Ordner `.github/`.
2. [ManuEtt/Dnd](https://github.com/ManuEtt/Dnd) öffnen. Bei einem bestehenden Projekt einen neuen Branch, beispielsweise `feat/solo-alpha`, von dessen aktuellem Standardbranch erstellen.
3. Bestehende Dateien vergleichen. Änderungen bei Überschneidungen zusammenführen; keine funktionierende ältere App unüberprüft ersetzen.
4. Über **Add file → Upload files** die entpackten Projektinhalte in die Repositorywurzel hochladen. Nicht den äußeren ZIP-Ordner als zusätzliche Ebene hochladen. Bei Bedarf mehrere Uploads verwenden.
5. Sicherstellen, dass `.github/workflows/android-build.yml` vorhanden ist. Dateimanager blenden Punktordner häufig aus. In GitHub lässt sich der Workflow auch über **Add file → Create new file** unter genau diesem Pfad anlegen und mit dem Inhalt aus dem ZIP füllen.
6. Änderungen auf dem neuen Branch committen. Danach einen Pull Request zum Standardbranch anlegen und die Prüfungen abwarten.

Der Web-Upload kann Dateigrößen- und Mengenbeschränkungen haben. Für viele Dateien oder die Übernahme versteckter Dateien ist Git zuverlässiger.

## Mit Git

Voraussetzung ist ein Git-Client mit dem bereits sicher eingerichteten GitHub-Zugriff. Keine privaten Schlüssel oder Tokens ausgeben.

```bash
git clone git@github.com:ManuEtt/Dnd.git
cd Dnd
git switch -c feat/solo-alpha
```

Die entpackten Projektinhalte einschließlich `.github/` anschließend in dieses Verzeichnis kopieren. Vorhandene Dateien prüfen und Unterschiede zusammenführen. Das ZIP enthält keine Git-Historie und soll keinen vorhandenen `.git/`-Ordner ersetzen.

```bash
git status --short
git diff --check
git add README.md ARCHITECTURE.md DEVELOPMENT_STATUS.md ROADMAP.md CHANGELOG.md TESTING.md AGENTS.md THIRD_PARTY_NOTICES.md app backend docs scripts .github .gitignore .gitattributes
git diff --cached --stat
git commit -m "feat: add German solo-alpha application and Android build"
git push -u origin feat/solo-alpha
```

Vor dem Commit prüfen, dass keine `.env`, API-Schlüssel, Benutzerdaten, `node_modules/`, `.dart_tool/` oder `build/`-Verzeichnisse hinzugefügt wurden. Die beabsichtigten Lockdateien und der Android-Gradle-Wrapper gehören dagegen zum Projekt.

## Build ausführen und APK herunterladen

1. Im Repository **Actions** öffnen und gegebenenfalls Workflows für das Repository aktivieren.
2. **Android-Alpha bauen** auswählen. Nach einem relevanten Push oder Pull Request startet der Workflow automatisch. Mit **Run workflow** kann der ausgewählte Branch manuell gebaut werden.
3. Der Workflow installiert Java 17, Flutter 3.35.7 und Node.js 22.14.0. Er führt Backend-Typprüfung, Build und Tests sowie Flutter-Analyse und Tests aus; erst danach baut er die Debug-APK.
4. Bei einem grünen Lauf das Artefakt **lebendiger-spielleiter-android-debug** herunterladen und entpacken. Darin liegt `app-debug.apk`.
5. APK auf ein Android-Gerät übertragen, installieren und die Gerätetests aus [TESTING.md](../TESTING.md) durchführen.

Ein Fehler beim Workflow wird unter dem betroffenen Schritt angezeigt. Für eine weitere Entwicklung die relevante Fehlermeldung zusammen mit Branch und Commit bereitstellen; keine Geheimnisse aus Umgebungsvariablen kopieren. Ein GitHub-Artefakt ist zeitlich befristet und kein Store-Release.
