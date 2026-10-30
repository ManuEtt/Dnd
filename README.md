# Würfelraunen – Der lebendige Spielleiter

## Chat B – NPC-Kontext nach Neustart unveränderlich (30.10.2026)

**PR:** [#431](https://github.com/ManuEtt/Dnd/pull/431). Read-only-NPC-Kontext ist jetzt einschließlich Notizliste und innerer Notizmaps gegen nachträgliche Änderungen gesichert. Ein neuer Flutter-/SQLite-Test deckt JSON-Roundtrip, echte Datenbank-Wiederaufnahme und Ablehnung veralteter Beziehungen ab. Branch `feat/chat-b/npc-context-immutable-restart-20261030`, Basis `69bfe78ec4eeb30042b26971978038a2ee9dac34`. Änderungen an Schema, Spielregeln und Bestands-Spielständen sind nicht erforderlich; CI-Abnahme steht zunächst aus.


## Chat C – Todesrettung bei 200 % Schrift (30.10.2026)

Das Chat-C-Arbeitspaket `feat/chat-c/death-save-actions-large-text-20261030`
(Implementierungscommit `bb3d1eaa9227cdaed84b845f6177f9d9de632fc2`,
Basis-main `55fe44475a113943c6310ec16a8ffb481185f4e9`)
stellt im Dialog des vorläufigen Todesrettungswurfs bei weniger als 500 dp
Kartenbreite und mindestens 180 % Schrift die verfügbaren Entscheidungen
untereinander über die volle Breite dar. Die kompakte Wrap-Ansicht bei
normaler Schrift bleibt erhalten; Verfügbarkeit und Sperrung bei laufender
Bestätigung bleiben aus den bestehenden Regeln abgeleitet.
Fünf Widget-Testfälle betreffen 320/360 dp, 200 % Schrift, simulierte
Tastatur, gesperrten Status, fehlende Klassenwiederholung und normales Layout.
Keine Änderung an Regelengine, Speicherdaten, Ressourcen oder Appversion.
**Vollständige CI und Gerätetest sind gesondert nachzuweisen.**


## Chat D – PR #391: Quell-ZIP-Exporte exklusiv veröffentlichen (29.10.2026)

Der Quell-ZIP-Exporter veröffentlicht ZIP und SHA256 mit einer
atomar angelegten, ausgabepfadspezifischen Sperre. Gleichzeitige
Schreibvorgänge auf dasselbe Archiv werden abgewiesen, und
unterbrochene Schreibvorgänge geben ihren eigenen Lock frei.
Eine nach hartem Absturz verbleibende Sperre bleibt aus
Integritätsgründen bestehen. Drei neue Regressionen ergänzen die
bisherigen ZIP-/Symlink-/Rollback-Tests. Keine Änderung an App,
Spielstand, SQLite, JSON oder Android-Version.
Die vollständige [PR-CI #40918352502](https://github.com/ManuEtt/Dnd/actions/runs/40918352502)
auf `5d5d615d9fc6b8c5152cc5fae1cb1725f1fc4758` hat 36/36
Prüfschritte bestanden. Nach Aufnahme des neueren Main ist eine
neue kombinierte CI abzunehmen; [PR #391](https://github.com/ManuEtt/Dnd/pull/391)
ist reviewbereit, aber noch nicht gemergt.
## Chat B – bestätigte NPC-Chronik ohne unsichtbare Steuerzeichen (30.10.2026)

[Draft-PR #398](https://github.com/ManuEtt/Dnd/pull/398) auf
`feat/chat-b/npc-context-control-sanitizing-20261030`, Ausgangs-`main`
`55fe44475a113943c6310ec16a8ffb481185f4e9`.

**IMPLEMENTIERT:** Der schreibgeschützte `NpcContinuityReader` entfernt
ASCII-/C1-Steuerzeichen, Unicode-Zeilentrenner und Bidi-Formatierungszeichen
vor der Darstellung bestätigter Namen, Beziehungen und NPC-Notizen.
Visuell gleiche NPC-Namen werden so deterministisch als mehrdeutig erkannt;
sichere gespeicherte IDs bleiben die einzige Unterscheidung.
Vier neue positive und negative Flutter-Regressionen im
`npc_continuity_control_chars_test.dart`; keine bestätigten Fakten verändert.

**GETESTET:** GitHub-Quellstand, PR-Dateipfade und fremde offene PRs geprüft.
**NICHT GETESTET:** neue Flutter-Regressionen und vollständige CI auf dem
finalen Dokumentationscommit noch abzunehmen; lokal kein Dart/Flutter-SDK,
kein GitHub-DNS-Checkout. Reales Android-Gerät/produktive KI nicht geprüft.
**MIGRATION:** keine; SQLite/JSON, Regeln und App-Version unverändert.
**KOORDINATION:** PR #396 ändert ein anderes Storymodul; gemeinsame README-
und Checkpoint-Dokumentation vor einem Merge additiv durch Chat D konsolidieren.
**NÄCHSTER SCHRITT:** Finales CI-Format/Tests des PR #398 prüfen; bei Fehlern
auf demselben Branch korrigieren, danach Review ohne automatischen Merge.

## Chat B – Strukturierte NPC-ID-Kontexte gegen Unicode-Bidi-Täuschung (30.10.2026)

- **Ausgangs-main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`; **Branch:** `feat/chat-b/npc-identity-bidi-context-20261030`; **PR:** [#407](https://github.com/ManuEtt/Dnd/pull/407), Draft; Fachcode-Commit `dfc3bf90c63f33335d4b7a4c2c420b91af4b4f61` (finalen HEAD im PR prüfen).
- **Ausgangsproblem:** Optisch identische NPC-Namen mit Bidi-Richtungszeichen konnten für die freie NPC-Auswahl als unterschiedlich gelten; die strukturierte `npcContexts`-Projektion gestattete dieselben Zeichen in Namen, Beziehungen und bestätigten Notizen.
- **IMPLEMENTIERT:** `app/lib/story/npc_identity_story_payload.dart` ignoriert unsichtbare Bidi-Formatierungszeichen bei der *Namenseindeutigkeit*, weist betroffene Originaltexte im strukturierten, revisionsgebundenen Transport aber zurück (fail-closed). Bestätigte SQLite-/JSON-Daten werden nicht umgeschrieben; explizite valide NPC-ID-Auswahl bleibt möglich.
- **TESTS ERGÄNZT:** `app/test/npc_identity_bidi_story_wire_test.dart`: sechs Flutter-Testfälle, darunter mehrere Unicode-Markierungen, vier unsichere Felder, positiv deutsche Namen/Revisionsgrenzen, Legacy-Kampagne ohne Notizen, zweimal SQLite-Neustart mit kostenlosem Fake-Backend und `npc-identity-v1` an/aus. **Ergebnis:** vollständige GitHub-CI von PR #407 am endgültigen Commit auswerten, vor Abschluss keine grüne CI behaupten.
- **DATEIEN:** `app/lib/story/npc_identity_story_payload.dart`, `app/test/npc_identity_bidi_story_wire_test.dart`, `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_B_CHECKPOINT.md`. Keine fremden Fachdateien, keine Migration/Buildnummer/SRD-Regeländerung.
- **KOORDINATION:** PRs #396, #398 und #403 ändern andere Storymodule. README-/Checkpoint-Einträge von Chat A/C/D bei Integration durch Chat D additiv konsolidieren; kein automatischer Merge. `memories`-Text-Wire ist gesonderte Arbeit in [#403](https://github.com/ManuEtt/Dnd/pull/403), keine doppelte Änderung hier.
- **BLOCKIERT/NICHT GETESTET:** CI-/Android-Abnahme für PR #407 bis zum finalen Lauf offen; reales Android-Gerät, TalkBack und produktive KI nicht getestet.
- **NÄCHSTER SCHRITT:** PR-CI und Push-CI bis zum Abschluss prüfen, bei Fehlern Ursache im eigenen Branch beheben, dann an Chat D zur konfliktfreien Integration übergeben.

## Chat B – Bidi-sichere NPC-Erinnerungen im Erzählertransport (30.10.2026)

- **Ausgangs-main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`; **Branch:** `feat/chat-b/npc-narrator-wire-bidi-20261030`; **PR:** [#403](https://github.com/ManuEtt/Dnd/pull/403) (Draft).
- **Ausgangsproblem:** Unauffällige Unicode-Bidi-Formatierungsmarkierungen konnten gespeicherte NPC-Notizen im `memories`-Transport täuschend darstellen. Gleich angezeigte Namen wie `Mira` und `Mira` mit Bidi-Override galten als zwei unabhängige Namen und erlaubten eine scheinbar eindeutige Namenszuordnung.
- **IMPLEMENTIERT:** `app/lib/story/npc_narrator_memory.dart` normalisiert diese Formatierungszeichen nur für die ausgehende, schreibgeschützte Erinnerung und ihre Namenserkennung. Visuell identische NPCs erhalten ohne explizite Identitätsauswahl keine priorisierten NPC-Notizen. Vier neue Fälle in `app/test/npc_narrator_bidi_wire_test.dart` für Identitätsmehrdeutigkeit, sauberen Wire-Text, Legacy-JSON und SQLite-Neustart mit echtem GameController und kostenlosem Fake-Backend.
- **GETESTET:** Quellstand, Main-SHA und alle offenen PR-Dateipfade auf Überschneidungen geprüft. **CI für PR #398:** [Push](https://github.com/ManuEtt/Dnd/actions/runs/41007610629) und [PR](https://github.com/ManuEtt/Dnd/actions/runs/41007615695) beide auf `92ddc263` erfolgreich; diese gehören zum **vorherigen** Paket, nicht zu #403.
- **NICHT GETESTET:** neue Tests/Flutter-Analyse/Android-APK von #403 erst nach finaler GitHub-CI gültig; reales Gerät/TalkBack und produktiver KI-Anbieter offen. Kein lokales Dart-/Flutter-SDK.
- **MIGRATIONEN:** keine, Regelzustand, SQLite/JSON und App-Version unverändert. Auch ältere gespeicherte Werte werden nicht umgeschrieben.
- **KOORDINATION:** #396 (`story_memory_engine.dart`) und #398 (`npc_continuity_reader.dart`) betreffen andere Fachdateien. Gemeinsame README und zentrale Checkpoints müssen Chat D additiv konsolidieren; kein Merge fremder PRs.
- **NÄCHSTER SCHRITT:** Finale vollständige CI von #403 auf dessen finalem HEAD abnehmen und bei Fehlern im eigenen Branch reparieren; keine Freigabe ohne grüne Builds.

## Chat B – 30.10.2026: NPC-Rückblicke mit sicherer ID-Unterscheidung (Draft-PR #396)

Bestätigtes Kampagnengedächtnis und Sitzungsrückblick geben bei gleichnamigen NPCs nur noch eindeutige einzeilige IDs aus `[A-Za-z0-9_-]{1,64}` aus. Unsichere mehrdeutige IDs und ihre spezifischen NPC-Notizen werden aus **erzählerischen Ausgaben** ausgelassen, nicht aus dem gespeicherten Spielstand. Eindeutige historische Namen und andere NPCs bleiben erhalten. Vier neue Flutter-Regressionstests ergänzen die bestehenden Recall-/Recap-Tests; **finale CI, APK und Gerätetest sind noch nicht bestätigt**. Keine Änderung an Regeln, SQLite/JSON, Backend oder Appversion. [PR #396](https://github.com/ManuEtt/Dnd/pull/396) · [Chat-B-Checkpoint](docs/parallel/CHAT_B_CHECKPOINT.md). Geteilte Dokumentation vor Integration mit anderen offenen PRs konsolidieren.
## Chat B – Eindeutige IDs für bestätigte Story-Einträge (30.10.2026)

- **Ausgangs-main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`; **Branch:** `feat/chat-b/story-entry-id-collision-20261030`; **PR:** [#414](https://github.com/ManuEtt/Dnd/pull/414), Draft; erste Fachcommits `9001dac7` und `33088157` (finale SHA im PR verifizieren).
- **Ausgangsproblem:** Nach App-Neustart oder Import kann der zeit- und sequenzbasierte ID-Generator alte IDs erneut erzeugen. Die Speicherung neuer NPC-Beziehungsnotizen, Sitzungsrückblicke und Handlungsstränge prüfte solche Kollisionen nicht.
- **IMPLEMENTIERT:** `app/lib/story/story_campaign_engine.dart` prüft generierte Eintrags-IDs vor dem Story-Commit auf bereits vorhandene IDs desselben Typs und weist Doppelbelegungen mit `FormatException` ab. Bearbeitungen bestehender Threads behalten ihre ID. Kein Schema-, Modell-, Regel- oder SQLite-Wechsel.
- **TESTS ERGÄNZT:** `app/test/story_confirmed_entry_id_collision_test.dart` mit sechs Regressionen: drei ID-Kollisionen, JSON-Neustart-Analogie, bestehende Thread-Bearbeitung, valide neue Journaleinträge und einen echten SQLite-Schließen/Neuöffnen/Weiterführen-Roundtrip mit Revisions- und Regelzustandsprüfung. Vor dem SQLite-Zusatz bestanden beide vollständigen GitHub-CI-Läufe auf `5c70fe20602d0c5f71a17f2b15bd2bcc9fe20e4f` (PR-CI `41071413126`, Push-CI `41071407643`); der neue finale Commit benötigt erneute Abnahme.
- **DATEIEN:** `app/lib/story/story_campaign_engine.dart`, `app/test/story_confirmed_entry_id_collision_test.dart`, `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_B_CHECKPOINT.md`.
- **KOORDINATION:** Keine Fachdatei-Überschneidung mit offenen PRs #396/#398/#403/#407 oder den parallelen Chat-A/C/D-Arbeiten. Gemeinsame README- und zentrale Checkpoints bei Integration durch Chat D additiv konsolidieren. Kein Merge, kein Force-Push.
- **NICHT GETESTET/BLOCKIERT:** Laufende CI-/Android-Abnahme für #414 noch nicht belegt; reale Android-Installation und produktive KI nicht getestet. Keine Migration erforderlich.
- **NÄCHSTER SCHRITT:** Finale GitHub-Push- und PR-CI samt vollständiger Flutter-Suite und APK-Builds prüfen, rote Gates im eigenen Branch korrigieren und erfolgreichen PR zur Integration an Chat D übergeben.


Deutschsprachige Fantasy-Solo-App für Android. Alpha **0.8.48+98**;
vollständige Charaktererstellung und SRD-Regelengine bleiben in Entwicklung.

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

## Qualität/Android-Sicherungen – Native Namen gegen Unicode-Steuerung absichern (CHAT D, 30.10.2026)

[PR #421](https://github.com/ManuEtt/Dnd/pull/421) auf `fix/chat-d/backup-filename-format-20261030` (Basis-`main`: `55fe44475a113943c6310ec16a8ffb481185f4e9`): Die native `JsonBackupIo.isSafeName`-Prüfung lehnt unsichtbare Unicode-Formatzeichen (Bidi-Anweisungen, Zero-Width-Zeichen, ergänzende Unicode-Tags) und verwaiste UTF-16-Surrogate ab. Sichtbare Namen mit Umlauten, Emoji und kombinierenden Akzenten bleiben möglich. Native Regressionen für erlaubte/verbotene Namen wurden hinzugefügt; vollständige GitHub-CI [#41119725865](https://github.com/ManuEtt/Dnd/actions/runs/41119725865) auf dem finalen damaligen Commit `da12ce1` erfolgreich, echter Android-SAF-Gerätetest weiter offen. Keine SQLite-/JSON-/Versionsmigration; kein Eingriff in Regeln, Story, Spielstände oder bestehende Benutzerberechtigungen. Vor Zusammenführung den finalen PR-HEAD samt nativen JUnit-, Flutter-, Backend- und APK-Prüfungen abnehmen und parallele Checkpointänderungen verlustfrei konsolidieren.

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

## Funktionen und Grenzen

| Bereich | Vorhanden | Weiter offen |
| --- | --- | --- |
| Charaktere | Attribute/Herkunft, vier Hintergrundpakete, zwölf Klassenstartgrundlagen, Klassenbelege, Talent-Zauberwahl, sichere Speicherung und Symbolwahl | Geführter Gesamtwizard, alle Spezies-/Klassen-/Talent-/Zauberpflichtwahlen |
| Regeln | Getestete Einzelmechaniken für Kampf, Ressourcen, Rasten, Ausrüstung, Klassenaufstieg und Zauber | Gesamte SRD-Automatik, alle Monster-/Zauberwirkungen und Ausnahmen |
| Kampagnen | Solo/Rabenwacht, Journal, Quests, bestätigtes NPC-Gedächtnis, Replay und dauerhafte Sendeaufträge | Keine universell autonome oder öffentliche Mehrspielerspielleitung |
| Android | Fantasy-UI, Schriftanpassung, Backups, geräteabhängige Sprache | Geräte-/TalkBack-Abnahme, produktive Signierung und Store-Veröffentlichung |

Die SRD-Matrix zählt 1.419 Prüfaufträge und neun Inventurlücken; das ist kein
vollständiger SRD-Nenner und kein Fertigstellungsprozentsatz.
[Audit](docs/SRD_5_2_1_COVERAGE_AUDIT.md) · [Charakterstatus](docs/CHARACTER_CREATION_COMPLETE.md).

## Lokal prüfen

Toolchain: Flutter 3.35.7, Dart 3.9.2, Java 17, Node.js 22.14.0 und Android SDK.

```bash
python3 scripts/generate_fantasy_buttons.py
bash scripts/check.sh
(cd app && flutter build apk --debug)
(cd app/android && bash gradlew :app:testDebugUnitTest --no-daemon)
```

Zum Spielen `cd app`, `flutter pub get`, `flutter run`. SQLite-Tests benötigen
libsqlite3. Optionale externe KI bleibt ausdrücklich einzurichten, keine
automatischen Kostenfreigaben. Vor Alpha-Updates Spielstände exportieren;
Testsignatur/APK-Build ersetzen keine echte Geräte- oder Upgradeabnahme.

[Checkpoint](docs/CODEX_CHECKPOINT.md) · [Architektur](ARCHITECTURE.md) ·
[Tests](TESTING.md) · [Änderungen](CHANGELOG.md) ·
[CC-BY-4.0-Namensnennung](THIRD_PARTY_NOTICES.md).
Frühere README-/Checkpoint-Stände bleiben bytegenau mit Git-Blob/SHA256 in
[docs/history/monk_tool_start_20261029/MANIFEST.json](docs/history/monk_tool_start_20261029/MANIFEST.json).
