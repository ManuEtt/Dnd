# Chat B – Schutz gegen NPC-Namensverwechslungen (25.10.2026)

## Ausgangsstand
- Repository: `ManuEtt/Dnd`
- Ausgangs-`main`: `5f9a01dd73f68ad4f9e226f859a8ca87803b8337`.
- Branch: `fix/chat-b/npc-memory-name-guard-20261025`.
- Pull Request: folgt nach Dokumentation; keine automatische Zusammenführung.
- Parallele PRs bei der Auswahl: #178, #179, #180, #181, #184, #187, #188, #189, #190, #191, #192. Alle geänderten Dateipfade wurden auf Überschneidungen geprüft.
- Eigener PR #191 bleibt separat; `backend/src/story.ts` und `backend/src/mock_npc_memory.ts` werden hier nicht geändert.

## Ausgangsproblem
- Die optionale KI-Fortsetzung erhält NPC-bezogene Erinnerungen als Strings mit einem angezeigten Namen, aber **ohne bestätigte NPC-ID**. Zwei unterschiedliche NPCs können denselben sichtbaren Namen tragen.
- Bei einem unkontrollierten Kontextdurchlauf könnte ein KI-Modell eine nur einem NPC zugedachte Notiz einem anderen gleichnamigen NPC zuschreiben.
- Das Backend darf aus einem clientseitigen Präfix „Bestätigte NPC-Beziehungsnotiz“ keine serverseitige Beweisbarkeit ableiten. Das Format ist eine Kennzeichnung, **keine Authentifizierung**.

## Implementiert
- `backend/src/story_npc_memory_guard.ts` stellt `filterAmbiguousNpcDiaryMemories` bereit: rein lesende, deterministische Überprüfung formell markierter NPC-Tagebuchnotizen anhand der mitgelieferten bekannten NPCs.
- Nur Namen, die genau einem bekannten NPC mit nicht leerer ID entsprechen, bleiben in der Liste. Deutsche Umlaute/Großschreibung werden vereinheitlicht; unbekannte, mehrdeutige, unvollständige und mehrzeilige Notizen werden ausgelassen.
- Allgemeine, nicht als NPC-Tagebuch markierte Erinnerungen behalten Reihenfolge und Inhalt.
- `backend/src/app.ts` wendet diese Filterung **vor** `narrator.advanceStory` an und validiert die Providerantwort gegen denselben gefilterten Request.
- Keine Änderung am HTTP-Schema, `StoryTurnInput`, SQLite, Android-Code oder D&D-Regelzustand.
- `backend/test/story-npc-memory-guard.test.ts`: fünf positive und negative Tests, einschließlich Fastify-Endpoint/Mock-Narrator und Beleg dafür, dass bei zwei gleichnamigen NPCs keine entsprechend markierte Notiz an den Narrator weitergereicht wird.

## Akzeptanzkriterien
1. Eindeutig zugeordneten NPC beibehalten; unbekannte und doppelte Anzeigenamen auslassen, auch bei unterschiedlichen IDs.
2. Eindeutige deutsche Namensvarianten anerkennen, ohne fehlerhafte oder fremde Einträge als NPC-Gedächtnis zu interpretieren.
3. Bestehende allgemeinen Erinnerungen unverändert weitergeben.
4. Die echte Backendroute darf keine mehrdeutig zugeordnete NPC-Notiz an einen Provider schicken.
5. Keine Regeln, Kampfwerte oder Spielstände verändern; keine Migration.

## Tests
- Implementierungs- und Testdateien auf GitHub gesichert. Die obligatorische CI auf dem finalen PR-Commit wird anhand GitHub Actions kontrolliert.
- Bis zur tatsächlichen Ausführung darf **kein erfolgreicher Test, Build oder APK** für diesen neuen Branch behauptet werden.
- Nicht geprüft: reales Android-Gerät, bezahlter KI-Provider, historische Geräte-Upgrades und produktive Release-Signierung.

## Integration und Risiken
- Namen allein können **keine** kryptographisch bestätigten NPC-IDs ersetzen. Diese Guard verwirft bei Unsicherheit; er bestätigt keine Client-Fakten.
- Der Code ist kompatibel sowohl mit `main` als auch mit dem offenen Mock-Kontinuitäts-PR #191: Dieser PR ändert eigene Backend-Dateien und `app.ts`, nicht dessen Mock-Quellcode.
- Gemeinsame README und zentraler Checkpoint sind mit Chat D zu konsolidieren; keine fremden Branches überschreiben oder PRs schließen.

## Genau ein nächster Schritt
Nach tatsächlicher CI-Abnahme ein separates, revisionsgeschütztes **ID-basiertes** Story-Kontextprotokoll entwerfen und positiv/negativ testen. Eine neue ID-basierte API darf erst nach Abstimmung mit den bereits offenen Client- und Story-PRs integriert werden.
