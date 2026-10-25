# CODEX-CHECKPOINT – Branch-Migration

Stand **2026-10-25T12:16:00+00:00**. Nutzerauftrag: alle GitHub-Branches migrieren, Fehler beheben und alte Branches löschen. Die ausdrückliche Freigabe umfasst geprüfte Main-Integration und anschließende sichere Bereinigung.

## Git und Herkunft

- Arbeitskopie `/workspace/Dnd-migration-20261025`, Branch `integration/all-branches-20261025`, [PR #171](https://github.com/ManuEtt/Dnd/pull/171).
- Ausgangs-Main `b60ffe7ff1aae502ea927cb77153b988be33e397`; Funktions-/Integrationscommit `cd724629c79a169ff1a078517031a33cf73ae130`. Version **0.8.39+89**, SQLite **2**, Kampagnen-JSON **1** unverändert.
- 19 erfasste Remote-Köpfe vor Integration gesichert, remote tags SHA-genau geprüft; alle Köpfe echte Vorfahren. Ursprünglich 13, später vier Sourcebranches plus eigener Integrationscheckpoint und Atomic-Archivbranch hinzugekommen.
- Sicherung: `Wuerfelraunen_Branches_vor_Migration_20261025_19_final_mit_Dokumentation.bundle`, SHA256 `fb75e843f3146d23044818dc7278487c44f024b2ba25475dbd450999aca299b7`. Unter `/workspace/artifacts/branch-migration-20261025/`; dort auch ältere unveränderte Bundles und Manifeste. Archivtags unter `archive/branch-migration-20261025T075644Z`. Atomic-Zwischenkopf und finaler geprüfter Atomic-Kopf separat erhalten.
- Reguläre Funktions-Merges, zehn nach konkreter Inhaltsprüfung unveränderte Historien-Merges; 42 bytegenau archivierte Dokumente. [JSON-Herkunft](branch_migration_20261025.json), [Audit](BRANCH_MIGRATION_AUDIT_20261025.md).

## IMPLEMENTIERT

Sending-W100-Validierung, Verbündetenbestätigung bei zulässigen Nebenhandangriffen, allgemeine Light-Nahkampfbonusangriffe, Schutz abgeschlossener Storyfäden, lokale und serverseitige ID-Kollisionssperren, Plot-Geheimnisschutz, Backend-Limiter und sichere Projektarchive sind vereinigt. Der bei der Integration gefundene Casefold-Fehler für generierte/Systemdateien ist mit Regressionstest behoben. Fehler beim ZIP-Schreiben oder Veröffentlichen der Prüfsumme bewahren das zuvor vorhandene Archiv; keine Zusage einer absturzübergreifend atomaren Dateipaar-Transaktion.

## GETESTET

**1.552 Flutter-, 106 Python-, 40 Backend- und 12 native Android-Tests bestanden.** Dart-Formatierung: 360 Dateien unverändert; Flutter-Analyse sowie Backend-Typecheck und -Build erfolgreich. Debug-APK und ARM64-Alpha gebaut; Version, ZIP-CRC, ABI und lokale Debug-Signatur geprüft.

Vollständiger Lauf `/workspace/validation/20261025-migration-final-full-check.log`: Flutter 1.552 / Python 102 / Backend 40 auf Quelle `6aef90d`. Danach nur Archivskript/-tests geändert; `/workspace/validation/20261025-migration-atomic-python-tests.log`: **106/106**. App, Backend und Workflow weiterhin bytegleich; kein Wiederholungslauf dieser unveränderten Quellen nötig. APK-Bau aus geprüftem Projekt-ZIP `6aef90d`; 424 App-Eingabedateien für ARM64 gegen ZIP, Arbeitskopie und Buildkopie geprüft. Alle 19 gesicherten Köpfe auf Ancestry geprüft. Casefold-Regression vor Fix fehlgeschlagen, danach grün. [Prüfnachweise](branch_migration_validation_20261025.json).

## NICHT GETESTET

Finale gemeinsame PR-CI und anschließende Main-CI bis tatsächlichem Abschluss separat ausstehend. Alte Einzel-CIs ersetzen diese Prüfung nicht. Kein reales Android-Gerät, kein reales Geräte-Upgrade mit historischem Spielstand, keine produktive Signierung. SRD-Gesamtumfang nicht fertig.

## BLOCKIERT

Geräteabnahme und produktive Signierung mangels Gerät/Schlüssel. GitHub-Schreibrechte, SDKs und lokale Tests funktionieren; keine weiteren technischen Blocker beobachtet.

## NOCH NICHT IMPLEMENTIERT / NÄCHSTER SCHRITT

**Zuerst Migration abschließen:** aktuellen finalen PR-Head pushen/CI abnehmen, normaler Merge mit erwartetem Head (kein Squash), tatsächliche Main-CI prüfen. Danach offene Vorgänger-PRs nur bei in Main enthaltenem Kopf schließen. Remote-SHAs erneut mit Backup vergleichen, Tags und Main-Abstammung prüfen, bedingte atomare Branchlöschung; Main erhalten. Neue oder verschobene Branches erneut sichern/integrieren. Ergebnisse in README, Checkpoint und Löschbericht nachführen.

Nach vollständigem Abschluss eigenes SRD-Paket allgemeine Gelegenheitsangriffe; konkrete Gegenfälle und Akzeptanzkriterien in README. Weitere Zauber-/Klassen-/Monsterwirkungen, Inventur, Item-Overrides und reale Android-Abnahme bleiben offen.

## Artefakte und Wiederaufnahme

`/workspace/artifacts/branch-migration-20261025/`: versionierte Vollprojekt-ZIPs, tatsächlich gegen Basis-Main angewandte Git-Patches, SHA256/Dateimanifeste, Git-Bundles und geprüfte Debug-/ARM64-APKs. Beide lokalen APKs verwenden den lokalen Android-Debugschlüssel, keine Gerätezulassung. Aktuelle Dateinamen nach jeder Paketierung im Artefaktindex nachführen.

Zuerst Git-Status/HEAD, Main, offene PRs und laufende Workflows neu prüfen. Manifest `/workspace/validation/20261025-branch-backup-manifest.json`; Löschwerkzeug `/workspace/validation/cleanup_migrated_branches.py` prüft grüne exakte Main-CI, Inventar, SHA, Archivtag und Ancestry vor SHA-gebundener Löschung. **Noch keine Main-Veröffentlichung oder Branchlöschung erfolgt.** Historische lokale Worktrees und unveröffentlichte Entwürfe nicht entfernen. Keine automatische Fortsetzung außerhalb einer aktiven Sitzung.

Nachtrag: späterer Atomic-Dokumentationskopf `1eb8046` ebenfalls remote gesichert, alle vier einzigartigen Statusdateien bytegenau archiviert und mit unverändertem Inhaltsbaum als Vorfahr aufgenommen. Nun zehn geprüfte Historien-Merges und 42 Archivdateien. App/Backend/Skripte bleiben gegenüber geprüftem Funktionscommit `cd72462` unverändert.
