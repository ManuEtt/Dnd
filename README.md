# Würfelraunen – Der lebendige Spielleiter

Deutschsprachige Fantasy-Solo-App für Android: Flutter/Dart, lokale SQLite-Spielstände,
regelgeprüfte Aktionen und ein optionaler Fastify-/TypeScript-Erzähler.

## Aktueller Stand und autonome Fortsetzung

**Alpha 0.8.49+99 – Gesamtintegration vom 30./31.10.2026, Issue #425.**
[PR #440](https://github.com/ManuEtt/Dnd/pull/440) ist regulär in Main
`72ba9d2e06e7121f955832b4ad22223f64f7c343` integriert.
[PR #444](https://github.com/ManuEtt/Dnd/pull/444) bewahrt anschließend die
restlichen Ursprungshistorien mit vier zusätzlichen Manifest-/Testdateien:
Main `47ab002872b7d46daeae03bb558258cf2ea73e4a`.
Originale App-/Backend-Dateien bleiben dabei bytegleich.
Der Abschlussnachtrag entsteht auf `docs/migration-issue425-acceptance-20261031`.

**Implementiert und zusammengeführt:**

- Alle 45 ursprünglichen Entwicklungsheads sowie der während der Analyse neu
  veröffentlichte Integrationsbranch #437 sind mit regulären Merge-Commits erhalten.
  [SHA-/Archivregister](docs/parallel/MIGRATION_BRANCHES_20261030.json).
- Zauber-Prüfpfade validieren Wirkzeit/Ritual, V/S/M-Metadaten, Reichweiten,
  eindeutige Materialstapel und vorhandene Ressourcen. Todesrettungs-Klassen
  und Kurzrast-Ressourcen werden vor den betroffenen Würfen geprüft.
- NPC-Erinnerung und Wire-Vertrag berücksichtigen sichere Identitäten,
  unsichtbare Zeichen und tief unveränderliche bestätigte Kontexte.
  Kollidierende Story-Eintrag-IDs werden vor der Speicherung abgewiesen.
- Kleine Android-Layouts unterstützen lange Texte, 200 % Schrift und Tastatur
  besser: Charakterbogen, Abenteuerstatus, Helden-/Schnellaktionen,
  NPC-Auswahl sowie EP- und Ausrüstungsdialoge.
- SQLite-Outbox, Backend-`PUBLIC_ORIGIN`, Metadatenprüfung, Fantasy-Grafikimport,
  Ausgabesperren für Checkpoints/ZIPs und APK-Dateitypprüfung sind abgesichert.
- Drei nachgewiesene Integrationsfehler korrigiert: konsistente Konzentrations-
  Gesamtmodifikatoren, ungültige Zweitklasse auf Stufe 0 und abweichender
  NPC-Namensvergleich bei eingefügten Richtungszeichen.

**Getestet und bereinigt:** vollständige [Main-CI 41183481979](https://github.com/ManuEtt/Dnd/actions/runs/41183481979)
auf `47ab0028` **erfolgreich**: **2.710 Flutter-, 262 Python- und 76 Backend-Tests**,
20 zusätzliche UI-Fälle, 576 unveränderte Dart-Dateien, saubere Analyse,
Backend-Typecheck/Build/Protokollsmoke, Debug-APK/native Gradle-Tests und
optimierte ARM64-/ARMv7-/x64-APKs. [Cleanup 41184619156](https://github.com/ManuEtt/Dnd/actions/runs/41184619156)
ist ebenfalls erfolgreich: alle **53 erfassten Altbranches** sind vollständig
in Main enthalten, remote entfernt und mit exakt passenden Archivtags erhalten.
[Einzelnachweis mit vollständigen SHAs](docs/parallel/MIGRATION_ACCEPTANCE_20261031.json).
Die danach neu begonnenen PRs [#446](https://github.com/ManuEtt/Dnd/pull/446),
[#447](https://github.com/ManuEtt/Dnd/pull/447) und [#448](https://github.com/ManuEtt/Dnd/pull/448)
bleiben als aktive Entwicklung geschützt. Abschluss-PR #445 ändert nur Dokumentation.

Der lokale volle Flutter-Testlog endet bei 1.154 erfolgreichen Fällen ohne
Abschluss; er gilt ausdrücklich **nicht** als Vollpass. Die obigen Endergebnisse
stammen aus den tatsächlich abgeschlossenen GitHub-Läufen.

**Grenzen:** Sechs übernommene SRD-Bausteine sind eigenständige, getestete
Domänen-APIs: Mehrziel-Magisches-Geschoss, dessen TP-Vorschau, Zauber-Aktionsökonomie,
belegter Materialwert sowie Konzentrationsschaden/-modifikator. Sie besitzen
weiterhin keine vollständige UI-/Controller-/Speicheranbindung. Ihre Übernahme
ist keine abgeschlossene Spielmechanik. Charakterassistent und Gesamtregelwerk
bleiben unvollständig; 1.419 Prüfaufträge und neun offene Inventurlücken sind
kein globaler Fertigstellungsprozentsatz. SQLite 3 / äußeres JSON 1 bleiben
unverändert; bestehende Spielstände werden nicht automatisch neu berechnet.

**Nächster Entwicklungsschritt:** bestätigte SRD-Klassenaliasnamen
bei normalen Mehrklassen-Zauberplätzen kanonisieren. `Wizard` und `Magier` müssen
dieselben belegten Plätze ergeben; Paktmagie bleibt getrennt, unbekannte Klassen
werden nicht geraten. Zuerst aktuelle PRs/Quellen prüfen; Domain-, SQLite-/Retry-
und bestehende Zauberregressionen verlangen. Keine automatische Fortsetzung
außerhalb einer aktiven Sitzung.

## Starten und prüfen

Toolchain wie CI: Flutter **3.35.7**, Dart **3.9.2**, Java **17**, Node **22.14.0**,
Android SDK/API 36. Unter Linux benötigen SQLite-Tests `libsqlite3-dev`.

```bash
python3 scripts/generate_fantasy_buttons.py
bash scripts/check.sh
cd app
flutter build apk --debug
cd android
./gradlew :app:testDebugUnitTest --no-daemon
```

`check.sh` prüft Projektstruktur, Modulgrenzen, SRD-Register, Python-Pakettests,
Backend-Installation/Typecheck/Tests/Build sowie Flutter-Formatierung/Analyse/
Tests einschließlich lokalem Node-/Dart-Protokolltest. Tests nutzen Mocks und
deterministische Würfel; kostenpflichtige KI ist nicht erforderlich.

## Spielen und sichern

Helden anlegen oder bestehende Charaktere importieren, Kampagne auswählen und
im Abenteuer ausdrücklich bestätigte Aktionen ausführen. Die lokale Engine
entscheidet über Würfe, TP, Ressourcen und Gegenstände. Erzähltext und
KI-Vorschläge erhalten keine Regelautorität. Unbekannte Werte bleiben unbekannt.

Spielstände lassen sich als JSON über Androids Dokumentauswahl oder Text sichern.
Importe werden vor Bestätigung validiert und atomar gespeichert. Vor einer
Deinstallation eigene Spielstände exportieren; Sicherungen sind nicht zusätzlich
verschlüsselt. [Backup-Anleitung](docs/SAVE_BACKUPS.md).

Der lokale Demo-Modus benötigt keinen Server oder API-Schlüssel. Ein optionaler
HTTPS-Erzähler verwendet nur serverseitige Anbieter-Schlüssel und ausdrücklich
freigegebene Kosten; Sitzungstoken bleiben im Arbeitsspeicher. Android-Sprache
hängt von den installierten Gerätediensten ab; vollständiges Offline-STT ist
nicht garantiert. [Backend](backend/README.md) · [Sprache](docs/SPEECH_TROUBLESHOOTING.md).

## Artefakte und Wiederherstellung

Aus der erfolgreichen Produkt-Main-CI `47ab0028`:
[Quell-ZIP, Patch, Manifest und vollständiges History-Bundle](https://github.com/ManuEtt/Dnd/actions/runs/41183481979/artifacts/13036032830) ·
[ARM64-Alpha mit Quellen](https://github.com/ManuEtt/Dnd/actions/runs/41183481979/artifacts/13036442277).
Der enthaltene CI-Patch verwendet die Basis `72ba9d2e06e7121f955832b4ad22223f64f7c343`;
für eine vollständige Wiederherstellung das ZIP oder History-Bundle verwenden.
Der Abschlussnachtrag #445 wird als reine Dokumentationsänderung separat geprüft.

Unter GitHub **Actions → erfolgreicher Android-Lauf → Artifacts** liegen
vollständiges Quell-ZIP, Binärpatch, SHA256-Manifest und History-Bundle sowie
Debug- und optimierte ARM64/ARMv7/x64-Alpha-APKs. Optimierte Alphas tragen eine
Debug-Testsignatur; Store-Signierung und echter Geräte-/Upgrade-/TalkBack-Test
sind separate offene Abnahmen. [APK-Hilfe](docs/APK_DOWNLOAD.md).

Ein ZIP enthält `app/`, `backend/`, `scripts/`, `docs/` und `.github/` unmittelbar
an der Wurzel. Für GitHub entpackte Inhalte in einem separaten Branch vergleichen;
kein bestehendes Main blind mit einem älteren ZIP überschreiben. Patches zuerst
mit `git apply --check` auf ihrer dokumentierten Basis prüfen. Das Git-Bundle
bewahrt die vollständige erreichbare Historie. [Import](docs/UPLOAD_TO_GITHUB.md).

Alle ursprünglichen Branchspitzen sind zusätzlich als
`archive/pre-migration-20261030/<Branch>-<SHA12>` auf GitHub erhalten.
Eine Branchlöschung erfordert vollständige Ancestry, erfolgreiche finale
Main-CI und einen frisch geprüften unveränderten Head.

## Dokumentation und Regelquelle

[Architektur](ARCHITECTURE.md) · [Tests](TESTING.md) ·
[Entwicklungsstand](DEVELOPMENT_STATUS.md) · [Änderungen](CHANGELOG.md) ·
[SRD-Audit](docs/SRD_5_2_1_COVERAGE_AUDIT.md) ·
[Integrationsbericht](docs/parallel/ALL_BRANCHES_MIGRATION_20261030.md).

Die vor der Konsolidierung vereinigten README-/Checkpoint-/Statusdateien sind
[bytegenau archiviert](docs/history/migration_20261030/manifest.json).
Alle ursprünglichen Fortschritte und Testberichte bleiben außerdem in Git
sowie den persönlichen Chat-Checkpoints erhalten. Historische Meldungen zu
laufender CI oder damals fehlenden SDKs sind keine aktuellen Befunde.

Regelgrundlage: ausschließlich rechtmäßig nutzbare Inhalte des **D&D SRD 5.2.1**
unter **CC BY 4.0**. [Namensnennung und Lizenzen](THIRD_PARTY_NOTICES.md).
Eine vollständige SRD-Umsetzung und ein öffentlicher Mehrspielerdienst sind
weiterhin Entwicklungsziele.
