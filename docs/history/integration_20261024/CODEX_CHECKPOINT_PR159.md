# CODEX-CHECKPOINT – Würfelraunen

## Aktueller Entwicklungszyklus – 24.10.2026, 14:53 Uhr MESZ (PR #159)

- **Produkt:** Würfelraunen – Der lebendige Spielleiter, Flutter-Alpha `0.8.38+88` aus `app/pubspec.yaml`. SQLite **2**, Kampagnen-Export-JSON **1**. Kein Versionssprung oder Migrationsbedarf.
- **Live-Git beim Abgleich:** `main` `b60ffe7ff1aae502ea927cb77153b988be33e397` (PR #158 integriert). Neuer Branch `fix/sending-percentile-block-validation-20261024` mit ursprünglicher Basis `dcb42c5`; Main nach SHA-geprüftem dateiselektiven Merge ohne Force-Push aufgenommen (`beef8f5`). Letzter ausführbarer Code-/Workflow-Restore-HEAD **`b22e2cbebfe98b87fba799de9536599f8ebb1f84`**; nachfolgende Dokumentations-Commits und aktuellster HEAD live unter [PR #159](https://github.com/ManuEtt/Dnd/pull/159/commits) kontrollieren.
- **Offene Pull Requests:** bei letzter GitHub-Abfrage ausschließlich [#159](https://github.com/ManuEtt/Dnd/pull/159), als Draft. PR #158 ist bereits in main gemergt, nicht erneut übernehmen.
- **Regelbezug:** `SPELL-ENTRY-SENDING`, SRD 5.2.1, Sending S. 161, CC BY 4.0, Status **partial**. Fachregel `SrdSendingRules.assessDelivery` unverändert: W100 erst bei bestätigter Nichtblockade und bestätigter anderer Ebene.

### IMPLEMENTIERT

`app/lib/ui/sending_attempt_dialog.dart`: Der W100 für verschiedene Ebenen wird nur dann angezeigt **und** an die rein lesende Vorschau durchgereicht, wenn zusätzlich `SendingBlockStatus.notBlockedConfirmed` bestätigt ist. Jeder neue Blockadestatus verwirft einen alten W100 und hebt die ausdrückliche Zustimmung auf. Damit entfällt die irreführende Eingabe bei unbestätigter oder bestätigter Blockade. Keine tatsächliche Nachrichtenzustellung, kein neues Story-/KI-Recht, keine Slot-/SQLite-Mutation über die UI.

`app/test/sending_attempt_dialog_test.dart`: Zwei neue Widgettests für beide Fakten, unbestätigte Blockade, bestätigte Blockade, Wechsel zurück, 5%-Fehlschlag, W100-Löschung und Zustimmung. Das Testformat wurde per **tatsächlicher** Dart-3.9-Ausgabe aus der GitHub-CI korrigiert; der temporär ergänzte Diagnose-Workflow wurde danach vollständig entfernt. `.github/workflows/android-build.yml` stimmt wieder bytegenau mit main überein. `README.md`, `CHANGELOG.md`, `DEVELOPMENT_STATUS.md` dokumentieren Änderungen und Grenzen.

### GETESTET

- GitHub-App-Schreibrechte, Main-SHA, PRs, Branch-Merge-Base, existierende Preview-Regeln und unveränderte Schema-Versionen geprüft.
- Früherer Main-Lauf [#40092582286](https://github.com/ManuEtt/Dnd/actions/runs/40092582286) auf `dcb42c5`: **completed/success**; PR-#158-Abnahme [#40093571340](https://github.com/ManuEtt/Dnd/actions/runs/40093571340) auf `80b615e`: **completed/success**. **Diese Läufe validieren nicht den neuen UI-Fix.**
- Frühere PR-#159-Läufe scheiterten bei `Dart-Formatierung prüfen`, unter anderem [#40095237772](https://github.com/ManuEtt/Dnd/actions/runs/40095237772). Verursachende Formatter-Differenz aus [Diagnose #40095535650](https://github.com/ManuEtt/Dnd/actions/runs/40095535650) identifiziert und im Quellcode korrigiert; kein Behaupten eines erfolgreichen Gesamttests.
- Vollständige neue CI auf `b22e2cb`: [PR-Workflow #40095701803](https://github.com/ManuEtt/Dnd/actions/runs/40095701803) und [Push-Workflow #40095698682](https://github.com/ManuEtt/Dnd/actions/runs/40095698682) wurden gestartet; bei Dokumentationsstand **noch kein success-Nachweis**. Aktuellen Commit und Abschlussstatus live abgleichen.

### NICHT GETESTET

Neue Flutter-Widgettests/Suite nach dem finalen Format-Fix, Flutter-Analyse und Android-APK/native Tests bis erfolgreichem neuen CI-Nachweis. Echter Android-Geräte-/Altspielstand-Update-Test und produktive Release-Signierung ebenfalls offen. In der aktuellen lokalen Containerumgebung sind Flutter und Dart **nicht installiert**; kein lokaler Checkout via Git, weil Netzwerk-DNS für github.com nicht erreichbar ist. Keine APK oder Quell-ZIP dieses PRs erstellt oder validiert; keine erfundenen Download-/Digest-Angaben.

### BLOCKIERT

Echte Geräteprüfung und lokaler Flutter-/Dart-Lauf mangels SDK/Testgerät; abschließende CI-Abnahme steht noch aus. Keine offenen SRD-Inventurlücken als vollständig erledigt melden.

### NOCH NICHT IMPLEMENTIERT

Tatsächliche Sending-Zustellung, empfängerbezogene automatische 8h-Weltzeitlogik und Antwort; Klassen-/Monster-/Zauberregeln insgesamt weiter unvollständig. Nebenhand-Verbündetenbestätigung bleibt eigenes künftiges fachliches Paket, unabhängig von PR #159.

### NÄCHSTER KONKRETER SCHRITT (genau einer)

**Den regulären CI-Lauf auf dem finalen PR-#159-HEAD zu Ende prüfen und erforderliche Fehler beheben.** Akzeptanz: `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, gezielte Sending-Tests, `flutter test`, Python-Projekt-/Importgrenzen-/SRD-Audit, Backend-Tests und Android-Debug/native Tests in einem tatsächlich erfolgreichen GitHub-Workflow. GitHub: [PR-Checks](https://github.com/ManuEtt/Dnd/pull/159/checks). Lokale Sollbefehle: `bash scripts/check.sh`, `python3 scripts/check_domain_boundaries.py`, `python3 scripts/srd_coverage.py --json`, `cd app && flutter test test/sending_attempt_dialog_test.dart && flutter build apk --debug`. Erst nach vollständigem Nachweis menschliches Review/Integration; keine eigenmächtige Main-Mutation.

### Änderungsprotokoll

- 24.10.2026, MESZ: Main/PRs überprüft, Dialogbedingung korrigiert, zwei Regressionen geschrieben, temporäre Formatanalyse betrieben und rückstandslos entfernt, Dokumentation erneuert. Kein Hintergrundlauf nach Sitzungsende.

---

## Vorheriger Entwicklungsstand – PR #158 (in main integriert)


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
