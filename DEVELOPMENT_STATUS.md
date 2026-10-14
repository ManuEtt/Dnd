# Entwicklungsstatus

Stand: 14. Oktober 2026. Aktuelle Etappe: App 0.3.0 mit geprüfter SRD-Attributstarthilfe; Attributshilfe und kleine APKs geprüft; Übergabe gesichert; autonome Entwicklung mit gesicherten Inkrementen für `ManuEtt/Dnd`.

Die vorhandene GitHub-Codebasis war während der Entwicklung nicht verfügbar. Dieses Paket wurde neu aufgebaut und noch nicht mit einer älteren Repositoryversion verglichen. Ein Push, ein Pull Request und eine Ausführung des Workflows auf GitHub sind deshalb nicht Bestandteil des nachgewiesenen Stands.

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
- Deutsche Systemspracherkennung mit bearbeitbarem Transkript, TTS, Stimmwahl, optionale automatische Ausgabe und Unterbrechung. Tatsächliche Gerätefunktion noch nicht geprüft.
- Fastify-/TypeScript-Backend mit validierter, ausschließlich erzählender API, eigenen kurzlebigen Read-only-Tokens, In-Memory-Anfragelimits und kostenlosem Mock. Optionaler OpenAI-Responses-Provider ausschließlich serverseitig und mit ausdrücklichem Kosten-Opt-in. Kein Realtime-Token.

Zusätzlich seit 0.2.0: HTTPS-Transport mit begrenzten JSON-Antworten, verweigerten Weiterleitungen, Ablaufprüfung, ausdrücklicher Kostenfreigabe und lokalem Anfragenversuchslimit. Token und Kostenfreigabe werden nicht gespeichert. Sitzungstest per authentifiziertem GET ohne Modellaufruf; neue Server-CLI gibt nur kurzlebige Sitzungstokens aus. Fehler führen ohne automatischen POST-Retry zur lokalen Demo. Ein Replay-Fehler durch unterschiedliche JSON-Objektschlüsselreihenfolge wurde behoben, ohne veränderte Werte oder Listen als identisch zuzulassen. Seit App 0.2.1 wählt MemoryEngine.retrieve bis zu 20 bestätigte Fakten, NPC-, Quest-, Inventar- und Ortsinformationen anhand deutscher Worttreffer und wichtiger Zustände aus. Keine Modelltexte oder Spielerbehauptungen werden als Faktenquelle verwendet; Datenbankschema und Importe bleiben Version 1.

Seit App 0.2.2 trennt BackupFiles die Dateiverarbeitung von Oberfläche und Repository. Die native Android-Brücke verwendet das Storage Access Framework ohne allgemeine Speicherrechte, prüft Dateinamen und tatsächliche Datenmenge bis 10 MiB und arbeitet im Hintergrund. Dart prüft striktes UTF-8 und erlaubt ein anfängliches BOM. Abbruch und Fehler speichern keine Importdaten; Erfolg beim Export setzt einen geschlossenen Stream voraus. Die echte Geräte-Dateiauswahl ist noch nicht abgenommen. Einrichtung und Grenzen: docs/SAVE_BACKUPS.md.

Der Workflow `.github/workflows/android-build.yml`, Projekt- und Übergabedokumentation liegen vor. CI verwendet Flutter 3.35.7, Dart 3.9.2, Java 17 und Node.js 22.14.0.

## GETESTET

Gesamter scripts/check.sh-Lauf für 0.3.0 erfolgreich: **222 Flutter-Tests** einschließlich lokalem Node-/Dart-Protokolltest, **22 Backend-Tests**, **22 Python-Paket-/Strukturtests** und Flutter-Analyse ohne Befunde mit der festgehaltenen Toolchain/Node 22.14.0. Zusätzlich nach Ergänzung der beiden neuen Pflichtdateien Python-Prüfer und alle 22 zugehörigen Tests erneut bestanden. 44 neue Flutter-Tests: 24 Domain-Regeltests, 7 echte SQLite-/Controller-Tests und 13 Widgettests. Der Debug-APK-Build 0.3.0+6 ist erfolgreich, Metadaten und Testsignatur geprüft.

Die Regeltests prüfen alle 720 Standardsatz-Zuweisungen, Punktekostentabelle, Budget und jede erlaubte Hintergrundsteigerung. Die UI-Prüfung umfasst 360 px, explizite Auswahl, Restpunkte, Basis-/Bonusvorschau, Modifikator 17→+3, Bestätigung und Abbruch. SQLite prüft Neustart/Export/Import, keine doppelten Boni, Arescan 19/14 und unbestätigten +7 sowie unveränderte Welt-/Inventardaten und ungültig gewordene alte Würfelproben. Ein echter später SQLite-Triggerfehler bestätigt vollständigen Rollback von Ereignis/Snapshot und Anzeige; erneutes Speichern gelingt. Statische zusätzliche Regel-/UI-Prüfung ohne Blocker. Kein realer Geräte-/Sprach-/GitHub-Test dadurch behauptet.

Erneuter kompletter scripts/check.sh-Lauf für 0.2.3 erfolgreich: Projektstrukturprüfung, **22 Python-Paket-/Strukturtests**, Backend-Typecheck/Build und **22 Backend-Tests** mit Node.js 22.14.0, saubere Flutter-Analyse sowie **178 Flutter-Tests** mit RUN_BACKEND_SMOKE=1. Neue Tests prüfen beide ZIP-Wurzeln, Byte-Erhalt, Geheimnis-/Cache-Ausschluss, Symlinkablehnung, unvollständige Uploads, Gradle-JAR-CRC und Unix-Zeilenenden. Keine kostenpflichtigen Modellaufrufe.

Drei optimierte Alpha-APKs lokal erfolgreich gebaut und geprüft: arm64-v8a 17.382.068 Byte, armeabi-v7a 14.861.712 Byte, x86_64 18.554.326 Byte. Alle Version 0.2.3, Buildcode 5, API 24+, richtige ABI und gleiche verifizierte lokale Debug-Testsignatur wie die bisherige 0.2.2-APK. Je ABI --target-platform verwendet, damit keine ABI-Codeoffsets spätere Updates verhindern. Kein Store-Release. ARM64 und ARM32 privat auf Google Drive erstellt und per Metadaten mit korrekter Größe/MIME/Owner-Recht gelesen; ARM64 zusätzlich über die Drive-Download-API abgerufen und byteidentisch per SHA-256 mit dem Original verglichen. Der Benutzerdownload und die Installation auf einem echten Gerät bleiben separat abzunehmen.

Flutter 3.35.7/Dart 3.9.2: Codeanalyse ohne Befunde und **178 Tests bestanden** mit RUN_BACKEND_SMOKE=1. Enthalten sind 74 bisherige Tests, 23 Transporttests, 13 Erzähl-/Replay-Tests, 13 SQLite-/Backend-Controller-Tests, 7 Backend-Widgettests, 13 Abruf-/Konsistenztests, 21 Dateikanal-/UTF-8-Tests, 13 Datei-Widgettests und ein echter lokaler Protokolltest. Der aktuelle Gesamtlauf verwendet Node 22.14.0 auch für den realen Protokolltest. Der Protokolltest startet den kompilierten Node-Server, stellt mit der Server-CLI einen synthetischen Sitzungstoken aus und prüft Dart-Transport, Backend-Erzählung, SQLite-Bestätigung und den Rückfall nach Serverabschaltung. Er verwendet ausschließlich lokale Mock-Dienste und Testdaten.

Backendquellen unverändert seit 0.2.0: Typecheck, Produktionsbuild und **22 Tests** erfolgreich mit Node.js 22.14.0 und 24.19.0. Geprüft sind neue Sitzungsprüfung, verbindliches outcome, Provider-/Tool-Abweisung, Authentifizierung, Eingabevalidierung, Nutzungslimits und sichere Fehler. Die historischen 0.1.0-Prüfungen und Quellenangaben bleiben im Änderungsprotokoll nachvollziehbar. Es wurden keine kostenpflichtigen Modellaufrufe ausgeführt.

Native Android-JVM-Prüfung mit Java 17 und Gradle 8.12: **12 Tests bestanden**, keine Fehler, keine übersprungenen Fälle. Geprüft sind reale Byte-Grenze statt Provider-Metadaten, Dateinamen, Lesen/Schreiben, Streamschluss und I/O- beziehungsweise Abbruchfehler. Lebenszyklus und SAF-Ergebniszustellung sind statisch geprüft, nicht durch diese JVM-Tests oder auf einem Gerät nachgewiesen.

Die Abschlusskorrektur ist ebenfalls abgenommen: Trennung und Dispose beenden ausstehende Backend-Wartevorgänge sofort; aktive HTTP-Verbindungen werden geschlossen, und verspätete Antworten bleiben wirkungslos. Der Abbruchknopf ist während einer laufenden Anfrage bedienbar. Bereits ausgelöste Anbieteraufrufe werden dadurch nicht automatisch erstattet.

## NICHT GETESTET

- Installieren und vollständiger End-to-End-Ablauf auf einem echten Android-Gerät, einschließlich neuer Attributshilfe mit großer Schrift/Screenreader.
- Echte Android-Dokumentauswahl, Dokumentanbieter, Berechtigungsübergabe, Schreibfehler und Aktivitätsende während einer Dateisicherung. Die Dateibrücke ist kompiliert; Dart-Kanal, Oberfläche und native I/O-Helfer werden getrennt automatisiert geprüft.
- Deutsche Mikrofoneingabe und Sprachausgabe mit einem konkreten Android-Sprachanbieter.
- Unterbrechung, Berechtigungsablehnung und Ausfall von echten Gerätesprachdiensten; die zugehörige App-Logik ist mit Mocks getestet.
- GitHub-Actions-Lauf und Herunterladen eines APK-Artefakts.
- Reale, kostenpflichtige OpenAI-Aufrufe und eine mobile HTTPS-Verbindung zu einem produktiven Server.

## BLOCKIERT

- Zugriff auf die vorhandene GitHub-Codebasis und direkte Übertragung der Änderungen: Erneute Prüfung als ManuEtt: Connector-Repositoryabruf404, keine sichtbaren App-Installationen/Konten und keine Dnd-Suchtreffer; Git-Lesen403. Bestehender Pushversuch des geprüften Standes nach origin/feat/solo-alpha wurde mit HTTP 403 „Write access to repository not granted“ abgewiesen. Das beweist keine Löschung oder Umbenennung. Eine genaue Web-Upload-/Actions-Fehlerursache ist ohne Benutzerfehlertext und Repo-Zugriff nicht bestätigt. Das flache Korrektur-ZIP und die Anleitung in docs/UPLOAD_TO_GITHUB.md ermöglichen die Übernahme und Zugriffsreparatur durch den Eigentümer.
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

**App 0.3.0+6: universeller Android-Debug-Build erfolgreich**, API 24+, Ziel 36, gleiche Paket-ID, Metadaten und Debug-Signatur geprüft. Drei optimierte kleine Alpha-APKs wurden mit normaler Buildnummer 6 erstellt und per Metadaten, Architektur und gleicher lokaler Testsignatur geprüft; alle unter 25 MiB. Toolchain unverändert wie im historischen Debugnachweis unten; letzte Gerätemessung weiterhin nicht vorhanden.

**App 0.2.3+5: drei optimierte kleine Alpha-APKs erfolgreich gebaut**, Release-AOT mit interner Debug-Testsignatur; Toolchain wie im folgenden Debugnachweis. Die CI-Konfiguration baut zusätzlich weiterhin die universelle Debug-APK, prüft die Struktur früh und hält die kleinen Artefakte 30 Tage bereit. YAML und lokale Befehle sind geprüft; der tatsächliche GitHub-Lauf ist weiterhin blockiert.

**App 0.2.2+4: Android-Debug-Build erfolgreich** mit Flutter 3.35.7/Dart 3.9.2, Temurin-JDK 17.0.20.1, Gradle 8.12, AGP 8.9.1, Kotlin 2.1.0, SDKs 34/35/36, Build Tools 35.0.0, NDK 27.0.12077973 und CMake 3.22.1. Paket-ID `de.aetheria.lebendiger_spielleiter`, Android ab API 24 (7.0), Ziel-API 36. APK-Metadaten (Version 0.2.2, Code 4), erforderliche Rechte und Debug-Signatur wurden geprüft. Keine allgemeine Speicherberechtigung hinzugefügt. Die Debug-Signatur entspricht der vorherigen 0.2.0-APK; ein Update ist damit grundsätzlich möglich, aber noch nicht auf einem Gerät geprüft. Der abschließende Build nach Dateiintegration war erfolgreich.

Anfangs fehlten ein vollständiger Java-Compiler, die Sprachplugin-SDKs und CMake. Diese Entwicklungswerkzeuge wurden installiert. Proxy-/CA-Vertrauen wurde ausschließlich in der lokalen Cloud-Werkzeugumgebung konfiguriert, ohne TLS-Prüfung zu deaktivieren. Lokale Werkzeugpfade und Cloud-Konfiguration gehören nicht zum ZIP. Die CI installiert die benötigten SDK-Komponenten ausdrücklich. Der erfolgreiche lokale Build ist **kein** ausgeführter GitHub-Actions-, Emulator- oder Gerätetest.

## Gesicherter Stand und Fortsetzung

- Letzter gesicherter Funktionsstand: `c0611e15134449b50ab856facb03a49514dbeda4` (0.3.0), Branch `feat/solo-alpha`.
- Zuletzt fertiggestellt: App 0.3.0-Attributshilfe mit Standardsatz/Punktekauf und ausdrücklicher SRD-Hintergrundsteigerung. 222 Flutter-, 22 Backend- und 22 Python-Tests sowie Analyse und Debug-Build erfolgreich. Bestehende native I/O-Tests bleiben 12 bestanden, unveränderter Code.
- Aktueller Abschluss: neue Regeln, Editor und Persistenz geprüft. Optimierte APKs geprüft und Code committet. ARM64 und ARM32 privat auf Drive per Metadaten bestätigt; ARM64 heruntergeladen und byteidentisch per SHA-256 geprüft. Flaches Quell-ZIP mit genau 100 versionierten Dateien, CRC/Quellbytes und entpackter Strukturprüfung abgenommen; endgültige ZIP-Übernahme/Links/Prüfsummen im externen Checkpoint. Keine Schemaänderung oder neue Laufzeitabhängigkeit. Die Hintergrundhilfe vergibt noch keine Talente, Fertigkeiten, Werkzeuge oder Ausrüstung.
- Bekannte Grenzen: kein automatischer Token-Refresh, keine abgenommenen Geräte-/OpenAI-/GitHub-Actions-Tests, begrenzte Regel- und Demo-Interpretation. Bei einem unterbrochenen Export kann eine bereits vollständig geschriebene Datei trotz fehlender Erfolgsantwort erhalten bleiben; auch die Entfernung einer fehlgeschlagenen neuen Datei hängt vom Dokumentanbieter ab. Kein Verlust bestätigter SQLite-Spielstände in den ausgeführten Tests.
- Nächster konkreter Entwicklungsschritt ohne Gerätezugriff: Stufe-1-Trefferpunkte aus ausdrücklich gewählter Klasse und bestätigtem Konstitutionsmodifikator vorschlagen. Offizielle SRD 5.2.1-Klassenquellen vorher lesen; bestehende/historische TP erst nach Bestätigung ändern, Klassen-/Modifikatorgrenzen und Speicherung testen. Sobald Gerät/Zugriff bereitsteht, Dateisicherung, HTTPS-/Sprachpfad und GitHub Actions separat abnehmen.
- Übergabepakete: Dnd-Projekt-0.3.0.zip mit Dateien direkt in der Wurzel sowie Der-lebendige-Spielleiter-0.3.0-arm64.apk/arm32.apk. Externer Dnd-0.3.0-status.json erfasst abschließenden Git-HEAD, SHA-256 und bestätigte private Drive-Links. Alte Übergabepakete bleiben erhalten.
- Der tatsächliche Git-HEAD wird vor jeder Fortsetzung mit `git log -1 --oneline` geprüft. Keine zusätzlichen Credits oder Limit-Zurücksetzungen wurden ausgelöst. Ein erkennbares Kontingentlimit wird nicht aus nicht vorhandenen Messwerten abgeleitet.
