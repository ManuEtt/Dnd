# Chat B – NPC-Kontext ohne Steuerzeichen (30.10.2026)

## Chat B – bestätigte NPC-Chronik ohne unsichtbare Steuerzeichen (30.10.2026)

[Draft-PR #398](https://github.com/ManuEtt/Dnd/pull/398) auf
`feat/chat-b/npc-context-control-sanitizing-20261030`, Ausgangs-`main`
`55fe44475a113943c6310ec16a8ffb481185f4e9`.

**IMPLEMENTIERT:** Der schreibgeschützte `NpcContinuityReader` entfernt
ASCII-/C1-Steuerzeichen, Unicode-Zeilentrenner und Bidi-Formatierungszeichen
vor der Darstellung bestätigter Namen, Beziehungen und NPC-Notizen.
Visuell gleiche NPC-Namen werden so deterministisch als mehrdeutig erkannt;
sichere gespeicherte IDs bleiben die einzige Unterscheidung.
Vier neue positive und negative Flutter-Regressionen im
`npc_continuity_control_chars_test.dart`; keine bestätigten Fakten verändert.

**GETESTET:** GitHub-Quellstand, PR-Dateipfade und fremde offene PRs geprüft.
**NICHT GETESTET:** neue Flutter-Regressionen und vollständige CI auf dem
finalen Dokumentationscommit noch abzunehmen; lokal kein Dart/Flutter-SDK,
kein GitHub-DNS-Checkout. Reales Android-Gerät/produktive KI nicht geprüft.
**MIGRATION:** keine; SQLite/JSON, Regeln und App-Version unverändert.
**KOORDINATION:** PR #396 ändert ein anderes Storymodul; gemeinsame README-
und Checkpoint-Dokumentation vor einem Merge additiv durch Chat D konsolidieren.
**NÄCHSTER SCHRITT:** Finales CI-Format/Tests des PR #398 prüfen; bei Fehlern
auf demselben Branch korrigieren, danach Review ohne automatischen Merge.
# Chat B – NPC-Erinnerungs-Wire (30.10.2026)

## Chat B – Bidi-sichere NPC-Erinnerungen im Erzählertransport (30.10.2026)

- **Ausgangs-main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`; **Branch:** `feat/chat-b/npc-narrator-wire-bidi-20261030`; **PR:** [#403](https://github.com/ManuEtt/Dnd/pull/403) (Draft).
- **Ausgangsproblem:** Unauffällige Unicode-Bidi-Formatierungsmarkierungen konnten gespeicherte NPC-Notizen im `memories`-Transport täuschend darstellen. Gleich angezeigte Namen wie `Mira` und `Mira` mit Bidi-Override galten als zwei unabhängige Namen und erlaubten eine scheinbar eindeutige Namenszuordnung.
- **IMPLEMENTIERT:** `app/lib/story/npc_narrator_memory.dart` normalisiert diese Formatierungszeichen nur für die ausgehende, schreibgeschützte Erinnerung und ihre Namenserkennung. Visuell identische NPCs erhalten ohne explizite Identitätsauswahl keine priorisierten NPC-Notizen. Vier neue Fälle in `app/test/npc_narrator_bidi_wire_test.dart` für Identitätsmehrdeutigkeit, sauberen Wire-Text, Legacy-JSON und SQLite-Neustart mit echtem GameController und kostenlosem Fake-Backend.
- **GETESTET:** Quellstand, Main-SHA und alle offenen PR-Dateipfade auf Überschneidungen geprüft. **CI für PR #398:** [Push](https://github.com/ManuEtt/Dnd/actions/runs/41007610629) und [PR](https://github.com/ManuEtt/Dnd/actions/runs/41007615695) beide auf `92ddc263` erfolgreich; diese gehören zum **vorherigen** Paket, nicht zu #403.
- **NICHT GETESTET:** neue Tests/Flutter-Analyse/Android-APK von #403 erst nach finaler GitHub-CI gültig; reales Gerät/TalkBack und produktiver KI-Anbieter offen. Kein lokales Dart-/Flutter-SDK.
- **MIGRATIONEN:** keine, Regelzustand, SQLite/JSON und App-Version unverändert. Auch ältere gespeicherte Werte werden nicht umgeschrieben.
- **KOORDINATION:** #396 (`story_memory_engine.dart`) und #398 (`npc_continuity_reader.dart`) betreffen andere Fachdateien. Gemeinsame README und zentrale Checkpoints müssen Chat D additiv konsolidieren; kein Merge fremder PRs.
- **NÄCHSTER SCHRITT:** Finale vollständige CI von #403 auf dessen finalem HEAD abnehmen und bei Fehlern im eigenen Branch reparieren; keine Freigabe ohne grüne Builds.

---

# Chat B – Sitzungsidentität beim Ereignis-Replay (27.10.2026)

## Chat B – unveränderliche NPC-Erinnerung nach SQLite-Neustart (30.10.2026)

- **PR:** [#431](https://github.com/ManuEtt/Dnd/pull/431). **Ausgangspunkt:** `main` `69bfe78ec4eeb30042b26971978038a2ee9dac34`, Chat-B-Branch `feat/chat-b/npc-context-immutable-restart-20261030`. Alle 38 zuvor offenen PRs auf Änderungen an den neuen Fach- und Testpfaden geprüft; keine Überschneidung. PR #424 ist mit GitHub Actions [#41120298615](https://github.com/ManuEtt/Dnd/actions/runs/41120298615) vollständig grün, aber weiterhin offen.
- **Problem:** `NpcIdentityContext.toContextMap()` lieferte ein veränderbares äußeres Map, eine veränderbare Notizliste und veränderbare Notizmaps. Aufrufer konnten nach der Bestätigung erzählte NPC-Kontextwerte ohne Spielstandänderung manipulieren.
- **Implementiert:** Das äußere Kontext-Map, die verschachtelte Liste und jede Notizmap sind jeweils unmodifiable. Identische Felder, Reihenfolge, JSON-Ausgabe und Story-/Backend-Protokoll bleiben erhalten; keine Regel- oder Speicher-Migration.
- **Testpaket:** `app/test/npc_identity_context_immutable_restart_test.dart` prüft erlaubte JSON-Ausgabe, gesperrte Mutationen auf drei Ebenen, identische NPC-Namen mit unterschiedlichen IDs, explizite Auswahl, SQLite-Schließen/Neustart, gleichrevisionierte Änderungen und unveränderten persistierten Heldenzustand.
- **Tests/CI zum Zeitpunkt der Anlage:** Testcode hinzugefügt, finale Flutter-/Android-CI auf dem Branch gesondert nachweisen, kein Gerätetest oder kostenpflichtiger KI-Dienst. Zentrale README-/Checkpoint-Ergänzungen additiv halten und mit Chat D koordinieren.
- **Nächster Schritt:** Den fertigen PR-Commit durch alle Gates abnehmen und erst danach die Integration durch Chat D freigeben.
## Chat B – Strukturierte NPC-ID-Kontexte gegen Unicode-Bidi-Täuschung (30.10.2026)

- **Ausgangs-main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`; **Branch:** `feat/chat-b/npc-identity-bidi-context-20261030`; **PR:** [#407](https://github.com/ManuEtt/Dnd/pull/407), Draft; Fachcode-Commit `dfc3bf90c63f33335d4b7a4c2c420b91af4b4f61` (finalen HEAD im PR prüfen).
- **Ausgangsproblem:** Optisch identische NPC-Namen mit Bidi-Richtungszeichen konnten für die freie NPC-Auswahl als unterschiedlich gelten; die strukturierte `npcContexts`-Projektion gestattete dieselben Zeichen in Namen, Beziehungen und bestätigten Notizen.
- **IMPLEMENTIERT:** `app/lib/story/npc_identity_story_payload.dart` ignoriert unsichtbare Bidi-Formatierungszeichen bei der *Namenseindeutigkeit*, weist betroffene Originaltexte im strukturierten, revisionsgebundenen Transport aber zurück (fail-closed). Bestätigte SQLite-/JSON-Daten werden nicht umgeschrieben; explizite valide NPC-ID-Auswahl bleibt möglich.
- **TESTS ERGÄNZT:** `app/test/npc_identity_bidi_story_wire_test.dart`: sechs Flutter-Testfälle, darunter mehrere Unicode-Markierungen, vier unsichere Felder, positiv deutsche Namen/Revisionsgrenzen, Legacy-Kampagne ohne Notizen, zweimal SQLite-Neustart mit kostenlosem Fake-Backend und `npc-identity-v1` an/aus. **Ergebnis:** vollständige GitHub-CI von PR #407 am endgültigen Commit auswerten, vor Abschluss keine grüne CI behaupten.
- **DATEIEN:** `app/lib/story/npc_identity_story_payload.dart`, `app/test/npc_identity_bidi_story_wire_test.dart`, `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_B_CHECKPOINT.md`. Keine fremden Fachdateien, keine Migration/Buildnummer/SRD-Regeländerung.
- **KOORDINATION:** PRs #396, #398 und #403 ändern andere Storymodule. README-/Checkpoint-Einträge von Chat A/C/D bei Integration durch Chat D additiv konsolidieren; kein automatischer Merge. `memories`-Text-Wire ist gesonderte Arbeit in [#403](https://github.com/ManuEtt/Dnd/pull/403), keine doppelte Änderung hier.
- **BLOCKIERT/NICHT GETESTET:** CI-/Android-Abnahme für PR #407 bis zum finalen Lauf offen; reales Android-Gerät, TalkBack und produktive KI nicht getestet.
- **NÄCHSTER SCHRITT:** PR-CI und Push-CI bis zum Abschluss prüfen, bei Fehlern Ursache im eigenen Branch beheben, dann an Chat D zur konfliktfreien Integration übergeben.
## Entwicklung 30.10.2026 – sichere NPC-ID im bestätigten Story-Gedächtnis (PR #396)

- **Ausgangs-main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`. **Branch:** `feat/chat-b/safe-npc-identity-recall-20261030`. **Fachcode-Commit:** `34b92d7ee6cc0415f8ca7d4ebcac977e70efda26`; **Test-Commit:** `d43d3246fdee2682c74e1cbc8f1607c38a1c3077`. [Draft-PR #396](https://github.com/ManuEtt/Dnd/pull/396); finalen Dokumentations-HEAD in GitHub nachsehen.
- **Problem:** `MemoryEngine.retrieve` und `buildSessionSummary` schrieben untypische gespeicherte IDs gleichnamiger NPCs einschließlich Zeilenumbrüchen ungeprüft in bestätigte Erzählertexte, anders als die bereits gehärtete Identitätsabfrage.
- **Lösung:** Eindeutig gespeicherte gleichnamige NPCs erscheinen nur noch mit kanonischer ID `[A-Za-z0-9_-]{1,64}`; sonst werden ihre mehrdeutigen NPC-spezifischen Zeilen/Notizen aus dem Recall und Recap ausgelassen. Andere NPCs und eindeutig benannte historische NPCs bleiben lesbar. Nichts wird im gespeicherten Spielstand umgeschrieben.
- **Geänderte Fachdateien:** `app/lib/story/story_memory_engine.dart`; neuer Test `app/test/story_memory_unsafe_npc_id_test.dart`. Dokumentation additiv in README, zentralem und persönlichem Checkpoint.
- **Akzeptanz / Regression:** Negativfälle für Zeilenumbruch, Leerzeichen, Punkt und 65 Zeichen; gültige 64-Zeichen-ID, SaveSessionRecap mit JSON-Roundtrip, eindeutiger Legacy-NPC mit untypischer ID. Unveränderte Heldenwerte und Spielstände. Bestehende Tests bleiben aktiv.
- **GETESTET:** Code- und PR-Struktur sowie aktuelle fremde PR-Dateipfade über GitHub geprüft; **keine ausgeführte Dart/Flutter-Regressionssuite belegt**.
- **NICHT GETESTET:** Dart-Format, Flutter-Analyse/-Test, Python-, Backend-, Android-/native CI auf finalem Commit; echtes Android-Gerät und KI-Provider. Auf GitHub Actions warten und finalen Head gesondert zuordnen.
- **BLOCKIERT:** Direkter Git-Checkout wegen DNS, lokal weder Flutter- noch Dart-SDK. GitHub-Connector stellt Branch-/PR-Schreiben bereit.
- **Migrationen:** keine (SQLite/JSON unverändert). Regelengine, Controller, Domänen- und Speichermodelle nicht geändert.
- **Koordination:** Bei Start offene PRs #387, #388, #389, #391, #392, #394, #395; keine Story-Fachdateien betroffen. Geteilte README/Checkpoint-Änderungen durch Chat D additiv zusammenführen; kein automatischer Merge.
- **Nächster konkreter Schritt:** Die vier neuen Regressionen plus vollständige CI auf finalem PR-HEAD prüfen, Fehler im eigenen Branch korrigieren und erst danach Review/Freigabe beantragen.

---
## Chat B – Eindeutige IDs für bestätigte Story-Einträge (30.10.2026)

- **Ausgangs-main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`; **Branch:** `feat/chat-b/story-entry-id-collision-20261030`; **PR:** [#414](https://github.com/ManuEtt/Dnd/pull/414), Draft; erste Fachcommits `9001dac7` und `33088157` (finale SHA im PR verifizieren).
- **Ausgangsproblem:** Nach App-Neustart oder Import kann der zeit- und sequenzbasierte ID-Generator alte IDs erneut erzeugen. Die Speicherung neuer NPC-Beziehungsnotizen, Sitzungsrückblicke und Handlungsstränge prüfte solche Kollisionen nicht.
- **IMPLEMENTIERT:** `app/lib/story/story_campaign_engine.dart` prüft generierte Eintrags-IDs vor dem Story-Commit auf bereits vorhandene IDs desselben Typs und weist Doppelbelegungen mit `FormatException` ab. Bearbeitungen bestehender Threads behalten ihre ID. Kein Schema-, Modell-, Regel- oder SQLite-Wechsel.
- **TESTS ERGÄNZT:** `app/test/story_confirmed_entry_id_collision_test.dart` mit sechs Regressionen: drei ID-Kollisionen, JSON-Neustart-Analogie, bestehende Thread-Bearbeitung, valide neue Journaleinträge und einen echten SQLite-Schließen/Neuöffnen/Weiterführen-Roundtrip mit Revisions- und Regelzustandsprüfung. Vor dem SQLite-Zusatz bestanden beide vollständigen GitHub-CI-Läufe auf `5c70fe20602d0c5f71a17f2b15bd2bcc9fe20e4f` (PR-CI `41071413126`, Push-CI `41071407643`); der neue finale Commit benötigt erneute Abnahme.
- **DATEIEN:** `app/lib/story/story_campaign_engine.dart`, `app/test/story_confirmed_entry_id_collision_test.dart`, `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_B_CHECKPOINT.md`.
- **KOORDINATION:** Keine Fachdatei-Überschneidung mit offenen PRs #396/#398/#403/#407 oder den parallelen Chat-A/C/D-Arbeiten. Gemeinsame README- und zentrale Checkpoints bei Integration durch Chat D additiv konsolidieren. Kein Merge, kein Force-Push.
- **NICHT GETESTET/BLOCKIERT:** Laufende CI-/Android-Abnahme für #414 noch nicht belegt; reale Android-Installation und produktive KI nicht getestet. Keine Migration erforderlich.
- **NÄCHSTER SCHRITT:** Finale GitHub-Push- und PR-CI samt vollständiger Flutter-Suite und APK-Builds prüfen, rote Gates im eigenen Branch korrigieren und erfolgreichen PR zur Integration an Chat D übergeben.
## Chat B – KI-Story-Formatzeichen (30.10.2026)

- **Basis-main:** 55fe44475a113943c6310ec16a8ffb481185f4e9; **Merge-Basis:** 69bfe78ec4eeb30042b26971978038a2ee9dac34; **PR:** #424; **Implementierungs-Commit:** e754f58bdd9b43b801beeecebcc727177a80e8fb; **Branch:** feat/chat-b/story-provider-unicode-guard-20261030.
- **Problem:** Generierte Szenen, NPC- und Handlungsnamen sowie dauerhafte Notizen konnten versteckte Steuerzeichen, Bidi-Anweisungen und Zero-Width-Space enthalten.
- **IMPLEMENTIERT:** Parser von Flutter und Backend weisen solche unbestätigten Textwerte zurück; reguläre Zeilenumbrüche/Tabs sowie sichtbare Unicode-Buchstaben werden beibehalten.
- **Tests ergänzt (nicht als bestanden behauptet):** app/test/ai_story_unicode_format_guard_test.dart und backend/test/story-unicode-format-guard.test.ts mit positiven, negativen und Unveränderlichkeitsfällen.
- **Dateien:** app/lib/story/ai_story.dart, backend/src/story.ts, die zwei Tests sowie diese Chat-B-Datei, docs/CODEX_CHECKPOINT.md und README.md.
- **Keine Migration:** Modelle, Schema, SQLite, Regelzustände und Controller unverändert. Bestehende ältere Speicherstände werden nicht stillschweigend bereinigt.
- **NICHT GETESTET:** lokale Flutter-/Dart-/Android-Prüfungen mangels SDK; finale GitHub-CI und echtes Gerät noch abzunehmen.
- **Nächster Schritt:** CI-Gates auf finalem PR-Commit prüfen und bei roten Prüfungen denselben Branch reparieren.


## Integrationskandidat 29.10.2026 – Chat B

Zusammengeführte Fachpakete: [#356](https://github.com/ManuEtt/Dnd/pull/356), [#362](https://github.com/ManuEtt/Dnd/pull/362), [#364](https://github.com/ManuEtt/Dnd/pull/364), [#371](https://github.com/ManuEtt/Dnd/pull/371), [#373](https://github.com/ManuEtt/Dnd/pull/373), [#377](https://github.com/ManuEtt/Dnd/pull/377), [#383](https://github.com/ManuEtt/Dnd/pull/383). Die ursprünglichen Branch-HEADs, PR-Beschreibungen, Tests, bekannte Grenzen und Statusmeldungen sind im [Integrationsjournal](INTEGRATION_20261029.md) mit Git-Historie dokumentiert. **Dieser Stand ist weder auf main integriert noch gemeinsam CI-abgenommen; Drafts sind nicht freigegeben.** Bisherige Checkpoint-Einträge bleiben erhalten.


- **main-Basis:** `96001353f2b90f293fbdade934e78b7b8281e965`; Branch `fix/chat-b/story-replay-session-identity-20261027`.
- **Problem:** `MemoryEngine.replay` konnte ein neues, gültig geformtes Ereignis derselben Kampagne aus einer fremden Sitzung akzeptieren. Auch ein Checkpoint mit abweichender Sitzungs-ID war möglich.
- **IMPLEMENTIERT:** Session-Guard für neue Ereignisse und `stateAfter`-Checkpoints, bestehende Kampagnen-/Revisionsprüfung unverändert. Bereits bekannte identische Ereignisse früherer Sitzungen weiterhin idempotent.
- **Geänderte Pfade:** `app/lib/story/story_memory_engine.dart`; `app/test/story_replay_session_boundary_test.dart`; `docs/STORY_REPLAY_SESSION_IDENTITY_20261027.md`; README, zentrale und persönliche Checkpoints.
- **Akzeptanz:** Erfolgreicher identischer Replay-Roundtrip; fremde Events mit/ohne Checkpoint und fremde Checkpoint-Sitzungen abweisen; vorher bekannte Sitzungsereignisse deduplizieren; Seed/Regelzustand unverändert.
- **Tests:** vier neue Flutter-Regressionen erstellt; finale CI-/APK-Ergebnisse noch nicht belegt. Kein lokales Flutter-/Dart-SDK; keine kostenpflichtigen Anbieteraufrufe.
- **Parallelentwicklung:** Fachdatei bei Aufgabenwahl in keinem offenen PR geändert; PR #175 bereits gemergt. Parallele Chat-B-NPC-/Outbox-Branches #288–#314 nicht verändert. Gemeinsame README und `docs/CODEX_CHECKPOINT.md` bei Integration durch Chat D additiv konsolidieren.
- **Migration:** keine (App 0.8.42+92, SQLite/JSON unverändert); keine Regeländerung und keine automatischen KI-Aktionen.
- **BLOCKIERT:** Offline-Git-Checkout wegen DNS nicht verfügbar; Flutter-/Android-Tests lokal nicht ausführbar. Actions finalem Commit zuordnen.
- **NÄCHSTER SCHRITT:** Finale PR-CI der Story-Replay-Regression abnehmen, rote Gates auf eigenem Branch reparieren und danach Review an Chat D geben.
- **Beleg:** [Ausführliche Beschreibung](../STORY_REPLAY_SESSION_IDENTITY_20261027.md).

---

# Chat B – Gleiche NPC-Anzeigenamen in bestätigten Recaps unterscheiden (27.10.2026)

- **Main bei Branchstart:** `ff245cc253194cd0858385d535ae7b2c9132bb06`
- **Branch:** `feat/chat-b/session-recap-npc-identity-20261027`
- **Fachcommits:** `0cb212b7ce0abc8ed9ecdb6fb35cb34c2431982d` und `da4b909269273cf5f558ef9019b9e118769e5100`, danach offizielle Formatcommits. **Finalen HEAD und PR im GitHub-Pull-Request verifizieren.**
- **Ausgangsproblem:** `MemoryEngine.buildSessionSummary` bezeichnete zwei Miras mit demselben Anzeigenamen/Beziehungsstatus ohne Identitätsbeleg. `MemoryEngine.retrieve` löst das bereits per ID.
- **Implementiert:** `app/lib/story/story_memory_engine.dart` zählt normalisierte Anzeigenamen und gespeicherte IDs. Gleiche Namen erhalten `(NPC-ID: ...)`, einzigartige Namen bleiben unverändert. Doppelt vorhandene gespeicherte IDs werden nicht als eindeutige Identität im Rückblick ausgegeben.
- **Tests:** `app/test/session_recap_npc_identity_test.dart` ergänzt vier positive/negative Flutter-Tests einschließlich de-DE-Umlautvarianten, Legacy-JSON, beschädigten doppelten IDs und tatsächlichem `GameEngine.saveSessionRecap` plus JSON-Roundtrip. Heldenwerte bleiben unangetastet. Code mit Dart 3.9.2 formatiert. Vollständige CI nach finalem HEAD gesondert prüfen.
- **Geändert:** `app/lib/story/story_memory_engine.dart`, neue Testdatei, `README.md`, `docs/CODEX_CHECKPOINT.md` und dieser Checkpoint.
- **Abgrenzung:** Keine gemeinsamen Änderungen an `models.dart`, `game_engine.dart`, `game_controller.dart`, `data/*`, SRD oder Story-Transport; keine Änderung an bestehenden Spielständen, keine Migration.
- **Konflikte:** Historische README-/Checkpoint-Passagen beim Merge durch Chat D konsolidieren; parallelen Branch zur NPC-Notiz-ID-Eindeutigkeit nicht überschreiben.
- **Nicht getestet:** lokales Flutter, Realgerät, produktive KI, komplette CI bis Abschluss.
- **Nächster unabhängiger Schritt:** Bei sehr langer identischer NPC-Beschreibung sicherstellen, dass die ID im 2.400-Zeichen-Sitzungsrückblick nicht still abgeschnitten wird; Grenzfälle inklusive Abkürzung/Formatierung testen.

---

# Chat B – zwei SQLite-Schreiber, NPC-Quittungen und Auftragsersetzung (27.10.2026)

- **Base:** PR #305, Head `eb4f3a43864ba00843aacd7f0b47b2e2f0fad1da`; **Branch:** `test/chat-b/npc-outbox-multiwriter-cas-20261027`. Abhängigkeit: #288 → #290 → #292 → #300 → #303 → #305 → dieses Testpaket.
- **Ausgangsproblem:** Die atomare NPC-Löschung in PR #305 war bereits mit einer SQLite-Verbindung getestet; die Absicherung über zwei getrennte Repository-Verbindungen und konkurrierende Aufträge fehlte.
- **Implementiert:** Neue Datei `app/test/npc_outbox_multiwriter_cas_test.dart`, vier Integrationstests mit echter SQLite-Datei und zwei geöffneten `SqliteCampaignRepository`-Instanzen. Verspätete ACKs können keine bewusst neu gewählte gleichnamige Figur, keine neue Revision und keinen Auftrag beim Wechsel text-only ↔ mit NPC-Auswahl entfernen. Zwei gleichzeitige Schreibversuche führen zu exakt einem verbleibenden Auftrag. Alle Tests führen nur lokale DB-I/O aus.
- **Getestet:** Offizielle Dart-3.9.2-Formatierung für die neue Testdatei über GitHub Actions übernommen; temporärer Diagnoseworkflow entfernt. Vollständige CI auf finalem PR-Head nach Veröffentlichung auswerten.
- **Nicht getestet:** Realgerät, produktiver KI-Spielleiter; keine zusätzliche UI-E2E-Abdeckung. Keine neue Migration oder Produktionscodeänderung.
- **Blockiert:** Zuerst die Vorgänger-PRs integrieren; fremde Branches und PRs nicht löschen/mergen. Chat D konsolidiert README-/Checkpoint-Kollisionen.
- **Nächster Schritt:** CI-Ergebnisse prüfen und gegebenenfalls neue Regressionen korrigieren, danach Integrationsreihenfolge dokumentieren.

---

# Chat B – NPC-ID gehört zum atomaren ACK-Vergleich (27.10.2026)

- **Basis und Reihenfolge:** `fix/chat-b/npc-outbox-cas-20261027` auf [PR #303](https://github.com/ManuEtt/Dnd/pull/303) (`5388d8e428e024c939bf99e609f857ec37c4a62a`), davor PRs #300, #292, #290, #288. Kein Auto-Merge und keine fremde Branchbereinigung.
- **FEHLER:** Vorher prüften `PlayerActionOutbox.remove` und `SqliteCampaignRepository.removePendingAction` bei einer Quittung nur `campaignId`, `requestId` und `text`. Eine neu gebundene NPC-Auswahl mit denselben Werten konnte so versehentlich aus der Outbox entfernt werden.
- **IMPLEMENTIERT:** `selectedNpcId` und `selectedNpcRevision` sind jetzt fester Bestandteil der Löschbedingung. SQLite validiert alle Werte transaktional und löscht ausschließlich mit übereinstimmenden nullable Spalten; der ältere Settings-Fallback lehnt ebenfalls jede NPC-ID-/Revisionsabweichung ab. Text-only-Aufträge funktionieren weiterhin unverändert.
- **TESTS:** Zwei neue echte SQLite-Tests mit drei falschen NPC-Varianten, Neustart und spätem ACK für bewusst ersetzten Auftrag. Bei Mismatch bleibt der Datensatz vollständig unverändert. Exaktes ACK löscht wie zuvor. Offizieller Dart-3.9.2-Formatter angewendet.
- **DOKUMENTATION:** Meldung `UnsupportedDatabaseVersion` auf die bereits bestehende Schema-Version 3 gebracht; Kommentar zur Outbox-Neuanlage angepasst. **Keine** Migration oder Änderung des JSON-/SRD-/Backendvertrags.
- **CI:** Basispaket #303 hat vollständige Flutter-Tests bestanden und die Android-Buildschritte durchlaufen; sein abschließender Workflowstatus separat prüfen. CI für das eigene Paket erst nach Veröffentlichung und Final-HEAD-Nachweis als bestanden melden.
- **NICHT GETESTET:** Android-Realgerät, produktive KI, vollständig durchgeklickter neuer Widget-E2E.
- **NÄCHSTER SCHRITT:** UI-Meldungen für alten NPC-Auftrag mit minimalem Fake-Test prüfen, ohne SQLite-FFI und `pumpWidget` zu verschachteln.

---

# Chat B – reine Flutter-Statusanzeige für ausstehende NPC-Handlungen (27.10.2026)

- **Branch:** `test/chat-b/pending-npc-status-widget-20261027`, Basis `fix/chat-b/npc-resume-deterministic-regressions-20261027` (PR #303, Head `5388d8e428e024c939bf99e609f857ec37c4a62a`).
- **Umsetzung:** `app/lib/ui/pending_action_status.dart` enthält die bisher in `app.dart` fest verdrahtete Anzeige des ausstehenden Auftrags, Fehlertext und Retry-/Discard-Buttons. Fünf reine Widgettests in `app/test/pending_action_status_test.dart` prüfen den Zustand ohne Datenbank und Providerschnittstelle. `app/lib/ui/app.dart` nutzt dieselben Aufrufer/Keys wie zuvor.
- **UX:** Bei explizit ausgewähltem NPC erscheint ein kurzer Hinweis auf die gebundene Figur und die erforderliche erneute Auswahl nach Spielstandsänderung. Bei normalen Handlungen wird keine NPC-Identität erfunden. Fehler sind als eigene Textkomponente weiterhin sichtbar; während des Sendens sind die Retry-/Discard-Schaltflächen ausgeblendet, bei Regelblockade deaktiviert.
- **VERTRAG:** Alle bisherigen Keys `adventure-action-submitting`, `adventure-pending-action-text`, `adventure-retry-action`, `adventure-discard-action`, `adventure-outbox-error` bestehen fort.
- **FORMAT:** Offizieller Dart-3.9.2-Formatter auf Widget, `app.dart` und Widgettests angewandt; temporären Workflow wieder entfernt.
- **NICHT GETESTET:** Android-Hardware, echte TTS, vollständige App-UI-Navigation, neue CI noch abzunehmen.
- **MIGRATION:** Keine; PR #290 enthält bereits SQLite-3-Änderung. Kein Eingriff in Helden, D&D-Regeln oder gespeicherte Kampagnen.
- **INTEGRATION:** PR #288 → #290 → #292 → #300 → #303 → dieser PR, nur bei grüner CI und durch Integrationschat. Keine fremden Branches verändert oder gelöscht.
- **NÄCHSTER SCHRITT:** Große Schrift/Screenreader in der realen Android-Oberfläche prüfen; weitere Fehlerintegration nur nach stabiler Testinfrastruktur.

---

# Chat B – NPC-Outbox-FakeAsync-Sicherheit und überprüfbare Kontinuität (27.10.2026)

- **Basisbranch/Head:** `fix/chatgpt/npc-ui-async-pump-20261027` / `92f440510bdedda51bb3acb188b49c40409b3ce7` (PR #300, seinerseits abhängig von #292, #290, #288). **Branch:** `fix/chat-b/npc-resume-deterministic-regressions-20261027`.
- **Ausgangsfehler:** GitHub Actions #40492615824 und #40505592178: 10-Minuten-Timeout und `TestAsyncUtils.guard`-Konflikt beim UI-`pumpWidget` mit SQLite-FFI. Erst das originale unbeschränkte Warten, danach das Nesting von `tester.pumpWidget` in `tester.runAsync`, lösten die Testprobleme aus. Der Grund lag im Testharness.
- **Implementiert:** `resolvePendingNpcAction` wertet vor dem Senden ausschließlich die ausgewählte NPC-ID, ursprüngliche Revision und bestätigte Ereignisquittung (Request-ID, Text, NPC-ID) aus. Es gibt genau fünf explizite Zustände `plain`, `ready`, `alreadyConfirmed`, `stale`, `unavailable`; nur eine exakte Quittung klärt einen verlorenen ACK. `app.dart` bindet den Helfer an den vorhandenen Sende-/Retry-Pfad an; keine automatische Providerübertragung.
- **Tests erneuert:** Vier `test()`-basierte echte SQLite-/GameController-/BackendTransport-Regressionsfälle in `npc_ui_outbox_restart_integration_test.dart`, ohne Widget-Testharness: zweite gleichnamige Mira, verlorene Quittung nach Datenbankneustart, stale Revision mit erhaltenem Outboxauftrag und gleiche Request-ID/Text bei anderer NPC-ID. Die NPC-Auswahl-Widgettests aus PR #290 bleiben unverändert erhalten. Diese Tests beweisen **nicht** die vollständige Klickstrecke im `LivingGameApp`.
- **Weitere Dateien:** README, zentrale und Chat-B-Checkpoints ergänzt; bestehende Angaben der früheren PRs als Verlauf belassen.
- **Teststatus:** Formatierung exakt nach Dart 3.9.2 durchgeführt; gesamte Flutter-/Backend-/Android-CI nach Veröffentlichung prüfen. Realgerät und produktive Provider ungetestet.
- **Keine Migration:** vorhandenes SQLite-3-Schema, Kampagnen-JSON 1, SRD-Regelzustände und Backendvertrag unverändert.
- **Reihenfolge:** PR #288 → #290 → #292 → #300 → dieses Inkrement, ggf. durch Chat D konfliktarm integrieren. Keine fremden Branches bereinigen/mergen.
- **NÄCHSTER SCHRITT:** Isolierte Flutter-Oberflächenmeldungen mit Fake-Repository-/Fake-Clock testen, statt reale SQLite-I/O und `pumpWidget` zu verschachteln.

---

# Chat B – NPC-Aktion nach SQLite-Neustart und verlorenem ACK (27.10.2026)

- **Branch:** `test/chat-b/npc-ui-restart-reconciliation-20261027`; Base `feat/chat-b/npc-picker-outbox-20261027` (PR #290, Head `c45d7f7ce82e367e78d102ccc98b0046683cbd23`). Vorherige Abhängigkeit: PR #288.
- **Ausgangsproblem:** Controller-ID-Auswahl und sichere SQLite-v3-Outbox sind fachlich geprüft, aber die echte Flutter-Abenteueroberfläche musste noch vollständig gegen Neustart, doppelte NPC-Namen und verloren gegangene ACKs getestet werden.
- **Implementiert:** Neuer reiner End-to-End-Test `app/test/npc_ui_outbox_restart_integration_test.dart`: Flutter-App mit echter SQLite-Datei, `LivingGameApp`, `GameController`, `PlayerActionOutbox`, stillem Voice-Mock und ausschließlich lokalem `BackendTransport`-Mock.
- **Fälle:** (1) Der Spieler tippt die zweite von zwei „Mira“-Figuren an; ausschließlich deren ID und Notiz werden transportiert. (2) Bei persistiertem Auftrag und bereits bestätigtem Event führt eine UI-Wiederholung nach Neustart **keinen** zweiten Backendaufruf aus und entfernt die Outbox. (3) Eine seit Auswahl geänderte Kampagnenrevision blockiert den Retry ohne Spielstandsänderung und ohne automatisches Umlenken auf den anderen NPC.
- **Format:** Exakte Ausgabe des offiziellen Dart-3.9.2-Formatters auf die neue Testdatei übernommen; kurzlebigen Diagnose-Workflow vollständig entfernt.
- **KEINE Produktioncodeänderung:** Kein Eingriff in Flutter-UI, Backend, Datenbank, Export-Schema, Kampagnenregeln, Asset-Dateien oder bestehende Testdateien; gemeinsame Docs/README hinzugefügt, historische Dokumentation beibehalten.
- **CI-Status:** Vollständige GitHub-CI für PR #290 ist auf dem korrigierten Head `c45d7f7c` zweimal grün (#40482612142 und #40482623135). Die CI dieses Inkrements erst nach nachgewiesener Ausführung als grün melden.
- **OFFEN:** Echte Android-/Screenreader-/TTS-Tests; PR-Integration muss #288 → #290 → diesen PR folgen. Fremde Branches und PRs bleiben unverändert.
- **Nächster Schritt:** Fail-closed-Tests für Verwerfen und erneute bewusste Auswahl nach einer abgelaufenen NPC-Revision, ohne parallele Chat-C-Oberfläche zu berühren.

---

# Chat B – NPC-Auswahl in Android-UI plus persistente Outbox (27.10.2026)

- **Branch:** `feat/chat-b/npc-picker-outbox-20261027`, basiert auf `feat/chat-b/controller-explicit-npc-selection-20261027` (PR #288, Basis-SHA `2ba524c307b3b48ad21a6343df700ae0a643f55d`). Kein unabhängiger Merge vor #288.
- **Problem:** Der bestehende Controller konnte die manuell gewählte NPC-ID transportieren, die Oberfläche bot keinen Auswahlweg. Die bisherige SQLite-2-Outbox speicherte nur Text und Request-ID; bei Restart wäre eine UI-Auswahl verlorengegangen.
- **IMPLEMENTIERT:** Neuer `npc_story_selection_dialog.dart` mit deutschen Texten, IDs neben identischen Anzeigenamen, Screenreader-Beschriftung, aktiver Auswahl oder Abbruch. Nur NPCs mit bestätigter Beziehungsnotiz sind wählbar. Im Adventure-Composer ist der neue Button bei ausgehandelter `npc-selection-v1` aktiv. Bestehender Sendeauftrag bleibt für Sprach-/Text-/Schnellaktionen maßgeblich.
- **KONTINUITÄT:** `PendingPlayerAction` persistiert optional `selectedNpcId`/`selectedNpcRevision` mit dem Text. `_dispatch` rekonstruiert nur die identische ausgewählte ID; bei neuer Revision bleibt der Auftrag sichtbar und wird nicht automatisch auf einen gleichnamigen NPC umgelenkt. Ein exaktes bestätigtes Ereignis darf den verloren gegangenen ACK nach Restart auflösen. Alle anderen Varianten benötigen neue bewusste Auswahl.
- **SCHEMA/MIGRATION:** SQLite `3` (vorher `2`): zusätzliche nullable `selected_npc_id`/`selected_npc_revision` im `pending_player_actions`-Datensatz, Version-2-Migration durch `ALTER TABLE`. Version 1 wird in denselben Endzustand übertragen. Alte textbasierte Aufträge bleiben unverändert; Kampagnen-JSON/Backend/SRD-Regeln unverändert.
- **TESTS:** `npc_story_selection_dialog_test.dart` (eindeutige ID trotz gleicher Namen, Abbruch, leere bestätigte Liste); `npc_selected_action_outbox_test.dart` (SQLite-Restart, ungültige Auswahl abweisen, SQLite-2-Upgrade). Die Ausgabe des offiziellen Dart 3.9.2-Formatters wurde übernommen.
- **BERÜHRTE DATEIEN:** `app/lib/ui/app.dart`, neuer Dialog, `player_action_outbox.dart`, `campaign_repository.dart`, `sqlite_campaign_repository.dart`, zwei neue Tests, README und beide CODEX-Checkpoints.
- **GEPRÜFT:** Aktueller Repo-/PR-Stand, Formatter. CI auf finalem PR-HEAD nachsehen. Keine manuelle Geräte- oder Live-KI-Abnahme.
- **BLOCKIERT:** Integration PR #288; gemeinsame UI-/README-Dokumentation durch Chat D bei Merge konsolidieren. Keine fremden Branches gelöscht.
- **NÄCHSTER SCHRITT:** Race/Restart-Sendeauftrag-Ende-zu-Ende-Test für verlorenes ACK und gleichnamige NPCs.

---

# Chat B – transportierte NPC-Erinnerungen bleiben bei zwölf Einträgen (27.10.2026)

- **Branch:** `test/chat-b/npc-memory-wire-budget-20261027`; Basis `fix/chat-b/npc-memory-budget-20261027` (PR #307, Head `47b4343fadd5f30b9030a702b3ccd701d701a598`). Gestapelter reiner Test-PR, kein unabhängiger Merge vor #307.
- **Konkret implementiert:** `app/test/npc_story_memory_wire_budget_test.dart` testet beide Backend-Fähigkeitsvarianten `npc-identity-v1` an/aus mit einer gespeicherten KI-Kampagne. Sie enthält 3 bestätigte Mira-Notizen und 18 allgemeine Fakten; `GameController.sendAction` führt über `NpcNarratorMemory.merge` zum Story-Transport, dessen `memories`-Payload erfasst wird.
- **AKZEPTANZ:** Exakt 12 Erinnerungseinträge, maximal 400 UTF-16-Codeeinheiten je Text, 3 jüngste bestätigte Mira-Notizen vorn, ergänzende allgemeine Fakten nur auf Restplätzen. Je ausgehandelter Fähigkeit optionale `npcContexts` und passende Revision vorhanden oder vollständig abwesend. Held bleibt identisch, neue Revision und rekonstruierter SQLite-Zustand stimmen überein.
- **KEINE PRODUKTIONSÄNDERUNG:** Nur neue Testdatei, README, zentrale und Chat-B-Checkpoints. Keine Android-Grafik/Bedienlogik, SRD, SQLite-Migration, Backend-API oder Providerkosten.
- **GETESTET:** GitHub-Hauptbranch/PR-Abhängigkeit und Transport-/Persistenz-Verträge geprüft; offizielles Dart-Formatter-Ergebnis anwenden und CI auf finalem PR-Commit ausführen. Android-Realgerät und Live-KI ungetestet.
- **PARALLEL:** Keine Fachdatei-Kollision mit den Chat-B-Outbox-PRs #303–#306. Dokumentationsdateien bei Integration konfliktarm konsolidieren.
- **NÄCHSTER SCHRITT:** Nach vollständiger grüner CI den PR erst nach #307 integrieren; weitere Grenzfälle deduplizierter oder leerer Erinnerungen separat absichern.

---

# Chat B – geteiltes Erinnerungslimit für NPC- und allgemeine Fakten (27.10.2026)

- **Basis:** `main` `f9b2f72a4bf8e4216bf8baac60c7f92c4a8a997f`; Branch `fix/chat-b/npc-memory-budget-20261027`. Unabhängig von der NPC-Auswahl-/Outbox-Kette #288 → #290 → #292 → #300 → #303 → #305 und dem parallelen UI-Status-PR #304.
- **PROBLEM:** `NpcNarratorMemory.merge` prüfte erst *nach* dem Anhängen allgemeiner Erinnerungen, ob das gemeinsame `limit` erreicht war. Bei `npcNoteLimit == limit` und mindestens einem normalen Fakt konnte die Ausgabe das Budget überschreiten.
- **IMPLEMENTIERT:** Vor dem Anhängen normaler Erinnerungen bei `result.length == limit` abbrechen. Priorität bestätigter NPC-Notizen und Verhalten bei freier Kapazität unverändert. Kein neues Verhalten für gleichnamige NPCs; diese werden aus Freitext weiterhin nicht geraten.
- **TESTS:** Zwei bestätigte NPC-Notizen mit Budget zwei, eine Notiz mit Budget eins, zwei Notizen mit Budget drei (ein normaler Fakt) sowie Unveränderlichkeit von Originalkampagne und Rückgabedaten prüfen. Bestehende Tests beibehalten.
- **DATEIEN:** `app/lib/story/npc_narrator_memory.dart`, `app/test/npc_narrator_memory_test.dart`, README, zentrale und Chat-B-Checkpoints. Alle Dart-Dateien offiziell formatiert.
- **NICHT GETESTET:** Lokale Flutter-/Android-Läufe, Realgerät, Live-Provider; GitHub-CI auf finalem Commit noch separat abzunehmen.
- **KEINE MIGRATION:** SQLite-Version 3, JSON-Export 1, Backend-Kontrakt und D&D-SRD unverändert.
- **NÄCHSTER SCHRITT:** Ein Ende-zu-Ende-Test für maximal 12 Erinnerungen am Story-Transport ohne Gefahr doppelter NPC-Namen.

---

# Chat B – NPC-ID nach SQLite-Neustart sicher fortsetzen (26.10.2026)

- **Ausgangs-`main`-SHA:** `67f146e690306b13d490bd8e7fd5636bb187c77e`.
- **Eigener Branch:** `feat/chat-b/npc-selection-resume-20261026`.
- **Implementierungs-/Test-Commit:** `945f6a18c3ce1570f52d95d8d21e453dbaf519dc`; PR und finaler Branch-SHA sind nach Veröffentlichung im GitHub-PR nachzusehen.
- **Vor Aufgabenwahl geprüfte PRs:** #244, #245, #246, #247, #248; während des Inkrements wurde zusätzlich Integrations-PR #250 eröffnet. Der neue Testpfad wird in keinem dieser PRs geändert. Gemeinsame `README.md` und `docs/CODEX_CHECKPOINT.md` durch Chat D bei der Integration konsolidieren.
- **AUSGANGSPROBLEM:** Nach Neustart gab es für zwei gleichnamige NPCs keinen einzelnen durchgängigen Regressionstest von bestätigtem SQLite-Spielstand über explizite Auswahl bis zum ausgehandelten Backend-Protokoll, einschließlich Revisionswechsel.
- **IMPLEMENTIERT:** `app/test/npc_selection_resume_sqlite_test.dart` als neuer, deterministischer Integrationstest mit echter temporärer SQLite-DB und kostenlosem Fake-Transport: Campagne speichern, DB neu öffnen, gleichnamige Mira-NPCs nicht aus freier Prosa erraten, Mira-ID ausdrücklich wählen, exakt eine gespeicherte Notiz zum Erzähler transportieren, erneute Sitzung bestätigen, alte Auswahl bei neuer Revision sperren, neu wählen und nur dieselbe gespeicherte NPC-ID übertragen. Separater Negativtest für Legacy-JSON ohne optionale NPC-Notizen.
- **GEÄNDERTE DATEIEN:** neuer Flutter-Test sowie `README.md`, `docs/CODEX_CHECKPOINT.md` und dieser Checkpoint. Keine Domain-, Controller-, Schema- oder Regelcodeänderung.
- **AKZEPTANZ:** ausschließlich `mira-two` mit ihrer gespeicherten Notiz in `npcContexts` und `selectedNpcId`; `mira-one` und ihre Notiz nie im ID-Kontext; stale Revision abgewiesen; lokaler Held und Spielstand unverändert; ältere JSONs ohne NPC-Notizen produzieren keinen erfundenen Verlauf.
- **TESTS:** Zwei Flutter-Tests neu erstellt. Ausführung über aktuelle GitHub-CI nachsehen, **nicht durch bloße Testdatei als bestanden werten**.
- **NICHT GETESTET:** Flutter/Android lokal (kein Flutter-/Android-SDK); echtes Gerät, produktiver KI-Provider und Revisionsrace zwischen Anforderungsaufbau und HTTP-Senden.
- **MIGRATION:** Keine. SQLite-Version 2 und Kampagnen-JSON 1 unverändert.
- **NÄCHSTER SCHRITT:** Bei erfolgreicher CI und nach Integration #250 einen eigenständigen narrativen Test gegen Änderungen an bereits abgeschlossenen Handlungssträngen durch unveränderten Terminalstatus erstellen; bestehende manuelle Bearbeitung muss weiterhin möglich bleiben.

---

# CHAT B – Checkpoint: NPC-Zeitstempel, 26.10.2026

- **Ausgangs-Main-SHA:** `20098805d8c70cbd361a13862379894c47ef4eb6`.
- **Branch:** `fix/chat-b/npc-timestamp-validation-20261026`.
- **Implementierungscommit:** `d7d47523d0b6679c3210ab5a9e86e7c430b2933d`; nachfolgende reine Dokumentationskorrektur auf demselben Branch. **PR:** [#220](https://github.com/ManuEtt/Dnd/pull/220).
- **PRs bei Aufgabenwahl:** #216 und #218 (UI bzw. Skripte, mit zentralen Dokumenten), #219 (Integration derselben UI-/Skriptänderungen). Keine fachliche Überschneidung im Backend-Validator oder seinem Test.
- **Problem:** `Date.parse` akzeptiert erfundene Kalendertage (z. B. 2026-02-30) und 24:00, korrigiert dabei die Zeitachse der bestätigten NPC-Chronik ohne ausdrückliche Zustimmung.
- **Implementiert:** UTC-Zeitstempel nur dann anerkennen, wenn der geparste Zeitwert dieselbe Kalendersekunde repräsentiert; bisher erlaubte 1 bis 6 Dezimalziffern, gültige UTC-Zeitstempel und Schaltjahre erhalten.
- **Dateien:** `backend/src/story_npc_identity_context.ts`, `backend/test/story-npc-identity-context.test.ts`, `README.md`, `docs/CODEX_CHECKPOINT.md`, diese Datei.
- **Akzeptanz:** Ungültige Tage/24:00 werden vor Aufruf eines Story-Providers abgelehnt. Gültige Schalttage und Millisekunden-/Mikrosekundenpräzision bleiben gültig; sonstige Alt-Clients ohne `npcContexts` unverändert.
- **Daten/Regeln:** keine Speicherung, keine Migration, SQLite 2 / Kampagnen-JSON 1; kein autoritativer Regelzustand oder NPC-Beziehungsupdate aus KI-Texten.
- **TESTS HINZUGEFÜGT:** Backend-Unit-Test positiver/negativer Kalenderdaten; negativer HTTP-Integrationstest vor Provideraufruf.
- **GETESTET:** für den Implementierungscommit noch keine vollständige GitHub-CI belegt; CI wurde über [PR #220](https://github.com/ManuEtt/Dnd/pull/220/checks) gestartet, zum Dokumentationszeitpunkt in Bearbeitung.
- **NICHT GETESTET:** Backend-/Flutter-/Python-Gesamtsuiten, Android-APK und reales Gerät.
- **BLOCKIERT:** lokales Flutter-/Android-SDK und vollständiger Checkout fehlen; tatsächliche PR-CI gesondert prüfen.
- **NÄCHSTER SCHRITT:** Nach erfolgreicher PR-Abnahme im kostenlosen Mock eindeutige revisionsgebundene NPC-Identitätskontexte als reinen Erzählhinweis nutzen. Abnahmekriterien: identische Namen bleiben nach ID getrennt, alte Clients funktionieren, keine mechanischen oder bestätigten Zustandsänderungen, Tests für Leer- und Wiederaufnahmeszenarien.

---

## Historischer Chat-B-Checkpoint vom 25.10.2026 (unverändert übernommen)

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

---

## Chat B – explizite NPC-Auswahl im Story-Protokoll (26.10.2026)

- **Ausgangs-Main:** `42d14ad36cc947691f7e5a1e8647a43f5421b86e`; offene Pull Requests: keine. Main-Workflow #40329543416 und #40329543284 `success`.
- **Eigener Branch:** `feat/chat-b/explicit-npc-wire-20261026`, PR gegen `main`; GitHub-PR-HEAD/CI bei Abschluss prüfen.
- **Implementiert:** Streng optionales, separat angekündigtes `selectedNpcId` für identische Anzeigenamen. Der Offline-Mock verwendet exakt die ausdrücklich gewählte und id-/revisionsgebundene NPC-Chronik ohne Erraten. Flutter-Netzwerkclient akzeptiert das Feld nur bei `npc-selection-v1`; alte Server bleiben kompatibel. Lokale `NpcIdentityStoryPayload`-Projektion bewahrt die ID.
- **Geänderte Fachdateien:** `backend/src/story_npc_identity_context.ts`, `backend/src/app.ts`, `backend/src/mock_npc_identity_hint.ts`, `app/lib/story/npc_identity_story_payload.dart`, `app/lib/services/backend_narrator.dart`.
- **Tests:** `backend/test/story-npc-explicit-selection.test.ts`, `app/test/backend_explicit_npc_transport_test.dart`, `app/test/npc_story_selection_test.dart`; positive/negative Sicherheit und Legacy-Vertrag.
- **Keine Migration:** keine SQLite-/JSON-/Rule-/Hero-/Quest-Mutation, keine Versionsänderung. Ältere Backendversionen melden das neue Capability nicht. Noch keine angeschlossene Android-UI-Auswahl.
- **Abnahme:** vollständige CI auf finalem Commit erforderlich; keine Test- oder APK-Freigabe vor entsprechender GitHub-Action. Kein Produktiv-KI-/Gerätetest.
- **Einziger nächster Schritt:** explizite NPC-ID-Auswahl im Story-Dialog samt Stale-Revisionsabbruch und automatisierten Widget-/Transporttests, abgestimmt mit Chat C. Siehe [Detailcheckpoint](CHAT_B_NPC_SELECTION_WIRE_20261026.md).


**GitHub-Nachtrag Chat B (26.10.2026):** [PR #237](https://github.com/ManuEtt/Dnd/pull/237) enthält das optionale `selectedNpcId`-Protokoll. Im nachgewiesenen Lauf [#40342521532](https://github.com/ManuEtt/Dnd/actions/runs/40342521532) haben Backend, Dart-Format, Flutter-Analyse und komplette Flutter-Tests bestanden; Android-Build bei Abruf noch offen. Abschlussstatus gilt nur für exakt getesteten PR-HEAD. Keine Übernahme nach `main`, keine Spielstandmigration.
