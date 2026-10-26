# Chat B – explizite NPC-ID-Auswahl für Story-Kontext (26.10.2026)

## Ausgangslage und Koordination
- Repository: `ManuEtt/Dnd`; Ausgangs-`main`: `20098805d8c70cbd361a13862379894c47ef4eb6`.
- Branch: `feat/chat-b/explicit-npc-identity-selection-20261026`; Pull Request [#224](https://github.com/ManuEtt/Dnd/pull/224). Quell-/Formatter-Korrektur-Commit: `99fe532c988a00799d9ae7c82625814e36926bbc`; der endgültige Dokumentations-HEAD steht unmittelbar am PR.
- Bei Start offen: PR #216, #218, #219 (UI/Gradle), #220 (Backend-Zeitstempelprüfung), #221 (Feuerpfeil-Regelwerk/Controller), #222 (Mock-NPC-Erinnerungen).
- Keine der offenen PRs verändert `app/lib/story/npc_identity_story_payload.dart`, `app/lib/story/npc_story_selection.dart` oder `app/test/npc_story_selection_test.dart`; gemeinsame README- und Checkpoint-Dateien beim Merge durch Chat D konsolidieren.
- PR #222 auf HEAD `35add6aa122a5059472e952243094d717f3f833f`: CI #40289940245 zum Start noch `in_progress` beim Android-Debug-Build, Backend- und Flutter-Tests vorher grün. #222 bleibt eigener PR.

## Problem
Der lokale ID-gebundene Story-Kontext konnte bislang nur anhand einer eindeutigen Erwähnung des **sichtbaren Namens** zusammengestellt werden. Haben zwei gespeicherte NPCs denselben Namen, wurde zur Vermeidung von Fehlzuordnung gar kein Kontext ausgewählt. Eine bewusste, vorab getroffene Auswahl anhand ihrer NPC-ID hatte die Story-Schicht bislang nicht als eigenen Typ.

## Akzeptanz
1. Ohne explizite Auswahl bleiben gleichnamige NPCs nicht anhand der Spielerprosa unterscheidbar (fail-closed).
2. `NpcStorySelection.choose(campaign, npcId)` akzeptiert nur genau eine gespeicherte, wohlgeformte NPC-ID, bindet sie an Kampagnenkennung, Revision sowie den bestätigten Namen/Lebens-/Beziehungsstatus.
3. `NpcIdentityStoryPayload.prepare(..., selectedNpc: choice)` projiziert auch bei gleichen sichtbaren Namen **nur** die Notizen dieser einen bewusst gewählten ID. Unbeteiligte Figuren dürfen nicht in den Payload rutschen.
4. Veraltete Revision, andere Kampagnen, geänderter oder doppelt gespeicherter NPC scheitern mit `FormatException`; kein stilles Ersetzen einer ungültigen Auswahl.
5. Ohne gespeicherte Notiz gibt es keinen Kontext statt eines fremden Fallbacks. Eine Änderung der Notizen bei unveränderter Revision wird vor dem Versand durch `payload.requireCurrent` erkannt.
6. Kein Rules-/Quest-/HP-/Inventar-Mutieren; keine Änderung an Daten-/API-Schema oder SQLite; Alt-JSON nach Roundtrip kompatibel.

## IMPLEMENTIERT
- `app/lib/story/npc_story_selection.dart` (neu): unveränderliche, revisionsgeschützte, explizite ID-Auswahl mit `choose` und `requireCurrent`.
- `app/lib/story/npc_identity_story_payload.dart`: optionaler Parameter `selectedNpc` an `prepare`. Bei Auswahl Vorrang der gespeicherten ID vor namengebundener Erwähnung. Die bestehende namensbasierte Auswahl für eindeutig bezeichnete NPCs bleibt unverändert.
- `app/test/npc_story_selection_test.dart` (neu): sechs positive/negative Testgruppen für Doppelname, eindeutige ID, stille Änderungen/Stale-State, unbekannte/doppelte IDs, Alt-JSON und reine Lesesicherheit.

## Grenzen / Nicht implementiert
- **Noch keine UI-Auswahl:** Die Android-Oberfläche (Chat C) und der gemeinsame `game_controller.dart` (gleichzeitig in Chat-A-PR #221) wurden absichtlich nicht geändert. Diese Änderung bietet den getesteten Story-Vertrag, aber noch keinen klickbaren NPC-Auswahldialog.
- Der aktuelle Backend-Mock behandelt ausdrücklich gleiche Anzeigenamen weiterhin vorsichtig; dessen späterer Umgang mit expliziter Clientauswahl muss gesondert in einem abgestimmten Protokoll-PR erfolgen. Eine nur im lokalen Request vorhandene ID darf nicht fälschlich als im Backend bestätigte UI-Auswahl ausgegeben werden.
- Kein realer Android-Gerätetest und keine produktive KI-Anbieterprüfung. Es werden keine Regel- oder Erzähl-Ergebnisse persistiert.

## Teststatus
- Source-Code und sechs Regressionstests sind in GitHub versioniert.
- Exakter vollständiger CI-Status des finalen PR-HEAD wird nach Dokumentation geprüft und bei Bedarf im PR kommentiert. `scripts/verify_project.py`, `scripts/check_domain_boundaries.py`, `scripts/srd_coverage.py --json`, die Python-Pakettests sowie Backend- und Flutter-/APK-Prüfungen führt die CI aus.
- Lokaler Dart-/Flutter-Build oder reales Gerät hier nicht als abgeschlossen gemeldet.

## Nächster unabhängiger Schritt
Eine von Chat C ausgelöste explizite NPC-Auswahl durch den Story-Controller (in separatem Integrationspaket, **nach** PR #221) verdrahten und zusammen mit dem Backend-Mock ein optionales ausgewähltes NPC-ID-Protokoll positiv/negativ testen. Die Auswahl muss vor dem Netzaufruf erneut revisionsgebunden geprüft werden.

---

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
