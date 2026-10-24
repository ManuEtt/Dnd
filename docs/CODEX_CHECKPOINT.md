# CODEX-CHECKPOINT – Würfelraunen

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
