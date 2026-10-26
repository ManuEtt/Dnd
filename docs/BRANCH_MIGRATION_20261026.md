# Branch-Konsolidierung – 26.10.2026

## Ausgangslage

Hauptbranch `main`, geprüfter Basis-SHA `542e0d46f0b4d858011fa90c1e0c2ba8800b8d0f`.
Bereits integriert waren die TalkBack-PRs #223 und #225 sowie die Backend-Korrektur #220.
Die zugehörigen TalkBack-Altbranches wurden durch einen separaten geprüften Bereinigungslauf bereits entfernt.

## Historienerhaltende Migration

[PR #233](https://github.com/ManuEtt/Dnd/pull/233) enthält auf einem gemeinsamen Branch die vollständigen
Git-Commit-Historien der ursprünglichen Feature-/Fix-Pakete:

| Ursprung | Aufgabe |
| --- | --- |
| #221 | Feuerpfeil-Klassenwerte und explizite Angriffsmodifikatorbestätigung |
| #222 | Strukturierte, ID-gebundene NPC-Erinnerung im Offline-Mock |
| #224 | Explizite NPC-Auswahl mit Revisionsschutz |
| #226 | Gleichnamige NPCs in bestätigten Rückblicken eindeutig zuordnen |
| #227 | Ungültige Säurespritzer-Ziel-IDs vor dem Wurf ablehnen |

Alle fünf Original-HEADs wurden vor ihrer Übernahme exakt mit ihren erwarteten SHA-Werten verglichen.
Bei konkurrierenden Änderungen an alten Checkpoints/README wurde der aktuelle Dokumentationsstand
erhalten; fachliche Quellcode- und Teständerungen ließen sich ohne Konflikte zusammenführen.
Originalcommits sind jeweils Vorfahren des Integrationsbranches (`behind_by=0`).
Die einzelnen GitHub-Android-CIs waren erfolgreich; eine Einzelabnahme gilt nicht als kombinierte Abnahme.

Kombinierte technische Python-Prüfungen erfolgreich:
[Integrationslauf A](https://github.com/ManuEtt/Dnd/actions/runs/40326665059),
[Integrationslauf B](https://github.com/ManuEtt/Dnd/actions/runs/40327400902).

## Abnahme und Branchbereinigung

Finaler Code-HEAD des Integrations-PRs bei Vorbereitung:
`0ed6bba297f88dcd44e83ae91dcbf2e4b97f8339`.

Vollständige [GitHub-CI #40327530670](https://github.com/ManuEtt/Dnd/actions/runs/40327530670):
vor Merge auf finalen Erfolg sämtlicher Python-/Backend-/Flutter-/Android-/APK-Schritte prüfen.
Keine Freigabe aufgrund früherer, abgebrochener oder noch laufender Builds behaupten.

[PR #235](https://github.com/ManuEtt/Dnd/pull/235) enthält die gesicherte Branchbereinigung,
die nach Integration ausgeführt werden soll. Sie prüft die `main`-SHA, offene PRs, die
tatsächliche Git-Ancestry und unveränderte Branch-HEADs vor dem Löschen. Bei dokumentations-
only Varianten wird deren SHA vorher unter `archive/2026-10-26/...` als Tag erhalten.
Nicht integrierte fachliche Änderungen bleiben unberührt.

Nicht durch GitHub-CI abgedeckt sind reale Geräteinstallationen, Upgrade von Altspielständen
auf einem physischen Gerät, produktive Signierung und vollständige SRD-5.2.1-Regelabdeckung.
