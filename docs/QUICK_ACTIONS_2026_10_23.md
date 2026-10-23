# Würfelraunen – Inkrement: sichere Schnellaktionen (23.10.2026)

## Ausgangspunkt und Abgrenzung

- Tatsächlich gelesener Standardbranch: `main`, Commit `cd86636fe32cb535526c3c35778aeb97b7875219`.
- Baseline-CI: GitHub Actions [39904815269](https://github.com/ManuEtt/Dnd/actions/runs/39904815269), erfolgreich **für diesen Ausgangscommit**, nicht als Nachweis für das vorliegende Inkrement.
- Für die neuen Änderungen: Entwicklungsbranch `feat/context-safe-adventure-shortcuts-20261023`; kein Merge nach `main` und kein Löschen alter Branches.
- Der offene PR #127 verändert die Fertigkeitensuche im Charakterbogen; diese Arbeit wird nicht überschrieben.
- Für einen vollständigen UI-/Regel-/Kampagnen-Audit reichen diese Änderungen nicht; siehe `AGENTS.md`, `ARCHITECTURE.md`, `docs/SRD_5_2_1_COVERAGE_AUDIT.md`.

## Implementiert

- `app/lib/ui/app.dart`: Die Abenteuer-Eingabefunktion `_send({quickAction})` verwendet unabhängig von Text, Spracherkennung und Schnellaktion denselben `GameController.sendAction`-Pfad und bewahrt den noch nicht abgesendeten Textentwurf. Das gilt auch für Textvorgaben aus der Kampfansicht. Der Entwurf wird nur nach erfolgreicher **manueller Texteingabe** geleert.
- `app/lib/ui/app.dart`: Der Angriff-Schnellknopf ist nur bei einem bestätigten aktiven Kampf, im Heldenspielzug, ohne offene Wurf-/Todesrettungs-/Schildentscheidung aktiv. Der freie Texteingabepfad bleibt unabhängig davon verfügbar.
- `app/lib/ui/fantasy_art.dart`: Das vorhandene Fantasy-Design und die fixierte Leiste bleiben erhalten. Die vorhandene Kachel erhält ein zustandsabhängiges Disabled-Signal und eine sicht-/zugängliche Tooltip-Erklärung. Es wurden keine Spielwerte, SRD-Regeln, Assets oder Persistenzformate geändert.

## Neue Regressionstests (noch von CI auszuführen)

- `app/test/fantasy_action_controls_test.dart`: Angriffsaktion ohne bestätigten Kampf deaktiviert, Tooltip begründet Sperre; Erkundungsaktion bleibt verfügbar.
- `app/test/ui_app_test.dart`: Nicht abgesendeter freier Text bleibt nach „Untersuchen“ erhalten; die Aktion wird dennoch über die bestätigte Spiellogik in den Spielstand geschrieben.

**Lokaler Status:** Flutter/Dart-SDK im aktuellen Ausführungssystem nicht vorhanden. Deshalb sind `dart format`, `flutter analyze`, `flutter test`, Android-Build, Emulator und reale Screenshots hier **nicht ausgeführt**. Die Tests sind implementiert, nicht als bestanden ausgewiesen. CI des neuen Branches und Geräteprüfung auswerten.

## Aktuelle Lücken und Fortsetzung

1. Auf dem Entwicklungsbranch `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, gezielte Widgettests und `flutter test` sowie vollständige Android-CI kontrollieren; Fehler korrigieren, bevor gemergt wird.
2. Auf Android die Schnellaktionsleiste mit offener Tastatur, Textskalierung, Gestenleiste, 320-dp-/360-dp- und breiter Ansicht prüfen; echte Screenshots beilegen. Flutter-Widgettests ersetzen keine Realgeräteprüfung.
3. Nächste funktionale Etappe: korrelierte, persistente Handlungs-IDs für Text, Sprachbefehle und Schnellaktionen; vor jedem Wurf eine getrennte Entscheidung/Bestätigung, danach atomare Übernahme. Mehrfachantworten und Absturz-Wiederanlauf mit SQLite-Integrationstests prüfen. Bestehende `GameEngine`, `GameController` und Schema 1 nicht ohne getestete Migration umbauen.
4. Weiterhin fehlen umfassend getrennte Wissensbereiche der NPCs, Mehrspielerzuordnung und vollständige SRD-5.2.1-Automatik. Keine Vollständigkeit behaupten.

Diese UI-Korrektur führt keine neuen D&D-Regeln ein; daher ist keine neue SRD-Regelreferenz für einen mechanischen Effekt erforderlich.
