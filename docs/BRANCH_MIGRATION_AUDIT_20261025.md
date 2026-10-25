# Branch-Migrationsaudit – 25.10.2026

## Abschluss-Nachtrag nach unabhängiger GitHub-CI

- [PR #171](https://github.com/ManuEtt/Dnd/pull/171) wurde **ohne Squash** gemergt. Tatsächlicher `main`-Merge-Commit: `635773db33724f543d61bacde9a9ebe679b9b1e9`. Integrations-HEAD: `255a5a0bdf8dc4915bfd70e808a69862f3d0708a`.
- Finale Integrations-CI [#40192473811](https://github.com/ManuEtt/Dnd/actions/runs/40192473811) und eigenständige [Main-CI #40193476536](https://github.com/ManuEtt/Dnd/actions/runs/40193476536) jeweils `completed/success` auf ihren exakten Commits, einschließlich Flutter/Backend/Python/Android/APKs/Artefakten.
- Alle **19/19** in `docs/branch_migration_20261025.json` erfassten SHA-Tags wurden erneut mit tatsächlichen Remote-Tag-Refs verglichen; **19/19** GitHub-Commitvergleiche bestätigen Ancestor-Beziehung zur finalen Main-Historie. Der nachträglich weiterentwickelte Integrationskopf besitzt einen eigenen Archivtag `archive/branch-migration-20261025T075644Z/integration-final-255a5a0`, SHA `255a5a0`.
- Sechs nach dem Merge noch offene gestapelte Vorgänger-PRs **#165, #166, #167, #168, #169, #172** sind nach Ancestry-Recheck **ohne erneutes Mergen geschlossen**. Ihre Git-Branches und sämtliche Sicherungstags bestehen weiter.
- **Remote-Branch-Löschung noch nicht erfolgt.** Der GitHub-Connector bietet in dieser Sitzung keinen SHA-gebundenen `delete_ref`-Aufruf; die vorgesehene lokale Bundle-Datei wurde hier nicht unabhängig geprüft. Vor einem späteren Löschlauf Backup-Tags, dann aktuelle Heads und Main-Ancestry erneut verifizieren und per `--force-with-lease`-ähnlicher atomarer Bedingung löschen. **Kein Force-Push und keine Löschung von `main`, neuen oder verschobenen Branches.**
- App-Version `0.8.39+89`, SQLite 2, Kampagnen-JSON 1. Kein reales Gerät/Upgrade oder produktive Release-Signatur abgenommen.

Die folgenden Abschnitte dokumentieren die **ursprünglichen Prüfbedingungen vor dem Merge** und bleiben als historische Audit-Spur erhalten.

---

Ausgangs-Main `b60ffe7ff1aae502ea927cb77153b988be33e397`; Nutzer beauftragt Integration, Fehlerbehebung und anschließende Löschung alter GitHub-Branches. [PR #171](https://github.com/ManuEtt/Dnd/pull/171), Integrationscode `cd724629c79a169ff1a078517031a33cf73ae130`. **Main-Übernahme und Branchbereinigung noch ausstehend.**

## Sicherung und Herkunft

19 erfasste Köpfe remote über geprüfte Archivtags unter `archive/branch-migration-20261025T075644Z` und lokal per vollständigem Bundle gesichert. Aktuelles Bundle `Wuerfelraunen_Branches_vor_Migration_20261025_19_final_mit_Dokumentation.bundle`, SHA256 `344e499cd8b21f04148903002428fe81ba58b83bf8aa67832f4a02a71476c973`; `git bundle verify` erfolgreich. Frühere Bundles unverändert erhalten. [JSON-Audit](branch_migration_20261025.json) dokumentiert alle exakten Köpfe und Erhaltungsentscheidungen. Alle sind echte Vorfahren des Integrationsstands.

Reguläre Merges integrieren die Funktionsstände 164, 165, 166, 169, 170 und den neu veröffentlichten Atomic-Archivbranch. Zehn zusätzliche Historien-Merges ändern keinen Inhaltsbaum und beruhen auf diesen Nachweisen:

- Sending-Journal `b90c21d`: gesamter Git-Baum identisch zu Main-Vorfahr `3b5affd`.
- Unicode `d73f3cf`: gesamter Git-Baum identisch zu Main-Vorfahr `4c6040c`.
- Alt-Schurke `d54f554`: nur zehn einzigartige Dokumentänderungen, alle bytegenau archiviert; Laufzeitcode bereits übernommen.
- PRs 159/161/162/163/167/168: enthaltene Laufzeithunks mittels fokussiertem rückwärtigem Patchcheck nachgewiesen.
- Späterer Atomic-Kopf `1eb8046`: nur vier einzigartige Statusdateien gegenüber bereits integriertem `a1a8dd9`; komplett historisch archiviert, unveränderter Baum beim Historien-Merge.

42 historische/konfliktbehaftete Dokumentdateien unter [Historie](history/branch_migration_20261025/README.md); beide Seiten aller Statuskonflikte erhalten. Der spätere Testkonflikt zwischen Casefold-Regression und vier Atomic-Tests wurde durch Erhalt sämtlicher fünf Fälle aufgelöst. Keine Laufzeitfunktion durch eine alte Vollkopie ersetzt.

## Fehlerbehebung und Abnahme

Neue Archivnormalisierung ließ `.DS_Store`/`GeneratedPluginRegistrant.java` wegen unsymmetrischem Casefold durch. Regression vor Korrektur nachgewiesen, danach grün. Neu hinzugekommene Archivveröffentlichung baut und prüft temporär und stellt bei fehlgeschlagener Prüfsummen-Veröffentlichung das vorhandene ZIP wieder her. Keine Aussage vollständiger Dateipaar-Atomizität bei Stromausfall oder parallelen Schreibern.

**1.552 Flutter-, 106 Python-, 40 Backend- und 12 native Android-Tests bestanden.** Dart-Formatierung: 360 Dateien unverändert; Flutter-Analyse sowie Backend-Typecheck und -Build erfolgreich. Debug-APK und ARM64-Alpha gebaut; Version, ZIP-CRC, ABI und lokale Debug-Signatur geprüft.

App/Backend/Workflow sind gegenüber geprüfter Quelle `6aef90d` unverändert; nachfolgender Archivmerge separat mit 106 Python-Tests geprüft. Detaillierte Quellen/Loghashes: [Prüfbericht](branch_migration_validation_20261025.json). Finale PR- und Main-CI bleiben eigenständige Gates. Reales Gerät, Geräte-Upgrade und produktive Signierung fehlen.

## Bedingung für Löschung

Erst nach erfolgreichem normalem PR-Merge und tatsächlicher Main-CI: aktuelle Branchliste vollständig abgleichen, jede SHA gegen Backup prüfen, Remote-Tag-SHA verifizieren, `git merge-base --is-ancestor <Head> <Main>` verlangen. Ausschließlich solche Branches atomar mit erwarteten SHA-Leases löschen; keine Historie umschreiben. Main und neu verschobene/unbekannte Köpfe erhalten. Noch offene Vorgänger-PRs nur bei übernommenem tatsächlichem Head schließen. Eigenen weiterentwickelten Integrationskopf zusätzlich auf erwarteten finalen PR-Head und Main-Ancestry prüfen. Löschbericht anschließend tatsächlich erzeugen.

## Wiederherstellen und importieren

```bash
git fetch origin --tags
git switch -c restore/mein-branch <exakter Archivtag aus JSON-Audit>
```

Vollständige Historie: `git clone <Bundlepfad> Wuerfelraunen-Restore`. Für GitHub-Import anschließend das korrekte Remote setzen und den gewünschten wiederhergestellten Branch pushen; Archivtags nicht ungeprüft nach Main schreiben.

Projekt-ZIP in eine leere Arbeitskopie entpacken. Der Patch bezieht sich auf Main `b60ffe7ff1aae502ea927cb77153b988be33e397`: neuen Branch auf dieser Basis erstellen, `git apply --check <Patch>` und `git apply <Patch>`, dann committen/pushen und PR öffnen. Die Checkpoint-Erzeugung prüft ZIP-CRC, alle Datei-Hashes/-Modi und tatsächliche Patch-Anwendung gegen diese Basis. ZIP enthält keine SDKs, Build-Caches, APKs oder persönlichen Spielstände; APKs separat.
