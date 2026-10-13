# Der lebendige Spielleiter

Deutschsprachiger Fantasy-Spielleiter für Android mit Flutter, lokalem Kampagnengedächtnis und einem kostenlosen Demo-Modus. Dieses Paket ist ein eigenständiger Alpha-Prototyp zum Übertragen in [ManuEtt/Dnd](https://github.com/ManuEtt/Dnd). Der vorhandene Repositoryinhalt konnte während dieser Entwicklung nicht gelesen werden; das Paket wurde deshalb nicht mit bestehendem Code zusammengeführt.

Der Schwerpunkt liegt auf einem spielbaren Solo-Ablauf: Charakter und Kampagne anlegen, Entscheidungen eingeben, mit einem deterministischen Spielleiter interagieren, würfeln, einfache Kämpfe austragen und den bestätigten Zustand wieder laden. Der Demo-Spielleiter verarbeitet einige Handlungsarten und liefert passende Szenen; frei formulierte Texte sind möglich, die Antworttiefe ist jedoch begrenzt. Eine umfassende generative KI und eine vollständige Umsetzung aller SRD-Regeln sind weitere Entwicklungsschritte.

## ZIP nach GitHub übertragen

Die ZIP **entpacken und ihre Projektinhalte einschließlich `.github/`** in das Repository übertragen. Nur die ZIP-Datei hochzuladen startet keinen Android-Build. Vorhandene Dateien vorher vergleichen und in einem neuen Branch arbeiten. Die [Schritt-für-Schritt-Anleitung](docs/UPLOAD_TO_GITHUB.md) erklärt den Upload und den APK-Download.

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

Der Demo-Modus benötigt keinen Server, keinen OpenAI-Schlüssel und keine kostenpflichtigen API-Aufrufe. Die App verwendet in diesem Stand den deterministischen Demo-Spielleiter; die optionale Backend-Erzählung ist noch nicht an die mobile Oberfläche angebunden. Die Android-Spracherkennung und Textausgabe nutzen die auf dem Gerät verfügbaren Systemdienste. Deutsche Sprachpakete müssen vorhanden sein; die Spracherkennung kann je nach Android-Dienst eine Internetverbindung benötigen. Eine vollständige Offline-Sprachfunktion wird nicht garantiert. Erkannte Eingaben lassen sich vor dem Absenden bearbeiten. Audiodateien werden von dieser App nicht dauerhaft gespeichert.

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

Nach Übertragung der Projektdateien läuft der Workflow **Android-Alpha bauen**. Unter **Actions → erfolgreicher Lauf → Artifacts** das Artefakt `lebendiger-spielleiter-android-debug` herunterladen und entpacken. Die enthaltene `app-debug.apk` ist ein Debug-Build für interne Tests. Android kann für die Installation eine Freigabe der verwendeten Installationsquelle verlangen. Es handelt sich nicht um einen signierten Store-Release.

Ein lokaler Build ist ebenfalls möglich:

```bash
cd app
flutter build apk --debug
```

Ausgabe: `app/build/app/outputs/flutter-apk/app-debug.apk`. Der lokale Android-Debug-Build wurde erfolgreich geprüft; die APK benötigt mindestens Android 7.0 (API 24). Tatsächlich durchgeführte Prüfungen und verbleibende Grenzen stehen in [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) und [TESTING.md](TESTING.md). Ein erfolgreicher Build ersetzt keinen Test auf einem Android-Gerät.

## Die beiden Ausgangskampagnen

**Das Herz der Ewigkeit** übernimmt die vorgegebene Geschichte in Aetheria mit Arescan in Silberhain. Der Angriffsgesamtwert 19 und der erzählte Schaden 14 bleiben historische Angaben. Fehlende Attribute, Trefferpunkte, Gold, Erfahrungspunkte, Ausrüstung und der ungeprüfte frühere Geschicklichkeitsmodifikator +7 werden nicht als bestätigte Regelwerte übernommen. Die Geschichte bleibt lesbar; vor neuen regelabhängigen Aktionen muss der Charakter vervollständigt werden. Auch die Kampfwerte des Schattenritters sind unbekannt: Der historische Kampf kann noch nicht regelkonform fortgesetzt werden, solange diese nicht ausdrücklich bestätigt werden.

Charaktere und Kampagnen lassen sich als JSON anzeigen und in die Zwischenablage kopieren. Für ein dauerhaftes Backup den Text selbst in einer `.json`-Datei sichern; Importe erfolgen über den JSON-Eingabedialog. Die lokale Datenbank ist nicht zusätzlich verschlüsselt. Android-App-Backups sind deaktiviert; vor einer Deinstallation wichtige Spielstände exportieren.

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
