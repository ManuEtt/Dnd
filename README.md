# Würfelraunen – Der lebendige Spielleiter

Deutschsprachige Android-Alpha für Soloabenteuer und regelgeprüfte Kampagnen. Die vollständige Umsetzung des SRD 5.2.1 bleibt in Arbeit.

## Aktueller Stand und autonome Fortsetzung (25.10.2026, nach Main-Merge)

**PR #171 wurde regulär (ohne Squash) nach `main` gemergt:** [Merge-Commit `635773db33724f543d61bacde9a9ebe679b9b1e9`](https://github.com/ManuEtt/Dnd/commit/635773db33724f543d61bacde9a9ebe679b9b1e9). Version **0.8.39+89**, SQLite 2 und Kampagnen-JSON 1 unverändert. Kombinierte finale [PR-CI #40192473811](https://github.com/ManuEtt/Dnd/actions/runs/40192473811) auf `255a5a0` **erfolgreich**. Die eigenständige [Main-CI #40193476536](https://github.com/ManuEtt/Dnd/actions/runs/40193476536) auf exakt `635773db` ist **vollständig erfolgreich**: einschließlich Flutter-/Backend-Tests, Android-Debug-APK, nativen Tests, ARM-/Alpha-APKs und Quellcode-Checkpoint.

Unabhängiger GitHub-Abgleich: **19/19** Migrations-Archivtags zeigen auf ihre protokollierten Original-SHAs; **19/19** Originalköpfe sind Vorfahren von `255a5a0`. Der finale Integrationskopf besitzt einen zusätzlichen [Archivtag](https://github.com/ManuEtt/Dnd/tree/archive/branch-migration-20261025T075644Z/integration-final-255a5a0). Die lokale Bundle-Datei wurde in dieser Sitzung nicht erneut geöffnet.

Die sechs gestapelten Vorgänger-PRs **#165, #166, #167, #168, #169 und #172** wurden nach erfolgreicher Main-CI und erneutem Ancestry-Check geschlossen, ohne Doppel-Merge. **Remote-Branches wurden nicht gelöscht**, die gesicherten SHA-Tags bleiben bestehen. Die abschließende Branchlöschung erfordert einen SHA-gesicherten GitHub-Ref-Löschzugriff, der in dieser Sitzung nicht verfügbar ist. Weitere Schritte und Vorbehalte: [aktueller Checkpoint](docs/CODEX_CHECKPOINT.md).

## Historischer Integrationsstand vor dem Main-Merge (25.10.2026)

**Version 0.8.39+89 – geprüfter Integrationsstand aller 19 erfassten GitHub-Branches.** [PR #171](https://github.com/ManuEtt/Dnd/pull/171) vereinigt ihre Änderungen auf `integration/all-branches-20261025`; Funktionscommit `cd724629c79a169ff1a078517031a33cf73ae130`. Ausgangs-Main: `b60ffe7ff1aae502ea927cb77153b988be33e397`. Main-Übernahme, Main-CI und abschließende Branchlöschung sind noch ausstehende Schritte dieses Auftrags.

Sending-W100-Validierung, Verbündetenbestätigung bei zulässigen Nebenhandangriffen, allgemeine Light-Nahkampfbonusangriffe, Schutz abgeschlossener Storyfäden, lokale und serverseitige ID-Kollisionssperren, Plot-Geheimnisschutz, Backend-Limiter und sichere Projektarchive sind vereinigt. Der bei der Integration gefundene Casefold-Fehler für generierte/Systemdateien ist mit Regressionstest behoben. Fehler beim ZIP-Schreiben oder Veröffentlichen der Prüfsumme bewahren das zuvor vorhandene Archiv; keine Zusage einer absturzübergreifend atomaren Dateipaar-Transaktion.

**1.552 Flutter-, 106 Python-, 40 Backend- und 12 native Android-Tests bestanden.** Dart-Formatierung: 360 Dateien unverändert; Flutter-Analyse sowie Backend-Typecheck und -Build erfolgreich. Debug-APK und ARM64-Alpha gebaut; Version, ZIP-CRC, ABI und lokale Debug-Signatur geprüft. Flutter-/Backend-Abnahme und APK-Quelle: `6aef90d`; App, Backend und Workflow sind im neueren Integrationscommit bytegleich. Die nachfolgende reine Archivänderung hat alle 106 Python-Tests bestanden. Gemeinsame finale GitHub-CI wird gesondert auf dem finalen PR-Head abgenommen. Echtes Gerät, Altspielstand-Upgrade auf einem Gerät und produktive Signierung sind nicht getestet.

Alle 19 erfassten Köpfe sind echte Vorfahren. Vorherige Branchstände bleiben über remote geprüfte Tags unter `archive/branch-migration-20261025T075644Z` und vollständige, verifizierte Git-Bundles wiederherstellbar. 42 konfliktbehaftete/historische Dokumente sind bytegenau archiviert. SQLite-Version 2 und Kampagnen-JSON-Version 1 bleiben unverändert.

[Operativer Checkpoint](docs/CODEX_CHECKPOINT.md) · [Migrationsaudit](docs/BRANCH_MIGRATION_AUDIT_20261025.md) · [Herkunft](docs/branch_migration_20261025.json) · [lokale Prüfnachweise](docs/branch_migration_validation_20261025.json). ZIPs, Patches, APKs und Git-Bundles: `/workspace/artifacts/branch-migration-20261025/`.

## Vorhandene Funktionen und Grenzen

| Bereich | Implementierter Umfang |
| --- | --- |
| Charaktere und Aufstieg | Zwölf SRD-Klassen, Attribute, bestätigte Startwerte/Ausrüstung, XP-Schwellen und bestätigte idempotente EP-Belohnungen, einzelne Aufstiege bis Gesamtstufe 20, bestehende Zweitklasse; zahlreiche Merkmals- und Talentwirkungen weiterhin offen |
| Kampf | W20/Vorteil/Nachteil, Angriff und Schaden, ausgewählte Zustände/Klassenaktionen, Bewegung/Aufstehen/Kriechen, Deckung, Einzelgegner mit bestätigten Mehrfachangriffen; keine vollständige Mehrakteur-Automatik |
| Magie | Zauberkatalog und Vorprüfungen, Plätze/Paktressourcen/Konzentration, ausgewählte echte Wirkungen und Schildreaktionen; Sending mit bestätigtem Dialog, Slotverbrauch und SQLite-Beleg, ohne Nachrichtenzustellung; Katalogeinträge sind keine vollständigen Zauberwirkungen |
| Kampagnen | Lokale Solo-Demo und Rabenwacht mit optionalen Fortsetzungen, Entscheidungen, NPC-Erinnerungen und Journal; keine universell fertige autonome Spielleitung |
| Speicherung | Kampagnen, Ereignisse und Revisionen atomar; JSON-Sicherung, transaktionale Spielerhandlungs-Outbox, Settings-Teilupdates und Datenreset; SQLite-Version 2, Kampagnen-JSON-Version 1 |
| Android und Fantasy-UI | Deutsche Oberfläche, Charakterbogen, vorhandene Fantasy-Assets/Porträts, Sprache/TTS und Abenteueraktionen; reale Geräteabnahme und produktive Signierung offen |
| Optionaler Erzähler | Getrennter Backenddienst, bestätigter Regelzustand bleibt lokal; keine automatische kostenpflichtige Wiederholung und keine externe Exactly-once-Garantie |

Regelanforderungen stehen in [Coverage-Audit](docs/SRD_5_2_1_COVERAGE_AUDIT.md) und den beiden JSON-Registern. Die derzeitigen **1.419 Prüfaufträge und neun Inventurlücken sind kein vollständiger SRD-Nenner**. Eine globale Fertigstellungsquote wird nicht behauptet.

## Lokal entwickeln und prüfen

Toolchain wie CI: Flutter 3.35.7 / Dart 3.9.2, Java 17, Node.js 22.14.0 und Android-SDK. Linux-SQLite-Tests benötigen `libsqlite3-dev`.

```bash
bash scripts/check.sh
python3 scripts/check_domain_boundaries.py
python3 scripts/srd_coverage.py --json
cd app
flutter build apk --debug
cd android
bash ./gradlew :app:testDebugUnitTest --no-daemon
```

Die Demo benötigt keinen externen KI-Anbieter. Für einen eigenen Erzähler siehe [Backend](backend/README.md) und [Verbindung](docs/BACKEND_CONNECTION.md). Dauerhafte Anbieter-Schlüssel gehören ausschließlich auf den Server.

## Nächster konkreter Entwicklungsschritt

Zuerst diesen Migrationsauftrag abschließen: finale PR-CI abnehmen, PR #171 normal nach Main mergen, Main-CI auf dem tatsächlichen Merge-Commit abwarten und ausschließlich unveränderte, gesicherte, in Main enthaltene Altbranches entfernen. Neu verschobene Köpfe erneut prüfen und erhalten.

Danach als eigenes Regelpaket die bisher fehlenden allgemeinen Gelegenheitsangriffe bearbeiten: belegter Reichweitenwechsel und ausdrückliche Bestätigung, verfügbare Reaktion, tatsächliche Nahkampfwaffe, Treffer-/Schadensauflösung und atomare SQLite-Speicherung. Ablehnung, bereits verbrauchte Reaktion, Disengage, Teleportation/erzwungene Bewegung, veralteter Zustand und Alt-JSON gezielt prüfen. Keine Positionen oder Waffenwerte aus KI-Erzählung erfinden. SRD-Quelle vor Umsetzung verifizieren.

Weitere offene Arbeiten: vollständige Quelleninventur, Zauberwirkungen, Klassen-/Monstermechaniken, strukturierte Item-Overrides und reale Android-Abnahme. Ein früherer lokaler Item-Entwurf bleibt separat erhalten.

## Dokumentation, Sicherung und Historie

- [Fortsetzungsprompt](docs/CODEX_CONTINUATION_PROMPT.md) · [aktueller Checkpoint](docs/CODEX_CHECKPOINT.md)
- [Architektur](ARCHITECTURE.md) · [Regel-/Story-Grenze](docs/ARCHITEKTUR_REGELENGINE_STORY_TRENNUNG.md) · [Tests](TESTING.md)
- [Historische Branch-Dokumente](docs/history/branch_migration_20261025/README.md) · [README vor Migration](docs/history/branch_migration_20261025/README_before_migration.md)
- [Entwicklungsstatus](DEVELOPMENT_STATUS.md) · [Changelog](CHANGELOG.md) · [Roadmap](ROADMAP.md)

Projekt-ZIP ohne äußeren Ordner in eine Arbeitskopie entpacken oder den Patch auf dem dokumentierten Basiscommit mit `git apply --check` und `git apply` importieren. Danach auf einen eigenen Branch pushen und einen PR öffnen. Für die vollständige Git-Historie das Bundle klonen; einzelne Altbranches aus den Archivtags wiederherstellen. Details im [Migrationsaudit](docs/BRANCH_MIGRATION_AUDIT_20261025.md).

Nur ausgewählte Inhalte des **SRD 5.2.1 von Wizards of the Coast unter CC BY 4.0** sowie eigene/lizenzierte Inhalte verwenden. [Namensnennung und Lizenzen](THIRD_PARTY_NOTICES.md) erhalten. Keine automatische Weiterarbeit außerhalb einer aktiven Sitzung.
