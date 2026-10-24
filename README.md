# Würfelraunen – Der lebendige Spielleiter

Deutschsprachige Android-Alpha für Soloabenteuer, regelgeprüfte Kämpfe und lokale Kampagnen mit SQLite. Flutter/Dart-App und optionaler Fastify-/TypeScript-Erzähler. Das vollständige SRD 5.2.1 ist noch nicht implementiert.

## Aktueller Stand und autonome Fortsetzung (24.10.2026)

**Version 0.8.38+88**, Branch `fix/sneak-attack-offhand-weapon-20261024`, Basis-main `dcb42c5efff40a757994d4f5b5f8e98b2ff128e9` (PR #157 integriert). Zu Beginn keine offenen PRs; Main-CI [40092582286](https://github.com/ManuEtt/Dnd/actions/runs/40092582286) lief noch. Der letzte abgeschlossene grüne Main-Nachweis war [40084074765](https://github.com/ManuEtt/Dnd/actions/runs/40084074765) auf `3b5affd`; er prüft diesen neuen Branch nicht.

**Korrigiert: Hinterhältiger Angriff prüft die tatsächlich angreifende Waffe.** Bisher wurde bei einer Nebenhandprobe die Hauptwaffe auf Finesse/Fernkampf geprüft. Ein bestätigter Dolch-Nebenhandangriff kann jetzt seine eigene Eignung nutzen; eine Handaxt erhält keine Eignung durch einen Dolch in der Hauptwaffe. Angriff, Schaden, kritische Treffer, einmalige Zugnutzung und Journal bleiben im vorhandenen Kampffluss.

Das betrifft auch gespeicherte offene Angriffe mit bereits bestätigtem Vorteil. Die Änderung erzeugt keinen Vorteil und erweitert die bisherigen Nebenhandvoraussetzungen nicht. Die Verbündetenbestätigung bleibt vorerst auf Hauptwaffenangriffe begrenzt. SQLite-Schema 2 und Kampagnen-JSON 1 bleiben erhalten; keine Migration und keine erfundenen KI-Regelwerte.

### Tatsächlicher Prüfstand dieses Pakets

Gezielte bestehende Kampf-/Speicher-/Widgetregressionen: **27 bestehende/Helper- und acht neue Kampf-/SQLite-Tests erfolgreich**. Vollständiger Check, Android-Builds und neue Branch-CI sind noch in Arbeit. Keine älteren APKs als Build dieses Pakets ausgeben. Reales Android-Gerät und produktive Signierung bleiben offen.

Aktuelle Übergabe: [CODEX_CHECKPOINT](docs/CODEX_CHECKPOINT.md). [Regelquelle und Abnahmekriterien](docs/SRD_SNEAK_ATTACK_WEAPON_CONTEXT_20261024.md). Vorherige Sending-, XP- und Schurkenstände sind integriert; deren frühere Entwicklungsangaben stehen separat in der [README-Historie](docs/history/main_0.8.37_20261024/README.md).

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
