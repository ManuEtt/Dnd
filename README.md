# Würfelraunen – Der lebendige Spielleiter


### Integrationsstand 24.10.2026 – bestätigte EP-Belohnungen

Der XP-Kern aus [PR #149](https://github.com/ManuEtt/Dnd/pull/149) ist auf den neueren Schurken-/Kampfstand aus `main` portiert: manuelle Bestätigung, idempotente Anfragekennungen, persistentes XP-Ereignisjournal, atomare SQLite-Transaktion sowie Schutz bei veralteten Revisionen und beschädigten Rabenwacht-Belohnungsbelegen. Regressionstests für Duplikate, Race-Bedingungen und Neustarts wurden übernommen. **Gemeinsame neue CI ausstehend**, obwohl die getrennten Vorläuferstände grün waren. Die alternativen UI-PRs #150/#151 und die SRD-Sending-PR #144 sind noch nicht Bestandteil dieser Integration.

Deutschsprachige Android-Alpha für Soloabenteuer, Charakterverwaltung und regelgeprüfte D&D-Spielabläufe. Flutter/Dart-App mit SQLite, optionalem Fastify-/TypeScript-Erzähler und Fantasy-Oberfläche. **Das vollständige SRD 5.2.1 ist noch nicht implementiert.**

## Aktueller Stand und autonome Fortsetzung (24.10.2026)

**Version `0.8.37+87`**, Entwicklungsbranch `feature/sneak-attack-ally-integration-20261023`. Funktionaler Code-Commit: [`0a56aba`](https://github.com/ManuEtt/Dnd/commit/0a56aba7057dc12d80750759443f6d70ed510dc1); Basis `main`: `5958579e5321338bb7b4e46abb859fd3bfd1515f`. Der vollständige [Basis-CI-Lauf #40012217485](https://github.com/ManuEtt/Dnd/actions/runs/40012217485) ist erfolgreich. Er belegt die Basis, nicht automatisch diesen Entwicklungsbranch.

**Neu: Hinterhältiger Angriff mit bestätigtem Verbündeten im tatsächlichen Kampf.** Vor einem offenen Hauptwaffenangriff kann ein Schurke einen Verbündeten benennen und zwei Fakten unabhängig bestätigen: innerhalb von 5 Fuß **des Ziels** und nicht handlungsunfähig (`Incapacitated`). Die Bestätigung gilt nur für diese Kampagne, dieses Ziel und diesen Wurf. Sie lässt sich vor dem Würfeln entfernen. Erst ein regelgültiger Treffer würfelt den zusätzlichen Schaden; kritische Treffer verdoppeln die Schadenswürfel. Die bestehende Begrenzung pro eigenem Zug bleibt erhalten.

Bestätigung, Würfelergebnis und Schadensfolgen werden über die Regelengine und atomare SQLite-Transaktionen gespeichert. Neustart und JSON-Backup erhalten einen offenen bestätigten Angriff. Veraltete Dialoge werden abgewiesen, freie Eingabeentwürfe bleiben erhalten. Erzähltext und KI-Antworten bestätigen keine Verbündetenposition. Die Fakten sind manuelle Beobachtungen; eine allgemeine Positionsverwaltung wird nicht vorgetäuscht.

Zusätzlich korrigiert: gespeicherte Hauptwaffenproben prüfen den Angriffsbonus über dieselbe Regelberechnung wie die Ausführung, einschließlich Bogenschießen bei Mehrklassen. Die vollständige Dart-Formatprüfung ist wieder lokal und in GitHub CI aktiv; 70 bereits vorhandene Dateien wurden in einem getrennten Format-Commit normalisiert.

### Integration des inzwischen aktualisierten Main

`main` wurde während der CI um PR #145 auf `1c2eeabcd6479a69bfaf5cfd5bf001390fc4fcdd` erweitert. Der XP-Fix wird übernommen: dieselbe Belohnungs-ID quittiert nur denselben gespeicherten Betrag; widersprüchliche oder beschädigte Belege werden ohne Zustandsänderung abgewiesen. Die gemeinsame Abnahme läuft erneut. Die nachfolgenden grünen 1.448-Tests-/APK-/CI-Nachweise beziehen sich auf den geprüften Vorintegrationsstand `bfc991f`; sie werden nicht als Test der neuen Kombination ausgegeben.

### Tatsächlicher Prüfstand

| Prüfung | Ergebnis dieses Zyklus |
| --- | --- |
| Normalisierte Funktionsbasis | 1.431 Flutter-Tests erfolgreich |
| Neues Paket gezielt | 11 Domain-/SQLite-Tests und 6 Widgettests erfolgreich |
| Python-Projekt-/Pakettests | 100 erfolgreich |
| Backend | Typecheck, Build und 31 Tests erfolgreich |
| Dart/Flutter | 344 Dateien unverändert formatiert, Analyse ohne Befunde |
| Vollständige neue Flutter-Suite | **1.448 Tests erfolgreich** |
| Android-Debug / native Tests | APK gebaut, Metadaten/CRC/Signatur geprüft; **12 native Tests erfolgreich** |
| GitHub-PR / Code-CI | [PR #147](https://github.com/ManuEtt/Dnd/pull/147); [CI #40056875863](https://github.com/ManuEtt/Dnd/actions/runs/40056875863) vollständig erfolgreich auf `182f44b` |
| Echtes Android-Gerät | nicht getestet |

APK-Herkunft: aus dem vollständigen Quell-ZIP gebaut, 461 ausführungsrelevante Quelldateien per SHA256 abgeglichen; Version 0.8.37/Build 87, minSdk24/targetSdk36, ARM64/ARMv7/x64, Debug-Testsignatur. Kein echter Geräte-/Update-Test. Die kleinere ARM64-Alpha ist gebaut und geprüft (**19,7MB**, gleicher Build 87, lokale Debug-Testsignatur).

**GitHub-Downloads:** [Vollprojekt-ZIP](https://github.com/ManuEtt/Dnd/actions/runs/40056875863/artifacts/12546510086) · [Alpha-APKs (ARM64/ARM/x64)](https://github.com/ManuEtt/Dnd/actions/runs/40056875863/artifacts/12546286030) · [Git-Patch](https://github.com/ManuEtt/Dnd/pull/147.diff). Der erfolgreiche Lauf prüft den veröffentlichten Code-Stand `182f44b` (Merge-Test `de67cd3`); der damalige Dokumentationsnachtrag änderte keinen ausführbaren Code; für die anschließende Main-Integration ist eine neue gemeinsame Abnahme erforderlich. Aktuelle Checks stehen am PR.

Aktuelle Übergabe: [docs/CODEX_CHECKPOINT.md](docs/CODEX_CHECKPOINT.md). Regelquelle, Akzeptanzkriterien und Grenzen: [Hinterhältiger Angriff](docs/SRD_SNEAK_ATTACK_ALLY_INTEGRATION_20261023.md).

## Vorhandene Funktionen und Grenzen

| Bereich | Implementierter Umfang |
| --- | --- |
| Charaktere und Aufstieg | Zwölf SRD-Klassen, Attribute, bestätigte Startwerte/Ausrüstung, XP-Schwellen, einzelne Aufstiege bis Gesamtstufe 20, bestehende Zweitklasse; zahlreiche Merkmals- und Talentwirkungen weiterhin offen |
| Kampf | W20/Vorteil/Nachteil, Angriff und Schaden, ausgewählte Zustände/Klassenaktionen, Bewegung/Aufstehen/Kriechen, Deckung, Einzelgegner mit bestätigten Mehrfachangriffen; keine vollständige Mehrakteur-Automatik |
| Magie | Zauberkatalog und Vorprüfungen, Plätze/Paktressourcen/Konzentration, ausgewählte echte Wirkungen und Schildreaktionen; Katalogeinträge sind keine vollständigen Zauberwirkungen |
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

Den tatsächlich angreifenden Waffenplatz beim Hinterhältigen Angriff durchgängig prüfen und den Bestätigungspfad für zulässige Nebenhandangriffe ergänzen. Abnahme: Finesse/Fernkampf der wirklichen Angriffswaffe, einmal pro Zug, alte Hauptwaffen-/JSON-Abläufe, kritische Treffer, Ablehnung und SQLite-Neustart. Allgemeine Gelegenheitsangriffe und automatisierte Verbündetenbewegung bleiben getrennte Arbeitspakete.

Weitere offene Arbeiten: vollständige Quelleninventur, Zauberwirkungen, Klassen-/Monstermechaniken, strukturierte Item-Overrides, Android-Upgrade mit echten Spielständen und produktive Signierung. Der frühere lokale Item-Entwurf ist separat gesichert und wurde nicht über neuere Main-Dateien kopiert.

## Dokumentation und Historie

- [Aktueller Fortsetzungsprompt](docs/CODEX_CONTINUATION_PROMPT.md) · [Operativer Checkpoint](docs/CODEX_CHECKPOINT.md)
- [Architektur](ARCHITECTURE.md) · [Regel-/Story-Grenze](docs/ARCHITEKTUR_REGELENGINE_STORY_TRENNUNG.md) · [Tests](TESTING.md)
- [Artefakte importieren](docs/ARTIFACT_IMPORT_20261024.md) · [Validierungsbericht](docs/VALIDATION_0_8_37_20261024.md)
- [Entwicklungsstatus](DEVELOPMENT_STATUS.md) · [Changelog](CHANGELOG.md) · [Roadmap](ROADMAP.md)
- [README vor diesem Zyklus](docs/history/main_0.8.36_20261023/README.md) · [ältere Historie](docs/README_HISTORIE_BIS_20261020.md)

Nur ausgewählte Inhalte des **SRD 5.2.1 von Wizards of the Coast unter CC BY 4.0** sowie eigene/lizenzierte Inhalte verwenden. [Namensnennung und Lizenzen](THIRD_PARTY_NOTICES.md) erhalten. Neue Arbeit erfolgt während einer aktiven Sitzung in einem eigenen Branch und PR; keine automatische Fortsetzung außerhalb einer laufenden Sitzung.
