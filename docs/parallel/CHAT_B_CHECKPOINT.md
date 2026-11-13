## 06.11.2026 – Ältere Unicode-Formatmarken aus Wiederaufnahmekontext entfernen

- **Ausgangs-main:** `9a0fa855374a67805e531ad8574e048d99b33745`; **Branch:** `feat/chat-b/resume-legacy-format-marks-20261106`; **PR:** [#598](https://github.com/ManuEtt/Dnd/pull/598) (Draft).
- **Fach-/Testcommit:** `49be541a4d2a841d09d182c424f202b8440c2166`, Dokumentations-/finalen Head nach Veröffentlichung prüfen.
- **Problem:** Im Kampagnen-Wiedereinstieg wurden alte, unsichtbare Unicode-Formatmarken U+00AD, U+034F, U+180E und U+206A–U+206F in gesicherten Texten noch angezeigt.
- **Implementiert:** `CampaignResumeReader.read` neutralisiert diese Formatmarken ausschließlich in seinen Auszügen, nicht in JSON/SQLite oder bestätigtem Zustand. Unveränderlicher `requireCurrent`-Rohstempel und vorhandene Grenzen bleiben gültig.
- **Geänderte Dateien:** `app/lib/story/campaign_resume_context.dart`, neuer Test `app/test/campaign_resume_legacy_format_marks_test.dart`, `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_B_CHECKPOINT.md`.
- **GETESTET:** GitHub-Main, 16 offene PRs, geänderte Story-Fachdateien und Branchvergleich geprüft. Keine fachliche Überschneidung mit #582, #590, #593.
- **NICHT GETESTET:** Drei neue Flutter-Tests sind geschrieben, aber noch nicht ausgeführt; keine lokale Dart-/Flutter-Toolchain, vollständige CI des finalen Heads ausstehend; kein Android-Gerät und keine Produktiv-KI.
- **BLOCKIERT:** Flutter-/Dart-/Android-Abnahme via GitHub Actions; fremde additive README-/Checkpoint-Nachträge müssen vor Merge verlustfrei konsolidiert werden.
- **Migration:** Keine; IDs, gespeicherte Kampagne, SQLite 3/JSON 1, Regeln, Replay und App-Version bleiben gleich.
- **Nächster konkreter Schritt:** CI/Format/Android-Build auf dem finalen PR-Head abnehmen und bei einem Fehlbefund exakt diesen Branch korrigieren.

---

## Konsolidierung 04.11.2026 – PR #536

Die ursprüngliche Chat-Dokumentation wird unter Erhalt ihrer bisherigen Abschnitte im übergreifenden Integrationsbranch `fix/chat-d/branch-migration-actions-20261104` ergänzt. Die Gesamt-CI ist unabhängig von den Einzel-PRs zu prüfen.

---

---

## Chat B – 04.11.2026: Eindeutige offene Story-IDs beim Wiedereinstieg (#536)

- **Ausgangs-main:** `c8f25132a82bcf55368a79100e0c2ea5595140b6`.
- **Branch:** `feat/chat-b/resume-lead-id-integrity-20261104`, **PR:** [#536](https://github.com/ManuEtt/Dnd/pull/536) (Draft).
- **Fachcommit:** `0c9243b3d5f8cc1232372081403a963dcf864c09` (Parser/ID-Prüfung korrigiert), **Testcommit:** `d8d12b3ee2aae27e1b415190fd0353ce73969284` (nach CI-Testbefunden); Dart-Formatcommit `351f5a5c97af2387e3b9704b169ca90011a18487`. Finalen Branch-HEAD nach Dokumentationscommit ermitteln.
- **Ausgangsproblem:** `CampaignResumeReader.read` nahm alle `status == open`-Einträge ohne Prüfung der gespeicherten Thread-ID als bestätigte offene Spur. Ein nicht validierter In-Memory-Spielstand mit identischer ID für `open` und `resolved`/`abandoned` kann abgeschlossene Spuren wieder anzeigen. Reguläre JSON-Importe lehnen doppelte IDs bereits korrekt ab.
- **IMPLEMENTIERT:** Identitäten vor Auswahl zählen; nur exakt einmalige kanonische IDs mit 1–64 ASCII-Zeichen (Buchstaben, Ziffern, Unterstrich, Bindestrich) zulassen. Doppelte und unsichere IDs konsequent aus der reinen Anzeige ausschließen. Gültige offene Spuren behalten ihre bisherigen Prioritäten, ihre Reihenfolge und das `maxLeads`-Limit.
- **Neue Regressionstests:** `app/test/campaign_resume_lead_id_integrity_test.dart` mit vier Tests zu widersprüchlichen und identischen Dubletten, unsicheren Unicode-/Zeilenende-IDs, Auswahlgrenzen, Ablehnung von Dubletten beim JSON-Import sowie SQLite-Schließen/Neuöffnen mit gültiger eindeutiger ID, unveränderten Heldenwerten und Journal-Rekonstruktion.
- **Dateien:** `app/lib/story/campaign_resume_context.dart`, neuer Test, additive README-/CODEX-/Chat-B-Checkpoint-Abschnitte.
- **GETESTET:** Live-GitHub-/Masterprompt-/PR-Prüfung; eigener Fachcode und Tests versioniert. [CI #41783012878](https://github.com/ManuEtt/Dnd/actions/runs/41783012878) auf vorherigem HEAD: Python, Backend, Dart-Format und Flutter-Analyse erfolgreich; 3095 Flutter-Tests bestanden, zwei neue Tests mit unzutreffenden Erwartungen fehlgeschlagen. Die Tests wurden in `d8d12b3` korrigiert, erneute vollständige CI noch nicht belegt. Main-Android-CI auf `c8f25132a82bcf55368a79100e0c2ea5595140b6` bei Prüfung erfolgreich; **nicht** gleichzusetzen mit PR-CI #536.
- **NICHT GETESTET:** Neues vollständiges CI auf finalem PR-HEAD; reales Android-Gerät/Upgrade, produktive KI; lokal kein Flutter-/Dart-SDK.
- **BLOCKIERT:** Finale CI-Gates und Review. README und zentraler Checkpoint müssen mit anderen PRs additiv integriert werden, nicht überschrieben. PR #535 bearbeitet andere UI-Fachpfade.
- **Datenkompatibilität:** Keine Migration oder Mutation; unveränderte Originale, Schema, Regelwerte, Questzustände, KI-Provider und App-Version.
- **Nächster konkreter Schritt:** Finalen CI-Lauf #536 prüfen und bei Fehlern im eigenen Branch korrigieren; anschließend von Chat D integrieren lassen.

---

# Chat B – NPC-Kontext ohne Steuerzeichen (30.10.2026)

## Chat B – verspätete Story-Antwort nach SQLite-Neustart (31.10.2026)

- **Basis-main:** `47ab002872b7d46daeae03bb558258cf2ea73e4a`. **Branch:** `feat/chat-b/delayed-story-response-restart-20261031`. **Pull Request:** [#446](https://github.com/ManuEtt/Dnd/pull/446).
- **Problem:** Ein KI-Anbieter kann nach einem anderen, bereits bestätigten lokalen Spielstand antworten und eine veraltete Handlung samt NPC-Notiz oder neuer Handlungsspur anbieten. Diese darf eine jüngere SQLite-Revision nicht überschreiben.
- **Implementiert:** `app/test/ai_story_delayed_sqlite_restart_test.dart` mit zwei unabhängigen SQLite-Verbindungen und echter Wiederaufnahme nach Schließen/Wiederöffnen; kontrolliert verzögerter Fake-Story-Provider und reale `GameController.sendAction`-Integration. Positiv: genau ein narrativer Spielzug nach Neustart; negativ: während der Provider wartet, wird ein manueller Story-Faden abgeschlossen und bestätigt, danach werden verspätete neue Threads/NPC-Notizen ohne Zweitevent abgelehnt. Neustart, unveränderte Heldenwerte, Journal und rekonstruiertes SQLite-Snapshot werden geprüft.
- **Dateien:** neuer Flutter-Storytest sowie additive README-/Checkpoint-Ergänzungen. **Keine** Änderungen an Regelengine, gemeinsamem Modell, SQLite-Schema, Controller oder Backend, kein kostenpflichtiger KI-Aufruf.
- **GETESTET:** Der alte PR #431 ist bereits gemergt und dessen beide CI-Läufe grün (Vorläufer, nicht dieses Paket).
- **NICHT GETESTET:** Flutter-/Dart-/Android-Gates dieses neuen Pakets sind bis zu einem bestätigten finalen CI-Lauf offen; lokales Flutter-SDK und GitHub-DNS-Checkout fehlen.
- **Nächster Schritt:** CI inklusive des neuen Tests abnehmen, etwaige Formatierungs-/Testfehler im selben Branch korrigieren, dann Chat D zur Integration vorlegen.


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

## Chat B – bestätigte NPC-Beziehungsauswahl für die Wiederaufnahme (02.11.2026)

- **Basis-main:** `885580202caeafc9787538b6dc1c833b3190a529`.
  **Branch:** `feat/chat-b/confirmed-npc-resume-selection-20261102`.
  **Draft-PR:** [#489](https://github.com/ManuEtt/Dnd/pull/489).
  **Fachcommit:** `7d28e4f5934e0e5ef407fdfda402b63638f3e5a2`.
  **Testcommit:** `f7408a6762d5e9ba776cc70a00b07cd1f08ca594`.
- **Ausgangsproblem:** Ohne Ranking können beim Laden einer Kampagne
  alte, wenig relevante NPC-Beziehungen vor aktuellen bestätigten
  Erinnerungen erscheinen; Namen allein gewährleisten keine Identität.
- **IMPLEMENTIERT:** eigenständiger schreibgeschützter
  `ConfirmedNpcResumeSelector` mit eindeutigen lokalen NPC-IDs;
  neueste bestätigte Notizzeit, gespeicherte Tie-Break-Reihenfolge
  und stabiler NPC-ID, keine unbestätigte KI-Prosa als Quelle.
  Ungültige/kollidierende IDs werden übersprungen; max. drei NPCs,
  bis drei Notizen pro NPC, globale 2.400 UTF-16-Einheiten mit
  rune-sicherer Kürzung und Unicode-/Bidi-Bereinigung.
  `ConfirmedNpcResumeSelection.requireCurrent` prüft Campaign-/Session-/
  Revision und die vollständigen ursprünglichen NPC-Quelldaten, auch
  hinter abgeschnittenen Texten.
- **Dateien:** `app/lib/story/confirmed_npc_resume_selection.dart`,
  `app/test/confirmed_npc_resume_selection_test.dart`, README
  und beide Checkpoints. Keine Domänen-/Regel-/Controller-/SQLite-
  oder Provider-Schnittstelle geändert.
- **GETESTET:** GitHub-Stand, offene PRs, Module/Tests geprüft;
  offizielle Dart-Formatierung auf beiden neuen Dateien angewandt.
  **NOCH NICHT GETESTET:** finale vollständige #489-CI,
  reale Android-Geräte, TalkBack, produktive KI.
  **BLOCKIERT:** fehlendes lokales Dart-/Flutter-SDK, GitHub CI verfügbar.
  **Migration:** keine, SQLite 3 und äußeres JSON 1 bleiben kompatibel.
- **Regressionen:** sieben Gruppen mit positiver/negativer Auswahl,
  gleicher NPC-Anzeige für verschiedene IDs, Datums-/Positionsgleichstand,
  Doppelte/Unsichere/Verwaiste Notizen, Emoji-/Ausgabegrenzen,
  Revisionsschutz einschließlich gleicher Revision/anderer Rohdaten,
  Legacy-JSON und echtem SQLite-Neustart/Rekonstruktion.
- **Koordination:** Keine Fachdateiüberschneidung mit den anderen B-PRs.
  Gemeinsam genutzte README/Checkpoints bei Chat D additiv zusammenführen.
  Kein automatischer Merge, keine Änderungen fremder Branches.
- **Nächster Schritt:** Abschluss-CI auf finalem PR-HEAD prüfen,
  notwendige Fehler korrigieren, dann unabhängige Integration durch Chat D.

---

## 02.11.2026 – Chat-D-Integrationsvorbereitung

Chat B – bestätigte NPC-Beziehungsauswahl aus PR #489 vollständig übernommen. Die Quell-CI #41404718886 war auf dem finalen Source-HEAD erfolgreich; die gemeinsame Chat-D-Integrations-CI ist noch offen.

---

## 02.11.2026 – Chat-D-Koordination: Chat-B-Quellnachträge aus #486 und #491

Beide vollständigen Quellnachträge sind originalgetreu enthalten. Die neue Gesamt-CI auf dem gemeinsamen Integrations-HEAD steht noch aus, kein vorzeitiger Merge und keine Branchlöschung.

---

### Originaleinfügungen aus PR #486


## Chat B – bestätigte NPC-Kurzfassung mit Länge-/Quellenschutz (02.11.2026)

- **Basis-main:** `885580202caeafc9787538b6dc1c833b3190a529`.
  **Branch:** `feat/chat-b/bounded-confirmed-npc-excerpt-v2-20261102`;
  **Draft-PR:** [#486](https://github.com/ManuEtt/Dnd/pull/486).
  **Fachübernahme-Commit:** `af99b5a1c082b7280a17af05537d9cb57248c8f3`;
  **Regressionen-Commit:** `506f3a716b04896dff8c4fefda0b1445b0d7cb84`.
  Der eigene Vorgänger-PR #484 auf älterer Main-Basis ist geschlossen,
  ohne Merge oder Branchlöschung.
- **Ausgangsproblem:** `NpcContinuityReader.confirmedContext` kann
  extrem lange Legacy-Namen/Beziehungen/Notizen ausgeben. Dies ist
  unpassend für einen kurzen sicheren bestätigten NPC-Rückblick.
- **Implementiert:** separate neue schreibgeschützte
  `ConfirmedNpcContinuityExcerpt.read`, gespeicherte sichere ASCII-ID
  immer im Text, höchstens drei neueste bestätigte Notizen, pro Feld
  definierte Grenzen und Gesamtlimit 1.800 UTF-16-Einheiten. Kürzung
  erhält Emoji-Surrogatpaare; Unicode-Format- und Steuerzeichen bleiben
  nicht als Zeilen- oder Identitätstäuschung in der Darstellung.
  Keine Veränderung des gespeicherten Quellzustands.
- **Geänderte Dateien:** `app/lib/story/confirmed_npc_continuity_excerpt.dart`,
  `app/test/confirmed_npc_continuity_excerpt_test.dart`, README,
  zentraler Checkpoint und dieser Checkpoint. Keine gemeinsam genutzten
  Domain-/SQLite-/Controller-Dateien berührt.
- **Tests:** sechs positive und negative Regressionen: aktuelle
  NPC-Identität/Nachrichtentrennung, lange Emoji-/Legacy-Daten,
  Mehrzeilen-/Bidi-Spoofing, ungültige/mehrdeutige IDs und Notizgrenzen,
  alte JSON ohne bestätigte Notizen, echte SQLite-Neuöffnung und Replay.
  **Getestet:** Live-Main, alle PR-Fachpfade, Modulgrenzen/Architektur,
  offizieller Dart-Formatter. **Noch nicht getestet:** vollständige
  CI auf dem letzten Dokumentations-Commit, Android-Echthardware und KI.
  **Blockiert:** kein lokales Flutter-/Dart-SDK, CI verfügbar.
  **Migrationen:** keine, SQLite 3 / äußeres JSON 1.
- **Koordination:** PR #477 bearbeitet `npc_continuity_reader.dart`;
  dieser PR importiert den Reader ausschließlich. Andere B-PRs
  #452/#456/#459/#464/#470 überschreiben keine neue Fachdatei.
  Gemeinsame README-/Checkpoint-Einträge später durch Chat D additiv
  zusammenführen, kein Auto-Merge.
- **Nächster Schritt:** finale GitHub-CI abnehmen, Fehler bei Bedarf
  im eigenen PR beheben, danach Chat-D-Review für Integration.


---

### Originaleinfügungen aus PR #491


---

## 02.11.2026 – Chat B: unsichtbare Joiner in KI-Storyantworten ablehnen (PR #491)

- **Ausgangs-main:** `c33448780dfe8b453f7f1db9d28c1396822901a7`.
- **Branch:** `feat/chat-b/ai-provider-zero-width-guard-20261102`.
- **Fachcommit:** `bfcedd60ea018d0c5964afaf571cf9554736b365`; **Testcommit:** `4295681ff0fb9b0660140640c23c50d0412c02dd`.
- **Pull Request:** [#491](https://github.com/ManuEtt/Dnd/pull/491) (Draft).
- **Ausgangsproblem:** Der KI-Textvalidator in `app/lib/story/ai_story.dart` wies bereits U+200B und Richtungsmarken ab, nicht aber U+200C (Zero-Width Non-Joiner) oder U+200D (Zero-Width Joiner). Eingehende unbestätigte Narration, NPC-/Ortsnamen und Story-/Beziehungsnotizen konnten optisch identische, technisch unterschiedliche Texte enthalten.
- **IMPLEMENTIERT:** Die bestehende Sperre umfasst nun U+200B–U+200F. Es werden nur **neue unbestätigte Anbieterantworten** bei `AiStoryPlan.fromJson`/`AiStoryStep.fromJson` abgelehnt; gespeicherte historische Daten, Hero, Kampf, Quests und bestätigte Erinnerungen werden nicht umgeschrieben.
- **TESTS ERGÄNZT:** `app/test/ai_story_zero_width_validation_test.dart` mit sicherem mehrsprachigem Positivfall (Tab/Zeilenumbruch, JSON-Roundtrip, unverändertes Heldenprofil) und je drei negativen Parameter-Testgruppen für beide Joiner über sämtliche `_text`-Felder von Plan und Step. Fehler müssen `FormatException` auslösen, der bestätigte Kampagnenzustand bleibt identisch.
- **GETESTET:** Repository-Zustand, zuletzt erfolgreiche Main-CI und geänderte Dateipfade aller zu Beginn 30 offenen PRs geprüft; keine Fachdateikollision. GitHub-Branch, Fach-/Testcommits und PR wurden nachgewiesen.
- **NICHT GETESTET:** Dart-Format, `flutter analyze`, `flutter test`, Python-/Backend-Gesamtgates, Android-Build und native Tests dieses **finalen PR-HEAD** bis zur tatsächlichen CI-Abnahme. Kein lokaler Flutter-/Dart-SDK oder GitHub-Checkout. Reales Gerät, produktive KI und alte Android-Versionen ebenfalls nicht geprüft.
- **BLOCKIERT:** Vollständige grüne CI des finalen Dokumentationscommits; gemeinsame README- und zentrale Checkpoint-Nachträge bei späterer Integration additiv durch Chat D vereinen.
- **MIGRATION:** keine; SQLite 3, äußeres JSON 1, API, Versionsnummern, bestätigte Spielstände und Rule-Engine unverändert.
- **NÄCHSTER SCHRITT:** CI inklusive Flutter-Format und gezielten Providerparser-Regressionen auf finalem PR-HEAD kontrollieren und eventuelle Fehler auf demselben Branch beheben. Danach ein separates Paket für bestätigte, id-/revisionsgebundene Handlungsstrang-Auswahl erwägen, ohne PR #459 oder #489 zu duplizieren.

---

## Chat B – verdeckte NPC-Chronik bei Wiederaufnahme absichern (02.11.2026)

- **Ausgangs-main:** `55d33945872e251ec53b6860addcb05152a80c3a`, danach konfliktfrei mit `84437e4e92d735e179bb2585427b46a10451951d` (neuer Main-Stand nach #497) vereint.
- **Branch:** `feat/chat-b/npc-hidden-history-staleness-20261102`; **PR:** [#501](https://github.com/ManuEtt/Dnd/pull/501) (Draft); Code-/Testcommit `1f05dceea033c32094dad9b748898c203299b60c`.
- **Ausgangsproblem:** Die schreibgeschützte Wiederaufnahme verglich bei `maxNotes` nur die sichtbaren neuesten Notizen. Ältere, ausgeblendete Notizen konnten unter derselben Revision geändert oder ergänzt werden, ohne den NPC-Kontext zu invalidieren.
- **IMPLEMENTIERT:** `NpcIdentityMemory.read` hält einen privaten JSON-Quellabdruck aus dem ausgewählten NPC und sämtlichen für seine gespeicherte ID relevanten Notizen fest; `requireCurrent` gleicht ihn vor Benutzung erneut ab. Das öffentliche `toContextMap` und der Regeldatenstand bleiben gleich. Andere NPC-Chroniken bleiben unabhängig.
- **Geänderte Fachdateien:** `app/lib/story/npc_identity_memory.dart`, `app/test/npc_identity_memory_test.dart`. Zwei neue deterministische positive/negative Regressionsfälle prüfen verdeckte Änderungs-/Anfügekonflikte, JSON-Roundtrip, fremde NPC-Notizen und unveränderte Heldenwerte.
- **GETESTET:** GitHub-Dateipfade/offene PRs und Main-Diff wurden auf NPC-Fachkollision geprüft; keine Kollision beobachtet.
- **NICHT GETESTET:** neue Flutter-Fälle, gesamte CI, Android-APK, reales Gerät und produktive KI; lokal fehlen Flutter/Dart und DNS für GitHub-Checkout. Aktuelle PR-CI ist separat auf dem finalen HEAD abzunehmen.
- **BLOCKIERT:** lokale Laufzeit fehlt, keine fachliche Fremd-PR-Kollision. Gemeinsame README-/Checkpoint-Ergänzungen beim Merge durch Chat D additiv bewahren.
- **NOCH NICHT IMPLEMENTIERT:** automatisch ausgeführte NPC-Gedächtnisaktionen; der neue Abdruck ist absichtlich weder Persistenzfeld noch Provider-Autorität.
- **Migration:** keine. Kampagnen-JSON 1, SQLite 3, Regelzustand und App-Version 0.8.49+99 unverändert.
- **Nächster unabhängiger Schritt:** Mehrdeutige Notiz-IDs in der rein lesenden NPC-Identitätsabfrage fail-closed prüfen, mit positiven/negativen Alt-JSON- und Neustartfällen und erfolgreicher vollständiger CI; erst nach dieser PR-Integration beginnen.

---

---

## 02.11.2026 – Gespeicherte Ortsdaten sicher wiederaufnehmen (PR #505)

- **Ausgangs-main:** 516bc14e06cb02e7035a6adfb8e2d21e54253184.
- **Eigener Branch:** feat/chat-b/confirmed-place-resume-20261102.
- **Pull Request:** https://github.com/ManuEtt/Dnd/pull/505 (Draft).
- **Problem:** Ortsauszüge dürfen gleichnamige/gefälschte IDs nicht vermischen, verdeckte Unicode-Zeichen nicht als Anweisungen ausgeben oder einen Besuch behaupten. Ein älterer Ortsauszug darf nach Änderung des gespeicherten Ortsstands trotz identischer Revision nicht weiterverwendet werden.
- **Implementiert:** app/lib/story/confirmed_place_resume_selection.dart erstellt eine nur lesende Ortsauswahl mit unveränderlichen Einträgen, bis zu vier ID-gekennzeichneten Orten, maximal 1.800 UTF-16-Codeunits, Unicode-bereinigten Feldern und requireCurrent mit Kampagnen-/Sitzungs-/Revisions- und vollständiger Quellstandprüfung. Doppelte/unsichere IDs und leere Namen werden nicht verwendet. Keine erfundenen Besuchsbelege.
- **Tests angelegt:** app/test/confirmed_place_resume_selection_test.dart: sechs Fälle zu Auswahl, ID-Mehrdeutigkeit, Unicode/Emoji, Längen und Grenzen, versteckten gleichen Revisionsänderungen, altem JSON und SQLite-Neustart.
- **Code-/Testcommits:** 61a00036b3b2fc3d76a343176e778fc827469526, 91de191d96744c8140567b2af3c4ae19872e0d89.
- **GETESTET:** Repository-Hauptbranch, offene Pull Requests und ihre geänderten Fachpfade geprüft. Keine Überschneidung an Code-/Testdateien mit den anderen offenen PRs.
- **NICHT GETESTET:** Dart-Format, Flutter-Analyse, Flutter-Tests, vollständige GitHub-CI und Android-Gerät auf finalem PR-HEAD noch nicht abgeschlossen beziehungsweise nicht nachgewiesen. Lokales Flutter-/Dart-SDK fehlt.
- **BLOCKIERT:** Lokale Flutter-Ausführung; CI-Auswertung ist gesondert erforderlich.
- **Migrationen:** keine. SQLite/JSON-Schema, Spielstände, Regeln, Provider und App-Version unverändert; story_api.dart bewusst unangetastet, da PR #459 dort arbeitet.
- **Nächster Schritt:** Finale CI des Draft-PR prüfen und Fehler ggf. im selben Branch korrigieren. Danach eine API-/UI-Anbindung der Ortsübersicht erst konfliktfrei mit PR #459 abstimmen.

---

---

## 02.11.2026 – ältere Unsichtbarzeichen im KI-Story-Transport abweisen

- **Ausgangs-main:** `a2f22eaceb344aaced12d0ad548b813aa44d544f`.
- **Branch:** `fix/chat-b/story-provider-invisible-unicode-20261102`.
- **Pull Request:** [#513](https://github.com/ManuEtt/Dnd/pull/513) (Draft).
- **Problem:** Weiches Trennzeichen U+00AD, Combining Grapheme Joiner U+034F, U+180E und veraltete bidi-Steuerzeichen U+206A–U+206F bestanden bislang Flutter- und Backend-Story-Validierung. Sie können in Bestätigungs-/Erzähltexten unsichtbare Bedeutungsunterschiede vortäuschen.
- **Implementiert:** `app/lib/story/ai_story.dart` und `backend/src/story.ts` synchron auf exakt zusätzliche Unicode-Sperren erweitert, ohne legitime Mehrzeilen-Texte und Emoji-Varianten zu verbieten.
- **Tests angelegt:** `app/test/ai_story_invisible_unicode_test.dart` und `backend/test/story-legacy-format-guard.test.ts`, jeweils positiven Unicode-/Emoji-Proben und Negativfällen für Geschichten, Threads, NPCs, Orte, Spielzüge und Abenteuerangebote.
- **Geänderte Fachdateien:** die genannten vier Code-/Testpfade. Die offenen PRs zu NPC-Fortsetzung/Ortsrückblick, Zaubern, Android-UI und Integrationen bearbeiten nach geprüften PR-Dateipfaden keine dieser vier Fachdateien.
- **Kompatibilität:** SQLite/JSON und bestehende Spielstände unverändert. Kein Player-State-Commit, keine Änderung der Regeln, der Story-Wire-Struktur, Version oder Kostenfreigabe.
- **GETESTET:** Quellstand und betroffene PR-Fachdateien geprüft. GitHub-Gesamt-CI des vorangegangenen Orts-PR #505 vollständig grün, nicht dieses neue Paket.
- **NICHT GETESTET:** Neue Dart-/Flutter-/Backend-/Android-CI auf finalem Commit und echte Android-Geräteprüfung stehen noch aus.
- **Nächster Schritt:** neue PR-CI auf finalem Head abnehmen; bei Fehlern im eigenen Branch korrigieren; erst danach Integrationsreview durch Chat D.

---

## Chat B – Zero-Width-NPC-Identitäten sicher normalisieren (01.11.2026)

- **Ausgangs-main:** `5a88834c98f5aca40395088c20c7e1dc5b587868`.
  **Branch:** `fix/chat-b/npc-zero-width-name-ambiguity-20261101`.
  **Draft-PR:** [#464](https://github.com/ManuEtt/Dnd/pull/464).
  **Code-Commit:** `72f1de592cf4fd26d87437bdbbb9b8385f558dc7`.
  **Test-Commit:** `b326b947b5b1e85b418fb722a73a1da1c5e919b4`.
- **Ausgangsproblem:** `Mira` und `Mi\u200bra` wurden in der
  erzählerseitigen NPC-Kontextauswahl als verschiedene Namen gezählt,
  obwohl sie sichtbar identisch sind. Das erlaubte scheinbar eindeutig
  zugeordnete bestätigte Notizen bei freier Spielerprosa.
- **IMPLEMENTIERT:** `NpcNarratorMemory` faltet unsichtbare
  Unicode-Zeichen (U+200B/U+200C/U+200D/U+2060/U+FEFF) ebenso wie
  bisherige Bidi-Steuerzeichen vor der Eindeutigkeitsprüfung; die
  ausgehende, schreibgeschützte Darstellung entfernt diese Zeichen aus
  Namen und bereinigt Notizen als eine Zeile. Keine Regeln/Provider-
  Berechtigungen/gespeicherten NPC-Daten verändert.
- **Neue Regressionen:** fünf optisch identische Dubletten,
  positive gültige alte Einzelidentität, Legacy-JSON ohne Notizen,
  echte SQLite-Neuöffnung/Rekonstruktion mit Ambiguität, Tarek als
  eindeutige Kontrollidentität und unverändertem Helden-/Revisionszustand.
- **Dateien:** `app/lib/story/npc_narrator_memory.dart`,
  `app/test/npc_zero_width_identity_memory_test.dart`, README,
  `docs/CODEX_CHECKPOINT.md`, dieser Checkpoint.
- **GETESTET:** aktuellen GitHub-HEAD, fremde PRs/Dateien, bestehende
  Architektur und Tests geprüft. **NICHT GETESTET:** finale CI-Checks
  auf Dokumentationscommit, reales Gerät, externer KI-Dienst.
  **BLOCKIERT:** kein lokales Dart-/Flutter-SDK. **MIGRATION:** keine;
  SQLite 3 / äußeres JSON 1, Version, Quest-/Heldendaten unverändert.
- **Koordination:** #452 `story_memory_engine.dart`, #456
  `story_campaign_engine.dart`, #459 `campaign_resume_context.dart`/
  `story_api.dart` – keine Fachdateiüberschneidung. README und
  Checkpoints nur additiv mit Chat D integrieren; kein Auto-Merge.
- **Nächster Schritt:** finale Format-/Analyse-/Flutter-/Android-CI
  von #464 abnehmen, bei Rot im eigenen Branch korrigieren und
  nach vollständiger Abnahme an Chat D übergeben.

---

## Chat B – strukturierte NPC-Identity gegen Zero-Width-Täuschung (02.11.2026)

- **Basis-main:** `5a88834c98f5aca40395088c20c7e1dc5b587868`;
  **Branch:** `fix/chat-b/structured-npc-zero-width-20261102`;
  **Draft-PR:** [#470](https://github.com/ManuEtt/Dnd/pull/470).
  **Fachcommit:** `09b7be36bd3049a201d4106c1cf74642441cad88`;
  **Regressionen:** `2a360c627464c92e440cfaa60c01df013e290108`;
  **offiziell formatiert:** `6829f86cb5b69003ddcf1664d44aca3fabc04462`.
- **Ausgangsproblem:** Sichtbar gleiche NPC-Namen konnten mit Zero-Width-
  Zeichen bei unstrukturierter Erwähnung als unabhängig gelten. Zusätzlich
  ließ der strukturierte NPC-Payload unerkennbare Unicode-Marker in Namen,
  Beziehungen und Notizen zu, die fälschliche Identität anzeigen könnten.
- **IMPLEMENTIERT:** Vergleichsnamen ohne Zero-Width-Zeichen kanonisieren;
  auf den geplanten ID-Wire nur explizit sichere originale Werte lassen,
  keine stille Änderung gespeicherter bestätigter Notizen. Bewusst
  gewählte eindeutige ID bleibt möglich, sofern Kontext valide.
  Keine HP-/XP-/Quest-/Item-/Regelmutationen.
- **Geänderte Dateien:** `app/lib/story/npc_identity_story_payload.dart`,
  `app/test/npc_identity_story_zero_width_payload_test.dart`, README,
  zentraler und Chat-B-Checkpoint. Diagnoseworkflow nur kurzzeitig zum
  Formatieren erstellt und anschließend entfernt.
- **Tests:** sechs unabhängige Gruppen mit positiven und negativen
  Identitäts-, Unicode-, Legacy-/Revision- und SQLite-Roundtrips.
  **GETESTET:** Main-/PR-Inventur und offizieller Dart-Formatter (3.9.2);
  #464 mit eigener kompletter erfolgreicher GitHub-CI (fremder Commit).
  **NICHT GETESTET:** vollständige #470-Final-CI noch offen; Gerät/TalkBack/
  Produktiv-KI. **BLOCKIERT:** kein lokales Flutter-/Dart-SDK.
- **Migration:** keine; SQLite 3, äußeres JSON 1, aktuelle Version
  und gespeicherte Regeln unverändert.
- **Koordination:** keine Fachdateiüberschneidung mit B-PRs #452/#456/
  #459/#464; übrige A/C/D-PRs betreffen andere Module. Gemeinsame
  README-/Checkpoint-Änderungen ausschließlich additiv durch Chat D
  konsolidieren. Kein Auto-Merge.
- **Nächster Schritt:** #470-Full-CI bis Abschluss abnehmen, Fehler
  auf demselben Branch beheben und danach Chat-D-Review ermöglichen.

---

## Chat B – NPC-Kontinuität bei Zero-Width-Identitäten (02.11.2026)

- **Ausgangs-main:** `2e920f222ab8fd501d9d90bff580d0f8ccc42ff1`.
  **Branch:** `fix/chat-b/npc-continuity-zero-width-20261102`.
  **Pull Request:** [#477](https://github.com/ManuEtt/Dnd/pull/477), Draft.
  **Fachcommit:** `f9fde6f4c19d45b291c4cc33e797f7893d07d01f`.
  **Testcommit:** `337dab38771379345cceefe1c49e1a39acba5ea4`.
- **Ausgangsproblem:** `NpcContinuityReader` behandelte U+200B–U+200D,
  U+2060 und U+FEFF nicht wie bestehende Bidi-Marken. Dadurch konnten
  zwei visuell gleiche NPCs ohne disambiguierende ID im bestätigten
  Rückblick erscheinen. Beziehungen/Notizen konnten solche Markierungen
  in der Anzeige enthalten.
- **IMPLEMENTIERT:** Unsichtbare Namensformatierung vor dem Vergleich
  und vor der Darstellung entfernen, sichere NPC-ID bei sichtbaren
  Namensdubletten verlangen; `_singleLine` bereinigt die Textausgabe,
  ohne gespeicherte Fakten/Notizen umzuschreiben.
- **Geänderte Dateien:** `app/lib/story/npc_continuity_reader.dart`,
  `app/test/npc_continuity_zero_width_test.dart`, README,
  `docs/CODEX_CHECKPOINT.md`, dieser persönliche Checkpoint.
- **Neue Tests:** sechs Unicode-Dubletten jeweils mit getrennten
  bestätigten Notizen, saubere eindeutige NPC-Namen, unsichere/
  doppelte Identität und Grenzwerte, Legacy-JSON ohne Notizen, echter
  SQLite-Neustart und Wiederherstellung, unveränderter Held/Revision.
- **GETESTET:** aktuelles main, offene PRs/Dateipfade, Architektur und
  vorhandene Tests geprüft. **NICHT GETESTET:** finale vollständige
  Flutter-/Backend-/Python-/Android-CI, echtes Gerät/Provider.
  **BLOCKIERT:** Dart/Flutter nicht lokal installiert; CI verfügbar.
  **Migrationen:** keine, SQLite 3/äußeres JSON 1, keine neue
  Provider-Schnittstelle, kein Regel- oder Questzustandswechsel.
- **Koordination:** Fachdateiüberschneidungen ausgeschlossen; #464
  betrifft `npc_narrator_memory.dart`, #470
  `npc_identity_story_payload.dart`. README/Checkpoints nur
  durch Chat D kontrolliert kombinieren. Keine fremden Branches ändern.
- **NÄCHSTER SCHRITT:** offiziellen Formatter und vollständige CI
  auf finalem Commit abnehmen, Fehler im Branch beheben, PR zur
  unabhängigen Integration übergeben.


---


---

## 03.11.2026 – Chat B: sichere bestätigte NPC-Wiederaufnahme (PR #519)

- **Ausgangs-Main-SHA:** `a786ad61c508da1a9ec1a24f85100a4a994182c8`.
- **Eigener Branch:** `feat/chat-b/npc-resume-invisible-marks-20261103`.
- **Pull Request:** [#519](https://github.com/ManuEtt/Dnd/pull/519), Draft. Der endgültige PR-HEAD muss nach Dokumentationscommits separat kontrolliert werden.
- **Code-/Test-Commits:** `651d9f0f490a1beafe417a83371dd92b0b0f792c`, `1e6e8ba6bff323789821101e9fe7d5d08c0c1634`, `0ea9af27610aa92c244065448840fe32de37dd40` (Testlabel).
- **Ausgangsproblem:** Die bestätigte, read-only NPC-Auswahl ließ U+00AD/U+034F/U+180E/U+206A–U+206F in alten Namen, Beziehungen und Notiztexten stehen; solche Zeichen sind optisch schwer erkennbar und wurden im Spieler-Rückblick nicht normalisiert.
- **IMPLEMENTIERT:** `ConfirmedNpcResumeSelector._formatMarks` filtert diese neun weiteren unsichtbaren Formatzeichen. Bei NPC-Namen werden sie entfernt, bei Beziehung/Notiz zu einem einzelnen sichtbaren Wortabstand normalisiert. Auswahl, bestätigte NPC-ID, Revisions-Snapshot und vollständiger Rohdatenstempel bleiben erhalten.
- **Geänderte Dateien:** `app/lib/story/confirmed_npc_resume_selection.dart`; neue Datei `app/test/confirmed_npc_resume_invisible_marks_test.dart`; additive Einträge in `README.md`, `docs/CODEX_CHECKPOINT.md` und diesem Checkpoint.
- **Akzeptanz/Regression:** Drei deterministische Tests prüfen alle neun verborgenen Zeichen in allen drei Anzeigefeldern, korrekte NPC-ID und Ausschluss unbestätigter Szenen, legitimes Deutsch/Akzente/Emoji-Variation-Selector, Ausgabelimit, JSON-Roundtrip ohne Umschreiben sowie Ablehnung derselben Revision mit veränderter Originalquelle.
- **GETESTET:** GitHub-Dateistruktur und offener PR-Dateipfadabgleich vor Branchstart; neue Testfälle und Code auf Branch gesichert. Keine lokale Flutter-Ausführung behauptet.
- **NICHT GETESTET:** Vollständige Flutter-/Dart-/Python-/Backend-/Android-Gates auf **finalem** PR-HEAD, APK, Realgerät und produktiver KI-Anbieter.
- **BLOCKIERT:** Flutter/Dart sind in der lokalen Laufzeit nicht installiert; vollständige Abnahme über GitHub Actions erforderlich. Ältere andere Chat-B- und Chat-D-PRs dürfen nicht ungeprüft zusammengemergt werden.
- **Migrationen:** Keine. Persistierte JSON- und SQLite-Rohdaten, Schema, Spielregeln, Backendprotokoll, Controller und Version bleiben unverändert.
- **Konflikte:** Geprüfte offene PRs ändern keine der beiden neuen Fach-/Testdateipfade. README und zentraler Checkpoint überschneiden sich dokumentarisch und müssen bei Integration durch Chat D additiv konsolidiert werden. PR #516 arbeitet getrennt in `npc_identity_memory.dart`.
- **Nächster konkreter Schritt:** GitHub-CI des finalen PR-HEAD abnehmen; falls rot, denselben Branch reparieren. Anschließend die unabhängige Orts-/NPC-Wiederaufnahme gemeinsam mit Chat D erst nach bestehenden Drafts integrieren.


---



## Chat B – natürliche Kampagnenrückblicke (31.10.2026, PR #452)

- **Ausgangsproblem:** Alltagssprache wie „Was haben wir bisher erlebt?“ und
  „Was ist beim letzten Mal passiert?“ führte nicht in den bestätigten Rückblick;
  die allgemeine Suche konnte ihre Füllverben irrtümlich als Themenfilter werten.
- **Basis-main:** `5a88834c98f5aca40395088c20c7e1dc5b587868`.
  **Branch:** `feat/chat-b/natural-recap-requests-20261031`.
  **Pull Request:** [#452](https://github.com/ManuEtt/Dnd/pull/452), Draft.
  **Fachcode-Commit:** `4ef4aa4f38562f8174595df7749f4c97f0cb8753`.
  **Test-Commit:** `5fac062ab8c30cfb1c036c20ce327780175cfb4c`.
  **Dart-Formatkorrektur:** `ac84ee15e8d3b2180bedd5fed44de6768d79f7db`.
  **Analyzer-Korrektur:** `95c59dfeba0354759abe0001f428e01c3907fb12`
  entfernt einen doppelten bereits vorhandenen Stopword-Eintrag `fass` aus
  der Ergänzung. In Push-CI `41244551245` bestanden Dart-Format und die
  vorausgehenden Python-/Backend-Gates; `flutter analyze` meldete exakt den
  doppelten Set-Eintrag und stoppte vor Flutter-Tests/APK. Der neue Commit
  benötigt erneut vollständige CI.
  Die vorläufige Push-CI `41244405913` war ausschließlich bei
  `dart format` für den neuen Test rot; vorangehende Python- und Backend-Prüfungen
  waren erfolgreich. Finale Flutter-/Android-Abnahme steht noch aus.
- **Implementiert:** Eng verankerte Rückblickfragen und umgangssprachliche
  Zusammenfassungsbitten; leere allgemeine Themenanfrage liefert ausschließlich
  bereits bestätigte Fakten. Keine stillen Freigaben freier NPC-/Spieleraktionen.
- **Geänderte Dateien:** `app/lib/story/story_memory_engine.dart`,
  `app/test/story_recall_intent_test.dart`, `README.md`,
  `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_B_CHECKPOINT.md`.
- **Akzeptanz/Regression:** positive und negative deutsche Frageformen;
  bestätigter `memory.recalled`-Turn mit echter `GameEngine.act`-Verarbeitung;
  NPC-Zitat bleibt normaler Spielzug; unveränderte Helden-/Regelzustände und
  unveränderte ursprüngliche Kampagne.
- **GETESTET:** GitHub-main-SHA, offene PRs und Dateiüberschneidungen geprüft.
  **NICHT GETESTET:** Flutter-/Dart-Test, Format, Analyse, kompletter CI-Workflow
  einschließlich APK auf finalem Branch-HEAD und reales Android-Gerät; lokale
  SDKs fehlen. Vorläufer-Main-CI ist kein Testnachweis dieses PR.
- **BLOCKIERT:** direkte lokale Flutter-/Dart-Ausführung; CI-Status nach
  Veröffentlichung des Dokumentationscommits gesondert auswerten.
- **Migration:** keine; SQLite/JSON, APIs, Rule-/Questzustand,
  Modell-/Controller-Dateien, Version und externe Anbieter unverändert.
- **Koordination:** #446 betrifft nur späte KI-Antworten und einen eigenen Test;
  #447–#451 andere Fachcodepfade. README/zentralen Checkpoint bei späterer
  Integration additiv durch Chat D konsolidieren, nicht blind überschreiben.
- **Nächster Schritt:** finale grüne PR-CI für #452 belegen oder rote Tests auf
  demselben Branch beheben; bis dahin Draft belassen.


---

## Chat B – offene Handlungsnotizen bei gespeicherter Wiederaufnahme (31.10.2026)

- **Main-Basis:** `5a88834c98f5aca40395088c20c7e1dc5b587868`.
  **Branch:** `feat/chat-b/confirmed-resume-leads-20261031`.
  **PR:** [#456](https://github.com/ManuEtt/Dnd/pull/456), Draft.
  **Code-Commit:** `461e086e784bbafde6d19b3e285d71b65c035c6c`.
  **Tests:** `15e5dd537a14042cc6d142692d1da922f7dcf471`,
  korrigierter Teststand `acc80d50953251742978061eae670e4e55efe6ca`.
- **Ausgangsproblem:** vorhandene Rückblicke führen Handlungsstränge nur
  mit Titel und Status. Länger pausierende Spieler müssen selbst nachlesen,
  welche ausdrücklich gespeicherten offenen Fragen als Nächstes relevant sind.
- **Akzeptanz/Implementierung:** Bis zu drei letzte offene gespeicherte
  Handlungsnotizen ergänzen den bereits vorhandenen bestätigten Sitzungsinhalt.
  Keine abgeschlossenen/aufgegebenen/leeren Einträge, keine Erzählung als
  bestätigte Fakten oder Regeltransaktion. Bestandsfakten priorisiert, sichere
  Ein-Zeilen-/Unicode-Darstellung, 2.400-Zeichen- und 160-Zeichen-Notiz-Grenzen.
- **Neue Tests:** `app/test/story_resume_recap_test.dart` für positive
  Auswahl und Reihenfolge, negative Endzustände/unbestätigte Szene,
  Unicode-Trunkierung, volle Recaps, echten SQLite-Neustart und Revisions-/
  Journal-/Heldenkontinuität.
- **Geändert:** `app/lib/story/story_campaign_engine.dart`, neuer Test,
  `README.md`, `docs/CODEX_CHECKPOINT.md`, diese Datei.
- **GETESTET:** Main-HEAD, offene PR-Dateipfade und vollständigen GitHub-
  Schreibzugriff geprüft. **NICHT GETESTET:** neue Dart/Flutter/Android-CI
  auf finalem Dokumentationscommit bis zum tatsächlichen Workflowabschluss.
  Kein lokales Dart/Flutter-SDK; Gerät/Produktiv-KI nicht geprüft.
- **BLOCKIERT:** lokale Tests mangels SDK; CI-Prüfung auf GitHub.
  **Migration:** keine, SQLite 3 / äußeres JSON 1, Hero-/Quest-/Kampf-
  mechanik und bestehende Rückblicke unverändert.
- **Koordination:** #452 berührt nur das andere
  `story_memory_engine.dart`; #446 ist ein separater KI-Verzögerungstest.
  #454 führt mehrere andere PRs zusammen, ohne StoryCampaignEngine zu ändern.
  Geteilte README-/zentrale Checkpoint-Ergänzungen additiv durch Chat D
  integrieren; keine fremden Branches ändern.
- **Nächster Schritt:** finale CI/Android-Prüfung von #456, etwaige roten
  Prüfungen im eigenen Branch beheben und nach vollständigem Grün an Chat D
  zur Integrationskoordination übergeben.


---

## Chat B – getrennter Kampagnen-Wiederaufnahmekontext (01.11.2026, CET)

- **main-Basis:** `5a88834c98f5aca40395088c20c7e1dc5b587868`.
  **Branch:** `feat/chat-b/read-only-resume-context-20261101`.
  **Draft-PR:** [#459](https://github.com/ManuEtt/Dnd/pull/459).
  **Code-Commit:** `6aa6a5814d81dbccf2cba7409370a2e76dfbbfb9`;
  **öffentlicher Story-Export:** `9ba20a46f75060e8a080efc0ebfccd508586ee8f`;
  **Test-Commit:** `f447223c40c48fbcf95fbadc8c36be0bc69e9ead`.
- **Problem:** Bei Wiederaufnahme nach einer Spielpause wäre die Behandlung
  einer frei erzählten letzten Szene als sicher bestätigter Regelzustand
  gefährlich; Rückblick und aktuelle Fakten/Handlungszustände sind zudem
  zeitlich unterschiedliche Quellen.
- **IMPLEMENTIERT:** `CampaignResumeReader` und unveränderliche
  `CampaignResumeSnapshot` mit vier klar ausgezeichneten Quellen.
  Bis zu drei offene Storynotizen und vier Fakten, optionale validierte
  Limits, Unicode-/Bidi-Schutz und UTF-16-sichere Kürzung. Kein
  `storyBible`-/Quest-/XP-/HP-/Kampf-/Inventar- oder Ereignisschreibzugriff.
- **Dateien:** neues `app/lib/story/campaign_resume_context.dart`,
  `app/lib/story/story_api.dart`, neuer
  `app/test/campaign_resume_context_test.dart`, README, zentraler und
  dieser persönliche Checkpoint. **Keine Datenmigration** und kein
  Versionsschritt (SQLite 3 / äußeres JSON 1).
- **Neue Regressionen:** vertrauensgetrennte Szene vs. gespeicherte Fakten;
  geschlossene/aufgegebene Stränge ausgeschlossen; älteres JSON ohne
  Gedächtnisfelder; Unicode, Begrenzung, Unveränderlichkeit und echter
  SQLite-Neustart-/Rekonstruktionsabgleich.
- **GETESTET:** aktueller GitHub-HEAD, offene PRs und Dateipfade;
  #456 hat grüne vollständige Push- und PR-CI.
  **NICHT GETESTET:** neuer #459-Code auf finalem CI-HEAD (noch offen),
  reales Gerät/Sprachausgabe/Produktiv-KI. Lokal kein Dart-/Flutter-SDK.
  **BLOCKIERT:** lokale Flutter-Tools fehlen.
- **Fremde PRs:** #452 berührt `story_memory_engine.dart`, #456 berührt
  `story_campaign_engine.dart`; keine Überschneidung mit diesem
  neuen Storymodul. Nur gemeinsame README-/Checkpoint-Texte erfordern
  spätere additive Konsolidierung durch Chat D. Kein Merge.
- **Nächster Schritt:** #459-CI auf finalem Dokumentationsstand abnehmen,
  etwaige Format-/Testfehler auf demselben Branch beheben, danach
  Review/Integration an Chat D übergeben.


---



---

## 03.11.2026 – verdeckte doppelte NPC-Notizen bei Fortsetzung ablehnen

- **Basis-main:** `a2f22eaceb344aaced12d0ad548b813aa44d544f`.
- **Branch:** `feat/chat-b/confirmed-npc-note-id-integrity-20261103`.
- **Pull Request:** [#516](https://github.com/ManuEtt/Dnd/pull/516) (Draft).
- **Problem:** `NpcIdentityMemory.read` übernahm für einen ausdrücklich ID-gewählten NPC unter Umständen alte Notizen mit wiederholter oder unsicherer Kennung. Ein harmlos wirkender Auszug mit `maxNotes: 1` konnte die Mehrdeutigkeit ausblenden.
- **Implementiert:** Alle gespeicherten Notizen des gewählten NPCs vor Kürzung auf gültige 1–64-Zeichen-IDs und Wiederholungen prüfen; unveränderte Revision kein Ersatz für diesen vollständigen Check. Keine pauschale Abweisung unbeteiligter NPC-Verläufe und kein Einfluss auf die Spielregelengine.
- **Fach-/Testdateien:** `app/lib/story/npc_identity_memory.dart`, `app/test/npc_identity_note_id_integrity_test.dart` (6 positive/negative Tests).
- **Geprüfte Parallelität:** Hauptbranch-HEAD, 21 offene PRs, deren relevante Fachpfade und bestehende Testfälle geprüft; keine Überschneidung auf den beiden Fachpfaden. Gemeinsame README-/Checkpoint-Nachträge bei späterer Integration additiv durch Chat D konsolidieren.
- **Tests auf neuem HEAD:** Erst durch GitHub-CI nach diesen Dokumentationscommits nachzuweisen; lokales Flutter/Dart nicht vorhanden. Vorherige erfolgreiche PR #513 (zwei vollständige CIs) betrifft ein anderes Paket.
- **Nicht getestet:** echter Android-Gerätebetrieb, TalkBack, vorherige App-Upgrade-Pfade, produktiver kostenpflichtiger KI-Provider.
- **Kompatibilität:** keine JSON-/SQLite-Migration, Schema/Version/Erzählprovider-Vertrag unverändert. Altbestände bleiben geladen und gespeichert; nur die unsichere Lesesicht scheitert geschlossen.
- **Nächster Schritt:** CI einschließlich FFI-Neustarttest prüfen, Fehler korrigieren, finalen HEAD und Abnahme in PR #516 dokumentieren.


---

## Chat B – begrenzte bestätigte NPC-Kontinuität (02.11.2026)

- **Ausgangs-main:** `2e920f222ab8fd501d9d90bff580d0f8ccc42ff1`.
  **Branch:** `feat/chat-b/bounded-confirmed-npc-excerpt-20261102`.
  **Draft-PR:** gegen main, Nummer in PR-Beschreibung.
  **Fachcommit:** `92c29ce9a111e765fb43754be196697be6681973`.
  **Testcommit:** `0165d137534d6a7ceb7e0fb97d1566b461d5a703`.
  **Dart-Testkorrektur:** `6345b6d5ec3cdea7bc9c93f9e1ec880c0433ee3c`.
- **Ausgangsproblem:** bestätigte NPC-Kontinuität aus Legacy-Spielständen
  kann sehr lange Namen/Beziehungen/Notizen enthalten. Die ungebundene
  `confirmedContext`-Ausgabe ist nicht für kurze Rückblicke geeignet.
- **IMPLEMENTIERT:** neue schreibgeschützte
  `ConfirmedNpcContinuityExcerpt.read` auf dem bestehenden
  `NpcContinuityReader`. Immer eindeutige, sichere NPC-ID,
  maximal drei bestätigte Notizen, maximal 1.800 UTF-16-Einheiten,
  rune-sicher, Unicode-/Bidi-Marken ohne Zeileninjektion dargestellt.
  Nicht bestätigte KI-Prosa und fremde NPC-Notizen ausgeschlossen,
  gespeicherte Regeln/Kampagnen unverändert.
- **Dateien:** `app/lib/story/confirmed_npc_continuity_excerpt.dart`,
  `app/test/confirmed_npc_continuity_excerpt_test.dart`, README
  und beide Checkpoints.
- **Tests:** sechs positive/negative Gruppen inklusive historischer
  langer Emoji-Texte, Notizordnung/-anzahl, unsicherer/mehrdeutiger IDs,
  JSON-Rückwärtskompatibilität, SQLite-Neustart und unveränderten
  Helden-/Revisionswerten.
  **GETESTET:** GitHub Main/PRs/Architektur/Module geprüft.
  **NICHT GETESTET:** finale CI, Android-Echthardware/produktive KI.
  **BLOCKIERT:** kein lokales Flutter-/Dart-SDK; Actions verfügbar.
  **Migration:** keine, SQLite 3/äußeres JSON 1 unverändert.
- **Koordination:** bestehender `npc_continuity_reader.dart` ist
  Eigentum des offenen PR #477, wird hier nicht bearbeitet.
  Auch #464 und #470 betreffen andere NPC-Fachmodule.
  README und Checkpoints bei Integration nur additiv durch Chat D.
- **Nächster Schritt:** Formatter/gesamte CI auf finalem Commit auswerten,
  Fehler im eigenen Branch beheben, danach Review durch Chat D.


---


---

## 03.11.2026 – Chat B: bestätigte NPC-Kurzchronik, Legacy-Formatmarken (#531)

- **Basis-Main:** `7be2135f5046c4139a7340cc2bfa876a7d311c93`, Version `0.8.49+99`.
- **Branch:** `feat/chat-b/npc-continuity-legacy-marks-20261103`.
- **PR:** [#531](https://github.com/ManuEtt/Dnd/pull/531) (Draft). Fach-/Testcommits `86caf50c4f1bc5a98c5c914ad796cfd58667937b`, `d6842a309ab1a0ee54d2de102064250de0f3bbaa`, `ae548ef951ef2bbc48a1d35cd6044f1dd772f3fb`; finaler Commit nach Dokumentation und neuer CI zu prüfen.
- **Ausgangsproblem:** Der bereits schreibgeschützte NPC-Kontinuitätsauszug filterte bekannte Bidi-Marken, aber nicht U+00AD, U+034F, U+180E und U+206A–U+206F. Legacy-Notizen konnten dadurch unsichtbare Unterschiede in bestätigtem Spielertext enthalten.
- **IMPLEMENTIERT:** Erweiterung von `ConfirmedNpcContinuityExcerpt._format` auf die neun Zeichen; NPC-Namen bleiben als lesbare Bezeichnung zusammen, Notizen/Beziehungen verwenden Wortabstände; alle Rohdaten und IDs bleiben unverändert.
- **Akzeptanz / Regression:** Drei neue Tests in `app/test/confirmed_npc_continuity_legacy_marks_test.dart`: neun Markierungszeichen als Negativfälle in vier Feldern, positiv lesbare deutsche/Akzent- und Emoji-Texte, klare NPC-ID und Ausschluss fremder/ungeprüfter Aussagen, JSON-Identität und SQLite-Neustart mit Heldenwerterhalt.
- **Geändert:** `app/lib/story/confirmed_npc_continuity_excerpt.dart`, neue Testdatei, README, `docs/CODEX_CHECKPOINT.md`, dieser persönliche Checkpoint.
- **GETESTET:** Aktuelle GitHub-/PR-Dateipfade und bereits vorhandene Story-Regressionsfälle geprüft; Code und Tests versioniert. Die beiden grünen CI-Läufe des Vorgängers [#519](https://github.com/ManuEtt/Dnd/pull/519) belegen **nicht** dieses neue Paket.
- **NICHT GETESTET:** Neues vollständiges CI auf finalem HEAD, echtes Android-Gerät, KI-Provider und Upgrade-Test.
- **BLOCKIERT:** Lokales Flutter/Dart nicht verfügbar. Der Gesamt-GitHub-CI-Status muss vor Freigabe ermittelt werden.
- **Migration:** Keine; persistente SQLite- und JSON-Strukturen, Regeln, Quest-/HP-/XP-Zustände, Provider und App-Version unverändert.
- **Konflikte:** Andere offene Chat-B-/D-PRs ändern teils andere Storymodule, jedoch nicht diese neue Fach-/Testdatei. README und zentraler Checkpoint sind gemeinsame Pfade: Additive Konsolidierung ausschließlich bei Chat-D-Integration. Kein Merge, Force-Push oder fremdes Branch-Löschen.
- **Nächster Schritt:** CI/Android auf dem finalen PR-HEAD verifizieren; fehlschlagende Schritte gezielt auf eigenem Branch reparieren und danach von Chat D konfliktfrei integrieren lassen.

---

## 05.11.2026 – Chat B: KI-Abenteuervorschläge gegen versteckte Steuerzeichen (#550)

- **Basis-main:** `d9fc2396dc44b9e03fc9a86d9dcc9c456c5a80a9`. **Branch:** `feat/chat-b/ai-offer-untrusted-format-20261105`. **Draft-PR:** [#550](https://github.com/ManuEtt/Dnd/pull/550).
- **Fachcommits:** `034796935dbd08083108fa09a5a59a137baca20d` (Validierung), `bdba116f07fcef44421df941bd1d3e2d7984a03a` (Regression), `e6b05ddc1cee096fb985273bba9a93a897a8508e` (Stil). Dokumentations-HEAD danach separat prüfen.
- **Problem:** `AdventureOffer.fromJson` ist ein Speicherparser, aber ein KI-Vorschlag braucht dieselbe unsichtbare-Zeichen-Policy wie andere generierte Erzählfelder. Bidi/Soft-Hyphen/Combining-Grapheme-Joiner konnten sonst in KI-Questtiteln stehen.
- **IMPLEMENTIERT:** Vier Textfelder von neuen optionalen KI-Angeboten zusätzlich mit `_text` prüfen. Gültige Angebote weitergeben, blockierte bei vorhandener Kampagnenofferte weiter ignorieren. Keine Speicher- oder Regeländerung.
- **Tests:** Vier neue deterministische Gruppen: positives Angebot, 20 negative Kombinationen über vier Felder und fünf Formatzeichen, Akzente/Emoji/Mehrzeiligkeit, ignorierte ungültige Provider-Offerte bei bereits vorhandenem gespeichertem Angebot. Spielstand/Revision/HP/Quests unverändert.
- **Dateien:** `app/lib/story/ai_story.dart`, `app/test/ai_story_adventure_offer_format_guard_test.dart`, README, zentraler und Chat-B-Checkpoint.
- **GETESTET:** Main-Stand und alle offenen PRs/Fachdateien sowie vorhandene Domänenvalidierung geprüft. **NICHT GETESTET:** finale Flutter-/Backend-/Android-CI und Realgerät/Produktiv-KI; kein lokales Dart/Flutter verfügbar.
- **BLOCKIERT:** vollständige CI-Abnahme auf finalem Commit und Chat-D-Integration. **Migration:** keine; bestehende gespeicherte Angebote bleiben gültig.
- **Koordination:** Keine Fachdatei-Überschneidung mit offenen Chat-B-PRs #545/#546; README/zentralen Checkpoint nur additiv integrieren.
- **Nächster Schritt:** Finalen CI-Status abwarten, bei roten Prüfungen denselben Branch korrigieren, nach Grün an Chat D übergeben.

---

## Chat B – 05.11.2026: Legacy-Formatzeichen in Ortsrückblicken (#555)

- **Basis-main:** `36ced64cd6b6b13888bee34f5dd33103edf04dcb`.
- **Eigener Branch:** `feat/chat-b/place-resume-legacy-format-marks-20261105`. **Draft-PR:** [#555](https://github.com/ManuEtt/Dnd/pull/555).
- **Commits:** `085a003aa529c4016b5e179827f279ab42564342` (Source-Filter), `7328f0722c4f1c5ef7fbcf053acd869a06f377fb` (drei Regressionstests), `185059e4d0a9d7ce82f6d0576df7f35c91e149da` (Dart-Interplations-/Assertion-Präzisierung). Finalen Dokuments-HEAD nachtragen.
- **Problem und Lösung:** Bei bestätigter Ortswiederaufnahme blieben sieben in älteren Daten vorkommende unsichtbare Formatzeichen U+00AD und U+206A–U+206F stehen. Erweiterung von `ConfirmedPlaceResumeSelector._formatMarks` auf diese sieben Codes; nur die schreibgeschützte Anzeige wird bereinigt. IDs bleiben eindeutig, gespeicherte Rohdaten unangetastet.
- **Dateien:** `app/lib/story/confirmed_place_resume_selection.dart`, `app/test/confirmed_place_resume_legacy_format_marks_test.dart`, README, zentraler und persönlicher Checkpoint.
- **Akzeptanz:** Positive/negative Zeichenfälle in beiden Feldern, eindeutige Orts-IDs trotz gleicher lesbarer Namen, Revalidation gegen unsichtbare Same-Revision-Änderungen, JSON-/SQLite-Roundtrip mit unveränderten Daten, TP, Revision und Ereignisrekonstruktion.
- **GETESTET:** aktuelle Main- und PR-Liste sowie tatsächlich betroffene Fachdateien konfliktfrei geprüft; alle Änderungen versioniert. Für #550 ist die vollständige unabhängige GitHub-CI #42000537289 erfolgreich. Diese frühere CI beweist **nicht** die neue Änderung #555.
- **NICHT GETESTET:** Finales #555-CI und tatsächlicher Android-Geräte-/Legacy-Upgrade-Test. Lokales Dart-/Flutter-SDK fehlt.
- **BLOCKIERT:** GitHub-CI-Abnahme, Integrationsreview durch Chat D.
- **Migration:** keine, keine Änderungen an Regeln, Quests, HP/XP, JSON/SQLite-Schema, Version oder Generierungsprovider.
- **Konfliktkontrolle:** Kein neuer Storyfachpfad in den parallel offenen PRs #545, #546, #550; gemeinsame Docs beim Merge nur additiv konsolidieren.
- **Genau nächster Schritt:** CI auf dem finalen Dokumentations-HEAD prüfen; etwaige Fehler beheben und Integration über Chat D abstimmen.

## 2026-11-05 – Quellenhistorien im zentralen Integrationsbranch

Folgende Fach-PRs von Arbeitsbereich B sind im Branch `integration/open-prs-20261105-reviewed` als unveränderte Git-Merge-Vorfahren eingebunden, einschließlich ihrer fachlichen Dateien und Regressionstests:

- [PR #545](https://github.com/ManuEtt/Dnd/pull/545)
- [PR #546](https://github.com/ManuEtt/Dnd/pull/546)
- [PR #560](https://github.com/ManuEtt/Dnd/pull/560)
- [PR #565](https://github.com/ManuEtt/Dnd/pull/565)
- [PR #569](https://github.com/ManuEtt/Dnd/pull/569)

Geteilte Historien und Dokumentationskonflikte werden im neutralen, append-only README-Nachtrag sowie in `docs/parallel/ALL_BRANCHES_MIGRATION_20261105.md` nachvollziehbar dokumentiert. Die gemeinsame PR-CI, der endgültige Main-Merge und archivierte Branchlöschungen bleiben bis zu konkretem Nachweis offen.



---

## 07.11.2026 – Epilog-NPC-Besuche nur nach expliziter Handlung (PR #628)

- **Basis-main:** `1816115990cc7420ecfb2d1ba7c6babb557f76da`. **Branch:** `fix/chat-b/epilogue-explicit-npc-visit-20261107`; **PR:** [#628](https://github.com/ManuEtt/Dnd/pull/628) (bis vollständiger CI Draft). **Fachcommit:** `00786d0f2ad77da11c63c03f55880226cf7edeb1`; **Testcommit:** `d0010c7b924ab7fd27511ce0404722fef211311d`.
- **Problem:** `FourteenthVoiceEpilogue.advance` behandelte rohe Teilzeichenfolgen wie `elda`, `zeichnung`, `brief`, `brunnen`, `platz` als gültige Besuche oder Rückkehr. Eine Erörterung ohne Reiseabsicht veränderte Story-Stage und setzte `voice:epilogue:<npc>=true`, also den Zähler für bestätigte Zeugen und die Freigabe der Dorfzukunft.
- **IMPLEMENTIERT:** `_visits` verlangt eine eindeutige vollständige Besuchs-/Reise-/Gesprächshandlung. `_returnsToSquare` verlangt eine ausdrückliche Rückkehr-/Ortswechselhandlung; bloße Dorfplatz-Erwähnungen bleiben ohne gespeicherten Zustandswechsel. Altkommandos `Ich besuche Elda`, `Ich besuche Tarek`, `Ich besuche Liora`, `Zurück zum Dorfplatz` bleiben gültig. Negationssperre und Mindestzahl unterschiedlicher Stimmen unverändert.
- **Geänderte Dateien:** `app/lib/story/fourteenth_voice_epilogue.dart`, neue Tests in `app/test/rabenwacht_epilogue_explicit_visit_test.dart`, append-only README sowie additive zentrale und lokale Checkpoints.
- **Tests ergänzt:** Fünf Fälle für unerwünschte NPC-, Gegenstand- und Ortsnennungen; acht echte Besuchs-/Gesprächs-/Reisevarianten; klare Rückkehr; JSON-Import/Wiederaufnahme; SQLite-Reopen und Journalrekonstruktion. Assertions auf unveränderte ursprüngliche Daten, Questzustände, Heldenwerte, Revision.
- **GETESTET:** Live-Masterprompt, Projektanweisungen, aktuelle Code-/Testdateien, 42 offene PRs und deren Story-/Rabenwacht-Dateipfade geprüft; keine parallele Änderung des Fachmoduls. Main ist bei Start `1816115990cc7420ecfb2d1ba7c6babb557f76da`, erste Code- und Testcommits sind remote gesichert.
- **NICHT GETESTET:** Vollständige Flutter-/Dart-/Android-Release-CI auf finalem Branch-HEAD bei Erstellung dieses Nachtrags offen, echtes Android-Gerät, produktive KI, Bestands-Upgrade. Alte grüne CI von PR #623 ist kein Nachweis für #628.
- **Kompatibilität:** Keine Migration, keine Schema-/JSON-Änderung, keine Regeln-/Kampf-/Ressourcenbuchung, keine KI-Provider-Änderung. Bisher gespeicherte NPC-Notizen und Besuche bleiben unangetastet.
- **NÄCHSTER SCHRITT:** CI auf finalem Commit vollständig prüfen, Fehler auf eigenem Branch korrigieren, danach Draft zur Review freigeben; Chat D übernimmt konfliktfreie Dokumentationsintegration und Merge.


### 2026-11-10 – Konfliktfreie Neuauflage der verneinten Rabenwacht-Rückreise

- Basis: `main` `73f377ece91cb14a5074ddba16fbbc57b153026e`; Branch: `fix/chat-b/rabenwacht-negated-revisit-rebased-20261110`.
- Verneinte Rückreise wird abgefangen, ohne Bühne, Ort, Held oder Besuchsmerker zu ändern; positive Rückreise bleibt erhalten.
- Regression: `app/test/rabenwacht_negated_revisit_test.dart`, drei Fälle. Ursprünglicher Draft-PR #666 mit 6/6 grünen Jobs bleibt unangetastet, da sein Branch wegen inzwischen divergiertem `main` nicht mergebar ist.
- Neue CI und Review durch Chat D erforderlich; kein automatischer Merge.



## 2026-11-05 – Strukturierte NPC-Identität gegen Legacy-Unicode (PR #582)

- **Ausgangs-main:** `0e4474c55ce80f625f373394d6f7855b4a2487ad`.
- **Branch:** `feat/chat-b/structured-npc-legacy-unicode-20261105`, **Draft-PR:** [#582](https://github.com/ManuEtt/Dnd/pull/582).
- **Fachcommit:** `ae5b889b7549b656bba3292cfdb44161ce7c8770`; **Regression:** `998ebcd49484c5929c3b920ec76a8e2caf367cde` sowie Testtitel-Formatcommit `247a4dfeb7119dd61aa7b9cfc0b26e7fe5c995c8`. Abschließenden HEAD und CI live prüfen.
- **Ausgangsproblem:** Die strukturierte `NpcIdentityStoryPayload` behandelte U+00AD, U+034F, U+180E und U+206A–U+206F nicht durchgehend als unsichtbare Formatcodes. Dadurch konnten visuell gleiche NPC-Namen bei freier Sprache als getrennte Identitäten behandelt werden. Die Codes konnten außerdem strukturierte Namen, Beziehungen und Notizen auf dem KI-Wire passieren.
- **IMPLEMENTIERT:** Zwei bestehende Wächter (`_fold` und `_validText`) im Modul `app/lib/story/npc_identity_story_payload.dart` um diese Codes erweitert: sichtbare Namen werden beim Vergleich gefaltet; strukturierte Daten mit unsicheren Rohzeichen werden verweigert (fail-closed). Gültig explizit gewählte, saubere NPC-IDs bleiben möglich. Keine Mutation gespeicherter Texte, mechanischer Regeln oder bestätigter Kampagnen.
- **TESTS ERGÄNZT:** `app/test/npc_identity_legacy_unicode_payload_test.dart` mit vier Gruppen: neun Namensspoofing-Varianten einschließlich expliziter Auswahl; je neun Formatzeichen in Namen, Beziehung, Notiz und Notizbeziehung; deutsche Namen/Emoji, JSON-Legacy und Stale-/Same-Revision; echter SQLite-Neustart, Identität und Journalrekonstruktion.
- **GETESTET:** GitHub-Main, Masterprompt, offene PRs, Fachdateipfade sowie bestehende Architektur-/Storytests geprüft; Fachcode und Regressionen auf eigenem Branch committed. Keine Überschneidung der Fachdateien mit den drei damals offenen Regel-PRs #579/#580/#581.
- **NICHT GETESTET:** Flutter/Dart/Python/Backend/Android-CI auf finalem PR-HEAD erst bei vollständigem Actions-Nachweis; Installation auf echtem Android-Gerät und produktiver KI-Anbieter nicht geprüft. Kein lokales Flutter/Dart-SDK.
- **MIGRATION:** Keine. Bestehende JSONs/SQLite-Versionen, IDs, Events, Helden, Inventar, Quests und alte gespeicherte Rohtexte unverändert.
- **BLOCKIERT:** Vollständige CI-/Integrationsabnahme und Geräteprüfung. Gemeinsame README-/CODEX-Nachträge mit parallelen PRs verlustfrei durch Chat D zusammenführen; README streng append-only und ohne neue Chat-Bezeichnungen.
- **NÄCHSTER SCHRITT:** Finale CI #582 prüfen, konkrete Formatter-/Testfehler auf demselben Branch korrigieren; nach grünen Gates kontrollierte Integration.



## 2026-11-06 – Legacy-NPC-Identität in Recall und Sitzungsrückblick (PR #590)

- **Ausgangs-main:** `84c6259b38c5f742198276ae3d3d0f80d0c4f51e`.
- **Eigener Branch:** `feat/chat-b/npc-memory-hidden-name-identity-20261106`. **PR:** [#590](https://github.com/ManuEtt/Dnd/pull/590) (Draft).
- **Fach-/Testcommits:** `9753525f02d61d3ca1e06a9d070a2146fef931c2`, `e36cb9a32fabd7953581392ee517f929b6c16b2c`, `bbf7eec464181e357a83e3f94e65ecadaed5daa4`. **Finalen Branch-HEAD** inklusive Dokumentation bei CI-Abnahme ermitteln.
- **Problem:** Legacy-Namen wie `Mira` und `Mi<U+00AD>ra` konnten im bestätigten `MemoryEngine.retrieve` und im gespeicherten `MemoryEngine.buildSessionSummary` als verschiedene Namen behandelt werden, ohne sichere NPC-ID. Versteckte Marken wurden sichtbar in Erinnerungszeilen übernommen.
- **Implementiert:** Unicode-Formatmarken werden beim lexikalischen Abgleich und bei der einzeiligen Namensdarstellung im Story-Gedächtnis entfernt. Optisch gleiche NPCs werden **nur bei eindeutigen, kanonischen IDs** mit eigener `NPC-ID` ausgewiesen; bei unsicherer/mehrdeutiger ID wird kein bestätigtes NPC-Faktum vermutet. Eingaben mit Legacy-Formatmarken finden dieselben bestätigten Namen. Sonstige Story- oder SRD-Regeln unberührt.
- **Betroffene Fachdateien:** `app/lib/story/story_memory_engine.dart`, `app/test/story_memory_npc_legacy_format_test.dart`. Dokumentation: README (nur angehängter neutraler Eintrag), `docs/CODEX_CHECKPOINT.md` (anhängen), dieser Checkpoint (anhängen).
- **Tests ergänzt:** vier Gruppen mit neun Formatcodepunkten, Dubletten-ID und leeren Sichtnamen, deutschen Unicode-Namen, GameEngine-Recap mit JSON-Legacy, echtem SQLite-Neustart mit Revision-0-Erstsave, vollständigem Feldvergleich und Journalrekonstruktion.
- **Prüfstatus:** Repository-/Masterprompt-/Architektur-/Fachdateien sowie offene PRs geprüft; keine Fachüberschneidung. **Neue Tests noch nicht als bestanden belegt**, GitHub-CI-Status nach finalem HEAD prüfen. Lokales Flutter/Dart nicht verfügbar. Der **vorausgehende** unabhängige PR #582 hat nach SQLite-Testfix die vollständige Actions-Suite [#42160305094](https://github.com/ManuEtt/Dnd/actions/runs/42160305094) erfolgreich abgeschlossen, ist jedoch noch nicht als integriert nachgewiesen.
- **Migration:** keine. Bestätigte Quellen, IDs, JSON und SQLite unverändert; keine Controller-, UI-, Regel-, Backend-, Signierungs- oder Event-Schemaänderung.
- **Bekannte Grenzen:** CI für #590 offen, Android-Realgerät und echter Anbieter ungetestet; README-/CODEX-Dokumentation mit anderen PRs bei Integration verlustfrei abstimmen.
- **Nächster konkreter Schritt:** Komplette CI des finalen PR-HEADs verfolgen, ggf. Fehlerursache im selben Branch beheben; danach Integration über Chat D koordinieren.



## 2026-11-06 – Sicherer typisierter NPC-Identitätskontext (PR #593)

- **Ausgangs-main:** `9a0fa855374a67805e531ad8574e048d99b33745`.
- **Branch:** `feat/chat-b/npc-typed-context-legacy-main-20261106`; [Draft-PR #593](https://github.com/ManuEtt/Dnd/pull/593).
- **Fach-/Testcommits:** `d6f95935c20312014fb04af456ef24b9d4add108`, `395c43924141bf112a722c6994a5838eaaff7178`; finalen HEAD nach den Checkpoint-/README-Nachträgen und CI-Befunden live prüfen.
- **Problem:** `NpcIdentityContext.toContextMap` behandelte nur `\s+` als Leerzeichen. Ältere gespeicherte Unicode-Formatcodes und Bidi-Marken blieben in als bestätigt markierten, ID-bezogenen Story-Kontextfeldern erhalten. Der separate Leser akzeptierte sogar unkanonische 128-Zeichen-IDs, obwohl strukturierte und ausdrücklich gewählte NPC-Identitäten nur 1–64 sichere ASCII-Zeichen unterstützen.
- **Implementiert:** `app/lib/story/npc_identity_memory.dart` gibt eine saubere, nur lesende Einzeilenprojektion aus. Unsichtbare Formatmarken werden in Anzeigenamen verbunden, in Beziehung/Notizen durch Leerraum ersetzt; C0/C1 und U+2028/U+2029 werden entfernt/vereinheitlicht. `NpcIdentityMemory.read` lehnt ungültige NPC-IDs künftig fail-closed ab. Die Quelle `NpcIdentityContext._sourceStamp` und sämtliche gespeicherten Raw-Daten bleiben unverändert; bei einem unbestätigten Rohwertwechsel unter derselben Revision schlägt `requireCurrent` weiterhin fehl.
- **Neue Regressionen:** `app/test/npc_typed_context_legacy_marks_test.dart` – neun historische Formatmarken, Control-/Newline-Spaces, ungültige IDs und 64-Zeichen-Grenzwert, alte JSONs, Immutabilität, echter SQLite-Neustart mit Revision-0-Erstsave, NPC-Isolation, Journalrekonstruktion und Snapshot-Revisionsschutz.
- **Fachdateien:** ausschließlich `app/lib/story/npc_identity_memory.dart` und neue Testdatei. Dokumentationsdateien README (append-only mit neutraler Überschrift), `docs/CODEX_CHECKPOINT.md` und dieser Checkpoint ebenfalls ausschließlich additiv.
- **Getestet:** aktuelle Projekt- und Architekturdokumentation, Quellcode, bekannte Regressionen, Main-Stand und alle offenen PR-Pfade geprüft; separater Branch vom neuen Hauptstand erstellt.
- **CI noch offen:** kein erfolgreicher Nachweis von finaler Dart-Formatierung, Flutter-Analyse/Vollsuite, Python/Backend und Android für #593 bis zur konkreten Action-Abnahme. Kein lokales Dart/Flutter installiert, kein reales Android-Gerät und kein produktiver KI-Anbieter geprüft.
- **Kompatibilität:** keine Änderungen an JSON-/SQLite-Schemata, Heldenzuständen, Quests, Regelwerten, Event-Fluss, GameEngine, Backend oder App-Version. Keine Migration. Vorherige getrennte PRs #582/#590 vollständig grün getestet, aber nicht automatisch integriert.
- **Nächster konkreter Schritt:** finale CI des PR-HEADs beobachten, fehlschlagende Prüfschritte nachweisbar beheben, erfolgreiche Ergebnisse im PR protokollieren; Integration und gemeinsame Dokumentation durch Chat D koordinieren.


## 06.11.2026 – Integrität offener Hinweise in gespeicherten Sitzungsrückblicken

- **Main-Ausgangs-SHA:** `95c605898f1bcae26e0a23afa55c767ec5b20744`.
- **Eigener Branch:** `feat/chat-b/recap-open-lead-id-integrity-20261106`; **Fach-/Testcommit:** `3cafb7a29079c0e6f47a67e0d04350b062c41941`. **Pull Request:** [#602](https://github.com/ManuEtt/Dnd/pull/602) (Draft; endgültigen Dokumentationscommit gesondert prüfen).
- **Ausgangsproblem:** Die gespeicherten Open-Leads-Rückblickzeilen vertrauten `status == open` ohne kanonische ID und Eindeutigkeitsnachweis; die read-only Wiederaufnahmeübersicht filterte diese Fälle bereits.
- **IMPLEMENTIERT:** `_summaryWithOpenLeads` zählt alle Thread-IDs vor der Auswahl und berücksichtigt nur eindeutige `^[a-zA-Z0-9_-]{1,64}$`-Kennungen mit offenem Status. Keine automatischen Quest-/Kampf-/EP-Folgen.
- **Änderungen:** `app/lib/story/story_campaign_engine.dart` und neuer `app/test/story_recap_open_lead_id_integrity_test.dart`; additive `README.md`-/`docs/CODEX_CHECKPOINT.md`-/`docs/parallel/CHAT_B_CHECKPOINT.md`-Dokumentation.
- **Tests:** Vier neue Flutter-Fälle zu erlaubten/unsicheren IDs, bestätigter Zusammenfassung, Doppel-IDs mit widersprüchlichen Status, Auswahlreihenfolge/Limit, SQLite-Replay und unverändertem Helden-/Originalzustand. **Ausführung auf dem finalen PR-HEAD noch ausstehend.** Vorherige volle CI #598 auf `a05e50b19572305520a62bb09a4ec0c5753e079b`: [erfolgreich](https://github.com/ManuEtt/Dnd/actions/runs/42184643176), unabhängig von diesem Paket.
- **NICHT GETESTET:** Lokales Dart/Flutter, vollständige neue GitHub-CI und Android-Debug-/ABI-APK, echtes Android-Gerät, Produktiv-KI.
- **BLOCKIERT:** CI/Review sowie verlustfreie, koordinierte Integration der allgemeinen README-/Checkpoint-Dateien mit den anderen offenen PRs.
- **Migrationen:** Keine. Vorhandene SQLite-/JSON-Spielstände, Regel-/Questwerte, Ereignisse und App-Version werden nicht geändert.
- **Nächster Schritt:** Gesamte CI auf finalem #602-Commit abnehmen, etwaige Fehler isoliert im eigenen Branch korrigieren und anschließend an die Integration übergeben.

- **Nachtrag zur Integration (06.11.2026):** Die bisherige CI [#42189711653](https://github.com/ManuEtt/Dnd/actions/runs/42189711653) wurde in der SQLite-Setup-Phase abgebrochen, nicht erfolgreich abgeschlossen. Der Branch wird deshalb verlustfrei mit dem aktuellen `main` (vor dem Merge-Commit: `0a813df100aa649c2204018349b0db9af09fb83f`) zusammengeführt; gemeinsam geänderte Dokumentation ist additive, die Fachdateien bleiben auf demselben Code-Stand. Vollständige CI auf dem neuen Merge-HEAD steht erneut aus.

---



## 06.11.2026 – Nur eindeutige NPC-Notiz-IDs im bestätigten Erzählergedächtnis

- **Basis-main:** `2a4fab5a56127d866dd2a8933836fd1136d772b3`; **Branch:** `feat/chat-b/npc-narrator-note-id-integrity-20261106`; **PR:** [#605](https://github.com/ManuEtt/Dnd/pull/605) (Draft); **Fach-/Testcommit:** `9e6f7f33bdfb4d7cfe60fbfe76cc1784c74d2e7c`.
- **IMPLEMENTIERT:** `NpcNarratorMemory.merge` priorisiert Beziehungsnotizen nur mit eindeutiger kanonischer 1–64-Zeichen-ASCII-ID und ebenso sicheren NPC-IDs. Kollisionen selbst über NPC-Grenzen hinweg sperren beide Notizen; Quellen-/Rohdaten bleiben unverändert.
- **Neue Tests:** `app/test/npc_narrator_note_id_integrity_test.dart` mit vier neuen Tests zu widersprüchlichen gleichen IDs, Cross-NPC-ID-Kollisionen, Legacy-JSON mit unsicheren Notiz-/NPC-IDs, und SQLite-Reopen/Replay mit identischem bestätigtem Spielstand und sauberem Wire-Kontext.
- **GETESTET:** Aktuelle GitHub-Main-/PR-/Fachpfadprüfung, eigenständige Code- und Testcommits. Letzter vollständig belegter eigener Story-PR-Vorgänger: [#598-CI](https://github.com/ManuEtt/Dnd/actions/runs/42184643176) auf `a05e50b19572305520a62bb09a4ec0c5753e079b` grün; nicht der aktuelle PR.
- **NICHT GETESTET:** Neue Tests und finale Flutter-/Dart-/Android-CI von #605, Gerätebetrieb, produktive KI; lokal kein Dart/Flutter-SDK. Laufender #602-SQLite-CI-Schritt ist unabhängig.
- **BLOCKIERT:** CI-/Review-Abnahme des finalen #605-Commits und spätere Dokumentationskonsolidierung; an fremden Branches und `main` nichts verändert.
- **Kompatibilität:** Kein Schema-/Versionswechsel, keine Migration, keine Regel-, Helden-, Quest-, XP-, Inventar- oder JSON-/SQLite-Mutation, kein neuer Anbieter.
- **Nächster Schritt:** GitHub Actions auf dem endgültigen Commit bis zu Flutter-/Android-Gates auswerten, fehlschlagende Regressionen im eigenen Branch beheben und danach kontrolliert zur Integration übergeben.

- **CI-/Integrationsnachtrag (06.11.2026):** Die vollständige [GitHub-CI #42194582591](https://github.com/ManuEtt/Dnd/actions/runs/42194582591) war für den ursprünglichen Fach-HEAD `2a2d6bad4926f84d070ba6c393c6cce2d96b8981` erfolgreich. Wegen neuer `main`-Änderungen wurden alle dortigen Dokumentationsnachträge erhalten und der PR-Branch durch einen Merge-Commit aktualisiert; für diesen neuen HEAD ist eine eigene vollständige CI-Abnahme erforderlich. Kein Merge in `main` und keine Geräteabnahme.

---



## 06.11.2026 – Sitzungsgültigkeit der expliziten NPC-Auswahl und präzisierter Testnachweis

- **Basis-main:** `0a813df100aa649c2204018349b0db9af09fb83f`; **Branch:** `fix/chat-b/npc-selection-terminal-newline-id-20261106`; **PR:** [#610](https://github.com/ManuEtt/Dnd/pull/610) (Draft); **Code-/Teststand:** `a6d02c839323b383272ba37309ec3912773ca0e7`.
- **Berichtigung:** Dart-RegExp weist abschließende Zeilenumbrüche mit dem vorhandenen regulären Ausdruck bereits zurück. Der vollständige `stringMatch` ist defensiver Vertrag und darf nicht als nachgewiesene alte Umgehung dargestellt werden.
- **IMPLEMENTIERT:** Zusätzlich zur vollständigen Kennungsprüfung weist `NpcStorySelection.choose` eine fehlende/nur Whitespace enthaltende `sessionId` zurück. Dieser vorher akzeptierte direkte In-Memory-Fall ist mit neuem Negativtest abgedeckt.
- **Dateien:** `app/lib/story/npc_story_selection.dart`, `app/test/npc_story_selection_terminal_id_test.dart`; additive Dokumentation in `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_B_CHECKPOINT.md`.
- **Regressionen:** Fünf Tests zu ungültigen/normalen IDs, ungültigen/normalen Sitzungen, Alt-JSON und konkretem ID-Kontext, kollisionsfreien gleichnamigen NPCs und Stale-Profil, SQLite-Reopen/Replay. Gespeicherte Identitäten und Heldenzustand bleiben unverändert.
- **GETESTET:** GitHub-Main-/PR-Abgleich und isolierte Branch-Code-/Testcommits. [CI #42201211687](https://github.com/ManuEtt/Dnd/actions/runs/42201211687) scheiterte bei der Dart-Formatierung; kompakte Testausdrücke wurden korrigiert; finale CI noch nicht grün nachgewiesen.
- **NICHT GETESTET:** Vollständige Flutter-Tests/Android-Build des aktuellen finalen HEAD, lokales Dart/Flutter, echtes Android, Produktiv-KI.
- **BLOCKIERT:** Vollständige CI-/Review-Abnahme und Integrationskoordination; kein automatischer Merge oder Force-Push.
- **Migrationen:** Keine. SQLite/JSON/Events, Quests, Kämpfe, XP, Herozustand und App-Version unverändert.
- **Nächster Schritt:** Endgültige CI einschließlich Format, Flutter-Tests und Android-Gates auf dem neuen finalen PR-HEAD auswerten und verbleibende Fehler auf demselben Branch beheben.

---

## 06.11.2026 – Nur kanonische, vollständige NPC-Auswahl-IDs verwenden

- **Ausgangs-main:** `0a813df100aa649c2204018349b0db9af09fb83f`.
- **Eigener Branch:** `fix/chat-b/npc-selection-terminal-newline-id-20261106`; **Fach-/Testcommit:** `231b98e1ad68e848674a3a4de87a61fcf5a73972`; **PR:** [#610](https://github.com/ManuEtt/Dnd/pull/610) (Draft; finalen Dok-HEAD/CI gesondert prüfen).
- **Ausgangslücke:** Der `hasMatch`-Guard der expliziten NPC-Wahl kann die Kennung eines älteren Spielstandes akzeptieren, wenn `$` unmittelbar vor einem abschließenden Zeilentrennzeichen passt.
- **IMPLEMENTIERT:** `NpcStorySelection.choose` verlangt die volle Übereinstimmung einer sicheren 1–64-stelligen ASCII-ID, bevor ein NPC ausschließlich über seine gespeicherte ID ausgewählt wird. Keine Ableitung aus dem Namen, keine ungeprüften Regeländerungen.
- **Regressionen:** `app/test/npc_story_selection_terminal_id_test.dart` enthält vier Tests zu Steuer-/Unicode-Zeilenenden, unverändertem JSON-Altbestand, expliziten gleichnamigen NPCs mit Stale-Sperren und SQLite-Neustart/Replay. Fachpfad `app/lib/story/npc_story_selection.dart`.
- **GETESTET:** Aktueller Main-HEAD und alle offenen PR-Fachdateien auf Kollisionen geprüft. Neuer Code und Tests auf eigenem Branch gesichert; kein fremder Branch überschrieben.
- **NICHT GETESTET:** Neue Flutter-Tests lokal (kein Dart-/Flutter-SDK), finale vollständige GitHub-PR-CI, Android-APK, reales Gerät, Produktiv-KI. Der alte vollständige grüne [#605-Lauf](https://github.com/ManuEtt/Dnd/actions/runs/42194582591) belegt nicht #610.
- **BLOCKIERT:** Neue CI-/Review-Abnahme; koordinierte Integration gemeinsamer README-/Checkpoint-Nachträge sowie noch laufende CI auf #602/#605.
- **Kompatibilität:** Bestehende NPC-IDs, gesicherte Notizen, JSON/SQLite/Events, Quest-/Regel-/Herozustand und App-Version unverändert. Keine Migration.
- **Nächster Schritt:** Volle GitHub-CI auf dem finalen #610-Head abnehmen, gegebenenfalls Format-/Testfehler auf dem Branch korrigieren und danach konfliktfreie PR-Integration koordinieren.

---





---

## 06.11.2026 – NPC-Wiedereinstieg benötigt gültige Sitzungs-ID (PR #611)

- **Ausgangs-Main-SHA:** `0a813df100aa649c2204018349b0db9af09fb83f`.
- **Branch:** `fix/chat-b/npc-resume-session-guard-20261106`; **Code-/Test-Commits:** `6444570b1ad5d9fa7e539bef23ebe57aee9399f7`, `9aeb6ce8768a7831e1f0663230d18f068ea5b3fc`; **PR:** [#611](https://github.com/ManuEtt/Dnd/pull/611) (Draft). Letzten Dokumentations-HEAD beim CI-Vergleich ermitteln.
- **Ausgangsproblem:** `ConfirmedNpcResumeSelector.read` akzeptierte eine direkt konstruierte Kampagne ohne gültige `sessionId`, obwohl ein bestätigter Rückblick an eine konkrete gespeicherte Sitzung gebunden sein muss.
- **IMPLEMENTIERT:** Leere oder nur Whitespace enthaltende `sessionId` wird bereits beim Read-Preflight mit `FormatException` abgelehnt; der eigentliche NPC-/Notiz-Selektor und der gespeicherte Spielstand werden nicht mutiert.
- **Geänderte Fachdateien:** `app/lib/story/confirmed_npc_resume_selection.dart`; neu: `app/test/confirmed_npc_resume_session_guard_test.dart`.
- **Akzeptanztests:** Drei deterministische Tests: leere/ASCII-/Unicode-Whitespace-Sitzung wird abgelehnt und lässt den Original-JSON-Zustand unangetastet; gültige Sitzung zeigt gespeicherte NPC-Notiz; gleich-revisionierte fremde oder leere Sitzung scheitert an `requireCurrent`.
- **GETESTET:** Aktueller Main-HEAD, 27 konkurrierende PRs und deren relevante Dateipfade vor Start geprüft; der Fachcode und die drei Regressionstests im eigenen Branch committed. Nach PR-Erstellung 28 offene PRs; die beiden neuen Fachdateipfade werden von keinem anderen offenen PR beansprucht.
- **NICHT GETESTET:** Dart-Format, Flutter-Analyse, Flutter-Unit-/Widgettests, APK, sämtliche PR-#611-CI-Jobs auf finalem Dokumentations-HEAD, Realgerät und produktive KI (lokal keine Dart-/Flutter-SDKs; kein GitHub-DNS-Checkout).
- **BLOCKIERT:** Fachliche CI-Abnahme und Review stehen aus; gemeinsame README und zentrale Checkpoints aus anderen PRs müssen bei der Integration verlustfrei zusammengeführt werden.
- **Migrationen:** Keine; JSON/SQLite, Charakterwerte, Quests, Regelzustand und App-Version bleiben unverändert.
- **NÄCHSTER SCHRITT:** CI von PR #611 auf dessen endgültigem HEAD abnehmen, etwaige Fehler im selben Branch korrigieren; danach ohne Dokumentationsverlust im Integrationsschritt zusammenführen.




---

## 07.11.2026 – NPC-Chronik mit global eindeutiger Notiz-ID (PR #615)

- **Main-Basis:** `0a813df100aa649c2204018349b0db9af09fb83f`; **Branch:** `fix/chat-b/npc-continuity-note-id-20261107`.
- **PR:** [#615](https://github.com/ManuEtt/Dnd/pull/615), zunächst Draft bis zur vollständigen CI-Abnahme. **Fachcommit:** `3bf714e1fe9cc616a7c47a8ccd6ad8180e758acb` (korrigierter Reader), **Testcommit:** `3bad7257c43227695106d6033fdbdf95d3efc1ba`; README-Nachtrag `066198341e307fe2dc6bd07653915719f850fd81`. Finalen Dokumentations-HEAD bei CI ermitteln.
- **Ausgangsproblem:** `NpcContinuityReader` wählte rohe gespeicherte NPC-Beziehungsnotizen ausschließlich anhand des NPC-Ziels und Zeitstempels. Ungültige/doppelte Notiz-IDs in direkt konstruierten oder beschädigten Kampagnen konnten als separate bestätigte Erinnerungen erscheinen und valide Notizen durch das Limit verdrängen.
- **IMPLEMENTIERT:** Kampagnenweite ID-Zählung und vollständige sichere Notiz-ID-Prüfung; alle doppelt/ungültig identifizierten Notizen werden schon vor Zeitstempel-Ranking/Limit verworfen. Gültige Notizen bleiben in alter zeitlicher Reihenfolge und ihrem Inhalt unverändert; keinerlei Schreibzugriff auf Spielstand oder Regeln.
- **Dateien:** `app/lib/story/npc_continuity_reader.dart`, neu `app/test/npc_continuity_note_id_integrity_test.dart`, ausschließlich additive README-/Checkpoint-Nachträge.
- **Akzeptanztests:** Vier deterministische positive/negative Fälle: Dubletten innerhalb und außerhalb des ausgewählten NPCs, gefährliche Leerzeichen/Zeilenende/Unicode-ID, Limit nach Filterung bei Zeitstempelgleichstand, gültiges/älteres JSON, SQLite-Neustart einschließlich unverändertem Helden und rekonstruierbarem Savegame.
- **GETESTET:** Repository, Masterprompt, Pflichtdokumente, Main-HEAD, 31 offene PRs samt relevanten Dateipfaden und Vorläufer-CI geprüft; Fachcode und Tests committed; sauberer Zwei-Datei-Code-Diff bestätigt. Vorläufer-PR #611 vollständig grün in [CI #42288725397](https://github.com/ManuEtt/Dnd/actions/runs/42288725397), was ausdrücklich kein Nachweis für #615 ist.
- **NICHT GETESTET:** Neue Flutter-/Dart-Tests, kompletter GitHub-Actions-Lauf inklusive APK/Release auf finalem PR-Head, Gerätetest, produktive KI, Upgrade (bei Anlage dieser Notiz noch offen).
- **BLOCKIERT:** CI-Abnahme und Review; zentrale README-/Checkpoint-Änderungen anderer PRs vor Integration verlustfrei zusammenführen.
- **Migrationen:** Keine; unveränderte SQLite-/JSON-Struktur, SchemaVersion, Helden-, Quest-, Regel- und KI-Provider-Daten.
- **NÄCHSTER SCHRITT:** Alle CI-Jobs für den finalen PR-#615-HEAD abnehmen und auffällige Tests im selben Branch korrigieren; danach PR zur Review freigeben und Chat D die konfliktfreie Dokumentationsintegration überlassen.




---

## 07.11.2026 – Rat der Zeugen ausschließlich durch explizite Einberufung (PR #619)

- **Main-Basis:** `0a813df100aa649c2204018349b0db9af09fb83f`; **Branch:** `fix/chat-b/act8-council-explicit-intent-20261107`; **PR:** [#619](https://github.com/ManuEtt/Dnd/pull/619) (zunächst Draft). **Fachcommit:** `9b2e4cc436e9418ed21c12b0c398ecfb492b08f2`; **Testcommit:** `21d191a25f256afdc7cd0ce532f0957b28a3aa97`.
- **Ausgangsproblem:** `FourteenthVoiceAct8.advance` leitete am `voice-threshold` bereits aus der Teilwort-Erwähnung „rat“ in „verrate“ oder dem Ortsnamen „Dorfplatz“ die Einberufung einer Ratsversammlung ab, obwohl der Spieler keine solche Entscheidung getroffen hatte.
- **IMPLEMENTIERT:** `_convenesCouncil` verlangt explizite Handlungsabsicht (berufen, versammeln, rufen, einladen) und eindeutiges Rats-/Zeugenziel; bestehende Negationssperre und echte Beweis-/Eidblattvoraussetzungen bleiben erhalten. Nur Story-Szenenübergang in `app/lib/story/fourteenth_voice_act8.dart`; keinerlei Änderung an Rule-/Hero-/Quest-/SQLite-Zustand.
- **TESTS ERGÄNZT:** `app/test/rabenwacht_act8_council_intent_test.dart` prüft falsche Teilworttreffer und bloße Orts-/Ratserwähnungen, vier gültige Einberufungen, Sperren bei fehlender Verwahrung/Beweisen, JSON-Roundtrip und unveränderten Originalspielstand.
- **GETESTET:** Live-main, Masterprompt, bestehende Akt-VIII-Abläufe und 35 offene PRs auf Dateikonflikte geprüft. Diff initial zwei Fachdateien ohne parallele Änderungen.
- **NICHT GETESTET:** Neue Flutter-/Dart-Tests, gesamte CI inkl. Android/Release auf finalem Branch-HEAD, Android-Gerät, produktive KI; bei Erstellung dieser Notiz noch offen.
- **ABGRENZUNG:** Keine neuen JSON-/SQLite-Felder, keine Migration, keine Regeln oder Bestätigungsbuchungen. Die README erhält ausschließlich einen neuen neutralen Nachtrag am Ende; zentrale Checkpoints bei späterem Merge additiv integrieren.
- **NÄCHSTER SCHRITT:** GitHub-Actions-Abnahme auf finalem Commit abschließen, Testfehler im Branch beheben, nach vollständig grünen Jobs PR zur Review freigeben, Chat D koordiniert Merge.




---

## 07.11.2026 – Verbindliche Nachgeschichten-Enden nur nach ausdrücklicher Wahl (PR #623)

- **Basis-main:** `f580d4c40f6a29df0098f656094844bfca1ed573` (inkl. PR #613), **Branch:** `fix/chat-b/morrow-ending-explicit-choice-20261107`; **PR:** [#623](https://github.com/ManuEtt/Dnd/pull/623), zunächst Draft. **Fachcommit:** `8d29f2f71687f3cc54e0ca25c7e8da737fabad0c`; **Testcommit:** `746865150ccdd3916a1f90a184a759f1e432c176`.
- **Ausgangsproblem:** Im `voice-morrow-council` konnte die rohe `_said`-Teilwortsuche aus bloßen Fragen, Zitaten oder hypothetischen Handlungsformen (`Sollten wir den Brief versiegelt verwahren?`) ein unumkehrbares Finale machen und Quests/Handlungsstränge als abgeschlossen markieren.
- **IMPLEMENTIERT:** Ein neues `_choosesEnding` akzeptiert für die drei Endoptionen nur vollständige direkte Kommandos bzw. explizite Ich-/Wir-Absichtserklärungen. Negationen, unvollständige Hinweise und ungelesener Brief blockieren weiterhin. Keine Änderung an bestätigten Regeln, KI-Autorität, Helden-, Inventar- oder sonstigem Speicherzustand durch eine unverbindliche Frage.
- **Dateien:** `app/lib/story/fourteenth_voice_morrow.dart`, neuer Test `app/test/rabenwacht_morrow_explicit_ending_test.dart`; ausschließlich additive README- und Checkpoint-Nachträge.
- **Akzeptanztests:** Fünf Tests für Fragen/Zitate/Hypothesen, drei direkte/erweiterte echte Entscheidungsvarianten, fehlende Beweise, JSON-Wiederaufnahme, SQLite-Schließen/Neuöffnen samt Quest-/Thread-/Heldenstatus und Journalrekonstruktion.
- **GETESTET:** Live-Masterprompt, aktuelle Projektanweisungen, alle 38 offenen PRs hinsichtlich fachlicher Dateikonflikte, unveränderte Story-Fachdatei nach neuem `main`-Merge von #613 und Zwei-Datei-Fach-Diff. Vorherige PRs #615/#619 im CI erfolgreich, aber kein Nachweis für #623.
- **NICHT GETESTET/BLOCKIERT:** Dart-Format, Flutter-Analyse/Tests, kompletter Android-/Release-Workflow auf finalem PR-HEAD bei Erstellung dieser Notiz noch offen; echtes Android-Gerät, produktive KI und App-Upgrade nicht geprüft.
- **Migrationen:** Keine SQLite-/JSON-/App-Version-Änderung. Die KI darf keinen Regelzustand bestätigen; Abschlussentscheidungen verbleiben in bestehendem `facts`, `quests` und `storyBible`-Schema.
- **NÄCHSTER SCHRITT:** Gesamt-CI auf endgültigem PR-HEAD abnehmen, etwaige Probleme innerhalb des Branches reparieren, dann PR zur Review freigeben. Zusammenführung inklusive gemeinsam genutzter README-/Checkpoint-Abschnitte durch Chat D, kein automatischer Merge.




---

## 07.11.2026 – Namesverwahrung in Akt VII ausdrücklich wählen (PR #632)

- **Ausgangs-main:** `bbe6ee0901f1873af67647bf54462e4a44821762`; **Branch:** `fix/chat-b/act7-custody-explicit-intent-20261107`; **PR:** [#632](https://github.com/ManuEtt/Dnd/pull/632), zunächst Draft. **Fachcommit:** `f3a8b68f77e4d1cd6e8951a42e471782773f84b9`; **Testcommit:** `fa61a18a75496a858c631e538299fccc8e74fcf6`.
- **PROBLEM:** Im `voice-ledger` erkannte `FourteenthVoiceAct7.advance` den Textausschnitt `liora den namen` beziehungsweise `selbst bewahr` als bestätigten Verwahrungsauftrag. Bereits eine Frage („Kann ich Liora den Namen anvertrauen?“) oder eine hypothetische Aussage konnte den unveränderlichen Kampagnenfakt `voice:nameCustody` setzen und den Weg zu Akt VIII freischalten.
- **IMPLEMENTIERT:** `_choosesNameCustody` akzeptiert ausschließlich vollständige Entscheidungen für Liora oder Eigenverwahrung (bestehende Aktionskommandos und eindeutige Ich-Absichtserklärungen). Die zuvor untersuchte Eidseite bleibt notwendig; negative und hypothetische Äußerungen bleiben unverbindlich. Keine eigenmächtigen Regeln, Würfel, XP, Inventar- oder Queständerungen.
- **DATEIEN:** `app/lib/story/fourteenth_voice_act7.dart`, neuer Test `app/test/rabenwacht_act7_custody_intent_test.dart`, zusätzlicher neutraler README-Nachtrag am Ende, zentrale und persönliche Checkpoints.
- **TESTS ERGÄNZT:** Sechs Flutter-Szenarien: zehn Negativformulierungen und unveränderte Ursprungsdaten, vier explizite Liora-Übergaben, fünf explizite Eigenverwahrungen, gesperrter Übergang ohne Eidseite, Legacy-/JSON-Roundtrip und echte SQLite-Wiederöffnung samt Journalrekonstruktion.
- **GETESTET:** Live-main, Masterprompt, Projektarchitektur und bestehende Akt-VII-Tests, letzte Actions und alle 43 offenen PRs mit relevanten Dateipfaden gesichtet; zwei Fachdateien konfliktfrei geändert und auf eigenem Remote-Branch gesichert. Vorherige grüne CI von PR #628 ist kein Nachweis für #632.
- **NICHT GETESTET/BLOCKIERT:** Vollständige GitHub-Workflow-CI auf endgültigem Dokumentations-HEAD bei Erstellung dieser Notiz offen: Python/Backend, Dart-Format, Flutter-Analyse/-Tests, Android-Debug/ABI und Release. Realgerät, produktiver KI-Provider und Bestandsupgrade ungeprüft.
- **KOMPATIBILITÄT:** Keine JSON-/SQLite-Migration und keine neuen Felder, keine Änderung an App-Version, Spielregel-/Modelldateien oder persistierten Bestandsentscheidungen. README-/Checkpoint-Konflikte nur durch Chat D integrieren, kein automatischer Merge.
- **NÄCHSTER SCHRITT:** Final-HEAD-CI auswerten, Fehler innerhalb des eigenen Branches beheben, nach vollständig grünen Jobs PR zur Review freigeben.



## 2026-11-07 – Ausdrückliche erste Liora-Entscheidung (#636)

- **Ausgangs-main:** `bbe6ee0901f1873af67647bf54462e4a44821762`.
- **Eigener Branch:** `feat/chat-b/liora-square-explicit-intent-20261107`, [PR #636](https://github.com/ManuEtt/Dnd/pull/636) (Draft). Codecommit `e78365af402026ea90774a995cb343e9eb6ea3d9`, Testcommit `64815cfbf1d92d6914d74909a65d0ece12a79166`; finaler Dokumentations-HEAD wird separat geprüft.
- **Ausgangsproblem:** Freie Texte mit bloßen Schlüsselwortfragmenten konnten Liora schützen, beschuldigen oder die Beweissuche festlegen, selbst wenn nur eine Möglichkeit erwähnt wurde. Erneute Eingabe konnte die bereits bestätigte erste NPC-Beziehung nachträglich überschreiben.
- **IMPLEMENTIERT:** Explizite erste Handlung für Schutz/Anschuldigung/Beweissuche nötig; nicht verpflichtende Aussagen bleiben ohne Quest- und NPC-Änderung. Die erste bestätigte Wahl ist gegen widersprechende Wiederholungen geschützt; Ermittlung bleibt über Elda und weitere Spuren möglich.
- **Betroffene Dateien:** `app/lib/story/fourteenth_voice_campaign.dart`, `app/test/rabenwacht_liora_square_explicit_intent_test.dart`, zusätzlich README, `docs/CODEX_CHECKPOINT.md` und dieser Checkpoint.
- **Tests:** Fünf deterministische Flutter-Testgruppen (Fragen, Negation, Bericht, explizite Auswahl, Wiederholung, andere Zeugen, JSON- und SQLite-Wiederaufnahme), positive und negative Fälle. **GETESTET:** Repository-/PR-/SHA-Konfliktprüfung; neue Tests geschrieben. **NICHT GETESTET:** Flutter-Tests/Dart-Format, vollständige Python-/Backend-/Android-CI am finalen Commit; Hardware/Upgrade/Produktiv-KI. Frühere CI ist kein Nachweis für dieses Paket.
- **Aktuelle CI:** [Android-Alpha #42411071998](https://github.com/ManuEtt/Dnd/actions/runs/42411071998) auf Testcommit `64815c` zum Dokumentationszeitpunkt in Bearbeitung. Neue Dokumentation erfordert getrennte finale Prüfung.
- **BLOCKIERT/Koordination:** Kein lokaler Flutter-/Dart-SDK-Zugriff und kein GitHub-DNS-Checkout. Parallel entstandener PR #632 verändert ausschließlich anderes Story-Fachmodul (Akt VII); eigener überlappender PR #635 wurde ohne Merge geschlossen. Gemeinsame README/CODEX-Dateien append-only integrieren.
- **Kompatibilität:** Kein Daten-/Schema-/Versionswechsel, keine Änderung am bestätigten Regelzustand; ältere Kampagnen und ihre bereits gewählten Werte werden unverändert weitergegeben.
- **NÄCHSTER SCHRITT:** Abschließende GitHub-Actions-Jobs für PR #636 am endgültigen Branch-HEAD prüfen und echte Fehler auf diesem Branch beheben, danach Integration koordinieren.



---

## 08.11.2026 – KI-Textvalidierung für unsichtbare Operatoren (PR #643)

- **Ausgangs-main:** `0ce0ad86e9eddf8302e495561d12a889008de49a`; **eigener Branch:** `feat/chat-b/ai-invisible-operators-20261108`; **Draft-PR:** [#643](https://github.com/ManuEtt/Dnd/pull/643).
- **Fachcommit:** `89b87a524e8a358f22c1671c40cd2af51432b454`; **Testcommit:** `4ea6a7e0f9df6d748b10ec40b8cf4ce2b077707d`; erläuternde Kommentarergänzung `3fae4ee48d32665b2067bdcf142b86beee004db7`. Dokumentationscommits folgen separat.
- **Ausgangsproblem:** In `AiStoryPlan.fromJson` und `AiStoryStep.fromJson` gelangten die unsichtbaren Unicode-Operatoren U+2061–U+2064 trotz bisherigem Spoofing-Filter durch die Textprüfung und konnten KI-generierte Hinweise, NPC-Beziehungen oder Questangebote täuschend darstellen.
- **IMPLEMENTIERT:** Der gemeinsame `_unsafeStoryFormatting`-Filter in `app/lib/story/ai_story.dart` sperrt nun den vollständigen Bereich U+2060–U+206F. Zulässiges mehrzeiliges Unicode, Umlaute und Emojis bleiben erhalten.
- **TESTS ERGÄNZT:** `app/test/ai_story_invisible_operator_test.dart` mit vier Gruppen: Plantext einschließlich verschachtelter Threads/NPCs/Orte (negative Fälle), aktualisierte Handlungs-/NPC-Texte (negative Fälle), optionale Abenteuerangebote (negative Fälle), gültige Eingaben mit JSON-Roundtrip und unverändertem Kampagnenzustand (positiver Fall).
- **GETESTET:** Aktuellen Main-HEAD und alle offenen PRs samt Story-Dateipfaden abgeglichen, Quell-/Testcode auf eigenem Branch gesichert, initialen Workflow [#42458390622](https://github.com/ManuEtt/Dnd/actions/runs/42458390622) als **in Arbeit** beobachtet. Weder dessen Ergebnis noch das neueste Branch-HEAD gelten damit als abgenommen.
- **NICHT GETESTET:** Vollständige Dart-Formatierung, Flutter-Analyse/-Tests, Android-APK und alle sechs GitHub-Jobs auf dokumentiertem finalen HEAD; kein physisches Android-Gerät und kein produktiver KI-Anbieter. Lokales Dart/Flutter fehlt, DNS verhindert lokalen GitHub-Checkout.
- **BLOCKIERT:** CI-/Review-Abnahme und koordinierte Integration der geteilten README-/Checkpoint-Anhänge. Die anderen offenen Story-PRs bearbeiten nicht `ai_story.dart` oder den neuen Test.
- **MIGRATION:** Keine. Regeln, Helden, Inventar, Quests, SQLite, JSON-Schema, bestätigte Spielstände und App-Version bleiben unverändert. Nur neu eingehende unbestätigte KI-Texte werden strenger geprüft.
- **NÄCHSTER SCHRITT:** Finale Actions einschließlich Formatcheck und der neuen Regressionen prüfen, ggf. auf diesem Branch korrigieren und anschließend Review durch die Integrationskoordination ohne Auto-Merge.



## 2026-11-09 – NPC-Kurzfassung und eindeutige Notiz-IDs (PR #654)

- **Ausgangs-Main-SHA:** `1cb332437624b9440cf21d338da45aa680578d53`.
- **Eigener Branch:** `fix/chat-b/npc-excerpt-unique-note-ids-20261109`; **Fachcommit:** `cecfb1f6cd5400aa06447767737f3e039833c45b`; **Testcommit:** `36efbc691636c3ba6f673334ea0a56ba7b88daa7`. Finaler Dokumentations-Commit via PR.
- **Pull Request:** [#654](https://github.com/ManuEtt/Dnd/pull/654), Draft bis zur Abnahme.
- **Problem:** Mehrdeutige oder unsichere IDs in einem unvalidierten NPC-Notizverlauf wurden im schreibgeschützten Rückblick als bestätigte Notizen gezeigt; ungültige neue Notizen konnten gültige ältere verdrängen.
- **Implementiert:** `ConfirmedNpcContinuityExcerpt.read` selektiert nur sichere, kampagnenweit eindeutige IDs des explizit ausgewählten NPCs, sortiert nach Zeitstempel und gespeicherter Position und übergeht leere, bereinigte Notiztexte ohne das Limit aufzubrauchen.
- **Geändert:** `app/lib/story/confirmed_npc_continuity_excerpt.dart`, neue `app/test/confirmed_npc_continuity_excerpt_note_id_test.dart` (fünf Tests), append-only `README.md`, `docs/CODEX_CHECKPOINT.md`, dieser Checkpoint.
- **GETESTET:** Main- und offene PRs sowie alle 54 PR-Dateipfade auf Fachkonflikt geprüft; kein paralleler PR verändert die beiden Fach-/Testdateien.
- **NICHT GETESTET:** Fünf Flutter-Regressionen mangels lokalem Flutter/Dart-SDK nicht ausgeführt; [Actions #42560154778](https://github.com/ManuEtt/Dnd/actions/runs/42560154778) zum Zeitpunkt dieses Eintrags im Gange. Kein vollständiger grüner Prüflauf behauptet; keine reale Android- oder produktive KI-Abnahme.
- **Bekannte Fehler/Blocker:** Keine bestätigten Laufzeitfehler; SDK-/Git-DNS-Zugriff lokal nicht verfügbar. Bei CI-Fehlern auf diesem Branch korrigieren; Doc-Anhänge vor Integration verlustfrei konsolidieren.
- **Migrationen:** Keine. Regeln, Kampagnenrevision, Heldendaten, Events, JSON- und SQLite-Schemata, App-Version unverändert.
- **Nächster konkreter Schritt:** Finale PR-Checks und gegebenenfalls Formatter-Tests korrigieren; danach unabhängige Lücke im bestätigten Orts-Wiedereinstieg nach frischem Main-/PR-Abgleich untersuchen.

## 2026-11-09 – Nachtrag zur unabhängigen NPC-Rückblicklücke und Formatkorrektur

- **Paketabgrenzung:** [PR #615](https://github.com/ManuEtt/Dnd/pull/615) filtert unsichere/doppelte Notiz-IDs im allgemeinen NPC-Reader. Eigenständige Aufgabe von [PR #654](https://github.com/ManuEtt/Dnd/pull/654) ist, leere bereinigte Notiztexte **vor** dem kompakten Anzeigelimit auszusortieren und auch jenseits der bisherigen 20 Reader-Einträge nach belegbaren Notizen zu suchen.
- **Sechster Regressionstest:** 24 jüngere, unsichtbare Notizen und ein älterer, sichtbarer Hinweis; die Kurzfassung muss genau den belegbaren Hinweis zeigen. Teständerung `645f0c3a507f97a76bcd1238e16cd1ecafd484fb`.
- **CI-Fehler nachgewiesen:** [#42560261362](https://github.com/ManuEtt/Dnd/actions/runs/42560261362) scheiterte am Dart-Format beider neuen Dateien nach bereits bestandenen Struktur-/Python-/Backend-Schritten; keine Flutter-Tests/Android-Artefakte in diesem Lauf. Exakte Formatter-Korrekturen `3b856557661caac458fcda25e5e49b57f45ac102` und `d716d6a2ba934a04bdb6017fc1745d67858aaa2a`, Diagnoselauf [#42560601010](https://github.com/ManuEtt/Dnd/actions/runs/42560601010) erfolgreich. Temporärer Workflow mit `9bbefd9e9d9be754bbb65ad5a5770943af902399` gelöscht; nicht im finalen Diff.
- **Status:** sechs Tests versioniert, nach vollständigem Format-Fix noch nicht als bestanden nachgewiesen; PR bleibt Draft. Eine neue vollständige CI des letzten Heads muss unabhängig geprüft werden.
- **Migrationen:** Keine Änderungen an Spielstands-/JSON-/SQLite-Schemata, HP, Inventar, Regeln, Queststatus, Revision oder App-Version.
- **Nächster Schritt:** Den finalen CI-Lauf prüfen; bei Fehlschlägen denselben Branch reparieren und Integrationsreview durch Koordination ermöglichen.



## 2026-11-09 – Explizite gespeicherte Ortsauswahl jenseits der Viererübersicht (#658)

- **Ausgangs-Main-SHA:** `b2e1a021067cec39b7c85bdad11aa98477cac14e`.
- **Arbeitsbranch:** `fix/chat-b/place-resume-full-id-match-20261109`, **PR:** [#658](https://github.com/ManuEtt/Dnd/pull/658) (Draft).
- **Fachcommits:** `3dd0373dd25bfa359dd6bd6836291a15cb54bf0f` (volle ID-Prüfung), `8b444c2617b1a8c8d6edc81ed36534f9ce02953a` (explizite Ortswahl), `acdb87bcc6f80ecaf0bddb6ee90df6237867617b` (Vorab-Formatkorrektur). Test-/Zwischenstände `ea7a27d9cf924ba6f0fc647a088d25c49c718b76`, `ceee776a2c61061bb91ac8db43fe2c9d4e8ee9aa` und `eef21b57abbea8ad2328eaa70220486543041f42`. Dokumentations-HEAD über den PR-Branch ermittelbar.
- **IMPLEMENTIERT:** `ConfirmedPlaceResumeSelector.readSelected` greift auf genau eine ausdrückliche gespeicherte Orts-ID auch jenseits der ersten vier zurück, verhindert falsches Zusammenfallen gleichnamiger Orte und prüft vollständige sichere ID, Eindeutigkeit, Revisions-/Sitzungskontext und den gesamten gespeicherten Orts-Quellstempel. Keine frei erfundene Besuchs-/Questbestätigung. Allgemeines `read` mit vollständigem Orts-ID-Treffervergleich.
- **Dateien:** `app/lib/story/confirmed_place_resume_selection.dart`, neuer `app/test/confirmed_place_resume_terminal_id_test.dart` (fünf Tests), `README.md`, `docs/CODEX_CHECKPOINT.md` und dieser persönliche Checkpoint (die letzten drei append-only).
- **GETESTET:** Reale GitHub-Quell-/PR-/Main-Prüfung: 53 offene PR-Dateilisten vor Beginn konfliktfrei hinsichtlich beider Fach-/Testpfade, zwischenzeitlichen Main-Merge #655 berücksichtigt und Branch von neuer SHA erstellt. Kein SDK für Flutter/Dart lokal.
- **NICHT GETESTET:** Neues Flutter-/Dart-/Android-/Backend-/Release-CI noch ohne Ergebnis zum Dokumentationszeitpunkt; physisches Android-Gerät/TalkBack und produktive Signierung nicht geprüft.
- **Blocker/Bekannte Grenzen:** Tests stehen bis zum vollständigen Actions-Lauf noch aus. Der neue reine Story-Selektor stellt eine API bereit; vollständige Endnutzer-UI-Verdrahtung ist nicht Teil dieses Pakets. Dokumentationskonflikte bei parallelen PRs müssen zentral additiv gelöst werden.
- **Migration:** Keine. Spielstände, JSON-/SQLite-Schema, event sourcing, Hero, Quests, Regeln, Provider, Version unverändert.
- **Nächster konkreter Schritt:** GitHub-CI auf der finalen PR-Head-SHA vollständig kontrollieren, Fehlermeldungen beheben und PR erst nach grünem Teststand koordinieren; anschließend eigenständige UI-Anbindung im zuständigen Oberflächen-Track prüfen.




---

## Chat B – verneinte Rückreisen in Rabenwacht respektieren (09.11.2026)

- **Basis-main:** `b2e1a021067cec39b7c85bdad11aa98477cac14e`.
- **Branch:** `fix/chat-b/rabenwacht-negated-travel-20261109`; Draft-PR wird nach Code-/Dokumentationsprüfung angelegt.
- **Ausgangsproblem:** `RabenwachtStoryModule._revisit` kombinierte Reiseverben und Ortsnamen, wertete die Negation aber nicht aus. Ein Satz wie „Ich gehe nicht zurück zur Mühle“ konnte den Helden trotzdem dorthin versetzen.
- **Implementiert:** Bei erkanntem bekannten Ziel plus Negation wird die Bewegung abgelehnt und eine Klarstellung erbeten. Positiv formulierte Rückreisen bleiben erhalten.
- **Tests:** drei neue Regressionen für negierte Rückreise, positive Rückreise und negierte Ortsnennung ohne Reisebefehl. Prüfen Etappe, Ort, Szene und Heldenwerte.
- **Dateien:** `app/lib/story/rabenwacht_campaign.dart`, `app/test/rabenwacht_negated_revisit_test.dart`, README und zentrale/persönliche Checkpoints (jeweils nur Nachtrag am Ende).
- **Kompatibilität:** keine Migration, keine Regel-/XP-/HP-/Quest-/Ressourcenänderung, kein Schema-/Versions-/Providerwechsel.
- **Konfliktprüfung:** 53 offene PRs einschließlich ihrer geänderten Dateien geprüft; keine Überschneidung mit den beiden Fach-/Testdateien.
- **GETESTET:** Änderungen auf eigenem Branch gesichert. **NICHT GETESTET:** lokaler Dart-/Flutter-Test mangels SDK, GitHub-CI auf finalem HEAD, Android-Gerät/produktive KI.
- **Nächster Schritt:** finale vollständige PR-CI abnehmen, rote Schritte auf demselben Branch korrigieren, anschließend an Chat D zur koordinierten Integration übergeben.




---

## Chat B – Rabenwacht: verneinte Rückreisen (09.11.2026)

- **Aktuelle Basis-main:** `f848cedef7787e2e89df7b63d93d04dfb06ed8ed`.
- **Branch:** `fix/chat-b/rabenwacht-negated-travel-main-sync-20261109`.
- **Problem:** `RabenwachtStoryModule._revisit` konnte eine Reise zu einem bekannten Ort ausführen, obwohl die Eingabe die Bewegung verneinte.
- **Änderung:** Negierte Bewegung zu einem bekannten Ziel wird abgelehnt; die Story bleibt am bisherigen Ort und bittet um eine eindeutige Formulierung. Positive Rückreisen bleiben möglich.
- **Tests:** drei Regressionen (negierte Rückreise, positive Rückreise, negierte Ortsnennung ohne Reisebefehl).
- **Dateien:** `app/lib/story/rabenwacht_campaign.dart`, `app/test/rabenwacht_negated_revisit_test.dart`, README und zentrale/persönliche Checkpoints (nur append-only).
- **Kompatibilität:** keine Migration oder Änderungen an Regeln, Spielständen, HP/XP, Ressourcen, Quests oder Providervertrag.
- **Integrationskorrektur:** Der frühere PR-Branch war gegenüber main um 27 Commits zurückgefallen. Da main nur die drei Dokumentationspfade verändert hatte, wurde der kleine Fachpatch samt Test auf aktuellem main neu aufgebaut und die Doku-Nachträge wurden dort neu angehängt.
- **GETESTET:** Änderungen auf aktuellem main versioniert. **NICHT GETESTET:** lokaler Dart-/Flutter-Lauf, vollständige GitHub-CI, Android-Gerät/produktive KI.
- **Nächster Schritt:** PR-CI vollständig abnehmen und erst danach zur koordinierten Integration übergeben.




### 2026-11-10 – Negierte Rabenwacht-Rückreisen auf aktuellem main

- **Main-Basis:** `73f377ece91cb14a5074ddba16fbbc57b153026e`.
- **Branch:** `fix/chat-b/rabenwacht-negated-revisit-main-20261110`; vorheriger Draft-PR #666 auf älterer Basis `f848cedef7787e2e89df7b63d93d04dfb06ed8ed`.
- **Änderungen:** `app/lib/story/rabenwacht_campaign.dart`, neuer Regressionstest `app/test/rabenwacht_negated_revisit_test.dart`; README und Checkpoints ausschließlich am Ende ergänzt.
- **Verhalten:** Negierte Ortsrückreise wird nicht ausgeführt; affirmative Rückreise funktioniert. Drei Regressionstests.
- **Tests:** CI #42701756432 auf altem Branch 6/6 erfolgreich; neue Basis noch nicht getestet. Keine lokale Flutter-/Android-Abnahme.
- **Kompatibilität:** Keine Schema-, JSON-, SQLite-, Spielregel-, Kampf- oder Ressourcenänderung; keine Migration.
- **Nächster Schritt:** PR für neuen Branch und vollständige CI; alten Draft-PR #666 nicht versehentlich parallel integrieren; Chat D koordiniert Merge.




### 2026-11-10 – StoryRuleBoundary-Regression

- Eigenständiger Test-Branch `test/chat-b/story-rule-boundary-regression-20261110` vom aktuellen `main` `5fa4037450c955f9dd393472239e7b5de1aa7fc3`.
- Neuer Test `app/test/story_rule_boundary_regression_test.dart`: Erzähländerung zulässig; Fakten-/Kampagnenidentitätsänderung abgelehnt; identischer Zustand zulässig.
- Produktionscode bleibt unverändert; neue GitHub-CI erforderlich. Keine Überschneidung mit offenen Chat-B-Storymodul-Änderungen.



- 2026-11-10: Rabenwacht-Reiseabsicht gegen Wortteil-Treffer (Vorgehen/Reisebericht/Besuchereintrag) abgesichert; zwei Regressionstests ergänzt. Branch `fix/chat-b/rabenwacht-travel-verb-boundaries-20261110`; CI ausstehend.

- 2026-11-11: Regression nach CI-Fehler #42957164227 differenziert: bloße Ortsnennung bleibt; aktiver Kapellenuntersuchungsbefehl führt regelkonform zum Archiv. Commit `b9836aecd8507cf0af96685643cc6e28801d988f`. Verlustfreie Integration inklusive ursprünglichem Branch als Merge-Vorfahre auf eigenem Integrationsbranch; erneute vollständige CI erforderlich.



### 2026-11-11 – Eindeutige Epilog-Vermächtniswahl (PR #694)

- **IMPLEMENTIERT:** Die Dorfzukunft bestätigt ein Vermächtnis nur bei einem vollständigen, einzelnen Spielerbefehl. Zitate, Fragen, Alternativenvergleiche und Verneinungen lösen keinen Abschluss aus. Kurzbefehle und ausdrückliche Ich-/Wir-Wünsche funktionieren. Der Regelzustand wird nicht verändert.
- **Ausgangs-main:** `e8a4c18026f24d801c33d7c6d8d87e6d7dad0930`; vor PR-Erstellung war `main` bereits auf `436ce018f672933ce6782119a5afaac694bbe888` weitergelaufen. **Branch:** `fix/chat-b/epilogue-explicit-legacy-choice-20261111`; **PR:** https://github.com/ManuEtt/Dnd/pull/694 (Draft). Fach- und Testcommits auf dem Branch; finaler HEAD und Actions-Status über den PR prüfen.
- **Dateien:** `app/lib/story/fourteenth_voice_epilogue.dart`, `app/test/rabenwacht_epilogue_explicit_legacy_choice_test.dart` sowie additive Projekt-Checkpoints und README-Nachtrag.
- **GETESTET:** Live-Code, PR- und betroffene Dateipfade, Basisrevision und bestehende Epilog-Regressionen überprüft; keine parallelen Änderungen am Epilog-Modul in offenen PRs gefunden.
- **NICHT GETESTET:** Flutter-Unit-/Integrationstests, Dart-Format/Analyse, Android-Build und reales Gerät; das Flutter-/Dart-SDK steht in dieser lokalen Laufzeit nicht zur Verfügung. Neue GitHub-CI ist gesondert zu prüfen.
- **Akzeptanztests (ergänzt, noch nicht ausgeführt):** drei eindeutige positive Vermächtnisse, ausdrückliche Ich-/Wir-Varianten, negative Fragen/Zitate/Mehrdeutigkeiten, Legacy-JSON-Roundtrip und idempotente Wiederaufnahme, fehlende Zeugen und bestehender Abschluss.
- **BLOCKIERT:** Vollständige CI-Abnahme und Review/Integration der gemeinsamen Dokumentationsnachträge durch Chat D. Keine Verbindung zu externem KI-Provider nötig.
- **Kompatibilität:** Keine Änderung von SQLite/JSON-Schema, API, Regeln, Questidentitäten, Heldenwerten, Revision oder App-Version. Bestehende bestätigte Wahl bleibt unverändert.
- **NOCH NICHT IMPLEMENTIERT:** Weitere Absicherung der Rückkehr- und Versammlungsintents außerhalb der endgültigen Vermächtniswahl.
- **NÄCHSTER SCHRITT:** PR-CI am finalen Commit prüfen, eventuelle Format- oder Testfehler auf demselben Branch beheben; danach kontrollierte Integration durch Chat D.

### 2026-11-12 – Story-/Regelgrenze gegen Revisionssprünge schützen (PR #700)

- **Ausgangs-main:** `31607a6eb0924970aa4d6d1869ab65352e808787`; **Branch:** `fix/chat-b/story-revision-boundary-20261112`; **Pull Request:** [#700](https://github.com/ManuEtt/Dnd/pull/700) (Draft). **App-Version:** `0.8.52+102`, unverändert. **Fachcommits:** `aa4b2409`, `d3392032`, `d3a4128c`; finalen Dokumentations-HEAD im PR prüfen.
- **IMPLEMENTIERT:** `StoryRuleBoundary.ensureRuleStateUnchanged` lässt für eine Erzählerersetzung nur die bisherige Revision und für einen regulären bestätigten Story-Commit höchstens eine zusätzliche Revision zu. Negative Sprünge, Rückschritte und ausgelassene Revisionen werden abgewiesen. Sonstige Regelgrenzen bleiben unverändert.
- **Geänderte Dateien:** `app/lib/story/story_rule_boundary.dart` und neuer `app/test/story_revision_boundary_test.dart`; append-only README, zentraler sowie eigener Checkpoint.
- **Akzeptanztests:** fünf Testgruppen, positive unveränderte/+1 Revision, negative Rollbacks und übersprungene Revisionen, bestehende verbotene HP-Änderungen, eingebundene `StoryCampaignEngine`-Commit-Callbacks sowie Legacy-JSON-Import/Wiederaufnahme.
- **GETESTET:** GitHub-Main-Stand, 69 offene PRs und die betroffenen Fach-/Testdateien auf Konflikte geprüft; PR #680 testet andere Fälle, PR #694 betrifft das unabhängige Epilogmodul.
- **NICHT GETESTET:** Lokale Dart-/Flutter-Prüfungen und Android-Builds mangels SDK; neue CI auf finalem PR-HEAD nach Dokumentationscommit noch gesondert abzunehmen.
- **BLOCKIERT:** Vollständige CI-/Android-Abnahme und koordinierte Integration der gemeinsam geänderten README-/Checkpoint-Dateien durch den Integrationstrack.
- **NOCH NICHT IMPLEMENTIERT:** Über die Revisionsgrenze hinausgehende abgesicherte Historien-/Event-Semantik der Story-Schnittstelle ist getrennt zu untersuchen.
- **Kompatibilität/Migration:** Kein SQLite- oder JSON-Schemawechsel, keine Änderungen an Spielständen, API, Regelwerten oder Kostenfreigabe. Bereits gespeicherte Revisionen werden nicht verändert.
- **NÄCHSTER SCHRITT:** Finalen CI-Lauf #700 auf tatsächlichem Branch-HEAD prüfen, auftretende Fehler im selben Branch beheben und anschließend nach Review integrieren.

### 2026-11-12 – Bestätigte Ereignishistorie bei Story-Commits schützen (PR #703)

- **Ausgangs-main:** `f028a6f3bce7649bd07b9bb2eeca83214bfff7b8` nach der 86-Branch-Migration; **Branch:** `fix/chat-b/story-event-history-append-only-20261112`; **Pull Request:** [#703](https://github.com/ManuEtt/Dnd/pull/703) (Draft); **App-Version:** `0.8.52+102`, unverändert. Fach-/Testcommits `3a4d51b` und `814623e`, Format-/Klarstellungscommit `492d43b`; endgültigen Dokumentations-HEAD im PR prüfen.
- **Ausgangsproblem:** Das Story-Commit-Callback durfte trotz unveränderter Regelwerte ein beliebig ersetztes `events`-Journal zurückgeben, weil `events` ein zulässiges Storyfeld der Regelgrenze ist.
- **IMPLEMENTIERT:** `StoryCampaignEngine._commitStory` prüft nach dem Regelzustandsschutz den unveränderten kanonischen JSON-Präfix bereits bestätigter Ereignisse und erlaubt höchstens einen neuen Eintrag. Dieser muss eine neue ID, korrekte Kampagnen-/Session-ID, exakte Rückmeldung in `GameUpdate.events` und den passenden `stateAfter`-Checkpoint besitzen. Keine Verdoppelung oder stille Umschreibung älterer Einträge. Journalfreie bestehende Test-/Preview-Callbacks bleiben kompatibel, solange die Historie erhalten ist.
- **Dateien:** `app/lib/story/story_campaign_engine.dart`, neuer `app/test/story_event_history_append_only_test.dart`, README und beide Checkpoints nur append-only.
- **Regressionen:** Fünf Testgruppen für gültigen Commit und JSON-Roundtrip, Löschen/Umordnen/Überschreiben/zusätzlichen Append, widersprüchliche IDs, Sessions und Checkpoints, semantisch gleiche JSON-Schlüsselreihenfolge sowie journalfreie Bestands-Callbacks.
- **GETESTET:** Aktueller Main-HEAD und sämtliche geöffneten PRs/Dateipfade auf Überschneidungen geprüft. PR #702 bearbeitet nur den unabhängigen Revisionsschutz, nicht `story_campaign_engine.dart` oder diese Testdatei. Neu erstellte Tests und Commits auf GitHub gesichert.
- **NICHT GETESTET:** Flutter-Tests, Analyzer, Dart-Formatierung und Android-Builds des finalen Commits noch durch CI abzunehmen; lokale Flutter-/Dart-SDKs fehlen. Kein reales Android-Gerät und kein produktiver KI-Provider geprüft.
- **BLOCKIERT:** Finale unabhängige PR-CI, Review/Integration nach #702 und eventuell verlustfreie README-/Checkpoint-Zusammenführung. Kein direkter Main-Merge.
- **Kompatibilität/Migration:** Keine Schema-, SQLite-, Versions- oder API-Änderungen; gespeicherte Kampagnen bleiben unverändert, bisherige `replaceNarration`-/KI-Freeturn-Rewrite-Wege bleiben unangetastet. Keine neuen Kosten.
- **NOCH NICHT IMPLEMENTIERT:** Die Identitäts- und Nachrichtenhistorie außerhalb regulärer `_commitStory`-Callbacks benötigt bei zukünftigen KI-Pfaden eigene Nachweise.
- **NÄCHSTER SCHRITT:** Vollständige GitHub-CI auf finalem HEAD abnehmen, konkrete Fehler auf demselben Branch beheben, nach erfolgreicher Abnahme zur Review freigeben.

### 2026-11-12 – Bestätigte Dialoghistorie an der Story-Commit-Grenze absichern (PR #706)

- **Ausgangs-main:** `32d1ffac6f022af65550cd02895e9915816e0f34`, grüne main-CI [#43185323211](https://github.com/ManuEtt/Dnd/actions/runs/43185323211); **Branch:** `fix/chat-b/story-message-history-append-only-20261112`; **PR:** [#706](https://github.com/ManuEtt/Dnd/pull/706) (Draft); Version `0.8.52+102`. Fach-/Testcommits `86bf0c94` und `4c0365df`; finalen Dokumentations-HEAD und CI im PR prüfen.
- **Ausgangsproblem:** Die bereits geschützte Ereignishistorie verhindert nicht, dass ein fehlerhaftes Story-Commit-Callback früher bestätigte Spieler- und Spielleiter-Nachrichten im `messages`-Array umschreibt, umsortiert oder entfernt.
- **IMPLEMENTIERT:** `StoryCampaignEngine._commitStory` prüft nach den bestehenden Regel- und Ereignisgrenzen alle vorherigen Nachrichten kanonisch auf unveränderten Inhalt und Reihenfolge. Höchstens eine neue Nachricht ist erlaubt, ausschließlich vom Spielleiter, mit neuer ID und exakt dem übergebenen bestätigten Erzähltext. Ein Callback ohne neuen Eintrag bleibt für ältere Preview-/Mock-Verträge zulässig. Die gesonderten, bereits geprüften Freeturn-Rewrites werden nicht verändert.
- **Dateien:** `app/lib/story/story_campaign_engine.dart`, neuer `app/test/story_message_history_append_only_test.dart`, plus additive README und zwei Checkpoints.
- **Akzeptanztests:** Fünf Testgruppen zu Normal-Commit inkl. JSON-Roundtrip, alten Textänderungen/Trunkierung/Umsortierung/Einschub, falscher neuer Nachricht (ID/Rolle/Text), Legacy-Preview-Callbacks und gültigem unbestätigten Narration-Rewrite.
- **GETESTET:** Main-HEAD, Masterprompt, Fachcode, bestehende Testverträge und offene PR-Dateipfade geprüft. Vorheriger PR #703 vollständig erfolgreich auf `411601b7dcb40d696257cab4af7309d70f60d781` in [CI #43176604693](https://github.com/ManuEtt/Dnd/actions/runs/43176604693), danach in main integriert. Dieser ältere Lauf ist **kein Testnachweis für #706**.
- **NICHT GETESTET:** Neue Flutter-Unit-/Integrationstests, Dart-Format, Flutter-Analyse, Android-Builds/APKs und Realgerät für #706 stehen bis zum neuen CI-Ergebnis aus.
- **BLOCKIERT:** Vollständige GitHub-CI auf finalem PR-HEAD, danach Review; keine lokalen Dart-/Flutter-SDKs. Offene PRs #704/#705 ändern ausschließlich fachfremde Tests und nicht die eigenen Story-Dateien.
- **Kompatibilität/Migration:** Keine JSON-/SQLite-Schemaänderung, keine API- oder Versionsanhebung, keine Modifikation gespeicherter Kampagnen oder Regelwerte, keine KI-Kostenänderung.
- **NOCH NICHT IMPLEMENTIERT:** Weitere unabhängige Schutzregeln für freiformulierte KI-Turns außerhalb dieses Story-Commit-Callbacks sind getrennt zu prüfen.
- **NÄCHSTER SCHRITT:** Finale CI #706 vollständig auf exaktem Commit abnehmen, Fehler im selben Branch korrigieren und erst nach Grün zur Review freigeben.

### 2026-11-13 – Bestätigten NPC-Kontext an gültige Sitzung binden (PR #734)

- **Ausgangs-main:** `184d93c2139b35cfbd4943da201ecef2f7e20dc7`; **Branch:** `fix/chat-b/npc-identity-session-guard-20261113`; **PR:** https://github.com/ManuEtt/Dnd/pull/734 (Draft); **App-Version:** `0.8.52+102` unverändert.
- **Ausgangsproblem:** `NpcIdentityMemory.read` lieferte einen bestätigten, typisierten NPC-Kontext auch bei leerer/Whitespace-Sitzungskennung und unbegrenzten großen Revisionen. Andere Wiederaufnahmereader prüfen diese Grenzen bereits.
- **IMPLEMENTIERT:** Bei fehlender Sitzungsidentität oder Revision außerhalb 0–2147483647 wird fail-closed mit `FormatException` abgebrochen. Gültige Daten bleiben unverändert.
- **Dateien:** `app/lib/story/npc_identity_memory.dart`, `app/test/npc_identity_session_bounds_test.dart`; append-only README und beide Checkpoints.
- **Akzeptanzkriterien:** Ungültige Sitzungskennungen und Revisionen zurückweisen; gültiger JSON-Roundtrip, Stale-Session-Erkennung und gültige Maximalrevision weiterhin zulassen; kein Rule-/Savegame-Write.
- **GETESTET:** Live-main, offene PRs einschließlich deren geänderte Story-Dateien, tatsächliche Modell-/Story-Verträge und Quellcode manuell geprüft. Fachänderung und drei neue Testfälle auf Branch committet. Ausgangs-PR-Head vor Doku `81f6396705c21675157bc3ba073a72404af588db`.
- **NICHT GETESTET:** Flutter-Unit-Tests, Dart-Format, `flutter analyze`, Python-/Backend-Prüfungen und Android-Debug-Build lokal nicht verfügbar (kein Flutter-/Dart-SDK; kein lokaler Repository-Clone wegen Netzwerkgrenze). Finale PR-CI steht aus.
- **BLOCKIERT:** CI-/Android-Abnahme des finalen Commit-SHA und koordinierter, verlustfreier Merge aller README-/Checkpoint-Nachträge. PR bleibt Draft.
- **Migration:** Keine. JSON-Schema 1, SQLite, Spielstandwerte, Ressourcen, Regeln und Provider-Verträge unverändert.
- **NOCH NICHT IMPLEMENTIERT:** Keine Änderungen an Story-Rückblicken anderer Module; Session-ID-Validierung dieser anderen Pfade ist ein getrenntes Paket.
- **NÄCHSTER SCHRITT:** PR #734 auf finalem Commit in GitHub Actions vollständig prüfen; bei roten Dart-/Flutter-Tests im eigenen Branch korrigieren und erst nach Grün durch Integrationstrack reviewen/mergen lassen.

### 2026-11-13 – Explizite Wiederaufnahme eines gespeicherten NPCs (PR #739)

- **Ausgangs-main:** `184d93c2139b35cfbd4943da201ecef2f7e20dc7`; **Branch:** `feat/chat-b/explicit-npc-resume-20261113`; **Pull Request:** [#739](https://github.com/ManuEtt/Dnd/pull/739) (anfangs Draft), Version unverändert `0.8.52+102`. Fachcommit `23429e3d73c339c4a730bc64f7da17e24905a11e`; Testcommit `b194a54717ee3ebc908596506eba7c5c1e79467d`; finalen Dokumentations-Head auf GitHub prüfen.
- **Ausgangsproblem:** Der read-only NPC-Rückblick wählt maximal drei Personen mit jüngsten Notizen. Ältere, ausdrücklich gewählte NPCs außerhalb dieses Fensters und bereits gespeicherte NPCs ohne Notizhistorie hatten keine ID-basierte Auswahl.
- **IMPLEMENTIERT:** Neue `ConfirmedNpcResumeSelector.readSelected` für genau eine, eindeutig gespeicherte und vollständig kanonische NPC-ID. Die Auswahl benötigt eine gültige Kampagne, nichtleere Sitzung, exakte Revision, 1–3 Notizen als Obergrenze; sie erfindet bei leerer Historie keine Fakten, entfernt uneindeutige Notizidentitäten aus dem Kontext, sortiert bestätigte Notizen deterministisch und nutzt den unveränderten vollständigen Rohstempel über NPCs/Notizen zur Revalidierung.
- **Dateien:** `app/lib/story/confirmed_npc_resume_selection.dart`, neuer `app/test/confirmed_npc_resume_explicit_selection_test.dart`, README und beide append-only Checkpoints.
- **Akzeptanztests:** Sechs Testgruppen zu älteren gleichnamigen NPCs außerhalb des Top-drei-Fensters, gespeicherten NPCs ohne Notizen, ungültigen/doppelten Identitäten, kollidierenden Notiz-IDs und Unicode, veralteten Revisionen/Sitzungen/Historien sowie JSON-/SQLite-Roundtrip.
- **GETESTET:** Haupt-HEAD, bisherige Fachtests und 28 offene PR-Metadaten auf eigene Story-Fileüberschneidung geprüft; keine offene Fachänderung an diesen neuen Dateipfaden festgestellt. Änderungen auf eigenem Branch gepusht.
- **NICHT GETESTET:** Neue Dart-/Flutter-Tests, Dart-Formatierung, Analyzer, Python-/Backend-Checks und Android-Build/APK auf finalem Branch-HEAD sind vor der GitHub-CI-Auswertung noch nicht bestätigt. Lokales Dart-/Flutter-SDK fehlt.
- **BLOCKIERT:** CI auf finalem Commit, anschließendes Review und verlustfreie Zusammenführung der gemeinsam verwendeten README-/Checkpoint-Dateien durch den Integrationstrack.
- **Kompatibilität/Migration:** Nur lesende NPC-Projektion; unveränderte JSON-/SQLite-Schemata, keine Migrationsarbeiten, keine Regelzustands-/Kostenfreigabe-Änderungen, keine Speicherwrites.
- **NOCH NICHT IMPLEMENTIERT:** Direkte Android-UI-Auswahl historischer NPCs und ID-basierter Erzählertransport; getrennte künftige Funktionspakete.
- **NÄCHSTER SCHRITT:** CI/Flutter-Tests für PR #739 auf exaktem finalen HEAD prüfen, konkrete Fehler auf demselben Branch beheben und erst nach vollständiger grüner CI zur koordinierten Integration freigeben.

### 2026-11-13 – Koordinierter Integrationsstand NPC-Sitzungsgrenze und bestätigte ID-Auswahl

- Beide unabhängigen NPC-Pakete aus PR #734 (`4c0e61cd647009742d1125652513de7529f2d1f5`) und PR #739 (`d3240ca001c31ee47c0216a76e29a6f1b6429c26`) in einem Integrationsbranch ohne Überschreiben der ursprünglichen Fachdateien verbunden.
- `npc_identity_memory.dart` lehnt Sitzungsgrenzen ohne gültige Sitzung oder mit ungültiger Revision ab; `confirmed_npc_resume_selection.dart` erlaubt gezielte Wiederaufnahme gespeicherter NPCs per verifizierter ID.
- Alle individuellen README-/zentralen/persönlichen Checkpoints append-only erhalten. Beide Quell-CIs vollständig grün; kombinierte CI auf neuem Branch zur separaten Abnahme ausstehend.
- Keine Spielstandmigration, Schemaänderung, SRD-Regeländerung oder neue KI-Kosten. Nächster Schritt: volle Integrations-CI und danach geschützter Merge.
