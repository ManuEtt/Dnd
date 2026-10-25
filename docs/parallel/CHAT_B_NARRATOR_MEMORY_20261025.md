# Chat B – NPC-Erinnerungen im KI-Erzählerkontext (25.10.2026)

## Git und Parallelkoordination

- Ausgangs-`main`: `45bea9c2a897275583bdbe32ed50afde5d0a76b0` (PR #182 integriert).
- Eigener Branch: `feat/chat-b/npc-narrator-memory-20261025`.
- PR: Wird nach der Code- und Dokumentationssicherung gegen `main` eröffnet.
- Andere offene PRs zum Start: #178, #179, #180, #181, #183, #184, später #185. Der Dateiabgleich ergab **keine** Überschneidung mit den hier geänderten Story-/Controller-/Testdateien. README und zentraler Checkpoint sind gemeinsam genutzte Dokumentation und vor Integration mit Chat D abzugleichen.
- PR #179: Erinnerungserkennung separat, nicht überschrieben. PR #181: eigenständige NPC-Historienprojektion separat, nicht überschrieben und noch nicht Voraussetzung dieses Pakets.

## Problem

Der bestehende `GameController._withNarration` versendet die ersten zwölf allgemein priorisierten `MemoryEngine.retrieve`-Erinnerungen an `/v1/story/advance`. Ältere bestätigte NPC-Beziehungsnotizen können dabei aus dem begrenzten Payload verdrängt werden, obwohl die aktuelle Handlung genau den NPC erwähnt.

## Implementiert

- `app/lib/story/npc_narrator_memory.dart`: ausschließliche, lesende Auswahl bestätigter NPC-Notizen. NPC-Namen müssen als ganze Wörter im aktuellen Handlungswortlaut vorkommen. Zugehörige Notizen werden zeitlich absteigend und bei Zeitgleichheit nach späterer Ereignisposition geordnet. Standardmäßig maximal drei priorisierte Notizen, insgesamt maximal zwölf Kontexteinträge à 400 UTF-16-Codeeinheiten. Keine unbeabsichtigte Dopplung allgemeiner Erinnerungen, Texte werden einzeilig und Unicode-sicher begrenzt.
- `app/lib/services/game_controller.dart`: bindet die neue Auswahl **nur für den KI-Kampagnenpfad** `advanceStory` an den bereits bestehenden `memories`-Parameter an. Keine neuen Providerfelder oder API-Schemaänderungen.
- `app/test/npc_narrator_memory_test.dart`: sieben Tests zu Priorisierung, irrelevanten NPCs, deutschen Namen, Sortierung, fehlenden/zweideutigen IDs, Grenzen und Alt-JSON.
- `app/test/npc_narrator_memory_integration_test.dart`: vollständiger GameController/SQLite/BackendTransport-Mock-Durchstich mit bestätigter NPC-Beziehungsnotiz, echter persistierter Handlung und überprüftem `/v1/story/advance`-Payload. Kein kostenpflichtiger Anbieter.

## Akzeptanzkriterien

1. Bei Handlung mit genanntem NPC hat dessen bestätigte frühere Beziehungsnotiz im KI-Kontext Vorrang.
2. Nicht genannte NPCs, unbestätigte Szenen-/Dialogprosa und ungültige Zuordnungen werden nicht als neue bestätigte NPC-Kontextfakten eingefügt.
3. Bestehender Backendvertrag `memories` bleibt auf höchstens zwölf Strings mit höchstens 400 Codeeinheiten je Element begrenzt.
4. Gleicher gespeicherter Stand ergibt denselben Kontext, einschließlich alter JSON-Spielstände und gleicher Zeitstempel.
5. Der lokale autoritative Zustand, Held, Quests, Kampf und Spielstandtransaktionen bleiben unverändert; keine automatischen Regelzustandsänderungen.

## Tests und offene Abnahme

- Code und zwei Testdateien sind in den GitHub-Branch geschrieben. Lokale Flutter-/Dart-Testausführung ist hier nicht verfügbar.
- Nach dem PR: exakten Commit prüfen und CI-Gates (Projektstruktur, Importgrenzen, Python/Backend, Dart-Format, Flutter-Analyse/Tests, Android-Debug-/Alpha-Build, native Android-Tests) anhand der tatsächlichen Ergebnisse ausweisen.
- Kein erfolgreiches CI- oder APK-Ergebnis ohne abschließenden SHA-gebundenen Workflow behaupten.
- Ausstehend: reale Android-Installation, produktiver Provider, manuelles altes Gerätedaten-Upgrade und Release-Signierung.

## Migrationsfolgen und Grenzen

- Keine Änderung an SQLite, Export-JSON, `StoryTurnInput` oder der App-Version.
- Confirmed bedeutet lokal persistierter, strukturierter Kontext. Sein Freitext ist weiterhin **untrusted input**, niemals eine Systemanweisung oder Grundlage für HP, XP, Gold, Regeln oder Questabschlüsse.
- Diese Anpassung hebt ausdrücklich erwähnte NPC-Notizen hervor; sie ist keine allgemeine semantische Erinnerungssuche.

## Nächster einzelner Schritt

Eine persistente, explizite NPC-Auswahl für die KI-Kontextpflege auch bei Namensgleichheit entwickeln, ohne IDs aus KI-Freitext zu übernehmen. Akzeptanz: bestätigte NPC-ID, Ablehnung unbekannter ID und Stale-Revision, keine Änderung an Regel-/Speichermodellen ohne Integrationskoordination.
