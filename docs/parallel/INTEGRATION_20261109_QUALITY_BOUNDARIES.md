# Integrationsprüfung: technische Qualitätskorrekturen vom 09.11.2026

## Ausgangslage
- Aktueller Main-Ausgangspunkt: `f848cedef7787e2e89df7b63d93d04dfb06ed8ed`.
- Beide Quell-PRs basieren auf `b2e1a021067cec39b7c85bdad11aa98477cac14e`.
- Die vier betroffenen Python-Fach-/Testdateien sind auf aktuellem Main gegenüber dieser Basis unverändert.
- Die Dokumentationsnachträge wurden aus den PR-Diffs isoliert und auf dem vollständigen aktuellen Main-Dokumentationsstand angehängt. Bestehende neuere Main-Einträge bleiben vollständig erhalten.

## Übernommene Änderungen
1. [PR #657](https://github.com/ManuEtt/Dnd/pull/657), Quell-HEAD `6ded9f77974a928d493ba1a057e77814cea6ec78`: kodierte Dart-URI-Literale in der Story-/Regel-Modulgrenzenprüfung fail-closed ablehnen. Regressionen für Escape-Sequenzen, Prozentkodierung, bedingte Direktiven und zulässige normale Imports.
2. [PR #662](https://github.com/ManuEtt/Dnd/pull/662), Quell-HEAD `9298b71131450eeee1252a479720c39526502cf6`: mehrdeutige ZIP-Verzeichniseinträge mit mehrfachen abschließenden Schrägstrichen vor CRC-/Dekompressionsprüfung ablehnen. Reguläre Verzeichniseinträge bleiben zulässig.

Die Quell-HEADs werden als zusätzliche Commit-Eltern des Integrationscommits erhalten. Die vier Python-Fach-/Testdateien werden unverändert aus den jeweiligen Quellbranches übernommen.

## Geänderte Dateien
- `scripts/check_domain_boundaries.py`
- `scripts/tests/test_domain_boundaries.py`
- `scripts/verify_project.py`
- `scripts/tests/test_verify_project.py`
- `README.md` (ausschließlich append-only)
- `docs/CODEX_CHECKPOINT.md` (ausschließlich append-only)
- `docs/parallel/CHAT_D_CHECKPOINT.md` (ausschließlich append-only)
- dieser Integrationsbericht

## Tests und CI
- PR #657: [Workflow #42595675213](https://github.com/ManuEtt/Dnd/actions/runs/42595675213), sechs von sechs Jobs erfolgreich auf Quell-HEAD `6ded9f77974a928d493ba1a057e77814cea6ec78`.
- PR #662: [Workflow #42641236946](https://github.com/ManuEtt/Dnd/actions/runs/42641236946), sechs von sechs Jobs erfolgreich auf Quell-HEAD `9298b71131450eeee1252a479720c39526502cf6`.
- Ausgangs-main: [Workflow #42641562891](https://github.com/ManuEtt/Dnd/actions/runs/42641562891), sechs von sechs Jobs erfolgreich auf `f848cedef7787e2e89df7b63d93d04dfb06ed8ed`.
- Die kombinierte CI dieses Integrationsbranches muss nach Veröffentlichung neu ausgeführt werden; die getrennten Quell-Workflows sind kein kombinierter CI-Nachweis.
- Lokale Python-/Flutter-/Backend-Ausführung wurde in dieser Sitzung mangels lokalem Repository-Checkout nicht vorgenommen.

## Kompatibilität und Grenzen
Keine Änderung an App-/Backend-Laufzeitcode, Spielständen, SQLite, JSON, Backupformat, App-Version oder Datenmigration. Die Änderungen betreffen ausschließlich Python-Projektprüfer und deren Tests sowie Dokumentation. Keine Original-PRs werden automatisch geschlossen oder gemergt.
