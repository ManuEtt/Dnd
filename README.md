# Würfelraunen – Der lebendige Spielleiter

Deutschsprachige Android-Alpha für Soloabenteuer, regelgeprüfte Kämpfe und lokale SQLite-Kampagnen. Das vollständige SRD 5.2.1 ist weiterhin in Arbeit.

## Aktueller Stand und autonome Fortsetzung (25.10.2026)

**Version 0.8.39+89**, Branch `feature/light-weapon-bonus-attack-20261024`. Basis **6f2ebbc893fb5ee053d069410a103a102662aa4d** aus [PR160](https://github.com/ManuEtt/Dnd/pull/160); dessen finale [CI40100211878](https://github.com/ManuEtt/Dnd/actions/runs/40100211878) ist erfolgreich. Der neue Branch wird als eigenes Folgepaket geprüft. Main bei Bestandsaufnahme b60ffe7, offene Integrations-PR164 berücksichtigt; keine direkten Mainänderungen.

**Neu: allgemeiner Light-Nahkampfbonus statt Kämpfer-Stilpflicht.** Nach einer abgeschlossenen Angriffsaktion mit leichter Waffe kann jede Klasse eine andere bestätigte leichte Nahkampfwaffe für ihre freie Bonusaktion wählen. Der deutsche Dialog in der Abenteueransicht erfasst die Waffe, Stärke/Finesse-Geschicklichkeit, bestätigte Übung und gehaltene Waffen. Vorschau und abschließende Zustimmung gehen der Buchung voraus; Änderungen widerrufen die Zustimmung. Freie Eingaben bleiben erhalten.

Ohne Kampfstil wird kein positiver Attributsmodifikator zum Zusatzangriffsschaden addiert; negative Modifikatoren bleiben. Der bisherige bestätigte Kämpfer-Kampfstil fügt den Modifikator einmal hinzu. Kampfrausch prüft das tatsächliche Angriffsattribut und die konkrete Waffe. Schadenssummen werden erst nach allen zugehörigen Klassenboni auf mindestens null begrenzt.

SQLite2 und Kampagnen-JSON1 bleiben kompatibel: neue optionale, gemeinsam validierte Nebenhandfelder, alte Fighter-Stil-Proben weiterhin lesbar. Revisions- und Transaktionsschutz gelten für Vorbereitung, Neustart und Auflösung. Ohne bestätigte Übung wird kein Bonus erfunden. Nick, Light-Fernkampf und allgemeines Waffenwechseln sind nicht Teil dieser Umsetzung.

### Tatsächlicher Prüfstand

55 Regel-/Kampftests,12 Zweiwaffentests,7 neue Widgettests und34 bestehende Sneak-/Speicher-/Widgetregressionen erfolgreich. Neuer Gesamtcheck läuft nach der Kampfrausch-/Schadenssummenkorrektur erneut; neue APK/native Tests und eigene finale CI noch offen. Frühere Zwischen-ZIPs/Patches bereits unter `/workspace/artifacts/` gesichert. Reales Gerät und produktive Signierung bleiben offen.

Aktuelle Übergabe: [CODEX_CHECKPOINT](docs/CODEX_CHECKPOINT.md). [Regelquelle und Scope](docs/SRD_LIGHT_BONUS_ATTACK_20261025.md). Vollständiger vorheriger Stand: [README-Historie](docs/history/pr160_0.8.38_20261024/README.md).

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

Nach Abnahme dieses Pakets die noch offenen Light-Fernkampf-/Munitions- und Nick-Regeln getrennt planen. Zunächst aktuelle Main-/PR-Integrationslage neu prüfen; keine freien Bonusaktionen oder gehaltene Waffen aus Erzähltext ableiten. Strukturierte Item-Overrides und vollständige SRD-Quelleninventur bleiben offen.

## Dokumentation und Historie

- [Aktueller Fortsetzungsprompt](docs/CODEX_CONTINUATION_PROMPT.md) · [Operativer Checkpoint](docs/CODEX_CHECKPOINT.md)
- [Architektur](ARCHITECTURE.md) · [Regel-/Story-Grenze](docs/ARCHITEKTUR_REGELENGINE_STORY_TRENNUNG.md) · [Tests](TESTING.md)
- [Artefakte importieren](docs/ARTIFACT_IMPORT_20261024.md) · [Validierungsbericht](docs/VALIDATION_0_8_38_20261024.md)
- [Entwicklungsstatus](DEVELOPMENT_STATUS.md) · [Changelog](CHANGELOG.md) · [Roadmap](ROADMAP.md)
- [README vor diesem Zyklus](docs/history/main_0.8.36_20261023/README.md) · [ältere Historie](docs/README_HISTORIE_BIS_20261020.md)

Nur ausgewählte Inhalte des **SRD 5.2.1 von Wizards of the Coast unter CC BY 4.0** sowie eigene/lizenzierte Inhalte verwenden. [Namensnennung und Lizenzen](THIRD_PARTY_NOTICES.md) erhalten. Neue Arbeit erfolgt während einer aktiven Sitzung in einem eigenen Branch und PR; keine automatische Fortsetzung außerhalb einer laufenden Sitzung.
