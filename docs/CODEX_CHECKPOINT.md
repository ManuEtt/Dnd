# CODEX-CHECKPOINT – Live-Nachtrag nach Branch-Merge (25.10.2026)

**Geprüfter Stand:** `main=635773db33724f543d61bacde9a9ebe679b9b1e9` nach regulärem GitHub-Merge [PR #171](https://github.com/ManuEtt/Dnd/pull/171), Integrations-HEAD `255a5a0bdf8dc4915bfd70e808a69862f3d0708a`. App **0.8.39+89**, SQLite 2, Kampagnen-JSON 1 unverändert. Nur ein separater Dokumentationsbranch wird bearbeitet, `main` nicht erneut direkt verändert.

- **IMPLEMENTIERT:** Alle im untenstehenden Migrationscheckpoint beschriebenen Feature- und Sicherheitsänderungen auf `main` integriert, ohne Squash, historische Branch-SHAs behalten.
- **GETESTET:** [PR-CI #40192473811](https://github.com/ManuEtt/Dnd/actions/runs/40192473811) für exakt `255a5a0`: `completed/success` mit Python, Backend, Flutter, Android-/APK- und Artefaktschritten. Unabhängig 19/19 verzeichnete Archive-Tag-Refs und GitHub-Ancestry gegen Integrations-HEAD positiv geprüft; sechs nach dem Merge noch offene gestapelte PRs mit Heads, die Vorfahren von `main` sind.
- **NICHT GETESTET:** Eigenständige [Main-CI #40193476536](https://github.com/ManuEtt/Dnd/actions/runs/40193476536) bis zu ihrem tatsächlichen Abschluss; reales Android-Gerät/Upgrade mit alten Spielständen, produktive Signierung. Kein neues Paket/kein neuer SHA256-Digest vorgetäuscht.
- **BLOCKIERT:** Physische Geräteabnahme und GitHub-Branch-Löschung über die aktuell verfügbare Connector-Schnittstelle (kein sicherer `delete_ref`-Endpunkt). Lokale Git-Bundle-Prüfung aus dokumentiertem Fremd-Arbeitsverzeichnis wurde hier nicht unabhängig wiederholt. Archivtags bleiben bestehen.
- **NOCH NICHT IMPLEMENTIERT:** Haupt- und Nebenbranch-Bereinigung erst nach grüner Main-CI und nochmaliger SHA-/Backup-Abstammungsprüfung. Vollständige SRD-Automatik, reale KI-/Gerätefreigabe offen.
- **Nächster konkreter Schritt:** Nach Abschluss der exakten Main-CI `635773d`: die sechs gestapelte PRs #165/#166/#167/#168/#169/#172, deren Head SHA weiterhin in `main` enthalten ist, ohne Re-Merge schließen; Remote-Branch-Löschung nur über einen SHA-gesicherten `delete_ref`-Workflow nach gesonderter Berechtigungs-/Backup-Prüfung. Bei neuer SHA/roter CI zuerst abklären, nichts löschen.

---

# CODEX-CHECKPOINT – Branch-Migration

Stand **2026-10-25T12:16:00+00:00**. Nutzerauftrag: alle GitHub-Branches migrieren, Fehler beheben und alte Branches löschen. Die ausdrückliche Freigabe umfasst geprüfte Main-Integration und anschließende sichere Bereinigung.

## Git und Herkunft

- Arbeitskopie `/workspace/Dnd-migration-20261025`, Branch `integration/all-branches-20261025`, [PR #171](https://github.com/ManuEtt/Dnd/pull/171).
- Ausgangs-Main `b60ffe7ff1aae502ea927cb77153b988be33e397`; Funktions-/Integrationscommit `cd724629c79a169ff1a078517031a33cf73ae130`. Version **0.8.39+89**, SQLite **2**, Kampagnen-JSON **1** unverändert.
- 19 erfasste Remote-Köpfe vor Integration gesichert, remote tags SHA-genau geprüft; alle Köpfe echte Vorfahren. Ursprünglich 13, später vier Sourcebranches plus eigener Integrationscheckpoint und Atomic-Archivbranch hinzugekommen.
- Sicherung: `Wuerfelraunen_Branches_vor_Migration_20261025_19_final_mit_Dokumentation.bundle`, SHA256 `344e499cd8b21f04148903002428fe81ba58b83bf8aa67832f4a02a71476c973`. Unter `/workspace/artifacts/branch-migration-20261025/`; dort auch ältere unveränderte Bundles und Manifeste. Archivtags unter `archive/branch-migration-20261025T075644Z`. Atomic-Zwischenkopf und finaler geprüfter Atomic-Kopf separat erhalten.
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
