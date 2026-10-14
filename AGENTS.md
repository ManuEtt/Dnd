# Arbeitsanweisungen für kommende Entwicklungssitzungen

## Einstieg

1. Arbeitsverzeichnis, Git-Status, Branches, Remotes und vorhandene Commits prüfen.
2. Diese Datei sowie `DEVELOPMENT_STATUS.md`, `ROADMAP.md`, `ARCHITECTURE.md` und `TESTING.md` lesen.
3. Vorhandene Änderungen anderer Beteiligter erhalten. Das ZIP ist ein eigenständiger Entwicklungsstand, kein geprüfter Merge mit einer älteren Repositoryversion.
4. Werkzeuge mit `flutter --version`, `dart --version`, `java -version` und `node --version` prüfen.
5. Den nächsten offenen, überprüfbaren Schritt aus der Roadmap bearbeiten. Keine fertigen Funktionen unnötig neu schreiben.

Das vorgesehene Hauptrepository ist `ManuEtt/Dnd`, SSH `git@github.com:ManuEtt/Dnd.git`. Kein alternatives Hauptrepository anlegen. Kein Force-Push und keine fremden Dateien ohne Prüfung überschreiben. Geheimnisse niemals anfordern oder im Chat, in Logs, Quellcode oder Commits ausgeben.

## Architektur und Regeln

- Flutter in `app/`, Fastify/TypeScript in `backend/`; UI, Domänenregeln und Datenzugriff getrennt halten.
- Der Spielleiter liefert Erzählung und validierte Vorschläge. Zustandsänderungen erfolgen ausschließlich durch die autorisierte Geschäfts- beziehungsweise Regelengine.
- Natürliche Würfelergebnisse getrennt von Gesamtwerten halten; Boni niemals zweimal anwenden.
- Kontrollierbare Zufallsquellen für Regeln verwenden. Tests benötigen keine kostenpflichtige KI.
- Historische Arescan-Werte 19 und 14 erhalten, aber nicht als neue bestätigte Regelberechnungen behandeln. Keine fehlenden Attribute erfinden; insbesondere den alten ungeprüften Modifikator +7 nicht übernehmen.
- Nur rechtmäßig verwendbare SRD-5.2.1-Inhalte und eigene Texte einsetzen. Neue Regelumsetzungen mit Quelle und Test versehen. `THIRD_PARTY_NOTICES.md` erhalten.
- Als Demo ausgewiesene Werte sind ausdrücklich festgelegte Demo-Daten; sie dürfen nicht stillschweigend den historischen Arescan-Bogen ersetzen.

## Speicher- und Sicherheitsvorgaben

- SQLite-Schema und Importformat versionieren. Schemaänderungen brauchen Migrationen und Wiederherstellungstests.
- Snapshot und dazugehöriges Ereignis in derselben Transaktion speichern.
- Doppelte Ereignis-IDs dürfen keine zweite Zustandsänderung erzeugen.
- Ungültige Importe ohne Teiländerungen ablehnen. Den letzten bestätigten Zustand nach Neustart erhalten.
- Dauerhafte Anbieter-Schlüssel ausschließlich serverseitig speichern; `.env` und Benutzerexporte nicht committen.
- Authentifizierung, Rollenprüfung, Eingabevalidierung und Nutzungsgrenzen nicht durch Clientdaten umgehen lassen.
- Audio nicht dauerhaft speichern. Geräteabhängige Spracherkennung nicht als garantiert offline bezeichnen.
- Die vorhandene Solo-Architektur nicht als fertigen öffentlichen Mehrspielerdienst darstellen.

## Befehle

```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

```bash
cd backend
npm ci
npm run typecheck
npm run build
npm test
```

Unter Linux benötigen SQLite-Tests `libsqlite3-dev`; der CI-Workflow installiert das Paket.

Flutter 3.35.7, Dart 3.9.2, Java 17 und Node.js 22.14.0 bilden die CI-Grundlage. Lockdateien mit Änderungen an Abhängigkeiten gemeinsam prüfen. App-Tests sollen insbesondere Regeln, Speichertransaktionen, Export/Import und relevante UI-Abläufe abdecken. Backend-Tests dürfen Fastify-Injection und Anbieter-Mocks verwenden. Erfolgreiche Tests nur mit tatsächlich beobachtetem Ergebnis dokumentieren.

## Abschluss eines Inkrements

Relevante Analyse, Tests und Build ausführen, Fehler beheben und `DEVELOPMENT_STATUS.md`, `CHANGELOG.md` sowie nötige technische Dokumentation aktualisieren. Klar zwischen **IMPLEMENTIERT**, **GETESTET**, **NICHT GETESTET**, **BLOCKIERT** und **NOCH NICHT IMPLEMENTIERT** unterscheiden. Build, Emulator und reales Gerät getrennt aufführen. Bei fehlendem Zugriff eine konkrete Übergabe erstellen und unabhängig mögliche Arbeiten fortführen. Geprüfte Änderungen mit aussagekräftiger Nachricht auf einem Entwicklungsbranch committen; nur bei vorhandener Berechtigung pushen.

## Autonomer Modus und Limit-Pause

Normale technische Entscheidungen selbst treffen und in kleinen, abgeschlossenen
Schritten entwickeln. Keine Credits kaufen und keine kostenpflichtigen
Limit-Zurücksetzungen auslösen. Bei einer tatsächlichen Limitwarnung keine große
neue Aufgabe oder zusätzliche Agentengruppe starten; zuerst den laufenden
Schritt testen, speichern und soweit möglich committen. Vor einer Pause den
fertigen Schritt, gesicherten Code-Commit, offene Aufgaben, bekannte Fehler und
den konkreten nächsten Schritt in DEVELOPMENT_STATUS.md dokumentieren. Ein
Kontingentstand darf nicht erfunden werden. Eine neue Sitzung liest zuerst den
Status und prüft anschließend den tatsächlichen Git-HEAD; automatische
Sitzungswiederaufnahme wird nicht vorausgesetzt.

## Backend-Erzähler seit 0.2.0

Sitzungstokens und Kostenfreigaben bleiben im Arbeitsspeicher. Die App darf nach
einem Neustart keinen Backendaufruf automatisch autorisieren. Nur validierte
freie Erzählungen werden extern ausgestaltet; Regelaktionen und historische
Werte bleiben lokal. Externe `stateChanges` sind unzulässig. Neue Erzählungen
und deren Checkpoints gemeinsam speichern. Weiterleitungen dürfen kein
Bearer-Token erhalten. Kein automatischer POST-Retry, da bereits übermittelte
Anfragen Kosten verursachen können. Hinweise: docs/BACKEND_CONNECTION.md.

Der zusätzliche Node-/Dart-Protokolltest läuft mit RUN_BACKEND_SMOKE=1 nach dem
Backend-Build. `scripts/check.sh` und CI aktivieren ihn; sein Loopback-HTTP ist
ausschließlich eine Testoption, die mobile Oberfläche akzeptiert nur HTTPS.

## Dateisicherung seit App 0.2.2

Android-JSON-Dokumente ausschließlich über die austauschbare BackupFiles-Schnittstelle und das Storage Access Framework öffnen beziehungsweise speichern. Keine allgemeine Speicherberechtigung und keine dauerhaften URI-Rechte ergänzen. Beide Kanalseiten prüfen Dateinamen und eine 10-MiB-Grenze. Importdateien zunächst im bearbeitbaren Dialog zeigen; vor ausdrücklicher Bestätigung keine Datenbankänderung. Bestehende versionierte Repositoryvalidierung erhalten. Abbruch, fehlerhafte Dateien, parallele Auswahl und UTF-8 mit Mocks beziehungsweise JVM testen; eine echte Dateiauswahl erfordert weiterhin Geräteabnahme. Details: docs/SAVE_BACKUPS.md.

## Upload und kleine APKs seit 0.2.3

Vor Analyse/Build `python3 scripts/verify_project.py` und
`python3 -m unittest discover -s scripts/tests -v` ausführen. Das Korrektur-ZIP
wird mit `python3 scripts/package_project.py <Ziel-außerhalb-des-Projekts>
--layout root` ohne zusätzlichen Dnd-Ordner erzeugt. Quellcode-ZIPs enthalten
keine APKs. ZIP-Integrität und Pflichtdateien prüfen; frühere Dateien nicht
ungeprüft überschreiben.

Kleine interne Alpha-APKs mit `flutter build apk --release --target-platform
android-arm64` beziehungsweise `android-arm`/`android-x64` bauen und die jeweilige
app-release.apk vor dem nächsten Build unter eigenem Namen sichern. Keine
ABI-Versionscodeoffsets aus `--split-per-abi` übernehmen: Die bereitgestellten
Sideload-Versionen sollen die normale Buildnummer behalten. Releasemodus bleibt
mit Debug-Testsignatur; echte Release-Signierung ist weiterhin offen. APK-Metadaten,
Signatur und Architektur prüfen. Neue Downloadlinks müssen aus bestätigten
Datei-/Artefaktergebnissen stammen; ein Workspacepfad allein beweist keinen
funktionierenden Benutzerdownload. Drive-Dateien privat halten; vorhandene
Freigaben nicht ändern. Details: docs/APK_DOWNLOAD.md.

## Attributstarthilfe seit 0.3.0

Grundwerte und Hintergrundsteigerungen getrennt halten. Standardsatz muss jeden
Wert genau einmal enthalten; Punktekauf validiert nur die neuen Basiswerte von 8 bis 15
und das Höchstbudget von 27 Punkten. Nicht ausgegebene Punkte werden sichtbar angezeigt und
nicht als ausdrücklich verbotener Regelverstoß dargestellt. Regelquelle und
Auslegung: docs/ABILITY_RULES.md. Hintergrundboni niemals auf bereits bestätigte
Endwerte erneut addieren. Die Oberfläche übernimmt nur ausdrücklich gewählte
Hintergrundsteigerungen, bewahrt bestehende Werte bis zur Bestätigung und lässt
manuelle/historische Charakterbearbeitung zu. Schema 1 bleibt kompatibel.
Die vier Hintergrundbezeichnungen sind keine vollständige Hintergrundimplementation:
Talente, Fertigkeiten, Ausrüstung und Klassenwerte werden weiterhin separat
bestätigt. Neue Ergänzungen an diesen Regeln vor Implementierung im offiziellen
SRD 5.2.1 prüfen und mit Domain-/Persistenztests absichern.

## Sprachdienste seit 0.3.1

Die Hauptsprache bleibt Deutsch. Native FlutterTts-Ergebnisse 0/false dürfen
nicht als Erfolg gespeichert werden. Stimmmetadaten für Netzwerkbedarf und
bekannt fehlende Daten erhalten; native Namen/Locale-IDs nicht umschreiben.
Locale-Normalisierung ausschließlich für Vergleich und Rangfolge verwenden.
Die Android-Erkennung kann bei der Sprachabfrage hängen; Abfragen begrenzen
und fehlende Listeneinträge nicht als Beweis fehlender Online-Unterstützung
interpretieren. Keine automatische erneute Mikrofonöffnung. TTS-Fehler können
native Futures offen lassen; lokale Abbruch-/Zeitgrenzen mit Mocks prüfen.
Eine Stimmensuche fordert keine Mikrofonberechtigung. Der Samsung-Gerätebericht
ist eine Benutzerrückmeldung, keine vollständige Entwicklerabnahme. Anleitung
und Paketquellen: docs/SPEECH_TROUBLESHOOTING.md.
