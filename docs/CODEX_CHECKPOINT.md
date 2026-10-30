# Codex-Checkpoint – Würfelraunen

## Chat C – TalkBack-Sperrgrund der Angriffs-Schnellaktion (30.10.2026)

- Ausgangs-main: `55fe44475a113943c6310ec16a8ffb481185f4e9`,
  Arbeitsbranch: `feat/chat-c/shortcut-disabled-hints-20261030`,
  Code-Commit: `1a0355f276966f55eaa81018160471325692827c`,
  [PR #399](https://github.com/ManuEtt/Dnd/pull/399) (Draft).
- IMPLEMENTIERT: Gemeinsamer Sperrgrund im `FantasyPinnedActionBar` als
  Tooltip und direkter Semantics-Hint für `FantasyShortcutTile`.
  Der deaktivierte Angriff bleibt gesperrt; bei Busy gewinnt der
  Verarbeitungsgrund, bei freigegebener Aktion entfällt der Hinweis.
  Der Tooltip wird nicht zusätzlich an TalkBack ausgegeben.
- TESTS ERGÄNZT: drei Widgettests für gesperrten Angriff samt Callback-Sperre,
  Vorrang des Busy-Grunds und freigegebenen Angriff ohne alten Hint.
- GETESTET: tatsächlicher GitHub-main/PR-/Dateistand und Quelltext
  geprüft; isolierter Branch und PR erstellt. Neue Widgettests nicht ausgeführt.
- NICHT GETESTET: Dart-Format, Flutter Analyze/Widgetsuite, Python,
  Backend, Android-APK/native Tests sowie TalkBack auf Realgerät.
  CI auf finalem Commit ist gesondert zu prüfen.
- BLOCKIERT: In diesem Container fehlt das Flutter-/Dart-SDK und GitHub-DNS
  für einen vollständigen lokalen Checkout.
- Geänderte technische Dateien: `app/lib/ui/fantasy_art.dart`,
  `app/test/fantasy_action_controls_test.dart`. Keine Migration, keine
  Änderung von Regeln, Story, Datenmodell, SQLite oder JSON.
- Koordination: Andere offene UI-PRs #388, #392 und #394 ändern andere
  technische UI-Dateien. README und beide Checkpoints gemeinsam und
  ausschließlich additiv durch Chat D integrieren.
- Nächster Schritt: Unter 320 dp und 200 % Schrift prüfen, dass der
  gesperrte Kampfbutton im TalkBack-Fokus den Sperrgrund einmal vorliest;
  bei freigegebenem Angriff muss der Hinweis fehlen. Anschließend
  vollständige Flutter-/Android-CI auf dem endgültigen Commit abnehmen.

---

## Chat C – NPC-Identitätsdialog bei großer Schrift (30.10.2026)

**IMPLEMENTIERT:** [Draft-PR #422](https://github.com/ManuEtt/Dnd/pull/422), Branch `feat/chat-c/npc-picker-large-text-20261030`, Basis-main `55fe44475a113943c6310ec16a8ffb481185f4e9`, Code-/Test-Commit `d706b5a5d2d892fd3ed8c69f6e5d2346ad71fa2e`. Ein scrollbarerer `AlertDialog` und eine bei 320 px begrenzte, textskalierungsabhängige Liste ersetzen feste 72-px-Zeilen im bestätigten NPC-Identitätsdialog. Neue Widgettests für 320/360 dp, 200 % Schrift, zwölf gleichnamige NPCs und Abbrechen ohne bestätigte Beziehungen.

**GETESTET:** Repository-, PR- und Modulüberschneidungsprüfung per GitHub; eigener Branch-Diff und PR-Anlage. **Keine lokal ausgeführten automatischen Tests.**

**NICHT GETESTET:** Format/Flutter-Analyze/Flutter-Test, Android-Build und reale TalkBack-/Geräteabnahme. CI des finalen PR-HEAD ist separat zu kontrollieren.

**BLOCKIERT:** Flutter/Dart-SDK im Container nicht verfügbar; Draft nicht ohne CI + Review mergen. README-/Checkpoint-Ergänzungen wegen paralleler Arbeiten nur additiv integrieren.

**NOCH NICHT IMPLEMENTIERT:** Keine Migration, kein SQLite-/JSON-, Domain-, Controller-, Story- oder Regelumbau; App bleibt `0.8.48+98`.

**NÄCHSTER SCHRITT:** Isolierte Layout-/Semantics-Tests der Kampfchronik bei 320 dp und 200 % Schrift, auch mit sehr langen bestätigten Ereignisdetails.

---

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
