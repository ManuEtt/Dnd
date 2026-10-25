# Eindeutige Story-Kontext-IDs vor generativer Fortsetzung

Datum: 25.10.2026 · [PR #167](https://github.com/ManuEtt/Dnd/pull/167)

## Ausgangsproblem

Der Backend-Erzähler erhielt bei `/v1/story/advance` vom Client bestätigte Handlungsstränge und NPCs. Die JSON-Validierung begrenzte Länge und Feldtypen, aber nicht die **Eindeutigkeit ihrer IDs**. Bei mehreren Threads mit derselben ID und widersprüchlichem `status` überschreibt `new Map(...)` im bisherigen `parseStoryTurn` frühere Einträge. Bei NPCs blieb die gleiche ID mehrfach möglich. Damit war der Input vor der Anbieteranfrage mehrdeutig. Ein echter Vorfall oder tatsächliche Kosten durch dieses Szenario sind nicht nachgewiesen.

## Implementierung

- `backend/src/story.ts`: neue exportierte Funktion `validateStoryTurnContext(input)` prüft doppelte ID innerhalb von `threads` und `npcs` jeweils unabhängig voneinander. Gleiche ID in **verschiedenen** Namespaces bleibt gültig. Sie benutzt den vorhandenen `duplicate_story_id`-Fehler und fordert keine neue Persistenzstruktur.
- `parseStoryTurn` ruft diese Prüfung auch dann auf, wenn Storyupdates ohne HTTP-Gateway verarbeitet werden. Mehrdeutige Eingaben werden vor Mapping/NPC-Verweisen abgewiesen.
- `backend/src/app.ts`: nach Authentifizierung und bestehender JSON-Schema-Prüfung lehnt die Route ungültigen Kontext mit HTTP **400** und generischem `invalid_request` ab, **bevor** der eventuell externe `narrator.advanceStory` aufgerufen wird. Providerfehler bleiben davon getrennt HTTP 502; keine geheimen Story-Felder in Fehlerantworten.
- `backend/test/story.test.ts`: reine Validator-/Parser-/Mock-Gegenbeispiele sowie HTTP-Injection (2 ungültige Anträge ⇒ 0 Providercalls, gültiger Antrag ⇒ 1 Providercall), keine API-Schlüssel oder bezahlten Anfragen.

## Bewusste Grenzen

Der Fix erzwingt nur **ID-Eindeutigkeit des Storykontexts**, nicht eine umfangreiche Umstrukturierung aller NPC-/Rollen-/Kampagnenreferenzen und keine sprachliche Kontrolle von Plotspoiler-Paraphrasen. Session-Zugriff, vorhandene Quoten und bestätigte Regelzustände bleiben unverändert. App-Version **0.8.38+88**, SQLite **2**, Export-JSON **1** ohne Migration. Keine Erhöhung des SRD-5.2.1-Abdeckungsstatus.

## Akzeptanzkriterien / Tests

- Duplizierter Thread mit widersprechendem Endstatus und duplizierter NPC werden **vor** einer externen Erzählanfrage mit HTTP 400 zurückgewiesen.
- Direkter `parseStoryTurn`-Aufruf darf die Prüfung nicht umgehen.
- Unterschiedliche Namespaces und ein gültiger existierender Request funktionieren weiter. `stateChanges: []` unverändert.
- `npm run typecheck && npm run build && npm test`, Python-/Import-Boundaries und vollständige Flutter-/Android-CI auf **exakt letztem PR-HEAD**; die grüne CI von [#164](https://github.com/ManuEtt/Dnd/actions/runs/40123094457) ist keine Abnahme dieses neuen Pakets.
- Produktive API-Kosten, Android-Gerät und Altspielstand-Upgrade nicht getestet.

**Integrationsreihenfolge:** [#164](https://github.com/ManuEtt/Dnd/pull/164) ist die noch offene gemeinsame Basis. [#165](https://github.com/ManuEtt/Dnd/pull/165) und #167 sind unabhängige, jeweils gestapelte PRs gegen #164. Der parallele Kampf-PR #166 bleibt unangetastet. Nach ausdrücklich genehmigtem #164-Merge beide Nachfolge-PRs getrennt auf dann aktuelles `main` ausrichten, erneut CI prüfen und reviewen. Kein Main-Push oder automatischer Merge.
