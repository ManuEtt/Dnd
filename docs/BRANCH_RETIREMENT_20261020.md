# Branch-Konsolidierung – 20.10.2026

**Unveränderter Hauptbranch vor Bereinigung:** `420fc1344a599a69ab17b71b46cf597793f8c48c` (`main`). Die GitHub-API lieferte genau zehn Branches (inkl. `main`), Seite 2 leer. Alle neun Nicht-main-Branches wurden über `compare/main...<branch>` geprüft: **ahead_by = 0**, status `behind` und jeweiliger HEAD-Commit bereits Vorfahr von `main`. GitHub-PR-Historie #39–#47 weist vollständige Merges aus. Dadurch gehen beim Entfernen der Zeiger **keine Commits verloren**. Es sind keine nachträglichen Cherry-Picks nötig.

| Vollständig integrierter Branch | festgehaltener HEAD | zusätzliche Commits gegenüber main | Einordnung |
|---|---|---:|---|
| `docs/srd-crawling-ci-20261020` | `915d70aa75b1` | 0 | bereits via PR in main |
| `docs/srd-force-defense-ci-20261020` | `dc45f477c81e` | 0 | bereits via PR in main |
| `docs/srd-magic-missile-ci-20261020` | `f441be46c6bc` | 0 | bereits via PR in main |
| `docs/srd-shield-ci-20261020` | `3c7ad81bdff5` | 0 | bereits via PR in main |
| `feature/level-up-xp-sequential-20261020` | `d8b8d3d4e3ce` | 0 | bereits via PR in main |
| `feature/srd-crawling-20261020` | `346210659215` | 0 | bereits via PR in main |
| `feature/srd-enemy-shield-reaction-20261020` | `81635c8eccb0` | 0 | bereits via PR in main |
| `feature/srd-magic-missile-20261020` | `78d89230281f` | 0 | bereits via PR in main |
| `feature/srd-missile-force-defense-20261020` | `8f703b0002ae` | 0 | bereits via PR in main |

## Absicherung und Ausführung

- Prüfsnapshots in `scripts/retire_merged_branches.py` erlauben **nur** die neun unveränderten HEADs und den eigenen, ebenfalls bereits gemergten temporären Maintenance-Branch.
- Die Aktion läuft auf `main`, vergleicht die Branches **erneut** mit dem aktuellen Hauptbranch, prüft `protected = false`, `ahead_by = 0`, identischen HEAD-SHA und beendet sich bei Änderungen ohne zu löschen.
- Keine Force-Pushs, keine Rebase-Überschreibungen, kein Git-Verlauf wird entfernt; vollständige Quellstände sind im Hauptbranch und den Merge-Commits vorhanden.
- Die einmalige Aktion wird durch Merge der Workflowdatei ausgelöst; weitere Ausführungen nur manuell. `main` wird nicht angefasst. Neue Branches ohne den ausdrücklich erlaubten Namen können nicht gelöscht werden.
- Die Workflow-Ausführung ist in GitHub Actions unter „One-time merged branch retirement“ einsehbar. **Nur ein erfolgreicher Aktionslauf bestätigt die tatsächliche Löschung.**

## Danach

Nach abgeschlossener Bereinigung mit `GET /branches` prüfen, ob ausschließlich `main` übrig ist; andernfalls eventuelle Fehler der GitHub-Actions-Berechtigung transparent dokumentieren. Nächste SRD-Entwicklungsaufgabe: Shield-Reaktion für den Held gegen gegnerische Treffer, inklusive Ressourcen- und Zustandsvalidierung. Vollständiges SRD weiter offen.
