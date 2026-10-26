# Chat B – Unicode-Spoilerschutz (26.10.2026)

- **Ausgangs-Main-SHA:** `5e3116f9e3f8de0af6e8125a97b3962cb8910cdf`.
- **Eigener Branch:** `fix/chat-b/story-secret-invisible-unicode-20261026`.
- **Fach-/Test-Commit:** `ad66617396ad713de426d580cfe3b42ae27eeb39`; [PR #244](https://github.com/ManuEtt/Dnd/pull/244), Ziel `main`.
- **PR-Prüfung vor der Arbeit:** #236, #237, #239, #240, #241, #242 und Integrations-PR #243. Keine der offenen Änderungen betrifft `backend/src/story_secret_guard.ts` oder `backend/test/story_secret_guard.test.ts`. PR #243 greift in gemeinsame README-/Checkpoint-Dateien ein: bei Integration mit Chat D konsolidieren, nicht überschreiben.
- **Ausgangsproblem:** Vollständige Story-Geheimnisse werden durch unsichtbare Unicode-Codepoints (beispielsweise U+200B in „Nebelkrone“) visuell offenbart, aber im bisherigen exakten Ausgabefilter nicht erkannt.
- **IMPLEMENTIERT:** Im Backend-Spoilerschutz NFKC plus Entfernung von Unicode `Default_Ignorable_Code_Point` *vor* dem Whole-word-Vergleich beider Seiten. Bereits bestätigte Story- und Regelzustände bleiben unberührt.
- **DATEIEN:** `backend/src/story_secret_guard.ts`, `backend/test/story_secret_guard.test.ts`, `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_B_CHECKPOINT.md`.
- **REGRESSIONSTESTS:** Storyplan und Storyturn mit U+200B, U+00AD, U+FE0F, U+034F, U+200D; negative Wortgrenze (Bogen/Bogenläufer); HTTP-Ablehnung auf `/v1/story/start` und `/v1/story/advance` ohne Geheimnis-Echo; bereits bestehende positive Anbieterantworten bleiben testbar.
- **GETESTET:** Fehlverhalten des bestehenden Regex und reparierter Vergleich für fünf Unicode-Zeichen sowie harmlose Wortgrenzen im isolierten Node.js-22-Minimaltest lokal nachgewiesen. Main- und PR-Dateipfade live gelesen.
- **NICHT GETESTET:** Projektbezogene `npm ci`, `npm run typecheck`, `npm run build`, `npm test`, Python-/Flutter-/Android-Suite und reales Gerät in der lokalen Umgebung (kein vollständiger Checkout bzw. kein Flutter-/Android-SDK). CI-Ergebnis ausschließlich nach Beobachtung des finalen PR-HEAD angeben.
- **MIGRATION:** keine. SQLite-Version 2, Kampagnen-JSON 1, Regelzustände und API-Format unverändert. Keine bestehenden Spielstände werden automatisch umgeschrieben.
- **BLOCKIERT:** lokale Gesamtsuite durch fehlenden GitHub-DNS-/Checkout-Zugriff; parallele Änderungen an zentralen Dokumenten im Integrations-PR.
- **NÄCHSTER SCHRITT:** Nur falls PR #244 inklusive finalem CI erfolgreich abgenommen und integriert ist, separat einen Test gegen direkte Plotgeheimnis-Ausgabe in weiteren bereits vorhandenen narrativen Textfeldern prüfen; keine semantische Geheimniserkennung ohne freigegebenen Story-Reveal-Vertrag.

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
