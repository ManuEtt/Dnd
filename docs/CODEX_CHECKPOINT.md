# 28.10.2026 – Gemeinsame Branch-Migration / 0.8.46+96

Arbeitsbranch `integration/all-branches-20261028`; Ausgangs-Main `dd0c2e94`, inzwischen Main `f9d68a97` enthalten. Alle 26 ursprünglichen Nebenbranch-Köpfe plus ein paralleler Integrationsbranch sind Vorfahren. Originale vorab in geprüftem Bundle gesichert. **Kein Branch wurde von diesem Durchlauf vor der gemeinsamen Abnahme gelöscht.**

**IMPLEMENTIERT:** Charakterpakete #297/#317/#319/#324/#330, Klassenmechaniken #313/#332/#336/#339/#340, Story-/Material-/Sprunghistorien, geschützte Bereinigung und Importgrenzen/Buttonsemantik gemeinsam integriert. Altarchiv-CAS tatsächlich reproduziert und korrigiert; Barden-Dialog bei großer Schrift repariert. **GETESTET:** Teilpakete und Legacy-SQLite-Regressionen; gemeinsame Vollsuite auf korrigiertem Stand läuft anschließend. Früher Vollversuch `300f7be` mit143 bewusst ersetzt, kein voller Erfolg. **NICHT GETESTET:** finale Gesamt-PR-/Main-CI und Android-Build bis zum tatsächlichen Nachweis; reale Geräteabnahme/Produktivsignierung offen. **BLOCKIERT:** kein reales Gerät. **NOCH NICHT IMPLEMENTIERT:** vollständiger Wizard/SRD; Talent- und Würfelbelege werden nicht als vollständige Wirkungsautomatik ausgegeben.

SQLite3 / Kampagnen-JSON1 unverändert. Hauptbericht und konkrete Wiederaufnahme: [BRANCH_MIGRATION_20261028.md](BRANCH_MIGRATION_20261028.md). Logs/Quell-ZIPs/Patches/Bundle: `/workspace/artifacts/branch-migration-20261028/` und `/workspace/validation/20261028-migration-*`. Finalen Commit und CI-Status am tatsächlichen PR prüfen; ältere Einträge darunter sind historische Momentaufnahmen.

**Genau nächster Schritt:** korrigierte gemeinsame Suite und Android/native Prüfungen abschließen, finalen eigenen PR prüfen und regulär nach Main mergen, Main-CI abwarten, dann nur archivierte unveränderte enthaltene Nebenbranches löschen. Danach explizite Kleriker-/Paladin-Symbolwahl im vorhandenen Assistenten ergänzen.

---

## 27.10.2026 – Chat B: Replay an bestätigte Sitzungsidentität binden

- **Ausgangs-main:** `96001353f2b90f293fbdade934e78b7b8281e965`; **Branch:** `fix/chat-b/story-replay-session-identity-20261027`. Dieser Eintrag betrifft ausschließlich die Story-Replay-Funktion und ihre Regressionen.
- **IMPLEMENTIERT:** Neue Ereignisse fremder Sitzungen und Checkpoints mit abweichender `sessionId` werden vor Replay-Übernahme zurückgewiesen. Exakt bereits gespeicherte Dubletten früherer Sitzungen bleiben idempotent; normale Wiederherstellung und Heldendaten bleiben erhalten.
- **GETESTET:** Code-/PR-Pfadprüfung anhand der echten GitHub-Quellen; **noch keine erfolgreich ausgeführte neue Flutter-Regression behauptet**.
- **NICHT GETESTET:** lokale Flutter-, Backend-, Python-Gesamtsuite, Android-Build und echtes Gerät. Die GitHub-CI auf finalem Branch-HEAD ist separat abzunehmen.
- **BLOCKIERT:** kein lokal erreichbarer Git-Checkout (GitHub-DNS), kein Flutter-/Dart-SDK. GitHub-Connector besitzt Schreibrechte; PR/Actions werden gesondert geprüft.
- **NOCH NICHT IMPLEMENTIERT:** eine allgemeine signierte Event-Provenienz oder neue persistierte Sitzungsübergangsereignisse; diese gehören nicht zu diesem Paket.
- **Dateien:** `app/lib/story/story_memory_engine.dart`, `app/test/story_replay_session_boundary_test.dart`, `docs/STORY_REPLAY_SESSION_IDENTITY_20261027.md`, README und Checkpoints.
- **Migration:** keine; Flutter-Version 0.8.42+92 und Kampagnen-JSON-Version 1 unverändert. Kein Eingriff in KI-Regelgrenzen.
- **Nächster Schritt:** CI-Abnahme der vier Regressionen auf finalem PR-HEAD; nur bei grünem Format/Analyze/Flutter/Android-Gate den PR zur Integration durch Chat D freigeben. [Technische Details](STORY_REPLAY_SESSION_IDENTITY_20261027.md).

---

# Chat B – NPC-Identitäten in Sitzungsrückblicken trennen (27.10.2026)

- **Ausgangs-Main:** `ff245cc253194cd0858385d535ae7b2c9132bb06`; **Arbeitsbranch:** `feat/chat-b/session-recap-npc-identity-20261027`.
- **AUSGANGSPROBLEM:** `MemoryEngine.retrieve` kennt die Unterscheidung über gespeicherte NPC-IDs schon, `buildSessionSummary` speicherte dagegen zwei gleichnamige Figuren ohne identifizierenden Verweis. Ihr Beziehungsstand konnte beim späteren Rückblick verwechselt werden.
- **IMPLEMENTIERT:** `app/lib/story/story_memory_engine.dart`: beim Aufbau der bestätigten Sitzungszusammenfassung Anzeigenamen normalisiert zählen; bei Namensgleichheit die tatsächliche NPC-ID ergänzen, bei eindeutigem Namen das historische Format bewahren. Mehrdeutige doppelte gespeicherte IDs werden in diesem Rückblick nicht als bestätigt ausgegeben. Der 2.400-Code-Unit-Rückblickgrenzwert bleibt gleich.
- **TESTS HINZUGEFÜGT:** `app/test/session_recap_npc_identity_test.dart`: identische Namen und Beziehungen; eindeutige Namen und altes JSON ohne optionale Notizen; duplizierte historische IDs; echte `GameEngine.saveSessionRecap`-Aufzeichnung und Kampagnen-JSON-Roundtrip ohne Heldenmutation.
- **BEREITS GETESTET:** Quellcode und offene PR-Dateipfade abgeglichen; beide geänderten Dart-Dateien exakt nach offiziellem Dart-3.9.2-Formatter formatiert; temporärer Diagnoseworkflow wieder entfernt. **Vollständige CI auf finalem PR-HEAD erst nach tatsächlichem Abschluss als bestanden ausweisen.**
- **NICHT GETESTET:** lokale Flutter-/Android-Ausführung (kein Flutter-/Dart-/Android-SDK in dieser Sitzung), Realgerät, Produktiv-KI und alte installierte Datenbank; GitHub-CI zu diesem Commit muss noch bestätigt werden.
- **BLOCKIERT:** Fachliche Freigabe erst nach grüner CI; gemeinsame Dokumentation mit weiteren offenen PRs durch Chat D zusammenführen. Nach Analyse wurde parallel ein Branch zur Eindeutigkeit der NPC-Notiz-IDs entdeckt; dieses Paket ändert bewusst weder dessen Modul noch seine Testdateien.
- **KEINE MIGRATION:** unverändertes Kampagnen-JSON und SQLite, keine SRD-/Backend-/Provideränderung, keine Änderung an bestätigten Regelzuständen.
- **NOCH NICHT IMPLEMENTIERT:** Allgemeine NPC-Synonymauflösung und semantisches Sprachverständnis; für dieses kleine Paket ausdrücklich außerhalb des Umfangs.
- **NÄCHSTER SCHRITT:** Prüfen, dass ein gespeicherter Sitzungsrückblick bei extrem langen NPC-Namen seine unterscheidende ID nicht abschneidet; positives und negatives Grenztestszenario auf eigenem Branch.

---

## 27.10.2026 – Chat D D-013: sichere APK-ZIP-Metadaten vor Alpha-Bündelung

**Basis:** `main` `f9b2f72a4bf8e4216bf8baac60c7f92c4a8a997f`; Arbeitsbranch `fix/chat-d/alpha-apk-zipbomb-guard-20261027`; Produkt Würfelraunen `0.8.42+92`, SQLite 2 / Kampagnen-JSON 1.

- **IMPLEMENTIERT:** `scripts/prepare_alpha_release.py` begrenzt ARM64-APK auf 512 MiB Datei-/1 GiB deklarierte entpackte Größe, 20.000 Mitglieder und 1000:1 Expansion einzelner großer ZIP-Mitglieder **vor** CRC-/Pflichtbibliotheksprüfung. Vorhandene Dateipfad-, Link-, Duplikat- und Integritätschecks bleiben erhalten.
- **REGRESSIONEN:** Vier negative Checks in `scripts/tests/test_prepare_alpha_release.py` für Größen-, Expansions- und Mitgliederlimits; unveränderte normale Alpha-Release-Fälle.
- **GETESTET:** Vorgänger D-012 PR #258 erfolgreich 36/36 auf SHA `45bfe793ab88db689d23355c832d7343753ddc18`, [Workflow](https://github.com/ManuEtt/Dnd/actions/runs/40391878647); seitdem nach Main gemergt. **Das ist kein Testbeleg für D-013.**
- **NICHT GETESTET:** Neue vollständige CI/Android-APK auf dem finalen D-013-PR-HEAD, reale Android-Hardware, Signierung und Speicher-Upgradepfade.
- **BLOCKIERT:** Lokaler Checkout über GitHub-DNS nicht möglich; gemeinsame README-/Checkpoint-Nachträge bei späterer paralleler Integration sorgfältig erhalten.
- **NOCH NICHT IMPLEMENTIERT:** Kein neuer Produktumfang – Qualitätskorrektur. Nächster konkreter Schritt: vollständige GitHub-CI, neue Main-/PR-Kollisionen, reviewfähiger PR nach Nachweis.
- **Kein Migrationsbedarf:** App- und Persistenzformate unverändert; kein Regel-/Story-/KI-Eingriff.

Details unter [Chat-D-Checkpoint](parallel/CHAT_D_CHECKPOINT.md).

---

# Charaktererstellung – gemeinsamer Stufe-1-Startprüfer (27.10.2026)

- **Repository-Basis:** `main` `ff245cc253194cd0858385d535ae7b2c9132bb06`; Branch `feat/character-start-values-all-classes-20261027`.
- **Beobachtete Lücke:** `SrdClassSelectionDialog` erzwang valide Start-TP/Starterkit bisher nur beim Kämpfer. Elf andere Klassen konnten die Klassenwahl ohne den betreffenden Startzustand übernehmen.
- **Implementiert:** eigene regelnahe `SrdFirstClassStartValidation`, UI-Sperre für sämtliche zwölf Neucharakterklassen, erzwungene bestätigte Start-TP-Übernahme und ausdrückliche Ausrüstung/Goldwahl. Bestehende Charaktere unverändert; Fighter-Sonderwahlen weiterhin verpflichtend.
- **Tests:** `app/test/srd_first_class_start_validation_test.dart` (alle Klassen, ungültige Werte, Mehrfachvergabe und Altcharakter) und ergänzter Waldläufer-End-to-End-Editor-Test. Neu eingefügt; vollständige CI auf finalem PR-HEAD und Realgerät noch offen.
- **Parallelität:** Kein Eingriff in die neuen Zauberauswahl- und Audit-Branches #317 und #318; vor dem Merge deren aktuelle Zustände sowie aktualisiertes `main` prüfen.
- **Nicht abgeschlossen:** sämtliche weiteren Pflichtentscheidungen der Klassen, SRD-Herkunftstalente, Speziesvarianten, Zauberlisten, vollwertiger Wizard und persistenter Entwurf; Starterkit-Wechsel innerhalb eines noch nicht bestätigten Editors weiter absichern.
- **Nächster Schritt:** auf exaktem PR-HEAD Format/Flutter/Android-GitHub-CI prüfen und ggf. reparieren; danach Klassenwahl-/Kitänderung im ungespeicherten Entwurf transaktional austauschen, damit keine Startgegenstände einer früheren Klassenauswahl verbleiben.
- **Quelle:** [SRD 5.2.1](https://www.dndbeyond.com/srd), CC BY 4.0. Keine kostenpflichtigen APIs, kein Force-Push, kein Main-Direktcommit.

---

# Chat D D-014 – Doppelte Branch-Bereinigung und 404-Rennen beseitigen (28.10.2026)

- **Ausgangs-main:** `571edec9455fb32e4991432953c9a2479a6fffb2`; **Branch:** `fix/chat-d/disable-legacy-cleanup-20261028`; [PR #329](https://github.com/ManuEtt/Dnd/pull/329) (reviewbereit).
- **Nachgewiesenes Problem:** Alte GitHub Action [40589220593](https://github.com/ManuEtt/Dnd/actions/runs/40589220593) scheiterte mit 404 beim Lesen des Branches `test/chat-b/story-12-memory-transport-20261027`. Die neuere Action [40589220368](https://github.com/ManuEtt/Dnd/actions/runs/40589220368) archivierte und entfernte diesen Branch zuvor.
- **IMPLEMENTIERT:** Alter Bereinigungsworkflow bleibt als nicht-automatischer, read-only Hinweis erhalten, ohne Lösch-/Tag-API. Der verifizierte Nachfolger `cleanup-merged-safe-20261027.yml` bleibt unverändert; kein Branch wird durch diesen PR gelöscht.
- **TESTS ERGÄNZT:** `scripts/tests/test_retired_cleanup_workflow.py` prüft erlaubten manuellen Read-only-Altworkflow, Manipulation negativer Trigger/Berechtigung/Mutationsaufrufe und Sicherheitsgrundlagen des Nachfolgers.
- **Technische Commits:** `45236f1b4d595303c19c1cf9e992ba36003026fc`, `c5b223389d75a9949a2bee13386d305bc586102e`. **Teststatus:** neue vollständige CI auf finalem Dokumentations-Commit vorher grün, neue CI läuft. Keine grüne CI behauptet.
- **KOMPATIBILITÄT:** Flutter/Backend, SQLite 2, JSON 1, SRD/Story und App-Version unverändert. Keine Migration.
- **ÜBERSCHNEIDUNG:** PR #301 bearbeitet einen anderen älteren Workflow; #311, #316 und #321 keine dieser Fachdateien. README/Checkpoint additiv und bei Integration zu konsolidieren.
- **NÄCHSTER SCHRITT:** Gesamte GitHub-CI auf finalem PR-Commit abwarten, PR bei Erfolg reviewbereit stellen; keine direkte Main-Änderung, keine fremden PRs/Branches löschen.

---

# Chat B – Outbox-Quittungen bei mehreren SQLite-Schreibern (27.10.2026)

- **Ausgangsbasis:** PR #305 `fix/chat-b/npc-outbox-cas-20261027` auf `eb4f3a43864ba00843aacd7f0b47b2e2f0fad1da`; eigener Branch `test/chat-b/npc-outbox-multiwriter-cas-20261027`.
- **IMPLEMENTIERT:** Reines Testpaket `app/test/npc_outbox_multiwriter_cas_test.dart`, vier echte SQLite-/`PlayerActionOutbox`-Integrationen mit zwei unabhängig geöffneten Verbindungen auf dieselbe DB: stale ACK bei neuem NPC; stale ACK bei derselben ID mit neuer Revision; alte Text-only-Quittung gegen neuen NPC-Auftrag in beide Richtungen; zwei gleichzeitige NPC-Handlungen derselben Kampagne mit exakt einem erfolgreichen Sendeauftrag.
- **AKZEPTANZ:** Ausschließlich exakt passender Request-ID/Text/NPC-ID/Revision-Datensatz darf gelöscht werden; eine verspätete Quittung bleibt wirkungslos und der neue Auftrag bleibt auf beiden SQLite-Verbindungen sichtbar; Parallel-Schreiber überschreiben nichts.
- **GETESTET:** GitHub-Code/API von PR #305 geprüft, offizielle Dart-3.9.2-Formatterausgabe übernommen und temporären Diagnoseworkflow entfernt. Endgültige GitHub-CI/Android-Abnahme auf eigenem finalem PR-Head gesondert nachweisen.
- **NICHT GETESTET:** Android-Realgerät und Live-KI-Provider; keine vollständige manuelle Oberflächenbedienung.
- **MIGRATION:** keine. Keine Änderung an SQLite-Version 3, Backend, Kampagnen-JSON, Regelengine oder Produktionsdateien.
- **BLOCKIERT:** Als gestapelter PR abhängig von #305 und dessen Vorgängern (#303, #300, #292, #290, #288). Gemeinsame Dokumentation durch Chat D beim Merge zusammenführen.
- **NÄCHSTER SCHRITT:** Nach grüner CI eine eigene kompakte Migration-/Recovery-Matrix dokumentieren und die gestapelten PRs durch Chat D integrieren.
- [Chat-B-Checkpoint](parallel/CHAT_B_CHECKPOINT.md). Ältere Einträge unverändert.

---

# Chat B – atomare NPC-Outbox-Quittung mit vollständiger Identität (27.10.2026)

- **Basis:** [PR #303](https://github.com/ManuEtt/Dnd/pull/303), Head `5388d8e428e024c939bf99e609f857ec37c4a62a`; eigener Branch `fix/chat-b/npc-outbox-cas-20261027`. Nicht vor den gestapelten Vorgänger-PRs integrieren.
- **AUSGANGSPROBLEM:** `removePendingAction` verglich bisher nur Kampagne, Request-ID und Text. Bei einem ersetzten Auftrag mit derselben Kennung und demselben Text, aber anderer bestätigter NPC-ID/Revision, konnte eine verspätete ACK-Löschung den neuen Auftrag entfernen.
- **IMPLEMENTIERT:** `PendingActionStore.removePendingAction` akzeptiert optional `selectedNpcId` und `selectedNpcRevision`. SQLite prüft die komplette Identität in derselben Transaktion vor dem Löschen und bindet beide optionalen Spalten an die `DELETE`-Bedingung. `PlayerActionOutbox.remove` übergibt und vergleicht beide Felder auch im Legacy-Fallback. Alte Aufträge ohne Auswahl sind kompatibel; keine automatische Wiederholung bei Neustart.
- **TESTS:** Zwei zusätzliche echte SQLite-Regressionen in `app/test/npc_selected_action_outbox_test.dart`: falscher NPC, falsche Revision und fehlende Auswahl dürfen einen bestehenden Auftrag nicht entfernen; ein späterer Auftrag mit wiederverwendeter Test-Request-ID und gleichem Text bleibt vor verspätetem ACK geschützt. Exakter Auftrag kann weiterhin gelöscht werden, auch nach SQLite-Neustart.
- **WEITERE KORREKTUR:** `UnsupportedDatabaseVersion.toString` zeigt unterstützte SQLite-Version 3 statt der historischen 2; Neuanlagenkommentar auf v3 berichtigt.
- **GETESTET:** Repository- und API-Quellcode des gestapelten PRs geprüft; offizielle Dart-3.9.2-Formatterausgabe angewendet und temporären Format-Workflow wieder entfernt. Der finale CI-Nachweis dieses PRs ist separat zu prüfen.
- **NICHT GETESTET:** Realgerät und produktiver KI-Provider, neue CI noch nicht als erfolgreich bestätigen.
- **MIGRATION:** keine. Die SQLite-v3-Erweiterung stammt aus PR #290, keine neue Spalte; Kampagnen-JSON, Backend und SRD unverändert.
- **BLOCKIERT:** Abhängige Integration #288 → #290 → #292 → #300 → #303 → dieser PR; Dokumentationsänderungen durch Chat D konsolidieren.
- **NÄCHSTER SCHRITT:** Eine fokussierte UI-Regression für veraltete Auftragsmeldungen mit Fake-Repository ohne den früheren FakeAsync-/SQLite-Deadlock.
- [Chat-B-Checkpoint](parallel/CHAT_B_CHECKPOINT.md), ältere Einträge bleiben erhalten.

---

## 28.10.2026 – Sicherer Charaktereditor auf fortgeschriebenem Main

- **Quell-PR #330:** [Revisionssichere Bearbeitung](https://github.com/ManuEtt/Dnd/pull/330); Ausgangs-HEAD `76d5daa` mit kompletter erfolgreicher [Android-/Flutter-CI](https://github.com/ManuEtt/Dnd/actions/runs/40631254745).
- **Integration:** Merge-Commit `8450cfc36574da6a688852514ea9ace52f79d4db` übernimmt `main` `3bdc3586` mitsamt SQLite-V3-/NPC-Migrationen und weiteren parallel integrierten Änderungen. Keine veralteten ganzen Dateien kopiert.
- **Funktion:** feste Kampagnen-ID/Revision beim Öffnen des Editors; transaktionaler Vergleich der ursprünglichen JSON-Fassung für eigenständige Archivfiguren; sichere Ablehnung einer Löschung, Doppelanlage oder Fremdbearbeitung.
- **Neue Tests:** sechs Fälle in `app/test/character_editor_stale_save_test.dart` mit zwei unabhängigen SQLite-Verbindungen und Neustart.
- **CI:** Ausgangs-HEAD erfolgreich; auf diesem kombinierten Commit noch ausstehend.
- **Parallel:** PR #319 und #324 für Klassenstartwerte bleiben getrennt; ihre Änderungen nicht dupliziert.
- **Grenzen:** keine echte Geräte-/TalkBack-Abnahme; weiterhin kein vollständiger SRD-Wizard und kein persistierter unbestätigter Charakterentwurf.
- [Details](CHARACTER_EDITOR_REVISION_20261028.md).

# Chat B – isolierte NPC-Outbox-Statusanzeige (27.10.2026)

- **Basis:** [PR #303](https://github.com/ManuEtt/Dnd/pull/303) Head `5388d8e428e024c939bf99e609f857ec37c4a62a`, eigene Branch `test/chat-b/pending-npc-status-widget-20261027`, gestapelter PR.
- **IMPLEMENTIERT:** Auslagerung der bisherigen Adventure-Komponenten für ausstehenden Auftrag, „Erneut bestätigen“, „Verwerfen“ und Fehlermeldung nach `app/lib/ui/pending_action_status.dart`. Die Komponente führt keine SQLite-, Netzwerk- oder asynchronen Aufgaben aus. NPC-Auswahl wird als bindend und revisionsabhängig erläutert. Bestehende Widget-Keys und Aufrufer-Callbacks bleiben erhalten.
- **TESTS:** `app/test/pending_action_status_test.dart` enthält fünf reine Flutter-Widgettests: Anzeige mit NPC-Bindung, stale Meldung, unterdrückte Buttons während Sendung, blockierte Interaktion und normale Handlungen ohne NPC-Auswahl. Keine FakeAsync/SQLite-Verschachtelung.
- **GETESTET:** Bestandstest-/UI-Verträge gegen Basis-PR geprüft; offizieller Dart-3.9.2-Formatter angewandt, temporären Diagnoseworkflow wieder entfernt. Neue CI nach finaler PR-Veröffentlichung abnehmen.
- **NICHT GETESTET:** Realgerät und Voice-/Live-Provider. Die Widgettests belegen die Darstellung, nicht den gesamten Navigations-/Providerfluss.
- **MIGRATION:** Keine. Beibehaltung bestehender SQLite v3 aus PR #290, SRD-Regeln, Kampagnen-/Export-JSON und Backend unverändert.
- **BLOCKIERT:** Integration der gestapelten Basis-PRs #288 → #290 → #292 → #300 → #303. Gemeinsame Checkpoints durch Chat D beim Merge konsolidieren.
- **NÄCHSTER SCHRITT:** Nach grüner CI gezielte manuelle Prüfung in Android bei großem Text und TalkBack; Statusmeldungen unter Konflikt und Neustart durch tatsächliche UI-Aufrufe nachziehen.
- [Chat-B-Checkpoint](parallel/CHAT_B_CHECKPOINT.md); ältere Einträge bleiben erhalten.

---

# Chat B – FakeAsync-Deadlock bei NPC-Wiederaufnahmetests beheben (27.10.2026)

- **Basis:** PR #288 → #290 → #292 → [#300](https://github.com/ManuEtt/Dnd/pull/300) Head `92f440510bdedda51bb3acb188b49c40409b3ce7`; eigener Branch `fix/chat-b/npc-resume-deterministic-regressions-20261027` (abhängig und **nicht** vor den Basis-PRs eigenständig integrieren).
- **Problem:** Der erste PR #292 scheiterte nach zehn Minuten an einem hängenden `pumpWidget`; der nachgeschaltete PR #300 verursachte mit `pumpWidget` innerhalb `tester.runAsync` einen Guard-Konflikt. Quell-CI #40505592178/#40505602173 rot. Es sind Testinfrastruktur-Probleme, kein bestätigter NPC-Produktionsdefekt.
- **IMPLEMENTIERT:** Reine, zustandsfreie `resolvePendingNpcAction`-Entscheidungsfunktion in `app/lib/services/npc_pending_action_recovery.dart`; dieselbe Funktion wird von `app/lib/ui/app.dart` für bestätigte, veraltete, nicht verfügbare und gültige NPC-Aufträge verwendet. Der UI-Vertrag, fehlendes automatisches Retry und gespeicherte ID-/Revisionsbelege bleiben erhalten.
- **TESTS:** Die bisher blockierende Datei `app/test/npc_ui_outbox_restart_integration_test.dart` testet nun vier SQLite-/GameController-/Fake-Narrator-Szenarien ohne WidgetTester oder FakeAsync: explizite Mira-ID mit exklusiver Notiz; verlorene Quittung nach echtem DB-/Controller-Neustart; veraltete Revision; identische Request-ID/Text, aber anderer gewählter NPC. Der visuelle Dialog wird bereits separat in `npc_story_selection_dialog_test.dart` geprüft. **Keine Behauptung einer vollständigen App-Tap-Integration.**
- **GETESTET:** Ursächliche CI-Stacktraces des alten PRs ausgewertet; die drei neu berührten Dart-Dateien mit offiziellem Dart-3.9.2-Formatter abgeglichen und temporären Diagnoseworkflow entfernt. Komplette CI auf finalem PR-Head getrennt bewerten.
- **NICHT GETESTET:** Realgerät, Live-KI, neues vollständig durchgeklicktes Widget-E2E; lokales Flutter-SDK nicht vorhanden.
- **MIGRATION:** keine. Die SQLite-v3-Migration gehört unverändert zum Basis-PR #290; keine SRD-, Backend- oder Exportänderung.
- **BLOCKIERT:** Basis-PRs #288, #290, #292 und #300. Gemeinsame Checkpoints durch Chat D konsolidieren.
- **NÄCHSTER SCHRITT:** Nach grüner CI gezielt einen kleinen separaten Widgettest für die Outbox-Meldungen ohne reale FFI-Pump-Abhängigkeit entwickeln.
- [Chat-B-Checkpoint](parallel/CHAT_B_CHECKPOINT.md); historische Einträge bleiben erhalten.

---

# Chat B – End-to-End-NPC-Auswahl, Neustart und verlorene Bestätigung (27.10.2026)

- **BASIS:** [PR #288](https://github.com/ManuEtt/Dnd/pull/288) → [PR #290](https://github.com/ManuEtt/Dnd/pull/290), Head `c45d7f7ce82e367e78d102ccc98b0046683cbd23`. Eigener gestapelter Branch `test/chat-b/npc-ui-restart-reconciliation-20261027`.
- **IMPLEMENTIERT:** `app/test/npc_ui_outbox_restart_integration_test.dart` mit drei echten Flutter-UI/SQLite/Controller/Backend-Mock-Regressionstests: bewusste zweite Mira direkt über Adventure-Dialog wählen; einen bereits bestätigten Auftrag nach SQLite- und Controller-Neustart ohne erneuten Provideraufruf quittieren; eine veraltete NPC-Auswahl nach neuer Revision beim Wiederholungsversuch fail-closed mit unberührtem Spielstand und weiterhin sichtbarer Outbox belassen.
- **TESTUMFANG:** Mehrdeutige NPC-Anzeigenamen, bestätigte NPC-Beziehungsnotizen, `selectedNpcId`, Status/Revision, kein automatisches Senden beim Start, verlorener ACK, Session-Token-Neuverbindung erforderlich, korrekte dauerhafte Request-ID.
- **GETESTET:** GitHub-Dateien und alle offenen relevanten PRs geprüft; exakte Dart-3.9.2-Formatter-Ausgabe auf den neuen Test angewendet, temporären Formatter-Workflow entfernt. Die vollständige neue CI-/APK-Abnahme ist auf dem finalen PR-HEAD separat zu prüfen.
- **NICHT GETESTET:** Android-Realgerät und kostenpflichtiger Live-KI-Provider; lokales Flutter-SDK nicht vorhanden.
- **MIGRATION:** Keine neue Migration durch dieses Testpaket (die abhängige v3-Outbox-Migration gehört zu PR #290), keine Änderungen an SRD-Regeln oder Produktionsdateien.
- **BLOCKIERT:** Gestapelte Integration in Reihenfolge #288 → #290 → dieser Test-PR. Gemeinsame README-/Checkpoint-Änderungen von Chat D konsolidieren.
- **NÄCHSTER SCHRITT:** Nach erfolgreicher CI gezielten Bildschirmleser-/Großschrift-Test und Fehleranalyse der Wiederholung bei Netzwerkunterbrechung ergänzen.
- [Chat-B-Checkpoint](parallel/CHAT_B_CHECKPOINT.md), historische Einträge bleiben erhalten.

---

# Chat B – zugängliche NPC-Auswahl und revisionsgebundene SQLite-Outbox (27.10.2026)

- **BASIS:** [PR #288](https://github.com/ManuEtt/Dnd/pull/288) `feat/chat-b/controller-explicit-npc-selection-20261027` bei `2ba524c307b3b48ad21a6343df700ae0a643f55d` (dessen gesamte CI erfolgreich); eigener Branch `feat/chat-b/npc-picker-outbox-20261027`, gestapelter PR.
- **IMPLEMENTIERT:** `app/lib/ui/npc_story_selection_dialog.dart`: Dialog mit eindeutig bestätigten NPC-IDs, Beziehungsanzeige und Screenreader-Semantik; Auswahl erfordert tatsächlichen Tipp. `app/lib/ui/app.dart` verdrahtet den Button, bereitet den Text über die **bestehende** Outbox vor und leitet die bestätigte ID an `GameController.sendAction(selectedNpc:...)` weiter. Ausstehende NPC-Auswahl wird bei Restart anhand der ursprünglichen Revision geprüft. Ein bereits bestätigter identischer Beleg kann nach verlorener Quittung abgeglichen werden; keine automatische Namenswahl.
- **MIGRATION:** SQLite **2 → 3**: optionale `selected_npc_id`/`selected_npc_revision` im Sendeauftrags-Speicher; Upgrade erhält Text-/Request-ID-Altbestand, bisherige Kampagnen-/Export-JSON-Version unverändert. `PendingActionStore` und `PlayerActionOutbox` bieten optionale Werte; alte Aufrufer bleiben kompatibel.
- **TESTS ERGÄNZT:** `app/test/npc_selected_action_outbox_test.dart` (Restart, atomare Validierung, Upgrade von SQLite 2) und `app/test/npc_story_selection_dialog_test.dart` (gleichnamige NPCs, Cancel, keine erfundenen Erinnerungen).
- **GETESTET:** GitHub-Quellcode und aktuelle PRs geprüft, offiziellen Dart-3.9.2-Formatter auf alle sieben geänderten Dart-Dateien angewendet; temporären Diagnoseworkflow entfernt. Vollständige neue CI auf finalem PR-HEAD nachsehen.
- **NICHT GETESTET:** reales Android-Gerät, produktiver KI-Provider und manueller Voice-Dialog; Integration setzt PR #288 voraus.
- **BLOCKIERT:** Zusammenführung nach Basis-PR #288 und CI; Dokumentationskonflikte durch Chat D abgleichen.
- **NÄCHSTER SCHRITT:** Test der Outbox-Neustart-Wiederaufnahme durch komplette UI-Controller-Kette mit simuliert verlorenem ACK und konkurrierenden Revisionen.
- [Chat-B-Checkpoint](parallel/CHAT_B_CHECKPOINT.md). Vorherige Einträge bleiben erhalten.

---

# Chat D D-013 – Verlinkte Pflichtdateien in der Projektprüfung ablehnen (27.10.2026)

- **Basis-main:** `ff245cc253194cd0858385d535ae7b2c9132bb06`; eigener Branch `fix/chat-d/verify-project-symlink-20261027`; technische Commits `4a81596a1bc2b729fe2c8cc739f7a201220f92f6` und `9c910244117ec4f7b3ea6149fedf5e78b279568a`; [PR #321](https://github.com/ManuEtt/Dnd/pull/321) (Draft).
- **PROBLEM:** Die Existenzprüfung per `Path.is_file()` folgte Links auf Pflichtdateien und deren Elternverzeichnisse. Die späteren JSON-/JAR-/Launcher-Prüfungen konnten dadurch externe Dateien öffnen.
- **IMPLEMENTIERT:** Pfadsegmentprüfung mit `is_symlink()` und Abbruch pro betroffenem Pflichtpfad; verlinkte Backend-JSON-, Gradle-JAR-, Gradle-Properties- und Launcher-Dateien werden nicht zur weiteren Inhaltsprüfung geöffnet. Keine sensitiven Linkziele in Fehlermeldungen.
- **TESTS ERGÄNZT:** Vier Python-Regressionstests für Dateilink, Backend-Elternverzeichnis, Wrapper-JAR ohne ZIP-Lesezugriff und defekten Link. Bestehender positiver Test für reguläre Kopien bleibt.
- **GETESTET:** GitHub-Quelländerungen und eigener Branch/PR verifiziert. Testausführung auf neuem PR-HEAD **noch nicht belegt**.
- **NICHT GETESTET:** Vollständige Python-, Flutter-, Backend-, Android-/APK-CI des finalen Commits und Realgerät.
- **ÜBERSCHNEIDUNG:** Offene PRs #316 (Domain-Boundaries) und #311 (Alpha-Archiv) bearbeiten andere Skripte/Tests; deren Änderungen nicht angetastet. README und Checkpoint sind bewusst additive, bei Integration zu koordinierende Dateien.
- **KOMPATIBILITÄT:** Kein Produktcode, keine Spielstandsänderung; SQLite 2/Kampagnen-JSON 1 und Version unverändert. Keine Migration.
- **RISIKO:** Dies ist eine strukturelle Vorprüfung, kein atomarer Dateizugriffsschutz gegen gleichzeitig vertauschte Pfade.
- **NÄCHSTER SCHRITT:** Finale PR-CI auf PR-HEAD kontrollieren, bei Fehlern in diesem Branch korrigieren und erst danach Review/Integration erwägen.

---

# Chat B – Story-Transport mit randvollem Erinnerungslimit (27.10.2026)

- **Basis:** [PR #307](https://github.com/ManuEtt/Dnd/pull/307) (`fix/chat-b/npc-memory-budget-20261027`, Head `47b4343fadd5f30b9030a702b3ccd701d701a598`). Gestapelter neuer Branch `test/chat-b/npc-memory-wire-budget-20261027`; erst #307 integrieren.
- **IMPLEMENTIERT:** `app/test/npc_story_memory_wire_budget_test.dart`, zwei End-to-End-Regressionen mit echter SQLite-Kampagne, `GameController`, drei bestätigten NPC-Beziehungsnotizen und 18 voneinander unterscheidbaren allgemeinen Fakten. `sendAction` führt zur abgefangenen Story-Backend-Anfrage mit **exakt zwölf** Erinnerungen; die drei NPC-Notizen bleiben priorisiert, allgemeine Fakten nutzen freie Plätze. Testet `npc-identity-v1` sowohl ein- als auch ausgeschaltet.
- **WEITERE PRÜFUNGEN:** Transport enthält keine überzähligen NPC-/allgemeinen Erinnerungen; Textlänge pro Eintrag höchstens 400 Zeichen; keine Duplikate; optionaler strukturierter NPC-Kontext enthält nur Mira; Helden-JSON bleibt unverändert, lokale Revision erhöht sich um eins, SQLite-Rekonstruktion entspricht gespeichertem Snapshot.
- **GETESTET:** Testvertragsprüfung gegen GitHub-Quellcode; offizielle Dart-3.9.2-Formatierung wird vor PR-Abgabe durchgeführt. Die vollständige GitHub-CI auf dem **finalen PR-Head** ist erst bei nachgewiesener Ausführung als bestanden zu kennzeichnen.
- **NICHT GETESTET:** echtes Android-Gerät oder produktiver KI-Provider. Kein lokales Flutter-SDK. Ein lokaler, nicht kostenpflichtiger Backend-Transport wird simuliert.
- **MIGRATION:** keine – Test und Dokumentation allein; SRD-, SQLite-, Kampagnenexport- und Backend-Protokolle unverändert.
- **BLOCKIERT:** Integration der Basisfunktion aus #307, gemeinsame Docs von Chat D konsolidieren.
- **NÄCHSTER SCHRITT:** Nach CI-Erfolg weitere adversariale Tests für gesättigte Erinnerungslisten mit bereits vorhandenen Wiederholungen und leerem Kontext.
- [Chat-B-Checkpoint](parallel/CHAT_B_CHECKPOINT.md), alte Historie bleibt erhalten.

---

# Chat B – NPC-Erinnerungslimit nicht überschreiten (27.10.2026)

- **Ausgangs-Main:** `f9b2f72a4bf8e4216bf8baac60c7f92c4a8a997f`; Branch `fix/chat-b/npc-memory-budget-20261027`.
- **BEFUND:** `NpcNarratorMemory.merge` fügte allgemeine Erinnerungen hinzu und prüfte `result.length == limit` erst danach. Wenn bestätigte NPC-Beziehungsnotizen das Limit bereits erreichten, entstanden `limit + 1` Einträge. Bei vollen Transportbudgets konnte die anschließende Backend-Validierung scheitern.
- **IMPLEMENTIERT:** Vor jedem allgemeinen Eintrag auf bereits ausgeschöpftes Gesamtkontingent prüfen. Bereits bestätigte NPC-Notizen behalten ihre Priorität; bei freier Kapazität bleiben allgemeine Erinnerungen erhalten. Keine Daten-, Regel- oder API-Migration.
- **TESTS:** `app/test/npc_narrator_memory_test.dart`: Limit 1 und Limit 2 vollständig mit bestätigten Notizen belegen, prüfen, dass kein weiterer allgemeiner Eintrag aufgenommen wird; Limit 3 lässt bewusst genau einen allgemeinen Fakt zu; Kampagnenstand bleibt identisch und Rückgabeliste unveränderlich.
- **GETESTET:** Live-`main` und offene PR-Dateien vor Aufgabenwahl geprüft; offizielle Dart-3.9.2-Formatterausgabe angewendet und temporären Workflow entfernt. Vollständige CI auf finalem PR-HEAD gesondert prüfen; lokales Flutter-SDK und Realgerät nicht vorhanden.
- **PARALLEL:** PR #304 bearbeitet die Widgetmeldungen des Outbox-Status bereits, PR #305 die atomare NPC-Löschung; dieser eigenständige Branch ändert **keine** von deren Fachdateien.
- **NÄCHSTER SCHRITT:** Nach grünem CI Ergebnis und anderem Branch-Merge den Narrator-Endpunkt mit einer randvollen (12 Einträge) Kontextliste auf Anwendungsebene testen.
- [Chat-B-Checkpoint](parallel/CHAT_B_CHECKPOINT.md), ältere Einträge bleiben erhalten.

---

## 27.10.2026 – Integrationskandidat der Charaktererstellung #264/#272/#273/#275

- **Basis:** `main` `4bd97b4d72fc747228df9bea46b61c3d4c82c382`; komplette gestapelte Quelle `ae148053feca82f5db1741b37536385f4d7d41c5`; Merge-Tree anhand der Git-Blob-SHAs konfliktarm zusammengestellt, beide Herkunfts-Commits als Eltern erhalten. Nur README und diese Checkpoint-Datei redaktionell aus dem originalen Main additiv ergänzt; fremde Chat-B-/Chat-D-Einträge bleiben erhalten.
- **Implementiert:** sechs Würfelergebnisse 4W6 (niedrigsten streichen), optionale versionierte Attribut-Herkunft, ausdrückliche Hintergrundpakete für Akolyth/Krimineller/Weiser/Soldat, konkrete Wahl von Spielset bzw. Heiligem Symbol, gültiges JSON/Inventar.
- **GETESTET auf den Quell-PRs:** einzelne GitHub CI inklusive Flutter/Android (z. B. #275 [Lauf 40456350744](https://github.com/ManuEtt/Dnd/actions/runs/40456350744) vollständig erfolgreich).
- **NOCH NICHT GETESTET:** gemeinsame Integrations-CI / auf main gemergter Code-HEAD sowie echte Android-Geräteinstallation, TalkBack, ältere Gerätedaten-Upgrades und produktive Signierung.
- **OFFEN:** Magieinitiierter-Zaubertricks/Zauberattribut, tatsächliche Herkunftstalente, weitere Spezies- und Klassenauswahl. **Kein vollständiger SRD-Nachweis.** SQLite 2, Kampagnen-JSON 1 und App-Version 0.8.42+92 unverändert.
- **Nächster Schritt:** Integrations-PR-CI auf finaler exakter SHA beobachten, Defekte beheben, danach nur nach grüner CI und geprüfter Main-Basis regulär mergen. Ursprungsbranches nicht vorschnell löschen. [Integrationsbeleg](CHARACTER_STACK_INTEGRATION_20261027.md).

---

# Chat B – Persistierte NPC-ID-Wiederaufnahme (26.10.2026)

- Ausgangs-`main`: `67f146e690306b13d490bd8e7fd5636bb187c77e`, Branch `feat/chat-b/npc-selection-resume-20261026`, Test-Commit `945f6a18c3ce1570f52d95d8d21e453dbaf519dc`.
- **IMPLEMENTIERT:** neuer SQLite-/Backend-Mock-Integrationstest `app/test/npc_selection_resume_sqlite_test.dart` prüft eindeutige NPC-ID bei zwei gleichnamigen Figuren nach Neustart, aktive Capability-Aushandlung, unveränderte Kampagnen- und Heldenwerte, Stale-Revisionsabbruch, neue Auswahl nach Sitzungswechsel und Legacy-JSON ohne Notizen.
- **GETESTET:** Start-`main`, offene PR-Dateipfade, Quellcode und vorhandene Integrationsverträge über GitHub gelesen; allein dadurch kein Test bestanden.
- **NICHT GETESTET:** neue Flutter-/Gesamtsuite und Android lokal; GitHub-CI auf finalem Commit abwarten; Realgerät/Provider nicht getestet.
- **BLOCKIERT:** Flutter-/Android-SDK lokal nicht installiert; konkurrierende Änderungen an gemeinsamer Dokumentation durch Integrations-PR #250 – Chat D übernimmt Konsolidierung.
- **KEINE MIGRATION:** Keine Änderung am Produktcode, an Regeln, Datenbankschema, JSON-Version oder App-Version.
- **NÄCHSTER SCHRITT:** Narrativen Terminalstatus plus Beschreibungsintegrität an bestehender Story-Grenze als eigenes Regel-/Story-freies Paket prüfen.
- [Chat-B-Checkpoint](parallel/CHAT_B_CHECKPOINT.md). Alle bisherigen Einträge bleiben darunter erhalten.

---

# CODEX-CHECKPOINT – vollständige Branch-Migration

## Chat D D-012 – Begrenzte Gradle-Wrapper-JAR-Prüfung (26.10.2026)

Branch `fix/chat-d/gradle-jar-zip-bomb-guard-20261026` auf Main-Basis `67f146e690306b13d490bd8e7fd5636bb187c77e`. ZIP-Metadaten des Wrapper-JAR werden nun vor jedem CRC-/Startklassenlesen auf 512 Einträge und 16 MiB entpackten Inhalt geprüft; auch die JAR-Datei selbst hat eine 16-MiB-Grenze. Vier Regressionstests (zu große JAR, komprimierte ZIP-Bomb, Eintragszahl, echtes gültiges Wrapper-JAR) ergänzen die unveränderten Wrapper-/Uploadchecks. Code `77a431955351e30a1dcf54e0dea7f8ba7b7b497a`, Tests `86634965c6784994ecb731c4bacab476a9f50ffa`.

**IMPLEMENTIERT:** Fail-Closed-Limits in Projektvorprüfung, bestehende Funktion erhält dieselben Nutzermeldungen. **GETESTET:** PR #246 (D-011) zuvor erfolgreich; für D-012 noch keine finale CI bestätigt. **NICHT GETESTET:** Vollständige Python-/Backend-/Flutter-/Android-Gesamtsuite und APK auf diesem Dokumentations-HEAD, reales Gerät. **BLOCKIERT:** lokaler Checkout mangels GitHub-DNS. **NOCH NICHT IMPLEMENTIERT:** keine weitere Funktion; nächste Aufgabe ist CI-Verifikation dieses PRs. **MIGRATION:** keine, Flutter/SQLite 2/JSON 1 und App-Version unverändert. Konfliktfrei zu den bei Start beobachteten Fach-Pfaden anderer PRs, zentrale Dokumente bei der Integration additiv erhalten.

[Chat-D-Detailcheckpoint](parallel/CHAT_D_CHECKPOINT.md).

---


Stand **2026-10-26T17:38:53+00:00**, Würfelraunen **0.8.42+92**, SQLite **2**, Kampagnen-JSON **1**.

## Git und Sicherungen

Basis-Main **`5e3116f9e3f8de0af6e8125a97b3962cb8910cdf`**, Arbeitsbranch **`integration/all-branches-20261026b`**, Worktree `/workspace/Dnd-all-branches-20261026`. Funktionsmerges bis `a64ffe7`; anschließender Formatter-/Versions-/Dokumentationscommit ist im aktuellen `git log` nachzusehen. Main bisher unverändert.

Die folgenden ursprünglichen sieben Köpfe und die drei ergänzten Fortschreibungsköpfe als Remote-Archivtags und lokalem geprüften Bundle gesichert, alle Vorfahren des Integrationsstands. Die sieben Nicht-Main-Branches werden erst nach gemeinsam grünen Checks, PR-Merge und grüner Main-Abnahme mit exakter SHA-Lease gelöscht. Neue/weitergeschriebene Köpfe vor Löschung erneut sichern und integrieren; Main und Archivtags niemals löschen.

| Branch | gesicherte SHA | Remote-Archivtag |
| --- | --- | --- |
| `feat/chat-b/explicit-npc-wire-20261026` | `40ea6cb9b62daf70dcee3a5d8f993bf7e9a1b5cf` | `archive/branch-migration-20261026T173427Z/feat/chat-b/explicit-npc-wire-20261026` |
| `feat/chat-c/action-economy-large-text-20261026` | `92fb423d19c84d3b9710fc3237d10206b9ef4712` | `archive/branch-migration-20261026T173427Z/feat/chat-c/action-economy-large-text-20261026` |
| `feat/chat-c/dice-plaque-large-text-20261026` | `771405675381687200900cfd17c900ad7d049e5e` | `archive/branch-migration-20261026T173427Z/feat/chat-c/dice-plaque-large-text-20261026` |
| `fix/chat-a/eldritch-primary-class-validation-20261026` | `1be828a91b124dd95443b7212d5220ab82710fb2` | `archive/branch-migration-20261026T173427Z/fix/chat-a/eldritch-primary-class-validation-20261026` |
| `fix/chat-d/checkpoint-manifest-nofollow-20261026` | `15ff60b251fb64d76b5c65bf93e93fe47545024c` | `archive/branch-migration-20261026T173427Z/fix/chat-d/checkpoint-manifest-nofollow-20261026` |
| `fix/chat-d/source-zip-symlink-swap-20261026` | `2904fabdfbd28ec5d0ae74c568fb709c87d493f7` | `archive/branch-migration-20261026T173427Z/fix/chat-d/source-zip-symlink-swap-20261026` |
| `main` | `5e3116f9e3f8de0af6e8125a97b3962cb8910cdf` | `archive/branch-migration-20261026T173427Z/main` |

Bundle **`/workspace/artifacts/branch-migration-20261026T173427Z/Alle_Branchstaende.bundle`**, SHA256 `1ee5f7814ffd02c6e88775c54b46064d52f23bf03d48b51f01b3d635e6e8bc0e`. Originale README-/Checkpoint-Fassungen bytegenau unter `docs/history/branch_migration_20261026T173427Z/`, Commit-/SHA256-Manifest dort. Inventar `docs/BRANCH_MIGRATION_20261026_INVENTORY.json`.

### Während der Migration neu gesichert

| Branch | zusätzliche SHA | Archivtag |
| --- | --- | --- |
| `fix/chat-a/spell-range-unit-validation-20261026` | `95057282286f93f3f46ee39196c047166d3cddf2` | `archive/branch-migration-20261026T173427Z/round2/fix/chat-a/spell-range-unit-validation-20261026` |
| `fix/chat-d/checkpoint-manifest-nofollow-20261026` | `3746c5769f5ddb01842762184b0f477845d11740` | `archive/branch-migration-20261026T173427Z/round2/fix/chat-d/checkpoint-manifest-nofollow-20261026` |

Zweites geprüftes Bundle `/workspace/artifacts/branch-migration-20261026T173427Z/Alle_Branchstaende_Runde2.bundle`, SHA256 `e26e0d3cd17149beb9f780801d620736cf3911de731ed7aeac003be0eb41c44b`. Die erste kombinierte Suite aufc246 wurde nach 155 Python-/70 Backend-Tests und grüner Analyse für den zusätzlichen Branch mit SIGTERM/143 beendet; **kein vollständiger Erfolg** behauptet. Früher Debug-APK-Stand separat unter `code-c2467c9/`; kein finales Paket daraus ableiten.

### Letzter archivierter Autor-Nachtrag

Zusätzlich `10f14cccd4f487bbbca5fee0938464d744d10e9d` / `archive/branch-migration-20261026T173427Z/round3/fix/chat-a/spell-range-unit-validation-20261026` regulär integriert. Produktionsparser identisch zu unserer Syntaxreparatur; eigene exakte Integer-Grenztests erhalten und kanonisch formatiert. Temporären reinen Formatter-Diagnoseworkflow nach Übernahme entfernt; reguläre CI bleibt vollständig. Runde3-Bundle `/workspace/artifacts/branch-migration-20261026T173427Z/Alle_Branchstaende_Runde3.bundle`, SHA256 `7d371f35dea17f98cd7abe0f9868bafc9e5e6ff2c228345b0bee55bcb38ade0a`. Insgesamt zehn gesicherte Ursprung-/Fortschreibungsköpfe aus acht Namen.

## IMPLEMENTIERT

Eldritch-Hauptklassenprüfung; optionaler revisions-/capabilitygeprüfter NPC-ID-Wire-Vertrag; große Schrift/semantische Trennung für Kampfmöglichkeiten und Würfelanzeige; O_NOFOLLOW-Leseweg auch für Checkpoint-Manifeste. **NPC-Auswahl ist noch nicht durch Android/GameController bis zum Wire-Aufruf verbunden.** Keine neue Speicher-/Event-/JSON-Struktur, keine Regeländerung durch Erzählung, keine realen Anbieteraufrufe. Quelle und Fachumfang in den erhaltenen `docs/parallel/`-Berichten; SRD-Anforderungen weiter nur teilweise umgesetzt.

## GETESTET

155 Python- und 70 Backend-Tests lokal vor dem letzten Source-Zuwachs erfolgreich; neue vollständige gemeinsame Abnahme erforderlich. Einzelkopf-CIs A236 #40339812512, B237 #40343591766, C239 #40360058998, Symlink2904 #40359044253 erfolgreich; diese Einzelbelege ersetzen keine neue kombinierte Abnahme. Letzte beim Start vollständig beobachtete Main-CI #40329543416 auf `42d14ad36cc947691f7e5a1e8647a43f5421b86e` grün; neue Main-CI #40369467941 auf5e3116f noch laufend. Alle sieben Ancestry-/Remote-Archivtag-/Bundle-Nachweise geprüft.

## FEHLER UND KORREKTUR

Neu eingetroffener PR242-Kopf9505728 enthält einen Syntaxfehler (duplizierte Methode mitten im Reichweiten-RegExp) und unformatierte Tests. Reparatur im Integrationsbranch samt exakter Integer-Grenzfälle,17 gezielte Tests und Analyse grün; volle Abnahme folgt; ursprüngliche Source-Fassung bleibt archiviert.

Dice-PR240 / Kopf7714056 scheiterte in #40369637672 bei Dart-Formatierung von `app/test/fantasy_dice_breakdown_test.dart`. Testdatei mit gepinntem Dart3.9.2 formatiert; alle Assertions erhalten. Andere Fachprüfungen fanden keine Blocker. Gemeinsame Suite prüft erst den korrigierten Integrationsstand.

## NICHT GETESTET

Neue komplette Flutter-/Backend-/Android-/CI-Kombination bis zum tatsächlichen Abschluss offen. Echtgerät, TalkBack-Geräteabnahme, historisches installiertes Daten-Upgrade und produktive Signierung offen. Keine alten Erfolge als neue CI ausgeben.

## BLOCKIERT

Kein reales Gerät/Produktivschlüssel. Lokale Toolchain vorhanden; keine SDK-Ausrede. Während Inventur entstanden Dice-PR240 und der Manifest-Branch; neu erfasste SHA7714056/15ff60b sind mitgesichert. Bei späterem Drift keine ungeprüfte Löschung.

## Abschluss, Artefakte und Fortsetzung

Frühzeitigen kompletten Quell-ZIP-/Patch-Checkpoint unter `/workspace/artifacts/branch-migration-20261026T173427Z/` erstellen, anschließend Gesamtprüfungen/Builds ausführen, Kopf auf GitHub sichern, Integrations-PR erstellen. Nach grüner exakter PR-CI per regulärem Merge integrieren, Main-CI tatsächlich abwarten, dann nur gesicherte enthaltene unveränderte Branches per SHA-Lease löschen. Vorhandene uncommittete Worktrees und frühere Artefakte erhalten.

Test-/Buildlogs `/workspace/validation/20261026-migration-*`. Prüfung `bash scripts/check.sh`; Android `flutter build apk --debug`, `bash app/android/gradlew :app:testDebugUnitTest --no-daemon` aus dem passenden Android-Verzeichnis; Alpha separat nach CI. Quell-ZIP ohne APKs, private Daten oder Toolchains, Patchbasis und SHA256 im Manifest.

## NOCH NICHT IMPLEMENTIERT / genau ein nächster Schritt

Explizite NPC-ID-Auswahl von Android über GameController an den bereits vorhandenen Wire-Vertrag durchreichen. Definition of Done: gleichnamige Figuren ausdrücklich per ID auswählen, fehlende Capability und Stale Revision vor Netzwerk/Kosten ablehnen, Abbruch/Neustart/SQLite testen, Regel-/Story-Grenze erhalten. Erst nach vollständigem Migrationsabschluss beginnen; aktuelle Main-/Branch-/CI-Stände erneut lesen. Keine automatische Wiederaufnahme außerhalb einer aktiven Sitzung.


---

## Aktueller Charakter-Checkpoint – 28.10.2026, 0.8.45+95

Der neueste Status dieses Charakterpakets steht am Dateiende; die zuvor
stehenden Main-Übergaben bleiben als Integrationsbasis unverändert.
**IMPLEMENTIERT:** ausdrückliche versionierte Startklassen-/Fertigkeits-/
Paketnachweise, sichere Wiederholung ohne zusätzliche Vergabe, Legacy-Erhalt
und konservativer Audit einschließlich offener Mönch-Werkzeugkopplung.
**GETESTET:** Zwischenkopf `019be0e` in
[CI 40631517151](https://github.com/ManuEtt/Dnd/actions/runs/40631517151)
komplett grün: 2.007 Flutter-, 168 Python- und 72 Backend-Tests plus Android.
**Aktuell lokal zusätzlich bestanden:** 57 gezielte Tests, Analyse, 465 Dateien
formatiert ohne Änderung und 168 Pythonprüfungen auf Main-Basis bf5999e.
**NICHT GETESTET:** abschließende gemeinsame CI nach zusätzlichem Main-Merge
`bf5999e`, echtes Android-Gerät/TalkBack und installiertes Altversionsupgrade.
**BLOCKIERT:** kein neuer Quellkonflikt; aktueller Integrationskopf muss geprüft
werden. **NOCH NICHT IMPLEMENTIERT:** vollständiger Charakterassistent und
sämtliche verpflichtenden Spezies-/Klassen-/Zauberwahlen.

Vollständiger Stand, Artefakte, bekannte Grenzen und konkrete Wiederaufnahme:
[CHARACTER_START_CLASS_CHECKPOINT_20261028.md](CHARACTER_START_CLASS_CHECKPOINT_20261028.md).
PR #319, Branch `feat/character-start-class-proof-20261027`; keine Force-Pushes,
keine direkte Main-Änderung und keine fremde Branchlöschung. Nächster Schritt:
finale gemeinsame CI/Artefakte abnehmen, danach den bereits von anderem Owner
bearbeiteten [Editor-CAS-PR #330](https://github.com/ManuEtt/Dnd/pull/330)
koordiniert mit aktuellem Main integrieren und erneut abnehmen. Dessen
CI 40631254745 ist bereits grün, einschließlich sechs SQLite-/CAS-Regressionen;
aktuelle Mergekonflikte auflösen, nichts doppelt implementieren. #323 ist bereits in Main `bf5999e` enthalten. Originale von Main `bf5999e` und unserem vorherigen
Status bleiben bytegenau im [Historienmanifest](history/character_class_main_20261028/manifest.json).
