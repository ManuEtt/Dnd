# Chat B – NPC-Tagebuch im Mock-Erzähler (25.10.2026)

## Ausgangsstand und Zuständigkeit
- Projekt: Würfelraunen – Chat B (KI-Spielleitung und Kampagne).
- Ausgangs-`main`: `af70a48c84d83c133ced4200be04ca81a91abf1b`.
- Branch: `feat/chat-b/mock-npc-recall-20261025`.
- Offene PRs bei der Auswahl: #178, #179, #180, #181, #184, #185, #187, #188 und #189. Die neue Fachänderung liegt ausschließlich in `backend/src/story.ts`, `backend/src/mock_npc_memory.ts` und `backend/test/mock-npc-memory.test.ts`; keiner dieser Pfade war in den offenen PRs geändert.
- PR #187 zur gezielten Weitergabe gespeicherter NPC-Notizen hat auf `80f103a3ba5ab8a95670375140e87dd1d4b459bc` vollständige grüne GitHub-CI #40222745973. PR #187 ist noch nicht in `main` gemergt und wird weder kopiert noch überschrieben.

## Problem
Die serverseitige Mock-Kampagnenfortsetzung ignoriert bisher auch dann die übergebenen `memories`, wenn der Spieler erneut eine bekannte Figur anspricht. Ihre Narration bleibt generisch, während der kostenpflichtige Provider aus demselben Erinnerungsfeld Kontext aufnehmen darf.

## Paket und Akzeptanzkriterien
- Neue rein narrative `mockNpcDiaryHint`-Funktion im Backend wertet ausschließlich ein vorhandenes, formal markiertes Tagebuchfeld mit einer ausdrücklich im Spielertext genannten, eindeutig benannten NPC-Figur aus.
- Bei Namensgleichheit, fehlenden/ungültigen Tagebuchmarkern oder fremden NPCs gibt es keinen neuen Tagebuchhinweis.
- Die erste relevante Tagebuchnotiz wird auf höchstens 160 Unicode-Codepunkte begrenzt und einzeilig ausgegeben; gleiche Eingaben ergeben gleiche Antworten. Deutschen Umlauten und Wortgrenzen wird Rechnung getragen.
- Die Ausgabe ist **nur** Erzähltext. Weder Mock noch Provider erhalten dadurch Schreibrechte für HP, XP, Inventar, Regeln oder Kampagnenzustand.
- Daten im Request sind weiterhin **nicht vertrauenswürdig**; die im Text stehende Kennzeichnung „Bestätigte NPC-Beziehungsnotiz“ ist nicht als serverseitig kryptographisch bestätigte Wahrheit zu verstehen.
- Keine Änderungen an SQLite, JSON, Backend-Schema oder Android-Version.

## Implementiert
- `backend/src/mock_npc_memory.ts`: deterministischer, rein lesender Tagebuchhinweis mit exakter Namenszuordnung, Unicode- und Steuerzeichen-Begrenzung.
- `backend/src/story.ts`: `mockStoryTurn` fügt den Hinweis in seine bestehende Erzählung ein, ohne den ansonsten generierten StoryTurn zu verändern.
- `backend/test/mock-npc-memory.test.ts`: sechs Tests für erlaubten NPC-Hinweis, deterministische Integration, negative Namens-/ID-Fälle, Unicode-Begrenzung, nicht passende/fehlende Marker und ausbleibende Regelzustandsänderungen.

## Teststand
- GitHub-Code/Testdateien angelegt und gespeichert, **finale CI-Prüfung steht vor der eigentlichen GitHub-Actions-Abnahme noch aus**.
- Erforderlich: `npm ci`, `npm run typecheck`, `npm run build`, `npm test` im Backend; Python- und Flutter-Regressionsgates, Android-Debug-Build über GitHub Actions.
- Ohne erfolgreichen Workflow auf dem finalen Commit ist kein Test oder Release als bestanden zu melden.
- Nicht überprüft: realer Android-Gerätetest, echter OpenAI-Provider, produktive Signierung.

## Parallelität und Migration
- Keine Migration. Persistente Altspielstände bleiben unverändert, da dieser Patch nur Text aus dem bestehenden Request liest.
- README und zentraler `docs/CODEX_CHECKPOINT.md` können mit anderen PRs kollidieren; Chat D konsolidiert diese Texte bei Integration. Kein ungeprüfter Auto-Merge.

## Ein nächster Schritt
Nach CI und Review den Story-Betrieb hinsichtlich eindeutig identifizierbarer Figuren bei gleicher sichtbarer Namensform absichern. Akzeptanz: keine fremden Notizen bei Namensgleichheit, lesbare Unterscheidung über bestätigte NPC-ID und keine Übernahme unbestätigter KI-Fakten.
