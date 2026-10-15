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
