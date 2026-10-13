# Aetheria – Der lebendige Spielleiter

Ein deutschsprachiger Fantasy-Rollenspiel-Prototyp mit Flutter (Android zuerst), lokalem Demo-Spielleiter, digitalen Würfeln, SQLite-Spielständen und gerätebasierter Sprachein- und -ausgabe. Dies ist eine **frühe Entwicklungsfassung, keine abgenommene Alpha**.

## Enthalten

- Material-3-Oberfläche mit Startseite, Kampagnen, Heldenerstellung, Spielansicht und Tagebuch
- Charaktere und Kampagnen in SQLite (`sqflite`), mit Datenbankschema Version 1
- Transaktionales Ereignisprotokoll für Dialogzüge, Schutz vor doppelter Rundenerfassung
- Deterministisch testbare W4/W6/W8/W10/W12/W20/W100-Proben mit Trennung von natürlichem Wurf und Ergebnis
- Offline-Mock-Spielleiter (festgelegte Reaktionen, **keine echte KI**)
- Deutsche Android-System-Spracherkennung und Sprachausgabe (abhängig von installierten Systemdiensten und Sprachpaketen)
- Arescan-Spielstand „Das Herz der Ewigkeit“ mit allen historischen Ereignissen und explizit **unbestätigten** Attributwerten
- Unabhängige Demo-Kampagne „Die Glocken des Nebelwaldes“
- Lokaler, nicht für das Internet freigegebener Fastify-Backend-Prototyp mit Eingabevalidierung

## Android starten

Voraussetzung: Flutter **3.47.0**, Android SDK/Android Studio, ein Android-Gerät oder Emulator, Java 17.

```bash
git clone https://github.com/ManuEtt/DND-Spielleiter-App.git
cd DND-Spielleiter-App
# Wenn die Projektdateien zunächst nur als ZIP vorliegen: ZIP entpacken,
# bis in GitHub committen/pushen wieder erlaubt ist.
bash tool/setup_android.sh
flutter pub get
flutter analyze
flutter test
flutter run
```

`tool/setup_android.sh` generiert das offizielle Android-Hostprojekt mit `flutter create`, falls es noch nicht existiert, und ergänzt die benötigten Android-Mikrofon- und Spracherkennungs-Deklarationen. Die resultierenden nativen Gradle-Dateien sollten nach einem erfolgreichen Build in das Repository übernommen werden, um vollständige Reproduzierbarkeit zu erreichen.

## Debug-APK über GitHub Actions

Sobald das Projekt auf GitHub liegt, löst ein Push, Pull Request oder manueller `workflow_dispatch` den Workflow `.github/workflows/android-build.yml` aus. Der Workflow prüft den Code und stellt im Erfolgsfall `aetheria-android-debug` als Artefakt bereit. **Es wurde noch kein erfolgreicher APK-Build nachgewiesen.**

## Backend

```bash
cd backend
npm install
npm test
npm run build
npm run dev
```

Der Server hört bewusst nur auf `127.0.0.1:8787` und bietet vorerst `/health` und `/v1/mock-turn`. Eine OpenAI-Verbindung, nutzerbezogene Authentifizierung, Realtime-Token und Cloudspeicher **sind noch nicht implementiert**. Niemals produktive API-Schlüssel in den Android-Client einbauen.

## Historischer Arescan-Spielstand

`assets/arescan_save.json` wird beim ersten Start eingespielt. Die früher erzählten Werte (Angriff gesamt 19, Schaden 14) sind historische Erzählfakten, keine regeltechnisch validierten Modifikatoren. Alle sechs Attribute und TP/RK bleiben bei Arescan zunächst unbekannt. Vor einem regelkonformen Kampf bitte den Charakter vervollständigen. Die App erfindet keine Werte.

## Lizenz- und IP-Hinweis

Eigenständige Spielwelt und Erzähltexte. Für künftige SRD-5.2.1-Regelinhalte gilt Creative Commons Namensnennung 4.0. Quelle: [System Reference Document 5.2.1](https://www.dndbeyond.com/srd), Wizards of the Coast LLC, CC BY 4.0, https://creativecommons.org/licenses/by/4.0/. Momentan verwendet das Projekt nur wenige grundlegende Spielmechaniken; keine nicht freigegebenen Texte, Logos oder Illustrationen enthalten.

Siehe [ARCHITECTURE.md](ARCHITECTURE.md), [ROADMAP.md](ROADMAP.md), [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md), [TESTING.md](TESTING.md).
