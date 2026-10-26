# Chat C – Kampf-Zugfolge bei 200 % Systemschrift

**Datum:** 26.10.2026 (Europe/Berlin)  
**Projekt:** Würfelraunen – Der lebendige Spielleiter  
**Basis-main:** `5f9a01dd73f68ad4f9e226f859a8ca87803b8337`  
**Branch:** `feat/chat-c/turn-tracker-large-text-20261026`  
**PR:** Bei Veröffentlichung aktualisieren.

## Problem

In `FantasyCombatTurnTracker` sind die bestätigten Helden-/Gegnernamen auf maximal zwei Zeilen begrenzt, während die Initiative und das Zuglabel rechts dieselbe Zeile beanspruchen. Auf Android bei 320/360 dp und 200 % Schrift schneidet das lange Namen ab. Es darf weder die bestätigte Initiativreihenfolge noch einen aktiven Zug umdeuten.

## IMPLEMENTIERT

- Nur `app/lib/ui/fantasy_combat_turn_tracker.dart`: ab 180 % Textskalierung bei unter 500 dp trennen sich vollständige Namensdarstellung und Initiative-/Aktivmarker in vertikale Bereiche. Namen dürfen beliebig umbrechen, ansonsten bleiben die kompakten zwei Zeilen und die horizontale Darstellung unverändert.
- Vorhandene Screenreader-Aussagen über Held/Gegner, Initiativwert, aktiven Zug oder beendetem Kampf bleiben 1:1 bestätigt und unverändert.
- Ausschließlich Präsentationscode: keine Aktion, keine Kampagnenmutation, keine neue Würfel-/Initiativentscheidung, keine Änderungen an Domain oder Storage.

## Regressionen

In `app/test/fantasy_combat_turn_tracker_test.dart` drei Tests ergänzt: zwei positiv bei 320/360 dp und 200 % auf volle Namen, vertikale Anordnung, bestehende Semantik und aktiven Zug; zwei Negativfälle (unbekannte Initiative bei aktivem Gegner und beendete Begegnung) in Widgettests. Namen und Initiativwerte bleiben vom Widget her unverändert.

## GETESTET

Testcode vorhanden. GitHub-Actions-/Flutter-Analyse und gesamte Flutter-/Android-/Backend-CI für den finalen PR-Head **noch abzunehmen**. Temporärer Formatter-Workflow `chat-c-turn-format.yml` wird vor Veröffentlichung des PR entfernt. Niemals aus einer erfolgreichen früheren CI auf eine neue Datei schließen.

## NICHT GETESTET / BLOCKIERT

Keine manuelle Android-/TalkBack-Geräteabnahme, keine App-Store-Signatur, keine lokale Flutter-/Dart-Ausführungsumgebung in der GitHub-Connector-Sitzung. Die vollständige CI muss ein gültiges Test- und Build-Ergebnis liefern.

## Kompatibilität und Parallelkoordination

- App `0.8.40+90`, SQLite 2 und JSON 1 aus `main` unverändert.
- Bestehende PRs #178, #192, #197 sowie parallele #179–#196 verändern `fantasy_combat_turn_tracker.dart` und dessen Testdatei nicht; ihre Dokumentationsabschnitte in README und CODEX_CHECKPOINT sind bei Integrationen zu erhalten.
- Frühere Chat-C-PR #185 ist gemergt. Andere offene PRs nicht selbständig mergen und kein Force-Push auf fremde Branches.

## NÄCHSTER SCHRITT

Bei erfolgreicher CI PR-Text/Checkpoint ergänzen, Merge offen lassen; danach ein weiteres unabhängiges Fantasy-UI-Element mit gezielten Screenreader- und 320-dp-Tests auswählen.
