# Chat B – Eindeutige NPC-Herkunft beim Erinnerungsabruf (26.10.2026)

## Ausgangsstand
- Basis-`main`: `dbeac3f7da4fa3a9759d447ef9e9eeb41d575970` (PR #219 bereits integriert).
- Eigener Branch: `fix/chat-b/disambiguate-recalled-npc-memories-20261026`.
- Zu Beginn offene PRs: #220 (Backend NPC-Zeitstempel), #221 (Feuerpfeil), #222 (Mock-NPC-Gedächtnis), #223/#225 (TalkBack-UI), #224 (explizite NPC-Auswahl). Deren Fachpfade überschneiden sich nicht mit `app/lib/story/story_memory_engine.dart` oder der neuen Regressionstestdatei.
- PR #224, Commit `4b0b9ad62f74e32f0659a39ffac8706a2fbb040f`: GitHub Actions #40292038729 vollständig erfolgreich. Diese neue Aufgabe implementiert **nicht nochmals** die NPC-ID-Auswahl.
- Zentral gemeinsam bearbeitete Dokumentation (README, CODEX_CHECKPOINT) bei Integration durch Chat D zusammenführen.

## Ausgangsproblem
`MemoryEngine.retrieve` bereitete NPC-Beziehungsnotizen ausschließlich mit ihrem Anzeigenamen auf. Zwei verschiedene NPCs mit identischem Namen (z. B. Mira/MIRA) waren im bestätigten Rückblick nicht unterscheidbar. Identisch formulierte Erinnerungsnotizen konnten zudem anhand ihrer Textidentität dedupliziert werden. `MemoryEngine` gehört zur lokalen bestätigten Erinnerung, nicht zum KI-Anbieter.

## Akzeptanz und Implementierung
- Bei mehrfach vorkommenden normalisierten Anzeigenamen werden Status- und Beziehungszeilen um die **eindeutige gespeicherte NPC-ID** ergänzt; eindeutig benannte NPCs bleiben im vorhandenen Format.
- Zu einer NPC-ID mehrere widersprechende Stammdatensätze bedeuten **unbestätigte Eigentümerschaft**: betreffende Beziehungen und Statuszeilen werden nicht als eindeutige Erinnerung ausgegeben.
- Zwei NPC-Notizen mit identischem Text, aber unterschiedlichen IDs bleiben getrennte bestätigte Erinnerungen.
- Kürzung bei `maxCharacters` darf die für gleiche Namen erforderliche ID nicht verstecken. Ist die vollständige Zuordnung im vorgegebenen Zeichenbudget nicht möglich, entfällt der konkrete NPC-Eintrag; andere Erinnerungsquellen bleiben verfügbar.
- Normale Fakten/Inventar/Quests und deren Prioritäten unverändert. Keine Dialog- oder KI-Behauptungen zu bestätigten Fakten machen.
- Reiner Leseweg: keine geänderten Kampagnenrevisionen, Regelwerte, SQLite- oder JSON-Formate.

## Geänderte Dateien
- `app/lib/story/story_memory_engine.dart`: sichere, datensparsame ID-Anzeige nur bei gleichen Namen, verweigerte Doppel-ID-Zuordnung und Schutz vor Abschneiden des Identifikators.
- `app/test/memory_recall_npc_identity_test.dart`: sechs Regressionen einschließlich gleichnamiger NPCs, identischer Notiztexte, Legacy-JSON-Roundtrip, doppelt gespeicherter IDs, kurzer Zeichenbudgets und nicht betroffener Fakten.
- `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_B_CHECKPOINT.md`: separates Inkrement protokolliert.

## Tests / Blocker
- Backend wird nicht fachlich geändert; GitHub Actions prüfen Projektstruktur/Python/SRD, Backend, Dart-Format, Flutter-Analyse, komplette Flutter-Tests und Android-Builds auf dem finalen Branch-Commit.
- Lokal sind Node.js und Python vorhanden, aber kein Dart/Flutter-SDK. Keine Behauptung von lokalen Flutter-Tests oder lauffähigen Android-Geräteinstallationen.
- Im laufenden Entwicklungszyklus CI-Ergebnisse nach tatsächlichem GitHub-Lauf nachtragen und eventuelle Fehler korrigieren.
- Keine Migration und keine Versionsänderung erforderlich.

## Nächster Schritt
Nach Integration von PR #224 im koordinierten Chat-C-/Chat-D-Schritt eine explizite ID-Auswahl **in der Kampagnen-UI** anbinden und sie per Roundtrip-Test bis zum Narrator überprüfen. Keine unkontrollierte Änderung an gemeinsam genutzten Controller-/UI-Dateien in diesem Paket.
