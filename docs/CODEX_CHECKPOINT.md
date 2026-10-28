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
