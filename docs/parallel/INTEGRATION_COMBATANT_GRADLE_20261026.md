# Integration: Kampfteilnehmerkarte und Gradle-Properties-Prüfung

Aktueller Ausgangspunkt: `20098805d8c70cbd361a13862379894c47ef4eb6`.

- Chat C, PR #216: `1c89286def233ea36be703924f0fa4e7f4dd186f`, neue responsive Kampfteilnehmerkarte und Widgettests.
- Chat D, PR #218 (Draft): `a8b4a151c07a95f13d9b1cdb99e9e2ddc7b539ae`, Behandlung von Java-Properties-Escapes und Fortsetzungszeilen mit Python-Tests.

Die aktuelle Hauptversion enthält nachweislich Korrekturen der alten ZIP-/Checkpoint-Tests, die auf dem historischen PR-#216-Ausgangspunkt fehlgeschlagen waren. Die Fachdateien beider PRs liegen in unterschiedlichen Pfaden. Neuere globale README- und CODEX_CHECKPOINT-Fassungen wurden nicht durch alte Inhalte ersetzt. Beide historischen Branch-Köpfe sind zusätzliche Git-Eltern des Integrationscommits, sodass ihre vollständigen Commits erhalten bleiben.

**Sicherheitskontrolle:** Der neue kombinierte Commit hat bisher kein eigenes grünes Build-Ergebnis. Nicht ohne eigene CI nach main übernehmen. Ein Erfolg der bisherigen #218-Tests allein genügt nicht.
