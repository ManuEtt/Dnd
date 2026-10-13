# Entwicklungsstatus – 2026-10-13

**Gesamtstatus:** Erste lokale Implementierung; **keine funktionsgeprüfte Android-Alpha**.

## IMPLEMENTIERT (Code geschrieben, nicht gleichbedeutend mit funktioniert)

- Flutter Material-3-Ansichten: Start, Charakter, Kampagne, Spiel, Tagebuch.
- SQLite-Schema Version 1 mit Charakteren, Kampagnen und Ereignissen.
- Atomare Speicherung von Dialogzügen und optimistischem Turn-Zähler.
- Arescan-Seedspielstand und unabhängige Demo-Kampagne.
- Deterministische Würfel- und einfache Attributmodifikator-Engine.
- Lokale, regelneutrale Mock-Antworten, Android-Sprachein- und -ausgabe im Code.
- TypeScript/Fastify-Backend-Mock und GitHub-Actions-Workflowdefinition.

## GETESTET

- Backend-Logiktests: 3/3 bestanden mit Node v22.16.0 (2026-10-13).

## NICHT GETESTET

- Flutter-Compilation, `flutter analyze`, `flutter test`, Widget-Tests, Pluginintegration.
- Debug-APK, GitHub Actions, Android-Gerätebetrieb, Persistenz nach Prozessabbruch, Mikrofon, TTS.
- Backend-TypeScript-Compilation/Fastify-Serverstart.

## BLOCKIERT

- GitHub API: Branchanlage und Dateierstellung jeweils 403 `Resource not accessible by integration`. Repository-Metadaten melden zwar `push: true`, der konkrete GitHub-App-Zugriff erlaubt aktuell dennoch kein Schreiben.
- Laufzeitumgebung: keine lokale Installation von Flutter/Dart und kein Android SDK; GitHub Actions kann erst nach Upload der Dateien gestartet werden.

## NOCH NICHT IMPLEMENTIERT

- Vollständige Charakterbögen, Charakterexport/-import, vollständige SRD-5.2.1-Regelabdeckung.
- Kampfengine und gespeicherte Begegnungen, Initiative, Zauberregeln.
- Autorisierte OpenAI-/Realtime-Integration, Live-KI, Kostenlimits, Cloud-Synchronisation.
- Semantisches Langzeitgedächtnis über Eventhistorie hinaus, Multiplayer/Autorisierung.

## Nächster konkreter Schritt

Projektdateien in den Repo-Branch übertragen, CI starten, Flutter-Analyzer- und Android-Fehler korrigieren, danach Geräte-Abnahmetest. Änderungen nur als geprüfte Alpha markieren, wenn alle Abnahmekriterien tatsächlich erfüllt sind.
