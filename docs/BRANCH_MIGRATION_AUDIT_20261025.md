# Branch-Migrationsaudit –25.10.2026

Initialer Main `b60ffe7ff1aae502ea927cb77153b988be33e397`,18 gesicherte Remote-Köpfe einschließlich Main und dem ersten eigenen Integrationscheckpoint. Nutzer hat ausdrücklich Integration, Fehlerbehebung und anschließende Löschung alter Branches beauftragt.

## Sicherung und vollständige Herkunft

Alle initialen Köpfe vor Änderungen als `archive/branch-migration-20261025T075644Z/<Branchname>` remote gesichert und auf ursprüngliche SHA geprüft. Vollständiges Git-Bundle `Wuerfelraunen_Branches_vor_Migration_20261025T075644Z.bundle`,SHA256 `5cf905026c49bdee6b301bd047bbe1f52dbe1c9b6001aabd31cc287c0e758831`, mit git bundle verify geprüft. Original-Commitbäume bleiben dadurch unabhängig von gelöschten Branchnamen zugänglich.

[JSON-Audit](branch_migration_20261025.json) enthält alle Branch-/SHA-/Tag-/Erhaltungsentscheidungen. Alle18 Köpfe sind nach Funktions- und Historienintegration echte Vorfahren des Kandidaten `1cddc4a3d590d0959733b532a5ec349b4195dcf4`. Historien-Merges mit ours ändern keine Inhaltsbäume; sie werden ausschließlich nach konkreter Herkunftsprüfung verwendet.

- Sending-Journalb90c21d: gesamter Git-Baum identisch mit Main-Vorfahr3b5affd.
- Unicode-D73f3cf: gesamter Git-Baum identisch mit Main-Vorfahr4c6040c.
- Alt-Schurked54f554: nur zehn Dokumentationsänderungen, Laufzeitcode identisch zum bereits integrierten Elterncommit. Alle zehn Dateien vollständig archiviert.
- PR159/161/162/163: sämtliche Laufzeitfeature-Hunks rückwärts mit git apply --reverse --check --unidiff-zero geprüft; Kernquellen bereits in der konsolidierten164 enthalten.
- PR160/164/165/166 und80b615e: reguläre tatsächliche Vorfahren durch Funktionsintegration oder ältere Main-Merges.

## Konflikte und Funktionsvereinigung

164 dann165 und166 zusammengeführt. Fünf Konflikte ausschließlich in CHANGELOG,DEVELOPMENT_STATUS,README,ROADMAP,CODEX_CHECKPOINT. Beide Fassungen plus zehn Altdateien unter [Historie](history/branch_migration_20261025/README.md), Herkunft/SHA in archived_documents.json. Aktuelle Statusdateien neu als gemeinsame Übergabe geschrieben.

App gegenüber Light166 unterscheidet sich nur durch Sending-Dialog/-Tests und lokalen Story-Guard/-Tests aus159/165; exakte Dateimenge geprüft. Backend/scripts/Workflow bytegleich zum geprüften164. Kein Funktionscodekonflikt und kein Abschalten von Tests.

## Abnahme und Löschgrenze

Vorgänger-CIs164/165/166 erfolgreich, neue gemeinsame Prüfung noch ausstehend. Ziel ist1549 Fluttertests, aber nur tatsächlich beobachteten Zähler dokumentieren. Backend/Python/native/Android separat abnehmen. Kein Main-Merge oder Branchlöschen aufgrund alter grüner Einzel-CIs.

Nach eigener erfolgreicher PR-Abnahme normaler Main-Merge mit erwartetem Head; tatsächliche Main-CI beobachten. Vor Löschung jede Remote-SHA gegen Sicherungsmanifest prüfen, Archivtag verifizieren und git merge-base --is-ancestor <Head> <aktueller Main> verlangen. Main und geänderte unbekannte Köpfe niemals löschen. Alte noch offene PRs nur schließen, wenn ihre Köpfe nachweislich in Main enthalten sind. Löschbericht und tatsächlicher Endzustand separat nachführen.

## Wiederherstellung

```bash
git fetch origin --tags
git switch -c restore/branch archive/branch-migration-20261025T075644Z/<Branchname>
```

Alternativ git clone <Bundlepfad> oder das vollständige finale Projekt-ZIP. Quellen- und APK-Artefakte getrennt halten; persönliche Spielstände und lokale nicht veröffentlichte Entwürfe nicht entfernen.


## Erweiterung nach erneutem Live-Abgleich

Vier weitere Sourcebranches167–170 seit ursprünglicher13er-Aufnahme erkannt, vor Integration plus eigenem erstem Integrationskopf gesichert: nun18 Archivtags/Köpfe. Story169 und Archivfilter170 normal integriert;167/168 nach fokussiertem Rückwärts-Patchnachweis ohne Baumänderung in die Historie aufgenommen. Alle18 gesicherten Köpfe echte Vorfahren. Neun Historien-Merges insgesamt,38 Status-/Altdateien historisch archiviert. Ursprüngliches Bundle bleibt erhalten; aktuelles erweitertes Bundle: Wuerfelraunen_Branches_vor_Migration_20261025_erweitert.bundle, SHA256 e54ffc8cc6084985aac8a5cb9b18caca07a50fa7c564caeab94bee236a1954ba.

Gefundener Fehler im neuen Archivfilter: casefold des Dateinamens verglich gegen noch gemischt geschriebene Ausschlussnamen. .DS_Store und GeneratedPluginRegistrant.java konnten dadurch einbezogen werden. Regression vor Fix nachgewiesen, Lookup einmalig symmetrisch normalisiert;11 Archivtests danach grün. Neuer kompletter kombinierter Lauf unter /workspace/validation/20261025-migration-final-full-check.log. Erster13er-Kandidat separat1549 Flutter-/100 Python-/38 Backend-Tests erfolgreich, kein Test der erweiterten Kombination. Neue endgültige Zahlen erst nach Beobachtung übernehmen.
