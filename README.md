# Würfelraunen – Der lebendige Spielleiter

## Chat D – eindeutige Gradle-Wrapper-Downloadparameter (D-005, 25.10.2026)

Der Projektprüfer lehnt mehrdeutige oder mehrfach vorkommende `distributionUrl`- und `distributionSha256Sum`-Einträge in `gradle-wrapper.properties` ab. Sechs neue Python-Regressionstests prüfen schädliche Dopplungen und gültige Kommentar-/Schreibweisen. Das Paket ändert weder Android-App-Code noch SRD-Regeln oder gespeicherte Spielstände. Die abschließende GitHub-CI des finalen Branch-Commits ist separat nachzuweisen. [Chat-D-Checkpoint](docs/parallel/CHAT_D_CHECKPOINT.md).

## Qualitätspaket Chat D D-004 – Gradle-Wrapper-JAR-Validierung

Nach der vollständigen Integration von [PR #183](https://github.com/ManuEtt/Dnd/pull/183) ergänzt [PR #186](https://github.com/ManuEtt/Dnd/pull/186) den Projektprüfer um die frühe Zurückweisung doppelter ZIP-Dateinamen, Pfad-Traversal/absoluter Namen und symbolischer Einträge im Gradle-Wrapper-JAR. Vier neue Python-Regressionen erfassen Positiv- und Negativfälle. Die vollständige GitHub-CI des mit `main` synchronisierten D-004-Commits bleibt bis zum Abschluss gesondert zu prüfen. Keine Spielstands-, SQLite-/JSON-, UI- oder SRD-Regeländerung. [Chat-D-Checkpoint](docs/parallel/CHAT_D_CHECKPOINT.md).

## Chat D – APK-ZIP-Härtung (25.10.2026, PR #183)

Nach den erfolgreich geprüften Integrationen von [PR #177](https://github.com/ManuEtt/Dnd/pull/177) und [PR #182](https://github.com/ManuEtt/Dnd/pull/182) wird die Alpha-Release-Prüfung mit [PR #183](https://github.com/ManuEtt/Dnd/pull/183) gegen mehrdeutige doppelte ZIP-Member, unsichere Eintragspfade und symbolische Links abgesichert. Vier neue Regressionstests prüfen auch erlaubte ZIP-Verzeichnisse. **Finale CI auf dem neu mit Main synchronisierten Commit ausstehend**. Keine SQLite-/JSON-Migration, keine Änderung an App-Code, Regelmechanik oder Build-Version. [Chat-D-Checkpoint](docs/parallel/CHAT_D_CHECKPOINT.md).

## Qualitätssicherung – Chat D: rekursiver Story-/Regelimportprüfer (25.10.2026)

Nach dem vollständig getesteten und regulär integrierten [Chat-D-PR #177](https://github.com/ManuEtt/Dnd/pull/177) ergänzt das neue [Paket D-002](docs/parallel/CHAT_D_CHECKPOINT.md) den Architekturprüfer: Dart-Unterordner von `app/lib/story/` und `app/lib/domain/` werden rekursiv geprüft; relative `../`- und `./`-Importvarianten werden vor dem Berechtigungscheck normalisiert. Sechs neue positive/negative Testfälle und sechs bisherige Grenztests wurden **in einer isolierten Python-Projektstruktur** gemeinsam ausgeführt (**12 bestanden**); die vollständige GitHub-CI und neue APKs sind erst nach Abschluss der Läufe auf dem finalen D-002-Commit belegt. Keine Änderung an SRD-Spielregeln, SQLite, JSON oder der App-Version.

## Qualitätssicherung – Chat D (PR #177, 25.10.2026)

[PR #177](https://github.com/ManuEtt/Dnd/pull/177) ergänzt zwei bislang nicht automatisch ausgeführte CI-Gates: `python3 scripts/check_domain_boundaries.py` und `python3 scripts/srd_coverage.py --json`. Beide laufen jetzt in der Android-CI und in `scripts/check.sh` vor den regulären Python-Tests. Der neue Konfigurationstest enthält positive und negative Fälle. Auf dem bisherigen PR-Commit `1fdd3c0` waren Architektur-/SRD-Prüfung, Python-Tests, Backend-Tests sowie Flutter-Analyse und Flutter-Tests erfolgreich; Android-Build und vollständige Release-Abnahme wurden noch nicht als erfolgreich bestätigt. Keine Änderung an SQLite, JSON, Spielregeln oder der App-Version. [Chat-D-Checkpoint](docs/parallel/CHAT_D_CHECKPOINT.md).

Dieser PR wurde gegen den inzwischen gemergten Main-Stand von [PR #176](https://github.com/ManuEtt/Dnd/pull/176) erneut abgeglichen; die dort eingeführte gespeicherte Gelegenheitsreaktion bleibt erhalten. PRs #178–#180 anderer Chats bleiben getrennt zur Prüfung offen.

Deutschsprachige Android-Alpha für Soloabenteuer und regelgeprüfte Kampagnen. Das vollständige SRD 5.2.1 bleibt in Arbeit.

## Aktueller Stand und autonome Fortsetzung (25.10.2026)

**Version 0.8.40+90 – gespeicherte Bewegungsunterbrechung für Gelegenheitsreaktionen.** Auf Basis des geprüften Main-Commits `407c2e1ef8ee310b30d1543a263fb66b3331a26e` entsteht der separate Branch `feature/opportunity-reaction-offer-20261025`. Letzte vollständig erfolgreiche Main-CI: [#40203583841](https://github.com/ManuEtt/Dnd/actions/runs/40203583841); sie belegt die Basis, keine neuen Änderungen.

In der Abenteueransicht kann ein ausdrücklich bestätigtes, sichtbares Verlassen der Nahkampfreichweite den laufenden Gegnerzug unterbrechen. Das eindeutige Angebot mit Kampf, Runde, Waffe, Entfernungen und Ursprungsrevision wird zusammen mit dem Ereignis atomar gespeichert. Es erscheint nach Neustart wieder. Weitere Regeln und Gegnerangriffe warten, bis der Spieler ausdrücklich verzichtet; dabei bleiben Reaktion, Trefferpunkte, Plätze, Aktionsbudget und übrige Gegnerangriffe unverändert. Dialogabbruch verändert nichts. Alte Dialoge und konkurrierende Schreibvorgänge dürfen kein neueres Angebot ersetzen oder ablehnen.

**Bewusste Grenze:** Noch kein Angriffswurf, Schaden oder Reaktionsverbrauch und keine automatische Positionsverfolgung. Das Angebot kann offen bleiben oder ausdrücklich abgelehnt werden. `RULE-COMBAT-OPPORTUNITY-ATTACKS` bleibt **partial**. SQLite 2 und Kampagnen-JSON 1 bleiben kompatibel; alte Exporte enthalten das neue optionale Feld nicht.

Gezielte Domain-/SQLite- und Android-Widgettests sind ausgeführt; vollständige neue Suite, Builds und PR-CI werden erst nach Abschluss als erfolgreich dokumentiert. Aktueller Nachweis: [CODEX_CHECKPOINT](docs/CODEX_CHECKPOINT.md). [Fachliche Abgrenzung](docs/SRD_OPPORTUNITY_MOVEMENT_20261025.md).

Der Live-Abgleich vor diesem Zyklus ergab nur `main` und keine offenen PRs: Die vorherige Branch-Migration und Bereinigung sind bereits übernommen. Originalstände bleiben über Archivtags und lokale Bundles erhalten. Frühere abweichende Statusmeldungen stehen [separat in der Historie](docs/history/opportunity_before_20261025/README.md).

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

Einen eigenen, revisionsgebundenen Reaktionsangriff auf dem gespeicherten Angebot ergänzen. Den normalen Angriffsaktionspfad nicht unverändert verwenden: Gegnerzug und restliche Gegnerangriffe erhalten, keine Extra-Attack-/Light-Freischaltung, Reaktion genau einmal verbrauchen, tatsächliche Waffe oder waffenlosen Schaden korrekt auflösen und Ergebnis/Event atomar speichern. Krit/Miss, Schildkonkurrenz, Sneak Attack pro tatsächlichem Zug, Abbruch, Stale Revision und SQLite-Neustart prüfen. SRD-Quelle vor Erweiterung erneut verifizieren.

Weitere offene Bereiche: vollständige amtliche Quelleninventur, zahlreiche Zauber-, Klassen- und Monsterwirkungen, strukturierte Item-Overrides, reale Android-Abnahme und produktive Signierung. Frühere lokale Entwürfe bleiben erhalten.

## Dokumentation, Sicherung und Historie

- [Fortsetzungsprompt](docs/CODEX_CONTINUATION_PROMPT.md) · [operativer Checkpoint](docs/CODEX_CHECKPOINT.md)
- [Architektur](ARCHITECTURE.md) · [Regel-/Story-Grenze](docs/ARCHITEKTUR_REGELENGINE_STORY_TRENNUNG.md) · [Tests](TESTING.md)
- [Changelog](CHANGELOG.md) · [Entwicklungsstatus](DEVELOPMENT_STATUS.md) · [Roadmap](ROADMAP.md)
- [README vor diesem Paket](docs/history/opportunity_before_20261025/README.md) · [Branch-Migrationsaudit](docs/BRANCH_MIGRATION_AUDIT_20261025.md)

Vollprojekt-ZIP, Patch und Prüfsummen unter `/workspace/artifacts/0.8.40+90/`; aktuelle Dateinamen im dortigen Artefaktindex nach Abschluss. Patchbasis dieses Pakets: `407c2e1ef8ee310b30d1543a263fb66b3331a26e`. ZIP in eine Arbeitskopie entpacken oder Patch mit `git apply --check`/`git apply` auf dieser Basis übernehmen, eigenen Branch pushen und PR öffnen. Keine alten Dateistände ungeprüft über Main kopieren.

Nur rechtmäßig verwendbare Inhalte des **SRD 5.2.1 von Wizards of the Coast unter CC BY 4.0** sowie eigene/lizenzierte Inhalte nutzen. [Namensnennung](THIRD_PARTY_NOTICES.md) erhalten. Keine automatische Weiterarbeit außerhalb einer aktiven Sitzung.
