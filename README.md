# Würfelraunen – Der lebendige Spielleiter

Deutschsprachige Flutter-Android-Alpha für lokale Soloabenteuer, bestätigte D&D-SRD-5.2.1-Regeln und optionalen KI-Erzähler. Das vollständige Regelwerk bleibt in Arbeit.

## Aktueller Stand und autonome Fortsetzung (26.10.2026)

**Version 0.8.42+92 – gemeinsame Branch-Migration.** Basis-Main `5e3116f9e3f8de0af6e8125a97b3962cb8910cdf`, Integrationsbranch `integration/all-branches-20261026b`. Acht Branch-Namen (Main plus sieben Entwicklungsbranches) samt später hinzugekommenem Reichweitenbranch und fortgeschriebenen Köpfen wurden vorab als Remote-Archivtags und geprüftes Git-Bundle gesichert. Alle zehn gesicherten Ursprungs-/Fortschreibungsköpfe sind im Integrationsbranch als Vorfahren erhalten; ursprüngliche README-/Checkpoint-Fassungen mit SHA256 archiviert.

Zusammengeführt:

- Numerische Zauberreichweiten akzeptieren nur bestätigte Fuß-/Meilen-Einheiten und verweigern übergroße Werte; Syntaxfehler der neu eingetroffenen Source-Fassung behoben und exakte 64-Bit-Grenzfälle ergänzt.

- Eldritch Blast verwirft unbekannte Hauptklassen auch bei vorhandener Hexenmeister-Zweitklasse vor RNG und Zustandsänderung; gültige Klassenaliase bleiben erlaubt.
- Eine ausdrücklich gewählte NPC-ID kann capability- und revisionsgeprüft über den optionalen Client-/Backendvertrag übertragen werden. **Android-Oberfläche und GameController reichen die gewählte ID noch nicht durch**; keine vollständige UI-Integration behauptet. Der Erzähler erhält keine freie Regelzustandsautorität.
- Kampfmöglichkeiten bleiben bei 200% Schrift getrennt lesbar und semantisch angekündigt; die Würfelanzeige blendet bei großer Schrift ein dekoratives Icon aus, damit Inhalt Platz behält.
- Quell-ZIP und Checkpoint-Manifeste lesen Dateien und Verzeichnisse auf POSIX über geprüfte Deskriptoren mit `O_NOFOLLOW`. Windows-Fallback bleibt best-effort.

**Gefundener Fehler behoben:** Die neuen Würfelanzeige-Tests scheiterten in [CI #40369637672](https://github.com/ManuEtt/Dnd/actions/runs/40369637672) an Dart-Formatierung. Mit Dart3.9.2 formatiert; keine Assertion entfernt. Im später hinzugekommenen Reichweitenbranch wurde außerdem ein nicht kompilierender kopierter Methodenblock im RegExp gefunden; Reparatur und 17 gezielte Flutter-Tests sind erfolgreich; vollständige gemeinsame Abnahme folgt. 155 Python-Tests bisher erfolgreich; neue gemeinsame Flutter-/Backend-/Android-/CI-Abnahme steht bis zu ihrem tatsächlichen Abschluss separat aus.

**Spielstände bleiben erhalten:** SQLite2 und Kampagnen-JSON1 unverändert, keine Historien-, Helden-, Event- oder Inventarmigration. Main und zu löschende Remote-Branches werden erst nach erfolgreicher kombinierter Abnahme verändert. Branchlöschung nur nach geprüftem Main-Vorfahrenvergleich, Archivtag und unveränderter Remote-SHA.

[Operativer Checkpoint](docs/CODEX_CHECKPOINT.md) · [Migrationsinventar](docs/BRANCH_MIGRATION_20261026_INVENTORY.json) · [Originaldokumente](docs/history/branch_migration_20261026T173427Z/manifest.json).

## Vorhandene Funktionen und Grenzen

| Bereich | Implementierter Umfang |
| --- | --- |
| Charaktere | Zwölf SRD-Klassen, bestätigte Attribute/Ausrüstung, XP-Schwellen, bestätigte idempotente EP-Belohnungen und einzelne Aufstiege; zahlreiche Klassen-/Talentwirkungen offen |
| Kampf und Magie | Regelgeprüfte Angriffe/Schäden, ausgewählte Klassen-/Zustands-/Zauberwirkungen, Ressourcen, Deckung und Bewegung; vollständige Mehrakteur-, Monster- und Zauberautomatik offen |
| Kampagnen | Lokale Solo-Demo, Rabenwacht, Journal, NPC-Erinnerung und Story-Fortsetzungen; keine universell fertige autonome Spielleitung |
| Daten und Backend | Transaktionale lokale Speicherung/Revisionen, JSON-Sicherungen, Spielerhandlungs-Outbox; optionaler HTTPS-Erzähler mit Mocks und Protokollvalidierung, keine automatische kostenpflichtige Wiederholung |
| Android und Fantasy-UI | Deutsche Oberfläche, Fantasy-Komponenten, Charakterbogen, Sprache/TTS und Abenteueraktionen; reale Geräte-/Upgrade-/TalkBack-Abnahme und produktive Signierung offen |

Katalogeinträge und reine Regelhelper zählen nicht als vollständige Spielmechanik. Die 1.419 Prüfaufträge und neun offenen Quellen-Inventurlücken sind kein vollständiger SRD-Nenner; keine globale Fertigstellungsquote.

## Lokal entwickeln und prüfen

Toolchain wie CI: Flutter3.35.7/Dart3.9.2, Java17, Node22.14.0, Android-SDK. Linux-SQLite-Tests brauchen `libsqlite3-dev`.

```bash
python3 scripts/generate_fantasy_buttons.py
bash scripts/check.sh
python3 scripts/srd_coverage.py --json
cd app
flutter build apk --debug
cd android
bash ./gradlew :app:testDebugUnitTest --no-daemon
```

Die 30 originalen Button-Grafiken werden deterministisch generiert; die CI führt diesen Schritt vor Tests/Build aus. Alpha-APKs bleiben mit Debug-Testsignatur versehen. Geräteinstallation und historisches Geräte-Upgrade sind eigene Abnahmen.

## Sicherung und Import

Migrationsbundle, Inventar, ZIPs/Patches, Manifeste und SHA256: `/workspace/artifacts/branch-migration-20261026T173427Z/`. Downloadlinks und tatsächliche Abschlussbelege folgen im Integrations-PR. ZIPs enthalten Quellcode ohne SDKs, private Daten oder APKs. Patch auf der im Manifest angegebenen Basis zuerst mit `git apply --check` prüfen. Main nicht mit einer älteren ZIP überschreiben.

[Architektur](ARCHITECTURE.md) · [Tests](TESTING.md) · [Changelog](CHANGELOG.md) · [Entwicklungsstatus](DEVELOPMENT_STATUS.md). Historische Versionsstände stehen unter `docs/history/` sowie in den bisherigen Journalen.

## Nächster konkreter Entwicklungsschritt

Nach vollständiger Migration die vorhandene explizite NPC-Auswahl aus der Android-Oberfläche durch den GameController an den neuen optionalen Wire-Vertrag weiterreichen. Bei gleichnamigen Figuren ID ausdrücklich wählen; fehlende Capability, Ablehnung, Stale Revision und Neustart ohne Netzwerk-/Kosten- oder Regelzustandsänderung testen. Bestehende Protokollhelper und Auswahlmodelle wiederverwenden.

SRD5.2.1 von Wizards of the Coast LLC unter CC BY4.0 sowie eigene/lizenzierte Inhalte; [Namensnennung](THIRD_PARTY_NOTICES.md) erhalten. Keine automatische Weiterarbeit außerhalb einer aktiven Sitzung.
