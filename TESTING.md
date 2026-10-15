## Illustrierte Oberfläche 0.5.0+20 – Pflichtchecks nach GitHub-Import

- `python3 scripts/verify_project.py .`
- `python3 -m unittest discover -s scripts/tests -v`
- `cd app && flutter pub get && flutter analyze && flutter test`
- `cd app && flutter build apk --debug`
- Android: auf 320/360/400 dp, vergrößerter Schrift und im Hoch-/Querformat testen, insbesondere die Aktionsleiste und den Inventardialog.
- End-to-End: Demo starten, Aktion eingeben/diktieren, Würfeln, Charakterbogen öffnen, Inventar anzeigen, Kampagne speichern/exportieren und App erneut starten.
- Die Art-Dateien sind lokal und brauchen keine Netzverbindung. Der CI-Status von v0.4.3 darf nicht als Erfolgsnachweis für v0.5.0 ausgegeben werden.

## Neue Regression 0.4.3+19

`app/test/fantasy_character_sheet_test.dart` testet die tatsächlichen Attributkarten auf 320/360/400 dp, die Einzigartigkeit der Grid-Keys und 1.4x-Systemschrift. Der vorherige CI-Lauf erreichte 319 bestandene / 4 fehlgeschlagene Flutter-Tests; diese Änderungen müssen in GitHub Actions neu nachgewiesen werden. Prüfe `flutter analyze`, `flutter test` und `flutter build apk --debug`.

## Regression für 0.4.2+18 – Flutter-Analyse

In 0.4.1 schlug GitHub Actions mit `undefined_named_parameter: mainAxisExtent` in `fantasy_character_sheet.dart:237` fehl. Die Syntax ist jetzt `GridView(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(..., mainAxisExtent: tileHeight))`. Bitte insbesondere `flutter analyze`, `flutter test` und den Android-Build im CI prüfen. Widgettests enthalten Fälle für 320, 360 und 400 logische Pixel sowie 1,4-fache Schrift; ein Test überprüft explizit den Grid-Delegate. Kein Fehler wird absichtlich unterdrückt.

## Zusätzliche Prüfung für 0.4.0+16

- Neues `app/test/fantasy_design_system_test.dart`: Theme-Farben und gerahmte Komponenten bei 320, 360 und 1000 logischen Pixeln.
- Vorhandene UI-/Dialogtests bleiben Teil der CI, insbesondere Scroll-/Tap-Tests unter 360 Pixeln, deren antippbare Elemente durch Gestaltung nicht überdeckt werden dürfen.
- Manuelle Geräteabnahme: untere Navigation, Landscape/Tablet-Seitenleiste, Abenteuer-Eingabe mit Tastatur, Scrollen, Inventar, Heldeneditor, Speichern, Import/Export.
- Lokal konnten Struktur und Python getestet werden; **Flutter-/Android-SDK fehlen**. Neue Widgets und mögliche Layout-/Compileprobleme erfordern die GitHub-CI.

## 0.3.9+15 – UI-Akzeptanz

1. `flutter analyze` und `flutter test`: insbesondere `fantasy_character_sheet_test.dart` und `ui_app_test.dart` auf einem 320-/360-dp-Fenster.
2. **Helden** → **Bogen ansehen**: gespeicherte Werte, farbige sechs Attribute, Übungsbonus und Rettungswürfe müssen stimmen; „Charakter bearbeiten“ öffnet den bisherigen Editor.
3. **Abenteuer** → **Charakterbogen ansehen**: die aktiven Kampagnenwerte anzeigen, ohne Spielerhandlung/Würfelwurf zu verändern.
4. Einen unvollständigen importierten Helden öffnen: unbekannte Werte bleiben „–“/„Nicht erfasst“, und in allen Ansichten gibt es keine überlaufende Typografie.
5. **Zustände/Verteidigung** wechseln; dabei dürfen keine Regeln oder Spielstände verändert werden.
6. Verifikation auf einem echten Android-Gerät, auch mit großer Systemschrift und aktiver Bildschirmvorlesefunktion, vor Freigabe.

## 0.3.8+14 – 15.10.2026 – spielbare dynamische Abenteuer und geprüfte KI-Angebote

- Narrative KI kann **genau eine optionale spielbare Herausforderung** pro Antwort vorschlagen, mit Quest, Begegnung und lokal ausgewähltem Gegnerprofil oder einer Wahrnehmungsaufgabe. KI-Daten werden auf Backend und Gerät validiert; der Provider kann keine Regel- oder Inventarwerte setzen.
- Neue Karten im Abenteuer: Angebot annehmen oder risikofrei verwerfen. Annahme startet einen lokal ausgewürfelten Einzelkampf oder eine Wahrnehmungsprobe SG 10, jeweils mit eigener Quest und atomarem Ereignis.
- Ein bestätigter Sieg/Erkundungserfolg schließt die verknüpfte Quest ab und vergibt eine **einmalige, nichtmagische Beute** aus der lokalen Tabelle; bei Fehlschlag/Flucht keine Beute. Keine EP- oder Gold-Buchung, keine unbestätigte Ausrüstung.
- Story-Fortschritt, Kampagnen-Journal, SQLite/JSON-Sicherung, bestehende Sprach- und Erzählfunktion bleiben angebunden; alte `schemaVersion:1`-Spielstände sind kompatibel. Neues optionales `adventureOffer`-Objekt.
- Korrektur des bisherigen CI-Blockers: Fastify-`preHandler` jetzt mit echten `FastifyRequest`/`FastifyReply`-Typen statt nichtkompatibler selbst gebauter Request-/Reply-Typen.
- Isolierte TypeScript-Prüfung des Abenteuer-Validators und Mock-Antworten, 22 Python-Pakettests, ergänzte Dart- und Backend-Tests. Flutter und vollständiges npm-Backend mangels lokalem SDK/offline-Abhängigkeiten **noch nicht bestätigt**. **Kein offizieller grüner Build dieses Stands**.
- Aktuelle Grenzen sind in [docs/AI_ADVENTURES.md](docs/AI_ADVENTURES.md) erklärt. **Keine Behauptung einer vollständig implementierten D&D-5e-Regelengine.**

## KI-Geschichtenmodul 0.3.7+13

Neue Tests: `app/test/ai_story_test.dart`, `app/test/ai_story_integration_test.dart`, `backend/test/story.test.ts`. Zusammen mit `app/test/campaign_memory_panel_test.dart` und `app/test/ui_app_test.dart` nach Import in GitHub Actions ausführen. Die Integrationstests nutzen nur einen simulierten Story-Provider und echte lokale SQLite-Revisionsspeicherung. Behauptet wird kein bestandener Flutter-Test, solange der Lauf nicht erfolgreich abgeschlossen wurde.

Zusätzlich auf Android prüfen: KI-Start mit Mock und OpenAI (ausdrückliche Kostenfreigabe), mehrere verschiedene Themen, Neustart nach drei Entscheidungen, NPC- und Queststatus, unterbrochene Sitzung, volles lokales Kontingent, fehlerhafte Providerantwort, PDF-freier JSON-Export/Import, alte 0.3.6-Spielstände und Abgrenzung der Mooswacht-Demo. Der narrative KI-Spielzug darf niemals Gegenstände, HP oder Würfel verändern. Die Backend-Endpunkte `/v1/story/start` und `/v1/story/advance` teilen sich Limits mit `/v1/narrate`.

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

## Rückblick und konsistente NPCs (0.3.5)

Nach GitHub-Import zusätzlich `cd app && flutter test test/memory_recall_test.dart test/ui_app_test.dart`
und `flutter analyze` ausführen. Automatische Tests sollen thematische
Filterung, leere/unbekannte Erinnerungen, bestätigte NPC-/Quest-/Inventarstatus,
reproduzierbares Ereignisjournal, erhaltene ausstehende Würfel und ungesendete
Texte prüfen. Auf dem Gerät Rückblick bei aktiver Tastatur und Push-to-Talk,
sowie das erneute Ansprechen Miras nach Schlüssel, Wächter und Questabschluss
prüfen. Ein bestandener CI-Test ersetzt diesen Gerätetest nicht.

## Persistentes Kampagnengedächtnis (0.3.6)

Nach GitHub-Import zusätzlich:

```bash
cd app
flutter analyze
flutter test test/campaign_memory_v036_test.dart test/campaign_memory_storage_test.dart test/campaign_memory_panel_test.dart test/ui_app_test.dart
```

Im Tagebuch einen Sitzungsrückblick speichern, einen offenen Handlungsstrang
anlegen und als gelöst markieren, Miras Beziehung mit Begründung ändern.
Das Gerät neu starten, Kampagne laden und dieselben Daten einschließlich der
alten Beziehungsnotiz sowie JSON-Export prüfen. Den Aktionsrückblick mit
Fragen zu NPCs und Handlungssträngen vergleichen. Eine Verwaltungsnotiz darf
keine TP, Würfel, Questbelohnung oder ausstehende Probe verändern.
Alten 0.3.5-Export ohne die drei neuen JSON-Felder importieren und den
360-px-Button „Vervollständigen“ überprüfen. Die eingereichten Dart-Tests
sind ohne erfolgreichen CI-Lauf nur Quellcode, keine bestandenen Tests.

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
