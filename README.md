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

### Chat C: Materialinventar-Dialog bei 200 % Text und Android-Tastatur (02.11.2026)

[PR #474](https://github.com/ManuEtt/Dnd/pull/474) verbessert den Materialinventar-Dialog bei 320/360 dp, 200 % Text und 220 dp geöffneter Tastatur: gemeinsamer vertikaler Dialog-Scrollbereich, kompakte Insets, Screenreader-Live-Regionen für Rezept-/Validierungsfehler. Fünf neue Widgettests prüfen fehlendes Rezept, ungültige Materialbestätigung, bestätigte read-only Inventarstapel und die Astral-Projection-Zieleingabe. **CI auf dem finalen PR-HEAD noch ausstehend.** Keine SRD-/Inventar-/Spielstands-/Versions- oder Datenformatänderung.
