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

# Chat B – revisionsgebundene NPC-Auswahl in GameController (27.10.2026)

- **Basis:** `main` `2421fcd18f4d980f31a71ec9d60e80a53b53e45b` zum Start; Branch `feat/chat-b/controller-explicit-npc-selection-20261027`.
- **IMPLEMENTIERT:** `GameController.sendAction` akzeptiert optional eine bewusst erstellte `NpcStorySelection`. Vor dem Spielzug werden KI-Modus, verbundener Server, `npc-selection-v1`, Kampagnenrevision in aktuellem SQLite, eindeutige NPC-ID und bestätigte Notizen geprüft. `_withNarration` erzeugt den ID-Kontext aus dem neuen Spielzug und sendet `selectedNpcId` nur nach erfolgreicher Aushandlung. Idempotente `requestId`-Quittungen enthalten optional die NPC-ID; eine andere ID unter derselben Kennung wird abgewiesen.
- **GETESTET:** Quellcode-/API-Verträge und parallele PRs geprüft; für Controller und Tests exakte Ausgabe des offiziellen Dart-3.9.2-Formatters übernommen und temporären Diagnoseworkflow wieder gelöscht.
- **TESTS ERGÄNZT:** `app/test/npc_explicit_controller_selection_test.dart` mit vier echten SQLite-/Fake-Backend-Regressionen (zwei gleichnamige NPCs, alter Server, alte Revision, Quittungskollision). CI-Abnahme auf finalem Commit separat nachweisen.
- **NICHT GETESTET:** Endgültiger gesamter CI-Lauf und Android-Realgerät; produktiver KI-Provider. **Es gibt noch keine UI zur aktiven NPC-Auswahl.**
- **BLOCKIERT:** UI-Anbindung später mit Chat C koordinieren, parallele README-/Checkpoint-Änderungen bei Integration mit Chat D konsolidieren.
- **MIGRATION:** Keine. Altes `sendAction(text)` und altes `sendAction(text, requestId: id)` funktionieren unverändert; keine SRD-/SQLite-/JSON-/Versionsänderung.
- **NÄCHSTER SCHRITT:** Nach grüner CI NPC-Auswahl im Android-Dialog als explizite, zugängliche Auswahl anzeigen; nicht aus gleichnamigem Freitext ableiten.
- [Chat-B-Checkpoint](parallel/CHAT_B_CHECKPOINT.md), bisherige Einträge bleiben erhalten.

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
