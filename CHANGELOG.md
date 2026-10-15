## 0.5.6+26 – CI-Fixes: Schnellaktionen und Inventar (15.10.2026)

- **Schnellaktionen:** Beim Öffnen der Android-Tastatur erkennt der feste Dock über `View.of(context).viewInsets` den tatsächlichen IME-Bereich auch hinter einem verschachtelten `Scaffold`. Die Überschrift wird ausgeblendet, die vier Aktionen bleiben erhalten.
- **Große Schrift:** Die Docküberschrift verwendet ein flexibles, auf eine Zeile begrenztes Textfeld; die Höhe der vier Buttons skaliert ausreichend mit bis zu zwei Zeilen großer Schrift. Behebt die CI-Overflows bei 320dp/180%.
- **Charaktereditor:** Der Inventartest scrollt den tatsächlichen `OutlinedButton` vollständig ins sichtbare Fenster und prüft vor dem Antippen die Trefferfläche. Keine Funktion oder Inventarlogik geändert.
- **Regression:** Der Tastaturtest prüft nun alle vier betätigbaren Schnellaktionen.
- **Eingangslage:** CI #38728029583 für 0.5.5+25: 349 Flutter-Tests grün, 3 rot; Flutter-Analyse, Backend und Python erfolgreich. **Neuer Flutter-CI-Lauf für 0.5.6 steht aus**, eine APK-Freigabe wird nicht behauptet.
- **Workflow:** Nur `.github/workflows/android-build.yml`; kein Codex in Actions. Datenbankschema 1 und historische Spielstände unverändert.

## 0.5.5+25 – feste Schnellaktionen am unteren Bildschirmrand (15.10.2026)

- Die Abenteuer-Schnellaktionen sind nun im `Scaffold.bottomNavigationBar` der Abenteueransicht verankert, nicht im scrollbaren Inhalt oder im Composer. Sie stehen unter dem Texteingabefeld und direkt über der allgemeinen App-Navigation.
- Die doppelten Sprach- und Würfel-Schaltflächen aus dem Composer entfernt. **Sprache/Stopp**, **Untersuchen**, **Angriff** und **W20** bleiben unten einheitlich erreichbar; **Rückblick** bleibt separat neben dem Eingabebereich.
- Bei offener Android-Tastatur bleibt die Leiste angedockt; die vorhandene Tastaturkompaktansicht bleibt erhalten. Funktionalität und gespeicherte Spielstände unverändert.
- Flutter-Widgettests auf die neuen Schnellaktions-Selektoren umgestellt und Integrationstest erweitert. Python- und Projektstrukturprüfungen werden getrennt protokolliert; Flutter-CI-Abnahme für 0.5.5 noch erforderlich.
- Keine Codex-Entwicklung in GitHub Actions; regulärer Android-/Release-Workflow bleibt vorhanden.

## Prüf- und Analysekorrekturen 0.5.4+24 – 15.10.2026 (nicht Flutter-CI-validiert)

- Automatischer Codex-Workflow bleibt aus dem vollständigen Import-ZIP ausgeschlossen; normaler Android-Workflow erhalten.
- Flutter-Analysefehler im Test der fixierten Schnellaktionen (`const NavigationBar`) korrigiert.
- Zwei Dart-Lint-Hinweise zu fehlenden Blockklammern in Charaktereditor und Zweitklassen-Dialog korrigiert.
- Projektprüfung und 35 Python-Tests erfolgreich; Flutter/Android-Build bleibt ausstehend.
- Live-GitHub enthält die alte Codex-Datei weiterhin; dortige Löschung noch erforderlich.

## 0.5.4+24 – GitHub Actions ohne automatische Codex-Entwicklung (15.10.2026)

- `.github/workflows/autonomous-development.yml` aus dem vollständigen Projekt entfernt. Es gibt im neuen Archiv keinen Zeitplan, keinen `openai/codex-action`-Aufruf und keinen automatischen Codex-PR-Job mehr.
- `.github/workflows/android-build.yml` und die regulären Flutter-, Backend-, Python-, Android- und Release-/Checkpoint-Jobs unverändert erhalten. Manuelle Codex-Verwendung außerhalb von GitHub Actions bleibt möglich.
- Import- und Fortsetzungsdokumentation aktualisiert; ein neuer Python-Regressionstest verhindert, dass versehentlich wieder ein Codex-Workflow in `.github/workflows` landet.
- **Keine App-Änderung und keine neue APK-Abnahme.** Die Versionsnummer `0.5.4+24` bleibt unverändert. GitHub-Commit nicht ausgeführt: Contents-API gibt HTTP 403 zurück. Bestehende Workflow-Datei auf GitHub muss gesondert mit `git rm` entfernt werden.

## 0.5.4+24 – Mehrklassen-Aufstieg absichern und versionierte Alpha-Auslieferung vorbereiten (15.10.2026)

- **Mehrklassen:** Vor dem Übernehmen einer Zweitklassen-Stufe wird jetzt überprüft, ob der Vorschlag noch zum selben Helden und zu denselben bestätigten Attributen, Fertigkeiten, maximalen Trefferpunkten und Klassenstufen gehört. Nachträglich ungültige Vorschläge werden ohne stillen Charakterfehler zurückgewiesen. Erlittener Schaden zwischen Vorschlag und Bestätigung bleibt erhalten und wird korrekt zum TP-Zuwachs berücksichtigt.
- **Defensive Validierung:** Direkte inkonsistente Primär-/Sekundärklassenstufen werden abgewiesen. Fünf Dart-Regressionstests ergänzen die bestehenden Mehrklassen-Tests.
- **Release-Automatisierung:** Neues `scripts/prepare_alpha_release.py` erzeugt nach **vollständig erfolgreichem CI-Lauf** ein versioniertes vollständiges Quellarchiv, die zuvor gebaute ARM64-APK, Release-Notizen und SHA-256-Prüfsummen. ARM64-Bibliotheken und APK-ZIP-Integrität werden vor Freigabe geprüft; die bestehende interne Debug-Testsignierung ist eindeutig gekennzeichnet.
- **Tests:** Sieben neue Python-Fälle decken die sichere Auslieferung ab. GitHub-Actions-Workflow nutzt das Skript und lädt die versionierten Dateien als gemeinsames Release-Artefakt hoch. Fehlerhafte Builds behalten die bisherige gesonderte **nicht freigegebene** Quell-Checkpoint-Veröffentlichung.
- **Abnahme:** Lokale Python- und Projektstrukturtests bestanden; Flutter-/Dart-Tests und Android-Build sind ohne SDK lokal **nicht ausgeführt**. Backend-`npm ci --offline` war wegen fehlendem Cache für `undici-types` nicht ausführbar. GitHub-`main` wurde nicht verändert. Dieser Entwicklungsstand bleibt ein *unverifizierter Quellcode-Checkpoint*, bis CI vollständig erfolgreich ist.

## Ergänzung zur Quellcodeübergabe 0.5.3+23 – 15.10.2026

- Vollständigen Quellstand mit bereits vorhandenen fixierten Schnellaktionen (0.5.3+23) übernommen; keine Spielstands-/Schemaänderung.
- Python-Regressionstest gegen ungültige `pubspec.yaml`-Beschreibung ergänzt.
- GitHub-Actions-Quellencheckpoint und einen getrennten, zunächst deaktivierten Codex-Workflow vorbereitet.
- `docs/AUTONOMOUS_DEVELOPMENT_STATE.md` und Importanleitung ergänzt. Neue APK/Flutter-CI-Abnahme noch ausstehend.

## 0.5.3+23 – Fixierte Schnellaktionen im Abenteuer (15.10.2026)

- **Navigation:** Die vier Schnellaktionen **Sprache, Untersuchen, Angriff und W20** wurden aus der scrollbaren Abenteuerszene in eine stets am unteren Rand sichtbare Aktionsleiste direkt **über der Hauptnavigation** verschoben. Sie sind auch in der Kampfübersicht erreichbar.
- **Responsive Darstellung:** Kompakte Fantasy-Kacheln passen nebeneinander auf 320/360/400 dp; bei eingeblendeter Tastatur entfällt nur die Leistenüberschrift. Doppelte Buttons im Eingabebereich werden bei geöffneter Tastatur ausgeblendet, um Platz zu schaffen.
- **Bestehende Funktionalität:** Die Schnellaktionen verwenden dieselben Methoden zur Mikrofonsteuerung, Untersuchung, Angriffseingabe und Würfelfunktion. Keine Änderungen an D&D-Regeln, KI, SQLite oder Spielstandformat.
- **Buildblocker korrigiert:** `app/pubspec.yaml` hatte seit der Umbenennung eine nicht maskierte zweite Doppelpunkt-Sequenz in `description`. Die Beschreibung ist jetzt gültig in Anführungszeichen gesetzt, damit `flutter pub get` nicht mehr bei der YAML-Analyse scheitert. Ursprünglicher Fehler: GitHub Actions Commit `bb5383b7a52b5052a5c2e8ce4714fe16b0e600da`.
- **Tests:** Neue Widgettests für fixierte Position bei Scrollbewegungen, Bedienbarkeit, schmale Bildschirme und geöffnetes Keyboard; Integrationstest mit echter Kampagnenseite. 22 Python-Tests und Strukturprüfung bestanden, YAML erfolgreich geparst. Flutter-Tests und APK-Build stehen auf GitHub Actions noch aus.

## 0.5.2+22 – Neuer Name und SRD-Zweitklassen-Assistent (15.10.2026)

- Neuer Produktname **Würfelraunen – Der lebendige Spielleiter** in Startseite, Android-Launcher, App-Titel, Sprecherprobe, Lizenzansicht und KI-Prompt; technische App-ID bleibt zur Update-Kompatibilität unverändert.
- Automatisierte Zweitklasse beim Stufenaufstieg (maximal zwei Klassen, Gesamtstufe bis 20): Primärattribut-Voraussetzungen beider Klassen, feste zusätzliche TP nach Trefferwürfel und Konstitution, gezielte neue Klassenfertigkeit bei Barde/Schurke/Waldläufer.
- Optionale Mehrklassenfelder in den bestehenden `schemaVersion:1`-Heldendaten; vorhandene Speicherstände und Importe bleiben lesbar, keine SQLite-Migration.
- Kein fälschliches Gewähren von Startausrüstung, neuem Start-TP-Maximum oder Rettungswurf-Übungen. Anzeige im Charakterbogen, Heldenliste und KI-Kontext; Regel-/Widgettests ergänzt.
- Grenzen: Klassenspezialfähigkeiten, Rüstung-/Waffen- und Werkzeugübungen sowie Zauberressourcen sind nicht vollständig automatisiert; ermittelte Zauberplätze dienen vorerst der Vorschau.
- Neues Quellpaket erstellt, Flutter/Android-CI für diese Version noch nicht ausgeführt.

## 0.5.1+21 – Flutter-CI-Abnahme des illustrierten Designs (15.10.2026)

- **CI-Ursache:** Letzter GitHub-Actions-Lauf für `0.5.0+20` (`a3a05d3888a9c0e19d3e43d2469cc849f5e1a4eb`) scheiterte trotz 328 bestandener Flutter-Tests an zwei veralteten Widgettest-Interaktionen.
- **Charakterbogen:** Der Test für unbekannte Angaben scrollt zur verzögert aufgebauten Tab-Navigation, bevor er die Tabs antippt. `ensureVisible` allein konnte den zunächst noch nicht aufgebauten Tab nicht finden.
- **Startseite:** Der 360-dp-Navigationstest scrollt zum echten Demo-Button unter dem illustrierten Header, überprüft die Antippbarkeit und startet dann die Demo. Keine Hit-Test-Warnungen unterdrückt und keine Tests deaktiviert.
- **Umfang:** Nur Widgettests, Versionsnummer und Dokumentation geändert. Alle zwölf neuen Illustrationen, UI-Widgets, Spiellogik, Backend und gespeicherte Daten bleiben unverändert.
- **Status:** Lokale Python-/Paketprüfungen durchgeführt; Flutter-Analyse, Flutter-Tests und APK-Build müssen die neue Version in GitHub Actions bestätigen. Ohne grünen Build noch keine Freigabe.

## 0.5.0+20 – Illustriertes Aetheria-Design (15.10.2026)

- Echte, kompakte App-Grafiken aus den zuvor entworfenen Aetheria-Illustrationen als lokale WebP-Assets (`app/assets/art/`, 12 Motive). Keine eingebetteten Bildschirm-Screenshots als UI.
- Neues `FantasyIllustratedBanner` mit realen Kampagnendaten und Fortsetzen-Aktion; gerahmte Kampagnenkarten mit regionalen Motiven; horizontale Schnellzugriffe zu bestehenden Funktionen.
- Abenteueransicht mit atmosphärischer Szene, weiterhin gespeicherter Szenentext und bestehende Spielaktionen. Zusätzliche Aktionskacheln verwenden die realen Spiel-/Sprach-/Würfelmethoden.
- Heldenarchiv mit individuellen Initialenmedaillons (kein erfundenes Porträt); Charakterbogen mit Burgenillustration, dekorativen Rahmen.
- Inventar mit einzelnen bebilderten Gegenständen auf Basis von `hero.inventory`: Anzahl und Name aus gespeicherten Daten, Detaildialog nur informativ, keine vorgetäuschte Anlegen-/Ablegen-Funktion.
- Chronik-Banner und einheitlicher Fantasy-Startbildschirm.
- Neues Testmodul zu Bild-Assets, Darstellung bei 320/360/400/950 dp und echten Inventargegenständen.
- Keine Änderungen an Backend, SQLite, Spielregeln oder den vorhandenen Import-/Exportformaten.
- Paket-/Strukturtests erfolgreich. Flutter-Analyse, Flutter-Widgettests und Android-APK müssen über GitHub Actions noch bestätigt werden.

## 0.4.3+19 – CI-Fix: überlaufende Attributkarten und mehrdeutige Widgettests (15.10.2026)

- GitHub Actions `38692820652`: Flutter-Analyse erfolgreich, 319 Tests erfolgreich, vier neue Layouttests rot. Drei Ursachen: `_AbilityCard`-Spalten bei 320 dp und 1.4x-Schrift überlaufen; bei 360/400 dp suchten Tests mehrdeutig nach `GridView` und warfen `Bad state: Too many elements`.
- Die sechs Attributkarten verwenden jetzt statt `GridView.count(childAspectRatio: ...)` einen expliziten `SliverGridDelegateWithFixedCrossAxisCount(mainAxisExtent: ...)`. Die Höhe passt sich mittels `MediaQuery.textScalerOf` an Systemschriftgrößen an. Keine Werte werden abgeschnitten oder verworfen.
- Übersichts- und Attributgrids haben eindeutige `ValueKey`s; Widgettests suchen gezielt das jeweilige Grid und scrollen bis zu den Rettungswürfen, um alle sechs Attributkarten zu rendern. Extra Test für TextScaler 1.4.
- Keine Änderungen an Spielregeln, Speicher, Backend oder Sicherheitsmodell; keine neuen Pakete.
- Prüfstatus: Projektstruktur, Python-Tests und ZIP-Integrität lokal; `flutter analyze`, `flutter test` und APK-Build erst durch GitHub Actions belegbar.

## 0.4.2+18 – Korrektur des CI-Kompilierfehlers (15.10.2026)

- `app/lib/ui/fantasy_character_sheet.dart`: `GridView.count` durch `GridView` mit `SliverGridDelegateWithFixedCrossAxisCount` ersetzt. Der Parameter `mainAxisExtent` befindet sich nun am richtigen Delegate.
- Bestehender Schutz vor `RenderFlex overflow` auf schmalen Displays und bei größerer Systemschrift bleibt erhalten.
- Regressionstest prüft Grid-Delegate, Anzahl Spalten und feste Kachelhöhe.
- Basiert auf `main` Commit `35a7b4062c5248b288598b587da6c606bf80122d` (0.4.1+17).
- Auslöser: GitHub Actions Build 38691911056 schlug am 15.10.2026 bei `flutter analyze` fehl (`undefined_named_parameter` in Zeile 237).
- Projektstruktur/Python-Tests hier geprüft; vollständige Flutter-/Android-Abnahme über GitHub Actions steht aus.

## 0.4.1+17 – Korrektur der Charakterbogen-Kacheln (15.10.2026)

- Die vier Statistik-Kacheln verwenden jetzt eine von Schriftgröße und Layout unabhängige Mindesthöhe statt eines festen Seitenverhältnisses. Dies behebt die drei `RenderFlex overflowed`-Fehler aus GitHub Actions beim Charakterbogen und beim Öffnen des Bogens aus dem Abenteuer.
- Große Textdarstellung wird durch eine an den TextScaler gekoppelte Höhe berücksichtigt. Lange Beschriftungen dürfen auf zwei Zeilen umbrechen; Zahlen werden bei Platzmangel horizontal skaliert.
- Zusätzliche Widget-Regressionstests für 320, 360, 400 logische Pixel und 140 % Schriftgröße.
- Keine Änderung an Regeln, Datenbank, KI-Backend oder gesicherten Charakterwerten. Der GitHub-Actions-Build muss die Korrektur bestätigen.

## 0.4.0+16 – 15.10.2026 – Gesamtes App-Design vereinheitlicht

- Das vollständige bestehende Flutter-UI orientiert sich jetzt am deutschen Dark-Fantasy-Charakterbogen. Zentrales Material-3-Theme und wiederverwendbare Widgets in `app/lib/ui/fantasy_ui.dart`.
- Einheitliche Farben, Serif-Überschriften, goldene/silberblaue Rahmen, einheitliche Buttons, Panels, Formulare, Dialoge, Chips, Listen, Erweiterungsfelder und Bottom Sheets.
- Hauptansichten **Start/Kampagnen**, **Abenteuer/Kampf**, **Helden/Charakterbogen**, **Tagebuch/Gedächtnis** und **Einstellungen/Backend** optisch angepasst. Inventar-Bottom-Sheet und Charaktereditor ebenfalls einbezogen.
- Responsive Navigation: unter 920 Pixel unten, ab 920 Pixel mit seitlicher Navigationsleiste. Keine künstlichen Inhalte oder nicht vorhandenen Karten-/Regel-Seiten.
- Zusätzliche Widgettests für Theme und Komponenten auf 320/360/1000 Pixeln sowie Dokumentation `docs/UI_DESIGN_SYSTEM.md`.
- Keine Spielregel-, Kampagnen-, Speicher-, API-, Kosten- oder Paketabhängigkeitsänderungen. Weiterhin echte bestätigte Daten und sichere Exportfunktionen.
- GitHub-Basis `ce64d5bd10288611bd3a8482b01a32939a309f76` (0.3.9+15). Strukturprüfung und 22 Python-Tests hier erfolgreich. **Flutter-/Android-Tests nicht lokal durchführbar.** Kein direkter Push auf `main`.

## 0.3.9+15 – 15.10.2026 – Neuer deutscher Fantasy-Charakterbogen

- Eigenständiger, deutschsprachiger Charakterbogen nach der abgestimmten Dark-Fantasy-Vorlage: dunkelblaue Flächen, goldene Kanten, farbige Attributkarten, Trefferpunktebalken und responsive Karten für Übungsbonus, Bewegung, Initiative und Rüstungsklasse.
- Aus der **Heldenverwaltung** („Bogen ansehen“) und aus dem **Abenteuer** („Charakterbogen ansehen“) erreichbar; vom Bogen aus ist der bisherige Charaktereditor weiterhin verfügbar.
- Abschnitte für Attribute/Rettungswürfe/Fertigkeiten, Zustände/Merkmale und Verteidigungsinformationen. Alle Informationen stammen aus dem echten `HeroCharacter`; unbekannte Werte bleiben als Strich bzw. „Nicht erfasst“ stehen. Mangels gespeicherter Portraitdaten wird ein Initialen-Avatar gezeigt, kein erfundenes Charakterporträt.
- Übungsbonus wird ausschließlich aus gültiger Stufe 1–20 berechnet, Attributmodifikatoren aus bestätigten Werten. Rettungswürfe addieren nur die explizit gespeicherte Übung; andere Effekte werden nicht erfunden. Die bestehende Bewegungseinheit bleibt **Meter**.
- Globales Designsystem an die neue Ansicht angepasst: marineblaue Karten/Hintergründe, Goldakzent, kontrastreichere Schriften und Buttons; Datenbankformat, Sprachausgabe, Kampagnen und Regel-Engine unverändert.
- Neue Flutter-Widgettests für deutsche Bezeichnungen, responsives Layout bei 320/360 px, Modifikatoren, fehlende Werte und Bearbeitungsaktion. Tests können hier mangels Flutter-SDK nur als Quellcode geprüft werden; sie müssen in GitHub Actions laufen.
- Korrektur des vorherigen Backend-CI-Testfehlers: Versionsassertion im Health-Test auf die tatsächliche Backend-Version `0.3.1` aktualisiert (vorher erwartete `0.3.0`).
- GitHub-Basis `125fc3630722002a955a4e3479395edd6bfb6635` (0.3.8+14). Kein direkter Push in `main`.

## 0.3.8+14 – 15.10.2026 – spielbare dynamische Abenteuer und geprüfte KI-Angebote

- Narrative KI kann **genau eine optionale spielbare Herausforderung** pro Antwort vorschlagen, mit Quest, Begegnung und lokal ausgewähltem Gegnerprofil oder einer Wahrnehmungsaufgabe. KI-Daten werden auf Backend und Gerät validiert; der Provider kann keine Regel- oder Inventarwerte setzen.
- Neue Karten im Abenteuer: Angebot annehmen oder risikofrei verwerfen. Annahme startet einen lokal ausgewürfelten Einzelkampf oder eine Wahrnehmungsprobe SG 10, jeweils mit eigener Quest und atomarem Ereignis.
- Ein bestätigter Sieg/Erkundungserfolg schließt die verknüpfte Quest ab und vergibt eine **einmalige, nichtmagische Beute** aus der lokalen Tabelle; bei Fehlschlag/Flucht keine Beute. Keine EP- oder Gold-Buchung, keine unbestätigte Ausrüstung.
- Story-Fortschritt, Kampagnen-Journal, SQLite/JSON-Sicherung, bestehende Sprach- und Erzählfunktion bleiben angebunden; alte `schemaVersion:1`-Spielstände sind kompatibel. Neues optionales `adventureOffer`-Objekt.
- Korrektur des bisherigen CI-Blockers: Fastify-`preHandler` jetzt mit echten `FastifyRequest`/`FastifyReply`-Typen statt nichtkompatibler selbst gebauter Request-/Reply-Typen.
- Isolierte TypeScript-Prüfung des Abenteuer-Validators und Mock-Antworten, 22 Python-Pakettests, ergänzte Dart- und Backend-Tests. Flutter und vollständiges npm-Backend mangels lokalem SDK/offline-Abhängigkeiten **noch nicht bestätigt**. **Kein offizieller grüner Build dieses Stands**.
- Aktuelle Grenzen sind in [docs/AI_ADVENTURES.md](docs/AI_ADVENTURES.md) erklärt. **Keine Behauptung einer vollständig implementierten D&D-5e-Regelengine.**

## 0.3.7+13 – 15.10.2026 – KI-gestützte eigene Kampagnen und Entscheidungen

- Optionaler Start neuer Kampagnen mit Wunschthema und bereits angelegtem Helden. Der verbundene OpenAI-Dienst erzeugt ein neues Abenteuer mit Welt, Einstiegsszene, verborgenem Plot, Ziel, 2–4 offenen Handlungssträngen, NPCs und Orten. Der Mock-Dienst bietet ausdrücklich nur eine deterministische Testgeschichte.
- Beim Weiterspielen berücksichtigt die KI die aktuelle Szene, gespeicherten Plot, bisherige Handlungsstränge, NPC-Beziehungen, geeignete bestätigte Erinnerungen und letzte sechs Spieleraktionen. Sie schlägt eine neue Szene, Statusänderungen, neue Fäden und Beziehungsentwicklungen vor. Die lokale Engine prüft die Struktur und übernimmt erlaubte erzählerische Daten als ein einziges atomar gespeichertes Ereignis.
- Persistenter `storyBible`-Block im Kampagnen-JSON (optional, alte Spielstände gültig), ohne neue SQL-Migration. Verborgene Wendungen stehen **nicht** in der allgemeinen Faktensuche oder im sichtbaren Tagebuch, wohl aber im privaten JSON-Export. Fortschritt, Beziehungen und Entscheidungen bleiben über Neustart und Export erhalten. Keine Gewichtsänderung oder lokale Modellschulung: **„lernend“ bedeutet kontext- und erinnerungsbasiert**.
- Neue authentifizierte, limitierte Backend-Endpunkte `POST /v1/story/start` und `POST /v1/story/advance`. Bestehende Sitzungstokens, HTTPS-Vorgaben und ausdrückliche OpenAI-Kostenfreigabe gelten auch hier; gemeinsames Minuten-/Tageslimit. Kein OpenAI-Schlüssel in der App, keine Server-Schreibrechte auf Spielstände.
- **Sicherheitsgrenze:** NPC-Beziehungs- und Story-Status dürfen sich entwickeln; HP, Würfelergebnisse, Attribute, Questbelohnungen und Inventar nicht. Ein Angriff auf einen nicht regeltechnisch erfassten Gegner wird blockiert, nicht von der KI ausgewürfelt. Das sind noch keine vollständigen frei generierten Kämpfe.
- Demo/Story getrennt: Die KI-Kampagne kann niemals automatisch auf das Mooswacht-Schlüssel-/Schrein-Skript zurückfallen. Provider-Ausfälle erhalten den bestätigten lokalen Spielzug; misslungener Kampagnenstart speichert gar nichts.
- Neue Domain-, SQLite-Integrations- und Backend-Tests zur Story-Erzeugung, ID-Validierung, deterministischen Testantworten, persistierten Beziehungen, falschen Providerantworten, Rate-Limits und verlorener Verbindung. Bekannte CI-Widgettestprobleme aus `ea486481d288...` (zweimaliger Dialogtitel und spätes Tagebuch-Scrolling) korrigiert.
- GitHub-Ausgangsbasis `ea486481d28856228abf65dd209857028b3b3c45` (0.3.6+12, 117 Dateien). **Hier ausgeführt:** Strukturscan, 22 Python-Tests, isolierter TypeScript-Parser und TypeScript-Syntaxcheck. Flutter-SDK und vollständige npm-Abhängigkeiten fehlen; Flutter-, komplette Backend-, APK- und Geräteprüfungen stehen aus.

## 0.3.6+12 – 15.10.2026 – Dauerhaftes Kampagnengedächtnis

- Im Tagebuch drei neue Bereiche: Sitzungsrückblicke dauerhaft speichern, Handlungsstränge mit Offen/Gelöst/Aufgegeben verwalten und Veränderungen der NPC-Beziehungen samt Notiz dokumentieren.
- Rückblicke werden ausschließlich aus strukturierten, bestätigten Quests, NPCs, Fakten und Handlungssträngen gebildet; freie KI-Erzähltexte und rohe Nutzereingaben sind keine Faktenquelle. Einträge gelangen in die lokale Erinnerungssuche und den Kontext des optionalen Backend-Erzählers.
- Neue optionale Felder `sessionRecaps`, `storyThreads`, `npcRelationshipNotes` in der bestehenden Kampagnen-JSON-Struktur. Vorhandene Sicherungen bleiben mit dem Parser kompatibel, SQLite-Schema bleibt Version 1. Maximal 60 Rückblicke, 100 Handlungsstränge und 300 Beziehungsnotizen.
- Alle Notizänderungen werden mit Revision und überprüfbarem Ereignis-Checkpoint atomar gespeichert. Regelwerte, HP, Würfel- und Questbelohnungen werden durch diese Verwaltungsaktionen nicht verändert.
- Zusätzliche Domänen-, Widget- und SQLite-Tests mit Testcode für Altimporte, Begrenzungen, Wiederherstellung, Replay, Beziehungshistorie und Eingabevalidierung.
- Vorherigen GitHub-CI-Fehler im Test `ui_app_test.dart` (Button „Vervollständigen“ auf 360-px-Bildschirm überlagert) durch Scrollen vor der Interaktion korrigiert. Auf Basis-Commit `6e967080baba7de252fac378d51758a20f6556ae` waren 290 Flutter-Tests erfolgreich, einer fehlgeschlagen; Flutter-Analyse, Python und Backend bestanden, APK-Schritte übersprungen.
- **Prüfstatus dieser Version:** Projektstruktur und alle 22 Python-Tests lokal bestanden. Mangels Flutter-/Dart-SDK und offline nicht verfügbarer npm-Abhängigkeiten sind Flutter/Backend-/APK-Prüfungen für 0.3.6 noch offen. Erfolgreiche CI vor Verwendung als installierbare APK erforderlich.

## 0.3.5+11 – 15.10.2026 – Kampagnenrückblick und NPC-Reaktionen

- Im Abenteuer gibt es einen direkt erreichbaren Button **Rückblick**. Ein noch nicht abgesendeter Handlungstext bleibt unverändert; Spracheingabe/-ausgabe wird vor der Aktion kontrolliert gestoppt.
- Erinnerung an bestätigte Fakten, NPC-Zustände, Queststatus, Inventar und bekannte Orte aus SQLite. Bei gezielten Fragen („Was weißt du über Mira?“, „Erinnere dich an den Waldschrein“) werden **nur thematisch passende** Erinnerungen ausgegeben, niemals ungefragte, unrelated Ereignisse.
- Bei allgemeinen Rückblicken werden bis zu vier relevante bestätigte Einträge angezeigt; die Ausgabe ist begrenzt und liefert explizit „keine passende Erinnerung“, wenn keine bestätigten Fakten zur Frage existieren. Unbestätigte Erzähltexte, Nutzereingaben und externe KI-Antworten werden nicht als bestätigte Fakten gelesen.
- Mira spricht im Demo-Modus jetzt abhängig vom bestätigten Verlauf: Schlüssel bereits gefunden, Dornenwächter besiegt, Waldlicht wieder entzündet. Erledigte Aufgaben werden nicht erneut verlangt.
- Neue Domänen- und Widgettests für thematische Abfragen, unbekannte Fakten, Unveränderlichkeit von Charakter-/Kampfwerten und Questzuständen sowie den Rückblick-Button.
- Ausgangsbasis `ManuEtt/Dnd` main `239ee5f7d333a6388159e7d431039abb92e936b7` (0.3.4+10); keine Schema-, Backend-, API- oder Paketabhängigkeitsänderungen. Flutter-/Android-Abnahme für dieses Inkrement muss nach GitHub-Import erfolgen.

## 0.3.4+10 – 15.10.2026 – Widgettest-Fix und Attribut-Vorschau

- Behebt den fehlerhaften Scrollweg im Widgettest `ui_srd_class_selection_test.dart`, der nach einem blockierten Speicherversuch die Hausregel-Checkbox nicht mehr fand (`StateError: Bad state: No element`). Bei Rueckspruengen wird jetzt negativ gescrollt.
- Neuer Komfort: Sofortige, unverbindliche Modifikatoranzeige unter Attributwerten im Charaktereditor, ueber dieselbe `RulesEngine.abilityModifier` berechnet wie regelgebundene Proben; unbestaetigte/ungueltige Werte bekommen keinen fiktiven Modifikator.
- Widgettest zur Aenderung, negativen Modifikatoren und Leereingabe ergaenzt.
- Basis ist unveraendert der GitHub-main-Commit `3b91a9778abe14184f35ac1db16f5acf121a84b5`. Keine Aenderung am Datenbankschema, Backend, Charakter-Speicherformat oder an bestehenden Charakterwerten.
- **Pruefung:** Python-Pakettests und Backend-Tests nach Moeglichkeit lokal; Flutter/Dart und Android SDK sind in dieser Ausfuehrungsumgebung nicht installiert. Neuer GitHub-Actions-Lauf nach Import erforderlich.

# Änderungsprotokoll

## 0.3.3 – Klassenwahl, Fertigkeiten und Startausrüstung (14. Oktober 2026)

- CI-Korrektur (15. Oktober 2026): Ungebundenen Dart-Dokumentationskommentar am Dateianfang von `app/lib/domain/srd_character_classes.dart` in reguläre Kommentare umgewandelt. GitHub-Actions-Lauf 38675268449 scheiterte ausschließlich an `dangling_library_doc_comments`. Flutter-Tests und Android-Build für diesen korrigierten Stand stehen nach Upload noch aus. Keine Änderungen an Spielregeln, Charakterdaten oder SQLite.


- Neue Klasse `SrdCharacterClass` mit den zwölf SRD-5.2.1-Klassen: Trefferwürfel, beide Rettungswurf-Übungen, zulässige Fertigkeitslisten und Auswahlanzahl (2–4) sowie Startpakete bzw. Startgold.
- Neuer Assistent „D&D-Klasse und Fertigkeiten wählen“ im Charaktereditor für Stufe-1-Charaktere. Ungültige oder doppelte Fertigkeitswahlen können nicht übernommen werden.
- Charakterausrüstung mit Inventargegenständen und Startgold kann **optional nur bei neuen noch unversorgten Charakteren** explizit übernommen werden; Wahl wird weder automatisch wiederholt noch Rüstung direkt angelegt.
- Start-TP-Vorschlag aus 0.3.2 im Assistenten nutzbar; vorhandene TP werden nur auf ausdrückliche Bestätigung ersetzt. Bestehende Fertigkeiten und Rettungswürfe bleiben beim Ergänzen erhalten; vollständiger Ersatz ist eine bewusste Option.
- Im neuen Charaktereditor werden freihändige Startattribute bzw. nachträgliche manuelle Änderungen an einer regelkonformen Verteilung nur nach Kennzeichnung als Hausregel gespeichert. Leere noch unbestätigte Attribute und historische/importierte Charaktere bleiben zulässig.
- Neue Domänen- und UI-Tests für sämtliche Klassentabellen, Fertigkeitsvalidierung, Aliasnamen, Altcharaktere und neue UI-Flows.
- Kein neues Backend, keine neuen Laufzeitabhängigkeiten und **keine Änderung am persistenten Charakter-JSON-Schema**. Klasse, Fertigkeiten, Rettungswürfe, Gold und Gegenstände verwenden die bereits vorhandenen Felder.
- Neue 0.3.3-Funktionen in dieser Übergabe **nicht mit Flutter auf Android kompiliert oder auf einem Gerät geprüft**; GitHub Actions führt die verbindlichen Flutter- und Android-Prüfungen nach dem Import aus.


## 0.3.2 – Vorbereitung, 14. Oktober 2026 (Start-Trefferpunkte nach SRD 5.2.1)

- Regelklasse `StartingHitPoints`: maximaler Klassen-Trefferwürfel plus KO-Modifikator für Stufe 1; zwölf SRD-Klassen, mindestens 1 TP.
- Neuer Button „Start-TP nach D&D vorschlagen“ im Charaktereditor mit eigener Vorschau und ausdrücklicher Bestätigung.
- Bisherige, importierte oder historische Trefferpunkte werden nur nach Bestätigung ersetzt; keine automatische Neuberechnung bei höherer Stufe.
- 19 neue Dart-Domänentests und ein Flutter-Widgettest im Quellcode; **Flutter-Test und Android-Build für 0.3.2 noch nicht ausgeführt**.
- Vollständiger Quellstand aus GitHub-Commit `4a8cfe9` geprüft und in das direkt importierbare ZIP integriert. Strukturprüfung und 22 Python-Tests nach Integration bestanden.
- Kein zusätzlicher API-Aufruf, keine neue Laufzeitabhängigkeit, keine SQLite-Schemaänderung.


## 0.3.1 — 14. Oktober 2026 (Sprache und CI; Backend bleibt 0.2.0)

- Abgewiesene TTS-Kommandos (0/false) werden als Fehler behandelt. Fehlgeschlagene Stimmwahl speichert keine ungültige Auswahl; entfernte Stimmen fallen bei der Neusuche auf einen verfügbaren deutschen Standard zurück.
- Deutsche Stimm-IDs normalisiert verglichen, native IDs erhalten, doppelte/fehlerhafte und als nicht installiert gemeldete Einträge entfernt. Anbieter-Metadaten für lokale und Netzwerkstimmen sichtbar.
- Stimmensuche ohne Mikrofonzugriff, Anbieter- und Locale-Anzeige, verständliche Paket-/Verbindungsfehler und unterbrechbare Ausgabe. Auswahl auf 360 px mit bis zu doppelter Schriftgröße geprüft.
- Hängende Android-Sprachabfragen und Wiedergabe begrenzt; unvollständige Erkennungsliste erlaubt ausdrücklichen de-DE-Versuch. Fehler-/Abbruchcallbacks geben lokale Wartevorgänge frei; keine automatische Mikrofonwiederholung.
- App-Start wartet auf lokale Spielstände, während der Sprachdienst danach unabhängig geprüft wird. Startprüfung mit echter SQLite-Datenbank und offener nativer Stimmabfrage ergänzt.
- Repositorystand erstmals gelesen und mit 0.3.0 verglichen: Dateiinhalte identisch, vier Ausführungsrechte verschieden. GitHub-Job bestätigt fehlendes sdkmanager nach erfolgreichen Tests; explizite Commandline-Tools-Installation in CI ergänzt. Git- und Connector-Schreibversuche weiterhin403, daher ZIP-Übergabe.
- Benutzerbericht zum App-Betrieb auf Samsung Galaxy S26 Ultra dokumentiert. Genaue betroffene Sprache/Anbieterfunktion bleibt offen; Sprachkorrektur auf dem Gerät separat abnehmen. Hauptsprache weiterhin Deutsch.

254 Flutter-Tests einschließlich 31 Sprachcontroller-, 7 neuen Einstellungen-
und 1 Starttest sowie 22 Backend- und 22 Python-Tests bestanden. Analyse ohne
Befunde, Backend- und universeller Debug-Build erfolgreich. Kleine APKs und
Übergabenachweise: DEVELOPMENT_STATUS.md.

## 0.3.0 — 14. Oktober 2026 (App; Backend bleibt 0.2.0)

- Explizite Stufe-1-Attributshilfe mit Standardsatz und Punktekauf bis 27 Punkten im Charaktereditor ergänzt.
- Vier SRD-Hintergründe mit erlaubten +2/+1- beziehungsweise +1/+1/+1-Steigerungen. Grundwerte, Boni, Endwerte und Modifikatoren getrennt dargestellt; Boni einmal angewendet.
- Vorhandene Werte benötigen Bestätigung zum Ersetzen. Öffnen/Abbrechen erhält historische und noch ungespeicherte Angaben.
- Nur Attribute und die gewählte Hintergrundbezeichnung werden übernommen; Talente, Fertigkeiten, Ausrüstung und Klassenwerte bleiben gesonderte Aufgaben. Keine Schemaänderung.
- Regeln anhand offizieller englischer/deutscher SRD 5.2.1-Quellen geprüft; 24 Domain-, 7 echte SQLite- und 13 neue Widgettests ergänzt und gezielt bestanden. Gesamter Check mit 222 Flutter-, 22 Backend- und 22 Python-Tests sowie Analyse und universeller Debug-Build erfolgreich. Drei optimierte Alpha-APKs gebaut, Metadaten/ABI und gleiche lokale Testsignatur geprüft. Geräteabnahme bleibt offen.

## 0.2.3 — 14. Oktober 2026 (Übergabe und Download; Backend bleibt 0.2.0)

- Quell-ZIP wahlweise ohne äußeren Dnd-Ordner; Byte-Erhalt, Dateiausschlüsse und sichere Paketpfade durch sechs Tests abgesichert.
- Projektprüfung vor SDK-Installation für fehlende/verschachtelte Dateien, Lockdateien, beschädigten Gradle-Wrapper und falsche Zeilenenden; 16 Regressionstests ergänzt.
- Kleine optimierte Alpha pro ARM64, ARM32 und x86_64 mit normalem Buildcode 5 sowie gleicher lokaler Testsignatur gebaut. Kein Store-Release. Dateien liegen jeweils unter 25 MiB.
- Kleine Alpha-Artefakte zusätzlich zur universellen Debug-APK in CI vorbereitet; 30 Tage Aufbewahrung.
- GitHub-Zugriff erneut überprüft: richtiger Benutzer ManuEtt, keine sichtbare App-Installation, Repository404 und Git403. Uploadursache ohne konkreten Fehlertext nicht als bestätigt behandelt.
- Upload-, Download- und Verbindungsanleitungen für die tatsächlichen Einschränkungen ergänzt.

## 0.2.2 — 14. Oktober 2026 (App; Backend bleibt 0.2.0)

- Charaktere und Kampagnen direkt als JSON-Dateien über Androids Systemauswahl sichern und öffnen; keine allgemeine Speicherberechtigung.
- Austauschbare Datei-Schnittstelle mit 10-MiB-Grenze, striktem UTF-8, sicheren vorgeschlagenen Dateinamen und verständlichen Fehlern.
- Ausgewählte Importdatei vor ausdrücklicher Bestätigung nur als bearbeitbaren Text anzeigen; Abbruch und Fehler erhalten bestehende SQLite-Daten. Zwischenablage bleibt verfügbar.
- 21 Kanal-/Sicherheitstests und 13 Datei-Widgettests ergänzen die Prüfung: 178 Flutter-Tests und Codeanalyse bestanden; Android-Debug-Build 0.2.2+4 erfolgreich. 12 native JVM-Tests für begrenztes I/O, Namen, Streamschluss und Abbruch bestanden; CI-Schritt ergänzt. Echte Dateiauswahl auf einem Gerät noch offen.

## 0.2.1 — 14. Oktober 2026 (App; Backend bleibt 0.2.0)

- Relevante bestätigte Erinnerungen für Backend-Erzählungen nach deutschen Worttreffern, NPC-Lebenszuständen, Queststatus und Inventarmengen ausgewählt.
- Unabhängige kurze Fakten und Flags bleiben beim Deduplizieren erhalten; Texte werden Unicode-sicher auf den erlaubten Kontext begrenzt.
- 13 neue Abruf-/Konsistenztests und ein Controller-Test mit mehr als 100 irrelevanten Fakten ergänzen die Prüfung: 144 Flutter-Tests, Analyse und Android-Debug-Build erfolgreich.

## 0.2.0 — 14. Oktober 2026

- Optionalen HTTPS-Backend-Erzähler mit temporärem Sitzungstoken, ausdrücklicher Kostenfreigabe und Anfragenversuchslimit in die App integriert.
- Backend-Sitzung ohne Modellaufruf prüfbar; neue Server-CLI zur Ausstellung kurzlebiger Tokens und Einrichtungshinweise ergänzt.
- Lokale Regelaktionen bleiben maßgeblich. Nur freie Erzählung und zugehöriger Checkpoint werden ersetzt; Ausfall, Tokenablauf und unzulässige Antworten führen zur lokalen Demo zurück.
- Fehler beim Ereignis-Replay behoben: Die Reihenfolge von JSON-Objektschlüsseln beeinflusst die Duplikatprüfung nicht mehr. Veränderte Werte und Listen werden weiter abgewiesen.
- Backend-Einstellungen, kleine Displays, Kostenfreigabe, echte lokale Node-/Dart-Kommunikation und Geheimnisfreiheit im SQLite-Speicher zusätzlich geprüft.

130 Flutter-Tests einschließlich echtem lokalem Protokolltest, 22 Backend-Tests, Codeanalyse und Android-Debug-Build bestanden. Ausstehende Backendanfragen lassen sich sofort trennen. Gerätetests bleiben separat offen. Details stehen in `DEVELOPMENT_STATUS.md`.

## 0.1.0 — 13. Oktober 2026

Eigenständiger Alpha-Projektstand zur ZIP-Übergabe für `ManuEtt/Dnd`. Ein Vergleich mit bestehendem Repositorycode war mangels Zugriff noch nicht möglich.

- Flutter-/Android-App mit Fantasy-Farben, Navigation, Charaktereditor, Abenteuer, Journal, Kampfgrundansicht und Einstellungen ergänzt.
- Deterministischen lokalen Spielleiter sowie Demo „Das Licht von Mooswacht“ mit Liora, Schlüssel, Waldschrein und einfacher Begegnung implementiert.
- Historische Kampagne „Das Herz der Ewigkeit“ als importierbaren Zustand mit ausdrücklich unvollständigem Arescan-Bogen ergänzt. Werte 19, 14 und der ungeprüfte Modifikator +7 bleiben historische Daten.
- Würfelregeln mit getrennten natürlichen Ergebnissen und Gesamtergebnissen, Angriffen, Schaden, Heilung und Todesrettung ergänzt.
- SQLite-Transaktionen für Charaktere, Kampagnensnapshots, Ereignisse und Revisionsjournal sowie JSON-Export/-Import eingerichtet.
- Grundlegende Kurzzeit-, Sitzungs- und Langzeitkontexte sowie Ereignisrekonstruktion ergänzt.
- Deutsche Gerätespracherkennung, bearbeitbares Transkript und unterbrechbare TTS integriert; Geräteprüfung steht noch aus.
- Optionales Fastify-/TypeScript-Backend mit validierter Erzähl-API, signierten Read-only-Sitzungstokens, Nutzungslimits und kostenlosem Mock eingerichtet. OpenAI Responses ist serverseitig optional; die mobile App nutzt weiterhin den lokalen Spielleiter.
- GitHub Actions für Backend- und Flutterprüfungen sowie Debug-APK eingerichtet.
- Architektur-, Status-, Test- und Übergabedokumentation sowie die geforderte SRD-5.2.1-Namensnennung ergänzt.

Erfolgreich geprüft: Flutter-Analyse ohne Befunde, 74 Flutter-Tests, 17 Backend-Tests und ein Android-Debug-APK-Build. Eine Prüfung auf einem echten Android-Gerät steht noch aus.

Überprüfte Ergebnisse stehen in `DEVELOPMENT_STATUS.md`. Vollständige SRD-Charakterbaulogik, öffentlicher Mehrspielerbetrieb, mobiler Realtime-WebRTC-Pfad, vollständige Erinnerungsverdichtung und weitere Plattformabnahmen bleiben offen.
