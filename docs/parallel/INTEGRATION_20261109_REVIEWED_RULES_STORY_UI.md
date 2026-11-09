# Integrationsprüfung – Ritualzauber, Epilog-NPC-Besuche, Heilzauber-Dialog

Stand: 2026-11-09. Ziel: `main`, Ausgangscommit `b2e1a021067cec39b7c85bdad11aa98477cac14e`. Arbeitsbranch: `fix/chat-d/integrate-three-reviewed-20261109`.

## Quellen und vollständig geprüfte Einzel-CI

| PR | Quell-HEAD | GitHub-Actions-Abnahme | Änderung |
| --- | --- | --- | --- |
| [#622](https://github.com/ManuEtt/Dnd/pull/622) | `62e05784e5d392e121dd349d34d90356525b8daf` | [#42360078379](https://github.com/ManuEtt/Dnd/actions/runs/42360078379), completed/success, sechs Jobs | SRD-Ritualidentitäten vor slotfreiem Wirken gegen geprüften Katalog absichern |
| [#628](https://github.com/ManuEtt/Dnd/pull/628) | `64c88176c74308c3ea3127aac14529563caba283` | [#42368317591](https://github.com/ManuEtt/Dnd/actions/runs/42368317591), completed/success, sechs Jobs | Orts-/NPC-Besuche im Rabenwacht-Epilog nur bei expliziter Handlung bestätigen |
| [#651](https://github.com/ManuEtt/Dnd/pull/651) | `59b8c5fd323785d885acc6224f6948db99293ee2` | [#42519714959](https://github.com/ManuEtt/Dnd/actions/runs/42519714959), completed/success, sechs Jobs | Heilzauberdialog nach bestätigtem Heldensnapshot neu aufbauen |

## Konflikt- und Herkunftsprüfung

- Alle drei Quell-PRs waren beim Erstellen weder Draft noch geschlossen; ihre Fach- und Testpfade unterscheiden sich paarweise.
- Sechs unveränderte Fach-/Testdateiblobs aus den Original-PR-Heads:
  - `app/lib/domain/srd_ritual_casting_rules.dart` – `47fb0c330ccba748e45b244e530ae8192dea287d`
  - `app/test/srd_ritual_catalog_identity_test.dart` – `35a1fffc653f310d2f80d1f0d5b1ccc8d099590b`
  - `app/lib/story/fourteenth_voice_epilogue.dart` – `bc4c0c29c1f1f99e4fa9b6312781c62fc09314ff`
  - `app/test/rabenwacht_epilogue_explicit_visit_test.dart` – `2af9dab3a9bbb614475816e15049f736753a3cbf`
  - `app/lib/ui/healing_spell_dialog.dart` – `7837a4549947990b3d10d230d68298e1b32c0520`
  - `app/test/healing_spell_live_snapshot_test.dart` – `77c7a952ef99473ab4120cbc8a9f80e6f150337b`
- Die drei Bestandsdateien sind bei `main` bis einschließlich Ausgangscommit blobidentisch zu ihren jeweiligen PR-Merge-Bases. Die drei Testdateien existierten auf `main` nicht.
- 51 andere beim abschließenden Abgleich offene Pull Requests wurden in ihrer vollständigen Liste geänderter Dateipfade geprüft; keine Überschneidung dieser sechs Pfade. Neue PRs müssen beim Merge erneut geprüft werden.
- Die vollständige **Original-Git-Historie** aller drei Quellen wird im Integrationscommit durch zusätzliche Merge-Eltern erhalten; keine künstliche Umbasierung/kein Force-Push.
- `README.md`, `docs/CODEX_CHECKPOINT.md` und `docs/parallel/CHAT_A_CHECKPOINT.md`, `CHAT_B_CHECKPOINT.md`, `CHAT_C_CHECKPOINT.md`: aktueller Main-Text vollständig als unverändertes Präfix, danach ausschließlich die jeweiligen Quell-Nachträge angehängt. README zusätzlich mit neutralem Integrationsnachtrag am absoluten Dateiende. Keine vorhandenen Einträge gekürzt.
- Unveränderte Daten-/SQLite-/JSON-Schemas, Buildnummer, Backend, bestehende Spielstände und Backups. Keine Datenmigration.

## Strikte Abnahme und nächste Schritte

- **GETESTET:** Die drei eigenständigen Quell-CIs auf den exakten Heads, jeweils sechs erfolgreiche Jobs. Das ist keine Abnahme der kombinierten Fassung.
- **NICHT GETESTET:** Der neue kombinierte Commit benötigt seine **eigene** vollständige CI: Projektprüfung, Modulgrenzen, SRD-Coverage, Python-Unittests, Backend-Typprüfung/Build/Tests, Dart-Format, Flutter-Analyse/Tests, native Android-Tests, Debug-APK, drei ABI-APKs, Alpha-Paket und Quellarchiv.
- **BLOCKIERT bis grün:** Kein Merge nach `main`. Der letzte Main-CI-Lauf `42594333535` war während der Vorbereitung noch `in_progress`; seinen Endstatus erneut prüfen.
- Erst auf dem finalen grünen Integrations-HEAD, mit aktuellem Main-Abgleich, erneutem PR-Fachpfadvergleich und erfolgreicher Main-CI mergen. Danach nachgewiesenermaßen integrierte Original-PRs schließen. Der vorhandene sichere Cleanup-Workflow archiviert alle unbenutzten, vollständig in Main enthaltenen Head-SHAs in Tags, bevor Branches gelöscht werden. Drafts und noch nicht integrierte Arbeiten bleiben unberührt.
- Reales Android-Gerät, Produktivsignierung und Versionsupgrade sind weiterhin nicht durch die CI abgenommen.
