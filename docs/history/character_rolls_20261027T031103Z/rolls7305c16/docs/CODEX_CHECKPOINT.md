## 26.10.2026 – Charaktererstellung: 4W6-Attributmethode, Draft-PR #264

- **Branch:** `feat/character-random-ability-rolls-20261026`;
  [PR #264](https://github.com/ManuEtt/Dnd/pull/264).
- **Implementiert:** Unveränderliche 4W6-Würfe, sechs Summen nach
  Streichen des niedrigsten Würfels, unverfälschbare Verteilung,
  explizite Zuordnung im deutschen Flutter-Assistenten.
- **Tests geschrieben:** `ability_random_generation_test.dart`,
  `ui_random_ability_assignment_test.dart`. **Bestanden:** bis zum
  nächsten geprüften finalen Workflow-Lauf nicht nachgewiesen.
- **Ungeprüft:** Gesamtsuite, Debug/ARM64-APK auf finalem Commit,
  Realgerät/TalkBack. Keine lokale Flutter-/Dart-Toolchain verfügbar.
- **Kompatibilität:** SQLite 2, Kampagnen-JSON 1 und Hero-Schema
  unverändert; alte Speicherstände werden nicht neu berechnet.
- **Offen:** Protokollierung von Basisattributen und Würfeln als
  versionierte Provenienz; alle Hintergrund-Startmerkmale,
  Charaktererstellungs-Wizard und die übrigen 12 Klassenfunktionen.
- **Nächster Schritt:** bestätigte Attribut-Provenienz mit
  rückwärtskompatibler Speicherung; danach Hintergrundpakete mit
  Übungen/Talenten und ausdrücklicher Ausrüstungswahl.
- **Detailnachweis:** [Teilabdeckung](CHARACTER_CREATION_COMPLETE.md)
  und [Matrix](CHARACTER_CREATION_COVERAGE.json). Kein vollständiger
  SRD-Abschluss behauptet.

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
