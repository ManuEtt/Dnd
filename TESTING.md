# Tests und Abnahme

Tests verwenden kontrollierbare Zufallsquellen und Anbieter-Mocks. Es sind keine kostenpflichtigen Modellaufrufe erforderlich. Ein Test gilt erst nach einem tatsächlich beobachteten erfolgreichen Lauf als bestanden; implementierter Testcode allein ist kein Testergebnis.

## Automatisierte Prüfungen

Unter Linux benötigen SQLite-Tests die Entwicklungsbibliothek `libsqlite3-dev` (Debian/Ubuntu: `sudo apt-get install libsqlite3-dev`). Der CI-Workflow installiert sie vor den Flutter-Tests.

Vor dem Installieren der Buildwerkzeuge die Übertragung prüfen:

```bash
python3 scripts/verify_project.py
python3 -m unittest discover -s scripts/tests -v
```

Diese Tests benötigen nur Python 3. Sie prüfen insbesondere Wurzelstruktur,
Dateiausschlüsse, fehlende Lock-/Workflowdateien, Gradle-JAR-CRC und beschädigte
Uploads. Der CI-Workflow führt sie ebenfalls vor Flutter/Node aus.

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

Die native Dateisicherungslogik wird nach einem Android-Build zusätzlich auf der JVM geprüft:

```bash
cd app/android
./gradlew :app:testDebugUnitTest --no-daemon
```

Diese JVM-Tests prüfen Dateinamen und begrenztes Lesen. Dart-Kanal- und Widgettests simulieren die Systemdateiauswahl; sie ersetzen keinen Gerätetest. Der GitHub-Workflow führt auch diese Prüfungen aus und stellt die APK nur nach erfolgreichem Build und erfolgreichen Tests bereit. Er benötigt für Demo-Tests keine API-Schlüssel.

Der zusätzliche echte Node-/Dart-Protokolltest benötigt zuvor `npm run build`
im Backend und wird mit `RUN_BACKEND_SMOKE=1 flutter test` aktiviert.
`scripts/check.sh` und GitHub Actions aktivieren ihn nach dem Backend-Build.
Er verwendet ausschließlich synthetische Zugangsdaten und den lokalen Mock;
unverschlüsseltes Loopback-HTTP ist nur für diesen Entwicklungstest freigeschaltet.

Die Testabdeckung soll natürliche Würfelwerte und Gesamtwerte, Attributmodifikatoren, Angriffe, Schaden und Heilung, unvollständige Charakterdaten, Speicherung und Neustart, Transaktionsrollback, doppelte Ereignisse, Importvalidierung, Demo-Erzählung, zentrale Widgets und Backend-Authentifizierung beziehungsweise Validierung prüfen. Die tatsächlich vorhandenen Tests und ausgeführten Ergebnisse stehen in [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md).

## Android-Gerätetest

Diese Schritte sind eine noch separat durchzuführende Abnahme. Gerät, Android-Version, APK-Commit und Sprachdienst im Testbericht festhalten.

1. APK installieren und App starten. Im Demo-Modus ohne Backend und ohne API-Schlüssel beginnen.
2. Charakter anlegen. **Attribute ermitteln** öffnen und Standardwerte beziehungsweise Punkte-Kauf testen. Hintergrund und Steigerung ausdrücklich wählen; Vorschau und Modifikatoren prüfen. Abbrechen muss eingegebene/historische Werte bewahren, bekannte Werte benötigen Ersetzbestätigung. Hilfe übernehmen, übrige Daten bestätigen, speichern und anzeigen; Werte bearbeiten. Die App schließen und neu öffnen, anschließend denselben Charakter prüfen.
3. Neue Demo-Kampagne starten. Texteingabe senden, Antwort lesen und mehrere freie Handlungen durchführen. Den Umfang der Demo-Interpretation dabei berücksichtigen.
4. Automatisch und manuell würfeln. Natürliches Ergebnis und Gesamtergebnis prüfen; sicherstellen, dass Boni genau einmal angewendet werden.
5. Einen einfachen Kampf bis zum Ende durchführen. Treffer, Fehlschlag, kritischen Treffer, Trefferpunkte und gespeichertes Ergebnis prüfen.
6. Die App nach einer bestätigten Aktion beenden und neu starten. Szene, Verlauf und Charakterzustand müssen erhalten bleiben. Einen kontrollierten Abbruch während einer Aktion zusätzlich prüfen.
7. Historische Kampagne „Das Herz der Ewigkeit“ laden. Die Geschichte, Gesamtangriff 19 und erzählter Schaden 14 müssen erhalten sein. Fehlende Werte und der ungeprüfte Modifikator +7 dürfen nicht automatisch als neue Regelwerte gelten.
8. Charakter und Kampagne über **Als Datei speichern** als `.json` sichern; im Android-Systemdialog Zielordner und Dateinamen auswählen. Nach dem Speichern die Datei außerhalb der App prüfen. Beim Import über **Datei wählen** zunächst laden und dann ausdrücklich **Importieren** drücken. Jeweils die Systemauswahl abbrechen: vorhandene Daten müssen unverändert bleiben. Ungültige, fremde, übergroße und nicht UTF-8-codierte Dateien abweisen. Vorhandene Kampagnen nicht überschreiben; für den Wiederherstellungstest ein gesichertes Testexemplar zuerst lokal löschen. Zwischenablage und Texteingabe als Fallback prüfen. Einen Schreibfehler, fehlenden Dokumentanbieter und Aktivitätsende separat testen. Auch den gewählten Dokumentanbieter und Offline-Verfügbarkeit im Bericht nennen.
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

Bisheriger Funktionsnachweis App 0.2.2/Backend 0.2.0: **178 Flutter-Tests** einschließlich echtem lokalem Node-/Dart-Protokolltest, **12 native JVM-Tests** sowie **22 Backend-Tests** des unveränderten Backends bestanden; Flutter-Analyse ohne Befunde und Android-Debug-APK erfolgreich gebaut. Die echten OpenAI- und Android-HTTPS-/Sprachpfade sind weiterhin separat abzunehmen. Details und Werkzeuge stehen in DEVELOPMENT_STATUS.md. Es wurden keine kostenpflichtigen API-Aufrufe ausgeführt.

## Kleine Alpha-APKs

```bash
cd app
flutter build apk --release --target-platform android-arm64
```

Ausgabe `build/app/outputs/flutter-apk/app-release.apk` sofort sichern, bevor
für android-arm oder android-x64 erneut gebaut wird. Die CI kopiert jede
Architektur separat nach build/alpha. Metadaten müssen App 0.3.1, Buildcode 7,
API 24 und die ausgewählte ABI zeigen; Signatur mit einer bisherigen lokalen
APK vergleichen. Ein eigener APK-Build und Metadatenprüfung ersetzen weiterhin
keine Installation. Je Architektur außerdem Start, Sprache, SQLite-Neustart und
Update von der alten Debug-App auf einem passenden Gerät abnehmen.

Stand 0.2.3: 22 Python-Paket-/Strukturtests bestanden; drei kleine Alpha-APKs
lokal erfolgreich gebaut, Metadaten, ABI und gleiche lokale Testsignatur
verifiziert. Der vollständige scripts/check.sh-Lauf ist erfolgreich: 22 Python-Tests,
22 Backend-Tests, 178 Flutter-Tests einschließlich realem lokalem Protokolltest
und saubere Flutter-Analyse. Remote-CI und Gerätetests bleiben offen.

## Attributshilfe 0.3.0

Neue Domain-Tests prüfen Standardsatz, alle 720 Zuweisungen, Punktekosten,
Höchstbudget und zulässige Hintergrundsteigerungen. Die Widgettests prüfen
unter anderem 360-Pixel-Breite, explizite Auswahl, Punktgrenzen, Vorschau,
Bestätigung und Abbruch. SQLite-Integration prüft Neustart, Export/Import,
regelkonforme Modifikatoren, keine wiederholten Boni und historischen Arescan.
Ein realer SQLite-Triggerfehler nach begonnenem Schreiben muss Transaktion
und angezeigten Zustand unverändert lassen. Aktuelle Gesamtergebnisse stehen
in DEVELOPMENT_STATUS.md; diese Tests ersetzen keine Geräteprüfung.

## Sprachkorrekturen 0.3.1

Controller-Mocks prüfen TTS-Ergebnisse 0/false, fehlende Stimmendaten,
Netzwerk-Metadaten, deutsche regionale Locales, Paket-Neusuche, Anbieterfehler,
offene Futures, Stop und verspätete Ergebnisse. Die Android-Sprachliste darf
unvollständig sein; ein fehlender deutscher Eintrag führt zu einem begrenzten
expliziten de-DE-Versuch. Keine Mikrofonaufnahme wird automatisch wiederholt.
Widgettests prüfen Neusuche ohne Mikrofon, entfernte gespeicherte Auswahl und
lange Anbieter-IDs bei 360 px mit bis zu doppelter Schriftgröße.

Die Startprüfung verwendet echte temporäre SQLite-Daten und eine offene
native Stimmabfrage: Die lokale Startseite muss bereits bedienbar sein. Nach
der Antwort des simulierten Dienstes erscheint dessen Status in Einstellungen.
Gezielte Befehle:

```bash
cd app
flutter test test/voice_controller_test.dart test/ui_voice_settings_test.dart test/bootstrap_voice_test.dart
```

Der Benutzerbericht bestätigt App-Betrieb auf Samsung Galaxy S26 Ultra, aber
keine vollständige Sprachabnahme. Am Gerät getrennt deutsche Eingabe und
Vorlesen, Anbietername, Pakete, Netzwerk, Unterbrechung, erneute Stimmensuche
und Update von der vorherigen APK prüfen. Anleitung:
[docs/SPEECH_TROUBLESHOOTING.md](docs/SPEECH_TROUBLESHOOTING.md).

Der alte GitHub-Lauf 38560369343 besteht alle Tests und scheitert anschließend
am fehlenden sdkmanager. Die neue Tools-Installation muss auf GitHub gesondert
bestehen; lokale Builds ersetzen diesen Nachweis nicht.
