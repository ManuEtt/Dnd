# Würfelraunen – Der lebendige Spielleiter

Deutschsprachige Android-Alpha für regelgeprüfte Soloabenteuer und lokale Kampagnen. Das vollständige SRD 5.2.1 bleibt in Arbeit.

## Aktueller Stand und autonome Fortsetzung (26.10.2026)

**Version 0.8.41+91 – Klassenprüfung für Heilige Flamme.** Branch `fix/sacred-flame-caster-validation-20261026` basiert auf Main `575a885bd34ecae2bd173dc183abf88a367a69af` und integriert die geprüfte Klassenwerte-Berechnung aus [PR #184](https://github.com/ManuEtt/Dnd/pull/184) in den tatsächlichen Zauberablauf.

Heilige Flamme lehnt doppelte Klassenaliase, unbekannte Partnerklassen und widersprüchliche Klassenstufen jetzt vor Würfeln, Schaden und Aktionsverbrauch ab. Für gültige Mehrklassencharaktere bleiben Kleriker-Weisheit und der Übungsbonus der Gesamtstufe maßgeblich. Nach der vorhandenen ausdrücklichen SG-Bestätigung zeigt der Dialog die verwendeten Werte; ungültige Profile können nicht bestätigt werden. Titel und Inhalt bleiben gemeinsam scrollbar, auch bei großer Schrift und eingeblendeter Tastatur.

**Spielstände bleiben erhalten:** keine globale Importverschärfung, kein Umschreiben historischer Werte oder Ereignisse, SQLite 2 und Kampagnen-JSON 1 unverändert. Alte Profile lassen sich weiterhin laden und bearbeiten; nur neue Zauberhandlungen benötigen gültige Klassenwerte.

**Bisher geprüft:** 20 Domain-, vier echte SQLite-/Controller- und sieben Widgettests grün. Sieben neue Klassen-Gegenfälle wurden zuerst am alten Code als Fehler nachgewiesen. Gesamtsuite, Android-Builds und eigene finale CI werden erst nach tatsächlichem Abschluss als bestanden dokumentiert. [Checkpoint](docs/CODEX_CHECKPOINT.md) · [fachlicher Nachweis](docs/SACRED_FLAME_CLASS_VALIDATION_20261026.md).

Andere aktuelle Arbeitsstände stehen unter [docs/parallel](docs/parallel/). Frühere README-/Checkpoint-Fassungen von Main und PR #184 sind [bytegenau archiviert](docs/history/sacred_flame_before_20261026/manifest.json). Grüne Einzel-CIs sind kein Nachweis einer neuen Kombination.

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

Die vorhandene klassenrichtige Feuerpfeil-Berechnung an dieselbe ausdrückliche Bestätigung unbekannter Zauberangriffsmodifikatoren anbinden. Fehlende Bestätigung muss vor RNG und Zustandseffekt abbrechen; vorhandene Magier-/Zauberer-Auswahl, Gesamtstufen-Übung und Erschöpfung genau einmal erhalten. Vorschau, Ablehnung, Stale Revision und SQLite-Rollback prüfen. Keine neue Klassenwahl oder bereits vorhandene reine Regelhelper duplizieren.

Weiterhin offen: zahlreiche Zauber-/Klassen-/Monstermechaniken, amtliche Vollinventur, vollständiger Gelegenheitsangriff, Item-Overrides und reale Android-Abnahme. Kataloge oder Vorprüfungen ergeben keine globale SRD-Fertigstellungsquote.

## Dokumentation, Sicherung und Import

- [Fortsetzungsprompt](docs/CODEX_CONTINUATION_PROMPT.md) · [operativer Checkpoint](docs/CODEX_CHECKPOINT.md)
- [Architektur](ARCHITECTURE.md) · [Regel-/Story-Grenze](docs/ARCHITEKTUR_REGELENGINE_STORY_TRENNUNG.md) · [Tests](TESTING.md)
- [Changelog](CHANGELOG.md) · [Entwicklungsstatus](DEVELOPMENT_STATUS.md) · [Roadmap](ROADMAP.md)

Vollprojekt-ZIP, Git-Patch, Dateimanifest und SHA256 unter `/workspace/artifacts/0.8.41+91/`; aktuelle Dateinamen im dortigen Artefaktindex. Patchbasis `575a885bd34ecae2bd173dc183abf88a367a69af`. ZIP in eine Arbeitskopie entpacken oder Patch auf dieser Basis mit `git apply --check` und `git apply` übernehmen, eigenen Branch pushen und PR öffnen. Keine alten Stände ungeprüft über Main kopieren. APKs werden separat bereitgestellt.

Nur rechtmäßig nutzbare Inhalte des **SRD 5.2.1 von Wizards of the Coast unter CC BY 4.0** sowie eigene/lizenzierte Inhalte nutzen. [Namensnennung](THIRD_PARTY_NOTICES.md) erhalten. Keine automatische Weiterarbeit außerhalb einer aktiven Sitzung.
