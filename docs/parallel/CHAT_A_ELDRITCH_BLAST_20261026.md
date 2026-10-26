# Chat A – Eldritch Blast Mehrstrahl (26.10.2026)

- **Ausgangsbasis:** `main 5f9a01dd73f68ad4f9e226f859a8ca87803b8337`.
- **Branch:** `feat/chat-a/eldritch-blast-multibeam-20261026`.
- **Chat-Kennung:** A / SRD-Regeln. Eigene Source/Testdateien; keine Änderungen an fremder KI-Story, Controller, Oberfläche oder Spielständen.
- **Parallele Chat-A-PRs:** #180/#195 Zauberdauern, #184 Klassen-Zauberwerte, #188 W20-Zauberangriffe, #190 Rituale. Ihre Quell- und Testdateien bleiben unangetastet.

## IMPLEMENTIERT
Ausdrücklich bestätigter Hexenmeister-Zaubertrick Eldritch Blast, getrennte Strahlen 1/2/3/4 ab Gesamtstufe 1/5/11/17, Ziel-Wiederholung erlaubt, W20 pro Strahl, unabhängige Force-Schadenswürfel, Krit/Deckung/Vorteil und vollständige Vorprüfung vor jedem Würfel.

## GETESTET
Regressionstests in `app/test/srd_eldritch_blast_rules_test.dart` geschrieben; tatsächliche GitHub-CI ist nach dem letzten Funktions- und Dokumentationscommit gesondert nachzuweisen.

## NICHT GETESTET
Reale Android-Geräteinstallation, Speicherstand-Upgrade, signierte Produktion, End-to-End-Cast mit Kampagnenpersistenz.

## BLOCKIERT
Dart-/Flutter-/Android-SDK lokal nicht verfügbar. Die mehreren parallelen offenen PRs verändern gemeinsam `README.md` und `docs/CODEX_CHECKPOINT.md` und erfordern vor Merge eine konfliktfreie Zusammenführung.

## NOCH NICHT IMPLEMENTIERT
Hit-Point-Buchung, tatsächliche Aktionskosten, Invocations/Hex, persistente Doppelbestätigung, UI für vier unabhängige Strahlen, resistenzabhängiger Endschaden.

## NÄCHSTER SCHRITT
Finalen CI-HEAD prüfen; danach unter Koordination der bestehenden Integrations-PRs die echte GameEngine-/Controller-Aktion mit Ziel-ID, Revisionsschutz und je Strahl aufgezeichnetem Treffer-/Schadensereignis planen.

[Fachliche SRD-Abgrenzung](../SRD_ELDRITCH_BLAST_MULTIBEAM_20261026.md).
