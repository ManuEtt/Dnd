# Bereinigung historischer GitHub Actions (04.11.2026)

Diese Änderung entfernt sieben überholte Workflow-Einstiegspunkte aus `.github/workflows/`, deren Code über die Git-Historie weiterhin wiederherstellbar ist:

- `chat-b-npc-note-format.yml`
- `cleanup-merged-branches-20261024.yml`
- `import-original-fantasy-art.yml`
- `retire-audited-branches-20261022.yml`
- `retire-character-branches-20261023.yml`
- `retire-verified-branches-20261026.yml`
- `retire-verified-story-ui-branches-20261027.yml`

**Begründung:** Der alte NPC-Formatter war nur an einen nicht mehr existierenden Branch gebunden. Die drei alten aktiven Einmal-Branch-Löschskripte konnten manuell parallel zum neuen SHA-sicheren Workflow Schreiboperationen ausführen. Die zwei bereits stillgelegten Cleanup-Stubs waren nur noch UI-Rauschen. Der einmalige Bild-ZIP-Import setzt eine bestimmte eingehende ZIP-Datei voraus, die im aktuellen main nicht mehr existiert, und hatte direkte Main-Schreibberechtigung.

**Erhalten:** `android-build.yml`, `cleanup-merged-safe-20261027.yml`, `dart-format-reparieren.yml`, `chat-a-eldritch-regression.yml`, `srd-monk-class-regression.yml`. Insbesondere die exakte SHA-/Ancestor-/Archivtag-Verifikation für die Branchbereinigung bleibt unverändert.

**Optimiert:** Der vollständige Android-Workflow läuft bei Pushes nur noch auf `main`, bei allen Pull Requests weiterhin regulär und manuell per `workflow_dispatch`. Dadurch entfallen parallele doppelte Push- und PR-Alpha-Builds für Featurebranches. Änderungen an beliebigen Workflow-YAMLs werden über `.github/workflows/**` in die CI-Pfadfilter aufgenommen.

**Nicht behauptet:** dass historisch fehlgeschlagene Workflow-Runs/Artefakte gelöscht wurden oder dass auf diesem Cleanup-PR bereits alle Tests bestanden haben. Alte CI-Logs bleiben als Diagnose-/Auditnachweis erhalten. Beide abgeschlossenen Issues #333/#425 bleiben geschlossen.

**Abnahme:** CI des Cleanup-PR gegen main, nach der Zusammenführung erneute main-CI; dabei darf der maintained safe cleanup nur nach grüner Main-CI laufen.
