# CODEX-CHECKPOINT – Würfelraunen

## Aktueller Inkrementstand 24.10.2026 (MESZ) – Nebenhand-Verbündetenbestätigung

- **Produkt:** Würfelraunen – Der lebendige Spielleiter, App `0.8.38+88`; SQLite 2, Export-JSON 1; keinerlei Migration.
- **Live-Basis:** `main` `b60ffe7ff1aae502ea927cb77153b988be33e397`. PR #158 integriert. **Offene PRs bei Abgleich:** [#159](https://github.com/ManuEtt/Dnd/pull/159) (Sending-W100, grün und reviewbereit), [#160](https://github.com/ManuEtt/Dnd/pull/160) (dieses Inkrement, Draft bis CI). Arbeitsbranch `feature/sneak-attack-offhand-ally-20261024`; Kopf und neue Commit-SHAs jederzeit am PR prüfen. Kein direkter main-Push, kein Force-Push.
- **Anforderung:** `CLASS-SCHURKE-1-BASE-SNEAK-ATTACK-1` **partial**, Wizards of the Coast SRD 5.2.1 Rogue/Sneak Attack S. 61–62 (CC BY 4.0). Kein Gesamtprozentsatz aus den 1.419 Inventurpunkten abgeleitet.

### IMPLEMENTIERT

`app/lib/domain/sneak_attack_ally_rules.dart`: Für `offhandAttack` nur zugelassene laufende Zweiwaffen-Bonusaktion und tatsächlich bestätigte Inventarwaffe akzeptieren. Vor Freigabe Held/Ziel/Zug, ungenutzten Sneak Attack, Finesse-/Fernkampfwaffe, kein Netto-Nachteil, beide manuell bestätigten Verbündetenfakten prüfen. Die beiden Fakten bleiben an Kampagnen-, Ziel- und ausstehende Wurf-ID gebunden.

`app/lib/domain/models.dart`: bestehendes `SneakAttackAllyConfirmation`-Schema 1 für Haupt- **oder** Nebenhand-Waffenangriff validieren; kein neues Spielstandsformat. `app/lib/domain/game_engine.dart`: bestehende Bestätigungsmeldung allgemein auf erlaubte Waffenangriffe erweitern. `app/lib/ui/app.dart`: bestätigten Verbündeten auch bei offenem Nebenhandwurf mit Entfernungsaktion anzeigen. Controller/Regelwürfel bleiben unverändert. KI-/Story-Importgrenze und externe Erzähldienste unverändert.

**Neu:** `app/test/sneak_attack_offhand_ally_test.dart` mit Treffer/Krit/Miss, ungültiger Nebenhandaxt, Nachteil, falschen/stale IDs, Wiederholung, SQLite-Reopen, JSON-Sicherung, doppelter Auflösung; `app/test/sneak_attack_ally_ui_test.dart` mit zwei Nebenhand-Widgets. Neues Quelldokument `docs/SRD_SNEAK_ATTACK_OFFHAND_ALLY_20261024.md` und Anforderungsmatrix im Status `partial` ergänzt.

### GETESTET

- Letzter vor diesem Inkrement vollständig grüner, **anderer** Code-Stand: [CI #40095802925](https://github.com/ManuEtt/Dnd/actions/runs/40095802925), SHA `15c1626057adb33f40d0acbe6e228f30f606d007`, PR #159. Auf `main` vorherige erfolgreiche [CI #40092582286](https://github.com/ManuEtt/Dnd/actions/runs/40092582286), SHA `dcb42c5`. Diese Läufe sind kein Nachweis für PR #160.
- Erste PR-#160-Läufe scheiterten an Dart-Formatabweichung in drei Dateien. Temporärer Formatter-Diagnoseworkflow gab exakten Diff aus; dieser wurde auf Branch übernommen, und die GitHub-Workflow-Datei anschließend exakt auf `main` zurückgesetzt.
- Diagnose-Lauf auf nicht finalem Quellstand: **1.513 Flutter-Tests bestanden, 1 neuer Test fehlgeschlagen**. Ursache war keine Regelabweichung, sondern ein vollständiger JSON-Gleichheitsvergleich, der vom erlaubten automatischen Katalog-Stat-Import betroffene Inventardaten einbezog. Testassertion nach Datenmodellprüfung auf identische offene Probe/Bestätigung präzisiert. Bereits erfolgreich: beide neuen UI-Tests.
- Frischer kompletter Code-/CI-Erfolg und APK des **endgültigen** Branch-HEAD zum Zeitpunkt dieses Checkpoints **ausstehend**, siehe [PR #160 – Checks](https://github.com/ManuEtt/Dnd/pull/160/checks).

### NICHT GETESTET

Die korrigierte finale vollständige Flutter-Suite und Android-APK/native Tests bis zum erfolgreichen neuen CI-Lauf. Echter Android-Gerätetest, Upgrade eines historischen persönlichen Spielstands, produktive Release-Signierung. Neue ZIP-/APK-/Digest-Links für PR #160 erst nach sichtbaren GitHub-Artefakten ergänzen.

### BLOCKIERT

In dieser Sitzung lokal kein Flutter-/Dart-SDK und keine GitHub-DNS-Erreichbarkeit für einen vollen Checkout; die unabhängige GitHub-CI ist verfügbar. Kein reales Android-Gerät und keine produktive Signatur.

### NOCH NICHT IMPLEMENTIERT

Allgemeine Mehrakteur-Positionsverwaltung, Gelegenheitsangriffe, nicht unterstützte Waffenmeisterschaften und vollständige SRD-Abdeckung. Weder erzählerische Behauptungen noch KI-NPCs dürfen Regelzustand bestätigen.

### NÄCHSTER KONKRETER SCHRITT – Definition of Done

Den vollständigen **finalen** GitHub-CI-Lauf von [PR #160](https://github.com/ManuEtt/Dnd/pull/160/checks) auswerten, etwaige verbleibende Fehler beheben und nach grüner CI PR reviewbereit machen. Gates: `python3 scripts/verify_project.py`, `python3 scripts/check_domain_boundaries.py`, `python3 scripts/srd_coverage.py --json`, `python3 -m unittest discover -s scripts/tests -v`, Backend-Typecheck/Build/Tests, `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, komplette `flutter test`, `flutter build apk --debug` und native Gradle-Tests. Vor Integration mit dem dann aktuellen main neu abgleichen; beide parallelen PRs nicht ohne Review mergen.

### Änderungsprotokoll

- 24.10.2026 (MESZ): Live-Bestand geprüft, zulässigen Nebenhand-Verbündetenpfad samt JSON/UI erweitert; deterministische Kampf-/SQLite-/Widgetregressionen ergänzt; Formatter- und Testassertionsfehler der Vorläufer-CI repariert; CI-Abnahme ausstehend. Kein Hintergrundlauf außerhalb dieser Sitzung.

---

## Vorherige Übergabe (PR #158, inzwischen integriert)


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
