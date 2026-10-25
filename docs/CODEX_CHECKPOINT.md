# CODEX-CHECKPOINT – Würfelraunen

## Aktueller Integrationszyklus 25.10.2026 – vereinte Story-Sicherheitsgrenzen, PR #169

**Git-Stand:** `main=b60ffe7ff1aae502ea927cb77153b988be33e397` beim Start, **nicht gemergt**. Offen: original #159–#163, getestete Basis #164 (`6776bd1`, [CI #40123094457](https://github.com/ManuEtt/Dnd/actions/runs/40123094457)), gestapelter lokaler Schutz #165 (`9324af0`, [CI #40170005782](https://github.com/ManuEtt/Dnd/actions/runs/40170005782)), selbständiger Backendschutz #167 (`4072a6d`, [CI #40180964702](https://github.com/ManuEtt/Dnd/actions/runs/40180964702)) und lokaler Duplikatscheck #168 (`e157801`, [CI #40182898798](https://github.com/ManuEtt/Dnd/actions/runs/40182898798)). Kampf-PR #166 unabhängig. Neuer Branch `integration/story-safety-pr165-167-168-20261025`, PR #169, direkt aus #168.

### IMPLEMENTIERT
Die vollständigen Android-Schutzmaßnahmen aus #165 und #168 bleiben unverändert. Zusätzlich exakt die geprüften drei Backend-Quell-/Test-BLOBs aus #167 übernommen: `backend/src/story.ts`, `backend/src/app.ts`, `backend/test/story.test.ts`. Damit werden mehrdeutige IDs bei der Backend-Anfrage (HTTP 400, **0** KI-Aufrufe), bei lokaler generativer Verarbeitung und bei der tatsächlichen Spielzugübernahme geschützt. Keine parallele API- oder Datenmodellmigration. `backend/README.md` und fachlicher Backend-Beleg ebenfalls aus #167 übernommen. Eigenes kombiniertes Dokument `docs/STORY_SAFETY_INTEGRATION_20261025.md`; README/CHANGELOG/ROADMAP/DEVELOPMENT_STATUS/Checkpoint auf Gesamtstand ergänzt.

### GETESTET
**Je Quell-PR bestätigt, jedoch anderes Commit:** #164, #165, #167 und #168 vollständige grüne GitHub CI auf deren jeweils eigenem finalen HEAD. Die neue gemeinsame CI des PR #169 muss auf **dessen exaktem letzten HEAD** geprüft werden: [Checks](https://github.com/ManuEtt/Dnd/pull/169/checks). Bis zum bestätigten Ende ausdrücklich keine Erfolgsbehauptung für das neue Paket.

### NICHT GETESTET
Neue kombinierte Backend-/Android-Gesamt-CI bis zu deren Abschluss; Upgrade persönlicher Altkampagnen, echtes Android-Gerät, produktive Signierung. Der lokale Guard saniert **nicht** alle potenziellen doppelten NPCs in beliebigen Importen.

### BLOCKIERT
Reale Gerätetests/Release-Signaturschlüssel stehen in dieser Umgebung nicht zur Verfügung; CI verfügbar.

### NOCH NICHT IMPLEMENTIERT
Vollständiges SRD-5.2.1-Regelwerk, semantischer Spoilerschutz und global verteilter Rate-Limiter. Kampf-Light-PR #166 ist nicht in diesem Storypaket integriert.

### NÄCHSTER KONKRETER SCHRITT
Vollständigen finalen [GitHub-CI-Lauf #169](https://github.com/ManuEtt/Dnd/pull/169/checks) prüfen, bei Bedarf zielgenau reparieren, dann zur menschlichen Review freigeben. Nach ausdrücklicher Genehmigung zuerst #164 mergen, den Stack #169 gegen aktuelles main abgleichen und **erneut** CI prüfen. Die durch #169 ersetzten PRs #165/#167/#168 nicht zusätzlich ungeprüft mergen. #166 bleibt eigenständig.

---


## Aktueller Zyklus 25.10.2026 – lokale Story-Identitäten validieren (PR #168)

**Live geprüft:** `main=b60ffe7ff1aae502ea927cb77153b988be33e397`, offene PRs #159–#167; die Integrationsbasis [#164](https://github.com/ManuEtt/Dnd/pull/164) war grün auf `6776bd1` ([Actions #40123094457](https://github.com/ManuEtt/Dnd/actions/runs/40123094457)). Das darauf gestapelte [#165](https://github.com/ManuEtt/Dnd/pull/165) war grün auf `9324af0` ([Actions #40170005782](https://github.com/ManuEtt/Dnd/actions/runs/40170005782)). [#167](https://github.com/ManuEtt/Dnd/pull/167) hat eine unabhängige grüne Backend-ID-Validierung ([Actions #40180964702](https://github.com/ManuEtt/Dnd/actions/runs/40180964702)). PR #166 betrifft separate Kampfregeln. Kein PR wurde in dieser Sitzung gemergt.

### IMPLEMENTIERT
Neuer gestapelter Branch `fix/local-ai-duplicate-npc-ids-20261025` auf HEAD #165. `app/lib/story/ai_story.dart` validiert nun eindeutige gespeicherte `storyThreads[].id` und `npcs[].id` je Namespace, bevor Antwort-IDs durch Map/Set aufgelöst werden. Doppelte NPCs können nicht mehr durch einen Erzählerupdate kollektiv verändert werden; widersprüchliche Threadstatus nicht mehr zusammenfallen. Der bestehende zweite `AiStoryStep.fromJson`-Check in `applyAiStoryStep` verhindert veralteten Identitätskontext.

Drei neue `app/test/ai_story_test.dart`-Regressionen für NPC-Duplikat mit Stale-Replay, Thread-Duplikat mit widersprüchlichem Status und gültige Überschneidung **zwischen** Namespaces. Dokumentation in `docs/STORY_LOCAL_DUPLICATE_IDS_20261025.md`; README/CHANGELOG/Status/Roadmap fortgeschrieben. Keine weiteren Änderungen an Android-Schema oder gemeinsamen Modell-/Controllerdateien.

### GETESTET
Alte Basis-CI #165 vollständig grün auf anderem SHA. **Neuer letzter #168-Code noch nicht durch die eigene abschließende CI abgenommen.** [CI-Checks](https://github.com/ManuEtt/Dnd/pull/168/checks) auswerten; Ergebnisse erst nach tatsächlichem Erfolg nachtragen.

### NICHT GETESTET
Finale GitHub-CI für das neue Paket, echter Android-Gerätetest, historisches Savegame-Upgrade, produktive Signierung. Keine globale Campaign.fromJson-Duplikatsanierung behaupten.

### BLOCKIERT
Kein physisches Gerät oder produktiver Signaturschlüssel; CI verfügbar.

### NOCH NICHT IMPLEMENTIERT
Vollständige SRD-5.2.1-Automatik, globale NPC-Eindeutigkeit in sämtlichen Importen und semantischer Spoilerschutz.

### NÄCHSTER KONKRETER SCHRITT
CI #168 mit Dart-Format/Flutter-Vollsuite, Python-/Backendtests und Android-Build/native/Alpha-Artefakten vollständig prüfen; bei Fehlern korrigieren. Nach Erfolg PR reviewbereit stellen. Anschließend Stack #164 → #165 → #168 reviewen/integrationsreif gegen aktuelles main prüfen. Parallel PR #167 und #166 unverändert erhalten, keine Double-Merges.

---


## Aktueller Arbeitszyklus 25.10.2026 – lokaler Story-Endzustandschutz, PR #165

**Live-Abgleich:** `main=b60ffe7ff1aae502ea927cb77153b988be33e397` und PRs #159–#164 offen. Der konsolidierte [PR #164](https://github.com/ManuEtt/Dnd/pull/164) steht auf Commit `6776bd1bdfef648431da8b20780053e0860d998d`, [GitHub-CI #40123094457](https://github.com/ManuEtt/Dnd/actions/runs/40123094457) vollständig erfolgreich: 100 Python-, 38 Backend- und 1516 Flutter-Tests, Android Debug und native Tests grün. **#164 ist reviewbereit, aber nicht gemergt.**

**Eigener Branch:** `fix/local-story-terminal-thread-guard-20261025`, als **Stacked PR [#165](https://github.com/ManuEtt/Dnd/pull/165)** direkt auf dem bereits geprüften Integrationsbranch, ohne #164/`main` zu überschreiben. App `0.8.38+88`, SQLite 2, Export-JSON 1.

### IMPLEMENTIERT

`app/lib/story/ai_story.dart::AiStoryStep.fromJson` prüft neu gegen die aktuell bestätigten Threadstatus der lokalen Kampagne: `resolved` und `abandoned` dürfen von einem generativen Vorschlag nicht wieder auf `open` oder auf den jeweils anderen Terminalstatus gesetzt werden. Eine rein narrative Notiz ohne Statuswechsel bleibt möglich; explizites manuelles Öffnen via `saveStoryThread` bleibt autoritativ. Beim `applyAiStoryStep` verhindert die bestehende zweite lokale Validierung die Übernahme einer zwischenzeitlich veralteten Antwort.

Drei neue Domain-/JSON-/Eventregressionen in `app/test/ai_story_test.dart` prüfen beide Terminalzustände, gespeicherte Altformate, freiwilliges Wiederöffnen und Stale-Antwort ohne Mutation. Dokumentiert in `docs/STORY_LOCAL_TERMINAL_GUARD_20261025.md`. Backend selbst, KI-Zugang, SRD-Regelautorität und Spielstandsformat unverändert.

### GETESTET

**Basis #164:** [CI #40123094457](https://github.com/ManuEtt/Dnd/actions/runs/40123094457) grün, aber für **anderen HEAD**. **Neue #165-CI** noch zu verifizieren: [Checks](https://github.com/ManuEtt/Dnd/pull/165/checks). Neue Code- und Testdateien auf eigenem GitHub-Branch committet; keine unbelegte Erfolgsmeldung.

### NICHT GETESTET

Vollständiger neuer GitHub-Actions-Lauf auf letztem #165-HEAD, echtes Android-Gerät, Upgrade eines persönlichen Spielstands und produktive Signierung. Die neue lokale Ablehnung ist keine semantische Plotauswertung.

### BLOCKIERT

Kein reales Testgerät oder produktiver Signierschlüssel; Flutter/Dart lokal nicht installiert. GitHub Actions verfügbar.

### NOCH NICHT IMPLEMENTIERT

Vollständige SRD-5.2.1-Regelabdeckung, NPC-basierte allgemeine Positionsautomatik, semantischer Plot-Geheimnisschutz, produktiver Mehrspielerbetrieb. Keine automatische Integration nach main.

### NÄCHSTER KONKRETER SCHRITT

Neuen finalen GitHub-CI-Lauf für #165 vollständig prüfen (Python, Backend, Dart-Format, Flutter-Analyse/Vollsuite, Android-Debug, Gradle, Alpha). Falls rot, konkrete Fehler korrigieren; erst bei vollem Grün zur Review stellen. Danach zuerst #164 mit Freigabe in `main` integrieren und #165 **neu gegen dann aktuelles main ausrichten** und testen. Alte PRs nicht doppelt mergen.

---


## Aktuelle Integrationsübergabe 24.10.2026 – PR #164

**Live-Basis:** `main=b60ffe7ff1aae502ea927cb77153b988be33e397` bei Beginn, App `0.8.38+88`, SQLite 2, Export-JSON 1. **Arbeitsbranch:** `integration/approved-pr159-163-20261024`, eigener Integrations-[PR #164](https://github.com/ManuEtt/Dnd/pull/164). Original-PRs [#159](https://github.com/ManuEtt/Dnd/pull/159), [#160](https://github.com/ManuEtt/Dnd/pull/160), [#161](https://github.com/ManuEtt/Dnd/pull/161), [#162](https://github.com/ManuEtt/Dnd/pull/162) und [#163](https://github.com/ManuEtt/Dnd/pull/163) bei Erstabgleich alle offen und reviewbereit, jeweils konfliktfrei gegenüber bisherigem main. Kein Commit auf main, kein Force-Push, keine Löschung anderer Branches.

### IMPLEMENTIERT

Ein neuer gemeinsamer Baum bewahrt **unverändert** die fachlichen Code- und Testdateien aller fünf isolierten PRs. Die ausführbaren Quelldateien und die JSON-SRD-Anforderungsmatrix hatten keine konkurrierenden Pfadänderungen. Kombiniert werden der Sending-W100-Dialog, die an tatsächliche Nebenhandattacke gebundene Verbündetenbestätigung, unveränderliche terminale Erzähler-Handlungsstränge, fail-closed Rate-Limiter-Kapazität und die Prüfung kompletter wörtlicher Plot-Secret-Veröffentlichungen.

Fünf überlappende Dokumentationsserien wurden bewusst konsolidiert: CHANGELOG, DEVELOPMENT_STATUS, ROADMAP und backend/README behalten alle PR-spezifischen Erweiterungen; die aktuelle README enthält eine gemeinsame Übersicht statt widersprüchlicher fünf Einzel-HEADs. Zusätzlich bleiben die fünf originalen CODEX_CHECKPOINT-Dateien als historische Kopien in `docs/history/integration_20261024/` verfügbar. Die vier Fachbelege der PRs #160–#163 sind unverändert enthalten.

Die GameController-/SQLite-Atomarität, `StoryRuleBoundary`, offenes Kampagnen-JSON v1, SQLite v2 und `pubspec.yaml` wurden nicht umgestellt. Das SRD-Inventar `CLASS-SCHURKE-1-BASE-SNEAK-ATTACK-1` bleibt `partial`; die Regelregister wurden nicht als vollständig bezeichnet. Die Backend-Spoilerprüfung ist **nur wörtlich**, kein semantischer Filter. Die Quoten sind nur pro Backendprozess, nicht zwischen Serverinstanzen geteilt.

### GETESTET

**Einzel-PR-CIs unabhängig erfolgreich auf den jeweiligen HEADs:**

- #159 [Actions #40095802925](https://github.com/ManuEtt/Dnd/actions/runs/40095802925), `15c1626`.
- #160 [Actions #40100211878](https://github.com/ManuEtt/Dnd/actions/runs/40100211878), `6f2ebbc`.
- #161 [Actions #40113090963](https://github.com/ManuEtt/Dnd/actions/runs/40113090963), `9428738`.
- #162 [Actions #40115897734](https://github.com/ManuEtt/Dnd/actions/runs/40115897734), `56128f2`.
- #163 [Actions #40118411876](https://github.com/ManuEtt/Dnd/actions/runs/40118411876), `032af6a`.

Diese Nachweise belegen **nicht automatisch** den kombinierten Code. Die neue [CI von PR #164](https://github.com/ManuEtt/Dnd/pull/164/checks) muss Format, Flutter-Analyse/Volltests, alle Backend-/Python-/Boundary- und SRD-Basisaudits sowie Android-/native Tests erfolgreich durchlaufen. Aktueller Abschlussstatus noch **ausstehend**.

### NICHT GETESTET

Vollständiger kombinierter Stand bis zur neuen CI; Installation auf realem Android-Gerät, Aktualisierung persönlicher Altkampagnen, produktive Release-Signierung. Keine Behauptung automatischer Secret-Freigaben, vollständiger SRD-Implementierung oder Online-Multiplayer-Reife.

### BLOCKIERT

Kein echtes Android-Testgerät oder produktiver Signierschlüssel in dieser Entwicklungsumgebung. CI ist verfügbar und erlaubt technische Android-Testartefakte.

### NOCH NICHT IMPLEMENTIERT

Beobachtbare KI-/NPC-Nachrichten-Zustellung für Sending, vollständige SRD-5.2.1-Ziel-/Positionsmechanik und Zauberwirkungen, semantischer Geheimnisschutz, autoritativ bestätigtes Freigeben eines bislang geheimen Plots, global verteilter Rate-Limiter sowie öffentliche produktive Mehrspieler-Architektur.

### NÄCHSTER KONKRETER SCHRITT

Die finale CI des Integrations-PRs #164 prüfen und etwaige gemeinsame Regressionen beheben. Erst bei tatsächlich komplett grüner CI den PR reviewbereit stellen. Vor Merge alle fünf ursprünglichen PRs anhand ihrer Änderungen als durch #164 ersetzt markieren; nicht dieselben Änderungen zweimal mergen. Reviewer muss Integration ausdrücklich genehmigen. Eine reale APK-Installation bleibt gesondert nötig.

### Historische Checkpoints

Die ursprünglichen Checkpoints der PRs #159–#163 sind als unveränderte Schnappschüsse in `docs/history/integration_20261024/` erhalten; folgende frühere Hauptbranch-Übergabe bleibt aus Gründen der Nachvollziehbarkeit erhalten.

---

## Historischer Hauptbranch-Checkpoint vor Integration


Stand **2026-10-24T12:20:50+00:00**, lokal vollständig abgenommenes Paket. Frühere operative Angaben vollständig in [Historie](history/main_0.8.37_20261024/CODEX_CHECKPOINT.md) erhalten. Vor Wiederaufnahme Live-Git/PR/CI erneut prüfen.

## Git und Produkt

- Produktversion **0.8.38+88**; Branch `fix/sneak-attack-offhand-weapon-20261024`.
- Basis-main **dcb42c5efff40a757994d4f5b5f8e98b2ff128e9**, PR #157 bereits integriert, keine offenen PRs bei der Bestandsaufnahme.
- Main-CI [40092582286](https://github.com/ManuEtt/Dnd/actions/runs/40092582286) auf dcb42c5: **success** zum Dokumentationszeitpunkt. Vorher vollständig grüner Main-Lauf [40084074765](https://github.com/ManuEtt/Dnd/actions/runs/40084074765) auf3b5affd. Kein Nachweis für neue Änderungen.
- Früheres Paket PR #147 seit f99f27ac zusammengeführt; eigener integrierter Code a6a949c in CI40059091439 erfolgreich. Späterer Quellencheckpoint d54f554 mit ZIP/Patch separat erhalten; nicht über neueren Main kopiert.
- Funktionaler Code **aa79ce593790e5763e9125743b0adeab55b581d5**, auf GitHub gesichert. [PR #158](https://github.com/ManuEtt/Dnd/pull/158) offen und gegen Basisdcb42c5 konfliktfrei. Eigene Code-CI40093220106 auf aa79ce5 gestartet; aktuelle finale Checks **live am [PR](https://github.com/ManuEtt/Dnd/pull/158/checks)** prüfen. Abschlussdokumentation verändert keinen ausführbaren Code; der finale Dokumentations-HEAD wird im externen Artefaktmanifest ausgewiesen. Main nicht direkt verändert.

## IMPLEMENTIERT

Hinterhältiger Angriff prüft bei bestehender Nebenhandauflösung `pendingRoll.weaponId` statt der angelegten Hauptwaffe. Der Helper erhält optional `attackingWeaponId`; alte Hauptwaffenaufrufe bleiben gültig. Eindeutiger vorhandener Inventareintrag mit positiver Menge erforderlich. Kein Rückfall auf Hauptwaffe bei explizit ungültiger Referenz.

Beide gemischten Waffenrichtungen, zulässiger Zusatzschaden, Krit/Miss und bestehende einmalige Nutzung pro eigenem Zug sind angebunden. Die bisherige Abenteueraktion und deren Würfel-/Schadensjournal verwenden die Regel direkt; kein neuer Menüpfad. Die Änderung erfindet keinen Vorteil und erweitert weder Kampfstil-/Bonusaktionsvoraussetzungen noch die manuelle Verbündetenbestätigung auf Nebenhand.

Dateien: class_combat_features.dart, game_engine.dart, pubspec.yaml, ein bestehender Helpertest und neue sneak_attack_weapon_context_test.dart, Regelregister und Statusdokumentation. SQLite2 und Kampagnen-JSON1 unverändert; keine Migration. Story/KI/Backend/Berechtigungen unverändert. Requirement `CLASS-SCHURKE-1-BASE-SNEAK-ATTACK-1` bleibt partial, SRD5.2.1 Rogue/Sneak Attack S.61–62, CC BY4.0.

## GETESTET

- **27** bestehende Domain-/Kampf-/SQLite-/Widgetregressionen einschließlich zusätzlichem Waffenreferenztest erfolgreich.
- **8** neue tatsächliche Kampf-/Speichertests erfolgreich: beide Waffenrichtungen, zulässiger/unzulässiger Krit, Miss, aufgehobener Vorteil, gemeinsame Nutzung und erneute Freigabe im nächsten Zug; JSON-Import/Export, SQLite schließen/öffnen, Controller-Auflösung, Ereignisrekonstruktion und doppelte Auflösung.
- Neue Tests verwenden bereits bestätigten, normal importierten PendingRoll-Vorteil. Sie behaupten keinen neuen Vorteilsauslöser in der Oberfläche.
- Flutter3.35.7/Dart3.9.2, Java17, Node22.14 lokal geprüft. Gezielter Dart-Formatter ohne Änderungen.
- Protokolle: `/workspace/validation/20261024-offhand-existing-regressions.log`, `20261024-weapon-context-tests.log`. Gesamtlauf erfolgreich: **1505 Flutter-, 100 Python-, 31 Backend-Tests**, Typecheck/Build,356 Dateien ohne Formatänderung und Analyse ohne Befund; Backend-Protokolltest eingeschlossen. Log: `20261024-offhand-full-check.log`.
- Android: neue Debug-APK und ARM64-Alpha aus validiertem Quell-ZIP gebaut; **12 native Tests**, 0 Fehler/übersprungen. CRC, aapt-Version/ABIs, Signatur und **474 identische ausführungsrelevante Quelldateien** zwischen ZIP, Buildkopie und Branch geprüft. Version 0.8.38/Build 88, minSdk24/targetSdk36; lokale Debug-Testsignatur, keine Gerätefreigabe.
- Story-/Rules-Importgrenzen erfolgreich; Coverage 1.419 Prüfaufträge, 9 Inventurlücken, keine globale Quote.

## NICHT GETESTET

Echtes Android-Gerät, Altspielstand-Update und produktive Release-Signierung offen. GitHub-Prüfungen sind ein eigener Nachweis; deren aktuellen finalen HEAD und Status unter [PR158/checks](https://github.com/ManuEtt/Dnd/pull/158/checks) lesen. Lokale und GitHub-APKs tragen eigene Archiv-/Signaturdigests. Kein älterer grüner Lauf ist eine Freigabe für ungeprüfte neue Codeänderungen.

## BLOCKIERT

Kein Android-Realgerät und kein produktiver Signaturschlüssel. Lokale SDKs verfügbar; frühere fehlende-SDK-Angaben sind historisch. Bisher keine Fehler in den abgeschlossenen neuen Tests.

## NOCH NICHT IMPLEMENTIERT

Manuelle Verbündetenbestätigung für Nebenhand, neue Vorteilsquellen, allgemeine Positionsverwaltung, Gelegenheitsangriffe und vollständiges SRD. Sending-Dialog samt Slot-/Journalpfad aus Main erhalten; Nachrichtenzustellung/Antwort/8h-Weltuhr weiterhin offen. Kleiner beobachteter Sending-UI-Fall: W100-Feld erscheint auch bei unbestätigter Blockade; separat behandeln.

## Abschluss und nächster Schritt

Lokaler Gesamtcheck, beide APKs und native Tests abgeschlossen. Branch und PR158 gesichert. Abschließendes ZIP/Patch mit `scripts/create_checkpoint.py --output-dir /workspace/artifacts --base dcb42c5efff40a757994d4f5b5f8e98b2ff128e9 --label offhand-waffenpruefung-abschluss` erzeugen bzw. über externen Artefaktindex wiederfinden. Die endgültigen Namen, HEADs und SHA256 stehen im Manifest und SHA256SUMS; ältere Pakete bleiben erhalten.

Build-Quell-ZIP: `Wuerfelraunen_0.8.38+88_20261024T121355251852Z_offhand-waffenpruefung-vor-abnahme_Vollprojekt.zip`, SHA256 **93d18f63ae4542ee7b93b613aac18d31e206c8f6c883127aaecb094ba5cc6f31**,637 Dateien,Code aa79ce5. Neue APKs unter `/workspace/artifacts/0.8.38+88/`: Debug SHA256 `cab6226cb0b71fdbbc1e9ed184e66a67d8c6a80560f5c38c9402f18c0eb59fb5`; ARM64 SHA256 `a0e31900676e923ea3d001df95e1b3bae16016b001507cdeb9c264eb3f96bbd9`. Gesamtprotokoll `Wuerfelraunen_0.8.38+88_Pruefergebnisse.json`, einzelne APK-Prüfungen und SHA-Dateien daneben. Aktuelle Actions-Quell-/APK-Artefakte am PR nach tatsächlicher Erzeugung auswählen. [Importanleitung](ARTIFACT_IMPORT_20261024.md) und [Validierung](VALIDATION_0_8_38_20261024.md).

Genau ein nächstes fachliches Paket: **Verbündetenbestätigung für die tatsächlich angreifende Nebenhandwaffe**. DoD: Finesse/Fernkampf der echten Waffe, an Ziel/Probe gebundene Zustimmung, keine Nutzung vor Treffer, gemeinsame einmalige Zugnutzung, Krit/Miss, stale Revision, JSON/SQLite-Neustart; alte Hauptwaffen unverändert.

Prüfbefehle: `bash scripts/check.sh`, `python3 scripts/check_domain_boundaries.py`, `python3 scripts/srd_coverage.py --json`, `cd app && flutter build apk --debug`, `cd android && bash ./gradlew :app:testDebugUnitTest --no-daemon`. Toolchainpfade dieser Umgebung: `/workspace/validation/TOOLCHAIN.md`. Keine automatische Fortsetzung außerhalb aktiver Sitzung.
