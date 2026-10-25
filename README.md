# Würfelraunen – Der lebendige Spielleiter

Deutschsprachige Android-Alpha für Soloabenteuer und regelgeprüfte Kampagnen. Das vollständige SRD5.2.1 bleibt in Arbeit.

## Aktueller Stand und autonome Fortsetzung (25.10.2026)

**Version0.8.39+89 – vollständige Branch-Migration.** Der Kandidat `1cddc4a3d590d0959733b532a5ec349b4195dcf4` auf `integration/all-branches-20261025` vereinigt alle18 anfänglich vorhandenen GitHub-Branch-Köpfe. Basis-main `b60ffe7ff1aae502ea927cb77153b988be33e397`. Main-Veröffentlichung, gemeinsame CI und anschließende Löschung werden getrennt nachgewiesen; derzeit läuft die kombinierte Abnahme.

Enthalten sind allgemeiner Light-Nahkampfbonus mit bestätigtem Waffenkontext, Nebenhand-Sneak-Attack, Sending-W100-Validierung, Backend-Limiter-Schutz sowie lokale und serverseitige Story-/Geheimnissicherungen. SQLite2 und Kampagnen-JSON1 bleiben kompatibel. Alle Vorgängerfunktionen und Tests erhalten.

Originalbranches sind über **archive/branch-migration-20261025T075644Z** sowie ein verifiziertes Git-Bundle wiederherstellbar. Historische Dokumente und beide Seiten der fünf Statuskonflikte separat archiviert. Alte Branches werden erst nach erfolgreicher gemeinsamer Abnahme, Main-Integration und erneuter SHA-/Abstammungsprüfung gelöscht.

Aktuelle Ergebnisse und Wiederaufnahme: [CODEX_CHECKPOINT](docs/CODEX_CHECKPOINT.md). [Migrationsaudit](docs/BRANCH_MIGRATION_AUDIT_20261025.md) · [Maschinenlesbare Herkunft](docs/branch_migration_20261025.json). Artefakte unter `/workspace/artifacts/branch-migration-20261025/`. Geräteabnahme und produktive Signierung bleiben offen.

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

Die manuelle Verbündetenbestätigung für zulässige Nebenhandangriffe an denselben sicheren Dialog-/Controllerpfad anbinden. Abnahme: Eignung der tatsächlichen Angriffswaffe, ziel-/wurfgebundene Zustimmung, gemeinsame einmalige Zugnutzung, Krit/Miss, Ablehnung, alte Hauptwaffen-/JSON-Abläufe und SQLite-Neustart. Allgemeine Gelegenheitsangriffe bleiben ein eigenes Arbeitspaket.

Weitere offene Arbeiten: vollständige Quelleninventur, Zauberwirkungen, Klassen-/Monstermechaniken, strukturierte Item-Overrides, Android-Upgrade mit echten Spielständen und produktive Signierung. Der frühere lokale Item-Entwurf ist separat gesichert und wurde nicht über neuere Main-Dateien kopiert.

## Dokumentation und Historie

- [Aktueller Fortsetzungsprompt](docs/CODEX_CONTINUATION_PROMPT.md) · [Operativer Checkpoint](docs/CODEX_CHECKPOINT.md)
- [Architektur](ARCHITECTURE.md) · [Regel-/Story-Grenze](docs/ARCHITEKTUR_REGELENGINE_STORY_TRENNUNG.md) · [Tests](TESTING.md)
- [Artefakte importieren](docs/ARTIFACT_IMPORT_20261024.md) · [Validierungsbericht](docs/VALIDATION_0_8_38_20261024.md)
- [Entwicklungsstatus](DEVELOPMENT_STATUS.md) · [Changelog](CHANGELOG.md) · [Roadmap](ROADMAP.md)
- [README vor diesem Zyklus](docs/history/main_0.8.36_20261023/README.md) · [ältere Historie](docs/README_HISTORIE_BIS_20261020.md)

Nur ausgewählte Inhalte des **SRD 5.2.1 von Wizards of the Coast unter CC BY 4.0** sowie eigene/lizenzierte Inhalte verwenden. [Namensnennung und Lizenzen](THIRD_PARTY_NOTICES.md) erhalten. Neue Arbeit erfolgt während einer aktiven Sitzung in einem eigenen Branch und PR; keine automatische Fortsetzung außerhalb einer laufenden Sitzung.


## Erweiterung nach erneutem Live-Abgleich

Vier weitere Sourcebranches167–170 seit ursprünglicher13er-Aufnahme erkannt, vor Integration plus eigenem erstem Integrationskopf gesichert: nun18 Archivtags/Köpfe. Story169 und Archivfilter170 normal integriert;167/168 nach fokussiertem Rückwärts-Patchnachweis ohne Baumänderung in die Historie aufgenommen. Alle18 gesicherten Köpfe echte Vorfahren. Neun Historien-Merges insgesamt,38 Status-/Altdateien historisch archiviert. Ursprüngliches Bundle bleibt erhalten; aktuelles erweitertes Bundle: Wuerfelraunen_Branches_vor_Migration_20261025_erweitert.bundle, SHA256 e54ffc8cc6084985aac8a5cb9b18caca07a50fa7c564caeab94bee236a1954ba.

Gefundener Fehler im neuen Archivfilter: casefold des Dateinamens verglich gegen noch gemischt geschriebene Ausschlussnamen. .DS_Store und GeneratedPluginRegistrant.java konnten dadurch einbezogen werden. Regression vor Fix nachgewiesen, Lookup einmalig symmetrisch normalisiert;11 Archivtests danach grün. Neuer kompletter kombinierter Lauf unter /workspace/validation/20261025-migration-final-full-check.log. Erster13er-Kandidat separat1549 Flutter-/100 Python-/38 Backend-Tests erfolgreich, kein Test der erweiterten Kombination. Neue endgültige Zahlen erst nach Beobachtung übernehmen.
