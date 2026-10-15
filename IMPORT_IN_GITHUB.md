# Projekt-Import – Aetheria 0.3.6+12

Vollständiger Projektquellstand zur GitHub-Übertragung, ohne äußeren `Dnd/`-Ordner.

1. Dieses ZIP lokal entpacken und die enthaltenen Unterordner `app/`, `backend/`, `scripts/`, `docs/` und `.github/` in die Wurzel von https://github.com/ManuEtt/Dnd übernehmen.
2. Einen **neuen Branch** ab `main` verwenden; vorhandene Dateien mit den neuen Versionen ersetzen, keine fremden Commits überschreiben.
3. Die versteckten `.github`-Dateien und Build-Wrapper ebenfalls übertragen. **Nicht die ZIP selbst als einzige Datei hochladen**.
4. Unter GitHub **Actions → Android-Alpha bauen** die vollständige Prüfung (Python, Backend, Flutter Analyse, Flutter Tests, APK und JVM-Tests) abwarten.
5. Nur wenn alle Jobs grün sind mergen; unter **Artifacts** kannst du die neue APK laden. Auf Android zusätzlich Tagebuchfunktionen, Rückblicke, NPC-Notizen und Handlungsstränge prüfen.

Basis: GitHub `main` Commit `6e967080baba7de252fac378d51758a20f6556ae` (0.3.5+11).
Änderungen: Modell und Engine für Sitzungsrückblicke, Handlungsstränge und
NPC-Notizen; Controller, neuer Tagebuchdialog `campaign_memory_panel.dart`,
Tests (Domain, Widget, SQLite) und Dokumentation. Zudem korrigierter
`ui_app_test.dart`-Scrollfall aus dem letzten fehlgeschlagenen CI-Lauf.

Wichtig: **Nach Upload Flutter/Android über GitHub Actions ausführen.**
Ein früherer 0.3.5-CI-Lauf scheiterte nach 290 bestandenen Flutter-Tests;
für 0.3.6 gibt es noch keinen erfolgreichen Flutter- oder APK-Nachweis.
Kein SQLite-Schemawechsel, keine neuen Abhängigkeiten, kein API-Schlüssel.
