# CODEX-CHECKPOINT – Würfelraunen

## Aktueller Entwicklungszyklus 25.10.2026 – Mehrdeutige Erzählreferenzen vor Provideraufrufen ablehnen (PR #167)

**Live-Stand:** `main=b60ffe7ff1aae502ea927cb77153b988be33e397`. Offen: Einzel-PRs #159–#163, kombinierter reviewbereiter [Integrations-PR #164](https://github.com/ManuEtt/Dnd/pull/164) (GitHub Actions [#40123094457](https://github.com/ManuEtt/Dnd/actions/runs/40123094457) grün, Commit `6776bd1`), [PR #165](https://github.com/ManuEtt/Dnd/pull/165) (lokaler Endzustandschutz, CI [#40170005782](https://github.com/ManuEtt/Dnd/actions/runs/40170005782) grün auf `9324af0`) und [PR #166](https://github.com/ManuEtt/Dnd/pull/166) (separater Kampf-Track). Neuer [PR #167](https://github.com/ManuEtt/Dnd/pull/167) auf Branch `fix/story-duplicate-context-ids-20261025`, gestapelt auf `integration/approved-pr159-163-20261024`. Keine fremden Branches geändert; `main` nicht überschrieben.

### IMPLEMENTIERT

`backend/src/story.ts`: `validateStoryTurnContext` erzwingt eindeutige IDs je bestätigter Thread-/NPC-Liste. Direkte Parsing-/Mockwege können doppelte Eingabereferenzen nicht mehr über `Map`/Set stillschweigend überschreiben. `backend/src/app.ts`: `/v1/story/advance` verweigert solchen Kontext als generischen HTTP 400 **vor** `narrator.advanceStory`; der kostenpflichtige Providerpfad wird gar nicht betreten. `backend/test/story.test.ts`: neue Domain- und HTTP-Regressionen mit explizitem 0-Aufrufzähler, gültiger Anfrage weiter mit `stateChanges: []`. Keine SQL-/JSON-/App-Version-/Regelmigration.

### GETESTET

**Bereits vorher bestätigt, nicht gleichzusetzen mit neuer CI:** #164 [CI #40123094457](https://github.com/ManuEtt/Dnd/actions/runs/40123094457), #165 [CI #40170005782](https://github.com/ManuEtt/Dnd/actions/runs/40170005782), jeweils grün. Der neue Quell-/Teststand ist auf eigenem Branch und PR #167 gesichert. **Finale #167-CI ist noch zu verifizieren:** [Checks](https://github.com/ManuEtt/Dnd/pull/167/checks). Bis zu tatsächlichem Erfolg keine Aussagen über bestandene neue Tests oder APK.

### NICHT GETESTET

Neuer finaler Backend-/Flutter-/Android-Code bis erfolgreicher GitHub-CI. Android-Echtgerät, historisches Nutzer-Spielstandsupgrade, produktive Signierung. Keine Aussage über globale Mehrinstanz-Providerkosten oder komplette SRD-Regelabdeckung.

### BLOCKIERT

Kein eigenes physisches Android-Gerät und keine produktiven Signaturschlüssel für die Geräteabnahme. CI verfügbar.

### NOCH NICHT IMPLEMENTIERT

Allgemeine mehrinstanzfähige Backend-Quoten, semantischer Spoilerschutz, vollständig automatisierte SRD-5.2.1-Regelwirkung. Dieser PR behebt ausschließlich die eindeutigen Story-Kontext-IDs und verändert keinen Kampfrule-Track.

### NÄCHSTER KONKRETER SCHRITT

Die unabhängige [PR-#167-CI](https://github.com/ManuEtt/Dnd/pull/167/checks) inklusive Backend, Python, Flutter, Android und native Tests auf **letztem PR-HEAD** prüfen, Fehler korrigieren, erst nach komplett grüner CI zur Review freigeben. Anschließend #164 nur nach ausdrücklichem Projekt-Review mergen; #165 und #167 getrennt auf das dann aktuelle main ausrichten und erneut CI prüfen, den parallelen #166 nicht doppelt integrieren.

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
