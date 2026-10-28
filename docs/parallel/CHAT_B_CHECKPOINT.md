# Chat B – NPC-Auswahl in Android-UI plus persistente Outbox (27.10.2026)

- **Branch:** `feat/chat-b/npc-picker-outbox-20261027`, basiert auf `feat/chat-b/controller-explicit-npc-selection-20261027` (PR #288, Basis-SHA `2ba524c307b3b48ad21a6343df700ae0a643f55d`). Kein unabhängiger Merge vor #288.
- **Problem:** Der bestehende Controller konnte die manuell gewählte NPC-ID transportieren, die Oberfläche bot keinen Auswahlweg. Die bisherige SQLite-2-Outbox speicherte nur Text und Request-ID; bei Restart wäre eine UI-Auswahl verlorengegangen.
- **IMPLEMENTIERT:** Neuer `npc_story_selection_dialog.dart` mit deutschen Texten, IDs neben identischen Anzeigenamen, Screenreader-Beschriftung, aktiver Auswahl oder Abbruch. Nur NPCs mit bestätigter Beziehungsnotiz sind wählbar. Im Adventure-Composer ist der neue Button bei ausgehandelter `npc-selection-v1` aktiv. Bestehender Sendeauftrag bleibt für Sprach-/Text-/Schnellaktionen maßgeblich.
- **KONTINUITÄT:** `PendingPlayerAction` persistiert optional `selectedNpcId`/`selectedNpcRevision` mit dem Text. `_dispatch` rekonstruiert nur die identische ausgewählte ID; bei neuer Revision bleibt der Auftrag sichtbar und wird nicht automatisch auf einen gleichnamigen NPC umgelenkt. Ein exaktes bestätigtes Ereignis darf den verloren gegangenen ACK nach Restart auflösen. Alle anderen Varianten benötigen neue bewusste Auswahl.
- **SCHEMA/MIGRATION:** SQLite `3` (vorher `2`): zusätzliche nullable `selected_npc_id`/`selected_npc_revision` im `pending_player_actions`-Datensatz, Version-2-Migration durch `ALTER TABLE`. Version 1 wird in denselben Endzustand übertragen. Alte textbasierte Aufträge bleiben unverändert; Kampagnen-JSON/Backend/SRD-Regeln unverändert.
- **TESTS:** `npc_story_selection_dialog_test.dart` (eindeutige ID trotz gleicher Namen, Abbruch, leere bestätigte Liste); `npc_selected_action_outbox_test.dart` (SQLite-Restart, ungültige Auswahl abweisen, SQLite-2-Upgrade). Die Ausgabe des offiziellen Dart 3.9.2-Formatters wurde übernommen.
- **BERÜHRTE DATEIEN:** `app/lib/ui/app.dart`, neuer Dialog, `player_action_outbox.dart`, `campaign_repository.dart`, `sqlite_campaign_repository.dart`, zwei neue Tests, README und beide CODEX-Checkpoints.
- **GEPRÜFT:** Aktueller Repo-/PR-Stand, Formatter. CI auf finalem PR-HEAD nachsehen. Keine manuelle Geräte- oder Live-KI-Abnahme.
- **BLOCKIERT:** Integration PR #288; gemeinsame UI-/README-Dokumentation durch Chat D bei Merge konsolidieren. Keine fremden Branches gelöscht.
- **NÄCHSTER SCHRITT:** Race/Restart-Sendeauftrag-Ende-zu-Ende-Test für verlorenes ACK und gleichnamige NPCs.

---

# Chat B – transportierte NPC-Erinnerungen bleiben bei zwölf Einträgen (27.10.2026)

- **Branch:** `test/chat-b/npc-memory-wire-budget-20261027`; Basis `fix/chat-b/npc-memory-budget-20261027` (PR #307, Head `47b4343fadd5f30b9030a702b3ccd701d701a598`). Gestapelter reiner Test-PR, kein unabhängiger Merge vor #307.
- **Konkret implementiert:** `app/test/npc_story_memory_wire_budget_test.dart` testet beide Backend-Fähigkeitsvarianten `npc-identity-v1` an/aus mit einer gespeicherten KI-Kampagne. Sie enthält 3 bestätigte Mira-Notizen und 18 allgemeine Fakten; `GameController.sendAction` führt über `NpcNarratorMemory.merge` zum Story-Transport, dessen `memories`-Payload erfasst wird.
- **AKZEPTANZ:** Exakt 12 Erinnerungseinträge, maximal 400 UTF-16-Codeeinheiten je Text, 3 jüngste bestätigte Mira-Notizen vorn, ergänzende allgemeine Fakten nur auf Restplätzen. Je ausgehandelter Fähigkeit optionale `npcContexts` und passende Revision vorhanden oder vollständig abwesend. Held bleibt identisch, neue Revision und rekonstruierter SQLite-Zustand stimmen überein.
- **KEINE PRODUKTIONSÄNDERUNG:** Nur neue Testdatei, README, zentrale und Chat-B-Checkpoints. Keine Android-Grafik/Bedienlogik, SRD, SQLite-Migration, Backend-API oder Providerkosten.
- **GETESTET:** GitHub-Hauptbranch/PR-Abhängigkeit und Transport-/Persistenz-Verträge geprüft; offizielles Dart-Formatter-Ergebnis anwenden und CI auf finalem PR-Commit ausführen. Android-Realgerät und Live-KI ungetestet.
- **PARALLEL:** Keine Fachdatei-Kollision mit den Chat-B-Outbox-PRs #303–#306. Dokumentationsdateien bei Integration konfliktarm konsolidieren.
- **NÄCHSTER SCHRITT:** Nach vollständiger grüner CI den PR erst nach #307 integrieren; weitere Grenzfälle deduplizierter oder leerer Erinnerungen separat absichern.

---

# Chat B – geteiltes Erinnerungslimit für NPC- und allgemeine Fakten (27.10.2026)

- **Basis:** `main` `f9b2f72a4bf8e4216bf8baac60c7f92c4a8a997f`; Branch `fix/chat-b/npc-memory-budget-20261027`. Unabhängig von der NPC-Auswahl-/Outbox-Kette #288 → #290 → #292 → #300 → #303 → #305 und dem parallelen UI-Status-PR #304.
- **PROBLEM:** `NpcNarratorMemory.merge` prüfte erst *nach* dem Anhängen allgemeiner Erinnerungen, ob das gemeinsame `limit` erreicht war. Bei `npcNoteLimit == limit` und mindestens einem normalen Fakt konnte die Ausgabe das Budget überschreiten.
- **IMPLEMENTIERT:** Vor dem Anhängen normaler Erinnerungen bei `result.length == limit` abbrechen. Priorität bestätigter NPC-Notizen und Verhalten bei freier Kapazität unverändert. Kein neues Verhalten für gleichnamige NPCs; diese werden aus Freitext weiterhin nicht geraten.
- **TESTS:** Zwei bestätigte NPC-Notizen mit Budget zwei, eine Notiz mit Budget eins, zwei Notizen mit Budget drei (ein normaler Fakt) sowie Unveränderlichkeit von Originalkampagne und Rückgabedaten prüfen. Bestehende Tests beibehalten.
- **DATEIEN:** `app/lib/story/npc_narrator_memory.dart`, `app/test/npc_narrator_memory_test.dart`, README, zentrale und Chat-B-Checkpoints. Alle Dart-Dateien offiziell formatiert.
- **NICHT GETESTET:** Lokale Flutter-/Android-Läufe, Realgerät, Live-Provider; GitHub-CI auf finalem Commit noch separat abzunehmen.
- **KEINE MIGRATION:** SQLite-Version 3, JSON-Export 1, Backend-Kontrakt und D&D-SRD unverändert.
- **NÄCHSTER SCHRITT:** Ein Ende-zu-Ende-Test für maximal 12 Erinnerungen am Story-Transport ohne Gefahr doppelter NPC-Namen.

---

# Chat B – NPC-ID nach SQLite-Neustart sicher fortsetzen (26.10.2026)

- **Ausgangs-`main`-SHA:** `67f146e690306b13d490bd8e7fd5636bb187c77e`.
- **Eigener Branch:** `feat/chat-b/npc-selection-resume-20261026`.
- **Implementierungs-/Test-Commit:** `945f6a18c3ce1570f52d95d8d21e453dbaf519dc`; PR und finaler Branch-SHA sind nach Veröffentlichung im GitHub-PR nachzusehen.
- **Vor Aufgabenwahl geprüfte PRs:** #244, #245, #246, #247, #248; während des Inkrements wurde zusätzlich Integrations-PR #250 eröffnet. Der neue Testpfad wird in keinem dieser PRs geändert. Gemeinsame `README.md` und `docs/CODEX_CHECKPOINT.md` durch Chat D bei der Integration konsolidieren.
- **AUSGANGSPROBLEM:** Nach Neustart gab es für zwei gleichnamige NPCs keinen einzelnen durchgängigen Regressionstest von bestätigtem SQLite-Spielstand über explizite Auswahl bis zum ausgehandelten Backend-Protokoll, einschließlich Revisionswechsel.
- **IMPLEMENTIERT:** `app/test/npc_selection_resume_sqlite_test.dart` als neuer, deterministischer Integrationstest mit echter temporärer SQLite-DB und kostenlosem Fake-Transport: Campagne speichern, DB neu öffnen, gleichnamige Mira-NPCs nicht aus freier Prosa erraten, Mira-ID ausdrücklich wählen, exakt eine gespeicherte Notiz zum Erzähler transportieren, erneute Sitzung bestätigen, alte Auswahl bei neuer Revision sperren, neu wählen und nur dieselbe gespeicherte NPC-ID übertragen. Separater Negativtest für Legacy-JSON ohne optionale NPC-Notizen.
- **GEÄNDERTE DATEIEN:** neuer Flutter-Test sowie `README.md`, `docs/CODEX_CHECKPOINT.md` und dieser Checkpoint. Keine Domain-, Controller-, Schema- oder Regelcodeänderung.
- **AKZEPTANZ:** ausschließlich `mira-two` mit ihrer gespeicherten Notiz in `npcContexts` und `selectedNpcId`; `mira-one` und ihre Notiz nie im ID-Kontext; stale Revision abgewiesen; lokaler Held und Spielstand unverändert; ältere JSONs ohne NPC-Notizen produzieren keinen erfundenen Verlauf.
- **TESTS:** Zwei Flutter-Tests neu erstellt. Ausführung über aktuelle GitHub-CI nachsehen, **nicht durch bloße Testdatei als bestanden werten**.
- **NICHT GETESTET:** Flutter/Android lokal (kein Flutter-/Android-SDK); echtes Gerät, produktiver KI-Provider und Revisionsrace zwischen Anforderungsaufbau und HTTP-Senden.
- **MIGRATION:** Keine. SQLite-Version 2 und Kampagnen-JSON 1 unverändert.
- **NÄCHSTER SCHRITT:** Bei erfolgreicher CI und nach Integration #250 einen eigenständigen narrativen Test gegen Änderungen an bereits abgeschlossenen Handlungssträngen durch unveränderten Terminalstatus erstellen; bestehende manuelle Bearbeitung muss weiterhin möglich bleiben.

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
