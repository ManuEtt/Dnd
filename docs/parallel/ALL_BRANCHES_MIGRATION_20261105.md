# Konsolidierte Branchmigration – 05.11.2026

## Status dieser Integrationsrunde

- **Arbeitsbranch:** `integration/open-prs-20261105-reviewed` (Ausgangs-`main`: `7b76d34e42f9f536993035876f8789d3405d70f9`).
- **21 zum Vergleichszeitpunkt offene PRs:** alle Head-SHAs als Git-Merge-Vorfahren im Arbeitsbranch erhalten; Änderungen an fachlichem Code, Regressionstests und individuellen Dokumentationsberichten in die gemeinsame Arbeitsbaumfassung übernommen.
- **Drei ersetzte Arbeitsbranches:** ebenfalls als Git-Merge-Vorfahren archiviert; produktive Implementierungen durch geprüfte Nachfolger abgedeckt, korrigierte Testformatierung bleibt maßgeblich.
- **Nicht übernommen als einfache Blob-Überschreibung:** kollidierende README-/Changelog-/Status-/Checkpoint-Dateien. Sie werden als zentraler, append-only Nachtrag dokumentiert, historische Originale sind durch Merge-Vorfahren erreichbar.
- **Regel-Audit:** beide unabhängigen Hunk-Änderungen aus PR #557 und #576 in `docs/srd_5_2_1_requirements.json` integriert und als JSON geparst.
- **WICHTIG:** Diese Zusammenstellung ist zunächst ein Integrationskandidat. Eine erfolgreiche gemeinsame Flutter-/Python-/Backend-/APK-CI, ein abgeschlossener `main`-Merge und eine Branch-Löschung dürfen erst nach den entsprechenden realen Nachweisen behauptet werden.

## In der Git-Historie konservierte PR-Heads

| PR | Quelle (unveränderter HEAD zum Integrationszeitpunkt) | Änderung | Ursprung |
| --- | --- | --- | --- |
| [#543](https://github.com/ManuEtt/Dnd/pull/543) | `6327e403cf2831bda20853db426d131298a660a1` | fix Paktmagie-Slots nur aus konsistenten SRD-Klassenprofilen | `feat/chat-a/pact-magic-class-profile-20261105` |
| [#545](https://github.com/ManuEtt/Dnd/pull/545) | `1f8d5f4561248f5fc36f1e6f55dc658db651250d` | feat Kampagnenrückblick gegen veraltete Storyquellen absichern | `feat/chat-b/resume-snapshot-stale-20261105` |
| [#546](https://github.com/ManuEtt/Dnd/pull/546) | `917616cd4577760c99fe702930832cf988d7c969` | fix gleichnamige Orte im bestätigten Langzeitgedächtnis unterscheiden | `feat/chat-b/place-recall-id-continuity-20261105` |
| [#548](https://github.com/ManuEtt/Dnd/pull/548) | `db16842615022b7fe3c6cc29e87abb9f7b0f2781` | feat gespeicherte Klassen-Zaubervorbereitung im SRD-Preflight prüfen | `feat/chat-a/prepared-spell-proof-preflight-20261105` |
| [#549](https://github.com/ManuEtt/Dnd/pull/549) | `16a06ddbfa8ae17a6b7469d003c40fcbb8d493de` | fix Fertigkeitensuche über Android-Tastatur halten | `feat/chat-c/skill-search-ime-safe-sheet-20261105` |
| [#551](https://github.com/ManuEtt/Dnd/pull/551) | `4d2f360b6d05b0dc09e87640e6256acf445849e3` | feat bestätigte Mehrklassen-Zauberquelle bis zum Turn-Staging weiterreichen | `feat/chat-a/spell-turn-class-confirmation-20261105` |
| [#554](https://github.com/ManuEtt/Dnd/pull/554) | `2d7fd66140a8e723601ea0a939a344103acc54f3` | fix Zauber- und Paktverbrauch vor langer Rast validieren (sauberer CI-Branch) | `feat/chat-a/long-rest-spell-guard-clean-20261105` |
| [#556](https://github.com/ManuEtt/Dnd/pull/556) | `b1107b1bb3d0c2fab6b1a040c77c109b466e1f31` | fix Outbox-Fehler für TalkBack als Live-Meldung markieren | `feat/chat-c/pending-error-live-region-20261105` |
| [#557](https://github.com/ManuEtt/Dnd/pull/557) | `8478dbb477acd47eb5f84d6c4b98c121360993e1` | fix erste manuelle Rettungswürfe vor Klassenbonus und W20 validieren | `fix/chat-a/manual-save-class-preflight-20261105` |
| [#560](https://github.com/ManuEtt/Dnd/pull/560) | `a7867dc2f675c1ba1a7faec8f9814e3fc8da7df1` | fix freie KI-Erzählungen gegen unsichtbare Unicode-Steuerzeichen schützen | `feat/chat-b/narration-provider-format-guard-20261105` |
| [#561](https://github.com/ManuEtt/Dnd/pull/561) | `22a1697e241ffee214ec7e60c3d4b35731e8558a` | fix Zweite Luft und Aktionsschub nur mit gültigem Kämpfer-Klassenprofil | `feat/chat-a/fighter-resource-class-profile-20261105` |
| [#564](https://github.com/ManuEtt/Dnd/pull/564) | `a1bafbc03c6621f9c905768a582ab5dd6e70ca4e` | fix Zauberkraftregeneration nur bei gültigem Zauberer-Klassenprofil | `feat/chat-a/sorcerous-restoration-class-profile-20261105` |
| [#565](https://github.com/ManuEtt/Dnd/pull/565) | `4aa600b548bdbed7e58689fa8d89ce47fce77a86` | fix ältere Unicode-Formatzeichen in bestätigten NPC-Rückblicken absichern | `feat/chat-b/npc-continuity-legacy-format-20261105` |
| [#566](https://github.com/ManuEtt/Dnd/pull/566) | `547903951284a3044c33baabbdd9eb38faf497c6` | fix Materialauswahl gegen doppelte und ungültige Inventar-IDs absichern | `feat/chat-c/material-inventory-id-ui-20261105` |
| [#567](https://github.com/ManuEtt/Dnd/pull/567) | `b45295e63c85b01bb721aacff7002fdc840e669a` | fix Gradle-Wrapper-JAR gegen nicht portable ZIP-Pfadnamen absichern | `fix/chat-d/wrapper-jar-portable-paths-20261105` |
| [#568](https://github.com/ManuEtt/Dnd/pull/568) | `14d7bad3c8d1c8f8b49e785174aa6497e0a9eba3` | fix Entrinnen nur mit konsistentem Mönch-/Schurken-Klassenprofil | `feat/chat-a/evasion-class-profile-20261105` |
| [#569](https://github.com/ManuEtt/Dnd/pull/569) | `bd1bbda92bdea04f9ff7fc3b654e3c51b566a0c4` | fix NPC-Erzählergedächtnis gegen ältere unsichtbare Unicode-Zeichen absichern | `feat/chat-b/npc-narrator-legacy-unicode-main-sync-20261105` |
| [#570](https://github.com/ManuEtt/Dnd/pull/570) | `2d384c16366bd43cf6169b2268c6fee86f25b551` | fix JSON-Importdialog bei großer Schrift und Android-Tastatur bedienbar halten | `feat/chat-c/backup-import-ime-accessible-20261105` |
| [#573](https://github.com/ManuEtt/Dnd/pull/573) | `620b434e37662ecfbd18a873eca6d94860d11e1e` | fix Windows-Gerätenamen in Alpha-APK-ZIP-Pfaden abweisen | `fix/chat-d/apk-windows-device-names-20261105` |
| [#575](https://github.com/ManuEtt/Dnd/pull/575) | `3e337df8506b37885c7344414a6953a19ef00476` | ci: Android-Alpha-Buildaktionen auf Node.js 24 aktualisieren | `fix/chat-d/android-actions-node24-20261105` |
| [#576](https://github.com/ManuEtt/Dnd/pull/576) | `0a8439ebf0a064ca09a4f9dc9e331f13280d7d33` | fix: Überlegene Inspiration nur mit konsistenten Barden-Klassenstufen | `fix/chat-a/bard-superior-inspiration-profile-20261105` |

## Ersetzte, aber historisch gesicherte Arbeit

- `diagnostic/chat-a/dart-format-pr561-20261105` @ `4c383ffadff50228fce8a7a0a04abc1e22d6fc0e`: identische Produktimplementierung wie #561; korrigierte Regressionstestformatierung von #561 bleibt erhalten, diagnostische Workflow-Abweichung nicht aktiviert.
- `feat/chat-a/long-rest-spell-pool-preflight-20261105` @ `5d2dfca0c12e8b1f49bb070c0fa6a50af86e75a2`: Produkt- und Testdateien bytegleich mit dem sauberen Folge-PR #554.
- `feat/chat-b/npc-narrator-legacy-unicode-20261105` @ `d3a9db52f48d480bd1a690258dce9bfb18f339a1`: Produktdatei identisch mit der synchronisierten Fassung #569; deren formatierte Tests bleiben erhalten.

## Schutzmaßnahmen und verbleibende Abnahmen

1. Kein Force-Push, keine direkte Änderung von `main` und keine vorzeitige Branchlöschung.
2. Nach dem Integrations-PR die vollständige CI des **kombinierten** Heads prüfen und konkrete Fehler auf dem selben Branch korrigieren.
3. Aktuelle fremde PR-Heads erneut vergleichen, bevor sie durch einen Merge als integriert gelten; parallel veröffentlichte neue Commits nicht verlieren.
4. Nach erfolgreicher `main`-CI darf der bestehende Workflow `cleanup-merged-safe-20261027.yml` nur vollständig übernommene, ungeschützte, nicht mehr in offenen PRs referenzierte Heads nach Erstellen eines identischen Archiv-Tags entfernen.
5. Issues #333 und #425 enthalten den abgeschlossenen Historienstand aus Oktober, nicht die Bestätigung dieser neuen November-Integration.

## Qualitätssicherung

- Vor Integrationsbeginn war `main` auf `7b76d34e...` mit Android-Alpha-CI #42072388815 grün.
- Individuelle PR-Workflows wurden geprüft; der Großteil war erfolgreich, bei der Bestandserhebung liefen jüngste Prüfungen noch.
- **Gesamttests des Integrationsheads:** ausstehend, bis der neue PR-Workflow sie wirklich durchgeführt hat.
- Echte Android-Geräteabnahme, Signierung und Altversionsupgrade sind weiterhin nicht durch diese Integration abgedeckt.
