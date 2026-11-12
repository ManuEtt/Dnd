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

---

## GitHub-Actions-Cleanup auf Node.js 24 aktualisiert (05.11.2026)

[Draft-PR #571](https://github.com/ManuEtt/Dnd/pull/571) stellt ausschließlich den aktiven archivierenden Branch-Cleanup in `.github/workflows/cleanup-merged-safe-20261027.yml` von `actions/github-script@v7` auf `@v8` um. GitHub hat die Ausführung von JavaScript-Actions auf Node.js 24 umgestellt; v8 unterstützt diese Laufzeit und benötigt GitHub Actions Runner 2.327.1 oder neuer. Drei neue Python-Regressionstests in `scripts/tests/test_cleanup_github_script_runtime.py` verhindern einen Rückfall auf v7, fehlende oder doppelte Einstiegspunkte und das irrtümliche Zählen von Kommentaren als Action-Steps. Die bestehenden SHA-, Vorfahren-, Archivtag-, Schutzbranch- und erfolgreiches-Main-CI-Gates bleiben unverändert. **CI des finalen PR-HEADs steht noch aus; der Workflow wurde nicht manuell ausgelöst.** Keine Android-App-, SQLite-/JSON-, Spielstands- oder Versionsänderung.

---

### 2026-11-05 – Zusammenführung der 21 offenen Entwicklungs-PRs

Die folgenden fachlichen Korrekturen, Tests und Build-Anpassungen wurden in einem separaten Integrationsbranch verlustarm zusammengetragen. Die Original-Commits sind über reguläre Merge-Eltern erreichbar. Dieser Nachtrag bestätigt **noch keinen Merge nach `main` und keinen erfolgreichen kombinierten CI-Durchlauf**.

- [PR #543](https://github.com/ManuEtt/Dnd/pull/543): fix(): Paktmagie-Slots nur aus konsistenten SRD-Klassenprofilen.
- [PR #545](https://github.com/ManuEtt/Dnd/pull/545): feat(): Kampagnenrückblick gegen veraltete Storyquellen absichern.
- [PR #546](https://github.com/ManuEtt/Dnd/pull/546): fix(): gleichnamige Orte im bestätigten Langzeitgedächtnis unterscheiden.
- [PR #548](https://github.com/ManuEtt/Dnd/pull/548): feat(): gespeicherte Klassen-Zaubervorbereitung im SRD-Preflight prüfen.
- [PR #549](https://github.com/ManuEtt/Dnd/pull/549): fix(): Fertigkeitensuche über Android-Tastatur halten.
- [PR #551](https://github.com/ManuEtt/Dnd/pull/551): feat(): bestätigte Mehrklassen-Zauberquelle bis zum Turn-Staging weiterreichen.
- [PR #554](https://github.com/ManuEtt/Dnd/pull/554): fix(): Zauber- und Paktverbrauch vor langer Rast validieren (sauberer CI-Branch).
- [PR #556](https://github.com/ManuEtt/Dnd/pull/556): fix(): Outbox-Fehler für TalkBack als Live-Meldung markieren.
- [PR #557](https://github.com/ManuEtt/Dnd/pull/557): fix(): erste manuelle Rettungswürfe vor Klassenbonus und W20 validieren.
- [PR #560](https://github.com/ManuEtt/Dnd/pull/560): fix(): freie KI-Erzählungen gegen unsichtbare Unicode-Steuerzeichen schützen.
- [PR #561](https://github.com/ManuEtt/Dnd/pull/561): fix(): Zweite Luft und Aktionsschub nur mit gültigem Kämpfer-Klassenprofil.
- [PR #564](https://github.com/ManuEtt/Dnd/pull/564): fix(): Zauberkraftregeneration nur bei gültigem Zauberer-Klassenprofil.
- [PR #565](https://github.com/ManuEtt/Dnd/pull/565): fix(): ältere Unicode-Formatzeichen in bestätigten NPC-Rückblicken absichern.
- [PR #566](https://github.com/ManuEtt/Dnd/pull/566): fix(): Materialauswahl gegen doppelte und ungültige Inventar-IDs absichern.
- [PR #567](https://github.com/ManuEtt/Dnd/pull/567): fix(): Gradle-Wrapper-JAR gegen nicht portable ZIP-Pfadnamen absichern.
- [PR #568](https://github.com/ManuEtt/Dnd/pull/568): fix(): Entrinnen nur mit konsistentem Mönch-/Schurken-Klassenprofil.
- [PR #569](https://github.com/ManuEtt/Dnd/pull/569): fix(): NPC-Erzählergedächtnis gegen ältere unsichtbare Unicode-Zeichen absichern.
- [PR #570](https://github.com/ManuEtt/Dnd/pull/570): fix(): JSON-Importdialog bei großer Schrift und Android-Tastatur bedienbar halten.
- [PR #573](https://github.com/ManuEtt/Dnd/pull/573): fix(): Windows-Gerätenamen in Alpha-APK-ZIP-Pfaden abweisen.
- [PR #575](https://github.com/ManuEtt/Dnd/pull/575): ci: Android-Alpha-Buildaktionen auf Node.js 24 aktualisieren.
- [PR #576](https://github.com/ManuEtt/Dnd/pull/576): Überlegene Inspiration nur mit konsistenten Barden-Klassenstufen.

Integration: `integration/open-prs-20261105-reviewed`, ausgehend von `main` `7b76d34e42f9f536993035876f8789d3405d70f9`. Beide getrennten SRD-Requirements-Änderungen sind in gültigem JSON erhalten. Drei fachlich ersetzte Diagnose-/Vorgängerbranches wurden über die Git-Historie gesichert; der eigentliche Produktcode ihrer nachfolgenden PRs ist maßgeblich.

Verifizierung: Vorherige Main-CI [#42072388815](https://github.com/ManuEtt/Dnd/actions/runs/42072388815) erfolgreich. Die Einzel-PRs besitzen eigene Testergebnisse; der **neue gemeinsame Stand muss noch durch GitHub Actions geprüft werden**. Gemeinsame CI, `main`-Merge, Archiv-Tags, Branchlöschungen und ein abschließender Issue-Nachweis bleiben bis zur tatsächlichen Ausführung offen. Details und alle Original-SHAs: [`docs/parallel/ALL_BRANCHES_MIGRATION_20261105.md`](docs/parallel/ALL_BRANCHES_MIGRATION_20261105.md).

### 2026-11-05 – Konsistente Node-24-Actions in allen aktiven Workflows

Die Android-Pipeline, die spezialisierten Regeltests, die manuelle Dart-Formatierungsreparatur und die sichere Altbranch-Bereinigung verwenden jetzt kompatible Action-Runtimes. Alle direkten First-Party-Aufrufe nutzen je nach Action `checkout@v6`, `setup-java@v6`, `setup-node@v6`, `upload-artifact@v6`, `download-artifact@v7` und `github-script@v8`. Die zwei Android-SDK-Setups wurden von `android-actions/setup-android@v3` auf `v4` angehoben, während die expliziten SDK-Werkzeug-/Paket-Pins unverändert blieben. Die Flutter-Composite-Action bleibt auf ihrem bestehenden kompatiblen Release.

Regressionen gegen Downgrades: `scripts/tests/test_android_actions_node24.py` und `scripts/tests/test_first_party_actions_node24.py`. Vorherige Projekt-Toolchains, Buildmatrix, APK-Dateinamen, Release-Archivierung und Cleanup-Ancestry-Schutz werden nicht bewusst verändert. Integrations-PR: [#577](https://github.com/ManuEtt/Dnd/pull/577). Die kombinierte CI des finalen Heads und die Main-/Geräteabnahme bleiben bis zur tatsächlichen Prüfung offen.



### 2026-11-05 – Unbezwingbare Stärke: gültige Klassenprofile

Der Mindestwert für Stärkeproben und Stärkerettungswürfe ab Barbarenstufe 18 wird bei widersprüchlichen Haupt-/Nebenklassen, doppelten Alias-Klassen, ungültigen Stufen oder unbekannten Klassen nicht mehr freigeschaltet. Gültige deutsche/englische Aliase und Mehrklassenprofile bleiben unterstützt. Betroffen: `srd_indomitable_might_rules.dart` und neue deterministische Profiltests. Branch `feat/chat-a/indomitable-might-class-preflight-20261105`; PR/CI siehe GitHub. Kein JSON-/SQLite-Schemawechsel und keine Migration. SRD 5.2.1, Barbarian 18 / Indomitable Might, CC BY 4.0.

### 2026-11-05 – Portable ZIP-Namen in Release-APK und Gradle-Wrapper

Release-APKs und die im Android-Upload enthaltene Gradle-Wrapper-JAR werden auf Windows-inkompatible ZIP-Dateinamen geprüft. Zeichen wie `:`, `?`, `*`, `|`, `<` oder `>` werden unabhängig von Datei- oder Verzeichnisposition vor ZIP-CRC zurückgewiesen. In der Wrapper-JAR gilt der Schutz zusätzlich für reservierte Gerätenamen wie `CON.txt`, `NUL` und `COM1.dll`. Die bereits vorhandenen zentralen Zeichen-/Namenslisten aus dem Quellarchiv-Prüfer werden verwendet.

**Implementierung:** `scripts/prepare_alpha_release.py` und `scripts/verify_project.py` mit sechs neuen Regressionstestmethoden in den bestehenden Python-Tests. Sie prüfen 21 unzulässige APK-Mitglieder, 21 unzulässige Wrapper-Mitglieder, elf Gerätebasen im Wrapper, gültige Interpunktion/Unicode, unveränderte JAR-Quelldateien und Release-Abbruch ohne Artefakte.

**GitHub:** Branch `fix/chat-d/archive-windows-invalid-chars-20261105`, [PR #584](https://github.com/ManuEtt/Dnd/pull/584). Die vollständige CI des finalen Dokumentations-HEADs steht zum Zeitpunkt dieses Eintrags noch aus; ein lokaler Kompletttest wurde nicht durchgeführt.

**Kompatibilität und Grenzen:** Keine SQLite-/JSON-/Backup-/Spielstands-, Gradle-, Android-Versions- oder SRD-Regeländerung. Realgerätetest und produktive Signierung sind separat offen.

### 2026-11-06 – Checkpoint-Dateinamen plattformübergreifend absichern

Beim Erstellen von vollständigen Quellcode-Checkpoints gelten für Manifest- und Patchpfade, Archivnamen sowie historische Prüfsummen-Einträge jetzt die gleichen Portabilitätsregeln wie beim Quell-ZIP-Export. Reservierte Windows-Gerätenamen (`CON`, `NUL`, `COM1` usw.), abschließende Punkte/Leerzeichen und Windows-unzulässige Zeichen werden vor dem Lesen bzw. Veröffentlichen von Sicherungen zurückgewiesen. Gültige internationale Zeichen und übliche Interpunktion bleiben erlaubt.

**Umsetzung:** `scripts/create_checkpoint.py` verwendet die bestehenden zentralen Namenskonstanten aus `scripts/package_project.py`. Vier Regressionstests in `scripts/tests/test_create_checkpoint.py` sichern problematische und gültige Namen, Prüfungen vor Archivdatenlesen, Veröffentlichungssperren und den unveränderten Bestand bereits veröffentlichter `LATEST`-/Prüfsummen-Dateien ab.

**GitHub:** Branch `fix/chat-d/checkpoint-portable-filenames-20261106`, [PR #587](https://github.com/ManuEtt/Dnd/pull/587). Die vollständige CI des finalen Commits steht noch aus; ein lokaler Kompletttest wurde nicht behauptet.

**Kompatibilität:** Keine Migration, keine Änderungen an SQLite-/JSON-Spielständen, tatsächlichen Backup-Dateiinhalten, Flutter- oder Android-Version, Regel- und Storylogik. Reale Geräteabnahme und produktive Signierung bleiben separat offen.

### 2026-11-06 – Alpha-Release-Dateien vor nachträglichen Kollisionen schützen

Die Alpha-Release-Veröffentlichung legt APK, Release-Notizen und SHA256-Prüfsummen jetzt ausschließlich als neue Dateien an. Treten nach der anfänglichen Versions-/Dateiprüfung zusätzliche Zieldateien oder symbolische Links auf, wird der Lauf abgebrochen statt fremde Inhalte zu überschreiben. Bei Fehlern werden nur die von diesem Lauf erzeugten Ausgaben entfernt; vorhandene fremde Dateien und deren Linkziele bleiben unverändert. Die Version-Sperre und die Validierung der APK-Quelldatei bestehen weiterhin.

**Implementierung und Nachweis:** `scripts/prepare_alpha_release.py`; drei neue Python-Regressionen in `scripts/tests/test_prepare_alpha_release.py` für eine spät eingefügte APK-Verknüpfung, eine reguläre fremde Notizdatei und eine SHA256-Verknüpfung. Branch `fix/chat-d/alpha-release-exclusive-output-20261106`, [PR #599](https://github.com/ManuEtt/Dnd/pull/599) (Draft). Der vollständige GitHub-Actions-Nachweis auf dem finalen PR-HEAD steht noch aus; kein lokaler Kompletttest, kein automatischer Merge.

**Kompatibilität:** Keine Änderungen an App-/Android-Version, Flutter-/Story-/Regelmodulen, bestehenden Spielständen, SQLite, JSON oder Backup-Format. Keine Migration. Geräteprüfung und produktive Signierung sind gesondert offen.

### 2026-11-06 – Besitzprüfung geöffneter Alpha-Release-Artefakte

Nach der exklusiven Dateierstellung wird nun zusätzlich die Identität der tatsächlich geöffneten Release-Zieldateien geprüft. Wird ein APK-Ziel, eine Notizdatei oder eine Prüfsummendatei während oder nach dem Schreiben durch einen fremden Eintrag ersetzt, bricht die Veröffentlichung ab; der Rollback entfernt nur weiterhin eigene reguläre Dateien. Auch vor und nach den abschließenden Archiv-/APK-Prüfungen werden die erwarteten Dateiidentitäten abgeglichen.

**Code und Regressionen:** `scripts/prepare_alpha_release.py` und `scripts/tests/test_prepare_alpha_release.py` mit vier neuen Fehlerfällen für Austausch während des APK-Kopierens, nach dem Schreiben von Notizen/Prüfsummen und nach gültiger APK-Validierung. Branch `fix/chat-d/release-target-identity-20261106`, [PR #604](https://github.com/ManuEtt/Dnd/pull/604) (Draft). Die vollständige CI auf finalem Dokumentations-HEAD steht noch aus; kein lokaler Kompletttest. Der grüne CI-Nachweis von Vorgänger-PR #599 gilt ausschließlich für dessen Code.

**Kompatibilität und Grenzen:** Kein Schema-/Formatwechsel für Spielstände, SQLite, JSON oder Backup, keine App-/Android-Version, keine Änderungen an Regeln, Story oder Flutter. Keine Migration. Aktive Manipulation eines fremd beschreibbaren Release-Verzeichnisses nach dem letzten Verifikationstakt bleibt außerhalb einer garantierten Race-free-Sicherheitsgrenze; Release-Verzeichnisse müssen geschützt bleiben. Echte Geräteabnahme und produktive Signierung sind getrennt offen.

### 2026-11-06 – Release-Artefakte vor Freigabe inhaltlich erneut prüfen

Die Alpha-Release-Erstellung kontrolliert jetzt zusätzlich zum Dateibesitz die **tatsächlichen Inhalte** der erzeugten Dateien vor dem erfolgreichen Abschluss. Ein gültiges ZIP oder eine unveränderte Dateikennung allein reichen nicht aus: Quell-ZIP, validierte und veröffentlichte ARM64-APK sowie Release-Notizen werden erneut mit den zuvor festgehaltenen SHA256-Digests verglichen. Auch die exakten Einträge des Release-Prüfsummen-Manifests und des Quell-ZIP-Sidecars werden geprüft. Bei Abweichungen wird abgebrochen und nur die weiterhin zu dieser Veröffentlichung gehörende Ausgabe bereinigt.

**Code und Nachweise:** `scripts/prepare_alpha_release.py` und `scripts/tests/test_prepare_alpha_release.py` mit sechs neuen positiven/negativen Regressionstests für gültige Hashlisten, im selben Inode veränderte weiterhin ZIP-gültige Dateien sowie manipulierte Notizen und Prüfsummen. Branch `fix/chat-d/release-final-checksums-20261106`, [PR #606](https://github.com/ManuEtt/Dnd/pull/606) (Draft, finale CI-Abnahme ausstehend). Separate GitHub-Actions-Ergebnisse gelten nur für den jeweils geprüften Commit; ein lokaler Kompletttest wurde nicht durchgeführt.

**Kompatibilität und Grenzen:** Keine Änderung von SQLite-/JSON-Spielständen, Backups, Flutter, Android-Build-/Versionsnummern, Story oder Regeln; keine Migration. Die abschließende Inhaltsprüfung ist keine Garantie gegen aktive Manipulation nach dem letzten Prüfzeitpunkt. Realgeräteabnahme und produktive Signierung sind weiterhin getrennt offen.

### 2026-11-06 – Zielaustausch vor Inhaltsdrift melden

Bei der abschließenden Alpha-Release-Prüfung hat die unveränderte Priorität des Dateibesitzschutzes Vorrang vor der neuen Inhaltsprüfung: Wird eine geöffnete Zieldatei durch eine andere reguläre Datei ersetzt, meldet die Prüfung den **Zielaustausch** und bewahrt den fremden Inhalt. Nur bei unveränderter Dateiidentität folgt die zusätzliche SHA256-Inhaltsprüfung. Damit bleiben ältere Regressionstests und die neue Erkennung stiller In-Place-Manipulation zugleich wirksam.

**Fehlerbehebung:** Commit `52280992156bbb5f92c351497d6ec9e49ccb8310` in [PR #606](https://github.com/ManuEtt/Dnd/pull/606). Der erste vollständige Lauf [#42194379586](https://github.com/ManuEtt/Dnd/actions/runs/42194379586) scheiterte in einem vorhandenen Python-Negativtest ausschließlich an einer anderen Fehlerklasse/Fehlermeldung; die Reihenfolge wurde korrigiert, kein Test entfernt. Eine erneute vollständige CI auf dem finalen Dokumentations-HEAD bleibt erforderlich. Keine Migration und keine Änderungen an Spielständen, JSON, SQLite, Story, Regeln oder Android-Version.


### 2026-11-06 – Android-SDK-Bereinigung auf reale SDK-Verzeichnisse begrenzen

**Problem und Lösung:** Der Android-CI-Installer akzeptierte syntaktisch absolute SDK-Wurzeln wie `/..` oder einen Symlink auf `/`, obwohl Wiederholungsversuche anschließend mit `rm -rf` Cache-/NDK-Unterordner entfernen. `scripts/install_android_sdk_packages.sh` löst den SDK-Pfad nun vor `sdkmanager` physisch auf, lehnt Root-Aliasse und nicht vorhandene SDK-Verzeichnisse ab und verwendet für die Bereinigung den kanonischen Pfad. Gültige SDK-Installationen und die bestehende Retry-/NDK-Schutzlogik bleiben erhalten.

**Nachweis:** Fachcommit `e363c7c04c71ccf497bfd124ae86fcb14ec4cdfc`, Testcommit `3508f83cae8e7a5bfb2297ab980cfa467ab10ca2`; Branch `fix/chat-d/android-sdk-root-canonical-20261106`; [PR #613](https://github.com/ManuEtt/Dnd/pull/613) (Draft; nicht integriert). Erweitert wurden `scripts/tests/test_install_android_sdk_packages.py` um negative Root-/Symlink-/Fehlpfadfälle und einen positiven kanonischen SDK-Pfadfall. Lokal bestanden `bash -n` und fünf isolierte Mock-Proben der identischen Shell-Logik; das vollständige Repository konnte wegen DNS-bedingt fehlendem Checkout **nicht lokal getestet** werden. Vollständige Python-, Backend-, Flutter-, APK- und Actions-Prüfungen stehen am endgültigen PR-HEAD noch aus. Keine SQLite-/JSON-Migration, keine Änderung an Spielständen, App-Version oder Fachregeln. Gemeinsame Statusdateien anderer offener PRs sind bei Integration verlustfrei zusammenzuführen.


### 2026-11-07 – Optionale Android-Cachebereinigung gegen fremde HOME-Pfade absichern

**Problem:** Selbst nach der Absicherung der SDK-Wurzel konnte die Wiederholung eines fehlgeschlagenen Android-SDK-Downloads weiterhin ungeprüft `$HOME/.android/cache` rekursiv entfernen. `HOME=/`, Root-Aliasse, relative Pfade und symbolische Links in `.android` konnten einen nicht vorgesehenen Ort betreffen.

**Lösung:** `scripts/install_android_sdk_packages.sh` erlaubt die optionale Cachebereinigung nur bei einem vorhandenen absoluten, physisch aufgelösten HOME-Verzeichnis außerhalb von `/` und ohne symbolische `.android`-/`cache`-Verzeichnisse. Bei unsicherem Pfad wird nur dieser optionale Teil mit einer Warnung übersprungen; die SDK- und NDK-Bereinigung sowie die Installations-Wiederholungen laufen unverändert. In `scripts/tests/test_install_android_sdk_packages.py` wurden drei neue Testmethoden mit vier Root-/Relativ-Pfadfällen, zwei Linkfällen und einem gültigen Alias ergänzt.

**Nachweis:** Fachcommit `205a8b8daa6152efda67eef5d5c8b29b5b48e72e`, Testcommit `34757df4d025a757ea7c08b8c093e93075ce3cd6`, Branch `fix/chat-d/android-home-cache-safe-20261107`, [PR #624](https://github.com/ManuEtt/Dnd/pull/624) (Draft; noch nicht integriert). Lokale isolierte Prüfung einer identisch rekonstruierten Shell-Datei: `bash -n` und sieben Fälle erfolgreich. Vollständiger Python-/Backend-/Flutter-/Android-CI-Nachweis auf dem endgültigen PR-Commit noch offen. Letzter bestätigter vollständiger Vorgänger-PR-Lauf: [#42287506256](https://github.com/ManuEtt/Dnd/actions/runs/42287506256) für PR #613; nicht auf diese Änderungen übertragbar. Keine Migration und keine Änderungen an SQLite, JSON, App-Version, Spielständen, Story, UI oder Spielregeln.


### 2026-11-07 – NDK-Elternverzeichnis bei SDK-Bereinigung vor symbolischen Links schützen

**Problem und Korrektur:** Die Wiederholung der Android-SDK-Paketinstallation entfernte bislang ein unvollständiges NDK unter `$ANDROID_SDK_ROOT/ndk/27.0.12077973`. Ein symbolischer Link der **übergeordneten** Komponente `ndk` konnte dabei zur Löschung fremder NDK-Verzeichnisse führen. Der Installer `scripts/install_android_sdk_packages.sh` überspringt bei einem solchen Elternlink ausschließlich die NDK-Bereinigung mit Warnhinweis; SDK-Wiederholungen, andere sichere Cache-Bereinigungen und der Schutz regulärer installierter NDKs bleiben bestehen.

**Nachweis:** Der ursprüngliche Fehler wurde lokal in einer temporären isolierten Sandbox mit symbolischem Elternverzeichnis reproduziert. Neue Tests in `scripts/tests/test_install_android_sdk_packages.py` decken transiente und persistente SDK-Fehler, außerhalb des SDK liegende Sentinel-Dateien und einen Symlink nur auf die endgültige NDK-Versionskomponente ab. Codecommit `20d4e4fc390853e036dc4b3ee0a641ea49e82581`; Testcommit `b707e215754c761139106dbf5c12ea93fe63d307`; Branch `fix/chat-d/ndk-parent-symlink-20261107`; [PR #626](https://github.com/ManuEtt/Dnd/pull/626) (Draft, noch nicht integriert). Die neue Python-Suite, Backend-/Flutter-/Android- und Release-CI müssen auf dem endgültigen PR-HEAD noch nachgewiesen werden. Letzte vollständige Vorgänger-CI: [#42361998502](https://github.com/ManuEtt/Dnd/actions/runs/42361998502) für PR #624; nicht auf PR #626 übertragbar. Keine Änderung an SQLite, JSON, App-Version, Spielständen, Regeln, Story oder UI; keine Migration.


### 2026-11-07 – Grafik-ZIP-Import gegen übergroße Archive absichern

**Problem/Lösung:** Der optionale Originalgrafik-Importer `scripts/import_complete_fantasy_assets.py` führte bisher `ZipFile.testzip()` ohne Größen- oder Eintragslimit aus. Manipulierte oder versehentlich sehr große ZIP-Archive konnten dadurch vor der eigentlichen Manifestvalidierung beliebig viel Dekompressionsarbeit auslösen. Nun gelten vor dem CRC-Scan ein Limit von 256 Einträgen und 64 MiB deklarierter unkomprimierter Gesamtgröße, eindeutige Dateinamen, maximal 512 KiB Manifest und höchstens 8 MiB je benötigtem Bild. Manifest und WebPs werden beschränkt gelesen; der SHA256-/WebP-Abgleich, sichere Zielpfade und bestehende Dateien bleiben geschützt.

**Nachweis/Abnahme:** Codecommit `f13a72634099eadfa79a845c22c5d7290321d91b`, Testcommit `3854288ad951132706c074ef50b038688c4dec1d`; Branch `fix/chat-d/fantasy-import-zip-limits-20261107`, [PR #629](https://github.com/ManuEtt/Dnd/pull/629) (Draft, nicht integriert). Sechs neue Python-Regressionsfälle prüfen übergroße ZIP-Einträge und Metadaten, doppelte Namen, nicht-objektförmige Manifeste und das Stoppen **vor** `testzip()`. Der vollständige Python-/Backend-/Flutter-/Android-CI-Nachweis auf dem finalen PR-Commit steht zum Dokumentationszeitpunkt noch aus. Keine Datenmigration, keine Änderungen an SQLite/JSON/Spielständen, UI, Regeln, Story oder Buildversion. Andere offene PRs ändern keine der beiden Fachdateien; gemeinsame Dokumentationsdateien bei Integration append-only zusammenführen.


### 2026-11-07 – Originalgrafiken erst nach vollständig erfolgreichem Schreiben veröffentlichen

**Fehlerbehebung:** Der optionale Import von 13 geprüften WebP-Originalgrafiken konnte bei einem E/A-Abbruch eine teilweise geschriebene Datei unter ihrem endgültigen Namen hinterlassen, die einen späteren erneuten Import blockierte. `scripts/import_complete_fantasy_assets.py` schreibt jedes neue Bild nun zunächst in eine zufällig benannte temporäre Datei im Zielordner, synchronisiert deren Inhalt und veröffentlicht sie erst danach über einen exklusiven Hardlink. Schlägt das Schreiben oder die Veröffentlichung fehl, wird die temporäre Datei entfernt; bereits fremde Dateien werden nicht überschrieben. Ein zwischen ZIP-Vorprüfung und tatsächlicher Veröffentlichung geändertes Original wird erneut anhand seiner Bytes abgelehnt.

**Tests/Nachweis:** Codecommits `bce63cd0c146d06b7f0045abae7961cb7a048622` und `e3b4c39b019c3733ccff2669a3c00eb06db0709f`, Testcommits `aeeb26bad86c76554b6c03df4a599d906195f893` und `b7d36d4e0fbc1b4fb32213bf04ca452840404d4a`; [PR #631](https://github.com/ManuEtt/Dnd/pull/631) (Draft, nicht integriert), Branch `fix/chat-d/fantasy-import-atomic-publication-20261107`. Vier neue Python-Regressionstests betreffen simulierten Datenträgerausfall, konkurrierende Zieldateien, späte Originaländerungen und Fortsetzung nach gescheiterter zweiter Veröffentlichung. Vollständige Python-/Backend-/Flutter-/Android-/Release-CI am finalen PR-HEAD zur Dokumentation noch ausstehend. Die Veröffentlichung ist **je Einzelbild atomar**, keine Transaktion aller 13 Grafiken: Ein erneuter Import ergänzt bereits korrekt veröffentlichte Dateien. Keine Auswirkungen auf SQLite, JSON, Spielstände, Domainregeln, UI oder Buildversion.


### 2026-11-07 – Windows-Gerätenamen mit hochgestellten Ziffern in Projektarchiven erkennen

**Problem/Lösung:** Die bisherige Windows-Dateinamenliste erkannte `COM1`–`COM9` und `LPT1`–`LPT9`, nicht jedoch die ebenfalls von Windows reservierten Namen `COM¹`, `COM²`, `COM³`, `LPT¹`, `LPT²` und `LPT³`. Damit konnten Quell-ZIPs und hochgeladene Gradle-Wrapper-JARs unter Linux Dateinamen enthalten, die Windows als Geräte statt als Dateien interpretiert. `scripts/package_project.py` ergänzt diese sechs Namen in der gemeinsamen `WINDOWS_RESERVED_STEMS`-Liste. Sowohl der portable Quellarchiv-Export als auch die `verify_project.py`-Validierung des Wrapper-JAR verwenden diese gemeinsame Liste bereits; unverdächtige ähnlich benannte Dateien bleiben erlaubt. Referenz: [Microsoft Windows-Namenskonventionen](https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-file).

**Nachweis:** Branch `fix/chat-d/windows-device-superscript-20261107`, [PR #637](https://github.com/ManuEtt/Dnd/pull/637) (Draft; nicht integriert), Codecommit `db7cb684ab0ff7af90dad28bf53a209559602ff0`, Testcommits `163c4ea0d05b40761775b543eeb875251e147aa3`, `f99e061d40e1e12e700888dfd1b6e73622271b45`, `b0b9c7dad58c6dc4ca9ddccabe300072ebe39f00`. Vier Python-Testmethoden prüfen alle sechs Namen als Datei- und Verzeichnisteile, das Bewahren alter ZIP-/SHA256-Ausgaben bei Fehlern, die Ablehnung im JAR **vor** dem CRC-Scan und erlaubte nichtreservierte Namen. Die Python-Teststufe der vorläufigen PR-Fassung ist auf GitHub bestanden; die endgültige Gesamt-CI nach dem Dokumentationscommit steht noch aus. Keine Änderung an SQLite, JSON, Spielständen, Flutter/UI, Regelengine, Story oder App-Version. Die Dokumentation des inzwischen integrierten PR #631 wurde zuvor verlustfrei übernommen; kein älterer README-Abschnitt wurde verändert.


### 2026-11-07 – Originalgrafik-Manifeste als eindeutiges JSON prüfen

**Problem/Lösung:** Das originale Grafik-ZIP hat bereits Größen-, WebP- und SHA256-Prüfungen. Der bisherige JSON-Parser konnte aber doppelte Schlüssel stillschweigend übergehen (letzter Wert gewinnt) sowie die nichtstandardisierten Zahlen `NaN` und `Infinity` akzeptieren. `scripts/import_complete_fantasy_assets.py` nutzt jetzt eine strikte Manifestprüfung: doppelte JSON-Schlüssel werden auf jeder Objektebene zurückgewiesen, `NaN`/`Infinity`/`-Infinity` sind verboten und die Manifestwurzel muss ein Objekt sein. Diese Prüfung läuft vor dem vollständigen ZIP-CRC-Scan und vor dem Schreiben der 13 verifizierten Originalgrafiken. Die sichere Einzeldatei-Veröffentlichung, Hash- und Größenprüfungen bleiben unverändert.

**Nachweis:** Branch `fix/chat-d/fantasy-manifest-unique-json-20261107`, [PR #638](https://github.com/ManuEtt/Dnd/pull/638) (Draft, zunächst nicht integriert), Codecommit `42871dbea42d81fbc4d5abc81339f32e83762784`, Testcommit `9b025bbd6931f41840183b3aab52626110a33b94`. Vier neue Python-Testmethoden prüfen doppelte Asset-Schlüssel, doppelte geschachtelte Größenangaben, nichtstandardisierte Zahlen und weiterhin gültige Manifeste mit 13 Dateien. Die frühe PR-Python-Stufe war erfolgreich; vollständige CI am finalen dokumentierten HEAD ist noch abzunehmen. Alle bereits integrierten Nachträge von PR #637 wurden vor diesem Abschnitt verlustfrei übernommen. Keine Migration, keine Änderungen an SQLite/JSON-Spielständen, Regelengine, Story, UI oder App-Version.


### 2026-11-08 – Grafikimport vor Symlinks in übergeordneten Zielpfaden schützen

**Problem/Lösung:** Bisher prüfte der optionale Originalgrafik-Import `scripts/import_complete_fantasy_assets.py` zwar `--target` selbst und alle darunterliegenden Bildpfade, jedoch nicht die *Elternverzeichnisse* des angegebenen Projektordners. Ein normaler Zielordner unter einem übergeordneten Symlink konnte den Import deshalb in einen anderen Verzeichnisbaum umlenken. `ensure_safe_destination` prüft nun vor dem Verifizieren/Veröffentlichen auch jeden Vorfahren des Zielordners ausdrücklich auf Symlinks. Das ist eine zusätzliche Sicherheitsgrenze ohne Änderung an den geprüften WebP-Inhalten, ZIP-Ressourcenlimits, strikten JSON-Manifesten, SHA256-Prüfungen oder der Veröffentlichung vollständiger Einzeldateien.

**Tests/Nachweis:** Branch `fix/chat-d/fantasy-target-ancestor-symlink-20261108`, [PR #640](https://github.com/ManuEtt/Dnd/pull/640) (Draft, zunächst nicht integriert), Codecommit `9a0f3bf5bed866371bdf380fadc0455995c6a8f2` und Testcommit `45806225eb87563e70c7d907802618221f50da89`. Zwei neue POSIX-Regressionstests prüfen die Ablehnung eines symlinkten Zielvorfahren auch im `--verify-only`-Modus sowie den Austausch eines Vorfahren *nach* der ZIP-Vorabprüfung ohne externe Schreibzugriffe. Die vollständige GitHub-CI am finalen PR-HEAD steht bei diesem Nachtrag noch aus. Vorhandene gültige Import- und Wiederaufnahmetests bleiben unverändert. Restgrenze: Eine bloße Pfadprüfung ist kein garantierter Schutz gegen einen exakt zwischen letzter Prüfung und Schreiben erfolgenden parallelen Verzeichnistausch; eine descriptorbasierte Lösung wäre gesondert nötig. Keine Änderungen an App-Version, SQLite, JSON-Spielständen, Regeln, Story oder UI.



### 2026-11-07 – Magieinitiierten-Auswahl beim Hintergrundwechsel neu bestätigen

In der Magieinitiierten-Zauberwahl wird beim Wechsel zwischen einem Kleriker- und einem Magier-Herkunftshintergrund eine zuvor noch nicht bestätigte Auswahl aus Zaubertricks, Grad-1-Zauber und Zauberattribut vollständig verworfen. Auch Zauber, die auf beiden Herkunftslisten stehen, gelten nicht als stillschweigend erneut gewählt. Die Dropdowns werden passend zur neu gewählten Herkunft aufgebaut; Hintergründe ohne Magieinitiierten-Auswahl erscheinen ausdrücklich als nicht verfügbar.

**Nachweis:** `app/lib/ui/srd_magic_initiate_dialog.dart`, `app/test/srd_magic_initiate_background_swap_test.dart`; Branch `feat/chat-c/magic-initiate-background-swap-20261107`, Grundlage main `bbe6ee0901f1873af67647bf54462e4a44821762`. Neue Widgettests für 320/360 dp, doppelte Android-Schriftgröße und simulierte Tastatur sowie für bestätigte, abgebrochene und nicht unterstützte Wechsel sind implementiert. GitHub-Actions-Tests und Android-Builds sind zum Zeitpunkt dieses Nachtrags noch nicht abgeschlossen; echte Geräte-/TalkBack-Prüfung fehlt. Keine Änderung an App-Version `0.8.52+102`, SRD-Regeln, SQLite-/JSON-Schema oder vorhandenen Spielständen.



### 2026-11-08 – Schadens- und TP-Freigaben beim Wechsel der Effektart erneut wählen

Bei der manuellen Bestätigung eines bereits regelgerecht ermittelten Charaktereffekts werden im Formular frühere, nur zur bisherigen Effektart gehörige Zustimmungen nach einem Wechsel zwischen Schaden, Heilung und temporären Trefferpunkten nicht mehr stillschweigend übernommen. Dies betrifft Resistenz, Anfälligkeit, Immunität, kritischen Treffer und die Erlaubnis, vorhandene temporäre Trefferpunkte zu ersetzen. Auch die Schadensart wird auf die neutrale Vorgabe zurückgesetzt. Ohne Effektartenwechsel bleibt die bestehende ausdrückliche Auswahl erhalten.

**Nachweis:** `app/lib/ui/character_effect_dialog.dart` und `app/test/character_effect_kind_consent_reset_test.dart` auf Branch `feat/chat-c/character-effect-kind-consent-reset-20261108` ab main `0ce0ad86e9eddf8302e495561d12a889008de49a`; drei neue Widgettests für 320/360 dp, 200 % Text und simulierte Android-Tastatur prüfen Zurücksetzen, bewusste Neuwahl, ausdrücklich übermittelte Entscheidungen und neutralen Abbruch. GitHub-CI-Abnahme auf dem neuen Branch steht zum Zeitpunkt dieses Eintrags noch aus. Keine Änderung an App-Version `0.8.52+102`, SRD-Regeln, Datenbank-/JSON-Schema oder gespeicherten Charakteren. Reale Android- und TalkBack-Geräteprüfung steht aus.

### 2026-11-08 – Zwei abgesicherte Dialogzustände gemeinsam integrieren

Die voneinander unabhängigen UI-Korrekturen für den Magieinitiierten-Hintergrundwechsel ([PR #634](https://github.com/ManuEtt/Dnd/pull/634)) und den Wechsel der Charaktereffekt-Art ([PR #642](https://github.com/ManuEtt/Dnd/pull/642)) wurden nach vollständig erfolgreichen jeweiligen Android-/Flutter-/Backend-/Python-CI-Prüfungen als Integrationskandidat auf `integration/reviewed-ui-resets-20261108` zusammengeführt. Die ursprünglichen Quell-Commits sind Git-Vorfahren; beide Testdateien und alle vorherigen README-Nachträge bleiben erhalten. Die **kombinierte CI auf diesem Integrationsstand steht noch aus** und ist vor einem Main-Merge verpflichtend. Keine Änderung an SQLite-/JSON-Schema, bestehenden Spielständen oder App-Version; echte Android-/TalkBack-Abnahme weiterhin offen.

### 2026-11-08 – Raw-Dart-Importe in der technischen Modulgrenzenprüfung erkennen

**Problem/Lösung:** Die Python-Prüfung der Story-/Regelmodulgrenzen übersah bislang zulässige Dart-URI-Literale mit vorangestelltem Raw-Präfix `r` bei direkten oder bedingten `import`-/`export`-Direktiven sowie bei `part` und `part of`. Die URI-Erkennung in `scripts/check_domain_boundaries.py` behandelt diese Formen nun wie gewöhnliche quoted URIs. Unverändert bleiben die bestehenden Modul-Whitelists, Dateisystemprüfungen und die Unterscheidung zwischen tatsächlichen Direktiven und Kommentaren/String-Beispielen.

**Regressionen und Nachweis:** In `scripts/tests/test_domain_boundaries.py` wurden drei Testmethoden für sieben direkte verbotene URIs, drei bedingte verbotene URIs und weiterhin erlaubte Beispiele ergänzt. Branch `fix/chat-d/raw-dart-uri-boundary-20261108`, [PR #649](https://github.com/ManuEtt/Dnd/pull/649) (Draft), Fachcommit `ed09317a6fadaa04ecc6f9e3fa2b917d733ab248`, Testcommit `ca860df1e97775fbae5155623ca05c0c77815944`. Die 56 zuvor offenen PRs hatten keine fachliche Überschneidung. Der vorhandene erfolgreiche Main-Workflow [#42514079690](https://github.com/ManuEtt/Dnd/actions/runs/42514079690) prüfte lediglich die Ausgangsbasis; vollständige neue Python-/Backend-/Flutter-/Android-CI am finalen PR-HEAD ist in diesem Nachtrag noch **nicht abgenommen**. Der Prüfer bleibt ein gezielter Direktivenscanner, kein vollständiger Dart-Parser. Keine Änderungen an SQLite-/JSON-Spielständen, Sicherungen, Version, Build, Regeln, UI oder Story; keine Migration.

### 2026-11-08 – Privilegierte Unix-Dateirechte aus Quell-ZIP-Metadaten entfernen

**Problem/Lösung:** Der allgemeine Quellarchiv-Exporter `scripts/package_project.py` übernahm bisher mit `stat.S_IMODE` auch Unix-Sonderrechte (Setuid/Setgid/Sticky) in die Berechtigungsbits der ZIP-Einträge. Archivmetadaten enthalten jetzt nur den regulären Dateityp und die gewöhnlichen `rwx`-Berechtigungen (`0o777`). Ausführbare Source-Skripte behalten ihre normalen Rechte; der Archivinhalt, Pfadnamen, SHA256 und das Format bleiben unverändert.

**Tests/Nachweis:** `scripts/tests/test_package_project.py` ergänzt einen POSIX-Regressionsfall für drei privilegierte Quelldatei-Modi (4755, 2750 und 1755) mit negativen Sonderbit-Prüfungen und positiven Nachweisen für den unveränderten Dateiinhalt, regulären Dateityp und normale Berechtigungen. Branch `fix/chat-d/source-zip-safe-modes-20261108`, [PR #650](https://github.com/ManuEtt/Dnd/pull/650) (Draft, nicht integriert), Codecommit `4d7bb9a0a9c8ff208b3b799cafeb7f42af811470`, Testcommits `3ea18bde7fd75794e7f6f15c8d797e3d211e56e6` und `48342a3033990a0833351cddcc7bac5a4a7badf1`. Der erfolgreiche Ausgangs-Main-Workflow [#42514079690](https://github.com/ManuEtt/Dnd/actions/runs/42514079690) ist **kein** Test des neuen Code-/Dokumentationsstands; die vollständige PR-CI ist hier noch ausstehend. Keine Änderung an Spielständen, SQLite/JSON-Format, Backups, Android-App, SRD-Regeln, Story oder Version; keine Migration.

### 2026-11-08 – Zwei geprüfte Qualitätskorrekturen gemeinsam integrierbar vorbereitet

Die beiden unabhängig erprobten Python-Korrekturen zur Dart-Modulgrenzenprüfung und zu sicheren Quell-ZIP-Dateirechten werden im gemeinsamen [Integrations-PR #652](https://github.com/ManuEtt/Dnd/pull/652) auf neuer Main-Basis zusammengeführt. Die zwei zuvor auf dem Hauptzweig vorgenommenen UI-Fortschritte und sämtliche bisherigen README-Einträge bleiben verlustfrei erhalten. Beide Quell-Pull-Requests [#649](https://github.com/ManuEtt/Dnd/pull/649) und [#650](https://github.com/ManuEtt/Dnd/pull/650) hatten auf ihren unveränderten Heads jeweils sechs erfolgreiche CI-Jobs. Der Integrationscommit `c9cda978ea5cc5dc3d6526d436b909769dc593f1` enthält beide Quell-Heads als echte Git-Eltern; die kombinierte CI ist zum Zeitpunkt dieses Nachtrags noch nicht erfolgreich abgenommen. Kein Main-Merge behauptet. Keine SQLite-/JSON-Spielstands-, Backup-, App-Versions-, UI-, Story- oder Regelmigration.


### 2026-11-06 – Quell-ZIP und Sidecar ohne Überschreiben veröffentlichen

Das Alpha-Release erstellt sein Quellarchiv samt `.zip.sha256` nun zunächst in einem privaten, temporären Verzeichnis unter der Release-Ausgabe. Anschließend werden beide geprüften Dateien ohne Überschreiben unter ihren Versionsnamen veröffentlicht. Taucht zwischen ursprünglichem Kollisionscheck und Veröffentlichung eine reguläre Datei oder ein Symlink auf, bricht die Alpha-Erstellung ab und bewahrt den fremden Eintrag. Beim Fehler-Rollback wird weiterhin nur tatsächlich erzeugener, anhand der Dateikennung identifizierter Inhalt entfernt.

Der allgemeine Quellarchiv-Exporter `scripts/package_project.py` behält seine bisherige Funktion zum absichtlichen Ersetzen existierender Archive. Die Korrektur betrifft ausschließlich `scripts/prepare_alpha_release.py`. In `scripts/tests/test_prepare_alpha_release.py` prüfen fünf neue Regressionen erfolgreiche Veröffentlichung, spät kollidierende ZIPs, externe Links, spät belegte Sidecars und den Austausch unmittelbar nach Veröffentlichung. Siehe [PR #608](https://github.com/ManuEtt/Dnd/pull/608), Branch `fix/chat-d/release-source-exclusive-publish-20261106` (Draft bis vollständige CI).

**Kompatibilität/Abnahme:** Keine Änderung an Spielstandformaten, SQLite, JSON, Backups, Story, Regeln, Flutter, Android-Build-/Versionsnummern oder der Release-Dateibenennung. Keine Migration. Die vollständige CI auf finalem Dokumentationscommit sowie echte Android-Geräteabnahme stehen noch aus. Ein aktiv fremd manipulierbares Ausgabe-Verzeichnis bleibt außerhalb einer garantierten Race-free-Sicherheitsgrenze.

### 2026-11-06 – Checkpoint-Historie gegen mehrdeutige Dateinamen absichern

Frühere Quellcode-Checkpoints dürfen keine zwei Dateinamen besitzen, die unter Unicode-NFC-Normalisierung und ohne Unterscheidung von Groß-/Kleinschreibung denselben Namen ergeben. Die Checkpoint-Erstellung verweigert solche Paare vor der Prüfsummenberechnung und Veröffentlichung, zum Beispiel `Case`/`case` oder `Café`/`Café`. Zusätzlich werden neue, gleich datierte Checkpoints mit nur anders geschriebenem Label sowie abweichend geschriebene Varianten der festen `LATEST`- und `SHA256SUMS.txt`-Dateien sicher zurückgewiesen.

**Umsetzung:** `scripts/create_checkpoint.py`; vier neue Regressionstests in `scripts/tests/test_create_checkpoint.py` prüfen Casefold-/Unicode-Kollisionen, Publikationssperren und den unveränderten Bestand zuvor veröffentlichter Archive und Prüfsummen.

**GitHub:** Branch `fix/chat-d/checkpoint-history-normalized-name-collisions-20261106`, [PR #592](https://github.com/ManuEtt/Dnd/pull/592). Die vollständige GitHub-CI des finalen PR-Commits ist noch abzunehmen; keine lokalen Projekttests als bestanden behauptet.

**Kompatibilität:** Keine Migration und keine Änderung an existierenden Backups, Spielständen, SQLite-/JSON-Daten, App-/Android-Versionen oder Spielregeln. Reale Geräteabnahme und produktive Signierung bleiben separat offen.


### 2026-11-08 – Checkpoint-Dateinamensicherung auf aktuellen Hauptstand übertragen

Der ältere [PR #592](https://github.com/ManuEtt/Dnd/pull/592) gegen Unicode-NFC-/Casefold-Kollisionen historischer Checkpoint-Artefakte ist auf den aktuellen Hauptstand zurückgeführt worden, ohne bestehende Code- oder Checkpoint-Historie zu überschreiben. Der gespeicherte Schutz erkennt mehrere historische Archive mit gleichwertigen Namen, ein gleich datiertes Checkpoint mit anders geschriebenem Label sowie alternative Schreibweisen der stabilen Ausgabedateien. Vier Regressionstests bleiben erhalten. Der aktualisierte PR bleibt bis zur vollständig erfolgreichen GitHub-CI am finalen Dokumentations-HEAD ein Draft; die Änderungen wurden noch nicht in `main` integriert. Keine Migration und keine Auswirkungen auf SQLite, JSON-Spielstände, App-Version, Regeln, Story oder UI.


### 2026-11-08 – Originalgrafik-Import vor nicht regulären Ziel-Dateien schützen

**Problem/Lösung:** Der optionale Import geprüfter Originalgrafiken las vorhandene Zieldateien bisher ohne Prüfung ihres Dateityps. Versteckte sich an einem Bildziel ein benanntes Pipe-/FIFO-Objekt, konnte das Lesen auf einen Schreiber warten und damit den Import blockieren. Nun verwenden sowohl die ZIP-Vorabprüfung als auch die finale Einzeldatei-Veröffentlichung dieselbe Funktion `verify_existing_asset()`: Vorhandene Ziele müssen reguläre Dateien sein, bevor ihre Inhalte gelesen und auf exakte Übereinstimmung geprüft werden. Verzeichnisse und FIFOs werden stattdessen abgelehnt. Übereinstimmende reguläre Dateien bleiben für sichere Wiederholungen unverändert, unterschiedliche Bilder werden weiterhin nicht überschrieben.

**Nachweis:** Branch `fix/chat-d/fantasy-import-nonregular-targets-20261108`, [PR #645](https://github.com/ManuEtt/Dnd/pull/645) (Draft, noch nicht integriert). Fachcommit `aeb143ea2a41474e6a871d94b4f90a375a0bc862`, Testcommit `9c3ae1b9ec54ace10579f1665428727e38486b6e`. Drei neue Regressionstests behandeln Verzeichnisziele im Normal- und Verify-Only-Modus, eine existierende POSIX-FIFO und eine erst nach dem ZIP-Preflight auftauchende FIFO; die Tests verbieten dabei explizit den potenziell blockierenden Leseaufruf. Die vollständige GitHub-CI auf dem final dokumentierten PR-Head ist bei diesem Nachtrag noch ausstehend. Die zuvor geprüften Symlink-, ZIP-Limit-, JSON-Manifest-, SHA256-/WebP- und atomaren Schreibprüfungen bleiben unverändert. Es besteht weiterhin keine Garantie gegen einen exakt zeitgleich erfolgenden Dateiaustausch; dafür wäre ein descriptorbasierter Pfadschutz nötig. Keine Änderung an SQLite, JSON-Spielständen, App-Version, Story, Regelengine oder UI.

### 2026-11-09 – Sichere Projekt-Checkpoints, Alpha-ZIP-Veröffentlichung und Grafikimport geprüft zusammenführen

Drei unabhängig entwickelte Qualitätsverbesserungen werden im Integrationsbranch `fix/chat-d/integrate-storage-safety-20261109` gemeinsam überprüft: kollisionssichere historische Checkpoint-Dateinamen ([PR #592](https://github.com/ManuEtt/Dnd/pull/592)), exklusive Veröffentlichung versionierter Alpha-Quellarchive und ihrer SHA256-Sidecars ([PR #608](https://github.com/ManuEtt/Dnd/pull/608)) sowie Schutz vor nicht regulären vorhandenen Grafik-Zieldateien ([PR #645](https://github.com/ManuEtt/Dnd/pull/645)). Jeder ursprüngliche PR-Commit hatte sechs erfolgreiche CI-Jobs; die gemeinsame Integrations-CI bleibt bis zum vollständigen Nachweis offen. Der bestehende README-Inhalt und alle vorherigen Nachträge bleiben unverändert; kein direkter Main-Commit, keine Spielstands-, SQLite-/JSON-, App- oder API-Migration.


### 2026-11-09 – Drei Qualitätskorrekturen mit erhaltener Historie zur Integrationsprüfung eingereicht

Die geprüften Verbesserungen für kollisionssichere historische Checkpoints, exklusive Alpha-Quell-ZIP-/SHA256-Veröffentlichung und den Schutz von Grafikimport-Zieldateien sind im [Integrations-PR #655](https://github.com/ManuEtt/Dnd/pull/655) zusammengefasst. Die ursprünglichen Fach-PRs [#592](https://github.com/ManuEtt/Dnd/pull/592), [#608](https://github.com/ManuEtt/Dnd/pull/608) und [#645](https://github.com/ManuEtt/Dnd/pull/645) und ihre vollständigen Git-Historien bleiben erhalten. Alle Einzelprüfungen waren erfolgreich; die gemeinsame CI auf dem abschließenden Integrationscommit ist gesondert abzunehmen. Unveränderte Spielstände, Backups, SQLite-/JSON-Schemas, UI, Story, Regelwerk und App-Version; kein ungeprüfter Main-Merge.


### 2026-11-07 – Ritualzauber-Freigabe an bestätigte Katalogidentitäten gebunden

Bei der lesenden SRD-5.2.1-Ritualvorprüfung konnten zuvor öffentlich konstruierte Zauberdefinitionen durch gefälschte Ritualkennzeichen und eine formal gültige Ritualwirkzeit eine **slotfreie** Vorabfreigabe erhalten, auch wenn das gewählte Zauberoriginal gar kein Ritual ist (etwa *Magic Missile*). Die Regelprüfung bindet nun alle **29 im aktuellen Arbeitskatalog als Ritual markierten Zauber** an die genaue Kombination von Name, ID, Grad, Wirkzeit und Klassenliste. Eine manipulierte Ritualberechtigung wird vor der Planerstellung abgewiesen. Die bestehenden Berechnungen für plus zehn Minuten, vorbereitete Zauber, Klassenberechtigung, Materialbestätigungen und nicht mutierende Helden-Snapshots bleiben erhalten. Neue deterministische Regressionen testen alle 29 Katalog-Rituale, negative Metadatenmanipulationen sowie unveränderte Slot-/JSON-Daten.

**Nachweis:** [PR #622](https://github.com/ManuEtt/Dnd/pull/622), Branch `feat/chat-a/ritual-catalog-identity-20261107`, initialer Fachcommit `8b98068173f4932d1349f29ca8464034bcfb71a5`. **Tests:** Quell-/Katalogabgleich mit 29/29 passenden Tupeln; die neue Dart-/Flutter-/Android-Gesamt-CI ist beim Eintrag noch offen. Kein lokales Flutter-SDK, keine Geräteabnahme. **Quelle:** Wizards of the Coast LLC, SRD 5.2.1, *Spells / Casting without Slots / Rituals und Longer Casting Times* (CC BY 4.0), https://www.dndbeyond.com/srd. **Kompatibilität:** Unveränderte Heldendaten, Spielstand-JSON, SQLite-Schema, Story, UI, Android-Version und bekannte gültige Ritualzeiten; keine Migration. Ritualvorprüfung ist kein ausgeführter Zaubereffekt und keine vollständige amtliche Reconciliation aller 339 Zauber.


### 2026-11-07 – NPC-Besuche im Rabenwacht-Epilog ausdrücklich bestätigen

Im spielbaren Epilog von Rabenwacht konnte bisher bereits die Erwähnung einer Person, eines Briefs, einer Zeichnung oder des Brunnens zu einem gespeicherten Ortswechsel führen und eine NPC-Stimme als gehört markieren. Das konnte spätere Dorfentscheidungen unbeabsichtigt freischalten. `FourteenthVoiceEpilogue` akzeptiert für Elda, Tarek und Liora jetzt nur ausdrücklich formulierte Besuche, Reisen oder Gespräche; ein beiläufig genannter Dorfplatz löst auch keine Rückkehr mehr aus. Die bestehenden freien Besuchsmöglichkeiten, Verneinungen, Voraussetzungen für die Dorfzukunft und bereits gespeicherte Erinnerungen bleiben erhalten.

**Code:** `app/lib/story/fourteenth_voice_epilogue.dart`; **Regressionen:** `app/test/rabenwacht_epilogue_explicit_visit_test.dart` mit fünf Szenarien für beiläufige Erwähnungen, acht echte Besuchsaktionen, bewusste Rückkehr, JSON-Wiederaufnahme und SQLite-Neustart mit unverändertem Helden- und Questzustand. [PR #628](https://github.com/ManuEtt/Dnd/pull/628), Branch `fix/chat-b/epilogue-explicit-npc-visit-20261107`, Basis-main `1816115990cc7420ecfb2d1ba7c6babb557f76da`. GitHub-Actions-Abnahme auf dem endgültigen PR-Head war bei Erstellung dieses Nachtrags noch offen; tatsächliche Testresultate stehen im PR. Keine Änderung an Datenformat, SQLite-Schema, Regelengine, KI-Provider oder App-Version. README- und Checkpoint-Ergänzungen anderer offener PRs bei Integration vollständig bewahren.

### 2026-11-08 – Heilzauber-Dialog bei aktualisierten Heldendaten neu aufbauen

**Problem und Lösung:** Bisher wurden Heilzauber, Zauberklassen und freie Zauber- beziehungsweise Paktmagieplätze beim Öffnen des Dialogs einmalig geladen. Wenn sich die bestätigten Heldendaten im bereits geöffneten Formular änderten, konnten zuvor gewählte Plätze und Komponentenfreigaben als alte Formularzustände bestehen bleiben. Die Oberfläche lädt bei neuem Hero-Snapshot nun alle Optionen erneut, verwirft die vorausgegangenen Zustimmungen sowie ältere Fehler und montiert die drei Dropdown-Felder unter unveränderten Bedien-Keys neu. Ein reines Rebuild desselben Snapshots behält ausdrücklich vorgenommene Entscheidungen dagegen bei. Die Heilung und Ressourcenbuchung bleiben weiterhin ausschließlich Sache des Regel-/Controllerpfads.

**Nachweis:** Branch `feat/chat-c/healing-spell-live-hero-refresh-20261108`, [PR #651](https://github.com/ManuEtt/Dnd/pull/651) (zunächst Draft), Fachcommit `3f21b9bf0d2d6dd994795faa22c07b73c376b0cd`, Testcommit `a1bbd11dead44b819114da3e0f69d9aa6ff84bbc`, synchronisiert mit aktuellem `main` über `ba16c4f36a684900d148f263a024ab5bafef52fa`. Sechs neue positive und negative Widgettests für unveränderte Dialog-Neuzeichnung, Helden-/Zauber-/Platzwechsel, ungültige Ressourcendaten und 320/360 dp bei 200 % Schrift sowie simulierter IME implementiert. **Eine neue erfolgreiche CI für den endgültigen PR-HEAD ist bei diesem Nachtrag noch nicht belegt**; Android-Gerät/TalkBack und echte Tastatur bleiben offen. Keine Änderung an Spielregeln, SQLite/JSON, alten Spielständen, Assets, App-Version `0.8.52+102`, Signierung oder Berechtigungen; keine Migration.


### 2026-11-09 – Drei geprüfte Verbesserungen zur gemeinsamen Integration vorbereitet

Die voneinander unabhängig getesteten Korrekturen für SRD-Ritualidentitäten ([PR #622](https://github.com/ManuEtt/Dnd/pull/622)), ausdrücklich bestätigte NPC-Besuche im Epilog ([PR #628](https://github.com/ManuEtt/Dnd/pull/628)) und aktualisierte Heilzauberauswahl ([PR #651](https://github.com/ManuEtt/Dnd/pull/651)) wurden für einen koordinierten Integrationsbranch auf `main` `b2e1a021067cec39b7c85bdad11aa98477cac14e` vorbereitet. Die sechs Fach-/Testpfade sind im Ausgangsstand unverändert und bei den weiteren offenen PRs nicht überlappt; die vollständigen Quell-Commits sollen als Git-Vorfahren erhalten bleiben. Die historischen README- und Checkpoint-Nachträge werden ausschließlich angehängt. Alle drei einzelnen PR-Head-CIs waren vollständig erfolgreich (je sechs Jobs); die **gemeinsame** Python-/Backend-/Flutter-/Android-/Release-CI ist noch nicht ausgeführt beziehungsweise abgenommen. Es erfolgt hiermit weder ein ungeprüfter `main`-Merge noch eine Löschung. Spielstände, SQLite/JSON, Version und Backups bleiben unverändert.

### 2026-11-09 – Kodierte Dart-URIs bei der Modulgrenzenprüfung abweisen

**Problem/Lösung:** Der technische Importgrenzen-Scanner für Story- und Regelmodule konnte bislang URI-Pfade mit Dart-Escape-Sequenzen oder Prozentkodierung nicht sicher als kanonische Modulziele bestimmen. Solche Literale werden nun bei Import, Export, `part`, `part of` und bedingten Import-/Exportalternativen konservativ abgewiesen. Normale unveränderte Imports und die bestehenden gültigen Modulgrenzen bleiben erlaubt.

**Tests/Nachweis:** Vier zusätzliche Regressionstestmethoden in `scripts/tests/test_domain_boundaries.py` prüfen Unicode-/Hex-Escapes, prozentkodierte Pfade und Package-URIs, mehrfache bedingte Varianten sowie unkodierte Positivfälle und die Ignorierung von Kommentaren und gewöhnlichen String-Literalen. Fach-Commits `2fbfd9e3034292f9fe8c35b8d5ceeacd7bd8cf71` und `8ca581fc47d8b14d02010f3778e0919cb7883426` im Branch `fix/chat-d/encoded-dart-uri-boundary-20261109`. Die vollständige GitHub-CI auf dem finalen Dokumentationsstand ist zum Zeitpunkt dieses Eintrags noch ausstehend; dieser Eintrag behauptet keinen Main-Merge. Keine Änderung an App-/Build-Version, Spielständen, SQLite/JSON, Backups, UI, Regelmechanik oder Story und keine Migration.

**GitHub-Review:** [Pull Request #657](https://github.com/ManuEtt/Dnd/pull/657) ist zur vollständigen CI-Prüfung eingereicht; bis zur Abnahme verbleibt er im Draft.

### 2026-11-09 – Mehrdeutige Verzeichnisnamen im Gradle-Wrapper-ZIP ablehnen

Der Projektübertragungsprüfer weist nun auch ZIP-Verzeichniseinträge mit mehreren abschließenden Pfadtrennzeichen zurück. Solche Namen werden nicht mehr stillschweigend durch Normalisierung auf einen regulären Verzeichnispfad reduziert. Ein Regressionstest stellt sicher, dass die Ablehnung vor der CRC-Dekompression erfolgt. Betroffen sind ausschließlich `scripts/verify_project.py` und dessen Tests. Keine Änderung an App, Spielständen, Backups oder Persistenzformaten. Implementierung und CI-Abnahme: [PR folgt nach Veröffentlichung].

## PR- und CI-Nachweis

- **Pull Request:** [#662](https://github.com/ManuEtt/Dnd/pull/662) (Draft).
- **Finaler Code-HEAD:** `f25c9bdbc371974fb8c9f2ea6283204df4845080`.
- **GitHub Actions:** nach Veröffentlichung gestartet; vollständige CI und Mergefähigkeit noch nicht bestätigt.
- **README-Nachtrag:** PR-Link ergänzt; kein Merge behauptet.


### 2026-11-09 – Veraltete Angriffsentscheidung im Wilden Angreifer verwerfen

Der Dialog für den Talentvorschlag „Wilder Angreifer“ verwirft eine bereits gewählte Wurfalternative, wenn sich Angriffsidentität, Kampf-/Kampagnensnapshot, Schadensausdruck, Würfelnachweise, kritischer Status oder Treffer-/Waffenbestätigung ändern. Ein unveränderter Vorschlag behält die ausdrückliche Auswahl bei einem reinen Parent-Rebuild. Fünf positive und negative Widget-Regressionen decken identische Rebuilds, neue Angriffe, abgelaufene Züge und geänderte Würfel ab; Spielstands-JSON bleibt unverändert.

Die Änderung liegt auf Branch `feat/chat-c/savage-attacker-live-offer-reset-20261108` und [PR #647](https://github.com/ManuEtt/Dnd/pull/647). Der ursprüngliche Branch-HEAD `69dd94292a1c2f4b0580fbf51378a0017446c449` hatte sechs erfolgreiche CI-Jobs ([Actions #42515186537](https://github.com/ManuEtt/Dnd/actions/runs/42515186537)). Nach dem Abgleich mit dem inzwischen weiterentwickelten `main` ist eine erneute vollständige CI auf dem neuen Merge-HEAD erforderlich; sie wird nicht vorweggenommen. Keine Änderung an Regeln, Controller, SQLite/JSON, App-Version oder Spielstandmigration.

### 2026-11-10 – Importgrenzen gegen verlinkte Quellwurzel absichern

- **Problem:** Der Story/Rules-Scanner wies verlinkte Modulverzeichnisse zurück, aber ein symbolischer Link auf `app/` oder `app/lib/` konnte beide Module unbemerkt außerhalb des Checkouts verlagern.
- **Lösung:** `scripts/check_domain_boundaries.py` verweigert die Prüfung vor dem Lesen bei verlinkten übergeordneten Quellverzeichnissen; zwei neue Negativtests sichern beide Varianten ab. Unverlinkte Modulverzeichnisse bleiben unverändert erlaubt.
- **Branch:** `fix/chat-d/domain-boundary-ancestor-symlink-20261110`. **Tests:** Neue Python-Unittests ergänzt; GitHub-CI nach Veröffentlichung ausstehend. Keine Änderung an Spielständen, JSON, SQLite, Regeln oder Android-Laufzeit.


### Rabenwacht: Verneinte Rückreisen respektieren

Eine ausdrücklich verneinte Rückreise zu einem bekannten Ort darf keinen Ortswechsel auslösen. Die Story-Logik bleibt am aktuellen Schauplatz; eine positive Rückreise bleibt möglich. Regressionstests: `app/test/rabenwacht_negated_revisit_test.dart`. Die Integration wird in einem separaten Draft-PR vom aktuellen `main` geprüft; bestehende Spielstände und Regelzustände bleiben unverändert.

### 2026-11-10 – Wiederherstellungsversuche gegen Datenverlust absichern

- Zwei SQLite-Regressionstests prüfen den wiederholten Import einer älteren Sicherung nach App-Neustart und mehrere fehlerhafte JSON-Formate. Erwartet werden Konflikt- bzw. Validierungsfehler ohne Überschreiben bestätigter Kampagnen, ohne angelegte Teilkampagnen und ohne zusätzliche Revisionsstände.
- **Branch:** `test/chat-d/backup-import-retry-integrity-20261110`. Tests sind hinzugefügt, CI-Abnahme nach PR-Erstellung ausstehend. Keine Änderung an Datenbankschema, Importformat, App-Version oder produktivem Speicherverhalten.

### 2026-11-10 – Verlinkte Repositorywurzel beim Upload-Check zurückweisen

- Der Quellübertragungs-Validator `scripts/verify_project.py` lehnt nun eine symbolisch verlinkte Repositorywurzel vor Datei- und ZIP-Zugriffen ab. Ein Regressionstest stellt sicher, dass die externe Projektstruktur nicht gelesen oder ihr Pfad in der Fehlermeldung ausgegeben wird.
- **Branch:** `fix/chat-d/verify-project-root-symlink-20261110`. CI-Prüfung nach PR-Erstellung ausstehend; keine Änderungen an Spielständen, Datenbankschema, App-Laufzeit oder Buildversion.

### 2026-11-11 – Heilige Flamme: Gegnerdaten bei Live-Wechsel neu bestätigen

- **Problem:** Ein geöffneter Heilige-Flamme-Dialog übernahm manuell eingegebenen GES-Rettungswurfbonus und Situationsbestätigungen auch dann, wenn der aktive Held oder Gegner aktualisiert wurde.
- **Lösung:** Bei einem neuen Helden- oder Gegner-Snapshot werden GES-Rettungswurfbonus und alle zugehörigen Checkbox-Bestätigungen sowie alte Fehlermeldungen verworfen. Ein unveränderter Parent-Rebuild erhält den nicht abgesendeten Entwurf.
- **Dateien:** `app/lib/ui/sacred_flame_dialog.dart`, `app/test/sacred_flame_live_snapshot_test.dart`.
- **Branch:** `feat/chat-c/sacred-flame-live-snapshot-20261111`; Code- und Testcommit `adf150def1cfd8fce51e4ff709eeda035030a3d0`.
- **Prüfungen:** Drei neue positive/negative Widgettestfälle hinzugefügt. Automatische Flutter-/Android-Prüfungen des finalen Branches stehen zum Zeitpunkt dieses Eintrags noch aus.
- **Kompatibilität:** Nur UI-Entwurfsdaten betroffen; keine Änderung an Regeln, JSON, SQLite, Spielstandschema oder App-Version und keine Migration.


### 2026-11-11 – Nebenhandangriff nach Helden- und Zielwechsel erneut bestätigen

- **Problem:** Ein geöffneter Nebenhandangriff-Dialog konnte die bereits gewählte Waffe, Waffenübung und Zustimmung über einen neuen Helden- oder Gegner-Snapshot hinweg beibehalten.
- **Lösung:** Der Dialog verwirft bei geänderten Heldenreferenzen oder Zielnamen sämtliche unbestätigten Auswahlen und Bestätigungen. Die Waffen-Auswahl wird als neues Flutter-FormField aufgebaut, damit ein alter Dropdown-Wert nicht erhalten bleibt; bei unverändertem Rebuild bleibt die gültige Eingabe bestehen.
- **Betroffene Dateien:** `app/lib/ui/offhand_attack_dialog.dart`, `app/test/offhand_attack_live_snapshot_test.dart`.
- **Branch:** `feat/chat-c/offhand-live-snapshot-reset-20261111`; **Code- und Testcommit:** `a50470cd6128a11c9cfe9b38ba925118a8b156aa`; Pull-Request- und finaler CI-Nachweis folgen über GitHub.
- **Tests:** Drei neue Widgettests für unveränderte Daten, Heldenwechsel und Zielwechsel ergänzt. Flutter/Dart lokal nicht vorhanden; Ausführung und Android-APK auf dem aktuellen PR-HEAD noch nicht bestätigt.
- **Kompatibilität:** Keine Änderung an Regeln, Controller, persistierten Spielständen, SQLite, JSON oder App-Version; keine Migration.

### 2026-11-11 – Rückreisen von bloßen Wortbestandteilen unterscheiden

- Rabenwacht: Rückreisen werden nur durch eigenständige Bewegungsverben ausgelöst; Begriffe wie „Vorgehen“ oder „Reisebericht“ lösen keinen Ortswechsel aus. Regressionstests prüfen beide Richtungen.
- Der präzisierte Regressionstest trennt bloße Ortsnennungen von einer eigenständigen Kapellenuntersuchung, die weiterhin zum Archiv führen darf. Originaländerung und Verlauf: PR #684, finaler Quell-Commit `b9836aecd8507cf0af96685643cc6e28801d988f`.
- **Tests:** Eine ältere CI #42957164227 bestand 3.353 Flutter-Tests, ein neuer Test scheiterte an einer falschen Erwartung und wurde korrigiert. Die CI auf dem konsolidierten Integrationsstand steht aus. Keine JSON-/SQLite-Migration.





### 2026-11-05 – Mönch: Sanfter Fall mit geprüften Klassenprofilen

Die Stufe-4-Reaktion **Sanfter Fall** berechnet den Schadensschutz weiterhin aus der tatsächlichen Mönchsstufe, lehnt jetzt aber ungültige Haupt-/Nebenklassen, doppelte Alias-Klassen, unbekannte Klassen und widersprüchliche Stufen ab. Gültige deutsche/englische Namen und Mehrklassen bleiben wirksam; eine bloße Erzählung löst keine Reaktion aus. Geändert: `app/lib/domain/srd_monk_slow_fall_rules.dart`, neu: `app/test/srd_monk_slow_fall_class_preflight_test.dart`. [PR #579](https://github.com/ManuEtt/Dnd/pull/579), Branch `feat/chat-a/monk-slow-fall-class-preflight-20261105`. Regelquelle: SRD 5.2.1, Monk / Level 4 Slow Fall, CC BY 4.0. Requirement `CLASS-M-NCH-4-BASE-SLOW-FALL-1` bleibt `partial` (keine vollständige End-to-End-Automatik). Keine JSON-/SQLite-Migration. CI-Prüfung des finalen PR-HEAD noch offen; lokale Dart-/Flutter-Tests mangels SDK nicht ausgeführt.




### 2026-11-05 – Waldläufer: Wilde Sinne nur aus gültigen Klassenprofilen

Die Blindsicht-Reichweite von 30 Fuß ab Waldläufer-Klassenstufe 18 wird nur noch aus einem konsistenten bestätigten Haupt-/Nebenklassenprofil angeboten. Ungültige Aliasdoppelungen, unbekannte Klassen, verwaiste Zweitstufen und Stufen außerhalb 1–20 gewähren weder Reichweite noch eine positive Distanzprüfung. Gültige deutsche/englische Klassenaliase und Mehrklassenkombinationen bleiben wirksam; es wird kein tatsächliches Entdecken versteckter Gegner behauptet. Dateien: `app/lib/domain/srd_ranger_feral_senses_rules.dart`, `app/test/srd_ranger_feral_senses_class_preflight_test.dart`. Branch `feat/chat-a/ranger-feral-senses-class-preflight-20261105`, PR/CI siehe GitHub. SRD 5.2.1, Ranger 18 / Feral Senses, CC BY 4.0, Requirement `CLASS-WALDL-UFER-18-BASE-FERAL-SENSES-0` bleibt `partial`. Keine Speicher-/JSON-/SQLite-Migration; lokale Dart-/Flutter-Tests nicht ausführbar, finale PR-CI separat nachweisen.




### 2026-11-05 – Relative vollständige Deckung beim Zusatzkreaturen-Angriff

Die manuelle Kampfregel prüft vollständige Deckung jetzt relativ zum ausdrücklich bestätigten Standort des Angreifers: Ein Ziel ist nur dann durch das Hindernis direkt unzulässig, wenn der Angriff von der gegenüberliegenden Seite ausgeht. Auf derselben Seite wird die Hindernis-Deckung ignoriert. Die bestehenden Ziel-, Reichweiten- und Einmalaktions-Schranken bleiben aktiv. Geändert: `app/lib/domain/srd_extra_creature_attack_rules.dart` und `app/test/srd_extra_creature_attack_test.dart`, zusätzliche Domänen- und Speicher-/Event-Regressionen. Branch `fix/chat-a/extra-creature-relative-total-cover-20261105`; Pull Request und finalen CI-Status im GitHub-Verlauf prüfen. Keine Änderungen an bestehenden JSON-/SQLite-Formaten, keine Migration. SRD 5.2.1, *Combat / Cover*, CC BY 4.0; `RULE-COMBAT-COVER` bleibt unverifiziert, da Gesamtdeckungs-/Geländeregeln nicht abschließend implementiert sind. Lokale Flutter-/Dart-Tests mangels SDK nicht durchgeführt; CI vor Integration notwendig.



### 2026-11-05 – JSON-Export bei großer Schrift und langen Spielständen

Der JSON-Exportdialog zeigt Titel, Speichern-Aktion, Status und vollständigen auswählbaren JSON-Text auf einer gemeinsamen scrollbaren Dialogfläche. Die zwei vorhandenen Aktionen „Schließen“ und „Kopieren“ sowie Schutz während laufender Dateiauswahl bleiben erhalten. Kompaktere Dialogränder helfen auf 320/360-dp-Android-Anzeigen bei 200 % Schrift und eingeschränktem Platz durch die Bildschirmtastatur.

Sechs neue Widgettests für lange JSON-Texte prüfen vollständiges Kopieren und Dateispeichern, explizites Schließen, laufende Dateidialog-Sperren, Dateiabbruch und sichere Screenreader-Live-Fehleransagen. Branch `feat/chat-c/backup-export-large-text-20261105`, [PR #583](https://github.com/ManuEtt/Dnd/pull/583) (Draft). GitHub-Flutter-/Android-CI zum Zeitpunkt dieses Nachtrags noch offen, kein reales Android/TalkBack abgenommen. Kein Eingriff in SQLite-/JSON-Format, BackupFiles, Regelengine, App-Version oder Berechtigungen und keine Migration.




### 2026-11-05 – Bardische „Quelle der Inspiration“ gegen Klassenprofil-Manipulation absichern

Die bestätigte Umwandlung eines Zauberplatzes oder passenden Paktplatzes in Bardische Inspiration ab eigener Bardenstufe 5 lehnt nun ungültige Haupt- und Zweitklassen, doppelte Aliase und widersprüchliche Stufen vor jeder Ressourcenbuchung ab. Auch ein manuell konstruierter, vermeintlich gültiger Vorschlag wird beim Einlösen erneut geprüft. Gültige Bard-/Bardin-Aliase, legale Mehrklassenprofile, Event-/Revisionsschutz sowie alte Speicherformate bleiben erhalten. Fachmodul `app/lib/domain/srd_bard_font_of_inspiration.dart`, neue Regression `app/test/srd_bard_font_class_preflight_test.dart`. Branch `fix/chat-a/bard-font-class-profile-20261105`; Pull Request und finalen CI-Status bei GitHub prüfen. SRD 5.2.1, Bard / Font of Inspiration, Wizards of the Coast LLC, CC BY 4.0. Requirement `CLASS-BARDE-5-BASE-FONT-OF-INSPIRATION-0` bleibt `partial`, keine Migration (SQLite 3 / JSON 1). Lokale Dart-/Flutter-Tests ohne SDK nicht ausgeführt; finale CI steht aus.



### 2026-11-05 – Strukturierte NPC-Identitäten gegen unsichtbare Unicode-Zeichen

Die strukturierte Übergabe bestätigter NPC-Erinnerungen an den optionalen KI-Erzähler schützt jetzt auch vor älteren unsichtbaren Zeichen (U+00AD, U+034F, U+180E sowie U+206A–U+206F). Bei der Namenszuordnung werden visuell identische Figuren nicht mehr anhand solcher Zeichen auseinandergehalten; unsichere Rohwerte in Namen, Beziehungen und Notizen gelangen nicht in strukturierte Identitätskontexte. Saubere ausdrücklich gewählte NPC-IDs bleiben nutzbar. Betroffen: `app/lib/story/npc_identity_story_payload.dart` und neue Regressionen in `app/test/npc_identity_legacy_unicode_payload_test.dart`, darunter SQLite-Neustart sowie JSON-/Revisionsschutz. [Pull Request #582](https://github.com/ManuEtt/Dnd/pull/582), Ausgangscommit `0e4474c5`; die vollständige CI auf dem finalen Pull-Request-Stand ist bis zum konkreten Nachweis offen. Keine Änderung von Regelwerten, gespeicherten Daten, Anbieterberechtigungen, Schema oder App-Version; keine Migration. Eine Geräteabnahme bleibt erforderlich.



### 2026-11-06 – Verständliche Sperrhinweise für die vier Abenteuer-Schnellaktionen

Bei laufender Spielaktion sind `Sprache`, `Untersuchen`, `Angriff` und `W20` weiterhin gesperrt. Alle vier Aktionen erklären TalkBack nun durch denselben eindeutigen Hinweis, dass bereits eine Handlung verarbeitet wird. Im Leerlauf bleibt die konkrete Begründung eines nicht verfügbaren Angriffs erhalten; die übrigen Aktionen erhalten keinen veralteten Sperrhinweis. Touch-, Tab-/Enter-, Mikrofon-, Würfel- und Aktionsverhalten bleiben unverändert.

Fünf neue Flutter-Widgettests prüfen 320/360 dp bei 200 % Schrift und geöffneter Tastatur, jeweils eindeutige Screenreader-Beschriftung, Busy-Hinweise, ausbleibende unerlaubte Aktionen sowie die wiederhergestellte Bedienbarkeit nach Ende der Sperre. Fachdatei `app/lib/ui/fantasy_art.dart`, Test `app/test/fantasy_quick_actions_busy_semantics_test.dart`. Branch `feat/chat-c/quick-actions-busy-semantics-20261106`, [PR #588](https://github.com/ManuEtt/Dnd/pull/588) (Draft). CI auf dem finalen PR-HEAD und echte Android-/TalkBack-Geräteabnahme zum Zeitpunkt des Nachtrags noch offen. Keine Regel-, Story-, JSON-/SQLite-, Berechtigungs-, Backup- oder Versionsänderung; keine Migration.



### 2026-11-06 – Sichtbare NPC-Identitäten im Kampagnengedächtnis

In bestätigten Erinnerungsabrufen und Sitzungsrückblicken werden ältere unsichtbare Unicode-Formatmarken in NPC-Namen nun beim Vergleichen und Anzeigen neutralisiert. Haben zwei Figuren dadurch denselben sichtbaren Namen, werden die jeweils gültigen, eindeutigen gespeicherten NPC-IDs zur Unterscheidung angezeigt; unklare oder ungültige IDs werden nicht als gesicherte Identitäten ausgegeben. Auch Rückfragen mit diesen unsichtbaren Zeichen finden die richtigen bestätigten Erinnerungen. Die Änderung betrifft ausschließlich die lesende Darstellung in `app/lib/story/story_memory_engine.dart` mit vier neuen Regressionstestgruppen in `app/test/story_memory_npc_legacy_format_test.dart` für Namensdublette, unsichere IDs, deutsche Umlaute/Emoji, Sitzungsrückblicke, JSON und SQLite-Neustart. Branch `feat/chat-b/npc-memory-hidden-name-identity-20261106`, [PR #590](https://github.com/ManuEtt/Dnd/pull/590). **CI für den finalen PR-HEAD zum Zeitpunkt dieses Nachtrags noch nicht abgeschlossen**; Geräteabnahme steht aus. Keine Änderung von gespeichertem NPC-Text, Spielregeln, API-Schnittstellen, JSON-/SQLite-Schema oder App-Version; keine Migration erforderlich.




### 2026-11-06 – Gewählter Kampfstil mit zwei Waffen für Paladin und Waldläufer

Der zusätzliche Light-Nahkampfangriff berücksichtigt den ausdrücklich gewählten Kampfstil `Kampfstil: Kampf mit zwei Waffen` nun neben Kämpfern ab Klassenstufe 1 auch für **Paladine und Waldläufer ab ihrer jeweiligen Klassenstufe 2**. Dadurch zählt der bestätigte Attributsmodifikator zum Schaden der Nebenhand einmal; ohne gewählten Stil oder bei unplausibler Haupt-/Zweitklassenverteilung bleibt der bisherige Light-Schaden bestehen. Deutsche/englische SRD-Klassenaliase, Mehrklassenprofile und die erforderliche separate Waffenübung bleiben berücksichtigt. Fachdatei `app/lib/domain/two_weapon_fighting_rules.dart`, neuer Test `app/test/two_weapon_style_class_eligibility_test.dart`, Fachbeleg `docs/SRD_LIGHT_BONUS_ATTACK_20261025.md`. Branch `fix/chat-a/two-weapon-style-paladin-ranger-20261106`; PR/CI siehe GitHub. D&D SRD 5.2.1 (Classes / Fighting Style, Feats / Two-Weapon Fighting, Equipment / Light), Wizards of the Coast LLC, CC BY 4.0. `RULE-COMBAT-TWO-WEAPON-FIGHTING` bleibt `partial`. Keine Schema-, JSON-, SQLite-, UI- oder Versionsänderungen, keine Migration. Lokale Dart-/Flutter-Tests mangels SDK nicht ausgeführt; vollständige Actions-Abnahme auf dem endgültigen PR-Commit ausstehend.



### 2026-11-06 – Typisierte NPC-Erinnerungen ohne versteckte Unicode-Formatzeichen

Die schreibgeschützte Ausgabe bestätigter NPC-Identitätskontexte normalisiert nun auch ältere unsichtbare Unicode-Format- und Richtungszeichen. Sie verbindet Namensfragmente bei der Anzeige korrekt und trennt Notiz-/Beziehungstext dagegen mit Leerzeichen; Steuer- und Zeilenzeichen werden ebenfalls aus der Kontextausgabe entfernt. Nur eindeutige, kanonische NPC-IDs mit 1–64 ASCII-Zeichen sind für solche Kontexte zulässig. Gespeicherte Rohwerte bleiben für Revisions- und Änderungsvergleiche unverändert. Das Fachpaket umfasst `app/lib/story/npc_identity_memory.dart` und vier neue Regressionstestgruppen in `app/test/npc_typed_context_legacy_marks_test.dart` (Legacy-Formatmarken, Zeilen-/Steuerzeichen, ungültige IDs, altes JSON und SQLite-Neustart). [Pull Request #593](https://github.com/ManuEtt/Dnd/pull/593), Branch `feat/chat-b/npc-typed-context-legacy-main-20261106`, Basis-`main` `9a0fa855`. **Die vollständige GitHub-CI auf dem finalen PR-HEAD steht bis zur tatsächlichen Bestätigung aus.** Keine Änderung gespeicherter Spielstände, Regelwerte, JSON-/SQLite-Schemata oder App-Version; keine Migration erforderlich. Reale Geräte- und produktive Anbieterprüfungen bleiben offen.



### 2026-11-06 – Vollständig lesbare Zustandskreis-Verwaltung bei großer Schrift

Die Aktionen „Zauberwirkungen verwalten“ und „Zustandsquellen verwalten“ im Charakter- und Kampf-Zustandskreis bleiben auf 320/360-dp-Android-Displays bei 200 % Schrift vollständig lesbar: Bei schmalem Inhalt erscheinen sie vollbreit mit automatisch umbrechenden Beschriftungen. Bei normaler Schrift behalten sie ihre bisherige kompakte Icon-Schaltfläche. Die Buttons behalten dieselben IDs und öffnen ausschließlich die bestehenden Bestätigungsdialoge; fehlende Verwaltungsaktionen werden weiterhin nicht angeboten.

Fünf neue Widgettests prüfen 320/360 dp, 200 % Text und simulierte 220 dp Bildschirmtastatur, mehrzeilige Beschriftung, sichtbare Touchflächen, getrennte Callback-Auslösung, fehlende Aktionen sowie den unveränderten Spielstand. Betroffen sind `app/lib/ui/fantasy_effect_ward.dart` und `app/test/fantasy_ward_management_large_text_test.dart`. Arbeitsbranch `feat/chat-c/ward-management-large-text-20261106`, [PR #591](https://github.com/ManuEtt/Dnd/pull/591) (Draft). Flutter-/Android-CI und echte Android-/TalkBack-Prüfung sind zum Zeitpunkt dieses Eintrags noch offen. Keine Änderungen an Regelengine, JSON, SQLite, Backup, Version oder Berechtigungen; keine Migration.




### 2026-11-06 – Klassenmerkmalskatalog und automatische Werte gegen widersprüchliche Profile absichern

Freigeschaltete SRD-Klassenmerkmale und die lesenden Ressourcen-/Klassenwert-Zusammenfassungen werden aus konsistenten Haupt-/Nebenklassenstufen abgeleitet. Bei unbekannten Klassen, doppelten deutschen/englischen Klassenaliasen, fehlenden oder verwaisten Zweitstufen sowie Gesamtstufen außerhalb 1–20 werden keine fälschlichen Freischaltungen und keine numerischen Ansprüche angezeigt. Gültige mehrklassige Charaktere, kanonische Aliase und die Unterscheidung zwischen Feature-Katalog und tatsächlich implementierter Regelwirkung bleiben erhalten. Betroffen: `app/lib/domain/srd_class_feature_catalog.dart`, `app/lib/domain/srd_class_automation.dart`, neuer Test `app/test/srd_class_feature_profile_preflight_test.dart`. Branch `fix/chat-a/class-feature-catalog-profile-20261106`; PR/CI-Fortschritt siehe GitHub. Quelle: D&D SRD 5.2.1, Klassen-/Stufenmerkmale (Wizards of the Coast LLC, CC BY 4.0). Kein neues SRD-Merkmal als vollständig implementiert ausgewiesen. Kein JSON-/SQLite-/Event-Schemawechsel, keine Migration. Lokale Dart-/Flutter-Tests mangels SDK nicht ausgeführt; finale GitHub-Actions-CI separat prüfen.




### 2026-11-06 – Normale Mehrklassen-Zauberplätze nur für stimmige Klassenprofile

Die Berechnung kombinierter Zauberklassenstufen prüft jetzt das gesamte SRD-Haupt-/Zweitklassenprofil, bevor reguläre Zauberplätze freigegeben oder verbucht werden können. Ein unbekannter Hauptklassenname kann keine Plätze aus einer bekannten Zweitklasse mehr erzeugen; doppelte kanonische Klassenaliase, ungültige Gesamt-/Nebenstufen und verwaiste Nebeneinträge werden ebenfalls gesperrt. Gültige englische/deutsche Aliase, Paladin-/Waldläufer-Halbzauberstufen und die separate Hexenmeister-Paktmagie bleiben nutzbar. Betroffen sind `app/lib/domain/multiclass_rules.dart`, der korrigierte Alt-Test `app/test/multiclass_spell_slot_alias_test.dart` und neue Regressionen in `app/test/multiclass_spell_slot_class_profile_test.dart`. Branch `fix/chat-a/multiclass-normal-slots-profile-20261106`; PR und CI-Status siehe GitHub. SRD 5.2.1, Multiclassing / Spellcasting, S. 25 (CC BY 4.0); Requirements `RULE-CHARACTER-CREATION-MULTICLASS-SPELLCASTING` und `RULE-SPELLS-SPELL-SLOTS` bleiben `unverified`, da die gesamte Zaubermechanik nicht vollständig implementiert ist. Keine Datenmodell-, JSON-/SQLite-, UI- oder Schema-Migration, kein Versionswechsel. Lokale Dart-/Flutter-Tests mangels SDK nicht ausgeführt; finale GitHub-CI separat nachweisen.



### 2026-11-06 – Ausgelöste Zauberwirkzeiten gegen falsche Identitäten absichern

Acht im SRD-5.2.1-Arbeitskatalog enthaltene Reaktions- bzw. ausgelöste Bonusaktionszauber werden in der Domänenprüfung nun mit ihren **exakten Wirkzeitangaben und Zaubernamen** verglichen. Erfundenen, vertauschten oder verkürzten Auslösertexten wird keine gültige Wirkzeitklassifizierung mehr gegeben; auch eine Umdeklaration eines solchen Zaubers zu einer gewöhnlichen Aktion wird abgewehrt. Dies erlaubt noch keinen tatsächlichen Reaktionszauber ohne gesondert bestätigten Auslöser.

Betroffen: `app/lib/domain/srd_spell_casting_time_rules.dart` und `app/test/srd_spell_casting_time_integrity_test.dart`; die vorhandenen normalen Action-/Ritualpfade bleiben unverändert. [Pull Request #597](https://github.com/ManuEtt/Dnd/pull/597), Branch `fix/chat-a/triggered-spell-casting-time-identity-20261106`, Fachcode/Test-HEAD `b3b6b502ab1bc93c6a15e135831b7ff8ebb138e4`. Ein statischer Vergleich aller acht Zuordnungen mit dem Katalog war erfolgreich; **Dart-/Flutter-Tests und vollständige GitHub-CI auf finalem Commit sind noch nicht nachgewiesen**. Keine Änderung an Spielstandformat, JSON, SQLite, App-Version oder Schnittstellen; keine Migration. Reale Android-Abnahme offen. Quelle: Wizards of the Coast LLC, [SRD 5.2.1](https://www.dndbeyond.com/srd), CC BY 4.0.



### 2026-11-06 – Wiederaufnahmekontext gegen ältere Unicode-Formatmarken abgesichert

- **Problem:** In gespeicherten Szenen, Rückblicken, Fakten und offenen Handlungsnotizen konnten die Legacy-Formatmarken U+00AD, U+034F, U+180E sowie U+206A–U+206F die schreibgeschützte Wiederaufnahmeprojektion erreichen.
- **Lösung:** `CampaignResumeReader.read` neutralisiert diese Zeichen nun in der Anzeige, bewahrt dabei normalen Unicode und prüft unverändert den vollständigen Rohquellstand auf veraltete Revisionen. Weder erzählte Behauptungen noch die Anzeige ändern bestätigte Regeln.
- **Code und Nachweise:** `app/lib/story/campaign_resume_context.dart`, `app/test/campaign_resume_legacy_format_marks_test.dart`, [PR #598](https://github.com/ManuEtt/Dnd/pull/598), Branch `feat/chat-b/resume-legacy-format-marks-20261106`, Fach-/Teststand `49be541a4d2a841d09d182c424f202b8440c2166`.
- **Tests:** Drei neue Flutter-Regressionen zu veralteten Formatmarken, unverändertem Unicode/Quellstempel und SQLite-Neustart ergänzt; bei Veröffentlichung dieses Eintrags noch nicht lokal ausgeführt und finale GitHub-CI noch nicht bestätigt.
- **Kompatibilität:** Keine JSON-/SQLite-Migration, keine Versionsanhebung, keine Änderung persistierter Rohtexte, Helden-, Quest- oder Kampfdaten. Reales Android-Gerät und Produktiv-KI nicht getestet.




### 2026-11-06 – Eldritch Blast: ungültige Trefferpunkte vor dem Würfeln sperren

Der bereits bestehende, separat bestätigte Eldritch-Blast-Strahlenresolver blockiert nun auch negative aktuelle Trefferpunkte, maximal 0 TP und aktuelle TP oberhalb des belegten TP-Maximums. Solche inkonsistenten Direkt-/Alt-Snapshots dürfen nicht länger Angriffs- und Schadenswürfe auslösen. Sieben Negativfälle prüfen die vollständige Sperre ohne Zufallsverbrauch und ohne Veränderung des Helden-JSON; positive Grenzfälle bei 1 TP und optional unbekannten Legacy-TP-Feldern erhalten die bestehende Strahlen-/Schadensberechnung. Fach- und Testdateien: `app/lib/domain/srd_eldritch_blast_rules.dart`, `app/test/srd_eldritch_blast_rules_test.dart`; Branch `fix/chat-a/eldritch-blast-hp-preflight-20261106`; PR und abschließendes Actions-Ergebnis siehe GitHub. Quelle: D&D SRD 5.2.1, *Dropping to 0 Hit Points / Eldritch Blast*, Wizards of the Coast LLC, CC BY 4.0. `SPELL-ENTRY-ELDRITCH-BLAST` bleibt `partial` – keine vollständige Zauber-, Kampf- oder Regelautomation. Keine Änderungen an JSON/SQLite, GameEngine, UI, Backend oder App-Version; keine Migration. Lokale Dart-/Flutter-Tests mangels SDK nicht ausgeführt; CI auf finalem PR-HEAD ausstehend.



### 2026-11-06 – Entwürfe für NPC-Beziehungsnotizen sicher trennen

**Problem:** Beim Wechsel der ausgewählten Figur im Dialog „NPC-Beziehung festhalten“ blieb die unbestätigte Erklärung des vorherigen NPC im Eingabefeld. Sie hätte bei versehentlicher Bestätigung einem anderen NPC zugeordnet werden können.

**Lösung:** Die Erklärung wird beim Wechsel der NPC-ID zurückgesetzt und das zugehörige Formularfeld NPC-spezifisch neu erzeugt. Zwei Flutter-Widgetregressionen prüfen den Zielwechsel, die zwingend neue Erklärung vor Bestätigung, eine neue bestätigte Notiz und das folgenlose Abbrechen. Das Beziehungsfeld folgt weiterhin der ausdrücklich ausgewählten NPC-ID.

**GitHub:** Branch `feat/chat-c/npc-relationship-note-reset-20261106`; Fach-/Test-Commit `bc9fe9f24554980e180cfa5c3057b80331237f8d`; [PR #596](https://github.com/ManuEtt/Dnd/pull/596) (Draft). Der Main-CI-Lauf [#42168660349](https://github.com/ManuEtt/Dnd/actions/runs/42168660349) war vor der Änderung erfolgreich; die Flutter-/Android-Prüfungen für den endgültigen PR-HEAD sind separat abzunehmen.

**Kompatibilität und Grenzen:** Keine Spielstands-, Regel-, Story-, SQLite-/JSON-, Backend-, Berechtigungs- oder App-Versionsänderung und keine Migration. Native Android-IME-/TalkBack-Geräteabnahme noch offen.



### 2026-11-06 – Kampfstatus bei großer Schrift vollbreit darstellen

**Problem und Lösung:** In der Begegnungsübersicht erscheinen bestätigte Angriffs-/Schild- und Reaktionshinweise bei unter 500 dp Inhalt und ab 180 % Textskalierung jetzt jeweils in einer eigenen vollbreiten Zeile. Der bisherige kompakte Wrap bei Standard-Schriftgröße bleibt erhalten; bestehende TalkBack-Labels und bestätigte Kampfwerte bleiben unverändert.

**Tests:** Neue Widget-Regressionen in `app/test/fantasy_combat_threat_large_text_test.dart` für 320/360 dp, 200 % Schrift, 220 dp Tastaturbereich, semantisch einzeln lesbare Statusmeldungen, unverändertes Standardlayout und ausgeblendete aktive Meldungen nach Kampfende. Die GitHub-Actions-Abnahme auf dem finalen PR-Commit erfolgt separat; bei Veröffentlichung dieses Nachtrags ist noch kein neuer vollständiger CI-Erfolg nachgewiesen.

**Nachweis:** `app/lib/ui/fantasy_combat_threat_status.dart` und die neue Testdatei; Branch `feat/chat-c/combat-threat-wide-seals-20261106`, [PR #603](https://github.com/ManuEtt/Dnd/pull/603) (Draft). Ursprüngliche Basis `9a0fa855374a67805e531ad8574e048d99b33745`, anschließend aktuelle Main-Änderungen aus `95c605898f1bcae26e0a23afa55c767ec5b20744` als mergefähige Git-Historie aufgenommen.

**Kompatibilität:** Keine Änderung an Spielstand-, JSON-/SQLite-, Regel-, Story-, Backend- oder Controller-Verträgen, Berechtigungen und App-Version. Keine Migration. Reale Android-TalkBack-/IME-Bedienung und produktive Signierung bleiben getrennt zu prüfen.




### 2026-11-06 – Perfekter Fokus benötigt konsistente Klassenstufen

Die automatische Fokusregeneration bei Initiative setzt jetzt bekannte, unterschiedliche Klassen und gültige Klassenstufen voraus. Widersprüchliche Altprofile bleiben unverändert und erhalten keine zusätzlichen Fokuspunkte. Gültige Mönchsaliase und Mönch 15/Kämpfer 2 behalten die bestehende Auffüllung auf vier Punkte. Der freiwillige Unheimliche Stoffwechsel wird dabei nicht automatisch gewählt; Trefferpunkte und andere Ressourcen bleiben unverändert. Regelquelle: SRD 5.2.1, Seite 52, CC BY 4.0.

Branch `fix/chat-a/monk-perfect-focus-profile-20261106`, Fachcommit `62e4544571f86ac5366b90ce2b91fab698e2eab7`, [PR #586](https://github.com/ManuEtt/Dnd/pull/586). **Gezielt bestanden:** 26 neue Domänen-, sechs echte SQLite-/Controller- und zwei App-UI-Fälle sowie 15 bestehende Fachtests. Alle drei Kampfstartpfade, tatsächlicher Alt-JSON-Import, Export/Import, Neustart, ID-Replay, veraltete Revision und später SQL-Rollback sind eingeschlossen. Die regulären Initiativewürfe bleiben bestehen; keine RNG-freie Kampfabweisung behauptet.

App-Version unverändert **0.8.52+102**, SQLite 3 / JSON 1 ohne Migration. Die vollständige lokale Prüfkette läuft auf unverändertem Regel-/Testcode; der finale aktuelle CI-Stand ist bei den [PR-Checks](https://github.com/ManuEtt/Dnd/pull/586/checks) und im abschließenden PR-Bericht nachgewiesen. Dieser Eintrag ist die eingefrorene Dokumentation vor Gesamtabnahme, kein vorweggenommener CI-Erfolg. Reales Gerät, TalkBack, tatsächliches Upgrade und produktive Signierung bleiben offen. Requirement `CLASS-M-NCH-15-BASE-PERFECT-FOCUS-0` wird anhand der tatsächlichen Wirkung konservativ als `partial` geführt. Nächster unabhängiger Schritt: nach frischem Main-/PR-Abgleich die Klassenberechtigung des ausdrücklich gewählten Unheimlichen Stoffwechsels vor Heilung, Fokus und Zusatzwürfel prüfen.


### 2026-11-06 – ZIP-Prüfungen mit aktuellem Main zusammengeführt

Main `84c6259b38c5f742198276ae3d3d0f80d0c4f51e` regulär in [PR #586](https://github.com/ManuEtt/Dnd/pull/586) übernommen; sämtliche neuen README-/Checkpoint-Inhalte bleiben erhalten. App-, Backend- und Androidquellen sind gegenüber dem bereits lokal vollständig geprüften Fokusstand unverändert: **3354 Flutter-, 341 Python- und 79 Backend-Tests**, ARM64-Debug und 14 native Fälle bestanden. Die ergänzten Python-Archivprüfungen werden erneut ausgeführt; finale kombinierte Abnahme über die aktuellen PR-Checks. Kein erfolgreicher noch laufender CI-Lauf vorweggenommen. Die lokale ARM64-Test-APK wird zusätzlich mit allen 30 generierten Buttonbildern gesichert; die bisherige CI-Alpha-Paketierung lässt diese Bilder aus und ist als separater Integrationshinweis dokumentiert.


### 2026-11-06 – Fokus-Nachweise getrennt vom Regelcode integriert

Die gemeinsamen Statusnachträge werden wegen wiederholter paralleler README-/Checkpoint-Konflikte in einem reinen Dokumentations-PR gebündelt. Der Regelcode und die 34 neuen Regressionen bleiben in [PR #586](https://github.com/ManuEtt/Dnd/pull/586); dieser Branch enthält keine neue Spielregel und keine bereits behauptete Main-Integration. Die aktuelle Code-CI ist über die PR-Checks nachgewiesen. Belegter vorheriger Code-Head `9eb6de6e`: vollständige [CI 42162661840](https://github.com/ManuEtt/Dnd/actions/runs/42162661840) mit 3354 Flutter-, 347 Python- und 79 Backend-Tests, Debug/native und allen drei ABIs erfolgreich. Die zusätzliche lokale ARM64-Test-APK enthält alle 30 generierten Buttonbilder; reale Android-, TalkBack- und Upgrade-Prüfung sowie produktive Signierung bleiben offen.



### 2026-11-06 – Selbstwiederherstellung bei ungültigen Klassenprofilen sperren

**Problem und Lösung:** Die Mönch-Fähigkeit *Selbstwiederherstellung* konnte bei ungültigen direkt konstruierten oder historischen Mehrklassenprofilen einen bestätigten Zustand beenden, weil lediglich die errechnete Mönchsstufe geprüft wurde. Die Regel prüft jetzt vor der Freischaltung Klassenidentitäten, kanonische Aliase und einen gültigen Stufensplit (Gesamtstufe 1–20). Gültige Mönche ab Klassenstufe 10 behalten ihre Wirkung und die notwendige ausdrückliche Auswahl bei mehreren heilbaren Zuständen.

**Code und Nachweis:** `app/lib/domain/monk_self_restoration.dart`, neue positive/negative Regressionen in `app/test/monk_self_restoration_class_preflight_test.dart`. Branch `feat/chat-a/monk-self-restoration-profile-20261106`, [PR #601](https://github.com/ManuEtt/Dnd/pull/601) (Draft), Code-/Integrationscommit `f2102a99d6d94aa0c64a362f9889abcadbbefa2b`. Lokale Dart-/Flutter-/Android-Tests waren ohne SDK **nicht ausführbar**. Die GitHub-Actions-Abnahme des finalen PR-Heads ist separat zu prüfen; es wird kein grüner Build behauptet.

**Kompatibilität und Grenzen:** SRD 5.2.1, Classes / Monk 10 / Self-Restoration (CC BY 4.0), Anforderung `CLASS-M-NCH-10-BASE-SELF-RESTORATION-1`. Keine Änderung an Spielfiguren-, Ereignis-, JSON-/SQLite-Schemas, Version, Story oder KI. Alte Spielstände bleiben lesbar und werden nicht verändert. Vollständige SRD-Wirkung und Geräteabnahme weiter offen.



### 2026-11-06 – Gespeicherte Rückblicke verwenden eindeutige Handlungsstrang-IDs

- **Problem und Lösung:** Die als bestätigt bezeichneten offenen Anknüpfungspunkte in neuen Sitzungsrückblicken verwendeten bisher alle gespeicherten `open`-Einträge. Der Story-Summarizer lässt jetzt nur kanonische ASCII-IDs mit 1–64 Zeichen und exakt einmaligem Vorkommen zu. Dadurch werden unsichere Legacy-IDs und widersprüchliche Open-/Closed-Dubletten nicht als gültige Fortsetzungshinweise präsentiert. Die bestehende Wiederaufnahmeansicht nutzt dieselbe Identitätsregel.
- **Umsetzung und Nachweis:** `app/lib/story/story_campaign_engine.dart`; neue Flutter-Regressionen in `app/test/story_recap_open_lead_id_integrity_test.dart` für erlaubte/unerlaubte IDs, doppelte Status, das Drei-Hinweise-Limit und den SQLite-Replay nach Neustart. Branch `feat/chat-b/recap-open-lead-id-integrity-20261106`, [PR #602](https://github.com/ManuEtt/Dnd/pull/602), Fach-/Testcommit `3cafb7a29079c0e6f47a67e0d04350b062c41941`.
- **Tests und Freigabe:** Vier neue Regressionen erstellt, lokale Dart-/Flutter-Tests mangels SDK nicht ausgeführt. GitHub-CI auf dem finalen PR-HEAD gesondert prüfen; keine Build-/APK-Freigabe allein aus geschriebenen Tests ableiten.
- **Kompatibilität:** Keine Änderung gespeicherter IDs, bestätigter Fakten, Helden-/Kampf-/Questwerte, SQLite-/JSON-Formate oder App-Version; keine Migration. Echte Geräteabnahme und Produktiv-KI bleiben separat offen.

**CI- und Integrationsstand (06.11.2026):** Der erste Formatierungsfehler wurde korrigiert; der anschließende Workflow [#42189711653](https://github.com/ManuEtt/Dnd/actions/runs/42189711653) endete während der SQLite-Installation als *abgebrochen*, nicht als bestandener Flutter-/Android-Nachweis. Die unveränderte Fachkorrektur wurde nun gegen das neuere `main` zusammengeführt, ohne dessen README-/Checkpoint-Nachträge zu ersetzen. CI des Merge-HEADs muss erneut geprüft werden.



### 2026-11-06 – Eindeutige Notizidentitäten für bestätigte NPC-Erinnerungen

- **Problem:** Die priorisierten NPC-Beziehungsnotizen im schreibgeschützten Erzählerkontext prüften bisher nur die Identität der benannten Figur. Historische Notiz-IDs mit Leerzeichen oder Formatmarken und doppelte IDs aus direkt konstruierten Legacy-Snapshots konnten dadurch als getrennte bestätigte Erinnerungen ausgegeben werden.
- **Lösung:** `NpcNarratorMemory.merge` berücksichtigt bei NPC- und Notiz-Identitäten nur eindeutige, kanonische ASCII-IDs mit 1–64 Zeichen. Notizkollisionen werden anhand *aller* gespeicherten Notizen erkannt, bevor eine für den Erzähler priorisiert wird. Korrekte Zeit-/Listenreihenfolge, Wire-Limits, unverdächtige allgemeine Fakten und die unveränderte lokale Regelautorität bleiben erhalten.
- **Code und Regressionen:** `app/lib/story/npc_narrator_memory.dart`, `app/test/npc_narrator_note_id_integrity_test.dart` (vier Fälle: Notizkollision am selben NPC, Kollision über mehrere NPCs, JSON-Legacy-IDs, SQLite-Neustart/Replay). Branch `feat/chat-b/npc-narrator-note-id-integrity-20261106`, [PR #605](https://github.com/ManuEtt/Dnd/pull/605), Code-/Teststand `9e6f7f33bdfb4d7cfe60fbfe76cc1784c74d2e7c`.
- **Teststatus:** Zum Zeitpunkt dieses Nachtrags nur Quellcode, Fachpfad-Abgleich und neue Testfälle gesichert. Die vollständige CI auf dem finalen PR-HEAD einschließlich Dart-Format, Flutter-Analyse/-Tests und Android-Build muss gesondert nachgewiesen werden; keine lokale Flutter-Toolchain, kein Realgerät oder kostenpflichtiger KI-Anbieter verwendet.
- **Kompatibilität:** Keine Änderung am gespeicherten NPC-Gedächtnis, an JSON-/SQLite-Schemas, Spielständen, Bestätigungsereignissen, SRD-Regeln, Version oder bestehenden UI-Funktionen; keine Migration.

**CI-/Integrationsnachtrag (06.11.2026):** Die vollständige [GitHub-CI #42194582591](https://github.com/ManuEtt/Dnd/actions/runs/42194582591) war für den ursprünglichen Fach-HEAD `2a2d6bad4926f84d070ba6c393c6cce2d96b8981` erfolgreich. Wegen neuer `main`-Änderungen wurden alle dortigen Dokumentationsnachträge erhalten und der PR-Branch durch einen Merge-Commit aktualisiert; für diesen neuen HEAD ist eine eigene vollständige CI-Abnahme erforderlich. Kein Merge in `main` und keine Geräteabnahme.



### 2026-11-06 – Handauflegen bei inkonsistenten Klassenprofilen sperren

**Problem und Lösung:** Bei ungültigen direkten bzw. historischen Charakterprofilen konnten unbekannte oder doppelte Klassen sowie unzulässige Stufensplits einen Paladin-Heilpunktevorrat freischalten. Die spezialisierte Handauflegen-Regel prüft nun die bekannten kanonischen Klassen und gültige Level-Verteilung vor der schreibfreien Pool-Anzeige sowie vor Heilung oder Entfernung von „Vergiftet“. Gültige Paladine behalten die SRD-5.2.1-Wirkung (Paladin 1 / Lay On Hands, CC BY 4.0) mit 5 Punkten je Paladin-Klassenstufe.

**Code und Nachweis:** `app/lib/domain/paladin_lay_on_hands.dart`, `app/test/paladin_lay_on_hands_class_preflight_test.dart` (positive und negative Klassen-/Grenz-/Alias-/JSON-Tests). Branch `feat/chat-a/paladin-lay-on-hands-profile-20261106`, [PR #609](https://github.com/ManuEtt/Dnd/pull/609), Draft. GitHub-Actions-Abnahme auf dem finalen PR-HEAD noch ausstehend; ohne lokal vorhandenes Dart-/Flutter-SDK wurde kein lokaler Testpass behauptet.

**Kompatibilität und Grenzen:** Kein Eingriff in Spielstands- und SQLite-/JSON-Schema, App-Version 0.8.52+102, GameEngine, KI, Story oder UI. Keine Migration; widersprüchliche Altprofile bleiben lesbar, aber lösen kein Handauflegen aus. Vollständige SRD-5.2.1-Abdeckung und reale Geräteabnahme weiterhin offen.



### 2026-11-06 – Vollständige NPC-ID-Prüfung bei expliziter Auswahl

Die explizite Wahl eines bereits gespeicherten NPCs akzeptiert jetzt ausschließlich eine **vollständig übereinstimmende** Kennung aus 1–64 ASCII-Zeichen (`A–Z`, `a–z`, Ziffern, `_` und `-`). Ein regulärer Ausdruck mit `hasMatch` konnte vorher bereits vor einem abschließenden Zeilentrennzeichen passen. So konnten historische IDs wie `mira\n` die Vorprüfung umgehen; die anschließende Story-Übertragung darf sich nicht allein auf einen späteren Schutz verlassen.

**Umsetzung:** `app/lib/story/npc_story_selection.dart` prüft die vollständige gespeicherte Kennung über `stringMatch(id) == id`. Vier neue Regressionstests in `app/test/npc_story_selection_terminal_id_test.dart` schützen reguläre und manipulierte IDs, gleichnamige NPCs, veraltete Entscheidungen, JSON-Altbestände sowie SQLite-Neustart und Replay.

**GitHub:** Branch `fix/chat-b/npc-selection-terminal-newline-id-20261106`, [PR #610](https://github.com/ManuEtt/Dnd/pull/610) (Draft), Code-/Teststand `231b98e1ad68e848674a3a4de87a61fcf5a73972`. Tests lokal nicht ausführbar (keine Dart-/Flutter-Toolchain); GitHub-CI auf dem finalen PR-HEAD separat auswerten. Vorherige PR-CI-Ergebnisse von #602/#605 zählen nicht als Test dieses Pakets.

**Kompatibilität:** Gespeicherte NPC-IDs, Beziehungsnotizen, Story-Inhalte, JSON/SQLite, Regel-/Quest-/HP-Werte und App-/Android-Version bleiben unverändert; keine Migration und kein KI-Provider-Aufruf. Gerätebetrieb und Store-Signierung sind gesondert zu prüfen.

### 2026-11-06 – Präzisierung und zusätzlicher Sitzungsnachweis bei NPC-Auswahl

**Fachliche Präzisierung zum vorherigen Nachtrag:** Der vorhandene Dart-RegExp-Ausdruck mit `^...$` ohne Multiline-Modus weist abschließende Zeilenumbrüche bereits zurück. Der neue Vergleich der vollständigen Match-Zeichenkette ist daher eine **zusätzliche defensive Sicherheitsprüfung**, keine nachgewiesene Fehlerbehebung dieses bereits abgewiesenen Eingabefalls.

**Tatsächliche Fehlerbehebung:** `NpcStorySelection.choose` wies bisher keine leere oder nur aus Leerraum bestehende `campaign.sessionId` zurück. Jetzt kann ein NPC nur ausdrücklich ausgewählt werden, wenn auch eine nichtleere Sitzungs-ID vorliegt. Das verhindert die Erzeugung scheinbar sitzungsgebundener Auswahlen aus unvollständigen In-Memory-Spielständen.

**Regressionen:** `app/test/npc_story_selection_terminal_id_test.dart` enthält jetzt fünf Tests, darunter einen gezielten zuvor fehlschlagenden Negativtest für `sessionId` mit `''`, Leerzeichen sowie Zeilenumbrüchen. Positive Entscheidungen, Legacy-JSON, SQLite-Neustart, Namensgleichheit, Revisionen und unveränderte Regelwerte bleiben abgedeckt.

**GitHub:** [PR #610](https://github.com/ManuEtt/Dnd/pull/610), Branch `fix/chat-b/npc-selection-terminal-newline-id-20261106`. Code-/Teststand `a6d02c839323b383272ba37309ec3912773ca0e7`. Der erste neue CI-Lauf [#42201211687](https://github.com/ManuEtt/Dnd/actions/runs/42201211687) scheiterte ausschließlich an `dart format` der neuen Testdatei; die kompakte Formatierung wurde daraufhin korrigiert, finale CI-Abnahme bleibt offen.

**Kompatibilität:** Keine Schema- oder Versionsänderungen, keine Migration, kein neuer KI-Aufruf, keine Mutation an gespeicherten Charakteren, NPCs, Quests oder Spielständen.




### 2026-11-06 – NPC-Wiederaufnahme nur mit gültiger Sitzungsidentität

Ein schreibgeschützter NPC-Rückblick durfte bisher aus einer unvollständig restaurierten oder direkt konstruierten Kampagne mit leerer Sitzungs-ID erzeugt werden. `ConfirmedNpcResumeSelector.read` verweigert jetzt leere und ausschließlich aus Whitespace bestehende Sitzungskennungen, bevor gespeicherte NPC-Beziehungen ausgewählt werden. Gültige Sitzungen bleiben unverändert; die Revision und gesicherte NPC-/Notizidentitäten werden wie bisher geprüft.

**Code und Nachweise:** `app/lib/story/confirmed_npc_resume_selection.dart`, drei deterministische positive/negative Fälle in `app/test/confirmed_npc_resume_session_guard_test.dart`; Code-Commit `6444570b1ad5d9fa7e539bef23ebe57aee9399f7`, Test-Commit `9aeb6ce8768a7831e1f0663230d18f068ea5b3fc`; Branch `fix/chat-b/npc-resume-session-guard-20261106`, [PR #611](https://github.com/ManuEtt/Dnd/pull/611) (Draft). Die Testdatei ist versioniert; lokaler Flutter-/Dart-Test und vollständige GitHub-CI auf dem abschließenden Dokumentations-HEAD sind noch nicht nachgewiesen.

**Kompatibilität:** Keine Änderung an Kampagnen-JSON, SQLite-Schema, bestätigten Spielregeln, Heldendaten oder App-Version; keine Migration. Die gemeinsame Dokumentation paralleler PRs muss beim Zusammenführen additiv erhalten bleiben. Reale Android-Geräteprüfung und produktiver KI-Test bleiben offen.



### 2026-11-06 – Manuelle Initiative-Zugfolge gegen ungültige Akteure absichern

Die Prüfung einer gespeicherten manuellen Zugfolge ignorierte bisher nicht mehr im lebenden Roster enthaltene Akteur-IDs. Direkt gebildete bzw. historische Kampagnen-Snapshots konnten deshalb eine zusätzliche unbekannte oder inzwischen entfernte ID besitzen, ohne dass die Zugfolge als veraltet galt. Jetzt müssen sämtliche Queue-IDs weiterhin zu Held, aktuellem Hauptgegner oder registrierten Zusatzkreaturen gehören; doppelte Rollen-IDs werden ebenfalls abgelehnt. Bereits besiegte, aber weiterhin registrierte Kreaturen dürfen wie bisher übersprungen werden.

**Regel und Nachweise:** D&D SRD 5.2.1, *Playing the Game / Combat / Initiative* (CC BY 4.0, https://www.dndbeyond.com/srd), `RULE-COMBAT-INITIATIVE` bleibt `partial`. Dateien: `app/lib/domain/srd_initiative_roster_rules.dart`, `app/test/srd_manual_turn_queue_test.dart`. Branch `feat/chat-a/manual-initiative-actor-integrity-20261106`, [PR #612](https://github.com/ManuEtt/Dnd/pull/612). Die Änderungen sind als Code- und Regressionstests eingecheckt; **Flutter-/Dart-Tests und Android-Build lokal mangels SDK nicht ausgeführt**, GitHub Actions auf finalem PR-HEAD noch nicht abgeschlossen.

**Kompatibilität:** Unverändertes JSON-1-/SQLite-3-Schema, keine Migration, keine Änderungen an bestehenden Kampfaktionen, App-/Backend-Versionen oder KI-/Story-Status. Gültige alte Zugfolgen bleiben erhalten, widersprüchliche Akteur-IDs werden bei erneuter Prüfung abgelehnt.




### 2026-11-06 – Ausrüstungskatalog bei großer Schrift und Tastatur bedienbar

Der SRD-Ausrüstungskatalog berechnet die Höhe seiner Suchergebnisse nun unter Berücksichtigung der eingeblendeten Android-Tastatur. Ein scrollfähiger Dialog und die eigene Aktionszeile je Gegenstand bei schmalem Display und mindestens 180 % Schriftgröße halten Name, Kategorie sowie Info-/Auswahlaktionen lesbar und erreichbar. Bei Standardschrift bleibt die bisherige kompakte Gegenstandsliste erhalten; nach der Such-IME-Aktion wird nur der Tastaturfokus geschlossen, keine Auswahl automatisch ausgelöst. Spielregeln, bestätigte Inventarwerte und Spielstände werden nicht verändert.

**Umsetzung und Prüfungen:** `app/lib/ui/equipment_catalog_dialog.dart` und die neuen Regressionen `app/test/equipment_catalog_large_text_ime_test.dart` für 320/360 dp, 200 % Schrift, offene Tastatur, explizite Auswahl und Abbruch sowie den Standardmodus. Branch `feat/chat-c/equipment-catalog-large-text-ime-20261106`, Fach-/Test-Commit `7fe870aab784880f7982c9fa1a298d50727d106c`, [PR #614](https://github.com/ManuEtt/Dnd/pull/614) (Draft). Flutter/Dart-Tests, Backend-/Python-/Android-Builds und CI des finalen PR-HEADs sind **noch nicht erfolgreich nachgewiesen**; Flutter-/Dart-SDK lokal nicht vorhanden, GitHub-Checkout lokal durch DNS blockiert. Echte TalkBack-/Android-Geräteprüfung separat offen.

**Kompatibilität:** Keine Änderung an SQLite, JSON, Regelwerk, Assets, Zugriffsrechten oder App-Version `0.8.52+102`; keine Migration. Der Pull Request wurde nicht in `main` integriert.


### 2026-11-07 – Scrollbare Ausrüstungssuche nach Widgettest-Regression abgesichert

Bei sehr großer Android-Schrift und eingeblendeter Tastatur können Suchfeld und Katalogtreffer so viel Platz beanspruchen, dass ein gesuchter Eintrag in der verzögert aufgebauten Liste zunächst außerhalb des sichtbaren Bereichs liegt. Die neuen Katalogtests scrollen deshalb vor der Prüfung ausdrücklich zum erwarteten Treffer oder zur Leermeldung; der Dialog bewahrt den eingetippten Suchbegriff auch dann, wenn die Suchzeile beim Scrollen neu aufgebaut wird. Die unverändert explizite Inventarauswahl nimmt keine Regel- oder Ressourcenbuchung vor.

**Nachweis:** `app/lib/ui/equipment_catalog_dialog.dart`, `app/test/equipment_catalog_large_text_ime_test.dart`, Branch `feat/chat-c/equipment-catalog-large-text-ime-20261106`, [PR #614](https://github.com/ManuEtt/Dnd/pull/614). Auf dem vorherigen Commit `30312de82392635abd012ea7d7677cf48ce082e6` meldete [CI #42288957572](https://github.com/ManuEtt/Dnd/actions/runs/42288957572) **3.321 bestandene, drei fehlgeschlagene Flutter-Tests**. Die zwei Folgekorrekturen `556707ed` und `3c26b441` sind eingecheckt; erfolgreiche CI auf dem finalen PR-HEAD ist noch nicht belegt. Keine SQLite-/JSON-Migration, keine Änderung an App-Version `0.8.52+102`, SRD-Regeln oder bestehender Speicherung. Android-Gerätetest, TalkBack, produktive Signierung und Integration weiterhin offen.




### 2026-11-07 – Bestätigte NPC-Chronik gegen doppelte Notizidentitäten absichern

Der schreibgeschützte NPC-Rückblick schließt jetzt Notizen aus, deren gespeicherte ID nicht exakt einem gültigen 1–64 Zeichen langen ASCII-Identifier entspricht oder kampagnenweit mehrfach verwendet wird. Der Filter erfolgt vor Zeitstempel-Sortierung und Notizbegrenzung: Zweifelhaftes kann damit keine ältere, eindeutig bestätigte Erinnerung verdrängen. Die Originaltexte und Spielstände werden dabei nicht verändert.

**Code/Nachweise:** `app/lib/story/npc_continuity_reader.dart`, vier neue positive/negative Tests in `app/test/npc_continuity_note_id_integrity_test.dart` (doppelte/unsichere IDs, Limit/Tie-Break, altes JSON, SQLite-Neustart). Branch `fix/chat-b/npc-continuity-note-id-20261107`; [PR #615](https://github.com/ManuEtt/Dnd/pull/615) (initial Draft). GitHub-Actions-Abnahme auf finalem Dokumentations-HEAD und echtes Android-Gerät stehen zum Zeitpunkt dieses Nachtrags noch aus. Vorherige CI-Nachweise anderer PRs gelten nicht als Testbeleg für diesen Stand.

**Kompatibilität und Grenzen:** Keine Änderung von SQLite-/JSON-Schema, Helden-/Regel-/Questzustand, App-Version oder KI-Provider. Keine Migration; valide eindeutige Altnotizen bleiben abrufbar. Gemeinsame Dokumentations-Nachträge anderer offener PRs müssen bei späterer Integration verlustfrei zusammengeführt werden.



### 2026-11-07 – Zauberfreigabe nur mit konsistentem Klassenprofil

Die SRD-Zauber-Vorabprüfung akzeptierte bisher eine bestätigte Zauberklasse auch dann, wenn der restliche direkt konstruierte oder historische Klassen-Snapshot widersprüchlich war (beispielsweise unbekannte Zweitklasse, doppelte Magier-/Wizard-Aliase oder unmögliche Klassenstufen). `SrdSpellPreflightRules.preflight` sperrt solche Profile jetzt vor der autoritativen Zauberplan-Erstellung; gültige Einzelklassen und Mehrklassen bleiben verwendbar. Zwei deterministische Testgruppen decken sowohl Zaubertricks als auch belegte Grad-1-Zauber, gültige deutsche/englische Klassenaliase, Ressourcenschutz und negative Profile ab.

**Regelbeleg:** D&D SRD 5.2.1, *Multiclassing / Spellcasting* (CC BY 4.0, https://www.dndbeyond.com/srd); `RULE-CHARACTER-CREATION-MULTICLASS-SPELLCASTING` bleibt `unverified`, da die übrigen Regelmechanismen nicht vollständig geprüft sind. **Code/Tests:** `app/lib/domain/srd_spell_preflight_rules.dart`, `app/test/srd_spell_preflight_profile_guard_test.dart`; Branch `feat/chat-a/spell-preflight-class-profile-20261107`, [PR #616](https://github.com/ManuEtt/Dnd/pull/616) (Draft; CI auf finalem PR-HEAD noch nachzuweisen). Lokal mangels Dart-/Flutter-SDK keine Flutter-Tests oder APK gebaut. Keine Veränderung am SQLite-/JSON-Format, keine Migration; alte gültige Spielstände bleiben kompatibel.

### 2026-11-07 – Präzisierung zur Reihenfolge der Klassenprüfung

Die Klassenkonsistenz wurde bisher bereits in einzelnen nachgelagerten Zauber-/Klassenhilfen überprüft. Die neue Änderung sichert **zusätzlich die öffentliche Zauber-Vorabprüfung vor jeder Vorbereitungsauskunft** ab: Selbst bei einem nicht vorbereiteten Zauber wird zunächst ein widersprüchliches Klassenprofil erkannt. Der zusätzliche Regressionstest prüft genau diese frühzeitige, eindeutige Ablehnung. Daraus folgt **nicht**, dass zuvor jeder Zauber mit einem ungültigen Profil erfolgreich gewirkt hätte. Der unveränderte SRD-Abdeckungsstatus, die fehlende automatische Zauberwirkung und die ausstehende finale CI gelten weiterhin.





### 2026-11-07 – Zauberressourcen bei ungültigen Verbrauchswerten sicher anzeigen

Der Dialog zur ausdrücklichen Bestätigung von Zauberressourcen zeigt bei widersprüchlichem gespeichertem Zauberplatz- oder Paktmagieverbrauch künftig eine verständliche Fehlermeldung, statt beim Öffnen abzustürzen oder die Werte als frei darzustellen. Die Bestätigung ist in diesem Fall deaktiviert; Abbrechen bleibt möglich. Bereits korrekt gespeicherte Werte und die ausdrücklich bestätigte Zauberauswahl werden weiterhin unverändert behandelt. Es werden weder Ressourcen noch Spielstände eigenmächtig geändert.

**Fachdateien:** `app/lib/ui/spellcasting_dialog.dart`, `app/test/spell_resource_dialog_invalid_state_test.dart`. **Branch:** `feat/chat-c/spell-resource-dialog-guard-20261107`. Positive und negative Widgettests sind ergänzt, aber die GitHub-CI auf dem neuen Branch ist noch ausstehend. Keine Änderungen an SRD-Regeln, SQLite-/JSON-Schema oder Version `0.8.52+102`. Android-Geräteprüfung und TalkBack bleiben offen.




### 2026-11-07 – Rat der Zeugen benötigt ausdrückliche Spielerentscheidung

In Rabenwachts Akt VIII beruft die Story den Rat der Zeugen erst dann ein, wenn die Spielerhandlung sowohl eine konkrete Einberufung bzw. ein Versammeln als auch den Rat, die Versammlung oder die Zeugen bezeichnet. Die bisherige Teilworterkennung konnte bereits aus „Ich verrate Liora meine Zweifel“ (Teilwort „rat“) oder einem bloßen Spaziergang zum Dorfplatz eine verbindliche Ratsszene ableiten. Normale Gespräche, Erkundungen, Erwähnungen und Verneinungen bleiben jetzt ohne diese Zustandsänderung. Eindeutige Einberufungen und die vorhandenen Anforderungen an Eidblatt und unabhängige Spuren bleiben erhalten.

**Code:** `app/lib/story/fourteenth_voice_act8.dart`; **Regressionen:** `app/test/rabenwacht_act8_council_intent_test.dart` (positive und negative Absichten, fehlende Belege/Verwahrung, Wiederaufnahme nach JSON-Roundtrip, Unveränderlichkeit der Originaldaten). [PR #619](https://github.com/ManuEtt/Dnd/pull/619), Branch `fix/chat-b/act8-council-explicit-intent-20261107`, initial Draft; CI-Abnahme auf finalem PR-Head war zum Zeitpunkt dieser Dokumentation noch offen. Keine Änderungen an Regeln, Heldenwerten, SQLite-/JSON-Schema, Queststatus oder KI-Provider.



### 2026-11-07 – Zauberdauern aus geprüften Katalogformen und Zauberidentitäten

Der bestehende SRD-5.2.1-Dauerinterpreter akzeptierte bislang auch frei konstruierte Zeitformen wie `999 days` und ließ sich bei direkt erstellten Zauberdefinitionen für einzelne kritische Zauber mit einer anderen, formal gültigen Dauer aufrufen. `SrdSpellDurationRules` begrenzt die Metadatenklassifikation nun auf die 23 tatsächlich im aktuellen 339-Zauber-Index vorhandenen auswertbaren Zeitformen (ein weiterer Katalogeintrag `Special` bleibt ausdrücklich nicht unterstützt). Zusätzlich sind Name, stabile Katalog-ID und exakte Dauer für 14 ausgewählte Zauber gemeinsam zu bestätigen; gefälschte Namen, IDs und Zeitangaben werden abgewiesen. Neue deterministische Positiv-/Negativfälle stehen in `app/test/srd_spell_duration_catalog_guard_test.dart`.

**GitHub:** Branch `feat/chat-a/spell-duration-metadata-integrity-20261107`; [PR #620](https://github.com/ManuEtt/Dnd/pull/620) (Draft, vollständige CI auf finalem HEAD noch abzunehmen). **Regelquelle:** SRD 5.2.1, *Spells / Duration* und einzelne Zaubertexte, CC BY 4.0, https://www.dndbeyond.com/srd. `RULE-SPELLS-SPELL-DURATION` bleibt global `unverified`: keine vollständige Wirkungsdauer-Automatik oder Zeitverfolgung, nur abgesicherte Metadatenauswertung. Lokal sind Dart-/Flutter-Tests und APK-Build wegen fehlendem SDK nicht ausführbar. Keine Änderung am äußeren JSON-/SQLite-Schema und keine Migration; gültige bestehende Zauberdauer-Daten bleiben erhalten.



### 2026-11-07 – Regelprüfung für katalogbelegte Zauberreichweiten

Die allgemeine Zauber-Ursprungsprüfung akzeptierte bisher beliebige syntaktisch gültige Fuß-/Meilenwerte wie `999 feet` als Reichweitenmetadaten. In der SRD-5.2.1-Vorabprüfung werden nun ausschließlich die 18 vorhandenen Formen des aktuellen Index mit 339 Zaubern anerkannt. Davon bleiben `Unlimited` und `Special` ausdrücklich nicht ohne gesonderte Regel umsetzbar. Für zwölf ausgewählte Zauber werden zusätzlich Katalogname, ID und die jeweils genaue Reichweite gemeinsam geprüft; eine veränderte Klasse von Zaubermetadaten wird nicht zu einer bestätigten Reichweite umgedeutet. Die allgemeine Einheitenumrechnung in `maxRangeFeet` bleibt unverändert. Positive und negative deterministische Tests einschließlich Katalogdurchlauf und Slot-Integrität stehen in `app/test/srd_spell_range_catalog_guard_test.dart`.

**Regelbeleg:** Wizards of the Coast LLC, *SRD 5.2.1*, *Spells / Range; Targets* (S. 105–106), CC BY 4.0, https://www.dndbeyond.com/srd. **Umsetzung:** `app/lib/domain/srd_spell_target_rules.dart`, Branch `feat/chat-a/spell-range-metadata-integrity-20261107`, [PR #621](https://github.com/ManuEtt/Dnd/pull/621) (Draft; vollständige CI auf abschließendem HEAD steht beim Eintrag noch aus). Ohne lokale Dart-/Flutter-Toolchain keine lokalen Flutter- oder APK-Tests. Kein SQLite-/JSON-Schemawechsel, keine Migration oder Änderung gültiger Altspielstände. SRD-Requirement `RULE-SPELLS-SPELL-RANGE` und `RULE-SPELLS-SPELL-TARGETS` bleiben `partial`; weitere Zaubereffekte und Zieltypen sind nicht vollständig geprüft.

### 2026-11-07 – Fehlerklassen der SRD-Reichweitenprüfung beibehalten

Die erste strenge Reichweitenprüfung in [PR #621](https://github.com/ManuEtt/Dnd/pull/621) sperrte manipulierte Werte fachlich korrekt, änderte jedoch unbeabsichtigt die bisherige Ausnahmeart bei nicht unterstützter Schreibweise: Für `120 FEET` wurde statt `UnsupportedError` ein Identitäts-`FormatException` ausgelöst. Der vollständige Flutter-Actions-Lauf #42352116576 erkannte diesen Fehler mit **3.322 bestandenen und zwei fehlgeschlagenen Tests**. Nun wird die Unterstützung der Katalogform vor der individuellen Name-/ID-Reichweitenbindung geprüft: unbekannte oder falsch geschriebene Reichweiten behalten `UnsupportedError`, eine andere, aber erlaubte Reichweite für einen gepinnten Zauber ergibt `FormatException`. Ein eigener Regressionstest prüft diese Unterscheidung. Korrekturcommit `f07efba564223a944f830649cfbaa2acff4f832b`; finale GitHub-CI auf Dokumentations-HEAD noch abzunehmen. Keine Modell-/JSON-/SQLite-/API-Schemaänderung und keine Migration.

### 2026-11-07 – Historische Reichweiten-Regression an kataloggebundene Freigabe angepasst

Der zweite vollständige GitHub-Actions-Lauf [#42355054722](https://github.com/ManuEtt/Dnd/actions/runs/42355054722) nach Reparatur der Ausnahmearten bestand **3.324 Flutter-Tests** und verfehlte einen weiteren historischen Fall: `srd_spell_target_rules_test.dart` verlangte, dass `Magic Missile` mit der frei konstruierten Reichweite `1 foot` regeltechnisch akzeptiert wird. Dies widerspricht der nun absichtlich strikt an den SRD-Zauberkatalog gebundenen Reichweitenfreigabe. Die bestehende `maxRangeFeet('1 foot') == 1`-Konvertierung bleibt erhalten; allein die beiden künstlichen Zulassungsfälle wurden zu expliziten negativen `UnsupportedError`-Regressionen geändert. Es wurde **kein Test deaktiviert**. Der neue Unit-Test zu unbekannten Reichweiten und die zusätzlichen Identitätsschutzprüfungen bleiben unverändert aktiv. PR [#621](https://github.com/ManuEtt/Dnd/pull/621) bleibt bis zum nachgewiesenen Erfolg aller finalen GitHub-Actions-Jobs Draft. Keine Schema-/Speicher-/Spielstandmigration.




### 2026-11-07 – Stufenaufstiegsverfahren bei großer Schrift scrollbar wählen

Der Stufenaufstiegsdialog hält die Wahl zwischen Erfahrungspunkten und Meilenstein auf schmalen Android-Bildschirmen mit vergrößerter Schrift horizontal bedienbar. Insbesondere bei unzureichenden Erfahrungspunkten muss die alternative Meilensteinmethode weiterhin ausdrücklich gewählt werden. Die vorhandene Prüfung der Aufstiegsvoraussetzungen und die getrennte Speicherung des Charakters bleiben unverändert.

**Nachweis:** `app/lib/ui/srd_class_level_up_dialog.dart`, `app/test/srd_class_level_up_large_text_method_test.dart`; Branch `feat/chat-c/levelup-method-large-text-20261107`. Neue Widgettests für 320/360 dp bei 200 % Schrift und positive/negative Aufstiegsentscheidungen erstellt; eine erfolgreiche CI-Abnahme auf diesem neuen Branch liegt noch nicht vor. Keine Änderung an App-Version `0.8.52+102`, SRD-Regeln, SQLite-/JSON-Daten oder bestehenden Spielständen. Tests auf einem physischen Android-Gerät und mit TalkBack stehen aus.




### 2026-11-07 – Nachgeschichte nur durch ausdrückliche Finalentscheidung abschließen

In Rabenwachts „Brief von Morgen“ darf eine Frage, eine zitierte Option oder eine hypothetische Erörterung keine endgültige Auflösung auslösen. Die bisherige Teilwortsuche in der Rats-Szene konnte etwa aus „Sollten wir den Brief versiegelt verwahren?“ bereits einen abgeschlossenen Auftrag und ein gespeichertes Finale ableiten. Die drei Enden benötigen nun eine vollständige Handlungsentscheidung oder eine klare Ich-/Wir-Absichtserklärung. Verneinungen, unvollständige Spuren und der noch ungelesene Brief bleiben gesperrt; normale direkte Abschlusskommandos bleiben gültig.

**Änderungen:** `app/lib/story/fourteenth_voice_morrow.dart` und fünf positive/negative Regressionstests in `app/test/rabenwacht_morrow_explicit_ending_test.dart` für hypothetische Fragen, sämtliche direkten Enden, Beweissperren, JSON-Wiederaufnahme und SQLite-Neustart. [PR #623](https://github.com/ManuEtt/Dnd/pull/623), Branch `fix/chat-b/morrow-ending-explicit-choice-20261107`, Ausgangs-`main` `f580d4c40f6a29df0098f656094844bfca1ed573`. Gesamte GitHub-Actions-Prüfung war bei Erstellung dieses Nachtrags noch offen; ein grüner Vorläufer-PR ist kein Testbeleg für diesen Stand. Keine Migration, Schema-, App-Version-, Regel-, Inventar- oder KI-Provideränderung. Zusammenführung mit parallelen README-/Checkpoint-Nachträgen bleibt ein koordinierter Integrationsschritt.




### 2026-11-07 – EP- oder Meilensteinaufstieg bei vergrößerter Schrift bedienbar

Die Auswahl zwischen Erfahrungspunkten und Meilenstein im Dialog für Klassenstufen ist auf schmalen Android-Bildschirmen horizontal scrollbar. Dadurch lässt sich die Meilensteinmethode auch bei verdoppelter Textgröße ausdrücklich wählen, falls die EP-Schwelle nicht erreicht ist. Vorschau, zugrunde liegende SRD-Prüfung und die spätere getrennte Charakter-Speicherung bleiben unverändert; die Bedienoberfläche bestätigt nichts automatisch.

**Nachweis:** `app/lib/ui/srd_class_level_up_dialog.dart`, `app/test/srd_class_level_up_large_text_method_test.dart`; Branch `feat/chat-c/levelup-method-large-text-20261107-mainf580`, basiert auf main `f580d4c40f6a29df0098f656094844bfca1ed573`. Widgettests für 320/360 dp, 200 % Schrift, positive und negative Wahl sowie normale EP-Auswahl ergänzt. GitHub-Actions-Abnahme dieses neuen Branches noch ausstehend. Keine Änderung von SQLite-/JSON-Schema, Spielständen, App-Version `0.8.52+102` oder SRD-Regelwerk. Reale Android-/TalkBack-Abnahme bleibt offen.



### 2026-11-07 – Auditierte SRD-Zaubermaterialien an den konkreten Zauber gebunden

Für die vier einzeln überprüften Materialrezepte *Astral Projection*, *Clone*, *Legend Lore* und *Secret Chest* genügte bisher bei direkten Zauberdefinitionen die Übereinstimmung von Name und Komponententext. Andere Angaben wie Grad, stabile ID oder Wirkzeit konnten unbemerkt abweichen. Der SRD-Materialregelpfad `SrdSpellComponentRules.auditedItems` verlangt nun für diese vier Rezepte zusätzlich die bestätigte Kombination von Name, ID, Grad, Schule, Klassenliste, Wirkzeit, Reichweite, Wirkungsdauer und V/S/M-/Konzentrations-/Ritualmarkierungen. Insbesondere eine gefälschte niedrige Zauberstufe oder eine Umbenennung unter beibehaltener geprüfter ID darf nicht als regulär auditiert behandelt werden. Der ursprüngliche Inventar-/Material- und Slotzustand wird bei der lesenden Ablehnung nicht verändert; die bestehende Preis- und Verbrauchsprüfung bleibt unabhängig davon erforderlich. Unbekannte andere Zauber werden unverändert nicht zu auditierten Rezepten aufgewertet.

**Nachweis:** [PR #627](https://github.com/ManuEtt/Dnd/pull/627) auf Branch `feat/chat-a/audited-material-recipe-identity-20261107`; Fachcommit `33ffcef4396070b17da36c2152bda55f9f6fb33d`, Testkorrektur `aed8755c0fdab14c1f05b1b9a1b339ee4383f35a`. Neue Datei `app/test/srd_spell_audited_recipe_identity_test.dart` mit Positivfällen aller vier Originalrezepte und Negativfällen für alle Metadatenfelder; Dart-/Flutter-/Android-CI auf finalem HEAD beim Eintrag **noch nicht vollständig bestätigt**. Kein lokales Dart-/Flutter-SDK, kein Gerätetest, keine Migration und keine Änderungen an JSON/SQLite/Story/UI oder Android-Version. Quelle: Wizards of the Coast LLC, *SRD v5.2.1*, *Spells / Components* und individuelle Zauberbeschreibungen, CC BY 4.0, https://www.dndbeyond.com/srd. Der Arbeitskatalog ist weiterhin nicht vollständig amtlich abgeglichen; die tatsächliche Materialqualität und Zauberwirkung werden aus Metadaten allein nicht bestätigt.




### 2026-11-07 – Kämpfer-Kampfstile bei großer Schrift begrenzt anzeigen

Im Assistenten zur Charaktererstellung bleibt der Dropdown-Eintrag für den Kampfstil des Kämpfers bei schmalen Android-Bildschirmen mit großer Schrift innerhalb der verfügbaren Dialogbreite. Lange Bezeichnungen werden visuell begrenzt, die vollständige Wahl aus den offiziellen vier Kampfstilen und die explizit bestätigten Waffenmeisterschaften bleiben unverändert. Eine unbeabsichtigte Klassenauswahl wird nicht ausgelöst.

**Quellen:** `app/lib/ui/srd_class_selection_dialog.dart` und `app/test/fighter_style_large_text_dialog_test.dart`; Branch `feat/chat-c/fighter-style-large-text-20261107`, basierend auf main `5766d64880fee8e35d15ac39fc14dc7ef965ccba`. Widgettests für 320/360 dp und 200 % Schrift samt Tastatur, Negativ-/Positivpfad und Normaltext ergänzt. Vollständige GitHub-Actions-Abnahme für diesen Branch zum Zeitpunkt des Nachtrags noch ausstehend. Keine SRD-Regel-, Datenbank-, JSON-, Versions- oder Spielstandmigration. Android-Realgerät und TalkBack bleiben ungetestet.



### 2026-11-07 – Sending-Vorschau an vollständige Katalogidentität binden

**Problem/Lösung:** Bei direkt konstruierten Zauberdefinitionen genügte bisher der Name `Sending` zusammen mit wenigen Eigenschaften, um die lesende Sending-Vorschau zu öffnen – auch mit fremder ID, abweichender Klassenliste oder manipulierten Komponenten. `SrdSendingRules.prepare` vergleicht nun alle bekannten Identitätsfelder mit dem konkreten aktuellen Katalogeintrag `spell-sending` und weist Abweichungen vor Erzeugung eines Nachrichtenplans zurück. Die vorhandene 25-Wörter-Prüfung, bestätigtes Empfängerwissen und der 5-%-Ebenenwurf bleiben unverändert; es erfolgt keine eigenständige Zauberwirkung.

**Nachweis/Stand:** `app/lib/domain/srd_sending_rules.dart` und `app/test/srd_sending_rules_test.dart`; Codecommit `a8f143ff3d945fb1197b25c4fd4e7c38c1e147cb`, Testcommit `d8b2cb9fe8f7973da26bf202801be4496965c91f`, Branch `feat/chat-a/sending-catalog-identity-20261107`, [PR #633](https://github.com/ManuEtt/Dnd/pull/633) (Draft, nicht integriert). Fünfzehn negative Metadatenfälle und ein positiver Originalfall sind ergänzt, jedoch ohne lokales Dart-/Flutter-SDK **noch nicht ausgeführt**; aktuelle vollständige GitHub-CI und APK-Abnahme stehen aus. Keine Änderung an JSON/SQLite, Events, Story/UI, Heldenwerten oder App-Version; keine Migration. SRD 5.2.1, *Sending*, CC BY 4.0; die Zauberwirkung und die amtliche Vollinventur bleiben offen. Gemeinsame Dokumentationsnachträge bei der Integration verlustfrei nachführen.





### 2026-11-07 – Verbindliche Namenverwahrung im siebten Akt nur bei ausdrücklicher Wahl

Im siebten Rabenwacht-Akt konnte bisher schon eine Frage oder hypothetische Erwähnung der Übergabe des vierzehnten Namens einen dauerhaften Verwahrungsentscheid auslösen und den Eintritt in Akt VIII als bestätigt speichern. Die Prüfung in `FourteenthVoiceAct7` verlangt nun eine vollständige, bewusste Spielerhandlung: Entweder wird der Name ausdrücklich Liora anvertraut oder selbst verwahrt. Negierte, zitierte oder bloß erwogene Entscheidungen führen zu keiner Zustandsänderung. Das zuvor tatsächlich untersuchte Eidblatt bleibt in beiden Fällen erforderlich; bestehende Spielstände, Heldenwerte und Questdaten werden nicht umgeschrieben.

**Dateien:** `app/lib/story/fourteenth_voice_act7.dart` und sechs neue Regressionstests in `app/test/rabenwacht_act7_custody_intent_test.dart` (Fragen und hypothetische Handlungen, beide Verwahrungswege, Beweissperren, JSON-Roundtrip, SQLite-Neustart samt Journalrekonstruktion). [PR #632](https://github.com/ManuEtt/Dnd/pull/632), Branch `fix/chat-b/act7-custody-explicit-intent-20261107`, Ausgangs-main `bbe6ee0901f1873af67647bf54462e4a44821762`. Vollständige CI auf dem endgültigen Branch-HEAD war bei Erstellung dieses Nachtrags noch offen; die Prüfergebnisse werden direkt im PR nachgetragen. Keine SQLite-/JSON-Migration, App-Version-, Regelengine- oder KI-Provideränderung. Parallele README-/Checkpoint-Ergänzungen müssen bei Integration verlustfrei erhalten bleiben.



### 2026-11-07 – Erste Liora-Beziehungsentscheidung ausdrücklich festhalten

**Problem:** Am Anfang der Rabenwacht-Fortsetzung konnten Teilworttreffer in hypothetischen Fragen, negierten Aussagen oder Berichten Schutz, Anschuldigung oder Beweissuche als endgültige Spielerentscheidung werten. Zudem ließ sich eine bestätigte erste Wahl durch eine spätere gegenteilige Eingabe überschreiben.

**Lösung:** In `app/lib/story/fourteenth_voice_campaign.dart` werden die drei Handlungsrichtungen nur noch durch eindeutige aktive Formulierungen angenommen. Spekulationen ändern weder NPC-Beziehung noch Queststatus. Eine bereits gespeicherte erste Wahl bleibt erhalten, ohne dass andere Zeugen-/Ermittlungswege gesperrt werden.

**Nachweis:** Fachcommit `e78365af402026ea90774a995cb343e9eb6ea3d9`, Testcommit `64815cfbf1d92d6914d74909a65d0ece12a79166`; Branch `feat/chat-b/liora-square-explicit-intent-20261107`; [PR #636](https://github.com/ManuEtt/Dnd/pull/636) (Draft, nicht integriert). Fünf neue positive und negative Flutter-Testgruppen in `app/test/rabenwacht_liora_square_explicit_intent_test.dart` prüfen Fragen/Negationen, bestätigte Varianten, widersprüchliche Wiederholung, andere Zeugen sowie JSON und SQLite-Neustart. Die GitHub-Android-Alpha-CI [#42411071998](https://github.com/ManuEtt/Dnd/actions/runs/42411071998) lief beim Dokumentationsstand noch auf dem Testcommit; ihr Ergebnis ist nicht als bestanden bestätigt. Lokal sind Flutter-/Dart-/Android-/Backend-/Python-Komplettprüfungen mangels Checkout und Flutter-SDK nicht ausgeführt.

**Kompatibilität:** Unverändertes JSON-/SQLite-Schema, keine Migration, keine Versionsänderung, kein Eingriff in Heldenwerte, Kämpfe, SRD-Regeln oder KI-Provider. Fremde offene Fach-PRs bleiben unberührt; parallele README- und Checkpoint-Nachträge bei Integration append-only zusammenführen. Reale Android-Geräte- und Upgrade-Tests bleiben offen.



### 2026-11-07 – Feuerwand-Vorschauen gegen verfälschte Zauberdefinitionen absichern

**Problem:** Die lesenden Wandseiten- und Ring-Vorschauen des Zaubers *Wall of Fire* akzeptierten direkt konstruierte SRD-Zauberobjekte, obwohl deren Schule, Klassenliste, Wirkzeit, Komponenten, Dauer oder Konzentrationsangaben vom Katalog abwichen.

**Lösung:** Gemeinsamer 14-Felder-Katalogidentitätswächter in `app/lib/domain/srd_wall_of_fire_catalog_identity.dart` vor beiden Regelvorschauen. 16 manipulierte Metadatenvarianten sowie der echte Katalog-Positivfall sind in `app/test/srd_wall_of_fire_catalog_identity_test.dart` als deterministische Regressionen erfasst. Ring-Geometrie, Wandseitenwahl und bestätigte Trigger bleiben unverändert.

**Nachweis:** Branch `feat/chat-a/wall-of-fire-catalog-identity-20261107`, Fachcommit `8f8713a6e5676afa4926d73bcc3eb86d9a1769ba`, [PR #639](https://github.com/ManuEtt/Dnd/pull/639) (Draft, noch nicht integriert). GitHub Actions auf dem endgültigen HEAD separat abzunehmen. Lokal keine Flutter-/Dart-Tests oder APK ausgeführt (SDK und GitHub-Checkout im Container nicht verfügbar); Quelltexte und Testfälle geprüft, keine grüne CI behauptet. Aktueller `main`-Merge `1efb5e219dc0b00965e3be2dfb4b2b52d621d362` wurde verlustfrei übernommen.

**Kompatibilität und Grenzen:** Keine Änderungen an Spielstands-JSON, SQLite, Events, Ressourcen, Story, UI, Android-Version oder Backend; keine Migration. Nur lesende Feuerwand-Vorschauen, keine automatisierte Zauberausführung; `SPELL-ENTRY-WALL-OF-FIRE` bleibt bis zum vollständigen amtlichen Quellenabgleich `unverified`. Weitere offene PR-Dokumentationsnachträge sind bei Integration verlustfrei zusammenzuführen.




### 2026-11-08 – Unsichtbare mathematische Operatoren in KI-Geschichten sperren

**Problem/Lösung:** Die Prüfung neuer KI-generierter Kampagnen, Erzählzüge und Abenteuerangebote sperrte bereits Steuerzeichen und irreführende Unicode-Formatierungen, akzeptierte aber noch die unsichtbaren Operatoren U+2061 bis U+2064. Die gemeinsame Story-Textprüfung in `app/lib/story/ai_story.dart` weist jetzt den gesamten Unicode-Bereich U+2060–U+206F zurück; normale Umlaute, Zeilenumbrüche und Emojis bleiben erlaubt. Vorhandene bestätigte Spielstände werden nicht verändert.

**Nachweis:** Branch `feat/chat-b/ai-invisible-operators-20261108`, [Draft-PR #643](https://github.com/ManuEtt/Dnd/pull/643), Codecommit `89b87a524e8a358f22c1671c40cd2af51432b454`, neue `app/test/ai_story_invisible_operator_test.dart` (`4ea6a7e0f9df6d748b10ec40b8cf4ce2b077707d`) mit vier positiven/negativen Testgruppen. [Initiale GitHub-CI #42458390622](https://github.com/ManuEtt/Dnd/actions/runs/42458390622) war zum Zeitpunkt dieses Nachtrags noch in Arbeit; **keine Abnahme oder Integration behauptet**. Lokale Dart-/Flutter-Prüfungen und vollständiger GitHub-Checkout sind in dieser Sitzung nicht ausführbar. Keine Schema-/JSON-Migration, keine Regel-/Quest-/Heldenmutation und keine App-Versionsänderung. Gemeinsame Dokumentationsnachträge beim Merge append-only erhalten.



### 2026-11-08 – Säurespritzer-Zielidentitäten gegen unsichtbare Unicode-Steuerzeichen absichern

**Problem:** Bereits bestätigte Kreaturen-IDs und Anzeigenamen konnten bei *Säurespritzer* unsichtbare Unicode-Richtungs- und Formatmarken enthalten. Diese Eingaben gelangen sonst in den protokollierten Kampfzustand und können Zielidentitäten optisch verfälschen.

**Lösung:** `AcidSplashRules.cast` prüft beide Textfelder mit einem einheitlichen eng begrenzten Schutz gegen ASCII-/C1-Steuerzeichen, Unicode-Zeilentrenner und versteckte Richtungs-/Formatmarken – vor allen Schadens- und Rettungswürfeln. Normale Umlaute, internationale Schriftzeichen und Emoji bleiben zulässig. Neue `app/test/acid_splash_unicode_identity_test.dart` umfasst einen positiven Unicode-Fall, 40 Negativfälle für 20 problematische Zeichen in ID und Namen, ein zweites manipuliertes Flächenziel sowie einen GameEngine-Regressionstest ohne Würfel- oder Spielstandsänderung.

**Nachweis:** Branch `feat/chat-a/acid-splash-target-unicode-20261108`, Fachcommit `9ecabb4454a1b1aa0e96c05dc88a3d5a2d8d4c69`, [PR #641](https://github.com/ManuEtt/Dnd/pull/641) (Draft, nicht integriert). GitHub-CI auf dem endgültigen HEAD gesondert abzunehmen. Kein lokaler Flutter-/Dart-Testlauf möglich (SDK nicht installiert, externer Checkout durch DNS blockiert). Prüferfolge werden erst nach konkretem Actions-Nachweis vermerkt.

**Kompatibilität/Grenzen:** SRD-5.2.1-Zaubermechanik, Casting, Attributs-SG, Kreaturenschaden, Kampagnen-Revisionen, App-Version, SQLite/JSON-Schema, Story und UI bleiben unverändert. Der Filter dient ausschließlich der Ereignis- und Identitätsintegrität, ist keine zusätzliche D&D-Namensregel und benötigt keine Migration. Bestehende Spielstände werden bei dieser Prüfung nicht umgeschrieben.






### 2026-11-08 – Zustandsquellen im geöffneten Dialog sicher aktualisieren

Wenn während der Verwaltung eines Zustands ein neuer Charakter- oder Kampfstand eintrifft, verwirft die Oberfläche nicht mehr vorhandene Quellenauswahlen, statt irrtümlich eine andere Quelle zu übernehmen. Wechselt der betroffene Charakter, wird eine vorherige, noch unbestätigte Auswahl nicht übertragen. Ändert sich die aktuelle Begegnung oder der aktive Zug, muss eine zuvor ausgewählte Zugend-Dauer erneut bewusst festgelegt werden. Die Quellen- und Dauerfelder werden für die neue Datenbasis neu aufgebaut; nur die getrennte explizite Bestätigung erzeugt einen Vorschlag, und der Controller bleibt für Änderungen am Spielstand zuständig.

**Nachweis:** `app/lib/ui/condition_effect_dialog.dart`, `app/test/condition_effect_live_snapshot_test.dart`; Branch `feat/chat-c/condition-source-live-refresh-20261108`, Ausgangs-main `0ce0ad86e9eddf8302e495561d12a889008de49a`. Fünf neue Widgetfälle für 320/360 dp mit 200 % Text und simulierter Android-Tastatur decken verschwundene Quellen, Charakterwechsel, Kampfzugwechsel, positiven Vorschlag und Abbruch ab. Vollständige GitHub Actions auf dem finalen Branch-HEAD sind zum Zeitpunkt dieses Nachtrags **noch nicht abgeschlossen**. Kein Eingriff in SRD-Regeln, gespeicherte Effekte, SQLite-/JSON-Schema oder App-Version `0.8.52+102`; echte Android-/TalkBack-Abnahme steht aus.



### 2026-11-08 – Manueller Zauberangriff nach aufgehobenem Vorteil/Nachteil
Ein bestätigter einzelner W20 wird bei Zauberangriffen jetzt auch akzeptiert, wenn Vorteil und Nachteil beide vorliegen und sich nach SRD 5.2.1 (D20 Tests / Advantage/Disadvantage, S. 8, CC BY 4.0) vollständig aufheben. Unaufgehobener Vorteil oder Nachteil erfordert weiterhin einen regulären Zwei-W20-Wurf. `SrdSpellAttackRollRules.resolve` bleibt rein lesend und ändert keine Kampf-, Würfel- oder Persistenzzustände. Ergänzte Regressionstests prüfen manuelle natürliche 1, 11 und 20 sowie fehlende Zielautorisierung und vollständige Deckung ohne Zufallsverbrauch. Branch `feat/chat-a/spell-attack-cancelled-manual-roll-20261108`, Fachcommit `60dd34d12e0a6e6f977a4328a218a4423f0d48f4`, [PR #646](https://github.com/ManuEtt/Dnd/pull/646). GitHub-CI inklusive Dart-Format, Analyse, Flutter, Android-Build und Release-Artefakten am dokumentierten PR-HEAD noch nicht final geprüft; kein Main-Merge und keine Realgerätabnahme behauptet. Kein JSON-/SQLite-Schema, keine Migration, keine App-Versionsänderung.


### 2026-11-09 – Zauber-SG nur mit bestätigter Klassenattribut-Zuordnung

Die bestehende `SrdSpellSavingThrowRules.spellSaveDc`-Schnittstelle hatte beliebige übergebene Attribute allein anhand des Attributwerts als vermeintlich gültigen Zauberrettungswurf-SG berechnet. Sie prüft jetzt, ob das Attribut tatsächlich zu einer bestätigten eigenen SRD-Zauberklasse gehört, und nutzt dafür die vorhandene vollständige `statsForClass`-Validierung von Klassenprofil, Mehrklassenstufen und Attribut. Gültige SG-Werte, Klassenaliasnamen und der Übungsbonus aus der Gesamtstufe bleiben erhalten; die Klasse eines konkret vorbereiteten Zaubers muss weiterhin separat bestätigt werden. Eine neue deterministische Testdatei prüft positive Zauberklassen- und Mehrklassenbeispiele, fremde Attribute, beschädigte Klassenprofile, fehlende Bestätigung sowie unveränderte Spielstände.

[Fach-PR #653](https://github.com/ManuEtt/Dnd/pull/653), Branch `feat/chat-a/spell-save-dc-class-identity-20261109`, erster Fachcommit `803d3545e809660449713dbd362a2f0c0c0f454c`. Die GitHub-PR-CI wurde gestartet ([Actions #42560123322](https://github.com/ManuEtt/Dnd/actions/runs/42560123322)); ein endgültig grüner Test-/Android-Build auf dem dokumentierten Endstand ist zum Zeitpunkt dieses Eintrags **noch nicht nachgewiesen**. Lokal kein Dart-/Flutter-SDK. Keine Änderung an Spielstandsformat, JSON/SQLite, Ressourcen, Story, UI oder App-Version; keine Migration. SRD 5.2.1 Spellcasting und Multiclassing, Wizards of the Coast LLC, CC BY 4.0. Keine vollständige SRD-Zauberfreigabe und kein Android-Gerätetest.




### 2026-11-09 – Bestätigte NPC-Chronik nur mit eindeutigen Notiz-IDs

Die schreibgeschützte NPC-Kurzfassung verwirft jetzt unsichere oder mehrfach belegte Notiz-IDs, auch wenn mehrere NPCs dieselbe ID tragen. So werden inkonsistente Legacy-/In-Memory-Einträge nicht als bestätigte Erinnerungen dargestellt. Gültige Notizen behalten die chronologische Reihenfolge; leere, bereinigte Einträge belegen kein Ausgabelimit. Betroffen: `app/lib/story/confirmed_npc_continuity_excerpt.dart`, fünf Regressionstests in `app/test/confirmed_npc_continuity_excerpt_note_id_test.dart`. [PR #654](https://github.com/ManuEtt/Dnd/pull/654) (Draft), Branch `fix/chat-b/npc-excerpt-unique-note-ids-20261109`, Fach-/Testcommits `cecfb1f6cd5400aa06447767737f3e039833c45b` / `36efbc691636c3ba6f673334ea0a56ba7b88daa7`. Testdatei geschrieben; Flutter-/Dart-Tests lokal mangels SDK nicht ausgeführt. [PR-CI #42560154778](https://github.com/ManuEtt/Dnd/actions/runs/42560154778) wurde gestartet und war bei diesem Nachtrag noch in Bearbeitung; kein Testerfolg behauptet. Keine Regel-, HP-, XP-, Quest-, Schema-, JSON-, SQLite-, Versions- oder Migrationsänderung. Weitere offene PR-Dokumentationsnachträge müssen vor der Integration verlustfrei vereinigt werden.

### 2026-11-09 – Präzisierung: NPC-Rückblick auch hinter unsichtbaren Verlaufseinträgen

Ergänzung zum vorigen NPC-Chronik-Nachtrag: Die Fachkorrektur schließt nun auch die eigenständige Lücke ab, dass mehr als 20 neuere, nach Anzeige-Bereinigung leere Notizen eine ältere gültige Erinnerung aus der Kurzfassung verdrängen konnten. Ein **sechster** Regressionstest prüft 24 unsichtbare Einträge vor dem bestätigten Hinweis. [PR #654](https://github.com/ManuEtt/Dnd/pull/654) grenzt diese Anzeige-Nachfüllung ausdrücklich von der allgemeinen Notiz-ID-Prüfung im noch offenen [PR #615](https://github.com/ManuEtt/Dnd/pull/615) ab. Frühere CI #42560261362 scheiterte ausschließlich an Dart-Formatierung der zwei Fach-/Testdateien (Struktur/Python/Backend zuvor bestanden). Die exakte Dart-3.9-Formatierung ist danach korrigiert; ein temporärer Diagnose-Workflow ist aus dem PR-Diff wieder entfernt. Vollständige finale CI noch separat abzunehmen. Spielstände und Regelzustand unverändert.


### 2026-11-09 – Automatische Rettungswurffehlschläge nur mit gültigen Attributwerten

Der Vorbereitungspfad `SrdManualSavingThrowRules.prepare` prüft bei ausdrücklich bestätigten automatischen Fehlschlägen für Stärke/Geschicklichkeit jetzt auch, ob das vorhandene Attribut zwischen **1 und 30** liegt, bevor der Kurzpfad ohne W20 beendet wird. Zuvor konnten direkt erzeugte ungültige Attributwerte trotz korrekter Zustandserkennung als bestätigte Fehlschläge behandelt werden. Bei gültigen Werten bleibt die SRD-5.2.1-Regel für Gelähmt, Versteinert, Betäubt und Bewusstlos unverändert, ebenso die schon vorgesehene Behandlung historischer Klassenprofile. Neue deterministische Regressionstests prüfen diese acht Kombinationen mit gültigen und ungültigen Attributwerten, reguläre Rettungswürfe und unveränderte Charakterdaten.

[PR #656](https://github.com/ManuEtt/Dnd/pull/656), Branch `feat/chat-a/automatic-save-ability-bounds-20261109`, erster Fachcommit `7054a7704af1a0c6144d929980cca05a3cf285ed`. [GitHub Actions #42594880639](https://github.com/ManuEtt/Dnd/actions/runs/42594880639) wurde gestartet; vollständige CI einschließlich aller Flutter-/Android-Stufen ist beim Anlegen dieses Nachtrags noch nicht bestätigt. Lokal kein Dart-/Flutter-SDK. Kein Eingriff in Kampagnenspeicherung, SQLite-/JSON-Schema, Story, UI, Ressourcen oder App-Version, keine Migration und kein Realgerätetest. Quelle: Wizards of the Coast LLC, *SRD 5.2.1* (Conditions, Saving Throws), CC BY 4.0.




### 2026-11-09 – Gespeicherten Kampagnenort ausdrücklich und ID-gebunden wiederaufnehmen

Die schreibgeschützte Orts-Wiederaufnahme unterstützt nun eine vom Spieler gezielt ausgewählte gespeicherte Orts-ID **auch außerhalb der ersten vier Orte** der allgemeinen Übersicht. `ConfirmedPlaceResumeSelector.readSelected` lehnt unsichere, fehlende und doppelte IDs, unanzeigbare Ortsnamen und veraltete Revisionen ab; bei gleichem gespeicherten Ortsnamen bleibt allein die eindeutige gespeicherte ID maßgeblich. Ein vollständiger Regex-ID-Treffer wird auch für die allgemeine Ortsübersicht geprüft. Die Ausgabe bestätigt ausdrücklich keinen Besuch und übernimmt keine freien KI-Erzählbehauptungen als Fakten. Betroffene Dateien: `app/lib/story/confirmed_place_resume_selection.dart` und fünf neue Regressionstests in `app/test/confirmed_place_resume_terminal_id_test.dart`. Branch `fix/chat-b/place-resume-full-id-match-20261109`, [PR #658](https://github.com/ManuEtt/Dnd/pull/658) (Draft, nicht integriert); Ausgangs-main `b2e1a021067cec39b7c85bdad11aa98477cac14e`. Prüfungen: GitHub-Dateipfade/Quellen und Quellcodeänderungen kontrolliert, Flutter-/Dart-Tests mangels lokaler SDKs noch nicht ausgeführt; GitHub-Actions-Gesamtabnahme beim Nachtrag ausstehend. Keine Änderung an HP, Quests, Inventar, Regeln, Ereignissen, Revision, SQLite/JSON-Schema, App-Version oder Anbieter; keine Datenmigration. Integration benötigt koordinierte verlustfreie Zusammenführung paralleler README-/Checkpoint-Nachträge.



### 2026-11-09 – Heilzauber-Auswahl bei aktualisiertem Charakter erneuern

Der geöffnete Selbstheilungsdialog lädt vorbereitete Heilzauber, Zauberklassen und freie Zauberplätze bei einem neuen Charakter-Snapshot erneut. Frühere Komponentenbestätigungen werden verworfen; Dropdown-Auswahlfelder werden gegen veraltete Formularwerte neu initialisiert. Zwei Widget-Regressionstests decken veränderte Zaubervorbereitung, Ressourcen und den Wegfall des Heilzauberangebots ab.

Branch `feat/chat-c/healing-spell-live-hero-refresh-20261109`; UI-Commit `1e20a8f639ceecece9d39c513405e2f043bd1cde`, Testcommit `852f4fa329a7a092495072e930da7bd235ba6b78`. Vollständige GitHub-CI nach PR-Erstellung noch ausstehend; lokale Flutter-/Dart-Ausführung war nicht verfügbar. Keine Änderung an Spielregeln, Spielständen, SQLite/JSON oder App-Version.


### 2026-11-09 – Live-Charakterwechsel im Heilzauberdialog
Der geöffnete Selbstheilungsdialog berechnet vorbereitete Heilzauber und verfügbare Zauber-/Paktplätze beim Austausch des Charakter-Snapshots erneut. Dabei werden Zauber-, Klassen- und Platzwahl sowie Komponentenbestätigungen und Fehlermeldungen zurückgesetzt. Die Auswahl-Unterwidgets werden an die Identität des aktuellen Heldensnapshots gebunden, damit Dropdowns nicht ihre alten Initialwerte behalten. Ein Widget-Regressionstest wechselt während des geöffneten Dialogs zu einem Charakter mit nur noch „Heilendes Wort“ und vollständig verbrauchten Plätzen und prüft, dass keine alte Auswahl oder Komponentenfreigabe fortbesteht. Die vollständige GitHub-CI steht nach diesem Commit noch aus; keine Änderungen an Regelengine, Spielständen, SQLite/JSON oder App-Version.



### 2026-11-09 – Live-Charakterwechsel im Heilzauberdialog
Der geöffnete Selbstheilungsdialog berechnet vorbereitete Heilzauber und verfügbare Zauber-/Paktplätze beim Austausch des Charakter-Snapshots erneut. Dabei werden Zauber-, Klassen- und Platzwahl sowie Komponentenbestätigungen und Fehlermeldungen zurückgesetzt. Beim Austausch des Heldensnapshots lädt `didUpdateWidget` die Auswahl neu; eine Angebotsversion in den Dropdown-Schlüsseln verwirft auch deren alte Initialwerte. Ein Widget-Regressionstest wechselt während des geöffneten Dialogs zu einem Charakter mit nur noch „Heilendes Wort“ und vollständig verbrauchten Plätzen und prüft, dass keine alte Auswahl oder Komponentenfreigabe fortbesteht. Die vollständige GitHub-CI steht nach diesem Commit noch aus; keine Änderungen an Regelengine, Spielständen, SQLite/JSON oder App-Version.




### 2026-11-09 – Verneinte Ortsrückreisen in Rabenwacht respektieren

Die Rabenwacht-Wiedererkennung führt eine ausdrücklich verneinte Bewegung zu einem bereits besuchten Ort nicht mehr aus. Bei mehrdeutigen Formulierungen bleibt der bestätigte Ort unverändert und die Spielleitung bittet um eine eindeutige Neuformulierung. Positiv bestätigte Rückreisen bleiben möglich. Drei Regressionstests sichern beide Fälle sowie eine verneinte Ortsnennung ohne Reisebefehl. Keine Änderungen an Regeln, Belohnungen, Quests, persistenten Daten oder Spielstandschema; die vollständige GitHub-CI auf dem finalen PR-Commit steht noch aus.



### 2026-11-09 – Magic-Missile-Zielverteilung an vollständige SRD-Katalogidentität binden

Die reine Zielverteilungsprüfung für *Magic Missile* akzeptierte bisher eine öffentlich konstruierte Zauberdefinition, wenn Name und ausgewählte Wirkungsdaten passten. Eine gefälschte Zauber-ID, Schule oder vertauschte Klassenreihenfolge konnte dadurch als bekannte SRD-Definition auftreten. Die Vorprüfung verlangt jetzt die vollständige kanonische Identität: ID `spell-magic-missile`, Name, Grad, Schule, geordnete Klassenliste, Wirkzeit, Reichweite, Komponenten, Dauer und sämtliche Komponenten-/Wirkungsflags. Die bisherige gleichzeitige Verteilung aller Geschosse und die ausdrücklichen Zielbestätigungen bleiben unverändert.

**Code/Test:** `app/lib/domain/srd_magic_missile_multi_target_rules.dart`, `app/test/srd_magic_missile_multi_target_rules_test.dart`. Neue Regressionen weisen gefälschte IDs, Schule und Klassenreihenfolge einschließlich doppelter Klasse ab; der echte Katalogeintrag bleibt zulässig. **Branch:** `feat/chat-a/magic-missile-catalog-identity-20261109`; **Fachcommit:** `0731f671d89cbbad603e83951a4e9f00b699f761`; **Testcommit:** `b2e5a923ae91aa470da907ea0f381df1c61ad08f`. PR und CI sind zum Zeitpunkt dieses Nachtrags noch nicht erstellt beziehungsweise ausgeführt.

**Quelle:** Wizards of the Coast LLC, SRD 5.2.1, *Magic Missile*, S. 146, CC BY 4.0, https://www.dndbeyond.com/srd. **Kompatibilität:** Nur eine read-only Regelvorprüfung; keine Änderung an Zauberwirkung, Spielständen, JSON, SQLite, Ereignissen, UI, Version oder Migration. Keine vollständige SRD-Zauberabdeckung wird behauptet.


### 2026-11-09 – PR-Nachtrag zur Magic-Missile-Katalogidentität

Die zuvor dokumentierte offene PR-Erstellung ist inzwischen abgeschlossen: [PR #665](https://github.com/ManuEtt/Dnd/pull/665) wurde als Draft gegen `main` eröffnet. Nach dem Formatierungsnachtrag ist der aktuelle Branch-HEAD `d3456a3a9cf5362531cba4d593a7b6272c694713`; die vollständige GitHub-Actions-Abnahme dieses endgültigen Stands wird nach den abschließenden Dokumentationsnachträgen erneut geprüft. Bis zum tatsächlichen Abschluss gilt CI als ausstehend, nicht als bestanden.




### 2026-11-09 – Android-Backupziele vor unbeabsichtigtem Überschreiben schützen

- **Problem:** Der native SAF-Bridge-Code öffnete einen zurückgegebenen Dokument-URI ohne Größenprüfung mit truncierendem Modus und löschte ihn nach Schreibfehlern/Abbruch. Die Android-API-Referenz erlaubt als Ergebnis von `ACTION_CREATE_DOCUMENT` auch ein vorhandenes Dokument.
- **Lösung:** Vor dem Schreiben nur ein bestätigtes 0-Byte-Ziel zulassen; fehlende/negative/nichtleere Größen fail-closed ablehnen. Bei Fehlern und Abbruch keine URI-Löschung mehr ausführen; mögliche partielle neue Datei bleibt erhalten und wird als Grenze kommuniziert.
- **Betroffene Funktionen:** Android-JSON-Backup über Storage Access Framework; keine Änderung am JSON-Format, SQLite oder Spielstandmodell.
- **Branch:** `fix/chat-d/android-backup-existing-target-20261109`.
- **Tests:** Native Kotlin-Regressionen für leeres, unbekanntes, negatives und nichtleeres Ziel ergänzt. GitHub-Actions-Abnahme auf finalem PR-HEAD steht aus.
- **Kompatibilität/Migration:** Keine Datenmigration, keine Änderung vorhandener Sicherungen oder App-Version.
- **Grenzen:** Metadatenprüfung ist nicht atomar gegenüber externen parallelen Provider-Schreibvorgängen; reale Geräte-/Providerabnahme ausstehend.




### 2026-11-09 – Verneinte Ortsrückreisen in Rabenwacht respektieren

Die Rabenwacht-Wiedererkennung führt eine ausdrücklich verneinte Bewegung zu einem bereits besuchten Ort nicht mehr aus. Bei mehrdeutigen Formulierungen bleibt der bestätigte Ort unverändert und die Spielleitung bittet um eine eindeutige Neuformulierung. Positiv bestätigte Rückreisen bleiben möglich. Drei Regressionstests sichern beide Fälle sowie eine verneinte Ortsnennung ohne Reisebefehl. Keine Änderungen an Regeln, Belohnungen, Quests, persistenten Daten oder Spielstandschema.




### 2026-11-09 – Inkonsistente Klassenprofile vor Stufenaufstieg abweisen

Der bestätigte Stufenaufstieg prüft vor jeder Berechnung die vollständige vorhandene Klassenkombination: bekannte und unterschiedliche SRD-Klassen, zulässige Zweitklassenstufe sowie das Fehlen verwaister Zweitklassenstufen. Ungültige historische Profile bleiben lesbar, dürfen aber nicht durch einen Stufenaufstieg stillschweigend repariert werden. Gültige Einzel- und Mehrklassenaufstiege behalten ihre bisherige Berechnung. Änderungen betreffen ausschließlich app/lib/domain/srd_class_level_up.dart und dessen Domain-Regressionstest. [Pull Request #661](https://github.com/ManuEtt/Dnd/pull/661). Finale CI-Abnahme steht noch aus. Keine Änderung an Spielständen, JSON-/SQLite-Schemas oder Migrationen.


### 2026-11-09 – Klassenprofilprüfung für Dart-Formatter vereinfacht

Der CI-Lauf [#42700994265](https://github.com/ManuEtt/Dnd/actions/runs/42700994265) bestätigte die Struktur-/SRD-Prüfungen und sämtliche Backend-Prüfungen, brach jedoch bei der Dart-Formatprüfung ausschließlich in `app/lib/domain/srd_class_level_up.dart` ab. Die verschachtelte bedingte Validierung wurde durch explizite, sequenzielle Guards ersetzt; die Regeln bleiben gleich: Hauptklasse muss bekannt sein, eine vorhandene Zweitklasse muss bekannt und verschieden sein und einen zulässigen Stufensplit besitzen, ohne Zweitklasse müssen Zweitklassenstufen null sein. Änderung in [PR #661](https://github.com/ManuEtt/Dnd/pull/661), Commit `46d702606c92cd39061460a786cc115ceb5a5e5e`. Die Formatkorrektur und vollständige CI auf diesem neuen Commit sind noch nicht abgenommen; frühere erfolgreiche Backend-/Strukturprüfungen gelten nicht als Nachweis für den neuen Head. Keine Änderung an Spielständen, Datenformaten, SQLite, App-Version oder Migrationen.


### 2026-11-10 – Offizielle Dart-Formatierung der Klassenaufstiegsprüfung korrigiert

Der finale Formatcheck auf dem vorherigen PR-Stand hatte ausschließlich `app/lib/domain/srd_class_level_up.dart` als nicht kanonisch formatiert gemeldet. Der offizielle Flutter-/Dart-Formatter 3.35.7 hat genau diese Datei angepasst. Die einmalige Formatierhilfe lief auf dem PR-Branch erfolgreich in [Workflow #42780777239](https://github.com/ManuEtt/Dnd/actions/runs/42780777239) und entfernte ihre temporäre Workflowdatei im selben Formatcommit. **Formatcommit:** `db3e2213a39d723761ca1e9d869ff75a836ecd99`. Der zwischenzeitliche Android-Lauf [#42780784186](https://github.com/ManuEtt/Dnd/actions/runs/42780784186) gehörte noch zum Commit mit der temporären Workflowdatei und scheiterte an der absichtlichen Projektprüfung der exakt zugelassenen Workflowdateien; die temporäre Datei ist im aktuellen Branch-Tree nicht mehr vorhanden. Eine vollständige CI-Abnahme des nachfolgenden finalen PR-Heads steht noch aus. Keine Änderung an Spielständen, Datenformaten, SQLite, App-Version oder Migrationen.




### 2026-11-10 – Modulgrenzen auch bei verlinkten Elternverzeichnissen schützen

Die Story-/Regelmodulprüfung weist nun symbolische Links in `app/` und `app/lib/` vor dem Durchlaufen der Dart-Dateien zurück. Zwei negative Regressionen prüfen beide Elternverzeichnisse, ohne externe Quellen einzulesen. Branch: `fix/chat-d/boundary-parent-symlink-20261110`. CI des neuen PR-Heads ausstehend. Keine Änderungen an Spielständen, SQLite, JSON, Android-Version oder Migrationen.




### 2026-11-10 – Verneinte Rückreisen in Rabenwacht respektieren

Eine ausdrücklich verneinte Rückreise zu einem bekannten Ort führt nicht länger zu einem ungewollten Ortswechsel. Die Spielleitung bittet stattdessen um eine eindeutige Reiseabsicht; bestätigte Rückreisen bleiben möglich. Drei Regressionstests prüfen verneinte Bewegung, bestätigte Rückkehr und bloße verneinte Ortsnennung. Fachmodule: `app/lib/story/rabenwacht_campaign.dart` und `app/test/rabenwacht_negated_revisit_test.dart`. Neu auf aktuellem `main` aufgebaut: Branch `fix/chat-b/rabenwacht-negated-revisit-main-20261110`; CI des neuen Branches noch offen. Keine Migration und keine Änderung an Regeln, Speicherformat oder Ressourcen.



### 2026-11-10 – Feuerball-Flächenvorschau für große Android-Schrift bedienbar machen

**Problem und Lösung:** Die Flächenvorschau des SRD-Feuerballs hatte 26-dp-Kartenzellen und einen separaten vertikalen Scrollbereich. Die Karte besitzt jetzt 48-dp-Touchziele; Titel, Anleitung, Hindernisbestätigung und Fehler scrollen als gemeinsamer Dialoginhalt mit kompaktem Abstand, während horizontales Kartenscrolling erhalten bleibt. Validierungsfehler sind für Screenreader als Live-Region ausgezeichnet. Die Oberfläche bleibt ausdrücklich eine reine Planungshilfe ohne Zauberwirkung oder Ressourcenbuchung.

**Nachweis:** [Draft-PR #673](https://github.com/ManuEtt/Dnd/pull/673) auf Branch `feat/chat-c/fireball-grid-accessibility-20261110`, Codecommit `c9b56edd103f47bdec39feb3174c2dac3f4dff39`, Testcommit `52158f792b4265bcbeb55a76817e709c122fcb65`. Vier neue Widget-Regressionen prüfen 320/360 dp bei 200 % Schrift und simulierter Android-IME, positive und negative Bestätigung, 32×32-Karte, 48-dp-Touchziele sowie Rücksetzen nach Bearbeitung. Eine vollständige **PR-CI auf dem finalen Branch-HEAD ist bislang nicht bestätigt**; lokale Flutter-/Dart-/Android-Tests und echte Geräte-/TalkBack-Prüfung stehen aus. Die letzte erfolgreiche main-CI #42788659259 ist kein Nachweis für den neuen PR. Keine Regel-, SQLite-/JSON-, Spielstands-, Backup-, API- oder Appversionsänderung und keine Migration.





### 2026-11-10 – Unabhängige Würfelnachweise für Wilder Angreifer

Die Regelvorschau weist wiederverwendete Würfelergebnisobjekte bei normalen und kritischen Waffentreffern zurück; unabhängig gewürfelte identische Ergebnisse bleiben zulässig. Betroffen: `app/lib/domain/srd_savage_attacker_rules.dart` und zugehörige Regressionstests. [PR #670](https://github.com/ManuEtt/Dnd/pull/670), Branch `feat/chat-a/savage-attacker-independent-rolls-20261110`. CI-Prüfung noch ausstehend; keine Migration oder Spielstandänderung.




### Regressionstest: Erzählung und bestätigter Spielzustand

`app/test/story_rule_boundary_regression_test.dart` prüft die bestehende StoryRuleBoundary mit vier Fällen: erlaubte Szenen-/StoryBible-Änderung, unzulässige Änderung bestätigter Fakten, unzulässige Änderung der Kampagnenidentität und unveränderte Kampagne. Nur Tests; keine Regel-, Speicher- oder Schnittstellenänderung.



- Rabenwacht: Rückreisen werden nur durch eigenständige Bewegungsverben ausgelöst; Begriffe wie „Vorgehen“ oder „Reisebericht“ lösen keinen Ortswechsel aus. Regressionstests prüfen beide Richtungen.






### 2026-11-11 – Unplausible Zahlen in der Kampfchronik ausblenden

- Die Kampf- und Würfelchronik übernimmt ungültige numerische Werte aus älteren/importierten Ereignissen nicht mehr als bestätigte Anzeige: insbesondere negative Schadens-/Heilmengen, gebrochene Würfel-/TP-Werte und NaN/Infinity. Gültige negative Gesamtwürfe, null Schaden und Bruchmeter bleiben sichtbar; TalkBack erhält dieselbe gefilterte Zusammenfassung.
- **Dateien:** `app/lib/ui/fantasy_combat_chronicle.dart`, `app/test/fantasy_combat_chronicle_test.dart`. **Branch:** `feat/chat-c/chronicle-numeric-display-20261111`. **Produkt-/Testcommit:** `50373e4987b2bb25cce9e4427c1c338351acdccc`. **PR:** [#685](https://github.com/ManuEtt/Dnd/pull/685), Entwurf, noch nicht integriert.
- Neue positive/negative Widgetregressionen einschließlich 320/360 dp und 200 % Schrift sind geschrieben, mangels lokalem Flutter-/Dart-SDK noch nicht ausgeführt; die neue PR-CI ist gesondert auszuwerten. Keine Änderungen an Regeln, gespeicherten Ereignissen, SQLite/JSON-Schema, App-Version oder bestehenden Spielständen; reale TalkBack-/Geräteabnahme steht aus.

### 2026-11-11 – CI-Abnahme der numerischen Kampfchronik

- Die ungültige Werte ausblendende Kampfchronik wurde auf dem Code- und Teststand `bb21090386bde88867789a34e4e577ff11349602` in [GitHub Actions #42958511774](https://github.com/ManuEtt/Dnd/actions/runs/42958511774) vollständig und erfolgreich geprüft: 669 Dart-Dateien unverändert formatiert, Flutter-Analyse fehlerfrei, 20 gezielte UI-Tests und 3.355 vollständige Flutter-Tests bestanden, Android-Debug-APK gebaut, native Android-Tests erfolgreich und drei optimierte APKs (arm64-v8a, armeabi-v7a, x86_64) samt Alpha-Artefakten erzeugt.
- [PR #685](https://github.com/ManuEtt/Dnd/pull/685) bleibt als Draft bis zur koordinierten Integration offen; der Main-Branch wurde nicht durch diesen PR geändert. Die Tests liefen in GitHub-CI, nicht lokal. Ein praktischer Android-/TalkBack-Gerätetest und eine Upgradeabnahme sind weiterhin offen. Keine Migration, keine Änderung an Spielständen, Regelengine, SQLite/JSON-Schema oder App-Version.



### 2026-11-11 – Epilogabschluss nur nach eindeutiger Vermächtniswahl

- **Problem und Lösung:** Die drei abschließenden Rabenwacht-Vermächtnisse konnten bisher durch beiläufige Erwähnungen ihrer Bezeichnung ausgelöst werden. Die Erkennung verlangt jetzt eine vollständige, einzelne Entscheidung; Fragen, Zitate, Vergleich mehrerer Optionen und Verneinungen lassen den Epilog offen. Bisherige direkte Befehle und ausdrückliche Ich-/Wir-Wünsche bleiben verwendbar.
- **Fachpfad und Tests:** `app/lib/story/fourteenth_voice_epilogue.dart` und `app/test/rabenwacht_epilogue_explicit_legacy_choice_test.dart` mit positiven/negativen Fällen, JSON-Wiederaufnahme und Schutz vor wiederholter Vergabe.
- **Branch:** `fix/chat-b/epilogue-explicit-legacy-choice-20261111`; **PR:** [#694](https://github.com/ManuEtt/Dnd/pull/694) (Draft). CI und Flutter-/Dart-/Android-Abnahme auf finalem Branch-HEAD noch offen; kein lokales Flutter-/Dart-SDK. Ein älterer grüner Workflow gilt nicht als Abnahme dieses PRs.
- **Kompatibilität:** Keine Migration, keine Änderung an Regel- oder Ressourcenbuchung, JSON/SQLite-Schema, bestehenden Wahlmarkierungen, App-Version oder externem KI-Anbieter.
- **Grenze:** Weitere Eindeutigkeitsprüfungen für Versammlungs- und Rückkehrbefehle stehen als eigenständige Aufgaben aus. Der PR ist noch nicht integriert.



### 2026-11-11 – Feuerpfeil: Live-Helden- und Gegnerwechsel sicher neu bestätigen

- **Problem:** Ein weiter geöffneter Feuerpfeil-Dialog behielt nach Helden- oder Gegnerwechsel die zuvor ermittelte Zauberklasse und situative Angriffserlaubnisse. Der sichtbare neue Gegner konnte damit einen alten Bestätigungsentwurf erben.
- **Lösung:** Bei neuer Helden- oder Encounter-Instanz werden Zauberklassen aus dem aktuellen Helden neu ermittelt, die interne Klassen-Auswahl neu aufgebaut und alle zwölf ziel- bzw. situationsgebundenen Checkboxen samt älteren Fehlern zurückgesetzt. Ein unveränderter Parent-Neuaufbau bewahrt eine bewusst gewählte Klasse und bestehende Eingaben.
- **Dateien:** `app/lib/ui/fire_bolt_dialog.dart`, `app/test/fire_bolt_live_snapshot_test.dart`.
- **Branch:** `feat/chat-c/fire-bolt-live-snapshot-20261111`; Code-/Testcommits `aa5d34f0c9708542c405d7de5e5da35677848d40`, `dac1c59aca348fa957fe595d7f5615fd41d3835a`.
- **Prüfungen:** Vier positive und negative Widget-Regressionen hinzugefügt; automatische Format-, Analyse-, Flutter- und Android-Prüfungen des finalen PR-HEAD stehen zum Zeitpunkt dieses Nachtrags noch aus.
- **Kompatibilität:** Ausschließlich Flutter-Dialogzustand; keine Änderung an Regeln, Domänenmodellen, JSON, SQLite, Spielstandschema oder App-Version. Keine Migration.



### 2026-11-12 – Gesamtintegration der vorhandenen Entwicklungsbranches

86 Nebenbranches mit erhaltener Quellhistorie auf einem Integrationsbranch zusammengeführt. Konflikte bei Akt VII, Heilzauber-Formularen, Reiseverben, Profilprüfungen und Dokumentation aufgelöst. Lokal 426 Python- und 79 Backendtests, Typecheck, Build, Struktur und Modulgrenzen bestanden. Gemeinsame Flutter-/Android-CI und sichere Branchbereinigung noch offen. Details und Herkunft: [Migrationsbericht](docs/parallel/MIGRATION_20261112.md), Branch `fix/integration/all-branches-20261112`. Keine Änderung der Spielstandformate.

### 2026-11-12 – Kampagnenrevisionen an der Story-/Regelgrenze absichern

- **Problem und Lösung:** Die reine Erzählgrenze nahm die Kampagnenrevision bislang vollständig aus dem Schutzvergleich aus. Erzählersetzungen dürfen jetzt weiterhin dieselbe Revision behalten; neue Story-Commits dürfen um genau eins fortschreiten. Rückschritte und ausgelassene Revisionen werden abgewiesen.
- **Dateien:** `app/lib/story/story_rule_boundary.dart`; neue deterministische Regressionen in `app/test/story_revision_boundary_test.dart` für erlaubte/unerlaubte Revisionsübergänge, Callback-Integration und JSON-Wiederaufnahme.
- **Branch:** `fix/chat-b/story-revision-boundary-20261112`; **PR:** [#700](https://github.com/ManuEtt/Dnd/pull/700) (Draft). Dart-/Flutter-/Android-CI des finalen Branch-HEADs noch separat zu prüfen; keine lokale SDK-Ausführung.
- **Kompatibilität:** Kein Datenformat-/SQLite-Schemawechsel, keine Migration oder Änderung an bestätigten Spielständen, Regel-/Quest-/Heldenwerten, App-Version oder externen KI-Kosten.
- **Grenzen:** Schutz bestehender Ereignishistorien ist ein gesondertes Prüfungspaket; das neue Arbeitspaket ist noch nicht in `main` integriert.

### 2026-11-12 – Bestätigte Ereignishistorie bei Story-Commits absichern

- **Problem:** Der Rückgabewert der Story-Commit-Schnittstelle durfte alte bestätigte Journalereignisse verändern, ohne den unveränderten Regelzustand zu verletzen.
- **Lösung:** Die Story-Engine schützt nun die vorhandene Reihenfolge und den Inhalt aller bestätigten Ereignisse. Ein neuer Commit darf höchstens ein konsistentes Ereignis mit neuer ID, passender Kampagnen-/Sitzungszuordnung und einem überprüften `stateAfter`-Checkpoint anhängen; semantisch gleiche JSON-Schlüsselreihenfolge bleibt erlaubt.
- **Dateien:** `app/lib/story/story_campaign_engine.dart`, neuer Regressionstest `app/test/story_event_history_append_only_test.dart` (fünf Testgruppen).
- **Branch/PR:** `fix/chat-b/story-event-history-append-only-20261112`, [#703](https://github.com/ManuEtt/Dnd/pull/703) (Draft; endgültigen HEAD und CI am PR prüfen).
- **Prüfungen:** Code/PR-Überschneidungen überprüft, neue Unit-Tests eingecheckt; vollständige Dart-/Flutter-/Android-CI zum Zeitpunkt dieses Nachtrags noch nicht abgenommen. Keine lokale SDK-Ausführung.
- **Kompatibilität:** Kein Versions-, SQLite-, Schema- oder API-Wechsel und keine Migration. Bestehende Spielstände werden nicht umgeschrieben; bestehende Erzählersetzung unbestätigter freier Züge bleibt unverändert.
- **Grenzen:** Integrationsreview und vollständige CI noch offen; keine Abnahme echter Geräte oder externer KI-Anbieter.

### 2026-11-12 – Bestätigte Dialognachrichten bei Story-Commits schützen

- **Problem:** Eine Story-Commit-Rückgabe konnte bisher bereits bestätigte Spieler- oder Spielleitertexte ändern oder entfernen, obwohl die Ereignis- und Regelzustandsgrenzen bestanden.
- **Lösung:** Die Story-Engine bewahrt alle früheren Dialogeinträge samt Reihenfolge und Inhalt. Höchstens eine neue, korrekt identifizierte Spielleiterantwort mit dem tatsächlich bestätigten Erzähltext darf bei einem Story-Commit hinzukommen.
- **Dateien:** `app/lib/story/story_campaign_engine.dart` und neue `app/test/story_message_history_append_only_test.dart` (fünf positive/negative Regressionstestgruppen inkl. JSON-Wiederaufnahme und unbestätigter Erzählersetzung).
- **Branch/PR:** `fix/chat-b/story-message-history-append-only-20261112`, [#706](https://github.com/ManuEtt/Dnd/pull/706) (Draft). Neue Flutter-/Backend-/Android-CI dieses PRs ist bei Veröffentlichung des Nachtrags noch ausstehend; der Vorgänger #703 und main sind separat vollständig grün.
- **Kompatibilität:** Keine JSON-/SQLite-/API-/Versionsänderung, keine Migration, keine Änderung an Regel- oder Heldenwerten, bestehende unbestätigte Freeturn-Rewrites bleiben erlaubt. Keine neuen externen KI-Kosten.
- **Grenzen:** Abschließende CI und Review erforderlich; kein Realgerät-/Provider-Nachweis dieses Pakets.
