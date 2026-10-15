# GitHub Actions: Codex-Entwicklung entfernen (Version 0.5.4+24)

Dieses **vollständige Quellarchiv** enthält keine `.github/workflows/autonomous-development.yml` mehr. Alle normalen Builds bleiben in `.github/workflows/android-build.yml` erhalten.

**Achtung:** Ein Upload der ZIP-Dateien in ein GitHub-Repository löscht bereits vorhandene Dateien nicht automatisch. Um die Codex-Action auf GitHub wirklich zu entfernen:

```bash
git checkout -b remove-codex-actions
git rm .github/workflows/autonomous-development.yml
# anschließend die dokumentierten Änderungen aus dem vollständigen Archiv übernehmen
git add .
git commit -m "ci: automatische Codex-Entwicklung aus Actions entfernen"
git push -u origin remove-codex-actions
# PR gegen main erstellen und mergen
```

**Nur wenn GitHub mit neueren Änderungen aktualisiert wurde:** Vor der Übernahme der Dateien den aktuellen Stand von `main` prüfen, damit keine neueren Funktionen versehentlich überschrieben werden. Für die reine Abschaltung genügt es, nur die Workflow-Datei mit `git rm` zu löschen.

# Import / Release – Würfelraunen 0.5.4+24

**Änderung:** Die Schnellaktionen sind nun in einer fixierten unteren Leiste direkt oberhalb der Navigation statt im Abenteuer-Scrollbereich. Die zuletzt auf GitHub registrierte YAML-Fehlermeldung in `app/pubspec.yaml` ist zusätzlich korrigiert.

**Grundlage:** `ManuEtt/Dnd` Commit `bb5383b7a52b5052a5c2e8ce4714fe16b0e600da` (0.5.2+22), vor der Korrektur. Alle bestehenden Quelldateien und Illustrationen sind enthalten. Die technische Android-App-ID bleibt aus Update-Gründen unverändert.

ZIP entpacken und sämtliche Dateien einschließlich `.github/` direkt in die Repositorywurzel übernehmen, vorzugsweise in einen Entwicklungsbranch. Danach GitHub Actions abwarten. Nach einer erfolgreichen APK-Ausgabe auf dem Gerät prüfen, dass die Schnellaktionen beim Scrollen immer im unteren Bereich bleiben und nicht von der Tastatur verdeckt werden. **Flutter-Tests und APK-Build wurden hier mangels lokalem Flutter-SDK noch nicht durchgeführt.**

---

# Import / Release – Würfelraunen 0.5.2+22

Diese Version ändert den sichtbaren App-Namen und führt einen D&D-SRD-5.2.1-Assistenten für die zweite Klasse ein. **Die Android-applicationId bleibt gleich**, um App-Updates und alte SQLite-Daten nicht zu gefährden.

ZIP-Inhalt direkt in die GitHub-Repositorywurzel übertragen (einschließlich `.github`). Anschließend den vollständigen Workflow abwarten: Strukturprüfung, 22 Python-Tests, Backend, `flutter analyze`, `flutter test` und APK-Build. Stand bei Erstellung: keine Flutter-/Android-Abnahme für 0.5.2.

> **Importstand 0.5.1+21:** Quelle ist der geprüfte GitHub-Commit `a3a05d3888a9c0e19d3e43d2469cc849f5e1a4eb` plus CI-Fix in zwei Widgettests. Die Dateistruktur einschließlich Bilder und `.github/` muss vollständig hochgeladen werden. Bitte warten, bis die Android-GitHub-Action erfolgreich abgeschlossen ist.

## Neues Grafik-Redesign 0.5.0+20

Die ZIP enthält zusätzlich `app/assets/art/` und `app/lib/ui/fantasy_art.dart`. Bitte **alle** Unterordner unverändert hochladen. Die Grafikdateien werden über `app/pubspec.yaml` als lokale Flutter-Assets eingebunden. Nach Import `flutter analyze`, `flutter test` und den Android-Workflow ausführen. Der grüne GitHub-Workflow von 0.4.3 bestätigt nicht automatisch diese neue Version.

## Hinweis zu 0.4.3+19

Dieses ZIP behebt die CI-Fehler des hochgeladenen Standes 0.4.2+18. Projektdateien aus dem ZIP direkt in die Repositorywurzel entpacken, einschließlich `.github/`. Keine andere Versionskopie mischen. Erst nach vollständig grünem GitHub-Actions-Lauf die APK einsetzen.

# Aetheria 0.4.2+18 – Import und Abnahme

**Basis:** GitHub `main` Commit `35a7b4062c5248b288598b587da6c606bf80122d` (0.4.1+17). Enthält die vollständigen 131 Projektdateien.

1. ZIP **entpacken** und sämtliche Dateien einschließlich `.github` in einen neuen Branch des Repositories `ManuEtt/Dnd` übernehmen. Die ZIP nicht als einzige Datei hochladen.
2. Bei Versionskonflikten zuerst die neueren Änderungen prüfen und nicht unbesehen überschreiben.
3. GitHub Actions → `Android-Alpha bauen` ausführen bzw. auf den automatischen Lauf warten.
4. Erst nach grünen Flutter-Tests, nativen Tests und APK-Build das Android-Artefakt herunterladen.

**Korrigiert:** `GridView.count(mainAxisExtent: ...)` war kein gültiger Konstruktoraufruf; jetzt `GridView(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(mainAxisExtent: ...))`. Das verhindert den Fehler `undefined_named_parameter`.

**Einschränkung:** Ein Flutter-SDK steht in der lokalen Umgebung nicht bereit; die neue Version ist noch nicht auf einem Android-Gerät oder in GitHub Actions bestätigt.

---

# UI-Korrektur 0.4.1+17

Das vollständige Projektpaket basiert auf `main`-Commit `c4d0dedd851ae1085d01a26afb6c0c7ff78c8830`.
Die Änderung korrigiert Layout-Überläufe des Fantasy-Charakterbogens und enthält zusätzliche Widgettests.
Die Dateien `app/`, `backend/`, `scripts/`, `.github/` und alle Root-Dateien gehören direkt in die Repositorywurzel.

Prüfung nach dem Hochladen: GitHub Actions → „Android-Alpha bauen“; insbesondere `flutter test`, `flutter analyze` und Android-APK.

---

# GitHub-Import – Aetheria 0.4.0+16 (komplettes Fantasy-Redesign)

**GitHub-Basis:** `ManuEtt/Dnd` / `main` / `ce64d5bd10288611bd3a8482b01a32939a309f76` (0.3.9+15).

1. Die ZIP **entpacken**, nicht als einzelne ZIP-Datei in GitHub committen.
2. Empfohlen: einen neuen Branch vom angegebenen Commit erstellen. Falls `main` inzwischen weiter ist, Unterschiede prüfen und zusammenführen.
3. **Sämtliche entpackten Inhalte** direkt in die Repository-Wurzel übertragen, insbesondere `.github/` und die neue Datei `app/lib/ui/fantasy_ui.dart`, die Tests sowie `docs/UI_DESIGN_SYSTEM.md`.
4. Den GitHub-Actions-Workflow abwarten: Python, Backend, `flutter analyze`, `flutter test`, Android-APK. Ein lokal erfolgreiches Python-Testergebnis ist kein Ersatz für einen erfolgreichen Flutter-Build.
5. Auf dem Gerät Start, Heldentab, Charaktereditor/Bogen, Abenteuer/Begegnung, Inventar, Tagebuch/Handlungsstränge, Optionen und Import-/Exportdialog testen. Auch Spracheingabe, Scrollen bei geöffneter Tastatur und Sicherungen testen.

**Wichtig:** Dieses ZIP enthält vollständigen Quellcode und keine fertige APK. `main` wurde nicht direkt verändert. Es enthält keine persönlichen Spielstände oder API-Schlüssel. Die Unterschiede sind in `CHANGELOG.md` aufgelistet.


Basis: `ManuEtt/Dnd`, `main`, Commit `125fc3630722002a955a4e3479395edd6bfb6635` (0.3.8+14).

1. ZIP entpacken. Alle Dateien, auch `.github/`, direkt in die Repository-Wurzel hochladen, **nicht** die ZIP selbst.
2. Vorzugsweise einen neuen Branch von diesem Basiscommit erstellen. Bei zwischenzeitlich neueren Commits erst vergleichen/zusammenführen.
3. Besonders die neue Datei `app/lib/ui/fantasy_character_sheet.dart`, die Änderungen in `app/lib/ui/app.dart`, `app/test/fantasy_character_sheet_test.dart`, `backend/test/backend.test.ts` und die Dokumentation mit übertragen.
4. Unter **GitHub Actions** zunächst Projektprüfung, Backend, `flutter analyze`, `flutter test` und die APK-Builds abwarten. Dieses ZIP ist **Quellcode**, keine installierbare APK.
5. Auf dem Gerät unter **Helden** den Bogen eines gespeicherten Helden öffnen; dieselbe Ansicht im **Abenteuer** aufrufen. Deutsch, TP-Anzeige, sechs Attributkarten, Rettungswürfe, Zustände und Verteidigung prüfen. „Charakter bearbeiten“ muss den vorhandenen Editor öffnen.

Es werden keine API-Schlüssel oder persönlichen Spielstände im neuen Paket hinzugefügt. Der `main`-Branch wurde hier nicht verändert.
