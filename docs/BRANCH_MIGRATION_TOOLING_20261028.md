# Branchmigration: Werkzeuggruppe 28.10.2026

## Ausgangsstand und Quellen

Basis Main: `dd0c2e94ccf0995c6070010b6af1df315205b36a`.
Arbeitsbranch: `integration/migration-tooling-20261028`.
Quellköpfe, durch reguläre Merge-Commits als Vorfahren erhalten:

- PR #316: `843fe4208dbc101f1a46553d97edf0e7c283eb16`.
- PR #335: `20a8c130d0ab860846b7c0afbf30c994e2f47502`.
- PR #301: `c190227882e0b96d31c036fe436640a36d4d0b47`.

## Implementiert

Der bestehende Dart-Importprüfer berücksichtigt alle bedingten Import-/Export-
URIs einschließlich Kommentare zwischen Direktivenbestandteilen. Die bisherigen
Story-/Regel- und Package-Grenzen gelten für jede Plattformvariante.

Der aktive Workflow `.github/workflows/cleanup-merged-safe-20261027.yml`
überspringt geschützte Branches vor jeder Archiv-/Löschprüfung. Vorhandene
Checks für aktuelle Main-CI, offene PR-Köpfe/-Basen, Ancestry, Archivtag und
unveränderte Referenzen bleiben unverändert.

Die veraltete PR-301-Bereinigung hätte einen zweiten automatischen Löschpfad
aktiviert und starre historische Blob-Stände vorausgesetzt. Nach Integration
neuerer Produktänderungen sind diese alten Gleichheitswerte kein geeigneter
aktueller Integrationsnachweis. Außerdem können konkurrierende automatische
Löschpfade auf bereits gelöschte Referenzen treffen. Deshalb ist ihr ausführbarer
Workflow jetzt ausschließlich ein `workflow_dispatch`-Hinweis mit `contents: read`,
ohne Actions-/JavaScript- oder Referenzoperationen. Der vollständige ursprüngliche
165-Zeilen-Workflow liegt bytegetreu unter
`docs/history/branch_migration_tooling_20261028/` samt SHA256-Manifest.

README-/Checkpoint-Konflikte wurden additiv aufgelöst. Main-Präfixe bleiben
erhalten; die ursprünglichen Konfliktseiten sind mit SHA256 archiviert.

## Getestet

- `python3 scripts/generate_fantasy_buttons.py`: 30 erwartete lokale PNGs erzeugt.
- `python3 scripts/verify_project.py`: bestanden.
- `python3 scripts/check_domain_boundaries.py`: bestanden.
- `python3 scripts/srd_coverage.py --json`: gültiges Register, 1.419 Prüfaufträge,
  neun Inventurlücken; kein globaler SRD-Fertigstellungsgrad.
- `python3 -m unittest discover -s scripts/tests -v`: **195 Tests bestanden**.
- Nach letzter Verschärfung der reinen Testprüfung: **28 gezielte Tests** für
  Domain-Grenzen, Schutz-Guard und inerten Altworkflow bestanden.
- `git diff --check`: bestanden.

Fünf neue Python-Tests prüfen den tatsächlich inaktiven Workflow, die Ablehnung
der originalen PR-301-Löschroutine, wieder eingeführte Push-Trigger, Schreibrechte,
Actions, zusätzliche Inline-Kommandos und Shell-Substitutionen, den Archiv-Hash
sowie die erhaltenen Gates des aktiven Nachfolgers. Die letzte Verschärfung
ändert keinen Produkt-/Workflow-Code und wurde zusätzlich gezielt ausgeführt.

## Nicht getestet und offen

Dieser Teilbranch enthält keine Dart-/Backend-Produktänderungen. Vollständige
kombinierte Flutter-, Backend-, Android- und GitHub-Prüfungen müssen trotzdem am
Gesamtmigrationskandidaten folgen. Keine echte Android-Geräteabnahme, kein
kostenpflichtiger Dienstaufruf, keine externe Sicherung, kein Remote-Push und
keine Branch-/Tag-Löschung in diesem Teilpaket. SQLite 2 und JSON 1 unverändert.

## Wiederaufnahme

Diesen Branch regulär in den Gesamtmigrationsbranch mergen, Konflikte additiv
auflösen und Gesamttests ausführen. Anschließend ausschließlich geprüften PR
nach Main übernehmen; erst nach erfolgreicher CI des dann aktuellen Main dürfen
archivierte, unveränderte, vollständig integrierte und unbenutzte Altbranches
bereinigt werden. Neue oder inzwischen veränderte Köpfe bleiben erhalten.
