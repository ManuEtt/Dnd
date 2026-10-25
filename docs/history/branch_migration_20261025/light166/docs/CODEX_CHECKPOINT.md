# CODEX-CHECKPOINT – Würfelraunen

Stand **2026-10-25T06:38:51+00:00**. Light-Nahkampfpaket lokal vollständig abgenommen. Bei Wiederaufnahme zuerst tatsächliche Branches, PRs und CI prüfen.

## Git und Produkt

- **0.8.39+89**, Branch `feature/light-weapon-bonus-attack-20261024`, [PR166](https://github.com/ManuEtt/Dnd/pull/166). Geprüfter Funktionscommit **2ca8993b7f8fd71ff21766b4fa7290caa7a961ff**; spätere Abschlussdokumentation verändert keinen ausführbaren Code.
- Patchbasis **6f2ebbc893fb5ee053d069410a103a102662aa4d**, HEAD des weiterhin separat reviewten PR #160. Gestapelter PR gegen `feature/sneak-attack-offhand-ally-20261024`; nicht mit einer Main-Freigabe verwechseln.
- Main bei letztem Abgleich b60ffe7, grüne Main-CI40094794864. PR159–163 jeweils separat CI-grün, Sammel-PR164 mit CI40123094457 auf6776bd1 grün. Keine direkte Mainänderung oder fremde Branchlöschung.
- Vollständig erfolgreicher Basislauf [40100211878](https://github.com/ManuEtt/Dnd/actions/runs/40100211878) auf 6f2ebbc. Eigene Code-CI40169504395 auf 2ca8993 gestartet; **aktuelle finale eigene Checks unter [PR166/checks](https://github.com/ManuEtt/Dnd/pull/166/checks)**. Finalen Dokumentations-HEAD und tatsächlich beobachtete CI-/Artefaktnachweise im externen Dateimanifest/Artefaktindex nachführen; keine ältere grüne CI als neue Freigabe ausgeben.

## IMPLEMENTIERT

Allgemeiner Light-Nahkampfbonus ohne Fighter-Stilpflicht nach abgeschlossener eigener Angriffsaktion. Andere eindeutige leichte Nahkampfwaffe, freie Bonusaktion, eigenes Ziel/Zug und bekannte Handlungsfähigkeit erforderlich. Deutscher Abenteuerdialog erfasst Waffe, Stärke/Finesse-Geschicklichkeit, ausdrücklich bestätigte Übung und gehaltene Waffen. Vorschau und Zustimmung vor Buchung; Eingabeänderung entzieht Zustimmung. Freier Texteingabeentwurf bleibt erhalten; ungeladene Outbox sperrt Aktionen.

Kein positiver Attributsschaden ohne Stil; negative Werte bleiben. Bestehender Fighter-Stil fügt einmal hinzu. Rage prüft die tatsächliche Waffen-ID und deren Attribut; kritische Treffer verdoppeln nur Würfel. Negative Waffensubtotalen werden erst nach Rage-/Sneak-Boni auf insgesamt null begrenzt, auch bei Hauptwaffen.

Neue optionale PendingRoll-Felder offhandAttackAbility/offhandWeaponProficient/offhandWeaponsHeldConfirmed nur gemeinsam für Nebenhand, Haltung=true; false bei Übung bleibt erhalten. Alte Fighter-Stil-Proben ohne Felder weiterhin gültig. Importvertrag vor RNG, Engine/Controller/SQLite atomar und revisionsgeschützt. SQLite 2/Kampagnen-JSON 1 unverändert, keine Migration. Story/KI erzeugen keine Fakten. Vorhandener PR160-Verbündetenpfad bleibt angebunden.

Dateien: TwoWeaponFightingRules, Models, GameEngine, GameController, RulesEngine, CombatClassActions, Adventure-UI, neuer Dialog, Version, drei Testdateien und Status-/SRD-Dokumentation. Backend/Anbieter/Berechtigungen unverändert. RULE-COMBAT-TWO-WEAPON-FIGHTING **partial**, SRD5.2.1 Light S.89 / TWF S.88 / Rage S.29 / Damage Rolls S.16, CC BY4.0.

## GETESTET

- Vollständiges scripts/check.sh **1544 Flutter-, 100 Python-, 31 Backend-Tests**, Backend-Typecheck/Build,360 Dart-Dateien ohne Formatänderung, Analyse ohne Befund; Backend-Protokolltest enthalten.
- Gezielt55 Regel-/Kampf-, 12 Zweiwaffen-, 7 neue Widget- und34 bisherige Sneak-/SQLite-/Widgetfälle erfolgreich. Unter anderem Ablehnung vor RNG, Waffen-/Attributs-/Übungsbindung, Krit/Miss/Rage/Sneak/negative Summen, gemeinsame Zugnutzung, Legacy-JSON, Backup, SQLite-Neustart/Rekonstruktion, stale Controller und später SQL-Rollback.320/360dp, Schrift1,8, Tastatur260dp und reale Adventure-Controller-Verbindung getestet.
- Story-/Rules-Importgrenzen erfolgreich. Coverage weiterhin1419 Prüfaufträge/9 Inventurlücken; keine globale Quote.
- Debug-APK und ARM64-Alpha aus vollständigem validiertem Quell-ZIP gebaut; 12 native Tests, 0 Fehler/übersprungen. CRC/aapt-Version/ABIs/apksigner erfolgreich,478 ausführungsrelevante Dateien zwischen ZIP, Buildkopie und Branch per SHA256 identisch. Version 0.8.39/Build 89, minSdk24/targetSdk36; lokale Debug-Testsignatur.
- Erster Gesamtcheck für notwendige Rage-Ergänzung bewusst gestoppt und vollständig neu ausgeführt. Erster Debug-Build scheiterte an vollem32GB-Laufwerk; ausschließlich alte temporäre Build-Caches entfernt, archivierte Quellen/APKs/ZIPs erhalten. Wiederholung erfolgreich. Früher falscher Testdateiname korrigiert; alle tatsächlichen Produkttests vollständig ausgeführt.
- Logs unter `/workspace/validation/`:20261025-light-full-check.log,20261025-light-class-damage-final.log,20261024-light-domain-full.log,20261024-light-offhand-ui.log,20261024-light-legacy-regression.log,20261025-light-debug-build-retry.log,20261025-light-native-tests.log,20261025-light-alpha-build.log.

## NICHT GETESTET

Reales Gerät, historischer App-Updatepfad und produktive Signierung. Eigene finale GitHub-Checks sind unabhängig von lokalen Ergebnissen zu lesen. Nicht mit dem separaten Integrations-PR164 kombinierter Main-Stand, bis dessen Quellen/CI tatsächlich gemeinsam geprüft sind.

## BLOCKIERT

Kein Android-Realgerät oder produktiver Signaturschlüssel. Lokale SDKs verfügbar, Laufwerk nach Cache-Bereinigung wieder mit freiem Platz. Voriger UI-Agent erreichte nach7 grünen Tests sein Kontingent; Root hat das Paket gesichert und abgeschlossen. Kein weiterer großer Funktionsstart vor Checkpoint.

## NOCH NICHT IMPLEMENTIERT

Light-Fernkampf/Munition, Nick, freie Attackenreihenfolge innerhalb Extra Attack, allgemeine Waffenwechsel/Positionen und weitere Stilquellen. Strukturierte Item-Overrides und vollständiges SRD offen; keine erfundenen Waffen/Übung aus KI-Erzählung.

## Artefakte

Lokaler Ordner `/workspace/artifacts/0.8.39+89/`: Debug-SHA256 `c8ebcfc66d2bda13addfe850fdf65c46495646711fa0d5aab9cd8f03eb6ab22a`; ARM64-SHA256 `49e5a9fa43057e846f1b11e2adaf3fbb215f5a52d18543515406e51e4af1a2bd`. Gesamtbericht Wuerfelraunen_0.8.39+89_Pruefergebnisse.json, Einzelprüfungen und SHA-Dateien daneben. Lokale und GitHub-Builds haben getrennte Signatur-/Archivdigests.

Tatsächliche Buildquelle `Wuerfelraunen_0.8.39+89_20261025T063244516115Z_light-vor-android_Vollprojekt.zip`, SHA256 **972540252f798ca086211244308ebf753dd0fea58d31cf1c28945c6ac26f8e75**,646 Dateien,Code 2ca8993. Finales Vollprojekt-ZIP/Patch mit Abschlussdokumentation und Manifest durch scripts/create_checkpoint.py gegen 6f2ebbc erzeugen/aus externem Artefaktindex wählen. Frühe Zwischenstände unverändert erhalten. SHA256 steht außerhalb des ZIPs, kein rekursiver Selbsthash. Import: [ARTIFACT_IMPORT_20261025.md](ARTIFACT_IMPORT_20261025.md); [Validierung](VALIDATION_0_8_39_20261025.md).

## Genau ein nächster Schritt

**Integrationsbasis aktualisieren.** Erst nach Review/Integration von PR160 bzw. Sammel-PR164 `git fetch origin main` und `git merge-base --is-ancestor 6f2ebbc893fb5ee053d069410a103a102662aa4d origin/main` prüfen. Wenn enthalten, PR166 aufmain umstellen, neuen Main konfliktfrei übernehmen, beide Historien und alle Regelfelder erhalten; vollständige gemeinsame Tests/Android/CI erneut prüfen. Andernfalls gestapelte Abhängigkeit offen dokumentieren. Keine Variante ungeprüft über Main kopieren. Light-Fernkampf/Nick erst als spätere eigenständige Pakete.

Prüfen: bash scripts/check.sh; python3 scripts/check_domain_boundaries.py; python3 scripts/srd_coverage.py --json; cd app && flutter build apk --debug; cd android && bash ./gradlew :app:testDebugUnitTest --no-daemon. Toolchainpfade /workspace/validation/TOOLCHAIN.md. Voriger Checkpoint vollständig in [Historie](history/pr160_0.8.38_20261024/CODEX_CHECKPOINT.md). Keine automatische Fortsetzung außerhalb aktiver Sitzung.
