## 03.11.2026 – Chat C: Gelegenheitsbewegung mit 200 % Schrift und IME

- **Ausgangs-main:** `a786ad61c508da1a9ec1a24f85100a4a994182c8`.
- **Branch:** `feat/chat-c/opportunity-movement-ime-accessibility-20261103`.
- **Codecommit:** `9674fbc4bca191e7d291851d4100658ae05aea76`.
- **Widgettestcommit:** `5e1bab84446141cb71a58eb744303fffb8f8aefb`; finalen Dokumentations-HEAD über [PR #521](https://github.com/ManuEtt/Dnd/pull/521) prüfen.
- **Problem:** Der Gelegenheitsbewegungs-Dialog verschachtelte einen eigenen Scrollbereich im nicht als Ganzes scrollbar konfigurierten AlertDialog. Bei 320/360 dp, großer Schrift und IME sind Formular und lange Freigabe schwer erreichbar.
- **Implementiert:** `AlertDialog(scrollable: true)` ohne inneres Scrollen, kurze sichtbare Zustimmung ab 180 % bei unveränderter vollständiger TalkBack-Semantik, Validierungsfehler als Live-Region. Die Regelprüfung und alle Kampagnendaten sind unverändert.
- **Dateien:** `app/lib/ui/opportunity_movement_dialog.dart`, neuer `app/test/opportunity_movement_ime_accessibility_test.dart`; additive Einträge in `README.md`, `docs/CODEX_CHECKPOINT.md` und diesem Checkpoint.
- **Neue Regressionen:** Vier Widgettests zu Scroll-/A11y-Struktur bei 320/360 dp und 200 %/IME, Abbruch, gültiger explicit authorisierter Bewegung, Widerruf nach geänderter ungültiger Entfernung; positive und negative Dialogrückgaben und unverändertes Kampagnen-JSON.
- **GETESTET:** main-HEAD und offene PRs/Änderungspfade geprüft; Quell- und Testcommits gesichert; Branch-Vergleich zunächst zwei erwartete Fachdateien, keine Überschneidung mit den damals offenen PR-Fachpfaden. Dies sind **keine** ausgeführten Flutter-Tests.
- **NICHT GETESTET:** Lokale Dart-Format-/Analyse-/Flutter-/APK-Prüfungen (SDK fehlt); komplette CI auf dem finalen PR-HEAD ausstehend; echtes Android, TalkBack, IME, Altversions-Upgrade ausstehend.
- **BLOCKIERT:** Fehlendes Flutter-/Dart-SDK und fehlender GitHub-Checkout im Container; CI-Freigabe bis vollständig erfolgreich abgeschlossenem Lauf gesperrt. README/zentralen Checkpoint nur additiv durch Chat D integrieren.
- **Migrationen:** Keine SQLite-, JSON-, Regel-, Story- oder API-Migration; kein Versionswechsel, keine Kostenaktion.
- **NÄCHSTER SCHRITT:** Den fertigen PR #521 auf exakt seinem finalen HEAD per GitHub-CI vollständig abnehmen; Format-/Testfehler im selben Branch korrigieren und danach einen echten Android-TalkBack-/IME-Test gesondert vornehmen.

---

## 02.11.2026 – Chat C: Mehrgegner-Initiative mit 200 % Schrift und IME

- **Ausgangs-main:** `885580202caeafc9787538b6dc1c833b3190a529`.
- **Eigener Branch:** `feat/chat-c/tracked-initiative-ime-20261102`.
- **Code-/Testcommit:** `4fc35cbb35f43142b98e700e52656b22f40fcd0c`.
  Finalen Branch-HEAD nach Dokumentationscommits über GitHub prüfen.
- **Pull Request:** [#488](https://github.com/ManuEtt/Dnd/pull/488), Draft.
- **Ausgangsproblem:** Der Dialog für weitere Kreatureninitiativen
  hatte einen eigenen Scrollbereich, während Titel/Aktionen nicht als
  ganzer Dialog scrollten. Auf kleinen Bildschirmen bei 200 % Schrift
  und Android-IME konnten Zustimmungen und Aktionen unerreichbar werden.
- **IMPLEMENTIERT:** Scrollbarer `AlertDialog` ohne innere Scrollfläche,
  kleinere Dialogränder, erweiterte Dropdowns, verkürzte visuelle
  Zustimmungen mit unveränderten langen Screenreader-Labels und
  Live-Region für ungültige Eingaben. Wahl statt Kampfbuchung.
- **Geänderte Fachdateien:** `app/lib/ui/tracked_creature_initiative_dialog.dart`,
  `app/test/tracked_creature_initiative_ime_test.dart`.
  Zusatzdokumentation: `README.md`, `docs/CODEX_CHECKPOINT.md`,
  `docs/parallel/CHAT_C_CHECKPOINT.md`.
- **Tests hinzugefügt:** fünf positive/negative Widget-Regressionen bei
  320/360 dp, 200 % Text und 220 dp Fake-IME. Sie prüfen
  Abbruch bei noch offenem Formular, fehlende Bestätigung,
  positive explizite Kreatureninitiative, unzulässige 101,
  Feld-Erreichbarkeit und unveränderte Kampagnen-JSON-Daten.
- **GETESTET:** GitHub-Main und alle offenen PRs/Fachdateien verglichen,
  eigener Branch und PR angelegt, Änderungen remote gegen Main geprüft.
  Diese Prüfungen sind kein Flutter-Test.
- **NICHT GETESTET:** Lokaler Flutter-/Dart-Format-/Widget-/Android-Lauf
  (SDK fehlt); vollständiger Workflow auf finalem HEAD noch offen;
  reales Android-Gerät, TalkBack, echte IME und Altversions-Upgrade.
- **BLOCKIERT:** Kein lokales Flutter-/Android-SDK und kein
  Netzwerk-Checkout im Container; technische CI-Ergebnisse abwarten.
  Gemeinsame README-/Checkpoint-Hunks bei Integration durch Chat D
  additiv konsolidieren. Kein automatischer Merge.
- **Bekannte Fehler:** Noch keine neue Regression nachgewiesen;
  CI-Abnahme ausstehend, daher keine positive Testbehauptung.
- **Migration:** Keine Regel-, Story-, Controller-, Inventar-, SQLite-,
  JSON-, Berechtigungs-, Schema- oder Appversionsänderung.
- **NÄCHSTER SCHRITT:** Schmale reale Android-Ansicht bei 200 %
  Schrift und geöffneter Tastatur mit TalkBack bedienen, inklusive
  Fehlermeldung und vollständiger Initiative-Bestätigung.

---

## 31.10.2026 – Chat C: Offene Schildreaktion in der Chronik (Draft-PR #447)

- **Ausgangs-Main:** `47ab002872b7d46daeae03bb558258cf2ea73e4a`.
- **Arbeitsbranch:** `feat/chat-c/pending-shield-chronicle-20261031`.
- **Code-HEAD vor Dokumentation:** `5f951e9b06b08956e9d86fa084b53699964f06c7`.
- **PR:** [#447](https://github.com/ManuEtt/Dnd/pull/447), zunächst Draft.
- **Ausgangsproblem:** Bei `pendingEnemyShieldHit == true` konnte die
  gespeicherte Kampfchronik aus Payloads vorzeitigen Schaden und kritische
  bzw. Hinterhältige Zusatzwürfel präsentieren, obwohl Schild noch offen war.
- **Implementiert:** Der bestätigte Angriffswurf und die offene Schildwahl
  bleiben sichtbar, noch unbestätigte Schadenssumme und alle Zusatzwürfel
  fehlen sowohl im visuellen Text als auch in TalkBack-Semantics.
- **Änderungen:** `app/lib/ui/fantasy_combat_chronicle.dart`,
  `app/lib/ui/fantasy_dice_breakdown.dart`,
  `app/test/fantasy_dice_breakdown_test.dart`.
- **Regression:** Zwei neue Widgettests bei 320/360 dp mit 200 % Schrift,
  böswillig/spekulativ befüllten Payloads und Semantics. Bestehende Tests
  für bereits bestätigten Schaden bleiben unverändert.
- **GETESTET:** Quellcode-/Testpfade und offene PRs gegen GitHub-live geprüft;
  neue Tests hinzugefügt, aber **noch kein grünes Ausführungsergebnis**.
  Actions-Lauf auf Code-HEAD: [#41183849337](https://github.com/ManuEtt/Dnd/actions/runs/41183849337), beim Eintrag in progress.
- **NICHT GETESTET:** Lokales Dart/Flutter (kein SDK in dieser Umgebung),
  gesamte Flutter-/Android-Suite, echtes Android-TalkBack und IME.
- **Parallele PRs:** #445 betrifft README/zentralen Checkpoint, nicht diese
  UI-Code-/Testdateien. Gemeinsame Dokumentationshunks vor Merge mit Chat D
  prüfen; kein automatischer Merge dieses Draft-PR.
- **Migration:** Keine Änderung an Regeln, SQLite, JSON, Spielständen oder
  externen Diensten.
- **Nächster Schritt:** Nach grüner CI bei 320 dp/200 % auf Android mit
  TalkBack sicherstellen, dass nur der bestätigte Angriffswurf plus offener
  Schildstatus vorgelesen wird, nicht unbestätigter Schaden.

---

## 30.10.2026 – Chat C: Ausrüstungsdialog bei 200 % Schrift und IME

## UI-Teilintegration des Gesamtmigrationslaufs – 30.10.2026

Die neun Chat-C-UI-Pakete und der enthaltene NPC-Dialog-Reparaturbranch sind
auf Basis `6465a4b2` regulär und mit vollständiger Historie verbunden.
**55 Widgettests in elf Dateien**, Flutter-Analyse, Formatprüfung (544 Dateien,
null Änderungen), Projektstruktur und Modulgrenzen sind lokal erfolgreich.
Die ursprünglichen zehn Branchheads sind Vorfahren des Teilpakets; Main und
Remote-Branches wurden dadurch noch nicht verändert. Gesamt-CI/Android und
reale Geräteabnahme sind separat offen. Keine Speicher-/Regel-/Versionsänderung.
Herkunft, Konfliktentscheidungen und nächste Integrationsprüfung:
[UI-Teilintegrationsnachweis](CHAT_C_ALL_BRANCHES_INTEGRATION_20261030.md).
Die früheren Vorabmeldungen darunter sind historische Einzelbranchberichte.

- **Ausgangs-main:** `718388dda5c020670ec306843058674a85f54ba0`.
- **Branch:** `feat/chat-c/equipment-loadout-large-text-ime-20261030`.
- **Technische Commits:** `d0ca27d99429440f0b912e79913df06e7d63c004`,
  `bc82f1c262844a825685507bdb30e8fe27dbdde0`.
- **Problem:** Der Ausrüstungsdialog zeigte einen nicht-scrollenden Titel
  über einem eigenen Scrollbereich; bei sehr großer Android-Schrift und
  geöffneter IME waren Teile der Bedienung schwer erreichbar.
- **IMPLEMENTIERT:** `app/lib/ui/equipment_loadout_dialog.dart` verwendet
  `AlertDialog(scrollable: true)`; der bisher verschachtelte
  `SingleChildScrollView` entfällt, Aktionsbuttons bleiben getrennt.
  Ab 180 % Schrift wird die lange Checkbox-Beschriftung für Rüstungsübung
  verkürzt. Keine Änderung am Vorschau- oder Bestätigungspfad.
- **TESTS ERGÄNZT:** `app/test/equipment_loadout_ime_test.dart`:
  zwei negative Abbruch-/Sperrungsfälle bei 320/360 dp und ein positiver
  Touch-Scroll- und Bestätigungsfall bei 320 dp, jeweils 200 %/IME.
  Original-`HeroCharacter` bleibt unverändert; die Dialogwahl liefert
  ausschließlich eine Regelvorschau.
- **GETESTET:** main, Masterprompt, andere PR-Dateiüberschneidungen,
  Quellcode und bestehender Ausrüstungs-Widgettest geprüft. Code und
  Tests auf eigenem Branch gesichert. **Flutter-/CI-Ergebnis offen.**
- **NICHT GETESTET:** Flutter lokal (SDK fehlt), tatsächlicher Android-
  TalkBack- und IME-Gerätetest, Upgrade, gesamter Android-Build.
- **BLOCKIERT:** Bis zum erfolgreichen CI-Lauf Draft lassen. Geteilte
  README- und Checkpoint-Einträge durch Chat D additiv konsolidieren.
- **Migration:** Keine Domain-/Regel-/Inventar-, SQLite- oder
  JSON-Schemaänderung, keine Migration oder Versionsänderung.
- **Nächster Schritt:** Auf echtem Android-Gerät bei 320 dp, 200 %
  Schrift und IME Dropdown- und Checkbox-Touch-Ziele sowie
  Abbruch/Übernahme mit TalkBack prüfen.
## 30.10.2026 – Chat C: NPC-Auswahl bei 200 % Schrift (PR #422)

- **Ausgangs-main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`; App `0.8.48+98`.
- **Eigener Branch:** `feat/chat-c/npc-picker-large-text-20261030`; **Pull Request:** [#422](https://github.com/ManuEtt/Dnd/pull/422) (Draft); letzter Code-/Test-Commit vor Dokumentationsupdates: `d706b5a5d2d892fd3ed8c69f6e5d2346ad71fa2e`. Finalen HEAD anhand des PRs ermitteln.
- **Ausgangsproblem:** Die NPC-Liste schätzte jede Zeile auf 72 px. Lange eindeutige Namen und Beziehungen können bei 200 % Schrift mehr Höhe benötigen; auf kleinen Displays war der Dialog nicht als Ganzes scrollbar.
- **IMPLEMENTIERT:** `app/lib/ui/npc_story_selection_dialog.dart` setzt `AlertDialog(scrollable: true)` und eine maximal 320 px hohe, `shrinkWrap`-gesteuerte NPC-Liste ohne feste Zeilenhöhe ein. Bestätigte NPC-IDs bleiben Grundlage der Auswahl; Abbrechen liegt außerhalb des Scrollbereichs.
- **TESTS ERGÄNZT:** `app/test/npc_story_selection_small_screen_test.dart`: 320/360 dp bei 200 % Schrift, Scrollen zum zwölften gleichnamigen NPC, gespeicherte ID und Revision, unveränderte Kampagnen-JSON-Daten; negativer Fall mit fehlenden bestätigten Erinnerungen und Abbrechen.
- **GETESTET:** GitHub-main, alle 32 vorher offenen PRs, die sieben Chat-C-PR-Dateilisten und eigenen Vergleich gegen main geprüft. Commit und Draft-PR erstellt. Für die neuen Widgettests liegt noch kein ausgeführtes Testergebnis vor.
- **NICHT GETESTET:** Dart-Format, Flutter-Analyse/-Tests, Android-APK, Python-/Backend-Gates und Realgerät/TalkBack, mangels Flutter-/Dart-SDK und GitHub-Checkout im lokalen Container. GitHub-Actions-Ergebnis des finalen Branch-HEAD separat überprüfen.
- **BLOCKIERT:** Lokale SDK-Ausführung fehlt; bis zum vollständigen CI-Erfolg und Review keine Mergefreigabe. Globale README/Checkpoint-Abschnitte mit Chat D bei Integration additiv konsolidieren.
- **NOCH NICHT IMPLEMENTIERT:** Keine Regel-, KI-, Story-, Speicher-, Schema- oder JSON-Änderung; keine Migration oder Versionsänderung.
- **NÄCHSTER SCHRITT:** Unabhängige Bedienungsprüfung der Kampfchronik bei 320 dp / 200 % Schrift und langen Ereigniszusammenfassungen. Akzeptanz: kein Textüberlauf, alle Ereignisdetails erreichbar, nur zulässige Belegfelder in Semantics, positive und negative Widgettests.

---

## 30.10.2026 – Chat C: EP-Belohnungsdialog bei 200 % Schrift und IME

- **Basis-main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`.
- **Branch:** `feat/chat-c/xp-reward-dialog-ime-scroll-20261030`.
- **PR:** [#426](https://github.com/ManuEtt/Dnd/pull/426) (Draft bis finaler CI).
- **Implementierungscommits:** `3622b4bf494ded300367ee781998be4e8dd386a0`
  (Scrollstruktur), `9f5012b98bd432c058c9a2ca39978b9ffdc42132`
  (Format/Scrollversuch), `eb5bb61e4d84a6cfe8b249ea59187e14c8c5bcbe`
  (tatsächlich antippbare kompakte Zustimmung/Touch-Scroll).
- **Problem:** Unter Android bei 320/360 dp, 200 % Schrift und
  geöffneter Tastatur waren Inhalte nicht zuverlässig scrollbar; die
  ursprüngliche Zustimmungszeile war im Diagnoselauf 448 dp hoch gegenüber
  einer 236 dp hohen Scrollfläche und konnte nicht in den Sichtbereich
  vollständig hineinbewegt werden.
- **IMPLEMENTIERT:** `app/lib/ui/experience_reward_dialog.dart` verwendet
  `AlertDialog(scrollable: true)` ohne verschachteltes inneres Scrollen;
  Abbruch und bestätigte Aktion bleiben getrennt außerhalb des Inhalts.
  Bei großer Schrift lautet der kurze ausdrückliche Zustimmungstitel
  „EP ausdrücklich bestätigen“; die volle bisherige Formulierung
  bleibt bei normaler Schrift erhalten.
- **TESTS ERGÄNZT:** `app/test/experience_reward_large_text_ime_test.dart`
  mit vier Fällen: Abbruch bei 320/360 dp, positive explizite EP-Auswahl
  (keine automatische Buchung) und negative ungültige EP bei 320 dp.
  Test unterstützt echte Touch-Scrollgesten anstatt bloßer Finder-Sichtbarkeit.
- **GETESTET:** Projektstatus, vollständiger Masterprompt/Projektanweisungen,
  `main`, PR-Pfade und vorbestehende EP-/Widgettests über GitHub geprüft.
  In [CI #41119777359](https://github.com/ManuEtt/Dnd/actions/runs/41119777359)
  bestanden die zwei Abbruchtests, aber Zustimmung war nicht erreichbar;
  [Diagnose #41120401425](https://github.com/ManuEtt/Dnd/actions/runs/41120401425)
  lieferte die konkrete 448/236-dp-Ursache. Finale Tests nach dem neuen
  UI-/Test-Fix sind beim Schreiben noch nicht als bestanden nachgewiesen.
- **NICHT GETESTET:** Echte TalkBack-/IME-Gerätebedienung, Android-Upgrade und
  produktive Release-Signierung. Lokal kein Flutter-/Dart-SDK;
  finale GitHub-CI separat nachweisen.
- **BLOCKIERT:** Keine lokale Flutter-Toolchain. GitHub-Actions-Queue ist
  durch parallel laufende PRs belastet. Geteilte README-/Zentral-Checkpoint-
  Ergänzungen bei Integration durch Chat D additiv konsolidieren.
- **Migration/Kompatibilität:** Keine geänderten XP-Domainregeln, Event-IDs,
  Spielstände, SQLite-Schema, JSON-Formate oder App-Version.
- **Nächster Schritt:** Echter Android-Gerätetest bei 320 dp/200 %/IME:
  Checkbox bis zur Antippbarkeit scrollen, Zustimmung setzen,
  Buchungswahl und Abbrechen auslösen, TalkBack-Labels prüfen.

---

- **Testnachtrag 30.10.2026:** Der Zwischenstand `e5491f4` hatte wegen
  einer fehlerhaften automatischen Testbearbeitung einen Dart-Syntaxfehler
  in Zeile 26; keine reale XP-Regel-Regression. Die **vollständige Testdatei**
  wurde in `746f4b4da9367b2a92ddddd53eb6739bb6dfc4d8` repariert.
  [Gezielte CI #41122944623](https://github.com/ManuEtt/Dnd/actions/runs/41122944623)
  erfolgreich: vier neue große-Schrift-/IME-Widgettests und sieben vorhandene
  EP-Dialogtests, darunter SQLite-Quittung; Dart-Format zwei Dateien ohne Änderung.
  Echte Geräteprüfung, Gesamtsuite und Android-Build auf finalem Merge-HEAD
  getrennt prüfen. Diagnoseworkflow wird nicht im finalen PR belassen.

## 30.10.2026 – Chat C: Ausstehende Handlungen bei großer Schrift/IME

- **Basis-main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`.
- **Branch:** `feat/chat-c/pending-action-controls-large-text-20261030`.
- **Pull Request:** [#417](https://github.com/ManuEtt/Dnd/pull/417) (separat von anderen Chat-C-Paketen).
- **Code-/Testcommit:** `3a48e283da3749d5a49a0563730059fbd8bf1a94`.
- **Problem:** Im festen Abenteuer-Composer teilen sich die Buttons zur
  Wiederbestätigung und zum Verwerfen bisher einen Wrap, der bei 320/360 dp
  und 200 % Schrift die Beschriftung stark verengt. Bei geöffneter Tastatur
  müssen beide Entscheidungen weiter getrennt erreichbar bleiben.
- **IMPLEMENTIERT:** `app/lib/ui/pending_action_status.dart` stellt
  ab 180 % Schrift und unter 500 dp die Retry-/Discard-Aktionen vollbreit
  vertikal dar. Der vorhandene Volltextschalter bleibt separat; bei
  normaler Schrift bleibt die Wrap-Anordnung bestehen. Bereits vorhandene
  `interactionBlocked`-/`submitting`-Prüfungen sind unverändert.
- **Fokus-Regressionsbefund:** Die scrollbare Flutter-Ansicht kann selbst einen Tab-Fokus-Stopp belegen; der Widgettest wartet maximal drei Tab-Tastendrücke pro Zielaktion, verlangt anschließend korrekte Reihenfolge und Enter-Auslösung. Die UI verwendet dafür eine explizite `OrderedTraversalPolicy` mit Fokuspositionen 0/1/2.
- **TESTS ERGÄNZT:** `app/test/pending_action_controls_large_text_test.dart`
  umfasst sieben Fälle: zwei schmale Displaybreiten mit 200 % und simulierter
  IME, Tab/Enter, blockierte Aktionen, lange NPC-Textvorschau ohne Mutation,
  vollständig ausgeblendete Aktionen während Submit und Standardlayout.
- **GETESTET:** Live-main/PRs/CI und aktuelle UI-/Testdateien geprüft;
  neue Implementierung und Tests auf eigenem Branch gesichert.
  Vollständige CI erst nach Lauf als erfolgreich bezeichnen.
- **NICHT GETESTET:** Flutter/Dart lokal (SDK fehlt); tatsächlicher
  Android-TalkBack-, Bildschirmtastatur- und Upgrade-Test.
- **BLOCKIERT:** Gemeinsame README-/Zentral-Checkpoint-Diffs bei
  Integration durch Chat D additiv koordinieren. Kein autonomer Merge.
- **Migration/Kompatibilität:** Keine Regel-, Outbox-, SQLite-, JSON-,
  Klassenressourcen- oder Versionsänderung; keine Migration.
- **Nächster Schritt:** Echte TalkBack-/IME-Geräteabnahme bei 320 dp/
  200 %: beide Entscheidungen vollständig vorlesen, unabhängig fokussieren,
  aktivieren und bei Sperre ohne Callback lassen.

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
## Chat C – 29.10.2026 – Abenteuer-HUD: lange bestätigte Zustände (PR #394)

- **Basis-main:** `55fe44475a113943c6310ec16a8ffb481185f4e9` (Alpha `0.8.48+98`); **Branch:** `feat/chat-c/adventure-status-details-large-text-20261029`; **Draft-PR:** [#394](https://github.com/ManuEtt/Dnd/pull/394); **Fachcode/Test-HEAD vor Dokumentation:** `fa4749049539f68decff5a6981d6c2f6ce0fcfd2` (finalen Head aus PR beziehen).
- **Ausgangsproblem:** `FantasyAdventureStatusHud` zeigte bestätigte temporäre Trefferpunkte, Zustände und Konzentration mit festem 3-Zeilen-Limit und Ellipse. Bei 320/360 dp mit 200 % Systemschrift konnten gerade aktuelle Zustände unlesbar sein.
- **IMPLEMENTIERT:** `app/lib/ui/fantasy_adventure_hud.dart`: ab Textskalierung 1,8 kein Zeilenlimit/keine Ellipse für die bestätigte Statuszeile, stabiler Widget-Key. Standardansicht bleibt bei drei Zeilen. Keine Änderungen an Regeln, Controller, SQLite 3, JSON 1, Appversion oder Story; keine Migration.
- **TESTS HINZUGEFÜGT:** `app/test/fantasy_adventure_status_details_large_text_test.dart` – 320/360 dp bei 200 %, volle Bedingungen/Konzentration/temporäre TP, Standardmodus mit 3 Zeilen, Altcharakter ohne Status. Prüft unverändertes `HeroCharacter.toJson()` und Widget-Ausnahmen.
- **GETESTET:** GitHub-Basis/main und offene PR-Dateien, bestehende HUD-Regressionen, tatsächlichen Code und Android-Layoutgrenzen geprüft; eigener Branch/PR erstellt. Vorherige Chat-C-PRs [#392](https://github.com/ManuEtt/Dnd/pull/392) und [#388](https://github.com/ManuEtt/Dnd/pull/388) haben jeweils vollständige grüne CI auf ihren eigenen Köpfen (u. a. [#40918977935](https://github.com/ManuEtt/Dnd/actions/runs/40918977935)); das beweist **nicht** PR #394.
- **NICHT GETESTET:** Dart-Format, Flutter-Analyse, neue Widgetsuite, Backend/Python und Android Debug/native/Alpha auf finalem PR #394 bis zur neuen CI. Echte Geräte- und TalkBack-Prüfung separat.
- **BLOCKIERT:** Im lokalen Container kein Dart-/Flutter-SDK; PR bleibt Draft bis vollständiger erfolgreicher GitHub-CI auf dem finalen Commit.
- **NOCH NICHT IMPLEMENTIERT:** Reale Screenreader-Abnahme und kombinierter Review-Merge durch Chat D.
- **Geänderte Dateien:** HUD, neuer Widgettest, dieser Checkpoint, `docs/CODEX_CHECKPOINT.md`, `README.md`.
- **Koordination:** #388/#392 bearbeiten andere UI-Module; #387/#389/#391 Fachregeln/Skripte. README und zentralen Checkpoint beim Merge **additiv** mit bestehenden Einträgen konsolidieren; Branches nicht eigenmächtig löschen.
- **Nächster Schritt:** Nach CI auf 320 dp/200 % mit deutscher TalkBack-Stimme überprüfen, dass jeder bestätigte Zustand und die Konzentration vollständig vorgelesen werden, bei unbekannten historischen Werten keine Statusdaten entstehen.
## 30.10.2026 – Chat C: Heldenaktionen mit großer Schrift und IME

- **Ausgangs-main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`.
- **Branch:** `feat/chat-c/hero-actions-large-text-ime-20261030`.
- **Implementierungscommit:** `8dad702764b3d012bd2e92595ab9509378ea47c1`.
- **Ausgangsproblem:** Auf schmalen Android-Karten drücken große Schrift und
  geöffnete Tastatur die beiden Heldenaktionen in einen schmalen Wrap-Bereich;
  Keyboard-Reihenfolge und unerreichbare deaktivierte Fortsetzung waren nicht
  eigens durch Widgettests abgedeckt.
- **Implementiert:** `FantasyActiveHeroCard` zeigt ab 180 % Schrift und unter
  500 dp Breite die beiden unveränderten Buttons vollbreit vertikal,
  mit expliziter Fokusreihenfolge (Fortsetzen, Helden verwalten);
  bei normaler Schrift bleibt die vorhandene Wrap-Anordnung bestehen.
- **Akzeptanz/Regressionen:** Zwei 320/360-dp-IME-Touchfälle bei 200 %,
  Tab/Enter-Fokusreihenfolge, deaktivierte Fortsetzung und
  unveränderte kompakte Standardansicht (fünf Widgetfälle).
  Änderungen ausschließlich in `app/lib/ui/fantasy_campaign_dashboard.dart`,
  `app/test/fantasy_hero_actions_ime_focus_test.dart` plus Dokumentation.
- **GETESTET:** GitHub-main, PR-Änderungspfade und Quelldateien vor Paketstart
  geprüft. Automatische Widget- und Gesamt-Tests erst nach tatsächlichem
  GitHub-Actions-Lauf als bestanden markieren.
- **NICHT GETESTET:** Lokale Dart-/Flutter-/Android-Kommandos (SDK fehlt in
  dieser Umgebung); Android-Gerät, TalkBack, echte IME und Upgrade offen.
- **BLOCKIERT:** Lokal kein Flutter/Dart. Gemeinsame README-/Checkpoint-Änderungen
  bei Integration durch Chat D additiv mit den offenen PRs koordinieren.
- **Migration/Kompatibilität:** Keine Zustandsmutation, kein SQLite-/JSON-/SRD-
  oder Backend-Eingriff; keine Migration, kein Versionswechsel.
- **Nächster Schritt:** Geräterealtest mit TalkBack bei 320 dp/200 %/IME;
  beide Aktionen müssen vollständig angekündigt, nacheinander fokussierbar
  und per Touch/Enter auslösbar sein, die deaktivierte Fortsetzung wird
  übersprungen; Integration nur nach vollständiger CI und Review.
## 30.10.2026 – Chat C: Ausstehende Handlungen bei großer Schrift/IME

- **Basis-main:** `55fe44475a113943c6310ec16a8ffb481185f4e9`.
- **Branch:** `feat/chat-c/pending-action-controls-large-text-20261030`.
- **Pull Request:** [#417](https://github.com/ManuEtt/Dnd/pull/417) (separat von anderen Chat-C-Paketen).
- **Code-/Testcommit:** `3a48e283da3749d5a49a0563730059fbd8bf1a94`.
- **Problem:** Im festen Abenteuer-Composer teilen sich die Buttons zur
  Wiederbestätigung und zum Verwerfen bisher einen Wrap, der bei 320/360 dp
  und 200 % Schrift die Beschriftung stark verengt. Bei geöffneter Tastatur
  müssen beide Entscheidungen weiter getrennt erreichbar bleiben.
- **IMPLEMENTIERT:** `app/lib/ui/pending_action_status.dart` stellt
  ab 180 % Schrift und unter 500 dp die Retry-/Discard-Aktionen vollbreit
  vertikal dar. Der vorhandene Volltextschalter bleibt separat; bei
  normaler Schrift bleibt die Wrap-Anordnung bestehen. Bereits vorhandene
  `interactionBlocked`-/`submitting`-Prüfungen sind unverändert.
- **Fokus-Regressionsbefund:** Die scrollbare Flutter-Ansicht kann selbst einen Tab-Fokus-Stopp belegen; der Widgettest wartet maximal drei Tab-Tastendrücke pro Zielaktion, verlangt anschließend korrekte Reihenfolge und Enter-Auslösung. Die UI verwendet dafür eine explizite `OrderedTraversalPolicy` mit Fokuspositionen 0/1/2.
- **TESTS ERGÄNZT:** `app/test/pending_action_controls_large_text_test.dart`
  umfasst sieben Fälle: zwei schmale Displaybreiten mit 200 % und simulierter
  IME, Tab/Enter, blockierte Aktionen, lange NPC-Textvorschau ohne Mutation,
  vollständig ausgeblendete Aktionen während Submit und Standardlayout.
- **GETESTET:** Live-main/PRs/CI und aktuelle UI-/Testdateien geprüft;
  neue Implementierung und Tests auf eigenem Branch gesichert.
  Vollständige CI erst nach Lauf als erfolgreich bezeichnen.
- **NICHT GETESTET:** Flutter/Dart lokal (SDK fehlt); tatsächlicher
  Android-TalkBack-, Bildschirmtastatur- und Upgrade-Test.
- **BLOCKIERT:** Gemeinsame README-/Zentral-Checkpoint-Diffs bei
  Integration durch Chat D additiv koordinieren. Kein autonomer Merge.
- **Migration/Kompatibilität:** Keine Regel-, Outbox-, SQLite-, JSON-,
  Klassenressourcen- oder Versionsänderung; keine Migration.
- **Nächster Schritt:** Echte TalkBack-/IME-Geräteabnahme bei 320 dp/
  200 %: beide Entscheidungen vollständig vorlesen, unabhängig fokussieren,
  aktivieren und bei Sperre ohne Callback lassen.
## 29.10.2026 – Chat C: vollständige Namen in der Charakter-Referenzübersicht (PR #392)

- **Ausgangs-Main:** `fde0ef6ed8b419d6a31c701a03aa05d61994c352`, App `0.8.47+97`. **Branch:** `feat/chat-c/reference-rows-large-text-20261029`. **Pull Request:** [#392](https://github.com/ManuEtt/Dnd/pull/392), Draft bis vollständiger CI. **Code-/Teststand vor Dokumentation:** `44d4d8232ba11575a730978c722ac8f4187fb759`; finaler SHA nach Dokumentationscommits separat im PR prüfen.
- **Ausgangsproblem:** `_ReferenceRow` in `app/lib/ui/fantasy_character_overview.dart` kürzte alle Referenznamen auch bei 320/360 dp und 200 % Schrift auf eine Zeile. Neben Boni, Status und Inventarmengen war der volle Name nicht lesbar.
- **IMPLEMENTIERT:** Ab Textskalierung 1,8 und unter 500 dp Breite stehen vollständige Zeilen ohne Ellipse über bestätigten Werten. Standardansicht bleibt kompakt, Icons und Daten unverändert.
- **GETESTET:** Prüfpaket aus tatsächlichen GitHub-Dateien abgeleitet. Vorheriger Chat-C-PR [#388](https://github.com/ManuEtt/Dnd/pull/388) hat auf `97262ab3900f21f5951afd45bd35da197c3b57ae` die [vollständig erfolgreiche Android-Alpha-CI #40914859785](https://github.com/ManuEtt/Dnd/actions/runs/40914859785), 36/36 Schritte, wurde reviewbereit gemacht; **dies beweist nicht die Tests von PR #392**.
- **TESTS ERGÄNZT, NOCH NICHT AUSGEFÜHRT:** `app/test/fantasy_reference_rows_large_text_test.dart` mit 320/360 dp, 200 %, langen Zauber-/Inventarnamen und darunter liegenden Konzentrations-/Mengenwerten, Standardansicht, unbekanntem Fertigkeitsbonus und unverändertem `toJson()`. Vollständige Flutter-/Python-/Backend-/Android-CI für finalen PR-Head prüfen; reales TalkBack und echtes Gerät offen.
- **BLOCKIERT:** Flutter-/Dart-SDK im lokalen Toolcontainer nicht installiert; CI-Abnahme für dieses neue Paket notwendig.
- **NOCH NICHT IMPLEMENTIERT:** Realgeräte- und Screenreader-Prüfung der Referenzübersicht.
- **Geänderte Dateien:** `app/lib/ui/fantasy_character_overview.dart`, `app/test/fantasy_reference_rows_large_text_test.dart`, dieser Checkpoint, `docs/CODEX_CHECKPOINT.md`, `README.md`. Keine Schema-/JSON-/Regel-/Story-/Controlleränderung und keine Migration.
- **Koordination:** PR #390 und #388 berühren die separate `fantasy_character_sheet.dart`; Chat-C-PR #392 berührt sie nicht. Offene PRs #387/#389/#390/#391 überschneiden sich in README und zentralem Checkpoint, die Chat D bei Integration additiv konsolidieren muss. Kein fremder Branch überschrieben.
- **Nächster unabhängiger Schritt:** Sprach-/TalkBack-Semantik der Charakter-Referenzzeilen am echten Android-Gerät prüfen; Akzeptanz: voller Name und unveränderter Wert getrennt vorgelesen, bei 320 dp/200 % ohne abgeschnittene Zeichen, ohne Zustandsmutation.
## 29.10.2026 – Chat C: vollständige Charakteridentität bei großer Schrift

- **Ausgangs-main:** `fde0ef6ed8b419d6a31c701a03aa05d61994c352` (App `0.8.47+97`). Bei Beginn keine offenen PRs; vorherige 24er-Integration ist in main und Main-Android-CI [40867945743](https://github.com/ManuEtt/Dnd/actions/runs/40867945743) erfolgreich.
- **Branch:** `feat/chat-c/sheet-header-large-text-20261029`; **PR:** [#388](https://github.com/ManuEtt/Dnd/pull/388) (Draft); **Code-/Test-HEAD vor Dokumentation:** `1e4fdbe970c8f526a1d408e9085b89f9076237d6`. Finalen Dokumentations-HEAD separat über GitHub prüfen.
- **Ausgangsproblem:** Charakterbogen-Header zeigt Namen, Klasse, Unterklasse und Hintergrund bei 320/360 dp und 200 % Schrift neben dem Porträt mit höchstens zwei Zeilen und Ellipse.
- **IMPLEMENTIERT:** Ab Textskalierung 1,8 und bei unter 500 dp Inhaltsbreite stapelt der Charakterbogen Porträt und Identität; alle vier Identitätsfelder behalten den vollständigen Text. Normale Textskalierung behält Querlayout und kompakte Zeilen.
- **TESTS ERGÄNZT:** `app/test/fantasy_character_header_large_text_test.dart`: zwei 200-%-Breiten (320/360 dp), Standardlayout mit Bearbeiten-Callback, Altcharakter ohne Namen. Tests prüfen Geometrie, Zeilenlimit/Overflow, unverändertes JSON und Flutter-Ausnahmen.
- **GETESTET:** Aktuelle Main-/PR-/Action-Informationen, tatsächlichen Headerquellcode, bestehende Flutter-Widgettests und Test-Fixturnutzung über GitHub geprüft. Eigener Branch, zwei Commits und PR tatsächlich erstellt. **Main-CI** [40867945743](https://github.com/ManuEtt/Dnd/actions/runs/40867945743) erfolgreich, aber nicht für diese Änderung.
- **NICHT GETESTET:** Neuer Flutter-Code/Test auf finalem Commit durch `dart format`, `flutter analyze`, `flutter test`, Debug-/Alpha-APK, Python-/Backend- und native Android-Gates noch nicht abgenommen; GitHub CI auf finalem Head prüfen. Kein echter Android-Geräte-/TalkBack-Test.
- **BLOCKIERT:** Im lokalen Container kein Dart-/Flutter-SDK und kein DNS-Git-Checkout; CI erforderlich. Bis grün und Review keine Integration.
- **NOCH NICHT IMPLEMENTIERT:** Vollständige Geräte- und Screenreader-Abnahme.
- **Dateien:** `app/lib/ui/fantasy_character_sheet.dart`, `app/test/fantasy_character_header_large_text_test.dart`, dieser Checkpoint, `docs/CODEX_CHECKPOINT.md`, `README.md`. Keine Schema-, JSON-, API-, Regel- oder Storyänderung; keine Migration.
- **Nächster eigenständiger Schritt:** Passivwahrnehmungs- und Klassenmerkmalbereiche des Charakterbogens bei 320 dp / 200 % Text auf sichtbare Werte und Touch-Bedienbarkeit prüfen, mit positiver/negativer Widgetregression, ohne Regelmutation.
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

## Integrationskandidat 29.10.2026 – Chat C

Zusammengeführte Fachpakete: [#359](https://github.com/ManuEtt/Dnd/pull/359), [#365](https://github.com/ManuEtt/Dnd/pull/365), [#374](https://github.com/ManuEtt/Dnd/pull/374), [#376](https://github.com/ManuEtt/Dnd/pull/376), [#379](https://github.com/ManuEtt/Dnd/pull/379), [#382](https://github.com/ManuEtt/Dnd/pull/382). Die ursprünglichen Branch-HEADs, PR-Beschreibungen, Tests, bekannte Grenzen und Statusmeldungen sind im [Integrationsjournal](INTEGRATION_20261029.md) mit Git-Historie dokumentiert. **Dieser Stand ist weder auf main integriert noch gemeinsam CI-abgenommen; Drafts sind nicht freigegeben.** Bisherige Checkpoint-Einträge bleiben erhalten.

## 28.10.2026 – Chat C: Inventardialog bei großen Beschreibungen bedienbar halten

- **Ausgangs-Main:** `ab8bef62039a2c4df04ee0cbecf0baebfefc8d78` (App `0.8.46+96`).
- **Branch:** `feat/chat-c/scrollable-inventory-details-20261028`; **PR:** [#355](https://github.com/ManuEtt/Dnd/pull/355) (Draft); **Code-/Test-Commit:** `ae9d4dc6ee6d359b44fdde44199a71b7817a4938`. Finalen Dokumentations-HEAD und CI separat anhand des PRs prüfen.
- **Ausgangsproblem:** Frei eingegebene bzw. importierte lange Inventarbeschreibungen belegen im bisherigen nicht scrollbaren `AlertDialog` mehr Platz als ein kleines Android-Display mit großer Schrift bietet. Die Schließen-Aktion soll unabhängig davon bedienbar bleiben.
- **IMPLEMENTIERT:** `app/lib/ui/fantasy_art.dart` verwendet `AlertDialog(scrollable: true)` für die schreibgeschützte Inventardetailansicht; die Schließen-Aktion bleibt außerhalb des scrollbaren Inhalts. Bestehende Mengen, Namen und Beschreibungstexte werden unverändert übernommen.
- **TESTS ERGÄNZT:** `app/test/fantasy_inventory_dialog_scroll_test.dart` enthält zwei positive lange Notizszenarien (320/360 dp, 520 dp Höhe, 2x Schrift; Schließen und Originaldaten prüfen) und den negativen Leerbeschreibungspfad mit Fallback und ohne Datenmutation.
- **FORMATDIAGNOSE:** Der erste Android-Workflow [#40715218076](https://github.com/ManuEtt/Dnd/actions/runs/40715218076) scheiterte ausschließlich an der neuen Testdatei-Formatierung und übersprang weitere Flutter-/APK-Schritte. Der kurzzeitig auf dem eigenen Branch ausgeführte [Dart-3.9.2-Formatter-Diagnoselauf #40716098297](https://github.com/ManuEtt/Dnd/actions/runs/40716098297) war erfolgreich und zeigte zwei konkrete Zeilenumbruch-Differenzen. Beide wurden in `ae9d4dc6ee6d359b44fdde44199a71b7817a4938` übernommen; der Diagnoseworkflow wurde im Commit `76ab0cf63b251eb390fc36262b4acf0522cd105d` vollständig entfernt. **Dies ist noch kein erfolgreicher App-Test.**
- **GETESTET:** Aktuellen main-SHA, offene PRs, PR-Dateiänderungen, Quellcode und vorhandene Inventar-Widgettests über GitHub geprüft. Eigenen Branch und PR tatsächlich erstellt.
- **NICHT GETESTET:** Python-Skripte, Dart-Formatierung, Flutter Analyze, Widget-/Gesamttests, Backend, Debug-APK und native Android-Tests in dieser Containerumgebung; kein Flutter-/Dart-SDK und kein DNS-Checkout. GitHub-Actions-CI auf dem finalen PR-SHA und echte Geräteprüfung getrennt abnehmen.
- **BLOCKIERT:** Lokale Flutter-/Android-Ausführung durch fehlende SDKs; Entwurfs-PR nicht mergen, bevor die CI erfolgreich ist.
- **NOCH NICHT IMPLEMENTIERT:** Allgemeine Android-TalkBack-Abnahme und weitere Tastaturfokus-Regressionen.
- **Geänderte Dateien:** `app/lib/ui/fantasy_art.dart`, `app/test/fantasy_inventory_dialog_scroll_test.dart`, `docs/parallel/CHAT_C_CHECKPOINT.md`, `docs/CODEX_CHECKPOINT.md`, `README.md`.
- **Migration/Kompatibilität:** Keine Schema-/JSON-/Domain-/Story-/Regeländerung; gespeicherte Spielstände und Item-IDs bleiben unverändert.
- **Nächster Schritt:** Isolierter Test der Tastaturfokus-Reihenfolge für die vier fixierten Abenteuer-Schnellaktionen bei 320 dp, geöffneter Tastatur und 2x Systemschrift; Akzeptanz: jede Aktion ist fokussierbar, eindeutig benannt und innerhalb des Bildschirms ohne Überlauf bedienbar.

---

## 27.10.2026 – Chat C: TalkBack-Toggle-Ansage bei Fantasy-Buttons

- **Ausgangs-main:** `e3e166a507bf9c88a4286473ceb97fc4b14ec35b`.
- **Branch:** `feat/chat-c/button-semantics-20261027`; **Pull Request:** [#320](https://github.com/ManuEtt/Dnd/pull/320) (Draft). **Letzter Code-/Test-Commit:** `0f8e05ee4f0522ed5f6843a27ef6f315df4db8a8`; finaler Dokumentations-/PR-HEAD über GitHub prüfen.
- **Ausgangsproblem:** `FantasyButton` meldete über `Semantics.toggled` bei normalen Aktionen `false`. TalkBack kann einen normalen Aktionsbutton irreführend als ausgeschalteten Schalter interpretieren.
- **IMPLEMENTIERT:** `app/lib/ui/fantasy_buttons.dart`: expliziter `toggleable`-Marker (standardmäßig false); nur `FantasyToggleButton` aktiviert ihn. Normale Buttons besitzen keinen Toggle-Zustand; Schalter melden ihren echten Zustand. Klicks und grafische Hervorhebung sind unverändert.
- **TESTS ERGÄNZT:** `app/test/fantasy_buttons_test.dart`: normaler hervorgehobener Aktionsbutton mit Callback, Schalter an/aus sowie deaktiviert.
- **NICHT GETESTET:** Dart-/Flutter-/Android-Gates lokal wegen fehlender SDKs; GitHub-CI und reales TalkBack-Gerät offen. Es wird kein Erfolg behauptet.
- **KOMPATIBILITÄT:** keine Regel-/Story-/Controller-/Datenbank-/JSON-Änderung; keine Migration.
- **NÄCHSTER SCHRITT:** Auf 320 dp bei großer Schrift die Tastaturfokus-Reihenfolge der fixierten Abenteuer-Schnellaktionen durch positive und negative Widgettests absichern.

---

# CHAT C – Android und Fantasy-UI

**Stand:** 2026-10-25 (Europe/Berlin)  
**Zusätzlich nachgezogener Main-Stand:** `97a06118f17d71cc77be2cb15a2fc9a53db20ee0` (enthält Chat D PR #177, dessen zusätzliche CI-Gates; alte Dokumentation bewahrt)  
**Nachgezogener Main-Stand:** `fb788a980b8ee9eb60439c249f3e1f5092a9f188` (enthält PR #176; Merge ausschließlich auf dem Feature-Branch)  
**Basis-Main-SHA:** `5c1499a9342449050bb946542659b221ac2653da`  
**Branch:** `fix/chat-c/npc-chronicle-fallback-20261025`  
**Letzter überprüfter Code-/Testcommit:** `65fbfc21ab347f4e4dd1d57bbd08a58304bd7c40`  
**Pull Request:** [#178 – NPC-Chronik absturzsicher anzeigen](https://github.com/ManuEtt/Dnd/pull/178) (offen, keine Main-Integration)

## Ausgangsproblem und Akzeptanzkriterien

`CampaignMemoryPanel` wertete NPC-Beziehungsnotizen mittels `firstWhere` aus. Ist die referenzierte NPC-ID nicht in `campaign.npcs` enthalten, wirft die UI beim Rendern eine `StateError`-Ausnahme. Die Oberfläche soll auch unvollständige/historische In-Memory-Daten lesbar machen, ohne Spielzustände oder die Importvalidierung zu verändern.

Akzeptanz:
- Vorhandene NPCs behalten ihren gespeicherten Namen.
- Fehlt ein referenzierter NPC, erscheint die eindeutige neutrale Anzeige `NPC nicht mehr vorhanden` neben den unveränderten gespeicherten Beziehungsdaten.
- Ein vollständiger NPC-Ausfall lässt die Anzeige nicht abstürzen; die Bearbeitungsaktion bleibt bei leerer NPC-Liste deaktiviert.
- Keine Mutation von `Campaign`, keinem JSON, SQLite-Schema, Regel- oder Story-Zustand.

## IMPLEMENTIERT

- `app/lib/ui/campaign_memory_panel.dart`: sichere Auflösung von NPC-Anzeigenamen über eine lokale Map mit neutralem Fallback.
- `app/test/campaign_memory_panel_test.dart`: zwei zusätzliche Widgettests für gemischte gültige/verwaiste Referenzen sowie komplett fehlende NPC-Stammdaten.

## Abnahme nach Synchronisierung mit main

- **Feature-/Merge-Commit mit vollständig grüner CI:** `0500ce52ce88eda8a1e7d1259293ce5530327d22`.
- **GitHub Actions:** [#40218237100](https://github.com/ManuEtt/Dnd/actions/runs/40218237100), `completed/success`.
- **Bestanden:** Python-Paket-/Strukturtests; Backend-Typecheck, Build und Tests; Dart-Formatierung; Flutter-Analyse; gezielte Fantasy-Dialogtests; vollständige Flutter-Testsuite; Android-Debug-APK; native Android-Dateisicherungstests; kleine Alpha-APKs; CI-Quell-Checkpoint. Die beiden neuen Widgettests wurden mit der vollständigen Suite geprüft.
- **Artefakte:** [Debug-APK](https://github.com/ManuEtt/Dnd/actions/runs/40218237100/artifacts/12608841640), [kleine Alpha-APKs](https://github.com/ManuEtt/Dnd/actions/runs/40218237100/artifacts/12609515426), [Quellarchiv](https://github.com/ManuEtt/Dnd/actions/runs/40218237100/artifacts/12609101293). Keine reale Installation behauptet.
- **Versionsstand nach PR #176:** `0.8.40+90` (aus main übernommen); SQLite 2, JSON 1 unverändert.
- **Nicht getestet:** Realgerät, produktive Signierung, manuelles Tastatur-/Barrierefreiheitsszenario. Die separat benannten Domain-Boundary-/SRD-Coverage-Kommandos wurden durch diesen Workflow nicht als eigenständige Schritte nachgewiesen.
- Die älteren Angaben unterhalb dokumentieren den damaligen Vor-CI-Zustand.

## GETESTET

- Live-GitHub-Basis und offene PRs geprüft: bei Arbeitsbeginn `main` wie oben, nur [PR #176](https://github.com/ManuEtt/Dnd/pull/176) offen. Sein Dateiumfang wurde mit den betroffenen UI-/Testdateien abgeglichen: keine Codeüberschneidung.
- GitHub-Diff und veröffentlichte Code-/Teständerungen auf eigenem Branch erneut gelesen; kein vollständiger Testlauf daraus abgeleitet.

## NICHT GETESTET

- Flutter/Dart-Formatierung, `flutter analyze`, gezielter Widgettest und Gesamt-`flutter test`; Android-Debug-APK und echtes Android-Gerät.
- Python-Projekttests und Backend-Checks in dieser Sitzung ebenfalls nicht ausgeführt.
- Branch- und PR-CI müssen anhand des finalen Head-SHA ausgewertet werden; keine erfolgreiche Abnahme vorweggenommen.

## BLOCKIERT

- Hier keine Flutter-/Dart-/Android-SDKs und kein direkter GitHub-Checkout via Container-Netzwerk. Prüfung über GitHub Actions erforderlich.
- Paralleler PR #176 ändert `README.md` und `docs/CODEX_CHECKPOINT.md`; dortige Zusatzdokumentation darf bei der späteren Integration nur bewusst konsolidiert werden.

## NOCH NICHT IMPLEMENTIERT

- Keine Änderung an Importvalidierung oder Datenspeicherung (diese lehnt verwaiste NPC-Verweise weiterhin ausdrücklich ab).
- Kein KI-/Regel-/Kampagnenverhalten verändert. Keine neue Version; Basis `0.8.39+89`, SQLite-Schema 2/JSON 1.

## NÄCHSTER SCHRITT

**Unabhängiges UI-Paket:** `FantasyAdventureStatusHud` bei 320 dp und 200 % Textskalierung auf ausreichende Beschriftung sowie Screenreader-Erkennbarkeit prüfen. Akzeptanz: keine Flutter-Overflows; TP, RK, Tempo und EP sind weiterhin unterscheidbar; kein erfundener unbekannter Wert; mindestens ein negativer/positiver Widgettest; keine Regel-/Persistenzänderung.

## Synchronisierung 25.10.2026 – Hauptbranch nach Sicherheitsprüfungen

- **PR #178:** UI-Dateien und zwei Widgettests unverändert, bisheriger GitHub-Lauf [#40219700324](https://github.com/ManuEtt/Dnd/actions/runs/40219700324) auf `907d665a38db150684d290314120765d8d651eb4` erfolgreich (`completed/success`).
- **Neuer main:** `af70a48c84d83c133ced4200be04ca81a91abf1b`; integrierte Chat-D-Änderungen an Gradle-/APK-/Python-Prüfungen behalten. README und zentraler Checkpoint bewusst konsolidiert.
- **Weiterhin offen:** kombinierte CI des neuen Merge-Commits und Realgerät/TalkBack/Produktionssignierung. Keine Schema- oder Regeländerung.

## Nachzug nach erfolgreichem HUD-Merge PR #185

- `main` `5f9a01dd73f68ad4f9e226f859a8ca87803b8337` hat PR #185 integriert. Chat-C-PR #178 betrifft ausschließlich die unabhängige `campaign_memory_panel.dart`/Tests, keine Überschreibung von `fantasy_adventure_hud.dart`.
- Früherer vollständiger CI-Beleg [#40219700324](https://github.com/ManuEtt/Dnd/actions/runs/40219700324); erneute kombinierte CI nach diesem Merge ausstehend. Keine JSON-/SQLite-Migration, keine reale Geräteprüfung.

---

## 02.11.2026 – Chat-D-Integrationsvorbereitung

Chat C – Initiative-Dialog mit 200 % Schrift/IME aus PR #488 vollständig übernommen. Die Quell-CI #41405839209 war auf dem finalen Source-HEAD erfolgreich; die gemeinsame Chat-D-Integrations-CI ist noch offen. Die überlappenden PRs #481/#483 bleiben separat.

---

## 02.11.2026 – Chat-D-Koordination: Originalnachträge PR #479

Der vollständige rein additive Chat-Fachnachtrag aus PR #479 ist nachfolgend erhalten. Die technische Quelländerung wird nur im gemeinsamen Draft aufgenommen; eine vollständige neue Integrations-CI ist vor einem Merge erforderlich.
## 02.11.2026 – Chat C: bestätigte Zauberwirkungen bei 200 % Schrift/IME (PR #479)

- **Ausgangs-main:** `2e920f222ab8fd501d9d90bff580d0f8ccc42ff1` und Branch `feat/chat-c/confirmed-spell-effect-ime-20261102`; [PR #479](https://github.com/ManuEtt/Dnd/pull/479) ist Draft bis zum finalen CI-Ergebnis.
- **Problem:** Separat vertikal scrollendes `ConfirmedSpellEffectDialog`-Formular unter feststehendem Dialogtitel, besonders bei 320/360 dp, 200 % Schrift, Tastatur-/IME-Inset 220 dp; fehlende gezielte Regression für Add-/Remove-Quellen.
- **IMPLEMENTIERT:** `app/lib/ui/confirmed_spell_effect_dialog.dart`: `AlertDialog(scrollable:true)` mit schmalen Insets, kein verschachtelter vertikaler Scrollview; lange Endzeiten mit `TextOverflow.ellipsis` dargestellt, Fehler mit `Semantics(liveRegion:true)` angekündigt.
- **VIER TESTS:** `app/test/confirmed_spell_effect_ime_test.dart`: 320/360 dp, 200 % Text und 220 dp IME; negative Quelle löst Fehler aus, Abbruch gibt null; valide Quelle liefert unverbindliches `ConfirmedSpellEffectChoice.add`; bei zwei bestätigten Quellen lässt sich die zweite gezielt als `remove` auswählen. Alle Wege müssen das Heldensnapshot unverändert lassen.
- **GEPRÜFT:** aktuelle Main-/Masterprompt-/Repo-/Checkpoint-Dokumentation, bestehende `confirmed_spell_effect_widget_test.dart`, tatsächlicher Dialogcode und offene PR-Dateilisten; keinerlei Überschneidung der zwei neuen fachlichen Pfade.
- **CI-AUSSTEHEND:** Dart-Format, Flutter-Analyse/gezielte/Volltests, Backend/Python, native Android-Tests, Debug-/ABI-Alpha-APK und Artefakte auf dem finalen #479-HEAD. Frühere #474-CI gilt **nicht** als Beweis für #479. Keine Echtgeräte-/TalkBack-/Hardwaretastatur-Abnahme.
- **MIGRATION:** keine. Keine SRD-, Story-, Domain-, Slot-/Ressourcen-, SQLite-/JSON-/Versionsänderung. Dokumentation additiv, Integration durch Chat D; kein Merge.
- **NÄCHSTES PAKET:** Sobald #474 gemergt ist, Fokusreihenfolge/TalkBack-Bedienbarkeit im Materialinventar einschließlich mehrfacher Checkboxbestätigungen prüfen, ohne aktiven PR zu überarbeiten.

---

## 02.11.2026 – Chat C: Materialinventar-Dialog bei 200 % Schrift und IME (PR #474)

- **Ausgangs-main:** `2e920f222ab8fd501d9d90bff580d0f8ccc42ff1` (Main wechselte während des Arbeitsstarts; beide fachlichen Dateien wurden auf diesen neuesten Main-Stand konfliktfrei neu übernommen).
- **Branch:** `feat/chat-c/material-inventory-ime-main-20261102`; [PR #474](https://github.com/ManuEtt/Dnd/pull/474) (Draft bis zur finalen CI).
- **Problem:** `SrdMaterialInventoryDialog` nutzte einen separat vertikal scrollbaren Inhalt, dessen Titel und Bestätigung bei 320/360 dp, 200 % Textskalierung und 220 dp Android-IME nicht gesondert geprüft waren. Materialfehler waren keine Screenreader-Live-Region.
- **IMPLEMENTIERT:** In `app/lib/ui/srd_material_inventory_dialog.dart` `AlertDialog(scrollable: true)` und kompakte `insetPadding`; der verschachtelte vertikale Scrollview entfällt. `Semantics(liveRegion:true)` um vorhandene `material-setup-error` und `material-validation-error` für Screenreader.
- **FÜNF TESTS HINZUGEFÜGT:** `app/test/srd_material_inventory_ime_test.dart`, je 320/360 dp, 200 % Text und 220 dp IME. Unbekanntes Rezept blockiert Bestätigung und Abbruch bleibt neutral; ohne bestätigte Materialpositionen kein Ergebnis; gültige zwei Stapel geben nur read-only Bindings zurück, Held/Inventar/Zauberplätze bleiben unverändert; Astral-Projection-Zieleingabe ist erreichbar und neutral abbrechbar.
- **GETESTET:** Masterprompt, Pflichtdokumente, tatsächlichen Code, bestehende Materialinventar-Widgettests und offene PR-Dateilisten geprüft. Auf den aktuellen Main-HEAD neu aufgesetzt. Frühere Chat-C-Pakete #465 und #469 waren in ihrer jeweils eigenen CI vollständig grün; dies ist **kein** CI-Nachweis für #474.
- **NOCH NICHT GETESTET:** `dart format`, `flutter analyze`, neue und komplette Flutter-Tests, Python/Backend, native Android-Tests, Debug-/Alpha-APK und Artefakte bis zum finalen GitHub-Actions-Lauf auf #474. Echtes Android-Gerät, TalkBack, Hardwaretastatur und Produktionssignierung separat.
- **BLOCKIERT:** Draft bis vollständigem `completed/success`-Nachweis. Kein automatischer Merge.
- **GEÄNDERTE DATEIEN:** `app/lib/ui/srd_material_inventory_dialog.dart`, neue `app/test/srd_material_inventory_ime_test.dart`, `README.md`, `docs/CODEX_CHECKPOINT.md`, dieser Chat-C-Checkpoint. **Migrationen:** keine. Keine Domain-, Zauber-/Slot- oder Speicherformat-/Versionsänderung.
- **NÄCHSTES PAKET:** Nach Integration offener Chat-C-Dialog-PRs Fokus-/Tastaturnavigation der Materialbestätigungen und Screenreader-Ansagen am echten Gerät sowie konfliktfreie UI-Regressionen für unbestätigte Materialverbrauchsangaben.

---

## 02.11.2026 – Chat C: Flächenzauber-Kreaturen-Registrierung mit IME (PR #469)

- **Ausgangs-main:** `5a88834c98f5aca40395088c20c7e1dc5b587868`; eigener Branch `feat/chat-c/area-creature-ime-20261102`; [PR #469](https://github.com/ManuEtt/Dnd/pull/469) (Draft bis zur finalen CI).
- **Vorheriges Paket:** [PR #465](https://github.com/ManuEtt/Dnd/pull/465) ist nach vollständig grüner CI auf unverändertem Kopf `3cd78d0881e3b0093eefb96342f7fb9b165292db` [#41323668152](https://github.com/ManuEtt/Dnd/actions/runs/41323668152) und [#41323664201](https://github.com/ManuEtt/Dnd/actions/runs/41323664201) jetzt **Ready for review, ungemergt**.
- **Problem:** Im Kreaturen-Dialog war der Titel nicht gemeinsam mit dem Form-Inhalt scrollbar; bei sehr großer Schrift und eingeblendeter Android-Tastatur fehlten gezielte Interaktionstests für vier Textfelder, Checkbox, Bestätigung/Abbruch.
- **IMPLEMENTIERT:** `app/lib/ui/area_creature_registration_dialog.dart` verwendet `AlertDialog(scrollable: true)` mit kompaktem Insets; der separate vertikale `SingleChildScrollView` entfällt. Fehlermeldungen sind per `Semantics(liveRegion: true)` angekündigt und besitzen `area-creature-error` als Test-Key. Keine Änderung am vorhandenen Domain-Validator `TrackedAreaCreature.fromJson` oder an der bestätigten Registrierungslogik.
- **VIER TESTS:** `app/test/area_creature_dialog_ime_test.dart`: bei 320/360 dp, 200 % Text, 220 dp Fake-IME bleibt Dialog scrollbar; fehlende Profildaten erzeugen einen Fehler, Abbrechen gibt null; bei 320 dp können vollständige Eingaben erst nach Häkchen übernommen werden; bei 360 dp bleiben 0 TP unzulässig, Nachkorrektur auf 4/7 TP ergibt die richtige Rückgabe.
- **GETESTET:** Masterprompt, Pflichtdokumente, aktuelle Main-/PR-Status und bestehenden Kreaturen-Widgettest sowie Domain-Validator geprüft; Code und Tests sind auf eigenem Branch und Draft-PR gespeichert. Ergebnisse aus #465 dürfen **nicht** als #469-CI ausgegeben werden.
- **NICHT GETESTET:** Neue Tests und vollständige Flutter-/Android-/Backend-/Python-CI auf finalem #469-HEAD bis zum Abschluss des GitHub-Actions-Runs; echtes Gerät mit Hardwaretastatur, TalkBack und Upgrade; produktive Signierung.
- **MIGRATION:** keine (keine Schema-/JSON-/Persistenz-/Versions-/Domainänderung).
- **BLOCKIERT:** Bis zur vollständigen grünen GitHub-CI im Draft belassen; nicht automatisch nach Main mergen. Dokumentationskonflikte mit parallelen PRs additiv von Chat D konsolidieren.
- **NÄCHSTES PAKET:** Nach Review/Integration der unabhängigen UI-Dialog-PRs Fokusreihenfolge/Screenreader-Interaktion und responsive Materialinventar-Auswahl prüfen, ohne laufende Fremdmodule zu ändern.

---

## 01.11.2026 – Chat C: Zustandsquellen-Dialog bei 200 % Schrift und IME (PR #465)

- **Ausgangs-main:** `5a88834c98f5aca40395088c20c7e1dc5b587868`; Branch `feat/chat-c/condition-effect-dialog-ime-20261101`; Pull Request [#465](https://github.com/ManuEtt/Dnd/pull/465) (Draft bis CI).
- **Problem:** Der Zustandsquellen-Dialog enthielt einen separat scrollenden Inhalt unter einem feststehenden Titel; für 320/360 dp, 200 % Schrift und eingeblendete Tastatur fehlte gezielte UI-Abnahme.
- **IMPLEMENTIERT:** `app/lib/ui/condition_effect_dialog.dart` nutzt `AlertDialog(scrollable: true)` mit kompakteren Insets. Lange Dropdown-Labels erhalten Ellipsis, Validierungsfehler erhalten `Semantics(liveRegion: true)`; sämtliche Domänenwerte und vorhandenen Kontrollpfade bleiben unverändert.
- **TESTS HINZUGEFÜGT:** `app/test/condition_effect_dialog_ime_test.dart`, vier Widgettests zu 320/360 dp, 200 % Schrift und 220 dp IME: ungültige Quelle zeigt angekündigten Fehler und neutralen Abbruch; gültige Zustandsquelle wird bestätigt, aber verändert den Helden nicht; Entfernen einer explizit gewählten Quelle von zwei Quellen liefert nur deren ID und mutiert nicht das übergebene Heldenmodell.
- **GETESTET:** Live-main, Masterprompt, Architektur, Checkpoints, alle offenen PR-Dateilisten, bestehende Zustandseffekt-Tests und Domänenregeln geprüft. Zwei Code-/Testdateien auf isoliertem Branch gesichert. PR #458 ist fertig grün/reviewbereit; dessen CI gilt nicht als Prüfung von #465.
- **NICHT GETESTET:** Für #465: Flutter-/Dart-Format, Flutter-Analyse und -Tests, Android-Debug/Alpha, native Tests, Backend/Python bis zum finalen GitHub-Actions-Lauf. Lokale Flutter-/Dart-Toolchain fehlt; echtes Android-Gerät und TalkBack bleiben offen.
- **BLOCKIERT:** Final-HEAD-CI bis `completed/success` prüfen, vorher kein Review-Merge.
- **GEÄNDERTE DATEIEN:** `app/lib/ui/condition_effect_dialog.dart`, `app/test/condition_effect_dialog_ime_test.dart`, dieser Checkpoint, `docs/CODEX_CHECKPOINT.md`, `README.md`. Keine Domänen-/Regel-/SQLite-/JSON-/Versionsänderung; **Migrationen:** keine.
- **NÄCHSTER SCHRITT:** Tastatur-/Screenreader-Fokusreihenfolge der Zustandsquelle auf echtem Android-Gerät, dabei Textfeld, Wechsel zwischen Hinzufügen und Entfernen und Fehleransage prüfen.

---

## 01.11.2026 – Chat C: Mehrklassen-Stufenaufstieg auf 320/360 dp mit 200 % Schrift/IME (PR #458)

- **Ausgangs-main:** `5a88834c98f5aca40395088c20c7e1dc5b587868`.
- **Branch:** `feat/chat-c/multiclass-dialog-large-text-ime-20261101`; **Code-/Testcommit:** `9524b7c8006e0dd9a2fee38b08c6ff33c792e49e`; **Pull Request:** [#458](https://github.com/ManuEtt/Dnd/pull/458) (Draft bis zur finalen CI).
- **Problem:** Der Dialog nutzte einen verschachtelten vertikalen Scrollview mit abgetrenntem Titel; die breite Erfahrung-/Meilenstein-Auswahl passte bei 320 dp/200 % möglicherweise nicht. Es gab keinen spezifischen IME-/Großschrift-Test.
- **IMPLEMENTIERT:** `app/lib/ui/multiclass_selection_dialog.dart` verwendet `AlertDialog(scrollable: true)` und kompakte Insets. Der bestehende `SegmentedButton<LevelUpMethod>` ist horizontal scrollbar; alle Regelabfragen und Bestätigungsaktionen bleiben unverändert.
- **TESTS ERGÄNZT:** `app/test/multiclass_dialog_large_text_ime_test.dart`: 320/360 dp bei 200 % Schrift/220 dp Tastatur-Inset, unbestätigter Aufstieg bei fehlenden EP gesperrt, Abbruch ohne Heldenänderung, expliziter Meilenstein auch ohne EP möglich, Barde nur nach zusätzlicher Fertigkeitswahl bestätigbar. Vier Fälle mit positiven und negativen Prüfungen.
- **GETESTET:** Masterprompt, alle Pflichtdokumente, aktuelle Main-/PR-Änderungsdateien geprüft; der Vor-PR #457 hat auf Commit `24fd1bdd821817952fe216156656b84b403ca766` vollständige grüne CI [#41248140576](https://github.com/ManuEtt/Dnd/actions/runs/41248140576), **nicht** als Nachweis für #458 verwenden.
- **NICHT GETESTET:** Neue Widgettests, Dart-Formatierung, `flutter analyze`, vollständiger Flutter-Lauf, Backend/Python, Gradle/native Tests, Debug-/Alpha-APKs des finalen #458-SHA bis zum GitHub-Actions-Ergebnis. Flutter-/Dart-SDK lokal nicht vorhanden. Reales Gerät, IME und TalkBack ausstehend.
- **BLOCKIERT:** Vollständige CI-Prüfung und Review, kein ungeprüfter Merge.
- **GEÄNDERTE DATEIEN:** UI-Dialog, neue Testdatei, `README.md`, `docs/CODEX_CHECKPOINT.md`, eigener Chat-C-Checkpoint. Kein Regel- oder Speichermodul, keine Version oder Schemaänderung; **Migrationen:** keine.
- **NÄCHSTER SCHRITT:** Tastatur-/TalkBack-Fokusreihenfolge und bestätigte Interaktionen des Magieinitiierter-Dialogs nach Integration von #457 auf Main an einem eigenständigen, konfliktfreien Paket prüfen; alle vier Wahlfelder mit Fokus erreichbar, Enter aktiviert niemals ungültigen Confirm.

---

## 31.10.2026 – Chat C: Magieinitiierter-Dialog bei großer Schrift und IME (PR #457)

- **Ausgangs-main:** `5a88834c98f5aca40395088c20c7e1dc5b587868`.
- **Branch:** `feat/chat-c/magic-initiate-ime-scroll-20261031`. **Fach-/Testcommit:** `2a87d116e1cccf2dcf4e9af9ffae43e55a31d706`; **PR:** [#457](https://github.com/ManuEtt/Dnd/pull/457) (Draft; finalen Head im PR prüfen).
- **Problem:** Das SRD-Magieinitiierter-Formular nutzt einen isolierten Inhalts-Scrollview in einem nicht explizit scrollbaren AlertDialog; 320/360 dp bei 200 % Schrift und Android-IME bislang nicht gezielt abgesichert.
- **IMPLEMENTIERT:** `app/lib/ui/srd_magic_initiate_dialog.dart` nutzt `AlertDialog(scrollable: true)`, schmale Insets und nur einen Scrollbereich für Titel/Inhalt; die vier validierten Dropdowns, Abbruch und Bestätigung behalten ihre bestehende fachliche Wirkung.
- **TESTS HINZUGEFÜGT:** `app/test/srd_magic_initiate_ime_test.dart`: 320 und 360 dp mit 200 % Text/220 dp IME, scrollbare Formularfelder und Abbruch; bei doppelten Zaubertricks kein Confirm; bei vier gültigen Angaben wird nur das korrekte Wahl-DTO zurückgegeben. Vier Widgetfälle, keine externe KI.
- **GETESTET:** Live-main, Masterprompt, Architektur/Arbeitsanweisungen, offene PR-Dateipfade und vorherige CI geprüft. PR #455 hat auf `aedc212faa3e64136f0713b1386e7141c4541381` zwei grüne CI-Läufe [41246044715](https://github.com/ManuEtt/Dnd/actions/runs/41246044715) / [41246040596](https://github.com/ManuEtt/Dnd/actions/runs/41246040596) und wurde auf Review gesetzt. Diese Läufe beweisen **nicht** #457.
- **NICHT GETESTET:** Der neue Code ist zunächst ohne lokale Dart-/Flutter-Toolchain; vollständige CI (Format, Analyse, Fluttertests, native Android-/APK-/Backend-/Python-Gates) auf finalem PR-HEAD noch abzunehmen. Echtes Android-Gerät mit IME, TalkBack, Upgrade/Release-Signatur separat.
- **BLOCKIERT:** Prüfung der vollständigen CI auf eigenem PR. Kein automatischer Merge.
- **GEÄNDERTE DATEIEN:** `app/lib/ui/srd_magic_initiate_dialog.dart`, `app/test/srd_magic_initiate_ime_test.dart`, dieser Checkpoint, `docs/CODEX_CHECKPOINT.md`, `README.md`. Keine Spielregel-/Schema-/JSON-/Versionsänderung; **Migrationen:** keine.
- **NÄCHSTER SCHRITT:** Tastatur-Tab/Enter-Fokusreihenfolge der vier Auswahlfelder bei 320 dp/200 %/IME gezielt abnehmen; gültige Auswahl und Abbruch vollständig per Hardwaretastatur erreichbar, nie unbeabsichtigt bestätigen.

---

## 31.10.2026 – Chat C: Hintergrundpaket bei 200 % Schrift und IME (PR #455)

- **Ausgangs-main:** `5a88834c98f5aca40395088c20c7e1dc5b587868`; **Branch:** `feat/chat-c/background-package-large-text-ime-20261031`.
- **Code- und Testcommit:** `3d2a1471338bf92fb31dd10b505fc9f3d7ca7eb1` (finalen Dokumentations-HEAD im PR prüfen); **Pull Request:** [#455](https://github.com/ManuEtt/Dnd/pull/455) (Draft).
- **Problem:** Im Dialog für Hintergrundpakete liegt ein eigener Scrollbereich innerhalb eines nicht als scrollable deklarierten AlertDialog. Für sehr große Schrift und simulierte Android-Tastatur gab es keine spezifischen Widgettests; zwei Dropdowns waren nicht expandiert.
- **IMPLEMENTIERT:** `app/lib/ui/srd_background_package_dialog.dart` nutzt nun einen einzigen `AlertDialog(scrollable: true)`, schmale Insets und beide Dropdowns mit `isExpanded: true`. Unveränderte explizite Bestätigung und Abbruch.
- **TESTS HINZUGEFÜGT:** `app/test/srd_background_package_ime_test.dart` mit vier positiven/negativen Varianten: 320/360 dp und 200 % Schrift bei 220 dp IME; Soldat ohne Spielset gesperrt und abbrechbar; Akolyth wählt 50 Gold statt Symbol; Soldat wählt ein wirklich vorhandenes Spielset. Layoutfehler werden explizit geprüft.
- **GETESTET:** GitHub-main, alle offenen PR-Bereiche, bestehender Quellcode und vorhandene Tests geprüft, Branch/Code/Test-PR angelegt. [PR #450 CI 41244483591](https://github.com/ManuEtt/Dnd/actions/runs/41244483591) ist auf eigenem Vor-Branch grün; **nicht** als Nachweis für #455 verwenden.
- **NICHT GETESTET:** Neue Tests, Formatierung, `flutter analyze`, vollständige Flutter-Suite, Backend/Python, native Gradle-Tests und APK für den finalen PR-Head sind bis zur CI offen. Flutter-/Dart-SDK lokal nicht vorhanden; keine echte Geräte-IME- oder TalkBack-Abnahme.
- **BLOCKIERT:** CI-Abnahme des neuen Pakets. Keine automatische Integration.
- **GEÄNDERTE DATEIEN:** UI-Dialog, neuer Test, `README.md`, `docs/CODEX_CHECKPOINT.md`, `docs/parallel/CHAT_C_CHECKPOINT.md`. Andere UI-/Fachmodule und Spielstandformat bleiben unangetastet. **Migrationen:** keine.
- **NÄCHSTER SCHRITT:** Den getrennten `SrdMagicInitiateDialog` bei 320 dp/200 %/IME auf durchgehende Scrollbarkeit prüfen. Akzeptanz: alle Zauberwahlen, Validierungsfehler und Abbruch/Bestätigung bleiben erreichbar; doppelte Zaubertricks dürfen keine Bestätigung erlauben.

---

## 31.10.2026 – CHAT C: Schildreaktionsdialog auf kleinen Displays (PR #450)

- **Ausgangs-main:** `5a88834c98f5aca40395088c20c7e1dc5b587868`.
- **Branch:** `feat/chat-c/hero-shield-dialog-large-text-ime-20261031`; **Code-/Testcommit:** `a4809858c402963015337f95b5a58cce0a54f3f2`; **PR:** [#450](https://github.com/ManuEtt/Dnd/pull/450) (Draft, finalen Head direkt beim PR prüfen).
- **Problem:** Der Bestätigungsdialog für die vorausgewählte Schildreaktion nutzt einen eigenen Scrollbereich ohne `AlertDialog.scrollable`. Bei 320/360 dp, 200 % Text und offener Android-Tastatur fehlte eine explizite Widget-Absicherung von Scrollen, Abbruch und gültiger Bestätigung.
- **IMPLEMENTIERT:** `app/lib/ui/hero_shield_reaction_dialog.dart` scrollt Titel und Eingabebereich im Dialog, nutzt kompakte Viewport-Ränder sowie expandierte Dropdowns; feste Abbruch-/Bestätigungsaktionen und ausdrückliche V/S-Bestätigung bleiben erhalten.
- **TESTS ERGÄNZT:** `app/test/hero_shield_reaction_dialog_large_text_ime_test.dart`: zwei positive Scroll-/Abbruchfälle (320 und 360 dp bei 200 %/IME), ungültige Komponentenbestätigung vor der gültigen Auswahl sowie der negative Fall ohne vorbereiteten Schild. Keine Daten- oder Ressourcenmutation beim Abbruch.
- **GETESTET:** GitHub main, vier offene PR-Aufgabenpakete und geänderte PR-Dateien geprüft; die Code-/Teständerungen sind auf dem eigenen Branch gesichert. Die letzte main-Android-CI [41184883579](https://github.com/ManuEtt/Dnd/actions/runs/41184883579) ist erfolgreich; dies ist **kein** Nachweis für PR #450.
- **NICHT GETESTET:** Neue Widgettests, lokaler Dart-Formatter, Flutter-Analyse, gesamter Flutter-/Backend-/Python-/Android-Build und Android-TalkBack/IME auf einem realen Gerät – Flutter-/Dart-SDK lokal nicht vorhanden. CI auf finalem PR-HEAD abnehmen.
- **BLOCKIERT:** Vollständige Validierung durch ausstehende GitHub-PR-CI / fehlende lokale Flutter-Toolchain. Kein automatischer Merge.
- **NOCH NICHT IMPLEMENTIERT:** Reale TalkBack- und Touch-Abnahme bei 320 dp/200 %/IME.
- **Geänderte Dateien:** Schilddialog, neuer Widgettest, `docs/parallel/CHAT_C_CHECKPOINT.md`, `docs/CODEX_CHECKPOINT.md`, `README.md`. Kein Schema, keine API, kein JSON, kein Spielstand, keine Migration.
- **Nächster unabhängiger Schritt:** Die Tastaturfokus-Reihenfolge des Schilddialogs auf 320 dp/200 %/IME mit Tab/Enter absichern; Akzeptanz: beide Komponenten und Abbruch sind erreichbar und Fokus aktiviert nie eine unbestätigte Schildreaktion.

---

## 02.11.2026 – Chat C: manueller Zusatzkreaturen-Angriff bei großer Schrift/IME (PR #492)

- **Ausgangs-main:** `c33448780dfe8b453f7f1db9d28c1396822901a7`.
- **Branch:** `feat/chat-c/manual-extra-attack-ime-20261102`; **PR:** [#492](https://github.com/ManuEtt/Dnd/pull/492) (Draft).
- **Code-/Test-HEAD vor Dokumentation:** `88dfb25b21065f51baad4031a7340d919696126c`; finalen HEAD dem PR entnehmen.
- **Ausgangsproblem:** Im umfangreichen Dialog für einen ausdrücklich bestätigten Zusatzkreaturen-Angriff erschwerten der innere Scrollbereich, lange Checkboxtexte und nicht expandierte Dropdowns die Bedienung auf 320/360 dp bei 200 % Schrift mit 220 dp IME.
- **Implementiert:** `AlertDialog(scrollable: true)` und kompakte Insets statt innerem `SingleChildScrollView`; kompakte visuelle Checkboxbeschriftungen ab 180 % mit vollständigem `Text.semanticsLabel`; drei expandierte Dropdowns, ellipsierte lange Kreaturennamen, lebende Fehler-Semantik. Keine Regel-/Controller-/Persistenzänderung.
- **Geänderte Fachdateien:** `app/lib/ui/manual_extra_creature_attack_dialog.dart`, neue `app/test/manual_extra_creature_attack_ime_test.dart`. Daneben additive README-/Checkpoint-Nachträge auf eigenem Branch.
- **Neue Regressionen:** Abbruch auf 320/360 dp mit 200 %/IME ohne Mutation, unvollständige Angriffsbestätigung ohne Mutation und positiver bestätigter Angriffs-DTO-Weg mit sieben Pflichtbestätigungen. Bestehende `manual_extra_creature_attack_dialog_test.dart` bleibt unverändert.
- **GETESTET:** Live-GitHub-main, 29 vor Start offene PRs inklusive geänderter Fachdateien und Quell-/Testfixtures geprüft; Branch/Commits und Draft-PR erstellt. Keine erfolgreichen ausführbaren Flutter-Tests behauptet.
- **NICHT GETESTET:** Dart-Format, Flutter-Analyse/Tests, Debug-APK, native Android-Tests, Python-/Backend-Gates auf finalem PR-HEAD, reales Android/TalkBack/IME und Altgeräteupgrade bis CI-/Geräteabnahme.
- **BLOCKIERT:** Lokales Flutter/Dart-SDK nicht vorhanden; CI auf finalem Commit nach Dokumentation neu bewerten. README-/zentrale Checkpoint-Integration wegen paralleler PRs durch Chat D.
- **Spielstandkompatibilität:** Keine Migration; unveränderte Domainregeln, JSON-/SQLite-Schemata, Ereignisse und App-Version.
- **Nächster unabhängiger Schritt:** `app/lib/ui/srd_class_level_up_dialog.dart` separat auf 320 dp/200 % und schmale Auswahlfelder prüfen; nur bei nachweisbarer UI-Regression testen und korrigieren, nicht parallel zu künftig kollidierenden PRs.

---

---

## 02.11.2026 – Sending-Dialog bei 200 % Schrift und Android-Tastatur

- **Ausgangs-main:** `55d33945872e251ec53b6860addcb05152a80c3a`.
- **Branch:** `feat/chat-c/sending-dialog-ime-20261102`.
- **PR:** [#503](https://github.com/ManuEtt/Dnd/pull/503) (Draft).
- **Problem:** Der umfangreiche Sending-Dialog benutzte einen eigenen Scrollbereich in einem nicht vollständig scrollbaren `AlertDialog`. Lange Zustimmungen und die Abschlussaktion waren bei 320/360 dp, 200 % Schrift und simuliertem 220-dp-IME-Inset nicht abgesichert.
- **Implementiert:** `AlertDialog(scrollable: true)` mit nur einem Dialog-Scrollbereich. Bei mindestens 180 % Schrift sind drei Bestätigungstexte visuell kompakt; ihre vollständigen bestehenden Aussagen bleiben als `Text.semanticsLabel` erhalten. Die lange Abschlussaktion wird visuell verkürzt.
- **Dateien:** `app/lib/ui/sending_attempt_dialog.dart`, `app/test/sending_attempt_ime_test.dart` sowie additive README-/Checkpoint-Einträge.
- **Widgettests geschrieben:** 320/360 dp, 200 % Text und 220 dp Android-IME: Abbruch, deaktivierte unbestätigte Buchung, scrollbarer Inhalt, positive explizite Sending-Vorschau und Widerruf der Zustimmung nach Textänderung. Vorher-/Nachher-JSON des Helden wird verglichen.
- **GETESTET:** GitHub-Quellstand, offene PRs, Fachdateiüberschneidungen, eigener Branch, Main-Merge ohne Dateikonflikte und offizielle Dartformatierung überprüft. Der erste kombinierte CI-Lauf [#41452067597](https://github.com/ManuEtt/Dnd/actions/runs/41452067597) auf `3bf9729d` hatte 2.789 erfolgreiche Fluttertests und einen neuen fehlgeschlagenen Touch-Widgettest: das nach einer Texteingabe oberhalb der Scrollposition liegende Dropdown war mit ausschließlich abwärts gerichtetem Test-Drag nicht erreichbar. Der Testhelfer wurde auf bidirektionales Scrollen korrigiert; neue vollständige CI am Folge-Commit noch zu prüfen.
- **NICHT GETESTET:** Vollständige grüne Flutter-/Android-CI auf dem nach der Regression korrigierten finalen HEAD; reale Android-/TalkBack-/IME-/Upgrade-Abnahme. Die erste Gesamt-CI ist wegen des einen expliziten Widgettestfehlers **fehlgeschlagen**, keine Gesamtfreigabe.
- **Keine Migration:** Regeln, Domain, Controller, Story, Datenbank, JSON-/SQLite-Schemas, App-Version und bestehende Spielstände unverändert. Keine automatische Zauberbuchung aus der UI.
- **Nächster Schritt:** Finale GitHub Actions auf dem vollständig dokumentierten Commit überprüfen und konkrete Fehler im selben Branch korrigieren; erst nach grüner CI für Integration freigeben.

---
