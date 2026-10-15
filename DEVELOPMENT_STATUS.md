## Aktueller Stand: 0.4.0+16 (vollständiger UI-Redesign-Stand)

Die deutsche Dark-Fantasy-Designsprache des Charakterbogens ist im existierenden App-UI vereinheitlicht. Status: vollstaendiges Quellcode-Inkrement für GitHub-Import, **nicht als grüner Flutter-/Android-Build nachgewiesen**. In dieser Umgebung bestanden die Strukturprüfung und 22 Python-Tests. Die Widgettests und Android-APK müssen in GitHub Actions laufen. Siehe `docs/UI_DESIGN_SYSTEM.md`.

## Status 0.3.9+15 – Oberflächengestaltung (15.10.2026)

**Integriert:** Neue native, responsive Flutter-Charakterbogenansicht mit vollständigen deutschen Labels und drei Bereichen; App-Farb- und Typografie-Thema angepasst. Einstieg aus Heldenliste und aktiver Kampagne, Weiterleitung zum bisherigen Editor. Kein geändertes Speicherformat, keine Hintergrundmigration, keine neuen Laufzeitabhängigkeiten. Das Mockup ist eine visuelle Referenz; die Android-App zeigt weiterhin echte, gespeicherte Daten.

**Ausstehend:** Flutter-/Dart-Analyse, vollständige Widgettests, Android-APK-Build, Smartphone-Abnahme und Prüfung des Designs mit Schriftgrößen-/Barrierefreiheitseinstellungen. Der jüngste GitHub-Workflow von `125fc3630722002a955a4e3479395edd6bfb6635` stoppte im Backend-Test durch eine veraltete Versionserwartung `0.3.0` statt `0.3.1`; diese Assertion ist in dieser ZIP korrigiert. CI muss diesen und die neuen UI-Tests bestätigen.

## 0.3.8+14 – 15.10.2026 – spielbare dynamische Abenteuer und geprüfte KI-Angebote

- Narrative KI kann **genau eine optionale spielbare Herausforderung** pro Antwort vorschlagen, mit Quest, Begegnung und lokal ausgewähltem Gegnerprofil oder einer Wahrnehmungsaufgabe. KI-Daten werden auf Backend und Gerät validiert; der Provider kann keine Regel- oder Inventarwerte setzen.
- Neue Karten im Abenteuer: Angebot annehmen oder risikofrei verwerfen. Annahme startet einen lokal ausgewürfelten Einzelkampf oder eine Wahrnehmungsprobe SG 10, jeweils mit eigener Quest und atomarem Ereignis.
- Ein bestätigter Sieg/Erkundungserfolg schließt die verknüpfte Quest ab und vergibt eine **einmalige, nichtmagische Beute** aus der lokalen Tabelle; bei Fehlschlag/Flucht keine Beute. Keine EP- oder Gold-Buchung, keine unbestätigte Ausrüstung.
- Story-Fortschritt, Kampagnen-Journal, SQLite/JSON-Sicherung, bestehende Sprach- und Erzählfunktion bleiben angebunden; alte `schemaVersion:1`-Spielstände sind kompatibel. Neues optionales `adventureOffer`-Objekt.
- Korrektur des bisherigen CI-Blockers: Fastify-`preHandler` jetzt mit echten `FastifyRequest`/`FastifyReply`-Typen statt nichtkompatibler selbst gebauter Request-/Reply-Typen.
- Isolierte TypeScript-Prüfung des Abenteuer-Validators und Mock-Antworten, 22 Python-Pakettests, ergänzte Dart- und Backend-Tests. Flutter und vollständiges npm-Backend mangels lokalem SDK/offline-Abhängigkeiten **noch nicht bestätigt**. **Kein offizieller grüner Build dieses Stands**.
- Aktuelle Grenzen sind in [docs/AI_ADVENTURES.md](docs/AI_ADVENTURES.md) erklärt. **Keine Behauptung einer vollständig implementierten D&D-5e-Regelengine.**

## 0.3.7+13 – KI-Kampagnen (15.10.2026)

Die neue Funktion erfordert einen verbundenen Backend-Erzähler. Im Testmodus erzeugt der Mock lediglich eine feste Story-Variante; kreative Kampagnen benötigen den ausdrücklich genehmigten OpenAI-Anbieter (`AI_PROVIDER=openai`, `ALLOW_PAID_AI=true`, serverseitig API-Key und Modell). Die App verbraucht pro Start und freiem Zug eine freigegebene Backend-Anfrage, zählt sie lokal mit und nutzt serverseitige Limits. Bei Abbruch bleibt der letzte bestätigte Spielstand erhalten.

Aktuelle Grenzen: kein autonomes Training der Modellgewichte, keine Live-Sprach-KI, kein KI-berechneter Kampf und keine garantierte Korrektheit freier KI-Prosa. Stattdessen kontextbasierte Story-Entwicklung aus persistenter Story-Bibel, NPC- und Handlungsstrangstatus und begrenzten früheren Entscheidungen. Die „geheime“ Wendung bleibt im lokalen gespeicherten Story-Kontext und damit beim Export sichtbar.

Grundlage: Repository `main` Commit `ea486481d28856228abf65dd209857028b3b3c45`. Dieser Stand scheiterte im CI mit 299 erfolgreichen und 2 fehlerhaften Flutter-Tests (Widget-Selektor / Tagebuch-Scrollen); die betreffenden Tests wurden im Quellpaket korrigiert. Die Korrekturen sind mangels Flutter noch nicht in CI bestätigt. Vor Übergabe lokal 22 Python-Tests und TypeScript-Syntax erfolgreich; vollständige Test- und APK-Abnahme ausschließlich in GitHub Actions.

## 0.3.6+12 – Erweiterung des Kampagnengedächtnisses (15.10.2026)

**Implementiert:** Drei neue Bereiche im Tagebuch für speicherbare Sitzungsschnappschüsse, Status und Beschreibung offener Handlungsstränge sowie protokollierte NPC-Beziehungen. Alle Änderungen erfordern eine Benutzeraktion. Neue Ereignistypen `memory.sessionRecapSaved`, `memory.npcRelationshipRecorded`, `memory.storyThreadSaved`; Änderungen liegen im bestätigten SQLite-Revisionsjournal und JSON-Export. Die lokale Erinnerungssuche berücksichtigt diese Einträge. Automatische generative Lore- und Beziehungsentscheidungen bleiben ausgeschlossen.

**Kompatibilität:** Alte `schemaVersion: 1`-Kampagnen dürfen die neuen optionalen Felder weglassen; dann werden leere Sammlungen angenommen. Keine SQLite-Migration und keine neuen Laufzeitabhängigkeiten. Maximal 60 Zusammenfassungen, 100 Handlungsstränge, 300 Beziehungseinträge sowie strenge Text-/Statusvalidierung. Es handelt sich um benutzergeführte Notizen, nicht um eine autonome semantische Gedächtnis-KI.

**Bekannter Vorfehler:** GitHub Actions für `6e967080baba7de252fac378d51758a20f6556ae` (`https://github.com/ManuEtt/Dnd/actions/runs/38683059572/job/116251682233`) zeigte erfolgreiche Analyse und 290 bestandene Flutter-Tests, aber einen Hit-Test-Fehler in `ui_app_test.dart` beim Button „Vervollständigen“ auf 360 px. Der Test scrollt nun kontrolliert zu diesem Button. Kein neuer GitHub-CI-Lauf für die 0.3.6-Änderungen erfolgt.

**Prüfungen:** Vollständige Projektstrukturprüfung und 22 Python-Tests erfolgreich. Neue Dart-Domain-, Widget- und SQLite-Testfälle sind im Quellcode vorhanden, jedoch ohne Flutter-SDK in dieser Umgebung noch nicht ausführbar; Android-APK-Build und reale Geräteabnahme stehen aus.

**Basis:** GitHub `main` Commit `6e967080baba7de252fac378d51758a20f6556ae` (0.3.5+11). Vollständige ZIP-Übergabe, der Hauptbranch wurde nicht verändert.

## 0.3.5+11 – Neues Inkrement (15.10.2026)

**IMPLEMENTIERT:** Lokaler Rückblick via GameEngine/MemoryEngine, thematisch gefilterte bestätigte Erinnerungen für D&D-Kampagnen, Schaltfläche „Rückblick“ mit Erhalt eines ungesendeten Entwurfs, und zustandsabhängige Mira-Antworten im Demo-Abenteuer.

**SICHERHEIT/DATEN:** Abfragen verwenden ausschließlich bereits bestätigte Kampagnenfakten, NPCs, Quests, Inventar und Orte. Unbestätigte Szene-/Nachrichtentexte werden nicht übernommen; Rückblicke verändern weder TP, Würfel, Inventar, Quests noch ausstehende Proben. Speicherung/Import/Export bleiben Version 1; keine neuen Server- oder Netzwerkrechte. Komplexe, freie KI-Erzählungen und semantische Gedächtnissuche sind weiterhin nicht implementiert.

**CODETESTS:** `app/test/memory_recall_test.dart` ergänzt; `app/test/ui_app_test.dart` erweitert. **Vorbereitete** Dart-/Flutter-Tests sind noch keine bestandenen Laufzeittests. Python-Projektprüfungen und Backend-Prüfungen sind separat nach Ausführung zu dokumentieren. Lokale Umgebung hat kein Flutter/Dart-/Android-SDK. GitHub Actions muss die neuen Dart-Tests und APK-Builds nach Import ausführen.

**GITHUB-BASIS:** `239ee5f7d333a6388159e7d431039abb92e936b7` vom 15.10.2026. Keine Änderungen direkt in den Hauptbranch geschrieben; ZIP kann in einem neuen Branch importiert werden. Vor Merge prüfen, ob GitHub seit dem Basisstand weiterentwickelt wurde.

## 0.3.4+10 – Fehlerkorrektur und Attribut-Modifikatorvorschau (15. Oktober 2026)

Basis fuer diesen Quellstand ist der per Git-Tree-SHA bestaetigte main-Commit
`3b91a9778abe14184f35ac1db16f5acf121a84b5`. Dessen GitHub-Actions-Job
`116229696416` schlug im Flutter-Test `new manually changed score requires explicit
house-rule consent` fehl: `scrollUntilVisible` suchte vorwaerts, obwohl die
Hausregel-Checkbox nach einem Speicherversuch oberhalb lag (281 erfolgreich,
1 fehlgeschlagen). Der Test verwendet nun einen negativen Scroll-Schritt.

Weiterentwicklung: Gueltige Attributwerte zeigen ihre regelkonform berechneten
Modifikatoren direkt im Charaktereditor. Vorschau, keine neue Spielzustandsquelle;
bei leeren oder ungueltigen Attributen wird kein Wert angenommen. Ein separater
Widgettest prueft `14/+2`, `9/-1`, Zuruecksetzen auf leer und kein Speichern.

Status: Quellcode integriert, Python-/Backend-Pruefungen separat dokumentiert.
Flutter-Analyse, Widgettests und Android-APK dieser Version sind **nicht**
lokal verifiziert. GitHub-Actions erneut durchlaufen lassen. Bei Erfolg APK
auf einem echten Android-Geraet einschliesslich Import/Export und Sprache pruefen.

## 0.3.3 – CI-Korrektur (15. Oktober 2026)

- Im offiziellen GitHub-Actions-Lauf [38675268449](https://github.com/ManuEtt/Dnd/actions/runs/38675268449) für Commit `02380c2180f98de9a31d1759fee8566d7575f3ce` wurden Projektstruktur, 22 Python- und 22 Backend-Tests erfolgreich geprüft. `flutter analyze` stoppte mit genau einem Dart-Hinweis `dangling_library_doc_comments` in `app/lib/domain/srd_character_classes.dart:1:1`; nachfolgende Flutter-Tests und APK-Builds wurden übersprungen.
- Diese ZIP behebt den Kommentarfehler ohne eine fachliche Codeänderung. Der Korrekturstand muss erneut in GitHub importiert und durch die gesamte Actions-CI geprüft werden. Ein Erfolg der noch ausstehenden Flutter-Tests und APK-Builds wird nicht behauptet.

## 0.3.3 – Stand der ergänzten Klassenwahl, 14. Oktober 2026

- BASIS: vollständig exportierte 0.3.2-Version aus GitHub `4007b2b65f3413238c0a828813d57b98c4498732`, bereits durch Actions für Flutter/Android getestet. Letzter freigegebener Gerätebericht: Attributverteilung, Spracheingabe, Sprachausgabe, Stufe-1-TP funktionieren.
- IMPLEMENTIERT (0.3.3): 12 SRD-5.2.1-Klassenprofile mit Rettungswurf-Übungen, Fertigkeitswahl, optionalem Startpaket/Startgold; UI-Klassenassistent mit Vorschau/Bestätigung, bestehende Werte nicht automatisch überschreiben; neuer manueller Hausregelweg für abweichende Startattribute bei neuen Charakteren. Keine Schema- oder Backend-Änderung.
- SOURCE-QA: neues Paket mit zusätzlichen Unit-/Widgettests; Gesamtprojektstruktur und vorhandene Python-Tests werden vor ZIP-Abgabe separat geprüft.
- OFFEN: Flutter-Analyse, Flutter-Tests und Android-Build für Version 0.3.3 können in der aktuellen Dateiumgebung ohne Flutter-SDK nicht ausgeführt werden. Nach GitHub-Import über Actions prüfen; 0.3.3 nicht bereits als Gerätetest ausgeben.
- REGELGRENZE: keine automatische Hintergrunderfahrung, Klassenmerkmale, aufgenommene Ausrüstung/Rüstungsklasse, Zauberplätze, Level-Ups oder Mehrklassenregeln. Mit zusätzlichen Stufe-1-Klassenübungen werden bestehende Einträge optional zusammengeführt; Ursprung der üblichen Mehrfach-Übungen ist in den bestehenden Listen noch nicht separat nachverfolgbar.

# Entwicklungsstatus

## Entwicklungsinkrement: SRD-5.2.1-Start-Trefferpunkte (0.3.2+8, im Quellstand integriert)

- Neue reine Dart-Regellogik `StartingHitPoints.propose` für die zwölf
  SRD-5.2.1-Klassen (deutsche/englische Namen): Stufe 1 = maximaler
  Klassen-Trefferwürfel + bestätigter Konstitutionsmodifikator, mindestens 1 TP.
- Im Charaktereditor ein separater, ausdrücklich zu bestätigender Vorschlag.
  Abbrechen, unbekannte Werte und Stufen größer 1 ändern keine Charakterwerte.
- Neue Domänen- und Widgettests hinzugefügt; **in diesem Übergabepaket nicht
  ausgeführt**, da die aktuelle Arbeitssitzung keine Flutter-/Dart-Toolchain hat.
- **Vollständiger Quellstand direkt integriert**: Alle 103 Originaldateien aus
  GitHub-main `4a8cfe9` über ihre Git-Blob-SHA geprüft, dazu fünf direkte
  HP-Code-/Test-/Statusänderungen und die Versions-/Dokumentationsaktualisierung.
  Projektstrukturprüfung und 22 Python-Tests erfolgreich.
- **Noch nicht nach GitHub geschrieben**: Die GitHub-Integration verweigert
  Branch-Erstellung mit 403. Nach Import `flutter analyze`, `flutter test`
  und GitHub-CI ausführen; erst danach als getestet melden.
- Nächstes Inkrement: Verteilungsmethode/Basiswerte/Boni persistieren und
  freie Attributbearbeitung bei regelkonform neu erstellten Charakteren
  gegen Umgehung des 27-Punkte-Budgets absichern, Altimporte schützen.

Hinweis zum vorherigen Stand: Der GitHub-Actions-Lauf `38582180726`
auf `4a8cfe9` war tatsächlich erfolgreich: 254 Flutter-Tests, Backend- und
Python-Tests sowie Debug-/ARM64-/ARM32-/x86_64-APKs. Diese Ergebnisse
gelten für 0.3.1, **nicht** als Abnahme des neuen 0.3.2-Codes.

Stand: 14. Oktober 2026. Aktuelle Etappe: App 0.3.1 mit Android-Sprachkorrekturen, Geräte-Rückmeldung und nachgewiesener GitHub-CI-Ursache; autonome Entwicklung mit gesicherten Inkrementen für `ManuEtt/Dnd`.

Der Lesezugriff auf GitHub ist jetzt vorhanden. Der hochgeladene main-Stand
`bc6c942483189acdcd82b37005de1040b49b36b8` stimmt in allen Dateiinhalten mit dem
gesicherten lokalen 0.3.0-Stand überein; nur vier Ausführungsrechte unterscheiden
sich. Der bestehende Actions-Lauf ist geprüft, direkte Schreiboperationen
erhalten weiterhin HTTP 403. Neue Korrekturen sind deshalb zusätzlich als ZIP
zu übernehmen; ein neuer GitHub-Lauf oder Pull Request ist noch nicht bestätigt.

## IMPLEMENTIERT

- Flutter-/Android-Projekt mit Material 3 und deutscher Navigation: Start, Charaktere, Abenteuer, Journal und Einstellungen.
- Flaches Korrektur-ZIP ohne äußeren Dnd-Ordner, Projektprüfung vor SDK-Installation und 22 Python-Paket-/Strukturtests. Kleine optimierte interne Alpha-APKs für ARM64, ARM32 und x86_64, weiterhin mit Testsignatur.
- Explizite Attributstarthilfe: Standardsatz oder Punktekauf bis 27 Punkte, vier SRD-Hintergründe, getrennte Grund-/Bonus-/Endwerte mit Modifikatorvorschau. Bekannte Werte benötigen Ersetzbestätigung; Öffnen/Abbruch bewahrt historische und ungespeicherte Eingaben. Nur Attribute und Hintergrundname werden übernommen.
- Charaktereditor mit nullable, ausdrücklich unbestätigten Werten; JSON-Export/-Import, Kampagnenauswahl und lokale Löschfunktionen. Seit 0.2.2 direkte Android-Dokumentauswahl und Dateisicherung, explizite Importbestätigung sowie Zwischenablage als Fallback.
- Deterministischer deutscher Spielleiter als kostenlose Voreinstellung. Optionaler HTTPS-Backend-Erzähler für freie Texte; lokale Regeln, Würfel und bestätigte Daten bleiben maßgeblich. Anbieterantworten ersetzen ausschließlich die neue Erzählung und ihren Ereignis-Checkpoint.
- Demo „Das Licht von Mooswacht“ in Lunaris mit Liora, Erkundung, Schlüssel, Quest und einfacher Gegnerbegegnung.
- Historischer Arescan-Zustand „Das Herz der Ewigkeit“: bekannte Geschichte, fehlende Attribute, historische Werte 19/14 und ungeprüfter Modifikator +7; keine erfundenen Helden- oder Gegnerkampfwerte.
- Würfel W4/W6/W8/W10/W12/W20/W100, natürliche Ergebnisse getrennt von Gesamtergebnissen, Vorteil/Nachteil und kontrollierbare Zufallsquelle.
- Regelgrundlagen für Attributmodifikatoren, Übungsbonus, Initiative, Angriffe, kritischen Schaden, Trefferpunkte, Heilung und Todesrettung. Demo-Kampf mit automatischer Gegenrunde; kein vollständiges SRD-Kampfsystem.
- SQLite-Schema 1, gemeinsame Speicherung von Snapshot und Ereignissen, Revisionsjournal, Konfliktprüfung, Idempotenz und Wiederherstellung bestätigter Zustände.
- Grundlegender Kurzzeitkontext, faktengestützte Sitzungsübersicht und Langzeitfakten zu NPCs, Quests und Inventar; Checkpoint-Ereignisrekonstruktion.
- Deutsche Systemspracherkennung mit bearbeitbarem Transkript, TTS, Stimmwahl, optionaler automatischer Ausgabe und Unterbrechung. Seit 0.3.1 geprüfte Anbieterergebnisse, deutsche Locale-Rangfolge, deduplizierte Stimmmetadaten und erneute Prüfung ohne Mikrofonzugriff. Fehlende Daten/Netzwerkprobleme erhalten verständliche Meldungen; nicht antwortende Dienste und Wiedergabe haben Zeitgrenzen. Lokale Oberfläche startet vor der Sprachdienstprüfung. Kein automatischer Mikrofon-Neustart.
- Fastify-/TypeScript-Backend mit validierter, ausschließlich erzählender API, eigenen kurzlebigen Read-only-Tokens, In-Memory-Anfragelimits und kostenlosem Mock. Optionaler OpenAI-Responses-Provider ausschließlich serverseitig und mit ausdrücklichem Kosten-Opt-in. Kein Realtime-Token.

Zusätzlich seit 0.2.0: HTTPS-Transport mit begrenzten JSON-Antworten, verweigerten Weiterleitungen, Ablaufprüfung, ausdrücklicher Kostenfreigabe und lokalem Anfragenversuchslimit. Token und Kostenfreigabe werden nicht gespeichert. Sitzungstest per authentifiziertem GET ohne Modellaufruf; neue Server-CLI gibt nur kurzlebige Sitzungstokens aus. Fehler führen ohne automatischen POST-Retry zur lokalen Demo. Ein Replay-Fehler durch unterschiedliche JSON-Objektschlüsselreihenfolge wurde behoben, ohne veränderte Werte oder Listen als identisch zuzulassen. Seit App 0.2.1 wählt MemoryEngine.retrieve bis zu 20 bestätigte Fakten, NPC-, Quest-, Inventar- und Ortsinformationen anhand deutscher Worttreffer und wichtiger Zustände aus. Keine Modelltexte oder Spielerbehauptungen werden als Faktenquelle verwendet; Datenbankschema und Importe bleiben Version 1.

Seit App 0.2.2 trennt BackupFiles die Dateiverarbeitung von Oberfläche und Repository. Die native Android-Brücke verwendet das Storage Access Framework ohne allgemeine Speicherrechte, prüft Dateinamen und tatsächliche Datenmenge bis 10 MiB und arbeitet im Hintergrund. Dart prüft striktes UTF-8 und erlaubt ein anfängliches BOM. Abbruch und Fehler speichern keine Importdaten; Erfolg beim Export setzt einen geschlossenen Stream voraus. Die echte Geräte-Dateiauswahl ist noch nicht abgenommen. Einrichtung und Grenzen: docs/SAVE_BACKUPS.md.

Der Workflow `.github/workflows/android-build.yml`, Projekt- und Übergabedokumentation liegen vor. CI verwendet Flutter 3.35.7, Dart 3.9.2, Java 17 und Node.js 22.14.0.

Seit 0.3.1 installiert CI Android Commandline Tools mit
android-actions/setup-android@v3, festgelegtem Build 12266719, vor dem
sdkmanager-Aufruf. Die Ursache des alten APK-Ausfalls ist durch GitHub-Logs
bestätigt, der korrigierte Workflow bleibt bis zur Übernahme separat zu prüfen.

## GERÄTERÜCKMELDUNG

Der Benutzer berichtet funktionierenden App-Betrieb auf einem **Samsung Galaxy
S26 Ultra**, aber Probleme bei einigen Sprachen. Das ist ein Benutzerbericht,
kein vollständig dokumentierter Entwickler-Gerätetest. App-/Android-/One-UI-
Version, Sprachdienst, genaue betroffene Sprache und Eingabe beziehungsweise
Ausgabe sind noch offen. 0.3.1 verbessert konkrete im Paketcode bestätigte
Fehlerpfade; deren Behebung auf dem Samsung ist noch nicht bestätigt. Die
Hauptsprache ist Deutsch, weitere Spielsprachen sind nicht implementiert.
Anleitung und Diagnosedaten: docs/SPEECH_TROUBLESHOOTING.md.

## GETESTET

Gezielte Sprachprüfung 0.3.1: **31 Controller-Tests** (24 neu) und **7 neue
Widgettests** bestanden, gezielte Analyse ohne Befunde. Geprüft sind 0/false
bei TTS-Kommandos, fehlende/doppelte Stimmendaten, lokale/Netzwerk-Metadaten,
gespeicherte entfernte Stimmen, Wiederholung nach Paketinstallation,
hängende Sprachabfrage/Wiedergabe, Fehlercallbacks, Abbruch und verzögerte
Ergebnisse. Die Einstellungen bestehen auf 360 px mit 1,3- und 2-facher
Schriftgröße. Die neue Startprüfung mit echter temporärer SQLite-Datenbank
zeigt die lokale Oberfläche während einer offenen nativen Stimmabfrage.

Abschließende Prüfungen für 0.3.1: **254 Flutter-Tests** einschließlich lokalem
Node-/Dart-Protokolltest erfolgreich mit Node 22.14.0 und RUN_BACKEND_SMOKE=1;
**22 Backend- und 22 Python-Tests**, Backend-Typecheck/Build und saubere
Flutter-Analyse. Insgesamt 32 neue Flutter-Tests. Universeller Debug-Build
0.3.1+7 erfolgreich; Version, API 24/36 und gleiche lokale Testsignatur geprüft.
Keine kostenpflichtigen Modellaufrufe. Native Dateisicherungsquellen unverändert,
deren bestehender Nachweis bleibt 12 JVM-Tests.

Der reale GitHub-Lauf **38560369343** auf main `bc6c942` besteht Strukturprüfung,
22 Python-, 22 Backend- und 222 Flutter-Tests sowie Codeanalyse. Job
115839661846 scheitert danach beim SDK-Schritt mit **sdkmanager: command not
found**, Exit 127. Alle APK-Schritte sind übersprungen. Dies ist ein tatsächlich
beobachteter Remote-Testlauf, aber kein erfolgreicher Remote-APK-Build.

Gesamter scripts/check.sh-Lauf für 0.3.0 erfolgreich: **222 Flutter-Tests** einschließlich lokalem Node-/Dart-Protokolltest, **22 Backend-Tests**, **22 Python-Paket-/Strukturtests** und Flutter-Analyse ohne Befunde mit der festgehaltenen Toolchain/Node 22.14.0. Zusätzlich nach Ergänzung der beiden neuen Pflichtdateien Python-Prüfer und alle 22 zugehörigen Tests erneut bestanden. 44 neue Flutter-Tests: 24 Domain-Regeltests, 7 echte SQLite-/Controller-Tests und 13 Widgettests. Der Debug-APK-Build 0.3.0+6 ist erfolgreich, Metadaten und Testsignatur geprüft.

Die Regeltests prüfen alle 720 Standardsatz-Zuweisungen, Punktekostentabelle, Budget und jede erlaubte Hintergrundsteigerung. Die UI-Prüfung umfasst 360 px, explizite Auswahl, Restpunkte, Basis-/Bonusvorschau, Modifikator 17→+3, Bestätigung und Abbruch. SQLite prüft Neustart/Export/Import, keine doppelten Boni, Arescan 19/14 und unbestätigten +7 sowie unveränderte Welt-/Inventardaten und ungültig gewordene alte Würfelproben. Ein echter später SQLite-Triggerfehler bestätigt vollständigen Rollback von Ereignis/Snapshot und Anzeige; erneutes Speichern gelingt. Statische zusätzliche Regel-/UI-Prüfung ohne Blocker. Kein realer Geräte-/Sprach-/GitHub-Test dadurch behauptet.

Erneuter kompletter scripts/check.sh-Lauf für 0.2.3 erfolgreich: Projektstrukturprüfung, **22 Python-Paket-/Strukturtests**, Backend-Typecheck/Build und **22 Backend-Tests** mit Node.js 22.14.0, saubere Flutter-Analyse sowie **178 Flutter-Tests** mit RUN_BACKEND_SMOKE=1. Neue Tests prüfen beide ZIP-Wurzeln, Byte-Erhalt, Geheimnis-/Cache-Ausschluss, Symlinkablehnung, unvollständige Uploads, Gradle-JAR-CRC und Unix-Zeilenenden. Keine kostenpflichtigen Modellaufrufe.

Drei optimierte Alpha-APKs lokal erfolgreich gebaut und geprüft: arm64-v8a 17.382.068 Byte, armeabi-v7a 14.861.712 Byte, x86_64 18.554.326 Byte. Alle Version 0.2.3, Buildcode 5, API 24+, richtige ABI und gleiche verifizierte lokale Debug-Testsignatur wie die bisherige 0.2.2-APK. Je ABI --target-platform verwendet, damit keine ABI-Codeoffsets spätere Updates verhindern. Kein Store-Release. ARM64 und ARM32 privat auf Google Drive erstellt und per Metadaten mit korrekter Größe/MIME/Owner-Recht gelesen; ARM64 zusätzlich über die Drive-Download-API abgerufen und byteidentisch per SHA-256 mit dem Original verglichen. Der Benutzerdownload und die Installation auf einem echten Gerät bleiben separat abzunehmen.

Flutter 3.35.7/Dart 3.9.2: Codeanalyse ohne Befunde und **178 Tests bestanden** mit RUN_BACKEND_SMOKE=1. Enthalten sind 74 bisherige Tests, 23 Transporttests, 13 Erzähl-/Replay-Tests, 13 SQLite-/Backend-Controller-Tests, 7 Backend-Widgettests, 13 Abruf-/Konsistenztests, 21 Dateikanal-/UTF-8-Tests, 13 Datei-Widgettests und ein echter lokaler Protokolltest. Der aktuelle Gesamtlauf verwendet Node 22.14.0 auch für den realen Protokolltest. Der Protokolltest startet den kompilierten Node-Server, stellt mit der Server-CLI einen synthetischen Sitzungstoken aus und prüft Dart-Transport, Backend-Erzählung, SQLite-Bestätigung und den Rückfall nach Serverabschaltung. Er verwendet ausschließlich lokale Mock-Dienste und Testdaten.

Backendquellen unverändert seit 0.2.0: Typecheck, Produktionsbuild und **22 Tests** erfolgreich mit Node.js 22.14.0 und 24.19.0. Geprüft sind neue Sitzungsprüfung, verbindliches outcome, Provider-/Tool-Abweisung, Authentifizierung, Eingabevalidierung, Nutzungslimits und sichere Fehler. Die historischen 0.1.0-Prüfungen und Quellenangaben bleiben im Änderungsprotokoll nachvollziehbar. Es wurden keine kostenpflichtigen Modellaufrufe ausgeführt.

Native Android-JVM-Prüfung mit Java 17 und Gradle 8.12: **12 Tests bestanden**, keine Fehler, keine übersprungenen Fälle. Geprüft sind reale Byte-Grenze statt Provider-Metadaten, Dateinamen, Lesen/Schreiben, Streamschluss und I/O- beziehungsweise Abbruchfehler. Lebenszyklus und SAF-Ergebniszustellung sind statisch geprüft, nicht durch diese JVM-Tests oder auf einem Gerät nachgewiesen.

Die Abschlusskorrektur ist ebenfalls abgenommen: Trennung und Dispose beenden ausstehende Backend-Wartevorgänge sofort; aktive HTTP-Verbindungen werden geschlossen, und verspätete Antworten bleiben wirkungslos. Der Abbruchknopf ist während einer laufenden Anfrage bedienbar. Bereits ausgelöste Anbieteraufrufe werden dadurch nicht automatisch erstattet.

## NICHT GETESTET

- Vollständig dokumentierter End-to-End-Ablauf auf einem echten Android-Gerät, einschließlich neuer Attributshilfe mit großer Schrift/Screenreader; Benutzer meldet App-Betrieb auf Samsung Galaxy S26 Ultra.
- Echte Android-Dokumentauswahl, Dokumentanbieter, Berechtigungsübergabe, Schreibfehler und Aktivitätsende während einer Dateisicherung. Die Dateibrücke ist kompiliert; Dart-Kanal, Oberfläche und native I/O-Helfer werden getrennt automatisiert geprüft.
- Deutsche Mikrofoneingabe und Sprachausgabe mit einem konkreten Android-Sprachanbieter.
- Unterbrechung, Berechtigungsablehnung und Ausfall von echten Gerätesprachdiensten; die zugehörige App-Logik ist mit Mocks getestet.
- GitHub-Actions-Lauf mit der SDK-Korrektur 0.3.1 und Herunterladen eines neuen APK-Artefakts; bisheriger Lauf scheitert nach erfolgreichen Tests.
- Reale, kostenpflichtige OpenAI-Aufrufe und eine mobile HTTPS-Verbindung zu einem produktiven Server.

## BLOCKIERT

- Direkte Übertragung der Änderungen: Lesen funktioniert, tatsächlicher Push auf fix/android-voice-reliability erhält HTTP 403 „Permission to ManuEtt/Dnd.git denied to ManuEtt“. Connector-Branchanlage erhält ebenfalls403 „Resource not accessible by integration“. Allgemeines push:true in Repository-Metadaten bestätigt nicht die Integrationsberechtigung. ZIP und docs/UPLOAD_TO_GITHUB.md ermöglichen die Übernahme durch den Eigentümer. Actions-Ursache ist inzwischen bestätigt und lokal korrigiert.
- Eine vollständige Prüfung auf einem Android-Gerät benötigt ein Gerät beziehungsweise einen geeigneten Emulator mit Sprachdiensten.
- Produktive KI-Anbindung benötigt sichere Serverkonfiguration und Anbieterzugang; der Demo-Modus bleibt unabhängig davon.

## NOCH NICHT IMPLEMENTIERT

- Vollständiges SRD-5.2.1-Regelsystem einschließlich regelkonformer automatischer Charaktererstellung, aller Klassen, Zauber, Ressourcen, Bonus- und Reaktionsaktionen sowie automatischem Stufenaufstieg.
- Regelkonforme Fortsetzung des historischen Arescan-Kampfs bei weiterhin unbekannten Gegnerwerten.
- Durchgängiger geprüfter mobiler OpenAI-Realtime-WebRTC-Sprachpfad und Ausstellung von OpenAI-Realtime-Credentials.
- Öffentlicher Mehrspielerdienst, PostgreSQL-Synchronisierung und Benutzerverwaltung.
- Vollständige mehrstufige Erinnerungsverdichtung und semantische Langzeitabrufe.
- Automatische sichere Sitzungserneuerung; Tokens müssen derzeit nach Ablauf neu ausgestellt werden.
- Signierter Veröffentlichungsbuild und Store-Veröffentlichung.
- Abgenommene Windows- und iOS-Versionen.

## Letzter Build und nächste Aufgabe

**App 0.3.1+7: universeller Android-Debug-Build erfolgreich**, API 24+, Ziel 36,
gleiche Paket-ID und verifizierte lokale Testsignatur wie 0.3.0. Drei optimierte
Alpha-APKs erfolgreich gebaut und geprüft: ARM64 17.447.960 Byte, ARM32
14.927.604 Byte, x86_64 18.685.754 Byte. Alle normaler Buildcode 7, richtige ABI,
gleiche lokale Testsignatur; neue Sprachtexte im kompilierten AOT-Code geprüft.
Toolchain unverändert;
kein Entwickler-Gerätetest und kein erfolgreicher neuer Remote-APK-Build.

**App 0.3.0+6: universeller Android-Debug-Build erfolgreich**, API 24+, Ziel 36, gleiche Paket-ID, Metadaten und Debug-Signatur geprüft. Drei optimierte kleine Alpha-APKs wurden mit normaler Buildnummer 6 erstellt und per Metadaten, Architektur und gleicher lokaler Testsignatur geprüft; alle unter 25 MiB. Toolchain unverändert wie im historischen Debugnachweis unten; letzte Gerätemessung weiterhin nicht vorhanden.

**App 0.2.3+5: drei optimierte kleine Alpha-APKs erfolgreich gebaut**, Release-AOT mit interner Debug-Testsignatur; Toolchain wie im folgenden Debugnachweis. Die CI-Konfiguration baut zusätzlich weiterhin die universelle Debug-APK, prüft die Struktur früh und hält die kleinen Artefakte 30 Tage bereit. YAML und lokale Befehle sind geprüft; der tatsächliche GitHub-Lauf ist weiterhin blockiert.

**App 0.2.2+4: Android-Debug-Build erfolgreich** mit Flutter 3.35.7/Dart 3.9.2, Temurin-JDK 17.0.20.1, Gradle 8.12, AGP 8.9.1, Kotlin 2.1.0, SDKs 34/35/36, Build Tools 35.0.0, NDK 27.0.12077973 und CMake 3.22.1. Paket-ID `de.aetheria.lebendiger_spielleiter`, Android ab API 24 (7.0), Ziel-API 36. APK-Metadaten (Version 0.2.2, Code 4), erforderliche Rechte und Debug-Signatur wurden geprüft. Keine allgemeine Speicherberechtigung hinzugefügt. Die Debug-Signatur entspricht der vorherigen 0.2.0-APK; ein Update ist damit grundsätzlich möglich, aber noch nicht auf einem Gerät geprüft. Der abschließende Build nach Dateiintegration war erfolgreich.

Anfangs fehlten ein vollständiger Java-Compiler, die Sprachplugin-SDKs und CMake. Diese Entwicklungswerkzeuge wurden installiert. Proxy-/CA-Vertrauen wurde ausschließlich in der lokalen Cloud-Werkzeugumgebung konfiguriert, ohne TLS-Prüfung zu deaktivieren. Lokale Werkzeugpfade und Cloud-Konfiguration gehören nicht zum ZIP. Die CI installiert die benötigten SDK-Komponenten ausdrücklich. Der erfolgreiche lokale Build ist **kein** ausgeführter GitHub-Actions-, Emulator- oder Gerätetest.

## Gesicherter Stand und Fortsetzung

- Letzter gesicherter Funktionsstand: `07c98db` (0.3.1), davor `8dc38b6` für CI-Werkzeuge. Branch `fix/android-voice-reliability` basiert auf dem tatsächlich gelesenen GitHub-main `bc6c942`; keine fremden Dateiinhalte überschrieben. Die frühere unabhängige Historie bleibt lokal als feat/solo-alpha erhalten. Abschließende Dokumentationscommits stehen im tatsächlichen Git-HEAD.
- Zuletzt fertiggestellt: Sprachkorrekturen, robuste Einstellungen und unabhängiger lokaler App-Start 0.3.1; fehlendes sdkmanager als echte CI-Ursache korrigiert. 254 Flutter-, 22 Backend- und 22 Python-Tests, Analyse und Debug-/drei optimierte APK-Builds erfolgreich. Bestehende native I/O-Tests bleiben 12 bestanden, unveränderter Code.
- Aktueller Abschluss: Code, Anbieterfehler und Historie geprüft; lokale APKs mit Version/Architektur/Signatur und neuen Sprachtexten im AOT-Code abgenommen. ARM64 und ARM32 privat auf Drive erstellt und per Größe/MIME/Rechten bestätigt. ARM64 erneut heruntergeladen und byteidentisch per SHA-256 geprüft. Flaches Quell-ZIP enthält 103 Dateien; Webupload in mindestens zwei Stapeln. Keine Schemaänderung, neue Laufzeitabhängigkeit oder kostenpflichtige Modellaufrufe. ZIP-Prüfung und endgültige Downloadlinks/Prüfsummen im externen Checkpoint.
- Bekannte Grenzen: genaue betroffene Sprache und Android-Anbieter unbekannt; Samsung-Sprachkorrektur nicht am Gerät bestätigt. Native TTS-Callbacks besitzen keine Wiedergabe-ID, sehr späte Ereignisse lassen sich deshalb nicht perfekt zuordnen. Kein automatischer Token-Refresh, kein vollständiges Regelwerk, keine abgenommenen produktiven OpenAI-/neuen Actions-APK-Tests. Bestätigte Spielstände bleiben in den ausgeführten Tests erhalten.
- Nächster konkreter Schritt: 0.3.1 auf dem Samsung getrennt für Erkennung und Vorlesen prüfen und ZIP mit CI-Korrektur übernehmen; neuen GitHub-Lauf/Artefakte abnehmen. Ohne Geräte-/Schreibzugriff anschließend Stufe-1-Trefferpunkte aus ausdrücklich gewählter Klasse und bestätigtem Konstitutionsmodifikator vorschlagen: vorher offizielle SRD-Quellen lesen, historische Werte erhalten, Vorschlag/Bestätigung/Persistenz testen.
- Übergabepakete: Dnd-Projekt-0.3.1.zip mit Dateien direkt in der Wurzel sowie Der-lebendige-Spielleiter-0.3.1-arm64.apk/arm32.apk. Externer Dnd-0.3.1-status.json erfasst abschließenden Git-HEAD, SHA-256 und bestätigte private Drive-Links. Alte Übergabepakete bleiben erhalten.
- Der tatsächliche Git-HEAD wird vor jeder Fortsetzung mit `git log -1 --oneline` geprüft. Keine zusätzlichen Credits oder Limit-Zurücksetzungen wurden ausgelöst. Ein erkennbares Kontingentlimit wird nicht aus nicht vorhandenen Messwerten abgeleitet.
