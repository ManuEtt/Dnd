# Chat B – abgeschlossene Story-Fäden dürfen nicht von KI umgeschrieben werden (26.10.2026)

- **Ausgangs-Main:** `67f146e690306b13d490bd8e7fd5636bb187c77e`, Branch `fix/chat-b/terminal-thread-description-20261026`.
- **Ausgangsproblem:** Die bisherigen Flutter-/Backend-Parser schützten für `resolved`/`abandoned` nur den Status, ließen aber bei unverändertem Terminalstatus vom Erzähler vorgeschlagene neue Beschreibungen zu. Das konnte bestätigte Abschlüsse stillschweigend umdeuten.
- **Implementiert:** `app/lib/story/ai_story.dart` und `backend/src/story.ts` prüfen für terminale Handlungsstränge nun **Status UND gespeicherte Beschreibung**. Identische Wiederholungen bleiben akzeptiert. Die manuellen `saveStoryThread`-Änderungen (inklusive ausdrücklich wieder geöffneter Story-Fäden) bleiben erlaubt.
- **Tests:** `app/test/ai_story_test.dart` prüft beide Terminalstatus, abgewiesene Beschreibungsänderungen, identische Antworten, gespeicherte manuelle Berichtigung und erlaubte Wiederöffnung. `backend/test/story.test.ts` prüft Parser und HTTP-Fehlerantworten ohne Echo unbestätigter Texte.
- **Weitere Dateien:** `README.md`, `docs/CODEX_CHECKPOINT.md`, dieses Chat-B-Checkpointdokument. Alle alten Abschnitte bleiben erhalten.
- **GitHub-Koordination:** Vorher offene PRs #244–#252 und deren geänderte Fachdateien geprüft; kein paralleler PR betrifft die beiden Parser oder ihre konkreten Tests. PR #250 integriert frühere Pakete; Konflikte gemeinsamer Dokumentation sind von Chat D beim Merge zu behandeln. PR #251 (NPC-Auswahl nach SQLite-Wiederaufnahme) wurde auf dem finalen Code-Commit `333d9afa` erfolgreich durch GitHub Actions #40379164281 und #40379171344 geprüft, bleibt zum Zeitpunkt dieses Zyklus aber offen.
- **GETESTET:** Live-Main, offene PR-Dateipfade, fachliche Parser, vorhandene Backend-/Flutter-Tests und manuellen Editor gegen aktuellen Stand geprüft.
- **NICHT GETESTET:** Neu implementierte Gesamtsuite und APK lokal mangels Flutter-SDK und Repository-Checkout. CI-Ergebnisse auf finalem Branch-HEAD separat verifizieren; Realgerät und produktive KI nicht getestet.
- **BLOCKIERT:** Offene parallele PRs und zentrale Dokumentationsmerges, keine technische Schema-Migration.
- **MIGRATION:** keine; SQLite 2, Kampagnen-JSON 1, D&D-Regelzustand, Helden-/Questdaten und vorhandene Spielstände unverändert.
- **NÄCHSTER SCHRITT:** Nach CI/Integration einen unabhängigen Kontinuitätstest für bestätigte Abschlüsse über SQLite-Wiederaufnahme und manuelle Berichtigung hinweg ergänzen; keine automatische Retro-Korrektur durch KI.

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

---

## Chat B – explizite NPC-Auswahl im Story-Protokoll (26.10.2026)

- **Ausgangs-Main:** `42d14ad36cc947691f7e5a1e8647a43f5421b86e`; offene Pull Requests: keine. Main-Workflow #40329543416 und #40329543284 `success`.
- **Eigener Branch:** `feat/chat-b/explicit-npc-wire-20261026`, PR gegen `main`; GitHub-PR-HEAD/CI bei Abschluss prüfen.
- **Implementiert:** Streng optionales, separat angekündigtes `selectedNpcId` für identische Anzeigenamen. Der Offline-Mock verwendet exakt die ausdrücklich gewählte und id-/revisionsgebundene NPC-Chronik ohne Erraten. Flutter-Netzwerkclient akzeptiert das Feld nur bei `npc-selection-v1`; alte Server bleiben kompatibel. Lokale `NpcIdentityStoryPayload`-Projektion bewahrt die ID.
- **Geänderte Fachdateien:** `backend/src/story_npc_identity_context.ts`, `backend/src/app.ts`, `backend/src/mock_npc_identity_hint.ts`, `app/lib/story/npc_identity_story_payload.dart`, `app/lib/services/backend_narrator.dart`.
- **Tests:** `backend/test/story-npc-explicit-selection.test.ts`, `app/test/backend_explicit_npc_transport_test.dart`, `app/test/npc_story_selection_test.dart`; positive/negative Sicherheit und Legacy-Vertrag.
- **Keine Migration:** keine SQLite-/JSON-/Rule-/Hero-/Quest-Mutation, keine Versionsänderung. Ältere Backendversionen melden das neue Capability nicht. Noch keine angeschlossene Android-UI-Auswahl.
- **Abnahme:** vollständige CI auf finalem Commit erforderlich; keine Test- oder APK-Freigabe vor entsprechender GitHub-Action. Kein Produktiv-KI-/Gerätetest.
- **Einziger nächster Schritt:** explizite NPC-ID-Auswahl im Story-Dialog samt Stale-Revisionsabbruch und automatisierten Widget-/Transporttests, abgestimmt mit Chat C. Siehe [Detailcheckpoint](CHAT_B_NPC_SELECTION_WIRE_20261026.md).


**GitHub-Nachtrag Chat B (26.10.2026):** [PR #237](https://github.com/ManuEtt/Dnd/pull/237) enthält das optionale `selectedNpcId`-Protokoll. Im nachgewiesenen Lauf [#40342521532](https://github.com/ManuEtt/Dnd/actions/runs/40342521532) haben Backend, Dart-Format, Flutter-Analyse und komplette Flutter-Tests bestanden; Android-Build bei Abruf noch offen. Abschlussstatus gilt nur für exakt getesteten PR-HEAD. Keine Übernahme nach `main`, keine Spielstandmigration.
