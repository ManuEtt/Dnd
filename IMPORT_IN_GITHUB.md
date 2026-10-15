# Projekt-Import – Aetheria 0.3.5+11

Vollständiger Projektquellstand zur GitHub-Übertragung, ohne äußeren `Dnd/`-Ordner.

1. Dieses ZIP lokal entpacken und die enthaltenen Unterordner `app/`, `backend/`, `scripts/`, `docs/` und `.github/` in die Wurzel von https://github.com/ManuEtt/Dnd übernehmen.
2. Einen **neuen Branch** ab `main` verwenden; vorhandene Dateien mit den neuen Versionen ersetzen, keine fremden Commits überschreiben.
3. Die versteckten `.github`-Dateien und Build-Wrapper ebenfalls übertragen. **Nicht die ZIP selbst als einzige Datei hochladen**.
4. Unter GitHub **Actions → Android-Alpha bauen** die vollständige Prüfung (Python, Backend, Flutter Analyse, Flutter Tests, APK und JVM-Tests) abwarten.
5. Nur wenn alle Jobs grün sind mergen; unter **Artifacts** kannst du die neue APK laden. Auf Android zusätzlich Rückblick und Mira-Dialoge prüfen.

Basis: GitHub `main` Commit `239ee5f7d333a6388159e7d431039abb92e936b7` (0.3.4+10).
Änderungen: `app/lib/domain/game_engine.dart`, `app/lib/ui/app.dart`,
`app/pubspec.yaml`, `app/test/memory_recall_test.dart`,
`app/test/ui_app_test.dart` und begleitende Dokumentation.

Kein SQLite-Schemawechsel, keine neuen Abhängigkeiten, kein neuer API-Schlüssel.
Lokale Python-Strukturtests sind möglich; Flutter/Dart und Android SDK sind
in der Paketumgebung nicht vorhanden. Der neue Stand darf daher vor erfolgreicher
GitHub-CI nicht als vollständig getestet oder installierbar bezeichnet werden.
