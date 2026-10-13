# Tests und Abnahme

Tests verwenden kontrollierbare Zufallsquellen und Anbieter-Mocks. Es sind keine kostenpflichtigen Modellaufrufe erforderlich. Ein Test gilt erst nach einem tatsächlich beobachteten erfolgreichen Lauf als bestanden; implementierter Testcode allein ist kein Testergebnis.

## Automatisierte Prüfungen

Unter Linux benötigen SQLite-Tests die Entwicklungsbibliothek `libsqlite3-dev` (Debian/Ubuntu: `sudo apt-get install libsqlite3-dev`). Der CI-Workflow installiert sie vor den Flutter-Tests.

Im Projektverzeichnis:

```bash
cd app
flutter pub get
flutter analyze
flutter test
```

```bash
cd backend
npm ci
npm run typecheck
npm run build
npm test
```

Mit Android SDK und Java 17:

```bash
cd app
flutter build apk --debug
```

Der GitHub-Workflow führt diese Prüfungen in derselben Reihenfolge aus und stellt die APK nur nach erfolgreichem Build bereit. Er benötigt für Demo-Tests keine API-Schlüssel.

Die Testabdeckung soll natürliche Würfelwerte und Gesamtwerte, Attributmodifikatoren, Angriffe, Schaden und Heilung, unvollständige Charakterdaten, Speicherung und Neustart, Transaktionsrollback, doppelte Ereignisse, Importvalidierung, Demo-Erzählung, zentrale Widgets und Backend-Authentifizierung beziehungsweise Validierung prüfen. Die tatsächlich vorhandenen Tests und ausgeführten Ergebnisse stehen in [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md).

## Android-Gerätetest

Diese Schritte sind eine noch separat durchzuführende Abnahme. Gerät, Android-Version, APK-Commit und Sprachdienst im Testbericht festhalten.

1. APK installieren und App starten. Im Demo-Modus ohne Backend und ohne API-Schlüssel beginnen.
2. Charakter anlegen, speichern und anzeigen; Werte bearbeiten. Die App schließen und neu öffnen, anschließend denselben Charakter prüfen.
3. Neue Demo-Kampagne starten. Texteingabe senden, Antwort lesen und mehrere freie Handlungen durchführen. Den Umfang der Demo-Interpretation dabei berücksichtigen.
4. Automatisch und manuell würfeln. Natürliches Ergebnis und Gesamtergebnis prüfen; sicherstellen, dass Boni genau einmal angewendet werden.
5. Einen einfachen Kampf bis zum Ende durchführen. Treffer, Fehlschlag, kritischen Treffer, Trefferpunkte und gespeichertes Ergebnis prüfen.
6. Die App nach einer bestätigten Aktion beenden und neu starten. Szene, Verlauf und Charakterzustand müssen erhalten bleiben. Einen kontrollierten Abbruch während einer Aktion zusätzlich prüfen.
7. Historische Kampagne „Das Herz der Ewigkeit“ laden. Die Geschichte, Gesamtangriff 19 und erzählter Schaden 14 müssen erhalten sein. Fehlende Werte und der ungeprüfte Modifikator +7 dürfen nicht automatisch als neue Regelwerte gelten.
8. Charakter und Kampagne als JSON exportieren, über die Zwischenablage selbst in einer `.json`-Datei sichern und anschließend deren Inhalt über den JSON-Importdialog importieren. Ungültige beziehungsweise nicht unterstützte Dateien ablehnen; vorhandene Daten dabei erhalten.
9. Deutsche Sprachpakete installieren beziehungsweise prüfen. Mikrofonfreigabe zunächst ablehnen und danach erlauben; beide Abläufe müssen verständliche Rückmeldung liefern.
10. Push-to-Talk verwenden. Erkanntes Deutsch anzeigen, Text manuell korrigieren und erst danach senden. TTS abspielen und unterbrechen; automatische Wiedergabe und verfügbare Stimmen prüfen.
11. Den Sprachdienst ohne Netzwerk testen. Das Ergebnis dokumentieren; vollständige Offline-Spracherkennung wird nicht zugesichert. Textspiel muss weiterhin verfügbar sein.
12. Datenexport und Löschfunktion prüfen. Bestätigte Löschung darf die entfernten Daten nach einem Neustart nicht zurückbringen.

## Getrennte Nachweise

| Nachweis | Bedeutung |
| --- | --- |
| Analyse und Unit-/Widget-/Backendtests | Prüfen Code und automatisierte Abläufe in der Entwicklungsumgebung |
| Android-APK-Build | Belegt erfolgreiche Kompilierung des Android-Projekts |
| Emulatorprüfung | Prüft Laufzeit auf der angegebenen Emulatorumgebung |
| Realer Gerätetest | Prüft tatsächliche Installation, Sprache, Berechtigungen und Wiederherstellung auf dem Gerät |
| GitHub-Actions-Lauf | Belegt das Verhalten der eingecheckten CI-Konfiguration auf GitHub |

Am 13. Oktober 2026 bestanden alle 74 Flutter-Tests sowie alle 17 Backend-Tests. Die Flutter-Analyse war ohne Befunde. Sprachlogik wird mit Plugin-Mocks getestet; Mikrofon und TTS auf Android benötigen weiterhin einen Gerätetest. Der Android-Debug-Build war mit JDK 17.0.20.1 erfolgreich; APK-Metadaten und Debug-Signatur wurden geprüft. Ein erfolgreicher APK-Build bedeutet nicht automatisch, dass Mikrofon, TTS oder alle Abläufe auf einem Gerät funktionieren. GitHub-Actions-, Emulator- und Gerätetests sind noch offen.
