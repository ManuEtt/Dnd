# Chat B – ID-sichere NPC-Kontinuität im Offline-Mock (26.10.2026)

## Ausgangslage und PR
- Ausgangs-`main`: `20098805d8c70cbd361a13862379894c47ef4eb6` nach Merge von PR #217.
- Eigener Branch: `feat/chat-b/mock-structured-npc-recall-20261026`; PR [#222](https://github.com/ManuEtt/Dnd/pull/222); Fach-/Testfix-Commit `29263f811ea78aa95d32c0202776286289613251`. Der GitHub-PR-HEAD enthält anschließend zusätzliche Dokumentationscommits; CI muss daher jeweils an der exakten SHA geprüft werden.
- Offene PRs zu Arbeitsbeginn: #216 (Kampfteilnehmer-Karte), #218 (Gradle-Properties), #219 (deren Integration); **keine Fachdateiüberschneidung**. Main-CI #40288770032 zu Beginn noch laufend; vorherige grüne Main-CI #40285915083 zum älteren HEAD `0212e99...`.
- Alle acht Pflichtdokumente anhand der tatsächlichen Dateien in `main` abgeglichen, einschließlich der aktuellen Story-/Backend-Verträge.

## Ausgangsproblem
Das Backend validierte schon `campaignRevision` und `npcContexts` für `/v1/story/advance`, und die Flutter-App konnte diese optional senden. Trotzdem verwendete `mockStoryTurn` beim Offline-/kostenlosen Mock ausschließlich `memories: string[]`. So blieb die bereits validierte, eindeutig per NPC-ID zugeordnete Bestätigung ohne Erzähleffekt.

## Akzeptanz
1. Bei gültiger, eindeutig zu einem angesprochenen NPC gehörender ID-Notiz erinnert der Mock an die neueste bestätigte Notiz – vor älteren namenbasierten Einträgen.
2. Bei Legacy-Clients, ungültigen, unpassenden, mehrdeutigen IDs, Namen oder Revisionen bleibt der bisherige sichere Fallback erhalten.
3. Keine ungewollten NPC-, Quest-, HP-, Ressourcen- oder Kampfänderungen. Anbieter- und Datenbankzugriffe entfallen.
4. Begrenztes, einzeiliges, Unicode-sicheres Zitat; auch nichtdeutsche Namen mit diakritischen Zeichen dürfen keine Regex-Fehler erzeugen.
5. Echte HTTP-Route mit Mock-Provider muss neue ID-Notiz narrativ wiedergeben und fremde Revision mit HTTP 400 abweisen.

## Implementiert
- `backend/src/mock_npc_identity_hint.ts` **NEU**: rein lesender ID-gestützter Mock-Erinnerungsauszug nach vorheriger serverseitiger Kontextvalidierung. Nur bei **genau einem** erwähnten, anhand seines Namens eindeutig zuordenbaren NPC; doppelte Anzeigenamen werden fail-closed nicht erraten. Neueste (absteigend validierte) Notiz, maximal 160 Unicode-Codepoints als einzeilige Erzählung.
- `backend/src/story.ts`: `mockStoryTurn` akzeptiert die bestehenden optionalen Felder und bevorzugt den neuen Auszug mit Legacy-Fallback. Keine Änderungen am Story-HTTP-Vertrag oder an der Antwort- und Regelgrenze.
- `backend/test/mock-npc-identity-hint.test.ts` **NEU**: positive und negative Tests, deterministische Wiederholung, UTF-/Diakritik-Fall, Altclient-Fallback, falsche IDs und Revisionen sowie echte Fastify-Route mit Mock-Anbieter.

## Sicherheitsgrenzen und Kompatibilität
- Der Server kann Client-Erinnerungen nicht unabhängig authentifizieren; ein vom Client gelieferter Tagebuchtext ist nur Erzählkontext, keine bestätigte Serverwahrheit.
- Keine SQLite-/JSON-Migration, keine App-Version oder Änderung an D&D-Mechaniken. Ältere Clients bleiben funktional.
- Keine Produktionsexterne KI, reale Android-Installation, Store-Signierung und kostenpflichtige Provider-Nutzung für dieses Paket geplant.

## Prüfstand
- Node.js 22.16.0, npm, Git und Python lokal verfügbar; **kein lokales Flutter/Dart-SDK**. Eine direkte GitHub-Checkout-Verbindung im Arbeitscontainer ist wegen fehlender DNS-Auflösung nicht verfügbar. Testdurchläufe erfolgen über die GitHub-CI.
- Der finale CI-Status und der genaue HEAD sind anhand der Actions-Resultate, nicht aus früheren erfolgreichen Runs, zu belegen.
- Eigenständiger Integrations-Pull-Request gegen `main`; kein automatischer Merge.

## Genau ein nächster Schritt
Nach grüner CI: Verhalten für zwei gleichnamige NPCs erst nach **expliziter UI-Auswahl einer NPC-ID** erweitern; bis dahin keine automatische Zuordnung aus der Spielerprosa ableiten.

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
