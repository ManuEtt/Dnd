## 02.11.2026 – Main2e9 integriert, kombinierte lokale Prüfungen bestanden

Main `2e920f222ab8fd501d9d90bff580d0f8ccc42ff1` aus #471 ist regulär
in denselben Entwicklungsbranch integriert; ursprüngliche Basis war `5a88834c`.
Der abschließende Mergecommit ist über [PR #473](https://github.com/ManuEtt/Dnd/pull/473)
ermittelbar. Keine Quellkonflikte; einziger Markdown-Konflikt im Chat-A-Checkpoint
additiv gelöst, alle Main-Beiträge erhalten. Die eigenen 51 Guardzeilen und ihr
Dateihash bleiben unverändert. SQLite3/JSON1 unverändert, keine Migration.

**GETESTET auf dem kombinierten Stand:** **182 gezielte Flutter-Regressionen**
mit den eigenen UI-/SQLite-Fällen und den neuen Main-Paketen; **275 Pythonfälle**,
Projekt-/Importgrenzen-/SRD-Prüfung, **582 Dartdateien ohne Formatänderung** und
saubere Analyse. Neuer **ARM64-Debug-Build und 14 native JUnit-Tests** ohne
Fehler, Error oder Skip bestanden. Die vollständige lokale frühere Suite
**2.782 Flutter /262 Python /76 Backend** gehört ausdrücklich zum Vorgänger8dd
auf Basis5a; sie ist kein behaupteter neuer kombinierter Vollpass.

**OFFEN:** vollständige CI des aktuellen abschließenden Merge-Heads, optimierte
Alpha und reale Geräte-/TalkBack-/Upgrade-/Produktivsignierungsabnahme.
[PR-Checks](https://github.com/ManuEtt/Dnd/pull/473/checks) abwarten; PR bleibt
bis zur tatsächlichen CI-/Artefaktabnahme Draft. Kein Code-/SDK-Blocker bekannt.
Der aktuelle Quellencheckpoint/Patch wird gegen **Main2e9** erstellt; frühere
8dd-/5a-Archive bleiben unverändert erhalten. Main nicht direkt verändert.
Allgemeiner initialer manueller Rettungswurf bleibt das nächste getrennte Paket;
beide Klassen-Requirements weiterhin partial, Gesamt-SRD/Charakterassistent offen.

**Nachfolgend historische Prüf- und Checkpointstände vor Main2e9:**

## 02.11.2026 – lokale Vollabnahme des Chat-A-Pakets bestanden

**0.8.51+101**, Basis-Main `5a88834c98f5aca40395088c20c7e1dc5b587868`,
Branch `fix/chat-a/saving-throw-class-preflight-20261102`. Laufzeit-/Testcommit
`de8cef1bf9cd4cd67cfa7eb1916eec1b6b60f038`, früher Dokumentationscheckpoint
`d5cf52f1c27ecdb0f01f0ce461788cde12449310`. Nur Dokumentation folgt danach;
Laufzeit-/Testcode unverändert. [PR #473](https://github.com/ManuEtt/Dnd/pull/473)
ist Draft; die **[Checks des finalen aktuellen PR-Heads](https://github.com/ManuEtt/Dnd/pull/473/checks)**
sind separat abzunehmen. Kein Main-Merge und keine erfolgreiche neue CI behauptet.

**GETESTET:** `bash scripts/check.sh` vollständig mit Exit 0 bestanden:
**2.782 Flutter / 262 Python / 76 Backend**, 579 Dartdateien ohne Formatänderung,
Analyse sauber, Backend-Typecheck/Build und tatsächlicher lokaler Protokollsmoke.
Abschlussmarker `08:15 +2782: All tests passed!`; 72 neue Fälle und 159 gezielte
Regressionen sind darin keine zusätzliche globale SRD-Abnahme. Lokaler ARM64-
Debug-Build und **13 native JUnit-Tests** ohne Fehler, Error oder Skip bestanden.
Der frühzeitige Quellencheckpoint auf d5cf52f1 ist unabhängig geprüft: **1.369
Dateien**, CRC/Hashes/Größen/Modi, echte Patchanwendung auf Basis5a und isolierte
Git-Bundle-Wiederherstellung/fsck bestanden. Endcheckpoint und finale CI folgen.

**Koordination:** Vor PR erneut **27 fremde PRs** geprüft: ursprüngliche 23 Heads
unverändert, neue #469–#472 ohne Überschneidung der Fachdateien; deren CI lief beim
Audit noch. #468 teilt das Requirement-Register, bearbeitet andere IDs. Bei späterer
Konsolidierung die neue Version101 gegenüber100 und alle geprüften Belege erhalten.

**OFFEN:** aktuelle finale PR-CI, optimierte Alpha und reale Geräte-/TalkBack-/
Upgrade-/Produktivsignierungsabnahme. Allgemeiner initialer manueller Rettungswurf
bleibt das nächste gesonderte Paket; vorher frische PR-/Quellenprüfung. SQLite3/
JSON1 ohne Migration; beide Klassen-Requirements bleiben partial. Weitere Details
im Fachbericht `docs/parallel/CHAT_A_SAVING_THROW_CLASS_PREFLIGHT_20261102.md`.

**Historischer Frühcheckpoint vor der vollständigen lokalen Abnahme:**

## 02.11.2026 – Chat A: Klassenprüfung vor Rettungswurf-Wiederholungen, 0.8.51+101

**Vorläufiger Quellen-Checkpoint, keine vollständige Abnahme.** Basis-Main
`5a88834c98f5aca40395088c20c7e1dc5b587868`, Branch
`fix/chat-a/saving-throw-class-preflight-20261102`. Code-/Testcommit
`de8cef1bf9cd4cd67cfa7eb1916eec1b6b60f038` ist gesichert. Pull Request und finale CI
folgen nach den erforderlichen Prüfungen. Main bleibt
unverändert; Issue #425 und alte Branchmigration sind abgeschlossen.

**IMPLEMENTIERT:** Genau 51 zusätzliche Zeilen im bestehenden
`app/lib/domain/saving_throw_class_actions.dart`: bekannte SRD-Klassen und
kanonische Aliase, Gesamt-/eigene Klassenstufen, zulässiger Zweitklassensplit und
eindeutige Rettungswurfübungen vor Klassenbonus, Ressourcenverbrauch und neuem
W20 prüfen. Die lesende Verfügbarkeitsabfrage liefert für solche ungültigen
Profile `false`. Berechnungen, Ressourcenregeln und übriger vorhandener Code
bleiben unverändert. In der bestehenden Engine-Kette erzeugt ein abgewiesener
Textversuch absichtlich `rules.blocked` und eine Revision; Helden-/Ressourcenwerte
und RNG ändern sich nicht. Historische Profile werden beim Öffnen nicht repariert.

**GETESTET:** 62 neue Domain-, acht Engine-/SQLite- und zwei tatsächliche App-UI-
Tests bestanden, zusammen **72 neue Fälle**. **159 gezielte neue und bestehende
Regressionen** bestanden (157 Domain-/Flowfälle plus zwei UI-Fälle). Lokaler
ARM64-Debug-APK-Build bestanden. Positivfälle
für alle zwölf Klassen, gültige Aliase, tatsächliche Kämpfer-Klassenstufe,
Übung/Erschöpfung einmal sowie negative Klassen-/Stufen-/Übungsdaten. Speicherfälle
prüfen Ablehnung, einmalige Ressourcenbuchung, Replay, stale Zweitcontroller,
Neustart, Export/Import und späten SQLite-Rollback. Ein vorher legitimer W20 wird
bei spätem SQL-Fehler nicht als rückrollbar behauptet.

**NICHT ABGESCHLOSSEN / NICHT GETESTET:** Vollständiges `scripts/check.sh` und
native Android-Tests laufen zum Frühcheckpoint noch; kein Vollpass behauptet.
Optimierte Alpha und aktuelle GitHub-CI stehen aus. Geräte-/TalkBack-/Upgrade-
und produktive Signierungsabnahme fehlen. Kein Legacy-Profil-Korrektur-UI-Flow
wird behauptet.

**BLOCKIERT:** Kein bekannter fachlicher oder GitHub-Zugriffsblocker; reparierte
UI-Fixtures haben 2/2 bestanden, vollständige Abnahme läuft. Nur begrenzter
lokaler Speicherplatz: frühes Quellen-ZIP, Patch und Bundle außerhalb des
Projekts priorisieren. Keine Quellen, Spielstände, WIP oder alten Artefakte löschen.

**NOCH NICHT IMPLEMENTIERT:** Allgemeiner initialer manueller Rettungswurf ist
in diesem Paket unverändert. Weitere Rettungswurfquellen, situative Modifikatoren,
kompletter Charakterassistent und Gesamt-SRD bleiben offen. SQLite **3** / äußeres
JSON **1**, keine Migration. `CLASS-K-MPFER-9-BASE-INDOMITABLE-0` und
`CLASS-M-NCH-14-BASE-DISCIPLINED-SURVIVOR-0` nur **partial**; keine globale Abschlussquote.

Vor Beginn 23 offene PRs anhand ihrer Dateilisten geprüft. PR #468 bleibt getrennt
und auf seinem eigenen Head CI-grün; seine Konzentrationsdateien werden nicht
verändert. Andere Chat-A-/B-/C-/D-Pakete nicht erneut implementieren oder mergen.
Gemeinsame README-/Checkpoint-Zusätze konsolidiert Chat D später additiv.

**Genau nächstes unabhängiges Paket:** Allgemeinen initialen manuellen Rettungswurf vor automatisch abgeleiteten Klassenboni und W20 validieren; schreibfreie Charakterbogen-Vorschauen unverändert lassen. Zuerst frische Main-/PR-Dateilisten prüfen. Akzeptanz: unbekannte/inkonsistente Klassen vor Bonus/RNG ablehnen, gültige Aliase und Mehrklassen behalten dieselben Boni, Domain-, SQLite-/Retry- und tatsächliche UI-Regressionen bestehen.

Fachnachweis: `docs/parallel/CHAT_A_SAVING_THROW_CLASS_PREFLIGHT_20261102.md`.
Die darunter bewahrten Berichte gelten jeweils für ihren damaligen Stand.

---

## 31.10.2026 – Migration abgenommen, Alpha 0.8.49+99

Gesamtintegration #440 und Herkunftsnachtrag #444 sind regulär integriert.
Produkt-Main: `47ab002872b7d46daeae03bb558258cf2ea73e4a`.
[Main-CI 41183481979](https://github.com/ManuEtt/Dnd/actions/runs/41183481979)
**erfolgreich**: 2.710 Flutter-, 262 Python-, 76 Backendtests, 20 zusätzliche
UI-Fälle, 576 Dartdateien unverändert, Analyse/Typen/Build/Protokollsmoke,
Android-Debug/native und drei optimierte ABI-APKs bestanden. Lokaler voller
Flutter-Testlog ohne Abschluss bei 1.154 Fällen zählt nicht als Vollpass.

[Cleanup 41184619156](https://github.com/ManuEtt/Dnd/actions/runs/41184619156)
**erfolgreich**; alle 53 erfassten Altbranches frisch einzeln auf vollständige
Main-Ancestry, tatsächliche Remote-Abwesenheit und exakten Archivtag-SHA geprüft.
[SHA-Nachweis](docs/parallel/MIGRATION_ACCEPTANCE_20261031.json).
Neu begonnene aktive PRs #446–#448 bleiben geschützt. Abschluss #445 verändert
nur Dokumentation, keine Spielregeln, Tests, Schemas, Versionsnummern oder UI.
SQLite3/äußeresJSON1 erhalten. Realgerät/TalkBack/Upgrade/Produktivsignierung
weiter offen; sechs neue Regel-APIs noch ohne vollständige Spielanbindung.
Nächster Schritt: bestätigte SRD-Caster-Aliase bei normalen Mehrklassen-Slots
kanonisieren; Kriterien im [Checkpoint](docs/CODEX_CHECKPOINT.md).

---

## 30.10.2026 – Gesamtintegration, Alpha 0.8.49+99, Issue #425

Alle 45 ursprünglichen Entwicklungsheads und der neue Integrationsbranch #437
regulär mit Historie vereinigt. Drei reproduzierte Integrationsfehler behoben
(Konzentrations-Gesamtgrenzen, Zweitklasse Stufe 0, NPC-Bidi-Namensvergleich).
Keine SQLite-/JSON-Migration. Getrennte Fachprüfungen bestanden; kombinierte
Vollsuite und Android-/PR-/Main-CI in Abnahme, Branchbereinigung erst nach
nachgewiesenem Erfolg. Aktuelle Ergebnisse und Grenzen: [Checkpoint](docs/CODEX_CHECKPOINT.md)
und [Gesamtbericht](docs/parallel/ALL_BRANCHES_MIGRATION_20261030.md).
Alle folgenden älteren Angaben sind historische Momentaufnahmen, bytegenau
zusätzlich unter `docs/history/migration_20261030/` erhalten.

---

## Chat A – offener Regel-PR: Todesrettungs-Klassenprüfung (30.10.2026)

Basis-Main `55fe4447`, Arbeitsbranch `feat/chat-a/death-save-class-validation-20261030`,
Laufzeit-/Testcommit `ee1e5a19e03b5db60fad838d0da36d1f360b84bc`. Unbekannte Haupt-/Zweitklassen können keinen
Mönch-Todesrettungsbonus oder Klassen-Wiederholungswurf mehr freigeben; auch
alte offene Proben werden vor einem neuen Wurf geprüft. Historische Profile und
unversionierte Proben bleiben lesbar, keine DB-/JSON-Migration. **2.504 Flutter-, 221 Python- und 72 Backend-Tests bestanden**, darunter 93
gezielte Domain-/Flow-/SQLite-/UI-Fälle. Formatprüfung 537 Dateien unverändert,
Analyse/Backend-Typecheck/Build/Protokollsmoke sauber. ARM64-Debug-Build und zwölf native App-Tests ebenfalls bestanden.
[PR #416](https://github.com/ManuEtt/Dnd/pull/416) · [CI des aktuellen PR-Kopfs](https://github.com/ManuEtt/Dnd/pull/416/checks).
Kein Merge nach Main behauptet; Chat D konsolidiert diesen eigenen PR mit den
parallelen Paketen. Version weiterhin Basis0.8.48+98. Geräteprüfung bleibt offen.
[Chat-A-Checkpoint](docs/parallel/CHAT_A_CHECKPOINT.md) ·
[Fachnachweis](docs/parallel/CHAT_A_DEATH_SAVE_CLASS_VALIDATION_20261030.md).
## Geprüfter Integrationsstand vor erneuter Abnahme

Main ist während dieses Pakets auf `69bfe78ec4eeb30042b26971978038a2ee9dac34`
(PR413, barrierefreie Todesrettungsoberfläche) weitergelaufen. Dieser Stand wird
regulär in den eigenen Branch übernommen; beide README-/Checkpoint-Berichte
bleiben erhalten. Der frühere Vollversuch auf Basis55fe4447 wurde vor Abschluss
bewusst beendet und gilt nicht als bestandene Vollsuite, auch wenn Flutter beim
SIGTERM Exit0 liefert. Die kombinierte Vollsuite und finale CI werden neu geprüft.
Der eigene Rast-Laufzeit-/Testcode19fe5e16 ist unverändert. Main wird durch diesen
Branch-Merge nicht verändert; PR416 und andere fremde Pakete bleiben getrennt.

## Chat A – Kurzrast-Ressourcenprüfung (offener PR#428, 30.10.2026)

[PR#428](https://github.com/ManuEtt/Dnd/pull/428) · [aktuelle Checks und Vollabnahme](https://github.com/ManuEtt/Dnd/pull/428/checks).
Basis-Main55fe4447, Branch `feat/chat-a/short-rest-resource-preflight-20261030`,
Quellcode-/Testcommit `19fe5e16394fae096c082a86e7aa8886461fc883`. Ungültige Klassen-/Paktressourcen werden im
Kurzrastpfad mit Trefferwürfeln vor RNG und Erholung geprüft. **2495 Flutter-/221 Python-/72 Backend-Tests auf kombiniertem Stand bestanden**,
538 Formatdateien unverändert, Analyzer sauber. Zusätzlich ARM64-Debug und zwölf
native App-Tests bestanden; darunter65 gezielte Domain-/Bestands- und sieben neue
Flow-/SQLitefälle. Vollständige
Test-/Buildzahlen und CI-/Artefaktnachweise stehen im aktuellen PR; keine
Geräteabnahme behauptet. Langrast und Engine-Null-HD-Sonderpfade bleiben getrennt.
Appbasis0.8.48+98, SQLite3/JSON1 unverändert. Voriger PR416 bleibt separat offen;
Integration/Dokumentationskonsolidierung durch Chat D, Main nicht verändert.
[Chat-A-Checkpoint](docs/parallel/CHAT_A_CHECKPOINT.md) ·
[Fachnachweis](docs/parallel/CHAT_A_SHORT_REST_RESOURCE_PREFLIGHT_20261030.md).

# Codex-Checkpoint – Würfelraunen

## Abnahme – Mönch-Werkzeugwahl, Alpha 0.8.48+98

Stand: 29.10.2026, UTC. [PR #390](https://github.com/ManuEtt/Dnd/pull/390)
ist regulär integriert. Geprüfter Produkt-Main:
`4193000fd28154eeb8b0be3497acc722f674c5ab`; getesteter Arbeitskopf
`53e8e72a58dc07bda07cc50a984142465a8cef79`, Branch
`feat/character-monk-tool-proficiency-20261029`, Basis `fde0ef6e`.
Der PR-Checkout `2b211456` und Produkt-Main haben denselben vollständigen
Git-Baum `1f976980975d5a29ac0277c44e1bc7b79d062ab3`.

**IMPLEMENTIERT:** Neue Erstklassen-Mönche wählen ausdrücklich eine von 27
Handwerkszeug-/Instrumentübungen. Paket A liefert dasselbe Werkzeug und 11 GM;
B liefert 50 GM ohne Werkzeug, die Übung bleibt bestehen. Klassenbeleg v3
prüft Quelle und Paketbindung; v1/v2 bleiben unverändert lesbar und ungeklärt.
Keine automatische Nachvergabe, kein zweiter Gold-/Inventargewinn bei Wiederwahl.
Historisch bestätigte Übungen überleben spätere Anzeigenamens-/Inventaränderungen;
Mönch als neue Zweitklasse erteilt keine Erstklassen-Werkzeugübung.

Der Charakterbogen zeigt belegte Übungen und eine explizite Attributs-/Fertigkeits-
Probenvorschau. Einmaliger Übungsbonus, Vorteil bei passender trainierter Fertigkeit,
Zustände/Erschöpfung, Rüstungsnachteil für Geschicklichkeit (Heimlichkeit) und
Werkzeug-Verlässliches-Talent ab Schurke 7 sind berücksichtigt. Die Vorschau führt
keinen Wurf oder Werkzeugvorgang aus. Audit prüft Pflichtwahl/Paketbindung separat.
Die reproduzierte Sperre Mönch→Barbar→Mönch bei bereits übernommenem Paket ist
behoben. SQLite **3** / äußeres JSON **1** unverändert; keine DB-Migration.

**GETESTET:** Lokal `bash scripts/check.sh` auf `53e8e72a` vollständig bestanden:
**2.450 Flutter-, 221 Python-, 72 Backend-Tests**, Format 535 Dateien unverändert,
Analyzer/Backend-Typen/Build/Protokollsmoke erfolgreich. Zusätzlich ARM64-Debug-APK
und zwölf native `:app:testDebugUnitTest`-Fälle ohne Fehler/Skip. Finale
[PR-CI 40920118585](https://github.com/ManuEtt/Dnd/actions/runs/40920118585)
**erfolgreich**: dieselben 2.450/221/72 sowie 20 gezielte UI-Fälle,
Debug-APK/native Tests und alle drei optimierten ABI-APKs/Alpha-/Quellpakete.
Die zusätzliche [Main-CI 40922492508](https://github.com/ManuEtt/Dnd/actions/runs/40922492508)
ist ebenfalls vollständig **erfolgreich** auf `4193000f`; tatsächliche Logs
bestätigen dieselben Zähler und sämtliche Build-/Paket-Schritte.

Gezielte Gegenfälle: alle 27 Werkzeuge mit A/B, alle zwölf historischen Klassen
mit v1/v2, ungültige Quellen/IDs/Paketkonflikte, Doppelübungen, Abbruch/Retry,
JSON/SQLite-Neustart, stale Editor ohne Änderungen aller sechs Tabellen und
320/360 dp bei 200 % Schrift mit Tastatur/Semantik. Der alte rote Vorlauf
[40918212562](https://github.com/ManuEtt/Dnd/actions/runs/40918212562) scheiterte
am erwarteten Audit-Zähler 11 statt jetzt 12 beim Mönch. Er ist repariert und
durch die vollständige grüne Wiederholung ersetzt; kein Test deaktiviert.
Ein früher bewusst beendeter Lauf gilt nicht als bestandene Vollsuite.

Alle **1.286** heruntergeladenen Main- und PR-Quelldateien mit Hash/Modus, Alpha-Quellpaket,
echte Binärpatch-Anwendung auf `fde0ef6e` und isoliertes Bundle/fsck sind geprüft.
ARM64-APK: Version **0.8.48+98**, minSDK24/targetSDK36, v2-Debug-Testsignatur.
[Source-ZIP/Patch/Manifest/History-Bundle](https://github.com/ManuEtt/Dnd/actions/runs/40922492508/artifacts/12918224840) ·
[ARM64-Alpha](https://github.com/ManuEtt/Dnd/actions/runs/40922492508/artifacts/12918823598).
Quell-ZIP-SHA256: `9070e1754b5d2838121f320a54c8d1fa5d93120b51f4f7bea6f47db51844116a`;
APK-SHA256: `4fdf28d6581dd94d7cbcdc7f00f470b313c249cd52d45c3d1ae454b20ae69c79`.

**NICHT GETESTET:** echtes Android-Gerät/TalkBack, installiertes Altversionsupgrade,
produktive Release-Signatur. **BLOCKIERT:** kein angeschlossenes Testgerät;
kein Code-/GitHub-Zugriffsblocker. **NOCH NICHT IMPLEMENTIERT:** vollständiger
Charakter-Wizard und übrige Spezies-/Klassen-/Talent-/Zauberpflichtwahlen;
ausgeführte Werkzeugaktionen samt Würfel-/Zeit-/Materialtransaktion.
`RULE-EQUIPMENT-TOOLS` / `EQUIP-CHOICES` bleiben `partial`; 1.419 Prüfaufträge
und neun Inventurlücken sind kein globaler SRD-Fertigstellungsprozentsatz.

Der eigene Produktbranch wurde nach grüner Main-CI durch
[Cleanup 40924681196](https://github.com/ManuEtt/Dnd/actions/runs/40924681196)
remote entfernt, exakt als
`archive/merged-20261027/feat/character-monk-tool-proficiency-20261029-53e8e72a58dc`
erhalten; fünf aktive fremde PR-Branches bleiben bestehen.

Amtliches SRD 5.2.1 S.8–9/49/63/83/93–95, CC BY 4.0;
THIRD_PARTY_NOTICES.md erhalten. Regel-/Story-Grenze und KI-Autorität unverändert.
Dieser anschließende Dokumentationsabschluss auf Branch
`docs/monk-tool-abnahme-20261029` ändert keine App-, Backend-, Skript- oder
Workflowdatei und erhöht keine Version. Seine statischen/Python-Prüfungen sind
separat; keine neue APK/Produkt-CI für den reinen Dokumentationskopf behaupten.

**Nächster Schritt:** drei Barden-Instrumentübungen und Paket-A-Instrumentbindung
nach amtlicher SRD-Quellenprüfung ausdrücklich auswählen und persistent belegen.
Neue Entscheidung kompatibel versionieren; v1/v2/v3 weder verschärfen noch mit
vermuteten Übungen anreichern. DoD: gültige/ungültige Instrument-IDs, drei eindeutige
Übungen, Paket A/B, Abbruch/Retry/stale Revision, Alt-JSON/SQLite-Neustart und
320/360 dp bei 200 %/IME/Semantik, danach komplette Prüfkette und finale PR-CI.
Keine automatische Fortsetzung nach Sitzungsende.

## Wiederaufnahme und Sicherung

1. Main, offene PRs und CI erneut live prüfen. Beim Abschluss sind #387–#389
   sowie #391/#392 fremde aktive Pakete; sie wurden nicht übernommen/gelöscht.
   Vorhandene WIP-Worktrees einschließlich Dnd-items bleiben erhalten.
2. AGENTS.md, Fortsetzungsprompt, diesen Checkpoint, README und amtliche Quellen
   lesen; Mönch nicht neu implementieren. Bardenpaket gegen offene PRs abgleichen.
3. `python3 scripts/generate_fantasy_buttons.py`, Projekt-/Grenz-/Coverageprüfer,
   221 Pythonfälle; bei Codeänderung `bash scripts/check.sh`, Debug/native und CI.
4. Alte Schreibstände bytegenau samt Git-Blob/SHA in
   docs/history/monk_tool_acceptance_20261029/ und monk_tool_start_20261029/.
5. Lokale Sicherungen außerhalb des Projekts:
   `/workspace/artifacts/character-monk-tool-20261029/`; Endstand im Unterordner
   `abschluss/`, Index `ARTEFAKTE_UND_IMPORT.md`. Source-ZIP enthält keine APK,
   privaten Spielstände, SDKs oder Schlüssel. Öffentliche Downloadlinks oben.
   Patchbasis ausdrücklich `fde0ef6ed8b419d6a31c701a03aa05d61994c352`; zuerst in
   separatem Branch/Clone `git apply --check <patch>` ausführen, bestehendes Main
   nicht mit ZIP-Dateien überschreiben. Auf integriertem Main keinen Patch erneut
   anwenden. Git-Bundle ermöglicht vollständige Wiederherstellung mit Historie.

Dokumentationsprüfung: 221 Pythonfälle, Projekt-/Grenz-/Registerprüfung erfolgreich.
`git diff --check` außerhalb des bytegenauen historischen Archivs sauber. Die
archivierte Original-CHANGELOG-Zeile 1061 enthält bereits im Quellstand ein
Leerzeichen am Zeilenende; es bleibt für die nachprüfbare Originaltreue erhalten.
