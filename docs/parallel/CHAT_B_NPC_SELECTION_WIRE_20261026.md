# Chat B – explizite NPC-ID über die sichere Story-Verbindung (26.10.2026)

## Ausgangspunkt und Parallelkoordination

- Ausgangs-`main`: `42d14ad36cc947691f7e5a1e8647a43f5421b86e` (kombinierte Main-CI #40329543416 und #40329543284 erfolgreich).
- Chat-B-Branch: `feat/chat-b/explicit-npc-wire-20261026`; PR wird gegen `main` eröffnet.
- Zu Beginn **keine offenen PRs**. Bereits integrierte Pakete #222 (Offline-Mock erinnert ID-gebunden) und #224 (lokale explizite NPC-Auswahl) sind Grundlage; keine fremden Branches oder Hauptbranch geändert.
- Erster Abnahmeschritt: isolierte Transport- und Mock-Verbindung, **keine Flutter-UI-Arbeit** und keine Domain-/Speichermodelländerung.

## Ausgangsproblem

Die lokale Story-Bibliothek kann unter `NpcStorySelection.choose` zwei gleichnamige gespeicherte NPCs anhand der ausdrücklich ausgewählten `npcId` unterscheiden. Der Client übermittelte jedoch weiterhin nur den strukturierten Kontext ohne ein ausdrückliches Auswahlkennzeichen. Der Offline-Mock durfte bei gleichem sichtbaren Namen daher nicht auf genau eine Figur schließen und erzählte keine gezielte Chronik.

## Akzeptanzkriterien

1. Bei zwei gleichnamigen NPCs wird **nur der tatsächlich gewählte Kontext** mit genau übereinstimmender ID und Kampagnenrevision für Erzähltext verwendet – auch wenn der Spieler den Namen nicht im Freitext erwähnt.
2. Mit unbekannter, fremder, doppelter, fehlender oder nicht zum Snapshot passender `selectedNpcId` folgt HTTP 400 **vor** einem Erzähler-Provideraufruf; keine stille Zuordnung anhand gleicher Namen.
3. Das Backend bietet ein separates `npc-selection-v1`-Merkmal für kompatible Clients; Altserver und Altclients bleiben bei `npc-identity-v1` sowie Legacy-Nachrichten.
4. Keine Änderungen an Trefferpunkten, Ausrüstung, XP, Quests, Kampf- oder anderen regelautoritativen Zuständen; `stateChanges: []`.
5. Revisionsgebundene Flutter-Auswahl wird bei Payload-Erstellung/Prüfung beibehalten und beim Transport nur nach Verhandlung und mit exakt einem ausgewählten Kontext gesendet.

## Implementiert

- `backend/src/story_npc_identity_context.ts`: neues optionales `selectedNpcId` im Kontexttyp; gekoppelte Prüfung `campaignRevision`/`npcContexts`, exakte Identität, genau ein Snapshot mit Notizen, kein Orphan oder ID-Spoofing.
- `backend/src/app.ts`: Sessions (GET/POST) bewerben zusätzlich `npc-selection-v1`; neue optionale Fastify-Property mit strenger ID-Syntax.
- `backend/src/mock_npc_identity_hint.ts`: wenn ausgewählte ID gültig ist, nur die für sie gespeicherte, neueste Notiz erzählen; ohne Auswahl bleibt die bisherige Ambiguitätssperre aktiv.
- `app/lib/story/npc_identity_story_payload.dart`: `selectedNpcId` wird von `NpcStorySelection` in den revisionsgeschützten, rein lesenden Story-Kontext übernommen und gegen ihn überprüft.
- `app/lib/services/backend_narrator.dart`: `supportsExplicitNpcSelection` wird **nur** bei gültiger aktiver Session mit beiden Fähigkeiten aktiviert, bei Trennung zurückgesetzt; `selectedNpcId` nur bei passender, einziger Kontext-ID übertragen.
- Tests: `backend/test/story-npc-explicit-selection.test.ts` (Unit + echter Fastify-Mock), `app/test/backend_explicit_npc_transport_test.dart` (Aushandlung, Altserver, ungültige IDs, Logout), `app/test/npc_story_selection_test.dart` (geprüfte ID des aufgebauten Kontextes).

## Sicherheitsgrenzen / Kompatibilität

- Das Backend hat **keinen eigenen autoritativen Kampagnen-Snapshot**: es kann nur die Konsistenz der vom Client behaupteten ID und Revision prüfen. Die Bestätigung der Auswahl geschieht lokal; untrusted Client-Fakten werden ausschließlich für **Erzählung** verwendet.
- Die **Android-UI und der Spiel-Controller übertragen noch keine benutzergewählte ID**, solange keine explizite UI-Aktion angeschlossen ist. Die Pipeline ist dafür vorbereitet; es handelt sich noch nicht um einen vollständigen Bildschirm-Workflow.
- Bestehende Nachrichten ohne `selectedNpcId` bleiben gültig; kein SQLite-/JSON-/API-Version-Wechsel oder geänderte App-Buildnummer. API-Feld ist optional, Capability neu.
- Keine echten OpenAI-/bezahlten Provider-Requests. Keine reale Android-Geräteinstallation oder produktive Signierung.

## Test- und Prüfdokumentation

- Zuordnung CI/PR immer auf **exaktem finalen Branch-HEAD** vor Freigabe prüfen. Zwischencommits sind kein Freigabenachweis.
- Verbindlich: Python-Struktur/SRD, Backend-Typecheck/-Build/-Tests, Dart-Format, Flutter-Analyse/-Tests und Debug-/Alpha-APK-Builds in GitHub Actions.
- Frühere fehlerhafte Zwischencommits hatten syntaktisch beschädigte Zeilen in `app.ts` bzw. `backend_narrator.dart`; diese wurden **vor** PR-Abnahme korrigiert, nicht durch Testdeaktivierung verdeckt.
- Lokales Dart-/Flutter-SDK nicht installiert; keine lokale Android-Abnahme. GitHub-CI ist der technische Prüfkanal.

## Genau ein nächster Schritt

Eine gezielte **Bedienoberfläche für die Auswahl zweier gleichnamiger NPCs** nach Abstimmung mit Chat C implementieren, die die bereits erstellte Auswahl sicher an `GameController` übergibt und bei einer zwischenzeitlichen Kampagnenrevision die Auswahl wieder verlangt.
