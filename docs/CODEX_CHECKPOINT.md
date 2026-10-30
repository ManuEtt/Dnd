# Codex-Checkpoint – Würfelraunen

## 30.10.2026 – Chat C: Todesrettungs-Entscheidungen bei 200 % Schrift

- **Basis-main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`.
- **Branch:** `feat/chat-c/death-save-actions-large-text-20261030`.
- **Implementierungscommit:** `bb3d1eaa9227cdaed84b845f6177f9d9de632fc2`.
- **Problem:** Die drei möglichen Entscheidungen des vorläufigen Todesrettungswurfs
  teilen sich bei 200 % Android-Schrift den verfügbaren `Wrap`-Platz.
  Längere Buttontexte werden dabei schmal und möglicherweise gekürzt, insbesondere
  bei 320/360 dp und offener Tastatur.
- **IMPLEMENTIERT:** Im reinen Flutter-UI-Widget
  `app/lib/ui/death_save_decision_panel.dart` stellt der `LayoutBuilder`
  bei weniger als 500 dp und ab 180 % Schrift verfügbare Aktionen
  untereinander in voller Breite dar. Der Standard-Wrap bleibt erhalten.
  Status- und Regelverfügbarkeitsprüfung bleiben unverändert.
- **TESTS HINZUGEFÜGT:** `app/test/death_save_actions_large_text_test.dart`
  prüft zwei positive Touch-Fälle bei 320/360 dp und 200 %, gesperrte Aktionen
  bei busy, fehlende Klassenwiederholung sowie Standardlayout (5 Fälle).
- **GETESTET:** Vor Start aktuellen Main, alle offenen PR-Aufgabenbereiche
  und geänderte Dateien der neuen PRs #405–#412 geprüft; andere PRs
  verändern diese neuen technischen Dateien nicht. Testausführung und CI
  müssen auf finalem PR-Head separat bestätigt werden.
- **NICHT GETESTET:** Lokale Flutter-/Android-Toolchain nicht verfügbar;
  Android-TalkBack, echte Gerätetastatur und Geräte-Upgrade nicht geprüft.
- **BLOCKIERT:** Keine lokalen SDKs. Gemeinsame README- und Checkpoint-Änderungen
  bei späterer Integration durch Chat D additiv konsolidieren.
- **Migration/Kompatibilität:** Keine Modell-, JSON-, SQLite-, SRD- oder
  Ressourcenänderung, keine Migration oder Versionsänderung.
- **Nächster Schritt:** Echtes Android-TalkBack-Gerät bei 320 dp und 200 %
  Schrift prüfen: alle verfügbaren Entscheidungen vollständig vorlesen,
  mit IME fokussieren und auslösen können, gesperrte Entscheidung ohne Callback.

---



## Chat D – Sicheren Import originaler Fantasy-Grafiken absichern (30.10.2026, PR #409)

[PR #409](https://github.com/ManuEtt/Dnd/pull/409) verhindert, dass der
verifizierte Grafik-ZIP-Importer über vorhandene symbolische Links außerhalb
des gewählten Projektziels schreibt. `scripts/import_complete_fantasy_assets.py`
prüft nun die Zielwurzel und alle Pfadbestandteile vor dem ZIP-Import sowie
erneut unmittelbar vor/nach dem Anlegen der Verzeichnisse. Neue Originalgrafiken
werden exklusiv angelegt und nicht überschrieben. Die vorhandenen SHA256-,
WebP-, CRC-, Abweichungs- und Reimport-Prüfungen bleiben unverändert.

**Basis-`main`:** `55fe44475a113943c6310ec16a8ffb481185f4e9`.
**Branch:** `fix/chat-d/fantasy-import-symlink-20261030`.
**Code-Commit:** `e2d28c1e35be405a8e09cd86a0e6f249259f2799`.
Vier neue Regressionstests prüfen regulären Import/Reimport, Symlink als
Assets-Verzeichnis, hängenden Symlink am Assetziel und Symlink als Projektziel.
**GETESTET:** keine vollständige CI für diesen finalen Stand bestätigt;
die [GitHub Actions von #409](https://github.com/ManuEtt/Dnd/pull/409/checks)
sind maßgeblich. **NICHT GETESTET:** reale Geräteinstallation und
vollständiger End-to-End-Build bis zum CI-Abschluss.
**Migrationen:** keine; keine Änderung an Spielständen, SQLite-/JSON-Schemas,
Flutter-UI oder SRD-Regeln. Fremde parallele PRs bleiben unverändert;
README/Checkpoint bei Integration additiv konsolidieren.

## Chat D – SRD-Qualitätsprüfung verarbeitet fehlerhafte JSON-Datensätze kontrolliert (30.10.2026, PR #410)

[PR #410](https://github.com/ManuEtt/Dnd/pull/410) schützt die technische
SRD-Inventurprüfung vor ungefangenen `TypeError`-/`KeyError`-Abbrüchen bei
syntaktisch gültigen, aber falsch strukturierten JSON-Werten. Nicht-objektförmige
Requirements, unhashbare `area`-/Status-/Entity-Felder, ungültige
Katalogeinträge und Inventarlücken erzeugen nun geordnete
`FEHLER:`-Diagnosen und Exitcode 1 statt Python-Tracebacks. Vier neue
Regressionstests wurden ergänzt; die bestehenden Anforderungen und
SRD-Abdeckungsregeln bleiben unverändert.

**Ausgangs-`main`:** `55fe44475a113943c6310ec16a8ffb481185f4e9`;
**Branch:** `fix/chat-d/srd-audit-malformed-records-20261030`;
**Code-Commit:** `248500247eb98f1cbde46d29448a9ca3303878e3`.
**Teststatus:** vollständige GitHub Actions auf dem finalen Branch-Commit
noch ausstehend; bis dahin keine grüne CI behaupten.
**Migration:** keine; SRD-Quelldaten, Regeln, JSON-/SQLite-Schemas,
Spielstände und Appversion unverändert.
Parallel-PR-Dateipfade wurden geprüft; gemeinsame README-/Checkpoint-Zeilen
müssen bei der Integration verlustfrei abgeglichen werden.

## CHAT D – Native SAF-Backup-Dateinamen, PR #421 (30.10.2026)

- **Ausgangs-main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`, **Branch:** `fix/chat-d/backup-filename-format-20261030`, **PR:** [#421](https://github.com/ManuEtt/Dnd/pull/421) (Review), **technische Commits:** `55477475` und `4f26cdd5`.
- **IMPLEMENTIERT:** native Android-Dateinamen-Validierung in `JsonBackupIo.kt` verbietet sämtliche Unicode-FORMAT-Codepoints, einschließlich Bidi-Steuerung, Zero-Width-Joinern und ergänzenden Tags, sowie alleinstehende UTF-16-Surrogate. Bestehende Pfad- und Steuerzeichenprüfungen bleiben. Test in `JsonBackupIoTest.kt` ergänzt positive sichtbare Unicode-Namen und negative Umgehungsfälle.
- **GETESTET:** vollständige GitHub Actions [#41119725865](https://github.com/ManuEtt/Dnd/actions/runs/41119725865) auf `da12ce1` erfolgreich, einschließlich nativer Gradle-/JUnit-Tests, Python, Backend, Flutter und Android-Builds. Nach dieser Integration ist eine erneute vollständige CI auf dem neuen HEAD erforderlich.
- **NICHT GETESTET:** echter Android-SAF-Gerätedialog und der neue Integrations-HEAD bis zum Abschluss des erneuten CI-Laufs.
- **BLOCKIERT:** lokal kein Repository-Checkout über DNS und kein Flutter SDK; GitHub-CI als Abnahmeweg verfügbar.
- **NOCH NICHT IMPLEMENTIERT:** keine allgemeinen Homoglyphenfilter (wäre eine separate Produktentscheidung). Vor Review/Integration vollständige finale CI prüfen.
- **Kompatibilität:** keine Änderungen an Datenbank/Spielständen/JSON, Berechtigungen, App-Version, Story oder D&D-Regeln. Dokumentationskonflikte mit parallelen PRs additiv zusammenführen.
- **Nächster Schritt:** PR #421 auf seinem finalen HEAD einschließlich `:app:testDebugUnitTest` und Android-APK vollständig abnehmen; erst dann Review/Mergeentscheidung.

## Chat D – Modulgrenzen bei fehlenden Verzeichnissen (30.10.2026; PR #401)

Auf Branch `fix/chat-d/boundary-module-presence-20261030` (Basis-`main`
`55fe44475a113943c6310ec16a8ffb481185f4e9`, Code-Commit
`8a14e706deeceff2fc5709cfdc928e5e25c3115b`) prüft
`scripts/check_domain_boundaries.py` beide Modulwurzeln
`app/lib/story` und `app/lib/domain` vor der Importanalyse auf
reguläre Verzeichnisse und verweigert symlink-basierte Modulwurzeln.
Bisher konnte insbesondere ein fehlendes Domain-Verzeichnis ohne Beanstandung
übersprungen werden. Drei zusätzliche Regressionstests und die angepasste
Nested-Modul-Testfixture sichern positive und negative Fälle ab.

**IMPLEMENTIERT:** fail-closed-Verzeichnisprüfung ohne Änderung der
bestehenden Import-Whitelist. **GETESTET:** zunächst kein lokal ausgeführter
vollständiger Projekttest; GitHub Actions auf dem finalen PR-HEAD auswerten.
**NICHT GETESTET:** Python-Gesamtsuite, Backend, Flutter, Android und Realgerät
bis zum bestätigten CI-Lauf. **BLOCKIERT:** kein lokaler GitHub-DNS-Checkout
und kein Flutter-/Dart-SDK in dieser Sitzung.
**NOCH NICHT IMPLEMENTIERT:** keine breitere Parser-/Regel-/Story-Umstellung.
**Spielstände:** SQLite-/JSON-Format, Version und Migrationen unverändert.
[PR #401](https://github.com/ManuEtt/Dnd/pull/401) bleibt bis zur
CI-Abnahme und Konfliktprüfung im Draft.

## Chat D – Android-NDK vor ungezieltem Retry-Löschen schützen (30.10.2026, PR #402)

**Ausgangs-Main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`.
**Branch:** `fix/chat-d/preserve-installed-ndk-20261030`,
**Code-Commit:** `0999d7a44d75233a6091b0808b9ab60c740e5412`,
[PR #402](https://github.com/ManuEtt/Dnd/pull/402) zunächst Draft.
`scripts/install_android_sdk_packages.sh` löscht nach einem fehlgeschlagenen
SDK-Installationsversuch das NDK-Verzeichnis nur noch, wenn
`source.properties` als Installationsmetadaten fehlt. Das vorhandene,
bereits installierte NDK bleibt bei Problemen anderer SDK-Pakete erhalten;
temporärer Download-Cache und unvollständiges NDK werden weiterhin bereinigt.

Zwei zusätzliche Python-Mock-Regressionen decken transiente und dauerhafte
`sdkmanager`-Fehler mit vorhandenem NDK ab; bestehende Gegenfälle testen
das Bereinigen unvollständiger Installationen. **GETESTET:** kein vollständiger
lokaler Lauf (GitHub-DNS blockiert). **NICHT GETESTET:** finale CI auf dem
Dokumentations-Commit, Flutter-/Android-Build und Gerätetests bis zu einem
nachweislich abgeschlossenen Workflow. **Keine Migration:** SQLite, JSON,
Spielstände, Appversion und Regeln bleiben unverändert.

Der vorherige [Chat-D-PR #401](https://github.com/ManuEtt/Dnd/pull/401)
ist separat auf finalem Commit `0544c238c39da11b4f18e77a70c1cb0af10b4bbd`
mit [Actions #41007222064](https://github.com/ManuEtt/Dnd/actions/runs/41007222064)
vollständig grün und zur Review freigegeben; kein automatischer Merge.
Gemeinsame README-/Checkpoint-Dokumentation vor Integration additiv abgleichen.

## Chat D – 29.10.2026: Exklusives Quell-ZIP/SHA256-Paar (PR #391)

- **IMPLEMENTIERT:** `exclusive_archive_output` in
  `scripts/package_project.py` verwendet ein atomar erzeugtes
  `.<zip>.lock`-Verzeichnis von der Quellprüfung bis einschließlich
  Veröffentlichung/Rollback. Der Besitzer entfernt es per `finally`;
  fremde oder durch Crash verwaiste Sperren werden nicht übergangen.
- **REGRESSIONEN:** drei neue Tests in
  `scripts/tests/test_package_project.py` für konkurrierende
  Aufrufe, bestehendes Lock und Wiederholung nach `KeyboardInterrupt`.
- **GETESTET:** finaler Vor-Integrations-Head
  `5d5d615d9fc6b8c5152cc5fae1cb1725f1fc4758`,
  [GitHub-CI #40918352502](https://github.com/ManuEtt/Dnd/actions/runs/40918352502)
  **36/36 erfolgreich** (Python, Backend, Flutter, Android, Artefakte).
- **NICHT GETESTET:** neue kombinierte CI mit Main
  `55fe44475a113943c6310ec16a8ffb481185f4e9`;
  externe Mehrprozess-Runner, Windows und reales Android-Gerät.
- **KOMPATIBILITÄT:** keine Spielstands-, Datenbank-, Schema-,
  Regel-, UI-, Backend-Laufzeit- oder Versionsmigration.
- **KOORDINATION:** [PR #391](https://github.com/ManuEtt/Dnd/pull/391)
  reviewbereit. Integrations-Commit übernimmt die aktuellen Main-
  Dokumente und die getesteten Quell- und Regressionsdateien.
- **NÄCHSTER SCHRITT:** kombinierte CI auf neuem Head abnehmen,
  danach Merge gesondert entscheiden.

## Chat D – Sichere Unix-Dateitypen in Alpha-APKs (30.10.2026, PR #406)

[PR #406](https://github.com/ManuEtt/Dnd/pull/406) schützt
`scripts/prepare_alpha_release.py` vor ZIP-Einträgen, die einen Unix-FIFO,
Geräte-, Socket- oder widersprüchlichen Datei-/Verzeichnistyp deklarieren.
Bisher wurden nur Symlinks ausdrücklich zurückgewiesen. Unbekannte
Unix-Typbits von ZIP-Quellen ohne Typmetadaten bleiben kompatibel;
reguläre Dateien und passend benannte Verzeichnisse bleiben erlaubt.
Drei neue Python-Testmethoden prüfen Sonderdateien, eine als Verzeichnis
deklarierte Pflicht-`libapp.so` sowie gültige reguläre Archiveinträge.

**Basis-`main`:** `55fe44475a113943c6310ec16a8ffb481185f4e9`.
**Branch:** `fix/chat-d/apk-entry-types-20261030`;
**Code-Commit:** `df45e36d78f2fba2372df4fec462a6df6eb5f7a6`.
**GETESTET:** noch keine vollständige CI auf finalem Dokumentations-Commit
abgeschlossen; Resultate im [PR](https://github.com/ManuEtt/Dnd/pull/406)
abnehmen. **NICHT GETESTET:** finale Android-CI und Realgerät
bis zur tatsächlich bestätigten Ausführung.
**Spielstände:** keine Änderungen an SQLite/JSON, Regeln oder Appversion.
Die beiden vorherigen Pakete sind vollständig per GitHub Actions grün:
[PR #401](https://github.com/ManuEtt/Dnd/pull/401)
([CI 41007222064](https://github.com/ManuEtt/Dnd/actions/runs/41007222064))
und [PR #402](https://github.com/ManuEtt/Dnd/pull/402)
([CI 41010021662](https://github.com/ManuEtt/Dnd/actions/runs/41010021662));
beide zur Review freigegeben, nicht gemergt.
## Chat D – Reiner HTTPS-Ursprung für Remote-Backend (30.10.2026, PR #411)

[PR #411](https://github.com/ManuEtt/Dnd/pull/411) validiert
`PUBLIC_ORIGIN` als reinen HTTPS-Ursprung und lehnt nun URL-Pfade,
Suchparameter und Fragmente zusätzlich zu bestehenden HTTP- und
Zugangsdaten-Verboten ab. Valide Ursprünge mit optionalem Port und
abschließendem Schrägstrich bleiben zulässig.
Ein neuer Backend-Test deckt erlaubte und verbotene Varianten ab.

**Ausgangs-`main`:** `55fe44475a113943c6310ec16a8ffb481185f4e9`;
**Branch:** `fix/chat-d/backend-public-origin-20261030`;
**Code-Commit:** `7ffa749d8be11ff9a518faaf8a65fc86f940dad1`.
**GETESTET:** keine finale CI auf Dokumentations-Commit bestätigt;
der vollständige [Workflow des PRs](https://github.com/ManuEtt/Dnd/pull/411/checks)
muss noch erfolgreich abgeschlossen sein.
**NICHT GETESTET:** reales Reverse-Proxy-Deployment und Android-Gerät.
**Migration:** keine; Spielstände, JSON-/SQLite-Schema, Story, SRD-Regeln
und Appversion unverändert. README-/Checkpoint-Änderungen vor Integration
mit parallelen Arbeiten verlustfrei konsolidieren.
## Chat D – Voll-Checkpoint-Veröffentlichung serialisieren (29.10.2026)

- **Basis:** `55fe44475a113943c6310ec16a8ffb481185f4e9`,
  Branch `fix/chat-d/checkpoint-publish-lock-20261029`,
  Code-Commit `cc2c557ea6f3eedb1e2aacf0fa761f70574528a2`.
- **IMPLEMENTIERT:** `exclusive_checkpoint_output` in
  `scripts/create_checkpoint.py` reserviert ein atomar erzeugtes
  `.checkpoint.lock` im gemeinsamen Ausgabeverzeichnis. Die Sperre
  umfasst versionierte Dateien, Historien-Hashing, `LATEST`- und
  `SHA256SUMS.txt`-Veröffentlichung; fremde Sperren werden nicht
  entfernt oder übernommen.
- **REGRESSIONEN:** drei neue Tests in
  `scripts/tests/test_create_checkpoint.py`: bestehende Sperre
  belässt frühere Backups bytegleich, zweiter Aufruf während eines
  laufenden Checkpoints scheitert, `KeyboardInterrupt` gibt die
  eigene Sperre frei und lässt eine saubere Wiederholung zu.
- **GETESTET:** Vorherige [Main-CI #40922492508](https://github.com/ManuEtt/Dnd/actions/runs/40922492508)
  grün. Dies ist **kein Testnachweis für das neue Paket**.
- **NICHT GETESTET:** finale Python-/Backend-/Flutter-/Android-CI
  auf dem neuen PR-Head, Windows, reale Mehrprozess-Runner und
  Android-Gerät.
- **BLOCKIERT:** fehlender direkter lokaler GitHub-Checkout/Flutter-SDK;
  neue CI erfolgt über GitHub Actions.
- **DATENFORMAT:** keine SQLite-/JSON-/Schema-/Versionsmigration.
- **NÄCHSTER SCHRITT:** finalen PR-Head durch CI prüfen,
  Konfliktcheck aktualisieren und erst danach zur Review freigeben.

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
## Chat D – 29.10.2026: Begrenzter Upload-Preflight

- **Ausgangs-Main:** `fde0ef6ed8b419d6a31c701a03aa05d61994c352`.
- **Branch:** `fix/chat-d/bounded-metadata-preflight-20261029`.
- **Code-Commits:** `76ffccf718ffd0f807c0b8a90d0545b4f2308a50`,
  `d32e318c6f00782ccbd4deed64a4999235ec02df`.
- **IMPLEMENTIERT:** `scripts/verify_project.py` begrenzt tatsächliche
  UTF-8-Lesezugriffe auf Backend-Paketmetadaten (16 MiB) und die
  Gradle-Properties-Datei (64 KiB). Der Gradle-Unix-Launcher wird für
  seine erforderliche Shebang-Kontrolle nur bis zum ersten Zeilenende,
  höchstens 4 KiB, gelesen. Fehlende, ungültige und übergroße Uploads
  werden abgelehnt; das gültige Projekt bleibt akzeptiert.
- **REGRESSIONEN:** vier neue Tests in
  `scripts/tests/test_verify_project.py` (beide großen JSONs,
  übergroße Properties, große Datei mit gültigem kurzem Shebang,
  überlanger Shebang). Die beiden JSONs werden in einem parametrisierten
  Test geprüft.
- **GETESTET:** vorherige vollständige [Main-CI](https://github.com/ManuEtt/Dnd/actions/runs/40867945743)
  erfolgreich – **kein** Nachweis für die neue Änderung.
- **NICHT GETESTET:** Python-/Backend-/Flutter-/Android-CI auf dem neuen
  Commit, Windows, Realgerät.
- **BLOCKIERT:** Lokal kein GitHub-Checkout (DNS) und kein Flutter-SDK;
  GitHub Actions nach PR-Erstellung abwarten. Für ZIP-/Release-Verfahren
  keine zusätzlichen Produktänderungen.
- **SPIELSTAND/MIGRATION:** SQLite, Kampagnen-JSON, Regeln, Story, UI,
  Backend-Laufzeit, APK-Version und Signatur unverändert; keine Migration.
- **NÄCHSTER SCHRITT:** vollständigen CI-Run am finalen PR-HEAD auswerten,
  eventuelle Fehler in demselben Branch beheben und nach Prüfung der
  dann aktuellen PRs zur Review freigeben.

## Integration 29.10.2026 – Regression bei großer Schrift nachvollziehbar scrollen

Im zusammengeführten Kandidaten wird die zuvor auf PR #379 nachweislich fehlgeschlagene Heldenkarten-Interaktion bei 200 % Schrift korrigiert: Die Tests scrollen ein tatsächlich über den Bildschirm hinausragendes `ListView` mit einer Nutzer-Geste und verlangen anschließend hit-testbare Buttons. Keine Beschriftung verkürzt, kein Test deaktiviert, kein Produkt-/Speicherverhalten geändert. Neue kombinierte CI auf dem Folge-Commit erforderlich.


## Konsolidierter Arbeitsstand – Integrationskandidat vom 29.10.2026

**Noch nicht in `main` integriert.** Die 24 offenen PRs von Chat A/B/C/D sind auf einem separaten technischen Integrationsbaum zusammengetragen; der gemeinsame Flutter-/Python-/Backend-/Android-CI-Lauf steht aus. Einzelne Pull Requests sind Entwürfe und bedürfen einer eigenen fachlichen Freigabe. Aktive Branches vor grüner gemeinsamer Abnahme und SHA-gesicherter Archivierung nicht löschen. [Herkunft, Originalbeschreibungen, HEADs und offene Risiken](parallel/INTEGRATION_20261029.md).


## Chat D – PR #358: Alpha-Release atomar pro Version sperren

**IMPLEMENTIERT:** `scripts/prepare_alpha_release.py` reserviert vor Publikationsbeginn ein atomar erzeugtes Lock-Verzeichnis pro Release-Version. Zweitaufrufe können keine fremden Dateien löschen. Drei positive/negative Regressionen (gleichzeitiger Aufruf, Fehler-Retry, verwaiste Sperre). **GETESTET:** vollständige CI auf dem vorherigen Stand `1d7b1723` bestanden ([Actions 40730971955](https://github.com/ManuEtt/Dnd/actions/runs/40730971955)). **NOCH NICHT GETESTET:** neuer kombinierter Head einschließlich PR #363, parallele Runner-Prozesse und reales Gerät. **BLOCKIERT:** kombinierte CI-Abnahme. **Migration:** keine. **Nächster Schritt:** kombinierte CI prüfen, danach Review/Merge nur bei Erfolg.

## Chat D – PR #363: Historische Checkpoint-Dateien nur aus sicheren Quellen

**IMPLEMENTIERT:** `scripts/create_checkpoint.py` lehnt unsichere Namen, Symlinks und nichtreguläre historische Artefakte vor Erzeugung des Prüfsummenindex ab. Neue Regressionen für Symlink, Zeilenumbruch und falschen ZIP-Typ. Keine Schema-/Versionsmigration. **GETESTET:** vollständige Python-, Backend-, Flutter- und Android-CI auf Vor-Integrations-HEAD `a02e2b9f` vollständig erfolgreich ([GitHub Actions 40730867003](https://github.com/ManuEtt/Dnd/actions/runs/40730867003)). **NOCH NICHT GETESTET:** kombinierter HEAD mit `main` `1dc8d076786d`, Gerätetest; diese Abnahme erfolgt auf dem neuen PR-HEAD. **BEKANNTE GRENZE:** kein racefreier Dateideskriptor beim Hashing. **Nächster Schritt:** kombinierte CI abwarten, erst danach integrieren.

## Abnahme 28.10.2026 – Charakter-Symbolwahl / Alpha 0.8.47+97

**IMPLEMENTIERT:** Kleriker/Paladin wählen im Klassenpaket A ausdrücklich Amulett,
Emblem oder Reliquiar. Typisierte Gegenstände und Gold werden nach Bestätigung
nur einmal übernommen. Neue Klassenbelege verwenden Version 2; historische
Version 1 bleibt unverändert lesbar, ungeklärt und ohne Nachvergabe. Wiederwahl
desselben Pakets erhält die Auswahl. Abbruch, Fremd-IDs und echte Paketwechsel
sind geprüft. SQLite **3** / äußeres JSON **1** bleiben unverändert, keine Migration.

**GETESTET:** [PR #369](https://github.com/ManuEtt/Dnd/pull/369) regulär integriert;
Produkt-Main `49b98d8aef7ae0e521320628b053c149c849dea0`.
[Finale PR-CI 40756846048](https://github.com/ManuEtt/Dnd/actions/runs/40756846048)
und [Main-CI 40758951956](https://github.com/ManuEtt/Dnd/actions/runs/40758951956)
sind vollständig **erfolgreich**: 2.265 Flutter-, 200 Python- und 72 Backend-Tests,
zusätzlich gezielter 20-Fälle-UI-Lauf; 507 Dart-Dateien unverändert formatiert,
Analyzer/Backend-/Debug-/native-/drei optimierte ABI-/Alpha-/Checkpoint-Schritte
bestanden. Lokal zusätzlich zwölf native App-Tests und die vollständige Suite
auf Produktcode `7ac32b1c` bestanden; finaler PR-Kopf `bfe4e5ab` ändert daran nur
Dokumentation. Main, PR-Kopf und tatsächlicher PR-Checkout `9bf0c017` besitzen
denselben vollständigen Git-Baum `f40b9dcf11093fef2e7331fdfd712537d391cd2b`.

Alle 1.248 heruntergeladenen Quelldateien mit Hash/Modus, Alpha-Quellpaket,
echte Binärpatch-Anwendung auf Basis `37a6142e`, isoliertes Git-Bundle/fsck und
32 historische Köpfe sind unabhängig geprüft. APK-Version/ABI/v2-Testsignatur
geprüft. [Source-ZIP/Patch/Manifest/History-Bundle](https://github.com/ManuEtt/Dnd/actions/runs/40758951956/artifacts/12847443480) ·
[ARM64-Alpha](https://github.com/ManuEtt/Dnd/actions/runs/40758951956/artifacts/12846529536).

**NICHT GETESTET:** echtes Android-Gerät/TalkBack, Upgrade einer installierten
Altversion und produktive Signatur. Ein zusätzlicher freiwilliger Test aller
Fremdplugin-Unterprojekte scheiterte an ByteBuddy/Jetifier (Klassenmajor 68);
die im CI vorgeschriebenen `:app:testDebugUnitTest --no-daemon` bestehen.
**BLOCKIERT:** kein angeschlossenes Android-Testgerät.
**NOCH NICHT IMPLEMENTIERT:** vollständiger Wizard mit allen Spezies-, Klassen-,
Talent- und Zauberpflichtwahlen; Symbolbesitz bestätigt keine komplette
Fokus-/Zauberwirkung. `EQUIP-CHOICES` bleibt `partial`, SRD-Inventur 1.419/9 offen.

Arbeitsbranch `feat/character-holy-symbol-choice-20261028` ist nach grüner
Main-CI exakt als `archive/merged-20261027/feat/character-holy-symbol-choice-20261028-bfe4e5ab7fba`
archiviert und remote gelöscht; [Cleanup 40761280014](https://github.com/ManuEtt/Dnd/actions/runs/40761280014)
bestand. Elf neue aktive PR-Branches #356–#359/#361–#367 blieben erhalten;
vor jeder Folgeänderung Main/PRs/CI erneut live prüfen.

Dieser anschließende reine Dokumentationsabschluss auf Produkt-Main `49b98d8a`
ändert **keine** App-, Backend-, Skript- oder Workflowdatei und erhöht keine
Version. Seine statischen/Pythonprüfungen werden separat im Dokumentations-PR
geführt. Eine weitere APK oder Produkt-CI für dessen Dokumentationskopf wird
nicht behauptet. Ältere Berichte darunter sind historische Schreibstände.

## Quellen, Speicherung und Wiederherstellung

Regelquelle: SRD 5.2.1 S.36/53/97, CC BY 4.0; THIRD_PARTY_NOTICES.md unverändert.
Fachnachweis: [CHARACTER_HOLY_SYMBOL_CHOICE_20261028.md](CHARACTER_HOLY_SYMBOL_CHOICE_20261028.md).
Code: starting_equipment_import.dart, starting_class_choice.dart, lesender
srd_character_creation_audit.dart, bestehender Klassen-/Charaktereditor.
Keine Regel-/Story-Grenzänderung, keine KI-Kosten, keine Spielstand-Neuberechnung.

| Main-Datei | SHA256 |
| --- | --- |
| Vollprojekt-ZIP | `5c8a2b6e66f156104231ce60d91a3faafa8f3665165dd9b2e3adbfe397fe28ab` |
| Binärpatch | `1bd26a2a785257d8132e51449ed44ef17286309b1a2f2a4e8f163433efeaaa36` |
| ARM64-APK | `63ebe346fd2ea6ed2f631eb63910efc27e78208ecd269dbb6575c8aa6974ae89` |

Lokale Sicherungen: `/workspace/artifacts/character-holy-symbol-20261028/`,
Index `ARTEFAKTE_UND_IMPORT.md`; Logs/Prüfberichte `/workspace/validation/20261028-*`.
ZIP in leeren Ordner entpacken; Patch nur auf seine explizite Basis anwenden.
Das Paket ist bereits in Main enthalten: keinen identischen Patch nochmals
auf Main anwenden. Bundle für eine separate lokale Wiederherstellung verwenden;
vor neuen GitHub-Änderungen aktuellen Main/PR-Zustand und Prüfungen beachten.

## Genau nächster Schritt

Die im Mönch-Paket A ausdrücklich gewählte Werkzeug-/Instrumentausrüstung mit
der erforderlichen Werkzeugübung koppeln. Zuerst amtliches SRD 5.2.1 S.49 prüfen;
vorhandene Auswahl-/Persistenzfunktionen erweitern. Neue versionierte Entscheidung,
bestehende Klassenbelege v1/v2 ohne Pflichtfeldverschärfung bewahren, keine
Nachvergabe. Gültige/ungültige IDs, doppelte Übungen, Abbruch, Retry, stale Revision,
SQLite-Neustart und JSON, 320/360 dp bei 200 %/IME/Semantik testen; anschließend
`bash scripts/check.sh`, Debug/native und finale PR-CI. Kein Hintergrund-Codexjob.

## Dokumentationshistorie

Vorige README und beide Checkpoints bleiben bytegenau mit Git-Blob/SHA256 in
[history/character_symbol_abnahme_20261028/MANIFEST.json](history/character_symbol_abnahme_20261028/MANIFEST.json).
Die frühere Migration aller 28 Altbranches ist abgeschlossen; Bericht/Inventar
[BRANCH_MIGRATION_20261028.md](BRANCH_MIGRATION_20261028.md). Nicht wiederholen.
