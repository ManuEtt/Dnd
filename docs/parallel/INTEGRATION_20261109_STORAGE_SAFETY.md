# Integrationsprüfung – sichere Dateiveröffentlichung und Checkpoint-Historie (09.11.2026)

## Ausgangspunkt und geprüfte Quellen

- Repo `ManuEtt/Dnd`, Integrationsbranch `fix/chat-d/integrate-storage-safety-20261109`.
- **Main-Basis:** `1cb332437624b9440cf21d338da45aa680578d53` (vollständig geprüftes Integrationspaket #652, gemergt). Der neu gestartete **Main-CI-Lauf #42559588669** war bei Beginn dieses Pakets noch `in_progress`; das ist kein grüner Nachweis für Main.
- **[PR #608](https://github.com/ManuEtt/Dnd/pull/608)**, Quell-HEAD `3f3f66948bd656156b636158997cb13622557a55`: exklusive Veröffentlichung eines versionierten Alpha-Source-ZIP mit SHA256-Sidecar. [Quell-CI #42199985399](https://github.com/ManuEtt/Dnd/actions/runs/42199985399): `completed/success`, sechs Jobs.
- **[PR #592](https://github.com/ManuEtt/Dnd/pull/592)**, Quell-HEAD `5fae563fbc795adc84e9278c20ad4223d6b45654`: kollisionssichere historische Dateinamen in Quellcode-Checkpoints. [Quell-CI #42515577415](https://github.com/ManuEtt/Dnd/actions/runs/42515577415): `completed/success`, sechs Jobs.
- **[PR #645](https://github.com/ManuEtt/Dnd/pull/645)**, Quell-HEAD `03169d4bcf229392d4b6e46de883253a4913b4a9`: beim Grafikimport existierende Zielpfade mit nicht regulärem Dateityp verwerfen. [Quell-CI #42514569047](https://github.com/ManuEtt/Dnd/actions/runs/42514569047): `completed/success`, sechs Jobs.
- Vollständige Original-Commit-Historien werden als zusätzliche Git-Eltern des Integrationscommits erhalten; keine Branches umgeschrieben oder gelöscht.

## Unverändert übernommene Fachdateien

1. `scripts/prepare_alpha_release.py` + `scripts/tests/test_prepare_alpha_release.py` exakt aus #608.
2. `scripts/create_checkpoint.py` + `scripts/tests/test_create_checkpoint.py` exakt aus #592.
3. `scripts/import_complete_fantasy_assets.py` + `scripts/tests/test_import_complete_fantasy_assets.py` exakt aus #645.

Alle sechs Pfade waren vom jeweiligen Quell-Basiscommit bis zum aktuellen `main` **blobidentisch**. In den weiteren 51 offenen PRs findet sich keine Änderung an einem dieser sechs Pfade. Die drei Fachpakete besitzen getrennte und unabhängige Dateien.

## Konfliktauflösung für gemeinsame Dokumentation

- `README.md`: Der gesamte Hauptbranch-Inhalt bleibt als unveränderter Präfix erhalten; nur die drei vollständigen neutralen Fachnachträge sind am absoluten Dateiende ergänzt, plus ein neutraler Integrationsnachtrag.
- `docs/CODEX_CHECKPOINT.md` und `docs/parallel/CHAT_D_CHECKPOINT.md`: Vollständiger Main-Präfix unverändert. Die Nachträge aus #592 und #645 waren append-only und wurden vollständig angehängt.
- Der alte PR #608 hatte seine Checkpoint-Ergänzung **vor** den Bestand geschrieben. Sie wurde im Integrationsstand **wortgetreu ans Ende** verlegt, damit bestehende Checkpoint-Historien und die aktuelle Append-only-Regel gewahrt bleiben. Das ursprüngliche Quell-Commit bleibt in der Git-Historie nachweisbar.
- Alle bisherigen fachlichen Hauptbranch-Nachträge, einschließlich der gemergten PRs #649/#650/#652, bleiben unverändert.

## Gates und Verträglichkeit

- **GETESTET:** sechs grüne CI-Jobs je Original-Quell-PR auf dessen finalem Head; 51 weitere PRs auf mögliche Fachdatei-Überschneidungen geprüft; unveränderte Basisblobs; vollständige Dokumentationspräfixe.
- **NICHT GETESTET:** die neue *gemeinsame* Integration auf ihrem abschließenden Dokumentations-HEAD; echtes Android-Gerät oder produktive Signierung; Installations-Upgrades.
- **BLOCKIERT:** Vor Main-Merge müssen die vollständige finale CI (Python, Backend, Dart/Flutter, Debug-APK, alle drei ABI-APKs, Release), die jeweils neueste Main-CI und der aktuelle PR-Konfliktstatus grün/geprüft sein.
- **Keine Migration:** Kein Eingriff in SQLite, JSON, Spielstände, Backups oder Persistenzschema; keine App-/Build-Versionserhöhung; keine Änderung an Regel-/Story-/UI-Produktion.
- **NÄCHSTER SCHRITT:** Endgültigen Integrationsstand als Draft-PR veröffentlichen, vollständige kombinierte CI abnehmen, danach erneut Main und offene PRs vergleichen, bei Erfolg regulär mergen und neue Main-CI prüfen.

## Veröffentlicht zur Review

- [Integrations-Pull-Request #655](https://github.com/ManuEtt/Dnd/pull/655), Draft.
- Fach-Integrationscommit `cede85fd9006b0869cd72187529c58fc13e14a7a` mit vier Git-Eltern und originalen Fachblobs.
- Gegen Main laut GitHub-Vergleich genau zehn Pfade; README +35/−0, zentraler Checkpoint +68/−0, persönlicher Checkpoint +72/−0 vor diesem Abschlussnachtrag.
- Die gemeinsame CI ist gesondert auf dem **letztgültigen Commit nach Dokumentationsnachträgen** abzunehmen; ein grüner Quell- oder Vor-Dokumentations-Commit genügt nicht.
