# Testprotokoll (2026-10-13)

## Tatsächlich ausgeführt

`cd backend && npm test` auf Node 22.16.0: **3 Tests bestanden, 0 fehlgeschlagen**. Getestet wurden Mock-Eingabevalidierung, Ablehnung fehlerhafter Felder und Regelneutralität des Backend-Mocktexts.

Python JSON-Syntaxprüfung für den Arescan-Spielstand: noch in der lokalen Abschlussprüfung auszuführen.

## Noch nicht ausgeführt

- `flutter analyze`: Flutter SDK in aktueller Arbeitsumgebung nicht vorhanden.
- `flutter test`: Flutter SDK in aktueller Arbeitsumgebung nicht vorhanden.
- `flutter build apk --debug`: kein Android SDK/Flutter verfügbar.
- Android-Mikrofon/TTS: kein angeschlossenes Testgerät.
- Backend `npm run build`: Abhängigkeiten lokal nicht installierbar.
- GitHub-Actions-Workflow: Dateien konnten noch nicht in GitHub übertragen werden.

## Manuelle Testfälle nach erstem APK-Build

1. Installation, App öffnen, beide Seed-Kampagnen sehen.
2. Arescan öffnen: alle sechs Attributwerte nicht belegt, TP/RK unbekannt.
3. Im Abenteuer „Untersuche das Amulett“ schreiben; passende Antwort und Tagebucheintrag prüfen.
4. App vollständig schließen, neu starten, Antwort weiterhin vorhanden.
5. W20 automatisch und manuell würfeln; natürliche Zahl, Modifikator, Zwischensumme getrennt sehen.
6. Deutschsprachigen Satz sprechen, Transkript korrigieren, senden und Antwort hören.
7. Aufnahmeberechtigung verweigern und sinnvolle Fehlermeldung erhalten.
8. Gerät ohne Netzverbindung testen: Text-Mock und lokale SQLite müssen funktionieren, Spracherkennung kann dienstabhängig ausfallen.
