# CODEX-CHECKPOINT – aktiver Light-Regelzyklus

Stand 2026-10-25T06:30:16+00:00. Version **0.8.39+89**, Branch `feature/light-weapon-bonus-attack-20261024`. Arbeitsverzeichnis `/workspace/Dnd-offhand-ally-20261024`.

## Basis und Abhängigkeiten

Main b60ffe7ff1aae502ea927cb77153b988be33e397 (PR158 integriert), Main-CI40094794864 vollständig erfolgreich. PR159 Sending-W100 separat grün; PR160 Nebenhand-Verbündeter bereits vorhanden, wird nicht dupliziert. Neues Paket baut auf dessen HEAD **6f2ebbc893fb5ee053d069410a103a102662aa4d** auf. Zunächst gestapelter PR gegen `feature/sneak-attack-offhand-ally-20261024`, nach deren Integration auf main umstellen. Keine direkten Mainänderungen/Force-Pushes. Historie vollständig unter docs/history/pr160_0.8.38_20261024/.

## IMPLEMENTIERT (Arbeitsstand)

Light-Nahkampfbonus ohne Klassen-/Stilpflicht, getrennte Finesse-Attributwahl und ausdrücklich bestätigte Waffenübung. Positiver Schadensmodifikator nur mit bestehendem Two-Weapon-Fighting-Stil, negative Werte immer. Neue Engine-/Controller-Vorbereitung mit eigener Zug-/Aktions-/Waffen-/Bestätigungsprüfung. Optional gespeicherte PendingRoll-Felder offhandAttackAbility/offhandWeaponProficient/offhandWeaponsHeldConfirmed nur gemeinsam; alte Fighter-Stil-Proben ohne Zusatzfelder bleiben gültig. Vor jeder Nebenhandauflösung Importvertrag vor RNG prüfen. Abenteuerdialog/Button samt Zustimmung, Vorschau und Revisionsschutz implementiert und gezielt getestet. SRD5.2.1 Light S89/Fighting Style S88, CC BY4.0; nur Nahkampf, kein Nick oder freie Zusatzaktion.

## GETESTET

12 TwoWeaponFighting-Domain-/bisherige Kampfregressionen, 18 neue Kampf-/SQLite-Tests und 7 Widgettests erfolgreich; negative Schadenssummen mit Rage/Sneak und beide Waffenplätze geprüft. Ein kombinierter Lauf inklusive domain_rules_test und combat_class_actions_test hat55 Tests bestanden. 34 bestehende Sneak-/Speicher-/Widgetregressionen ebenfalls erfolgreich. Kampfrausch verwendet nun die tatsächliche Angriffswaffe und ihr Attribut. Negative Modifikatoren werden erst nach sämtlichen Klassenboni auf insgesamt mindestens null begrenzt. Voriger Gesamtcheck wurde für diese notwendige Codeergänzung bewusst gestoppt und wird vollständig neu ausgeführt. Einzelaufruf enthielt zunächst einen nicht vorhandenen Testdateinamen; in domain_rules_test.dart korrigiert, kein übersprungener Produkttest. Ursprüngliche 12er-Prüfung: Log `/workspace/validation/20261024-light-domain-full.log`. Frühere PR160-Code-CI40099238901 erfolgreich; neue Kombination benötigt eigene vollständige Abnahme. SDKs lokal vorhanden.

## NICHT GETESTET

Neue UI-/Integrationstests bestanden; vollständiger Gesamtcheck läuft erneut unter /workspace/validation/20261025-light-full-check.log. Neue APK/native Prüfungen noch nicht ausgeführt. Echtes Gerät/Altspielstand-Upgrade nicht getestet.

## BLOCKIERT

Kein echtes Android-Gerät oder produktiver Signaturschlüssel. Kein aktueller SDK-/Git-Zugriffsblocker.

## NOCH NICHT IMPLEMENTIERT

Light-Fernkampf/Munition, Nick, Waffenwechsel-/Positionssystematik und vollständiges SRD. Strukturierte Item-Overrides weiter separat offen.

## Wiederaufnahme und Sicherung

Die getrennten Agentenarbeiten sind abgeschlossen; voriger UI-Agent erreichte nach sieben grünen Widgettests sein Kontingent. Keine weitere Agentengruppe starten; Root schließt das bestehende Paket ab. Root besitzt models.dart/game_engine.dart/game_controller.dart/Version/Dokumentation. Bei Unterbrechung zuerst tatsächlichen Git-Status und laufende Prozesse prüfen, keine alten Modelle kopieren. Vollprojekt-ZIP/Patch gegen6f2ebbc mit scripts/create_checkpoint.py vor Abnahme als Zwischenstand erzeugen; finale Pakete erst nach erfolgreichen Prüfungen als abgenommen benennen.

Nächster konkreter Schritt: gezielte neue UI-/SQLite-Tests, dann scripts/check.sh, Importgrenzen, Coverage, Android-Debug/native/ARM64 aus neuem ZIP; Branch/PR sichern und Checkpoint/README mit tatsächlichen Ergebnissen aktualisieren. Keine automatische Wiederaufnahme behaupten.
