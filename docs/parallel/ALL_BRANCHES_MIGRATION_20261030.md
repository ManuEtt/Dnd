# Gesamtintegration aller Branches – 30.10.2026, Issue #425

## Auftrag und Umfang

Die neue ausdrückliche Nutzerweisung umfasst die fachlich geprüfte Migration
aller Entwicklungsbranches, Fehlerkorrekturen, anschließende sichere Bereinigung
und den Abschluss von Issue #425. Sie erweitert den vorherigen Chat-A-Auftrag;
keine weitere Fachfunktion wird unabhängig von dieser Integration begonnen.

Ausgangs-Main: `6465a4b2fc8d42ae7aab596ac26e85d61d2b8f49`.
Arbeitsbranch: `integrate/all-branches-issue425-20261030`.
Kombinierter Fachstand mit Version **0.8.49+99**: `b0a4211c`.
Anfangs 45 Entwicklungsbranches plus Main und 41 offene PRs; während der
Analyse zusätzlich #437 aufgenommen. Das [Referenzregister](MIGRATION_BRANCHES_20261030.json)
enthält alle 47 gesicherten Ausgangs-/Entwicklungsreferenzen mit vollem SHA,
Ursprungs-PR und unveränderlichem Archivtag. Alle sind Vorfahren des Fachstands.

## Verfahren und Quellen

Vier getrennte lokale Gruppen wurden mit regulären Merge-Commits aufgebaut
und nach Prüfung in den Gesamtbranch übernommen. Keine ursprüngliche Branch
wurde überschrieben, kein Rebase und kein Force-Push:

| Gruppe | Ursprüngliche Heads | Geprüfter Gruppenkopf | Bericht |
| --- | --- | --- | --- |
| Regeln A | 13 | `a97b8c529e0ec7cd57ef545aa7c22c6e4fac0b46` | [A](CHAT_A_MIGRATION_20261030.md) |
| Story B | 7 | `c8de752ad5ae6e4133924f4530898373a390d3de` | [B](CHAT_B_MIGRATION_REVIEW_20261030.md) |
| Oberfläche C und NPC-Reparatur | 10 | `d02a59dd1d4b55be3c391cfcde78e9b0ab97be6d` | [C](CHAT_C_ALL_BRANCHES_INTEGRATION_20261030.md) |
| Infrastruktur D | 15 | `400528abbd5f75b68b00f4c00aa70886a2416f46` | [D](CHAT_D_MIGRATION_20261030.md) |

Die vollständige bisherige Main-Dokumentation und alle additiven Fachberichte
wurden vereinigt. Nur Markdownkonflikte und ein einziger Kommentarunterschied
zwischen ursprünglicher und synchronisierter Zauberwirkzeitdatei mussten
aufgelöst werden. Die neuere technische Wirkzeitversion wurde beibehalten;
beide Historien bleiben vorhanden. Anforderungs-JSON wurde nach den bestehenden
unterschiedlichen Regel-IDs kombiniert, ohne neue globale Vollständigkeit.

Auch der neue #437 ist regulär als Commit-Vorfahre aufgenommen. Seine zwölf
technischen Dateien sind bereits durch B/C enthalten; die zusätzlichen
Dokumentationsabschnitte bleiben erhalten. Vollständige kombinierte README,
Checkpoints, Changelog und Entwicklungsstatus sind vor dem kompakten Live-Status
[bytegenau archiviert](../history/migration_20261030/manifest.json).

## Tatsächlich behobene Integrationsfehler

1. Konzentrationsvorbereitung erlaubte bestätigte Gesamtmodifikatoren bis ±60,
   die nachfolgende Auflösung jedoch nur ±30. Beide bestehenden Vertragsseiten
   akzeptieren jetzt denselben vorbereiteten Gesamtbereich; zusätzliche
   Spielerwerte behalten ihre engere ±30-Grenze. Positive und negative belegte
   Gesamtwerte +36/−38 werden konsistent weitergereicht, ±61 abgewiesen.
2. Eine benannte Zweitklasse auf Stufe 0 wurde von der Konzentrationsvorbereitung
   akzeptiert. Die bereits vorhandene Klassenvalidierung wird jetzt auch für
   diesen Fall verlangt. Kein automatischer Bonus für ungültige Klassen.
3. Strukturierter NPC-Kontext entfernte Richtungszeichen beim Namensvergleich,
   lesbare Legacy-Kontexte ersetzten sie durch Leerzeichen. `Mira` und
   `Mi\u200era` konnten so falsch als eindeutig gelten. Alle Projektionen
   erkennen nun dieselbe Mehrdeutigkeit, echte Leerzeichen bleiben relevant.

Alle drei Fehler wurden durch neue vorher rote Regressionen belegt. Es wurde
kein Test deaktiviert und keine neue Spielregel erfunden. Die NPC-Korrektur
ändert keine gespeicherten Namen oder Spielzustände.

## Abdeckung und offene Fachintegration

Laufende Spielpfade erhalten die Wirkzeit-/Komponenten-/Reichweiten-/Material-
und Klassen-/Ressourcenwächter. Layoutänderungen sind in echten Widgets
angebunden, Storyschutz in den bestehenden Speicher-/Wire-Pfaden.

Sechs neu übernommene Regelbausteine haben dagegen ausdrücklich noch keine
Aufrufer im vollständigen UI-/Controller-/Persistenzablauf:

- `SrdMagicMissileMultiTargetCastRules`;
- `SrdMagicMissileEncounterHpRules` (nur Vorschau);
- `SrdSpellActionEconomyRules`;
- `SrdSpellMaterialValueRules`;
- `SrdConcentrationDamageRules`;
- `SrdConcentrationSaveModifierRules`.

Sie sind domänengetestete Teilbausteine, keine fertig integrierten Spielfunktionen.
Die Übernahme ihrer Branches ist kein Abschluss des gesamten Regelwerks oder
Charakterassistenten. 1.419 SRD-Prüfaufträge und neun Inventurlücken bleiben als
begrenzte Inventur ausgewiesen; keine globale Prozentzahl. Amtliches SRD 5.2.1,
CC BY 4.0; `THIRD_PARTY_NOTICES.md` unverändert.

## Tests und Freigabe

Die vier Gruppennachweise sind in den Berichten verlinkt. Gesamtprüfung:

- `bash scripts/check.sh`: kombinierte Python-/Backend-/Flutter-Abnahme;
- `flutter build apk --debug --target-platform android-arm64`;
- `bash gradlew :app:testDebugUnitTest --no-daemon`;
- vollständige GitHub-PR-CI auf finalem Head;
- regulärer PR-Merge mit erwartetem Head-SHA und anschließend vollständige
  neue Main-CI auf dem tatsächlichen aktuellen Main-SHA.

Beobachtete Endergebnisse werden in README/Checkpoint und PR fortgeschrieben.
Einzelne grüne Gruppen ersetzen keine dieser kombinierten Prüfungen.
Gerät/TalkBack/realer Upgrade-/KI-/Sprachpfad und produktive Signierung bleiben
ungetestet. SQLite **3** / äußeres JSON **1** unverändert, keine Migration.

## Sicherung und Löschbedingungen

Vor jeder Integration: vollständiges Ausgangs-Main-ZIP und Bundle aller Remote-
Heads unter `/workspace/artifacts/migration-issue425-20261030/ausgang/`.
Alle 47 während der Bestandsaufnahme erfassten Referenzen wurden außerdem als
`archive/pre-migration-20261030/<Branch>-<SHA12>` remote gesichert.

Nach endgültiger Main-CI werden Branchliste, alle offenen PRs und exakte Heads
frisch geprüft. Nur unveränderte vollständig integrierte Referenzen dürfen
entfernt werden. Der bestehende Cleanup-Workflow schützt offene Heads/Basen,
prüft Ancestry und archiviert vor dem Löschen erneut. Seine historisch feste
Tagwurzel `archive/merged-20261027/` ist kein aktueller Datumsnachweis.
Das alte `retire_merged_branches.py` besitzt eine historische feste Allowlist
und wird für heutige Branches ausdrücklich nicht als generischer Löscher genutzt.

Nach Bereinigung müssen die tatsächliche Abwesenheit jeder Remote-Referenz und
der exakt passende Archivtag nochmals unabhängig geprüft werden. Erst dann
Issue #425 als gelöst schließen. Neue aktive Änderungen dürfen nicht mitgelöscht
werden. Lokale alte WIP-Worktrees bleiben erhalten.

## Nächster Schritt

Nach gesicherter Integration: normale Mehrklassen-Zauberplätze für bestätigte
SRD-Klassenaliasnamen konsistent berechnen; `Wizard`/`Magier` identisch, Pact
Magic separat, keine geratenen unbekannten Klassen, Domain-/SQLite-/Retrytests.
Vor Beginn erneut Main und Parallel-PRs prüfen. Keine Hintergrundentwicklung
außerhalb der aktiven Sitzung.
