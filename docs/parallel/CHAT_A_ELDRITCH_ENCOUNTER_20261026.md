# Chat A – Eldritch Blast im Einzelgegnerkampf (26.10.2026)

- **Basis:** geprüfter [PR #202](https://github.com/ManuEtt/Dnd/pull/202), Head `31136c840ebc82f84923fa799065151cf1a118a6` (vollständige GitHub-CI #40271848617 `success`).
- **Eigener Branch:** `feat/chat-a/eldritch-blast-encounter-20261026`, ausdrücklich auf #202 gestapelt.
- **IMPLEMENTIERT:** `GameEngine.castEldritchBlastSingleEnemy` und `GameController.castEldritchBlastSingleEnemy`. Die bisher rein lesenden Strahlen werden gegen genau einen gespeicherten Gegner mit Magic-Aktion, Kraftschadensabwehr je Strahl, einem revisionsgebundenen Event und einer atomaren SQLite-Buchung ausgeführt. Kein Zauberplatzverbrauch und keine Speicherformatänderung.
- **TESTS GESCHRIEBEN:** `app/test/srd_eldritch_blast_encounter_test.dart`: Sieg-/Treffer-/Verfehlungsablauf, resistenter Schaden je Instanz, ungültige Zielrevision/RK, Vorab-Guards, SQLite-Neustart, alte Revision und vollständiger Transaktionsrollback bei Event-SQL-Fehler.
- **GETESTET:** Für das **neue** Paket ist die tatsächliche vollständige GitHub-CI noch zu prüfen; grüne CI von #202 ist nur der Baseline-Beleg.
- **NICHT GETESTET:** echte Android-Geräteabnahme, UI-Kontrollfluss, Multi-Gegner-HP, produktive Signierung.
- **BLOCKIERT:** unabhängige persistente Zielauswahl für mehrere Feinde fehlt im Encounter-Schema; andere parallel laufende Chats und Integrations-PRs dürfen nicht überschrieben werden.
- **NOCH NICHT IMPLEMENTIERT:** Invocation-/Hex-/unmodellierte Boni sowie Mehrgegner-Kampagnenwirkung.
- **NÄCHSTER SCHRITT:** finalen stacked-PR-CI-Stand abnehmen und die koordinierte Integration nach Freigabe von #202 durchführen. Danach separate UI-Bedienung für einen gespeicherten Gegner mit bewussten Checkboxen/Revision und Dialogtests.
- [Fachbeleg](../SRD_ELDRITCH_BLAST_ENCOUNTER_20261026.md). `SPELL-ENTRY-ELDRITCH-BLAST` bleibt `partial`.
