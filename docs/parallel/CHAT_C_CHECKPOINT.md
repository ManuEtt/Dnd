## 30.10.2026 – Chat C: Ausrüstungsdialog bei 200 % Schrift und IME

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
