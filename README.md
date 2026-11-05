# Würfelraunen – Der lebendige Spielleiter

**Würfelraunen** ist eine deutschsprachige Fantasy-Solo-App für Android. Eine lokale Regelengine prüft Spielerhandlungen und verwaltet bestätigte Spielzustände; ein austauschbarer Erzähler führt durch Abenteuer, Figuren, Orte und Quests. Das Projekt befindet sich in der **Alpha-Entwicklung**.

## Funktionsüberblick

- **Charaktere und Kampagnen:** Charakterverwaltung, Abenteuerverlauf, Journal, Quests, Inventar, Kampf und Würfelproben.
- **Regeln statt freier KI-Behauptungen:** Die lokale Engine entscheidet über bestätigte Würfe, Trefferpunkte und Ressourcen. Erzähltexte und KI-Vorschläge dürfen diese Werte nicht eigenmächtig ändern.
- **Beständiges Kampagnengedächtnis:** bestätigte Ereignisse, Orte, NPCs und Handlungsstränge bleiben für die Wiederaufnahme erhalten.
- **Lokale Spielstände:** SQLite mit versioniertem JSON-Import und -Export; ein Demo-Modus ist ohne externen KI-Dienst nutzbar.
- **Optionaler Erzähler und Sprache:** ein Fastify-/TypeScript-Backend für externe Erzählmodelle sowie Android-Sprachfunktionen über verfügbare Gerätedienste.
- **Android-Oberfläche:** deutschsprachige Flutter-Oberfläche mit Fantasy-Gestaltung und laufender Verbesserung von Bedienbarkeit und Barrierefreiheit.

## Repository-Aufbau

| Pfad | Zweck |
| --- | --- |
| `app/` | Flutter-/Dart-App, Regelengine, Story, Oberfläche und Tests |
| `backend/` | optionaler Fastify-/TypeScript-Erzähler und Backendtests |
| `scripts/` | Projektprüfungen, Build-, Paket- und Release-Werkzeuge |
| `docs/` | Architektur, Spielstandhinweise, SRD-Nachweise und Entwicklungsdokumentation |
| `docs/parallel/` | Dokumentation der parallelen Entwicklung und Integration |
| `.github/workflows/` | automatisierte Prüfungen und Android-Builds |

## Projektstand und Grenzen

Die **verbindliche App-Version** steht in [`app/pubspec.yaml`](app/pubspec.yaml); den Integrations- und Teststatus des aktuellen Commits zeigen [GitHub Actions](https://github.com/ManuEtt/Dnd/actions) und [offene Pull Requests](https://github.com/ManuEtt/Dnd/pulls). Ältere Versions-, PR- und Testergebnisse im Entwicklungsprotokoll sind **historische Momentaufnahmen**, keine automatische Freigabe neuerer Commits.

Die D&D-Regelgrundlage ist das **SRD 5.2.1** unter CC BY 4.0. Die Regelabdeckung ist noch **nicht vollständig**: einzelne Domänenbausteine können bereits getestet sein, ohne vollständig an Oberfläche, Controller oder Speicherung angeschlossen zu sein. Reale Android-Geräteabnahme, produktive Release-Signierung und die Unterstützung weiterer Plattformen sind getrennt zu verifizieren. Ein öffentlich nutzbarer Mehrspielerdienst gehört nicht zum derzeit nachgewiesenen Funktionsumfang.

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

## Historische Build-Artefakte und Wiederherstellung

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

---

## Entwicklungsprotokoll und Nachweise

Die folgenden unverändert erhaltenen Entwicklungsnotizen enthalten sowohl integrierte Arbeit als auch **damals offene oder nur vorgeschlagene Pull Requests**. Vor einer Aussage zum heutigen Stand müssen jeweils Code, PR-Status und CI auf dem betreffenden Commit geprüft werden. Die Reihenfolge der älteren Notizen ist historisch gewachsen.

**Verbindliche Schreibregel:** Ab jetzt dürfen neue Entwicklungsnachträge ausschließlich **ganz am Ende dieser README, nach dem letzten vorhandenen Eintrag**, angefügt werden. Nichts vor die Projektüberschrift, nicht in die Projektbeschreibung und nicht zwischen ältere Einträge setzen.

### Archivierter Integrationsstand (31.10.–02.11.2026)

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

**Fachpaket (02.11.2026, separater PR):**
Das SRD-5.2.1-Merkmal Metamagie erhält eine
**streng bestätigte, extern versionierbare
Auswahlliste** mit 2 Optionen ab eigener
Zaubererstufe 2, 4 ab Stufe 10 und 6 ab 17.
Bei einem verifizierten Aufstieg der
Zaubererklasse darf höchstens **eine**
Option ersetzt werden; ein anderer
Mehrklassenaufstieg schenkt nichts.
Unbekannte Metamagieoptionen,
Doppelbelegungen, erfundene Klassen,
manipulierte JSON-Felder und veraltete
Sorcerer-Klassenstufen werden abgewiesen.
Zwölf Domain-/JSON-/SQLite-/Revisionstests
sind angelegt.

**Wichtig:** Der neue
`SrdMetamagicChoiceRecord` ist bislang ein
**eigenständiges JSON-Artefakt** und **nicht**
im bestehenden Helden- oder SQLite-Modell
gespeichert; eine rohe JSON-Datei
beweist keine autorisierte Wahl.
Der parallel offene PR #463 wird
nicht überschrieben. App-Version,
SQLite3 und äußeres JSON1 unverändert.
[Fachgrenzen](docs/SRD_METAMAGIC_CHOICE_RECORD_20261102.md).

**Nächster Schritt:** nach
koordiniertem Merge einen autorisierten
Metamagie-Auswahlbeleg am Helden
persistieren und Distant Spell nur
bei nachweisbarer aktueller Wahl
in die atomare Cast-Transaktion aufnehmen.

---

## Verzögerte KI-Antwort nach SQLite-Neustart (31.10.2026)

Ein neuer Flutter-Regressionstest schützt vor einer Story-Provider-Antwort, die erst nach einer parallelen, bereits bestätigten SQLite-Änderung ankommt. Der positive Gegenfall bestätigt genau einen narrativen Spielzug; der Konfliktfall bewahrt Journal, NPC-Notizen, Story-Fäden, Heldenzustand und rekonstruierte Kampagne. Branch `feat/chat-b/delayed-story-response-restart-20261031` von `47ab002872b7`; CI-Ausführung dieses Pakets steht bei Erstellung noch aus. Kein Schemawechsel, keine neuen API-Kosten.

> **Neu im separaten Draft-PR [#447](https://github.com/ManuEtt/Dnd/pull/447) (31.10.2026):**
> Während einer noch offenen Schildreaktion zeigt die Kampfchronik nur
> bestätigte Angriffswürfel, keinen vorzeitigen Schaden oder kritische
> Zusatzwürfel. Widget-Regressionen für 320/360 dp, 200 % Schrift und
> TalkBack-Semantics wurden ergänzt; erfolgreiche CI und echte
> Geräteabnahme stehen noch aus. Diese Änderungen sind **nicht Teil von main**.

## Zauberaktion und Zauberplatz als gemeinsames Staging (31.10.2026)

Der neue explizit verwendbare Domainbaustein
`SrdSpellTurnTransactionRules` verbindet die vorhandenen
`SrdSpellPreflightRules` (vorbereiteter Zauber, Klasse, Ziel, Komponenten
und Slot) mit `SrdSpellActionEconomyRules` (bestätigter eigener Zug,
Magic Action vs. Bonus Action und Slotlimit). Das Ergebnis besteht aus
**zwei unveränderten Originalen und einem zusammengehörigen neuen
Helden-/Encounter-Vorschlag**: Aktion oder Bonusaktion sowie ggf.
Zauberplatz werden nur gemeinsam berechnet. Veraltete Helden-,
Zauber- und Kampfsnapshots und unbestätigte Effekte werden abgewiesen.
Neun neue Regressionstestgruppen inklusive Retry, Zustand nach dem
Wurf, Zaubertricks, Slotlimit, Nicht-Kampf-Grenzen und JSON-Roundtrip
in `app/test/srd_spell_turn_transaction_rules_test.dart`.

**Grenze:** Dieses Regel-Staging schreibt noch nicht in SQLite und
ist noch nicht an den vorhandenen `GameController` gekoppelt.
Spielstandsrevision und Eventjournal müssen durch einen nachfolgenden
koordinierten Integrations-PR atomar geschrieben werden. Keine
vorhandene Legacy-Schnittstelle oder Speicher-/Versionsnummer geändert.
Details: `docs/SRD_SPELL_TURN_TRANSACTION_STAGING.md`.
Neue vollständige CI für diesen Branch noch abzunehmen.

## Unicode-Zeilentrenner in Android-Backupdateinamen (31.10.2026)

[PR #449](https://github.com/ManuEtt/Dnd/pull/449) auf `fix/chat-d/backup-unicode-separators-20261031`, Basis-main `5a88834c98f5aca40395088c20c7e1dc5b587868`: Die native SAF-Dateinamenprüfung verbietet jetzt auch Unicode-Zeilen- und Absatztrenner (U+2028, U+2029). Diese werden von der bisherigen ISO-Steuerzeichen- und Unicode-FORMAT-Prüfung nicht erfasst. Negative und positive Kotlin-Regressionstests sichern die Sperre sowie gültige Namen mit Umlauten, Emojis, gewöhnlichen Leerzeichen und kombinierenden Zeichen ab. Vollständige GitHub-CI/Android-Geräteabnahme bei Erstellung noch offen. Keine Migration von SQLite, JSON-Spielständen oder Appversion; kein Eingriff in Regeln, UI oder Story. Parallel integrierte Dokumentation muss vor Review/Merge erhalten bleiben.

---

### Portable Quellcode-ZIP-Dateinamen (PR #451)

Am 31.10.2026 wurde auf dem unabhängigen Branch `fix/chat-d/archive-unicode-controls-20261031` die Prüfung
`scripts/package_project.py` gegen unsichtbare Unicode-Steuerzeichen,
Formatzeichen, Surrogate und Zeilen-/Absatztrenner erweitert.
`scripts/tests/test_package_project.py` enthält vier neue Regressionstests
einschließlich unverändertem ZIP-/SHA256-Paar bei abgelehnten Pfaden.
[PR #451](https://github.com/ManuEtt/Dnd/pull/451) ist ein Draft.
Vollständige GitHub-CI ist am finalen Commit gesondert nachzuweisen;
kein SQLite-/JSON-Migrationsbedarf, keine Änderung von Flutter oder Android.
Vor Integration mit #446–#449 müssen gemeinsame README-/Checkpoint-Ergänzungen
verlustfrei konsolidiert werden.


---

### Unicode-sichere Alpha-APK-ZIP-Einträge (PR #460)

Auf dem Branch `fix/chat-d/apk-unicode-entry-names-20261101` prüft der Release-Validator
`scripts/prepare_alpha_release.py` zusätzlich die Unicode-Kategorien
`Cc`, `Cf`, `Cs`, `Zl` und `Zp` in APK-ZIP-Mitgliedsnamen, bevor er CRC-Daten
dekomprimiert oder Release-Artefakte veröffentlicht. Fünf Regressionstests
(`scripts/tests/test_prepare_alpha_release.py`) decken unzulässige
Steuer-/Richtungs-/Trennzeichen, Surrogate, weiterhin zulässige internationale
Namen und den Erhalt früherer Releases ab.
[PR #460](https://github.com/ManuEtt/Dnd/pull/460) bleibt Draft bis zur
vollständigen CI auf finalem HEAD. Keine SQLite-/JSON-/Spielstandmigration und
keine Änderung der App-Version. Gemeinsame README-/Checkpoint-Änderungen
mit parallelen PRs bei Integration additiv erhalten.


---

### Gradle-Wrapper-JAR gegen Unicode-Kontrollzeichen absichern (PR #462)

Der Projektübertragungsprüfer `scripts/verify_project.py` weist in den
ZIP-Mitgliedsnamen der Gradle-Wrapper-JAR jetzt zusätzlich die Unicode-
Kategorien `Cc/Cf/Cs/Zl/Zp` **vor CRC-Dekompression** zurück. Vier neue
Regressionstestmethoden in `scripts/tests/test_verify_project.py` prüfen
C1-Steuerzeichen, Bidi-/Zero-Width-Formatzeichen, Zeilen-/Absatztrenner,
Surrogat-Metadaten sowie weiterhin gültige Umlaute, Akzente, Emoji und CJK.
[PR #462](https://github.com/ManuEtt/Dnd/pull/462) wird bis zur
vollständig erfolgreichen GitHub-CI auf finalem PR-HEAD als Draft geführt.
Keine App-/Gradle-Artefakt-, SQLite-/JSON-/Spielstand- oder Versionsänderung.
Bei Integration gemeinsame Dokumentation mit den anderen offenen PRs
verlustfrei zusammenführen.

---

### Gemeinsame Unicode-ZIP-Schutzprüfungen (Integrationspaket, 01.11.2026)

Die drei fachlich getrennten Korrekturen [#451](https://github.com/ManuEtt/Dnd/pull/451),
[#460](https://github.com/ManuEtt/Dnd/pull/460) und
[#462](https://github.com/ManuEtt/Dnd/pull/462) sind auf ihren **exakten finalen
Einzel-Commits vollständig CI-grün**. Dieser unabhängige Integrationsbranch führt
die sechs ursprünglichen Python-Code-/Test-Blobs unverändert zusammen; die
zugehörigen README-, zentralen und Checkpoint-Nachträge werden additiv
ohne Verlust historischer Statusangaben kombiniert. Für die gemeinsame
Kombination ist eine **eigene vollständige CI** erforderlich. Alte Hinweise
"Draft/CI ausstehend" in den historischen Einzel-Abschnitten beschreiben
den damaligen Zustand, nicht die aktuelle Einzelabnahme.
Die kombinierte Abnahme erfolgt ausschließlich im Integrations-PR;
kein automatischer Merge, kein Branchlöschen, keine Änderungen an
Spielstand-, SQLite- oder JSON-Schemata.

---

### 02.11.2026 – gemeinsame Regel-, Story-, UI- und ZIP-Sicherheitsintegration

Die beiden unabhängig CI-geprüften Integrationspakete
[#454](https://github.com/ManuEtt/Dnd/pull/454) (vier A–D-Pakete,
[CI #41244568578](https://github.com/ManuEtt/Dnd/actions/runs/41244568578))
und [#466](https://github.com/ManuEtt/Dnd/pull/466) (drei ZIP-Schutzpakete,
[CI #41323233143](https://github.com/ManuEtt/Dnd/actions/runs/41323233143))
werden auf `chore/chat-d/integrate-verified-ad-and-zip-guards-20261102`
gemeinsam abgenommen. Die ursprünglichen Fach- und Testdateien bleiben
**bytegenau unverändert**; die vollständigen vorherigen README- und
Checkpoint-Beiträge beider Pakete werden **verlustfrei additiv** gesichert.
Eine neu gestartete vollständige GitHub-CI auf dem finalen kombinierten
Commit ist verpflichtend. Historische Aussagen „CI ausstehend“ in älteren
Einzel-Notizen gelten nur für deren damaligen Bearbeitungsstand.
Keine automatische Main-Integration, kein Altbranch-Löschen und
keine SQLite-/JSON-/Spielstandschema-Migration.

---

### 02.11.2026 – Unix-Dateitypen im Gradle-Wrapper-JAR prüfen

Die Upload-/Projektprüfung `scripts/verify_project.py` weist beim
Gradle-Wrapper-JAR nun zusätzlich Unix-ZIP-Mitglieder zurück, die als
Gerätedatei, Pipe oder Socket markiert sind, oder deren Dateityp dem
Pfad widerspricht (Verzeichnis ohne abschließenden Schrägstrich bzw.
reguläre Datei mit abschließendem Schrägstrich). Die Prüfung erfolgt
**vor ZIP-CRC und Lesezugriff**. Vier Regressionstests in
`scripts/tests/test_verify_project.py` prüfen abgewiesene Spezialtypen,
eine als Verzeichnis getarnte `GradleWrapperMain.class`, einen
als Verzeichnis benannten regulären Eintrag sowie weiterhin zulässige
Unix-Datei-/Verzeichniseinträge. Die vorhandene JAR-Binärdatei bleibt
unverändert; keine SQLite-/JSON-/Spielstandmigration.
Branch `fix/chat-d/wrapper-jar-member-types-20261102`. Die CI-Abnahme ist auf dem finalen PR-HEAD
separat zu verifizieren; kein automatischer Merge.


---

### Kollidierende APK-ZIP-Dateinamen abweisen (02.11.2026)

Der ARM64-Alpha-Release-Prüfer `scripts/prepare_alpha_release.py`
lehnt jetzt neben exakt doppelten ZIP-Einträgen auch gleichwertige
ZIP-Pfade nach Unicode-NFC-Normalisierung und `casefold()` ab,
einschließlich unterschiedlich geschriebener impliziter
Verzeichnispfade. Die Ressourcennamen werden nicht umbenannt;
Kollisionen werden vor dem ZIP-CRC-Test erkannt und eine bereits
publizierte Alpha bleibt unangetastet. Fünf neue Regressionstests
in `scripts/tests/test_prepare_alpha_release.py` prüfen
ASCII-Groß-/Kleinschreibung, Unicode-NFC, implizite Verzeichnisse,
gültige internationale Namen und Release-Bestandsschutz.
Der Quellcode liegt auf
`fix/chat-d/apk-unicode-path-collisions-20261102` in [PR #476](https://github.com/ManuEtt/Dnd/pull/476).
Vollständige kombinierte GitHub-CI auf dem finalen PR-HEAD
ist vor einer Review- oder Merge-Freigabe erforderlich.
Keine Änderung an SQLite, JSON, Spielständen, Android-App-Code,
App-Version oder Berechtigungen.

---

### Zusammen geprüfte Archivvalidierung (Integrations-PR, 02.11.2026)

Die unabhängigen Arbeitsbereiche
[#475](https://github.com/ManuEtt/Dnd/pull/475) (Unix-Spezialdateitypen
in Gradle-Wrapper-JARs) und
[#476](https://github.com/ManuEtt/Dnd/pull/476) (Unicode-NFC- und
Casefold-Kollisionen in APK-ZIP-Einträgen) werden auf
`chore/chat-d/integrate-apk-wrapper-guards-20261102` gemeinsam
abgenommen. Beide ursprünglichen Python-Implementierungen und ihre
Tests werden bytegenau übernommen, alle drei Dokumentationen nur
additiv kombiniert. Vor einer Merge-Freigabe sind **jeweils vollständige
Einzel-CI und neue vollständige Kombinations-CI** auf den finalen
PR-Commits erforderlich. Dieser Abschnitt dokumentiert den
Integrationsvorbereitungsstand; er behauptet noch keine erfolgreiche
Gesamt-CI. Keine neuen SQLite-/JSON-/Spielstands-/Appversionsänderungen,
kein automatischer Merge oder Löschen von Branches.

---

### 0-TP-Sperre für Kriechen und Aufstehen (PR #487, 02.11.2026)

Ein historischer Held mit 0 TP kann ohne gespeichertes `bewusstlos`-Flag nicht mehr durch `GameEngine.crawl` oder `GameEngine.standUp` bewegt werden. Beide spezialisierten Bewegungsregeln verlangen vor der Bestätigung bekannte positive TP und einen lebenden Helden. Legacy-JSON und SQLite-Daten werden beim Lesen nicht verändert; nach bestätigter Heilung bleibt der normale Ablauf möglich. Vier neue Flutter-Domänen-/Engine-Regressionen (positive und negative Fälle) sind ergänzt. **CI auf dem finalen PR-HEAD noch offen; kein lokal installiertes Flutter-/Dart-SDK.** Quelle: SRD 5.2.1, *Dropping to 0 Hit Points*, S. 17, CC BY 4.0. [Pull Request #487](https://github.com/ManuEtt/Dnd/pull/487); Regelabdeckung weiterhin teilweise.


## Bestätigte NPC-Beziehungen für die Kampagnenwiederaufnahme (02.11.2026)

[Draft-PR #489](https://github.com/ManuEtt/Dnd/pull/489) ergänzt einen
revisionsgebundenen, schreibgeschützten `ConfirmedNpcResumeSelector`.
Aus bestätigten lokalen `npcRelationshipNotes` werden höchstens drei NPCs
nach neuestem Notizzeitpunkt, gespeicherter Reihenfolge und eindeutiger
NPC-ID ausgewählt. Jede Beziehung behält ihre explizite sichere NPC-ID;
unsichere oder doppelte NPC-/Notiz-IDs und unbestätigte KI-Szenen zählen
nicht als Erinnerungsquelle. Je NPC sind maximal drei bestätigte Notizen
zulässig, Unicode-Ausgaben werden auf Zeichenlimits und insgesamt 2.400
UTF-16-Einheiten begrenzt. Der Snapshot ist unveränderlich und kann auch
bei gleicher Revision gegen Änderungen der ursprünglichen NPC-Chronik
revalidiert werden.

Sieben neue Regressionen prüfen Reihenfolge, Namensdubletten, unsichere
IDs, Unicode-/Emoji-Grenzen, veraltete Kontexte, ältere JSON ohne
NPC-Notizen und den tatsächlichen SQLite-Neustart. Die Auswahl ist ein
eigenständiger Storybaustein, noch nicht an UI oder Backend angeschlossen.
Keine Änderungen an Regeln, Held, Inventar, Quests, SQLite 3,
äußerem JSON 1 oder Version. Die vollständige CI auf dem finalen
PR-Commit ist bei dieser Dokumentation noch offen.


---

### Unicode-sichere Pfadkollisionen im Gradle-Wrapper-JAR (02.11.2026)

Der Projekt-Upload-Prüfer `scripts/verify_project.py` verweigert im
Gradle-Wrapper-JAR nun auch Dateinamen und implizite Verzeichnisse, die sich
nur durch Groß-/Kleinschreibung oder kanonisch gleichwertige
Unicode-Schreibweisen (NFC und `casefold()`) unterscheiden. Anders als
gewöhnliche gültige Unicode-Namen werden diese Kollisionen bereits beim
Lesen der ZIP-Metadaten **vor CRC/Dekomprimierung** erkannt.
`scripts/tests/test_verify_project.py` ergänzt fünf Regressionstests
für ASCII- und `ß`-Casefold, NFC-Namen und -Verzeichnispräfixe sowie
zulässige unterschiedliche internationale Namen. Der tatsächliche
Gradle-Wrapper, Android-App-Code, Spielstände und Version bleiben unverändert.
Branch: `fix/chat-d/wrapper-jar-unicode-collisions-20261102`.
Eine vollständige GitHub-CI auf dem finalen PR-HEAD ist für Review/Merge
erforderlich; keine automatische Branchbereinigung.


---

### Datei-/Verzeichnis-Kollisionen in ZIP-Archiven verhindern (02.11.2026)

Die Import-/Release-Prüfungen `scripts/verify_project.py` (Gradle-Wrapper-JAR)
und `scripts/prepare_alpha_release.py` (ARM64-APK) sperren nun zusätzlich
ZIP-Namen, bei denen ein expliziter Dateieintrag gleichzeitig als
Verzeichnispräfix anderer Einträge oder als explizites Verzeichnis
auftaucht. Die Prüfung wertet ZIP-Metadaten vor CRC/Dekomprimierung aus
und funktioniert unabhängig von der Reihenfolge der Einträge.
Ein regulärer Verzeichnis-Eintrag mit untergeordneten Dateien bleibt erlaubt.
Sieben Regressionstests sichern Ablehnung, positive Fälle und den
Bestandsschutz bereits veröffentlichter Release-Artefakte ab.
Branch: `fix/chat-d/zip-file-directory-conflicts-20261102`.
Die finale GitHub-CI auf dem vollständigen PR-Commit ist vor Review oder Merge
verbindlich. Kein SQLite-/JSON-/Save-Schema- oder Appversionswechsel.

---

### Vorbereitete Integration vollständig getesteter Fachpakete (02.11.2026)

Der eigenständige Integrations-Draft verbindet die bereits einzeln CI-geprüften
[#485](https://github.com/ManuEtt/Dnd/pull/485) (Metamagie-Auswahlbeleg),
[#487](https://github.com/ManuEtt/Dnd/pull/487) (keine Bewegung bei 0 TP),
[#488](https://github.com/ManuEtt/Dnd/pull/488) (Initiative-Dialog mit IME)
und [#489](https://github.com/ManuEtt/Dnd/pull/489) (bestätigte NPC-Beziehungen).
Die technischen Git-Blobs werden jeweils unverändert übernommen, alle
Quell-Dokumentationseinfügungen einschließlich dieses README bleiben erhalten.
Die gemeinsame CI auf dem finalen Integrationsstand ist **vor** einem Merge
vollständig abzunehmen; laufende andere PRs bleiben unabhängig.
Keine neuen Datenbankmigrationen oder Berechtigungsänderungen durch die Integration.

---

### Vorbereitete Integration der PRs #478, #479, #486, #491 (02.11.2026)

Die folgenden Originaldokumentations-Ergänzungen stammen aus vier getrennten,
vollständig CI-geprüften Quell-PRs; sie werden ohne Verlust der bisherigen
Main-Historie an die aktuelle README angefügt. Der kombinierte Draft ist
bis zur vollständigen eigenen CI nicht zur Integration freigegeben.

---

#### Dokumentationsübernahme aus PR #478

**Fachpaket (02.11.2026, separater PR):** Für
SRD-5.2.1-Metamagie **Distant Spell** prüft ein neuer
isolierter Domainbaustein die 30-Fuß-Touch-Reichweite,
Zaubererstufe 2+, offizielle eigene Klassen-/Zauber-
Freigabe, tatsächliche Metamagiewahl, Hindernisse und
einen verfügbaren Sorcery Point. Der Plan ist lesend
und an einen unveränderten Figuren-Snapshot gebunden;
Punktkosten können nur als neue Heldenkopie für die
spätere atomare Transaktion vorgemerkt werden.
Zehn Testgruppen einschließlich falscher
Mehrklassenquelle, blockierter Strecke, altem JSON,
SQLite-Neustart und Revisionskonflikt sind angelegt.
**Keine** automatische Spell-Cast-Freigabe oder
Metamagie-Auswahlpersistenz und **kein** Einbau in
offene PR #461/#463/#472; Schema-/Versionsstand
unverändert. [Regelbeleg und Grenzen](docs/SRD_DISTANT_TOUCH_METAMAGIC_20261102.md).

**Nächster Schritt:** persistente
Metamagiewahl und atomare Slot-/Punkt-/Effekt-
Transaktion nach koordinierter Integration
der bisherigen Vorbereitungs-/Raster-PRs.


---

#### Dokumentationsübernahme aus PR #479


### Bestätigte Zauberwirkungen bei großer Schrift und Tastatur (02.11.2026)

[PR #479](https://github.com/ManuEtt/Dnd/pull/479) macht den Dialog zur ausdrücklich bestätigten Zauberwirkung bei 320/360 dp, 200 % Schrift und geöffneter Android-Tastatur insgesamt scrollbar, kürzt lange Laufzeittexte und kennzeichnet Validierungsfehler für Screenreader. Vier Widgettests prüfen Abbruch, Belegprüfung, Bestätigung und gezieltes Entfernen einer bestehenden Quelle. **CI auf finalem #479-HEAD noch zu prüfen.** Keine SRD-, Zauberwirkungs-, Ressourcen-/Spielstand-, Domain- oder Datenformatänderung.

---

#### Dokumentationsübernahme aus PR #486


## Begrenzter bestätigter NPC-Rückblick (02.11.2026)

[Draft-PR #486](https://github.com/ManuEtt/Dnd/pull/486) auf Basis-main
`885580202caeafc9787538b6dc1c833b3190a529` ergänzt eine separate,
schreibgeschützte `ConfirmedNpcContinuityExcerpt.read`-Projektion
für bestätigte NPC-Erinnerungen. Die gespeicherte, sichere NPC-ID erscheint
immer ausdrücklich, auch bei ähnlich angezeigten Figuren. Höchstens drei
bestätigte Notizen und maximal 1.800 UTF-16-Einheiten (Unicode-/Emoji-sicher)
gehen in die Kurzfassung; Alttexte werden ausschließlich für die Anzeige
bereinigt und gekürzt. Sechs neue Regressionen prüfen Quellentrennung,
Unicode, lange Legacy-Texte, ungültige/mehrdeutige NPC-IDs,
Legacy-JSON und einen echten SQLite-Neustart.
Kein Umbau des `npc_continuity_reader.dart` (offener PR #477),
keine KI-/UI-Anbindung, kein Einfluss auf Regeln, Quest, Held, SQLite-/JSON-
Schema oder Version. Finale CI-Abnahme bei Dokumentation noch offen.


---

#### Dokumentationsübernahme aus PR #491


---

### 02.11.2026 – Unsichtbare Zeichen in neuen KI-Geschichten

[PR #491](https://github.com/ManuEtt/Dnd/pull/491) (Draft),
Branch `feat/chat-b/ai-provider-zero-width-guard-20261102`,
Basis-main `c33448780dfe8b453f7f1db9d28c1396822901a7`:
Der Storyparser lehnt jetzt auch U+200C/U+200D (Zero-Width-Joiner)
in neu eintreffender KI-Erzählung, NPC-/Ortsnamen und Notizen ab.
Der neue `ai_story_zero_width_validation_test.dart` enthält positive
mehrzeilige internationale Erzählungen und negative Providerfeldvarianten.
Die Quell-/Testcommits sind `bfcedd60`/`4295681f`;
die GitHub-CI für den finalen PR-HEAD ist vor einer Freigabe
noch tatsächlich zu prüfen. Bestehende SQLite-/JSON-Spielstände,
Story- und Regelwerte sowie App-Versionen bleiben unverändert.
Gemeinsame Dokumentationsnachträge bei Integration additiv erhalten.

---

### Materialinventar-Dialog bei 200 % Text und Android-Tastatur (02.11.2026)

[PR #474](https://github.com/ManuEtt/Dnd/pull/474) verbessert den Materialinventar-Dialog bei 320/360 dp, 200 % Text und 220 dp geöffneter Tastatur: gemeinsamer vertikaler Dialog-Scrollbereich, kompakte Insets, Screenreader-Live-Regionen für Rezept-/Validierungsfehler. Fünf neue Widgettests prüfen fehlendes Rezept, ungültige Materialbestätigung, bestätigte read-only Inventarstapel und die Astral-Projection-Zieleingabe. **CI auf dem finalen PR-HEAD noch ausstehend.** Keine SRD-/Inventar-/Spielstands-/Versions- oder Datenformatänderung.

---

### Kreaturenerfassung bei 200 % Schrift und Android-Tastatur (02.11.2026)

[PR #469](https://github.com/ManuEtt/Dnd/pull/469) macht die zusätzliche Kreaturenregistrierung mit vier Eingabefeldern und Bestätigungs-Checkbox bei 320/360 dp, 200 % Schrift und geöffneter IME vollständig scrollbar. Fehler werden über eine Screenreader-Live-Region angekündigt. Vier neue Widgettests prüfen ungültige Angaben, Abbruch, gültige bestätigte Registrierung und TP-Korrektur. **Finale CI des neuen PR steht aus**; SRD-Regeln, Speicher, Datenformate, App-Version und bestehende Verantwortlichkeitsgrenzen bleiben unverändert.

**Integrationsnachweis (02.11.2026):** Die zuvor als ausstehend beschriebenen vollständigen Einzel-CIs sind auf den finalen Heads abgeschlossen und erfolgreich: [#474 / 41396373761](https://github.com/ManuEtt/Dnd/actions/runs/41396373761) und [#469 / 41393278139](https://github.com/ManuEtt/Dnd/actions/runs/41393278139). Kombination mit #495 erfordert eine eigene CI.

---

### Zustandseffekt-Dialog bei großer Schrift und Tastatur (01.11.2026)

[PR #465](https://github.com/ManuEtt/Dnd/pull/465): Der Dialog zur bestätigten Zustandsquelle bleibt bei 320/360 dp, 200 % Schrift und offener Android-Tastatur als Ganzes scrollbar. Lange Dropdown-Texte werden gekürzt dargestellt, Validierungsfehler als Live-Region markiert. Vier neue Flutter-Widgettests prüfen Fehler/Abbruch, neue Quelle und gezieltes Entfernen nur einer Quelle; Heldenstände bleiben unangetastet. **Finale Flutter-/Android-CI noch zu verifizieren.** Keine SRD-, Ressourcen-, Spielstand- oder Datenformatänderung.

---

### Mehrklassen-Dialog bei 200 % Schrift und Android-Tastatur (01.11.2026)

[PR #458](https://github.com/ManuEtt/Dnd/pull/458) macht den Mehrklassen-Stufenaufstieg auf 320/360 dp mit 200 % Schrift und eingeblendeter Tastatur durchgängig vertikal scrollbar; die Erfahrung-/Meilenstein-Auswahl erhält horizontales Scrolling. Vier neue Flutter-Widgetfälle prüfen Abbruch, EP-Sperrung, Meilenstein und Barden-Fertigkeitswahl. **CI auf dem finalen PR-Commit noch ausstehend.** Keine Änderung an SRD-Regeln, Heldendaten, Spielständen, Speicherformat oder Version.

---

### Magieinitiierter-Dialog bei 200 % Schrift und geöffneter Tastatur (31.10.2026)

[PR #457](https://github.com/ManuEtt/Dnd/pull/457): Die bestehende explizite Wahl von zwei Zaubertricks, Erstgradzauber und Zauberattribut bleibt nun auch bei 320/360 dp und simuliertem Android-IME in einem vollständig scrollbaren Dialog. Vier neue Flutter-Widgetfälle prüfen erreichbare Felder/Abbruch, gesperrte doppelte Tricks und den bestätigten Wahl-Datensatz. **Die neuen Flutter-/Android-CI-Tests müssen auf dem finalen PR-HEAD geprüft werden.** SRD-Regeln, Spielstände und Ressourcenbuchung bleiben unverändert.

---

### Hintergrundpaket-Dialog bei großer Schrift und Tastatur (31.10.2026)

[PR #455](https://github.com/ManuEtt/Dnd/pull/455) verbessert die Flutter-Hintergrundpaketwahl bei 320/360 dp und 200 % Schrift mit eingeblendeter Tastatur: ein einzelner scrollbarer Dialog, schmale Außenränder und expandierte Dropdowns. Neue Widgettests sichern Abbruch, gesperrte unvollständige Soldat-/Akolyth-Wahlen, Akolyth-Goldwahl und explizite Spielsetauswahl ab. **Flutter-/Android-CI des finalen PR-Commits und echte Geräteprüfung noch offen.** Keine Regel-, Speicher-, Schema- oder Versionsänderung.

**Integrations-CI-Nachweis (02.11.2026):** Vollständige Quellprüfungen waren jeweils auf dem finalen Head erfolgreich: [#465](https://github.com/ManuEtt/Dnd/actions/runs/41323668152), [#458](https://github.com/ManuEtt/Dnd/actions/runs/41282153192), [#457](https://github.com/ManuEtt/Dnd/actions/runs/41248140576) und [#455](https://github.com/ManuEtt/Dnd/actions/runs/41246044715). Historische Angaben „CI ausstehend“ beziehen sich auf den damaligen Veröffentlichungszeitpunkt. Kombinierte neue CI bleibt verpflichtend.

---

**Separater Fix (02.11.2026, noch nicht in main):**
Ein bestätigter Berührungszauber darf auf dem vorhandenen
5-Fuß-Taktikraster nicht allein mit gesetztem
`withinTouchReachConfirmed`-Flag ein beliebig weit
entferntes Ziel erreichen. Im konservativen Standardpfad
sind nur das eigene und angrenzende Felder mit zusätzlicher
ausdrücklicher Berührungsbestätigung zulässig.
Die SRD erlaubt Sonderfälle mit größerer *reach*,
deren separate Verifikation hier weiterhin offen ist.
Neue Domain-/Preflight-/JSON-/SQLite-/Revisionsregressionen
testen die fehlende implizite Zauberbuchung.
Keine DB-/JSON-Migration, kein UI-/Engineumbau,
keine Änderungen an parallelen Preflight-PRs.
[Fachnachweis](docs/SRD_GRID_TOUCH_REACH_20261102.md).

**Nächster Schritt:** explizit
bestätigte Spezialreichweiten für Touch
regelquellengebunden gesondert überprüfen.

---

**Separates Regelpaket (01.11.2026, noch nicht in main):**
Branch `feat/chat-a/prepared-spell-exchange-triggers-20261101`
führt die offizielle SRD-5.2.1-Tabelle (S.104) zum
**Austausch bereits vorbereiteter Zauber** als rein
lesende Regelprüfung ein: Kleriker/Druide/Magier dürfen
bei bestätigter langer Rast mehrere Zauber tauschen,
Paladin/Waldläufer dort einen, Barde/Zauberer/Hexenmeister
einen beim nachgewiesenen **Aufstieg ihrer eigenen Klasse**.
Die Vorprüfung verweigert unbekannte/widerrechtliche Klassen,
Zaubertricks, illegale Grade, unbestätigte Rast,
unbestätigtes Magier-Zauberbuch und zu viele Wechsel.
Elf deterministische Testgruppen einschließlich SQLite-
Neustart und Revisionskonflikt sind angelegt.
**Keine** Speicherung oder Zauberfreigabe aus dieser
Vorprüfung allein; offene PRs #461 und #463 werden
nicht überschrieben. SQLite3, JSON1, App-Version
unverändert. [Fachdetails und Grenzen](docs/SRD_SPELL_PREPARATION_EXCHANGE_20261101.md).

**Nächster Schritt:** nach Integration der isolierten
Vorbereitungs-PRs diese Regeln atomar mit bestätigter
Rast- und Klassen-Aufstiegsentscheidung verknüpfen.

---

**Separater Regelfix (Branch, noch nicht in main):**
`feat/chat-a/multiclass-slot-aliases-20261031` behebt die
Namensabhängigkeit in `MulticlassRules.combinedSpellcasterLevel`.
Die schon unterstützten SRD-Klassenaliase (`Wizard`/`Magier`,
`Ranger`/`Waldläufer` usw.) ergeben damit identische
Mehrklassen-Zauberplatzwerte. Hexenmeister-Paktmagie bleibt
eigenständig, unbekannte Klassen werden nicht geraten.
Sieben neue Domain-/SQLite-/Altspielstand-Testgruppen stehen
in `app/test/multiclass_spell_slot_alias_test.dart`; tatsächlicher
CI-Nachweis ist vom finalen PR-HEAD abhängig. Keine Migration,
keine Änderungen an bestehenden Klassennamen und Spielständen.
Der offene PR #448 bearbeitet einen anderen Regelbaustein;
gemeinsame Dokumentation muss bei der Integration additiv
konsolidiert werden. [Details](docs/parallel/CHAT_A_CHECKPOINT.md).

**Nächster unabhängiger Schritt nach diesem Fix:**
Regelgeprüfte Vorbereitung von Mehrklassen-Zaubern pro
Klassenstufe und bestätigtem Katalogeintrag, mit
Ablehnungs-, Alt-JSON- und SQLite-Retrytests.

---

**Separates Regelpaket (01.11.2026, noch nicht in main):**
Branch `feat/chat-a/multiclass-prepared-source-20261101`
verlangt eine ausdrückliche Zuordnung zum ausgewählten
`castingClass`, falls ein Mehrklassenheld denselben Zauber
auf **beiden** eigenen Klassenlisten und für **beide** individuellen
Klassenstufen vorbereiten könnte. Die globale historische
Zauberliste allein beweist die Klasse nicht. Eindeutige Zuordnungen,
Einzelklassen und bestehende Ressourcen-/Material-/Ziel-/
Snapshot-Prüfungen bleiben unverändert. Acht neue
Domain-/JSON-/SQLite-Regressionen sind angelegt; maßgebliche
GitHub-CI auf dem finalen PR-Commit prüfen. Keine
Migration, SQLite 3 / JSON 1. Kein vollständiger
klassenbezogener Vorbereitungseditor oder fertiges
SRD-Regelwerk. [Fachnachweis und Grenzen](docs/SRD_MULTICLASS_PREPARED_SOURCE_20261101.md).

**Nächster unabhängiger Schritt:** versionierte,
ausdrücklich bestätigte per-Klasse-Zaubervorbereitung mit
Altspielstand-/Revisions-/SQLite-Tests, ohne bestehende
unbekannte Zuordnungen zu erraten.

---

### Schildreaktionsdialog bei großer Schrift und Tastatur (31.10.2026)

Der Flutter-Dialog zur expliziten Schildreaktion nutzt auf kleinen Android-Displays einen durchgehend scrollbaren Dialog mit kompakterem Außenabstand und vollbreiten Klass-/Zauberplatz-Auswahlen. Neue Widgettests decken 320/360 dp mit 200 % Schrift, simulierte Tastatur, Abbruch, fehlende Komponentenbestätigung und fehlenden vorbereiteten Schildzauber ab. Umsetzung: [PR #450](https://github.com/ManuEtt/Dnd/pull/450), Branch `feat/chat-c/hero-shield-dialog-large-text-ime-20261031`. **Die neue Flutter-Widget-/Android-CI ist noch nicht bestätigt**; Geräte- und TalkBack-Abnahme steht aus. Keine Regel-, Speicher-, Schema-, Versions- oder API-Änderung.

**Integrationsstatus  (02.11.2026):** Erfolgreiche Einzel-PR-CIs auf finalen Quellheads: [#472](https://github.com/ManuEtt/Dnd/actions/runs/41393551106), [#467](https://github.com/ManuEtt/Dnd/actions/runs/41323611885), [#453](https://github.com/ManuEtt/Dnd/actions/runs/41244807154), [#461](https://github.com/ManuEtt/Dnd/actions/runs/41282290565) und [#450](https://github.com/ManuEtt/Dnd/actions/runs/41244483591). Neue kombinierte Integrations-CI ist noch auszuwerten; historische „CI ausstehend“-Texte sind keine aktuellen Messergebnisse.

---

## Zauberwirkzeit: unsichtbare Trigger-Steuerzeichen abweisen (02.11.2026)

Die strikt konservative Metadatenprüfung für ausgelöste Zauber-Reaktionen/-Bonusaktionen weist zusätzlich U+206A–U+206F und U+FFF9–U+FFFB ab. Die Änderung samt 8 gültigen Katalog-Triggern und negativen Regressionen liegt in [PR #500](https://github.com/ManuEtt/Dnd/pull/500) auf dem eigenen Branch; die finale CI ist **noch zu verifizieren**, es wurde keine APK und kein Gerätetest abgenommen. Keine Klassen-/Ressourcen-/Spielstand-/Schemaänderung. SRD 5.2.1 (CC BY 4.0).

---

## NPC-Wiederaufnahme bleibt bei älteren Notizänderungen revisionssicher (02.11.2026)

[Draft-PR #501](https://github.com/ManuEtt/Dnd/pull/501) bindet die schreibgeschützte NPC-Erinnerung an die **vollständige bestätigte Historie** des ausgewählten NPC, nicht nur die durch `maxNotes` sichtbaren neuesten Notizen. Gleichrevisionierte Änderungen an älteren Einträgen machen den Kontext ungültig; eine unveränderte JSON-Wiederherstellung oder die Änderung eines anderen NPC bleibt erlaubt. Zwei neue deterministische Regressionstests sind ergänzt; vollständige Flutter-/Android-CI auf dem finalen PR-HEAD ist noch abzunehmen. Keine Regel-/SQLite-/JSON-/Backend- oder App-Versionsänderung. Parallelzweige und gemeinsame Checkpoint-Ergänzungen bleiben  zur konsolidierten Integration vorbehalten.

---


### Manuell bestätigter Zusatzkreaturen-Angriff bei großer Schrift (02.11.2026)

[PR #492](https://github.com/ManuEtt/Dnd/pull/492) (Draft) macht das Angriffsformular auf 320/360 dp mit 200 % Schrift und Android-Tastatur als Gesamtdialog scrollbar. Kompakte Bestätigungstexte bewahren vollständige TalkBack-Beschriftungen; lange Zielnamen passen in das Dropdown. Neuer Widgettest: `app/test/manual_extra_creature_attack_ime_test.dart` (Abbruch, unvollständige und vollständige bestätigte Auswahl; keine automatische Zustandsänderung). **CI auf dem finalen PR-Commit noch offen**; keine APK-/Realgeräteabnahme und keine Änderung an Regel-, Speicher- oder JSON-Verträgen.

---


### Sending-Dialog mit großer Android-Schrift und Tastatur (02.11.2026)

Ein eigenständiger Entwicklungsbranch `feat/chat-c/sending-dialog-ime-20261102` macht den Sending-Versuch als ganzen `AlertDialog` scrollbar. Bei mindestens 180 % Schrift bleiben die Bestätigungen visuell kurz und für TalkBack vollständig benannt. Neue Widgettests decken 320/360 dp, 200 % Schrift und ein simuliertes 220-dp-Tastatur-Inset ab, darunter Abbruch, bewusste Zustimmung, deren Widerruf nach Eingabeänderung und unveränderte Helden-JSON-Daten. Der Dialog bestätigt nur eine Vorschau; keine Spielregel-, Spielstands-, SQLite-, JSON- oder Versionsänderung. Ausführungsergebnisse und Integrationsstatus stehen im eigenen [Checkpoint](docs/parallel/CHAT_C_CHECKPOINT.md); keine Freigabe ohne finale GitHub-CI und Review.

---

### Checkpoint-Checksumliste gegen unsichtbare Unicode-Namen (02.11.2026)

Das Python-Checkpointwerkzeug verwirft nun auch Unicode-C1-/Formatsteuerzeichen sowie Zeilen- und Absatztrenner in historischen Archivdateinamen, bevor diese in die SHA-256-Prüfsummenliste gelangen. Zwei neue Regressionstests prüfen abgewiesene Namen ohne Änderung bestehender Sicherungs-Aliase und die unveränderte Unterstützung sichtbarer internationaler Namen. Branch `fix/chat-d/checkpoint-unicode-ledger-20261102`; CI auf finalem PR-HEAD noch ausstehend, keine Änderung von Spielständen, SQLite/JSON oder App-Version. Die gemeinsame Dokumentation ist beim Merge additiv zu übernehmen.

---

---

## Gespeicherte Ortsdaten bei Wiederaufnahme (02.11.2026)

[Draft-PR #505](https://github.com/ManuEtt/Dnd/pull/505) ergänzt den eigenständigen,
nur lesenden `ConfirmedPlaceResumeSelector` in
`app/lib/story/confirmed_place_resume_selection.dart`. Er liefert bis zu vier
gespeicherte Orte mit eindeutiger ID, entschärfter und begrenzter Anzeige sowie
Revisions-, Sitzungs- und Vollquellstandprüfung. Der Text sagt ausdrücklich
**nicht**, dass der Held diese Orte besucht oder entdeckt hat. Sechs neue
Flutter-Tests prüfen Mehrdeutigkeit, Unicode, ungültige Grenzen, veraltete
Datensätze, Legacy-JSON und SQLite-Neustart. Keine Änderung an Regeln,
Spielständen, Schema, `story_api.dart` (offener PR #459) oder App-Version.
Lokale Flutter-/Android-Prüfungen stehen mangels SDK aus; vollständige CI
auf finalem PR-HEAD und Geräteabnahme sind separat nachzuweisen.

---

## Wilder-Angreifer-Auswahl auf schmalem Android (02.11.2026)

Im [Draft-PR #506](https://github.com/ManuEtt/Dnd/pull/506) auf Branch `feat/chat-c/savage-attacker-ime-20261102` scrollt der gesamte Dialog für die Wahl zwischen zwei bestätigten Waffenwürfen (`AlertDialog.scrollable`). Der gewählte Wurf wird für Screenreader ausdrücklich als ausgewählt markiert. Vier neue Widgetfälle decken 320/360 dp, 200 % Schrift und simulierte 220 dp Tastatur, Abbruch, kritischen Treffer und ungültige Auswahl ab. Der Dialog gibt nur eine überprüfbare Wahl zurück und bucht keinen Schaden. Keine Änderungen an Regeln, Controller, SQLite/JSON oder App-Version. Zehn gezielte Widgettests waren in GitHub Actions #41478500514 erfolgreich; die vollständige CI und reale Android-/TalkBack-Prüfung bleiben separat nachzuweisen. Details im [Checkpoint](docs/parallel/CHAT_C_CHECKPOINT.md).

---

## Mönch „Sanfter Fall“: zustimmungssicherer Android-Dialog (02.11.2026)

In [Draft-PR #509](https://github.com/ManuEtt/Dnd/pull/509) auf Branch `feat/chat-c/slow-fall-ime-consent-20261102` ist der Dialog auch bei großer Schrift und simulierter Tastatur als Ganzes scrollbar. Nach einer Änderung des bestätigten Sturzschadens müssen Sturz und vollständig abgeschlossene andere Schadensanpassungen neu bestätigt werden. Die Vorschau und Bestätigung bleiben rein unverbindlich; Reaktion/Schaden verbucht nur der zuständige Controller. Vier zusätzliche Widgetfälle prüfen schmale 320-/360-dp-Ansichten mit 200 % Schrift und simuliertem Android-IME einschließlich Abbruch und bereits verbrauchter Reaktion. Keine Migration von Spielständen, SQLite oder JSON und keine Änderung der Spielregeln. CI-Abnahme und reales Android/TalkBack noch offen. Siehe [Checkpoint](docs/parallel/CHAT_C_CHECKPOINT.md).

---

### Manuelle Kampf-Zugfolge bei großer Schrift und Android-Tastatur (02.11.2026)

[PR #481](https://github.com/ManuEtt/Dnd/pull/481) verbessert die responsive Bedienung der manuellen Initiative-Reihenfolge: durchgängig scrollbarer `AlertDialog` bei 320/360 dp, 200 % Schrift und geöffneter Android-Tastatur, kompakte Insets und Screenreader-Live-Region für Bestätigungsfehler. Fünf neue Widgettests schützen explizite Initiative-/Gleichstandbestätigungen, Umordnung bei Gleichstand, read-only Zugfolge/Marker und neutralen Abbruch. **CI auf dem finalen PR-HEAD steht noch aus.** Keine Änderungen an Initiative-Regeln, Kampagnenzustand, Speichern, Schema, Datenformat oder Version.

---

### Manuelle Kampf-Zugfolge bei 200 % Schrift und Tastatur (02.11.2026)

[PR #483](https://github.com/ManuEtt/Dnd/pull/483) hält die manuelle Zugfolgen-Verwaltung bei 320/360 dp, 200 % Schrift und geöffneter Android-Tastatur durch einen einheitlichen Dialog-Scrollbereich bedienbar. Akteurspezifische Gleichstands-Pfeile erhalten eindeutige Screenreader-Beschriftungen, Validierungsfehler sind Live-Regionen. Fünf neue Widgettests prüfen fehlende Bestätigungen, Initiative-Gleichstände, neutralen Abbruch, gespeicherten manuellen Marker und unveränderte Kampagnensnapshots. **Neue finale PR-CI noch offen.** Keine automatische Kampf-/Ressourcenbuchung, Regel-, Speicher- oder Versionsänderung.

---

---

## Unsichtbare ältere Unicode-Formatzeichen in KI-Storys (02.11.2026)

Eigenständiges Sicherheits-/Kompatibilitätspaket auf
`fix/chat-b/story-provider-invisible-unicode-20261102`:
Flutter-`AiStoryPlan`/`AiStoryStep` und Fastify-`parseStoryPlan`/
`parseStoryTurn`/`parseAdventureDraft` verwerfen zusätzlich
U+00AD (weiches Trennzeichen), U+034F (Combining Grapheme Joiner),
U+180E und die veralteten bidi-Steuerzeichen U+206A–U+206F.
Frühere Unicode-Sperren bleiben bestehen, echte mehrzeilige deutsche
Erzählungen, Tabs, Emoji und Variation Selector U+FE0F bleiben zulässig.
Neue Flutter- und Backend-Regressionstests schützen Plan-, NPC-, Orts-,
Handlungs- und Abenteuerfelder. Keine Änderung an Regeln, bestätigten
Spielständen, JSON-/SQLite-Schema oder App-Version. Vollständige CI und
Gerätetest sind am finalen PR-HEAD gesondert nachzuweisen.

---

### Alpha-Release akzeptiert keine symbolisch verlinkte APK-Quelle (02.11.2026)

Die Python-Releasevorbereitung prüft vor dem Lesen und nochmals vor dem Kopieren der ARM64-APK, ob der angegebene APK-Pfad oder eines seiner Elternverzeichnisse ein symbolischer Link ist. Verknüpfte APKs werden abgewiesen, statt ihrem externen Ziel zu folgen. Positive und negative Regressionstests decken normale APKs, direkte und Eltern-Symlinks sowie einen Link-Austausch nach der Quell-ZIP-Stagingphase ab. Branch `fix/chat-d/alpha-apk-source-symlink-20261102`; finale CI auf dem PR-HEAD ist noch nicht bestätigt. Keine App-, SQLite-, Spielstands-, JSON- oder Versionsänderung.

---

## PR #515: korrigierte Negativtests (03.11.2026)

[PR #515](https://github.com/ManuEtt/Dnd/pull/515) wurde nach dem roten Gesamttest auf Code-Commit `49745fc6232f7f8d3ddd711bbffd4aa1eaea52c0` korrigiert. Die drei neuen Negativtests erwarten nun die bestehende `FormatException` beim nicht serialisierbaren manipulierten Spielstand statt ein fälschlich behauptetes gespeichertes `rules.blocked`-Ereignis; Helden-JSON, Eventliste und RNG bleiben unberührt. Die zwei Positivtests bleiben erhalten. Vorher: 2.854 Flutter-Tests bestanden, drei fehlgeschlagen (Läufe #41532714674 und #41532722057); neue finale CI steht noch zur Abnahme aus. Kein Produktions- oder Schemawechsel durch die Korrektur.


## Kurzrast ohne Trefferwürfel: Ressourcen vor Recovery prüfen (02.11.2026)

[PR #515](https://github.com/ManuEtt/Dnd/pull/515) ergänzt den zentralen, **nicht mutierenden Kurzrast-Ressourcencheck** für normale Rasten und beide Sonderpfade ohne Trefferwürfelverbrauch. Ein fingierter Paktplatzverbrauch (etwa bei einem Kämpfer ohne Hexenmeisterstufe) wird vor jeder Regeneration abgewiesen. Fünf neue deterministische Domain-/GameEngine-Regressionen decken gültige und ungültige Fälle, RNG-Freiheit, unverändertes Ursprungs-JSON und Wiederaufnahme ab. **CI auf finalem PR-HEAD ausstehend; keine APK-/Gerätefreigabe.** SQLite 3, JSON 1 und App-Version 0.8.49+99 unverändert; keine Migration. Grundlage: SRD 5.2.1, CC BY 4.0.

---

## Zero-Width-Namensschutz für NPC-Erinnerungen (01.11.2026)

[Draft-PR #464](https://github.com/ManuEtt/Dnd/pull/464) verhindert, dass
Unicode-Zeichen ohne sichtbare Breite (U+200B–U+200D, U+2060, U+FEFF)
zwei gleich dargestellte NPC-Namen bei freier Spielereingabe fälschlich als
unterschiedliche Namen erscheinen lassen. Bestätigte NPC-Beziehungsnotizen
werden bei unklarer Identität nicht geraten oder an den optionalen Erzähler
weitergereicht. Für eindeutig gespeicherte NPCs bleiben bestätigte Notizen
nutzbar; unsichtbare Markierungen werden ausschließlich beim Ausgeben
bereinigt, nicht aus dem gespeicherten Spielstand entfernt. Neue Tests
umfassen fünf Unicode-Varianten, die positive eindeutige Zuordnung,
alte JSONs und einen echten SQLite-Neustart. Keine Migration/Versionsänderung.
Die neue CI ist bei Anlage noch nicht abgenommen.

---

## Strukturierte NPC-Identitätsübertragung (02.11.2026)

[Draft-PR #470](https://github.com/ManuEtt/Dnd/pull/470) schließt eine
separate Zero-Width-Lücke in `NpcIdentityStoryPayload`. Visuell gleiche
NPC-Namen mit U+200B/U+200C/U+200D/U+2060/U+FEFF gelten bei freien
Spielereingaben als mehrdeutig; eine NPC-ID wird dann **nicht geraten**.
Strukturierte NPC-Namen, Beziehungen und bestätigte Notizen mit solchen
unsichtbaren Steuerzeichen gelangen nicht in den geplanten Identity-Wire.
Eine explizit gewählte, sichere NPC-ID mit bestätigtem Kontext bleibt zulässig.
Sechs Testgruppen einschließlich älterem JSON, Revisionskontrolle und echtem
SQLite-Neustart ergänzen den Code. Keine neue API-Anbindung, keine Migration
(SQLite 3/äußeres JSON 1) oder Änderung an Regelzuständen. Finale CI
auf dem Dokumentationsstand ist bei Erstellung noch offen.

---

## Bestätigte NPC-Kontinuität und unsichtbare Namen (02.11.2026)

[Draft-PR #477](https://github.com/ManuEtt/Dnd/pull/477).

Der neue Branch `fix/chat-b/npc-continuity-zero-width-20261102`
(Basis-main `2e920f222ab8fd501d9d90bff580d0f8ccc42ff1`) behebt eine
separate Lücke im schreibgeschützten `NpcContinuityReader`. Unsichtbare
Zero-Width- und Bidi-Marken in gespeicherten NPC-Namen dürfen die
Mehrdeutigkeitsprüfung nicht umgehen: visuell gleiche Figuren bekommen
im bestätigten Rückblick ihre **gespeicherte, sichere NPC-ID** angehängt,
damit Notizen nicht einer falschen Figur zugeschrieben werden. Der Rückblick
entfernt unsichtbare Steuerzeichen auch aus Beziehungen und Notizen,
während ursprüngliches NPC-JSON und SQLite-Daten unverändert bleiben.
Fünf neue Testgruppen einschließlich Legacy-JSON, unsicherer IDs und
echtem SQLite-Neustart. Keine neue Provider-Anbindung, keine Mutation von
Helden-/Quest-/Regelzustand, keine Schema-/Versionsänderung. Vollständige
CI-Abnahme erst auf dem finalen PR-Commit nachweisen.


---


---

## Bestätigter NPC-Rückblick ohne ältere Unicode-Formatmarken (03.11.2026)

[PR #519](https://github.com/ManuEtt/Dnd/pull/519) erweitert in
`app/lib/story/confirmed_npc_resume_selection.dart` ausschließlich die
schreibgeschützte Normalisierung bereits gespeicherter NPC-Überblicke:
U+00AD, U+034F, U+180E sowie U+206A–U+206F werden nicht mehr unsichtbar
an Spieler weitergegeben. Die angezeigte NPC-ID bleibt erhalten; originale
Kampagnendaten, JSON/SQLite, Regelzustand und App-Version bleiben unverändert.
Drei neue deterministische Flutter-Tests prüfen betroffene Zeichen in Namen,
Beziehungen und Notizen, zulässige Akzente und Emoji-Varianten sowie JSON-
Wiederaufnahme mit unverändertem Rohzustand und Revisionsprüfung.
Die vollständige CI auf dem finalen PR-HEAD und ein reales Android-Gerät
müssen noch gesondert abgenommen werden; der PR ist bis dahin Draft.


---

## Sichtbar eindeutige Zaubermaterial-IDs (03.11.2026)

[Draft-PR #520](https://github.com/ManuEtt/Dnd/pull/520) schließt in
`SrdSpellInventoryIdRules` eine bisherige Lücke für die neun unsichtbaren
Unicode-Zeichen U+206A–U+206F und U+FFF9–U+FFFB.
Ein neuer deterministischer Flutter-Test prüft zulässige internationale
Inventar-IDs, sämtliche neun Ablehnungen, auditiertes Zaubermaterial,
ausbleibende Slot-/Inventaränderungen bei Fehlern und erfolgreiche gültige
Materialbuchung. Ein bestehender Spielstand wird weder migriert noch
umgeschrieben; SQLite-/JSON-Schema und App-Version bleiben unverändert.
Die vollständige GitHub-CI auf finalem PR-HEAD sowie Android-Geräte-/
Upgrade-Abnahme sind getrennt zu bestätigen. Keine automatische Mergefreigabe.

---


---

## Gelegenheitsbewegung bei großer Schrift und Tastatur (03.11.2026)

[Draft-PR #521](https://github.com/ManuEtt/Dnd/pull/521) macht den
Android-Dialog „Gegnerbewegung bestätigen“ einschließlich Formular,
Abbruch und ausdrücklicher Zustimmung scrollbar. Ab 180 % Schrift ist die
sichtbare Bestätigungszeile kompakt, der ursprüngliche vollständige
Sicherheitstext bleibt über TalkBack erhalten; Fehler werden als
Screenreader-Live-Region ausgegeben. Vier neue Widgettests decken
320/360 dp, 200 % Schrift, simulierte Android-IME, positives und negatives
Bestätigungsverhalten sowie unveränderte Kampagnendaten ab.
Regeln, Story, SQLite/JSON, App-Version und Spielstände bleiben
unverändert. Lokales Flutter/Dart-SDK und Android-Gerät fehlen; die
vollständige GitHub-CI des **finalen** PR-HEAD und die reale Geräteabnahme
müssen noch belegt werden. Kein automatischer Merge.

---


---

## Unsichtbare Unicode-Zeichen in Zauberkomponenten (03.11.2026)

[Draft-PR #523](https://github.com/ManuEtt/Dnd/pull/523) schützt die
SRD-5.2.1-Metadatenvalidierung von Materialkomponenten gegen unsichtbare
Unicode-Format- und Steuerzeichen, die sonst Preis- oder Verbrauchswörter
auftrennen könnten. Ein konkreter negativer Fall ist `Revivify` mit
einem Steuerzeichen im Wort `consumes`: Ohne Schutz kann die
Materialverbrauchserkennung fehlschlagen.
Positive und negative Flutter-Tests decken den regulären Katalog,
internationale Materialbeschreibungen, neun unauffällige Formatzeichen
(U+206A–U+206F und U+FFF9–U+FFFB), JSON-Import und
Ressourcen-Preflight ohne Spielstandsänderung ab. Es werden weder
SQLite-/JSON-Schema, App-Version, Materialpreise, Slotregeln noch
bestätigte Inventare verändert. Vollständige CI am finalen PR-HEAD
und reale Android-Abnahme bleiben separat nachzuweisen.

---


---


## Natürlich formulierte Kampagnenrückblicke (31.10.2026)

[Draft-PR #452](https://github.com/ManuEtt/Dnd/pull/452) ergänzt ausschließlich die
Story-Gedächtniserkennung: „Was haben wir bisher erlebt?“, „Was ist beim letzten
Mal passiert?“ und vergleichbare ausdrückliche Rückblickbitten greifen auf
**bestätigte** Erinnerungen zurück. Allgemeine Fragewörter werden nicht mehr
als thematische Suchbegriffe fehlgedeutet. Dialoge mit NPCs und freie Aktionen
bleiben Spielerzüge. Positive/negative Flutter- und GameEngine-Tests liegen in
`app/test/story_recall_intent_test.dart`. Grundlage `main` `5a88834c`;
**CI für diesen Branch bei Dokumentation noch ausstehend**. Keine Änderungen
an SQLite/JSON, Regeln, Heldenwerten, externen KI-Kosten oder App-Version.
Die parallele PR-Dokumentation wird im koordinierten Integrationsschritt zusammengeführt.


---

## Bestätigte offene Handlungsnotizen beim Fortsetzen (31.10.2026)

[Draft-PR #456](https://github.com/ManuEtt/Dnd/pull/456) erweitert den
bestehenden Befehl **„Rückblick dauerhaft speichern“**: Die Bestandsaufnahme
enthält nun bis zu drei zuletzt gespeicherte offene Handlungsnotizen. Für
abgeschlossene/aufgegebene Stränge werden keine neuen Anknüpfungspunkte
vorgeschlagen. Bestätigte Fakten haben Vorrang vor Zusatznotizen;
Szenenbehauptungen, nicht bestätigte Dialoge und die geheime Storyvorgabe
bleiben ausgeschlossen. Unicode- und 2.400-Zeichen-Grenzen bleiben erhalten.
Neue Flutter-/SQLite-Regressionen dokumentieren Neustart und Revisions-/
Regelzustandskontinuität. **Die vollständige CI dieses PR ist hier noch
nicht abgenommen.** SQLite 3 / JSON 1 und App-Version unverändert.


---

## Kampagnenkontext zum Fortsetzen (01.11.2026)

[Draft-PR #459](https://github.com/ManuEtt/Dnd/pull/459) stellt die
schreibgeschützte Story-API `CampaignResumeReader.read(campaign)` bereit:
letzte **erzählte** Szene (ausdrücklich kein bestätigter Regelzustand),
letzter explizit gespeicherter Rückblick (historischer Speicherstand),
aktuelle bestätigte Fakten und nur **aktuell offene** Handlungsstränge.
Jede Quelle erhält eine eigene Kennzeichnung; die Projektion ist begrenzt,
Unicode-/Bidi-bereinigt und unveränderlich. Verdeckte `storyBible`-Ziele,
Quest-/Inventar-/HP-Änderungen und externe KI-Anfragen sind ausgeschlossen.
Sechs neue Flutter-Regressionen einschließlich altem JSON und echtem
SQLite-Neustart wurden hinzugefügt. Noch **keine** UI-/KI-Anbindung und
**keine behauptete CI-Abnahme** für diesen PR; die GitHub-Gates sind zu prüfen.
App-Version, SQLite-Schema 3 und äußeres JSON-Schema 1 unverändert.


---

**Separates Fachpaket (01.11.2026, noch nicht in main):**
Der Branch `feat/chat-a/class-prepared-spell-record-20261101`
speichert eine ausdrücklich bestätigte Zaubervorbereitung
getrennt nach den beiden tatsächlich eigenen Klassen.
Die optionale, versionierte Bestätigung bleibt im bestehenden
Hero-JSON und dadurch beim SQLite-Neustart erhalten;
historische globale Listen bleiben ohne Klassenannahme
unverändert. Klassen-/Stufen-/Listenänderungen machen
die frühere Bestätigung ungültig, reine Ressourcenänderungen
nicht. Falsche Klassen, unbekannte SRD-Zauber, Dubletten
und individuell zu hohe Zaubergrade werden abgelehnt.
Neun Domain-/Alt-JSON-/SQLite-/Revisions-Testgruppen
wurden angelegt; CI auf finalem PR-Kopf prüfen.
Keine Migration (SQLite3/äußeresJSON1).
**Noch keine** automatische Zauberpreflight-Integration:
Der bestehende Preflight wird separat in offenem PR #461
bearbeitet. [Regelbeleg und Grenzen](docs/SRD_CLASS_PREPARED_SPELL_RECORD_20261101.md).

**Nächster Schritt:** den Nachweis nach Review des
PR #461 in dessen Vorprüfung nutzen und dort
Legacy-/Stale-/Revisionsfälle absichern.


---

## 01.11.2026 – Klassenprüfung vor Konzentrationswürfen

Entwicklungsstand **0.8.50+100**, Branch
`fix/chat-a/concentration-class-preflight-20261101`, Code/Test
`37604994828745ac44e48d8e2f628024f2f355e2`, Basis-Main `5a88834c`.
Die vorhandene Klassen-/Stufen-/Rettungswurf-Übungsprüfung wird jetzt auch vor
dem tatsächlichen Konzentrationswurf und vor einer separaten W20-Auflösung
verwendet. Unbekannte oder widersprüchliche Klassen gewähren keinen Mönchsbonus.
Der deutsche Schadensdialog zeigt den Fehler ohne Teiländerung; nach expliziter
Klassenkorrektur bleibt der normale Ablauf ausführbar. Alte Profile bleiben
lesbar, keine SQLite-/JSON-Migration. SG 10–30 war bereits zuvor umgesetzt.

**GETESTET:** 68 neue Tests (58 Domain, 8 Engine/SQLite, 2 echte UI-Flows) und
42 bestehende Regressionen: **110 gezielte Tests bestanden**, Analyzer sauber.
Die neuen Domänentests auf unverändertem Main: 25 bestanden / 33 fehlgeschlagen;
mit Fix alle 58 bestanden. **Vollständig lokal bestanden:** 2.778 Flutter-,
262 Python- und 76 Backend-Tests, 579 Dart-Dateien ohne Formatänderung,
Analyse/Backend-Typecheck/Build/Protokollsmoke. Zusätzlich ARM64-Debug-APK und
**13 native JUnit-Tests** ohne Fehler oder Skip. Zwei Android-Vorläufe scheiterten
am vollen Datenträger; nach Bereinigung ausschließlich erzeugter Caches bestand
die Wiederholung. Quellen, Spielstände und frühere Artefakte blieben erhalten.
[PR #468](https://github.com/ManuEtt/Dnd/pull/468) ist gesichert; vollständige finale
GitHub-CI auf seinem aktuellen Head separat abwarten. Kein Main-Merge behauptet.
**NICHT GETESTET:** echtes Androidgerät/TalkBack, installiertes Upgrade,
produktive Signierung. **NOCH NICHT IMPLEMENTIERT:** vollständige Konzentrations-
automation und Klassenprüfung aller allgemeinen Wiederholungswürfe.
[Fachbericht und Grenzen](docs/parallel/CHAT_A_CONCENTRATION_CLASS_PREFLIGHT_20261101.md).

Nächster Schritt nach Abnahme: allgemeine Klassen-Wiederholungen vor Würfel und
Ressourcenverbrauch auf dieselbe konsistente Klassenherkunft prüfen. Vorher
aktuelle PRs abgleichen; offene #453/#461/#463/#448 nicht erneut implementieren.
Die nachfolgenden früheren Entwicklungsstände sind historische Momentaufnahmen.

---


---

**Aktueller integrierter Stand, 02.11.2026 – 0.8.51+101:** Main
`2e920f222ab8fd501d9d90bff580d0f8ccc42ff1` aus #471 regulär in den eigenen
Entwicklungsbranch übernommen. Keine Quellkonflikte; die 51 Guardzeilen für
Klassenwiederholungen sind unverändert, gemeinsame Checkpoint-Ergänzungen erhalten.

**Kombiniert lokal bestanden:** 182 gezielte Flutter-Fälle einschließlich echter
App-/SQLite-Flows und neuer Main-Pakete, 275 Pythonfälle, 582 unverändert formatierte
Dartdateien, saubere Analyse, ARM64-Debug und 14 native JUnit-Tests. Die darunter
historisch dokumentierte vollständige Suite2782/262/76 gehört zum Vorgänger8dd.
Die vollständige kombinierte **[CI auf dem aktuellen PR-Head](https://github.com/ManuEtt/Dnd/pull/473/checks)**
ist noch abzunehmen; [PR #473](https://github.com/ManuEtt/Dnd/pull/473) bleibt Draft.
Aktueller Patch gegen Main2e9, alte geprüfte8dd-Archive bleiben erhalten.
Main nicht direkt verändert, SQLite3/JSON1 ohne Migration. Reales Gerät/TalkBack/
Upgrade/Produktivsignierung offen. Nächstes Paket bleibt der allgemeine initiale
manuelle Rettungswurf vor Klassenbonus/RNG; Gesamt-SRD/Charaktererstellung offen.

### Historische Abnahme vor Main2e9

**Lokale Vollabnahme – 02.11.2026, 0.8.51+101:** Klassenprüfung vor
bestätigten Rettungswurf-Wiederholungen ist auf Code-/Testcommit
`de8cef1bf9cd4cd67cfa7eb1916eec1b6b60f038` vollständig lokal geprüft.
**2.782 Flutter-, 262 Python- und 76 Backend-Tests**, 579 unverändert formatierte
Dartdateien, saubere Analyse, Backend-Typecheck/Build und lokaler Protokollsmoke
bestanden. Außerdem ARM64-Debug-Build und **13 native JUnit-Tests** bestanden.
72 neue Fälle, einschließlich zweier tatsächlicher App-UI-Flows, und 159 gezielte
Regressionen sind abgedeckt. Historische Profile, SQLite3 und JSON1 bleiben erhalten.

[PR #473](https://github.com/ManuEtt/Dnd/pull/473) ist ein eigener Draft; **[finale
PR-Checks](https://github.com/ManuEtt/Dnd/pull/473/checks)** sind noch separat
abzunehmen. Main unverändert. Der frühe Quellencheckpoint auf d5cf52f1 wurde mit
1.369 Dateien, tatsächlicher Patchanwendung und isolierter Bundle-Wiederherstellung
unabhängig geprüft; finaler Quellencheckpoint und optimierte Alpha folgen.
Vor PR 27 fremde PRs geprüft, einschließlich der neuen #469–#472; Fachdateien
konfliktfrei, gemeinsame Dokumentation/Requirements und Version101 bei der Integration
additiv konsolidieren. Reale Geräte-/TalkBack-/Upgrade-/Signierungsabnahme offen.

**Genau nächster Schritt:** allgemeine initiale manuelle Rettungswürfe vor
automatisch abgeleiteten Klassenboni und RNG validieren, ohne lesende Charakterbogen-
Vorschauen zu verändern. Zuerst neue PR-Dateilisten prüfen; gültige Aliase,
Mehrklassen, Ablehnung vor RNG und UI-/SQLite-/Retry-Fälle testen. Die vollständige
Charaktererstellung und das gesamte SRD bleiben offen.

### Historischer Frühcheckpoint vor lokaler Vollabnahme

**02.11.2026 – Alpha 0.8.51+101: Klassen vor Rettungswurf-Wiederholungen prüfen.**
Eigener Arbeitsbranch `fix/chat-a/saving-throw-class-preflight-20261102`, Basis-Main
`5a88834c98f5aca40395088c20c7e1dc5b587868`. Code-/Testcommit
`de8cef1bf9cd4cd67cfa7eb1916eec1b6b60f038` ist gesichert. Dies ist ein Frühcheckpoint vor
vollständiger Abnahme; Pull Request und aktuelle CI stehen aus. Main wurde
nicht verändert. Die frühere Migration und Issue #425 sind bereits abgeschlossen;
die darunter bewahrten Migrationseinträge sind historische Momentaufnahmen.

`SavingThrowClassActions` prüft vor einer ausdrücklich gewählten Mönch-14- oder
Kämpfer-9-Wiederholung bekannte Klassen, zulässige eigene Klassenstufen und
eindeutige Rettungswurfübungen. Ungültige Profile bieten keine Klassenwiederholung
an und werden vor Bonus, Ressourcenverbrauch und W20 abgewiesen. Die vorhandenen
Berechnungen und die deutsche UI-/Engine-/SQLite-Kette bleiben bestehen. Eine
abgewiesene Texteingabe wird weiterhin absichtlich als `rules.blocked` mit neuer
Revision protokolliert; Heldenwerte, Ressourcen und RNG bleiben dabei unverändert.

**Bisher bestanden:** 62 neue Domänen-, acht Engine-/SQLite- und zwei echte
App-UI-Tests, zusammen **72 neue Fälle**. **159 gezielte Regressionen** bestanden
(157 Domain-/Flowfälle plus zwei UI-Fälle). Lokaler ARM64-Debug-APK-Build bestanden.
Vollständiges `scripts/check.sh` und native Android-Tests laufen noch; ihre
Abschlüsse, optimierte Alpha und finale PR-CI sind noch kein Erfolgsnachweis.
SQLite **3** / äußeres JSON **1**, keine Migration oder stille Änderung alter
Profile. Beide betroffenen Klassen-Requirements bleiben **partial**. Allgemeine
Erstwürfe, vollständiger Charakterassistent und Gesamt-SRD sind nicht abgeschlossen.
Reales Gerät/TalkBack/Upgrade und produktive Signierung bleiben separate Abnahmen.

**Nächster konkreter Schritt nach Paketabnahme:** Allgemeinen initialen manuellen Rettungswurf vor automatisch abgeleiteten Klassenboni und W20 validieren; schreibfreie Charakterbogen-Vorschauen unverändert lassen. Zuerst frische Main-/PR-Dateilisten prüfen. Akzeptanz: unbekannte/inkonsistente Klassen vor Bonus/RNG ablehnen, gültige Aliase und Mehrklassen behalten dieselben Boni, Domain-, SQLite-/Retry- und tatsächliche UI-Regressionen bestehen.
[Fachnachweis](docs/parallel/CHAT_A_SAVING_THROW_CLASS_PREFLIGHT_20261102.md) ·
[aktueller Checkpoint](docs/parallel/CHAT_A_CHECKPOINT.md).

### Historischer Main- und Migrationsstand


---


 
---

## Gespeicherte NPC-Notiz-IDs vor Wiederaufnahme prüfen (03.11.2026)

[PR #516](https://github.com/ManuEtt/Dnd/pull/516) schließt eine
Lücke im bestätigten NPC-Gedächtnis: Selbst ältere gespeicherte Notizen,
die nicht in der begrenzten Vorschau erscheinen, müssen für den ausdrücklich
gewählten NPC eine eindeutige und gültige ASCII-Notiz-ID besitzen.
Doppelte, leere, zu lange oder formatierte Kennungen führen vor jeder
Kontextausgabe zu `FormatException`, einschließlich erneuter Abfrage nach
unbemerkten Änderungen bei identischer Kampagnenrevision.
Unabhängige NPC-Chroniken bleiben separat auswählbar.
Sechs neue Tests prüfen JSON, SQLite-Neustart, Negativfälle, Revisionsschutz
und reguläre positive Erinnerungen. Nur lesende Story-Projektion; keine
Kampagnen-, Regel-, SQLite-/JSON-Schema-, Wire- oder Versionsänderung.
**CI/Android-Abnahme auf dem finalen PR-HEAD steht noch aus.**


---

## Porträtauswahl für 200 % Schrift (03.11.2026)

[Draft-PR #529](https://github.com/ManuEtt/Dnd/pull/529) korrigiert die
untere Android-Aktionsleiste der Charakterporträt-Auswahl: Bei 200 %
Schriftgröße oder extrem schmalen Ansichten stehen „Abbrechen“ und
„Übernehmen“ jeweils über die volle Breite untereinander. Bei normaler
Schrift bleiben sie nebeneinander. Vier neue Flutter-Widgettests prüfen
320/360 dp mit simulierter IME, Touch-Erreichbarkeit, Auswahl-Semantik,
Abbruch ohne Rückgabe, bewusste Übernahme und den normalen Layoutpfad.
Regeln, Story, Spielstände, SQLite/JSON, Bilder, App-Version unverändert.
Vollständige CI auf finalem PR-HEAD und reale Android-/TalkBack-Abnahme
noch ausstehend; kein Auto-Merge.

---


---



### Regelengine: Unicode-Validierung von Konzentrations-Schadensquellen (03.11.2026)

Im [Draft-PR #530](https://github.com/ManuEtt/Dnd/pull/530) erweitert der PR ausschließlich die Quell-ID-Validierung in `app/lib/domain/srd_concentration_damage_rules.dart`: U+206A–U+206F und U+FFF9–U+FFFB können nicht mehr als unsichtbare Bestandteile bestätigter Konzentrationsschadensquellen verwendet werden. Zwei neue deterministische Testgruppen prüfen Fehl- und Gutfälle in `app/test/srd_concentration_damage_rules_test.dart`. Flutter-/Android-CI auf dem finalen PR-HEAD noch separat nachzuweisen; keine Datenmigration. Fachquelle: [D&D SRD 5.2.1, Concentration](https://www.dndbeyond.com/srd) (CC BY 4.0).


---


---

## NPC-Kurzchronik gegen ältere unsichtbare Unicode-Zeichen (03.11.2026)

[Draft-PR #531](https://github.com/ManuEtt/Dnd/pull/531) sichert die
schreibgeschützte bestätigte NPC-Kontinuitätsansicht gegen U+00AD, U+034F,
U+180E und U+206A–U+206F ab. Die Darstellung trennt oder vereinigt
unsichtbare Formatzeichen nach Feldtyp, nennt die gespeicherte NPC-ID und
übernimmt keine unbestätigte KI-Erzählung. Drei neue Flutter-Regressionstests
prüfen alle Zeichen, normale Akzente/Emoji und das Wiederöffnen einer SQLite-
Kampagne. Alte gespeicherte Originale, JSON/SQLite, Regelwerte, Backend,
Version 0.8.49+99 und vorhandene NPC-Auswahl bleiben unverändert.
Finale GitHub-CI und reale Geräteabnahme getrennt nachweisen; kein Auto-Merge.

---

## Vier Quellpakete koordiniert integriert (03.11.2026)

[Draft-PR #533](https://github.com/ManuEtt/Dnd/pull/533) bündelt die vier erfolgreich einzeln geprüften PRs #528–#531 als einen 14-Dateien-Integrationsstand auf Basis `main@fad366d7`. Der technische Integrationscommit vor diesem Nachtrag ist `9b759cd3`; Quell-Git-Blobs und Original-Historien sind erhalten, gemeinsame Checkpoints ausschließlich additiv konsolidiert. Die vollständige gemeinsame GitHub-CI auf dem **finalen** PR-HEAD und danach die neue Main-CI sind separate Freigaben, noch nicht als bestanden behauptet. Kein SQLite-/JSON-/Versionswechsel. Sichere Branch-Bereinigung erst nach geprüfter Main-Integration.


---

## Story-/Regelmodule vor verschachtelten Symlinks schützen (03.11.2026)

Die Python-Integritätsprüfung `scripts/check_domain_boundaries.py` weist jetzt auch symbolische Links innerhalb von `app/lib/story/` und `app/lib/domain/` zurück (Dateien und Unterordner), bevor externe Dart-Dateien gelesen werden. Drei ergänzende Python-Regressionen sichern verschachtelte Datei- und Verzeichnislinks sowie Nicht-Dart-Links ab. Die Änderung enthält keine Regel-/Story-/UI-Anpassung oder Speicherformatmigration. Separate Abnahme auf `fix/chat-d/domain-symlink-source-guard-20261103`; vollständige CI auf finalem Commit noch ausstehend.

---

---

## KI-Abenteuervorschläge ohne unsichtbare Formatzeichen (05.11.2026)

[Draft-PR #550](https://github.com/ManuEtt/Dnd/pull/550) schließt eine Vertrauenslücke in `AiStoryStep.fromJson`: optionale generierte Abenteuerangebote werden nach der bestehenden Domänenprüfung auch für alle vier nutzerseitigen Textfelder (`title`, `description`, `questTitle`, `questDescription`) auf Bidi-, Legacy- und Steuerzeichen geprüft. Normale Umlaute, Akzente, Emoji und Zeilenumbrüche bleiben zulässig. Vier neue Testgruppen prüfen 20 verbotene Kombinationen, gültige Angebote und den unveränderten Spielstand. Gespeicherte Angebote und JSON-/SQLite-Schema bleiben kompatibel; keine Regel- oder Queständerung. Finale CI ist gesondert zu prüfen.

---

## Alte unsichtbare Zeichen in bestätigten Ortsrückblicken (05.11.2026)

[Draft-PR #555](https://github.com/ManuEtt/Dnd/pull/555) erweitert die rein darstellende Ortsbereinigung um Soft Hyphen (U+00AD) und die sechs früheren Bidi-Formatsteuerzeichen U+206A–U+206F. Namen bleiben lesbar, Beschreibungen einzeilig; eine nur scheinbar andere Ortsbezeichnung erhält weiterhin ihre echte Orts-ID. Drei Flutter-Regressionsgruppen prüfen alle sieben Zeichen in beiden Textfeldern, gleiche sichtbare Namen mit unterschiedlichen IDs, veraltete Schnappschüsse trotz gleicher Revision sowie JSON-/SQLite-Neustart mit unveränderten Rohdaten. Keine Änderung an gespeichertem Ort, Schema, Quest, Regelwert oder Versionsnummer. Vollständige CI auf finalem Commit und Android-Realgerät werden gesondert abgenommen.

---

## Validierte Android-APK sicher in das Release übernehmen (05.11.2026)

Der Alpha-Release-Builder `scripts/prepare_alpha_release.py` bindet die Quell-APK jetzt beim Kopieren an die vor dem ZIP-Validierungslauf aufgezeichnete Identität (Gerät, Inode, Größe, Änderungs- und Statuszeit). Unter POSIX öffnet er außerdem jeden Quellpfad-Bestandteil ohne Verfolgung symbolischer Links und prüft die tatsächlich geöffnete APK vor und nach dem Kopieren. Eine spät eingefügte symbolische Datei/ein Elternordnerlink oder der Austausch gegen eine andere reguläre APK kann so keine fremde, unvalidierte Installationsdatei in ein fertiges Release schleusen. Drei zusätzliche Regressionen sichern die Austauschzeitfenster ab; der normale APK-Releasefall bleibt bestehen. [Draft-PR #552](https://github.com/ManuEtt/Dnd/pull/552), Fach-/Testcommit `333d00776672`; vollständige CI auf dem finalen Head noch offen. Keine Änderung an SQLite-/JSON-Spielständen, App-Version oder Release-Namen.

---

## Gradle-Kommentare mit Backslash verdecken keine Folgewerte (05.11.2026)

Die Python-Uploadprüfung erkennt jetzt, dass Java `Properties.load` **Kommentarzeilen niemals durch einen abschließenden Backslash fortsetzt**. Bisher konnte eine auf `# ignored \\` oder `! ignored \\` endende Zeile den nächsten tatsächlichen `distributionUrl`- oder `distributionSha256Sum`-Eintrag bei der Duplikatprüfung verschlucken. Die Kontrolle behandelt `#`/`!`-Kommentarzeilen jetzt vor dem Fortsetzungsmechanismus; echte, nicht kommentierte Java-Properties-Fortsetzungen bleiben erlaubt. Vier Regressionstestmethoden decken 23 CR/LF/CRLF-, Duplikat- und Kompatibilitätsfälle ab. OpenJDK 21 bestätigt die Kommentarsemantik direkt. [Draft-PR #547](https://github.com/ManuEtt/Dnd/pull/547) auf `fix/chat-d/gradle-comments-continuation-20261105`, Code-/Test-HEAD `9a88f16448b2`, finale GitHub-CI noch nicht vollständig abgenommen. Keine Migration, keine Änderung an SQLite-/JSON-Spielständen oder der App-Version.

---

## Checkpoint-Dateien gegen spätes Überschreiben schützen (05.11.2026)

Das Quellcode-Checkpoint-Skript `scripts/create_checkpoint.py` prüft identische Version-/Zeitstempel-/Label-Artefakte jetzt nicht nur vor der aufwendigen Vorbereitung, sondern nochmals unter der exklusiven Veröffentlichungssperre unmittelbar vor der eigentlichen Ausgabe. Dadurch kann ein konkurrierender Lauf nach der frühen Prüfung keine gleichnamigen, bereits veröffentlichten ZIP-/Patch-/Manifest-/Prüfsummendateien mehr unbemerkt ersetzen. Hängende Symlinks zählen ebenfalls als belegte Namen. Zwei neue Regressionen in `scripts/tests/test_create_checkpoint.py` decken spätes Auftauchen einer Archivdatei und eines hängenden Manifest-Symlinks ab. [Draft-PR #544](https://github.com/ManuEtt/Dnd/pull/544), Basis `74548d3d5243`, Fachcommit `021672463075`. Vollständige Actions-CI auf dem finalen dokumentierten HEAD noch ausstehend. SQLite/JSON, Speicherformate, App-Version und bestehende Aliasse bleiben unverändert.

---

## Fachübergreifende Integration und CI-Bereinigung (04.11.2026)

Die Fachbeiträge [#535](https://github.com/ManuEtt/Dnd/pull/535) bis [#539](https://github.com/ManuEtt/Dnd/pull/539) werden im Integrationsbranch `fix/chat-d/branch-migration-actions-20261104` unter Erhalt ihrer Commit-Historien zusammengeführt. Die Android-Alpha-ABIs und der Quellcode-Checkpoint sollen auf getrennten GitHub-Actions-Runnern geprüft werden. Historische Zusatz-Workflows werden entfernt; `main` bleibt bis zur vollständigen Integrations-CI unverändert. Details: [Integrationsbericht](docs/parallel/INTEGRATION_20261104.md). Keine SQLite-/JSON-Schema- oder App-Versionsänderung.

---

<!-- Originalbeitrag aus PR #535 -->
## EP-Fortschritt mit Screenreader im Kampagnen-Dashboard (04.11.2026)

Der bestätigte EP-Fortschrittsbalken der aktiven Heldenkarte kündigt jetzt
„Erfahrungsfortschritt: N Prozent“ an und vermeidet eine doppelte technische
Balkenansage. Der Wert wird aus der bestehenden EP-Berechnung übernommen;
unbestätigte Werte bleiben ausdrücklich unbekannt. Drei Widgettests prüfen
320/360 dp mit 200 % Schrift, simulierter Android-Tastatur, korrekte
Semantik, bedienbare Aktionen und unveränderte gespeicherte Heldenwerte.
Branch `feat/chat-c/campaign-xp-progress-semantics-20261104`;
[Draft-PR #535](https://github.com/ManuEtt/Dnd/pull/535). Die gezielte Flutter-CI [#41776172261](https://github.com/ManuEtt/Dnd/actions/runs/41776172261) bestand 11 Tests; die neue vollständige GitHub-CI
und eine echte Android-/TalkBack-Abnahme sind noch ausstehend.
Keine Änderungen an Spielregeln, SQLite/JSON, App-Version oder Assets.

---

---

<!-- Originalbeitrag aus PR #536 -->
---

## Doppelte Handlungsstrang-IDs bei Kampagnenwiederaufnahme (04.11.2026)

[Draft-PR #536](https://github.com/ManuEtt/Dnd/pull/536) verhindert,
dass ungeprüfte In-Memory-StoryThreads mit mehrfach belegten IDs und
widersprüchlichen Stati einen bereits geschlossenen Strang erneut als
„aktuell offen“ darstellen. Reguläre JSON-Importe weisen solche Dubletten
bereits zurück. `CampaignResumeReader` übernimmt nur eindeutige
sichere IDs, erhält die zuletzt gespeicherte Reihenfolge und begrenzt die
Anzeige unverändert. Vier neue Flutter-Regressionstests decken mehrdeutige
IDs, ungültige Identitäten, Reihenfolge/Limit, JSON-Importabwehr bei
Dubletten und SQLite-Neustart mit gültigen IDs ab. Keine Regel-/Event-/Quest-, Datenbank- oder App-Versionsänderung.
Die vollständige CI auf dem finalen PR-HEAD und Geräteabnahme bleiben
gesonderte Freigabegates.

---

<!-- Originalbeitrag aus PR #537 -->
## Java-konforme Whitespace-Prüfung der Gradle-Wrapper-Werte (04.11.2026)

Die Übertragungsprüfung `scripts/verify_project.py` validiert `distributionUrl` und `distributionSha256Sum` jetzt ohne das bisherige `strip()` auf den Property-Werten: Java `Properties.load()` ignoriert nur führende ASCII-SP/Tab/FF, bewahrt aber abschließende Leerzeichen und nicht-ASCII-Leerzeichen. Der Parser darf diese ungültigen Werte nicht nachträglich als gültige URL/SHA maskieren. Drei neue Python-Regressionsmethoden in `scripts/tests/test_verify_project.py` prüfen insgesamt 22 Negativ- und Kompatibilitätsvarianten. Java 21 hat das zugrunde liegende Parse-Verhalten in einem isolierten Minimalversuch bestätigt. [Draft-PR #537](https://github.com/ManuEtt/Dnd/pull/537), Fachcommit `15304e04861a`; vollständige Projekt-/CI-Tests für den finalen HEAD sind noch offen. Keine Änderung an Gradle-Distribution, SQLite/JSON, vorhandenen Spielständen oder App-Version.

---

---

<!-- Originalbeitrag aus PR #538 -->
### 04.11.2026 – Waldläufer-Unermüdlich mit bestätigtem Klassenprofil
[PR #538](https://github.com/ManuEtt/Dnd/pull/538) validiert vor der SRD-5.2.1-Waldläuferfähigkeit *Unermüdlich / Tireless* (Klassenstufe 10) die gesamte Klassenkombination, darunter gültige Aliase, unterschiedliche Mehrklassen und konsistente Stufen. Ungültige Profile werden ohne Würfelwurf, Nutzungsverbrauch oder Erschöpfungsreduktion abgewiesen. Ein neuer deterministischer Domain-Test deckt negative und positive Fälle ab; bestehende SQLite-/JSON-Spielstände und öffentliche APIs bleiben unverändert. Vollständige GitHub-CI und APK auf dem finalen PR-HEAD noch gesondert zu bestätigen. Quelle: [SRD v5.2.1](https://www.dndbeyond.com/srd), CC BY 4.0.

---

<!-- Originalbeitrag aus PR #539 -->
## Hexenmeister-Magische-List: konsistente Klassenprofile (04.11.2026)

[Draft-PR #539](https://github.com/ManuEtt/Dnd/pull/539) schützt die SRD-5.2.1-Fähigkeiten `Magical Cunning` (Hexenmeister 2) und `Eldritch Master` (Hexenmeister 20) vor unberechtigten Paktplatz-Regenerationen aus inkonsistenten direkt erzeugten bzw. historischen Klassenprofilen. Unbekannte, doppelte oder unplausibel gestufte Klassenkombinationen liefern lesend null Nutzungen und scheitern beim ausdrücklich abgeschlossenen Ritual vor jedem Ressourcenverbrauch mit `FormatException`. Bestätigte deutsche/englische Aliase und Kämpfer-/Hexenmeister-Mehrklassen bleiben zugelassen. **Zwölf neue deterministische Testfälle**: neun ungültige Profile und drei Positiv-/Grenzfälle. Getestete CI auf finalem PR-Commit und Android-Debug-APK stehen zur Überprüfung aus; lokal kein Dart-/Flutter-SDK. Klassen-/Paktlogik außerhalb dieses spezialisierten Moduls, Story, UI und Datenformate unverändert; SQLite 3 und JSON 1 ohne Migration. SRD 5.2.1 CC BY 4.0; Requirement `CLASS-HEXENMEISTER-2-BASE-MAGICAL-CUNNING-0` bleibt `partial` (keine echte Ritual-Uhr/Unterbrechungsbestätigung). Basis-main `c8f25132`, Code-/Testcommit `86c83b5c`; gemeinsame Dokumentation wird durch  additiv integriert.

---

---

## Korrekte Java-Properties-Zeilentrennung bei Gradle-Uploadprüfung (03.11.2026)

Die Python-Übertragungsprüfung `scripts/verify_project.py` wertet physische Zeilen der Gradle-Wrapper-Konfiguration nun wie Java Properties ausschließlich an CR/LF/CRLF aus. Unicode-Zeichen U+0085, vertikaler Tab und U+2028/U+2029 innerhalb eines Kommentars erzeugen keine vorgetäuschten gültigen `distributionUrl`- oder `distributionSha256Sum`-Einträge und keine fälschlichen Doppelbelegungen mehr. Drei Regressionstest-Gruppen in `scripts/tests/test_verify_project.py` decken fehlende Pflichtwerte, erlaubte Kommentarinhalte und echte Zeilenenden ab. Separater Draft-[PR #528](https://github.com/ManuEtt/Dnd/pull/528), Basis `7be2135`, Fachcommit `ab0a8c8`. **Vollständige CI auf ursprünglichem PR-HEAD `1e04364` erfolgreich:** [Run 41713843451](https://github.com/ManuEtt/Dnd/actions/runs/41713843451). Auf dem konsolidierten Integrations-HEAD ist erneut eine vollständige CI erforderlich. Keine SQLite-/JSON-/Versionsmigration.


---

## JSON-Spielstandimport auf 10 MiB UTF-8 begrenzen (02.11.2026)

[PR #502](https://github.com/ManuEtt/Dnd/pull/502) prüft in der bestehenden
SQLite-Importgrenze nun die tatsächlichen UTF-8-Bytes statt ausschließlich
Darts UTF-16-`String.length`. Die billige Zeichenlängenprüfung bleibt vor
der Bytezählung erhalten. Zwei SQLite-FFI-Regressionstests schützen die
Ablehnung eines mehrbyteigen Übergrößenimports ohne Datenbankänderungen und
den regulären Unicode-Roundtrip. SQLite 3, JSON-Format 1, App-Version,
vorhandene Spielstände und Exportformat bleiben unverändert.
Flutter-/Android-Build und CI auf dem finalen PR-HEAD müssen noch bestätigt
werden; kein Realgerätetest behauptet.

---


## Mehrgegner-Initiative bei 200 % Schrift und IME (02.11.2026)

[Draft-PR #488](https://github.com/ManuEtt/Dnd/pull/488) verbessert den
unabhängigen `TrackedCreatureInitiativeDialog`: Der gesamte Dialog scrollt
ohne verschachtelte Scrollflächen, Bestätigungen bleiben auf schmalen
Android-Displays bedienbar, die ursprünglichen ausführlichen
Screenreader-Texte bleiben trotz kürzerer sichtbarer Labels erhalten.
Fünf Widgettests prüfen 320/360 dp bei 200 % Schrift und 220 dp
Tastatureinblendung einschließlich Abbruch, unvollständiger/ungültiger
Initiative und rein unverbindlicher Auswahl. Keine Kampfregel-, 
SQLite-/JSON-, Spielstands- oder Versionsänderungen. Vollständige CI
auf dem finalen PR-HEAD und reale TalkBack-/IME-Geräteprüfung noch offen;
keine automatische Mergefreigabe.

---

---

## Portable APK-ZIP-Pfade vor Alpha-Veröffentlichung prüfen (05.11.2026)

[Draft-PR #563](https://github.com/ManuEtt/Dnd/pull/563) weist innerhalb der ARM64-APK-Prüfung jetzt ZIP-Mitgliedsnamen zurück, deren Datei- oder Verzeichnisbestandteile mit Punkt oder Leerzeichen enden. Diese können auf Windows-kompatiblen Dateisystemen beim Entpacken mit anderen Namen kollidieren. Sechs negative Pfadvarianten, ein gültiger Pfad mit innerem Punkt/Leerzeichen und ein Release-Abbruchtest sichern die Vorabprüfung vor ZIP-CRC und Veröffentlichung ab. Keine SQLite-/JSON-/Spielstands- oder Android-Versionsänderung. Die vollständige GitHub-CI auf dem finalen PR-HEAD ist getrennt abzunehmen; die erfolgreiche Main-CI [#42053653539](https://github.com/ManuEtt/Dnd/actions/runs/42053653539) beweist diese neue Änderung noch nicht.

---

---

## 05.11.2026 – Projekt-README und Änderungsprotokoll vereinheitlicht

Die README bleibt die sachliche Einstiegsseite für die Android-Fantasy-App, Regelengine, Speicherung, optionalen Erzähler und Projektprüfungen. Im historischen Entwicklungsprotokoll wurden lesbare Chat-Zuordnungen durch fachliche Änderungstitel ersetzt. Technische Branch-Namen, Checkpoint-Pfade, PR-Links, Testergebnisse und die vorhandene Historie bleiben als Nachweise erhalten.

Der Masterprompt verlangt für künftige Änderungen **ausschließlich neue, sachlich benannte Nachträge am absoluten Ende der README** – ohne Chat-Kennungen und ohne Änderungen an den vorderen Projektabschnitten. App-Quellcode, Backend, Spielstände und Versionen sind davon nicht betroffen.
