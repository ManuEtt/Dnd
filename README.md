# Würfelraunen – Der lebendige Spielleiter

## UI-Teilintegration des Gesamtmigrationslaufs – 30.10.2026

Die neun Chat-C-UI-Pakete und der enthaltene NPC-Dialog-Reparaturbranch sind
auf Basis `6465a4b2` regulär und mit vollständiger Historie verbunden.
**55 Widgettests in elf Dateien**, Flutter-Analyse, Formatprüfung (544 Dateien,
null Änderungen), Projektstruktur und Modulgrenzen sind lokal erfolgreich.
Die ursprünglichen zehn Branchheads sind Vorfahren des Teilpakets; Main und
Remote-Branches wurden dadurch noch nicht verändert. Gesamt-CI/Android und
reale Geräteabnahme sind separat offen. Keine Speicher-/Regel-/Versionsänderung.
Herkunft, Konfliktentscheidungen und nächste Integrationsprüfung:
[UI-Teilintegrationsnachweis](docs/parallel/CHAT_C_ALL_BRANCHES_INTEGRATION_20261030.md).
Die früheren Vorabmeldungen darunter sind historische Einzelbranchberichte.

## Chat C – Ausrüstungsdialog bei großer Schrift und IME (30.10.2026)

Der unabhängige Branch `feat/chat-c/equipment-loadout-large-text-ime-20261030`
basiert auf `main` `718388dda5c020670ec306843058674a85f54ba0`
und schützt den Ausrüstungsdialog gegen verdeckte Inhalte bei 320/360 dp,
200 % Schrift und eingeblendeter Tastatur. `AlertDialog(scrollable: true)`
ersetzt den doppelten inneren Scrollbereich, während **Abbrechen** und
**Werte übernehmen** außerhalb der Scrollfläche verbleiben. Die
Beschriftung der Rüstungsübung wird bei großer Schrift kompakt angezeigt.
Drei neue Widgetfälle prüfen beide engen Breiten, gesperrte Bestätigung,
erreichbare Rüstungsübung sowie unveränderte Helden- und Inventardaten.
Die EP-/Kampfsystem-, Regel-, SQLite- und JSON-Schnittstellen bleiben
unverändert. Volle GitHub-CI und echte Android-/TalkBack-Abnahme sind erst
nach dem Lauf als bestanden zu werten.

## Chat C – NPC-Auswahl bei großer Schrift (30.10.2026, Draft-PR #422)

Der [Chat-C-PR #422](https://github.com/ManuEtt/Dnd/pull/422) verbessert den
Dialog für explizite, gespeicherte NPC-Identitäten auf kleinen Android-Displays:
Der Titel und der Inhalt sind scrollbar, die NPC-Liste begrenzt ihre maximale
Höhe, nicht jedoch die einzelne Zeilenhöhe. Die Abbrechen-Aktion bleibt
erreichbar. Neue Widgettests decken 320/360 dp mit 200 % Textskalierung,
zwölf gleichnamige NPCs, die konkrete ID-Auswahl und das Fehlen bestätigter
Beziehungen ab. Basis-main: `55fe4447`. Keine Datenmigration oder
Regeländerung. **Noch nicht gemergt und nicht lokal durch Flutter-Tests
abgenommen**; den finalen GitHub-Actions-Status des PR prüfen. Gemeinsame
Dokumentationsänderungen bei der späteren Integration additiv konsolidieren.
## Chat C – EP-Dialog bei großer Android-Schrift und IME (30.10.2026)

Das unabhängige Chat-C-Arbeitspaket [PR #426](https://github.com/ManuEtt/Dnd/pull/426)
(`feat/chat-c/xp-reward-dialog-ime-scroll-20261030`, Basis-main
`55fe44475a113943c6310ec16a8ffb481185f4e9`) führt den
EP-Belohnungsdialog in einen einzigen scrollbar begrenzten Titel-/Formularbereich
über, während **Abbrechen** und **EP verbindlich buchen** außerhalb dieser
Scrollfläche bleiben. Bei mindestens 180 % Schrift wird der ausdrückliche
Zustimmungs-Checkbox-Titel kompakt „EP ausdrücklich bestätigen“ dargestellt,
damit er auch im durch die Android-Tastatur verkleinerten Sichtfenster
antippbar bleibt. Vier neue Flutter-Widgettestfälle prüfen 320/360 dp,
200 % Schrift, simulierte IME, Scroll-/Touch-Bedienung, ausdrückliche
Buchungswahl und gesperrte ungültige Beträge. Spielstände, SQLite/JSON,
Regel-/EP-Transaktionen und Appversion bleiben unverändert.
Der gezielte finale Testlauf und die vollständige CI müssen anhand des
finalen PR-HEADs bestätigt werden; reale Geräteabnahme fehlt.


Deutschsprachige Fantasy-Solo-App für Android. Alpha **0.8.48+98**;
vollständige Charaktererstellung und SRD-Regelengine bleiben in Entwicklung.

**Testabnahme-Nachtrag:** Nach Wiederherstellung der vollständigen Widgettestdatei
liefen am finalen Code- und Teststand `746f4b4da9367b2a92ddddd53eb6739bb6dfc4d8`
alle **vier neuen** IME-Fälle und **sieben bestehenden** EP-Dialogtests
erfolgreich; [GitHub Actions #41122944623](https://github.com/ManuEtt/Dnd/actions/runs/41122944623).
Dart-Format: zwei Dateien, null Änderungen. Finaler Android-Gesamttest
nach Integration mit neuer `main`-Basis separat abzunehmen.
## Chat B – NPC-Kontext nach Neustart unveränderlich (30.10.2026)

**PR:** [#431](https://github.com/ManuEtt/Dnd/pull/431). Read-only-NPC-Kontext ist jetzt einschließlich Notizliste und innerer Notizmaps gegen nachträgliche Änderungen gesichert. Ein neuer Flutter-/SQLite-Test deckt JSON-Roundtrip, echte Datenbank-Wiederaufnahme und Ablehnung veralteter Beziehungen ab. Branch `feat/chat-b/npc-context-immutable-restart-20261030`, Basis `69bfe78ec4eeb30042b26971978038a2ee9dac34`. Änderungen an Schema, Spielregeln und Bestands-Spielständen sind nicht erforderlich; CI-Abnahme steht zunächst aus.
## Chat B – Unicode-Grenzen für neue KI-Geschichten (30.10.2026)

Backend und Flutter prüfen neue unbestätigte Story-Texte jetzt auf unsichtbare Steuer- und Bidi-Zeichen; sichtbarer Unicode und normale Zeilenumbrüche bleiben erlaubt. Zwei neue Testdateien ergänzen positive/negative Fälle. Diese Änderungen betreffen keine vorhandenen Spielstände oder Regeln. [PR #424](https://github.com/ManuEtt/Dnd/pull/424), Branch: feat/chat-b/story-provider-unicode-guard-20261030, ursprüngliche Basis-main: 55fe44475a113943c6310ec16a8ffb481185f4e9; aktualisierte Basis: 69bfe78ec4eeb30042b26971978038a2ee9dac34. CI-Ergebnisse sind bis zum geprüften Lauf offen.


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
## Chat D – Parallele Voll-Checkpoints absichern (29.10.2026)

Die Erstellung vollständiger Quell-Checkpoints serialisiert die
Veröffentlichung der versionierten Archive, Patches, Dateimanifeste,
Prüfsummen und stabilen `LATEST`-Aliase mit einer exklusiven
`.checkpoint.lock`-Verzeichnissperre im Ausgabeordner.
Ein zweiter Aufruf auf denselben Ausgabeordner wird ohne Veränderung
der bisherigen Datensicherungen abgewiesen; nach behandelbaren
Fehlern oder `KeyboardInterrupt` wird die eigene Sperre freigegeben.
Nach hartem Prozessabbruch bleibt sie bewusst bestehen, statt
unkontrolliert einen neuen Export zuzulassen. Drei neue Python-
Regressionen. Keine Änderung an Flutter, SQLite, Spielstand-JSON,
Backend oder App-Version. Die neue vollständige CI auf dem PR-Head
ist noch abzunehmen.
## Chat D – Branch-Bereinigung vor veränderten Referenzen schützen (30.10.2026)

[PR #419](https://github.com/ManuEtt/Dnd/pull/419) auf `fix/chat-d/retire-main-recheck-20261030`
(Draft, Basis-main `55fe44475a113943c6310ec16a8ffb481185f4e9`).
Das ausdrücklich allowlistgebundene historische Bereinigungsskript prüft vor
jeder tatsächlichen Branchlöschung den unveränderten `main`-HEAD, den
aktuellen Schutz-/Mergezustand des Branches und danach das Verschwinden
der Referenz. Sechs neue Python-Regressionsfälle simulieren diese Abläufe
ohne GitHub-Löschzugriff. **Testausführung und vollständige CI auf dem
finalen PR-Commit noch nicht nachgewiesen**. Kein Cleanup gestartet, kein
Branch gelöscht, keine Änderung von App, SQLite/JSON oder App-Version.
Vor Integration mit anderen README-Änderungen additiv konsolidieren.

## Chat C – Abenteuer-HUD bei großer Android-Schrift (29.10.2026)

[PR #394](https://github.com/ManuEtt/Dnd/pull/394) (Draft, Basis `55fe44475a113943c6310ec16a8ffb481185f4e9`) stellt bei mindestens 180 % Systemschrift bestätigte Zustände, temporäre Trefferpunkte und laufende Konzentration vollständig dar, ohne dass die bisherige Drei-Zeilen-Kürzung wichtige Informationen abschneidet. Normale Schrift bleibt kompakt. Neue UI-Regressionen für 320/360 dp bei 200 %, Standardtext und unbekannte Daten sind ergänzt. **Neue PR-CI und echte TalkBack-Geräteprüfung noch offen**. Keine Auswirkungen auf App-Version `0.8.48+98`, SQLite, JSON oder Spielregeln.

Die unabhängigen Chat-C-PRs [#388](https://github.com/ManuEtt/Dnd/pull/388) und [#392](https://github.com/ManuEtt/Dnd/pull/392) besitzen jeweils erfolgreiche eigene CI-Läufe; ihre Integration mit dem neueren main ist separat zu prüfen. Dokumentationsüberschneidungen mit Chat A/D werden durch Chat D bei der Zusammenführung additiv aufgelöst.
## Chat C – Heldenaktionen mit großer Schrift und Tastatur (30.10.2026)

Neues UI-Paket auf Basis von `main` `55fe44475a113943c6310ec16a8ffb481185f4e9`:
Die Aktionen **Abenteuer fortsetzen** und **Helden verwalten** in
`FantasyActiveHeroCard` stehen bei Kartenbreite unter 500 dp und
mindestens 180 % Schrift untereinander. Bei normaler Schrift bleibt die
bisherige kompakte Anordnung erhalten. Die Fokusreihenfolge ist explizit;
deaktivierte Fortsetzung bleibt nicht auslösbar. Fünf Widgettestfälle prüfen
320/360 dp mit simulierter Android-Tastatur und 200 % Schrift, Touch,
Tab/Enter, deaktivierte Aktion und Standardlayout. Der ältere
[Chat-C-PR #399](https://github.com/ManuEtt/Dnd/pull/399) bleibt separat
und wird nicht überschrieben. Es gibt keine Änderungen an Regeln, SQLite,
JSON oder der Appversion. **Finale CI/Android- und TalkBack-Gerätetests
müssen anhand des finalen PR-Commits nachgewiesen werden.**
## Chat C – Ausstehende Handlungen bei großer Schrift (30.10.2026)

Das isolierte [Chat-C-Paket #417](https://github.com/ManuEtt/Dnd/pull/417) `feat/chat-c/pending-action-controls-large-text-20261030`
(basierend auf `main` `55fe44475a113943c6310ec16a8ffb481185f4e9`,
Code-Commit `3a48e283da3749d5a49a0563730059fbd8bf1a94`)
ordnet im `PendingActionStatus` die Aktionen **Erneut bestätigen** und
**Verwerfen** bei Kartenbreiten unter 500 dp und mindestens 180 % Systemschrift
untereinander in voller Breite an. Der vorhandene Volltextschalter, die
Statussperren und die normale kompakte Anordnung bleiben erhalten.
Die Tab-Navigation berücksichtigt einen möglichen zusätzlichen Fokus-Stopp des scrollbaren Bereichs; die zwei Entscheidungs-Buttons haben eine ausdrückliche Reihenfolge. Sieben neue Flutter-Widgettestfälle prüfen 320/360 dp mit simuliertem
Tastatureinzug und 200 % Text, Tab/Enter, Sperrung, lange NPC-Aufträge,
den Sendestatus sowie das normale Layout. Keine Änderung von Outbox,
Spielzustand, Regeln, SQLite oder JSON. Finale CI und echter Android-
TalkBack-Test müssen separat nachgewiesen werden.
## Chat C – Screenreader-Hinweis für gesperrten Angriff (30.10.2026)

[PR #399](https://github.com/ManuEtt/Dnd/pull/399) (Draft; Basis
`55fe44475a113943c6310ec16a8ffb481185f4e9`): Die fixierte
Angriffs-Schnellaktion erhält bei Sperre einen erklärenden TalkBack-Hinweis.
Eine laufende Handlung hat Vorrang vor einem fehlenden Angriffsziel;
die bestehende Tooltip-Anzeige und alle vier Aktionen bleiben unverändert.
Drei Widget-Regressionen prüfen gesperrte, laufende und freigegebene
Zustände. **Tests neu geschrieben, hier noch nicht ausgeführt**; vollständige
GitHub-Actions-CI und echte TalkBack-Geräteabnahme offen. Keine Änderung von
Regelzustand, SQLite, JSON, Appversion oder Spielständen; keine Migration.
Gemeinsame Dokumentation vor Merge additiv konsolidieren.
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
## Chat D – PNG-Generierung gegen Symlinks und Teilwrites absichern (30.10.2026, PR #412)

[PR #412](https://github.com/ManuEtt/Dnd/pull/412) stärkt den zu
Beginn der Android-CI ausgeführten Generator für Fantasy-Buttons.
`scripts/generate_fantasy_buttons.py` verweigert bekannte symbolische
Links entlang der Ausgabeordner und an einzelnen PNG-Ausgabedateien.
Die PNG-Bytes werden erst in einer temporären Datei vollständig geschrieben
und danach atomar per `os.replace` veröffentlicht. Scheitert die
Veröffentlichung, bleibt die vorige PNG unverändert; temporäre Dateien
werden wieder entfernt. Die Bildgestaltung und deterministische
Wiederholbarkeit ändern sich nicht.

**Basis-`main`:** `55fe44475a113943c6310ec16a8ffb481185f4e9`;
**Branch:** `fix/chat-d/fantasy-button-output-safety-20261030`;
**Code-Commit:** `69d691a58fb12dfc850920d2c1e0f7960c4084de`.
Fünf neue Regressionstests prüfen verlinkte Eltern-/Zielordner,
symlink-basiertes PNG-Ziel, atomaren Schreibfehler und Sonderdateityp.
**Abnahme:** vollständige CI auf dem finalen Dokumentations-Commit ist noch
ausstehend; vorhandene Tests nicht vor ihrer Ausführung als bestanden zählen.
**Migrationen:** keine. Spielstände, SRD-Regeln, Android-UI, SQLite-/JSON-Schema
und Appversion unverändert. README-/Checkpoint-Ergänzungen bei Integration
nur verlustfrei mit den parallelen PRs konsolidieren.

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
## Chat D – Begrenzte Metadatenprüfung (29.10.2026)

Die technische Projektvorprüfung liest `backend/package.json` und
`backend/package-lock.json` nun mit einer festen Grenze von 16 MiB, die
Gradle-Wrapper-Eigenschaften höchstens mit 64 KiB und nur die erste,
maximal 4 KiB lange Gradle-Shebang-Zeile. Dadurch führt eine beschädigte
oder übergroße Projektübertragung nicht mehr zu unbegrenztem Lesen dieser
Dateien. Vier neue Python-Regressionen decken Ablehnung, begrenztes Lesen
und gültige Kurzzeilen ab. Produkt-App, JSON-Speicherformat, SQLite,
Android-Versionsnummer und Backend-Verhalten bleiben unverändert.
Die technischen Prüfungen und Android-CI dieses PRs sind separat
abzunehmen. Beim letzten geprüften Ausgangs-Main
`fde0ef6ed8b419d6a31c701a03aa05d61994c352` waren alle 24
Integrations-PRs bereits übernommen, keine PRs offen und der
[Main-CI-Lauf](https://github.com/ManuEtt/Dnd/actions/runs/40867945743)
erfolgreich. Ältere darunterstehende Integrationsstatus sind historische
Momentaufnahmen.
## Chat C – Android-Zugänglichkeit der Charakterübersicht (29.10.2026)

[PR #392](https://github.com/ManuEtt/Dnd/pull/392) (Draft) zeigt bei mindestens 180 % Schrift und weniger als 500 dp Kartenbreite **vollständige Fertigkeits-, Zauber-, Zustands- und Inventarnamen** oberhalb des jeweiligen bestätigten Wertes an; normalgroße Darstellung behält die bisherigen kompakten Zeilen. Neue Flutter-Widgettests decken 320/360 dp bei 200 %, normalen Text, Konzentration/Inventarmenge sowie unbekannte historische Werte ab. **Die PR-#392-CI ist bis zum erfolgreichen Lauf auf dem finalen SHA offen**. Keine Änderungen an Regeln, Charakterdaten, Version, SQLite oder JSON.

Die ältere Chat-C-Arbeit [PR #388](https://github.com/ManuEtt/Dnd/pull/388) (Charakterbogen-Header) besteht dagegen [36/36 CI-Schritte](https://github.com/ManuEtt/Dnd/actions/runs/40914859785) auf `97262ab3900f21f5951afd45bd35da197c3b57ae` und ist reviewbereit. PR #390 bearbeitet dieselbe Header-Fachdatei wie #388: vor Integration bewusst zusammenführen. PR #392 ist fachlich davon getrennt. Offen gebliebene gemeinsame README-/Checkpoint-Zweige der Chats A/D und Charaktererstellung müssen bei Integration bewahrt werden.
## Aktualisierte Main-Basis und Chat-C-UI-Arbeit (29.10.2026)

Die vorherigen 24 parallelen PR-Pakete wurden inzwischen in `main` integriert und ihre Branches bereinigt. Main `fde0ef6ed8b419d6a31c701a03aa05d61994c352` / Android-Alpha-CI [40867945743](https://github.com/ManuEtt/Dnd/actions/runs/40867945743) sind erfolgreich. Darunterstehende „Integrationskandidat“-Abschnitte beschreiben einen **historischen Vor-Merge-Zustand** und dürfen nicht als aktuelle offene PR-Liste gelesen werden.

**Aktueller UI-Entwurf:** [Chat C PR #388](https://github.com/ManuEtt/Dnd/pull/388) erweitert den Charakterbogen-Header bei 180–200 % Android-Schrift und weniger als 500 dp Breite: Porträt über vollständigem Namen, Klasse/Stufe, Unterklassen und Hintergrund. Normale Schrift bleibt kompakt. Vier neue Widgettests (320/360 dp, Standardaktion, historisch leerer Name) sind hinzugefügt; **CI für diesen Feature-Head noch separat abnehmen**. Keine Änderung an Version, Regeln, Story, SQLite oder JSON.


## Konsolidierter Arbeitsstand – Integrationskandidat vom 29.10.2026

**Noch nicht in `main` integriert.** Die 24 offenen PRs von Chat A/B/C/D sind auf einem separaten technischen Integrationsbaum zusammengetragen; der gemeinsame Flutter-/Python-/Backend-/Android-CI-Lauf steht aus. Einzelne Pull Requests sind Entwürfe und bedürfen einer eigenen fachlichen Freigabe. Aktive Branches vor grüner gemeinsamer Abnahme und SHA-gesicherter Archivierung nicht löschen. [Herkunft, Originalbeschreibungen, HEADs und offene Risiken](docs/parallel/INTEGRATION_20261029.md).


## Qualitätsabsicherung – Alpha-Release-Sperre (Chat D, PR #358)

Parallele Alpha-Packaging-Läufe mit derselben App-Version werden vor der Dateiprüfung durch ein exklusives `_Release.lock`-Verzeichnis serialisiert. Bei einem Fehler werden fremde Releases nicht gelöscht; nach normalem Abschluss oder behandelter Ausnahme wird die Sperre freigegeben. Eine verwaiste Sperre blockiert sicherheitshalber die Veröffentlichung. Drei Regressionen; keine Änderung an SQLite, JSON oder Regeln. [Erfolgreiche Vor-Integrations-CI](https://github.com/ManuEtt/Dnd/actions/runs/40730971955); der kombinierte Stand mit PR #363 erhält eine eigene Prüfung.

## Qualitätsabsicherung – Checkpoint-Historie (Chat D, PR #363)

Historische Dateien im Quell-Checkpoint werden vor Aufnahme in `SHA256SUMS.txt` auf sichere Namen und regulären Dateityp geprüft. Vorhandene Symlinks, Zeilenumbrüche oder ZIP-Verzeichnisse werden vor einer Veröffentlichung abgelehnt; drei neue negative Python-Regressionen sichern alte stabile Aliases. [Erfolgreicher CI-Stand auf dem vorigen Commit](https://github.com/ManuEtt/Dnd/actions/runs/40730867003); der jetzt kombinierte `main`-Stand wird separat geprüft. Keine Speicherformatmigration. Die Prüfung ist keine vollständige TOCTOU-Abwehr.

Deutschsprachige Fantasy-Solo-App für Android mit lokalen Charakteren,
Kampagnen, ausgewählten D&D-SRD-5.2.1-Regeln und optionalem KI-Erzähler.
**Alpha 0.8.47+97**; lokales Spielen benötigt keinen Account oder KI-Server.
Charaktererstellung und Regelengine sind noch nicht vollständig.

## Aktueller Stand und autonome Fortsetzung

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


## Chat D – Validierung ausstehender SQLite-Handlungen (PR #397, Draft)

Der öffentliche SQLite-Schreibpfad für nicht bestätigte Spielerhandlungen prüft nun auch direkte Aufrufer auf gültige Auftragskennung, Kampagnenkennung und begrenzten, nicht leeren Handlungstext. Dadurch können solche Aufrufe keinen Auftrag speichern, den die Outbox beim nächsten App-Start nicht mehr decodieren kann. Drei neue FFI-Regressionstests decken Ablehnung ohne Datenänderung, persistente Wiederherstellung/ACK und Duplikatkonflikte ab. **Noch keine finale CI-Abnahme** dieses PR-Standes; bestehende SQLite-3-/Kampagnen-JSON-1-Daten und Appversion unverändert.
