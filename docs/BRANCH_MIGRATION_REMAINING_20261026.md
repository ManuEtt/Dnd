# Zusammenführung der nach PR #243 offenen Entwicklungsbeiträge (26.10.2026)

Dieses Integrationspaket basiert auf dem bereits nach main gemergten PR #243 (main `12e2df634c1f60e972681cef4ca08b41e2d29410`).

## Übernommene Quell- und Testdateien
- PR #244: Unicode-Plotgeheimnis-Schutz, `backend/src/story_secret_guard.ts` samt Tests.
- PR #245: TalkBack-Kampfwerte, `app/lib/ui/fantasy_combatant_card.dart` samt Tests.
- PR #246: Package-URI-Story-Grenze, `scripts/check_domain_boundaries.py` samt Tests.
- PR #247: V/S/M-Metadaten-Grammatik, `app/lib/domain/srd_spell_catalog.dart` und neue Regressionstests.
- PR #248: NPC-Namensmehrdeutigkeit, `app/lib/story/npc_narrator_memory.dart` samt Tests.

Diese zehn Quell-/Testdateien wurden anhand der entsprechenden vorhandenen GitHub-Blobs übernommen. Gemeinsam benutzte Dokumente (README, CODEX_CHECKPOINT und Chat-Checkpoints) werden nicht von veralteten Entwicklungsbranches überschrieben. Originalzweige und PRs bleiben bis zur integrierten Abnahme erhalten.

## Stand / offene Arbeit
- PR #242 besitzt trotz grünem Einzelcheck inzwischen einen Merge-Konflikt mit main. Seine Kernimplementierung `srd_spell_target_rules.dart` ist bereits byteidentisch in main; begleitende Tests/Dokumentation und etwaige neuere Differenzen sind noch separat zu verifizieren.
- CI des **kombinierten** Pakets ist abzuwarten. Grüne Einzel-PRs ersetzen diesen Nachweis nicht.
- Vor Freigabe: Python-/Grenztests, Backend-Tests, Dart-Format, Flutter-Analyse, Flutter-Test, native Android-Tests und Debug-APK auf dem Merge-Kandidaten prüfen.
- Keine Branches löschen, solange offene Änderungen, neue Commits oder unbestätigte Merges möglich sind.
- Keine Änderungen an SQLite/JSON-Datenschemata; keine Geräteabnahme behaupten.
