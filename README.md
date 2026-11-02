# Würfelraunen – Der lebendige Spielleiter

## Chat C – Mehrgegner-Initiative bei 200 % Schrift und IME (02.11.2026)

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

**Chat-A-Fachpaket (02.11.2026, separater PR):**
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

**Nächster Chat-A-Schritt:** nach
koordiniertem Merge einen autorisierten
Metamagie-Auswahlbeleg am Helden
persistieren und Distant Spell nur
bei nachweisbarer aktueller Wahl
in die atomare Cast-Transaktion aufnehmen.

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

## Chat B – verzögerte KI-Antwort nach SQLite-Neustart (31.10.2026)

Ein neuer Flutter-Regressionstest schützt vor einer Story-Provider-Antwort, die erst nach einer parallelen, bereits bestätigten SQLite-Änderung ankommt. Der positive Gegenfall bestätigt genau einen narrativen Spielzug; der Konfliktfall bewahrt Journal, NPC-Notizen, Story-Fäden, Heldenzustand und rekonstruierte Kampagne. Branch `feat/chat-b/delayed-story-response-restart-20261031` von `47ab002872b7`; CI-Ausführung dieses Pakets steht bei Erstellung noch aus. Kein Schemawechsel, keine neuen API-Kosten.

> **CHAT C – neu im separaten Draft-PR [#447](https://github.com/ManuEtt/Dnd/pull/447) (31.10.2026):**
> Während einer noch offenen Schildreaktion zeigt die Kampfchronik nur
> bestätigte Angriffswürfel, keinen vorzeitigen Schaden oder kritische
> Zusatzwürfel. Widget-Regressionen für 320/360 dp, 200 % Schrift und
> TalkBack-Semantics wurden ergänzt; erfolgreiche CI und echte
> Geräteabnahme stehen noch aus. Diese Änderungen sind **nicht Teil von main**.

## Chat A – Zauberaktion und Zauberplatz als gemeinsames Staging (31.10.2026)

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

## Chat D – Unicode-Zeilentrenner in Android-Backupdateinamen (31.10.2026)

[PR #449](https://github.com/ManuEtt/Dnd/pull/449) auf `fix/chat-d/backup-unicode-separators-20261031`, Basis-main `5a88834c98f5aca40395088c20c7e1dc5b587868`: Die native SAF-Dateinamenprüfung verbietet jetzt auch Unicode-Zeilen- und Absatztrenner (U+2028, U+2029). Diese werden von der bisherigen ISO-Steuerzeichen- und Unicode-FORMAT-Prüfung nicht erfasst. Negative und positive Kotlin-Regressionstests sichern die Sperre sowie gültige Namen mit Umlauten, Emojis, gewöhnlichen Leerzeichen und kombinierenden Zeichen ab. Vollständige GitHub-CI/Android-Geräteabnahme bei Erstellung noch offen. Keine Migration von SQLite, JSON-Spielständen oder Appversion; kein Eingriff in Regeln, UI oder Story. Parallel integrierte Dokumentation muss vor Review/Merge erhalten bleiben.

---

### Chat D – portable Quellcode-ZIP-Dateinamen (PR #451)

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

### Chat D – Unicode-sichere Alpha-APK-ZIP-Einträge (PR #460)

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

### Chat D – Gradle-Wrapper-JAR gegen Unicode-Kontrollzeichen absichern (PR #462)

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

### Chat D – Gemeinsame Unicode-ZIP-Schutzprüfungen (Integrationspaket, 01.11.2026)

Die drei fachlich getrennten Korrekturen [#451](https://github.com/ManuEtt/Dnd/pull/451),
[#460](https://github.com/ManuEtt/Dnd/pull/460) und
[#462](https://github.com/ManuEtt/Dnd/pull/462) sind auf ihren **exakten finalen
Einzel-Commits vollständig CI-grün**. Dieser unabhängige Integrationsbranch führt
die sechs ursprünglichen Python-Code-/Test-Blobs unverändert zusammen; die
zugehörigen README-, zentralen und Chat-D-Checkpoint-Nachträge werden additiv
ohne Verlust historischer Statusangaben kombiniert. Für die gemeinsame
Kombination ist eine **eigene vollständige CI** erforderlich. Alte Hinweise
"Draft/CI ausstehend" in den historischen Einzel-Abschnitten beschreiben
den damaligen Zustand, nicht die aktuelle Einzelabnahme.
Die kombinierte Abnahme erfolgt ausschließlich im Integrations-PR;
kein automatischer Merge, kein Branchlöschen, keine Änderungen an
Spielstand-, SQLite- oder JSON-Schemata.

---

### 02.11.2026 – gemeinsame A–D-/ZIP-Sicherheitsintegration

Die beiden unabhängig CI-geprüften Integrationspakete
[#454](https://github.com/ManuEtt/Dnd/pull/454) (vier A–D-Pakete,
[CI #41244568578](https://github.com/ManuEtt/Dnd/actions/runs/41244568578))
und [#466](https://github.com/ManuEtt/Dnd/pull/466) (drei Chat-D-ZIP-Schutzpakete,
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

### 02.11.2026 – Chat D: Unix-Dateitypen im Gradle-Wrapper-JAR prüfen

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

### Chat D – kollidierende APK-ZIP-Dateinamen abweisen (02.11.2026)

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

### Chat D – zusammen geprüfte Archivvalidierung (Integrations-PR, 02.11.2026)

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

### Chat A – 0-TP-Sperre für Kriechen und Aufstehen (PR #487, 02.11.2026)

Ein historischer Held mit 0 TP kann ohne gespeichertes `bewusstlos`-Flag nicht mehr durch `GameEngine.crawl` oder `GameEngine.standUp` bewegt werden. Beide spezialisierten Bewegungsregeln verlangen vor der Bestätigung bekannte positive TP und einen lebenden Helden. Legacy-JSON und SQLite-Daten werden beim Lesen nicht verändert; nach bestätigter Heilung bleibt der normale Ablauf möglich. Vier neue Flutter-Domänen-/Engine-Regressionen (positive und negative Fälle) sind ergänzt. **CI auf dem finalen PR-HEAD noch offen; kein lokal installiertes Flutter-/Dart-SDK.** Quelle: SRD 5.2.1, *Dropping to 0 Hit Points*, S. 17, CC BY 4.0. [Pull Request #487](https://github.com/ManuEtt/Dnd/pull/487); Regelabdeckung weiterhin teilweise.


## Chat B – bestätigte NPC-Beziehungen für die Kampagnenwiederaufnahme (02.11.2026)

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

### Chat D – Unicode-sichere Pfadkollisionen im Gradle-Wrapper-JAR (02.11.2026)

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

### Chat D – Datei-/Verzeichnis-Kollisionen in ZIP-Archiven verhindern (02.11.2026)

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

### Chat D – vorbereitete Integration vollständig getesteter A/B/C-Pakete (02.11.2026)

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

### Chat D – vorbereitete Integration der PRs #478, #479, #486, #491 (02.11.2026)

Die folgenden Originaldokumentations-Ergänzungen stammen aus vier getrennten,
vollständig CI-geprüften Quell-PRs; sie werden ohne Verlust der bisherigen
Main-Historie an die aktuelle README angefügt. Der kombinierte Draft ist
bis zur vollständigen eigenen CI nicht zur Integration freigegeben.

---

#### Dokumentationsübernahme aus PR #478

**Chat-A-Fachpaket (02.11.2026, separater PR):** Für
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

**Nächster Chat-A-Schritt:** persistente
Metamagiewahl und atomare Slot-/Punkt-/Effekt-
Transaktion nach koordinierter Integration
der bisherigen Vorbereitungs-/Raster-PRs.


---

#### Dokumentationsübernahme aus PR #479


### Chat C: Bestätigte Zauberwirkungen bei großer Schrift und Tastatur (02.11.2026)

[PR #479](https://github.com/ManuEtt/Dnd/pull/479) macht den Dialog zur ausdrücklich bestätigten Zauberwirkung bei 320/360 dp, 200 % Schrift und geöffneter Android-Tastatur insgesamt scrollbar, kürzt lange Laufzeittexte und kennzeichnet Validierungsfehler für Screenreader. Vier Widgettests prüfen Abbruch, Belegprüfung, Bestätigung und gezieltes Entfernen einer bestehenden Quelle. **CI auf finalem #479-HEAD noch zu prüfen.** Keine SRD-, Zauberwirkungs-, Ressourcen-/Spielstand-, Domain- oder Datenformatänderung.

---

#### Dokumentationsübernahme aus PR #486


## Chat B – begrenzter bestätigter NPC-Rückblick (02.11.2026)

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

### 02.11.2026 – Chat B: unsichtbare Zeichen in neuen KI-Geschichten

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

### Chat C: Materialinventar-Dialog bei 200 % Text und Android-Tastatur (02.11.2026)

[PR #474](https://github.com/ManuEtt/Dnd/pull/474) verbessert den Materialinventar-Dialog bei 320/360 dp, 200 % Text und 220 dp geöffneter Tastatur: gemeinsamer vertikaler Dialog-Scrollbereich, kompakte Insets, Screenreader-Live-Regionen für Rezept-/Validierungsfehler. Fünf neue Widgettests prüfen fehlendes Rezept, ungültige Materialbestätigung, bestätigte read-only Inventarstapel und die Astral-Projection-Zieleingabe. **CI auf dem finalen PR-HEAD noch ausstehend.** Keine SRD-/Inventar-/Spielstands-/Versions- oder Datenformatänderung.

---

### Chat C: Kreaturenerfassung bei 200 % Schrift und Android-Tastatur (02.11.2026)

[PR #469](https://github.com/ManuEtt/Dnd/pull/469) macht die zusätzliche Kreaturenregistrierung mit vier Eingabefeldern und Bestätigungs-Checkbox bei 320/360 dp, 200 % Schrift und geöffneter IME vollständig scrollbar. Fehler werden über eine Screenreader-Live-Region angekündigt. Vier neue Widgettests prüfen ungültige Angaben, Abbruch, gültige bestätigte Registrierung und TP-Korrektur. **Finale CI des neuen PR steht aus**; SRD-Regeln, Speicher, Datenformate, App-Version und bestehende Verantwortlichkeitsgrenzen bleiben unverändert.

**Nachweis Chat-D-Integration (02.11.2026):** Die zuvor als ausstehend beschriebenen vollständigen Einzel-CIs sind auf den finalen Heads abgeschlossen und erfolgreich: [#474 / 41396373761](https://github.com/ManuEtt/Dnd/actions/runs/41396373761) und [#469 / 41393278139](https://github.com/ManuEtt/Dnd/actions/runs/41393278139). Kombination mit #495 erfordert eine eigene CI.
