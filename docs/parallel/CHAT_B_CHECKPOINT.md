# Chat B – doppelte NPC-Anzeigenamen beim freien Erinnerungsabruf (26.10.2026)

- **Ausgangs-main:** `5e3116f9e3f8de0af6e8125a97b3962cb8910cdf`.
- **Eigener Branch:** `fix/chat-b/npc-name-ambiguous-recall-20261026`.
- **Fach-/Test-Commit:** `63b0b7bf3fa259f05830b29470514308d1c349c0`.
- **Pull Request:** [#248](https://github.com/ManuEtt/Dnd/pull/248).
- **Geprüfte offene PRs:** #236, #237, #239, #240, #241, #242, #243, #244, #245, #246, #247; keine davon ändert die beiden Fachdateien. Zentrale Dokumentationsdateien werden von anderen PRs geändert und müssen von Chat D konsolidiert werden.
- **Ausgangsproblem:** `NpcNarratorMemory.merge` prüfte eindeutige NPC-IDs, aber nicht, ob derselbe normalisierte Anzeigename zu mehreren unterschiedlichen IDs gehörte. Freier Text wie „Ich frage Mira“ konnte zwei NPC-Erinnerungen ohne ID-Kennzeichnung zugleich in den optionalen Erzähler einspeisen.
- **IMPLEMENTIERT:** Namen innerhalb derselben Kampagne normalisieren und zählen; NPC-spezifische Notizen nur bei genau einem Vorkommen dieses Namens aus unstrukturierter Prosa wählen. Bereits bestehende Prüfung mehrdeutiger IDs bleibt erhalten. Getrennter expliziter ID-Transport wird nicht berührt.
- **GEÄNDERTE DATEIEN:** `app/lib/story/npc_narrator_memory.dart`, `app/test/npc_narrator_memory_test.dart`, `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_B_CHECKPOINT.md`.
- **AKZEPTANZ:** Zwei „Mira“ mit verschiedenen IDs oder zwei gleichlautende normalisierte Namen erzeugen ohne explizite Auswahl keine Namensnotizen; eindeutiger „Tarek“ liefert weiterhin die richtige Notiz. Unveränderte Kampagnen-JSON-Repräsentation, unveränderbare Rückgabe und kompatible Legacy-Memory-Liste.
- **TESTS ERGÄNZT:** Positive und negative Flutter-Unit-Regressionen in `npc_narrator_memory_test.dart` samt Nachweis, dass die kampagneneigenen Daten durch den Abruf nicht verändert werden.
- **GETESTET:** Aktuellen Main-, PR- und Dateistand direkt über GitHub geprüft; geänderte Dateiabschnitte nach GitHub-Commit erneut gelesen.
- **NICHT GETESTET:** Lokale Dart-/Flutter-Unit-/Gesamtsuite, Backend, APK und echter Gerätetest (kein Flutter-SDK oder lokaler GitHub-Checkout). GitHub Actions auf finalem PR-HEAD separat prüfen.
- **BLOCKIERT:** lokale SDK-Verfügbarkeit; gemeinsame README-/Checkpoint-Merges erfordern Chat-D-Integration.
- **MIGRATION:** keine; SQLite 2 und Kampagnen-JSON 1 bleiben unverändert; keine Regel-, Quest-, Inventar- oder Ressourcenmutation.
- **NÄCHSTER SCHRITT:** Nach erfolgreicher CI von PR #248 einen separaten Integrationstest für die unstrukturierte Legacy-Memory-Übertragung mit zwei namensgleichen NPCs und ausdrücklich gewählter NPC-ID ergänzen (ID-Payload darf nur die ausgewählte Identität enthalten).

---

# CHAT B – Checkpoint: NPC-Zeitstempel, 26.10.2026

- **Ausgangs-Main-SHA:** `20098805d8c70cbd361a13862379894c47ef4eb6`.
- **Branch:** `fix/chat-b/npc-timestamp-validation-20261026`.
- **Implementierungscommit:** `d7d47523d0b6679c3210ab5a9e86e7c430b2933d`; nachfolgende reine Dokumentationskorrektur auf demselben Branch. **PR:** [#220](https://github.com/ManuEtt/Dnd/pull/220).
- **PRs bei Aufgabenwahl:** #216 und #218 (UI bzw. Skripte, mit zentralen Dokumenten), #219 (Integration derselben UI-/Skriptänderungen). Keine fachliche Überschneidung im Backend-Validator oder seinem Test.
- **Problem:** `Date.parse` akzeptiert erfundene Kalendertage (z. B. 2026-02-30) und 24:00, korrigiert dabei die Zeitachse der bestätigten NPC-Chronik ohne ausdrückliche Zustimmung.
- **Implementiert:** UTC-Zeitstempel nur dann anerkennen, wenn der geparste Zeitwert dieselbe Kalendersekunde repräsentiert; bisher erlaubte 1 bis 6 Dezimalziffern, gültige UTC-Zeitstempel und Schaltjahre erhalten.
- **Dateien:** `backend/src/story_npc_identity_context.ts`, `backend/test/story-npc-identity-context.test.ts`, `README.md`, `docs/CODEX_CHECKPOINT.md`, diese Datei.
- **Akzeptanz:** Ungültige Tage/24:00 werden vor Aufruf eines Story-Providers abgelehnt. Gültige Schalttage und Millisekunden-/Mikrosekundenpräzision bleiben gültig; sonstige Alt-Clients ohne `npcContexts` unverändert.
- **Daten/Regeln:** keine Speicherung, keine Migration, SQLite 2 / Kampagnen-JSON 1; kein autoritativer Regelzustand oder NPC-Beziehungsupdate aus KI-Texten.
- **TESTS HINZUGEFÜGT:** Backend-Unit-Test positiver/negativer Kalenderdaten; negativer HTTP-Integrationstest vor Provideraufruf.
- **GETESTET:** für den Implementierungscommit noch keine vollständige GitHub-CI belegt; CI wurde über [PR #220](https://github.com/ManuEtt/Dnd/pull/220/checks) gestartet, zum Dokumentationszeitpunkt in Bearbeitung.
- **NICHT GETESTET:** Backend-/Flutter-/Python-Gesamtsuiten, Android-APK und reales Gerät.
- **BLOCKIERT:** lokales Flutter-/Android-SDK und vollständiger Checkout fehlen; tatsächliche PR-CI gesondert prüfen.
- **NÄCHSTER SCHRITT:** Nach erfolgreicher PR-Abnahme im kostenlosen Mock eindeutige revisionsgebundene NPC-Identitätskontexte als reinen Erzählhinweis nutzen. Abnahmekriterien: identische Namen bleiben nach ID getrennt, alte Clients funktionieren, keine mechanischen oder bestätigten Zustandsänderungen, Tests für Leer- und Wiederaufnahmeszenarien.

---

## Historischer Chat-B-Checkpoint vom 25.10.2026 (unverändert übernommen)

# Chat B – KI-Spielleitung und Kampagnen (25.10.2026)

## Live-Ausgangslage
- Repository: `ManuEtt/Dnd`
- Ausgangs-`main`: `5c1499a9342449050bb946542659b221ac2653da` (PR #175 integriert).
- Arbeitsbranch: `fix/chat-b/recall-intent-20261025`.
- Fach-Commit: `90a280d5565eae42044f80135450d46b2c4c9b90`.
- Test-/Format-Commit: `c3959e4f088729bbd48f3993c35ca1ac298ca62d`.
- Pull Request: [#179](https://github.com/ManuEtt/Dnd/pull/179) – geöffnet, CI für finalen HEAD zum Zeitpunkt dieser Aktualisierung noch nicht abgenommen.
- Offene fremde PRs während der Bearbeitung: #176 (Gelegenheitsreaktion/Kampf/UI/Modelle) und #177 (CI-Qualitätsgates). Keine der dort geänderten Fachdateien wurde bearbeitet.
- Main-Workflow `40216189451` war bei der Ausgangsprüfung noch `in_progress`; frühere grüne Läufe sind kein Nachweis für Chat B.

## Ausgangsproblem und Akzeptanz
`MemoryEngine.isRecallRequest` wertete bisher schon einzelne Wörter wie `Tagebuch`, `bisherig` oder `erinnere` als Erinnerungsbefehl. Die Spielerhandlung „Ich lese das Tagebuch“ wurde somit fälschlich durch einen bestätigten Rückblick ersetzt.

Akzeptanz:
1. Ausdrückliche deutsche Erinnerungsfragen und Befehle werden weiterhin erkannt.
2. Gewöhnliche Erzähl- und Tagebuchhandlungen, berichtete Erinnerungen und zitierte Fragen werden nicht als Recall klassifiziert.
3. Der echte `GameEngine.act`-Pfad bleibt für Tagebuchhandlungen ein regulärer Spielzug, für eine ausdrückliche Mira-Frage jedoch `memory.recalled`.
4. Helden-/Regelzustand und bestehende Speicher- und JSON-Formate bleiben unverändert.

## Implementiert
- Nur die Absichtserkennung in `app/lib/story/story_memory_engine.dart` präzisiert: explizite, deterministische deutsche Frage- und Befehlsformen statt lose Schlüsselwörter.
- Vier neue Unit-/Integrationstests in `app/test/story_recall_intent_test.dart` angelegt. Positive und negative Fälle und echte `GameEngine.act`-Integration enthalten.
- Keine KI-Provider-Abfragen; keine Änderungen an `models.dart`, `game_engine.dart`, `game_controller.dart`, `app/lib/data/*`, Regeln oder Schema.
- Dokumentation: `README.md`, `docs/CODEX_CHECKPOINT.md` und dieser eigene Checkpoint.

## Getestet
- Inhaltlicher Code- und PR-Dateipfad-Abgleich gegen den Live-Stand durchgeführt; keine lokale Dart-Testausführung.
- Die tatsächlichen GitHub-CI-Ergebnisse müssen am finalen PR-HEAD kontrolliert werden. Testfälle existieren, sind damit aber nicht automatisch bestanden.

## Nicht getestet
- `dart format`, `flutter analyze`, `flutter test`, `flutter build apk --debug` lokal nicht ausgeführt (kein installiertes Dart-/Flutter-SDK und kein lokaler Repository-Checkout).
- Python-Strukturtests und Backend-Build im lokalen Container nicht ausgeführt (kein Repo-Checkout).
- Android-Realgerät, alte Spielstände, Release-Signierung und vollständige GitHub-CI für den finalen Commit bislang nicht nachgewiesen.

## Blockiert/Risiken
- Der GitHub-Connector kann schreiben, aber nicht lokal Flutter ausführen.
- Die zentralen README-/Checkpoint-Dateien werden auch in anderen PRs bearbeitet; Chat D muss bei späterer Integration widerspruchsfrei konsolidieren. Kein eigenmächtiger Merge.

## Migrationen
- Keine. SQLite, Export-JSON, IDs, Kampfzustand und Ressourcen bleiben unverändert.

## Genau ein nächster unabhängiger Schritt
Gezielten Abruf bestätigter NPC-Beziehungsnotizen auch bei mehreren aufeinanderfolgenden Sitzungen absichern. Akzeptanz: nur nachgewiesene Notizen, stabile Reihenfolge, keine unbestätigte KI-Dialogprosa, negative Tests für fremde NPC-IDs; eigene Storydateien und Tests, keine Änderung an Shared Models.
