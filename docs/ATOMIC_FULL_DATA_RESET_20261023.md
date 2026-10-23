# Atomarer vollständiger Datenreset – 23.10.2026

## Problem

Vor Version 0.8.33+83 führte `GameController.deleteAllData` mehrere getrennte
Repository-Löschvorgänge für Kampagnen, Helden, PlayerActionOutbox und
Einstellungen nacheinander aus. Bei einem SQLite-/Laufzeitfehler konnte nur
ein Teil der lokalen Nutzerdaten gelöscht sein. Die reguläre Kampagnenlöschung
bleibt eine davon unabhängige Operation.

## Umsetzung

`AtomicUserDataReset` in `app/lib/data/campaign_repository.dart` ist ein
zusätzlicher Vertrag. `SqliteCampaignRepository.deleteAllUserData()` leert
in einer SQLite-Transaktion:

1. `game_events`
2. `campaign_revisions`
3. `campaigns`
4. `characters`
5. `settings`
6. `pending_player_actions`

Dies ist eine **ausdrücklich vom Nutzer bestätigte Komplettlöschung**. Der
Controller verwendet den Vertrag, wenn verfügbar, und aktualisiert erst
nach dem erfolgreichen Commit die angezeigte Kampagne. Bestehende andere
Implementierungen der `CampaignRepository`-Schnittstelle bleiben kompatibel,
haben aber weiterhin keinen garantierten transaktionalen Komplettreset.

Eine fehlgeschlagene SQLite-Operation innerhalb der Transaktion verwirft
auch frühere Löschungen desselben Resets. Nach einem erfolgreichen Commit
können andere, weiterhin aktive Verbindungen neue Daten schreiben; eine
globale Sperre über alle künftigen Nutzeraktionen hinweg ist nicht Bestandteil
dieses Pakets. Es wurde kein neues SQLite-Schema benötigt (weiter Version 2).
JSON-Kampagnenexport bleibt bei `schemaVersion=1`. Externe KI-Anfragen,
Würfel, XP und andere D&D-/Storyregeln wurden nicht verändert.

## Regression

`app/test/atomic_full_data_reset_test.dart`:

- Start mit gespeicherter Kampagne, Eventjournal, Charakterarchiv,
  Einstellungen und einer ausstehenden Spielerhandlung
- Bestätigter Reset leert alle sechs Tabellen; ein erneuter Reset ist harmlos
- Neustart derselben SQLite-Datei bleibt leer
- Ein SQLite-Trigger erzwingt einen `ABORT` beim Löschen des Charakterarchivs,
  nachdem frühere Tabellenlöschungen versucht wurden. Alle Datensätze und
  der sichtbare Controllerzustand bleiben bei diesem Fehler erhalten.
- Nach Entfernung des Testtriggers ist der gleiche Reset erfolgreich.

## Abnahme und Grenzen

```bash
cd app
flutter test test/atomic_full_data_reset_test.dart
flutter test
flutter analyze
flutter build apk --debug
```

Zusätzlich vollständiger Android-GitHub-Actions-Workflow, native Tests und
eine echte Geräteabnahme. Nur der vollständig **abgeschlossene** CI-Lauf
auf dem relevanten Code-HEAD ist als Testbeleg zulässig. Eine echte Android-
Installation, Update von SQLite-Schema 1 auf 2, Backup/Restore und spätere
Freigabesignierung bleiben separat nachzuweisen.
