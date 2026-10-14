# Der lebendige Spielleiter

Deutschsprachiger Fantasy-Spielleiter für Android mit Flutter, lokalem Kampagnengedächtnis und einem kostenlosen Demo-Modus in [ManuEtt/Dnd](https://github.com/ManuEtt/Dnd). Der zunächst unabhängig erstellte Stand wurde nach Wiederherstellung des Zugriffs mit dem hochgeladenen 0.3.0-Repository verglichen: Die Dateiinhalte stimmen überein, lediglich vier Ausführungsrechte unterscheiden sich. Neue Korrekturen bauen auf diesem Repositorystand auf.

Der Schwerpunkt liegt auf einem spielbaren Solo-Ablauf: Charakter und Kampagne anlegen, Entscheidungen eingeben, mit einem deterministischen Spielleiter interagieren, würfeln, einfache Kämpfe austragen und den bestätigten Zustand wieder laden. Der Demo-Spielleiter verarbeitet einige Handlungsarten und liefert passende Szenen; frei formulierte Texte sind möglich, die Antworttiefe ist jedoch begrenzt. Eine umfassende generative KI und eine vollständige Umsetzung aller SRD-Regeln sind weitere Entwicklungsschritte.

## ZIP nach GitHub übertragen

Das Korrektur-ZIP **Dnd-Projekt-0.3.1.zip entpacken und seine Projektinhalte einschließlich `.github/`** direkt in die Repositorywurzel übertragen; das neue Paket enthält keinen äußeren `Dnd/`-Ordner. Nur die ZIP-Datei hochzuladen startet keinen Android-Build. Vorhandene Dateien vorher vergleichen und in einem neuen Branch arbeiten. Die [Schritt-für-Schritt-Anleitung](docs/UPLOAD_TO_GITHUB.md) erklärt Zugriff, Upload und APK-Download. Vor dem Build prüft `python3 scripts/verify_project.py` die Vollständigkeit ohne Flutter/Android SDK.

## Starten und prüfen

Benötigte Versionen: Flutter **3.35.7** mit Dart **3.9.2**, Java **17** (vollständiges JDK einschließlich `javac`), Android SDK und Node.js **22.14.0** oder eine kompatible neuere Node-22-Version. Abhängigkeiten sind über `app/pubspec.lock` und `backend/package-lock.json` festgehalten. Netzwerkzugang wird beim ersten Installieren der Entwicklungsabhängigkeiten benötigt.

```bash
cd app
flutter pub get
flutter analyze
flutter test
flutter run
```

Für SQLite-Tests unter Linux wird zusätzlich `libsqlite3-dev` benötigt, unter Debian/Ubuntu beispielsweise über `sudo apt-get install libsqlite3-dev`.

Der Demo-Modus benötigt keinen Server, keinen OpenAI-Schlüssel und keine kostenpflichtigen API-Aufrufe. Ab Version **0.2.0** lässt sich unter Einstellungen zusätzlich ein eigener HTTPS-Backend-Erzähler mit kurzlebigem Sitzungstoken verbinden. Der Token bleibt ausschließlich im Arbeitsspeicher. Kostenpflichtige Anbieter benötigen eine ausdrückliche Freigabe; bei Ausfall erzählt die lokale Demo weiter. Regeln, Würfel und bestätigter Spielzustand bleiben lokal. Einrichtung und Grenzen stehen in [docs/BACKEND_CONNECTION.md](docs/BACKEND_CONNECTION.md).

Die Android-Spracherkennung und Textausgabe nutzen die auf dem Gerät verfügbaren Systemdienste. Deutsche Sprachpakete müssen vorhanden sein; die Spracherkennung kann je nach Android-Dienst eine Internetverbindung benötigen. Eine vollständige Offline-Sprachfunktion wird nicht garantiert. Erkannte Eingaben lassen sich vor dem Absenden bearbeiten. Audiodateien werden von dieser App nicht dauerhaft gespeichert.

Seit **0.3.1** lassen sich Stimmen nach einer Sprachpaketinstallation neu prüfen.
Die Auswahl zeigt vom Anbieter gemeldete Netzwerkabhängigkeit; fehlende
Sprachdaten und abgewiesene Stimmen erhalten verständliche Rückmeldungen.
Wartezeiten für nicht antwortende Dienste sind begrenzt; die lokale Oberfläche
startet bereits während der Sprachdienstprüfung. Die App unterstützt
derzeit Deutsch; eine Stimmwahl übersetzt keine Spieltexte. Gerätehilfe und
der Benutzerbericht zum Samsung Galaxy S26 Ultra stehen in
[docs/SPEECH_TROUBLESHOOTING.md](docs/SPEECH_TROUBLESHOOTING.md).

Optionales Backend:

```bash
cd backend
npm ci
npm run typecheck
npm test
npm run build
npm run dev
```

Die Backend-Konfiguration steht in [backend/.env.example](backend/.env.example). Echte Schlüssel gehören ausschließlich in lokale Umgebungsvariablen beziehungsweise die sichere Serverkonfiguration. Details zu vorhandenen API-Routen, Demo-Betrieb und optionaler OpenAI-Verbindung stehen im [Backend-README](backend/README.md). Es ist keine öffentliche Hostingumgebung eingerichtet.

## Android installieren

Nach Übertragung der Projektdateien läuft der Workflow **Android-Alpha bauen**. Unter **Actions → erfolgreicher Lauf → Artifacts** das Artefakt `lebendiger-spielleiter-alpha-kleine-apks` herunterladen und entpacken. Für übliche 64-Bit-Android-Geräte `app-arm64-v8a-alpha.apk` wählen; ältere 32-Bit-Geräte benötigen `app-armeabi-v7a-alpha.apk`. Das zusätzliche große Debug-Artefakt bleibt verfügbar. Die kleinen APKs sind optimierte interne Alpha-Builds mit Testsignatur. Downloadhilfe: [docs/APK_DOWNLOAD.md](docs/APK_DOWNLOAD.md). Android kann für die Installation eine Freigabe der verwendeten Installationsquelle verlangen. Es handelt sich nicht um einen signierten Store-Release.

Ein lokaler Build ist ebenfalls möglich:

```bash
cd app
flutter build apk --debug
```

Ausgabe: `app/build/app/outputs/flutter-apk/app-debug.apk`. Der lokale Android-Debug-Build wurde erfolgreich geprüft; die APK benötigt mindestens Android 7.0 (API 24). Tatsächlich durchgeführte Prüfungen und verbleibende Grenzen stehen in [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) und [TESTING.md](TESTING.md). Ein erfolgreicher Build ersetzt keinen Test auf einem Android-Gerät.

## Attribute erstellen

Ab **0.3.0** öffnet **Attribute ermitteln** im Charaktereditor eine
Stufe-1-Starthilfe. Weise den Standardsatz 15, 14, 13, 12, 10, 8 zu oder kaufe
Grundwerte von 8 bis 15 mit bis zu 27 Punkten. Wähle anschließend ausdrücklich
Akolyth, Krimineller, Weiser oder Soldat sowie dessen zulässige
Attributssteigerungen. Die Vorschau zeigt Grundwert, Bonus, Endwert und
Modifikator. Erst **Attribute übernehmen** ändert den Editor, und erst
**Charakter speichern** bestätigt die Daten dauerhaft. Vorhandene Werte
benötigen eine zusätzliche Bestätigung zum Ersetzen; Abbrechen erhält sie.

Die Hilfe vergibt Attribute und die gewählte Hintergrundbezeichnung.
Fertigkeiten, Talente, Ausrüstung, Trefferpunkte und Klassenfortschritt brauchen
weiter eigene bestätigte Angaben. Historische Arescan-Werte werden nicht
abgeleitet oder automatisch ergänzt. Regeln und Quellen:
[docs/ABILITY_RULES.md](docs/ABILITY_RULES.md).

## Die beiden Ausgangskampagnen

**Das Herz der Ewigkeit** übernimmt die vorgegebene Geschichte in Aetheria mit Arescan in Silberhain. Der Angriffsgesamtwert 19 und der erzählte Schaden 14 bleiben historische Angaben. Fehlende Attribute, Trefferpunkte, Gold, Erfahrungspunkte, Ausrüstung und der ungeprüfte frühere Geschicklichkeitsmodifikator +7 werden nicht als bestätigte Regelwerte übernommen. Die Geschichte bleibt lesbar; vor neuen regelabhängigen Aktionen muss der Charakter vervollständigt werden. Auch die Kampfwerte des Schattenritters sind unbekannt: Der historische Kampf kann noch nicht regelkonform fortgesetzt werden, solange diese nicht ausdrücklich bestätigt werden.

Seit App **0.2.2** lassen sich Charaktere und Kampagnen über **Als Datei speichern** direkt als JSON sichern. Android fragt nach dem Zielordner; die App benötigt dafür keine allgemeine Speicherberechtigung. Beim Import öffnet **Datei wählen** die Android-Dateiauswahl. Der geladene Text wird erst mit **Importieren** bestätigt und gespeichert. Abbrechen und fehlerhafte Dateien verändern den vorhandenen Spielstand nicht. JSON-Anzeige, manuelle Texteingabe und Zwischenablage bleiben verfügbar. Details und Dateigrenzen stehen in [docs/SAVE_BACKUPS.md](docs/SAVE_BACKUPS.md).

Sicherungsdateien und die lokale Datenbank sind nicht zusätzlich verschlüsselt. Wähle einen geeigneten Speicherort; ein Cloud-Dateianbieter kann Daten zu seinem Dienst übertragen. Android-App-Backups sind deaktiviert; vor einer Deinstallation wichtige Spielstände exportieren.

Die separate Demo-Kampagne **Das Licht von Mooswacht** beginnt in der Welt Lunaris mit **Liora**, einer menschlichen Kämpferin der Stufe 1. Sie enthält ausdrücklich festgelegte Demo-Werte und führt über einen Brunnen, einen Schlüssel und einen Waldschrein zu einer einfachen Begegnung. Sie dient zum Prüfen des Ablaufs ohne externe KI-Dienste. Importierbare Ausgangsspielstände liegen unter `app/assets/arescan.json` und `app/assets/demo.json`.

## Projektstruktur

| Pfad | Aufgabe |
| --- | --- |
| `app/` | Flutter-App, Android-Projekt, Domänenmodelle, Regeln, Persistenz, UI und Tests |
| `backend/` | TypeScript/Fastify, validierte API, Demo-Provider und optionale OpenAI-Anbindung |
| `.github/workflows/` | Analyse, Tests und Android-Debug-APK |
| `docs/` | Übergabe- und Upload-Anleitungen |
| `scripts/` | Lokale Prüfung und sauberes ZIP-Paket ohne Buildcache oder Geheimnisse |

Architektur: [ARCHITECTURE.md](ARCHITECTURE.md). Nächste Aufgaben: [ROADMAP.md](ROADMAP.md). Hinweise für spätere Entwicklungssitzungen: [AGENTS.md](AGENTS.md).

Die verwendete Regelgrundlage ist eine ausgewählte Teilmenge von SRD 5.2.1 unter CC BY 4.0. Namensnennung und weitere Hinweise stehen in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Eine Lizenz für den eigenständigen Projektquellcode ist noch festzulegen.
