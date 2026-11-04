# A–D-Gesamtintegration und Bereinigung der GitHub Actions – 04.11.2026

## Ausgangszustand
Main-HEAD `c8f25132a82bcf55368a79100e0c2ea5595140b6`.
Fünf offene Draft-PRs mit disjunkten Fach-/Testpfaden, aber konkurrierenden README-/Checkpoint-Ergänzungen:

| PR | Arbeitspaket | Gesicherter HEAD |
| --- | --- | --- |
| [#535](https://github.com/ManuEtt/Dnd/pull/535) | TalkBack-Semantik des Kampagnen-EP-Fortschritts | `b7115900499fe44276bac218dc0f748b2d6da102` |
| [#536](https://github.com/ManuEtt/Dnd/pull/536) | Eindeutige StoryThread-IDs beim Wiederaufnehmen | `87b15f353de50e42e5ca930d1524b5cd570fda5e` |
| [#537](https://github.com/ManuEtt/Dnd/pull/537) | Java-konforme Gradle-Properties-Whitespace-Prüfung | `5db7bbdb666d27e750a3b709bbf46d049cc12b55` |
| [#538](https://github.com/ManuEtt/Dnd/pull/538) | Waldläufer-Unermüdlich nur bei validen Klassen | `5804de7bd094d86ff931179f1e2a3e7c400bf32d` |
| [#539](https://github.com/ManuEtt/Dnd/pull/539) | Magische List nur bei validen Hexenmeisterklassen | `6eb3155e1c23853b16aa6f8109768b320425ed52` |

## Konsolidierung
Der Arbeitsbranch `fix/chat-d/branch-migration-actions-20261104` erhält alle fünf
Original-HEADs als zusätzliche Eltern des Integrationscommits. Die zehn
Fach- und Testdateien werden über ihre unveränderten Git-Blob-SHAs eingebunden.
README und zentrale/persönliche Checkpoints übernehmen die
additiven Textbeiträge *aller* PRs, ohne historische Abschnitte von main zu
löschen. Ein regulärer Merge des Integrations-PR (nicht Squash/Rebase) bewahrt
damit die Commit-Historien sowie die Vorfahrenbeziehungen zur sicheren
nachgelagerten Branchbereinigung.

Keine Änderung am SQLite-Schema 3, externen JSON-Format 1, Benutzer-Speicherdaten
oder der App-Version; keine Datenmigration.

## GitHub Actions und Fehler
Die Einzel-PRs #536, #537 und #538 haben abgeschlossene erfolgreiche PR-CI.
Bei #535 und #539 bestanden auf den zuletzt geprüften PR-Läufen Python,
Backend, Dart-Format, Flutter-Analyse/-Vollsuite, Debug-APK und native
Android-Tests. Erst der gemeinsame Schritt für drei optimierte Release-ABIs
und der zusätzliche History-Checkpoint scheiterten. Der Push-CI-Lauf für
#539 war auf identischem HEAD vollständig grün. Die Logs der beiden
fehlerhaften Jobs ließen sich zum Analysezeitpunkt nicht mehr abrufen:
eine konkrete Fehlerursache ist deshalb **nicht** bestätigt.

Die zentrale `.github/workflows/android-build.yml` wird strukturiert in:
1. die unveränderten Qualitätstests plus Debug-APK,
2. drei dedizierte Release-ABI-Jobs auf separaten Runnern,
3. Release-Paketierung nach erfolgreichem Abschluss,
4. Quellarchivierung auf einem weiteren Runner, auch bei Fehlern.

Alle früheren Prüfkommandos bleiben erhalten. Der Rootcause
(Platz-/Ressourcenproblem als Hypothese) ist durch die neue CI erst
nach dem vollständigen Integrations-PR-Lauf zu verifizieren.

Neun veraltete/duplizierte oder einmalige Workflow-Dateien entfallen:
`chat-a-eldritch-regression.yml`,
`chat-b-npc-note-format.yml`,
`cleanup-merged-branches-20261024.yml`,
`import-original-fantasy-art.yml`,
`retire-audited-branches-20261022.yml`,
`retire-character-branches-20261023.yml`,
`retire-verified-branches-20261026.yml`,
`retire-verified-story-ui-branches-20261027.yml`,
`srd-monk-class-regression.yml`.
Die alte Laufhistorie bleibt als nachvollziehbarer Audit-Trail erhalten.
Der Hauptworkflow, der abgesicherte automatische Cleanup und die
manuelle Dart-Formatierungsreparatur bleiben verfügbar.

Der verbliebene `cleanup-merged-safe-20261027.yml` löscht Branches
**ausschließlich** nach erfolgreicher CI des exakt aktuellen main-HEADs,
unter Schutz offener PRs, mit SHA-/Ancestor-Prüfung und Archivtags.

## Issues / Abnahme
Zum Ausgangszeitpunkt kein eigenständiges offenes Issue.
Das frühere Migrations-Issue [#425](https://github.com/ManuEtt/Dnd/issues/425)
ist bereits mit `completed` am 31.10.2026 geschlossen.

**Noch offen vor endgültiger Abnahme:** Gesamt-CI auf dem vereinigen
Integrations-HEAD abwarten und alle Jobs prüfen; danach regulärer Merge
nach main; ursprüngliche PRs kontrollieren/abschließen; grüne Main-CI und
anschließende Branch-Archivierung/-Löschung verifizieren. Bis dahin
bleiben alle fünf alten PR-Branches erhalten. Reale Geräte-, TalkBack-
und Upgrade-Abnahme ist separat offen.
