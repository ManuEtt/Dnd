# Branch-Migration: Klassenregeln, 28.10.2026

Ausgangs-Main `dd0c2e94ccf0995c6070010b6af1df315205b36a`;
isolierter Arbeitsbranch `integration/migration-rules-20261028`.
Die regulären Merge-Commits erhalten die sechs Quellköpfe als Vorfahren;
keine Änderung an `main`, kein Push und keine Branch-Löschung in diesem Teilpaket.

| PR | ursprünglicher Kopf | übernommener Umfang |
| --- | --- | --- |
| #313 | `f5fe63bf2d314f0066b834819e01d3ff344a8926` | Entrinnen als bestätigte GE-Halbschadens-Vorprüfung und Bogenanzeige; keine automatische TP-Buchung |
| #332 | `7a2c0098228611037543047120b8807a4e3bf15f` | Quelle der Inspiration: bestätigter Zauberplatztausch, revisionsgeschützter Controller-/SQLite-Pfad, Bogen und Auswahldialog |
| #336 | `3a565a21bdfdf2c2b381f49c4d8c446ae145ca57` | Unbezwingbare Stärke in vorbereiteten Stärke-Proben und manuellen Stärke-Rettungswürfen; Rohwurf getrennt |
| #339 | `2eac8f2b21281a6d98257e1a3ee2a37b1c509703` | Überlegene Inspiration bei drei bestätigten Initiative-/Kampfbeginnpfaden |
| #340 | `0a551fa8b531318b97c85ab2313dac2c2fbce7b4` | Unermüdlich: kurze Rast und bestätigte Magieaktion für temporäre TP |
| #348 | `5a44dc4b9ab4e5b8648f72439b414a2915cc42bb` | Fünf Produkt-/Testdateien bereits bytegleich Main; ausschließlich historische Verbindung, keine erneute Attributsvergabe |

## Konfliktentscheidungen und Fehlerkorrektur

- Die ältere Barden-Initiative basierte auf `MonkPerfectFocus`. Alle drei Pfade
  verwenden weiterhin die aktuelle `MonkInitiativeFeatures`-Logik samt freiwilligem
  Unheimlichem Stoffwechsel, anschließend die Bardenregel. Ereignisse behalten
  Fokus-Erholung, optionale Heilung/Wurf/Nutzung und Barden-Erholung getrennt.
- Die widersprüchlichen Barden-Importtests behalten beide sinnvollen Prüfungen:
  bestätigtes Charisma und stabilen zweiten JSON-Roundtrip.
- Regel-Fassaden exportieren alle bestehenden und neuen Module. Kein alter
  Fremdbranch überschreibt aktuelle Mechaniken.
- Der neue Barden-Dialog hatte bei 320/360 dp, 200 % Schrift und einer simulierten
  Tastatur einen reproduzierten `RenderFlex`-Überlauf (bei 360 dp 80 Pixel).
  `AlertDialog.scrollable` hält Text und beide Aktionen erreichbar.
- Vier zusätzliche Widgetfälle prüfen Öffnen ohne Mutation, Abbruch ohne Kosten,
  semantische Aktionsnamen und ausdrückliche Bestätigung eines Vorschlags. Ein
  erhaltener Vorschlag verändert den Originalcharakter nicht; Ressourcen ändern
  sich erst bei gültiger Anwendung.
- Alte optimistische „noch nicht in main“-Kapstonehinweise werden nicht als neuer
  Live-Status eingesetzt. Originale Quellen bleiben durch Git-Eltern und die
  zentrale Migration-Sicherung erhalten.

## Tatsächliche Prüfung

**GETESTET:** 95 gezielte bestehende Flutter-Regel-/UI-/SQLite-Tests bestanden;
zusätzlich vier neue Barden-Dialogtests bestanden. Analyzer ohne Befund;
Domain-Grenzen und maschinenlesbare SRD-Matrixprüfung erfolgreich.
Die Regression wurde auch gegen den alten nicht scrollenden Dialog ausgeführt:
alle vier Fälle scheiterten am Layout; mit Korrektur alle vier erfolgreich.
Die zunächst fehlerhafte SemanticsHandle-Bereinigung im neuen Test wurde durch
`try/finally` korrigiert, keine Produktprüfung deaktiviert.

**NICHT GETESTET:** gemeinsame vollständige Suite aller Migrationsgruppen,
GitHub-CI des finalen Gesamt-PRs, Android-Build und echtes Gerät in diesem
Teilpaket. Der leitende Integrationsdurchlauf muss sie separat ausführen.

**BLOCKIERT:** keine lokale Toolchain-Blockade; keine echten Android-Geräte.

**NOCH NICHT IMPLEMENTIERT:** vollständige Entrinnen-TP-/Schadensbuchung,
sämtliche Stärke-Rettungswurfpfade und ein vollständiger neuer Klassenassistent.
Die SRD-Matrix bleibt ausdrücklich teilweise implementiert, ohne globale Quote.
SQLite-/Kampagnen-/JSON-Versionen unverändert. Kein KI-/Backendaufruf,
keine erfundenen Regeln; SRD 5.2.1 unter CC BY 4.0, bestehende Namensnennung bleibt.
