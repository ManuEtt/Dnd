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
