# CODEX-CHECKPOINT – vollständige Branch-Migration

Stand **2026-10-25T11:58:39+00:00**. Nutzerauftrag: alle GitHub-Branches integrieren, Fehler beheben und anschließend alte Branches löschen. Diese ausdrückliche Freigabe erlaubt die geprüfte Main-Integration und berechtigte Bereinigung ohne erneute Rückfrage.

## Git und Sicherung

- Initialer Main **b60ffe7ff1aae502ea927cb77153b988be33e397**, Branch `integration/all-branches-20261025`, aktuell integrierter Funktions-/Historienstand **09f498d1b617890765ad534e4efbfdd1387c2f0b**. Version0.8.39+89, SQLite2/JSON1 unverändert.
- Alle13 initialen Remote-Köpfe gesichert: Präfix **archive/branch-migration-20261025T075644Z**, remote auf exakte ursprüngliche SHA geprüft. Vollständiges geprüftes Git-Bundle `/workspace/artifacts/branch-migration-20261025/Wuerfelraunen_Branches_vor_Migration_20261025T075644Z.bundle`, SHA256 `5cf905026c49bdee6b301bd047bbe1f52dbe1c9b6001aabd31cc287c0e758831`. Manifest `/workspace/validation/20261025-branch-backup-manifest.json`.
- Konsolidierte164/165 und Light166 normal zusammengeführt. Sieben zusätzliche Historien-Merges ändern keinen Git-Baum: zwei alte Squash-Endbäume komplett identisch mit Main-Vorfahren, vier schon enthaltene Laufzeitpatches rückwärts anwendbar geprüft, ein reiner Alt-Dokumentationscommit vollständig archiviert.
- Alle13 initialen Köpfe sind echte Vorfahren des Kandidaten. **Noch keine Branchlöschung/Main-Veröffentlichung durchgeführt.** Prüfbare Details [branch_migration_20261025.json](branch_migration_20261025.json).

## IMPLEMENTIERT

Gemeinsamer Stand enthält Sending-W100-Sicherung, Nebenhand-Verbündetenbestätigung, Backend-Limiter-Kapazitätsschutz, Backend- und lokale Sperre gegen Wiederöffnen abgeschlossener Storyfäden, Plot-Geheimnisschutz sowie vollständiges bestehendes Light-Paket einschließlich Attribut/Übung/Rage/Schadenssummen. Keine alte Variante über neueren Funktionscode kopiert. Fünf Dokumentationskonflikte aufgelöst, beide Seiten und zehn historische Altdateien bytegenau archiviert;20 Dateien mit SHA256 unter docs/history/branch_migration_20261025/.

## GETESTET

Vorgänger-CIs164=40123094457,165=40170005782,166=40169851171 jeweils grün auf ihren exakten getrennten Heads. Historien-/Patch-/Baumidentität und Archivtags geprüft. Neue kombinierte scripts/check.sh-Abnahme läuft unter `/workspace/validation/20261025-migration-full-check.log`; nicht aus alten grünen Läufen ableiten. Importgrenzen erfolgreich, Coverage erneut ermittelt.

## NICHT GETESTET

Vollständige neue Kombination, neue Android-Builds und endgültige neue PR-/Main-CI bis tatsächlicher Abnahme. Echtes Gerät/Altspielstand-Upgrade und produktive Signierung offen.

## BLOCKIERT

Kein Geräte-/Produktivsignierungsschlüssel. SDKs lokal vorhanden; Platz durch Entfernung eines verifizierten alten temporären Build-Caches freigegeben. Keine Quellarchive oder APKs gelöscht.

## NOCH OFFEN

Gesamtprüfungen beenden, Fehler korrigieren, neuen Integrations-PR erstellen und nach eigener erfolgreicher Prüfung per normalem Merge nach Main übernehmen. Main-CI auf tatsächlichem Merge-SHA beobachten. Erst danach alte PRs schließen, jede exakte Remote-SHA/Archivtag/Main-Abstammung erneut prüfen und alte Remote-Branches bedingt löschen. Main niemals löschen. Geänderte neue Köpfe erneut integrieren, nicht ungeprüft entfernen.

## Wiederaufnahme

Arbeitskopie `/workspace/Dnd-migration-20261025`. Initiale Branch-/PR-Liste in `/workspace/validation/20261025-branch-migration-start.json`. Aktueller Git-Status/HEAD und laufende Tests zuerst prüfen. Alle Originalköpfe durch Remote-Tags und Bundle wiederherstellbar. Prüf- und Löschberichte unter `/workspace/artifacts/branch-migration-20261025/` nachführen. Lokale historische Worktrees/ungeprüfte Item-Entwürfe erhalten; Auftrag bezieht sich auf GitHub-Branches.

Nächster konkreter Schritt: vollständige kombinierte Abnahme einschließlich Android, Quelle-ZIP/Patch, Integrations-PR und erfolgreiche Main-Veröffentlichung. Keine Branchlöschung vor diesen Nachweisen. Keine automatische Fortsetzung außerhalb aktiver Sitzung.
