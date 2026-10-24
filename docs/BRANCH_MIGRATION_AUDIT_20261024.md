# Branchmigration und auditierte Bereinigung vom 24.10.2026

Repository: `ManuEtt/Dnd`. Zielbranch: `main`. Dieser Bericht beschreibt die tatsächliche GitHub-Bestandsaufnahme und den geprüften Konsolidierungspfad; historische Dokumentations-Snapshots gelten nicht als aktuelle CI-Nachweise.

## Abgeschlossene Integrationen

| PR | Funktion | Main-Merge-Commit | Quellbranch-Head | CI-Nachweis |
| --- | --- | --- | --- | --- |
| [#149](https://github.com/ManuEtt/Dnd/pull/149) | EP-Belohnung, SQLite/Controller-Revisionsschutz und beschädigte Rabenwacht-Belege | `071ba6e39a5e5f01ef998508d8506fd718b67672` | `4a3821b44adacfeef8cd68c76b40d9bf7568030b` | [#40061181521](https://github.com/ManuEtt/Dnd/actions/runs/40061181521) erfolgreich |
| [#144](https://github.com/ManuEtt/Dnd/pull/144) | reiner SRD-Sending-Vorprüfungsdienst ohne automatische Zauberausführung | `72357804f00cdecd589e93fce373edd63de456b7` | `e8197465f298fff6f05b000bd6d145aecca0c2fc` | [#40061432707](https://github.com/ManuEtt/Dnd/actions/runs/40061432707) erfolgreich |
| [#151](https://github.com/ManuEtt/Dnd/pull/151) | ausdrücklich bestätigter Fantasy-EP-Dialog mit SQLite-E2E-Test | `aacafbd5ca6dd22a557b5e0c4c0cea0218e57124` | `b89f2a2d4b248e485fdf0a5540627c4b7c4cc8b8` | [#40061472370](https://github.com/ManuEtt/Dnd/actions/runs/40061472370) erfolgreich |

Die CI-Nachweise gehören jeweils zu den genannten Commits. Die aktuelle Main-CI nach #151 und dieser zusätzliche Testlauf sind gesondert zu prüfen.

## Altbranches und ihre Sicherung

Diese Branches sind nach GitHub-Commitvergleich vollständig von `main` umfasst (kein eigener vorausliegender Commit):

- `fix/atomic-campaign-deletion-selection-20261023` → `012c51d09f599ea4daf004834aef8e23d71c2fcc`.
- `fix/rabenwacht-xp-marker-integrity-20261024` → `ca9167cfec691c11710ea40cc364f245ae00202a`.
- `fix/confirmed-xp-ci-recovery-20261024` → `4a3821b44adacfeef8cd68c76b40d9bf7568030b`.
- `feat/srd-sending-message-rules-20261023` → `e8197465f298fff6f05b000bd6d145aecca0c2fc`.
- `feat/xp-reward-confirmation-ui-20261024` → `b89f2a2d4b248e485fdf0a5540627c4b7c4cc8b8`.

**Alternative ohne direkte Codeübernahme:** PR [#150](https://github.com/ManuEtt/Dnd/pull/150), `feat/confirmed-xp-dialog-20261024` → `6a977715e26ba17afb4577879f69f1ee4c57308e`. Dessen separater Dialog ist mit #151 funktional überlappend und darf nicht als zweite EP-Buchungsoberfläche in die App kopiert werden. Fehlende Eingabevalidierungs- und Zustimmungstestfälle aus #150 werden in die bestehende `experience_reward_dialog_test.dart` übernommen. **Vor Löschung** wird der alternative Head als leichter Git-Tag `archive/2026-10-24/pr150-alternative-xp-dialog` gesichert und PR #150 als ersetzt geschlossen. So geht die alternative Historie nicht verloren.

## Sicherheitskonzept der Branchbereinigung

Ein einmaliger, zusätzlich manuell auslösbarer [GitHub-Actions-Workflow](../.github/workflows/cleanup-merged-branches-20261024.yml) verwendet nur `GITHUB_TOKEN` mit begrenzten Schreibrechten auf Repository-Inhalte. Er läuft erstmals nur auf `main` beim Hinzufügen seiner Workflowdatei. Vor der Änderung von Referenzen prüft er, ob der jeweilige Branch noch auf dem exakt geprüften SHA steht; für fünf gemergte Branches zusätzlich, ob der Commit über den gemeinsamen Main-HEAD erreichbar ist. PR #150 muss geschlossen sein; dessen alternativer Commit wird vorher mit einem eigenen Tag gesichert. `main` wird niemals gelöscht oder zurückgesetzt. Ist eine Bedingung nicht erfüllt, bleibt der betroffene Branch bestehen.

Eine erfolgreich ausgeführte Branchbereinigung ist **erst durch abgeschlossenen GitHub-Actions-Lauf und neue Branchliste bestätigt**, nicht durch bloßes Anlegen oder Mergen dieses Workflows. Es gibt keinen Force-Push. Zusätzliche Apps/Geheimnisse sind nicht erforderlich.

## Grenzen

Der reziproke Zauber `Sending` führt derzeit nur eine isolierte Eingabe-/Regelprüfung aus, keine Nachricht und keinen Slot-Commit. Android-SDK-/Flutter-/CI-Testläufe ersetzen keinen echten Geräte- und Migrations-/Restore-Test. App-Version, Datenbank-Schema 2 und JSON-Schema 1 werden nicht verändert.
