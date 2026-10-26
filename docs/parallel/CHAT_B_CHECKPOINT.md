# CHAT B – Checkpoint: NPC-Zeitstempel, 26.10.2026

- **Ausgangs-Main-SHA:** `20098805d8c70cbd361a13862379894c47ef4eb6`.
- **Branch:** `fix/chat-b/npc-timestamp-validation-20261026`.
- **Arbeitscommit:** siehe Branch-HEAD; PR-Nummer nach Erstellung zu ergänzen.
- **PRs bei Aufgabenwahl:** #216 und #218 (UI bzw. Skripte, mit zentralen Dokumenten), #219 (Integration derselben UI-/Skriptänderungen). Keine fachliche Überschneidung im Backend-Validator oder seinem Test.
- **Problem:** `Date.parse` akzeptiert erfundene Kalendertage (z. B. 2026-02-30) und 24:00, korrigiert dabei die Zeitachse der bestätigten NPC-Chronik ohne ausdrückliche Zustimmung.
- **Implementiert:** UTC-Zeitstempel nur dann anerkennen, wenn der geparste Zeitwert dieselbe Kalendersekunde repräsentiert; bisher erlaubte 1 bis 6 Dezimalziffern, gültige UTC-Zeitstempel und Schaltjahre erhalten.
- **Dateien:** `backend/src/story_npc_identity_context.ts`, `backend/test/story-npc-identity-context.test.ts`, `README.md`, `docs/CODEX_CHECKPOINT.md`, diese Datei.
- **Akzeptanz:** Ungültige Tage/24:00 werden vor Aufruf eines Story-Providers abgelehnt. Gültige Schalttage und Millisekunden-/Mikrosekundenpräzision bleiben gültig; sonstige Alt-Clients ohne `npcContexts` unverändert.
- **Daten/Regeln:** keine Speicherung, keine Migration, SQLite 2 / Kampagnen-JSON 1; kein autoritativer Regelzustand oder NPC-Beziehungsupdate aus KI-Texten.
- **TESTS HINZUGEFÜGT:** Backend-Unit-Test positiver/negativer Kalenderdaten; negativer HTTP-Integrationstest vor Provideraufruf.
- **GETESTET:** für diesen neuen Commit noch keine vollständige lokale oder GitHub-CI belegt.
- **NICHT GETESTET:** Backend-/Flutter-/Python-Gesamtsuiten, Android-APK und reales Gerät.
- **BLOCKIERT:** lokales Flutter-/Android-SDK und vollständiger Checkout fehlen; tatsächliche PR-CI gesondert prüfen.
- **NÄCHSTER SCHRITT:** Nach erfolgreicher PR-Abnahme im kostenlosen Mock eindeutige revisionsgebundene NPC-Identitätskontexte als reinen Erzählhinweis nutzen. Abnahmekriterien: identische Namen bleiben nach ID getrennt, alte Clients funktionieren, keine mechanischen oder bestätigten Zustandsänderungen, Tests für Leer- und Wiederaufnahmeszenarien.
