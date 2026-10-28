# History-Abgleich bereits integrierter Chat-A-Branches – 28.10.2026

Basis-Main: `dd0c2e94ccf0995c6070010b6af1df315205b36a`. Arbeitsbranch: `integration/migration-history-20261028`.

Die sieben unten aufgeführten Originalköpfe sind durch reguläre Merge-Commits im gemeinsamen Verlauf erhalten. Die Regeln, Oberfläche, Backend-, Skript- und Workflow-Dateien sind gegenüber der Basis **bytegleich**. Es wurde keine zweite Regelimplementierung eingeführt.

| Branch | Originalkopf |
| --- | --- |
| `feat/chat-a/audited-material-inventory-20261027` | `4d7b8c0107022d531d0c5950c09dcaff9b60e6cd` |
| `feat/chat-a/audited-multi-material-components-20261027` | `779137bbfeaf86242bd246918c53bdc757febd9f` |
| `feat/chat-a/high-jump-preflight-20261027` | `0441729ada038aaa61a1bcab5da222849ef90824` |
| `feat/chat-a/long-jump-atomic-integration-20261027` | `ee1b33d00536049dfec9f1447306b48773f33c81` |
| `feat/chat-a/long-jump-encounter-plan-20261027` | `461e36f4f5a768aa2900830fd38be65149c569d6` |
| `feat/chat-a/long-jump-preflight-20261027` | `4e15ba643a22b94e9ec3ba7da72e8330a0b0e56c` |
| `feat/chat-a/material-inventory-dialog-20261027` | `7595484f6bd06b10c73aa7cf34f3d7ec3c49dbc9` |

## Abgleich und Sicherung

- Materialinventar, Mehrfachmaterialien, Materialdialog, Weitsprung-Vorprüfung und Begegnungsplan sowie Hochsprung waren in Main bereits inhaltsgleich integriert.
- Beim atomaren Weitsprung sind die eigentlichen Sprungmethoden ebenfalls bereits vorhanden. Die abweichenden Gesamtdateien `game_engine.dart` und `game_controller.dart` enthalten in Main zusätzlich neuere Mönchs-, NPC- und Wilder-Angreifer-Änderungen. Diese bleiben vollständig erhalten; der Importkonflikt wurde zugunsten der vorhandenen Sanfter-Fall-Regel aufgelöst.
- README, operativer Checkpoint und gemeinsamer Chat-A-Checkpoint bleiben auf dem neueren Main-Stand. 31 Originaldokumente aller sieben Köpfe liegen bytegenau in [`history/branch_migration_history_20261028/`](history/branch_migration_history_20261028/manifest.json). Das Manifest enthält Originalpfad, SHA des Herkunftscommits und SHA-256 jedes Dokuments.
- Historische Fachberichte wurden zusätzlich erreichbar gemacht; dortige damalige Test-/Blockerangaben sind keine heutige Gesamtabnahme.

## Nachweise und offene Abnahme

**IMPLEMENTIERT:** Ancestry-Migration aller sieben Originalköpfe; keine funktionale Produktänderung.

**GETESTET:** `python3 scripts/verify_project.py`; sieben erfolgreiche `git merge-base --is-ancestor`-Prüfungen; alle 31 SHA-256- und Git-Blob-Vergleiche; leerer Produktdiff gegen die festgehaltene Main-Basis.

**NICHT GETESTET:** Neue gemeinsame Flutter-/Backend-/Android-CI der übergeordneten Gesamtmigration und echtes Android-Gerät. Diese History-Teilprüfung ersetzt deren Abnahme nicht.

**BLOCKIERT:** Kein lokaler Blocker dieses Teilpakets. Remote-Branches wurden weder geändert noch gelöscht.

**NÄCHSTER SCHRITT:** Diesen History-Branch regulär in die Gesamtmigration übernehmen, dort alle Branchköpfe erneut auf Ancestry und unveränderte Remote-SHA prüfen und erst nach erfolgreicher Gesamtabnahme bereinigen.
