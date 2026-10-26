# Chat B – optionales, strukturiertes NPC-ID-Protokoll (26.10.2026)

## Koordination und Abhängigkeit

- Repository: `ManuEtt/Dnd`, Ziel: sicheres optionales NPC-Gedächtnis für den externen Story-Erzähler.
- Eigener Branch: `feat/chat-b/structured-npc-context-20261026`, **ausgehend vom vollständig grünen HEAD `bdd95cac4006a0f575d96fef614091464c0e748e` von PR #193**.
- PR wird **gestapelt gegen `fix/chat-b/npc-memory-name-guard-20261025`** erstellt, nicht direkt gegen `main`. PR #193 bleibt unverändert; erst nach dessen Integration darf dieser Folgeschritt separat nach `main` portiert/gemergt werden.
- Stand des `main` beim Start: `5f9a01dd73f68ad4f9e226f859a8ca87803b8337`. PR #196 hat auf `11fd21c6addd502adbadabbf18272a58906c4643` vollständig grüne CI #40267805222, ist aber noch offen. PR #194 übernimmt getrennt das KI-Clientpaket aus #187.
- Andere parallele UI-/Regel-PRs wurden gesichtet; das neue Fachpaket berührt nur `backend/src/app.ts` aus **seiner eigenen PR-#193-Basis**, eine neue Moduldatei, eine neue Testdatei und isolierte Dokumentation.

## Konkretes Problem

Die bisherige Story-API `/v1/story/advance` akzeptiert ausschließlich `memories: string[]` und hat keine belastbare NPC-ID-Zuordnung. Bei gleichnamigen Figuren entfernt PR #193 die potenziell falsch attribuierten markierten Textnotizen. PR #196 liefert dagegen bereits einen lokal bestätigten ID- und revisionsgebundenen Snapshot – das Backend konnte ihn bislang nicht empfangen.

## Implementiert

- `backend/src/story_npc_identity_context.ts`: neue optionale Typen `StoryNpcIdentityContext` und `StoryTurnWithNpcIdentities`, plus `validateNpcIdentityContext`.
- Neuer optionaler Request-Vertrag (nur wenn **beide** Felder vorliegen): `campaignRevision` (Integer >=0) und `npcContexts` (max. 3 strukturierte NPCs mit je max. 5 gespeicherten Notizen). Ohne beide Felder bleibt der bisherige Contract gültig.
- Für jeden Kontext zwingend: passende `campaignId`, identische Revision, eine bekannte `npcId` mit derselben angezeigten Namens- und Beziehungsinformation, eindeutige NPC-Kontext-ID, boolescher Lebensstatus.
- Notizen: eigene eindeutige IDs, zugehörige NPC-ID, begrenzte Einzeilentexte, plausibles UTC-Datum, absteigende Zeitfolge. Überhöhte Längen, Kontrollzeichen, fremde/duplizierte IDs und Revisionen werden zurückgewiesen.
- `backend/src/app.ts` erweitert ausschließlich das bestehende **optionale** Fastify-Eingabeschema und prüft die neuen Werte **vor** dem Erzähler-Provider; ungültige Kontextdaten ergeben HTTP 400 ohne Anbieteraufruf.
- Der bestehende PR-#193-Schutz für mehrdeutige Legacy-Tagebuchtexte bleibt bestehen. Eindeutige ID-basierte Notizen können daneben an den Erzähler übergeben werden, ohne Namen zu erraten.
- `backend/test/story-npc-identity-context.test.ts`: sechs positive und negative Testgruppen einschließlich echter Fastify-Route und simuliertem Anbieter, bei denen keine ungültige Eingabe den Anbieter erreicht.

## Sicherheitsgrenzen

- **Server ist zustandslos:** Er besitzt keine Kampagnendatenbank und kann nicht unabhängig nachweisen, ob die vom Client behauptete Revision tatsächlich die neueste gespeicherte Revision ist. Der Schutz prüft innere Konsistenz, keine kryptographische Authentizität.
- Kein Anbieter darf aus den Kontexten Trefferpunkte, XP, Gegenstände oder Quests autoritativ ändern. Die bestehende Antwortvalidierung und das leere `stateChanges` bleiben bestehen.
- Dies ist die **serverseitige optionale Aufnahme**. Der Android-Client sendet die neuen Felder noch nicht; dessen gezielte Integration aus PR #196 ist ein nachfolgender eigener Schritt.
- Keine SQLite-/Export-JSON-Migration, keine App-Versionserhöhung, keine Providerbezahlung während der Tests.

## Abnahmekriterien

1. Alte Requests ohne neue Felder bleiben gültig und funktional.
2. Zulässige neue Requests unterscheiden gleichnamige NPCs über IDs; ein nicht zugeordneter Legacy-Namenshinweis wird parallel entfernt.
3. Teilweise, fremde, widersprüchliche, doppelte, übergroße und manipulierte Kontexte werden **vor** einem potenziell bezahlten Provideraufruf abgelehnt (HTTP 400).
4. Autoritative Spielzustände bleiben unverändert, Antwort enthält weiterhin `stateChanges: []`.
5. Endgültigen Teststatus nur anhand der CI auf **exaktem finalen Commit** ausweisen.

## Teststatus und Ausblick

- Quellcode, neue Backendtests und Checkpoint vor PR-Erstellung auf dem separaten GitHub-Branch versioniert.
- Lokale Node-/Flutter-/Android-Ausführung hier nicht zuverlässig verfügbar; GitHub Actions prüfen Backend-Typecheck/-Build/-Tests, Dart-Format, vollständige Flutter-Tests und Android-Debug-/Alpha-Builds.
- Reale Android-Installation, produktiver Anbieter, Signierung und ID-Kontext vom Flutter-Client bleiben ungetestet bzw. unimplementiert.
- **Nächster Schritt:** nach Integration von PR #193 und #196 den optionalen Clienttransport explizit verdrahten, vor Versand `NpcIdentityMemory.requireCurrent` prüfen und Negativtests für Stale-Revisionen zwischen Vorbereitung und Versand hinzufügen.
